"""Regenerate EUI world map instance and flight point data from Questie-335 tables.

Output is keyed by the native Wrath GetCurrentMapAreaID() value and stores
zone-map percentages. Run again only to refresh the data file.
"""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

questie = root / 'Questie-335'
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
Questie={IsWotlk=true,IsTBC=false,IsClassic=false,IsEra=false}
local modules={}
QuestieLoader={}
function QuestieLoader:ImportModule(n) modules[n]=modules[n] or {}; return modules[n] end
QuestieLoader.CreateModule=QuestieLoader.ImportModule
QuestieCompat={}
''')
for rel in ['Database/Zones/zoneTables.lua', 'Compat/UiMapData.lua', 'Database/Wotlk/wotlkNpcDB.lua']:
    lua.execute((questie / rel).read_text(encoding='utf-8-sig'))
private = lua.eval('QuestieLoader:ImportModule("ZoneDB").private')
uimap = lua.eval('QuestieCompat.UiMapData')
npcs = lua.eval('assert(loadstring(QuestieLoader:ImportModule("QuestieDB").npcData))()')

def map_id(area):
    ui = private.areaIdToUiMapId[area]
    data = ui and uimap[ui]
    value = data and data['mapID']
    return int(value) if value and value > 0 else None

RAIDS = {1977: '20', 2159: '10/25', 2677: '40', 2717: '40', 3428: '40', 3429: '20', 3456: '10/25', 3457: '10',
         3606: '25', 3607: '25', 3805: '10', 3836: '25', 3845: '25', 3923: '25', 3959: '25', 4075: '25',
         4273: '10/25', 4493: '10/25', 4500: '10/25', 4603: '10/25', 4722: '10/25', 4812: '10/25', 4987: '10/25'}
NAMES = {3428: "Temple of Ahn'Qiraj", 3845: 'The Eye'}
LEVELS = {
    'Ragefire Chasm': '13-18', 'Wailing Caverns': '15-25', 'The Deadmines': '15-21', 'Shadowfang Keep': '18-25',
    'Blackfathom Deeps': '20-30', 'The Stockade': '22-30', 'Gnomeregan': '24-34', 'Razorfen Kraul': '25-35',
    'Scarlet Monastery': '26-45', 'Razorfen Downs': '35-45', 'Uldaman': '35-45', "Zul'Farrak": '43-50',
    'Maraudon': '40-52', "The Temple of Atal'Hakkar": '50-60', 'Blackrock Depths': '52-60',
    'Blackrock Spire': '55-60', 'Dire Maul': '55-60', 'Scholomance': '58-60', 'Stratholme': '58-60',
    'Hellfire Ramparts': '60-62', 'The Blood Furnace': '61-63', 'The Slave Pens': '62-64', 'The Underbog': '63-65',
    'Mana-Tombs': '64-66', 'Auchenai Crypts': '65-67', 'Old Hillsbrad Foothills': '66-68', 'Sethekk Halls': '67-69',
    'The Steamvault': '68-70', 'Shadow Labyrinth': '69-70', 'The Shattered Halls': '69-70', 'The Black Morass': '69-70',
    'The Mechanar': '69-70', 'The Botanica': '70', 'The Arcatraz': '70', "Magisters' Terrace": '70',
    'Utgarde Keep': '69-72', 'The Nexus': '70-73', 'Azjol-Nerub': '72-74', "Ahn'kahet: The Old Kingdom": '73-75',
    "Drak'Tharon Keep": '74-76', 'The Violet Hold': '75-77', 'Gundrak': '76-78', 'Halls of Stone': '77-79',
    'Halls of Lightning': '79-80', 'The Oculus': '79-80', 'Utgarde Pinnacle': '79-80',
    'The Culling of Stratholme': '79-80', 'Trial of the Champion': '80', 'The Forge of Souls': '80',
    'Pit of Saron': '80', 'Halls of Reflection': '80',
}
RAID_LEVELS = {1977: '60', 2677: '60', 2717: '60', 3428: '60', 3429: '60', 2159: '80', 3456: '80', 4075: '70'}

def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'

instances, missing = {}, set()
for area, entry in private.dungeons.items():
    name = NAMES.get(area, entry[1])
    locations = private.dungeonLocations[area]
    if not locations:
        continue
    raid = area in RAIDS
    level = RAID_LEVELS.get(area, '70' if raid and area < 4000 else '80') if raid else LEVELS.get(name)
    if not raid and not level:
        missing.add(name)
    for loc in locations.values():
        mid = map_id(loc[1])
        if not mid:
            continue
        key = (mid, round(float(loc[2]), 1), round(float(loc[3]), 1))
        group = instances.setdefault(key, {})
        group[name] = (2 if raid else 1, level or '', RAIDS.get(area, ''))

def read_taxi_nodes():
    """TaxiNodes.dbc from the client: rebuffed.mpq carries English names, patch-6.MPQ Portuguese ones."""
    import math, struct, mpyq
    data_dir = root.parents[1] / 'Data'

    def parse(rel):
        d = mpyq.MPQArchive(str(data_dir / rel), listfile=False).read_file('DBFilesClient\\TaxiNodes.dbc')
        n, _, size, _ = struct.unpack('<4I', d[4:20])
        strings = d[20 + n * size:]
        out = {}
        for i in range(n):
            r = d[20 + i * size:20 + (i + 1) * size]
            node, mapid = struct.unpack('<2I', r[:8])
            x, y = struct.unpack('<2f', r[8:16])
            off = struct.unpack('<I', r[20:24])[0]
            mounts = struct.unpack('<2I', r[88:96])
            out[node] = (mapid, x, y, strings[off:strings.index(b'\0', off)].decode('utf-8'), mounts)
        return out

    english, translated = parse('rebuffed.mpq'), parse('patch-6.MPQ')
    nodes = {}
    for node, (mapid, x, y, name, mounts) in english.items():
        if not any(mounts) or name.startswith(('Quest', 'Transport')) or name.endswith((' - Begin', ' - End', ' - Start')):
            continue
        names = [name]
        alt = translated.get(node, (0, 0, 0, name))[3]
        if alt and alt != name:
            names.append(alt)
        nodes[node] = (mapid, x, y, names)
    return nodes, math


taxi_nodes, math = read_taxi_nodes()
used_nodes, far_flights = {}, []
# Questie stores the Blood Elf/Draenei isles and Quel'Danas in continent-shifted coordinates.
NODE_OVERRIDES = {'Skymistress Gloaming': 82, 'Skymaster Sunwing': 83, 'Kiz Coilspanner': 205,
                  'Laando': 93, 'Stephanos': 94, 'Ohura': 213}


def nearest_node(name, area, x, y):
    if name in NODE_OVERRIDES:
        node = NODE_OVERRIDES[name]
        used_nodes[node] = taxi_nodes[node][3]
        return node
    ui = private.areaIdToUiMapId[area]
    data = ui and uimap[ui]
    if not data or not data[1]:
        return 0
    # HereBeDragons world X/Y are the DBC Y/X axes.
    wx, wy = data[3] - data[1] * x / 100, data[4] - data[2] * y / 100
    best, dist = 0, 1e9
    for node, (mapid, nx, ny, _) in taxi_nodes.items():
        if mapid == data['instance']:
            d = math.hypot(ny - wx, nx - wy)
            if d < dist:
                best, dist = node, d
    if dist > 250:
        far_flights.append((area, x, y, round(dist)))
        return 0
    used_nodes[best] = taxi_nodes[best][3]
    return best


flights, unmapped = {}, 0
for npc_id, npc in npcs.items():
    flags = npc[15] or 0
    spawns = npc[7]
    name = npc[1] or ''
    if not flags & 8192 or not spawns or not name or name.startswith('[') or 'UNUSED' in name.upper():
        continue
    faction = npc[13] or ''
    title = npc[14] or 'Flight Master'
    for area, coords in spawns.items():
        mid = map_id(area)
        if not mid:
            unmapped += 1
            continue
        for pair in coords.values():
            x, y = float(pair[1]), float(pair[2])
            if 0 < x < 100 and 0 < y < 100:
                flights.setdefault(mid, {})[(round(x, 1), round(y, 1))] = (name, title, faction, nearest_node(name, area, x, y))

# Duplicate NPC records can share one taxi node on a map; keep one marker, preferring a single-faction tag.
for mid, points in flights.items():
    groups = {}
    for key, value in sorted(points.items()):
        if value[3]:
            groups.setdefault(value[3], []).append(key)
    for keys in groups.values():
        single = {}
        for key in keys:
            if len(points[key][2]) == 1:
                single.setdefault(points[key][2], key)
        keep = set(single.values()) or {keys[0]}
        for key in keys:
            if key not in keep:
                del points[key]

lines = ['-- Generated by backport-tools/generate_worldmap_points.py. Keys are GetCurrentMapAreaID().',
         '-- Instances: {x,y,{{name,kind(1 dungeon/2 raid),levels,size},...}}. Flights: {x,y,name,title,faction,taxiNode}.',
         '-- TaxiNodes: {[taxiNode]={names...}} as returned by TaxiNodeName() on English and translated clients.',
         'local ns=select(2,...)', 'ns.WorldMapInstances={']
for mid in sorted({k[0] for k in instances}):
    lines.append(f'    [{mid}]={{')
    for key in sorted(k for k in instances if k[0] == mid):
        names = ','.join('{%s,%d,%s,%s}' % (lua_str(n), kind, lua_str(lv), lua_str(sz))
                         for n, (kind, lv, sz) in sorted(instances[key].items(), key=lambda i: (-i[1][0], i[0])))
        lines.append(f'        {{{key[1]},{key[2]},{{{names}}}}},')
    lines.append('    },')
lines += ['}', 'ns.WorldMapFlights={']
for mid in sorted(flights):
    lines.append(f'    [{mid}]={{')
    for (x, y), (name, title, faction, node) in sorted(flights[mid].items()):
        lines.append(f'        {{{x},{y},{lua_str(name)},{lua_str(title)},{lua_str(faction)},{node}}},')
    lines.append('    },')
lines += ['}', 'ns.WorldMapTaxiNodes={']
for node in sorted(used_nodes):
    lines.append(f'    [{node}]={{{",".join(lua_str(n) for n in used_nodes[node])}}},')
lines.append('}')
out = root / 'EllesmereUIBlizzardSkin/EUI_WorldMap_335_Points.lua'
out.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(f'{len(instances)} instance markers on {len({k[0] for k in instances})} maps; '
      f'{sum(len(v) for v in flights.values())} flight points on {len(flights)} maps; '
      f'{unmapped} unmapped flight spawns; dungeons without level range: {sorted(missing)}')
print(f'{len(used_nodes)} taxi nodes linked; flight masters without a node within 250 yards: {far_flights}')
