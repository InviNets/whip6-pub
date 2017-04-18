#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Przemyslaw Horban
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
import os
import subprocess

from build_step import BuildStep

class BuildDirMakerRun(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def run_step(self):
      self.call(
              'mkdir',
              '-p',
              self.build_dir)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = BuildDirMakerRun
