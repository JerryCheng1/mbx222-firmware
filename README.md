# MBX222 Firmware - Alder Lake N Board Port

基于 coreboot 的 MBX222 板级 UEFI BIOS 固件移植项目。

## 平台概述

| 项目 | 规格 |
|------|------|
| **平台** | Intel Alder Lake N (ADL-N) |
| **基板** | Google Nissa (brya 系列) |
| **参考变体** | Craask |
| **SoC** | ADL-N 4核 (2P + 2E), 6W TDP |
| **内存** | DDR4 单槽 SODIMM (非 LP5X) |
| **存储** | 1x NVMe (PCIe RP9) + 1x SATA AHCI |
| **无线** | 板载 Intel CNVi WLAN |
| **eMMC** | 无 (已禁用) |
| **EC** | ITE IT5771VG (eSPI 接口) |
| **Super I/O 配置端口** | 0x4EEC |
| **Super I/O I/O 地址** | 0x0A00 |
| **Debug UART (COM1)** | 0x3F8 |
| **TPM** | Google Ti50 (I2C) |

## eSPI GPIO 映射

EC (IT5771VG) 通过 eSPI 接口连接到 PCH，GPIO 对应关系：

| EC 信号 | PCH GPIO | 功能 |
|---------|----------|------|
| EC_CLK | GPP_A9 | ESPI_CLK |
| EC_IO3 | GPP_A3 | ESPI_IO3/SUSACK# |
| EC_IO2 | GPP_A2 | ESPI_IO2/SUSWARN#/SUSPWRDNACK |
| EC_IO1 | GPP_A1 | ESPI_IO1 |
| EC_IO0 | GPP_A0 | ESPI_IO0 |
| EC_CS | GPP_A4 | ESPI_CS0# |
| EC_RST | GPP_A10 | ESPI_RESET# |

## 目录结构

```
mbx222-firmware/
├── README.md                           # 本文件
├── defconfig                           # coreboot 编译配置
├── patches/
│   ├── Kconfig.patch                   # 板级 Kconfig 补丁
│   └── Kconfig.name.patch              # 板级 Kconfig.name 补丁
├── scripts/
│   ├── build.sh                        # 一键编译脚本 (symlink 方式, 不污染 coreboot)
│   ├── apply_variant.sh                # 集成脚本 (symlink 方式)
│   └── restore_original.sh             # 恢复脚本 (还原 coreboot 树)
├── 3rdparty/fsp/AlderLakeN/            # Intel FSP (ADL-N IoT 版本)
│   ├── Fsp.fd                          # FSP 固件二进制 (1.2 MB)
│   ├── Fsp.bsf                         # FSP 启动设置文件 (543 KB)
│   ├── README.md                       # Intel FSP 说明
│   ├── Include/                        # FSP UPD 头文件
│   │   ├── FspUpd.h                    # UPD 顶层头文件
│   │   ├── FsptUpd.h                   # Temp RAM 初始化 UPD
│   │   ├── FspmUpd.h                   # 内存初始化 UPD
│   │   ├── FspsUpd.h                   # Silicon 初始化 UPD
│   │   ├── FspInfoHob.h                # FSP Info HOB
│   │   ├── FirmwareVersionInfoHob.h    # 固件版本信息 HOB
│   │   └── MemInfoHob.h                # 内存信息 HOB
│   └── Vbt/
│       └── Vbt_ADLN.bin                # ADL-N 专用 VBT (Video BIOS Table)
├── src/
│   ├── mainboard/google/brya/
│   │   ├── overrides/baseboard/nissa/  # Nissa 基板覆盖文件
│   │   │   ├── memory.c               # DDR4 SODIMM 内存配置
│   │   │   ├── gpio.c                 # GPIO 完整配置
│   │   │   └── include/baseboard/
│   │   │       ├── ec.h               # ITE IT5771E EC 定义
│   │   │       └── gpio.h             # GPIO 宏定义
│   │   └── variants/mbx222/           # MBX222 变体文件
│   │       ├── Makefile.mk            # 构建规则
│   │       ├── gpio.c                 # 变体 GPIO 覆盖
│   │       ├── overridetree.cb        # 设备树覆盖 (关键配置)
│   │       ├── variant.c              # 设备树动态更新
│   │       ├── fw_config.c            # 固件配置探测
│   │       ├── include/variant/
│   │       │   ├── ec.h               # 变体 EC 定义
│   │       │   └── gpio.h             # 变体 GPIO 宏
│   │       └── memory/
│   │           └── Makefile.mk        # 内存构建规则 (SPD 从 DIMM 读取)
│   └── superio/ite/it5771e/
│       └── it5771e.h                  # IT5771E 头文件 (自定义配置端口)
```

## 关键配置说明

### 1. 内存 (DDR4 SODIMM)

MBX222 使用 DDR4 SODIMM 而非 Nissa 默认的 LP5X 焊接内存：
- `memory.c` 中配置 `MEM_TYPE_DDR4` 和 `MEM_TOPO_DIMM_MODULE`
- SPD 数据通过 SMBus 从 DIMM EEPROM 读取 (地址 0x50)
- `half_populated = true` (ADL-N 单通道)

### 2. ITE IT5771E EC (eSPI)

替换了 Nissa 默认的 Chrome EC：
- 配置端口: 0x4EEC (扩展地址)
- 数据端口: 0x4EED
- I/O 基地址: 0x0A00
- 走 eSPI 四线模式 (Quad I/O)
- eSPI 时钟频率: 20MHz

### 3. 存储配置

- **NVMe**: PCIe Root Port 9, SRCCLKREQ1, CLKREQ2
- **SATA**: AHCI 模式, Port 0 启用, 无 DevSlp
- **eMMC**: 已禁用 (硬件不存在)
- **SD Card**: 已禁用

### 4. USB 配置

- USB2 Port 0-1: Type-C
- USB2 Port 2-4: Type-A
- USB3 Port 0-1: Type-A
- 所有端口不做过流检测 (OC_SKIP)

### 5. WLAN 配置

板载 Intel CNVi WiFi：
- CNV_BRI_DT/RS: GPP_F0/F1
- CNV_RGI_DT/RS: GPP_F2/F3
- CNV_RF_RESET#: GPP_F4
- CNV_CLKREQ: GPP_F5 (NF3)
- WLAN_PCIE_WAKE: GPP_H3

### 6. FSP (Firmware Support Package)

本项目使用 Intel 公开的 ADL-N IoT 版本 FSP，来源于 [Intel FSP GitHub 仓库](https://github.com/intel/FSP/tree/master/AlderLakeFspBinPkg/IoT/AlderLakeN)。

**FSP 文件说明：**

| 文件 | 说明 |
|------|------|
| `Fsp.fd` | FSP 固件二进制，包含 FSP-T/M/S 三个模块 |
| `Fsp.bsf` | BCT 设置文件，描述所有 FSP UPD 参数 |
| `Include/FsptUpd.h` | Temp RAM 初始化阶段参数 (Cache-as-RAM) |
| `Include/FspmUpd.h` | 内存初始化阶段参数 (MRC, DDR4 配置等) |
| `Include/FspsUpd.h` | Silicon 初始化阶段参数 (PCIe, SATA, USB 等) |
| `Include/MemInfoHob.h` | 内存信息 HOB 数据结构 |
| `Vbt/Vbt_ADLN.bin` | ADL-N 专用 VBT (Video BIOS Table) |

**VBT 选择：** 通过 `defconfig` 中的 `CONFIG_VBT_FILE` 指定 VBT 文件路径：
```
CONFIG_VBT_FILE="3rdparty/fsp/AlderLakeN/Vbt/Vbt_ADLN.bin"
```

**适用 SKU：** 该 FSP 支持 ADL-N / Amston Lake (ASL) / Twin Lake (TWL) 系列：
- Intel Atom x7000 Series
- Intel Core i3-N305
- Intel Processor N150/N250
- Intel Core 3 Processor N355

## 编译步骤

### 1. 安装前置依赖

coreboot 编译需要以下工具链：

**Arch Linux:**

```bash
sudo pacman -S base-devel gcc cmake ninja iasl python3 nasm pkgconf \
    bison flex git gcc-ada imagemagick
```

**Ubuntu / Debian:**

```bash
sudo apt install build-essential gcc g++ cmake ninja-build iasl python3 \
    nasm pkg-config uuid-dev bison flex git m4 gnat imagemagick
```

### 2. 准备 coreboot 源码树

```bash
# 克隆 coreboot（如果还没有）
git clone https://review.coreboot.org/coreboot.git ../coreboot
cd ../coreboot
git submodule update --init --checkout  # 获取 3rdparty 子模块
```

FSP 已包含在本项目的 `3rdparty/fsp/AlderLakeN/` 目录中（来自 [Intel FSP GitHub](https://github.com/intel/FSP/tree/master/AlderLakeFspBinPkg/IoT/AlderLakeN)），无需额外下载。

### 3. 一键编译（推荐）

使用 `build.sh` 脚本自动完成所有步骤，编译完成后自动清理 coreboot 源码树（使用 symlink 方式，不污染源码）：

```bash
chmod +x scripts/*.sh

# 默认编译（编译完自动清理）
./scripts/build.sh

# 指定 coreboot 路径
./scripts/build.sh --coreboot-path /path/to/coreboot

# 指定编译线程数
./scripts/build.sh -j 8

# 编译但不清理（保留用于调试）
./scripts/build.sh --no-clean

# 仅清理（移除 symlink 和恢复原始文件）
./scripts/build.sh clean

# 查看帮助
./scripts/build.sh --help
```

**`build.sh` 参数说明：**

| 参数 | 说明 |
|------|------|
| *(无参数)* | 默认编译，完成后自动清理 coreboot 树 |
| `--no-clean` | 编译但不清理，保留 symlink（调试用） |
| `clean` | 仅清理，移除所有 symlink 并恢复原始文件 |
| `--coreboot-path PATH` | 指定 coreboot 源码路径（默认 `../coreboot`） |
| `-j N` | 编译线程数（默认自动检测） |
| `-h, --help` | 显示帮助信息 |

编译成功后，ROM 文件输出到 `build/coreboot_mbx222.rom`。

### 4. 分步操作（高级用户）

如果需要更多控制，可以分步执行：

```bash
# 步骤 A: 集成变体文件（symlink 方式，不复制文件）
./scripts/apply_variant.sh

# 步骤 B: 编译 coreboot
cd ../coreboot
make olddefconfig
make -j$(nproc)

# 步骤 C: 编译完成后恢复原始文件
cd ../mbx222-firmware
./scripts/restore_original.sh
# 或使用 build.sh 的 clean 命令:
./scripts/build.sh clean
```

### 使用 UEFI Payload (TianoCore)

如需生成完整的 UEFI BIOS 固件：

```bash
# 在 defconfig 中启用 TianoCore payload
echo "CONFIG_PAYLOAD_TIANOCORE=y" >> defconfig
./scripts/build.sh
```

## 调试

Debug UART 配置：
- 端口: COM1 (0x3F8)
- 波特率: 115200
- 数据位: 8, 无校验, 1停止位
- GPIO: H10 (RXD), H11 (TXD) - UART0 NF2

## 注意事项

1. **IT5771VG 配置端口**: 该芯片使用 0x4EEC 作为扩展配置端口，与标准 ITE 0x4E 不同。这是通过硬件 BADDR 引脚配置的。

2. **DDR4 SPD**: 确保安装的 DDR4 SODIMM 包含有效的 SPD EEPROM 数据。

3. **eSPI EC**: IT5771VG 的 eSPI 固件需要单独烧录到 EC 芯片中。

4. **FSP 版本**: 本项目已集成 Intel 公开 FSP IoT 版本（`3rdparty/fsp/AlderLakeN/`），支持 ADL-N/ASL/TWL 系列 SKU。如需更新，可从 [Intel FSP GitHub](https://github.com/intel/FSP/tree/master/AlderLakeFspBinPkg/IoT/AlderLakeN) 下载最新版本替换。

5. **BIOS 区域**: 确保_FLASH 描述文件中为 NVMe Opal 等功能预留足够空间。

## License

GPL-2.0-or-later (与 coreboot 项目一致)