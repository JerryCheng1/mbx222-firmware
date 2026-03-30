# 项目：Google Nissa (Alder Lake-N) - coreboot UEFI 移植

## 概述

将 coreboot UEFI 固件移植到 **Google Nissa** 主板（Alder Lake-N 平台）。
Nivviks 是 coreboot 代码树中的一个主板变体。EC 固件独立开发，参考小米
IT5571E EC 代码仅作为架构参考。

---

## 平台：Intel Alder Lake-N

| 项目 | 详情 |
|------|---------|
| SoC | Intel Alder Lake-N（单芯片 SiP，无独立 PCH）|
| CPU | E-core（Gracemont），或 E-core + P-core 组合 |
| TDP | 6W-15W（移动/超极本领域）|
| 内存 | LPDDR5 6400 板载，支持 3 种 SKU（见内存章节）|
| 存储 | NVMe (PCIe) + SATA（集成在 SoC 内）|
| 启动 | SPI Flash（BIOS 芯片）|

> **Alder Lake-N = 全合一 SiP。** 无独立 PCH，所有 PCIe/SATA/USB/XHCI/SATA
> 均集成在 SoC 封装内。这简化了主板布局，但与有独立 PCH 的传统桌面/移动
> 平台的内存布局不同。

---

## 硬件规格

| 组件 | 详情 |
|-----------|---------|
| RAM | 2x LPDDR5 6400 8GB，3 种 SKU（Micron/Samsung/Hynix，见下文）|
| NVMe | 1x M.2 PCIe x4 插槽 |
| SATA | 1x SATA III 插槽 |
| WLAN | Intel CNVI（Wi-Fi，集成在 SoC 内）+ PCIe WLAN 模块 |
| 以太网 | Realtek 千兆（待确认：USB 还是 PCIe？）|
| 音频 | Realtek ALC256 |
| 显示 | eDP 面板 + HDMI 输出 |
| USB | 2x USB-A 3.2 Gen 1 |
| SD 卡 | 内置 SD 卡读卡器 |
| TPM | 无 |

---

## EC 芯片：IT5571E（自主开发）

> EC 固件独立开发。小米 NB6590A IT5571E 代码仅作为架构参考，不直接复制。
> 这一区分保护了双方项目的知识产权。

### 芯片识别

| 寄存器 | 地址 | 值 |
|----------|---------|-------|
| ECHIPID1 | 0x2000 | 0x85 (IT5571E) |
| ECHIPID2 | 0x2001 | - |
| ECHIPVER | 0x2002 | - |

### 主机 I/O 端口

| 寄存器 | 值 | 描述 |
|----------|-------|-------------|
| BADRSEL | 0x02 | 基地址：用户定义 |
| SWCBALR | 0x4E | EC 索引端口 |
| SWCBAHR | 0x00 | EC 高字节 |
| **EC 端口** | **0x4E/0x4F** | 索引=0x4E，数据=0x4F |

### 主机 RAM 窗口（EC RAM 映射到主机）

| 寄存器 | 值 | 主机地址 |
|----------|-------|--------------|
| HRAMW0BA | 0xA0 | 0xFF0B_A000 |
| HRAMW1BA | 0x40 | 0xFF0B_4000 |
| HRAMWC | 0x01 | 窗口 0 启用，LPC |

LPC RAM 基址：0xFF0B_0000（F5=0x00，F6=0x0B，FC=0x00）

### 外设 I/O 基址

| 外设 | LDN | I/O 基址 | IRQ |
|------------|-----|----------|-----|
| UART1 | 01h | 0x3F8 | 5 |
| PS/2 鼠标 | 05h | - | 12 |
| SMBus | 12h | 0xF0 | - |

### 关键 EC 寄存器

| 寄存器 | 地址 |
|----------|---------|
| RSTS | 0x2006 |
| RSTC1 | 0x2007 |
| BADRSEL | 0x200A |
| WNCKR | 0x200B |

### EC 接口配置

```c
SUPPORT_INTERFACE_eSPI      TRUE
ITE_eSPI_LOW_FREQUENCY     TRUE
SHARED_BIOS_TRI_STATE       TRUE
SUPPORT_LPC_BUS_1_8V        TRUE
```

---

## 通过 GPIO strap 检测内存 SKU

MBX222 Nissa 使用 **GPP_S4/S5/S6** 进行内存 SKU 检测。支持三种 LPDDR5 8GB 颗粒：

| SKU ID | 内存型号 | 厂商 | 料号 |
|--------|-----------|--------|-------------|
| 0 | LPDDR5 6400 8GB | **Micron** | MT62F2G32D8DR-031 WT:B |
| 1 | LPDDR5 6400 8GB | **Samsung** | K3LKCKC0BM-MGCP LF+HF |
| 2 | LPDDR5 6400 8GB | **Hynix** | H9JCNNNFA5MLYR-N6E LF+HF |
| 3-7 | 保留 | - | - |

GPIO strap 编码（S4=bit0，S5=bit1，S6=bit2，下拉默认=0）：

| GPP_S6 | GPP_S5 | GPP_S4 | SKU ID | 内存 |
|--------|--------|--------|--------|--------|
| 0 | 0 | 0 | 0 | Micron MT62F2G32D8DR-031 |
| 0 | 0 | 1 | 1 | Samsung K3LKCKC0BM-MGCP |
| 0 | 1 | 0 | 2 | Hynix H9JCNNNFA5MLYR-N6E |
| 0 | 1 | 1 | 3 | 保留 |
| 1 | 0 | 0 | 4 | 保留 |
| 1 | 0 | 1 | 5 | 保留 |
| 1 | 1 | 0 | 6 | 保留 |
| 1 | 1 | 1 | 7 | 保留 |

> **硬件设计注意：** 所有三个引脚都焊接下拉电阻（默认=0）。
> 仅在对应 SKU ID 的引脚上（bit=1）焊接上拉电阻。
> 这样对任何单一 SKU 都能使 PCB 电阻数量最少。

`memory.c` 实现：

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

SPD hex 文件（coreboot 中已有）：

| SKU | coreboot 路径 |
|-----|--------------|
| Micron | `spd/lp5/set-0/spd-4.hex` |
| Samsung | `spd/lp5/set-0/spd-6.hex` |
| Hynix | `spd/lp5/set-1/spd-4.hex` |

`mem_parts_used.txt` 配置：

```
# Part Name
MT62F2G32D8DR-031 WT:B
K3LKCKC0BM-MGCP
H9JCNNNFA5MLYR-N6E
```

---

## coreboot 主板结构

```
coreboot/
  src/mainboard/google/brya/         <- 父主板：Brya
    variants/
      nivviks/                        <- 参考变体（coreboot 主线）
      baseboard/
        nissa/                        <- 目标主板（coreboot 主线）
          boardinfo.cb
          config
          devicetree.cb
          gpio.c
          acpi/
          memory.c                    <- 通过 GPP_S4/S5/S6 检测内存 SKU
          variant/                    <- Nissa 特定覆盖
```

> Brya 是父主板。Nivviks 和 Nissa 是 brya/variants/ 下的兄弟变体。

---

## 开发流程

### 阶段 1：信息收集
- [ ] 确认 Alder Lake-N SKU（N100 或 i3-N305；代码层面无差异，均为 ADL-N FSP，仅社区文档/踩坑资料多少不同）
- [ ] 确认与 Nivviks 的硬件差异（GPIO、外设）
- [ ] 确认 BIOS 芯片：容量和型号（SST/Winbond SPI Flash，如 8MB/16MB）
- [ ] 确认 WLAN 模块：Intel CNVI PHY + PCIe WLAN 卡型号
- [ ] 确认启动路径：SPI Flash 布局（boot block、EC、FMAP、RW_A/RW_B）

### 阶段 2：EC 固件开发
> 参考：小米的 NB6590A IT5571E 代码（仅架构参考，独立开发）
- [ ] 获取 IT5571E 数据手册（联系 ITE Tech Inc.）
- [ ] 开发 Nissa 专用 EC 固件：
  - [ ] SMBus/LPC/eSPI 主机接口（与 CPU 通信）
  - [ ] EC 中断：SMI、SCI、GPE（系统管理中断）
  - [ ] 电源状态管理：S0/S3/S4/S5（ACPI 电源状态）
  - [ ] 键盘扫描矩阵
  - [ ] 电池/SMBus 智能电池管理
  - [ ] 风扇控制（1 或 2 通道）
  - [ ] USB-C PD（Power Delivery）- Cypress/TI CCGx 驱动
  - [ ] 音频编解码器协调（HDA 链路）
  - [ ] EC 刷写/更新机制（boot block + 恢复）
- [ ] 构建 EC 固件：ITE SDK（Keil 或 ITEEC.mak）

### 阶段 3：coreboot 基础移植
- [ ] 克隆 coreboot：`git clone https://review.coreboot.org/coreboot`
- [ ] 参考 Nivviks 变体（`brya/variants/nivviks/`），适配：
  - [ ] boardinfo.cb
  - [ ] config（Kconfig）
  - [ ] devicetree.cb（GPIO 引脚复用）
  - [ ] gpio.c（GPIO 初始化，包含 GPP_S4/S5/S6 strap）
  - [ ] acpi/（DSDT/SSDT 表）
  - [ ] memory.c（用 GPP_S4/S5/S6 实现 `variant_memory_sku()`）
  - [ ] variant/（主板特定覆盖）
- [ ] 配置 `mem_parts_used.txt` 以支持 3 种内存 SKU
- [ ] 配置 FSP-M（Firmware Support Package - 内存初始化）
- [ ] 配置 FSP-S（Alder Lake-N 硅片初始化）
- [ ] 内存训练：LPDDR5（FSP-M 处理，SPD hex 已存在）
- [ ] 配置 Intel CNVi Wi-Fi（集成在 SoC 内）
- [ ] 配置 PCIe WLAN 插槽
- [ ] 配置 SATA/AHCI
- [ ] 配置 NVMe
- [ ] 配置 USB XHCI
- [ ] 配置 eDP + HDMI（FSP-O 或独立 VBIOS）
- [ ] 配置 ALC256 音频（HDA）
- [ ] 配置 SD 卡读卡器
- [ ] 配置 ACPI 表（S0ix、C-states、电源状态）

### 阶段 4：UEFI Payload
- [ ] 构建 Tianocore UEFI payload
- [ ] 集成 Gen12 显卡 VBIOS（Alder Lake-N 集成显卡）
- [ ] 验证 GOP（Graphics Output Protocol）：eDP + HDMI
- [ ] 在 UEFI 环境下验证音频编解码器（ALC256）

### 阶段 5：调试与验证
- [ ] 通过 UART1（0x3F8）输出 80Port POST 代码
- [ ] IPMI/KCS 调试接口
- [ ] EC<->CPU 通信测试（SMBus/LPC/eSPI）
- [ ] 通过 GPP_S4/S5/S6 检测内存 SKU（验证全部 3 个 ID）
- [ ] 启动到 UEFI Shell
- [ ] 启动到操作系统（Linux/ChromeOS）
- [ ] USB 端口枚举和功能
- [ ] NVMe/SATA 读写
- [ ] eDP + HDMI 显示输出
- [ ] 音频播放
- [ ] WLAN（CNVI + PCIe 卡）
- [ ] SD 卡读卡器
- [ ] S3/S4/S5 挂起/唤醒

---

## 关键参考

| 资源 | 位置 |
|----------|----------|
| coreboot 代码库 | https://review.coreboot.org/coreboot |
| Nivviks 变体 | `src/mainboard/google/brya/variants/nivviks/` |
| Nissa 变体（baseboard）| `src/mainboard/google/brya/variants/baseboard/nissa/` |
| Brya 父主板 | `src/mainboard/google/brya/` |
| Google Nissa (ChromeOS) | https://chromium.googlesource.com/chromiumos/third_party/coreboot/ |
| Alder Lake-N FSP | https://github.com/intel/FSP（见下方设置）|
| IT5571E 数据手册 | 联系 ITE Tech Inc.（https://www.ite.com.tw/）|
| ITE EC SDK | ITEEC.mak + Keil 项目（仅参考）|

---

## EC 参考代码结构（仅作架构参考）

```
MI_EC_NB6590A_IT5771_DEMO/   <- 小米参考（NB6590A 平台，请勿复制）
  Code/
    API/                      # 芯片级 API（ADC、GPIO、PWM、SMBus...）
    CHIP/                     # 寄存器定义
      INCLUDE/CORE_CHIPREGS.H # 0x2000=ECHIPID1，0x200A=BADRSEL
    CORE/                     # 核心 EC 固件
      CORE_COMMON/            # Core_Main.c、Core_Init.c、CORE_ACPI.c...
      CORE_BANK0/             # CORE_FLASH、CORE_SCAN、CORE_PS2...
      INCLUDE/                # CORE_INIT.H：基端口 0x4E/0x4F
    OEM/NB6590A/             # 平台 OEM 层
      INCLUDE/
        OEM_PROJECT.H        # ITE_CHIP_IT557X=TRUE
        OEM_HOSTIF.H         # 主机接口（LPC/eSPI）
      OEM_BANK0/             # OEM_MAIN.C、OEM_POWER.C、OEM_FAN.C...
      USBC_PD/               # USB-C PD（Cypress/ITE/TI 驱动）
  ROM/                        # 预编译二进制文件
  uVision/                   # Keil uVision 项目（.uvproj）
```

---

### Intel FSP + VBT 设置（必需）

Intel FSP 和 VBT 是**不在公共 git 上的二进制 blob**，所以克隆时 `3rdparty/fsp`
子模块会被跳过。需要手动下载：

```bash
# 1. 克隆 Intel FSP 仓库
git clone https://github.com/intel/FSP.git

# 2. 复制 ADL-N FSP 二进制文件到 coreboot
cp -r FSP/AlderLakeFspBinPkg/IoT/AlderLakeN \
      coreboot/3rdparty/fsp/AlderLakeN/
```

Alder Lake-N 所需的 FSP 组件：
- **FSP-M：** 内存初始化（LPDDR5 训练）
- **FSP-S：** 硅片初始化（CPU/PCH 配置）
- **FSP-O：** 可选，用于显卡

coreboot 期望的 FSP 二进制文件位置：
```
coreboot/3rdparty/fsp/AlderLakeN/Fsp.fd
coreboot/3rdparty/fsp/AlderLakeN/FspM.fd
coreboot/3rdparty/fsp/AlderLakeN/FspS.fd
```

### VBT（Video BIOS Table）设置

VBT（Video BIOS Table）是平台特定的显示配置 blob（eDP/HDMI 时序、面板信息）。
对于 Alder Lake-N，它包含在 FSP 包中：

```
https://github.com/intel/FSP/tree/master/AlderLakeFspBinPkg/IoT/AlderLakeN
```

ADL-N 的 VBT 文件名通常包含 "ADLN" 或 "AlderLakeN"。

```bash
# 1. 克隆 Intel FSP 仓库后（见上方 FSP 设置）
# 2. 在 ADL-N 目录中找到 VBT 文件
ls /path/to/FSP/AlderLakeFspBinPkg/IoT/AlderLakeN/*.bin
#   或
ls /path/to/FSP/AlderLakeFspBinPkg/IoT/AlderLakeN/*.vbt

# 3. 将 VBT 复制到 coreboot 主板目录（coreboot 将其嵌入 CBFS）
cp /path/to/FSP/AlderLakeFspBinPkg/IoT/AlderLakeN/*.bin \
      coreboot/src/mainboard/google/brya/variants/baseboard/nissa/data.vbt
```

VBT 文件在 coreboot 中的位置：
```
coreboot/src/mainboard/google/brya/variants/baseboard/nissa/data.vbt
```

> **重要：** 使用 ADL-N 专用的 VBT 二进制文件。使用其他平台（如 ADL-P、ADL-M）
> 的 VBT 会导致显示初始化失败或面板时序错误。

---

## 注意事项与坑点

- **Alder Lake-N 单芯片：** PCIe 通道、SATA、USB、XHCI 全部在 SoC 内部。
  与有独立 PCH 的桌面 ADL 平台相比，内存布局不同。
- **Intel CNVI：** 射频/模拟部分在 CPU 封装内 + 独立的 PCIe WLAN 卡（基带）。
  coreboot FSP 必须支持 CNVI 驱动初始化。请验证 FSP-M/S 版本。
- **LPDDR5 内存：** MBX222 支持 3 种 SKU（Micron/Samsung/Hynix），
  通过 GPP_S4/S5/S6 strap（2^3=8 种组合）。SPD hex 文件已在 coreboot 中。
  在 `memory.c` 中用 GPP_S4/S5/S6 引脚实现 `variant_memory_sku()`。
- **无 TPM：** 无 fTPM/Intel PTT。仅支持软件磁盘加密。BitLocker
  可能需要额外配置。
- **eSPI vs LPC：** 现代 ChromeOS 主板使用 eSPI 进行 EC-Host 通信。
  请确认 IT5571E eSPI 接口配置正确。
- **EC 刷写：** IT5571E 使用专用刷写机制。请确认
  boot block 恢复流程和内部编程模式。
- **小米参考代码：** 仅作架构参考使用。请独立开发
  Nissa 专用 EC 固件，以避免知识产权污染。
- **SPI Flash 布局：** 请确认 FMAP、RW_A/RW_B 分区。ChromeOS 使用
  带有 RO+RW 分区的验证启动。
