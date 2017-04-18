#!/usr/bin/env python
#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Szymon Acedanski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#

import os.path
import sys
import argparse
import errno

KINDS = {
    'flash': 'DdGgpRrTt',
    'ram': 'CDdGgBb',
}

parser = argparse.ArgumentParser(description='Creates a directory tree from a '
        'list of symbol (output of nm -t posix) with files of the sizes '
        'corresponding to the symbols. They can then be visualized with tools '
        'like Baobab.')
parser.add_argument('--kinds', '-k', choices=KINDS.keys(), default='flash',
        help='kinds of symbols to choose')
parser.add_argument('output_dir',
        help='output directory')

args = parser.parse_args()

kinds = KINDS[args.kinds]
for line in sys.stdin:
    tokens = line.split()
    if len(tokens) < 4:
        continue
    symbol, kind, offset, size = line.split()
    if kind not in kinds:
        continue
    offset = int(offset, 16)
    size = int(size, 16)
    parts = symbol.replace('lto_priv', 'ltopriv').split('_')
    parts = [part for part in parts if part]
    parts[-1] += '.size'
    filename = os.path.join(args.output_dir, *parts)
    try:
        os.makedirs(os.path.dirname(filename))
    except OSError, e:
        if e.errno != errno.EEXIST:
            raise
    with open(filename, 'wb') as f:
        f.write('X' * size)
