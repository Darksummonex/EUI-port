"""List Cooldown Manager option helper calls whose `dis` argument is a string literal.

O.T(store,key,label,dis,tip) and friends take the disabled predicate before the tooltip;
a tooltip passed in the `dis` slot makes the Options widget call a string."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
path = root / 'EllesmereUIOptions/EUI_CooldownManager_335_Options.lua'
DIS_INDEX = {'T': 3, 'P': 3, 'S': 6, 'D': 5, 'C': 4}  # zero-based argument position of `dis`


def split_args(src, start):
    """Return (args, end) for the call whose '(' is at src[start]."""
    depth, i, args, cur, quote = 0, start, [], [], None
    while i < len(src):
        ch = src[i]
        if quote:
            cur.append(ch)
            if ch == '\\':
                cur.append(src[i + 1]); i += 1
            elif ch == quote:
                quote = None
        elif ch in '"\'':
            quote = ch; cur.append(ch)
        elif ch in '({[':
            depth += 1
            if depth > 1:
                cur.append(ch)
        elif ch in ')}]':
            depth -= 1
            if depth == 0:
                args.append(''.join(cur).strip()); return args, i
            cur.append(ch)
        elif ch == ',' and depth == 1:
            args.append(''.join(cur).strip()); cur = []
        else:
            cur.append(ch)
        i += 1
    raise ValueError('unbalanced call at %d' % start)


def scan(src):
    bad = []
    for name, idx in DIS_INDEX.items():
        token = 'O.%s(' % name
        pos = src.find(token)
        while pos != -1:
            if not src[pos - 1].isalnum() and not src[pos - 1] == '.':
                args, end = split_args(src, pos + len(token) - 1)
                if len(args) > idx and args[idx][:1] in '"\'':
                    bad.append((pos, end, name, args, idx))
            pos = src.find(token, pos + 1)
    return sorted(bad)


raw = path.read_bytes()
src = raw.decode('utf-8-sig')
bad = scan(src)
for pos, _, name, args, idx in bad:
    print('%d: O.%s %s -> dis=%s' % (src.count('\n', 0, pos) + 1, name, args[2], args[idx][:60]))
print('found', len(bad))
if bad and '--fix' in sys.argv:
    # Only the tooltip-in-dis form (dis is the last argument) is rewritten: insert nil before it.
    for pos, end, name, args, idx in reversed(bad):
        assert len(args) == idx + 1, 'unexpected argument count at %d' % pos
        call = src[pos:end + 1]
        tail = ',' + args[idx] + ')'
        assert call.endswith(tail), call
        src = src[:pos] + call[:-len(tail)] + ',nil' + tail + src[end + 1:]
    assert not scan(src)
    bom = b'\xef\xbb\xbf' if raw.startswith(b'\xef\xbb\xbf') else b''
    path.write_bytes(bom + src.encode('utf-8'))
    print('fixed', len(bad))
    sys.exit(0)
sys.exit(1 if bad else 0)
