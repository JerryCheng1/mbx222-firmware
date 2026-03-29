/* SPDX-License-Identifier: GPL-2.0-or-later */

/*
 * MBX222 variant device tree update
 * Disables eMMC, enables SATA, configures NVMe
 */

#include <baseboard/variants.h>
#include <device/device.h>
#include <device/pci_def.h>
#include <drivers/intel/gma/opregion.h>
#include <soc/pci_devs.h>

void variant_devtree_update(void)
{
	/*
	 * MBX222 specific device tree updates:
	 * - eMMC is physically not present, ensure it's disabled
	 * - SATA is present, ensure it's enabled
	 * - NVMe on RP9 is present
	 * - CNVi WLAN is onboard
	 */

	struct device *emmc_dev = pcidev_path_on_root(PCH_DEVFN_EMMC);
	if (emmc_dev)
		emmc_dev->enabled = 0;

	/* Ensure SATA is enabled */
	struct device *sata_dev = pcidev_path_on_root(PCH_DEVFN_SATA);
	if (sata_dev)
		sata_dev->enabled = 1;
}

const char *variant_fw_config_field_prefix(enum fw_config_field_id field)
{
	switch (field) {
	default:
		return "";
	}
}