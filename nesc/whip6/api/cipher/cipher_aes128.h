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
 *
 * Common definitions for AES-128 functionality.
 */

#ifndef CIPHER_AES128_H
#define CIPHER_AES128_H

typedef struct {
    uint8_t key[16];   
} _aes128_key_t;
typedef _aes128_key_t _aes128_key_t_xdata;
typedef _aes128_key_t_xdata aes128_key_t;

typedef struct {
    uint8_t nonce[16];
} _aes128_nonce_t;
typedef _aes128_nonce_t _aes128_nonce_t_xdata;
typedef _aes128_nonce_t_xdata aes128_nonce_t;

typedef struct {
    uint8_t mac[16];
} _aes128_mac_t;
typedef _aes128_mac_t _aes128_mac_t_xdata;
typedef _aes128_mac_t_xdata aes128_mac_t;

#define AES128_BLOCK_SIZE_BYTES (128 / 8)
#endif
