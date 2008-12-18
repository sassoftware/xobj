#!/usr/bin/python
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
#

import types

import testsuite
testsuite.setup()
from testrunner import testhelp
from lxml import etree

from xobj import xobj
from StringIO import StringIO

def _xml(fn, s, asFile = False):
    f = open("../../test/%s.xml" % fn, "w")
    f.write(s)
    if asFile:
        return StringIO(s)

    return s

class XobjTest(testhelp.TestCase):

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

        # ---

        class SubelementClass(xobj.XObject):
            subattr = int

        class TopClass(xobj.XObject):
            subelement = SubelementClass
            unused = str
            attr1 = str

        class DocumentClass(xobj.Document):
            top = TopClass

        o = xobj.parsef(xml, documentClass = DocumentClass)
        self.assertEqual(o.top.subelement.subattr, 2)
        self.assertEqual(o.top.unused, None)

        # ---

        class SubelementClass(xobj.XObject):
            subattr = [ int ]
        TopClass.subelement = SubelementClass

        o = xobj.parsef(xml, documentClass = DocumentClass)
        self.assertEqual(o.top.subelement.subattr, [ 2 ] )

        # ---

        TopClass.subelement = [ SubelementClass ]
        o = xobj.parsef(xml, documentClass = DocumentClass)
        self.assertEqual(o.top.subelement[0].subattr, [ 2] )

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

        self.assertEqual(o.tostring(), xmlText)

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

        class SubpropClass(xobj.XObject):
            subattr = int
            unused = str

        class PropClass(xobj.XObject):
            subprop = [ SubpropClass ]

        class SimpleClass(xobj.XObject):
            pass

        class TopClass(xobj.XObject):
            unused = str
            prop = PropClass
            simple = [ SimpleClass ]

        class DocumentClass(xobj.Document):
            top = TopClass

        o = xobj.parsef(xml, documentClass = DocumentClass)
        self.assertEqual(o.top.prop.subprop[1].subattr, 2)
        self.assertEqual(o.top.unused, None)
        self.assertEqual(o.top.prop.subprop[0].unused, None)
        self.assertEqual(o.top.simple[0].text, 'simple')

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
        self.assertEqual(o.tostring(), xmlOutText)


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
        assert(o.tostring(xml_declaration = False) == xmlString)

        class Top(xobj.Document):
            nameSpaceMap = { 'other3' : 'http://other/other2' }

        o = xobj.parsef(xml, documentClass = Top)
        assert(o.top.other_tag.other_val == '1')
        assert(o.top.other3_tag.val == '2')
        newXmlString = xmlString.replace("other2:", "other3:")
        newXmlString = newXmlString.replace(":other2", ":other3")
        assert(o.tostring(xml_declaration = False) == newXmlString)

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
        xobj.parsef(xml, schemaf = schema)

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

        class Ref(xobj.XObject):
            other = xobj.XIDREF

        class Top(xobj.XObject):
            ref = Ref

        class Document(xobj.Document):
            top = Top

        d = xobj.parsef(xml, documentClass = Document)
        assert(d.top.ref.other == d.top.item)
        s2 = d.tostring(xml_declaration = False)
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

        class Item(xobj.XObject):
            anid = xobj.XID
        Top.item = Item

        d = xobj.parsef(xml, documentClass = Document)
        assert(d.top.ref.other == d.top.item)
        s2 = d.tostring(xml_declaration = False)
        self.assertEquals(s, s2)

        # and test if the id isn't defined properly
        class Top(xobj.XObject):
            _attributes = set(['ref'])
            ref = xobj.XIDREF
        Document.top = Top

        d = Document()
        d.top = Top()
        d.top.ref = xobj.XObjectStr('something')
        try:
            d.tostring()
        except xobj.XObjSerializationException, e:
            self.assertEquals(str(e), 'No id found for element referenced by ref')
        else:
            assert(0)

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
        s2 = d.tostring(xml_declaration = False)

        expecteds2 = (
            '<ns:top xmlns:ns="http://somens.xsd">\n'
            '  <ns:element ns:attr="foo"/>\n'
            '</ns:top>\n'
            )
        assert(s2 == expecteds2)

    def testUnknownType(self):
        s ='<top/>'
        xml = StringIO(s)

        class Document(xobj.Document):
            top = object

        self.assertRaises(xobj.UnknownXType, xobj.parsef, xml,
                          documentClass = Document)

    def testTypeMap(self):
        s ='<top><item val="3"/></top>'
        xml = StringIO(s)

        class D(xobj.Document):
            typeMap = { 'val' : int }

        d = xobj.parsef(xml, documentClass = D)
        assert(d.top.item.val == 3)

        class I(xobj.XObject):
            val = int

        d = xobj.parsef(xml, typeMap = { 'item' : I} )
        assert(d.top.item.val == 3)

    def testEmptyList(self):
        class Top(xobj.XObject):
            l = [ int ]

        d = xobj.parse("<top/>", typeMap = { 'top' : Top })
        assert(d.top.l == [])

    def testUnion(self):
        class TypeA(xobj.XObject):
            vala = int

        class TypeB(xobj.XObject):
            valb = int

        class Top(xobj.XObject):
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
        assert(s == d.tostring(xml_declaration = False))

        d = xobj.parse('<top/>', typeMap = { 'top' : Top } )
        assert(d.top.items == [])

if __name__ == "__main__":
    testsuite.main()
