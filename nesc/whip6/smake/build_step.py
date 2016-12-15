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
import shutil
import subprocess
from termcolor import colored

from config_tags import BUILD_DIR

def truncate(string, max_len):
    if len(string) > max_len:
        return string[:(max_len - 3)] + '...'
    else:
        return string

class BuildError(Exception):
    pass

class BuildStep(object):
    """Represents an abstract build step"""

    def __init__(self, project_root, configs, flags):
        """
        Args:
          project_root: abs. path to project directory, i.e. whip6/nesc/whip6
          app_root: abs. path to the application directory
          build_dir: path to the directory with built files
          step_dir: path to the directory containting the build step implementation
          configs: topological ordered list of read configurations
          flags: -W<option> options passed to smake

        Returns: int - this should be the exit code of ran command. 0 will
                       be interpreted as successful completion
        """
        self.project_root = project_root
        self.configs = configs
        self.flags = flags

        self.build_dir = self.find_config_value(BUILD_DIR)
        if not self.build_dir:
            print colored('Warning: "build dir" not defined. This is ok, '
            'if build step does not need one.', 'yellow')

        self.board = flags.pop(-1)
        self.target_args = flags.pop(-1)
        self.step_dir = flags.pop(-1)
        self.target_name = flags.pop(-1)
        self.alt_project_root = flags.pop(-1)

    def collect_config_list(self, key):
        values = []
        for config in self.configs:
            values.extend(config.get(key, []))
        return values

    def find_config_value(self, key, default=None):
        found = False
        value = default
        for config in self.configs:
            if key in config:
                if found:
                    raise ValueError('"%s" defined twice' % (key,))
                value = config[key]
                found = True
        return value

    def run_step(self):
        """Does the actual building"""
        raise NotImplementedError

    def call(self, *args, **kwargs):
        call_args = []
        for a in args:
            if isinstance(a, list):
                call_args += a
            else:
                call_args.append(a)

        real_command = ' '.join(call_args)

        save_stdout = kwargs.pop('save_stdout', None)
        if save_stdout is not None:
            stdout_file_name = os.path.join(self.build_dir, save_stdout)
            f = open(stdout_file_name, 'w')
            real_command += ' > %s' %  stdout_file_name
            kwargs['stdout'] = f
        else:
            f = None

        self._show_command(real_command)

        try:
            result = subprocess.call(call_args, **kwargs)
            if result != 0:
                raise BuildError('Command "%s" returned %d' % (
                    truncate(real_command, 100), result))
        except OSError, e:
          raise BuildError('Failed to execute "%s": %s' % (
                real_command, e))

        if f:
            f.close()

        return self

    def move(self, src, trg):
        # TODO: If exception occurs here, turn it
        # into a BuildError
        shutil.move(
                os.path.join(self.build_dir, src),
                os.path.join(self.build_dir, trg))
        self._show_command('mv %s %s' % (src, trg))
        return self

    def copy(self, src, trg):
        # TODO: If exception occurs here, turn it
        # into a BuildError
        shutil.copyfile(
                os.path.join(self.build_dir, src),
                os.path.join(self.build_dir, trg))
        self._show_command('cp %s %s' % (src, trg))
        return self

    def _show_command(self, command):
        if 'show_commands' in self.flags:
            print colored(command, 'yellow')
