from lxml import etree

class XObject(object):

    pass

class XObjParseException(Exception):

    pass

def smiter(item):
    if hasattr(item, '__iter__'):
        return item
    else:
        return [ item ]

def parse(xml, schemaXml = None):

    def nsmap(s):
        map = { '{http://www.w3.org/2001/XMLSchema}' : 'xsd_' }
        for key, val in map.iteritems():
            if s.startswith(key):
                s = s.replace(key, val)

        return s

    def flatten(el):
        if hasattr(el, 'xsd_sequence'):
            el = el.xsd_sequence

        return el

    def parseElement(element, schemaXObj = None):
        xsdElement = None
        if schemaXObj:
            for e in smiter(schemaXObj.xsd_element):
                if e.name == element.tag:
                    xsdElement = e
                    break

            if not xsdElement:
                raise XObjParseException('element %s not found' %
                                            element.tag)

            if hasattr(xsdElement, 'xsd_complexType'):
                xsdElement = xsdElement.xsd_complexType

        if not element.items() and not element.getchildren():
            return element.text

        xobj = XObject()
        for (key, val) in element.items():
            if xsdElement:
                xsdAttribute = None
                for attr in smiter(xsdElement.xsd_attribute):
                    if attr.name == key:
                        xsdAttribute = attr
                        break

                if not xsdAttribute:
                    raise XObjParseException('attribute %s for element %s not '
                                             'found' % (key, element.tag))

                if hasattr(xsdAttribute, 'type'):
                    if xsdAttribute.type == 'xs:integer':
                        val = int(val)

            key = nsmap(key)
            xobj.__setattr__(key, val)

        for childElement in element.getchildren():
            tag = nsmap(childElement.tag)
            child = parseElement(childElement, flatten(xsdElement))

            if hasattr(xobj, tag):
                cur = xobj.__getattribute__(tag)
                if type(cur) == list:
                    cur.append(child)
                else:
                    xobj.__setattr__(tag, [ cur, child ])
            else:
                xobj.__setattr__(tag, child)

        return xobj

    if schemaXml:
        schemaXObj = parse(schemaXml)
    else:
        schemaXObj = None

    return parseElement(xml.getroot(), schemaXObj)

def parsef(f, schemaf = None):
    if schemaf:
        schemaXml = etree.parse(schemaf)
        schemaXObj = parse(schemaXml)
        schemaObj = etree.XMLSchema(schemaXml)
    else:
        schemaXml = schemaXObj = schemaObj = None

    parser = etree.XMLParser(schema = schemaObj)
    xml = etree.parse(f, parser)

    return parse(xml, schemaXml = schemaXml)
