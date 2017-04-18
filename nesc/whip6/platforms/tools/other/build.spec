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
direct targets:
  - create_build_dir
  - clean
  - make_ext_libs
  - makeapp
  - setuniqueids
  - warn_about_printfs
  - gengdbinit
