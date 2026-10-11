# EllesmereUI 3.3.5a — Handoff — 2026-10-06

## Personal-use side project: NaowhUI_EUI (not part of EUI)

- `NaowhUI_EUI/` is Alex's personal 3.3.5 port of Naowh's EUI companion (Retail 1.1.7). It stays out of git through `.git/info/exclude` (with `validate_naowhui_eui.py`, `prepare_naowhui_media.py`, `scan_naowhui_qol_keys.py`, `scan_naowhui_eui_api.py`), and `zip_addons.ps1` only packs `EllesmereUI*` folders. Never commit, zip, or list it in patch notes or READMEs. The validator prints SKIP when the folder is absent. It needed no EllesmereUI changes.
- Same rules for `NaowhUI/` + `NaowhUI_Data/` (Retail installer 20261007.02, `/nui install`; excluded with `validate_naowhui.py`, `scan_naowhui_data_strings.py`). Private Ace3 subset in `NaowhUI/Compat_335.lua` (no LibStub libs). Steps: EllesmereUI (Retail strings through `ImportProfileInteractive`) and TBC WeakAuras from LoD `NaowhUI_Data` (only with a WeakAuras that has LibSerialize). Dropped: BigWigs, Details, ElvUI, Plater, MRT, EXBoss, NSRT, Naowh addons, Edit Mode, Cooldown Manager layouts.

## Latest (2026-10-10) — performance pass: Nameplates 0.20, Blizz UI Enhanced 0.34

- BlizzardSkin: `OnEvent` drops UNIT_* from other units (UNIT_INVENTORY_CHANGED also from the inspected unit while InspectFrame shows); stat/aura events only set `dirty` while CharacterFrame shows. Tooltip OnShow/OnTooltipSet* call `RefreshTooltip` (Paint of that tooltip only, no `dirty`); tooltip `SetBackdrop` only when `s.tooltipEdge` changes (cleared in `Restore`).
- Nameplates: UNIT_AURA only flags plates bound to target/mouseover/focus; player UNIT_AURA clears `ns.tankState` (`IsTank` cache, names resolved once). Other events set `ns.updatePending` (one `ns.Update` per frame); interrupts and roster stay immediate (validator expects it). Plate OnShow runs `ns.UpdatePlate(s)` (BindUnits + ResolveFriendlyClasses + paint of that plate). Paint caches root scale/alpha and aura icon/stack/time; layout/aura keys are numbers.
- Audit backlog (not done, ranked): Damage Meters `ns.Refresh()` after every CLEU (`EUI_DamageMeters_335.lua` ~311; add `return` after `ns.Parse`) and `GroupInCombat` per CLEU; Unit Frames `PLAYER_MOUNT_DISPLAY_CHANGED`→UNIT_AURA alias on `_visFrame` with no unit filter, uncoalesced `C_Timer.After(0)`; UF event wrapper allocates before the unit check (`EUI_UnitFrames_335.lua` ~399); Raid Frames 0.2 s full `UpdateAll`, per-unit-event button scan + full repaint, `Apply` on every roster event; Cooldown Manager full aura scan + `ns.Bars()` normalisation per event, hunter recompile on BAG_UPDATE; Chat `Remember` on ChatFrame2 with `table.remove(…,1)`; Bags capture on most events + 5 s capture; Quest Tracker `WatchFrame_Update` hook → full Apply; Minimap text on player UNIT_AURA (and `SetMapToCurrentZone` with coords); Friends 0.5 s Apply when `ns.panel` is nil; ActionBars shaped-icon strip mirroring without change checks.

## Latest (2026-10-10) — locale catch-up (no bump)

- `backport-tools/find_new_locale_keys.py` (read only) lists UI keys `export_ptbr_keys.py` would export that are not in `ptbr_work/keys.tsv`, plus stale keys. Never rerun `export_ptbr_keys.py` itself: it renumbers keys.tsv and breaks every `out_*.tsv`. `append_locale_keys.py [--check]` appends new keys with fresh ids and writes the next `ptbr_work/in_NN.tsv` and `locale_work/<code>/in_NN.tsv`; translate into the matching `out_NN.tsv`, then run `build_ptbr_catalog.py` and `build_locale_additions.py`.
- Patch notes: every `_WHATSNEW_PATCHES` eyebrow/title/desc/text/module already goes through `EllesmereUI.L`. `patch_note_strings.py` lists them; `append_locale_keys.py --patch-notes` adds the missing ones (ids 5479-5827: ptBR in_17-18, deDE 06-07, frFR 07-08, ruRU 09-10, koKR/zhCN/zhTW 05-06, esES 12-13). New patch-note items stay English until the next `--patch-notes` pass.
- This pass: ids 5259-5478 (ptBR in_16/out_16, deDE 05, frFR 06, ruRU 08, koKR/zhCN/zhTW 04, esES 11). "Português (Brasil)" is skipped on purpose. 38 stale keys stay in the catalogs (harmless).
- World markers are server items 131077-131084 (Quickdraw `ns.worldMarkerItems`, Raid Tools `WORLD_ITEMS`, raid target order); the server's Raid tab "Reset Markers" button is `rmarkbtn` (`/click rmarkbtn`: Quickdraw `clearworldmarkers`, Raid Tools Shift + Left Click on the clear icon).

## Latest (2026-10-10) — Quickdraw 0.4: Assign to Spec, nest geometry, selection color

- Per-palette `specs` ({[talentGroup]=true}, nil = both) gates the driver `enabled` attribute, the override bindings and nesting (`ns.PaletteActive`, `GetActiveTalentGroup`; `ACTIVE_TALENT_GROUP_CHANGED` already re-applies). `keyShare` = owner index: `ns.ShareOwner` only honours it when both palettes name disjoint groups; `UpdateBindings` sends the owner's keys to the sharer while the owner does not load. `RemovePalette` clears both.
- New palette defaults `nestBand` 40 / `nestScale` .8 (ring: first child radius = radius + size/2 + band + child/2; grid/fan lanes start `band` past the block edge), `invertScroll` (view attribute read by the wheel snippet), `selectColorCustom` / `selectColor` / `useClassColor` via `ns.SelectColor(cfg)` (class outranks custom, accent default).
- Not ported: fan coverflow (Visible Icons, Select Action with Mouse), Arc Nest Shape / Grid Nest Style Halo, Toggle World Markers and placed-marker pips (no 3.3.5 API for active ground markers).

## Latest (2026-10-10) — QoL Raid Tools in the Retail layout (QoL 0.19, no extra bump)

- New `EllesmereUIQoL/EUI_QoL_335_RaidTools.lua` (TOC after Panels) replaces the single `EUI335QoLRaidTools` window. Retail's secure state machine: shells `EUI335QoLRaidTools` / `EUI335QoLRaidToolsMarkers` (SecureHandlerStateTemplate, `apply` + `_onstate-euirt_vis`), icon `EUI335QoLRaidToolsIcon` and key target `EUI335QoLRaidToolsToggle` (SecureHandlerClickTemplate, `AnyUp`), refs via `SecureHandlerSetFrameRef`. `ApplyVisibility` only resets attributes when its signature changes, since QoL re-applies on every ADDON_LOADED.
- Settings `raidTools.mode` (unset = legacy enabled/groupOnly via `ns.RaidToolsMode`), `showAs`, `collapsedIcon`, `growDir`, `toggleKey`, `compactWidth/Height`, `pullTimes` {3,5,10}, `showConvert`, `showDisband`; scale stays percent. Pulls stay in Panels: `ns.StartPull(secs)`, `ns.StopPull()` (sync 0 with no local pull). Markers are plain buttons (SetRaidTarget is unprotected); target markers only.
- Unlock keys `EUI_RaidTools` (positions.raidTools), `EUI_RaidTools_Markers`, `EUI_RaidTools_Compact` (resizable). Options preview through `ns.RaidToolsPreview`. Media from `prepare_raidtools_media.py` (strips PIL's TGA footer). Not portable: world markers/Quick Fire, Role Check, `C_PartyInfo.DoCountdown`.

## Latest (2026-10-10) — Style page on Wrath, Damage Meters Classic (DM 0.9, Options 0.114, no extra bumps)

- Style page is Retail 9.4's: no per-module rows (`StyleRowCfg`, `SECTION_STYLES` gone); a `BuildVisOptsCBDropdown` checklist under each look card (`dimLocked` ported into `EllesmereUI_Widgets.lua`) holds pending picks, Apply Styles writes them with one reload prompt; cards use `inUseAlpha = 0.5`, `badgeSize = 13` (ported into `EllesmereUI_StyleCards.lua`). A look a module can't draw (`Supports`) leaves it out of that card's list. Builder written by `backport-tools/port_style_page_dropdowns.py` (one-off).
- `EUI_Style_Options.lua`: on `EUI_WOW_335` the Cooldown Manager icons/bars, Minimap and Damage Meters offer only `{"eui","classic"}` (`m.styles`); Player Aura Bars is not registered. `Supports(m, key)` makes Apply to All, `StyleChangesFor` and the card count skip modules without that look. `DMProfile` returns the port's root profile; DM slot keys are `windows.<1..5>.bgColor/barTexture/barBgColor` (stamp `classicSeeded`); `PathGet`/`PathSet` index numeric segments.
- Damage Meters: `ns.DMStyle/DMClassic` (latched per session from `useClassicStyle`), `ns.DMSeedClassic` once per profile. Display: tooltip box (`CLASSIC_BOX`, inset 5), tooltip header band and 1px line, Retail vanilla header art (`CLASSIC_ART`) and per-metric spell icons (`CLASSIC_METRIC`). Not ported: Retail's chat-tab rim, Blizzard Style for CDM/Minimap/DM, options gating under Classic. Checked in `validate_damagemeters.py` and `validate_themes_presets.py`.
- Action Bars 0.22 End Caps: new `EllesmereUIActionBars/EUI_ActionBars_335_EndCaps.lua` (TOC after the main file; validators load it explicitly). Per-bar `endCapLeft/Right`, `endCapScale/OffsetX/OffsetY`; Classic art only (Retail `AB_CAPS.classic` geometry); host is a child of the bar; called from `Layout` via `ns.AB_ApplyCaps`. Options: "End Caps" row closes LAYOUT (checklist swapped into the row, cog, Sync); the preview pads by `ns.AB_CapsReach`. Not ported: Modern/Forever art, Micro/Bag bar caps, first-install span.
- Action Bars 0.22 XP Bar Style (Menu, Bags & XP Bars > EXPERIENCE BAR): dropdown EllesmereUI / Blizz Default replaces Enable Experience Bar; reads `nativeHUD.xp`, writes `xp` and `reputation` together (Retail's single useBlizzardDataBars switch). Professions/Forever not ported (Retail atlases).
- Also this session: Global Settings action row (Reset ALL | Uninstall, Optimize removed), import into current profile, sync popup `SetParent(nil)` fix (Core 0.66).

## Latest (2026-10-09) — other locales filled (no bump)

- `backport-tools/export_locale_batches.py` exported the port keys missing from each Retail catalog to `backport-tools/locale_work/<code>/in_NN.tsv`; translations are in `out_NN.tsv`. `build_locale_additions.py` (`--check` for a dry run) appends them after the MARKER line `-- == 3.3.5 port additions (backport-tools/build_locale_additions.py) ==` at the end of each Retail catalog, so everything above the marker stays the (unused-key-trimmed) Retail text (`validate_locales.py` checks only that part against Retail). esMX reuses the esES batches. `FIXES` overrides the broken deDE "Learn %d skill%s for %s". esES uses "vida" for Health, like Retail (`normalize_esES_terms.py`). Coverage: `check_locale_catalogs.py`. Edit `out_*.tsv` and rerun the build; it rewrites the block after the marker.

## pt-BR catalog (no bump: Alex wants no version bumps or patch notes for language updates)

- New port-only `EllesmereUILocales/ptBR.lua` (4925 entries; no Retail ptBR exists). Source: `backport-tools/export_ptbr_keys.py` wrote the 5259 port UI keys (catalog keys in use plus port labels, minus long patch-notes prose) to `backport-tools/ptbr_work/keys.tsv`; translations are in `ptbr_work/out_*.tsv` (`<id>\t<pt-BR>`), glossary `ptbr_work/GLOSSARY.md`. `build_ptbr_catalog.py` rebuilds the catalog and rejects bad placeholders/markup/escapes; fix a translation in `out_*.tsv` and rerun it. Engine `SUPPORTED` has `ptBR`; the picker lists "Português (Brasil)". `validate_locales.py` skips the Retail-subset check for ptBR and asserts Background -> Fundo. Port labels added later need a new export pass.

## Locale catalogs trimmed (2026-10-09, no bump)

- On Alex's request the EllesmereUILocales catalogs are no longer byte-identical to Retail. `backport-tools/clean_locale_catalogs.py` removed 5430 single-line entries the port never shows (Retail-only text and keys unused even in Retail); kept 4048: verbatim port literals (3598), near matches of port text (301, recoverable by restoring the Retail wording / `%1$s` formats), and runtime-built labels (149, a port label ending in space/colon plus a short tail). Kept lines are byte-identical and in Retail order; `validate_locales.py` checks that. Backup: `.codex-backups/locales-before-clean-20261009-015841`.
- `backport-tools/scan_locale_coverage.py` (read only) reports used / reworded / Retail-only / unused keys and port UI labels without a key (about 1970, mostly 3.3.5-only option text and patch notes) to `%TEMP%\eui_locale_coverage.txt`. Rerun the cleaner after big text changes only if Alex asks.

## Latest (2026-10-09) — Standalone Damage Meters (no bumps)

- `backport-tools/build_standalone.py [--module DamageMeters] [--out DIR] [--zip]` builds `standalone/EUIStandaloneDamageMeters` (ignored by git) and `EllesmereUI-3.3.5-EUIStandaloneDamageMeters-<stamp>.zip`. Ship it as a separate release asset, never inside the suite zip, and never copy it into an install that also has the suite.
- Lightweight on Alex's request ("only the damage meter and settings on his own, no EUI and Unlock Mode menu"): no Core, Libs, EUI panel or Unlock Mode. `backport-tools/standalone_src/DamageMeters_Standalone.lua` is the shim: `E.Lite.NewAddon/NewDB` (one account profile in the module SV, `ResetProfile`), `_ModuleNS`, accent/font (bundled Expressway), and its own settings window that renders the existing `EUI_DamageMeters_335_Options.lua` via `E:RegisterModule` + `E.Widgets` (`SectionHeader`/`DualRow`/`WideButton`; toggle, slider + value box, custom dropdown list, input, ColorPickerFrame swatches, multiSwatch), tabs per page, deferred `RefreshPage` (waits for ColorPickerFrame to close), two-click "Reset to Defaults", ESC closes. The "Unlock Mode" wide button is skipped; all DM Unlock calls are already guarded.
- Fonts: the build ships unchanged `Libs` LibStub, CallbackHandler and LibSharedMedia (Retail LSM, so the guard also adds the `C_UIFileAsset.IsKnownFile` shim; the folder loads before `EllesmereUI`). The shim registers Expressway with LSM; `E.GetFontPath` returns `profile.font` via LSM (default Expressway). `EUI_DamageMeters_335_Options.lua` adds a "Font" dropdown under BAR TEXT only when `E.StandaloneFontChoices` exists (never in the suite); dropdown entries with `previewFont` render in their own font.
- Rename scheme (same as Retail packager): AddOns paths -> the folder; `EllesmereUIDamageMeters` -> `EUIStandaloneDamageMeters`; other contiguous `EllesmereUI` -> `EUICoreStandaloneDamageMeters`, except inside strings when not followed by an identifier character; addon API calls with `"EllesmereUI"` -> the folder.
- TOC order: generated `Standalone_Guard.lua` (inert + chat warning if the suite is enabled; every other file starts with `if EUIStandaloneDamageMeters_Inert then return end` on line 1), shim, module TOC files, `EUI_DamageMeters_335_Options.lua`. Copies `media/fonts/Expressway.ttf`, `media/eg-logo.tga`, `Media_335`, Resource Bars `Textures_335`. SVs: `EUIStandaloneDamageMetersDB`, per-char `EUIStandaloneDamageMetersHistory`. 51 files, 1.6 MB.
- `validate_standalone_damagemeters.py`: TOC/compile/rename/path checks, guard both ways, and runs the real build in the mock (lifecycle, SV, `/edm` window, every widget kind, refresh, reset, close). Copied to Test; not confirmed in game yet.

## Latest (2026-10-09) — Update notices (Core 0.61) and EUI Staff page (Options 0.113)

- `EllesmereUI/EllesmereUI_UpdateCheck_335.lua` (last in the Core TOC): release stamp = Core TOC `## X-EUI-Release: YYYYMMDDNN` (now `2026101003`, release v0.6). **Raise it for every GitHub release/RC**, or clients never see a newer one.
- Prefix `EUIVER`, payload = stamp. Sends to GUILD 15 s after login and to BATTLEGROUND/RAID/PARTY on roster changes; 60 s throttle per channel/target. A lower stamp gets ours back on the same channel (WHISPER to the sender); a higher one prints one chat notice per session unless `EllesmereUIDB.updateCheckDisabled` (toggle "Update Notices", Global Settings > General). `/euiupdate` opens `ShowCopyPopup` with the releases URL. No clickable chat link: unknown hyperlink types error in Blizzard `SetItemRef` without EUI Chat.
- Patch Notes: tab `PAGE_STAFF = "EUI Staff"` (Alex wants the EUI Staff name kept); page title "Special thanks to Ellesmere", cards PORT STAFF (`EllesmereUI._PORT_STAFF`, Laraystiri + GitHub icon -> `EllesmereUI.ShowLinkPopup`, exposed from the Panel footer) and ORIGINAL STAFF (`_STAFF`). Header line "Special thanks to: Ellesmere" restored (opens that page). Icon `EllesmereUI/media/icons/github.png` from `backport-tools/make_github_icon.py` (Octicons mark).
- Validators: new `validate_update_check.py`; `validate_patch_notes.py` updated.

## Latest (2026-10-09) — Hidden 3.3.5 dead options (no bumps)

- Global Settings Reset: `EllesmereUI._applyHideBlizzardPartyFrame` (Retail-only) is called only if defined; the reset now finishes and reloads.
- Hidden when `_G.EUI_WOW_335` (Retail unchanged), in `EUI__General_Options.lua`: Increase Game Image Quality and Lag Tolerance (Combat row is now Max Camera Distance | Cast Actions on Key Down), Combat Text Size (Combat Text Font moves left), Prevent Swiftmend Icon Dim, Dark Mode (Class Resource Bar) (blank slot), CLASS RESOURCE COLORS section (gate 3 skipped), and Monk/Demon Hunter/Evoker + Fury/Lunar Power/Insanity/Maelstrom/Ebon Might swatches (`WithoutWrathMissing`, color tables untouched).
- `EUI_Fonts_Options.lua`: Combat & World Text card keeps only the font link; Disable Slug Outline hidden (Name Font moves left).
- `EUI_Textures_Options.lua`: QoL card drops cursor/GCD/cast ring textures (`_ECL_*` does not load); the card is removed unless `EllesmereUI._MovementBarTextures` exists.
- `EUI_UnitFrames_Options.lua`: Important Cast Glow row (cog/sync) and its two Glows-page sites hidden (no `C_Spell.IsSpellImportant`).
- Blizz UI Enhanced: window spec `addonlist` has `optional=true`; the options page skips optional specs whose first frame is missing (`_G.AddonList`).
- ABR: `CollectRuneforge` returns when `consumables.enabled.runeforge == false`.
- Validators: `validate_combat_text_settings.py` (static + swatch filter behaviour), `validate_blizzardskin.py` (AddOn List row with/without frame), `validate_unitframes.py`, `validate_aurabuffreminders.py` (runeforge off -> no reminder).

## Latest (2026-10-08) — Mail boxes and tooltip anchor (small fixes, Blizz UI Enhanced stays 0.28)

- `InnerPanel` puts the border frame at its owner's level (not -1), except sheet frames; at -1 it tied with SendMailFrame, whose BACKGROUND sheet fill hid the To/Subject/body borders. Edit boxes get a lighter fill (.06) and a .25 border.
- An EditBox whose parent is a chromeFrames ScrollFrame (SendMailBodyEditBox) gets no box; the scroll frame's box frames it.
- Tooltips: `T` is an `ns.extras` module, so `ns.Apply` (every 0.2 s when dirty) ran `T.PositionFixed` and snapped the dragged anchor back. `T.Apply` skips it while `E._unlockActive`.
- Collapsed options mini window: no cause found (code and art unchanged since `4654752`); waiting for a screenshot.

## Latest (2026-10-08) — Send Mail recipient list (QoL 0.15) and edit box cursor

- `EUI_QoL_335_Mail.lua`: `mailRecipients` (default on) adds `EUI335QoLMailRecipientsButton` right of `SendMailNameEditBox` and a custom popup `EUI335QoLMailRecipients` (no UIDropDownMenu, avoids taint) with Alts/Guild/Recent tabs, 12 rows, mouse-wheel scroll.
- `EUI_QoL_335.lua` `ns.InstallMerchantWheel` (`merchantWheel`, default on, same QoL 0.15): MerchantFrame mouse wheel clicks the native `MerchantPrevPageButton`/`MerchantNextPageButton` when shown and enabled.
- Data in `EllesmereUIDB.mailRecipients`: `alts[realm][name]={class,level,faction}` recorded on every `ApplyMail`; `recent[realm]` = last 15 names, saved on `MAIL_SEND_SUCCESS` from a `hooksecurefunc("SendMail")` post-hook. Alts filtered by faction; guild via `GetGuildRosterInfo`, `GuildRoster()` on tab open.
- Blizz UI Enhanced 0.28 (no bump): `Font()` only calls `SetFont` when path/size/flags differ and `InnerPanel` only clears a backdrop that exists, so refreshes no longer hide the edit box cursor (unconfirmed in game).
- Collapsed menu (Core 0.60, no bump): on Wrath the E logo `badgeOv` is on OVERLAY, above the black disc.

## Latest (2026-10-08) — Code review: taint and error fixes (small fixes, no bumps)

- Bags: `ns.TakeOverBags` (called from `ns.Apply`) replaces the 10 bag globals only once `enhancedBags` is on (`ns.bagsTakenOver`); with it off they stay native. Turning it off afterwards still passes through until /reload (tooltip says so).
- QoL Mail: bulk attach is a `hooksecurefunc` post-hook on `ContainerFrameItemButton_OnModifiedClick`; it hides `StackSplitFrame` when the click attached items.
- Resource Bars Totems: `T.LayoutCall` checks combat before sizing/positioning the call bar holder (it parents protected buttons).
- Core Tooltip IDs: `SetAction` uses the 4th `GetActionInfo` return (spell ID), falling back to `GetSpellLink(slot, bookType)`.
- ABR options: zone merge creates `zoneNames` from `zone`/`zoneName` on old reminders and clears the saved `_nameSet` cache.
- Validators: `validate_inventory_resources.py`, `validate_qol.py`, `validate_resourcebars.py`, `validate_tooltip_ids.py`.

## Latest (2026-10-08) — Channel cast text (small fix, no bump: Unit Frames 0.18, Resource Bars 0.5)

- Wrath `UnitChannelInfo` returns name, rank, "Channeling", icon, ...; the third
  value is a fixed label. `W.UnitChannelInfo` and `C.ReadCast` used it as the
  display text; both now use the name. `wrath_mock.lua` returns "Channeling" there
  like the client, and the UF/RB validators assert the spell name.

## Latest (2026-10-08) — Auction House vs AH addons (Blizz UI Enhanced 0.28)

- The AH skin is the generic window walk. It restyled Auctionator's own frames
  (backdrops, Blizzard-path art) inside AuctionFrame. The `auctionhouse` spec is
  now `nativeOnly`: children that are anonymous or whose global name is not
  `issecurevariable` go through `WalkForeign` (fonts and ui-panel-button text
  buttons only), and anonymous textures on the AuctionFrame root are left alone.
- `Button`: `*CloseButton` with label text (BrowseCloseButton, BidCloseButton,
  AuctionsCloseButton, addon "Close" buttons) no longer gets the "x" label.
- `blizzardskin_mock.lua`: window close buttons are label-less like UIPanelCloseButton.
- Open: Alex reported "some bars misplaced" on the AH; still needs a screenshot
  of the Blizzard tabs to identify them.

## Latest (2026-10-08) — Boss frame health poll (Unit Frames 0.18)

- Wrath sends a boss's UNIT_HEALTH/UNIT_POWER under the target/focus token only,
  never `bossN`, and the 3.3.5 `RegisterUnitEvent` shim filters by token, so
  untargeted boss frames froze. `EUI_UnitFrames_Engine.lua` `Engine.Attach` puts
  boss1-5 in `bossFrames`; `bossTicker` (0.2 s, shown only while a boss frame is
  shown) paints health, power, text and absorb. `validate_unitframes.py` covers it.

## Latest (2026-10-08) — Targeted Spells (Raid Frames 0.18, Options 0.112)

- Retail Raid Frames no longer ships the code; only the migration
  `rf_targeted_spells_bool_to_mode_v1` (`tsMode`, `tsRaidMode`, never/whenHealing)
  and locale labels remain, so the port follows those keys and labels.
- `EllesmereUIRaidFrames/EUI_RaidFrames_335_TargetedSpells.lua` (after ClickCast):
  per-group keys `tsMode` (party whenHealing, every raid layout never but
  selectable), `tsPreview`, `tsSize`, `tsMax`, `tsPosition`, `tsGrowth`,
  `tsOffsetX/Y`, `tsSwipe`, `tsTimer`, `tsColorInterrupt`,
  `tsInterruptibleColor`, `tsUninterruptibleColor` (patched into `ns.defaults`).
  Wraps `ns.Apply` (refresh activation), `ns.LayoutButton`, `ns.UpdateFrame`
  (preview icons and repaint); `ns.TargetedSpells` holds the state.
- Detection: one entry per caster GUID; victim `UnitGUID(token.."target")` is
  re-read on every observation. UNIT_SPELLCAST_* only for target, focus,
  mouseover, boss1-4, arena1-5; UNIT_TARGET, PLAYER_TARGET/FOCUS_CHANGED,
  UPDATE_MOUSEOVER_UNIT refresh. A 0.2 s scan reads target, focus, mouseover,
  targettarget, focustarget, pettarget, boss1-4 and raidNtarget/partyNtarget.
  Unseen casters are dropped 250 ms after their end time; an interrupted or
  stopped cast is not revived by the scan (`TS.ended` keeps its start).
  Events and OnUpdate are only registered while the live group's mode is on.
- Validator: new `validate_raid_targeted_spells.py`.
- Not ported: Retail glow/important-cast highlight, icon tooltips, per-spell
  filters. Which tokens fire UNIT_SPELLCAST_* on Alex's client still needs
  in-game confirmation (compound tokens are polled either way).

## Latest (2026-10-08) — Absorb shields (Core 0.60, Raid Frames 0.17, Unit Frames 0.18, Options 0.111)

- Core `EllesmereUI_Absorbs_335.lua` (after SpellCostPrediction in the TOC):
  `EllesmereUI.GetUnitAbsorb(unit)`, `GetGUIDAbsorb(guid)`,
  `RegisterAbsorbCallback(owner, fn(guid))`, `UnregisterAbsorbCallback`. Events
  register on the first callback. CLEU estimate: known shield IDs (PW:S, Divine
  Aegis, Sacred Shield proc 58597, Ice Barrier, Mana Shield, Fire/Frost/Shadow
  Ward, Sacrifice, AMS, AMZ, Savage Defense, Val'anyr 64413) get the rank base,
  plus SP x coefficient when the player cast it (no talents/glyphs); Aegis 30% of
  the caster's last crit heal on the target, Val'anyr 15% of the last heal (both
  stack to a cap); AMS 50% of max health; Savage Defense 25% AP (own) else 1500.
  Absorbed parts of damage and `*_MISSED ABSORB` drain shields oldest first,
  school wards only for their school. Removal within 0.5 s of a hit stores the
  absorbed total as the learned capacity per spell+caster. UNIT_AURA seeds untracked
  shields and drops gone ones. A secure native `UnitGetTotalAbsorbs` bypasses all
  of it (`issecurevariable` filters addon-defined globals).
- Shared overlay `EllesmereUI.Absorbs.CreateOverlay/Paint/Hide`: two textures
  (forward + overshield backfill), edge modes overlay/overlayReverse/right/left,
  overshield always/never/fromleft, vertical, reverse; tiled styles keep native
  density via texcoords. Art in `media/textures/shields_335` from
  `backport-tools/prepare_absorb_media.py` (PNG/NPOT Retail art to POT TGA).
- Raid Frames: Retail keys/defaults (`absorbStyle` striped, 90%, white, overlay,
  overshield on); ABSORBS section after HEAL PREDICTION.
- Unit Frames: `EUI_UnitFrames_335_Absorbs.lua` wraps `ns.UF_AttachEngineFrame`
  (player/target/focus/boss1-5), repaints from `ns.UF_ReloadAllAuraContainers`
  (wrapped) and the absorb callback; reads Retail keys, Striped = striped3
  stretched. One-time seed `wrathAbsorbSeeded` sets `showPlayerAbsorb` to striped.
  Options: `elseif EUI_WOW_335` ABSORBS branch and `ns.UF_WrathAbsorbPreview` in
  the preview. `EllesmereUIUnitFrames.lua` and the Engine are untouched.
- Validators: new `validate_absorbs.py`; `validate_raidframes.py`,
  `validate_unitframes.py`, `validate_core_engines.py` extended.
- Not ported: heal absorbs, absorb strip bars, Glow Line, large/pixels styles,
  absorb text tags, the preview eyeball. Waiting for in-game confirmation.

## Latest (2026-10-08) — Cooldown Manager 0.7 (Retail add menus)

- The CDM Bars header '+' slots open `O.ShowPicker` (UIParent child,
  FULLSCREEN_DIALOG, DD_STYLE, closes on outside click, wheel scroll above
  `O.PICK_MAX_H`). Main '+': Custom Spell ID / Custom Item ID / Equipment Slot
  (`E:ShowInputPopup`), Trinket Slot 1/2, Racial (`O.PlayerRacial`), Potions &
  Healthstone submenu (`ns.ITEM_PRESETS`), learned class-tab spells. Gold '+' and a
  Buffs bar's '+': Custom Spell ID as aura, `ns.BUFF_PRESETS`, class catalog buffs,
  learned spells as auras. Entries already on the bar are greyed (`O.Tracked`); list
  picks reopen the picker on the rebuilt '+' at the same scroll. All adds go through
  `O.AddEntry` (40 cap). The ADD ENTRY section is unchanged.
- `/ecdm debug` and the `_dbg` calls are gone.
- Not ported: "Missing Spells?" footer, Retail's equipment slot picker popup,
  wrong-bar-type warning, cross-bar "already used on" claims.

## Latest (2026-10-08) — Chat 0.49 (Copy Chat)

- `ns.CopyChat()` picked `FCF_GetCurrentChatFrame()`, which on 3.3.5 is the last
  right-clicked tab (`CURRENT_CHAT_FRAME_ID`), so it could copy an empty tab. It now
  uses `FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)`, then `SELECTED_CHAT_FRAME`.

## Latest (2026-10-08) — Cooldown Manager 0.6 (bar selection jumping to Buffs)

- Root cause: Spec Overrides golden borders (`EllesmereUI_SpecOverrides_335.lua`,
  `BeginTrace`/`TraceSlot`) swap every `db.profile` for read proxies and run getters.
  In Lua 5.1 `#`/`ipairs` see a proxy as empty, so `ns.Bars()` reseeded the default
  bars into index 1 (last write = a fresh Buffs bar), corrupting saves (two Buffs, no
  Cooldowns) and making `O.Bar()` select Buffs. `ns.Bars()` now detects a proxy
  (`rawget(bars,1)==nil and bars[1]~=nil`) and returns a plain list read via
  `__index`, never seeding/repairing there; `ns.Migrate` checks `old[1]==nil`.
- Any other getter that writes based on `#`/`ipairs` of profile data has the same
  hazard under the trace.
- The temporary `/ecdm debug` log and `_dbg` calls were removed in 0.7 (Alex
  confirmed the fix).

## Latest (2026-10-08) — Cooldown Manager 0.5 (racials, trinket ICDs)

- Racial variants (`ns.RACIAL_GROUP`): seeds add one entry per race, `ns.CollapseRacials`
  merges saved variants once per session, and `ns.Compile` skips a second entry for
  the same spellbook spell on a bar (three Arcane Torrents).
- `EUI_CooldownManager_335_TrinketData.lua` (generated by
  `backport-tools/extract_cdm_trinket_icd.py` from Alex's "Item Widget" WeakAura):
  passive proc trinkets in slots 13/14 resolve even with Show Passive Trinkets off and
  run their ICD from the combat log (registered only while one is tracked) or the proc
  aura start. Options show the equipped trinket icon instead of "?" for hidden slots.
- Not ported: enchant/gem ICDs, realm ICD tweaks, ICD start on equip, saved ICD across
  reloads.

## Latest (2026-10-08) — Cooldown Manager header (Options 0.110)

CDM Bars has Retail's content header, built by `O.HeaderBuilder` in
`EUI_CooldownManager_335_Options.lua` and registered through `getHeaderBuilder`.
- **Bar dropdown** (`O.BarDropdown`/`O.BuildMenu`): select a bar; rename and delete
  custom and FocusKick bars; "+ Add New Cooldowns/Utility/Buff Bar" (capped at 20
  custom bars); "+ Add FocusKick Bar" while none exists.
- **Icon row** (`O.IconRow`/`O.IconSlot`):
  - Drag reorders (`O.MoveEntry`).
  - Click selects the entry and scrolls to Tracked Spells; middle-click removes it.
  - "+" opens the add picker (0.7); the gold "+" opens the buff picker.

The old Select Bar, Bar Name, New Bar Type, Add Bar and Remove Selected Bar rows are
gone. `validate_cooldownmanager.py` drives the header.

Not ported:
- Retail's spell and buff picker menus (ported in Cooldown Manager 0.7).
- Dragging custom bars to reorder them inside the dropdown.
- Styled preview icons.

Not in Test yet. Nothing is committed since `3c94695`.

## Project layout (changed 2026-10-06)

The project lives in `C:\Users\Gaming\Desktop\EUI backport`, which is the git
repo (remote `https://github.com/Darksummonex/EUI-port.git`). Open this folder as
the workspace. It holds the 20 real `EllesmereUI*` addon folders,
`backport-tools/` (validators, mocks, extractors, packers), `.codex-tools/` (lupa
and mpyq for Python), `.codex-backups/`, these docs and the EUI ZIPs. The project
is strictly EllesmereUI: other addons are not part of it or its backups.

Alex plays on the `D:\Jogo\WLk` client: a customised 3.3.5 (build 12340)
client that ships Retail UI ports, including an addon-level `C_Texture` whose
`GetAtlasInfo` errors on unknown atlases (Core wraps it, see Core 0.49). Its
errors are in `D:\Jogo\WLk\WTF\Account\DARKSUMMON\SavedVariables\!BugGrabber.lua`
and `D:\Jogo\WLk\Logs\FrameXML.log`. `D:\Jogo\Whitemane\Games\FrostmourneRebuffed`
is the second install; `game_paths.py` points at it for the reference addons and
client MPQs. In both installs `Interface\AddOns` keeps the game's own addons plus
one directory junction per `EllesmereUI*` folder pointing back here, so each
client loads the project files directly. WLk's previous copies were moved to
`D:\Jogo\WLk\Interface\EUI-copies-20261006`. Edit files here and `/reload` in game. Do not replace the junctions
with copies. A new EUI module folder is created here and linked with
`New-Item -ItemType Junction -Path "<AddOns>\<Name>" -Target "<project>\<Name>"`.

**Test and Production installs** (Alex, 2026-10-06; supersedes the junction note
above for these two installs, which hold real folder copies):
`D:\Jogo\Whitemane\Games\FrostmourneRebuffed` is **Test** (launch its `Wow.exe`) and
`D:\Jogo\FrostmourneRebuffed` is **Production**. "send updates to test" backs up and
mirrors the `EllesmereUI*` folders and `AbilityTimeline` into Test only
(`.codex-backups\test-addons-before-copy-<stamp>`). Production is updated only when
Alex asks, after the same backup (`production-addons-before-copy-<stamp>`).
AbilityTimeline lives outside the project; its working copy is now the Test one.
DBM is only in Production, so the AbilityTimeline validators read Production through
`EUI_GAME_DIR=D:\Jogo\FrostmourneRebuffed`.

**Do not use the game client folders** (Alex, 2026-10-06): no reading, copying,
syncing or inspecting `D:\Jogo\...` installs, their WTF/BugGrabber, logs or MPQs.
Ask Alex to paste in-game errors instead. `backport-tools/game_paths.py` is `None`
unless `EUI_GAME_DIR` is set explicitly; without it the checks against other
addons (ElvUI, DBM, AbilityTimeline, ACP) skip. Retail sources stay at
`D:/World of Warcraft/_retail_` (read only, never modify).

Blizzard files extracted from the client (`backport-tools/framexml-worldmap/`,
`framexml-skins/`, `_glyph_art/`) are listed in `.git/info/exclude`. Never commit
them. The project ZIP contains them, so keep it private.

## Workflow and rules

- Per module: compare Retail against Wrath, port, validate, bump the TOC
  version (no BOM), add a Portuguese entry to the module `README-335.md`, update
  the in-game patch notes in `EllesmereUIOptions/EUI__General_Options.lua` (one
  header per module, `version = "<Module> X.Y"` matching the TOC, with
  `heroes`/`features`/`fixes`), then report what was not ported.
- Every module needs Unlock Mode movers plus Element Options (Zone Text excepted).
- Never restart WoW; ask for `/reload`.
- Do not edit the byte-identical Retail copies kept in module folders (for example
  `EllesmereUIActionBars/EllesmereUIActionBars.lua`,
  `EllesmereUIOptions/EUI_ActionBars_Options.lua`); validators compare them.
- Keep Options EditBox autofocus and focus cleanup; no fake keyboard propagation.
  Avoid `SetRotatesTexture`.
- Compat shims only fill methods the client lacks. Never replace an existing method
  on a shared widget metatable: Blizzard frames share it and get tainted (Options
  0.87 did this and Esc showed "EllesmereUIOptions has been blocked"). Per-instance
  patches on EUI-owned objects (Unit Frames `PatchRegion`) are fine.
- Do not rerun `update_*_checkpoint.py`, `scope_options_factory.py`,
  `connect_indicator_editor.py` or `prepare_raidframe_textures.py`.
  `package_project.py` is the old 0.38 checkpoint packer and still expects the
  0.38 archives.
- Keep old backups, `.codex-backups` and checkpoint scripts.
- Commits: `cursor/` branch, stage only related files, concise message, push only
  when asked. Keep the exact addon folder names at the top level of ZIPs.

Python: `C:/Users/Gaming/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`
(missing since 2026-10-06 19:00; any 64-bit Python 3.12 works with `.codex-tools`,
see `AGENTS.md`). Git: `C:\Program Files\Git\cmd\git.exe`. Full validator loop
(66 validators, all pass), run from the project folder:

```
$py='C:/Users/Gaming/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'; $all=Get-ChildItem backport-tools\validate_*.py; $fail=@(); $all | ForEach-Object { $out = & $py $_.FullName 2>&1 | Out-String; if ($LASTEXITCODE -ne 0) { $fail += $_.Name; $_.Name; ($out.Trim() -split "`n" | Select-Object -Last 6) } }; "Ran $($all.Count). Failures: $($fail.Count) -> $($fail -join ', ')"
```

Working-tree backups: `backport-tools/backup_project.py` writes
`EllesmereUI-3.3.5-HUD-backup-<stamp>.zip` (installable addon folders) and
`EllesmereUI-3.3.5-project-backup-<stamp>.zip` (plus tools and docs), each with a
`.sha256`, and records versions in `.codex-backups/`. Latest: `20261006-1240`.

## Current versions

Core 0.66; Action Bars 0.22; Arena 0.3; AuraBuff Reminders 0.7; Bags 0.12;
Blizz UI Enhanced (BlizzardSkin) 0.34; Chat 0.49; Cooldown Manager 0.9;
Damage Meters 0.9; Data Bars 0.5; Friends 0.3; Minimap 0.4; Nameplates 0.20;
Options 0.114; Locales 0.1; QoL 0.19; Quest Tracker 0.3; Quickdraw 0.4; Raid Frames 0.24;
Resource Bars 0.5; Unit Frames 0.26.

Retail reference is EUI 9.4 (2026-10-09). `backport-tools/sync_retail_references.py`
(dry run; `--apply` backs up first) refreshes unloaded Retail copies and adds new
Retail files; it skips TOC-loaded files, `.toc`, `Bindings.xml` and EllesmereUILocales.
`compare_retail_update.py` reports Retail vs project differences. The locale
catalogs stay trimmed from the 9.3.4 catalogs: `validate_locales.py` checks them
against commit 4654752 (untrimmed 9.3.4), not the live Retail folder.
Retail 9.4 batch ported (easy items): QoL Auto Select Single Gossip, Raid Frames
"Down and then Right", Nameplates Enemy Buff Filter (Show All), Unit Frames Hide
Sated / Exhaustion, Action Bars Show Equipped Item Color.
!!!ClassicAPI (other 3.3.5 polyfill addon) injects a SetClipsChildren that reparents
the frame into a ScrollFrame sized at call time (EUI dropdowns never opened) and a
CreateMaskTexture that returns nil. EUI never calls them on its frames: Core helpers
`EUI335.SetClipsChildren` (no-op), `EUI335.CreateMaskTexture` (hidden fake mask) and
`EUI335.OwnFrame` (per-frame overrides, metatables untouched), used by
`EllesmereUI.CreateOptionsFrame`; UF `PatchRegion` always sets a no-op clip.
`validate_classicapi_compat.py` simulates ClassicAPI.
Ideas taken from ClassicAPI (own code, no dependency): Unit Frames 0.20 Heal
Prediction (`EUI_UnitFrames_335_HealPred.lua`, LibHealComm-4.0 bundled in UF too;
validate_uf_heal_prediction.py) and Core 0.62 `EllesmereUI.CreateTextureSwipe`
(four ScrollFrame quarters + a wedge turned by a zero-length Rotation animation;
validate_texture_swipe.py), used by Cooldown Manager 0.8 Swipe Style "Shaped".
Both add files: a full client restart is needed. Confirmed working in game.
Retail 9.4 easy-medium batch: Cooldown Manager 0.9 Hide Until Usable / Hide Outside
Form/Stance (ns.CD_STATE_HIDE; form from the tooltip "Requires <form>" line, red when
unmet, Retail caster-form fallback) and Empty Slot entries (kind "empty");
validate_cdm_hide_modes.py. Unit Frames 0.21 player Type Icon Position (dispel icon,
Wrath spell icons) and focus aura border options. Blizz UI Enhanced 0.29 inspect
enchant icon/hover or names (inspectEnchantNames, inspectEnchantSize).
General/QoL/Bags/Skins+ batch: Core 0.63 Uninstall EUI (EllesmereUI_Uninstall_335.lua:
E.SetCVar/SetChatWindowSize/NoteBinding/OnUninstall/Uninstall, per-character records in
EllesmereUIDB.restoreOnUninstall; Minimap, Nameplates, Chat, QoL, Tooltips and Quickdraw
write through it; validate_uninstall.py). Bags 0.12 Junk Marker (bagShowJunkIcon,
bagShowJunkCoin, Junk category, bagJunkPrev, ns.SellJunk; validate_bag_junk.py). QoL 0.17
Self Combat Text (EUI_QoL_335_CombatText.lua, combat log, OnUpdate scroll;
validate_qol_combattext.py). Blizz UI Enhanced 0.30 tooltipShowBuffs icons and
highlightStatItems glow (validate_blizzardskin_extras.py). Two new files: full restart.

Git: branch `cursor/eui-shapes-bars-skins-qol`, built on
`cursor/eui-arena-and-fixes`. Neither is merged into `main`; no PR is open.

## Latest work (2026-10-05 / 06)

- Core 0.58 / Options 0.108 / Locales 0.1: eight original community catalogs
  for native WoW 3.3.5 languages; English is built in. EUI_Locale_335.lua
  preserves the Retail reference and adds Lua 5.1 positional formatting and
  native-client glyph fonts. Automatic/manual selection and English fallback.
  No ptBR/itIT catalogs. Project only; not deployed to Test yet.

- 2026-10-07: restored Chat 0.48 / Options 0.107 gold-seller filters at Alex's
  request, including bucks offers and disguised website names. Core 0.57 uses
  baked circular badge alpha, the existing eg-logo.tga Ellesmere E logo tinted
  with the UI accent, and an explicit close icon for the collapsed menu.
  No Gargul changes are included.

- AuraBuff Reminders 0.6 / Options 0.99: custom reminder IDs, where-to-show and
  section sound use EllesmereUIAuraBuffRemindersCharDB (SavedVariablesPerCharacter).
  Runtime and add/remove/options use GetCustomSettings. Legacy shared lists are
  claimed by the first character reading them and cleared from the profile so
  other characters do not inherit them. Profile switches leave the character list
  intact; legacy lists in newly selected profiles migrate on access with deduping.

- AuraBuff Reminders 0.5: Holy Paladin Seal of Wisdom aura reminder (seal_wisdom,
  spell 20166), enabled by default and independently configurable in AURAS.
  Only accepts the player's Wisdom seal; generic seal reminder excluded for Holy.
  Protection/Retribution and pre-talent generic behavior stay unchanged.

- Core 0.56: widget tooltip fade-in/out falls back to Wrath Alpha:SetChange;
  fixes Unlock Mode Grow Right hover SetFromAlpha nil error. Native methods are
  retained when present; no shared animation/widget metatable changes.

- Damage Meters 0.8: consumed shield absorbs contribute to Healing Done/HPS and
  new Absorbs Done metric. Tracks common shield auras and caster ownership before
  combat; seeds UnitAura at combat start. Attributes only a unique friendly owner,
  groups overlapping spells from that owner, and leaves conflicting/unknown owners
  unassigned. Absorbs Received stays unchanged. No shield-capacity guesses or
  future damage credit on application. Native combat-log testing pending.

- Chat 0.44 / Options 0.96: independent optional achievement (player/guild),
  public Trade-ad and guild-recruitment presets plus literal custom keyword/phrase
  filtering. Keywords use repeat scope selectors and comma/semicolon/newline lists;
  visible text only, case/space normalized. Own messages and achievements remain
  visible. All additions default off. Presets match common English/Portuguese text,
  not every locale or obfuscation. Native in-game review pending.

- Chat 0.43: optional repeated-message filtering in Chat > Spam Filter. Default
  off; public chat enabled as the initial scope, group/guild and incoming whispers
  opt in. Repeat window 1–120 seconds (15 default), same sender by default or
  across senders. Case/whitespace normalization, per-channel matching, own-message
  bypass, bounded caches and consistent per-line-ID decisions across chat windows.
  Clients without line IDs use independent window histories. Hidden repeats do
  not extend the window; settings changes reset history. All 62 validators pass, including
  validate_chat_spam_filter.py. Options 0.95 adds the controls. Native in-game review pending.

- Classic WoW UI green health (Unit Frames 0.14, Options 0.89):
  `ns.UF_SeedStock` sets `healthClassColored=false` and
  `customFillColor` = `ns.UF_CLASSIC_HEALTH_COLOR` (0,1,0) on every
  `ns.UF_TEXTURE_UNITS` frame once per profile (stamp `classicHealthSeeded`).
  The keys are in `ns.UF_StyleSlotKeys()` and `SLOT_KEYS.unitframes`; a
  profile already Classic banks its current colours into `_styleSlots.eui`
  first. Validator: `validate_classic_health.py`.
- Classic WoW UI power colours (Unit Frames 0.15, Options 0.90): every Unit
  Frames power colour read goes through `ns.UF_PowerColor(unit)` /
  `ns.UF_PowerInfo(token)`, which return the client's `PowerBarColor` under
  Classic only and EllesmereUI's palette otherwise. No settings change.

- Per-text outline (Core 0.50, Nameplates 0.13, Unit Frames 0.11, QoL 0.10,
  Options 0.86): `EllesmereUI.ApplyTextOutline(fs, path, size, mode, moduleKey)`
  in `EllesmereUI_Fonts.lua` maps module/none/outline/thick/shadow; "module"
  returns false so the caller keeps its own default. Keys: nameplates
  `<element>Outline` (cog dropdowns), Unit Frames `<slot>Outline` for
  left/right/center/extraText, btbLeft/Right/Center and powerPercent (38
  `SetFSFont` call sites, options cogs and preview), QoL `zoneTextOutline`
  (Blizzard zone strings, restored from their font object). Test:
  `validate_text_outline.py`. One-off patchers: `add_uf_text_outline.py`,
  `add_uf_preview_outline.py` (both idempotent).

- Action Bars 0.17: Custom Button Shape per bar (none, square, curved square,
  circle, portrait, diamond, hexagon, shield). Wrath has no mask textures: circle
  and portrait use `SetPortraitToTexture`; diamond, hexagon and shield crop the
  icon into horizontal strips cut from the mask rows (`SHAPE_ROWS`), with the icon
  as the first strip and the rest mirrored by hooks; square and curved square are
  outline only. The cooldown swipe is always square, so it shrinks to the
  inscribed square or the shape's `SHAPE_SWIPE` rectangle.
- Action Bars 0.18: Bars 7-10 on action pages 7-10 (slots 73-120), off by default,
  with bindings (`Bindings.xml`, 60 entries for bars 6-10), Unlock Mode and full
  Bar Display settings. Pages 7-10 are also stance/form pages for Warrior, Druid,
  Rogue (7) and Priest (7); `ns.PageShare` drives a warning in Bar Display unless
  Bar 1 has Disable Form Paging on.
- Core 0.48: the Incompatible Addon popup offers "Disable <addon>" and, where it
  applies, "Disable EUI <module>", then reloads (`ShowConfirmPopup` `extraButtons`).
- Blizz UI Enhanced 0.26: native dropdown panels inset to the visible box (ending
  at the arrow button); Raid Information uses its own inset instead of the Friends
  window's classic one.
- Earlier in this period: Arena module (pets, DR tracking, out-of-range fade),
  raid debuff highlight in Raid Frames, battleground capture bar and GM chat
  status skins, loot roll choices, QoL interrupt announce, auto-accept invites
  from guild and friends, disband raid.

## Waiting for in-game confirmation

Strip-cropped Diamond/Hexagon/Shield icons (possible seams at UI scales other
than 1), the conflict popup's disable buttons, Bars 7-10 and their keybinds (if
they are missing from Key Bindings after `/reload`, `Bindings.xml` may need a
client restart), the dropdown and Raid Information backgrounds, the per-text
outline dropdowns (Shadow rendering, Zone Text restore to Blizzard Default).

## Not ported (Wrath limits)

Masked button shapes: square and curved square stay outline only, and the swipe
stays square. Extra action bars cannot get their own slots on stance/form pages.

---

# Previous log — checkpoint 2026-10-01

Latest build: HUD-test-0.38. Friends 0.1 and Quest Tracker 0.1 added.
Options 0.43; Blizzard Skin 0.7; Core 0.28 and other runtimes unchanged.
Nineteen EUI addon folders; twenty selected release archives.

Friends styles Wrath's native social window and recycled friend rows with
readable outlined fonts, localized class colors/icons, background/scale settings
and exact native-style restoration. Native tabs, clicks, whisper/invite/context
actions and available Battle.net data remain native. Blizzard Skin yields only
FriendsFrame while this enabled module owns it, and resumes when disabled.

Quest Tracker styles Wrath WatchFrame while retaining native quest/achievement
lines, timers, map links, collapse controls and quest-item buttons. Settings
include readable fonts, content-sized background, scale/width/height, visibility
and Unlock Mode position. Optional auto-accept/turn-in helpers default off;
Shift skips them, reward choices and paid/material turn-ins stay manual. An
optional hotkey securely clicks the first visible native quest-item button;
rebinding and structural edits defer during combat. /efriends and /eqt open
their new settings. Profiles, style presets and global font settings integrate.
Retail sources/media remain byte-identical and unloaded; no external addon
dependency or external character data is used. Retail-only tracking/social
systems are not loaded or fabricated on Wrath.

Lua 5.1 checks pass for both real Lite lifecycles, combat login/deferred refresh,
native/recycled rows and clicks, fonts, state drivers, quest-item hotkeys,
positions/restoration, helper guards, Options pages, Blizzard Skin ownership
and private Options factory/input cleanup. Rendering and taint still need
in-game review. ACP's separate menu patch is not part of the EUI archives.

Previous checkpoint: HUD-test-0.37.

Latest build: HUD-test-0.37. Options 0.42. Core and all module versions
remain unchanged from 0.36; Quickdraw runtime remains 0.1.

Quickdraw Assign Key now opens a temporary hotkey capture dialog instead of
trying to bind a typed key string. It samples Ctrl/Alt/Shift on the first
non-modifier key press, shows the selected chord, and saves the binding when
that key is released. Bare modifiers and key repeats never become bindings.
Escape, Cancel/right-click, page teardown, closing Options, combat start,
focus transfer or a 20-second timeout always disable the dialog's keyboard
input and clear its event registration. Capture never uses keyboard propagation,
global Escape hooks or persistent keyboard handlers. Existing native binding
and secure Quickdraw hold/release behavior remains in place.

Lua 5.1 tests exercise actual capture scripts, modifier snapshots, repeat and
release handling, persistence, invalid bindings, ten Escape cycles, hide/page/
Options/combat/timeout/focus/cancel cleanup, and rearming after failure.
Quickdraw secure regressions, Options factory/focus and all active Lua compile
checks pass. Native in-game input and appearance still need client review.

Previous checkpoint: HUD-test-0.36.

Latest build: HUD-test-0.36. Options 0.41 / AuraBuff Reminders 0.1 /
Quickdraw 0.1. Core 0.28 and other module versions unchanged.

AuraBuff Reminders is independently implemented for Wrath: learned raid-buff
providers, group/single-rank name equivalence, reachable/alive member counts,
personal armor/aura/shield/pet reminders, flask/food/restock counts, weapon
enchant checks (excluding shields/frills), missing or expiring auras, manual
player/target/focus buff/debuff/own-caster filters, location-gated expected
talent spell reminders, sounds, dismissal, preview and Unlock Mode positions.
Click-to-cast/use overlays exist separately from the dynamic reminder display;
native state drivers hide them in combat. The read-only display can refresh
in combat without protected frame writes or allocation. Open /eabr or /ebr.
Settings pages: Auras, Buffs & Consumables / Custom Reminders / Talent Reminders.
Talent/zone assignments are manual, using native Wrath learned spells.

Quickdraw supports 16 numbered palettes, each with up to 20 actions. Hold its
key, point or scroll, release to execute; center/empty-space/no-motion cancels.
Escape cancels and removes temporary overrides. Ring/arc (span + rotation),
horizontal fan and grid layouts, cursor/screen positioning, size/opacity/fonts,
counts and cooldowns are configurable. Add spell/item IDs, named macros or
macro text, equipment sets, mounts/companions, raid markers and native micro
buttons; cursor pickup is supported. Bind through settings or native bindings.
Secure restricted click/wheel/cancel snippets work in combat without insecure
attribute writes. Combat edits and held-palette cache updates defer. Display
uses a snapshot matching the secure actions. /eqd opens settings.
Retail nested palettes, world markers and Retail collection APIs are not loaded.

All original Retail Lua and ABR sound files remain unchanged and unloaded.
Quickdraw's original XML is retained as Bindings_Retail.xml; native Bindings.xml
registers exactly 16 stable EUI_RADIAL action names and is not listed in the TOC.
No external addon runtime, data or libraries are needed by either new module.

Validated in Lua 5.1: real Core lifecycle, aura rank/group ownership/expiry,
reachable units, consumable/weapon checks, zone/talent reminders, sound dedup,
OOC secure casts and combat read-only updates, preview/dismiss/unlock/settings.
Quickdraw executes real source snippets in a restricted fixture enforcing
Wrath's no-function/no-table-creation parser rules, native owner frame refs,
combat mutation guards, release actions, arc/grid/fan/wheel/deadzone/no-motion,
modifier routing, repeated Escape cleanup, deferred edits, direct-slot cleanup,
native micro-button macros, keybindings and cursor assignments. 110 active Lua
files compile. CDM/memory, Damage Meters and private Options regressions pass.
Native rendering and real client secure execution still need in-game review.

Previous checkpoint: HUD-test-0.35.

Latest build: HUD-test-0.35. Core 0.28 / Options 0.40 / Cooldown Manager 0.1.
Other module versions unchanged.

Cooldown Manager now runs independently on Wrath, with cooldown, utility,
buff icon groups and tracking bars. Class defaults include learned spells,
equipped trinkets and player proc/buff auras. Manual spell/aura/item/equipment
assignments, unit/buff/debuff/own-caster filters, ordering/removal and per-dual-
talent-group storage are available in CDM Bars / Tracking Bars / Bar Glows.
Display controls include dimensions, growth, visibility, duration/stack/keybind
labels, opacity, outline, range tint, observed-GCD suppression, previews and
Unlock Mode positions. Native cooldowns follow the highest learned rank or
pet spellbook; permanent auras render without fake durations. Optional aura
triggers highlight owned EUI action buttons. Icons are tracking displays;
clicking opens settings. Retail rotation/talent-condition systems are not loaded.
All 11 original Retail Lua files remain unchanged as unloaded references.

The Options sidebar now shows Memory Usage for all loaded EllesmereUI-named
addons including the load-on-demand Options addon. Native memory accounting
is refreshed every five seconds while visible and displayed in MB. Disabled
addons and unrelated addons are excluded; no forced garbage collection.

Validated with actual Lite lifecycle in Lua 5.1: rank/passive/pet handling,
strict unit and caster aura ownership, permanent/expired auras, cooldown/GCD,
items/stacks, spec-list persistence, previews/unlock callbacks, manual settings,
action glows/keybinds and no combat UI allocation. Combined memory totals include
Options. 102 active Lua files compile. Existing theme/preset, private options
factory, Unit Frames and Damage Meters regressions pass. Native appearance and
real class spell coverage require client review.

Previous checkpoint: HUD-test-0.34.

Latest build: HUD-test-0.34. Damage Meters 0.3 / Options 0.39;
Core 0.27 and all other modules unchanged.

Hover an actor bar to see its top spells with native spell icons, amounts,
percentages and affected-target bars. Hidden entries are summed as Other,
so top-entry percentages remain accurate. Hover updates with live data and
is dismissed when the bar changes identity, hides or the view changes.
One native tooltip and its rows are preallocated; hover/combat refresh does
not allocate UI frames. The death metric shows the latest recap; threat
shows native target threat rather than invented spell attribution.

Left-click an actor to replace that same meter with the person's spell
breakdown. The footer switches Spells/Targets; Back restores the group.
Spell bars have icons and hover hit/crit/min/max information. Death focus
uses the recorded recap with a death selector. Mouse wheel scrolls focus
rows; live totals/percentages/rates update. Right-click retains the separate
statistics window. Report preview uses the current group or focused view;
only explicit Send sends chat, as before.

Focus is per-window transient state, excluded from saved profiles. Metric,
segment and profile changes clear it; missing-player data stays empty with
Back available. Reset clears focus and hover. Actor rows retain their class/
specialization icons. Existing window opacity/outline settings are preserved.
No external addon data, libraries or runtime is consulted.

Validated in Lua 5.1: 98 active files, real row OnEnter/OnClick/OnLeave,
native spell icons, exact actor percentages, combined Other totals, targets,
inline focus/back/footer/death recap, DPS including fractional bar scaling,
live updates and scrolling without frame allocation, row reorder/metric/
segment/profile/hide cleanup, focused reports and prior native collector,
history/specification/opacity/font/unlock/report regressions. Retail
reference files remain unchanged. Native rendering requires client review.

Previous checkpoint: HUD-test-0.33.

Latest build: HUD-test-0.33. Core 0.27 / Options 0.38 / Damage Meters 0.2;
all other modules unchanged.

Damage Meters > Windows now provides independent Background Opacity,
Bar Opacity and Header / Footer Opacity settings. Text does not fade with
the bars/background. Meter names/values default to OUTLINE with black
shadow, independent of the global EUI outline; a per-window dropdown
selects Outline, Thick Outline, None or the EUI font setting.

Specialization icons appear beside actor names. The player uses native
active talent-group information. Group members are inspected sequentially
out of combat with cooldown, timeout, GUID/token and inspection ownership
checks. Native Inspect UI takes priority; no shared inspection data is
cleared and no global native function is replaced. Class icons are the
fallback while talents are unknown/out of range. Existing known combat
segment specializations survive later talent switches; previously unknown
history entries are backfilled. No other addon cache/library is used.
The icon toggle, outline and opacity fields also migrate older extra windows.

Options theme art now occupies native BORDER above the permanent BACKGROUND
base on Wrath. Pixels accent and collapse-box strips/glyphs use higher
native layers. Retail texture sublevels cannot reliably order this art on
Wrath; instant switching alone in 0.32 did not fix the base occlusion.
Retail retains its original layering/crossfade.

Validated: 97 active Lua 5.1 files, actual Core/meter lifecycle, native
specialization groups/events, class fallback, historical icons, inspection
ownership/GUID changes/throttles/timeouts/combat/range/user-inspect guards,
independent opacity settings including zero, hover restoration, default
outline and black shadow. Real theme layer construction ignores sublevels
in the fixture; palette/art/overlay and prior Presets regressions pass.
Unit Frames and private options factory regressions pass. Native appearance
still requires client review.

Previous checkpoint: HUD-test-0.32.

Latest build: HUD-test-0.32. Core 0.26 / Options 0.37;
all other modules unchanged.

Options theme changes now apply the selected background and menu accent
together. Wrath switches the background/collapse-box layers immediately,
hides the outgoing art and clears the Pixels overlay without relying on
a crossfade ticker under a hidden or collapsed panel. The live background
handle follows the selected layer. Retail retains its animated transition.
Match Accent to Theme still controls theme versus independent profile color.

General combat damage/healing toggles and the periodic/pet damage cog now
read/write stock Wrath CombatDamage, CombatHealing,
CombatLogPeriodicSpells, PetMeleeDamage and PetSpellDamage. Retail v2 names
remain used on Retail. Existing combat restrictions and safe handling of
unavailable CVars are preserved.

Validated in Lua 5.1: real theme API/menu colors, every native TGA path,
visible background/collapse layers, rapid hidden-panel selections, Pixels
overlay removal and Retail transition; actual combat-text row/cog callbacks
against strict native and Retail CVar sets; independent toggles, combat
guard and unavailable CVars. Unit Frames, private options factory and
search/focus regressions pass. Native appearance requires client review.

Previous checkpoint: HUD-test-0.31.

Latest build: HUD-test-0.31. Damage Meters 0.1 / Options 0.36;
Core 0.25 and all other modules unchanged.

EllesmereUIDamageMeters now runs its own Wrath CLEU collector and saved
history. The installed Details main addon was examined as a reference;
there were no separate installed Details plugins. No Details runtime,
libraries, globals, saved data or copied parser are used. Retail EUI
sources/media remain unloaded and unchanged. Native combat collection
replaces Retail C_DamageMeter, which is not available on stock 3.3.5.

Two default windows (damage/healing), up to four, support damage/DPS,
healing/HPS, overheal/received healing, incoming/enemy/friendly damage,
absorbs received, blocks/resists/misses/avoidance, deaths/recaps, interrupts,
dispels, casts, resurrections, CC breaks, distinct power gains, buff/debuff
uptime and native current-target threat. Header selects metric, footer
selects current/last, overall or one of up to 30 saved segments; menus and
rows scroll. Left click opens spells, right click targets. R previews a
report; only the explicit Send button sends paced chat messages.

Open /edm or the Damage Meters sidebar. Windows move by header drag or
Unlock Mode; profiles and per-window display/visibility settings apply.
Combat history is per-character EllesmereUIDamageMetersHistory, separate
from exported UI profiles. Save History controls logout persistence.
Clearing data requires confirmation and is blocked during combat.

Absorbs belong to the recipient: no guessed shield caster/healing credit.
Aura uptime sums observed target-seconds and does not claim a universal
percentage. Resource types stay separate. DPS/HPS use encounter duration,
which freezes during the end grace; active group combat keeps collecting.
Overall refresh merges summaries; spell/target breakdowns merge on demand.
Rows are preallocated; native frame factory, Escape and game menus remain
untouched. Report inputs do not autofocus and clear focus on hide.

Validated: actual Lua 5.1 Core lifecycle with Details absent, eight-field
CLEU/spells/pets/statistics, recaps, aura timing/reconciliation, segments/
overall/rates/frozen duration, history reload/retention/disable, threat,
options/profile rebind/unlock/window pooling and explicit report flow.
Native client appearance and actual encounter totals require review.

Previous checkpoint: HUD-test-0.30.

Latest build: HUD-test-0.30. Core 0.25 / Options 0.35 / UnitFrames 0.8 /
RaidFrames 0.4; other modules unchanged.

Buffs/Debuffs pages share a non-secure header preview and indicator editor
for Raid Frames and Unit Frames. Click a preview spell or indicator list
entry to edit it. Positions, growth, size, offsets, stacks, duration/swipe,
opacity, border and manual spell assignments refresh the preview in place.
The whole preview layout scales to fit its canvas; live icon sizes do not.

Default buff indicators are healer assignments, personal defensives and
external active effects (3+2+2 icons). Other buffs start empty and must be
added manually. An explicit Wrath-only catalogue matches rank variants by
native localized spell name, without importing another addon's filters or
saved data. Externals may come from other casters even with the global Own
filter; indicator Own Only and global exclusions/hard constraints apply.
These indicators show active effect durations, not remote cooldown readiness.

Unit Frames > Buffs > Select Frame: Player > Use Indicator Layout enables
the new player display and hides only its previous aura row. Disabling the
mode restores the old row/settings. Buff/debuff and player/target/focus/boss
settings remain independent. Sixteen plain icons are preallocated per
unit frame (eight per aura type); aura events/expiry reuse this pool.
Raid/party and 10/25/40 settings are independent. The old automatic broad
Buff Icons default migrates to healing, retaining its visual edits; named,
manual and custom-filter indicators are retained.

Validated: real raid/UF lifecycle and registration, shared editor/preview,
all nine anchors and four growth directions compared to live raid layout,
rank matching/exclusions, external any-caster, healing Own Only, manual-only
ordinary buffs, selected-layout isolation, live player pools/expiration,
no combat allocations, old-row restore, header reuse/input/native-factory
safety and 217 Lua 5.1 files. Native rendering still needs client review.

Previous checkpoint: HUD-test-0.29.

HUD-test-0.29. Options 0.34 / BlizzardSkin 0.6;
Core 0.24 / Minimap 0.3 and all other modules unchanged.

User confirmed the 0.28 blocked-action warning was fixed, then reported
keyboard input locking after repeated Escape closes. The compatibility
EditBox probe had native autofocus after the global factory removal. All
probe widgets now live under a hidden input-disabled parent, are themselves
hidden/input-disabled, and the EditBox explicitly disables autofocus and
clears focus. Native frame creation remains unchanged; EUI search fields
retain click-to-focus and normal typing.

Glyphs no longer paint a second full-window panel over talents. The higher
glyph sheet fill is bounded to the body and has no duplicate accent/header;
shared tabs, portrait and close button remain visible. Talent-only content
is hidden while glyphs are active and its prior visibility restored when
leaving or disabling the skin. Native glyph socket art/clicks/tooltips and
native show/hide handlers remain intact. Combat defers skin writes.

Validated: probe visibility/focus/input across show/hide cycles, native
CreateFrame identity, actual search/widget behavior, six glyph sockets and
repeated talent/glyph switching, footer/body bounds, native callbacks,
inactive control restoration, skin disable/combat deferral/frame reuse,
existing currency/LFD/mail/quest/character skins and 215 Lua 5.1 files.
Client rendering and repeated Escape/input flow still need confirmation.

Previous checkpoint: HUD-test-0.28.

HUD-test-0.28. Core 0.24 / Options 0.33 / Minimap 0.3;
other modules unchanged.

Reported trigger: middle-click minimap menu > Spellbook or another native
window > Escape produced an EllesmereUIOptions blocked-action popup.
Options globally replaced CreateFrame; that adapter is now private and
bound only inside 18 active EUI options builders. Panel/global search use
it locally; UnitFrames retains its private Wrath frame adapter. Native
CreateFrame stays unchanged after options loads, and native EditBoxes no
longer receive EUI autofocus/OnHide modifications.

All minimap menu actions now use securecall for native named toggles or
native micro-button clicks, preserving disabled state, arguments and OOC
guards. Native close handlers, Escape bindings and blocked-action reports
are retained. Restart clears the previous session's existing taint.

Validated: unchanged native factory identity, template filtering/private
focus cleanup, idempotent compatibility loading, active builder bindings,
secure menu routes, Spellbook open/close, existing search/options access,
widget setters and 215 Lua 5.1 compilation/UnitFrames regressions. Native
client taint confirmation is still required for the exact reported flow.

Previous checkpoint: HUD-test-0.27.

HUD-test-0.27. Minimap 0.2 / QoL 0.2 / ActionBars 0.12 /
Options 0.32; Core and other modules unchanged.

Middle-click micro menu uses an EUI-owned native popup without EasyMenu.
Native window/button actions, optional entries, shared font/accent,
outside-click/Escape dismissal, combat close and exact disable restore
are covered by the real Lua 5.1 Core lifecycle regression.

QoL > Raid Tools now selects a 3-60 second pull duration (default 10).
Broadcast and chat countdown are independent toggles. Chat announces the
start duration, 10 and the final 5/4/3/2/1, then Pull!, choosing Raid Warning
when permitted, Raid otherwise, or Party. Solo countdown stays local.
Broadcast uses native DBMv4-PT, D4 PT and legacy BigWigs BWCustomBar Pull
formats, without requiring a boss mod here. Raid leader/assistant or party
leader permissions apply; recipient filters and throttles remain in force.
Legacy BigWigs displays a custom timer/finish alert; compatible later Pull
plugins have their own countdown UI. Cancel/early combat/disable/profile
and group transitions stop the local countdown without stale chat.

The original stance/pet controllers and bonus shell now have a hidden
parent while EUI handles the buttons and bonus paging. Blizzard Show/alpha
updates during stance changes cannot reveal duplicate native bar shells.
Their events stay registered. Disabling restores original appearance.

Validated: lifecycle/menu native actions and dismissal/theme, timer
scheduling/channel priority/packets/cancellation, actual installed DBM PT
receiver, secure stance/bonus shell suppression, button/paging/restore,
existing ActionBars/QoL and UnitFrames compile/regression checks. Native
rendering, taint and remote boss-mod sounds still need client confirmation.

Previous checkpoint: HUD-test-0.26.

HUD-test-0.26. DataBars 0.2 / Bags 0.7 / BlizzardSkin 0.5 /
RaidFrames 0.3 / Options 0.31; other versions unchanged.

DataBars initialization uses the captured addon reference with Lua 5.1
xpcall. The regression now runs the real Core loading/login dispatcher.
Mail quantities remain above skinned icons; dark quest/gossip text and
inline colors remain readable, including after native refresh. Actions,
empty counts and original appearance restoration are preserved.

Bags owns alt gold snapshots even when inventory is not yet ready. Saved
bags show the character balance; footer/broker hover includes each alt,
realm total and combined total, explicitly last recorded for offline alts.
Cached item subclasses support Crafting Reagents, Food & Drink, Potions,
Flasks & Elixirs and Other Consumables plus a view-only category filter.

Raid/party defaults to Tank > Healer > DPS within each subgroup. Hide DPS
Role Icons keeps all player frames visible. Role/name lists update outside
combat; membership changes in this sorting mode can wait until combat ends.
Unknown roles sort last. Name/Roster sorting remains selectable. Separate
Buffs/Debuffs pages offer independent indicators and filters, spell lists,
custom order, show-in raid/party, anchors/growth/offsets, sizes, opacity,
borders, duration swipe/text, stack counts and hide-icon options. Eight
preallocated icons per aura type are shared across indicators. Existing
group/layout profiles, aura filters and click casting are retained.

Validated: actual lifecycle, serialized SavedVariables across three
character/realm sessions, gold updates/tooltip/categories, native mail
stack layers/actions/restore, quest colors including inline codes,
secure header role ordering, icon hiding only, independent indicator
filters/options/render state, combat deferral and existing module checks.
215 Lua 5.1 files compile. Thirteen addon folders/fourteen release ZIPs
are current. Rendering and taint still require client confirmation.

Previous checkpoint: HUD-test-0.25.

HUD-test-0.25. DataBars 0.1 / Bags 0.6 / Options 0.30 /
ActionBars 0.11; other versions unchanged.

Added the requested EllesmereUIDataBars Retail folder as unchanged Lua/media
references with a native 3.3.5 TOC loading only EUI_DataBars_335.lua and
EUI_DataBars_335_Blocks.lua. /edb opens a single native settings page: bar
selection, four templates, CRUD, ordered blocks, horizontal/vertical layouts,
full-screen/custom length, equal/custom width weights, scale, fonts, opacity,
EUI accent/flat themes, border and secure combat/group visibility. A bottom
information bar is seeded once on a fresh profile. Every bar has its own Edit
Mode mover and profile position. Core profile refresh already invokes _EDB_Apply.

Twenty native block types: clock, FPS, latency, location, coordinates, gold,
bags, durability, combat, XP/reputation, talents/dual spec, primary/secondary
professions, hearthstone, micro menu, currency, equipped item-level average,
audio, EUI inventory broker and spacer. The travel action is a native secure
item button. Data comes from the client or EUI's own inventory namespace only;
no external addon data or dependency. Retail-only Crests/Great Vault/loot spec,
warbank, random hearthstones and arbitrary external broker plugins are absent.
Coordinates do not alter the user's map selection and can be unavailable;
currency/skill lists follow native expanded categories. Equipped iLvl is a
local average of occupied slots, not a Retail item-level API value.

ActionBars hides its own XP/reputation holder and Edit Mode entry while an
active DataBars block presents the same progress type. Its suppression of
native Blizzard bars is retained; removing/disabling the block restores the
configured ActionBars holder without changing saved preferences. The default
bottom template uses information blocks, leaving the existing progress bars.

Bags saved bank/alt item buttons remain read-only plain Buttons. They no
longer call CheckButton-only SetCheckedTexture; live item CheckButtons still
clear their checked texture. A stricter fixture reproduced the exact reported
line-109 failure before the fix. Cache, serialization/persistence, broker and
inventory/resource tests now pass with native button types enforced.

DataBars tests execute actual Lite/module/options code and verify all block
values/actions, secure hearthstone, state drivers, combat deferral, profile
replacement, frame reuse, layout bounds/vertical, positions, option writes,
source byte integrity and native TOC. ActionBars regressions include progress
handoff/fallback. 215 Lua 5.1 files compile. Thirteen addon folders/fourteen
release archives are current; project pack excludes player data. Native
rendering, input and taint confirmation still require the in-game test.

Previous checkpoint: HUD-test-0.24. Bags 0.5 / Options 0.29 / ActionBars 0.10;
other versions unchanged.

User reported inventory not storing and explicitly removed authorization to
use other addons' data. All external import functions/options/optional deps
are removed. Inventory is now EllesmereUIInventoryDB, an account SavedVariables
global owned by the Bags TOC, separate from Core/layout profiles. Legacy direct
EUI snapshots migrate once; externally sourced snapshots are excluded. The
actual existing EUI save file contained two direct characters, two bag snapshots
and two banks, confirming at least some earlier recording occurred; no precise
client failure cause is claimed. Startup with zero backpack/bank capacity no
longer replaces existing data. Pure-data recording runs every five seconds,
on native events and logout, even with windows closed/in combat. Bank reads
remain restricted to active banker sessions. Save Inventory & Reload UI gives
an explicit native serialization action; options include cache totals.

Player Buffs: the user requested downward growth within the screen. Aura row
offsets already used negative Y, but CENTER/BOTTOM holder anchors shifted the
top row upward as height changed. ActionBars 0.10 fixes the top-right corner
before resizing and persists a top anchor. Live Edit Mode dragging and combat
deferral remain intact; debuff layout is unchanged. The secure ActionBars/HUD
regression checks growth/shrink, position persistence and native behavior.

The broker object uses only the libraries bundled in EUI Core. Recording,
saved views and account persistence work without an external display or any
other inventory addon. Project pack no longer includes the external database
test reference; historical transition scripts are not to be rerun.

Validation includes separate Lua sessions with actual SavedVariables text
serialization and reloading for character/realm switching, direct bank/stack
records, startup-empty preservation, periodic/combat capture, explicit reload,
old direct-data migration, Core/profile replacement independence and absent
external addons. Bundled LDB, inventory/resource, account-cache checks and
193 Lua 5.1 compilation pass. Twelve addon folders/thirteen archives verified;
client persistence/display confirmation pending. Old archives retained.

Previous checkpoint: HUD-test-0.23. Bags 0.4 / Options 0.28; other versions unchanged.
The following external integration has been superseded and removed in 0.24.

User requested DataBroker like Bagnon for cross-alt inventory. The installed
Bagnon version uses Bagnon Forever for persistence; LDB is its display/plugin
interface. EUI now publishes "EllesmereUI Bags" through the real Core LDB
library: free/total slot text, left-click inventory, right-click saved bank,
per-character bag/bank totals in tooltip, GetCharacters/GetInventory copied
data for consumers. Persistence remains EllesmereUIDB.wrathInventoryCache,
independent of layout profiles and optional display addons.

Use Bagnon Saved Data defaults on; Import Bagnon Alt Data syncs available
BagnonForeverDB records when Bagnon_Forever is loaded (optional dependency).
Import handles realm/name isolation, negative bank/keyring indices, equipped
bag headers, purchased slots, short/full item variants, stack counts and money.
Uncached item IDs/counts remain present and icons hydrate on item-cache retry.
Imported views identify unknown original save time. Purchased slot metadata
alone does not fabricate bank contents. EUI direct snapshots always win; only
missing or previously imported snapshots refresh. Bagnon data is not modified
or force-loaded. Imported snapshots remain usable after Bagnon is disabled.
EUI's own recording does not require Bagnon or a broker display.

Validation: validate_bag_broker.py executes actual LDB/CallbackHandler libraries
and installed Bagnon Forever access methods. Checks cover registration/change
events, clicks/tooltip, copied data APIs, provider format, realms/alts/stacks/
suffixes, uncached icons, immutable source, direct priority, unknown banks/time,
save/reload/profile survival, absent/late provider and native options. Inventory,
resource and account-cache regressions pass; 193 Lua 5.1 files compile. Client
confirmation pending. Twelve addon folders/thirteen release archives plus the
updated project pack are verified. Project pack includes Bagnon_Forever/db.lua
as a narrow test reference; player SavedVariables are excluded.

Previous checkpoint: HUD-test-0.22. Bags 0.3; other versions unchanged.

User reported missing item stack information. Wrath ItemButtonTemplate Count
starts hidden; setting its text did not reveal live bag/bank quantities. The
renderer now shows counts above one, hides single/empty counts and promotes
white stack text to OVERLAY. The label is stored as stackCount separately from
the native numeric button.count expected by item/refund handlers. Saved bank
and alt views follow the same visibility rule; existing count font settings
still apply.

Validation: the legacy fixture models the native hidden Count region and its
BORDER layer. Visibility regression failed before the correction and passes
afterward. Inventory/resource and cache checks cover live counts, stack changes,
empty/single slots, saved bank/alts, numeric count metadata and Global Fonts.
All 192 Lua 5.1 sources compile. Build archives and project pack are verified;
client display confirmation pending. Older archives retained.

Native references: https://github.com/wowgaming/3.3.5-interface-files/blob/main/ItemButtonTemplate.xml
and https://github.com/wowgaming/3.3.5-interface-files/blob/main/ItemButtonTemplate.lua

Previous checkpoint: HUD-test-0.21. Core 0.23 / Options 0.27 / Bags 0.2 /
ActionBars 0.9. Other module versions are unchanged.

Inventory and bank now include bag-equipment slot strips with capacities,
click filters, native item drop/bag pickup and confirmed bank-slot purchases.
Bank opens the current character's last saved bank away from a banker;
Characters selects saved bag/bank contents for alts across realms. Saved items
use separate plain buttons with no native item-action handlers. Search, bag
filters, saved timestamps and cross-character item counts work on snapshots.
Unknown bank contents are identified instead of reported as an empty bank.

Account snapshots live in EllesmereUIDB.wrathInventoryCache outside layout
profiles. Bags record even while closed/in combat; bank reads occur only in
an active bank session. Each alt must be logged into, and its bank visited,
to populate the cache. Normal game logout/reload persists SavedVariables.
The project pack contains code, not player inventory data.

Action Bars > Select Bar > Bag Bar > Consolidate Bags reduces the HUD strip
to one native backpack button opening the unified inventory. It preserves
the interior bag-slot strips, native events/scripts and full-strip restoration;
changes made during combat wait until combat ends.

Validation: validate_bag_cache.py covers native slot IDs/drop/pickup/purchase,
saved banks away from bankers, realm/alt isolation, stale removal, closed-window
and combat recording, read-only pools, search/counts, profile/reset/reload
persistence, selector/options and exact bank-session/native restoration.
Inventory/resource and secure ActionBars/HUD regressions pass, as do Raid/QoL
regressions and compilation of 192 Lua 5.1 files. Client rendering/input and
real logout/relogin persistence still require user confirmation. Twelve addon
folders/thirteen release archives are saved and verified against installed
sources with SHA-256. Older archives retained.

Previous checkpoint: HUD-test-0.20. Core 0.23 / Options 0.26 / BlizzardSkin 0.4.
User confirmed its currency, dungeon rewards, talent icons and tab skins look
good in the client; project-0.20 was saved and verified.

Other module versions are unchanged, including Raid Frames 0.2.

User reported unreadable Currency rows, missing random-dungeon reward icons,
missing talent icons, overlapping talent tabs and asked to check other tab
indicators. Shared skin fills now use an owned BACKGROUND texture on the
native owner; the child panel draws only borders. This prevents filled child
frames covering native icons/text when frame levels change. Native icons
are promoted to ARTWORK, including iconTexture/IconTexture fields, with
original layer/sublevel/coords restored when disabled. Currency uses native
sheet dimensions and header while PaperDoll is hidden; the expanded character
layout returns only on its own tab. Native Currency/LFD refresh functions and
TokenFrameContainer.update get guarded hooks even after delayed addon loading.

Talent footer tabs measure labels, pack with 6px gaps and retain IDs/native
clicks/selection. The point bar stays above the tab rows. Native geometry
restores on disable. Other native footer/header tab panels respect 10px
transparent margins rather than drawing over adjacent selection indicators;
FriendsTabHeader is recognized. Other tabs retain their native geometry/input.

Validation: validate_skin_content.py covers Currency sizing/text/icons,
LFD icons/tooltips/late refresh, talent icons/clicks/tab spacing, seven native
window tab strips (Merchant/Friends/GuildBank/Auction/Inspect/Achievement/
Options), selection state, combat deferral, native restoration and reuse.
Full BlizzardSkin/character-sheet checks and compilation of all 191 Lua 5.1
sources pass. Tests model native API contracts; in-game rendering still needs
confirmation. Thirteen current archives match the installed source and are
recorded with SHA-256 in the current manifest. Older archives retained.

Previous checkpoint: HUD-test-0.19. Core 0.23 / Options 0.26 / Raid Frames 0.2.
Other module versions are unchanged.

Raid Frames now saves independent 10-, 25- and 40-player layouts, including
dimensions, appearance, aura/filter settings and Unlock positions. Raid >
RAID LAYOUTS separates Use Raid Layout (Automatic or forced size) from Edit
Raid Layout (which size to configure). Automatic chooses native instance
capacity first, otherwise roster size; outside raids it uses 40. Nonsecure
preview outside a raid follows the edited size. Global Fonts, Textures and
Aura Filters also expose the layout selector. Migration copies the previous
raid settings, filter tables and position independently to all three layouts.
The old raid table remains a migration source, not the live runtime profile.

Show Group 1–2 / 1–5 / 1–8 toggles hide individual subgroups per layout.
Remaining headers pack without gaps and preserve their native groupFilter
and group labels. Group Limit still caps the last subgroup; showing a group
raises that limit as needed. All hidden means the raid holder and mover hide.
Native roster assignment remains with secure headers. Layout/visibility/size
switches during combat defer until PLAYER_REGEN_ENABLED. Roster/zone events
and the existing native poll detect automatic layout changes.

Validation: actual Lua 5.1 runtime/options tests cover 10/25/40 thresholds,
underfilled instance capacity, manual override, hidden-group compaction and
all-hidden state, combat roster/visibility deferral, legacy migration without
shared filter tables, separate positions, inactive-layout editing, preview,
and Global Fonts/Textures/filter isolation. All 191 Lua sources compile;
UnitFrames, nameplate GUID/channel/aura filters and Bags/Resource Bars shared
option regressions pass. Thirteen current archives are checked against the
installed source and recorded in the SHA-256 manifest. In-game secure behavior
and appearance still require client confirmation. Older archives retained.

Previous checkpoint: HUD-test-0.18. Core 0.23 / Options 0.25 / Raid Frames 0.1.
Other module versions are unchanged.

Raid Frames: native secure raid and party headers with 45 preallocated unit
buttons, separate layouts, class colors, health/power, range, threat, roles,
leader/raid markers, ready checks, vehicles and offline/dead/AFK status.
Native headers own membership and sorting; layout and click-binding edits
defer until combat ends. Aura icons follow each member independently of target
selection, retain click-through behavior and support native tooltips, timers,
stacks, dispellable rules and separate raid/party tracked/excluded ID filters.
Click casting is opt-in with modifiers and mouse buttons 1–5; default target
and native unit menu remain. Clique registration is available. Native party
frames preserve scripts/events and restore their original parent/positions
when the replacement is disabled. Other group addons and native raid pullouts
are not modified. Preview uses independent nonsecure buttons and does not
cover live groups. Unlock movers, central profiles, Global Fonts and Textures
use the live native settings. /erf and /rf open the four options pages.

Retail sources remain unchanged, unloaded. Converted roles/textures are
independent native TGA assets. Unsupported Retail private-aura, prediction,
portrait and advanced manager controls are not exposed. Other preset menus
remain available; the unsupported Retail raid style selector is omitted.

Validation: 191 Lua 5.1 sources compile. Actual native Raid Frames runtime and
options builders pass explicit Wrath contract tests for roster/subgroup/GUID
changes, aura ownership/removal/expiry, vehicles, secure combat deferral,
click bindings, range/status/ready checks, preview, native restoration,
profiles and movers. Shared UnitFrames, nameplate GUID/aura filters,
themes/presets, Bags/Resource Bars and QoL regression checks pass.
The contract fixture does not replace in-game native secure/rendering checks.
Current build contains twelve addon folders and thirteen archives including
the bundle; the current manifest verifies every ZIP member and SHA-256 hash.
Older archives remain after the prior approval-review deletion block.

Previous checkpoint: HUD-test-0.17. Core 0.23 / Options 0.24 / ActionBars 0.8 /
Nameplates 0.6 / Quality of Life 0.1. Other module versions are unchanged.

User confirmed plate identity is now correct and asked for DEBUFF indicators
to persist after deselection. Nameplates refreshes LibAuraInfo directly from
an identified unit's native aura list before the target/mouseover token is
lost. This learns unknown spell IDs/durations independently of library event
ordering. Cached debuffs stay on that verified visible plate and clear on
removal, expiry, death or frame hide/reuse. No name-only mapping is restored.
The new regression fails against the previous 0.5 archive and passes with 0.6.

ActionBars: Bar 1 could be covered by the retained invisible native MainMenuBar
art containers. Disable their mouse surfaces while EUI bars are enabled;
restore the saved mouse state on disable. Native micro/bag children keep their
click/drop handlers. Actual LAB secure drag/drop/paging/lock tests pass.
In-game confirmation of the reported Bar 1 drop problem is still required.

QoL: new native runtime and five pages (QoL, Cursor, Shifter, Raid Tools,
Logging). Supports merchant repair/junk, quick loot, trainer button, delete
text, cinematic/error/tutorial toggles, FPS/stats/coords/crosshair/durability,
combat/death alerts, player cooldown/lockout displays, cursor, window dragging,
secure target markers/ready check/local pull countdown and instance logging.
Automation and overlays start opt-in. Core profile refresh now reapplies QoL;
Global Fonts edits the native profile. Native overlays and raid tools have
Unlock movers. /eqol and /qol open the module. Retail originals are preserved,
unloaded; no modern shared battle-res charges/Mythic+ upgrade/key tools are
emulated. Cursor textures have separate power-of-two bottom-origin copies.

Validation: QoL native Lua 5.1 lifecycle, automation gates/ownership/restore,
logging, live spell/aura tuples, timers/cursor, protected-frame combat guards,
profiles/movers/options/global fonts and Retail byte integrity passed.
Nameplates + real GUID cache/filter tests, ActionBars + native HUD tests and
compilation of all 178 Lua sources passed. ZIPs are checked against every
installed source member and hashed in ELLESMEREUI_335_CURRENT_BUILD.json.
Current build has eleven modules and twelve archives including the bundle.
Visual appearance and native secure behavior still need client confirmation.

Workspace: D:/Jogo/Whitemane/Games/FrostmourneRebuffed/Interface/AddOns.

Previous correction: Nameplates 0.5, HUD-test-0.16. User reported debuffs also
appearing on nearby nameplates. Removed the 0.4 name/GUID cache shortcut:
a single visible same-name plate cannot prove it is the combat-log recipient,
particularly after the affected plate hides or the native frame is reused.
Auras now require GUID observation through native target selection/mouseover;
verified GUIDs stay with that plate only for its visible lifetime. Unknown
plates stay empty until observed. No name-only aura lookup remains.
A freshly observed GUID has one plate owner; previous owners clear immediately.
If selection alpha lags a conflicting native mouseover highlight, mouseover
wins and the alpha candidate is unbound. Duplicate retained GUIDs are rejected;
missing GUIDs cannot authorize native aura rendering. Aura filters unchanged.

Validation: validate_channel_aura_filters.py reproduces the name-copy bug when
run against the previous Nameplates 0.4 ZIP and passes with installed 0.5.
Covers nearby same-name plates, original plate disappearing, reuse, two separately
observed same-name units with different debuffs, independent removal, cache
updates after target changes, and one-GUID/one-owner target-alpha transitions.
Nameplates lifecycle/options and Lua 5.1 syntax checks pass. In-game visual
confirmation pending. Current manifest identifies the 11 current archives.
Older ZIPs retained following earlier approval-review deletion block.



Previous checkpoint: HUD-test-0.15. Core 0.22 / Options 0.23 / UnitFrames 0.7 /
Nameplates 0.4 / ResourceBars 0.2. User clarified BOTH castbars have animation
and channel tick problems, then added non-target nameplate debuffs and filters.
Cast/GCD fill now updates every render frame; UF fill/text/expiry share one
engine driver, without the generic shim's competing OnUpdate. Known Wrath
channels use localized counts from the provided ElvUI channel catalogue, native
haste endpoints, and fixed initial pulse intervals through pushback. Penance
accounts for the initial pulse; unknown spells get no invented timing.
Show Channel Ticks defaults on: /erb > Bars > Player Cast Bar; /euf > Main
Frames > CAST BAR. Resource preview timer cache stays consistent.

Nameplates now bundles unchanged local ElvUI Libraries/LibAuraInfo-1.0 by
Cyprias (major LibAuraInfo-1.0-ElvUI revision 19) and spellIdData.lua. LibStub/
CallbackHandler are already in Core; ElvUI need not be enabled. Native Wrath
combat log tracks aura apply/refresh/dose/remove/death, native UnitAura learns
unknown IDs/durations. Verified plate GUIDs remain while visible after changing
target; unique active name/GUID pairs can identify anonymous plates. Inferred
mappings immediately invalidate on ambiguity. Identical-name packs require
target/mouseover first. Hide/reuse discards identity. Cached duration can be an
estimate; combat log does not provide native Stealable metadata.

New Aura Filters pages in /euf and /enp: all/own/tracked, tracked/excluded spell
IDs, timed-only, stealable buffs and reset. UF player/target/focus/boss filters
stay separate. Tracked IDs supplement own mode; exclusions win; own includes
pet/vehicle. Includes/excludes use existing tables and per-ID caster scoping.
Invalid IDs preserve existing lists. Display/layout toggles stay on old pages.

Validation: 163 Lua sources compile with Lua 5.1. UnitFrames and inventory/
resources checks cover .016s progression, tick pooling/toggle/stop/expiry,
Penance/pushback and native aura render filters. New
validate_channel_aura_filters.py loads real LibStub/CallbackHandler/LibAuraInfo,
uses native hex GUID/raw combat payloads, and checks never-selected plate auras,
refresh/stacks/removal/expiry/pet ownership/ambiguity/recycling and both actual
filter page builders with UF per-frame isolation. Rendering/taint in-game pending.
Earlier HUD-test-0.14 and old individual ZIPs retained after prior approval
review deletion block; use manifest. No deletion workaround.


User confirmed “Great so far so good” after the duplicate Buffs Edit Mode
overlay fix, then requested deleting old build files and saving the current build.
That combination was confirmed; Core 0.16 adds the requested Esc/Options access
and awaits in-game confirmation. UnitFrames 0.6 fixes the reported Blizzard
level font initialization error and also awaits in-game confirmation.
This is not a claim of complete coverage.
Core 0.17 fixes the two reported Unlock tutorial/tooltip issues; visual
confirmation pending. User explicitly resumed Presets; implemented in Options 0.21.
Latest: BlizzardSkin 0.3 fixes overlapping Character tabs and implements the
requested expanded reference-style Wrath paper doll. In-game visuals pending.
Latest: Core 0.19 / Options 0.21 restore the Presets style picker, repair all
Options theme textures and add the user's Lich King theme with icy-blue accents.
Native spell-ID tooltips now work through the existing Developer option.
Core 0.20 fixes both search fields being impossible to type into. User clarified
"Cannot type"; ReleaseWrathPanelKeyboard disabled every descendant's keyboard,
including native EditBoxes, on panel show/hide. Now EditBoxes clear focus and
keep keyboard enabled; ordinary keybind capture frames stay disabled until armed.
validate_search.py reproduced failure before fix, passes after: cleanup/reopen,
real typing/debounce/Escape/Enter handlers, current-page filtering/restoration,
feature popup/unvisited-page indexing/result navigation and hook idempotence.

| Addon | Version |
| --- | --- |
| EllesmereUI | 3.3.5-core-0.25 |
| EllesmereUIOptions | 9.3.4-335-0.35 |
| EllesmereUIUnitFrames | 9.3.4-335-0.8 |
| EllesmereUIMinimap | 9.3.4-335-0.3 |
| EllesmereUIActionBars | 9.3.4-335-0.12 |
| EllesmereUIChat | 9.3.4-335-0.3 |
| EllesmereUINameplates | 9.3.4-335-0.6 |
| EllesmereUIBlizzardSkin | 9.3.4-335-0.6 |
| EllesmereUIBags | 9.3.4-335-0.7 |
| EllesmereUIResourceBars | 9.3.4-335-0.2 |
| EllesmereUIQoL | 9.3.4-335-0.2 |
| EllesmereUIRaidFrames | 9.3.4-335-0.4 |
| EllesmereUIDataBars | 9.3.4-335-0.2 |

Full build: EllesmereUI-3.3.5-HUD-test-0.30.zip. Keep it together with the thirteen
current individual ZIPs. ELLESMEREUI_335_CURRENT_BUILD.json records exact
archive sizes and SHA-256 hashes. Older EllesmereUI ZIPs were removed by the
user's explicit request; historical “preserve old ZIP” notes are superseded.
Installed source, backport-tools and .codex-tools are preserved. Unrelated addon
files are outside this checkpoint's cleanup scope. After building Core 0.16,
automatic approval review blocked Remove-Item for the superseded Core 0.15 and
HUD-test-0.7 ZIPs (reason: “blocked by policy”); these two archives remain.
Superseded UnitFrames 0.5 and HUD-test-0.8 archives are also retained; no removal
workaround was attempted after that policy block. Use the manifest for current ZIPs.
Core 0.16/HUD-test-0.9 also remain after the next build; no deletion retry.
Core 0.17/Options 0.19/BlizzardSkin 0.2/HUD-test-0.10 remain after this build;
no deletion workaround. Current archives are exactly those in the manifest.
Core 0.18/Options 0.20/HUD-test-0.11 also remain after this build; no retry.
Core 0.19/HUD-test-0.12 remain after the search fix; no deletion retry.
Core 0.20/Options 0.21/HUD-test-0.13 remain after this build; no deletion retry.

Latest: user added Bags, then ResourceBars during Bags implementation. Both
are included; in-game confirmation pending. Retail sources are read-only and
copied originals are byte-identical except replacement TOCs. Only the new
EUI_Bags_335.lua and EUI_ResourceBars_335.lua adapters load.

Bags 0.1: unified player bags/keyring/bank; scrollable grid, live search dimming,
category/name view sorting (no physical moves), quality/count/ilvl/lock/cooldown
display. Native template item actions retain parent bag ID and button slot ID.
Bank reads require a server bank session; native BankFrame is temporarily
moved/alpha-hidden rather than Hide(), which would close the session. Native
Bank button restores purchases/bank bag management. Drag positions and visible
window Edit Mode movers supported. /ebags toggles inventory; EUI > Bags settings.

ResourceBars 0.1: health/power, Rogue/Cat combo points, six DK runes, Shaman
totems, optional player cast/channel and native 61304 GCD. Health/cast default
off; unsupported resources stay hidden. Native cast alpha is suppressed/restored;
UnitFrames' cast remains separately configured. Automatic Edit Mode previews,
independent movers, /erb, one Bars page with bar selector, global Fonts/Textures
live writes and 15 TGA fills. Retail styles/advanced helpers stay unloaded.
Core 0.21 adds Bags profile refresh; Options 0.22 adds native module pages and
guards unsupported Retail styles/labels and fixes the texture page deep link.

validate_inventory_resources.py executes real Core Lite/safecall in Lua 5.1.
Checks: native slot actions, search, pools, scrolling, cache retry, bank session/
restore/fallback, combat, positions, Warrior/Rogue/Cat/DK/Shaman resources,
casts/channels/delay/stale-stop/GCD expiry/native cast restore, all selector
pages, and real Global Fonts/Textures tile setters. 158 Lua files compile;
UnitFrames, Presets/themes and search regressions pass. Native taint and
in-game visuals/interactions still require testing.

Recent changes: ElvUI Norm XP/reputation skin (blue XP, purple rested, dark
empty background); reversible Blizzard bar art toggle; one /eab panel selecting
14 action/HUD/aura groups with independent layout/position controls. Corrected
Texture vs Frame snapshot APIs, font-before-text ordering, and Core method self
arguments. Chat 0.3 removes the native 50px bottom clamp margin to allow Y=0.
Core 0.15 removes read-only Buffs/Debuffs Edit Mode overlays when the real Player
Buffs/Player Debuffs mover owns that group, with native fallback when disabled.
Core 0.16 adds a native Esc menu EllesmereUI button and Interface/AddOns category
with Open EllesmereUI; click-only LOD load, combat guard and coexistence with
other addons' menu anchors. EUI_OptionsAccess_335.lua is loaded from the Core TOC.
UnitFrames 0.6 guards the optional GameNormalNumberFont and sets the selected
module font (native fallback if rejected) before Blizzard level SetText during
first layout. Later passes preserve name font inheritance and custom level size.
Core 0.17 shows Unlock sidebar guidance only on hover, anchored to the right,
with immediate leave/hide/click dismissal; automatic first-open tutorial skips
Wrath. Edit Mode's Okay label gets explicit font/bounds/alpha and button layering;
click stops fade, hides the tutorial and saves unlockTipSeen.
BlizzardSkin 0.3 adds EUI_CharacterSheet_335.lua after the skin adapter TOC entry.
Expanded 660x580 sheet, larger native model, square native slots around it,
per-item ilvl and equipped average (17 combat slots; two-hand fills empty offhand).
Native UpdatePaperdollStats/PaperDollStatTooltip drive named stat rows in a
collapsible/scrollable sidebar. Native Titles/Equipment actions retained.
Character tabs get measured widths/gaps/pet visibility/wrapped footer rows.
Timed bounded visible cache retry replaces nonexistent GET_ITEM_INFO_RECEIVED.
Toggle off restores geometry, alpha, visibility, UIPanel width and title parent;
skin off also restores tabs; combat changes defer and frames are reused.
Options 0.20 adds /ebs > Blizzard Window Skins > CHARACTER ENHANCEMENT toggles.
Core 0.18 only adds these two account keys to the optional skin export/import bundle.

Resumed Presets: the user explicitly requested resumption. The proposal in
backport-tools/paused-presets-navigation.patch is now applied (do not reapply).
Profiles > Presets / UI Style Presets open the existing in-game style builder;
Wrath no longer intercepts SelectPage with the absent Retail VideoGuides popup.
Hidden indexing and page-cache restore use the same style builder/cleanup.
Real card clicks tested for eui/blizzard/classic: profiles stay unchanged until
reload confirmation. Supported Wrath surfaces are UnitFrames/player auras and
Minimap; unsupported Retail style rows remain excluded/disabled as before.

Themes: all original PNGs remain untouched. prepare_theme_textures.py generates
uncompressed RGBA 1024x1024 TGA copies in media/backgrounds_335, rescaling the
whole canvas so normalized texture cuts stay aligned. Includes base/shadow,
Pixels accent overlay, and the user's eui-bg-lichking.png. Collapse/expand icon
gets a 32x32 TGA copy in media/icons_335. Wrath-only theme map rewrites occur
before preload and exports; native close-box specs copied to native paths.
Lich King is a native-color background with accent #5CC3EB. Global Settings >
General > DISPLAY has Match Accent to Theme (Wrath default on): resolver uses
selected palette for menu highlights/borders/tabs without rewriting saved
profile colors. Off restores profile custom/class accent; selecting a swatch
turns matching off. Login fallback/live resolution agree; reset clears override.
validate_themes_presets.py executes dropdown/matching, preload/crossfade,
tint, actual Presets registration/navigation/cards/switches/cache/prebuild.

Spell IDs: EUI_TooltipIDs_335.lua is TOC-loaded with the Core. Reuses saved
showSpellID / spellIDModifier and Global Settings > General > DEVELOPER >
Show Spell ID on Tooltip (kept reachable on Wrath). Native OnTooltipSetSpell,
SetSpellByID/SetAction/SetHyperlink/SetUnitBuff/SetUnitDebuff/SetUnitAura hooks
add one Spell ID line to GameTooltip/ItemRefTooltip. Wrath aura return 11,
macro resolved spell link, tooltip-clear reset, other-addon dedup and modifiers.
No Retail TooltipDataProcessor or unsupported aura-ID CVar is used on Wrath.
validate_tooltip_ids.py exercises real native hooks/IDs/toggles/modifiers/dedup.
Themes, Presets and spell IDs still await in-game visual confirmation.

Read ELLESMEREUI_335_BACKPORT_STATUS.md and each module README-335.md for history
and limits. Retail files at D:/World of Warcraft/_retail_/Interface/AddOns were
read/copied only; preserve them. The original Downloads handoff remains unchanged.
Keep exact addon folder names inside ZIPs; versions belong in TOCs and ZIP names.
Preserve Options EditBox autofocus/focus cleanup; no fake keyboard propagation.
Avoid SetRotatesTexture on this Wrath client (prior native crash).

Python runtime:
C:/Users/Gaming/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe.
Lua 5.1 tests use Lupa in .codex-tools. validate_unitframes.py compiles all 140
Lua files and now tests unfonted Blizzard level creation for player/target/focus,
custom sizes, name inheritance, missing file fallback, level events, skull and
visibility; validate_actionbars.py uses real Core methods/overlay logic and LAB
secure snippets; validate_chat.py covers native chat contracts and Y=0. Other
focused validators are in backport-tools; validate_options_access.py verifies
the new menu/category/lazy-load/layout contracts. package_unitframes.py builds and checks
the current nine archives. Local tests do not reproduce native taint/rendering.
validate_character_sheet.py covers new character geometry/tabs/actions/native
stat row names, cache bounds, two-hand averages, scroll/collapse, combat and exact
restoration/reuse; executes real Core skin-key snapshot/import functions too.
validate_blizzardskin.py loads the new module and tests both new option controls.

Persistent user preference: after each completed code correction, close only
Wow processes whose executable path is
D:/Jogo/Whitemane/Games/FrostmourneRebuffed/Wow.exe, then start that executable
with FrostmourneRebuffed as working directory. Do not restart for archive cleanup.



- Restored pre-Gargul EUI state from test-addons-before-copy-20261007-021200: Chat 0.47 / Options 0.106. Later gold-seller changes reverted, earlier fixes retained.
