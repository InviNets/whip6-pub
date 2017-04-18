#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Przemyslaw Horban
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
import glob
import time
import cStringIO
from os.path import join

from build_step import BuildStep


SYMBOL = 'UINT16_ID_UNIQUE_IN_APPC'
REMOVE_LINE = 'extern uint16_t UINT16_ID_UNIQUE_IN_APPC;'



class SetUniqueIdInAppC(BuildStep):
  def __init__(self, project_root, configs, flags):
    BuildStep.__init__(self, project_root, configs, flags)


  def run_step(self):
    targetPaths = glob.glob(join(self.build_dir, '*.[ch]'))
    bestIdsList = self._findEfficientNumbers(999)
    firstId = 0
    for cFile in targetPaths:
      firstId = self._replaceWithNumbers(cFile, bestIdsList, firstId)

  def _replaceWithNumbers(self, cFile, bestIdsList, firstId):
    with open(cFile, 'r') as f:
      contents = f.read()
    contents = contents.replace(REMOVE_LINE, '')
    parts = contents.split(SYMBOL)
    io = cStringIO.StringIO()
    io.write(parts[0])
    for p in parts[1:]:
      io.write(str(bestIdsList[firstId]))
      io.write(p)
      firstId += 1
    with open(cFile, 'w') as f:
      f.write(io.getvalue())
    return firstId

  def _findEfficientNumbers(self, maxNumber):
    """Efficient numbers are thouse which have no 0s (101 - bad),
    are short and have a small digit sum"""
    candidates = []
    for i in xrange(1, maxNumber + 1):
      hasZero, cost = self._evaluateNumber(i)
      if not hasZero:
        candidates.append((cost, i))
    candidates.sort()
    return [i for _, i in candidates]

  def _evaluateNumber(self, n):
    digCnt = 0
    digSum = 0
    while n != 0:
      d = n % 10
      digSum += d
      if d == 0:
        return True, -1
      n /= 10
      digCnt += 1

    return (False, (digCnt + digSum))

# Exports the BuildStep to make it visible for smake
BuildStepImpl = SetUniqueIdInAppC

# vim:sw=2
