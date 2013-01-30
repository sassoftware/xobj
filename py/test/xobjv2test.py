#!/usr/bin/python
#
# Copyright (c) SAS Institute Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


import datetime
from dateutil import tz
import types

import testsuite
testsuite.setup()
from lxml import etree

from xobj import xobj2
from StringIO import StringIO

from xobjtest import TestCase, _xml

class XobjV2Test(TestCase):

    def testParse1(self):
        class Item(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes = dict(id=xobj2.XID, type=xobj2.XObj, count=int,
                    isBig=bool, ),
                elements = [
                    xobj2.Field('repeated', bool),
                    xobj2.Field('value', unicode),
                    xobj2.Field('number', long),
                ],
            )
        class Root(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'root',
                elements = [ xobj2.Field('item', [ Item ]) ])
        doc = xobj2.Document(rootNodes = [ Root ])
        string = '''\
<root>
    <item id="id-a" type="type-a" count="1" isBig="true">
        <repeated>true</repeated>
        <value>a1</value>
        <number>1000</number>
    </item>
    <item id="id-b" type="type-b" count="2" isBig="false">
        <repeated>false</repeated>
        <value>b1</value>
        <number>2000</number>
    </item>
</root>'''
        doc.parse(string)
        obj = doc.root
        self.failUnlessEqual([ x.id for x in obj.item ],
            [ 'id-a', 'id-b' ])
        self.failUnlessEqual([ x.type for x in obj.item ],
            [ 'type-a', 'type-b' ])
        self.failUnlessEqual([ x.count for x in obj.item ],
            [ 1, 2 ])
        self.failUnlessEqual([ x.value for x in obj.item ],
            [ 'a1', 'b1' ])
        self.failUnlessEqual([ x.number for x in obj.item ],
            [ 1000, 2000 ])
        self.failUnlessEqual([ x.repeated for x in obj.item ],
            [ True, False ])
        return doc, string

    def testSerialize1(self):
        obj, xmlstring = self.testParse1()
        xml = obj.toxml()
        self.assertXmlEqual(xml, xmlstring)

    def testSerializeDictionary(self):
        # Only one non-null item, to make sure we don't have ordering issues
        d = dict(a=1, c=None)
        doc = xobj2.Document(root=d, rootName="blabbedy")
        xml = doc.toxml(xml_declaration=False, prettyPrint=False)
        self.failUnlessEqual(xml, "<blabbedy><a>1</a></blabbedy>")

        # more than one item
        d = dict(a=1, b=2, c=None)
        doc = xobj2.Document(root=d, rootName="blabbedy")
        xml = doc.toxml(xml_declaration=False, prettyPrint=False)

        class Blabbedy(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'blabbedy',
            )

        document = xobj2.Document.fromxml(xml, rootNodes=[Blabbedy])
        self.failUnlessEqual(document.root.a, '1')
        self.failUnlessEqual(document.root.b, '2')

    def failUnlessStartsWith(self, obj, prefix):
        self.failUnless(obj.startswith(prefix), obj)

    def testSimpleParse(self):
        xml = _xml('simple-V2', """
<top attr1="anattr" attr2="another">
    <!-- comment -->
    <prop>something</prop>
    <subelement subattr="2">
        <subsub>1</subsub>
    </subelement>
</top>""", asFile = True)
        doc = xobj2.Document.fromxml(xml)
        self.assertEqual(doc.root.__class__.__name__, 'top_XObj_Type')
        self.assertEqual(doc.root.attr1, 'anattr')
        self.assertEqual(doc.root.attr2, 'another')
        self.assertEqual(doc.root.prop, 'something')
        self.assertEqual(doc.root.subelement.subattr, '2')
        self.assertEqual(doc.root.subelement.__class__.__name__,
                         'subelement_XObj_Type')
        self.failUnlessStartsWith(repr(doc), '<xobj.xobj2.Document object')
        self.failUnlessStartsWith(repr(doc.root), '<xobj.xobj2.top_XObj_Type object')
        self.failUnlessStartsWith(repr(doc.root.subelement),
                                    '<xobj.xobj2.subelement_XObj_Type object')
        self.assertEqual(repr(doc.root.attr1), "'anattr'")

        # ---

        class SubelementClass(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes=dict(subattr=int))

        class TopClass(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [
                    xobj2.Field('subelement', SubelementClass),
                    xobj2.Field('unused', str),
                    xobj2.Field('attr1', str),
                ])

        doc = xobj2.Document(rootNodes = [ TopClass ])

        o = doc.parse(xml)
        self.assertEqual(o.root.subelement.subattr, 2)
        self.assertEqual(o.root.unused, None)

        # ---

        class SubelementClass(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes=dict(subattr=int),
                elements = [ xobj2.Field('subsub', [ int ]) ])

        class TopClass(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [
                    xobj2.Field('subelement', SubelementClass),
                    xobj2.Field('unused', str),
                    xobj2.Field('attr1', str),
                    xobj2.Field('prop', str),
                ])

        o = xobj2.Document.fromxml(xml, rootNodes=[TopClass])
        self.assertEqual(o.root.subelement.subattr, 2 )
        self.assertEqual(o.root.subelement.subsub, [ 1 ] )
        self.assertEqual(o.root.prop, 'something')

        # ---

        class TopClass(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [
                    xobj2.Field('subelement', [ SubelementClass ]),
                    xobj2.Field('unused', str),
                    xobj2.Field('attr1', str),
                    xobj2.Field('prop', [ str ]),
                ])

        o = xobj2.Document.fromxml(xml, rootNodes=[TopClass])
        self.assertEqual(o.root.subelement[0].subattr, 2 )
        self.assertEqual(o.root.subelement[0].subsub, [ 1 ] )
        self.assertEqual(o.root.prop, [ 'something' ])

    def testComplexParse(self):
        xmlText = _xml('complex-V2', """\
<?xml version='1.0' encoding='UTF-8'?>
<top>
  <prop>
    <subprop subattr="1">asdf</subprop>
    <subprop subattr="2">fdsa</subprop>
  </prop>
  <simple>simple</simple>
</top>""")
        xml = StringIO(xmlText)
        o = xobj2.Document.fromxml(xml)

        # ---

        self.assertXMLEquals(o.toxml(), xmlText)

        # ---

        self.assertEqual(o.root.__class__.__name__, 'top_XObj_Type')
        self.assertEqual(type(o.root.prop.subprop), types.ListType)
        self.assertEqual(o.root.prop.subprop, ['asdf', 'fdsa'])
        asdf = o.root.prop.subprop[0]
        self.assertEqual(asdf.__class__.__name__, 'subprop_XObj_Type')
        self.assertEqual(o.root.prop.__class__.__name__,
                         'prop_XObj_Type')
        for i in range(2):
            self.assertEqual(o.root.prop.subprop[i].__class__.__name__,
                             'subprop_XObj_Type')
        assert(o.root.prop.subprop[0].__class__ ==
               o.root.prop.subprop[1].__class__)

        # ---

        class SubpropClass(object):
            __slots__ = [ 'subattr', 'unused', ]
            _xobjMeta = xobj2.XObjMetadata(
                attributes = dict(subattr=int, unused=str))

        class PropClass(object):
            _xobjMeta = xobj2.XObjMetadata(
                elements = [
                    xobj2.Field('subprop', [ SubpropClass ])
                ],
            )
            subprop = [ SubpropClass ]

        class SimpleClass(xobj2.XObj):
            pass

        class TopClass(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [
                    xobj2.Field('unused', str),
                    xobj2.Field('prop', PropClass),
                    xobj2.Field('simple', [ SimpleClass ]),
                ],
            )

        o = xobj2.Document.fromxml(xml, rootNodes = [ TopClass ])
        self.assertEqual(o.root.prop.subprop[1].subattr, 2)
        self.assertEqual(o.root.unused, None)
        self.assertEqual(o.root.prop.subprop[0].unused, None)
        self.assertEqual(o.root.simple[0], 'simple')

        # ---

        # asdf/fdsa have been dropped becuase SubpropClass has slots
        # that don't include _xobjText
        # the complex class PropClass
        xmlOutText = """\
<?xml version='1.0' encoding='UTF-8'?>
<top>
  <prop>
    <subprop subattr="1"/>
    <subprop subattr="2"/>
  </prop>
  <simple>simple</simple>
</top>"""
        self.assertXMLEquals(o.toxml(), xmlOutText)

    def testComplexListStrGen(self):
        """
        Test generating XML from a list of strings.
        """

        class Collection(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'collection',
                elements = [ xobj2.Field('data', [str]) ])

        collection = Collection()
        collection.data = [ 'a', 'b', 'c', ]

        document = xobj2.Document()
        document.root = collection

        xml = document.toxml()
        doc = xobj2.Document.fromxml(xml, rootNodes = [ Collection ] )
        self.failUnlessEqual(collection.data, doc.root.data)
        self.failUnlessEqual(doc.rootName, 'collection')

    def testComplexListObjGen(self):
        """
        Test generating XML from lists of objects.
        """

        class Basic(object):
            _xobjMeta = xobj2.XObjMetadata(attributes = [ 'foo' ])
        class BasicCollection(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'collection',
                elements = [ xobj2.Field('data', [ Basic ]) ])

        basic = Basic()
        basic.foo = 'a'

        collection = BasicCollection()
        collection.data = [ basic, ]

        doc = xobj2.Document(root=collection)
        xml = doc.toxml()

        doc = xobj2.Document.fromxml(xml, rootNodes = [ BasicCollection ])
        self.failUnlessEqual(basic.foo, doc.root.data[0].foo)

    def testNamespaces(self):
        xmlString = _xml('namespaces-V2', """\
<top xmlns="http://this" xmlns:other="http://other/other"
 xmlns:other2="http://other/other2">
  <local/>
  <other:tag other:val="1"/>
  <other2:tag val="2"/>
</top>""")
        o = xobj2.Document.fromxml(xmlString)
        assert(o.root.other_tag.other_val == '1')
        assert(o.root.other2_tag.val == '2')
        self.assertXmlEqual(o.toxml(xml_declaration = False), xmlString)

        o = xobj2.Document()
        o.nameSpaceMap = { 'other3' : 'http://other/other2' }

        o.parse(xmlString)
        assert(o.root.other_tag.other_val == '1')
        assert(o.root.other3_tag.val == '2')
        newXmlString = xmlString.replace("other2:", "other3:")
        newXmlString = newXmlString.replace(":other2", ":other3")
        self.assertXmlEqual(o.toxml(xml_declaration = False), newXmlString)

    def testSchemaValidation(self):
        s = (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">\n'
            '   <xs:element name="top">\n'
            '    <xs:complexType>\n'
            '      <xs:sequence>\n'
            '        <xs:element name="prop" type="xs:string"/>\n'
            '        <xs:element name="subelement">\n'
            '          <xs:complexType>\n'
            '          <xs:attribute name="subattr" type="xs:integer"/>\n'
            '          </xs:complexType>\n'
            '        </xs:element>\n'
            '      </xs:sequence>\n'
            '      <xs:attribute name="attr" type="xs:string"/>\n'
            '    </xs:complexType>\n'
            '  </xs:element>\n'
            '</xs:schema>\n')
        schema = StringIO(s)

        s = (
            '<top attr="anattr">\n'
            '  <prop>something</prop>\n'
            '  <subelement subattr="2"/>\n'
            '</top>\n')
        xml = StringIO(s)
        d = xobj2.Document.fromxml(xml, schemaf = schema)
        s2 = d.toxml(xml_declaration = False)
        self.failUnlessEqual(s, s2)
        d.root.unknown = 'foo'
        self.assertRaises(xobj2.DocumentInvalid, d.toxml)
        d.schema = schema
        self.assertRaises(xobj2.DocumentInvalid, d.toxml)

        xml = StringIO(s.replace('prop', 'prop2'))

        d.schema = None
        d.parse(xml)

        d.schema = schema
        self.assertRaises(etree.XMLSyntaxError, d.parse, xml)

    def testId(self):
        s = _xml('id1-V2',
            '<top>\n'
            '  <ref other="theid"/>\n'
            '  <item id="theid" val="value"/>\n'
            '</top>\n')

        class Ref(xobj2.XObj):
            _xobjMeta = xobj2.XObjMetadata(
                attributes = dict(other = xobj2.XIDREF))

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [ xobj2.Field('ref', Ref) ])

        d = xobj2.Document.fromxml(s, rootNodes = [ Top ])
        self.failUnlessEqual(d.root.ref.other,  d.root.item)
        s2 = d.toxml(xml_declaration = False)
        self.assertXMLEquals(s, s2)

        # now test if the id is called something else
        s = _xml('id2',
            '<top>\n'
            '  <item anid="theid" val="value"/>\n'
            '  <ref other="theid"/>\n'
            '</top>\n')
        xml = StringIO(s)
        e = self.failUnlessRaises(xobj2.XObjIdNotFound,
            xobj2.Document.fromxml, xml, rootNodes = [ Top ])
        self.failUnlessEqual(str(e), "XML ID 'theid' not found in document")

        class Item(xobj2.XObj):
            _xobjMeta = xobj2.XObjMetadata(attributes = dict(anid=xobj2.XID))
        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [
                    xobj2.Field('item', Item),
                    xobj2.Field('ref', Ref),
                ])

        d = xobj2.Document.fromxml(xml, rootNodes = [ Top ])
        assert(d.root.ref.other == d.root.item)
        s2 = d.toxml(xml_declaration = False)
        self.assertXMLEquals(s2, s)

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [
                    xobj2.Field('item', Item),
                    xobj2.Field('ref', Ref),
                ])

        # test outputing an idref w/o a corresponding id
        t = Top()
        t.item = Item()
        t.item.anid = 'foo'
        t.ref = Ref()
        t.ref.other = Item()
        t.ref.other.anid = 'bar'

        d = xobj2.Document()
        d.root = t

        e = self.failUnlessRaises(xobj2.UnmatchedIdRef,
            d.toxml, xml_declaration = False)
        self.failUnlessEqual(str(e),
            'Unmatched idref values during XML creation for id(s): bar')

        t.ref.other = t.item
        s = d.toxml(xml_declaration = False)
        self.assertXMLEquals(s, '<top>\n'
                             '  <item anid="foo"/>\n'
                             '  <ref other="foo"/>\n'
                             '</top>\n')

        # and test if the id isn't defined properly
        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                attributes = dict(ref=xobj2.XIDREF))

        class Ref(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes = dict(blah=str))

        d = xobj2.Document()
        d.root = Top()
        d.root.ref = Ref()
        e = self.failUnlessRaises(xobj2.XObjSerializationException,
            d.toxml)
        self.assertEquals(str(e), 'No id found for element referenced by ref')

        class Ref(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes = dict(blah=xobj2.XID))
        d.root.ref = Ref()
        e = self.failUnlessRaises(xobj2.XObjSerializationException,
            d.toxml)
        self.assertEquals(str(e),
            'Empty ID field blah for element referenced by ref')


    def testIdInNamespace(self):
        s = _xml('id-in-ns1-V2',
            '<ns:top xmlns:ns="http://somens.xsd">\n'
            '  <ns:ref ns:other="theid"/>\n'
            '  <ns:item ns:id="theid" ns:val="value"/>\n'
            '</ns:top>\n')
        xml = StringIO(s)

        class Ref(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes=dict(ns_other = xobj2.XIDREF))

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'ns_top',
                elements = [ xobj2.Field('ns_ref', Ref) ])

        d = xobj2.Document(rootNodes = [ Top ])
        d.nameSpaceMap.update(ns="http://somens.xsd")
        d = xobj2.Document.fromxml(xml, rootNodes = [ Top ])
        self.failUnlessEqual(d.root.ns_ref.ns_other, d.root.ns_item)
        s2 = d.toxml(xml_declaration = False)
        self.assertXMLEquals(s, s2)

    def testExplicitNamespaces(self):
        s = _xml('explicitns',
            '<top xmlns="http://somens.xsd" xmlns:ns="http://somens.xsd">\n'
            '  <element ns:attr="foo"/>\n'
            '</top>\n'
            )

        d = xobj2.Document.fromxml(s)
        self.failUnlessEqual(d.rootName, 'ns_top')
        self.failUnlessEqual(d.root.ns_element.ns_attr, 'foo')
        s2 = d.toxml(xml_declaration = False)

        expecteds2 = (
            '<ns:top xmlns:ns="http://somens.xsd">\n'
            '  <ns:element ns:attr="foo"/>\n'
            '</ns:top>\n'
            )
        self.failUnlessEqual(s2, expecteds2)

    def testObjectType(self):
        s ='<top attr="foo"/>'

        d = xobj2.Document.fromxml(s)
        self.failUnlessEqual(d.root._xobjMeta.tag, 'top')
        self.failUnlessEqual(d.root.attr, 'foo')

    def testObjectTypeBool(self):
        class Top(object):
            __slots__ = [ 'val' ]
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [ xobj2.Field('val', bool) ])

        t = Top()
        t.val = True

        s = "<top><val>true</val></top>"
        d = xobj2.Document(root=t)
        self.assertXMLEquals(d.toxml(xml_declaration = False), s)

        d = xobj2.Document.fromxml(s, rootNodes = [ Top ])
        self.assertTrue(d.root.val)

    def testEmptyList(self):
        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [ xobj2.Field('l', [ int ]) ])

        d = xobj2.Document.fromxml("<top/>", rootNodes = [ Top ])
        self.failUnlessEqual(d.root.l, [])

    def testUnion(self):
        class TypeA(object):
            _xobjMeta = xobj2.XObjMetadata(tag='typea',
                attributes=dict(vala=int))

        class TypeB(object):
            _xobjMeta = xobj2.XObjMetadata(tag='typeb',
                attributes=dict(valb=int))

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [
                    xobj2.Field('items', [ TypeA, TypeB, ]) ])

        s = _xml('union',
                 '<top>\n'
                 '  <typea vala="1"/>\n'
                 '  <typeb valb="2"/>\n'
                 '  <typea vala="3"/>\n'
                 '  <typeb valb="4"/>\n'
                 '  <typea vala="5"/>\n'
                 '</top>\n')

        d = xobj2.Document.fromxml(s, rootNodes = [ Top ])
        self.failUnlessEqual(d.root.items[0].vala, 1)
        self.failUnlessEqual(d.root.items[1].valb, 2)
        self.failUnlessEqual(d.root.items[2].vala, 3)
        self.failUnlessEqual(d.root.items[3].valb, 4)
        self.failUnlessEqual(d.root.items[4].vala, 5)
        self.assertXMLEquals(d.toxml(xml_declaration = False), s)

        d = xobj2.Document.fromxml('<top/>', rootNodes = [ Top ])
        self.failUnlessEqual(d.root.items, [])

    def testUnionMetadataValidation(self):
        class NoTag(object):
            _xobjMeta = xobj2.XObjMetadata()
        class WithTag(object):
            _xobjMeta = xobj2.XObjMetadata(tag='foo')
        class NoMeta(object):
            pass

        e = self.failUnlessRaises(TypeError, xobj2.XObjMetadata,
            elements=[ xobj2.Field('union', [ str, int, ])])
        self.failUnlessEqual(str(e), "Union types should have metadata")

        e = self.failUnlessRaises(TypeError, xobj2.XObjMetadata,
            elements=[ xobj2.Field('union', [ str, NoMeta, ])])
        self.failUnlessEqual(str(e), "Union types should have metadata")

        e = self.failUnlessRaises(TypeError, xobj2.XObjMetadata,
            elements=[ xobj2.Field('union', [ WithTag, NoMeta, ])])
        self.failUnlessEqual(str(e), "Union types should have metadata")

        e = self.failUnlessRaises(TypeError, xobj2.XObjMetadata,
            elements=[ xobj2.Field('union', [ WithTag, str, ])])
        self.failUnlessEqual(str(e), "Union types should have metadata")

        e = self.failUnlessRaises(TypeError, xobj2.XObjMetadata,
            elements=[ xobj2.Field('union', [ WithTag, WithTag, ])])
        self.failUnlessEqual(str(e), "Duplicate tags in union type")

        e = self.failUnlessRaises(TypeError, xobj2.XObjMetadata,
            elements=[ xobj2.Field('union', [ WithTag, NoTag, ])])
        self.failUnlessEqual(str(e), "Union types should specify a tag")

    def testDocumentExceptions(self):
        class NoTag(object):
            _xobjMeta = xobj2.XObjMetadata()
        class NoMeta(object):
            pass

        e = self.failUnlessRaises(TypeError, xobj2.Document, rootNodes = NoMeta)
        self.failUnlessEqual(str(e), "Root node classes should have metadata")

        xobj2.Document(rootNodes=dict(root=NoMeta))

        e = self.failUnlessRaises(TypeError, xobj2.Document, rootNodes = NoTag)
        self.failUnlessEqual(str(e), "Root node classes should have a tag")

        xobj2.Document(rootNodes=dict(root=NoTag))

        e = self.failUnlessRaises(TypeError, xobj2.Document,
            rootNodes = { object: NoTag })
        self.failUnlessEqual(str(e), "Expected string for tag type")

    def testDocumentPrimitiveTypes(self):
        xml = "<int>1</int>\n"
        d = xobj2.Document.fromxml(xml, rootNodes=dict(int=int))
        self.failUnlessEqual(d.rootName, 'int')
        self.failUnlessEqual(type(d.root), int)
        self.failUnlessEqual(d.toxml(xml_declaration=False), xml)

        # Add a basic type to the root. Should work.
        d = xobj2.Document(root=1, rootName='int')
        self.failUnlessEqual(d.toxml(xml_declaration=False), xml)

    def testObjectTree(self):
        class Top(object):
            pass

        class Middle(object):
            _xobjMeta = xobj2.XObjMetadata(
                elements = [ xobj2.Field('tag', int) ],
            )

            def foo(self):
                pass

        t = Top()
        t.prop = 'abc'
        t.middle = Middle()
        t.middle.tag = 123
        t.bottom = None

        d = xobj2.Document()
        d.root = t
        d.rootName = 'top'

        s = d.toxml(t, xml_declaration = False)
        self.assertXMLEquals(s, '<top>\n'
                             '  <middle>\n'
                             '    <tag>123</tag>\n'
                             '  </middle>\n'
                             '  <prop>abc</prop>\n'
                             '</top>\n')

        d.parse(s)

    def testCleanCreation(self):
        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes = [ 'foo', 'bar', ],
                elements = [ "first", "second", "third" ])

        t = Top()
        t.first = "1"
        t.second = "2"
        t.foo = "f"

        d = xobj2.Document()
        d.root = t
        d.rootName = 'top'

        self.assertXMLEquals(d.toxml(t, xml_declaration = False),
            '<top foo="f">\n'
            '  <first>1</first>\n'
            '  <second>2</second>\n'
            '</top>\n')

        t.unknown = "unknown"
        assert("<unknown>unknown</unknown>" in
                    d.toxml(xml_declaration = False))

    def testIntElement(self):
        xml = _xml('intelement', '<top><anint>5</anint></top>')
        doc = xobj2.Document.fromxml(xml)
        self.failUnlessEqual(doc.root.anint, '5')

    def testMetadataAttributeTypes(self):
        class Bar:
            _xobjMeta = xobj2.XObjMetadata(
                        attributes = {
                            'ref' : xobj2.XIDREF } )

        class Top:
            _xobjMeta = xobj2.XObjMetadata(
                        tag = 'top',
                        attributes = { 'val' : int },
                        elements = [ xobj2.Field('bar', Bar) ])

        s = ('<top id="foo" val="5">\n'
             '  <bar ref="foo"/>\n'
             '</top>\n')

        d = xobj2.Document.fromxml(s, rootNodes = [ Top ])
        self.failUnlessEqual(d.rootName, 'top')
        self.failUnlessEqual(d.root.val, 5)
        self.failUnlessEqual(d.root, d.root.bar.ref)

        s2 = d.toxml(xml_declaration = False)
        self.failUnlessEqual(s, s2)

    def testSimpleMultiParse(self):
        """
        Test parsing multiple xml documents with one set of classes.
        """

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(tag='top',
                elements=[xobj2.Field('foo', str)])

        d = xobj2.Document()

        topA = Top()
        topA.foo = 'A'
        d.root = topA
        xmlA = d.toxml()

        topB = Top()
        topB.foo = 'B'
        d.root = topB
        xmlB = d.toxml()

        docAroot = d.parse(xmlA).root
        docBroot = d.parse(xmlB).root

        self.failUnlessEqual(docAroot.foo, 'A')
        self.failUnlessEqual(docBroot.foo, 'B')

    def testComplexMultiParse(self):
        """
        Test parsing multiple xml documents with one set of classes using more
        complex types.
        """

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'top',
                elements = [ xobj2.Field('foo', [ str ]) ])

        class Document(xobj2.Document):
            def __init__(self, *args, **kwargs):
                kwargs['rootNodes'] = [ Top ]
                xobj2.Document.__init__(self, *args, **kwargs)

        xmlTextA = _xml('complex-multi-V2',
                       '<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top>\n'
                       '  <foo>a</foo>\n'
                       '  <foo>b</foo>\n'
                       '</top>\n')

        docA = Document.fromxml(xmlTextA)

        xmlTextB = _xml('complex-multi-V2',
                       '<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top>\n'
                       '  <foo>A</foo>\n'
                       '  <foo>B</foo>\n'
                       '</top>\n')

        xmlB = StringIO(xmlTextB)
        docB = Document.fromxml(xmlB)

        self.failUnlessEqual([ x for x in docA.root.foo ], [ 'a', 'b' ])
        self.failUnlessEqual([ x for x in docB.root.foo ], [ 'A', 'B' ])

    def testNoneSingleElementSerialization(self):
        """
        Test serializing a single element set to None.
        """

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(elements=['foo'])

        top = Top()
        top.foo = None

        doc = xobj2.Document()
        doc.root = top
        doc.rootName = 'top'

        xml = doc.toxml()
        expectedXml = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top/>\n')
        self.failUnlessEqual(xml, expectedXml)

        Top._xobjMeta.tag = 'top'
        doc = xobj2.Document.fromxml(xml, rootNodes = [ Top ])
        self.failUnlessEqual(top.foo, doc.root.foo)

    def testNoneMultiElementSerialization(self):
        """
        Test serializing multiple elements that are set to None.
        """

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(elements = [ 'foo', 'bar' ])

        top = Top()
        top.foo = None
        top.bar = ''

        d = xobj2.Document()
        d.root = top
        d.rootName = 'top'

        xml = d.toxml()
        expectedXml = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top>\n'
                       '  <bar></bar>\n'
                       '</top>\n')
        self.failUnlessEqual(xml, expectedXml)

        Top._xobjMeta.tag = 'top'
        doc = xobj2.Document.fromxml(xml, rootNodes = [ Top ])
        self.failUnlessEqual(top.foo, doc.root.foo)
        self.failUnlessEqual(top.bar, doc.root.bar)

    def testNoneSingleAttributeSerialization(self):
        """
        Test serializing a single attribute that is set to None.
        """

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(attributes=['foo'])

        top = Top()
        top.foo = None

        doc = xobj2.Document()
        doc.root = top
        doc.rootName = 'top'

        xml = doc.toxml()
        expectedXml = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top/>\n')
        self.failUnlessEqual(xml, expectedXml)

        Top._xobjMeta.tag = 'top'
        doc = xobj2.Document.fromxml(xml, rootNodes = [ Top ])
        self.failUnlessEqual(top.foo, doc.root.foo)

    def testNoneMultiAttributeSerialization(self):
        """
        Test serializing multiple attributes that are set to None.
        """

        class Top(object):
            _xobjMeta = xobj2.XObjMetadata(attributes=['foo', 'bar'])

        top = Top()
        top.foo = None
        top.bar = ''

        doc = xobj2.Document()
        doc.root = top
        doc.rootName = 'top'

        xml = doc.toxml()
        expectedXml = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top bar=""/>\n')
        self.failUnlessEqual(xml, expectedXml)

        Top._xobjMeta.tag = 'top'

        doc = xobj2.Document.fromxml(xml, rootNodes = [ Top ])
        doc.parse(xml)
        self.failUnlessEqual(top.foo, doc.root.foo)
        self.failUnlessEqual(top.bar, doc.root.bar)

    def testMissingRootElement(self):
        """
        Test that an error is raised if toxml() is called on a document
        with no root element.
        """
        class Broken(xobj2.XObj):
            pass
        top = Broken('broken')
        d = xobj2.Document(root=top, rootName='broken')

        s = d.toxml(xml_declaration=False)
        self.failUnlessEqual(s, '<broken>broken</broken>\n')

        d2 = xobj2.Document.fromxml(s)
        # We expect the root to be a dynamic type, there's no way to
        # force a simple type at the top level
        self.failUnlessEqual(d2.root.__class__.__name__, 'broken_XObj_Type')

    def testManualTag(self):
        class Item(str):
            _xobjMeta = xobj2.XObjMetadata(tag = 'item')

        i = Item()
        i.val = 10

        d = xobj2.Document(root=i)
        s = d.toxml()
        assert(s == "<?xml version='1.0' encoding='UTF-8'?>\n"
                    "<item>\n"
                    "  <val>10</val>\n"
                    "</item>\n")


    def testUnicodeIn(self):
        doc = xobj2.Document.fromxml('<top>'
                '<foo>m\xc3\xb8\xc3\xb8se bites are n\xc3\xa5sti</foo>'
                '<bar asdf="\xe3\x81\xa7\xe3\x81\x99\xe3\x80\x9c" />'
                '<baz ghjk="bl&#xEB;h" /></top>')
        self.assertEquals(doc.root.foo, u'm\xf8\xf8se bites are n\xe5sti')
        self.assertEquals(doc.root.bar.asdf, u'\u3067\u3059\u301c')
        self.assertEquals(doc.root.baz.ghjk, u'bl\xebh')

    def testUnicodeOut(self):
        class top(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes=dict(bar=str),
                elements=[ xobj2.Field('foo', str) ])

        d = xobj2.Document()
        d.rootName = 'top'
        d.root = t = top()

        # Bad: non-ASCII str in text
        t.foo = 'b\xc3\xa5d'
        t.bar = 'good'
        self.assertRaises(UnicodeDecodeError, d.toxml)

        # Bad: non-ASCII str in attribute
        t.foo = 'good'
        t.bar = 'b\xc3\xa5d'
        self.assertRaises(UnicodeDecodeError, d.toxml)

        # Good: char string (unicode) for text and attribute
        t.foo = u'\xf6'
        t.bar = u'\xf6'
        if etree.__version__ >= "2.2.0":
            attr = "\xc3\xb6"
        else:
            attr = "&#xF6;"
        self.assertXMLEquals(d.toxml(),
                '<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                '<top bar="%s">\n  <foo>\xc3\xb6</foo>\n</top>\n' % attr)


    def testLong(self):
        class Foo(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'foo', attributes = dict(i=long))

        f = Foo()
        f.i = 1 << 33

        d = xobj2.Document()
        d.root = f

        s = d.toxml()
        x = xobj2.Document.fromxml(s, rootNodes = [ Foo ])
        assert(x.root.i == 1 << 33)

    def testGlobalsPoisoning(self):
        # RBL-5328
        class Foo(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'root',
                elements = [ 'elem1', 'elem2' ])

        f = Foo()
        f.elem1 = 'val1'
        f.elem2 = 'val2'

        d = xobj2.Document(root=f, rootName='root')

        s = d.toxml(xml_declaration=False)
        self.assertXMLEquals(s,
            "<root><elem1>val1</elem1><elem2>val2</elem2></root>")

        # Now feed it an XML string that uses attributes instead of elements
        d = xobj2.Document.fromxml('<root elem1="val1" elem2="val2" />',
            rootNodes = [ Foo ])
        self.failUnlessEqual(d.root.elem1, f.elem1)
        self.failUnlessEqual(d.root.elem2, f.elem2)

        # Now serialize f again; class Foo is now poisoned with
        # attributes in addition to elements
        s = d.toxml(xml_declaration=False)
        self.assertXMLEquals(s,
            '<root elem1="val1" elem2="val2"><elem1>val1</elem1><elem2>val2</elem2></root>')

        # Brand new object; get rid of attributes
        f2 = Foo()
        f2.elem1 = 'val2'
        Foo._xobjMeta.attributes.clear()

        d = xobj2.Document(root=f2)
        s2 = d.toxml(xml_declaration=False)
        self.assertXMLEquals(s2,
            "<root><elem1>val2</elem1></root>")

    def testDefaultValuesSimple(self):
        class Foo(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'foo',
                elements = [ xobj2.Field('i', int) ])
            def __init__(self, i=0):
                self.i = i

        xml = '<foo><i>1</i></foo>'

        doc = xobj2.Document.fromxml(xml, rootNodes = [ Foo ])
        self.failUnlessEqual(type(doc.root.i), int)
        self.failUnlessEqual(doc.root.i, 1)

        xml2 = '<foo><i>1</i><i>2</i></foo>'

        doc2 = xobj2.Document.fromxml(xml2, rootNodes = [ Foo ])
        self.failUnlessEqual(type(doc.root.i), int)
        self.failUnlessEqual(doc2.root.i, 2)

    def testDefaultValuesComplex(self):
        class Foo(object):
            _xobjMeta = xobj2.XObjMetadata(attributes=dict(i=int))
            def __init__(self, i=0):
                self.i = i
            def __repr__(self):
                return 'Foo(%s)' % self.i
            def __cmp__(self, other):
                return cmp(self.i, other.i)
        class Bar(object):
            _xobjMeta = xobj2.XObjMetadata(
                tag='bar',
                elements = [ xobj2.Field('j', [ Foo ]) ])
            def __init__(self):
                self.j = [ Foo(0), Foo(1), Foo(2), ]

        xml2 = '<bar><j><i>3</i></j><j><i>4</i></j></bar>'

        doc2 = xobj2.Document.fromxml(xml2, rootNodes = [ Bar ])
        self.failUnlessEqual(type(doc2.root.j), list)
        self.failIfEqual(len(doc2.root.j), len(Bar().j))
        self.failUnlessEqual(doc2.root.j, [Foo(3), Foo(4)])

    def testCollectionWithAttrs(self):
        class Foo(object):
            _xobjMeta = xobj2.XObjMetadata(attributes=('id', ),
                elements = [ 'bar' ])
        class Foos(object):
            foo = [ Foo, ]
            _xobjMeta = xobj2.XObjMetadata(
                tag = 'foos',
                attributes=('id', ),
                elements = [ xobj2.Field('foo', [ Foo ]) ])

        xml = """\
<?xml version='1.0' encoding='UTF-8'?>
<foos id="/api/foos">
    <foo id="/api/foos/1">
        <bar>a</bar>
    </foo>
    <foo id="/api/foos/2">
        <bar>b</bar>
    </foo>
</foos>
"""

        doc = xobj2.Document.fromxml(xml, rootNodes=[Foos])

        self.failUnlessEqual([ x.bar for x in doc.root.foo ],
            [ 'a', 'b'])

        xml2 = doc.toxml()

        self.assertXMLEquals(xml, xml2)

    def testSettingTag(self):
        xml = """\
<?xml version='1.0' encoding='UTF-8'?>
<foo href="http://example.com/api/" />
"""
        class Foo(object):
            _xobjMeta = xobj2.XObjMetadata(tag='foo', attributes=dict(href=str))

        doc = xobj2.Document.fromxml(xml, rootNodes=[Foo])

        self.failUnlessEqual(doc.root._xobjMeta.tag, 'foo')

        doc2 = xobj2.Document.fromxml(xml)
        self.failUnlessEqual(doc2.root._xobjMeta.tag, 'foo')

        foo = Foo()
        foo.href = 'http://example.com/api/'

        doc3 =  xobj2.Document()
        doc3.root = foo

        xml2 = doc3.toxml()

        self.assertXMLEquals(xml, xml2)

        doc.root._xobjMeta.tag = None
        doc.rootName = None
        e = self.failUnlessRaises(TypeError, doc.toxml)
        self.failUnlessEqual(str(e), 'must specify a tag')

    def testTextElementWithAttribute(self):
        class Foo(object):
            _xobjMeta = xobj2.XObjMetadata(attributes=dict(href=str))
        class Foos(object):
            _xobjMeta = xobj2.XObjMetadata(
                elements=[ xobj2.Field('foo', [Foo]) ])

        d = xobj2.Document(rootNodes=dict(foos=Foos))

        xml = """\
<?xml version='1.0' encoding='UTF-8'?>
<foos>
  <foo href="http://example.com/api/1">value1</foo>
  <foo href="http://example.com/api/2">value2</foo>
</foos>
"""
        d.parse(xml)
        self.failUnlessEqual(d.root._xobjMeta.tag, 'foos')
        self.failUnlessEqual([ x.href for x in d.root.foo ],
            [ "http://example.com/api/1", "http://example.com/api/2" ])
        self.failUnlessEqual([ xobj2.XType.getText(x) for x in d.root.foo ],
            [ "value1", "value2" ])
        self.failUnlessEqual(d.toxml(), xml)

    def testFieldIsList(self):
        meta = xobj2.XObjMetadata(
            elements = [
                xobj2.Field('isalist', [ str ]),
                xobj2.Field('notalist', str ) ])

        self.failUnlessEqual(meta.elements[0].isList, True)
        self.failUnlessEqual(meta.elements[1].isList, False)

    def testNestedLists(self):
        xml = """\
<?xml version='1.0' encoding='UTF-8'?>
<msis>
  <msi>
    <name>Setup</name>
    <files>
      <file>foo.exe</file>
      <file>bar.exe</file>
    </files>
  </msi>
  <msi>
    <name>Setup2</name>
    <files>
      <file>
        <name>foo.exe</name>
        <uuid>12345</uuid>
      </file>
      <file>
        <name>bar.exe</name>
        <uuid>23456</uuid>
      </file>
    </files>
  </msi>
</msis>
"""

        doc = xobj2.Document.fromxml(xml)

        self.failUnlessEqual(doc.rootName, 'msis')
        self.failUnless(isinstance(doc.root.msi, list))
        self.failUnlessEqual([ x.name for x in doc.root.msi ],
            ['Setup', 'Setup2'])

        msi0 = doc.root.msi[0]

        self.failUnlessEqual(msi0.name, 'Setup')
        self.failUnless(hasattr(msi0, 'files'))
        self.failUnless(hasattr(msi0.files, 'file'))
        self.failUnless(isinstance(msi0.files.file, list))
        self.failUnlessEqual(len(msi0.files.file), 2)

        msi1 = doc.root.msi[1]

        self.failUnlessEqual(msi1.name, 'Setup2')
        self.failUnless(hasattr(msi1, 'files'))
        self.failUnless(hasattr(msi1.files, 'file'))
        self.failUnless(isinstance(msi1.files.file, list))
        self.failUnlessEqual(len(msi1.files.file), 2)
        self.failUnlessEqual(msi1.files.file[0].name, 'foo.exe')
        self.failUnlessEqual(msi1.files.file[0].uuid, '12345')
        self.failUnlessEqual(msi1.files.file[1].name, 'bar.exe')
        self.failUnlessEqual(msi1.files.file[1].uuid, '23456')

    def testObjectWithSlots(self):
        class B(object):
            _xobjMeta = xobj2.XObjMetadata(tag='b')

        class Foo(object):
            __slots__ = [ 'a', 'b', ]
            _xobjMeta = xobj2.XObjMetadata(tag="foo", elements=[ 'a' ])

        class Foos(object):
            foo = [ Foo, ]
            _xobjMeta = xobj2.XObjMetadata(tag="foos",
                 elements=xobj2.Field('foo', [ Foo ]))

        f1 = Foo()
        f1.a = 'a1'
        f1.b = 'b1'
        f2 = Foo()
        f2.a = 'a2'
        f2.b = 'b2'

        doc = xobj2.Document(root = Foos())
        doc.root.foo = [ f1, f2 ]

        xml = """
<foos>
  <foo><a>a1</a><b>b1</b></foo>
  <foo><a>a2</a><b>b2</b></foo>
</foos>"""

        self.assertXMLEquals(doc.toxml(prettyPrint=False), xml)
        doc = xobj2.Document.fromxml(xml, rootNodes=Foos)
        self.failUnlessEqual(doc.root._xobjMeta.tag, 'foos')
        self.failUnlessEqual([ x.a for x in doc.root.foo ],
           [ "a1", "a2" ])
        self.failUnlessEqual([ x.b for x in doc.root.foo ],
            [ "b1", "b2" ])
        self.assertXMLEquals(doc.toxml(prettyPrint=False), xml)

    def testObjectWithNotEnoughSlots(self):
        # Class only defines slot b
        class Item(object):
            __slots__ = [ 'b' ]
            _xobjMeta = xobj2.XObjMetadata(attributes=[ 'b' ])
        class Root(object):
            _xobjMeta = xobj2.XObjMetadata(elements=xobj2.Field('item', [ Item ]))

        xml = '<root><item a="a1" b="b1">text1</item><item a="a2" b="b2">text2</item></root>'

        doc = xobj2.Document.fromxml(xml, rootNodes = dict(root=Root))
        self.failUnlessEqual([ x.b for x in doc.root.item ], [ 'b1', 'b2'])
        self.failUnlessEqual([ hasattr(x, 'a') for x in doc.root.item ],
            [ False, False ])
        self.failUnlessEqual([ hasattr(x, '_xobjText') for x in doc.root.item ],
            [ False, False ])

        class Item(object):
            __slots__ = [ 'b', '_xobjText', ]
            _xobjMeta = xobj2.XObjMetadata(attributes=[ 'b' ])

        class Root(object):
            _xobjMeta = xobj2.XObjMetadata(elements=xobj2.Field('item', [ Item ]))

        doc = xobj2.Document.fromxml(xml, rootNodes = dict(root=Root))
        self.failUnlessEqual([ x.b for x in doc.root.item ], [ 'b1', 'b2'])
        self.failUnlessEqual([ hasattr(x, 'a') for x in doc.root.item ],
            [ False, False ])
        self.failUnlessEqual([ xobj2.XType.getText(x) for x in doc.root.item ],
            [ 'text1', 'text2'])

    def testChecksum(self):
        # Class only defines slot b
        class Item(object):
            _xobjMeta = xobj2.XObjMetadata(attributes=[ 'b', 'checksum', ],
                checksumAttribute='checksum')
            __slots__ = _xobjMeta.getSlots()
        class Root(object):
            _xobjMeta = xobj2.XObjMetadata(checksumAttribute='csum',
                elements=xobj2.Field('item', [ Item ]))
            __slots__ = _xobjMeta.getSlots()

        xml = '<root><item a="a1" b="b1">text1</item><item a="a2" b="b2">text2</item></root>'

        doc = xobj2.Document.fromxml(xml, rootNodes = dict(root=Root))
        ret = doc.toxml()
        self.assertXMLEquals(ret, """
<root csum="0860ae70231fca9085e96645ae1f2921f08fc1d4">
  <item b="b1" checksum="fc5c65f38b7be4f71419913b3e88b90df9edc073"/>
  <item b="b2" checksum="9e51b4b21eb771c58636405a6c0e8ab61519d62b"/>
</root>""")

    def testConflictWithBuiltin(self):
        xml = """<root count="1"/>"""
        class Root(object):
            _xobjMeta = xobj2.XObjMetadata()
        doc = xobj2.Document.fromxml(xml, rootNodes = dict(root=Root))
        self.failUnlessEqual(doc.root.count, '1')

        # Now with typing
        class Root2(object):
            _xobjMeta = xobj2.XObjMetadata(attributes=dict(count=int))
        doc = xobj2.Document.fromxml(xml, rootNodes = dict(root=Root2))
        self.failUnlessEqual(doc.root.count, 1)

    def testStringAndUnicode(self):
        xml = u"""<?xml version='1.0' encoding='UTF-8'?>
<root><val summary="a"/><val summary="a\xf6a"/></root>"""
        class Val(object):
            _xobjMeta = xobj2.XObjMetadata()

        class Root(object):
            _xobjMeta = xobj2.XObjMetadata(elements=xobj2.Field('val', [ Val ]))
        doc = xobj2.Document.fromxml(xml, rootNodes = dict(root=Root))
        self.failUnlessEqual(
            [ x.summary for x in doc.root.val],
            [ 'a', u'a\xf6a', ])

    def testDateValue(self):
        xml = """\
<root>
  <dateElement>2011-12-13T14:15:16.789012+00:00</dateElement>
  <dateAttribute attr="2010-10-06T00:11:27.828160+00:00"/>
  <dateAttribute2 attr="2010-10-06 00:11:27"/>
</root>"""

        class DateAttribute(object):
            _xobjMeta = xobj2.XObjMetadata(attributes=dict(attr=xobj2.Date))

        class DateAttribute2(object):
            _xobjMeta = xobj2.XObjMetadata(
                attributes=dict(attr=xobj2.Date),
            )

        class Root(object):
            _xobjMeta = xobj2.XObjMetadata(
                elements=[
                    xobj2.Field('dateElement', xobj2.Date),
                    xobj2.Field('dateAttribute', DateAttribute),
                    xobj2.Field('dateAttribute2', DateAttribute2),
                ],
            )
        doc = xobj2.Document.fromxml(xml, rootNodes = dict(root=Root))
        self.assertEquals(doc.root.dateElement,
            datetime.datetime(2011, 12, 13, 14, 15, 16, 789012,
                tzinfo=tz.tzutc())
        )
        self.assertEquals(doc.root.dateAttribute.attr,
            datetime.datetime(2010, 10, 6, 0, 11, 27, 828160,
                tzinfo=tz.tzutc())
        )
        self.assertEquals(doc.root.dateAttribute2.attr,
            datetime.datetime(2010, 10, 6, 0, 11, 27))

        xml2 = doc.toxml()
        self.assertXmlEqual(xml2, xml)

if __name__ == "__main__":
    testsuite.main()
