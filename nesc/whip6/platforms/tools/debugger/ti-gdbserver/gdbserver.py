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
import sys

from build_step import BuildStep

CONFIG = 'ti jtag config file'

class TIGdbServer(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def run_step(self):
    config_file = self.find_config_value(CONFIG)
    if not config_file:
        raise RuntimeError("Platform did not define the mandatory "
                "setting '%s' in build.spec" % (CONFIG,))
    config_file = os.path.join(self.project_root, config_file)
    config_file = os.path.abspath(config_file)
    self.call('gdb_agent_console', config_file)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = TIGdbServer
