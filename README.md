# Samoklava ZMK config

ZMK config for my self-built [open source keyboard](https://github.com/soundmonster/samoklava). It uses a nice!nano
microcontroller.

## How to flash

- Push the change
- Go to GitHub actions and download the firmware zip file. No need to unzip.
- Flash using the flash utility.

  ```bash
  sudo  ./scripts/flash-samoklava.sh
  ```

  > ℹ️  To put the keyboard into flash mode double press the reset button. When flashing the right keyboard connect it
  using USB! Connection via TRRS cable is not enough.

