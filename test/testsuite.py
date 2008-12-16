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
from testrunner import testhelp
from testrunner import resources, testhandler

#from pychecker import checker

_setupPath = None

def setup():
    """
    Setup initializes variables must be initialized before the testsuite
    can be run.  Generally this means setting up and determining paths.
    """
    global _setupPath
    if _setupPath:
        return _setupPath

    xobjPath = testhelp.getPath('XOBJ_PATH')
    os.environ['XOBJ_PATH'] = xobjPath
    for path in xobjPath.split(':'):
        if not os.path.isdir(path):
            print 'XOBJ_PATH %s does not exist' %path
            sys.exit(1)
    testhelp.insertPath(testhelp.getPath('XOBJ_PATH'), updatePythonPath=True)

    from testrunner import testSetup
    testSetup.setup()

    from conary.lib import util
    sys.excepthook = util.genExcepthook(True, catchSIGUSR1=False)

    testhelp._conaryDir = resources.conaryDir
    _setupPath = path
    return path

def main(argv=None, individual=True):
    cfg = resources.cfg
    cfg.isIndividual = individual

    setup()

    cfg.cleanTestDirs = not individual
    cfg.coverageExclusions = ['scripts/.*', 'epdb.py', 'stackutil.py',
                              'test/.*']
    cfg.coverageDirs = [ os.environ['XOBJ_PATH'] ]

    if argv is None:
        argv = list(sys.argv)
    topdir = testhelp.getTestPath()
    if topdir not in sys.path:
        sys.path.insert(0, topdir)
    cwd = os.getcwd()
    if cwd != topdir and cwd not in sys.path:
        sys.path.insert(0, cwd)



    from conary.lib import util
    from conary.lib import coveragehook
    sys.excepthook = util.genExcepthook(True, catchSIGUSR1=False)

    handler = testhandler.TestSuiteHandler(cfg, resources)
    print "This process PID:", os.getpid()
    results = handler.main(argv)
    if results is None:
        sys.exit(0)
    sys.exit(not results.wasSuccessful())

if __name__ == '__main__':
    #testDir = os.path.dirname(__file__)
    #if not os.path.exists(testDir + '/conarytest/testsetup.py'):
    #    print "Executing makefile to create required symlinks..."
    #    os.system('make')
    main(sys.argv, individual=False)
