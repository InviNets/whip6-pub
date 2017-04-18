#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 InviNets Sp. z o.o.
# Copyright (c) 2012-2017 Przemyslaw Horban
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
dependencies:
  - api/sys/scheduler
  - api/sys/sleep

nesc arguments:
  fnesc-scheduler: TinySchedulerPub,TinySchedulerPub.TaskBasic,TaskBasic,TaskBasic,runTask,postTask

wnesc arguments:
  scheduler: TinySchedulerPub,TinySchedulerPub.TaskBasic,TaskBasic,TaskBasic,runTask,postTask
