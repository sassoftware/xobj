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

        self._setItem(key, val, expectedXType)

    def _setItem(self, key, val, xType = None):
        current = getattr(self, key, None)
        if xType and xType.forceList:
            # force the item to be a list, and use the type inside of
            # this list as the type of elements of the list
            if id(current) == id(xType):
                current = []
                setattr(self, key, current)

        if key not in self.__dict__:
            # This has not yet been set in the instance.
            setattr(self, key, val)
        elif type(current) == list:
            current.append(val)
        else:
            setattr(self, key, [ current, val ])

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

    def parseElement(element, xClass = None):
        # handle the text for this tag
        if xClass:
            xobj = xClass(element.text)
        else:
            localTag = nsmap(element.tag)
            # create a subclass for this type
            NewClass = type(localTag + '_XObj_Type', (XObjectStr,), {})
            xobj = NewClass(element.text)

        # handle children
        for childElement in element.getchildren():
            if types.BuiltinFunctionType == type(childElement.tag):
                # this catches comments. this is ugly.
                continue

            tag = nsmap(childElement.tag)
            childType = getattr(xClass, tag, None)
            if childType:
                #import epdb;epdb.st()
                childXType = XTypeFromXObjectType(childType)
            else:
                childXType = None

            child = parseElement(childElement, xClass = childType)
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

    return parseElement(xml.getroot(), xClass = rootXClass)

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
