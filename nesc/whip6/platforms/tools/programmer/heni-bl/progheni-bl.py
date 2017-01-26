import os
import os.path

from build_step import BuildStep

class ProgBl(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def run_step(self):
    self.call('heni-bl',
            os.path.join(self.build_dir, 'app.workingcopy.hex'),
            'pc',
            )

# Exports the BuildStep to make it visible for smake
BuildStepImpl = ProgBl
