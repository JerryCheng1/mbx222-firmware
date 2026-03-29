/* SPDX-License-Identifier: GPL-2.0-or-later */

/*
 * MBX222 variant GPIO definitions
 * Alder Lake N, ITE IT5771E EC via eSPI
 */

#ifndef VARIANT_GPIO_H
#define VARIANT_GPIO_H

#include <baseboard/gpio.h>

/* NVMe SSD power enable - active high */
#define NVME_EN			GPP_D11
/* NVMe SSD reset - active low */
#define NVME_RST_L		GPP_B4
/* NVMe SSD detect */
#define NVME_PLN_L		GPP_E17

/* SATA LED - active low */
#define SATA_LED_N		GPP_A12

/* WLAN disable - active low */
#define WLAN_DISABLE_L		GPP_E8
/* WLAN reset - active low */
#define WLAN_RST_L		GPP_H20
/* WLAN wake */
#define WLAN_PCIE_WAKE_ODL	GPP_H3

/* Speaker enable */
#define EN_SPK_PA		GPP_A11

/* EC wake pin */
#define EC_SOC_WAKE_ODL		GPP_F17

#endif /* VARIANT_GPIO_H */