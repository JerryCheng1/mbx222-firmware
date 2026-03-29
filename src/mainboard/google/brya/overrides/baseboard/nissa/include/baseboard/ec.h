/* SPDX-License-Identifier: GPL-2.0-or-later */

/*
 * MBX222: ITE IT5771E EC configuration via eSPI
 * Replaces ChromeEC definitions for ITE IT5771VG EC
 */

#ifndef __BASEBOARD_EC_H__
#define __BASEBOARD_EC_H__

#include <ec/ec.h>
#include <baseboard/gpio.h>

/*
 * ITE IT5771E EC configuration:
 * - Configuration port: 0x4EEC
 * - I/O base address: 0x0A00
 * - Interface: eSPI (GPP_A0-A4, A9, A10)
 * - Debug UART COM1: 0x3F8
 */

/* EC SCI interrupt - via eSPI virtual wire, reported as GPE */
#define EC_SCI_GPI		GPE0_ESPI

/* EC wake pin - GPP_F17 */
#define GPE_EC_WAKE		GPE0_DW2_17

/* WP signal to PCH */
#define GPIO_PCH_WP		GPP_E12

/* EC in RW or RO - from eSPI VW or GPIO */
#define GPIO_EC_IN_RW		GPP_F18

/* EC sync IRQ via eSPI */
#define EC_SYNC_IRQ		GPD2_IRQ

/* SLP_S0 gate - dummy for Nissa without HAVE_SLP_S0_GATE */
#define GPIO_SLP_S0_GATE	GPP_H18

/*
 * ACPI EC definitions for ITE IT5771E
 * These define the EC event masks for SMI/SCI/wake handling
 */
#define MAINBOARD_EC_SCI_EVENTS \
	(0)

#define MAINBOARD_EC_SMI_EVENTS \
	(0)

/* EC can wake from S5 with power button */
#define MAINBOARD_EC_S5_WAKE_EVENTS \
	(0)

/* EC wake from S3/S0ix */
#define MAINBOARD_EC_S3_WAKE_EVENTS \
	(0)

#define MAINBOARD_EC_S0IX_WAKE_EVENTS \
	(0)

/* Log EC events */
#define MAINBOARD_EC_LOG_EVENTS \
	(0)

/* Enable LID switch via EC */
#define EC_ENABLE_LID_SWITCH
#define EC_ENABLE_WAKE_PIN	GPE_EC_WAKE

#endif /* __BASEBOARD_EC_H__ */