/* SPDX-License-Identifier: GPL-2.0-or-later */

/*
 * MBX222 variant GPIO table
 * Alder Lake N + ITE IT5771E EC via eSPI
 * DDR4 SODIMM, 1 NVMe, 1 SATA, onboard WLAN, no eMMC
 */

#include <baseboard/gpio.h>
#include <baseboard/variants.h>
#include <types.h>
#include <soc/gpio.h>

/*
 * Variant-specific GPIO overrides.
 * These are applied on top of the baseboard GPIO configuration.
 * MBX222 specific: SATA enable, eMMC disable, NVMe configuration
 */
static const struct pad_config override_gpio_table[] = {
	/* A12 : SATA_GP0 ==> SATA_LED_N (active for SATA) */
	PAD_CFG_GPO(GPP_A12, 1, DEEP),

	/* D7  : SRCCLKREQ2# ==> NVMe SSD CLKREQ (active) */
	PAD_CFG_NF(GPP_D7, NONE, DEEP, NF1),

	/* D11 : EN_PP3300_SSD ==> NVMe SSD power enable */
	PAD_NC(GPP_D11, NONE),

	/* E17 : SSD_PLN_L ==> NVMe SSD detect (active) */
	PAD_NC(GPP_E17, NONE),

	/* eMMC pins - all NC since no eMMC on this board */
	PAD_NC(GPP_I5, NONE),
	PAD_NC(GPP_I7, NONE),
	PAD_NC(GPP_I8, NONE),
	PAD_NC(GPP_I9, NONE),
	PAD_NC(GPP_I10, NONE),
	PAD_NC(GPP_I11, NONE),
	PAD_NC(GPP_I12, NONE),
	PAD_NC(GPP_I13, NONE),
	PAD_NC(GPP_I14, NONE),
	PAD_NC(GPP_I15, NONE),
	PAD_NC(GPP_I16, NONE),
	PAD_NC(GPP_I17, NONE),
	PAD_NC(GPP_I18, NONE),
};

const struct pad_config *variant_gpio_override_table(size_t *num)
{
	*num = ARRAY_SIZE(override_gpio_table);
	return override_gpio_table;
}