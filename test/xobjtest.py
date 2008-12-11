#!/usr/bin/python

import testsuite
testsuite.setup()
from testrunner import testhelp
from lxml import etree

from xobj import xobj
from StringIO import StringIO

class XobjTest(testhelp.TestCase):

    def testSimpleParse(self):
        xml = StringIO('<top attr1="anattr" attr2="another">\n'
                       '    <!-- comment -->'
                       '    <prop>something</prop>\n'
                       '    <subelement subattr="2"/>\n'
                       '</top>\n')
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

    def testNamespaces(self):
        xmlString = ('<top xmlns="http://this" xmlns:other="http://other/other"'
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


if __name__ == "__main__":
    testsuite.main()
