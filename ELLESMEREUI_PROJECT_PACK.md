# EllesmereUI 3.3.5 project pack — build 0.38

Saved checkpoint: 1 October 2026. Build 0.38 adds Friends 0.1 and Quest
Tracker 0.1, updates Options to 0.43 and Blizzard Skin to 0.7 for social-window
ownership handoff. Native social actions and Wrath WatchFrame behavior remain
in place, with EUI styling/settings, tracker movement and optional quest helpers.
Prior modules and Quickdraw hotkey capture remain included. Automated Lua 5.1,
native lifecycle, combat deferral, Options input and skin regressions pass.
Rendering and native interaction need in-game review.

This project pack contains the nineteen EllesmereUI addon source folders, all
twenty current release ZIPs, the current SHA-256 build manifest, handoff and
status documents, backport tools/tests and the local Lupa test dependency.
Two narrow ElvUI reference paths are included for existing test comparisons:
Libraries/LibAuraInfo-1.0 and Media/Textures/normTex2.tga. This is not an ElvUI
installation. Earlier build ZIPs and unrelated addons are not part of the pack.

To install, extract EllesmereUI-3.3.5-HUD-test-0.38.zip into the game's
Interface/AddOns directory. It contains exactly the nineteen addon folders.
Keep each folder's original name. The complete project archive is for source
backup and continued development; its documentation/tools are not game addons.
Player accounts and game SavedVariables are not included.

Use CODEX_HANDOFF_EllesmereUI_335_CURRENT.md to continue development.
ELLESMEREUI_335_CURRENT_BUILD.json identifies the exact current module versions
and release archives. Retail copies inside addon folders remain unloaded;
native 3.3.5 TOCs select the ported runtimes.

The tools require Python, Lupa (Lua 5.1) and Pillow for texture conversions.
The bundled .codex-tools dependency is the existing local Windows Lupa build;
on another Python/platform install compatible Lupa and Pillow. Test scripts
resolve the project root relative to their own location. Retail byte-integrity
comparisons use the original D:/World of Warcraft/_retail_/Interface/AddOns
reference paths. Supply those sources to repeat the original-source checks.

From the extracted project root, package current addon ZIPs with
`python backport-tools/package_unitframes.py`, verify/save their manifest with
`python backport-tools/save_current_checkpoint.py`, then create the full source
checkpoint with `python backport-tools/package_project.py`.
Historical update_*_checkpoint.py scripts record completed version transitions;
do not rerun them on the already-updated checkpoint. The scope_options_factory.py
script is also a completed one-time migration and must not be rerun.

The project ZIP is CRC-checked and compared byte for byte with every selected
source file. Its adjacent .sha256 file records the completed archive's hash.

connect_indicator_editor.py is a completed one-time migration; do not rerun.
