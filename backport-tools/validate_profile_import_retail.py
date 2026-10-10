"""Core: Retail / WoW Forever profile strings import only what the port supports
(EllesmereUI_ProfileImport_335.lua), port strings import unchanged.

Runs the adapter against mock live module profiles. When the decoded strings Alex
pasted are present (.codex-backups/profile-strings, written by
decode_profile_strings.py / compare_profile_strings.py) the real Retail string is
also run through it, with the port string's module data as the live profiles."""
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

core = root / 'EllesmereUI'
toc = [l.strip() for l in (core / 'EllesmereUI.toc').read_text(encoding='utf-8-sig').splitlines()
       if l.strip() and not l.startswith('#')]
assert toc.index('EllesmereUI_Profiles.lua') < toc.index('EllesmereUI_ProfileImport_335.lua')

profiles = (core / 'EllesmereUI_Profiles.lua').read_text(encoding='utf-8-sig')
stamp = profiles.split('function EllesmereUI.StampPayloadClient', 1)[1].split('\nend', 1)[0]
assert 'EllesmereUI.WRATH_PAYLOAD_CLIENT' in stamp
other = profiles.split('function EllesmereUI.PayloadFromOtherClient', 1)[1].split('\nend', 1)[0]
assert 'EllesmereUI.WrathPayloadIsForeign(payload)' in other
imp = profiles.split('function EllesmereUI.ImportProfile(', 1)[1]
i_canon = imp.index('CanonToLocal(payload.data.addons)')
i_adapt = imp.index('EllesmereUI.WrathAdaptForeignPayload(payload)')
i_media = imp.index('ReconcileImportedMedia(payload.data)')
assert i_canon < i_adapt < i_media

np_display = (root / 'EllesmereUINameplates/EUI_Nameplates_335_Display.lua').read_text(encoding='utf-8')
assert 'if targetScale>5 then targetScale=targetScale/100 end' in np_display
assert 'math.max(.5,math.min(2,targetScale))' in np_display
qol_raid = (root / 'EllesmereUIQoL/EUI_QoL_335_RaidTools.lua').read_text(encoding='utf-8')
assert 'if v<=5 then v=v*100 end' in qol_raid

src = (core / 'EllesmereUI_ProfileImport_335.lua').read_text(encoding='utf-8')
assert '\r\n' not in src

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
printed = {}
EllesmereUI = { Lite = { _dbRegistry = {} }, _unlockRegisteredElements = {},
    FONT_FILES = { Expressway = "Expressway.TTF" }, FONT_BLIZZARD = { ["Friz Quadrata"] = "x" } }
function EllesmereUI.Print(msg) printed[#printed + 1] = msg end
function EllesmereUI.IsScreenEdgeKey(k) return k == "EUI_ScreenTop" end
fontsDB = { global = "Expressway", outlineMode = "shadow", _styleSlots = { active = "eui" } }
function EllesmereUI.GetFontsDB() return fontsDB end
function Reset(live)
    EllesmereUI.Lite._dbRegistry = {}
    for folder, profile in pairs(live) do
        table.insert(EllesmereUI.Lite._dbRegistry, { folder = folder, profile = profile })
    end
    EllesmereUIDB = { activeProfile = "Default", profiles = { Default = { unlockLayout = {
        anchors = { targettarget = { target = "target", side = "RIGHT" } } } } },
        charSheetEnchantNames = true, inspectShowItemLevel = false }
    printed = {}
end
''')
lua.execute(src)
G = lua.globals()
E = G.EllesmereUI

# Client detection.
detect = lua.eval('''function(p) return EllesmereUI.WrathPayloadClient(p) end''')
mk = lua.eval('''function(kind)
    if kind == "stamped" then return { client = "wrath", data = { addons = { EllesmereUIActionBars = { bars = { MainBar = {} } } } } } end
    if kind == "forever" then return { client = "forever", data = {} } end
    if kind == "abport" then return { data = { addons = { EllesmereUIActionBars = { _abRetail = 1, bars = {} } } } } end
    if kind == "abretail" then return { data = { addons = { EllesmereUIActionBars = { bars = { MainBar = {} } } } } } end
    if kind == "dragon" then return { data = { addons = { EllesmereUIDragonRiding = {} } } } end
    if kind == "wspec" then return { data = { assignedSpecs = { 33011 } } } end
    if kind == "rspec" then return { data = { assignedSpecs = { 257 } } } end
    if kind == "npretail" then return { data = { addons = { EllesmereUINameplates = { healthBarHeight = 25 } } } } end
    if kind == "npport" then return { data = { addons = { EllesmereUINameplates = { width = 150, healthBarHeight = 25 } } } } end
    return { data = {} }
end''')
for kind, want in [('stamped', 'wrath'), ('forever', 'forever'), ('abport', 'wrath'), ('abretail', 'retail'),
                   ('dragon', 'retail'), ('wspec', 'wrath'), ('rspec', 'retail'), ('plain', 'wrath'),
                   ('npretail', 'retail'), ('npport', 'wrath')]:
    assert detect(mk(kind)) == want, (kind, detect(mk(kind)))

lua.execute(r'''
function Live()
    return {
        EllesmereUIActionBars = { enabled = true, bars = {
            bar1 = { borderSize = 1, barVisibility = "always", bgColor = { r = 0, g = 0, b = 0, a = .5 } },
            petBar = { borderSize = 1 } }, barPositions = {} },
        EllesmereUIQoL = { battleRes = false, cursor = { gcd = false, texture = "ring_thin", size = 27 },
            order = { "a", "b", "c" }, spells = { 1, 2 }, raidTools = { scale = 100 }, positions = {} },
        EllesmereUINameplates = { targetScale = 1, castScale = 100 },
        EllesmereUICooldownManager = { cdmBars = { bars = {
            { key = "cooldowns", growDirection = "RIGHT", iconSize = 36 },
            { key = "utility", growDirection = "RIGHT" } } }, positions = {} },
        EllesmereUIUnitFrames = { player = { width = 200, healthBarTexture = "fade" },
            positions = { player = { point = "CENTER", relPoint = "CENTER", x = 1, y = 1 } } },
        EllesmereUIRaidFrames = { positions = {}, healerMana = { mode = "none" } },
        EllesmereUIChat = { chat = { enabled = true } },
        EllesmereUIDamageMeters = { windows = { { name = "A" }, { name = "B" } } },
        EllesmereUIResourceBars = { gcdBar = { enabled = false } },
    }
end
function RetailPayload()
    return { version = 3, type = "full", data = {
        addons = {
            EllesmereUIActionBars = { enabled = false, bars = {
                MainBar = { borderSize = 2, borderThickness = "thin", bgColor = { a = 1 } },
                PetBar = { borderSize = 3 }, XPBar = { enabled = true } },
                barPositions = { MainBar = { point = "CENTER", relPoint = "CENTER", x = -20, y = -300 },
                    StanceBar = { point = "BOTTOM", x = 5, y = 6 }, XPBar = { point = "TOP", x = 1, y = 1 },
                    QueueStatus = { point = "CENTER", x = 9, y = 9 } } },
            EllesmereUIQoL = { battleRes = { enabled = true }, cursor = { gcd = { enabled = true }, texture = "ring_normal",
                size = "big", hex = "FFFFFF" }, order = { "c", "a", "b" }, spells = { 99, 98 },
                raidTools = { scale = 1.2 }, fpsPos = { point = "CENTER", relPoint = "CENTER", x = 0, y = -700 } },
            EllesmereUIRaidFrames = { unlockPos = { point = "CENTER", relPoint = "CENTER", x = 1, y = -500 },
                partyUnlockPos = { point = "CENTER", x = 0, y = -356 },
                healerMana = { unlockPos = { point = "CENTER", relPoint = "CENTER", x = -1600, y = -156 } } },
            EllesmereUIChat = { chat = { chatPosition = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = 50, y = 56 } } },
            EllesmereUIDamageMeters = { dm = { windows = { { position = { point = "CENTER", relPoint = "CENTER", x = 5, y = 6 } },
                { position = { point = "TOP", relPoint = "CENTER", x = 7, y = 8 } },
                { position = { point = "TOP", relPoint = "CENTER", x = 9, y = 9 } } } } },
            EllesmereUIResourceBars = { gcdBar = { unlockPos = { point = "CENTER", relPoint = "CENTER", x = 0, y = -78 } } },
            EllesmereUINameplates = { targetScale = 120, castScale = 90 },
            EllesmereUICooldownManager = { cdmBars = { bars = {
                { key = "cooldowns", growDirection = "CENTER", iconSize = 40 },
                { key = "focuskick", barType = "cooldowns" } } }, specProfiles = { x = 1 },
                cdmBarPositions = { cooldowns = { point = "RIGHT", relPoint = "CENTER", x = -394, y = -245, tgtx = 1 },
                    custom_13_16756_701 = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 } } },
            EllesmereUIUnitFrames = { player = { width = 230, healthBarTexture = "sm:Atrocity", housingHide = true },
                positions = { player = { point = "CENTER", relPoint = "CENTER", x = -300, y = -200 },
                    target = { point = "LEFT", relPoint = "CENTER", x = 300, y = -200 }, bogus = { point = 1 } } },
            EllesmereUIDragonRiding = { enabled = true },
            EllesmereUIMythicTimer = { enabled = true },
        },
        unlockLayout = {
            anchors = { playerCastbar = { target = "player", side = "BOTTOM" },
                CDM_custom_1 = { target = "player" }, player = { target = "RF_PartyFrames" },
                focus = { target = "EUI_ScreenTop" } },
            widthMatch = { playerCastbar = "player", ERB_ClassResource = "CDM_cooldowns" },
            widthMatchExtra = { playerCastbar = 2, ERB_ClassResource = 4 },
            heightMatch = {}, phantomBounds = { player = { w = 1 }, CDM_custom_1 = { w = 2 } },
        },
        unlockLayoutMeta = { keyToFolder = {} },
        specOverrides = { a = 1 }, condOverrides = { b = 1 }, overridesIncluded = true,
        assignedSpecs = { 257, 264 }, cdmSpells = { ["257"] = {} },
        _migrations = { retail_only_v1 = true },
        fonts = { global = "Retail Only Font", outlineMode = "outline", neverShowSlug = false },
        uiScale = 0.53, euiAccent = { useClass = true }, tooltipFixedPos = { centerX = 1580, centerY = -394 },
        blizzSkinGlobals = { charSheetEnchantNames = false, inspectShowItemLevel = true, retailOnlyKey = 1 },
        applyBlizzSkinGlobals = true,
    } }
end
''')
G.Reset(G.Live())
for k in ('player', 'target', 'playerCastbar', 'focus'):
    G.EllesmereUI._unlockRegisteredElements[k] = lua.table()
payload = G.RetailPayload()
stats = E.WrathAdaptForeignPayload(payload)
assert stats is not None
d = payload.data
A = d.addons
assert A.EllesmereUIDragonRiding is None and A.EllesmereUIMythicTimer is None
ab = A.EllesmereUIActionBars
assert ab.enabled is False
assert ab.bars.bar1.borderSize == 2 and ab.bars.bar1.borderThickness is None
assert ab.bars.bar1.barVisibility == 'always' and ab.bars.bar1.bgColor.a == 1 and ab.bars.bar1.bgColor.r == 0
assert ab.bars.petBar.borderSize == 3 and ab.bars.MainBar is None and ab.bars.XPBar is None
assert ab.barPositions.bar1.x == -20 and ab.barPositions.bar1.relPoint == 'CENTER'
assert ab.barPositions.stanceBar.relPoint == 'BOTTOM' and ab.barPositions.XPBar is None
q = A.EllesmereUIQoL
assert q.battleRes is False and q.cursor.gcd is False, 'a port toggle must not become a Retail table'
assert q.cursor.texture == 'ring_normal' and q.cursor.size == 27 and q.cursor.hex is None
assert list(q.order.values()) == ['c', 'a', 'b'], 'a reorder of port entries is taken'
assert list(q.spells.values()) == [1, 2], 'foreign scalar lists are not mixed in'
assert abs(A.EllesmereUINameplates.targetScale - 1.2) < 1e-9, 'Retail percent -> port multiplier'
assert A.EllesmereUINameplates.castScale == 90
assert abs(q.raidTools.scale - 120) < 1e-9, 'Retail multiplier -> port percent'
bars = A.EllesmereUICooldownManager.cdmBars.bars
assert bars[1].growDirection == 'CENTER' and bars[1].iconSize == 40
assert bars[2].key == 'utility' and bars[2].barType is None and bars[3] is None
assert A.EllesmereUICooldownManager.specProfiles is None
uf = A.EllesmereUIUnitFrames.player
assert uf.width == 230 and uf.healthBarTexture == 'sm:Atrocity' and uf.housingHide is None
# Positions: records are taken whole even where the port profile had none yet.
ufp = A.EllesmereUIUnitFrames.positions
assert ufp.player.x == -300 and ufp.target.point == 'LEFT' and ufp.target.x == 300 and ufp.bogus is None
assert ab.barPositions.hud_xp.point == 'TOP' and ab.barPositions.QueueStatus is None
assert q.positions.fps.y == -700 and q.fpsPos is None
rf = A.EllesmereUIRaidFrames
assert rf.positions.raid10.y == -500 and rf.positions.raid25.y == -500 and rf.positions.raid40.y == -500
assert rf.positions.party.relPoint == 'CENTER' and rf.positions.healerMana.x == -1600
assert rf.unlockPos is None and rf.partyUnlockPos is None and rf.healerMana.unlockPos is None
assert A.EllesmereUIChat.chat.position.x == 50 and A.EllesmereUIChat.chat.chatPosition is None
dmw = A.EllesmereUIDamageMeters.windows
assert dmw[1].savedPos.x == 5 and dmw[2].savedPos.point == 'TOP' and dmw[3] is None and dmw[1].name == 'A'
assert A.EllesmereUIDamageMeters.dm is None
assert A.EllesmereUIResourceBars.gcdBar.unlockPos.y == -78
cdmp = A.EllesmereUICooldownManager.positions
assert cdmp.cooldowns.point == 'RIGHT' and cdmp.cooldowns.tgtx is None, 'clean record for a known bar'
assert cdmp.custom_13_16756_701 is None and A.EllesmereUICooldownManager.cdmBarPositions is None
assert d.tooltipFixedPos.point == 'CENTER' and d.tooltipFixedPos.x == 1580 and d.tooltipFixedPos.y == -394
# The live profiles themselves are not touched until ImportProfile applies.
live_ab = [db for db in G.EllesmereUI.Lite._dbRegistry.values() if db.folder == 'EllesmereUIActionBars'][0]
assert live_ab.profile.bars.bar1.borderSize == 1

ul = d.unlockLayout
assert ul.anchors.playerCastbar.target == 'player'
assert ul.anchors.CDM_custom_1 is None and ul.anchors.player is None
assert ul.anchors.focus.target == 'EUI_ScreenTop'
assert ul.widthMatch.playerCastbar == 'player' and ul.widthMatch.ERB_ClassResource is None
assert ul.widthMatchExtra.playerCastbar == 2 and ul.widthMatchExtra.ERB_ClassResource is None
assert ul.phantomBounds.player.w == 1 and ul.phantomBounds.CDM_custom_1 is None
assert d.unlockLayoutMeta is None

assert d.specOverrides is None and d.condOverrides is None
assert d.overridesExcluded is True and d.overridesIncluded is None
assert d.assignedSpecs is None and d.cdmSpells is None and d._migrations is None
assert d.fonts['global'] == 'Expressway' and d.fonts.outlineMode == 'outline'
assert d.fonts._styleSlots.active == 'eui' and d.fonts.neverShowSlug is None
assert d.uiScale == 0.53 and d.euiAccent.useClass is True
db = G.EllesmereUIDB
assert db.charSheetEnchantNames is False and db.inspectShowItemLevel is True and db.retailOnlyKey is None
assert d.blizzSkinGlobals is None and d.applyBlizzSkinGlobals is None
msg = G.printed[1]
assert len(G.printed) == 1 and 'Not on this client:' in msg and 'DragonRiding' in msg and 'MythicTimer' in msg, msg
assert E.PayloadFromOtherClient is None  # Profiles.lua is not loaded here
# A second pass over the adapted payload reads it as port data and changes nothing.
assert E.WrathAdaptForeignPayload(payload) is None

# Port strings import unchanged.
lua.execute('''
function PortPayload(stamped)
    return { version = 3, type = "full", client = stamped and "wrath" or nil, data = {
        addons = { EllesmereUIActionBars = { _abRetail = 1, bars = { bar1 = { borderSize = 9 } } },
                   EllesmereUIQoL = { battleRes = true } },
        assignedSpecs = { 33011 }, specOverrides = { a = 1 }, _migrations = { x = true } } }
end''')
for stamped in (True, False):
    G.Reset(G.Live())
    p = G.PortPayload(stamped)
    assert E.WrathAdaptForeignPayload(p) is None
    assert p.data.addons.EllesmereUIActionBars.bars.bar1.borderSize == 9
    assert p.data.addons.EllesmereUIQoL.battleRes is True
    assert p.data.specOverrides.a == 1 and p.data._migrations.x is True and p.data.assignedSpecs[1] == 33011
    assert len(G.printed) == 0
# Non-full payloads are left alone.
assert E.WrathAdaptForeignPayload(lua.eval('{ type = "cdm_spells", data = {} }')) is None

# A Nameplates-only Retail string (no client stamp): Retail key names map onto the port engine's.
G.Reset(lua.eval('''{ EllesmereUINameplates = { width = 150, height = 17, castHeight = 17, nameSize = 11,
    castBarColor = { r = .7, g = .4, b = .9 }, castIconPosition = "left", auraTimerPosition = "topleft",
    raidMarkerSlot = "topright", maxAuras = 5, targetScale = 1 } }'''))
np_payload = lua.eval('''{ version = 3, type = "full", data = { addons = { EllesmereUINameplates = {
    healthBarWidth = 40, healthBarHeight = 25, castBarHeight = 19, enemyNameTextSize = 13,
    castBar = { r = .1, g = 1, b = .2 }, showCastIcon = true, castIconOnRight = true,
    debuffTimerPosition = "bottomright", raidMarkerPos = "none", maxDebuffs = 4, targetScale = 100 } } } }''')
assert detect(np_payload) == 'retail'
assert E.WrathAdaptForeignPayload(np_payload) is not None
n = np_payload.data.addons.EllesmereUINameplates
assert n.width == 190, 'Retail extra width 40 on a 150 bar'
assert n.height == 25 and n.castHeight == 19 and n.nameSize == 13 and n.maxAuras == 4
assert n.castBarColor.g == 1 and n.castIconPosition == 'right' and n.raidMarkerSlot == 'none'
assert n.auraTimerPosition == 'topleft', 'an unsupported Retail timer position keeps the port value'
assert n.targetScale == 1 and n.healthBarWidth is None and n.healthBarHeight is None
assert "elseif slot==\"topright\"" in np_display and 'E.BuildBarTextureTables(true)' in np_display

# The real strings, when present.
strings = root / '.codex-backups' / 'profile-strings'
if (strings / 'retail.txt').exists() and (strings / 'port.json').exists():
    G.LibDeflate = lua.execute((core / 'Libs/LibDeflate/LibDeflate.lua').read_text(encoding='utf-8-sig'))
    chunk = profiles.split('local Serializer = {}', 1)[1].split('EllesmereUI._Serializer = Serializer', 1)[0]
    decode = lua.execute('local Serializer = {}' + chunk + '''
return function(s) return Serializer.Deserialize(LibDeflate:DecompressDeflate(LibDeflate:DecodeForPrint(s:sub(6)))) end''')
    port = json.loads((strings / 'port.json').read_text(encoding='utf-8'))
    def to_lua(v):
        if isinstance(v, dict):
            t = lua.table()
            for k, x in v.items():
                t[int(k[1:]) if k.startswith('#') else k] = to_lua(x)
            return t
        return v
    G.Reset(to_lua(port['data']['addons']))
    real = decode((strings / 'retail.txt').read_text(encoding='ascii').strip())
    assert detect(real) == 'retail'
    st = E.WrathAdaptForeignPayload(real)
    ra = real.data.addons
    assert ra.EllesmereUIDragonRiding is None and ra.EllesmereUIMythicTimer is None
    assert ra.EllesmereUIQoL.battleRes is False and ra.EllesmereUIQoL.bloodlust is False
    assert ra.EllesmereUIActionBars.bars.bar1 is not None and ra.EllesmereUIActionBars.bars.MainBar is None
    assert real.data.specOverrides is None and real.data.cdmSpells is None
    assert ra.EllesmereUINameplates.targetScale == 1, ra.EllesmereUINameplates.targetScale
    print('real Retail string:', G.printed[1])
    assert st.applied > 100, st.applied
    assert ra.EllesmereUIRaidFrames.positions.raid25.y < -500 and ra.EllesmereUIRaidFrames.positions.party is not None
    assert ra.EllesmereUIQoL.positions.fps.y < -700 and ra.EllesmereUIActionBars.barPositions.hud_xp is not None
    assert ra.EllesmereUIChat.chat.position.point == 'BOTTOMLEFT'
    assert ra.EllesmereUIUnitFrames.positions.player is not None
    assert real.data.tooltipFixedPos.point == 'CENTER' and real.data.tooltipFixedPos.x > 1500
    if (strings / 'nameplates3.txt').exists():
        G.Reset(to_lua(port['data']['addons']))
        npr = decode((strings / 'nameplates3.txt').read_text(encoding='ascii').strip())
        assert detect(npr) == 'retail', 'untagged Nameplates-only Retail string'
        E.WrathAdaptForeignPayload(npr)
        n = npr.data.addons.EllesmereUINameplates
        assert n.width == 190 and n.height == 25 and n.targetScale == 1 and n.healthBarTexture == 'melli'
        print('real Nameplates string:', G.printed[1])

print('profile import retail: ok')
