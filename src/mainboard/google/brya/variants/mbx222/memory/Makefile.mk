# SPDX-License-Identifier: GPL-2.0-or-later
#
# MBX222 memory configuration
# DDR4 SODIMM - SPD is read from DIMM via SMBus at runtime
# No static SPD hex files needed for SODIMM configuration
#
# The memory configuration is handled by the baseboard memory.c override
# which configures MEM_TYPE_DDR4 and MEM_TOPO_DIMM_MODULE.
# SPD data is read from the SODIMM EEPROM via SMBus address 0x50.

# Empty - DDR4 SODIMM reads SPD from module EEPROM at runtime
SPD_SOURCES =