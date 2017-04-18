#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2017 Konrad Iwanicki
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files.
#

all: bin/Server.class bin/Client.class


bin/Server.class: src/Server.java
	javac -d bin/ $<


bin/Client.class: src/Client.java
	javac -d bin/ $<

clean:
	rm -f bin/*.class
