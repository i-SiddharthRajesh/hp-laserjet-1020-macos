# HP LaserJet 1020 on macOS

I have an HP LaserJet 1020 Plus, and getting it to print from a modern Mac was far more difficult than it should have been. The printer was detected over USB, but macOS wouldn't offer the right driver, and the usual options didn't get me anywhere.

After a lot of troubleshooting, I managed to get it printing again using Apple's legacy HP printer driver files and a manually configured CUPS printer queue.

This repository documents that solution and aims to make it easier for other people to try it on their own Macs.

The goal is simple: **keep a perfectly usable old printer working instead of replacing it just because its software is outdated.**

## What this project does

- Installs the required legacy HP printer driver files from a driver package you provide.
- Applies a small compatibility fix to the printer's PPD file.
- Detects the connected printer's USB address.
- Configures a printer queue through macOS's built-in CUPS printing system.
- Includes an uninstaller to remove the files installed by this project.

Once the printer is configured, you should be able to print normally through macOS using **`Cmd + P`**. No separate printing application should be necessary.

## Before you start

A few things worth knowing before running anything:

> [!WARNING]
> This project is community-made and is not affiliated with or endorsed by HP or Apple. It modifies system printer files and configures a CUPS printer queue. Read the scripts before running them, and make sure you understand what they do.

- This solution was tested with an **HP LaserJet 1020 Plus** connected over USB to a **MacBook Air M4 running macOS 27 (Golden Gate)**.
- Other Macs, macOS versions, USB adapters, hubs, and printer variants may behave differently.
- The installation script has not yet been fully tested on a clean second Mac. Treat it as experimental until that testing is complete.
- You will need administrator access because the driver files are installed in system-wide printer directories.
- You need a compatible legacy HP printer driver package. This repository does not include HP's proprietary driver binaries.

## What you'll need

- An HP LaserJet 1020 or 1020 Plus.
- A Mac running macOS.
- A USB connection between the Mac and printer. If your Mac only has USB-C ports, you may need a suitable adapter or hub.
- A compatible legacy HP printer driver package.
- The files in this repository.

## Installation

### 1. Download the repository

On GitHub, click **Code → Download ZIP**, then extract the downloaded archive.

You can also clone the repository:

```bash
git clone <your-repository-url>
cd <your-repository-folder>
```

Replace the URL and folder name with the ones for your repository.

### 2. Get the legacy HP driver package

You need the original compatible HP printer driver package containing the `hplaserjetzjs.bundle` driver and the HP LaserJet 1022 PPD file.

The PPD is for the related LaserJet 1022 model; it was the legacy driver configuration used in my working setup for the LaserJet 1020 Plus.

**Please don't download random driver files from untrusted websites.** Use a legitimate driver package and check its source before proceeding.

### 3. Read the installer before running it

Open `install.sh` in a text editor and review what it does. Check the script's expected driver-package location and any options documented in the script.

The installer is still experimental, so don't assume it will work on every Mac just because it worked on mine.

### 4. Run the installer

Follow the instructions and command documented in `install.sh` and provide the driver package in the location the script expects.

The script may request your macOS administrator password to install the driver and configure the printer. That is expected for system-wide changes, but **never enter your password into a script you haven't reviewed**.

If the installer reports an error, stop and read the message instead of repeatedly running it.

### 5. Check the printer

After a successful installation:

1. Open **System Settings → Printers & Scanners**.
2. Check whether the HP LaserJet printer queue appears.
3. Try printing a short test document.
4. If the test works, open a document and print with `Cmd + P`.

If the printer appears in the settings but doesn't physically print, the installation is not fully successful yet.

## How I got it working

For anyone interested in the technical details, the working setup involved:

- Apple's legacy `hplaserjetzjs.bundle` driver.
- The HP LaserJet 1022 PPD, with two PPD directives corrected for compatibility.
- The driver's `rasterToHPZJS` and `commandToHPZJS` filters.
- A CUPS printer queue configured to use the printer's USB URI.

The important part was that **detecting the printer over USB was not the same as having a working print pipeline**. The correct driver files, permissions, PPD configuration, and printer queue all mattered.

I verified the final setup by sending a test print through CUPS and confirming that the printer physically printed it.

## Troubleshooting

### The printer doesn't appear in Printers & Scanners

First, check the USB connection. A printer can be detected by macOS at the USB level without having a usable printer queue.

Make sure the printer is powered on, the cable is connected securely, and any USB adapter or hub is working properly.

### The printer appears, but nothing comes out

Check the print queue for paused or failed jobs. A successful submission message alone doesn't guarantee that the printer physically printed the page.

If you're troubleshooting the installation, check the CUPS queue and the reported error before changing driver files.

### The installer reports a missing driver or PPD

Check that you supplied the expected legacy driver package and that it contains the required files. Don't substitute unrelated PPD files just to get past the error.

### The printer worked before, but stopped after a macOS update

Legacy printer drivers can break when Apple changes macOS or its printing system. This project has only been tested in the configuration described above, so compatibility with later updates is not guaranteed.

### I'm getting a different error

Please open a GitHub issue with:

- Your Mac model and macOS version.
- The exact printer model.
- Whether the printer is connected directly or through a hub.
- The command you ran and the complete error message.
- Whether the printer appears in Printers & Scanners.

Remove serial numbers and other identifying information from logs before posting them publicly.

## Uninstalling

This repository includes `uninstall.sh` to remove the driver files and printer configuration installed by the project.

**Read the script before running it.** Make sure it targets only the files and printer queue created by this project. It should not be used as a general-purpose printer cleanup tool.

## Frequently asked questions

**Q: Do I need to buy a new printer?**

A: Not necessarily. My LaserJet 1020 Plus printed successfully with this configuration. Your results may vary depending on your hardware and macOS version.

**Q: Do I need a separate printing application?**

A: No separate printing application was needed in my tested setup. Once configured, I could print through the normal macOS print dialog.

**Q: Does this work on every version of macOS?**

A: No such guarantee. Legacy printer drivers are increasingly difficult to use on modern macOS, and this project has only been tested in the environment documented above.

**Q: Why does the project use a LaserJet 1022 PPD for a LaserJet 1020 Plus?**

A: The related 1022 PPD was part of the working configuration I tested. That doesn't mean every LaserJet variant will behave identically.

**Q: Is this an official HP tool?**

A: No. This is an independent community project built around legacy driver files.

**Q: Why aren't the HP driver binaries included here?**

A: The original driver files are proprietary. This repository provides the installation workflow and compatibility adjustments rather than redistributing those files without permission.

**Q: Can I report a bug or contribute a fix?**

A: Yes! Open an issue with the details listed in the troubleshooting section, or submit a pull request with a clear explanation of what you changed and how you tested it.

## A note about contributions

If this project helps you get your printer working, consider sharing your Mac model, macOS version, and printer variant in a discussion or issue. A successful test on another machine would help establish how broadly this solution works.

Please don't submit changes that are described as working unless they've actually been tested. Small, verified fixes are much more useful than untested changes that might make the installation harder for someone else.

## License

See [`LICENSE`](LICENSE) for the license covering this repository's own files.

The original HP and Apple driver components remain subject to their respective licensing terms. The repository's license does not grant permission to redistribute those components.

---

**If you're here because macOS gave up on your old LaserJet, I hope this saves you some time.** I built this project because I wanted to keep using a printer that still worked perfectly well. If you manage to get yours running too, sharing your results will help the next person.
