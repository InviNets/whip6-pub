/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 *
 * @author Przemyslaw Horban <extremegf@gmail.com>
 * @author Michal Marschall <m.marschall@invinets.com>
 */

#include "I2CDefs.h"

generic module HalTMP431TemperatureReaderPrv() {
    provides interface DimensionalRead<TDeciCelsius, int16_t> as ReadTemp;

    uses interface OnOffSwitch;
    uses interface Resource;
    uses interface I2CPacket<TI2CBasicAddr>;
    uses interface Timer<TMilli, uint32_t> as EnableDelay;
    uses interface Timer<TMilli, uint32_t> as SettlingDelay;
}

implementation {
    enum {
        STATE_IDLE,
        STATE_CONFIG,
        STATE_ONE_SHOT,
        STATE_READ_TEMP,
    };

    uint8_t state = STATE_IDLE;

    enum {
        REG_TEMP_LOCAL_READ = 0x00,
        REG_CONFIG1_WRITE = 0x09,
        REG_ONE_SHOT = 0x0f,

        CONFIG1_SD_MASK = 1 << 6,
        CONFIG1_RANGE_MASK = 1 << 2,

        DEV_ADDRESS1 = 0x4C,
        DEV_ADDRESS2 = 0x4D,
    };

    enum {
        TMP431_ENABLE_DELAY = 17, /* use high value just in case */
        TMP431_SETTLE_DELAY_MS = 17,
    };

    uint8_t_xdata i2cBuf[2];
    error_t result;
    uint8_t devAddress = DEV_ADDRESS1;

    task void returnResult();

    command error_t ReadTemp.read() {
        if(state != STATE_IDLE) {
            return EBUSY;
        }
        state = STATE_CONFIG;
        call OnOffSwitch.on();
        /* It doesn't work if you write a command immediately, but I don't see any information concerning
         * this fact in the documentation. */
        call EnableDelay.startWithTimeoutFromNow(TMP431_ENABLE_DELAY);
        return SUCCESS;
    }

    event void EnableDelay.fired() {
        result = call Resource.request();
        if(result != SUCCESS) {
            post returnResult();
        }
    }
        
    event void Resource.granted() {
        /* shutdown device to perform one-shot conversion and set the extended range (-55 C to 150 C) */
        i2cBuf[0] = REG_CONFIG1_WRITE;
        i2cBuf[1] = CONFIG1_SD_MASK | CONFIG1_RANGE_MASK;
        result = call I2CPacket.write(I2C_START | I2C_STOP, devAddress, 2, i2cBuf);
        if(result != SUCCESS) {
            post returnResult();
        }
    }

    event void SettlingDelay.fired(){
        i2cBuf[0] = REG_TEMP_LOCAL_READ;
        result = call I2CPacket.write(I2C_START, devAddress, 1, i2cBuf);
        if(result != SUCCESS) {
            post returnResult();
        }                                     
    }

    event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t_xdata *data) {
        result = error;
        
        if(result != SUCCESS) {
            if(state == STATE_CONFIG && devAddress == DEV_ADDRESS1) {
                /* Try again with a different address. We assume this error may only happen on the first command
                 * (write to the CONFIG1 register) if a used device has another address, so we change the address
                 * permanently and pass the same I2C flags here as in the initial command. */
                devAddress = DEV_ADDRESS2;
                result = call I2CPacket.write(I2C_START | I2C_STOP, devAddress, length, data);
                if(result != SUCCESS) {
                    post returnResult();
                }
            } else {
                post returnResult();
            }
            return;
        }

        switch(state) {
            case STATE_IDLE: /* this should never happen */
                break;
            case STATE_CONFIG:
                state = STATE_ONE_SHOT;
                i2cBuf[0] = REG_ONE_SHOT;
                /* Any value written to that register triggers conversion, so we don't set the second byte. */
                result = call I2CPacket.write(I2C_START | I2C_STOP, devAddress, 2, i2cBuf);
                break;
            case STATE_ONE_SHOT:
                state = STATE_READ_TEMP;
                call SettlingDelay.startWithTimeoutFromNow(TMP431_SETTLE_DELAY_MS);
                break;
            case STATE_READ_TEMP:
                result = call I2CPacket.read(I2C_START | I2C_STOP, devAddress, 2, i2cBuf);
                break;
        }

        if(result != SUCCESS) {
            post returnResult();
        }
    }

    event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t_xdata *data) {
        result = error;
        post returnResult();
    }

    task void returnResult() {
        int16_t deciCelc = 0;

        call OnOffSwitch.off();
        call Resource.release();
        if(result == SUCCESS) {
            deciCelc = ((int16_t)i2cBuf[0] - 64); /* 0x00 is -64 C and 0xff is 191 C */
            deciCelc = (deciCelc << 4) + (i2cBuf[1] >> 4); /* in range [-64 * 16 + 0; 191 * 16 + 15] = [-1024; 3071] */
            deciCelc *= 10; /* in range [-10240; 30710] */
            deciCelc >>= 4; /* in range [-10240 / 16; 30710 / 16] = [-640; 1919] */
        }
        state = STATE_IDLE;
        signal ReadTemp.readDone(result, deciCelc);
    }

    default event void ReadTemp.readDone(error_t, int16_t) {}
}
