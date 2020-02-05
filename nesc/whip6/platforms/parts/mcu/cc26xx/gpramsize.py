#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2020 Michal Siwinski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
import os
import os.path
import platform

from build_step import BuildStep

class GpramSize(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def run_step(self):
    size_dir = os.path.join(self.build_dir, 'app.nobl.gpram.sizes')
    system = platform.system()
    if system == 'Darwin':
        self.call('open', '-a', 'GrandPerspective', size_dir)
    elif system == 'Linux':
        self.call('baobab', size_dir)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = GpramSize
