/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 InviNets Sp. z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/**
 * @author Michal Marschall <m.marschall@invinets.com>
 */

#include <driverlib/i2c.h>

generic module HalBlockingI2CPrv(uint32_t i2cBase) {
    provides interface BlockingI2CPacket<TI2CBasicAddr>;
}

implementation {
    command error_t BlockingI2CPacket.read(i2c_flags_t flags, uint16_t addr,
            uint16_t length, uint8_t_xdata* data) {
        uint16_t i;
        uint32_t cmd;
        if (length == 0) {
            return EINVAL;
        }
        if (data == NULL) {
            return EINVAL;
        }
        I2CMasterSlaveAddrSet(i2cBase, addr, true);
        cmd = 0x01;
        if (flags & I2C_START) {
            cmd |= 0x02;
        }
        if (length == 1) {
            if (flags & I2C_STOP) {
                cmd |= 0x04;
            }
            if (flags & I2C_ACK_END) {
                cmd |= 0x08;
            }
            I2CMasterControl(i2cBase, cmd);
            while (I2CMasterBusy(i2cBase)) /* nop */;
            if (I2CMasterErr(i2cBase) != I2C_MASTER_ERR_NONE) {
                return EIO;
            }
            data[0] = I2CMasterDataGet(i2cBase);
        } else {
            cmd |= 0x08;
            for (i = 0; i < length; i++) {
                I2CMasterControl(i2cBase, cmd);
                while (I2CMasterBusy(i2cBase)) /* nop */;
                if (I2CMasterErr(i2cBase) != I2C_MASTER_ERR_NONE) {
                    I2CMasterControl(i2cBase,
                            I2C_MASTER_CMD_BURST_RECEIVE_ERROR_STOP);
                    while (I2CMasterBusy(i2cBase)) /* nop */;
                    return EIO;
                }
                data[i] = I2CMasterDataGet(i2cBase);
                if (i == 0) {
                    cmd &= ~0x02;
                }
                if (i == length - 2) {
                    if (flags & I2C_STOP) {
                        cmd |= 0x04;
                    }
                    if (!(flags & I2C_ACK_END)) {
                        cmd &= ~0x08;
                    }
                }
            }
        }
        return SUCCESS;
    }

    command error_t BlockingI2CPacket.write(i2c_flags_t flags, uint16_t addr,
            uint16_t length, const uint8_t_xdata* data) {
        uint16_t i;
        uint32_t cmd;
        if (length == 0) {
            return EINVAL;
        }
        if (data == NULL) {
            return EINVAL;
        }
        I2CMasterSlaveAddrSet(i2cBase, addr, false);
        cmd = 0x01;
        if (flags & I2C_START) {
            cmd |= 0x02;
        }
        if (length == 1) {
            if (flags & I2C_STOP) {
                cmd |= 0x04;
            }
            I2CMasterDataPut(i2cBase, data[0]);
            I2CMasterControl(i2cBase, cmd);
            while (I2CMasterBusy(i2cBase)) /* nop */;
            if (I2CMasterErr(i2cBase) != I2C_MASTER_ERR_NONE) {
                return EIO;
            }
        } else {
            for (i = 0; i < length; i++) {
                I2CMasterDataPut(i2cBase, data[i]);
                I2CMasterControl(i2cBase, cmd);
                while (I2CMasterBusy(i2cBase)) /* nop */;
                if (I2CMasterErr(i2cBase) != I2C_MASTER_ERR_NONE) {
                    I2CMasterControl(i2cBase,
                            I2C_MASTER_CMD_BURST_SEND_ERROR_STOP);
                    while (I2CMasterBusy(i2cBase)) /* nop */;
                    return EIO;
                }
                if (i == 0) {
                    cmd &= ~0x02;
                }
                if (i == length - 2) {
                    if (flags & I2C_STOP) {
                        cmd |= 0x04;
                    }
                }
            }
        }
        return SUCCESS;
    }
}
