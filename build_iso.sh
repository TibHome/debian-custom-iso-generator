#!/bin/bash

#################################################
# Default variables
#################################################

DEBIAN_VERSION="${DEBIAN_VERSION:-12.10.0}"

SIZE_G_SWAP="${SIZE_G_SWAP:-2}"
SIZE_G_VAR="${SIZE_G_VAR:-5}"
SIZE_G_OPT="${SIZE_G_OPT:-5}"
SIZE_G_TMP="${SIZE_G_TMP:-10}"

USER_NAME="${USER_NAME:-"debian"}"
USER_PASS="${USER_PASS:-"password"}"

ROOT_PASS="${ROOT_PASS:-"password"}"

TIME_ZONE="${TIME_ZONE:-"Europe/Paris"}"

KEYBOARD_LANG="${KEYBOARD_LANG:-"fr"}"

BOOT_DISK="${BOOT_DISK:-"/dev/sda"}"

#################################################
# Local variables
#################################################
THROW_ERROR="false"

LOCAL_SIZE_G_SWAP=$((SIZE_G_SWAP * 1024))
LOCAL_SIZE_G_VAR=$((SIZE_G_VAR * 1024))
LOCAL_SIZE_G_OPT=$((SIZE_G_OPT * 1024))
LOCAL_SIZE_G_TMP=$((SIZE_G_TMP * 1024))

KEYBOARD_MAJ=$(echo "$KEYBOARD_LANG" | tr '[:lower:]' '[:upper:]')
DOWNLOAD_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-${DEBIAN_VERSION}-amd64-DVD-1.iso"
ISO_ORIGINAL_FILE="/original/debian-original-${DEBIAN_VERSION}.iso"
ISO_CUSTOM_FILE="/output/debian-${DEBIAN_VERSION}-autoinstall.iso"

LOCAL_USER_PASS_HASH=""
LOCAL_ROOT_PASS_HASH=""

#################################################
# Functions
#################################################

log_title() {
    printf "%s\n" ""
    printf "%s\n" "======================================================"
    printf "%s\n" " $*"
    printf "%s\n" "======================================================"
}
log() {
    printf "%s\n" "$*"
}

get_original_iso() {
  if [ -f "${ISO_ORIGINAL_FILE}" ]; then
    log "File ${ISO_ORIGINAL_FILE} already exists"
  else
    log "File ${ISO_ORIGINAL_FILE} does not exist. Downloading it !"
    mkdir -p /original
    wget --quiet --no-check-certificate ${DOWNLOAD_URL} -O ${ISO_ORIGINAL_FILE} &
    local wget_pid=$!
    local start_time=$(date +%s)
    while kill -0 $wget_pid 2>/dev/null; do
      local now=$(date +%s)
      local elapsed=$(( now - start_time ))
      local minutes=$(( (elapsed % 3600) / 60 ))
      local seconds=$(( elapsed % 60 ))
      local elapsed_formatted=$(printf "%02dm%02ds" $minutes $seconds)
      log "Downloading in progress since $elapsed_formatted"
      sleep 5
    done
    wait $wget_pid
    local status=$?
    if [ $status -ne 0 ]; then
      log "ERROR : download failed"
      exit 1
    fi
    log "File ${ISO_ORIGINAL_FILE} downloaded"
  fi
}

define_root_pass_hash() {
  LOCAL_ROOT_PASS_HASH=$(mkpasswd -m sha-512 "${ROOT_PASS}")
  log "Hash root password"
}

define_user_pass_hash() {
  LOCAL_USER_PASS_HASH=$(mkpasswd -m sha-512 "${USER_PASS}")
  log "Hash user password"
}

generate_custom_config() {
  log "Extract original ISO"
  mkdir -p iso-custom
  bsdtar -C iso-custom -xf ${ISO_ORIGINAL_FILE}

  log "Define preseed config"
  mv custom_scripts iso-custom/
  mv preseed.cfg iso-custom/
  sed -i "s#USER_NAME#${USER_NAME}#g" iso-custom/preseed.cfg
  sed -i "s#USER_PASS_HASH#${LOCAL_USER_PASS_HASH}#g" iso-custom/preseed.cfg
  sed -i "s#ROOT_PASS_HASH#${LOCAL_ROOT_PASS_HASH}#g" iso-custom/preseed.cfg
  sed -i "s#TIME_ZONE#${TIME_ZONE}#g" iso-custom/preseed.cfg
  sed -i "s#KEYBOARD_LANG#${KEYBOARD_LANG}#g" iso-custom/preseed.cfg
  sed -i "s#KEYBOARD_MAJ#${KEYBOARD_MAJ}#g" iso-custom/preseed.cfg
  sed -i "s#BOOT_DISK#${BOOT_DISK}#g" iso-custom/preseed.cfg
  sed -i "s#LOCAL_SIZE_G_SWAP#${LOCAL_SIZE_G_SWAP}#g" iso-custom/preseed.cfg
  sed -i "s#LOCAL_SIZE_G_VAR#${LOCAL_SIZE_G_VAR}#g" iso-custom/preseed.cfg
  sed -i "s#LOCAL_SIZE_G_OPT#${LOCAL_SIZE_G_OPT}#g" iso-custom/preseed.cfg
  sed -i "s#LOCAL_SIZE_G_TMP#${LOCAL_SIZE_G_TMP}#g" iso-custom/preseed.cfg

  cat > iso-custom/isolinux/txt.cfg << 'EOF'
label auto
  menu label ^Auto Install Debian
  kernel /install.amd/vmlinuz
  append auto=true priority=critical file=/cdrom/preseed.cfg initrd=/install.amd/initrd.gz --- quiet
EOF

  log "Include isohdpfx binary"
  cp /usr/lib/ISOLINUX/isohdpfx.bin iso-custom/isolinux/
}

generate_iso_file() {
  VOLUME_ID=$(isoinfo -d -i ${ISO_ORIGINAL_FILE} | grep "Volume id" | sed s#Volume\ id\:\ ##g)
  cd iso-custom
  mkdir -p /output
  xorriso -as mkisofs \
    -r -V "${VOLUME_ID}" \
    -o ${ISO_CUSTOM_FILE} \
    -J -joliet-long \
    -isohybrid-mbr isolinux/isohdpfx.bin \
    -partition_offset 16 \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    .
  local status=$?
  if [ $status -ne 0 ]; then
    log "ERROR : ISO generation failed"
    exit 1
  fi
  log "${ISO_CUSTOM_FILE} generated"
}

log_title "Get original Debian ISO"
get_original_iso

log_title "Hash password"
define_root_pass_hash
define_user_pass_hash

log_title "Generate custom configuration"
generate_custom_config

log_title "Generate final ISO file"
generate_iso_file

cat << EOF

"======================================================"
 YOUR CUSTOM IMAGE IS READY
"======================================================"

Disk configuration:
  swap                 -->  ${SIZE_G_SWAP}G
  /var                 -->  ${SIZE_G_VAR}G
  /tmp                 -->  ${SIZE_G_TMP}G
  /opt                 -->  ${SIZE_G_OPT}G
  /                    -->  remaining available space
  boot disk            -->  ${BOOT_DISK}

User configuration:
  root password        -->  ${ROOT_PASS}
  user account         -->  ${USER_NAME}
  user password        -->  ${USER_PASS}

Other configuration:
  debian version       -->  ${DEBIAN_VERSION}
  time zone            -->  ${TIME_ZONE}
  keyboard languague   -->  ${KEYBOARD_LANG}

============================================================
 SECURITY REMINDER
============================================================

Please remember to:
  - Change the ROOT password on first boot
  - Change the default USER password as well

This is essential to secure your system.

Enjoy!

EOF