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
import platform

from build_step import BuildStep

class FlashSize(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def run_step(self):
    size_dir = os.path.join(self.build_dir, 'app.nobl.flash.sizes')
    system = platform.system()
    if system == 'Darwin':
        self.call('open', '-a', 'GrandPerspective', size_dir)
    elif system == 'Linux':
        self.call('baobab', size_dir)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = FlashSize
