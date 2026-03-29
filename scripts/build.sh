#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# MBX222 Build Script
# Builds coreboot firmware using symlinks to avoid polluting the coreboot source tree.
# All changes to the coreboot tree are automatically cleaned up after build.
#
# Usage: ./scripts/build.sh [OPTIONS]
#
# Options:
#   (no options)           Build and auto-clean
#   --no-clean             Build without cleaning up (for debugging)
#   clean                  Only clean up (remove symlinks, restore originals)
#   --coreboot-path PATH   Specify coreboot source tree path (default: ../coreboot)
#   -j N                   Number of build jobs (default: auto-detect)
#   -h, --help             Show this help message

set -e

# ============================================================
# Configuration
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COREBOOT_DIR=""
NO_CLEAN=0
JOBS="$(nproc 2>/dev/null || echo 4)"
ACTION="build"

# ============================================================
# Parse arguments
# ============================================================

while [[ $# -gt 0 ]]; do
	case "$1" in
		--coreboot-path)
			COREBOOT_DIR="$2"
			shift 2
			;;
		--no-clean)
			NO_CLEAN=1
			shift
			;;
		clean)
			ACTION="clean"
			shift
			;;
		-j)
			JOBS="$2"
			shift 2
			;;
		-h|--help)
			echo "Usage: ./scripts/build.sh [OPTIONS]"
			echo ""
			echo "Options:"
			echo "  (no options)           Build and auto-clean"
			echo "  --no-clean             Build without cleaning up (for debugging)"
			echo "  clean                  Only clean up (remove symlinks, restore originals)"
			echo "  --coreboot-path PATH   Specify coreboot source tree path (default: ../coreboot)"
			echo "  -j N                   Number of build jobs (default: $(nproc 2>/dev/null || echo 4))"
			echo "  -h, --help             Show this help message"
			exit 0
			;;
		*)
			echo "ERROR: Unknown option: $1"
			echo "Use --help for usage information."
			exit 1
			;;
	esac
done

# Default coreboot path
COREBOOT_DIR="${COREBOOT_DIR:-${PROJECT_DIR}/../coreboot}"

# ============================================================
# Helper functions
# ============================================================

# Track files/dirs we've modified so we can clean up
CLEANUP_LIST="${PROJECT_DIR}/.build_cleanup_$$"
touch "${CLEANUP_LIST}"

cleanup_handler() {
	if [ "${NO_CLEAN}" = "1" ] || [ ! -f "${CLEANUP_LIST}" ]; then
		rm -f "${CLEANUP_LIST}" 2>/dev/null
		return
	fi
	echo ""
	echo "=== Auto-cleaning coreboot tree ==="
	do_cleanup
	rm -f "${CLEANUP_LIST}"
}

do_cleanup() {
	while IFS= read -r entry; do
		[ -z "${entry}" ] && continue
		type="${entry%%:*}"
		path="${entry#*:}"

		case "${type}" in
			symlink_dir)
				if [ -L "${path}" ]; then
					echo "  Removing symlink: ${path}"
					rm -f "${path}"
				fi
				;;
			symlink_file)
				if [ -L "${path}" ]; then
					echo "  Removing symlink: ${path}"
					rm -f "${path}"
				fi
				;;
			backup_restore)
				if [ -f "${path}.mbx222_bak" ]; then
					echo "  Restoring: ${path}"
					mv -f "${path}.mbx222_bak" "${path}"
				fi
				;;
			kconfig_patch)
				if [ -f "${path}.mbx222_bak" ]; then
					echo "  Restoring Kconfig: ${path}"
					mv -f "${path}.mbx222_bak" "${path}"
				fi
				;;
			config_file)
				if [ -f "${path}" ]; then
					echo "  Removing: ${path}"
					rm -f "${path}"
				fi
				;;
		esac
	done < "${CLEANUP_LIST}"

	# Try to remove empty parent directories we may have created
	rmdir "${COREBOOT_DIR}/3rdparty/fsp" 2>/dev/null || true
	rmdir "${COREBOOT_DIR}/3rdparty" 2>/dev/null || true
}

register_cleanup() {
	echo "$1" >> "${CLEANUP_LIST}"
}

# ============================================================
# Validate environment
# ============================================================

echo "=== MBX222 Build Script ==="
echo "Project dir:    ${PROJECT_DIR}"
echo "Coreboot dir:   ${COREBOOT_DIR}"
echo "Jobs:           ${JOBS}"
echo ""

# Auto-clone coreboot if not present
if [ ! -d "${COREBOOT_DIR}" ]; then
	echo "Coreboot tree not found at ${COREBOOT_DIR}"
	echo "Cloning coreboot repository..."
	git clone https://review.coreboot.org/coreboot.git "${COREBOOT_DIR}"
	if [ $? -ne 0 ]; then
		echo "ERROR: Failed to clone coreboot"
		exit 1
	fi
	echo "Coreboot cloned successfully."
	echo ""
fi

if [ ! -f "${COREBOOT_DIR}/Makefile" ]; then
	echo "ERROR: ${COREBOOT_DIR} does not appear to be a valid coreboot tree"
	echo "Hint: clone coreboot to ../coreboot or specify --coreboot-path"
	exit 1
fi

if [ ! -d "${COREBOOT_DIR}/src/mainboard/google/brya" ]; then
	echo "ERROR: brya mainboard not found in ${COREBOOT_DIR}"
	exit 1
fi

# Auto-initialize submodules (especially tianocore for UEFI payload)
echo "Checking submodules..."
cd "${COREBOOT_DIR}"

# Initialize and update all submodules if .gitmodules exists
if [ -f ".gitmodules" ]; then
	# Check if submodules are already initialized
	SUBMODULES_NEED_INIT=0

	# Check critical submodules
	for sub in 3rdparty/tianocore 3rdparty/vboot 3rdparty/libgfxinit 3rdparty/libhwbase; do
		if [ -f ".gitmodules" ] && grep -q "${sub}" .gitmodules 2>/dev/null; then
			if [ ! -f "${sub}/.git" ] && [ ! -f "${sub}/Makefile" ]; then
				echo "  Submodule ${sub} needs initialization"
				SUBMODULES_NEED_INIT=1
			fi
		fi
	done

	if [ "${SUBMODULES_NEED_INIT}" = "1" ]; then
		echo "Initializing submodules (this may take a while)..."
		git submodule update --init --checkout 2>&1 || {
			echo "WARNING: Full submodule update failed, trying critical ones individually..."
			git submodule update --init --checkout 3rdparty/vboot 2>&1 || true
			git submodule update --init --checkout 3rdparty/tianocore 2>&1 || true
			git submodule update --init --checkout 3rdparty/libgfxinit 2>&1 || true
			git submodule update --init --checkout 3rdparty/libhwbase 2>&1 || true
		}
		echo "Submodules initialized."
	else
		echo "  All critical submodules present."
	fi
fi

cd "${PROJECT_DIR}"
echo ""

# ============================================================
# Clean-only mode
# ============================================================

if [ "${ACTION}" = "clean" ]; then
	echo "=== Cleaning up coreboot tree ==="
	# Also check for legacy .orig backups from old apply_variant.sh
	for f in \
		"${COREBOOT_DIR}/src/mainboard/google/brya/variants/baseboard/nissa/memory.c.orig" \
		"${COREBOOT_DIR}/src/mainboard/google/brya/variants/baseboard/nissa/gpio.c.orig" \
		"${COREBOOT_DIR}/src/superio/ite/it5771e/it5771e.h.orig"; do
		if [ -f "${f}" ]; then
			orig_name="${f%.orig}"
			echo "  Restoring (legacy): ${orig_name}"
			mv -f "${f}" "${orig_name}"
		fi
	done
	# Also clean up any copied mbx222 variant dir
	if [ -d "${COREBOOT_DIR}/src/mainboard/google/brya/variants/mbx222" ] && \
	   [ ! -L "${COREBOOT_DIR}/src/mainboard/google/brya/variants/mbx222" ]; then
		echo "  Removing copied variant directory (legacy)"
		rm -rf "${COREBOOT_DIR}/src/mainboard/google/brya/variants/mbx222"
	fi
	do_cleanup
	echo "=== Clean complete ==="
	exit 0
fi

# Register cleanup handler (runs on exit unless --no-clean)
trap cleanup_handler EXIT

# ============================================================
# Step 1: Symlink MBX222 variant directory
# ============================================================

echo "Step 1: Linking MBX222 variant..."

VARIANT_SRC="${PROJECT_DIR}/src/mainboard/google/brya/variants/mbx222"
VARIANT_DST="${COREBOOT_DIR}/src/mainboard/google/brya/variants/mbx222"

if [ -L "${VARIANT_DST}" ]; then
	echo "  Symlink already exists, skipping..."
elif [ -d "${VARIANT_DST}" ]; then
	echo "  WARNING: ${VARIANT_DST} exists as real directory (from previous copy)"
	echo "  Removing copied directory and creating symlink..."
	rm -rf "${VARIANT_DST}"
	ln -s "${VARIANT_SRC}" "${VARIANT_DST}"
	register_cleanup "symlink_dir:${VARIANT_DST}"
else
	ln -s "${VARIANT_SRC}" "${VARIANT_DST}"
	register_cleanup "symlink_dir:${VARIANT_DST}"
	echo "  Linked: ${VARIANT_DST} -> ${VARIANT_SRC}"
fi

# ============================================================
# Step 2: Backup and replace baseboard override files
# ============================================================

echo ""
echo "Step 2: Linking baseboard override files..."

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
		echo "  Backing up and replacing: ${f}"
		mv -f "${dst}" "${dst}.mbx222_bak"
		ln -s "${src}" "${dst}"
		register_cleanup "backup_restore:${dst}"
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
		echo "  Backing up and replacing: include/baseboard/${f}"
		mv -f "${dst}" "${dst}.mbx222_bak"
		ln -s "${src}" "${dst}"
		register_cleanup "backup_restore:${dst}"
	fi
done

# ============================================================
# Step 3: Backup and replace IT5771E driver
# ============================================================

echo ""
echo "Step 3: Linking IT5771E driver..."

SIO_SRC="${PROJECT_DIR}/src/superio/ite/it5771e/it5771e.h"
SIO_DST="${COREBOOT_DIR}/src/superio/ite/it5771e/it5771e.h"

if [ -L "${SIO_DST}" ]; then
	echo "  Already a symlink, skipping..."
elif [ -f "${SIO_DST}.mbx222_bak" ]; then
	echo "  Already backed up, skipping..."
else
	echo "  Backing up and replacing: it5771e.h"
	mv -f "${SIO_DST}" "${SIO_DST}.mbx222_bak"
	ln -s "${SIO_SRC}" "${SIO_DST}"
	register_cleanup "backup_restore:${SIO_DST}"
fi

# ============================================================
# Step 4: Symlink FSP files
# ============================================================

echo ""
echo "Step 4: Linking FSP (Alder Lake N IoT)..."

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
	register_cleanup "symlink_dir:${FSP_DST}"
else
	ln -s "${FSP_SRC}" "${FSP_DST}"
	register_cleanup "symlink_dir:${FSP_DST}"
	echo "  Linked: ${FSP_DST} -> ${FSP_SRC}"
fi

# ============================================================
# Step 5: Patch Kconfig (must modify in-place)
# ============================================================

echo ""
echo "Step 5: Patching Kconfig..."

BRYA_KCONFIG="${COREBOOT_DIR}/src/mainboard/google/brya/Kconfig"
BRYA_KCONFIG_NAME="${COREBOOT_DIR}/src/mainboard/google/brya/Kconfig.name"

# Patch Kconfig
if grep -q "BOARD_GOOGLE_MBX222" "${BRYA_KCONFIG}" 2>/dev/null; then
	echo "  Kconfig already patched, skipping..."
else
	# Backup original
	cp -f "${BRYA_KCONFIG}" "${BRYA_KCONFIG}.mbx222_bak"
	register_cleanup "kconfig_patch:${BRYA_KCONFIG}"

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
	echo "  Kconfig patched."
fi

# Patch Kconfig.name
if grep -q "BOARD_GOOGLE_MBX222" "${BRYA_KCONFIG_NAME}" 2>/dev/null; then
	echo "  Kconfig.name already patched, skipping..."
else
	if [ ! -f "${BRYA_KCONFIG_NAME}.mbx222_bak" ]; then
		cp -f "${BRYA_KCONFIG_NAME}" "${BRYA_KCONFIG_NAME}.mbx222_bak"
		register_cleanup "kconfig_patch:${BRYA_KCONFIG_NAME}"
	fi

	sed -i '/^config BOARD_GOOGLE_NIVVIKS/i\
config BOARD_GOOGLE_MBX222\
\tbool "MBX222"\
' "${BRYA_KCONFIG_NAME}"
	echo "  Kconfig.name patched."
fi

# ============================================================
# Step 5b: Apply vboot patches (GCC 14+ compatibility)
# ============================================================
# GCC 14+ makes strchr() return const char* when input is const char*.
# Several vboot host tools pass const char* to strchr() but assign the
# result to char* and/or modify the string through the pointer.
# Fix: cast the input to char* so strchr returns char*.

VBOOT_DIR="${COREBOOT_DIR}/3rdparty/vboot"

# Check if any patching is needed (use host_key2.c as sentinel)
VBOOT_SENTINEL="${VBOOT_DIR}/host/lib/host_key2.c"
VBOOT_NEEDS_PATCH=0

if [ -f "${VBOOT_SENTINEL}" ]; then
	if grep -q 'char \*colon = strchr(key_info,' "${VBOOT_SENTINEL}" 2>/dev/null; then
		VBOOT_NEEDS_PATCH=1
	fi
fi

if [ "${VBOOT_NEEDS_PATCH}" = "1" ]; then
	echo ""
	echo "Step 5b: Patching vboot for GCC 14+ compatibility..."

	# --- futility/cmd_dump_fmap.c ---
	VBOOT_FILE="${VBOOT_DIR}/futility/cmd_dump_fmap.c"
	if [ -f "${VBOOT_FILE}" ] && [ ! -f "${VBOOT_FILE}.mbx222_bak" ]; then
		cp -f "${VBOOT_FILE}" "${VBOOT_FILE}.mbx222_bak"
	fi
	if [ -f "${VBOOT_FILE}" ]; then
		# const char *a = names[i] -> char *a = (char *)names[i]
		sed -i 's/const char \*a = names\[i\];/char *a = (char *)names[i];/' "${VBOOT_FILE}"
		# Undo any previous bad patch
		sed -i 's/const char \*f = strchr(a,/char *f = strchr(a,/' "${VBOOT_FILE}"
		register_cleanup "backup_restore:${VBOOT_FILE}"
	fi

	# --- host/lib/host_key2.c ---
	VBOOT_FILE="${VBOOT_DIR}/host/lib/host_key2.c"
	if [ -f "${VBOOT_FILE}" ] && [ ! -f "${VBOOT_FILE}.mbx222_bak" ]; then
		cp -f "${VBOOT_FILE}" "${VBOOT_FILE}.mbx222_bak"
	fi
	if [ -f "${VBOOT_FILE}" ]; then
		# char *colon = strchr(key_info, ':') -> cast key_info to char*
		sed -i 's/char \*colon = strchr(key_info,/char *colon = strchr((char *)key_info,/' "${VBOOT_FILE}"
		register_cleanup "backup_restore:${VBOOT_FILE}"
	fi

	# --- futility/updater.c ---
	VBOOT_FILE="${VBOOT_DIR}/futility/updater.c"
	if [ -f "${VBOOT_FILE}" ] && [ ! -f "${VBOOT_FILE}.mbx222_bak" ]; then
		cp -f "${VBOOT_FILE}" "${VBOOT_FILE}.mbx222_bak"
	fi
	if [ -f "${VBOOT_FILE}" ]; then
		# char *equ = strchr(token, '=') -> cast token to char*
		sed -i 's/char \*equ = strchr(token,/char *equ = strchr((char *)token,/' "${VBOOT_FILE}"
		register_cleanup "backup_restore:${VBOOT_FILE}"
	fi

	# --- futility/updater_manifest.c ---
	VBOOT_FILE="${VBOOT_DIR}/futility/updater_manifest.c"
	if [ -f "${VBOOT_FILE}" ] && [ ! -f "${VBOOT_FILE}.mbx222_bak" ]; then
		cp -f "${VBOOT_FILE}" "${VBOOT_FILE}.mbx222_bak"
	fi
	if [ -f "${VBOOT_FILE}" ]; then
		# char *dash = strchr(tag, '-') -> cast tag to char*
		sed -i 's/char \*dash = strchr(tag,/char *dash = strchr((char *)tag,/' "${VBOOT_FILE}"
		register_cleanup "backup_restore:${VBOOT_FILE}"
	fi

	# --- futility/cmd_load_fmap.c ---
	VBOOT_FILE="${VBOOT_DIR}/futility/cmd_load_fmap.c"
	if [ -f "${VBOOT_FILE}" ] && [ ! -f "${VBOOT_FILE}.mbx222_bak" ]; then
		cp -f "${VBOOT_FILE}" "${VBOOT_FILE}.mbx222_bak"
	fi
	if [ -f "${VBOOT_FILE}" ]; then
		# char *f = strchr(a, ':') in cmd_load_fmap.c - a is char* from argv, should be fine
		# but patch preventively for consistency
		sed -i 's/char \*f = strchr(a,/char *f = strchr((char *)a,/' "${VBOOT_FILE}"
		register_cleanup "backup_restore:${VBOOT_FILE}"
	fi

elif [ -f "${VBOOT_SENTINEL}" ]; then
	echo ""
	echo "Step 5b: vboot patches already applied, skipping..."
fi

# ============================================================
# Step 6: Configure and build
# ============================================================

echo ""
echo "Step 6: Configuring coreboot..."

cp -f "${PROJECT_DIR}/defconfig" "${COREBOOT_DIR}/.config"
register_cleanup "config_file:${COREBOOT_DIR}/.config"

cd "${COREBOOT_DIR}"
make olddefconfig 2>&1 | tail -5

echo ""
echo "Step 7: Building coreboot (${JOBS} jobs)..."
echo ""

make -j"${JOBS}" 2>&1

# ============================================================
# Step 8: Copy output
# ============================================================

BUILD_OUTPUT="${COREBOOT_DIR}/build/coreboot.rom"
if [ -f "${BUILD_OUTPUT}" ]; then
	OUTPUT_DIR="${PROJECT_DIR}/build"
	mkdir -p "${OUTPUT_DIR}"
	cp -v "${BUILD_OUTPUT}" "${OUTPUT_DIR}/coreboot_mbx222.rom"
	ROM_SIZE=$(stat -c%s "${BUILD_OUTPUT}" 2>/dev/null || stat -f%z "${BUILD_OUTPUT}" 2>/dev/null || echo "?")
	echo ""
	echo "=== Build successful! ==="
	echo "Output: ${OUTPUT_DIR}/coreboot_mbx222.rom (${ROM_SIZE} bytes)"
else
	echo ""
	echo "=== Build completed but coreboot.rom not found ==="
	echo "Check ${COREBOOT_DIR}/build/ for build artifacts."
fi

if [ "${NO_CLEAN}" = "1" ]; then
	echo ""
	echo "Note: --no-clean specified. Coreboot tree still has symlinks/patches."
	echo "To clean up later: ./scripts/build.sh clean"
	# Remove cleanup list so handler doesn't clean
	rm -f "${CLEANUP_LIST}"
fi

echo ""
echo "Done."