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

def smiter(item):
    if hasattr(item, '__iter__'):
        return item
    else:
        return [ item ]

class AbstractSchemaMember(object):

    pass

class SchemaType(AbstractSchemaMember):

    @staticmethod
    def fromString(x):
        return x

class EmptyType(SchemaType):

    pass

class StringType(SchemaType):

    pass

class IntegerType(SchemaType):

    @staticmethod
    def fromString(x):
        return int(x)

class SequenceType(AbstractSchemaMember):

    def findElement(self, name):
        for x in self.elements:
            if x.name == name:
                return x

        return None

    def __init__(self, xobjSeq):
        self.elements = [ SchemaElement(x)
                                for x in smiter(xobjSeq.xsd_element) ]

class Attribute(AbstractSchemaMember):

    def getType(self):
        return self.xtype

    def __init__(self, name, xtype):
        self.name = name
        self.xtype = xtype

class SchemaElement(AbstractSchemaMember):

    def getType(self):
        return self.xtype

    def findAttribute(self, name):
        return self.attributes.get(name, None)

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


class Schema(SequenceType):

    def __init__(self, xobjSchema):
        # xobjSchema is a schema; it's children are global

        # XXX parse global types
        # XXX parse global attributes
        SequenceType.__init__(self, xobjSchema)


