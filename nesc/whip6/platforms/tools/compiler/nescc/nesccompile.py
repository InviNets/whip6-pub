#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Przemyslaw Horban
# Copyright (c) 2012-2017 Szymon Acedanski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE
# files.
#
import os
import subprocess
import sys
import tempfile
import shutil

from build_step import BuildStep, BuildError

from config_tags import APP_NAME
from config_tags import CONF_PATH
from config_tags import DEFINITIONS
from config_tags import DEPENDENCIES
from config_tags import NESC_ARGS

GCC_PREFIX = 'gcc prefix'
INCL_PATHS = 'include paths'
NESC_DEFINE = 'nesc define'

class NescBuilder(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)
    self.include_paths = [os.path.join(self.project_root,
                'platforms/tools/compiler/nescc/include'), self.build_dir]
    self.defines = []
    self.nescc_args = {}
    self.app_name = None

  def run_step(self):
    for config in self.configs:
      self.include_paths.append(config[CONF_PATH])

      if INCL_PATHS in config:
        self.include_paths.extend(config[INCL_PATHS])

      if DEFINITIONS in config:
        self.defines.extend(config[DEFINITIONS])

      if NESC_DEFINE in config:
        self.defines.extend(config[NESC_DEFINE])

      if NESC_ARGS in config:
        for name, value in config[NESC_ARGS].items():
          self.nescc_args[name] = value

      if APP_NAME in config:
        if self.app_name:
          raise ValueError('App name already specified')
        else:
          self.app_name = config[APP_NAME]

    if not self.app_name:
      raise ValueError('App name not specified. Define "app name:"')

    wiring_dumpfile = os.path.join(self.build_dir,
          'app.workingcopy.wiring.xml')

    self.call(
          'nescc',
          self._get_nesc_arg_list(),
          '-gcc=%s' % self._find_suitable_gcc(),
          '-std=c99',
          '-fnesc-cfile=%s/app.workingcopy.c' % self.build_dir,
          '-fnesc-dump=wiring',
          '-fnesc-dump=interfaces(!abstract())',
          '-fnesc-dump=referenced(interfacedefs, components)',
          '-fnesc-dumpfile=%s' % wiring_dumpfile,
          '-fnesc-separator=___',
          '-conly',
          '%s.nc' % self.app_name)
    self.copy('app.workingcopy.c', 'app.nesccompile.c')

    # nescc-wiring, contrary to its man page, does not return a non-zero
    # status if some check fails. We determine success by verifying that
    # it does not print anything on stderr.
    with tempfile.TemporaryFile() as wiring_stderr:
        self.call('nescc-wiring', wiring_dumpfile, stderr=wiring_stderr)
        wiring_stderr.flush()
        if wiring_stderr.tell() != 0:
            wiring_stderr.seek(0)
            if [l for l in wiring_stderr.readlines() if not '_JAVA_OPTIONS' in l]:
                wiring_stderr.seek(0)
                shutil.copyfileobj(wiring_stderr, sys.stderr)
                raise BuildError("nesC wiring check failed")

  def _get_nesc_arg_list(self):
    args = []
    for name, value in self.nescc_args.items():
      if isinstance(value, list):
        for part in value:
          args.append(self._arg(name, part))
      else:
        args.append(self._arg(name, value))
    for name in self.defines:
      args.append('-D%s' % name)

    # In the past (nesc < 1.3) nesc used the target compiler for
    # preprocessing. Now it's no more, it has its own. But it does
    # not know the target compiler's include paths (it uses /usr/include
    # etc.!). This is sad, but we have to pass them explicitly, and I think
    # this is the most reasonable place for it.
    if self._compiler_type() == 'SDCC':
      sdcc_prefix = os.path.join(
          os.path.dirname(subprocess.check_output(['which', 'sdcc'])), '..')
      self.include_paths.append(
          os.path.join(sdcc_prefix, 'share/sdcc/include'))
      args.append('-nostdinc')
      # This is needed by nesc1 (preprocessor). It looks like a typo there.
      args.append('-fnostdinc')

    for path in self.include_paths:
      args.append(self._arg('I' + path, None))

    return args

  def _arg(self, name, value):
    if value:
      return '-%s=%s' % (name, str(value))
    else:
      return '-%s' % name

  def _compiler_type(self):
    for candidate in ['SDCC', 'ARMGCC']:
      if any(candidate in define for define in self.defines):
        return candidate
    return 'NATIVE'

  def _find_native_gcc(self):
    check_compilers = ['gcc-4.6', 'gcc-mp-4.6', 'gcc-4.7', 'gcc-4.8',
            'gcc-4.9', 'gcc-4.5', 'gcc-4.4', 'gcc-4.3',
            'gcc-4.2', 'gcc-apple-4.2', 'gcc']
    for c in check_compilers:
      try:
        version = subprocess.check_output([c, '-v'], stderr=subprocess.STDOUT)
        if 'LLVM' in version:
          continue
        if c != 'gcc-4.6':
          print('WARNING: gcc-4.6 not found. Note that this is the recommended')
          print('compiler version for NesC.')
        return c
      except Exception:
        pass
    raise RuntimeError("No native gcc found.")

  def _find_suitable_gcc(self):
    compiler_type = self._compiler_type()
    if compiler_type == 'SDCC':
      return self._find_native_gcc()
    elif compiler_type == 'ARMGCC':
      return self.find_config_value(GCC_PREFIX, '') + 'gcc'
    elif compiler_type == 'NATIVE':
      return self._find_native_gcc()
    else:
      raise RuntimeError("Unknown compiler type: %s" % (compiler_type,))


# Exports the BuildStep to make it visible for smake
BuildStepImpl = NescBuilder
