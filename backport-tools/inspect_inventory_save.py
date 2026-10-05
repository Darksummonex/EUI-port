"""Report EUI inventory save metadata without printing account/character names."""
from pathlib import Path
import sys,json,os
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
paths=[Path(p) for p in os.environ.get('EUI_INVENTORY_AUDIT_FILES','').split('|') if p] or sorted((root.parents[1]/'WTF/Account').rglob('EllesmereUI*.lua'))
for path in paths:
    if path.name.lower() not in ('ellesmereui.lua','ellesmereuibags.lua'): continue
    lua=LuaRuntime()
    lua.execute(path.read_text(encoding='utf-8-sig'))
    info=lua.execute('''
local root=EllesmereUIInventoryDB or (EllesmereUIDB and EllesmereUIDB.wrathInventoryCache)
local info={characters=0,bagSnapshots=0,bankSnapshots=0,bagItems=0,bankItems=0,importedSnapshots=0}
if root and root.realms then for _,chars in pairs(root.realms) do for _,record in pairs(chars) do
 info.characters=info.characters+1
 for _,kind in ipairs({'bags','bank'}) do local snapshot=record[kind]
  if snapshot then info[kind=='bags' and 'bagSnapshots' or 'bankSnapshots']=info[kind=='bags' and 'bagSnapshots' or 'bankSnapshots']+1
   if snapshot.source then info.importedSnapshots=info.importedSnapshots+1 end
   for _,bag in pairs(snapshot.containers or {}) do for _,item in pairs(bag.items or {}) do info[kind=='bags' and 'bagItems' or 'bankItems']=info[kind=='bags' and 'bagItems' or 'bankItems']+(item.count or 1) end end
  end
 end
end end end
return info
''')
    print(json.dumps({'addonFile':path.name,'bytes':path.stat().st_size,'inventory':dict(info.items())}))
