/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */


typedef enum {
    MOTION_PROCESSOR_MODE_FULL,

    // Hardware-assisted algorithms turned off. May reduce the accurracy,
    // power consumption and featurres. May stop updates of some of the
    // sensors. Implementation-dependent.
    MOTION_PROCESSOR_MODE_NO_DMP,

    // A low-power limited sensors mode, with only accelerometer data
    // available. Other sensors may update if they don't depend on
    // data from other hardware sensors.
    MOTION_PROCESSOR_MODE_LOW_POWER_ACCEL,

    // Enter low-power mode and wake when motion is detected.
    // After wakeup, newMotionData() event is generated and
    // the previous state is restored.
    MOTION_PROCESSOR_MODE_WAIT_FOR_MOTION,
} motion_processor_mode_t;

interface MotionProcessorControl {
    command error_t setMode(motion_processor_mode_t mode);
    command motion_processor_mode_t getMode();

    command error_t setSampleRate(uint16_t readingsPerSecond);
    command uint16_t getSampleRate();

    // Fired once, after OnOffSwitch.on() when the motion detector
    // is initialized, but before the first newMotionData event.
    event void detectorStarted();

    // Fired regularly when new motion data is available, even if
    // there is no change in actual values.
    //
    // The metrics can be there read from the MotionData<> interfaces.
    event void newMotionData();

    // Fired once, when OnOffSwitch.off() is called.
    event void detectorStopped();

    // Fired if an error has beed detected.
    //
    // The detector is disabled and may be restarted using OnOffSwitch.off()
    // and then OnOffSwitch.on() again after some delay.
    //
    // The chip is left in an unknown state and may consume extra power if
    // not switched off.
    //
    // No newMotionData events will be generated after this, but
    // detectorStopped will be signalled when OnOffSwitch.off() is called.
    event void detectorFailed(error_t error);

    // Start a self-test. If failed, signal via detectorFailed as usual.
    command void selfTest();

    // Print implementation-specific information (with printf).
    command void dumpDebugInfo();
}
