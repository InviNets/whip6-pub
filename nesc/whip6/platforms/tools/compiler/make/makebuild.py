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
    cflags.extend(map(lambda p: '-I' + p, include_paths))
    cflags.extend(map(lambda d: '-D' + d, defines))

    ldflags = self.collect_config_list(LD_FLAGS)

    objects = self.collect_config_list(BUILT_OBJS)
    #objects = map(lambda o: os.path.join(self.build_dir, o), objects)
    objects.extend(self.collect_config_list(EXTERNAL_OBJS))
    objects.append('app.workingcopy.o')
    objects.reverse()

    makefile = self.find_config_value(MAKEFILE)
    if not makefile:
        raise RuntimeError('no "%s" specified' % (MAKEFILE,))
    print >>f, 'APP_NAME :=', app_name
    print >>f, 'PROJECT_ROOT :=', self.project_root
    print >>f, 'ALT_PROJECT_ROOT :=', self.alt_project_root
    print >>f, 'BUILD_DIR :=', self.build_dir
    print >>f, 'LDFLAGS += ', ' '.join(ldflags)
    print >>f, 'CFLAGS += ', ' '.join(cflags)
    print >>f, 'OBJS :=', ' '.join(objects)
    print >>f, 'include ', makefile

  def run_step(self):
    makeopts = self.collect_config_list(MAKE_OPTS)
    with open(os.path.join(self.build_dir, 'Makefile'), 'w') as f:
        self._gen_makefile(f)
    self.call(['make', '-B', '-C', self.build_dir] + makeopts)

# Exports the BuildStep to make it visible for smake
BuildStepImpl = MakeBuildRun
