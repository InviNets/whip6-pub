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

# Core logic of smake build system

import argparse
import os
import re
import sys
import yaml
from collections import defaultdict

from termcolor import colored

from build_step import BuildError

from config_tags import TAG_SECTION_TYPES
from config_tags import APP_NAME
from config_tags import BOARD
from config_tags import COMP_TARGETS
from config_tags import DIRECT_TARGETS
from config_tags import DEPENDENCIES
from config_tags import CONF_PATH
from config_tags import BOARDS

from config_consts import BOARD_VAR
from config_consts import SPEC_DIR_VAR
from config_consts import REPO_PATH_VAR
from config_consts import PRV_REPO_PATH_VAR

parser = argparse.ArgumentParser(description='Build and install sensor node os.')

parser.add_argument('board', metavar='BOARD', type=str, nargs='?',
                    help='Name of the board to build for',
                    default=None)

parser.add_argument('target', metavar='TARGET', type=str, nargs='?',
                    default='all',
                    help='Target - "all" is the default')

parser.add_argument('target_args', metavar='TARGET ARGUMENTS', type=str, nargs='*',
                    help='Any arguments passed to the target')


parser.add_argument('--boards_dir', dest='boards_dirs', action='append',
                    default=[os.path.join('platforms', 'boards'),
                             os.path.join('platforms', 'pc')],
                    help='Directory containing board definitions',
                    metavar='BOARDS_DIR')

parser.add_argument('--list-boards', action='store_true', dest='list_boards',
                    help='Only list boards available for the application.')

parser.add_argument('-f', '--force', action='store_true', dest='force',
                    help='Proceed even if the board is not compatible with '
                         'the app.')

parser.add_argument('--conf_name', dest='conf_name',
                    default='build.spec',
                    help='Name of the file that, if found in a'
                         'package will be treated as config file.'
                         ' (default: build.spec)',
                    metavar='SPEC_NAME')

parser.add_argument('--show_config_paths', action='store_true',
                    help='Shows all dependencie paths')

parser.add_argument('--project_root_to_repo', dest='project_root_to_repo',
                    default = '../..',
                    help='Path from smake project root to the repository root',
                    metavar = 'TO_REPO')

parser.add_argument('--project_root_to_alt_project_root', dest='project_root_to_alt_project_root',
                    default = 'prv',
                    help='Path from smake project root to the alternative project root',
                    metavar = 'TO_REPO')

parser.add_argument('-W', action='append', dest='flags',
                    help='Pass configuration flags to all targets. '
                    'I.e.: -Wshow_commands')

args = parser.parse_args()

def fail(msg):
  print(colored(msg, 'red'))
  sys.exit(1)

class SMake(object):
  def __init__(self, project_root):
    self.project_root = project_root
    self.alt_project_root = os.path.realpath(os.path.join(
        project_root, args.project_root_to_alt_project_root))
    repo_path = os.path.realpath(os.path.join(
        project_root, args.project_root_to_repo))
    prv_repo_path = os.path.realpath(os.path.join(
      self.alt_project_root, args.project_root_to_repo))
    self.constants_in_conf = { REPO_PATH_VAR: repo_path, PRV_REPO_PATH_VAR: prv_repo_path }
    self.boards = self._find_boards()

  def run(self):
    available_board_names = self._available_board_names()
    if args.list_boards:
      for board_name in available_board_names:
        print(board_name)
      sys.exit(0)

    if not args.board:
      self._show_boards_and_quit('No board selected')

    self.board = board = args.board
    self.constants_in_conf[BOARD_VAR] = board

    if args.board not in available_board_names and not args.force:
      fail('This app is available for the following platforms only: %s. '
           'You may add %s to the list of boards in build.spec or use '
           'the --force option.' % (
          ', '.join(available_board_names), args.board))
      sys.exit(1)

    target = args.target

    # Verify the board argument
    if board not in self.boards:
      self._show_boards_and_quit('Unknown board.')

    # Read configurations recursively
    configs = self._recursive_config_list(
        [os.getcwd(), self.boards[board]], suffixes=[board])

    # Parse the targets
    direct_targets, dir_ip = self._load_direct_targets(configs)
    composite_targets, com_ip = self._load_composite_targets(configs)

    # Check for target collisions
    for name in composite_targets.keys():
      if name in direct_targets:
        fail('Target "%s" ambiguity between %s and %s' %
             (name, dir_ip[name],
                 ', and '.join(com_ip[name])))
        sys.exit(1)

    # Verify target argument
    if target not in direct_targets and target not in composite_targets:
      print(colored('Unknown target. Choose one of:', 'yellow'))
      self._show_board_targets(board)
      sys.exit(1)

    # Recursively make target
    targets_ready = set()
    target_history = []

    def make(new_target):
      if new_target in targets_ready:
        return

      if new_target in target_history:
        fail('Target loop detected:')
        for t in target_history:
          fail(t),
        print('')
        sys.exit(1)

      target_history.append(new_target)

      if new_target in composite_targets:
        for sub_target in composite_targets[new_target]:
          make(sub_target)
      elif new_target in direct_targets:
        BuildStepClass = direct_targets[new_target]
        if not args.flags: args.flags = []
        # We will pass the target name, target dir and additional arguments
        # via flags last field totally a hack, but the
        # BuildStep constructor will clean it up.

        # Alt. project root
        args.flags.append(self.alt_project_root)

        # Target name
        args.flags.append(new_target)

        # Directory where target is located
        args.flags.append(os.path.dirname(dir_ip[new_target]))

        # Additional target args
        args.flags.append(args.target_args)

        # Board name
        args.flags.append(args.board)

        build_step = BuildStepClass(self.project_root,
                                    configs,
                                    args.flags)
        try:
          build_step.run_step()
        except BuildError as e:
          fail('Target "%s" failed - %s' % (new_target, str(e)))

      else:
        fail('Undefined target "%s"' % new_target)

      target_history.pop(-1)
      targets_ready.add(new_target)
      print(colored('Target %s complete.' % new_target, 'cyan'))

    make(target)  # Actually do the job
    print(colored('All targets completed successfully!', 'green'))

  def _available_board_names(self):
    config = self._read_config(os.getcwd())
    board_names = set(self.boards.keys());
    if BOARDS in config:
        board_names &= set(config[BOARDS])
    return list(board_names)

  def _show_board_targets(self, brd):
    # Read configurations recursively
    configs = self._recursive_config_list([self.boards[brd]])
    # Parse the targets
    direct_targets, dir_ip = self._load_direct_targets(configs)
    composite_targets, com_ip = self._load_composite_targets(configs)
    padding = max(max(len(k) for k in composite_targets.keys()),
                  max(len(k) for k in direct_targets.keys()))
    format_str = '%%%ds - %%s' % (padding + 9)
    for name in composite_targets.keys():
      print(format_str % (colored(name, 'cyan'), ', '.join(com_ip[name])))
    for name in direct_targets.keys():
      print(format_str % (colored(name, 'cyan'), dir_ip[name]))

  def _show_boards_and_quit(self, msg):
    print('%s. Choose one of:' % msg)
    brd_names = self._available_board_names()
    brd_names.sort()
    for brd in brd_names:
      print(colored(brd, 'green'), 'with target:')
      self._show_board_targets(brd)
    sys.exit(1)

  def _find_boards(self):
    boards = {}

    for boards_dir in args.boards_dirs:
      for search_root in [self.project_root, self.alt_project_root]:
        boards_root = os.path.join(search_root, boards_dir)
        for dirpath, dirnames, filenames in os.walk(boards_root):
          config_path = os.path.join(dirpath, args.conf_name)
          config = self._read_config(config_path)

          if BOARD in config:
            if config[BOARD] != os.path.basename(dirpath):
              print(('Warning: Board name in config should'
                    ' match its dir name %s' % dirpath), file=sys.stderr)
            if config[BOARD] in boards:
              raise ValueError('Conflicting board names %s and %s' %
                              (dirpath, boards[config[BOARD]]))
            boards[config[BOARD]] = dirpath

    return boards

  def _config_file_path(self, path, suffix=None):
    if os.path.isdir(path):
      conf_name = args.conf_name
      if suffix:
          base, ext = os.path.splitext(conf_name)
          conf_name = '%s-%s%s' % (base, suffix, ext)
      path = os.path.join(path, conf_name)
    return path

  def _read_config(self, path, suffix=None):
    path = self._config_file_path(path, suffix)
    if not os.path.isfile(path):
      return {}
    else:
      with open(path, 'r') as f:
        body = f.read()
        spec_dir = os.path.dirname(path)
        body = body.replace('$(%s)' % SPEC_DIR_VAR, spec_dir)
        for key, value in self.constants_in_conf.items():
          body = body.replace('$(%s)' % key, value)

        # Try replacing $VAR statements with env. variables
        for var in re.findall('\$\(([^\)]*)\)', body):
            val = os.getenv(var)
            if val:
                body = body.replace('$(%s)' % var, val)

        config = yaml.safe_load(body)
      return config

  def _recursive_config_list(self, search_roots, suffixes=()):
    visited = set()
    suffixes = [None] + list(suffixes)
    configs = [[] for i in range(len(suffixes))]

    def dfs(u):
      if not os.path.isdir(u):
        print(colored('Warning: Package %s does not exist' % u, 'yellow'))
      try:
        visited.add(u)

        for i, suffix in enumerate(suffixes):
          config = self._read_config(u, suffix)
          if config is None:
            fail('Empty specification file %s - remove it.' %
                 self._config_file_path(u))
          for tag, (iscorrect, expected_str) in TAG_SECTION_TYPES.items():
            if tag in config and not iscorrect(config[tag]):
              raise ValueError('Section "%s" of %s should be a %s' %
                               (tag, os.path.join(u, args.conf_name),
                                expected_str))

          if CONF_PATH in config:
            raise ValueError('Section %s is reserved' % CONF_PATH)
          if not os.path.isabs(u):
            raise ValueError('Internal Error: Absolute path expected')
          config[CONF_PATH] = u

          for v in self._extract_sub_deps(config):
            if v not in visited:
              dfs(v)

          configs[i].append(config)

        if args.show_config_paths:
          print(u)
      except:
        print('Error processing: %s' % os.path.join(u, args.conf_name))
        raise

    if args.show_config_paths:
      print('Dependencie paths:')

    for root in search_roots:
      if root not in visited:
        dfs(root)

    return sum(configs, [])

  def _extract_sub_deps(self, config):
    if DEPENDENCIES in config:
      paths = []
      for p in config[DEPENDENCIES]:
          found_p = False
          for r in [self.project_root, self.alt_project_root]:
              path = os.path.join(r, p)
              if os.path.exists(path):
                  paths.append(path)
                  found_p = True
          if not found_p:
              print(colored("WARNING: Dependency %s not found in config\n%s" %
                            (p, config[CONF_PATH]),
                            'yellow'))
      for i in range(len(paths)):
          if paths[i].endswith('/'):
              paths[i] = paths[i][:-1]
      return paths
    else:
      return []

  def _load_direct_targets(self, configs):
    targets = {}
    target_impl_paths = {}
    for config in configs:
      if DIRECT_TARGETS in config:
        for target_name in config[DIRECT_TARGETS]:
          py_file_path = os.path.join(config[CONF_PATH], target_name + '.py')
          if target_name in targets:
            print(('Target "%s" ambiguity between %s and %s' %
                   (target_name, target_impl_paths[target_name], py_file_path)))
            sys.exit(1)

          if not os.path.isfile(py_file_path):
            print(colored('Target "%s" script file %s not found' %
                   (target_name, py_file_path), 'yellow'))
            continue


          sys.path.append(config[CONF_PATH])
          module = __import__(target_name, globals(), locals(), [], 0)
          targets[target_name] = module.BuildStepImpl
          target_impl_paths[target_name] = py_file_path
    return targets, target_impl_paths

  def _load_composite_targets(self, configs):
    targets = defaultdict(list)
    target_impl_paths = defaultdict(list)

    for config in configs:
      if COMP_TARGETS in config:
        impl_path = os.path.join(config[CONF_PATH], args.conf_name)
        for target_name, dependent_targets in config[COMP_TARGETS].items():
          targets[target_name].extend(dependent_targets)
          target_impl_paths[target_name].append(impl_path)
    return targets, target_impl_paths
