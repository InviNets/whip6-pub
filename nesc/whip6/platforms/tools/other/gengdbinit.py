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
import fileinput
import os
import re
import sys
from build_step import BuildStep
from config_tags import CONF_PATH

INCL_PATHS = 'include paths'
GDBINIT = 'gdbinit'

class GenGDBInitRun(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def _gen_gdbinit(self, f):
    paths = [self.build_dir]
    for config in self.configs:
      paths.append(config[CONF_PATH])
    paths.extend(self.collect_config_list(INCL_PATHS))
    for path in paths:
        print >>f, 'directory ', path

  def run_step(self):
    with open(os.path.join(self.build_dir, 'gdbinit'), 'w') as f:
      self._gen_gdbinit(f)
      for path in self.collect_config_list(GDBINIT):
        f.write(open(os.path.join(self.project_root, path)).read())

# Exports the BuildStep to make it visible for smake
BuildStepImpl = GenGDBInitRun
