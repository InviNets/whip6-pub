#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2016 InviNets Sp z o.o.
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files. If you do not find these files, copies can be found by writing
# to technology@invinets.com.
#
import glob
import re
from os.path import join
from termcolor import colored


from build_step import BuildStep

PRINTF_PATTERN = re.compile(ur'printf\s*\(\s*"')
WARNING_MSG = '''
+-------------------------------------------------------------------+
|                                                                   |
|                           !!! WARNING !!!                         |
|              PRINTF STATEMENTS DETECTED IN *.c FILES!             |
|                                                                   |
+-------------------------------------------------------------------+
'''.strip()  # Remove leading \n

class WarnAboutPrintfs(BuildStep):
    def __init__(self, project_root, configs, flags):
        BuildStep.__init__(self, project_root, configs, flags)


    def run_step(self):
        c_files = glob.glob(join(self.build_dir, '*.[c]'))
        for cFile in c_files:
            with open(cFile, 'r') as f:
                if PRINTF_PATTERN.search(f.read()):
                    print colored(WARNING_MSG, 'yellow')
                    return

BuildStepImpl = WarnAboutPrintfs

# vim:sw=2
