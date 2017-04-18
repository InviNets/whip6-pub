/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */
/** \addtogroup module_scif_osal Operating System Abstraction Layer
  *
  * \section section_osal_overview Overview
  * The OSAL allows provides a set of functions for internal use by the SCIF driver to allow it to
  * interface with the real-time operating system or other run-time framework running on the System CPU.
  *
  * The OSAL consists of a set of mandatory functions, listed below, and a set of OS-dependent functions
  * to be called by the application, also listed below, for example initialization of the OSAL or AUX
  * domain access control.
  *
  * The OSAL C source file can, but does not need to, be included in the application project.
  *
  *
  * \section section_osal_implementation Implementation "None"
  * This OSAL uses the following basic mechanisms:
  * - Hardware event interrupts to implement the SCIF READY and ALERT callbacks
  * - Critical sections by disabling interrupts globally
  *
  * This OSAL does not implement the \ref scifWaitOnNbl() timeout mechanism.
  *
  * The application must call the \ref scifOsalEnableAuxDomainAccess() and
  * \ref scifOsalDisableAuxDomainAccess() functions to enable and disable access to the AUX domain. See
  * \ref section_scif_aux_domain_access for more information.
  *
  *
  * \section section_osal_int_func Mandatory Internal Functions
  * The SCIF OSAL must provide the following functions for internal use by the driver:
  * - Thread-safe operation:
  *     - \ref scifOsalEnterCriticalSection()
  *     - \ref scifOsalLeaveCriticalSection()
  *     - \ref osalLockCtrlTaskNbl()
  *     - \ref osalUnlockCtrlTaskNbl()
  * - Task control support:
  *     - \ref osalWaitOnCtrlReady()
  *
  * @{
  */
#ifndef SCIF_OSAL_WHIP6_H
#define SCIF_OSAL_WHIP6_H


void osalClearCtrlReadyInt(void);
void osalEnableCtrlReadyInt(void);
void osalDisableCtrlReadyInt(void);
void osalClearTaskAlertInt(void);
void osalEnableTaskAlertInt(void);
void osalDisableTaskAlertInt(void);


#endif
//@}
