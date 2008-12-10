from lxml import etree
import xmlschema
import types

class UnknownXType(Exception):

    pass

class XType(object):

    def _isComplex(self):
        complex = False
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

    _elementOrder = None

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

    def _addElement(self, key, val, xType = None):
        self._setItem(key, val, xType = xType)
        if self._elementOrder is None:
            self._elementOrder = [ key ]
        elif key not in self._elementOrder:
            self._elementOrder.append(key)

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

    def getElementTree(self, tag, rootElement = None, nsmap = {},
                       rewriteMap = {}):
        def addns(s):
            for key, val in rewriteMap.iteritems():
                if s.startswith(key + '_'):
                    s = s.replace(key + '_', val)

            return s

        attrs = {}
        elements = {}
        for key, val in self.__dict__.iteritems():
            if key[0] != '_':
                if getattr(val, '_isattr', False):
                    key = addns(key)
                    attrs[key] = str(val)
                else:
                    l = elements.setdefault(key, [])
                    l.append(val)

        orderedElements = []
        if self._elementOrder:
            for name in self._elementOrder:
                for val in elements[name]:
                    orderedElements.append((name, val))
            for name in (set(elements) - set(self._elementOrder)):
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
                key = addns(key)
                if type(val) == list:
                    for subval in val:
                        subval.getElementTree(key, rootElement = element,
                                              rewriteMap = rewriteMap)
                else:
                    val.getElementTree(key, rootElement = element,
                                       rewriteMap = rewriteMap)

        return element

    def __init__(self, text = None):
        self.text = text

class RootXObject(XObject):

    def tostring(self, nsmap = {}):
        foo = dict(self._nsmap)
        foo['ovf'] = 'http://schemas.dmtf.org/ovf/envelope/1'
        for key, val in self.__dict__.iteritems():
            if isinstance(val, XObject):
                break

        et = val.getElementTree(key, nsmap = foo,
                                 rewriteMap = nsmap)
        return etree.tostring(et, pretty_print = True, encoding = 'UTF-8')

    def fromElementTree(self, xml, rootXClass = None, nameSpaceMap = {}):

        def nsmap(s):
            for key, val in nameSpaceMap.iteritems():
                if s.startswith(key):
                    s = s.replace(key, val + '_')

            return s

        def parseElement(element, parentXType = None, parentXObj = None):
            # handle the text for this tag
            if element.getchildren():
                text = None
            else:
                text = element.text

            tag = nsmap(element.tag)

            if parentXObj is None:
                parentXObj = self
                parentXType = XTypeFromXObjectType(self.__class__)

            thisXType = None
            if parentXType:
                thisPyType = getattr(parentXType.pythonType, tag, None)
                if thisPyType:
                    thisXType = XTypeFromXObjectType(thisPyType)

            if element.getchildren():
                # It's a complex type, so the text is meaningless.
                text = None

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
                xobj._setAttribute(key, val)

            # anything which is the same as in the class wasn't set in XML, so
            # set it to None
            for key, val in xobj.__class__.__dict__.items():
                if key[0] == '_': continue
                if getattr(xobj, key) == val:
                    setattr(xobj, key, None)

            if parentXObj is not None:
                parentXObj._addElement(tag, xobj, thisXType)

            return xobj

        rootElement = xml.getroot()

        parseElement(rootElement)
        self._nsmap = xml.getroot().nsmap

class XObjectInt(XObject, int):

    pass

class XObjectStr(XObject, str):

    pass

class XObjParseException(Exception):

    pass

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

    if rootXClass is None:
        rootXClass = RootXObject

    rootObj = rootXClass()

    parser = etree.XMLParser(schema = schemaObj)
    xml = etree.parse(f, parser)
    rootObj.fromElementTree(xml, nameSpaceMap = nameSpaceMap)

    return rootObj
