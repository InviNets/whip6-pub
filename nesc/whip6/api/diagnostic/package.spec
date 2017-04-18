#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Przemyslaw Horban
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#
Required components:
  LedsPub:
    configuration LedsPub {
      provides interface Led as Red; # only leds available on device
      provides interface Led as Green;    
      provides interface Led as Blue;
    }
