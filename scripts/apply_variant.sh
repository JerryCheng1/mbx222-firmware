#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# MBX222 Board Variant Integration Script
# Links variant files into the coreboot source tree using symlinks.
# Changes can be reverted with restore_original.sh
#
# Usage: ./scripts/apply_variant.sh [coreboot_path]
#
# coreboot_path defaults to ../coreboot

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COREBOOT_DIR="${1:-${PROJECT_DIR}/../coreboot}"

echo "=== MBX222 Board Variant Integration (symlink mode) ==="
echo "Project dir:  ${PROJECT_DIR}"
echo "Coreboot dir: ${COREBOOT_DIR}"

# Validate coreboot directory
if [ ! -f "${COREBOOT_DIR}/Makefile" ]; then
	echo "ERROR: ${COREBOOT_DIR} does not appear to be a valid coreboot tree"
	exit 1
fi

if [ ! -d "${COREBOOT_DIR}/src/mainboard/google/brya" ]; then
	echo "ERROR: brya mainboard not found in ${COREBOOT_DIR}"
	exit 1
fi

echo ""
echo "Step 1: Patching Kconfig..."

# Apply Kconfig patch (add BOARD_GOOGLE_MBX222 entry)
BRYA_KCONFIG="${COREBOOT_DIR}/src/mainboard/google/brya/Kconfig"
BRYA_KCONFIG_NAME="${COREBOOT_DIR}/src/mainboard/google/brya/Kconfig.name"

# Check if already patched
if grep -q "BOARD_GOOGLE_MBX222" "${BRYA_KCONFIG}" 2>/dev/null; then
	echo "  Kconfig already patched, skipping..."
else
	# Backup original
	cp -f "${BRYA_KCONFIG}" "${BRYA_KCONFIG}.mbx222_bak"

	sed -i '/^config BOARD_GOOGLE_NIVVIKS/i\
config BOARD_GOOGLE_MBX222\
\tbool "->  MBX222 (Alder Lake N, ITE IT5771E EC)"\
\tselect BOARD_GOOGLE_BASEBOARD_BRYA\
\tselect CHROMEOS\
\tselect DRIVERS_INTEL_DPTC_SUPPORT\
\tselect DRIVERS_I2C_GENERIC\
\tselect DRIVERS_USB_ACPI\
\tselect EC_GOOGLE_CHROMEEC\
\tselect EC_GOOGLE_CHROMEEC_ESPI\
\tselect HAVE_WWAN_POWER_SEQUENCE\
\tselect MAINBOARD_HAS_CHROMEOS_DYNAMIC\
\tselect MEMORY_SODIMM\
\tselect SOC_INTEL_ALDERLAKE\
\tselect SOC_INTEL_COMMON_BLOCK_HDA\
\tselect SUPERIO_ITE_IT5771E\
\tselect SYSTEM_TYPE_LAPTOP\
\tselect TPM_GOOGLE_TI50\
\tselect USE_SAR\
\tselect VBOOT\
\thelp\
\t  MBX222 board based on Alder Lake N with ITE IT5771E EC via eSPI,\
\t  DDR4 SODIMM, 1x NVMe, 1x SATA, onboard CNVi WLAN.\
' "${BRYA_KCONFIG}"
	echo "  Kconfig patched (backup: Kconfig.mbx222_bak)."
fi

# Apply Kconfig.name patch
if grep -q "BOARD_GOOGLE_MBX222" "${BRYA_KCONFIG_NAME}" 2>/dev/null; then
	echo "  Kconfig.name already patched, skipping..."
else
	cp -f "${BRYA_KCONFIG_NAME}" "${BRYA_KCONFIG_NAME}.mbx222_bak"

	sed -i '/^config BOARD_GOOGLE_NIVVIKS/i\
config BOARD_GOOGLE_MBX222\
\tbool "MBX222"\
' "${BRYA_KCONFIG_NAME}"
	echo "  Kconfig.name patched (backup: Kconfig.name.mbx222_bak)."
fi

echo ""
echo "Step 2: Linking MBX222 variant directory..."

VARIANT_SRC="${PROJECT_DIR}/src/mainboard/google/brya/variants/mbx222"
VARIANT_DST="${COREBOOT_DIR}/src/mainboard/google/brya/variants/mbx222"

if [ -L "${VARIANT_DST}" ]; then
	echo "  Symlink already exists, skipping..."
elif [ -d "${VARIANT_DST}" ]; then
	echo "  WARNING: ${VARIANT_DST} exists as real directory (from previous copy)"
	echo "  Removing copied directory and creating symlink..."
	rm -rf "${VARIANT_DST}"
	ln -s "${VARIANT_SRC}" "${VARIANT_DST}"
	echo "  Linked: ${VARIANT_DST} -> ${VARIANT_SRC}"
else
	ln -s "${VARIANT_SRC}" "${VARIANT_DST}"
	echo "  Linked: ${VARIANT_DST} -> ${VARIANT_SRC}"
fi

echo ""
echo "Step 3: Linking baseboard override files..."

BASEBOARD_SRC="${PROJECT_DIR}/src/mainboard/google/brya/overrides/baseboard/nissa"
BASEBOARD_DST="${COREBOOT_DIR}/src/mainboard/google/brya/variants/baseboard/nissa"

for f in memory.c gpio.c; do
	src="${BASEBOARD_SRC}/${f}"
	dst="${BASEBOARD_DST}/${f}"

	if [ -L "${dst}" ]; then
		echo "  ${f} already a symlink, skipping..."
	elif [ -f "${dst}.mbx222_bak" ]; then
		echo "  ${f} already backed up, skipping..."
	else
		echo "  Backing up and linking: ${f}"
		mv -f "${dst}" "${dst}.mbx222_bak"
		ln -s "${src}" "${dst}"
	fi
done

# Baseboard headers
mkdir -p "${BASEBOARD_DST}/include/baseboard"
for f in ec.h gpio.h; do
	src="${BASEBOARD_SRC}/include/baseboard/${f}"
	dst="${BASEBOARD_DST}/include/baseboard/${f}"

	if [ -L "${dst}" ]; then
		echo "  ${f} already a symlink, skipping..."
	elif [ -f "${dst}.mbx222_bak" ]; then
		echo "  ${f} already backed up, skipping..."
	else
		echo "  Backing up and linking: include/baseboard/${f}"
		mv -f "${dst}" "${dst}.mbx222_bak"
		ln -s "${src}" "${dst}"
	fi
done

echo ""
echo "Step 4: Linking IT5771E driver..."

SIO_SRC="${PROJECT_DIR}/src/superio/ite/it5771e/it5771e.h"
SIO_DST="${COREBOOT_DIR}/src/superio/ite/it5771e/it5771e.h"

if [ -L "${SIO_DST}" ]; then
	echo "  Already a symlink, skipping..."
elif [ -f "${SIO_DST}.mbx222_bak" ]; then
	echo "  Already backed up, skipping..."
else
	echo "  Backing up and linking: it5771e.h"
	mv -f "${SIO_DST}" "${SIO_DST}.mbx222_bak"
	ln -s "${SIO_SRC}" "${SIO_DST}"
fi

echo ""
echo "Step 5: Linking FSP (Alder Lake N IoT)..."

FSP_SRC="${PROJECT_DIR}/3rdparty/fsp/AlderLakeN"
FSP_DST="${COREBOOT_DIR}/3rdparty/fsp/AlderLakeN"

mkdir -p "${COREBOOT_DIR}/3rdparty/fsp"

if [ -L "${FSP_DST}" ]; then
	echo "  Symlink already exists, skipping..."
elif [ -d "${FSP_DST}" ]; then
	echo "  WARNING: ${FSP_DST} exists as real directory (from previous copy)"
	echo "  Removing copied directory and creating symlink..."
	rm -rf "${FSP_DST}"
	ln -s "${FSP_SRC}" "${FSP_DST}"
	echo "  Linked: ${FSP_DST} -> ${FSP_SRC}"
else
	ln -s "${FSP_SRC}" "${FSP_DST}"
	echo "  Linked: ${FSP_DST} -> ${FSP_SRC}"
fi

echo ""
echo "Step 6: Creating defconfig..."

cp -v "${PROJECT_DIR}/defconfig" "${COREBOOT_DIR}/.config"

echo ""
echo "=== Integration complete! ==="
echo ""
echo "To build:"
echo "  cd ${COREBOOT_DIR}"
echo "  make olddefconfig"
echo "  make -j\$(nproc)"
echo ""
echo "Or use the build script (recommended):"
echo "  ./scripts/build.sh"
echo ""
echo "To restore original files:"
echo "  ./scripts/restore_original.sh"
echo "  # or"
echo "  ./scripts/build.sh clean"