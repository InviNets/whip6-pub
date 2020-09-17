#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Szymon Acedanski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE
# files.
#
import fileinput
import os
import re
import sys
import shlex

from build_step import BuildStep
from config_tags import APP_NAME, CONF_PATH, DEFINITIONS, MAKE_OPTS

EXTERNAL_OBJS = 'external objects'
BUILT_OBJS = 'built objects'
INCL_PATHS = 'include paths'
C_FLAGS = 'c flags'
LD_FLAGS = 'ld flags'
MAKEFILE = 'main makefile'

class MakeBuildRun(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def _gen_makefile(self, f):
    app_name = self.find_config_value(APP_NAME)

    include_paths = []
    for config in self.configs:
      include_paths.append(config[CONF_PATH])
    include_paths.extend(self.collect_config_list(INCL_PATHS))
    defines = self.collect_config_list(DEFINITIONS)
    cflags = self.collect_config_list(C_FLAGS)
    cflags.extend(['-I' + p for p in include_paths])
    cflags.extend(['-D' + d for d in defines])

    ldflags = self.collect_config_list(LD_FLAGS)

    objects = self.collect_config_list(BUILT_OBJS)
    #objects = map(lambda o: os.path.join(self.build_dir, o), objects)
    objects.extend(self.collect_config_list(EXTERNAL_OBJS))
    objects.append('app.workingcopy.o')
    objects.reverse()

    makefile = self.find_config_value(MAKEFILE)
    if not makefile:
        raise RuntimeError('no "%s" specified' % (MAKEFILE,))
    print('APP_NAME :=', app_name, file=f)
    print('BOARD_NAME :=', self.board, file=f)
    print('PROJECT_ROOT :=', self.project_root, file=f)
    print('ALT_PROJECT_ROOT :=', self.alt_project_root, file=f)
    print('BUILD_DIR :=', self.build_dir, file=f)
    print('LDFLAGS += ', ' '.join(ldflags), file=f)
    print('CFLAGS += ', ' '.join(cflags), file=f)
    print('OBJS :=', ' '.join(objects), file=f)
    print('include ', makefile, file=f)

  def run_step(self):
    makeopts = self.collect_config_list(MAKE_OPTS)
    with open(os.path.join(self.build_dir, 'Makefile'), 'w') as f:
        self._gen_makefile(f)
    self.call(['make', '-B', '-C', self.build_dir] + makeopts)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = MakeBuildRun
