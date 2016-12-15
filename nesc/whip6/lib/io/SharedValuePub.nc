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

/**
 * @author Szymon Acedanski
 *
 * Interface for storing a value used by more than one component.
 * Any user may read or set the value, but all the users are notified
 * then the value changes.
 */

generic module SharedValuePub(typedef value_type) {
    provides interface SharedValue<value_type>;
}
implementation {
    value_type value;

    command value_type SharedValue.get() {
        return value;
    }

    command void SharedValue.set(value_type new_value) {
        if (memcmp(&new_value, &value, sizeof(value_type))) {
            value_type old_value = value;
            value = new_value;
            signal SharedValue.valueChanged(old_value, new_value);
        }
    }
}
