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
import xmlschema
import types
from StringIO import StringIO

class UnknownXType(Exception):

    pass

class XType(object):

    def _isComplex(self):
        for key in self.pythonType.__dict__.iterkeys():
            if key[0] != '_':
                return True

        return False

    def __init__(self, pythonType, forceList = False):
        self.pythonType = pythonType
        self.forceList = forceList

def XTypeFromXObjectType(xObjectType):

    if (type(xObjectType) == type and
            issubclass(xObjectType, XObject)):
        return XType(xObjectType)
    elif xObjectType == int:
        return XType(XObjectInt)
    elif xObjectType == str:
        return XType(str)
    elif type(xObjectType) == list:
        assert(len(xObjectType) == 1)
        return XType(XTypeFromXObjectType(xObjectType[0]).pythonType,
                     forceList = True)

    raise UnknownXType

class XObject(object):

    _elements = []
    _attributes = set()

    def _setAttribute(self, doc, key, val):
        expectedType = getattr(self.__class__, key, None)
        if expectedType is None:
            expectedType = doc.typeMap.get(key, None)

        if expectedType:
            expectedXType = XTypeFromXObjectType(expectedType)
            if (key == 'id' or key == 'xml_id' or
                        issubclass(expectedXType.pythonType, XID)):
                doc._ids[val] = self
            elif issubclass(expectedXType.pythonType, XIDREF):
                doc._idsNeeded.append((self, key, val))
                return
            else:
                val = expectedXType.pythonType(val)
        else:
            if (key == 'id' or key == 'xml_id'):
                doc._ids[val] = self

            expectedXType = None
            val = XObjectStr(val)

        self._addAttribute(key, val, xType = expectedXType)

    def _addAttribute(self, key, val, xType = None):
        if not self._attributes:
            self._attributes = set([key])
        elif key not in self._attributes:
            self._attributes.add(key)

        self._setItem(key, val, xType)

    def _addElement(self, key, val, xType = None):
        self._setItem(key, val, xType = xType)
        if not self._elements:
            self._elements = [ key ]
        elif key not in self._elements:
            self._elements.append(key)

    def _setItem(self, key, val, xType = None):
        current = getattr(self, key, None)
        if xType and xType.forceList:
            # force the item to be a list, and use the type inside of
            # this list as the type of elements of the list
            if key not in self.__dict__:
                current = []
                setattr(self, key, current)

        if self.__dict__.get(key, None) is None:
            # This has not yet been set in the instance (because it's missing) or it's been
            # set to None (because we think we don't have this value but it's actually an idref
            # being filled in later)
            setattr(self, key, val)
        elif type(current) == list:
            current.append(val)
        else:
            setattr(self, key, [ current, val ])

    def getElementTree(self, tag, rootElement = None, nsmap = {}):

        def addns(s):
            for short, long in nsmap.iteritems():
                if short and s.startswith(short + '_'):
                    s = '{' + long + '}' + s[len(short) + 1:]

            return s

        tag = addns(tag)

        attrs = {}
        elements = {}
        for key, val in self.__dict__.iteritems():
            if key[0] != '_':
                if key in self._attributes:
                    pythonType = getattr(self.__class__, key, None)
                    if pythonType and issubclass(pythonType, XIDREF):
                        idVal = getattr(val, 'id', None)
                        if idVal is None:
                            for idKey, idType in val.__class__.__dict__.iteritems():
                                if (idKey[0] != '_' and type(idType) == type
                                                and issubclass(idType, XID)):
                                    idVal = getattr(val, idKey)

                        if idVal is None:
                            raise XObjSerializationException('No id found for element referenced by '
                                                             '%s' % key)
                        val = idVal

                    key = addns(key)
                    attrs[key] = str(val)
                else:
                    l = elements.setdefault(key, [])
                    l.append(val)

        orderedElements = []
        if self._elements:
            for name in self._elements:
                for val in elements[name]:
                    orderedElements.append((name, val))
            for name in (set(elements) - set(self._elements)):
                for val in elements[name]:
                    orderedElements.append((name, val))

        if rootElement is None:
            element = etree.Element(tag, attrs, nsmap = nsmap)
        else:
            element = etree.SubElement(rootElement, tag, attrs)

        if self.text is not None:
            element.text = self.text

        for key, val in orderedElements:
            if val is not None:
                if type(val) == list:
                    for subval in val:
                        subval.getElementTree(key, rootElement = element,
                                              nsmap = nsmap)
                else:
                    val.getElementTree(key, rootElement = element,
                                       nsmap = nsmap)

        return element

    def __init__(self, text = None):
        self.text = text

class XID(XObject):

    pass

class XIDREF(XObject):

    pass

class Document(XObject):

    nameSpaceMap = {}
    typeMap = {}

    def __init__(self):
        self._idsNeeded = []
        self._dynamicClassDict = {}
        self._ids = {}
        self.__explicitNamespaces = False
        self.__xmlNsMap = {}

    def tostring(self, nsmap = {}, prettyPrint = True, xml_declaration = True):
        for key, val in self.__dict__.iteritems():
            if key[0] == '_': continue
            if isinstance(val, XObject):
                break

        if self.__explicitNamespaces:
            map = self.__xmlNsMap.copy()
            del map[None]
        else:
            map = self.__xmlNsMap

        et = val.getElementTree(key, nsmap = map)
        xmlString = etree.tostring(et, pretty_print = prettyPrint,
                                   encoding = 'UTF-8',
                                   xml_declaration = xml_declaration)

        return xmlString

    def fromElementTree(self, xml, rootXClass = None, nameSpaceMap = {}):

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

        def parseElement(element, parentXType = None, parentXObj = None):
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
                    thisPyType = getattr(parentXType.pythonType, tag, None)

                if not thisPyType:
                    thisPyType = self.typeMap.get(tag, None)

                if thisPyType:
                    thisXType = XTypeFromXObjectType(thisPyType)

                self._dynamicClassDict[tag] = thisXType

            if thisXType:
                if text is not None and thisXType._isComplex():
                    # This type has child elements, so it's complex, so
                    # the text is meaningless.
                    text = None

                xobj = thisXType.pythonType(text)
            else:
                localTag = nsmap(element.tag)
                # create a subclass for this type
                if text is None:
                    NewClass = type(localTag + '_XObj_Type', (XObject,), {})
                else:
                    NewClass = type(localTag + '_XObj_Type', (XObjectStr,), {})
                xobj = NewClass(text)
                self._dynamicClassDict[tag] = XType(NewClass)

            # handle children
            for childElement in element.getchildren():
                if types.BuiltinFunctionType == type(childElement.tag):
                    # this catches comments. this is ugly.
                    continue
                child = parseElement(childElement, parentXType = thisXType,
                                     parentXObj = xobj)

            # handle attributes
            for (key, val) in element.items():
                key = nsmap(key)
                xobj._setAttribute(self, key, val)

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
                parentXObj._addElement(tag, xobj, thisXType)

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
            xobj._addAttribute(tag, self._ids[theId])

class XObjectInt(XObject, int):

    pass

class XObjectStr(XObject, str):

    pass

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
        schemaObj = etree.XMLSchema(etree.parse(schemaf))
    else:
        schemaObj = None

    if typeMap:
        newClass = type('XObj_Dynamic_Document', (documentClass,),
                        { 'typeMap' : typeMap})
        document = newClass()
    else:
        document = documentClass()

    parser = etree.XMLParser(schema = schemaObj)
    xml = etree.parse(f, parser)
    document.fromElementTree(xml)

    return document

def parse(s, schemaf = None, documentClass = Document, typeMap = {}):
    s = StringIO(s)
    return parsef(s, schemaf, documentClass = documentClass, typeMap = typeMap)


