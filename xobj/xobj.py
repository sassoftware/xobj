from lxml import etree
import xmlschema
import types

class XObject(object):

    def _setElement(self, key, val):
        expectedType = getattr(self.__class__, key, None)

        current = getattr(self, key, None)
        if current is None:
            setattr(self, key, val)
        elif current == int:
            setattr(self, key, int(val))
        elif current == expectedType:
            setattr(self, key, val)
        elif type(current) == list:
            current.append(val)
        else:
            setattr(self, key, [ current, val ])

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
        if not element.items() and not element.getchildren():
            return element.text

        # create a subclass for this type
        if xClass:
            xobj = xClass()
        else:
            localTag = nsmap(element.tag)
            NewClass = type(localTag + '_XObj_Type', (XObject,), {})
            xobj = NewClass()

        for (key, val) in element.items():
            key = nsmap(key)
            xobj._setElement(key, val)

        for childElement in element.getchildren():
            if types.BuiltinFunctionType == type(childElement.tag):
                # this catches comments. this is ugly.
                continue

            tag = nsmap(childElement.tag)
            childType = getattr(xClass, tag, None)
            child = parseElement(childElement, xClass = childType)
            xobj._setElement(tag, child)

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
