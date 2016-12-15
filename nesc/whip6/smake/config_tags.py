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
APP_NAME = 'app name'
BOARD = 'board'
BOARDS = 'boards'
COMP_TARGETS = 'composite targets'
DEFINITIONS = 'define'
DEPENDENCIES = 'dependencies'
DIRECT_TARGETS = 'direct targets'
NESC_ARGS = 'nesc arguments'
REG_IFACE_SPECS = 'register interface specs'
BUILD_DIR = 'build dir'
BANK_MAP = 'bank map'
OBJ_TO_BANK = 'object file to bank mapping'
RUN_MAKE_IN = 'run make at'
MAKE_OPTS = 'make options'
OVERWRITE_FLASH = 'overwrite flash image'
WNESC_ARGS = 'wnesc arguments'
INTERRUPTS = 'interrupts'
WNESC_BANKS = 'wnesc banks'

# private
CONF_PATH = '__CONF_PATH__'

# Configuration files schema verification. Each entry has a typechecking
# predicate and decription of the expected type.
def _comp_targets_typecheck(t):
  if not isinstance(t, dict):
    return False
  if t.values():
    if not isinstance(t.values()[0], list):
      return False
  return True

TAG_SECTION_TYPES = {
    APP_NAME:        (lambda t: isinstance(t, str),  'string'),
    BOARD:           (lambda t: isinstance(t, str),  'string'),
    COMP_TARGETS:    (_comp_targets_typecheck,       'dictonary of lists'),
    DEFINITIONS:     (lambda t: isinstance(t, list), 'list'),
    DEPENDENCIES:    (lambda t: isinstance(t, list), 'list'),
    DIRECT_TARGETS:  (lambda t: isinstance(t, list), 'list'),
    NESC_ARGS:       (lambda t: isinstance(t, dict), 'dictonary'),
    REG_IFACE_SPECS: (lambda t: isinstance(t, list), 'list'),
    BUILD_DIR:       (lambda t: isinstance(t, str),  'string'),
    BANK_MAP:        (lambda t: isinstance(t, dict), 'dictonary'),
    OBJ_TO_BANK:     (lambda t: isinstance(t, list), 'list'),
    RUN_MAKE_IN:     (lambda t: isinstance(t, list), 'list'),
    OVERWRITE_FLASH: (lambda t: isinstance(t, dict), 'list'),
    WNESC_ARGS:      (lambda t: isinstance(t, dict), 'dictionary'),
    INTERRUPTS:      (lambda t: isinstance(t, dict), 'dictionary'),
    WNESC_BANKS:     (lambda t: isinstance(t, dict), 'dictionary'),
}

