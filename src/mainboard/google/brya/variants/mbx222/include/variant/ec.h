/* SPDX-License-Identifier: GPL-2.0-or-later */

/*
 * MBX222 variant EC definitions
 * ITE IT5771E EC via eSPI interface
 */

#ifndef __VARIANT_EC_H__
#define __VARIANT_EC_H__

#include <baseboard/ec.h>

/*
 * ITE IT5771E EC specific definitions
 * The EC is connected via eSPI (not LPC)
 * Configuration port: 0x4EEC
 * I/O base address: 0x0A00
 */

/* Enable tablet mode switch (via EC) */
#if !CONFIG(CHROMEOS)
#define EC_ENABLE_TBMC_DEVICE
#endif

/* EC S0ix wake mask */
#define MAINBOARD_EC_S0IX_WAKE_EVENTS \
	(EC_HOST_EVENT_MASK(EC_HOST_EVENT_LID_CLOSED) |\
	 EC_HOST_EVENT_MASK(EC_HOST_EVENT_LID_OPEN) |\
	 EC_HOST_EVENT_MASK(EC_HOST_EVENT_POWER_BUTTON))

#endif /* __VARIANT_EC_H__ */