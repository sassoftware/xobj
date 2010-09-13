#!/usr/bin/python
#
# Copyright (c) 2008-2009 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any waranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
#

import os
import types

import testsuite
testsuite.setup()
from testrunner import testhelp
from lxml import etree

from xobj import xobj
from StringIO import StringIO

def _xml(fn, s, asFile = False):
    # We write out the XML files into a directory that is shared with the
    # actionscript test suite. Make sure you hg add the file when you create a
    # new one.
    f = open(os.path.join(os.path.dirname(__file__),
                          "../../test/%s.xml" % fn), "w")
    f.write(s)

    if asFile:
        return StringIO(s)

    return s

class TestCase(testhelp.TestCase):
    @classmethod
    def assertXmlEqual(cls, s1, s2):
        """
        A more reliable way to compare two XML documents. The order of
        attributes is undefined, and that should not break the equality.
        """
        d1 = etree.fromstring(s1)
        d2 = etree.fromstring(s2)
        return cls._compareTrees(d1, d2)

    @classmethod
    def _compareTrees(cls, t1, t2):
        # Two DOM trees are equal if:
        # 1. the tags are identical
        if not (t1.tag == t2.tag):
            return False
        # 2. Same text
        if not (t1.text == t2.text):
            return False
        # 3. The attributes are identical (order is not important)
        if not (dict(t1.items()) == dict(t2.items())):
            return False
        # 3. Same number of children (so we can apply zip() below)
        ch1 = t1.getchildren()
        ch2 = t2.getchildren()
        if len(ch1) != len(ch2):
            return False
        # 4. Children on corresponding positions are equal (recursively)
        for child1, child2 in zip(ch1, ch2):
            if not cls._compareTrees(child1, child2):
                return False
        return True

class XobjTest(TestCase):

    def testSimpleParse(self):
        xml = _xml('simple', '<top attr1="anattr" attr2="another">\n'
                             '    <!-- comment -->'
                             '    <prop>something</prop>\n'
                             '    <subelement subattr="2"/>\n'
                             '</top>\n', asFile = True)
        o = xobj.parsef(xml)
        self.assertEqual(o.top.__class__.__name__, 'top_XObj_Type')
        self.assertEqual(o.top.attr1, 'anattr')
        self.assertEqual(o.top.attr2, 'another')
        self.assertEqual(o.top.prop, 'something')
        self.assertEqual(o.top.subelement.subattr, '2')
        self.assertEqual(o.top.subelement.__class__.__name__,
                         'subelement_XObj_Type')
        assert(repr(o).startswith('<xobj.xobj.Document object'))
        assert(repr(o.top).startswith('<xobj.xobj.top_XObj_Type object'))
        assert(repr(o.top.subelement).startswith(
                                    '<xobj.xobj.subelement_XObj_Type object'))
        self.assertEqual(repr(o.top.attr1), "'anattr'")

        # ---

        class SubelementClass(object):
            subattr = int

        class TopClass(object):
            subelement = SubelementClass
            unused = str
            attr1 = str

        class DocumentClass(xobj.Document):
            top = TopClass

        o = xobj.parsef(xml, documentClass = DocumentClass)
        self.assertEqual(o.top.subelement.subattr, 2)
        self.assertEqual(o.top.unused, None)

        # ---

        class SubelementClass(object):
            subattr = [ int ]
        TopClass.subelement = SubelementClass
        TopClass.prop = xobj.XObj

        o = xobj.parsef(xml, documentClass = DocumentClass)
        self.assertEqual(o.top.subelement.subattr, [ 2 ] )
        self.assertEqual(o.top.prop, 'something')

        # ---

        TopClass.subelement = [ SubelementClass ]
        TopClass.prop = [ str ]
        o = xobj.parsef(xml, documentClass = DocumentClass)
        self.assertEqual(o.top.subelement[0].subattr, [ 2] )
        self.assertEqual(o.top.prop, [ 'something' ])

    def testComplexParse(self):
        xmlText = _xml('complex',
                       '<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top>\n'
                       '  <prop>\n'
                       '    <subprop subattr="1">asdf</subprop>\n'
                       '    <subprop subattr="2">fdsa</subprop>\n'
                       '  </prop>\n'
                       '  <simple>simple</simple>\n'
                       '</top>\n')
        xml = StringIO(xmlText)
        o = xobj.parsef(xml)

        # ---

        self.assertEqual(o.toxml(), xmlText)

        # ---

        self.assertEqual(o.top.__class__.__name__, 'top_XObj_Type')
        self.assertEqual(type(o.top.prop.subprop), types.ListType)
        self.assertEqual(o.top.prop.subprop, ['asdf', 'fdsa'])
        asdf = o.top.prop.subprop[0]
        self.assertEqual(asdf.__class__.__name__, 'subprop_XObj_Type')
        self.assertEqual(o.top.prop.__class__.__name__,
                         'prop_XObj_Type')
        for i in range(2):
            self.assertEqual(o.top.prop.subprop[i].__class__.__name__,
                             'subprop_XObj_Type')
        assert(o.top.prop.subprop[0].__class__ ==
               o.top.prop.subprop[1].__class__)

        # ---

        class SubpropClass(object):
            subattr = int
            unused = str

        class PropClass(object):
            subprop = [ SubpropClass ]

        class SimpleClass(xobj.XObj):
            pass

        class TopClass(xobj.XObj):
            unused = str
            prop = PropClass
            simple = [ SimpleClass ]

        class DocumentClass(xobj.Document):
            top = TopClass

        o = xobj.parsef(xml, documentClass = DocumentClass)
        self.assertEqual(o.top.prop.subprop[1].subattr, 2)
        self.assertEqual(o.top.unused, None)
        self.assertEqual(o.top.prop.subprop[0].unused, None)
        self.assertEqual(o.top.simple[0], 'simple')

        # ---

        # asdf/fdsa have been dropped becuase text is dropped from
        # the complex class PropClass
        xmlOutText = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                      '<top>\n'
                      '  <prop>\n'
                      '    <subprop subattr="1"/>\n'
                      '    <subprop subattr="2"/>\n'
                      '  </prop>\n'
                      '  <simple>simple</simple>\n'
                      '</top>\n')
        self.assertEqual(o.toxml(), xmlOutText)

    def testComplexListStrGen(self):
        """
        Test generating XML from a list of strings.
        """

        class Collection(object):
            data = [ str ]
        class DocumentClass(xobj.Document):
            collection = Collection

        collection = Collection()
        collection.data = [ 'a', 'b', 'c', ]

        xml = xobj.toxml(collection, 'collection')
        doc = xobj.parse(xml, documentClass=DocumentClass)
        self.failUnlessEqual(collection.data, doc.collection.data)

    def testComplexListObjGen(self):
        """
        Test generating XML from lists of objects.
        """

        class Basic(object):
            foo = str
        class BasicCollection(object):
            data = [ Basic ]
        class DocumentClass(xobj.Document):
            collection = BasicCollection

        basic = Basic()
        basic.foo = 'a'

        collection = BasicCollection()
        collection.data = [ basic, ]

        xml = xobj.toxml(collection, 'collection')
        doc = xobj.parse(xml, documentClass=DocumentClass)
        self.failUnlessEqual(basic.foo, doc.collection.data[0].foo)

    def testComplexDictStrGen(self):
        """
        Test generating XML from dictionaries of strings.
        """

        raise testhelp.SkipTestException('dicts not currently supported')

        class Collection(object):
            data = {str: str}
        class DocumentClass(xobj.Document):
            collection = Collection

        collection = Collection()
        collection.data = {'a': 'A'}

        xml = xobj.toxml(collection, 'collection')
        doc = xobj.parse(xml, documentClass=DocumentClass)
        self.failUnlessEqual(collection.data, doc.collection.data)

    def testComplexDictObjGen(self):
        """
        Test generating XML from dictionaries of objects.
        """

        raise testhelp.SkipTestException('dicts not currently supported')

        class Basic(object):
            foo = str
        class Collection(object):
            data = {Basic: Basic}
        class DocumentClass(xobj.Document):
            collection = Collection

        basicKey = Basic()
        basicKey.foo = 'a'

        basicVal = Basic()
        basicVal.foo = 'A'

        collection = Collection()
        collection.data = {basicKey: basicVal}

        xml = xobj.toxml(collection, 'collection')
        doc = xobj.parse(xml, documentClass=DocumentClass)

        key = doc.collection.data.keys()[0]
        val = doc.colleciton.data[key]

        self.failUnlessEqual(key.foo, basicKey.foo)
        self.failUnlessEqual(val.foo, basicVal.foo)

    def testNamespaces(self):
        xmlString = _xml('namespaces',
                    '<top xmlns="http://this" xmlns:other="http://other/other"'
                    ' xmlns:other2="http://other/other2">\n'
                    '  <local/>\n'
                    '  <other:tag other:val="1"/>\n'
                    '  <other2:tag val="2"/>\n'
                    '</top>\n')
        xml = StringIO(xmlString)
        o = xobj.parsef(xml)
        assert(o.top.other_tag.other_val == '1')
        assert(o.top.other2_tag.val == '2')
        self.assertXmlEqual(o.toxml(xml_declaration = False), xmlString)

        class Top(xobj.Document):
            nameSpaceMap = { 'other3' : 'http://other/other2' }

        o = xobj.parsef(xml, documentClass = Top)
        assert(o.top.other_tag.other_val == '1')
        assert(o.top.other3_tag.val == '2')
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
        d = xobj.parsef(xml, schemaf = schema)
        s2 = d.toxml(xml_declaration = False)
        assert(s == s2)
        d.top.unknown = 'foo'
        self.assertRaises(xobj.DocumentInvalid, d.toxml)
        self.assertRaises(xobj.DocumentInvalid, xobj.toxml,
                          d.top, 'top', schemaf = schema)

        xml = StringIO(s.replace('prop', 'prop2'))
        xobj.parsef(xml)
        self.assertRaises(etree.XMLSyntaxError,
                          xobj.parsef, xml, schemaf = schema)

    def testId(self):
        s = _xml('id1',
            '<top>\n'
            '  <item id="theid" val="value"/>\n'
            '  <ref other="theid"/>\n'
            '</top>\n')
        xml = StringIO(s)

        class Ref(xobj.XObj):
            _xobj = xobj.XObjMetadata(attributes = [ 'other' ])
            other = xobj.XIDREF

        class Top(xobj.XObj):
            ref = Ref

        class Document(xobj.Document):
            top = Top

        d = xobj.parsef(xml, documentClass = Document)
        assert(d.top.ref.other == d.top.item)
        s2 = d.toxml(xml_declaration = False)
        self.assertEquals(s, s2)

        # now test if the id is called something else
        s = _xml('id2',
            '<top>\n'
            '  <item anid="theid" val="value"/>\n'
            '  <ref other="theid"/>\n'
            '</top>\n')
        xml = StringIO(s)
        try:
            xobj.parsef(xml, documentClass = Document)
        except xobj.XObjIdNotFound, e:
            self.assertEquals(str(e), "XML ID 'theid' not found in document")
        else:
            assert(0)

        class Item(xobj.XObj):
            _xobj = xobj.XObjMetadata(attributes = [ 'anid' ])
            anid = xobj.XID
        Top.item = Item

        d = xobj.parsef(xml, documentClass = Document)
        assert(d.top.ref.other == d.top.item)
        s2 = d.toxml(xml_declaration = False)
        self.assertEquals(s, s2)

        # test outputing an idref w/o a corresponding id
        t = Top()
        t.item = Item()
        t.item.anid = 'foo'
        t.ref = Ref()
        t.ref.other = Item()
        t.ref.other.anid = 'bar'
        try:
            xobj.toxml(t, 'top', xml_declaration = False)
        except xobj.UnmatchedIdRef, e:
            assert(str(e) == 'Unmatched idref values during XML creation '
                             'for id(s): bar')

        t.ref.other = t.item
        s = xobj.toxml(t, 'top', xml_declaration = False)
        self.assertEquals(s, '<top>\n'
                             '  <item anid="foo"/>\n'
                             '  <ref other="foo"/>\n'
                             '</top>\n')

        # and test if the id isn't defined properly
        class Top(xobj.XObj):
            _xobj = xobj.XObjMetadata(attributes = [ 'ref' ])
            ref = xobj.XIDREF
        Document.top = Top

        d = Document()
        d.top = Top()
        d.top.ref = xobj.XObj('something')
        try:
            d.toxml()
        except xobj.XObjSerializationException, e:
            self.assertEquals(str(e), 'No id found for element referenced '
                                      'by ref')
        else:
            assert(0)

    def testIdInNamespace(self):
        s = _xml('id-in-ns1',
            '<ns:top xmlns:ns="http://somens.xsd">\n'
            '  <ns:item ns:id="theid" ns:val="value"/>\n'
            '  <ns:ref ns:other="theid"/>\n'
            '</ns:top>\n')
        xml = StringIO(s)

        class Ref(object):
            ns_other = xobj.XIDREF

        d = xobj.parsef(xml, typeMap = { 'ns_ref' : Ref } )
        assert(d.ns_top.ns_ref.ns_other == d.ns_top.ns_item)
        s2 = d.toxml(xml_declaration = False)
        assert(s == s2)

    def testExplicitNamespaces(self):
        s = _xml('explicitns',
            '<top xmlns="http://somens.xsd" xmlns:ns="http://somens.xsd">\n'
            '  <element ns:attr="foo"/>\n'
            '</top>\n'
            )
        xml = StringIO(s)

        d = xobj.parsef(xml)
        assert(d.ns_top.ns_element.ns_attr == 'foo')
        assert(d.__class__ == xobj.Document)
        s2 = d.toxml(xml_declaration = False)

        expecteds2 = (
            '<ns:top xmlns:ns="http://somens.xsd">\n'
            '  <ns:element ns:attr="foo"/>\n'
            '</ns:top>\n'
            )
        assert(s2 == expecteds2)

    def testObjectType(self):
        s ='<top attr="foo"/>'
        xml = StringIO(s)

        class Document(xobj.Document):
            top = object

        d = xobj.parsef(xml, documentClass = Document)
        assert(d.top.attr == 'foo')

    def testTypeMap(self):
        s ='<top><item val="3"/></top>'
        xml = StringIO(s)

        class D(xobj.Document):
            typeMap = { 'val' : int }

        d = xobj.parsef(xml, documentClass = D)
        assert(d.top.item.val == 3)

        class I(xobj.XObj):
            val = int

        d = xobj.parsef(xml, typeMap = { 'item' : I} )
        assert(d.top.item.val == 3)

    def testEmptyList(self):
        class Top(xobj.XObj):
            l = [ int ]

        d = xobj.parse("<top/>", typeMap = { 'top' : Top })
        assert(d.top.l == None)

    def testUnion(self):
        class TypeA(xobj.XObj):
            vala = int

        class TypeB(xobj.XObj):
            valb = int

        class Top(xobj.XObj):
            items = [ { 'typea' : TypeA,
                        'typeb' : TypeB } ]

        s = _xml('union',
                 '<top>\n'
                 '  <typea vala="1"/>\n'
                 '  <typeb valb="2"/>\n'
                 '  <typea vala="3"/>\n'
                 '  <typeb valb="4"/>\n'
                 '  <typea vala="5"/>\n'
                 '</top>\n')

        d = xobj.parse(s, typeMap = { 'top' : Top } )
        assert(d.top.items[0].vala == 1)
        assert(d.top.items[1].valb == 2)
        assert(d.top.items[2].vala == 3)
        assert(d.top.items[3].valb == 4)
        assert(d.top.items[4].vala == 5)
        assert(s == d.toxml(xml_declaration = False))

        d = xobj.parse('<top/>', typeMap = { 'top' : Top } )
        assert(d.top.items == None)

    def testObjectTree(self):
        class Top(object):
            pass

        class Middle(object):

            tag = int

            def foo(self):
                pass

        t = Top()
        t.prop = 'abc'
        t.middle = Middle()
        t.middle.tag = 123
        t.bottom = None

        s = xobj.toxml(t, 'top', xml_declaration = False)
        self.assertEquals(s, '<top>\n'
                             '  <middle>\n'
                             '    <tag>123</tag>\n'
                             '  </middle>\n'
                             '  <prop>abc</prop>\n'
                             '</top>\n')

        d = xobj.parse(s)

    def testCleanCreation(self):
        class Top:
            _xobj = xobj.XObjMetadata(
                        elements = [ "first", "second", "third" ],
                        attributes = [ "foo", "bar" ])

        t = Top()
        t.first = "1"
        t.second = "2"
        t.foo = "f"

        self.assertEquals(xobj.toxml(t, 'top', xml_declaration = False),
            '<top foo="f">\n'
            '  <first>1</first>\n'
            '  <second>2</second>\n'
            '</top>\n')

        t.unknown = "unknown"
        assert("<unknown>unknown</unknown>" in
                    xobj.toxml(t, 'top', xml_declaration = False))

    def testIntElement(self):
        xml = _xml('intelement', '<top><anint>5</anint></top>')
        doc = xobj.parse(xml, typeMap = { 'anint' : int })
        assert(doc.top.anint == 5)

    def testMetadataAttributeTypes(self):
        class Bar:
            _xobj = xobj.XObjMetadata(
                        attributes = { 'ref' : xobj.XIDREF } )

        class Top:
            _xobj = xobj.XObjMetadata(
                        attributes = { 'val' : int } )
            bar = Bar

        s = ('<top id="foo" val="5">\n'
             '  <bar ref="foo"/>\n'
             '</top>\n')

        d = xobj.parse(s, typeMap = { 'top' : Top })
        assert(d.top.val == 5)
        assert(d.top == d.top.bar.ref)

        s2 = d.toxml(xml_declaration = False)
        assert(s == s2)

    def testSimpleMultiParse(self):
        """
        Test parsing multiple xml documents with one set of classes.
        """

        class Top(object):
            foo = str
        class DocumentClass(xobj.Document):
            top = Top

        topA = Top()
        topA.foo = 'A'
        xmlA = xobj.toxml(topA, 'top')

        topB = Top()
        topB.foo = 'B'
        xmlB = xobj.toxml(topB, 'top')

        docA = xobj.parse(xmlA, documentClass=DocumentClass)
        docB = xobj.parse(xmlB, documentClass=DocumentClass)

        self.failUnlessEqual('A', docA.top.foo)
        self.failUnlessEqual('B', docB.top.foo)

    def testComplexMultiParse(self):
        """
        Test parsing multiple xml documents with one set of classes using more
        complex types.
        """

        class Top(object):
            foo = [ str ]
        class DocumentClass(xobj.Document):
            top = Top

        xmlTextA = _xml('complex',
                       '<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top>\n'
                       '  <foo>a</foo>\n'
                       '  <foo>b</foo>\n'
                       '</top>\n')

        xmlA = StringIO(xmlTextA)
        docA = xobj.parsef(xmlA, documentClass=DocumentClass)

        xmlTextB = _xml('complex',
                       '<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top>\n'
                       '  <foo>A</foo>\n'
                       '  <foo>B</foo>\n'
                       '</top>\n')

        xmlB = StringIO(xmlTextB)
        docB = xobj.parsef(xmlB, documentClass=DocumentClass)

        self.failUnlessEqual('a', docA.top.foo[0])
        self.failUnlessEqual('b', docA.top.foo[1])
        self.failUnlessEqual('A', docB.top.foo[0])
        self.failUnlessEqual('B', docB.top.foo[1])

    def testNoneSingleElementSerialization(self):
        """
        Test serializing a single element set to None.
        """

        class Top(object):
            foo = str
        class DocumentClass(xobj.Document):
            top = Top

        top = Top()
        top.foo = None

        xml = xobj.toxml(top, 'top')
        expectedXml = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top/>\n')
        self.failUnlessEqual(xml, expectedXml)

        doc = xobj.parse(xml, documentClass=DocumentClass)
        self.failUnlessEqual(top.foo, doc.top.foo)

    def testNoneMultiElementSerialization(self):
        """
        Test serializing multiple elements that are set to None.
        """

        class Top(object):
            foo = str
            bar = str
        class DocumentClass(xobj.Document):
            top = Top

        top = Top()
        top.foo = None
        top.bar = ''

        xml = xobj.toxml(top, 'top')
        expectedXml = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top>\n'
                       '  <bar></bar>\n'
                       '</top>\n')
        self.failUnlessEqual(xml, expectedXml)

        doc = xobj.parse(xml, documentClass=DocumentClass)
        self.failUnlessEqual(top.foo, doc.top.foo)
        self.failUnlessEqual(top.bar, doc.top.bar)

    def testNoneSingleAttributeSerialization(self):
        """
        Test serializing a single attribute that is set to None.
        """

        class Top(object):
            _xobj = xobj.XObjMetadata(attributes=['foo'])
        class DocumentClass(xobj.Document):
            top = Top

        top = Top()
        top.foo = None

        xml = xobj.toxml(top, 'top')
        expectedXml = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top/>\n')
        self.failUnlessEqual(xml, expectedXml)

        doc = xobj.parse(xml, documentClass=DocumentClass)
        self.failUnlessEqual(top.foo, doc.top.foo)

    def testNoneMultiAttributeSerialization(self):
        """
        Test serializing multiple attributes that are set to None.
        """

        class Top(object):
            _xobj = xobj.XObjMetadata(attributes=['foo', 'bar'])
        class DocumentClass(xobj.Document):
            top = Top

        top = Top()
        top.foo = None
        top.bar = ''

        xml = xobj.toxml(top, 'top')
        expectedXml = ('<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                       '<top bar=""/>\n')
        self.failUnlessEqual(xml, expectedXml)

        doc = xobj.parse(xml, documentClass=DocumentClass)
        self.failUnlessEqual(top.foo, doc.top.foo)
        self.failUnlessEqual(top.bar, doc.top.bar)

    def testMissingRootElement(self):
        """
        Test that an error is raised if toxml() is called on a document
        with no root element.
        """
        class Broken(xobj.Document):
            top = str
        xml = Broken()
        error = self.assertRaises(RuntimeError, xml.toxml)
        self.assertEquals(error.args, ('Document has no root element.',))

    def testManualTag(self):
        class Item(str):
            _xobj = xobj.XObjMetadata(tag = 'item')

        i = Item()
        i.val = 10
        s = xobj.toxml(i, None)
        assert(s == "<?xml version='1.0' encoding='UTF-8'?>\n"
                    "<item>\n"
                    "  <val>10</val>\n"
                    "</item>\n")


    def testUnicodeIn(self):
        doc = xobj.parse('<top>'
                '<foo>m\xc3\xb8\xc3\xb8se bites are n\xc3\xa5sti</foo>'
                '<bar asdf="\xe3\x81\xa7\xe3\x81\x99\xe3\x80\x9c" />'
                '<baz ghjk="bl&#xEB;h" /></top>')
        self.assertEquals(doc.top.foo, u'm\xf8\xf8se bites are n\xe5sti')
        self.assertEquals(doc.top.bar.asdf, u'\u3067\u3059\u301c')
        self.assertEquals(doc.top.baz.ghjk, u'bl\xebh')

    def testUnicodeOut(self):
        class Stuff(xobj.Document):
            class top(xobj.XObj):
                _xobj = xobj.XObjMetadata(attributes=['bar'])
                foo = str
        s = Stuff()
        s.top = Stuff.top()

        # Bad: non-ASCII str in text
        s.top.foo = 'b\xc3\xa5d'
        s.top.bar = 'good'
        self.assertRaises(UnicodeDecodeError, s.toxml)

        # Bad: non-ASCII str in attribute
        s.top.foo = 'good'
        s.top.bar = 'b\xc3\xa5d'
        self.assertRaises(UnicodeDecodeError, s.toxml)

        # Good: char string (unicode) for text and attribute
        s.top.foo = u'\xf6'
        s.top.bar = u'\xf6'
        if etree.__version__ >= "2.2.0":
            attr = "\xc3\xb6"
        else:
            attr = "&#xF6;"
        self.assertEquals(s.toxml(),
                '<?xml version=\'1.0\' encoding=\'UTF-8\'?>\n'
                '<top bar="%s">\n  <foo>\xc3\xb6</foo>\n</top>\n' % attr)


    def testLong(self):
        class Foo(object):
            i = long

        f = Foo()
        f.i = 1 << 33
        s = xobj.toxml(f, 'foo')
        x = xobj.parse(s, typeMap = { 'foo' : Foo })
        assert(x.foo.i == 1 << 33)

    def testGlobalsPoisoning(self):
        # RBL-5328
        class Foo(object):
            _xobj = xobj.XObjMetadata(attributes = [ ],
                elements = [ 'elem1', 'elem2' ])

        f = Foo()
        f.elem1 = 'val1'
        f.elem2 = 'val2'
        s = xobj.toxml(f, 'root')
        self.assertXMLEquals(s,
            "<root><elem1>val1</elem1><elem2>val2</elem2></root>")

        # Now feed it an XML string that uses attributes instead of elements
        x = xobj.parse('<root elem1="val1" elem2="val2" />',
            typeMap = { 'root' : Foo })
        self.failUnlessEqual(x.root.elem1, f.elem1)
        self.failUnlessEqual(x.root.elem2, f.elem2)

        # Now serialize f again, elements should continue to be elements
        s = xobj.toxml(f, 'root')
        self.assertXMLEquals(s,
            "<root><elem1>val1</elem1><elem2>val2</elem2></root>")

        # Brand new object
        f2 = Foo()
        f2.elem1 = 'val2'
        s2 = xobj.toxml(f2, 'root')
        self.assertXMLEquals(s2,
            "<root><elem1>val2</elem1></root>")

    def testDefaultValuesSimple(self):
        class Foo(object):
            i = int
            def __init__(self, i=0):
                self.i = i
        class Doc(xobj.Document):
            foo = Foo

        xml = '<foo><i>1</i></foo>'

        doc = xobj.parse(xml, documentClass=Doc)
        self.failUnless(issubclass(type(doc.foo.i), Foo.i))

        xml2 = '<foo><i>1</i><i>2</i></foo>'

        doc2 = xobj.parse(xml2, documentClass=Doc)
        self.failUnless(issubclass(type(doc2.foo.i), Foo.i))
        self.failUnlessEqual(doc2.foo.i, 2)

    def testDefaultValuesComplex(self):
        class Foo(object):
            i = int
            def __init__(self, i=0):
                self.i = i
            def __repr__(self):
                return 'Foo(%s)' % self.i
            def __cmp__(self, other):
                return cmp(self.i, other.i)
        class Bar(object):
            j = [ Foo ]
            def __init__(self):
                self.j = [ Foo(0), Foo(1), Foo(2), ]
        class BarDoc(xobj.Document):
            bar = Bar

        xml2 = '<bar><j><i>3</i></j><j><i>4</i></j></bar>'

        doc2 = xobj.parse(xml2, documentClass=BarDoc)
        self.failUnless(issubclass(type(doc2.bar.j), type(Bar.j)))
        self.failIfEqual(len(doc2.bar.j), len(Bar().j))
        self.failUnlessEqual(doc2.bar.j, [Foo(3), Foo(4)])

    def testCollectionWithAttrs(self):
        class Foo(object):
            bar = str
            _xobj = xobj.XObjMetadata(attributes=('id', ))
        class Foos(object):
            foo = [ Foo, ]
            _xobj = xobj.XObjMetadata(attributes=('id', ))
        class Doc(xobj.Document):
            foos = Foos

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

        doc = xobj.parse(xml, documentClass=Doc)

        self.failUnlessEqual(len(doc.foos.foo), 2)
        self.failUnlessEqual(doc.foos.foo[0].bar, 'a')
        self.failUnlessEqual(doc.foos.foo[1].bar, 'b')

        xml2 = doc.toxml()

        self.assertXMLEquals(xml, xml2)

    def testSettingTag(self):
        class Foo(object):
            _xobj = xobj.XObjMetadata(tag='foo', attributes='href')
            href = str
        class Doc(xobj.Document):
            foo = Foo

        xml = """\
<?xml version='1.0' encoding='UTF-8'?>
<foo href="http://example.com/api/" />
"""

        doc = xobj.parse(xml, documentClass=Doc)
        self.failUnlessEqual(doc.foo._xobj.tag, 'foo')

        doc2 = xobj.parse(xml)
        self.failUnlessEqual(doc2.foo._xobj.tag, 'foo')

        foo = Foo()
        foo.href = 'http://example.com/api/'
        xml2 = xobj.toxml(foo)

        self.assertXMLEquals(xml, xml2)

        doc.foo._xobj.tag = None
        self.failUnlessRaises(TypeError, xobj.toxml, doc.foo)


if __name__ == "__main__":
    testsuite.main()
