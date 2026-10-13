# HP LaserJet 1020 macOS Legacy Driver Setup

Unofficial, experimental compatibility scripts for creating a standard macOS CUPS queue for compatible HP LaserJet 1020-family printers.

**Known proof of concept:** HP LaserJet 1020 over USB on a MacBook Air M4 running macOS 27. Other combinations are unverified. CUPS has deprecated PPD-based drivers; future macOS releases may remove support.

## Driver package and licensing

This repository does not redistribute Apple's/HP's driver package or extracted files. Obtain `HewlettPackardPrinterDrivers.dmg` from a legitimate source and place it at `~/Downloads/HewlettPackardPrinterDrivers.dmg`. Review its applicable terms. The MIT license here applies only to original scripts and documentation, not third-party driver components.

## Requirements

- macOS, administrator access, and the original driver DMG in Downloads.
- Printer connected and powered on over USB.
- Apple silicon may require Apple's Rosetta for the legacy Intel filters.

## Install

Review `install.sh` before running it. From this repository directory:

```bash
./install.sh --check
./install.sh --dry-run
./install.sh
```

The script asks for administrator authorization when needed, refuses to overwrite existing target driver files, validates the PPD, detects the USB URI, and creates a queue named `HP_LaserJet_1020`.

Verify and test:

```bash
lpstat -p HP_LaserJet_1020 -l
printf 'HP LaserJet 1020 test print\n' | lp -d HP_LaserJet_1020
```

You can then print using **Command-P** and select `HP_LaserJet_1020`.

## Uninstall

```bash
./uninstall.sh
```

The uninstaller requires a marker created by this project and removes only the queue and exact bundle/PPD paths this project installs. It does not remove Rosetta or unrelated software.

## Troubleshooting

- If no USB URI is detected, check the cable, hub, power, and `lpinfo -v`. Do not reuse another Mac's USB URI; serial numbers can differ.
- If `cupstestppd` fails, stop and report the exact error. Do not bypass validation.
- If a queue exists but nothing prints, inspect `lpstat -o HP_LaserJet_1020` and CUPS logs before resubmitting jobs.
- Redact USB serial numbers and personal data from logs before posting issues.

## Compatibility matrix

| Environment | Status |
|---|---|
| MacBook Air M4, macOS 27, HP LaserJet 1020 over USB | Proof of concept: test page printed |
| Other Apple silicon Macs | Not verified |
| Intel Macs | Not verified |
| Other 1020-family models | Not verified |
| Future macOS/CUPS versions | Not verified |

This is not an official HP or Apple project. Read the scripts before running them; they modify `/Library/Printers/` and create a CUPS queue.
