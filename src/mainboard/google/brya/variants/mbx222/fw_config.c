/* SPDX-License-Identifier: GPL-2.0-or-later */

/*
 * MBX222 fw_config probing
 * Fixed configuration: NVMe + SATA, DDR4, onboard WLAN, no eMMC
 */

#include <baseboard/variants.h>
#include <bootstate.h>
#include <console/console.h>
#include <fw_config.h>

static void fw_config_handle(void *unused)
{
	if (!fw_config_is_provisioned()) {
		printk(BIOS_INFO,
		       "MBX222: FW config is not provisioned, using defaults\n");
		return;
	}

	printk(BIOS_INFO, "MBX222: FW config is provisioned\n");
}
BOOT_STATE_INIT_ENTRY(BS_DEV_ENABLE, BS_ON_ENTRY, fw_config_handle, NULL);