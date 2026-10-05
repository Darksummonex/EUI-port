# Resource Bars 3.3.5a — 0.1

Native Wrath resource displays with EllesmereUI fonts and flat bar textures.
Open EllesmereUI > Resource Bars, or /erb. Select a bar in the single Bars page.

- Player power: mana, rage, energy and runic power, using native power colors.
- Optional player health with a class-color toggle.
- Rogue/Druid Cat combo points; six DK runes with type colors/recharge timers.
- Shaman totem duration bars in native Fire/Earth/Water/Air order.
- Optional player cast/channel bar, spell icon, name and timer.
- Optional GCD bar using the native 61304 cooldown marker; ability cooldowns
  longer than 1.7 seconds are excluded.
- Six independent positions in Edit Mode, with automatic previews of enabled,
  class-supported bars. The panel also provides Preview/End Preview buttons.
- Global Fonts/Textures edit the same profile fields. Fifteen fill textures
  are supplied as Wrath-compatible power-of-two RGBA TGA assets.

Health and Cast Bar start disabled to avoid redundant displays in an existing
HUD. Enabling Cast Bar suppresses the native CastingBarFrame alpha and restores
its previous alpha when disabled. UnitFrames' own cast bar is configured separately.

Only EUI_ResourceBars_335.lua is loaded. Original Retail sources are preserved;
Retail secret-value APIs, modern spec mechanics, Forever/12.1 helpers and
swing-timer/threshold extensions are not loaded in this initial Wrath module.
Resource frames and settings are local-player displays, not group unit frames.

validate_inventory_resources.py exercises native power types, Rogue/Cat/DK/
Shaman resources, cast/channel/delayed/stale-stop events, GCD expiry, native
cast restoration, combat deferral, profiles, fonts/textures and mover callbacks.
In-game visuals, native taint and modified-client behavior still require testing.

0.2: cast/GCD fills update every render frame; class resource work keeps the
.05s throttle. Known Wrath channels show pulse separators by default. Toggle
Show Channel Ticks under Bars > Player Cast Bar. Native endpoints account for
haste; pushback retains initial pulse spacing; unknown spells get no invented
markers. Core EUI_ChannelTicks_335.lua is shared with UnitFrames.
