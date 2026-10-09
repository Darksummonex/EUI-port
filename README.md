# EllesmereUI for WoW 3.3.5a

A backport of **EllesmereUI**, the Retail UI suite by Ellesmere, to the **Wrath of the Lich King 3.3.5a client (build 12340)**.

Every module runs on native Wrath APIs (Lua 5.1). Retail looks and settings were ported wherever the 3.3.5a client supports them; Retail-only systems were left out or replaced with Wrath equivalents.

**[Download the latest release](https://github.com/Darksummonex/EUI-port/releases)**

> This is for **WoW 3.3.5a only**. It does not work on Retail, Classic or other private server versions.

## Installation

1. Download the latest `EllesmereUI-3.3.5-addons-*.zip` from [Releases](https://github.com/Darksummonex/EUI-port/releases).
2. Extract it into `World of Warcraft\Interface\AddOns`. The zip already contains the `EllesmereUI*` folders at its root.
3. Restart the game (not just `/reload`) and enable the modules you want on the character screen.
4. Type `/eui` in game to open the options.

`EllesmereUI` (Core) and `EllesmereUIOptions` are required. Every other module is optional.

## Modules

| Module | What it does |
|---|---|
| **Core** | Shared options panel, Unlock Mode, profiles, themes, fonts, colors, update notices |
| **Action Bars** | Retail-style action bars |
| **Arena** | Enemy arena frames |
| **Aura Buff Reminders** | Missing buff, consumable and talent reminders |
| **Bags** | Retail bags and bank window |
| **Blizz UI Enhanced** | Skins and upgrades for Blizzard windows and tooltips |
| **Chat** | Retail chat panel and spam filters |
| **Cooldown Manager** | Cooldown and buff tracking bars |
| **Damage Meters** | Built-in damage and healing meters |
| **DataBars** | Information bars with Wrath data blocks |
| **Friends List** | Retail friends list |
| **Locales** | Translations for the Wrath client languages |
| **Minimap** | Minimap shapes, borders and button flyout |
| **Nameplates** | Retail-style nameplates |
| **Quality of Life** | Automation, mail, merchant and display helpers |
| **Quest Tracker** | Retail-style quest tracker |
| **Quickdraw** | Radial action menus |
| **Raid Frames** | Party and raid frames |
| **Resource Bars** | Health, power, class resources, cast and swing bars |
| **Unit Frames** | Player, target, focus, party, boss and pet frames |

## Features

### Core and Options
- One options panel for every module, with search, live previews and per-element settings.
- **Unlock Mode** to move and resize every frame, with snapping and element options.
- Profiles with import/export, presets, settings overrides and a Lich King theme.
- Shared fonts, textures, sounds and colors, including everything registered with **LibSharedMedia**.
- Per-text outline styles: None, Outline, Thick Outline or Shadow.
- Spell IDs on tooltips, a memory readout and one-click addon conflict fixes.
- **Update notices**: tells you when a guild or group member runs a newer release (`/euiupdate` shows the download link).

### Unit Frames
- Retail aura lanes, combat indicator, portraits and indicator layout.
- Estimated **absorb shields** on health bars (Wrath has no absorb API, so shields are estimated from the combat log).
- Druid form power, threat display, pet happiness and a player dispel overlay.
- Boss frames that keep updating when the boss is not your target or focus.

### Raid Frames
- Party and raid frames with a Retail look, horizontal party layout and a 25-player preview.
- Raid debuffs, dispel highlights, ready check icons and out-of-range fade.
- Heal and resurrection prediction, absorb shields and **targeted spell** icons.

### Arena
- Enemy frames for arena1-5 with health, power and cast bars.
- Diminishing returns tracking, PvP trinket cooldown and crowd control icons.
- Enemy pet bars, out-of-range fade, unseen (stealthed) enemies and test frames.

### Nameplates
- Retail look with smooth cast bars, health number text and every Retail text choice.
- Live preview plate and SharedMedia bar textures.

### Action Bars
- Action bars 7 to 10, custom button shapes and short keybind text.
- Quick Keybind Mode and native HUD skins.

### Resource Bars
- Health, power, runes and combo points.
- Cast bar with spell queue latency overlay, GCD bar, **swing timer** and totem bars.

### Cooldown Manager
- Retail bar model with tracking bars, an add-spell menu and presets.
- Trinket internal cooldowns, bar glows, cooldown states and talent conditions.

### Aura Buff Reminders
- Class, raid buff and consumable reminders, talent reminders and custom reminders per character.
- Raid buff provider button and choices for where reminders show.

### Bags
- Retail bags and bank window with categories, physical sorting and a settings cog.
- Opens in combat; saved characters can be deleted.

### Chat
- Retail chat panel, idle fade, chat bubbles and a copy chat button.
- Spam filters with presets and keywords, a gold seller filter, a repeated message filter, a hardcore death filter and a hidden messages log.

### Blizz UI Enhanced
- Skins for many Blizzard windows (character sheet, mail, auction house, inspect, merchant, popups and more).
- Tooltip options with **GearScore** on tooltips, group roll choices and character sheet upgrades.

### Quality of Life
- Merchant: auto repair, auto sell junk, a Train All button and mouse-wheel page turning.
- Mail: Open All, shift-click to attach a whole category, and a **recipient list** with alts, guild members and recent names.
- Quick loot, auto open containers, accept invites from friends and guild, interrupt announce, disband group and a pull timer.
- Displays: FPS and latency with quality colors, secondary stats, crosshair, coordinates, target distance, zone text, alerts and trackers.

### DataBars, Minimap, Friends, Quest Tracker, Damage Meters, Quickdraw
- **DataBars**: Retail engine with 20 Wrath data blocks, latency colors and Retail tooltips.
- **Minimap**: shapes and borders, addon button flyout, classic style, text boxes and a friends online button.
- **Friends List**: Retail friends list with Blizzard and Classic styles.
- **Quest Tracker**: quest helpers, a quest item hotkey and accent styling, hidden in arenas.
- **Damage Meters**: Retail windows, hover breakdown, spell history, combat timer and shield absorbs counted in healing.
- **Quickdraw**: radial palettes, nested action menus and key capture.

## Slash commands

| Command | Action |
|---|---|
| `/eui` | Open the options |
| `/unlock` | Toggle Unlock Mode |
| `/euiupdate` | Show your installed release and the download link |
| `/earena test` | Show arena test frames |

## Reporting bugs

Open an [issue](https://github.com/Darksummonex/EUI-port/issues) with the error text (BugSack/BugGrabber output helps) and the module you were using.

## Credits

- **Ellesmere** and the original EllesmereUI staff: the original Retail addon, design and art.
- **Laraystiri**: the 3.3.5a backport.

This project is not affiliated with or endorsed by Blizzard Entertainment.

## License

[MIT](LICENSE) for the backport work.
