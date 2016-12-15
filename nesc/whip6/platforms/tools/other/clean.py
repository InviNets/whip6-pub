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
import subprocess

from build_step import BuildStep

class CleanRun(BuildStep):
  def __init__(self,  project_root, configs, flags):
      BuildStep.__init__(self,  project_root, configs, flags)

  def run_step(self):
      if os.path.exists(self.build_dir):
          self.call(
                  'rm',
                  '-rf',
                  self.build_dir)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = CleanRun
