#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Szymon Acedanski
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE
# files.
#
dependencies:
  - api/containers
  - api/control
  - api/sys/sleep
  - api/sys/debug
  - api/ieee154/
  - api/power/
  - api/watchdog/
  - api/ipv6
  - api/diagnostic
  - api/power/arbiter
  - api/io
  - api/storage
  - lib/base
  - lib/ble
  - lib/centroute/
  - lib/cipher
  - lib/containers
  - lib/control
  - lib/diagnostic
  - lib/extern/microc/cortex-m3
  - lib/icmpv6
  - lib/ieee154
  - lib/io
  - lib/ipv6
  - lib/lowpan
  - lib/mac/
  - lib/netstack
  - lib/power
  - lib/power/arbiter
  - lib/storage
  - lib/sys/bootseq
  - lib/sys/global
  - lib/sys/processes
  - lib/sys/scheduler
  - lib/timers/
  - lib/udp
  - lib/util
  - lib/watchdog
  - platforms/parts/mcu/cc26xx/
  - platforms/parts/mcu/cortex-m3/native/context_switching
  - platforms/tools/compiler/nescc
  - platforms/tools/compiler/make
  - platforms/tools/other/
  - platforms/tools/programmer/uniflash
  - platforms/tools/programmer/ccbsl
  - platforms/tools/programmer/whipprog
  - platforms/tools/programmer/mesh
  - platforms/tools/programmer/heni-bl
  - platforms/tools/debugger/ti-checkjtag
  - platforms/tools/debugger/ti-gdbserver
  - platforms/boards/cc26xxbased/private
  - platforms/common

define:
  - PANIC_NO_EXTENDED_MESSAGES

composite targets:
  all:
    - build
  reinstall:
    - proguniflash
  install:
    - build
    - proguniflash
  blreinstall:
    - progccbsl
  blinstall:
    - build
    - progccbsl
  whipreinstall:
    - progwhip
  whipinstall:
    - build
    - progwhip
  henireinstall:
    - progheni-bl
  heniinstall:
    - build
    - progheni-bl
  build:
    - clean
    - create_build_dir
    - nesccodegen
    - make_ext_libs
    - buildappc
    - makebuild
    - gengdbinit
  buildappc:
    - nesccompile
    - setuniqueids
    - warn_about_printfs
  nesccodegen: []  # Will be filled by modules which auto-generate code
  compile:
    - gcccompile
  link:
    - gcclink
