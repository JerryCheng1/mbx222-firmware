#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Restore original coreboot files after MBX222 integration
# Handles both symlink-based and legacy copy-based integrations

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COREBOOT_DIR="${1:-${PROJECT_DIR}/../coreboot}"

echo "=== Restoring original coreboot files ==="
echo "Coreboot dir: ${COREBOOT_DIR}"

# Remove MBX222 variant symlink or directory
VARIANT_DST="${COREBOOT_DIR}/src/mainboard/google/brya/variants/mbx222"
if [ -L "${VARIANT_DST}" ]; then
	echo "Removing variant symlink: ${VARIANT_DST}"
	rm -f "${VARIANT_DST}"
elif [ -d "${VARIANT_DST}" ]; then
	echo "Removing variant directory (legacy copy): ${VARIANT_DST}"
	rm -rf "${VARIANT_DST}"
fi

# Restore baseboard files (check both .mbx222_bak and legacy .orig)
BASEBOARD_DST="${COREBOOT_DIR}/src/mainboard/google/brya/variants/baseboard/nissa"
for f in memory.c gpio.c; do
	dst="${BASEBOARD_DST}/${f}"
	if [ -L "${dst}" ]; then
		echo "Removing symlink: ${f}"
		rm -f "${dst}"
	fi
	# Restore from .mbx222_bak
	if [ -f "${dst}.mbx222_bak" ]; then
		echo "Restoring: ${f}"
		mv -f "${dst}.mbx222_bak" "${dst}"
	# Restore from legacy .orig
	elif [ -f "${dst}.orig" ]; then
		echo "Restoring (legacy): ${f}"
		mv -f "${dst}.orig" "${dst}"
	fi
done

# Restore baseboard headers
for f in ec.h gpio.h; do
	dst="${BASEBOARD_DST}/include/baseboard/${f}"
	if [ -L "${dst}" ]; then
		echo "Removing symlink: include/baseboard/${f}"
		rm -f "${dst}"
	fi
	if [ -f "${dst}.mbx222_bak" ]; then
		echo "Restoring: include/baseboard/${f}"
		mv -f "${dst}.mbx222_bak" "${dst}"
	fi
done

# Restore IT5771E header
SIO_DST="${COREBOOT_DIR}/src/superio/ite/it5771e/it5771e.h"
if [ -L "${SIO_DST}" ]; then
	echo "Removing symlink: it5771e.h"
	rm -f "${SIO_DST}"
fi
if [ -f "${SIO_DST}.mbx222_bak" ]; then
	echo "Restoring: it5771e.h"
	mv -f "${SIO_DST}.mbx222_bak" "${SIO_DST}"
elif [ -f "${SIO_DST}.orig" ]; then
	echo "Restoring (legacy): it5771e.h"
	mv -f "${SIO_DST}.orig" "${SIO_DST}"
fi

# Remove FSP symlink or directory
FSP_DST="${COREBOOT_DIR}/3rdparty/fsp/AlderLakeN"
if [ -L "${FSP_DST}" ]; then
	echo "Removing FSP symlink: ${FSP_DST}"
	rm -f "${FSP_DST}"
elif [ -d "${FSP_DST}" ]; then
	echo "Removing FSP directory (legacy copy): ${FSP_DST}"
	rm -rf "${FSP_DST}"
fi
# Clean up empty parent dirs
rmdir "${COREBOOT_DIR}/3rdparty/fsp" 2>/dev/null || true
rmdir "${COREBOOT_DIR}/3rdparty" 2>/dev/null || true

# Restore Kconfig files
BRYA_KCONFIG="${COREBOOT_DIR}/src/mainboard/google/brya/Kconfig"
BRYA_KCONFIG_NAME="${COREBOOT_DIR}/src/mainboard/google/brya/Kconfig.name"

for f in "${BRYA_KCONFIG}" "${BRYA_KCONFIG_NAME}"; do
	if [ -f "${f}.mbx222_bak" ]; then
		echo "Restoring: $(basename "${f}")"
		mv -f "${f}.mbx222_bak" "${f}"
	fi
done

# Restore vboot patches (GCC 14+ compatibility fix)
for vf in \
	"${COREBOOT_DIR}/3rdparty/vboot/futility/cmd_dump_fmap.c" \
	"${COREBOOT_DIR}/3rdparty/vboot/host/lib/host_key2.c" \
	"${COREBOOT_DIR}/3rdparty/vboot/futility/updater.c" \
	"${COREBOOT_DIR}/3rdparty/vboot/futility/updater_manifest.c" \
	"${COREBOOT_DIR}/3rdparty/vboot/futility/cmd_load_fmap.c"; do
	if [ -f "${vf}.mbx222_bak" ]; then
		echo "Restoring: $(echo "${vf}" | sed 's|.*/vboot/|vboot/|')"
		mv -f "${vf}.mbx222_bak" "${vf}"
	fi
done

# Remove .config if we created it
if [ -f "${COREBOOT_DIR}/.config" ]; then
	echo "Removing: .config"
	rm -f "${COREBOOT_DIR}/.config"
fi

echo "=== Restore complete ==="