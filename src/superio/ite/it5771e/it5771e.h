/* SPDX-License-Identifier: GPL-2.0-only */

/*
 * ITE IT5771E/IT5771VG Super I/O / EC definitions
 * MBX222 board: Configuration port 0x4EEC, I/O base 0x0A00
 * Connected via eSPI interface
 */

#ifndef SUPERIO_ITE_IT5771E_H
#define SUPERIO_ITE_IT5771E_H

#include <device/pnp_type.h>
#include <stdbool.h>
#include <stdint.h>

/* Logical Device Numbers (LDN) */
#define IT5771E_SP1    0x01  /* Serial Port 1 */
#define IT5771E_KBC    0x06  /* Keyboard Controller */
#define IT5771E_EC     0x11  /* Embedded Controller */
#define IT5771E_WDT    0x14  /* Watchdog Timer */
#define IT5771E_PECI   0x15  /* PECI Host Interface */
#define IT5771E_PMPRO  0x19  /* Power Management */

/* Chip ID */
#define IT5771E_CHIPID1  0x55
#define IT5771E_CHIPID2  0x71

/*
 * Configuration Registers
 * MBX222 uses extended configuration port at 0x4EEC
 * The IT5771VG is accessed via a two-byte address scheme:
 *   Write 0x87 to 0x4EEC twice to enter configuration mode
 *   Then use 0x4EEC as index and 0x4EED as data
 */
#define IT5771E_CONFIG_PORT  0x4EEC  /* Extended address port for MBX222 */
#define IT5771E_DATA_PORT    0x4EED  /* Extended data port for MBX222 */
#define IT5771E_CHIPID_REG   0x20    /* CHIPID1: 0x55 */
#define IT5771E_CHIPVER_REG  0x21    /* CHIPID2: 0x71 */

/* LDN 0x06 (KBC) sub-registers */
#define IT5771E_KBC_KBMS_SEL 0xf0
#define IT5771E_KBC_KBMS_INT 0xf1
#define IT5771E_KBC_A20M_PASS 0xf2

/* I/O base addresses for MBX222 */
#define IT5771E_COM1_IOBASE  0x0A00  /* COM1 I/O base address */
#define IT5771E_KBC_IOBASE0  0x0060  /* KBC data port */
#define IT5771E_KBC_IOBASE1  0x0064  /* KBC command port */

/* Debug UART COM1 at standard address (via internal UART, not SIO) */
#define IT5771E_DEBUG_UART   0x03F8

/* Early init functions */
void it5771e_enable_serial(pnp_devfn_t dev, u16 iobase);
void it5771e_enable_kbc(pnp_devfn_t dev);
bool it5771e_detect(pnp_devfn_t dev);

#endif /* SUPERIO_ITE_IT5771E_H */