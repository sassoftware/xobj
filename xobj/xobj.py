from lxml import etree
import xmlschema

class XObject(object):

    pass

class XClass(object):

    pass

class XObjParseException(Exception):

    pass

def smiter(item):
    if hasattr(item, '__iter__'):
        return item
    else:
        return [ item ]

def parse(xml, schema = None, nameSpaceMap = {}):

    def nsmap(s):
        for key, val in nameSpaceMap.iteritems():
            if s.startswith(key):
                s = s.replace(key, val)

        return s

    def parseElement(element, schema = None):
        schemaElement = None
        schemaType = None
        if schema:
            schemaElement = schema.findElement(element.tag)

            if not schemaElement:
                raise XObjParseException('element %s not found' %
                                            element.tag)

            schemaType = schemaElement.getType()

        if not element.items() and not element.getchildren():
            return element.text

        # create a subclass for this type
        NewClass = type(nsmap(element.tag) + '_XObj_Type', (XObject,), {})
        xobj = NewClass()

        for (key, val) in element.items():
            if schemaElement:
                schemaAttribute = schemaElement.findAttribute(key)

                if not schemaAttribute:
                    raise XObjParseException('attribute %s for element %s not '
                                             'found' % (key, element.tag))

                val = schemaAttribute.getType().fromString(val)

            key = nsmap(key)
            xobj.__setattr__(key, val)

        for childElement in element.getchildren():
            tag = nsmap(childElement.tag)

            child = parseElement(childElement, schemaType)

            if hasattr(xobj, tag):
                cur = xobj.__getattribute__(tag)
                if type(cur) == list:
                    cur.append(child)
                else:
                    xobj.__setattr__(tag, [ cur, child ])
            else:
                xobj.__setattr__(tag, child)

        return xobj

    return parseElement(xml.getroot(), schema)

def parsef(f, schemaf = None):
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

    return parse(xml, schema = schema)
