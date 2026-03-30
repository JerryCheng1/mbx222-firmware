# Project: Google Nissa (Alder Lake-N) - coreboot UEFI Port

## Overview

Port coreboot UEFI firmware to **Google Nissa** board (Alder Lake-N platform).
Nivviks is a board variant within the coreboot tree. EC firmware is developed
independently, referencing Xiaomi IT5571E EC code as architecture reference only.

---

## Platform: Intel Alder Lake-N

| Item | Details |
|------|---------|
| SoC | Intel Alder Lake-N (single-chip SiP, no discrete PCH) |
| CPU | E-cores (Gracemont), or E-core + P-core combos |
| TDP | 6W-15W (mobile/ultrabook segment) |
| Memory | LPDDR5 or DDR5 (on-board, not SODIMM) |
| Storage | NVMe (PCIe) + SATA (integrated in SoC) |
| Boot | SPI flash (BIOS chip) |

> **Alder Lake-N = All-in-one SiP.** No discrete PCH. All PCIe/SATA/USB/XHCI/SATA
> are integrated into the SoC package. This simplifies board layout but changes
> the memory map vs traditional desktop/mobile platforms with separate PCH.

---

## Hardware Specs

| Component | Details |
|-----------|---------|
| RAM | 2x LPDDR5 8GB (16GB total, on-board) |
| NVMe | 1x M.2 PCIe x4 slot |
| SATA | 1x SATA III slot |
| WLAN | Intel CNVI (Wi-Fi, integrated in SoC) + PCIe WLAN Module |
| Ethernet | Realtek Gigabit (verify: USB or PCIe?) |
| Audio | Realtek ALC256 |
| Display | eDP panel + HDMI output |
| USB | 2x USB-A 3.2 Gen 1 |
| SD Card | Built-in SD card reader |
| TPM | None |

---

## EC Chip: IT5571E (Self-Developed)

> EC firmware is developed independently. Xiaomi NB6590A IT5571E code is used as
> architecture reference only. Not a direct copy. This separation protects both
> projects' IP.

### Chip Identification
| Register | Address | Value |
|----------|---------|-------|
| ECHIPID1 | 0x2000 | 0x85 (IT5571E) |
| ECHIPID2 | 0x2001 | - |
| ECHIPVER | 0x2002 | - |

### Host I/O Ports
| Register | Value | Description |
|----------|-------|-------------|
| BADRSEL | 0x02 | Base addr: User define |
| SWCBALR | 0x4E | EC Index Port |
| SWCBAHR | 0x00 | EC High Byte |
| **EC Port** | **0x4E/0x4F** | Index=0x4E, Data=0x4F |

### Host RAM Window (EC RAM mapped to Host)
| Register | Value | Host Address |
|----------|-------|--------------|
| HRAMW0BA | 0xA0 | 0xFF0B_A000 |
| HRAMW1BA | 0x40 | 0xFF0B_4000 |
| HRAMWC | 0x01 | Window 0 enabled, LPC |

LPC RAM base: 0xFF0B_0000 (F5=0x00, F6=0x0B, FC=0x00)

### Peripheral I/O Bases
| Peripheral | LDN | I/O Base | IRQ |
|------------|-----|----------|-----|
| UART1 | 01h | 0x3F8 | 5 |
| PS/2 Mouse | 05h | - | 12 |
| SMBus | 12h | 0xF0 | - |

### Key EC Registers
| Register | Address |
|----------|---------|
| RSTS | 0x2006 |
| RSTC1 | 0x2007 |
| BADRSEL | 0x200A |
| WNCKR | 0x200B |

### EC Interface Config
```c
SUPPORT_INTERFACE_eSPI      TRUE
ITE_eSPI_LOW_FREQUENCY     TRUE
SHARED_BIOS_TRI_STATE       TRUE
SUPPORT_LPC_BUS_1_8V        TRUE
```

---

## coreboot Board Structure

```
coreboot/
└── src/mainboard/google/brya/         ← Parent board: Brya
    ├── variants/
    │   ├── nivviks/                  ← Reference variant (coreboot main)
    │   │   ├── boardinfo.cb
    │   │   ├── config
    │   │   ├── devicetree.cb
    │   │   ├── gpio.c
    │   │   ├── acpi/
    │   │   └── variant/             ← Variant-specific overrides
    │   └── baseboard/
    │       └── nissa/               ← Target board (coreboot main)
    │           ├── boardinfo.cb
    │           ├── config
    │           ├── devicetree.cb
    │           ├── gpio.c
    │           ├── acpi/
    │           └── variant/         ← Nissa-specific overrides
    └── (parent board files: brya/)
```

> Brya is the parent board. Nivviks and Nissa are sibling variants under `brya/variants/`.
> Both share the same Brya parent board files. Reference Nivviks when creating Nissa port,
> override where hardware differences exist.

---

## Development Workflow

### Phase 1: Information Gathering
- [ ] Confirm Alder Lake-N SKU (e.g., Intel N100, N200, i3-N305, N5105)
- [ ] Get Nivviks board files from coreboot tree (`src/mainboard/google/brya/variants/nivviks/`)
- [ ] Get Google Nissa ChromeOS board files (schematics if available)
- [ ] Verify Nissa vs Nivviks hardware differences (GPIO, peripherals, memory)
- [ ] Confirm BIOS chip: size and type (SST/Winbond SPI flash, e.g., 8MB/16MB)
- [ ] Confirm LPDDR5 vendor and part number (critical for memory training)
- [ ] Verify WLAN module: Intel CNVI PHY + PCIe WLAN card model
- [ ] Confirm boot path: SPI flash layout (boot block, EC, FMAP, RW_A/RW_B)

### Phase 2: EC Firmware Development
> Reference: Xiaomi NB6590A IT5571E code (architecture only, develop original)
- [ ] Obtain IT5571E datasheet (contact ITE Tech Inc.)
- [ ] Develop Nissa-specific EC firmware:
  - [ ] SMBus/LPC/eSPI host interface (communicate with CPU)
  - [ ] EC interrupts: SMI, SCI, GPE (system management interrupts)
  - [ ] Power state management: S0/S3/S4/S5 (ACPI power states)
  - [ ] Keyboard scan matrix
  - [ ] Battery/SMBus smart battery management
  - [ ] Fan control (1 or 2 fan channels)
  - [ ] USB-C PD (Power Delivery) - Cypress/TI CCGx driver
  - [ ] Audio codec coordination (HDA link)
  - [ ] EC flash/update mechanism (boot block + recovery)
- [ ] Build EC firmware: ITE SDK (Keil or ITEEC.mak)

### Phase 3: coreboot Base Port
- [ ] Clone coreboot: `git clone https://review.coreboot.org/coreboot`
- [ ] Create nissa board variant: `mkdir -p src/mainboard/google/brya/variants/baseboard/nissa/`
- [ ] Reference Nivviks variant (`brya/variants/nivviks/`), adapt:
  - [ ] boardinfo.cb
  - [ ] config (Kconfig)
  - [ ] devicetree.cb (GPIO pinmux)
  - [ ] gpio.c (GPIO initialization)
  - [ ] acpi/ (DSDT/SSDT tables)
  - [ ] variant/ (memory training params, board-specific overrides)
- [ ] Configure FSP-M (Firmware Support Package - Memory init)
- [ ] Configure FSP-S (Silicon init for Alder Lake-N)
- [ ] Memory training: LPDDR5 (critical, verify with memory vendor)
- [ ] Configure Intel CNVI Wi-Fi (integrated in SoC)
- [ ] Configure PCIe WLAN slot
- [ ] Configure SATA/AHCI
- [ ] Configure NVMe
- [ ] Configure USB XHCI
- [ ] Configure eDP + HDMI (FSP-O or separate VBIOS)
- [ ] Configure ALC256 audio (HDA)
- [ ] Configure SD card reader
- [ ] Configure ACPI tables (S0ix, C-states, power states)

### Phase 4: UEFI Payload
- [ ] Build UEFI payload (Slim Bootloader SBL or EDK2)
- [ ] Integrate VBIOS for Gen12 GPU (Alder Lake-N integrated graphics)
- [ ] Verify GOP (Graphics Output Protocol): eDP + HDMI
- [ ] Port ChromeOS ACPI extensions if needed
- [ ] Verify Audio codec (ALC256) in UEFI environment

### Phase 5: Debug & Validation
- [ ] 80Port POST codes via UART1 (0x3F8)
- [ ] IPMI/KCS debug interface
- [ ] EC<->CPU communication test (SMBus/LPC/eSPI)
- [ ] Boot to UEFI Shell
- [ ] Boot to OS (Linux/ChromeOS)
- [ ] USB port enumeration and function
- [ ] NVMe/SATA read-write
- [ ] eDP + HDMI display output
- [ ] Audio playback
- [ ] WLAN (CNVI + PCIe card)
- [ ] SD card reader
- [ ] S3/S4/S5 suspend/resume

---

## Key References

| Resource | Location |
|----------|----------|
| coreboot tree | https://review.coreboot.org/coreboot |
| Nivviks variant | `src/mainboard/google/brya/variants/nivviks/` |
| Nissa variant (baseboard) | `src/mainboard/google/brya/variants/baseboard/nissa/` |
| Brya parent board | `src/mainboard/google/brya/` |
| Google Nissa (ChromeOS) | https://chromium.googlesource.com/chromiumos/third_party/coreboot/ |
| Alder Lake-N FSP | Intel FSP-M/S for ADL-N (download from Intel) |
| IT5571E datasheet | Contact ITE Tech Inc. (https://www.ite.com.tw/) |
| ITE EC SDK | ITEEC.mak + Keil project (reference only) |

---

## EC Reference Code Structure (Architecture Reference Only)

```
MI_EC_NB6590A_IT5771_DEMO/   ← Xiaomi reference (NB6590A platform, do not copy)
├── Code/
│   ├── API/                 # Chip-level API (ADC, GPIO, PWM, SMBus...)
│   │   └── INCLUDE/
│   ├── CHIP/               # Register definitions
│   │   └── INCLUDE/CORE_CHIPREGS.H   # 0x2000=ECHIPID1, 0x200A=BADRSEL
│   ├── CORE/               # Core EC firmware
│   │   ├── CORE_COMMON/    # Core_Main.c, Core_Init.c, CORE_ACPI.c...
│   │   ├── CORE_BANK0/     # CORE_FLASH, CORE_SCAN, CORE_PS2...
│   │   └── INCLUDE/        # CORE_INIT.H: base port 0x4E/0x4F
│   └── OEM/NB6590A/        # Platform OEM layer
│       ├── INCLUDE/
│       │   ├── OEM_PROJECT.H   # ITE_CHIP_IT557X=TRUE
│       │   └── OEM_HOSTIF.H   # Host interface (LPC/eSPI)
│       ├── OEM_BANK0/      # OEM_MAIN.C, OEM_POWER.C, OEM_FAN.C...
│       └── USBC_PD/        # USB-C PD (Cypress/ITE/TI drivers)
├── ROM/                    # Pre-built binaries
└── uVision/               # Keil uVision project (.uvproj)
```

---

## Notes & Gotchas

- **Alder Lake-N single-chip:** PCIe lanes, SATA, USB, XHCI all inside SoC. No PCH.
  Memory map differs from desktop ADL platforms.
- **Intel CNVI:** RF/analog on CPU package + separate PCIe WLAN card (baseband).
  coreboot FSP must support CNVI driver initialization. Verify FSP-M/S version.
- **LPDDR5 memory training:** Most critical and complex step. Nivviks may use
  specific LPDDR5 vendor bins. Verify if Nissa uses same or different memory.
- **No TPM:** No fTPM/Intel PTT. Software-only disk encryption only. BitLocker
  may require additional configuration.
- **eSPI vs LPC:** Modern ChromeOS boards use eSPI for EC-Host communication.
  Verify IT5571E eSPI interface is properly configured.
- **EC flashing:** IT5571E uses proprietary flashing mechanism. Confirm
  boot block recovery procedure and internal programming mode.
- **Xiaomi reference code:** Use as architecture reference ONLY. Develop original
  Nissa-specific EC firmware to avoid IP contamination.
- **SPI flash layout:** Verify FMAP, RW_A/RW_B partitioning. ChromeOS uses
  verified boot with RO+RW sections.
