/* SPDX-License-Identifier: GPL-2.0-or-later */

/*
 * MBX222: DDR4 SODIMM memory configuration
 * Alder Lake N platform with single DDR4 SODIMM slot
 * Overrides Nissa baseboard LP5X soldered-down configuration
 */

#include <baseboard/gpio.h>
#include <baseboard/variants.h>
#include <gpio.h>
#include <soc/romstage.h>

static const struct mb_cfg ddr4_mem_config = {
	.type = MEM_TYPE_DDR4,

	.rcomp = {
		/* Board uses 100ohm Rcomp resistors */
		.resistor = 100,

		/* Rcomp target values */
		.targets = {50, 20, 25, 25, 25},
	},

	.LpDdrDqDqsReTraining = 1,

	.ect = 1, /* Early Command Training */

	.UserBd = BOARD_TYPE_MOBILE,

	.ddr_config = {
		.dq_pins_interleaved = 1,
	},
};

const struct mb_cfg *__weak variant_memory_params(void)
{
	return &ddr4_mem_config;
}

bool __weak variant_is_half_populated(void)
{
	/*
	 * Alder Lake N has single memory channel.
	 * Single SODIMM slot = half populated (64-bit width on single channel).
	 */
	return true;
}

void __weak variant_get_spd_info(struct mem_spd *spd_info)
{
	/*
	 * DDR4 SODIMM - read SPD via SMBus from DIMM slot.
	 * Channel 0, Slot 0 at SMBus address 0x50.
	 * Only one physical slot on this board.
	 */
	spd_info->topo = MEM_TOPO_DIMM_MODULE;
	spd_info->smbus[0].addr_dimm[0] = 0x50;
}
</end_content>
<task_progress>
- [x] 创建项目目录结构
- [ ] 创建 Nissa baseboard 覆盖文件 (memory.c - DDR4, gpio.c, ec.h, gpio.h)
- [ ] 创建 MBX222 变体 GPIO 配置 (gpio.c)
- [ ] 创建 MBX222 变体设备树覆盖 (overridetree.cb)
- [ ] 创建 MBX222 变体头文件 (ec.h, gpio.h)
- [ ] 创建 MBX222 变体 Makefile.mk
- [ ] 创建 MBX222 变体 variant.c 和 fw_config.c
- [ ] 创建 MBX222 内存配置文件
- [ ] 创建 IT5771E 驱动修改文件
- [ ] 创建 Kconfig 补丁
- [ ] 创建 defconfig 编译配置
- [ ] 创建构建脚本和文档
</task_progress>
</write_to_file>