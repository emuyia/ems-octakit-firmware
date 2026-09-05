# MANDATORY READING

- Please backup your projects before updating. Avoid working on anything critical.
- Development builds are available on my website, [here](https://www.junes.website/goodies/octakit). Alternatively this repo can be downloaded and used to patch firmware locally.

No Octatrack firmware is hosted or distributed here or on my website. This repo has been designed not to contain any official code or assets. You provide your own official OS 1.40C.

Current changes:

- 64 Parts (4 per Bank) have been replaced with 256 Kits per Project (untethered from Banks).
- Old Projects that contain Parts should be automatically migrated to the first 64 Kit slots, with patterns assigned accordingly. (Downgrading firmware back to stock may result in losing Kit data).
- OS version number changed to date based versioning (e.g. 26512), and splash animation removed.

UX changes:

- On MKII, PART opens LOAD KIT, FUNC+PART opens SAVE KIT
- On MKI, FUNC+MIDI opens LOAD KIT, then FUNC+BANK opens SAVE KIT
- FUNC+CUE reloads the assigned Kit
- Saving a Kit prompts a name (max 7 chars). FUNC+PART+YES (MKI: FUNC+BANK+YES) skips the prompt
- In the LOAD/SAVE KIT menus, you can copy/paste/clear/undo Kit slots
- Unassigned Kits are marked with an asterisk

# BUG REPORTS

If you find a bug or a crash, please [open an issue](../../issues/new?template=bug_report.md) for it. Make sure to mention which firmware version you are using, and what the crash message says, if there is one. It would also be great to provide steps to reproduce the issue, if known.

If you'd like to make a suggestion, feel free to [open a discussion](../../discussions/new?category=suggestions).

# FUTURE OF OCTAKIT

Currently this Octakit firmware mod exists because I prefer the silver boxes' (MnM & MD's) Kit approach over Parts - it better fits my way of working.

I don't have specific plans beyond that currently, however there is a decent chance this will change as I continue to use the OT, and Kits become more stable.

There is also a lot of other Octatrack firmware modification being done in the community. You're free to use this repo as a submodule to combine with other efforts.
