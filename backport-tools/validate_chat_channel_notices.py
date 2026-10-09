"""Unsupported server channel notices must stop before native format(nil)."""
from validate_chat import boot
lua=boot()
lua.execute(r'''
local p=CHAT.GetSettings(); p.enabled=false; p.spamFilterEnabled=false
local f=CHAT.ChannelNoticeFilter
assert(f(ChatFrame1,'CHAT_MSG_CHANNEL_NOTICE','NOT_IN_LFG'))
assert(f(ChatFrame1,'CHAT_MSG_CHANNEL_NOTICE_USER','UNKNOWN_SERVER_CODE'))
assert(f(ChatFrame1,'CHAT_MSG_CHANNEL_NOTICE',nil))
assert(not f(ChatFrame1,'CHAT_MSG_SAY','NOT_IN_LFG'))
CHAT_JOINED_NOTICE='Joined %s %s'
assert(not f(ChatFrame1,'CHAT_MSG_CHANNEL_NOTICE','JOINED'))
CHAT_BN_TEST_NOTICE_BN='BN %s %s'
assert(not f(ChatFrame1,'CHAT_MSG_CHANNEL_NOTICE','BN_TEST'))
for _,event in ipairs({'CHAT_MSG_CHANNEL_NOTICE','CHAT_MSG_CHANNEL_NOTICE_USER'}) do
 local found=false; for _,filter in ipairs(chatFilters[event] or {}) do if filter==f then found=true end end; assert(found,'Missing native filter registration')
end
assert(CHAT_NOT_IN_LFG_NOTICE==nil and CHAT_NOT_IN_LFG_NOTICE_BN==nil,'Blizzard strings modified')
''')
print('PASS: missing server notices, normal and BN strings, malformed codes, unrelated events, disabled features and native filter registration')
