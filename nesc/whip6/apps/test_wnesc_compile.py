#!/usr/bin/env python3
#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Przemyslaw Horban
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#

import intelhex
import os
import os.path
import shutil
import subprocess
import time

from collections import defaultdict
from termcolor import colored

BANK_FILES = {
   'HOME.hex',
   'BANK1.hex',
   'BANK2.hex',
   'BANK3.hex',
   'BANK4.hex',
}

results = defaultdict(dict)

def get_status_str(value):
   return colored('ok', 'green') if value else colored('error', 'red')

for (dirpath, dirnames, filenames) in os.walk('.'):
   if 'build.spec' not in filenames:
      continue

   with open(os.path.join(dirpath, 'build.spec')) as f: 
      if 'fedo' not in f.read():
         continue
   try:
     shutil.rmtree(os.path.join(dirpath, 'build', 'fedo'))
   except FileNotFoundError:
     pass
   os.makedirs(os.path.join(dirpath, 'build', 'fedo'))
   old_wd = os.getcwd()
   os.chdir(dirpath)

   before_call = time.perf_counter()
   return_code = subprocess.call(('smake', 'fedo', 'wnesccompile'))
   after_call = time.perf_counter()

   results[dirpath]['time'] = after_call - before_call

   if return_code != 0:
      results[dirpath]['status'] = False
   else:
      results[dirpath]['status'] = True
      if subprocess.call(('smake', 'fedo', 'sdcccompile')) != 0:
         results[dirpath]['sdcccompile-status'] = False
      else:
         results[dirpath]['sdcccompile-status'] = True
         if subprocess.call(('smake', 'fedo', 'buildhex')) != 0:
            results[dirpath]['buildhex-status'] = False
         else:
            results[dirpath]['buildhex-status'] = True
            total_size = 0
            overflow = False
            for filename in os.listdir(os.path.join('build', 'fedo')):
               if filename in BANK_FILES:
                  hex_file = intelhex.IntelHex(os.path.join('build', 'fedo', filename))
                  size = hex_file.maxaddr() - hex_file.minaddr()
                  total_size += size
                  if size >= 32767:
                     overflow = True
            results[dirpath]['size'] = total_size
            results[dirpath]['overflow'] = overflow


   os.chdir(old_wd)

apps_good, apps_bad = [], []

for app, data in results.items():
   if data['status']:
      apps_good.append(app)
   else:
      apps_bad.append(app)

with open('results.csv', 'w') as f:
   f.write('name,time,size,overflow\n')
   for app, data in results.items():
      if data['status'] and data['sdcccompile-status'] and data['buildhex-status']:
         f.write('{},{},{},{}\n'.format(app, data['time'], data['size'], data['overflow']))

print('----------------------------------------------------------')
print(colored('good apps:', 'green'), ','.join(apps_good))
print(colored('bad apps:', 'red'), ','.join(apps_bad))
print('result: {}/{}'.format(len(apps_good), len(apps_good) + len(apps_bad)))
