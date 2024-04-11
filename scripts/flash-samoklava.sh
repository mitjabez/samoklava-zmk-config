#!/bin/bash
set -e

MY_NAME=$(basename "$0")

MNT_DIR="/mnt/usb"
KEYB_ID=" Adafruit_nRF_UF2"
TMP_DIR=

error() {
  echo "Error: $*" >&2
}

die() {
  error "$*"
  exit 1
}

usage() {
  echo "$MY_NAME <firmware zip file>"
  echo "Flashes the ZMK firmware to the keyboard."
}

if [ $# -ne 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  exit 1
fi

cleanup() {
  [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"
}

detect_keyboard_volume() {
  volume=$(lsblk --output NAME,ID | grep "$KEYB_ID" | cut -f1 -d' ')
  if [ -z "$volume" ]; then
    return 1
  fi
  echo "/dev/$volume"
}

last_uf2() {
  side="$1"
  filter="*$side*.uf2"
  newest_file=$(find . -name "$filter")
  if [ -z "$newest_file" ]; then
    return 1
  fi
  echo "$newest_file"
}

prompt() {
  echo "$1"
  echo "Press ENTER to continue"
  read -r
}

flash() {
  side="$1"
  firmware=$(last_uf2 "$side")
  if [ -z "$firmware" ]; then
    error "Cannot find any file using matching '$full_filter'"
    exit 1
  fi

  echo "Preparing to flash $firmware:"
  prompt "Connect $side side of the keyboard and put it into flash mode"

  while : ; do
    volume=$(detect_keyboard_volume)
    if [ -z "$volume" ]; then
      prompt "Cannot detect keyboard. Try again."
    else
      break
    fi
  done

  echo "Mounting $volume"
  mount "$volume" "$MNT_DIR"
  echo "Copying $firmware ..."
  cp "$firmware" "$MNT_DIR"
  echo "Unmounting $volume"
  umount "$volume"
  echo "Done flashing $side"
  echo
}

zip_file="$1"
test -f "$zip_file" || die "File $zip_file doesn't exist"

trap cleanup EXIT
TMP_DIR=$(mktemp -d)
unzip "$zip_file" -d "$TMP_DIR"

cd "$TMP_DIR"
ls "$TMP_DIR"
flash "left"
flash "right"


