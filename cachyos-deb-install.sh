#!/usr/bin/env bash

################################
# CachyOS DEB Kernel Installer #
#                              #
# Author: Jiab77               #
# Contributor: osevan          #
# Version: 0.0.0               #
################################

# Options
[[ -r $HOME/.debug ]] && set -o xtrace || set +o xtrace

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
NC="\033[0m"
NL="\n"
TAB="\t"

# Config
DEBUG_MODE=false
REMOVAL_MODE=false
BOOT_CHECK=false
PATCH_CONFIG=false

# Internals
BOOT_DEVICE=$(mount | grep -v /efi | grep /boot | cut -d" " -f1)
BOOT_MNT_OPTS=$(mount | grep -v /efi | grep /boot | cut -d" " -f6)
BOOT_MNT_OPTS="${BOOT_MNT_OPTS/\(/}" # Remove '(' character
BOOT_MNT_OPTS="${BOOT_MNT_OPTS/\)/}" # Remove ')' character
INITRAMFS_CONFIG="/etc/initramfs-tools/initramfs.conf"
MINIMAL_BOOT_SIZE=$((2*1024*1024*1024))
MINIMAL_BOOT_FREE_SIZE=$((1*1024*1024*1024))
SMALL_BOOT_SIZE=$((1*1024*1024*1024))

# Functions
# Imported 'die' method from the 'bash-funcs' project
function die() {
  echo -e "${NL}${RED}[ERROR] ${YELLOW}$*${NC}${NL}" >&2
  exit 255
}
function print_usage() {
  echo -e "${NL}Usage: $(basename "$0") [flags] <version> -- Install given custom kernel version"
  echo -e "${NL}Flags:"
  echo -e "  -h | --help${TAB}Print this message and exit"
  echo -e "  -c | --check${TAB}Check '/boot' partition size"
  echo -e "  -d | --debug${TAB}Enable debug mode"
  echo -e "  -f | --force${TAB}Patch 'initramfs' config file and install"
  echo -e "  -r | --remove${TAB}Remove given kernel version"
  echo
  exit
}
# Imported 'get_fs_size' method from the 'bash-funcs' project
function get_fs_size() {
  # Config
  local FS_NAME
  local HUMAN_SIZE=false
  local FREE_SIZE=false
  local FIELD_SIZE="FSSIZE"
  local OPT_ARGS="-b"

  # Usage
  if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo -e "${NL}Usage: get_fs_sze [flags] <mountpoint> -- Return size of given mountpoint."
    echo -e "${NL}Flags:"
    echo -e "  -h | --help${TAB}Print this message and exit"
    echo -e "  -f | --free${TAB}Print free size instead of full size"
    echo -e "  -H | --human-size${TAB}Print size in human friendly format"
    echo
    return
  fi

  # Flags
  if [[ $1 == "-f" || $1 == "--free-size" ]]; then
    FREE_SIZE=true ; shift
  fi
  if [[ $1 == "-H" || $1 == "--human-size" ]]; then
    HUMAN_SIZE=true ; shift
  fi

  # Checks
  [[ $# -eq 0 ]] && die "Missing argument: mountpoint"

  # Init
  FS_NAME="$1"

  # Main
  [[ $HUMAN_SIZE == true ]] && unset OPT_ARGS
  [[ $FREE_SIZE == true ]] && FIELD_SIZE="FSAVAIL"
  lsblk -npr $OPT_ARGS -x MOUNTPOINT -o $FIELD_SIZE,MOUNTPOINT | grep -m1 "$FS_NAME" | cut -d" " -f1
}
# Imported 'get_file_size' method from the 'bash-funcs' project
function get_file_size() {
  # Config
  local FILE_NAME
  local HUMAN_SIZE=false

  # Usage
  if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo -e "${NL}Usage: get_file_sze [flags] <file> -- Return size of given file."
    echo -e "${NL}Flags:"
    echo -e "  -h | --help${TAB}Print this message and exit"
    echo -e "  -H | --human-size${TAB}Print size in human friendly format"
    echo
    return
  fi

  # Flags
  if [[ $1 == "-H" || $1 == "--human-size" ]]; then
    HUMAN_SIZE=true ; shift
  fi

  # Checks
  [[ $# -eq 0 ]] && die "Missing argument: file"

  # Init
  FILE_NAME="$1"

  # Main
  if [[ $HUMAN_SIZE == true ]]; then
    die "Not implemented yet."
  else
    stat -Lc "%s" "$FILE_NAME"
  fi
}
function check_boot_size() {
  local CURRENT_BOOT_SIZE ; CURRENT_BOOT_SIZE=$(get_fs_size /boot)
  local CURRENT_BOOT_FREE_SIZE ; CURRENT_BOOT_FREE_SIZE=$(get_fs_size -f /boot)
  local CURRENT_BOOT_HUMAN_SIZE ; CURRENT_BOOT_HUMAN_SIZE=$(get_fs_size -H /boot)
  local CURRENT_BOOT_HUMAN_FREE_SIZE ; CURRENT_BOOT_HUMAN_FREE_SIZE=$(get_fs_size -f -H /boot)

  if [[ $CURRENT_BOOT_SIZE -ge $MINIMAL_BOOT_SIZE && $CURRENT_BOOT_FREE_SIZE -ge $MINIMAL_BOOT_FREE_SIZE ]]; then
    echo -e "${NL}${CYAN}Info: ${WHITE}That's ${GREEN}AWESOME${WHITE}!! You can easily install your custom kernel :)${NC}${NL}"
  elif [[ $CURRENT_BOOT_SIZE -lt $MINIMAL_BOOT_SIZE && $CURRENT_BOOT_FREE_SIZE -gt $MINIMAL_BOOT_FREE_SIZE ]]; then
    echo -e "${NL}${YELLOW}Warning: Your boot partition size is a bit small but it should work.${NC}${NL}"
  elif [[ $CURRENT_BOOT_FREE_SIZE -le $MINIMAL_BOOT_FREE_SIZE ]]; then
    echo -e "${NL}${RED}Error: ${YELLOW}Your boot partition size is too small to install your custom kernel.${NC}${NL}"
    echo -e "${WHITE}- Current ${PURPLE}/boot${WHITE} parition size: ${RED}${CURRENT_BOOT_HUMAN_SIZE}${WHITE} / available: ${RED}${CURRENT_BOOT_HUMAN_FREE_SIZE}${NC}"
    echo -e "${WHITE}- Recommended ${PURPLE}/boot${WHITE} parition size: ${GREEN}$((MINIMAL_BOOT_SIZE/1024/1024/1024))G${NC}"
    echo -e "${WHITE}- Minimal ${PURPLE}/boot${WHITE} parition size: ${YELLOW}>$((SMALL_BOOT_SIZE/1024/1024/1024))G${NC}"
    # echo -e "${NL}${BLUE}Note: ${WHITE}Try again with ${CYAN}--force${WHITE} to patch your '${PURPLE}initramfs${WHITE}' config file.${NC}${NL}"
    echo
    exit 1
  else
    die "Unable to detect boot partition size."
  fi
}
function patch_initramfs_config() {
  # Status
  echo -ne "${NL}${YELLOW}Patching '${PURPLE}initramfs${YELLOW}' config...${NC}"

  # Backup existing file
  if [[ ! -r "${INITRAMFS_CONFIG}.original" ]]; then
    cp "$INITRAMFS_CONFIG" "${INITRAMFS_CONFIG}.original" || die "Failed to backup '${PURPLE}initramfs${YELLOW}' file."
  fi

  # Check config patch
  if [[ $(grep -c "MODULES=dep" "$INITRAMFS_CONFIG") -eq 1 ]]; then
    echo -e " ${YELLOW}already patched${NC}${NL}"
  else
    # Enable 'DEP' module
    sed -e 's|MODULES=most|MODULES=dep|' -i "$INITRAMFS_CONFIG"
    RET_CODE_PATCH=$?

    # Check status
    if [[ $RET_CODE_PATCH -eq 0 && $(grep -c "MODULES=dep" "$INITRAMFS_CONFIG") -eq 1 ]]; then
      echo -e " ${GREEN}success${NC}${NL}"
    else
      die "Failed to patch '${PURPLE}initramfs${YELLOW}' config file."
    fi
  fi
}
function install_custom_kernel() {
  # Config
  local CREATED_DEB_FILES
  local OPT_ARGS

  # Init
  CREATED_DEB_FILES=$(find linux-$KERNEL_VERSION -type f -iname "*.deb" 2>/dev/null | wc -l)

  # Checks
  [[ ! -d linux-$KERNEL_VERSION ]] && die "Unable to find 'linux-$KERNEL_VERSION' folder."
  [[ $CREATED_DEB_FILES -eq 0 ]] && die "Unable to find created DEB files in 'linux-$KERNEL_VERSION' folder."

  # Status
  echo -e "${NL}${WHITE}Installing kernel [${PURPLE}${KERNEL_VERSION}${WHITE}]...${NC}${NL}"

  # Install DEB packages
  dpkg -i linux-$KERNEL_VERSION/*.deb || die "Unable to install given kernel."

  # Patch 'initramfs' config file
  [[ $PATCH_CONFIG == true ]] && patch_initramfs_config

  # Generate new 'initramfs' file
  [[ $DEBUG_MODE == true ]] && OPT_ARGS="-v"
  update-initramfs $OPT_ARGS -c -k $KERNEL_VERSION || die "Failed to create new 'initramfs' file."

  # Update 'grub' config
  update-grub || die "Failed to update 'grub' config."
}
function remove_user_kernel() {
  # Status
  echo -e "${NL}${WHITE}Removing kernel [${PURPLE}${KERNEL_VERSION}${WHITE}]...${NC}${NL}"

  # Main
  apt remove --purge linux-*$KERNEL_VERSION*
  RET_CODE_REMOVAL=$?
  if [[ $RET_CODE_REMOVAL -eq 0 ]]; then
    echo -e "${NL}${WHITE}Finished.${NC}${NL}"
  else
    echo -e "${NL}${RED}Failed.${NC}${NL}"
  fi
  exit $RET_CODE_REMOVAL
}
function init_install() {
  if [[ $REMOVAL_MODE == true ]]; then
    remove_user_kernel
  elif [[ $BOOT_CHECK == true || $PATCH_CONFIG == false ]]; then
    check_boot_size
  else
    install_custom_kernel
  fi
}

# Flags
[[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]] && print_usage
if [[ $1 == "-c" || $1 == "--check" ]]; then
  BOOT_CHECK=true ; shift
fi
if [[ $1 == "-d" || $1 == "--debug" ]]; then
  DEBUG_MODE=true ; shift
fi
if [[ $1 == "-f" || $1 == "--force" ]]; then
  PATCH_CONFIG=true ; shift
fi
if [[ $1 == "-r" || $1 == "--remove" ]]; then
  REMOVAL_MODE=true ; shift
fi

# Checks
[[ ! $BOOT_CHECK == true && $# -eq 0 ]] && die "Missing 'version' argument."
[[ $(id -u) -ne 0 ]] && die "You must run this script as root or with 'sudo'."

# Init
KERNEL_VERSION="$1"

# Main
init_install
