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
import os
import os.path
import subprocess
from termcolor import colored

from config_tags import RUN_MAKE_IN, MAKE_OPTS, DEFINITIONS

from build_step import BuildStep

class BuildExternalLibRun(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def get_num_threads(self):
    try:
      res = int(os.sysconf('SC_NPROCESSORS_ONLN'))
      if res > 0:
        return res
    except (AttributeError, ValueError):
      pass
    return 1

  def run_step(self):
    makeopts = self.collect_config_list(MAKE_OPTS)
    makeopts.append("PROJECT_ROOT=" + self.project_root)
    makeopts.append("BUILD_DIR=" + self.build_dir)
    num_threads = self.get_num_threads()
    for config in self.configs:
      if RUN_MAKE_IN in config:
         for l in config[RUN_MAKE_IN]:
           relative_l = l[(len(self.project_root) + 1):]
           print colored('Running make in %s ...' % (relative_l,), 'cyan')
           self.call('make', '-j', str(num_threads), '-C', l, *makeopts)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = BuildExternalLibRun
