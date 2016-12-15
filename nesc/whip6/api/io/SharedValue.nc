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

interface SharedValue<value_type> {
    command void set(value_type v);
    command value_type get();
    event void valueChanged(value_type old_value, value_type new_value);
}
