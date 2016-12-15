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

all: bin/Server.class bin/Client.class


bin/Server.class: src/Server.java
	javac -d bin/ $<


bin/Client.class: src/Client.java
	javac -d bin/ $<

clean:
	rm -f bin/*.class

