/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

/// \addtogroup module_scif_osal
//@{
#ifdef SCIF_INCLUDE_OSAL_C_FILE


#include <inc/hw_nvic.h>
#include <driverlib/cpu.h>
#include <driverlib/interrupt.h>
#include "scif_osal_whip6.h"


/// MCU wakeup source to be used with the Sensor Controller task ALERT event, must not conflict with OS
#define OSAL_MCUWUSEL_WU_EV_S   AON_EVENT_MCUWUSEL_WU3_EV_S


/// The READY interrupt is implemented using INT_AON_AUX_SWEV0
#define INT_SCIF_CTRL_READY     INT_AON_AUX_SWEV0
/// The ALERT interrupt is implemented using INT_AON_AUX_SWEV1
#define INT_SCIF_TASK_ALERT     INT_AON_AUX_SWEV1


/// Calculates the NVIC register offset for the specified interrupt
#define NVIC_OFFSET(i)          (((i) - 16) / 32)
/// Calculates the bit-vector to be written or compared against for the specified interrupt
#define NVIC_BV(i)              (1 << ((i - 16) % 32))


/** \brief Enters a critical section by disabling hardware interrupts
  *
  * \return
  *     Whether interrupts were enabled at the time this function was called
  */
uint32_t scifOsalEnterCriticalSection(void) {
    return !CPUcpsid();
} // scifOsalEnterCriticalSection




/** \brief Leaves a critical section by reenabling hardware interrupts if previously enabled
  *
  * \param[in]      key
  *     The value returned by the previous corresponding call to \ref scifOsalEnterCriticalSection()
  */
void scifOsalLeaveCriticalSection(uint32_t key) {
    if (key) CPUcpsie();
} // scifOsalLeaveCriticalSection




/// Stores whether task control non-blocking functions have been locked
//static volatile bool osalCtrlTaskNblLocked = false;




/** \brief Locks use of task control non-blocking functions
  *
  * This function is used by the non-blocking task control to allow safe operation from multiple threads.
  *
  * The function shall attempt to set the \ref osalCtrlTaskNblLocked flag in a critical section.
  * Implementing a timeout is optional (the task control's non-blocking behavior is not associated with
  * this critical section, but rather with completion of the task control request).
  *
  * \return
  *     Whether the critical section could be entered (true if entered, false otherwise)
  */
static bool osalLockCtrlTaskNbl(void) {
    /*uint32_t key = !CPUcpsid();
    if (osalCtrlTaskNblLocked) {
        if (key) CPUcpsie();
        return false;
    } else {
        osalCtrlTaskNblLocked = true;
        if (key) CPUcpsie();
        return true;
    }*/
    return true;
} // osalLockCtrlTaskNbl




/** \brief Unlocks use of task control non-blocking functions
  *
  * This function will be called once after a successful \ref osalLockCtrlTaskNbl().
  */
static void osalUnlockCtrlTaskNbl(void) {
    //osalCtrlTaskNblLocked = false;
} // osalUnlockCtrlTaskNbl




/** \brief Waits until the task control interface is ready/idle
  *
  * This indicates that the task control interface is ready for the first request or that the last
  * request has been completed. If a timeout mechanisms is not available, the implementation may be
  * simplified.
  *
  * \note For the OSAL "None" implementation, a non-zero timeout corresponds to infinite timeout.
  *
  * \param[in]      timeoutUs
  *     Minimum timeout, in microseconds
  *
  * \return
  *     Whether the task control interface is now idle/ready
  */
static bool osalWaitOnCtrlReady(uint32_t timeoutUs) {
    if (timeoutUs) {
        while (!(HWREG(AUX_EVCTL_BASE + AUX_EVCTL_O_EVTOAONFLAGS) & AUX_EVCTL_EVTOAONFLAGS_SWEV0_M));
        return true;
    } else {
        return (HWREG(AUX_EVCTL_BASE + AUX_EVCTL_O_EVTOAONFLAGS) & AUX_EVCTL_EVTOAONFLAGS_SWEV0_M);
    }
} // osalWaitOnCtrlReady




/** \brief OSAL "None": Enables the AUX domain and Sensor Controller for access from the MCU domain
  *
  * This function must be called before accessing/using any of the following:
  * - Oscillator control registers
  * - AUX ADI registers
  * - AUX module registers and AUX RAM
  * - SCIF API functions, except \ref scifOsalEnableAuxDomainAccess()
  * - SCIF data structures
  *
  * The application is responsible for:
  * - Registering the last set access control state
  * - Ensuring that this control is thread-safe
  */
void scifOsalEnableAuxDomainAccess(void) {

    // Force on AUX domain clock and bus connection
    HWREG(AON_WUC_BASE + AON_WUC_O_AUXCTL) |= AON_WUC_AUXCTL_AUX_FORCE_ON_M;
    HWREG(AON_RTC_BASE + AON_RTC_O_SYNC);

    // Wait for it to take effect
    while (!(HWREG(AON_WUC_BASE + AON_WUC_O_PWRSTAT) & AON_WUC_PWRSTAT_AUX_PD_ON_M));

} // scifOsalEnableAuxDomainAccess




/** \brief OSAL "None": Disables the AUX domain and Sensor Controller for access from the MCU domain
  *
  * The application is responsible for:
  * - Registering the last set access control state
  * - Ensuring that this control is thread-safe
  */
void scifOsalDisableAuxDomainAccess(void) {

    // Force on AUX domain bus connection
    HWREG(AON_WUC_BASE + AON_WUC_O_AUXCTL) &= ~AON_WUC_AUXCTL_AUX_FORCE_ON_M;
    HWREG(AON_RTC_BASE + AON_RTC_O_SYNC);

    // Wait for it to take effect
    while (HWREG(AON_WUC_BASE + AON_WUC_O_PWRSTAT) & AON_WUC_PWRSTAT_AUX_PD_ON_M);

} // scifOsalDisableAuxDomainAccess


#endif
//@}
