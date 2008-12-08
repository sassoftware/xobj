from lxml import etree
import xmlschema
import types

class UnknownXType(Exception):

    pass

class XType(object):

    def __init__(self, pythonType, forceList = False):
        self.pythonType = pythonType
        self.forceList = forceList

def XTypeFromXObjectType(xObjectType):

    if (type(xObjectType) == type and
            issubclass(xObjectType, XObject)):
        return XType(xObjectType)
    elif issubclass(xObjectType.__class__, XType):
        return XType
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

    def _setAttribute(self, key, val):
        expectedType = getattr(self.__class__, key, None)
        if expectedType:
            expectedXType = XTypeFromXObjectType(expectedType)
            val = expectedXType.pythonType(val)
        else:
            expectedXType = None
            val = XObjectStr(val)

        val._isattr = True

        self._setItem(key, val, expectedXType)

    def _isComplex(self):
        complex = False
        for key in xType.pythonType.__dict__.iterkeys():
            if key[0] != '_':
                complex = True
                break

        return False

    def _setItem(self, key, val, xType = None):
        current = getattr(self, key, None)
        if xType and xType.forceList:
            # force the item to be a list, and use the type inside of
            # this list as the type of elements of the list
            if key not in self.__dict__:
                current = []
                setattr(self, key, current)

        if key not in self.__dict__:
            # This has not yet been set in the instance.
            setattr(self, key, val)
        elif type(current) == list:
            current.append(val)
        else:
            setattr(self, key, [ current, val ])

    def getElementTree(self, tag, rootElement = None):
        attrs = {}
        elements = {}
        for key, val in self.__dict__.iteritems():
            if isinstance(val, XObject):
                if getattr(val, '_isattr', False):
                    attrs[key] = str(val)
                else:
                    elements[key] = val

        if rootElement is None:
            element = etree.Element(tag, attrs)
        else:
            element = etree.SubElement(rootElement, tag, attrs)

        if self.text is not None:
            element.text = self.text

        for key, val in elements.iteritems():
            val.getElementTree(key, rootElement = element)

        return element

    def tostring(self):
        et = self.getElementTree('top')
        return etree.tostring(et, pretty_print = True, encoding = 'UTF-8')

    def __init__(self, text):
        self.text = text

class XObjectInt(XObject, int):

    pass

class XObjectStr(XObject, str):

    pass

class XObjParseException(Exception):

    pass

def smiter(item):
    if hasattr(item, '__iter__'):
        return item
    else:
        return [ item ]

def parse(xml, rootXClass = None, nameSpaceMap = {}):

    def nsmap(s):
        for key, val in nameSpaceMap.iteritems():
            if s.startswith(key):
                s = s.replace(key, val)

        return s

    def parseElement(element, xType = None):
        # handle the text for this tag
        if element.getchildren():
            text = None
        else:
            text = element.text

        if xType:
            if text:
                if xType.isComplex():
                    text = None

            xobj = xType.pythonType(text)
        else:
            localTag = nsmap(element.tag)
            # create a subclass for this type
            if text is None:
                NewClass = type(localTag + '_XObj_Type', (XObject,), {})
            else:
                NewClass = type(localTag + '_XObj_Type', (XObjectStr,), {})
            xobj = NewClass(text)

        # handle children
        for childElement in element.getchildren():
            if types.BuiltinFunctionType == type(childElement.tag):
                # this catches comments. this is ugly.
                continue

            tag = nsmap(childElement.tag)

            childXType = None
            if xType:
                childType = getattr(xType.pythonType, tag, None)
                if childType:
                    childXType = XTypeFromXObjectType(childType)

            child = parseElement(childElement, xType = childXType)
            xobj._setItem(tag, child, childXType)

        # handle attributes
        for (key, val) in element.items():
            key = nsmap(key)
            xobj._setAttribute(key, val)

        # anything which is the same as in the class wasn't set in XML, so
        # set it to None
        for key, val in xobj.__class__.__dict__.items():
            if key[0] == '_': continue
            if getattr(xobj, key) == val:
                setattr(xobj, key, None)

        return xobj

    if rootXClass:
        rootXType = XTypeFromXObjectType(rootXClass)
    else:
        rootXType = None

    return parseElement(xml.getroot(), xType = rootXType)

def parsef(f, rootXClass = None, nameSpaceMap = {}):
    schemaf = None
    if schemaf:
        schemaXml = etree.parse(schemaf)
        schemaXObj = parse(schemaXml, nameSpaceMap = 
                           { '{http://www.w3.org/2001/XMLSchema}' : 'xsd_' })
        schema = xmlschema.Schema(schemaXObj)
        schemaObj = etree.XMLSchema(schemaXml)
    else:
        schema = schemaXml = schemaXObj = schemaObj = None

    parser = etree.XMLParser(schema = schemaObj)
    xml = etree.parse(f, parser)

    return parse(xml, rootXClass = rootXClass, nameSpaceMap = nameSpaceMap)
