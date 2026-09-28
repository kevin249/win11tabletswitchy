# Win11 Tablet Switchy / Z13 Mode

A small Windows 11 tray utility for ROG Flow Z13 and other detachable/convertible PCs. It provides manual **PC / Tablet / Auto** switching when Windows 11 does not expose the old Windows 10 tablet-mode quick toggle.

![Z13 Mode icon](assets/Z13Mode.png)

## Features

- **Left-click tray icon:** quick toggle between forced PC mode and forced Tablet mode.
- **Right-click tray icon:** choose PC, Tablet, Auto, refresh Explorer, or exit.
- **Auto mode:** removes the `ConvertibilityEnabled` override so Windows / ASUS can resume hardware-driven behavior.
- Starts at user logon through an elevated interactive Scheduled Task.
- Custom tray and Start Menu icon.
- Windows PowerShell 5.1 compatible scripts (UTF-8 with BOM).

## Install

1. Download `dist/Z13Mode_v3.zip` and extract it.
2. Double-click `Install-Z13Mode.cmd`.
3. Accept the one-time UAC prompt.
4. The Z13 Mode icon appears in the notification area.

## Modes

| Mode | Registry state |
|---|---|
| PC | `ConvertibilityEnabled=0`, `ConvertibleSlateMode=1` |
| Tablet | `ConvertibilityEnabled=1`, `ConvertibleSlateMode=0` |
| Auto | removes `ConvertibilityEnabled`; Windows / OEM logic owns the mode again |

Registry path:

`HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl`

## Uninstall

Double-click `Uninstall-Z13Mode.cmd`.

## Files

- `Z13Mode.ps1` — tray application.
- `Z13Mode.ico` — selected program/tray icon.
- `Install-Z13Mode.ps1` / `.cmd` — installer.
- `Uninstall-Z13Mode.ps1` / `.cmd` — uninstaller.
- `assets/Z13Mode.png` — source artwork for the selected icon.
- `dist/Z13Mode_v3.zip` — ready-to-install package.

## Note

This utility writes machine-wide registry values and therefore runs with elevated privileges. Use Auto mode or uninstall the utility to return control to Windows / OEM mode detection.
