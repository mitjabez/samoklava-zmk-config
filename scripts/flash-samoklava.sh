#!/bin/bash
set -e

MY_NAME=$(basename "$0")

MNT_DIR="/mnt/usb"
KEYB_ID=" Adafruit_nRF_UF2"
ZIP_FILE=
SIDE="both"
TMP_DIR=

error() {
  echo "Error: $*" >&2
}

die() {
  error "$*"
  exit 1
}

usage() {
  cat <<EOF
$MY_NAME <firmware zip file>
Flashes the ZMK firmware to the keyboard.

Arguments:
  -s, --side <side>         Which side of the keyboard to flash. Can be left, right, both. (Default: $SIDE).
  -f, --file <file>         Zip file to flash. The zip file contains uf2 files for both sides of the keyboard.
  -h, --help                Display this help message.

EOF
}

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

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -s|--side) SIDE="$2"; shift 2 ;;
      -f|--file) ZIP_FILE="$2"; shift 2 ;;
      -h|--help) usage; exit 0; ;;
      *) echo "Unknown parameter: $1"; usage; exit 1; ;;
    esac
  done
}

main() {
  parse_args "$@"

  test -z "$ZIP_FILE" && die "Please provide the zip file. Check -h for more info."
  test -f "$ZIP_FILE" || die "File $ZIP_FILE doesn't exist"
  if [[ "$SIDE" != "left" ]] && [[ "$SIDE" != "right" ]] && [[ "$SIDE" != "both" ]]; then
    die "Invalid side. Can be left, right, both."
  fi

  trap cleanup EXIT
  TMP_DIR=$(mktemp -d)
  unzip "$ZIP_FILE" -d "$TMP_DIR"

  cd "$TMP_DIR"
  ls "$TMP_DIR"

  if [ "$SIDE" == "left" ] || [ "$SIDE" == "both" ]; then
    flash "left"
  fi
  if [ "$SIDE" == "right" ] || [ "$SIDE" == "both" ]; then
    flash "right"
  fi
}

main "$@"
