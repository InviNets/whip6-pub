This app allows to measure the power consumption of a thermometer read using
icount. For aprox. 1 second the app reads the thermometer as many times as it
can. Then the app idles for another second. This cycle repeats indefinitely.

At the break of each cycle icount value (number of regulator ticks) and current
ms timestamp since boot is printed. This should allow to estimate via
reggression the cost of a single temperature read.

Number of temperature reads is also known, as they are logged.

Example output:

...
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Finished cycle with continous thermometer reads: icount: 301688, timestamp: 577621
Finished cycle with disabled thermometer: icount: 302015, timestamp: 578645
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Finished cycle with continous thermometer reads: icount: 302767, timestamp: 579695
Finished cycle with disabled thermometer: icount: 303095, timestamp: 580719
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
Temperature in tenths of degree Celsius: 310
...
