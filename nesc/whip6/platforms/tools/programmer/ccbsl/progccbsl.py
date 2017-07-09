import os
import os.path
import sys

from build_step import BuildStep

base_dir = os.path.abspath(os.path.dirname(__file__))

class ProgBl(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)
    self.ccbsl_flags = ['--' + f[len('--ccbsl-'):] for f in flags if f.startswith('--ccbsl-')]

  def run_step(self):
    self.call(os.path.join(base_dir, 'cc2538-bsl.py'),
            '-b', '115200',  # some serial ports do not support higher speed
            '-e', '-w', '-v',
            os.path.join(self.build_dir, 'app.workingcopy.hex'),
            self.ccbsl_flags)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = ProgBl
