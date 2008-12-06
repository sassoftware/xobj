def smiter(item):
    if hasattr(item, '__iter__'):
        return item
    else:
        return [ item ]

class AbstractSchemaMember(object):

    pass

class SchemaType(AbstractSchemaMember):

    pass

class EmptyType(SchemaType):

    pass

class StringType(SchemaType):

    pass

class IntegerType(SchemaType):

    pass

class SequenceType(AbstractSchemaMember):

    def __init__(self, xobjSeq):
        self.elements = [ SchemaElement(x)
                                for x in smiter(xobjSeq.xsd_element) ]

class Attribute(AbstractSchemaMember):

    def __init__(self, name, xtype):
        self.name = name
        self.xtype = xtype

class SchemaElement(AbstractSchemaMember):

    def __init__(self, xobjElement):

        def findSimpleType(typeStr):
            if typeStr == 'xs:integer':
                return IntegerType
            elif typeStr == 'xs:string':
                return StringType

            return None

        self.name = xobjElement.name
        self.xtype = None
        self.attributes = {}
        attributes = None

        # is this a type?
        if hasattr(xobjElement, 'xsd_complexType'):
            xobjType = xobjElement.xsd_complexType
            attributes = getattr(xobjType, 'xsd_attribute', None)
            if hasattr(xobjType, 'xsd_sequence'):
                self.xtype = SequenceType(xobjType.xsd_sequence)
            else:
                self.xtype = EmptyType()
        elif hasattr(xobjElement, 'type'):
            self.xtype = findSimpleType(xobjElement.type)
        else:
            assert(0)


        if attributes:
            for attr in smiter(attributes):
                self.attributes[attr.name] = Attribute(
                                        attr.name, findSimpleType(attr.type))


class Schema(object):

    def __init__(self, xobjSchema):
        # xobjSchema is a schema; it's children are global

        # XXX parse global types
        # XXX parse global attributes
        self.elements = []
        for element in smiter(xobjSchema.xsd_element):
            self.elements.append(SchemaElement(element))


