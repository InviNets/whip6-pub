import os
import os.path
import sys
from distutils.spawn import find_executable

from build_step import BuildStep

UNIFLASH_CONFIG = 'uniflash config file'

class ProgBl(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def run_step(self):
    config_file = self.find_config_value(UNIFLASH_CONFIG)
    if not config_file:
        raise RuntimeError("Platform did not define the mandatory "
                "setting '%s' in build.spec" % (UNIFLASH_CONFIG,))
    config_file = os.path.join(self.project_root, config_file)
    if find_executable('uniflash.sh'):
        self.call('uniflash.sh', '-ccxml', config_file,
            '-program', os.path.join(self.build_dir, 'app.workingcopy.hex'),
            '-verify', os.path.join(self.build_dir, 'app.workingcopy.hex'),
            '-targetOp', 'reset')
    elif find_executable('dslite.sh'):
        self.call('dslite.sh', '-c', config_file, '-f', '-v', '-e',
            '-s', 'ResetOnRestart=true',
            '-b', 'Erase',
            os.path.join(self.build_dir, 'app.workingcopy.hex'))
    else:
        raise RuntimeError("Neither uniflash.sh nor dslite.sh found. "
                "Please install TI Uniflash and make sure one of these "
                "scripts is on PATH.")

# Exports the BuildStep to make it visible for smake
BuildStepImpl = ProgBl
