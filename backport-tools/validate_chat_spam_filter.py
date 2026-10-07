"""Exercise spam filtering in the real Chat lifecycle and options harness."""
from validate_chat import boot, root
lua=boot()
lua.execute(r'''
local p=CHAT.GetSettings()
local function deliver(frame,event,text,author,id,channel)
    -- Wrath's native filter loop, preserving returned arguments.
    local args={text,author,"Common","", "", "", 0,channel or 1,"World","",id or 0,"guid"}
    for _,filter in ipairs(chatFilters[event] or {}) do
        local result={filter(frame,event,unpack(args,1,12))}
        if result[1] then return true end
        if result[2] then for i=1,12 do args[i]=result[i+1] end end
    end
    return false
end
assert(not p.spamFilterEnabled)
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale","Bob",1))
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale","Bob",2))
p.spamFilterEnabled=true; CHAT.Apply()
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","Sale   now","Bob",3))
assert(not deliver(ChatFrame2,"CHAT_MSG_CHANNEL","Sale   now","Bob",3))
assert(deliver(ChatFrame1,"CHAT_MSG_CHANNEL"," sale NOW ","Bob",4))
assert(deliver(ChatFrame2,"CHAT_MSG_CHANNEL"," sale NOW ","Bob",4))
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale now","Alice",5))
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale now","Bob",6,2))
assert(not deliver(ChatFrame1,"CHAT_MSG_YELL","sale now","Bob",7))
assert(not deliver(ChatFrame1,"CHAT_MSG_PARTY","ready","Bob",8))
assert(not deliver(ChatFrame1,"CHAT_MSG_PARTY","ready","Bob",9))
assert(not deliver(ChatFrame1,"CHAT_MSG_WHISPER","hey","Bob",10))
assert(not deliver(ChatFrame1,"CHAT_MSG_WHISPER","hey","Bob",11))
-- Player/NPC/system chat bypass and originals remain intact.
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","mine","player",12))
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","mine","player",13))
assert(not CHAT.SpamFilter(ChatFrame1,"CHAT_MSG_MONSTER_SAY","hi","NPC"))
assert(not CHAT.SpamFilter(ChatFrame1,"CHAT_MSG_SYSTEM","hi","Bob"))
assert(not CHAT.SpamFilter(ChatFrame1,"CHAT_MSG_CHANNEL",nil,"Bob"))
-- Time is measured from the displayed message, not from suppressed attempts.
CHAT.ResetSpamFilter(); now=100
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale","Bob",20))
now=114; assert(deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale","Bob",21))
now=115; assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale","Bob",22))
-- Clients without a usable ID: first delivery in each frame is visible.
CHAT.ResetSpamFilter()
assert(not deliver(ChatFrame1,"CHAT_MSG_SAY","hello","Bob",0))
assert(not deliver(ChatFrame2,"CHAT_MSG_SAY","hello","Bob",0))
assert(deliver(ChatFrame1,"CHAT_MSG_SAY","HELLO","Bob",0))
assert(deliver(ChatFrame2,"CHAT_MSG_SAY","HELLO","Bob",0))
p.spamFilterAnySender=true; p.spamFilterGroup=true; p.spamFilterWhispers=true; CHAT.Apply()
assert(not deliver(ChatFrame1,"CHAT_MSG_GUILD","invite","Bob",30))
assert(deliver(ChatFrame1,"CHAT_MSG_GUILD","invite","Alice",31))
assert(not deliver(ChatFrame1,"CHAT_MSG_WHISPER","hey","Bob",32))
assert(deliver(ChatFrame1,"CHAT_MSG_WHISPER","hey","Alice",33))
assert(not deliver(ChatFrame1,"CHAT_MSG_WHISPER_INFORM","hey","Bob",34))
-- Distinct item IDs are distinct content, even when displayed names match.
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","|Hitem:1|h[Item]|h","Bob",35))
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","|Hitem:2|h[Item]|h","Bob",36))
p.enabled=false; combat=true; CHAT.Apply()
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale","Bob",40))
p.enabled=true; CHAT.Apply(); combat=false; CHAT.Apply()
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale","Bob",41))
p.spamFilterPublic=false; CHAT.Apply()
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","sale","Bob",42))
p.spamFilterPublic=true; CHAT.Apply()
-- Invalid ID/string payloads are harmless, and memory remains capped in busy chat.
assert(not CHAT.SpamFilter(ChatFrame1,"CHAT_MSG_CHANNEL",{},"Bob"))
CHAT.ResetSpamFilter()
for i=1,1000 do assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","unique "..i,"Bob",1000+i)) end
assert(not deliver(ChatFrame1,"CHAT_MSG_CHANNEL","unique 1","Bob",3001))
''')
lua.execute('''
IsLoggedIn=function() return true end; rows={}; buttons={}
EllesmereUI.Widgets={DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end,
SectionHeader=function() return {},30 end,WideButton=function(_,parent,text,y,fn) buttons[text]=fn; return {},40 end}
function cfg(text) for _,row in ipairs(rows) do for _,c in ipairs(row) do if c.text==text then return c end end end; error(text) end
''')
lua.execute((root/'EllesmereUIOptions/EUI_Chat_335_Options.lua').read_text())
lua.execute('''
testModule.buildPage("Spam Filter",UIParent,0)
cfg("Filter Repeated Messages").setValue(false)
assert(cfg("Repeat Window (seconds)").disabled())
cfg("Filter Repeated Messages").setValue(true)
assert(not cfg("Repeat Window (seconds)").disabled())
cfg("Repeat Window (seconds)").setValue(30); assert(CHAT.GetSettings().spamFilterWindow==30)
cfg("Match Across Senders").setValue(false); assert(not CHAT.GetSettings().spamFilterAnySender)
assert(not CHAT.SpamFilter(ChatFrame1,"CHAT_MSG_SAY","reset","Bob"))
assert(CHAT.SpamFilter(ChatFrame1,"CHAT_MSG_SAY","reset","Bob"))
buttons["Clear Filter History"]()
assert(not CHAT.SpamFilter(ChatFrame1,"CHAT_MSG_SAY","reset","Bob"))
''')
print('PASS: spam scopes, normalization, sender/channel separation, multi-window line IDs, missing IDs, expiry, own messages, toggles/combat, cache limits and real options controls')
lua.execute(r'''
local p=CHAT.GetSettings()
p.spamFilterEnabled=false; p.spamFilterKeywordsEnabled=false
p.spamFilterTrade=false; p.spamFilterRecruitment=false; p.spamFilterAchievements=false
p.spamFilterPublic=true; p.spamFilterGroup=false; p.spamFilterWhispers=false; CHAT.Apply()
local function blocked(event,text,author) return CHAT.SpamFilter(ChatFrame1,event,text,author or "Bob") end
-- With every filter off, messages return before any text work.
local plain=CHAT.PlainText; CHAT.PlainText=function() error("text processed with all filters off") end
assert(not blocked("CHAT_MSG_CHANNEL","WTS anything")); CHAT.PlainText=plain
assert(#chatFilters.CHAT_MSG_ACHIEVEMENT==1 and #chatFilters.CHAT_MSG_GUILD_ACHIEVEMENT==1)
assert(not blocked("CHAT_MSG_ACHIEVEMENT","earned"))
p.spamFilterAchievements=true; CHAT.Apply()
assert(blocked("CHAT_MSG_ACHIEVEMENT","earned"))
assert(blocked("CHAT_MSG_GUILD_ACHIEVEMENT","earned"))
assert(not blocked("CHAT_MSG_ACHIEVEMENT","earned","player"))
assert(not blocked("CHAT_MSG_SYSTEM","earned"))
p.spamFilterTrade=true; p.spamFilterPublic=false; CHAT.Apply()
assert(not blocked("CHAT_MSG_CHANNEL","WTS [Sword]"),"presets follow the Public Chat scope")
p.spamFilterPublic=true; CHAT.Apply()
for _,text in ipairs({"WTS [Sword]", "WTB gems", "WTT cloth", "Selling enchants", "vendo itens", "compro ouro"}) do
 assert(blocked("CHAT_MSG_CHANNEL",text),text)
end
assert(not blocked("CHAT_MSG_CHANNEL","Who wants to run a dungeon?"))
assert(not blocked("CHAT_MSG_CHANNEL","wtsfoo is my name"))
assert(not blocked("CHAT_MSG_GUILD","WTS cloth"))
assert(not blocked("CHAT_MSG_WHISPER","WTS cloth"))
assert(not blocked("CHAT_MSG_CHANNEL","WTS cloth","player"))
p.spamFilterTrade=false; p.spamFilterRecruitment=true; CHAT.Apply()
for _,text in ipairs({"<Guild> recruiting raiders", "<Raiding Stars> is recruiting active players", "Guild looking for members", "LF guild", "Looking for a guild", "Guilda recrutando membros"}) do
 assert(blocked("CHAT_MSG_YELL",text),text)
end
assert(not blocked("CHAT_MSG_CHANNEL","My guild cleared ICC yesterday"))
assert(not blocked("CHAT_MSG_CHANNEL","Recruiting for ICC pug"))
for _,text in ipairs({"<Frost> LF 1 heal ICC25", "<Elite> lf tank for VoA", "LF guildies for ICC"}) do
 assert(not blocked("CHAT_MSG_CHANNEL",text),"raid ad hidden as recruitment: "..text)
end
assert(blocked("CHAT_MSG_CHANNEL","lfguild"))
p.spamFilterRecruitment=false; p.spamFilterKeywordsEnabled=true; p.spamFilterPublic=true
p.spamFilterKeywords=" boost ; GOLD   seller,  ,100%, [sale],a.b\ncheap gold"; CHAT.Apply()
assert(blocked("CHAT_MSG_CHANNEL","BOOST runs available"))
assert(blocked("CHAT_MSG_SAY","gold   SELLER today"))
assert(blocked("CHAT_MSG_CHANNEL","100% discount"))
assert(blocked("CHAT_MSG_CHANNEL","[sale] now"))
assert(blocked("CHAT_MSG_CHANNEL","a.b"))
assert(not blocked("CHAT_MSG_CHANNEL","axb"))
assert(blocked("CHAT_MSG_CHANNEL","cheap gold"))
assert(not blocked("CHAT_MSG_PARTY","boost"))
assert(not blocked("CHAT_MSG_WHISPER","boost"))
assert(not blocked("CHAT_MSG_WHISPER_INFORM","boost"))
assert(not blocked("CHAT_MSG_MONSTER_SAY","boost"))
assert(not blocked("CHAT_MSG_CHANNEL","boost","player"))
-- Match link labels, not payloads, texture paths or color codes.
assert(not blocked("CHAT_MSG_CHANNEL","|Hitem:boost|h[Sword]|h |Tboost:16|t"))
assert(blocked("CHAT_MSG_CHANNEL","|cff00ff00|Hitem:1|h[Boost]|h|r"))
p.spamFilterGroup=true; p.spamFilterWhispers=true; CHAT.Apply()
assert(blocked("CHAT_MSG_PARTY","boost"))
assert(blocked("CHAT_MSG_WHISPER","boost"))
-- GM messages (arg6 flag) are always shown.
assert(not CHAT.SpamFilter(ChatFrame1,"CHAT_MSG_WHISPER","boost","Gamemaster","Common","","","GM"))
-- Accented capitals fold like ASCII on both sides; the multiplication sign is left alone.
p.spamFilterKeywords="promoção, ÉPICO"; CHAT.Apply()
assert(blocked("CHAT_MSG_CHANNEL","PROMOÇÃO hoje"))
assert(blocked("CHAT_MSG_CHANNEL","item épico"))
p.spamFilterKeywords="2×3"; CHAT.Apply(); assert(blocked("CHAT_MSG_CHANNEL","2×3 deal"))
p.spamFilterKeywords=" , ; \n "; CHAT.Apply()
assert(not blocked("CHAT_MSG_CHANNEL","anything"))
p.enabled=false; CHAT.Apply()
assert(not blocked("CHAT_MSG_ACHIEVEMENT","earned"))
p.enabled=true; CHAT.Apply()
rows={}; testModule.buildPage("Spam Filter",UIParent,0)
cfg("Filter Repeated Messages").setValue(false)
cfg("Filter Keywords").setValue(true)
assert(not cfg("Public Chat").disabled())
cfg("Blocked Keywords").setValue(" gold seller, boost ")
assert(cfg("Blocked Keywords").getValue()==" gold seller, boost ")
assert(blocked("CHAT_MSG_CHANNEL","gold seller"))
cfg("Filter Keywords").setValue(false)
assert(cfg("Blocked Keywords").disabled())
assert(cfg("Public Chat").disabled(),"scopes greyed with every scoped filter off")
cfg("Filter Trade Ads").setValue(true); assert(not cfg("Public Chat").disabled(),"presets use the scope boxes")
cfg("Filter Trade Ads").setValue(false)
assert(not blocked("CHAT_MSG_CHANNEL","gold seller"))
cfg("Filter Trade Ads").setValue(true); assert(blocked("CHAT_MSG_CHANNEL","WTS gems"))
cfg("Filter Guild Recruitment").setValue(true); assert(blocked("CHAT_MSG_CHANNEL","Guild recruiting"))
cfg("Filter Achievements").setValue(false); assert(not blocked("CHAT_MSG_ACHIEVEMENT","earned"))
''')
print('PASS: independent achievement/trade/recruitment presets, whole-word guards, custom literal keyword phrases/separators/visible links, scopes, own messages and options')
