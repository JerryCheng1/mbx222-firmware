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
| Memory | LPDDR5 6400 on-board, 3 SKUs supported (see Memory section) |
| Storage | NVMe (PCIe) + SATA (integrated in SoC) |
| Boot | SPI flash (BIOS chip) |

> **Alder Lake-N = All-in-one SiP.** No discrete PCH. All PCIe/SATA/USB/XHCI/SATA
> are integrated into the SoC package. This simplifies board layout but changes
> the memory map vs traditional desktop/mobile platforms with separate PCH.

---

## Hardware Specs

| Component | Details |
|-----------|---------|
| RAM | 2x LPDDR5 6400 8GB, 3 SKUs (Micron/Samsung/Hynix, see below) |
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

## Memory SKU Detection via GPIO Strapping

MBX222 Nissa uses **GPP_S4/S5/S6** for memory SKU detection. Three LPDDR5 8GB颗粒 are supported:

| SKU ID | Memory Part | Vendor | Part Number |
|--------|-----------|--------|-------------|
| 0 | LPDDR5 6400 8GB | **Micron** | MT62F2G32D8DR-031 WT:B |
| 1 | LPDDR5 6400 8GB | **Samsung** | K3LKCKC0BM-MGCP LF+HF |
| 2 | LPDDR5 6400 8GB | **Hynix** | H9JCNNNFA5MLYR-N6E LF+HF |
| 3-7 | Reserved | - | - |

GPIO strapping encoding (S4=bit0, S5=bit1, S6=bit2, pull-down default=0):

| GPP_S6 | GPP_S5 | GPP_S4 | SKU ID | Memory |
|--------|--------|--------|--------|--------|
| 0 | 0 | 0 | 0 | Micron MT62F2G32D8DR-031 |
| 0 | 0 | 1 | 1 | Samsung K3LKCKC0BM-MGCP |
| 0 | 1 | 0 | 2 | Hynix H9JCNNNFA5MLYR-N6E |
| 0 | 1 | 1 | 3 | Reserved |
| 1 | 0 | 0 | 4 | Reserved |
| 1 | 0 | 1 | 5 | Reserved |
| 1 | 1 | 0 | 6 | Reserved |
| 1 | 1 | 1 | 7 | Reserved |

> **Hardware design note:** Populate pull-down resistors (default=0) on all three pins.
> Only populate the pull-up on the pin corresponding to the desired SKU ID (bit=1).
> This minimizes resistor count on the PCB for any single SKU.

`memory.c` implementation:

```c
int __weak variant_memory_sku(void)
{
    // GPIO_MEM_CONFIG_0  GPP_S4  (bit0)
    // GPIO_MEM_CONFIG_1  GPP_S5  (bit1)
    // GPIO_MEM_CONFIG_2  GPP_S6  (bit2)
    gpio_t spd_gpios[] = { GPP_S4, GPP_S5, GPP_S6 };
    return gpio_base2_value(spd_gpios, ARRAY_SIZE(spd_gpios));
}
```

SPD hex files (already available in coreboot):

| SKU | coreboot path |
|-----|--------------|
| Micron | `spd/lp5/set-0/spd-4.hex` |
| Samsung | `spd/lp5/set-0/spd-6.hex` |
| Hynix | `spd/lp5/set-1/spd-4.hex` |

`mem_parts_used.txt` configuration:

```
# Part Name
MT62F2G32D8DR-031 WT:B
K3LKCKC0BM-MGCP
H9JCNNNFA5MLYR-N6E
```

---

## coreboot Board Structure

```
coreboot/
  src/mainboard/google/brya/         <- Parent board: Brya
    variants/
      nivviks/                        <- Reference variant (coreboot main)
      baseboard/
        nissa/                        <- Target board (coreboot main)
          boardinfo.cb
          config
          devicetree.cb
          gpio.c
          acpi/
          memory.c                    <- Memory SKU detection via GPP_S4/S5/S6
          variant/                    <- Nissa-specific overrides
```

> Brya is the parent board. Nivviks and Nissa are sibling variants under brya/variants/.

---

## Development Workflow

### Phase 1: Information Gathering
- [ ] Confirm Alder Lake-N SKU (e.g., Intel N100, N200, i3-N305, N5105)
- [ ] Verify hardware differences vs Nivviks (GPIO, peripherals)
- [ ] Confirm BIOS chip: size and type (SST/Winbond SPI flash, e.g., 8MB/16MB)
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
- [ ] Reference Nivviks variant (`brya/variants/nivviks/`), adapt:
  - [ ] boardinfo.cb
  - [ ] config (Kconfig)
  - [ ] devicetree.cb (GPIO pinmux)
  - [ ] gpio.c (GPIO initialization, include GPP_S4/S5/S6 strapping)
  - [ ] acpi/ (DSDT/SSDT tables)
  - [ ] memory.c (implement `variant_memory_sku()` with GPP_S4/S5/S6)
  - [ ] variant/ (board-specific overrides)
- [ ] Configure `mem_parts_used.txt` for 3-memory SKU support
- [ ] Configure FSP-M (Firmware Support Package - Memory init)
- [ ] Configure FSP-S (Silicon init for Alder Lake-N)
- [ ] Memory training: LPDDR5 (FSP-M handles, SPD hex already available)
- [ ] Configure Intel CNVi Wi-Fi (integrated in SoC)
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
- [ ] Memory SKU detection via GPP_S4/S5/S6 (verify all 3 IDs)
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
| Alder Lake-N FSP | https://github.com/intel/FSP (see setup below) |
| IT5571E datasheet | Contact ITE Tech Inc. (https://www.ite.com.tw/) |
| ITE EC SDK | ITEEC.mak + Keil project (reference only) |

---

## EC Reference Code Structure (Architecture Reference Only)

```
MI_EC_NB6590A_IT5771_DEMO/   <- Xiaomi reference (NB6590A platform, do not copy)
  Code/
    API/                      # Chip-level API (ADC, GPIO, PWM, SMBus...)
    CHIP/                     # Register definitions
      INCLUDE/CORE_CHIPREGS.H # 0x2000=ECHIPID1, 0x200A=BADRSEL
    CORE/                     # Core EC firmware
      CORE_COMMON/            # Core_Main.c, Core_Init.c, CORE_ACPI.c...
      CORE_BANK0/             # CORE_FLASH, CORE_SCAN, CORE_PS2...
      INCLUDE/                # CORE_INIT.H: base port 0x4E/0x4F
    OEM/NB6590A/             # Platform OEM layer
      INCLUDE/
        OEM_PROJECT.H        # ITE_CHIP_IT557X=TRUE
        OEM_HOSTIF.H         # Host interface (LPC/eSPI)
      OEM_BANK0/             # OEM_MAIN.C, OEM_POWER.C, OEM_FAN.C...
      USBC_PD/               # USB-C PD (Cypress/ITE/TI drivers)
  ROM/                        # Pre-built binaries
  uVision/                   # Keil uVision project (.uvproj)
```

---

### Intel FSP Setup (Required)

Intel FSP binaries are **binary blobs not on public git**, so the `3rdparty/fsp` submodule is
skipped during clone. You must download them manually:

```bash
# 1. Clone the FSP repo
git clone https://github.com/intel/FSP.git

# 2. Copy ADL-N FSP binaries to coreboot
cp -r FSP/AlderLakeFspBinPkg/IoT/AlderLakeN \
      /path/to/coreboot/3rdparty/fsp/AlderLakeN/

# 3. Or if using the repo layout directly:
cp -r FSP/ /path/to/coreboot/3rdparty/fsp/
```

Required FSP components for Alder Lake-N:
- **FSP-M:** Memory init (LPDDR5 training)
- **FSP-S:** Silicon init (CPU/PCH config)
- **FSP-O:** Optional, for graphics

coreboot expects FSP binaries at:
```
coreboot/3rdparty/fsp/AlderLakeN/Fsp.fd          # Combined FSP
coreboot/3rdparty/fsp/AlderLakeN/FspM.fd         # Memory init
coreboot/3rdparty/fsp/AlderLakeN/FspS.fd         # Silicon init
coreboot/3rdparty/fsp/AlderLakeN/Fsp.bin         # Legacy format
```

---

## Notes & Gotchas

- **Alder Lake-N single-chip:** PCIe lanes, SATA, USB, XHCI all inside SoC. No PCH.
  Memory map differs from desktop ADL platforms.
- **Intel CNVI:** RF/analog on CPU package + separate PCIe WLAN card (baseband).
  coreboot FSP must support CNVI driver initialization. Verify FSP-M/S version.
- **LPDDR5 memory:** MBX222 supports 3 SKUs (Micron/Samsung/Hynix) via GPP_S4/S5/S6
  strapping (2^3=8 combinations). SPD hex files already in coreboot.
  Implement `variant_memory_sku()` in `memory.c` with GPP_S4/S5/S6 pins.
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
