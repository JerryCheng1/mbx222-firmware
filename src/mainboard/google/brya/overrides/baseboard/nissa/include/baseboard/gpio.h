/* SPDX-License-Identifier: GPL-2.0-or-later */

/*
 * MBX222: GPIO definitions for Nissa baseboard override
 * ITE IT5771E EC via eSPI, DDR4 SODIMM
 */

#ifndef __BASEBOARD_GPIO_H__
#define __BASEBOARD_GPIO_H__

#include <soc/gpe.h>
#include <soc/gpio.h>

/* eSPI EC interface pins (hardware configured, reference only) */
#define GPIO_ESPI_CLK		GPP_A9
#define GPIO_ESPI_IO0		GPP_A0
#define GPIO_ESPI_IO1		GPP_A1
#define GPIO_ESPI_IO2		GPP_A2
#define GPIO_ESPI_IO3		GPP_A3
#define GPIO_ESPI_CS_N		GPP_A4
#define GPIO_ESPI_RESET_N	GPP_A10

/* EC interface */
#define GPIO_EC_IN_RW		GPP_F18
#define GPIO_PCH_WP		GPP_E12
#define GPIO_EC_WAKE		GPP_F17

/* NVMe SSD */
#define GPIO_SSD_CLKREQ		GPP_D7
#define GPIO_SSD_PLN		GPP_E17
#define GPIO_SSD_PERST		GPP_B4
#define GPIO_EN_PP3300_SSD	GPP_D11

/* SATA */
#define GPIO_SATA_LED		GPP_A12

/* WLAN */
#define GPIO_WLAN_DISABLE	GPP_E8
#define GPIO_WLAN_PERST		GPP_H20
#define GPIO_WLAN_PCIE_WAKE	GPP_H3

/* Audio */
#define GPIO_EN_SPK_PA		GPP_A11
#define GPIO_HP_INT		GPP_A23

/* Touchpad */
#define GPIO_TCHPAD_INT		GPP_F14

/* Memory strapping pins */
#define GPIO_MEM_STRAP_0	GPP_E1
#define GPIO_MEM_STRAP_1	GPP_E2
#define GPIO_MEM_STRAP_2	GPP_E3

/* Debug UART (COM1) */
#define GPIO_UART0_RXD		GPP_H10
#define GPIO_UART0_TXD		GPP_H11

#endif /* __BASEBOARD_GPIO_H__ */