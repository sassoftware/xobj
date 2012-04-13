#
# Copyright (c) 2008-2011 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any waranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.

"""
XObj can be used to parse XML and produce plain Python objects, as well as
produce XML from python objects.

For instance, one can parse the following XML fragment:

xmlString = '''
    <element intAttr="10" strAttr="hello">
       <subelement>Value 0</subelement>
    </element>
'''

by doing:

    doc = xobj2.Document.fromxml(xmlString)

The root node is accessible via doc.root, and each sub-node is represented by
a Python object.

So:

    doc.root.intAttr = "10"
    doc.root.strAttr = "hello"
    doc.root.subelement = "Value 0"

Producing XML from such a document is easy:

    doc.toxml()

Note that intAttr is represented as a string. To force a conversion to an
integer, one would have to define the structure of the object:

class Element(object):
    _xobjMeta = xobj2.XObjMetadata(
        attributes = dict(intAttr=int))

Parsing the same XML can be now done with:

    doc = xobj2.Document.fromxml(rootNodes = dict(element=Element))

Note that, because the Element object did not define its tag in the metadata,
a map from a tag name to a class had to be passed in the rootNodes argument
of the fromxml factory.


Assuming now that subelement can be repeated:

xmlString = '''
    <element intAttr="10" strAttr="hello">
       <subelement>Value 0</subelement>
       <subelement>Value 1</subelement>
    </element>
'''

we will get:
    doc.root.subelement = [u'Value 0', u'Value 1']

Or, to formally define a field to be a list of string objects:

class Element(object):
    _xobjMeta = xobj2.XObjMetadata(
        attributes = dict(intAttr=int),
        elements = [ xobj2.Field('subelement', [ str ]) ],
    )


One can serialize plain python objects without having to define their XML
structure. Each field will become a subelement.

class ColoredShape(object):
    def __init__(self, verticeCount, color):
        self.verticeCount = int(verticeCount)
        self.color = color

whiteRectangle = ColoredShape(4, 'white')

xmlString = xobj2.Document(root=whiteRectangle, rootName="shape").toxml()
print xmlString

<?xml version='1.0' encoding='UTF-8'?>
<shape>
  <color>white</color>
  <verticeCount>4</verticeCount>
</shape>


To force a particular field to be an attribute, one can define it like this:

class ColoredShape(object):
    _xobjMeta = xobj2.XObjMetadata(attributes=dict(verticeCount=int))
    def __init__(self, verticeCount=None, color=None):
        if verticeCount is not None:
            verticeCount = int(verticeCount)
        self.verticeCount = verticeCount
        self.color = color

Now xmlString will be:

<?xml version='1.0' encoding='UTF-8'?>
<shape verticeCount="4">
  <color>white</color>
</shape>

Parsing the same xmlString:

doc = xobj2.Document.fromxml(xmlString, rootNodes=dict(shape=ColoredShape))

would now show doc.root.verticeCount to be the integer 4.

Note that ColoredShape's __init__ method had to be changed to accept no
arguments.

Classes that have no child elements (but contain attributes) can have text data.
Text data is available using the _xobjText property.

If the classes do not define __slots__, then any additional data present
in the XML will be stored as instance data for the object of that class.

If you want to tightly control memory consumption, you can define classes
with __slots__. Additional fields will no longer show up in the objects.
"""

import datetime
import types
import inspect
from StringIO import StringIO

from lxml import etree
DocumentInvalid = etree.DocumentInvalid

try:
    import hashlib
    SHA1 = hashlib.sha1
except ImportError:
    import sha
    SHA1 = sha.new

try:
    from dateutil import parser as DateParser
    from dateutil import tz
    TZUTC = tz.tzutc()
except ImportError:
    DateParser = None
    TZUTC = None

class UnmatchedIdRef(Exception):
    """
    Exception raised when idref's cannot be matched with an id during
    XML generation.
    """

    def __str__(self):
        return ("Unmatched idref values during XML creation for id(s): %s"
                    % ",".join(str(x) for x in self.idList))

    def __init__(self, idList):
        self.idList = idList

class UniversalSet(object):
    """
    A set-like object that contains any object
    """
    __slots__ = ()
    def __contains__(self, obj):
        return True

class XType(object):
    def __init__(self, pythonType, forceList = False):
        self.pythonType = pythonType
        self.forceList = forceList
        self._meta = getattr(self.pythonType, '_xobjMeta', None)
        self._elements = dict(self._iterElements())

    def getFieldType(self, name):
        # First look up an attribute with that name
        ctype = self._meta.attributes.get(name)
        if ctype is not None:
            return ctype
        return self._elements.get(name)

    def getUnionTags(self):
        unionTags = dict()
        if self._meta is None:
            return unionTags
        for field in self._meta.elements:
            fname, ftype = field.name, field.type
            if isinstance(ftype, list) and len(ftype) > 1:
                for uf in ftype:
                    xtype = XTypeFromXObjectType(uf)
                    xtype.forceList = True
                    unionTags[uf._xobjMeta.tag] = (fname, xtype)
        return unionTags

    def _isComplex(self):
        # An element is complex if it has child elements
        for ftag, ftype in self._iterElements():
            return True
        return False

    def _getAttributes(self):
        if self._meta is None:
            return {}
        return self._meta.attributes

    def _iterElements(self):
        if self._meta is not None:
            for field in self._meta.elements:
                yield field.name, field.type

    @classmethod
    def issubclass(cls, obj, klass):
        if not inspect.isclass(obj):
            return False
        return issubclass(obj, klass)

    @classmethod
    def getClassSlots(_, klass):
        allSlots = set()
        for cls in inspect.getmro(klass):
            allSlots.update(getattr(cls, '__slots__', []))
        return allSlots

    @classmethod
    def getText(_, obj):
        if isinstance(obj, XObj):
            return unicode(obj)
        if isinstance(obj, _Native):
            return obj.toText()
        text = getattr(obj, '_xobjText', None)
        return text

def XTypeFromXObjectType(xObjectType):
    if type(xObjectType) == list:
        assert(len(xObjectType) == 1)
        return XType(XTypeFromXObjectType(xObjectType[0]).pythonType,
                     forceList = True)
    xobjClass = _Native.__metaclass__.getXobjClass(xObjectType)
    if xobjClass is not None:
        return XType(xobjClass)

    return XType(xObjectType)

class XObj(unicode):
    def __repr__(self):
        if self:
            return unicode.__repr__(self)
        else:
            return object.__repr__(self)

class _Native(object):
    _xobjNoMetadata = True
    __slots__ = [ 'val', ]

    class __metaclass__(type):
        _registry = {}
        def __new__(mcs, name, bases, attributes):
            if '__slots__' not in attributes:
                attributes.update(__slots__=[])
            cls = type.__new__(mcs, name, bases, attributes)
            nativeType = attributes.get('_nativeType')
            if nativeType:
                mcs._registry[nativeType] = cls
            return cls

        @classmethod
        def getXobjClass(mcs, nativeType):
            return mcs._registry.get(nativeType)

    def __init__(self, val=None):
        self.val = self.fromText(val)
    @classmethod
    def fromText(cls, val=None):
        if val is None:
            return cls.fromNone()
        return cls._nativeType(val)
    def toPythonType(self):
        return self.val
    @classmethod
    def toText(cls, val):
        return unicode(val)
    @classmethod
    def fromNone(cls):
        return None

class XObjUnicode(_Native):
    _nativeType = unicode
    @classmethod
    def fromNone(cls):
        return u''

class XObjString(_Native):
    _nativeType = str
    @classmethod
    def fromText(cls, val=None):
        # lxml may present the same string as either text or unicode
        if isinstance(val, unicode):
            return val
        if val is not None:
            # Only ASCII data is allowed
            return val.decode('ascii')
        return ''

class XObjBool(_Native):
    _nativeType = bool
    @classmethod
    def fromText(cls, val=None):
        if isinstance(val, basestring):
            val = val.lower()
            val = (val == 'true')
        return bool(val)
    @classmethod
    def toText(cls, val):
        if val:
            return 'true'
        return 'false'

class XObjInt(_Native):
    _nativeType = int

class XObjFloat(_Native):
    _nativeType = float

class XObjLong(_Native):
    _nativeType = long

class Date(_Native):
    __slots__ = []
    _nativeType = datetime.datetime

    @classmethod
    def fromText(cls, val=None):
        if val is None:
            return cls.fromNone()
        if DateParser is None:
            return val
        return DateParser.parse(val)

    @classmethod
    def toText(cls, val):
        if val is None:
            return None
        return val.isoformat()

class XObjMetadata(object):
    """
    User-defined metadata at class creation time
    If the optional checksumAttribute is specified, a sha1 hash for the node
    will be computed over its XML represetation.
    """
    __slots__ = [ 'elements', 'attributes', 'tag', '_elementsMap',
        'checksumAttribute', ]

    def __init__(self, tag=None, elements=None, attributes=None,
            checksumAttribute=None):
        self.elements = self._toFields(elements)
        self.attributes = self._toAttributes(attributes)
        self.tag = tag
        self._elementsMap = dict((x.name, x) for x in self.elements)
        self.checksumAttribute = checksumAttribute

    def getElement(self, name):
        return self._elementsMap.get(name, None)

    def getAttribute(self, name):
        return self.attributes.get(name, None)

    def hasField(self, name):
        return self.getAttribute(name) or self.getElement(name)

    def addAttribute(self, name, type):
        self.attributes[name] = type

    def addElement(self, name, type):
        field = Field(name, type)
        self._elementsMap[name] = field
        self.elements.append(field)

    def getIdField(self):
        # Look for an attribute whose type is XID
        candidates = []
        for fname, ftype in self.attributes.items():
            if XType.issubclass(ftype, XID):
                return fname
            if ((fname == 'id' or fname.endswith('_id')) and
                    ftype in [ str, unicode ]):
                candidates.append(fname)
        for field in self.elements:
            if field.type == XID:
                return field.name
        if candidates:
            return candidates[0]
        return None

    @classmethod
    def _toFields(cls, elements):
        if not elements:
            return []
        if not isinstance(elements, list):
            elements = [ elements ]
        ret = []
        for elt in elements:
            if isinstance(elt, basestring):
                elt = Field(elt, unicode)
            if not isinstance(elt, Field):
                raise TypeError, "Expected a Field object"
            if isinstance(elt.type, list) and len(elt.type) > 1:
                # Union type. Should be a list of complex types, or we get
                # upset
                tagNames = set()
                for uEl in elt.type:
                    meta = getattr(uEl, '_xobjMeta', None)
                    if meta is None:
                        raise TypeError("Union types should have metadata")
                    if meta.tag is None:
                        raise TypeError("Union types should specify a tag")
                    if meta.tag in tagNames:
                        raise TypeError("Duplicate tags in union type")
                    tagNames.add(meta.tag)
            ret.append(elt)
        return ret

    @classmethod
    def _toAttributes(cls, attributes):
        if not attributes:
            return {}
        if isinstance(attributes, dict):
            return attributes
        if isinstance(attributes, (list, tuple)):
            return dict((x, unicode) for x in attributes)
        raise TypeError, "Invalid attribute specification: %s" % (attributes, )

    def getSlots(self):
        slots = set(self.attributes)
        slots.update(x.name for x in self.elements)
        if self.checksumAttribute:
            slots.add(self.checksumAttribute)
        return sorted(slots)

class XID(XObj):
    pass

class XIDREF(XObj):
    pass

def isMethod(func):
    return inspect.ismethod(func) or inspect.ismethoddescriptor(func)

def findPythonType(xobj, key):
    md = getattr(xobj.__class__, '_xobjMeta', None)
    if md is None:
        return None
    attr = md.getAttribute(key)
    if attr is not None:
        return attr
    elem = md.getElement(key)
    if elem is not None:
        return elem.type
    return None

    pc = xobj.__class__.__dict__.get(key, None)
    if pc is not None and not isMethod(pc):
        return pc

    md = getattr(xobj.__class__, '_xobj', None)
    if md is None:
        return None

    return md.attributes.get(key, None)

class ElementGenerator(object):
    _UNDEFINED = object()

    def __init__(self, xobj, tag, nsmap = {}, schema = None):
        self.idsNeeded = set()
        self.idsFound = set()
        self.element = self.getElementTree(xobj, tag, nsmap = nsmap)
        if (self.idsNeeded - self.idsFound):
            raise UnmatchedIdRef(self.idsNeeded - self.idsFound)

        if schema:
            schema.assertValid(self.element)

    def getElementTree(self, xobj, tag, parentElement=None, nsmap=None):

        if xobj is None:
            return

        tag = self._addns(tag, nsmap)

        xobjClass = _Native.__metaclass__.getXobjClass(type(xobj))
        if xobjClass:
            xobj = xobjClass.toText(xobj)
            if parentElement is None:
                element = etree.Element(tag, {})
            else:
                element = etree.SubElement(parentElement, tag, {})
            element.text = xobj
            return element

        meta = getattr(xobj.__class__, '_xobjMeta', None)
        if meta is None:
            meta = XObjMetadata()
            try:
                xobj.__class__._xobjMeta = meta
            except TypeError:
                # Base types like dict don't allow for extra attributes
                # to be added
                pass
        return self._fromMeta(xobj, tag, meta, parentElement, nsmap)

    def tostring(self, prettyPrint = True, xml_declaration = True):
        return etree.tostring(self.element, pretty_print = prettyPrint,
                              encoding = 'UTF-8',
                              xml_declaration = xml_declaration)

    def _fromMeta(self, xobj, tag, meta, parentElement, nsmap):
        if tag is None:
            tag = self._addns(meta.tag, nsmap)

        # Store all field names for this xobj, so we can catch things we
        # haven't defined in the metadata
        if isinstance(xobj, dict):
            allFieldNames = xobj.keys()
        elif hasattr(xobj, '__dict__'):
            allFieldNames = set(xobj.__dict__)
        else:
            allFieldNames = XType.getClassSlots(xobj.__class__)

        attrs = {}
        for attrName, attrType in meta.attributes.items():
            # Mark this field as already processed
            allFieldNames.discard(attrName)
            if attrName == meta.checksumAttribute:
                # If the checksum attribute is part of the regular
                # attributes, ignore it, we don't want to compute a sha1
                # of something that will change.
                continue

            val = self._getattr(xobj, attrName, None)
            if val is None:
                continue
            if XType.issubclass(attrType, XIDREF):
                # The value is a complex object, from which we need
                # to extract its id and copy it as a ref.
                smeta = getattr(val, '_xobjMeta', None)
                if smeta is None:
                    # Probably simple type
                    idVal = unicode(val)
                else:
                    fieldName = smeta.getIdField()
                    if fieldName is None:
                        raise XObjSerializationException(
                            'No id found for element referenced by %s' % attrName)
                    idVal = self._getattr(val, fieldName, None)
                    if idVal is None:
                        raise XObjSerializationException(
                            'Empty ID field %s for element referenced by %s' %
                                (fieldName, attrName))
                    val = idVal
                self.idsNeeded.add(idVal)
            elif (attrName == 'id' or attrName.endswith('_id') or
                    XType.issubclass(attrType, XID)):
                self.idsFound.add(val)
            else:
                xobjClass = _Native.__metaclass__.getXobjClass(type(val))
                if xobjClass:
                    val = xobjClass.toText(val)
            attrs[self._addns(attrName, nsmap)] = val

        if parentElement is None:
            element = etree.Element(tag, attrs, nsmap = nsmap)
        else:
            element = etree.SubElement(parentElement, tag, attrs)

        text = getattr(xobj, '_xobjText', None)
        if text is None and isinstance(xobj, XObj):
            text = unicode(xobj) or None or None
        element.text = text

        for field in meta.elements:
            # Mark this field as already processed
            allFieldNames.discard(field.name)

            val = self._getattr(xobj, field.name, None)
            if val is None:
                continue
            self._getElementTreeForValue(val, field.name, element, nsmap)

        # Now iterate over the rest of the values and add them as fields
        for fieldName in allFieldNames:
            if fieldName.startswith('_'):
                continue
            val = self._getattr(xobj, fieldName, None)
            if val is None:
                continue
            self._getElementTreeForValue(val, fieldName, element, nsmap)

        if meta.checksumAttribute:
            # We need to checksum the XML node
            csum = SHA1()
            csum.update(etree.tostring(element, pretty_print = False,
                xml_declaration = False, encoding = 'UTF-8'))
            element.attrib[meta.checksumAttribute] = csum.hexdigest()
        return element

    @classmethod
    def _getattr(cls, obj, attrName, defVal=_UNDEFINED):
        # Class attributes take priority
        val = getattr(obj, attrName, cls._UNDEFINED)
        if val is not cls._UNDEFINED:
            return val
        if hasattr(obj, 'get'):
            val = obj.get(attrName, cls._UNDEFINED)
        if val is not cls._UNDEFINED:
            return val
        # XXX should probably try  __getitem__ too
        return defVal

    def _getElementTreeForValue(self, value, tag, parentElement, nsmap):
        if not isinstance(value, list):
            value = [ value ]
        for subval in value:
            self.getElementTree(subval, tag, parentElement=parentElement,
                                nsmap=nsmap)

    @classmethod
    def _addns(cls, s, nsmap):
        if nsmap is None:
            return s
        for short, long in nsmap.iteritems():
            if short and s.startswith(short + '_'):
                s = '{' + long + '}' + s[len(short) + 1:]
        return s

class Document(object):
    _UniversalSet = UniversalSet()
    ElementGenerator = ElementGenerator
    Undefined = object()
    def __init__(self, rootNodes=None, schema=None, root=None, rootName=None):
        self._idsNeeded = []
        self._dynamicClassDict = {}
        self._ids = {}
        self._explicitNamespaces = False
        self._xmlNsMap = {}
        self.schema = schema
        self.root = root
        self.rootName = rootName
        self.rootNodesMap = self._toRootNodesMap(rootNodes)
        self.nameSpaceMap = {}

    def parse(self, data, schemaf = None):
        return self.fromxml(data, schemaf=schemaf, document=self)

    @classmethod
    def serialize(cls, root, **kwargs):
        doc = cls()
        doc.root = root
        return doc.toxml(**kwargs)

    def toxml(self, prettyPrint=True, xml_declaration=True, nsmap=None):
        et = self.getElementTree(nsmap=nsmap)
        return et.tostring(prettyPrint = prettyPrint,
                           xml_declaration = xml_declaration)

    def getElementTree(self, nsmap=None):
        if nsmap:
            map = nsmap
        else:
            map = self._xmlNsMap

        if self._explicitNamespaces:
            map = map.copy()
            del map[None]

        return self._getElementTree(self.root, self.rootName,
                schemaf=self.schema, nsmap=map)

    @classmethod
    def _getElementTree(cls, xobj, tag, schemaf=None, nsmap=None):
        if schemaf:
            schemaObj = etree.XMLSchema(file = schemaf)
        else:
            schemaObj = None

        if tag is None:
            meta = getattr(xobj.__class__, '_xobjMeta', None)
            if meta is None or meta.tag is None:
                raise TypeError, 'must specify a tag'
            tag = meta.tag

        gen = cls.ElementGenerator(xobj, tag, schema = schemaObj, nsmap = nsmap)
        return gen


    def fromElementTree(self, xml, rootXClass=None):

        rootElement = xml.getroot()

        if not self.nameSpaceMap:
            self._xmlNsMap = rootElement.nsmap
        else:
            fullNsMap = dict((y,x) for (x,y) in self.nameSpaceMap.iteritems())
            for short, long in rootElement.nsmap.iteritems():
                if long not in fullNsMap:
                    fullNsMap[long] = short

            self._xmlNsMap = dict((y,x) for (x,y) in fullNsMap.iteritems())

        self._explicitNamespaces = False
        if None in self._xmlNsMap:
            if [ y for (x, y) in self._xmlNsMap.iteritems()
                    if x and y == self._xmlNsMap[None] ]:
                self._explicitNamespaces = True

        self.root, self.rootName = self._parseElement(rootElement)

        for (xobj, tag, theId) in self._idsNeeded:
            if theId not in self._ids:
                raise XObjIdNotFound(theId)
            self._addAttribute(xobj, tag, self._ids[theId])

    def _nsmap(self, s):
        for short, long in self._xmlNsMap.iteritems():
            if self._explicitNamespaces and short is None:
                continue

            if s.startswith('{' + long + '}'):
                if short:
                    s = short + '_' + s[len(long) + 2:]
                else:
                    s = s[len(long) + 2:]

        return s

    def _setAttribute(self, xobj, doc, key, val):
        expectedType = findPythonType(xobj, key)

        if expectedType:
            expectedXType = XTypeFromXObjectType(expectedType)
            if (key == 'id' or key.endswith('_id') or
                        XType.issubclass(expectedXType.pythonType, XID)):
                doc._ids[val] = xobj
            elif XType.issubclass(expectedXType.pythonType, XIDREF):
                doc._idsNeeded.append((xobj, key, val))
                return
            else:
                val = expectedXType.pythonType(val)
        else:
            if (key == 'id' or key.endswith('_id')):
                doc._ids[val] = xobj

            expectedXType = None

        self._addAttribute(xobj, key, val, xType = expectedXType)

    def _addAttribute(self, xobj, key, val, xType = None):
        self._setItem(xobj, key, val, xType)
        meta = xobj.__class__._xobjMeta
        if not meta.getAttribute(key):
            # preserve any type information we copied in, but only if it
            # wasn't previously defined (either element or attribute).
            if xType is None:
                typ = type(val)
            else:
                typ = xType.pythonType
            meta.addAttribute(key, typ)

    def _addElement(self, xobj, key, val, xType = None):
        self._setItem(xobj, key, val, xType = xType)
        meta = xobj.__class__._xobjMeta
        if not meta.hasField(key):
            # preserve any type information we copied in, but only if it
            # wasn't previously defined (either element or attribute).
            meta.addElement(key, xType.pythonType)

    @classmethod
    def _setItem(cls, xobj, key, val, xType = None):
        # If there are no slots for this key, don't bother
        if (not hasattr(xobj, '__dict__') and
                key not in XType.getClassSlots(xobj.__class__)):
            return
        # Get rid of the XObjXXX types here, if possible
        if hasattr(val, 'toPythonType'):
            val = val.toPythonType()
        current = getattr(xobj, key, None)
        if xType:
            if xType.forceList:
                # force the item to be a list, and use the type inside of
                # this list as the type of elements of the list
                v = cls._getPropValue(xobj, key)
                if v is cls.Undefined:
                    current = []
                setattr(xobj, key, current)
            # Avoid turning things into lists that are not defined as lists
            # in the type map.
            elif not isinstance(xobj, XObj):
                setattr(xobj, key, val)
                return

        if getattr(xobj, key, None) is None:
            # This has not yet been set in the instance (because it's
            # missing) or it's been set to None (because we think we don't
            # have this value but it's actually an idref being filled in
            # later)
            setattr(xobj, key, val)
        elif type(current) == list:
            current.append(val)
        else:
            setattr(xobj, key, [ current, val ])

    @classmethod
    def _setText(cls, xobj, text):
        if text is None:
            return
        if (hasattr(xobj, '__dict__') or
                '_xobjText' in XType.getClassSlots(xobj.__class__)):
            xobj._xobjText = text

    def _getXTypeForTag(self, tag, parentXType, parentXObj, parentUnionTags):
        thisXType = self._dynamicClassDict.get(tag)
        if thisXType is not None:
            return thisXType
        if parentXObj is None:
            # Match the element with one of the user-supplied classes
            thisPyType = self.rootNodesMap.get(tag)
        else:
            if tag in parentUnionTags:
                thisPyType = parentUnionTags[tag][1].pythonType
            else:
                thisPyType = parentXType.getFieldType(tag)

        if thisPyType is None:
            # create a subclass for this type
            thisPyType = type(tag + '_XObj_Type', (XObj,),
                dict(_xobjDynamic=True, _xobjMeta=XObjMetadata()))
            thisXType = XType(thisPyType)
        thisXType = XTypeFromXObjectType(thisPyType)

        if getattr(thisPyType, '_xobjDynamic', False):
            self._dynamicClassDict[tag] = thisXType
        return thisXType


    def _parseElement(self, element, parentXType = None, parentXObj = None,
                      parentUnionTags = {}):
        # handle the text for this tag
        if element.getchildren():
            # It's a complex type, so the text is meaningless.
            text = None
        else:
            text = element.text

        tag = self._nsmap(element.tag)

        thisXType = self._getXTypeForTag(tag, parentXType, parentXObj,
            parentUnionTags)

        assert thisXType is not None
        unionTags = {}

        if text is not None and thisXType._isComplex():
            # This type has child elements, so it's complex, so
            # the text is meaningless.
            text = None

        if text:
            xobj = self._newPythonObject(thisXType, text)
        else:
            xobj = self._newPythonObject(thisXType)

        # look for unions
        unionTags.update(thisXType.getUnionTags())

        meta = getattr(xobj.__class__, '_xobjMeta', None)
        if meta is None and not getattr(xobj.__class__, '_xobjNoMetadata', True):
            meta = xobj.__class__._xobjMeta = XObjMetadata()
        if meta is not None and meta.tag is None:
            meta.tag = tag

        # handle children
        for childElement in element.getchildren():
            if types.BuiltinFunctionType == type(childElement.tag):
                # this catches comments. this is ugly.
                continue

            self._parseElement(childElement, parentXType = thisXType,
                               parentXObj = xobj,
                               parentUnionTags = unionTags)

        # handle attributes
        for (key, val) in element.items():
            key = self._nsmap(key)
            self._setAttribute(xobj, self, key, val)

        if parentXObj is not None:
            if tag in parentUnionTags:
                meta.tag = tag
                self._addElement(parentXObj, parentUnionTags[tag][0], xobj,
                                 parentUnionTags[tag][1])
            else:
                self._addElement(parentXObj, tag, xobj, thisXType)

        if hasattr(xobj, 'toPythonType'):
            xobj = xobj.toPythonType()
        return xobj, tag

    @classmethod
    def fromxml(cls, f, schemaf = None, document=None, rootNodes=None):
        if not hasattr(f, 'read'):
            f = StringIO(f)
        if document is None:
            document = cls(rootNodes=rootNodes, schema=schemaf)

        if schemaf is None:
            schemaf = document.schema

        if schemaf is None:
            schemaObj = None
        else:
            schemaObj = etree.XMLSchema(file = schemaf)

        parser = etree.XMLParser(schema = schemaObj)
        xml = etree.parse(f, parser)
        document.fromElementTree(xml)
        return document

    @classmethod
    def _newPythonObject(cls, xType, text=None):
        if text is None:
            obj = xType.pythonType()
        elif XType.issubclass(xType.pythonType, (XObj, _Native)):
            obj = xType.pythonType(text)
        else:
            obj = xType.pythonType()
            cls._setText(obj, text)
        fieldSet = cls._getFieldSet(obj)
        for fieldName in xType._getAttributes():
            if fieldName not in fieldSet:
                continue
            setattr(obj, fieldName, None)
        for fieldName, fieldType in xType._iterElements():
            if fieldName not in fieldSet:
                continue
            val = None
            if isinstance(fieldType, list):
                val = []
            setattr(obj, fieldName, val)
        return obj

    @classmethod
    def _toRootNodesMap(cls, rootNodes):
        if rootNodes is None:
            return {}
        if isinstance(rootNodes, dict):
            for k, v in rootNodes.iteritems():
                if not isinstance(k, basestring):
                    raise TypeError("Expected string for tag type")
            return rootNodes
        if not isinstance(rootNodes, list):
            rootNodes = [ rootNodes ]
        ret = {}
        for cls in rootNodes:
            meta = getattr(cls, '_xobjMeta', None)
            if meta is None:
                raise TypeError("Root node classes should have metadata")
            if meta.tag is None:
                raise TypeError("Root node classes should have a tag")
            ret[meta.tag] = cls
        return ret

    @classmethod
    def _getFieldSet(cls, obj):
        if hasattr(obj, '__dict__'):
            return cls._UniversalSet
        return XType.getClassSlots(obj.__class__)

    @classmethod
    def _getPropValue(cls, obj, name):
        return getattr(obj, name, cls.Undefined)

class XObjParseException(Exception):
    pass

class XObjIdNotFound(XObjParseException):

    def __str__(self):
        return "XML ID '%s' not found in document" % self.theId

    def __init__(self, theId):
        self.theId = theId

class XObjSerializationException(Exception):
    pass

class Field(object):
    """
    Representation of a field. Contains name and type.
    """
    __slots__ = ('name', 'type', )
    def __init__(self, name, type):
        self.name = name
        self.type = type

    @property
    def isList(self):
        return isinstance(self.type, list)

    def __repr__(self):
        return "Field(%s, %s)" % (self.name, self.type)
