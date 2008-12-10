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
                       '    </top>\n')
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


if __name__ == "__main__":
    testsuite.main()
