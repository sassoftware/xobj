#
# Copyright (c) 2008 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any waranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.

from lxml import etree
import types
from StringIO import StringIO

DocumentInvalid = etree.DocumentInvalid

class UnknownXType(Exception):

    """
    Exception raised when a class prototype specifies a type which is not
    understood.
    """

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

class XType(object):

    def _isComplex(self):
        for key, val in self.pythonType.__dict__.iteritems():
            if (type(val) != types.FunctionType and 
                 type(val) != types.MethodType and key[0] != '_'
                 and key != 'text'):
                return True

        return False

    def __init__(self, pythonType, forceList = False):
        self.pythonType = pythonType
        self.forceList = forceList

class XUnionType(XType):

    def __init__(self, d):
        self.d = {}
        for key, val in d.iteritems():
            self.d[key] = XTypeFromXObjectType(val)
            self.d[key].forceList = True

def XTypeFromXObjectType(xObjectType):

    if xObjectType == str or xObjectType == object:
        # Basic object's are static, making instantiating one pretty worthless.
        return XType(XObj)
    elif xObjectType == int:
        return XType(XObjInt)
    elif xObjectType == float:
        return XType(XObjFloat)
    elif type(xObjectType) == list:
        assert(len(xObjectType) == 1)
        return XType(XTypeFromXObjectType(xObjectType[0]).pythonType,
                     forceList = True)

    return XType(xObjectType)

class XObj(str):

    """
    Example class for all elements represented in XML. Subclasses of XObject
    can be used to specify how attributes and elements of the element are
    represented in python. For example, parsing the XML:

        <element intAttr="10" strAttr="hello">
           <subelement>Value</subelement>
        </element>

    using this class:

        class Element(xobj.XObj):

            intAttr = int                       # force an int
            subelement = [ str ]                # force a list

    (which is done with doc = xobj.parse("---xml string---",
                                    typeMap = { 'element' : Element } )
    will result in the object tree:

        doc.element.intAttr = 10
        doc.element.strAttr = 'hello'
        doc.element.subelement.text = [ 'Value' ]

    """

    def __repr__(self):
        if self:
            return str.__repr__(self)
        else:
            return object.__repr__(self)

class XObjInt(int):
    pass

class XObjFloat(float):
    pass

class XObjMetadata(object):

    __slots__ = [ 'elements', 'attributes', 'tag' ]

    def __init__(self, elements = None, attributes = None):
        if elements:
            self.elements = list(elements)
        else:
            self.elements = []

        if attributes:
            if type(attributes) == dict:
                self.attributes = attributes.copy()
            else:
                self.attributes = dict( (x, None) for x in attributes )
        else:
            self.attributes = dict()

        self.tag = None

class XID(XObj):

    pass

class XIDREF(XObj):

    pass

def findPythonType(xobj, key):
    pc = getattr(xobj.__class__, key, None)
    if pc is not None:
        return pc

    md = getattr(xobj.__class__, '_xobj', None)
    if md is None:
        return None

    return md.attributes.get(key, None)

class ElementGenerator(object):

    def getElementTree(self, xobj, tag, parentElement = None, nsmap = {}):

        def addns(s):
            for short, long in nsmap.iteritems():
                if short and s.startswith(short + '_'):
                    s = '{' + long + '}' + s[len(short) + 1:]

            return s

        if xobj is None:
            return

        if type(xobj) in (int, float):
            xobj = str(xobj)

        if type(xobj) == str:
            element = etree.SubElement(parentElement, tag, {})
            element.text = xobj
            return element

        tag = addns(tag)

        if hasattr(xobj, '_xobj'):
            attrSet = xobj._xobj.attributes

            if xobj._xobj.tag is not None:
                tag = xobj._xobj.tag
        else:
            attrSet = set()

        attrs = {}
        elements = {}
        for key, val in xobj.__dict__.iteritems():
            if key[0] != '_':
                if key in attrSet:
                    pythonType = findPythonType(xobj, key)

                    if pythonType and issubclass(pythonType, XIDREF):
                        idVal = getattr(val, 'id', None)
                        if idVal is None:
                            # look for an id name in a different namespace
                            for idKey, idType in (
                                        val.__dict__.iteritems()):
                                if idKey.endswith('_id'):
                                    idVal = getattr(val, idKey)
                                    break

                        if idVal is None:
                            # look for something prorotyped XID
                            for idKey, idType in (
                                        val.__class__.__dict__.iteritems()):
                                if (idKey[0] != '_' and type(idType) == type
                                                and issubclass(idType, XID)):
                                    idVal = getattr(val, idKey)
                                    break

                        if idVal is None:
                            raise XObjSerializationException(
                                    'No id found for element referenced by %s'
                                    % key)
                        val = idVal
                        self.idsNeeded.add(idVal)
                    elif (key == 'id' or key.endswith('_id') or
                          (pythonType and issubclass(pythonType, XID))):
                        self.idsFound.add(val)

                    if val is not None:
                        key = addns(key)
                        attrs[key] = str(val)
                else:
                    l = elements.setdefault(key, [])
                    if type(val) == list:
                        l.extend(val)
                    else:
                        l.append(val)

        orderedElements = []

        if hasattr(xobj, '_xobj'):
            for name in xobj._xobj.elements:
                for val in elements.get(name, []):
                    orderedElements.append((name, val))
            for name in (set(elements) - set(xobj._xobj.elements)):
                for val in elements[name]:
                    orderedElements.append((name, val))
        else:
            orderedElements = sorted(elements.iteritems())

        if parentElement is None:
            element = etree.Element(tag, attrs, nsmap = nsmap)
        else:
            element = etree.SubElement(parentElement, tag, attrs)

        if isinstance(xobj, str) and xobj:
            element.text = str(xobj)

        for key, val in orderedElements:
            if val is not None:
                if type(val) == list:
                    for subval in val:
                        self.getElementTree(subval, key,
                                            parentElement = element,
                                            nsmap = nsmap)
                else:
                    self.getElementTree(val, key, parentElement = element,
                                        nsmap = nsmap)

        return element

    def tostring(self, prettyPrint = True, xml_declaration = True):
        return etree.tostring(self.element, pretty_print = prettyPrint,
                              encoding = 'UTF-8',
                              xml_declaration = xml_declaration)

    def __init__(self, xobj, tag, nsmap = {}, schema = None):
        self.idsNeeded = set()
        self.idsFound = set()
        self.element = self.getElementTree(xobj, tag, nsmap = nsmap)
        if (self.idsNeeded - self.idsFound):
            raise UnmatchedIdRef(self.idsNeeded - self.idsFound)

        if schema:
            schema.assertValid(self.element)

class Document(object):

    nameSpaceMap = {}
    typeMap = {}

    def __init__(self, schema = None):
        self._idsNeeded = []
        self._dynamicClassDict = {}
        self._ids = {}
        self.__explicitNamespaces = False
        self.__xmlNsMap = {}
        self._xobj = XObjMetadata()
        self.__schema = schema

    def toxml(self, nsmap = {}, prettyPrint = True, xml_declaration = True):
        for key, val in self.__dict__.iteritems():
            if key[0] == '_': continue
            break

        if self.__explicitNamespaces:
            map = self.__xmlNsMap.copy()
            del map[None]
        else:
            map = self.__xmlNsMap

        gen = ElementGenerator(val, key, nsmap = map, schema = self.__schema)
        return gen.tostring(prettyPrint = prettyPrint,
                            xml_declaration = xml_declaration)

    def fromElementTree(self, xml, rootXClass = None, nameSpaceMap = {},
                        unionTags = {}):

        def nsmap(s):
            for short, long in self.__xmlNsMap.iteritems():
                if self.__explicitNamespaces and short is None:
                    continue

                if s.startswith('{' + long + '}'):
                    if short:
                        s = short + '_' + s[len(long) + 2:]
                    else:
                        s = s[len(long) + 2:]

            return s

        def setAttribute(xobj, doc, key, val):
            expectedType = findPythonType(xobj, key)
            if expectedType is None:
                expectedType = doc.typeMap.get(key, None)

            if expectedType:
                expectedXType = XTypeFromXObjectType(expectedType)
                if (key == 'id' or key.endswith('_id') or
                            issubclass(expectedXType.pythonType, XID)):
                    doc._ids[val] = xobj
                elif issubclass(expectedXType.pythonType, XIDREF):
                    doc._idsNeeded.append((xobj, key, val))
                    return
                else:
                    val = expectedXType.pythonType(val)
            else:
                if (key == 'id' or key.endswith('_id')):
                    doc._ids[val] = xobj

                expectedXType = None

            addAttribute(xobj, key, val, xType = expectedXType)

        def addAttribute(xobj, key, val, xType = None):
            setItem(xobj, key, val, xType)
            if key not in xobj._xobj.attributes:
                # preserver any type information we copied in
                xobj._xobj.attributes[key] = None

        def addElement(xobj, key, val, xType = None):
            setItem(xobj, key, val, xType = xType)
            if key not in xobj._xobj.elements:
                xobj._xobj.elements.append(key)

        def setItem(xobj, key, val, xType = None):
            current = getattr(xobj, key, None)
            if xType and xType.forceList:
                # force the item to be a list, and use the type inside of
                # this list as the type of elements of the list
                if key not in xobj.__dict__:
                    current = []
                    setattr(xobj, key, current)

            if xobj.__dict__.get(key, None) is None:
                # This has not yet been set in the instance (because it's
                # missing) or it's been set to None (because we think we don't
                # have this value but it's actually an idref being filled in
                # later)
                setattr(xobj, key, val)
            elif type(current) == list:
                current.append(val)
            else:
                setattr(xobj, key, [ current, val ])

        def parseElement(element, parentXType = None, parentXObj = None,
                         parentUnionTags = {}):
            # handle the text for this tag
            if element.getchildren():
                # It's a complex type, so the text is meaningless.
                text = None
            else:
                text = element.text

            tag = nsmap(element.tag)

            if tag in self._dynamicClassDict:
                thisXType = self._dynamicClassDict[tag]
            else:
                if parentXObj is None:
                    parentXObj = self
                    parentXType = XTypeFromXObjectType(self.__class__)

                thisXType = None
                thisPyType = None

                if parentXType:
                    if tag in parentUnionTags:
                        thisPyType = parentUnionTags[tag][1].pythonType
                    else:
                        thisPyType = getattr(parentXType.pythonType, tag, None)

                if not thisPyType:
                    thisPyType = self.typeMap.get(tag, None)

                if thisPyType:
                    thisXType = XTypeFromXObjectType(thisPyType)

                self._dynamicClassDict[tag] = thisXType

            unionTags = {}
            if thisXType:
                if text is not None and thisXType._isComplex():
                    # This type has child elements, so it's complex, so
                    # the text is meaningless.
                    text = None

                if text:
                    xobj = thisXType.pythonType(text)
                else:
                    xobj = thisXType.pythonType()

                # look for unions
                for key, val in thisXType.pythonType.__dict__.iteritems():
                    if key[0] == '_': continue
                    if isinstance(val, list) and isinstance(val[0], dict):
                        ut = XUnionType(val[0])
                        for a, b in ut.d.iteritems():
                            unionTags[a] = (key, b)
            else:
                localTag = nsmap(element.tag)
                # create a subclass for this type
                NewClass = type(localTag + '_XObj_Type', (XObj,), {})
                self._dynamicClassDict[tag] = XType(NewClass)

                if text:
                    xobj = NewClass(text)
                else:
                    xobj = NewClass()

            if not hasattr(xobj, '_xobj'):
                xobj._xobj = XObjMetadata()

            # handle children
            for childElement in element.getchildren():
                if types.BuiltinFunctionType == type(childElement.tag):
                    # this catches comments. this is ugly.
                    continue
                child = parseElement(childElement, parentXType = thisXType,
                                     parentXObj = xobj,
                                     parentUnionTags = unionTags)

            # handle attributes
            for (key, val) in element.items():
                key = nsmap(key)
                setAttribute(xobj, self, key, val)

            # Backfill any attributes that were not in the XML with None.
            for key, val in xobj._xobj.attributes.iteritems():
                key = nsmap(key)
                # Do not backfill values that are XIDREFs, they will be
                # handled later.
                if val is not None and issubclass(val, XIDREF):
                    continue
                if not hasattr(xobj, key):
                    setAttribute(xobj, self, key, val)

            # anything which is the same as in the class wasn't set in XML, so
            # set it to None
            for key, val in xobj.__class__.__dict__.items():
                if key[0] == '_': continue
                if getattr(xobj, key) == val:
                    if type(val) == list:
                        setattr(xobj, key, [])
                    else:
                        setattr(xobj, key, None)

            if parentXObj is not None:
                if tag in parentUnionTags:
                    xobj._xobj.tag = tag
                    addElement(parentXObj, parentUnionTags[tag][0], xobj,
                                           parentUnionTags[tag][1])
                else:
                    addElement(parentXObj, tag, xobj, thisXType)

            return xobj

        rootElement = xml.getroot()

        if not self.nameSpaceMap:
            self.__xmlNsMap = rootElement.nsmap
        else:
            fullNsMap = dict((y,x) for (x,y) in self.nameSpaceMap.iteritems())
            for short, long in rootElement.nsmap.iteritems():
                if long not in fullNsMap:
                    fullNsMap[long] = short

            self.__xmlNsMap = dict((y,x) for (x,y) in fullNsMap.iteritems())

        self.__explicitNamespaces = False
        if None in self.__xmlNsMap:
            if [ y for (x, y) in self.__xmlNsMap.iteritems()
                    if x and y == self.__xmlNsMap[None] ]:
                self.__explicitNamespaces = True

        parseElement(rootElement)

        for (xobj, tag, theId) in self._idsNeeded:
            if theId not in self._ids:
                raise XObjIdNotFound(theId)
            addAttribute(xobj, tag, self._ids[theId])

class XObjParseException(Exception):

    pass

class XObjIdNotFound(XObjParseException):

    def __str__(self):
        return "XML ID '%s' not found in document" % self.theId

    def __init__(self, theId):
        self.theId = theId

class XObjSerializationException(Exception):

    pass

def parsef(f, schemaf = None, documentClass = Document, typeMap = {}):
    if schemaf:
        schemaObj = etree.XMLSchema(file = schemaf)
    else:
        schemaObj = None

    if typeMap:
        newClass = type('XObj_Dynamic_Document', (documentClass,),
                        { 'typeMap' : typeMap})
        document = newClass(schema = schemaObj)
    else:
        document = documentClass(schema = schemaObj)

    parser = etree.XMLParser(schema = schemaObj)
    xml = etree.parse(f, parser)
    document.fromElementTree(xml)

    return document

def parse(s, schemaf = None, documentClass = Document, typeMap = {}):
    s = StringIO(s)
    return parsef(s, schemaf, documentClass = documentClass, typeMap = typeMap)

def toxml(xobj, tag, prettyPrint = True, xml_declaration = True,
          schemaf = None):
    if schemaf:
        schemaObj = etree.XMLSchema(file = schemaf)
    else:
        schemaObj = None

    gen = ElementGenerator(xobj, tag, schema = schemaObj)

    return gen.tostring(prettyPrint = prettyPrint,
                        xml_declaration = xml_declaration)
