#!/usr/bin/python

import testsuite
testsuite.setup()
from testrunner import testhelp

from xobj import xobj
from StringIO import StringIO

class XobjTest(testhelp.TestCase):

    def testSimpleParse(self):
        xml = StringIO('<top attr="anattr">\n'
                       '    <!-- comment -->'
                       '    <prop>something</prop>\n'
                       '    <subelement subattr="2"/>\n'
                       '</top>\n')
        o = xobj.parsef(xml)
        self.assertEqual(o.top.__class__.__name__, 'top_XObj_Type')
        self.assertEqual(o.top.attr, 'anattr')
        self.assertEqual(o.top.prop, 'something')
        self.assertEqual(o.top.subelement.subattr, '2')

        # ---

        class SubelementClass(xobj.XObject):
            subattr = int

        class TopClass(xobj.XObject):
            subelement = SubelementClass
            unused = str

        class RootClass(xobj.RootXObject):
            top = TopClass

        o = xobj.parsef(xml, rootXClass = RootClass)
        self.assertEqual(o.top.subelement.subattr, 2)
        self.assertEqual(o.top.unused, None)

        # ---

        class SubelementClass(xobj.XObject):
            subattr = [ int ]
        TopClass.subelement = SubelementClass

        o = xobj.parsef(xml, rootXClass = RootClass)
        self.assertEqual(o.top.subelement.subattr, [ 2 ] )

        # ---

        TopClass.subelement = [ SubelementClass ]
        o = xobj.parsef(xml, rootXClass = RootClass)
        self.assertEqual(o.top.subelement[0].subattr, [ 2] )

    def testNamespaces(self):
        xmlString = ('<top xmlns="http://this" xmlns:other="http://other/other"'
                        ' xmlns:other2="http://other/other2">\n'
                     '  <local/>\n'
                     '  <other:tag val="1"/>\n'
                     '  <other2:tag val="2"/>\n'
                     '</top>\n')
        xml = StringIO(xmlString)
        o = xobj.parsef(xml)
        assert(o.top.other_tag.val == '1')
        assert(o.top.other2_tag.val == '2')
        assert(o.tostring() == xmlString)

        class Top(xobj.RootXObject):
            nameSpaceMap = { 'other3' : 'http://other/other2' }

        o = xobj.parsef(xml, rootXClass = Top)
        assert(o.top.other_tag.val == '1')
        assert(o.top.other3_tag.val == '2')
        newXmlString = xmlString.replace("other2:", "other3:")
        newXmlString = newXmlString.replace(":other2", ":other3")
        assert(o.tostring() == newXmlString)

if __name__ == "__main__":
    testsuite.main()
