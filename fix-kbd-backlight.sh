#!/bin/bash
# Fix ASUS TUF A16 (FA617NT) keyboard backlight after cold boot.
#
# After a cold boot (e.g. following a power outage), the keyboard controller
# ignores EC commands. The EC's RGB-state command (DEVS 0x00100057) only takes
# effect when the stale MC60 register (left over from a previous mode write) is
# cleared first. This script clears it and re-applies the power state, a static
# color, and the brightness.
#
# Requires root (writes to /dev/mem and the asus-nb-wmi debugfs interface).

set -e

# 1. Clear the stale MC60 register (EC command arg2) via /dev/mem.
python3 - <<'EOF'
import struct
with open('/dev/mem', 'r+b', buffering=0) as f:
    f.seek(0xFE700C60)
    f.write(struct.pack('<I', 0))
EOF

# 2. Send the WMI commands through the asus-nb-wmi debugfs interface.
DBG=/sys/kernel/debug/asus-nb-wmi
if [ ! -d "$DBG" ]; then
  echo "asus-nb-wmi debugfs not found at $DBG" >&2
  exit 1
fi

cd "$DBG"

# Enable keyboard power states (cmd=1, boot/awake/sleep/keyboard all on).
echo 0x53564544 > method_id   # DEVS
echo 0x00100057 > dev_id      # TUF_RGB_STATE
echo 0xAA04BD > ctrl_param    # 0xbd | (BIT(2)<<8) | (0xAA<<16)
cat call > /dev/null

# Static white mode (cmd=0xb3, mode=0, R=255, G=255, B=255, speed=slow).
echo 0x53564544 > method_id   # DEVS
echo 0x0010005A > dev_id      # TUF_RGB_MODE2
echo 0xFFF000B3 > ctrl_param  # 0xb3 | (0<<8) | (255<<16) | (255<<24)
cat call > /dev/null

# Brightness level 3 (on + max).
echo 0x53564544 > method_id   # DEVS
echo 0x00050021 > dev_id      # KBD_BACKLIGHT
echo 0x83 > ctrl_param        # 0x80 (on) | 3
cat call > /dev/null

echo "keyboard backlight fix applied"