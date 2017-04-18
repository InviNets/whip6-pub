/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */


typedef enum {
    MotionTapXPlus,
    MotionTapXMinus,
    MotionTapYPlus,
    MotionTapYMinus,
    MotionTapZPlus,
    MotionTapZMinus,
} motion_tap_dir_t;

interface MotionTapDetector {
    event void tapDetected(motion_tap_dir_t direction, uint8_t count);
}
