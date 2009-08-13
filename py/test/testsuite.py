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
import os
import sys
import unittest

import bootstrap
from testrunner import pathManager

#from pychecker import checker

_setupPath = None
_individual = False

def isIndividual():
    global _individual
    return _individual

def setup():
    """
    Setup initializes variables must be initialized before the testsuite
    can be run.  Generally this means setting up and determining paths.
    """
    global _setupPath
    if _setupPath:
        return _setupPath

    xobjPath = pathManager.addExecPath('CONARY_PATH')

    xobjPath = pathManager.addExecPath('XOBJ_PATH')
    xobjTestPath = pathManager.addExecPath('XOBJ_TEST_PATH')
    pathManager.addExecPath('TEST_PATH',path=xobjTestPath)

    from conary.lib import util
    sys.excepthook = util.genExcepthook(True, catchSIGUSR1=False)

    _setupPath = xobjPath
    return xobjPath

def getCoverageDirs(handler, environ):
    return  pathManager.getPathList('XOBJ_PATH')

def getExcludePaths(handler, environ):
    return ['scripts/.*', 'epdb.py', 'stackutil.py',
                              'test/.*']

def sortTests(tests):
    order = {'smoketest': 0, 
             'unit_test' :1,
             'functionaltest':2}
    maxNum = len(order)
    tests = [ (test, test.index('test')) for test in tests]
    tests = sorted((order.get(test[:index+4], maxNum), test)
                   for (test, index) in tests)
    tests = [ x[1] for x in tests ]
    return tests

def main(argv=None, individual=True):
    global _individual
    _individual = individual

    setup()

    if argv is None:
        argv = list(sys.argv)

    from conary.lib import util
    from conary.lib import coveragehook
    sys.excepthook = util.genExcepthook(True, catchSIGUSR1=False)

    from testrunner import testhelp
    handlerClass = testhelp.getHandlerClass(testhelp.ConaryTestSuite,
                                            getCoverageDirs,
                                            getExcludePaths,
                                            sortTests)

    handler = handlerClass(individual=individual, topdir=pathManager.getPath("XOBJ_TEST_PATH"),
                           testPath=pathManager.getPath("XOBJ_TEST_PATH"), conaryDir=pathManager.getPath("CONARY_PATH"))
    
    print "This process PID:", os.getpid()
    results = handler.main(argv)
    if results is None:
        sys.exit(0)
    sys.exit(not results.wasSuccessful())

if __name__ == '__main__':
    main(sys.argv, individual=False)
