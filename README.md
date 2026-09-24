# ASUS TUF A16 (FA617NT) Keyboard Backlight Fix

Fixes the keyboard backlight on the ASUS TUF Gaming A16 FA617NT (and similar
TUF A16 models) after a cold boot, where the keyboard controller ignores EC
commands and the backlight stays dark even though the brightness value changes.

## Background

After a cold boot (e.g. following a power outage), the keyboard controller
(ITE5570) enters a mode where it ignores embedded-controller (EC) commands.
The WMI interface accepts brightness/RGB writes and reports success, but the
LEDs never light.

The EC's RGB-state command (`DEVS 0x00100057`) only takes effect when the
stale `MC60` register — left over from a previous RGB-mode write — is cleared
first. This script clears it and re-applies the power state, a static color,
and the brightness.

## Install

```bash
sudo install -m 755 fix-kbd-backlight.sh /usr/local/sbin/fix-kbd-backlight
sudo cp fix-kbd-backlight.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now fix-kbd-backlight.service
```

## Usage

Run manually at any time:

```bash
sudo /usr/local/sbin/fix-kbd-backlight
```

## Customizing brightness

Edit `fix-kbd-backlight.sh`:

- **Brightness:** `0x83` = on + level 3 (max). Levels are 0-3.

## Color support

The FA617NT keyboard is **white-only**. The EC exposes the TUF RGB protocol
(`kbd_rgb_mode`, shared firmware across the TUF family) and accepts color
commands, but the LED hardware is single-color white and ignores the R/G/B
values. Verified: red/green/blue commands reach the EC and are processed, but
the LEDs stay white.

## Files

- `fix-kbd-backlight.sh` — the fix script (run as root)
- `fix-kbd-backlight.service` — systemd oneshot service, runs at boot