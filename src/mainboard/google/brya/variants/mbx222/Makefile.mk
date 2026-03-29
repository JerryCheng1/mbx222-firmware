# SPDX-License-Identifier: GPL-2.0-or-later
#
# MBX222 variant Makefile
# Alder Lake N, ITE IT5771E EC via eSPI, DDR4 SODIMM

bootblock-y += gpio.c
verstage-y += gpio.c
romstage-y += gpio.c
ramstage-y += gpio.c
ramstage-y += variant.c

# Enable fw_config probing
ramstage-$(CONFIG_FW_CONFIG) += fw_config.c