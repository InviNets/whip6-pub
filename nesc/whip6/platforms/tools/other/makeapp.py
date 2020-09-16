#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Przemyslaw Horban
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
import os
import sys
import re
import shutil

from config_tags import RUN_MAKE_IN

from build_step import BuildStep, BuildError
from os import listdir
from os.path import isfile, join

APPS='apps'

class BuildNewAppFolder(BuildStep):
  def __init__(self,  project_root, configs, flags):
    BuildStep.__init__(self,  project_root, configs, flags)

  def run_step(self):
    coreName = input("What will be the core name of the "
            "app (fe. ButtonRadio, Blink)?\n> ").strip()

    if not re.match(r'^[A-Z]\w+$', coreName):
      raise BuildError("Error: Name must match regex ^[A-Z]\w+$")

    newAppPath = join(self.project_root, APPS, coreName)

    if os.path.exists(newAppPath):
      raise BuildError("Error: path %s already exists" % newAppPath)

    srcAppName = input("What will be the base app? This must be"
        " an existing app folder name\n"
            "[Blink] > ").strip()

    if not srcAppName:
      srcAppName = 'Blink'

    srcAppPath = join(self.project_root, APPS, srcAppName)

    if not os.path.exists(srcAppPath):
      raise BuildError("Error: Path %s does not exist" % srcAppPath)

    repName = input("What will be the replace word? This word will be"
        " replaced in all files with %s\n"
            "[%s] > " % (coreName, srcAppName)).strip()

    if not repName:
      repName = srcAppName

    shutil.copytree(srcAppPath, newAppPath)

    newFiles = [ f for f in listdir(newAppPath)
                   if isfile(join(newAppPath,f)) ]

    for f in newFiles:
      path = join(newAppPath, f)
      base, ending = os.path.split(path)
      newPath = join(base, ending.replace(repName, coreName))
      if newPath != path:
        shutil.move(path, newPath)

      with open(newPath, 'r') as newFile:
        content = newFile.read()
      with open(newPath, 'w') as newFile:
        newFile.write(content.replace(repName, coreName))


# Exports the BuildStep to make it visible for smake
BuildStepImpl = BuildNewAppFolder
