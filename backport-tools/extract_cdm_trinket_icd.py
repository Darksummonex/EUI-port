"""Extract the 'Item Widget' WeakAura tables pasted by Alex in the agent transcript
and write the compact Cooldown Manager trinket ICD data file.

Usage: python extract_cdm_trinket_icd.py [--dump]
  --dump  only writes the raw pasted message to .codex-backups/cdm_icd_source.txt
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TRANSCRIPT = pathlib.Path(
    r"C:\Users\Gaming\.cursor\projects\c-Users-Gaming-Desktop-EUI-backport\agent-transcripts"
    r"\f665aa40-6f75-426e-9500-b4368437cdd2\f665aa40-6f75-426e-9500-b4368437cdd2.jsonl"
)
OUT = ROOT / "EllesmereUICooldownManager" / "EUI_CooldownManager_335_TrinketData.lua"
DUMP = ROOT / ".codex-backups" / "cdm_icd_source.txt"


def texts(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from texts(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from texts(v)


def source_text():
    found = None
    with TRANSCRIPT.open(encoding="utf-8") as fh:
        for line in fh:
            if "local ITEM_DATA = {" not in line:
                continue
            for t in texts(json.loads(line)):
                if "local ITEM_DATA = {" in t and "COOLDOWNS_DATA" in t and (not found or len(t) > len(found)):
                    found = t
    if not found:
        sys.exit("ITEM_DATA not found in transcript")
    return found


def table_body(src, name):
    m = re.search(r"local\s+" + name + r"\s*=\s*\{", src)
    if not m:
        return None
    i, depth = m.end(), 1
    start = i
    while depth:
        c = src[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        i += 1
    return src[start:i - 1]


def strip_comments(body):
    return re.sub(r"--[^\n]*", "", body)


def parse_map(body):
    """[key] = value  where value is a number, true, or {numbers}."""
    out = {}
    body = strip_comments(body)
    for m in re.finditer(r"\[\s*(\d+)\s*\]\s*=\s*(\{[^}]*\}|true|[\d.]+)", body):
        key, val = int(m.group(1)), m.group(2)
        if val == "true":
            out[key] = True
        elif val.startswith("{"):
            out[key] = [int(x) for x in re.findall(r"\d+", val)]
        else:
            out[key] = float(val) if "." in val else int(val)
    return out


def lua_num(v):
    return str(int(v)) if float(v).is_integer() else repr(v)


def write_lua(items, cooldowns, nocd):
    # Only proc items: 99999 marks on-use items, which use the item cooldown already.
    procs = {}
    for item, val in sorted(items.items()):
        ids = val if isinstance(val, list) else [val]
        ids = [i for i in ids if i != 99999]
        if ids:
            procs[item] = ids
    used = {p for ids in procs.values() for p in ids}
    cds = {p: cooldowns[p] for p in sorted(used) if p in cooldowns}
    noc = sorted(p for p in used if nocd.get(p))

    def chunks(entries, per=8):
        for i in range(0, len(entries), per):
            yield " " + ",".join(entries[i:i + per]) + ","

    lines = [
        "local _,ns=...",
        "-- Passive trinket internal cooldowns (WeakAura \"Item Widget\" data).",
        "-- ITEM[itemID]=procID or {procIDs}; ICD[procID]=seconds (45 when missing); NOCD[procID]: no timer.",
        "ns.TRINKET_PROCS={",
    ]
    entries = []
    for item, ids in procs.items():
        v = str(ids[0]) if len(ids) == 1 else "{" + ",".join(map(str, ids)) + "}"
        entries.append("[%d]=%s" % (item, v))
    lines += chunks(entries)
    lines.append("}")
    lines.append("ns.TRINKET_ICD={")
    lines += chunks(["[%d]=%s" % (p, lua_num(s)) for p, s in cds.items()])
    lines.append("}")
    lines.append("ns.TRINKET_NOCD={")
    lines += chunks(["[%d]=true" % p for p in noc], 10)
    lines.append("}")
    OUT.write_bytes(("\n".join(lines) + "\n").encode("utf-8"))
    print("items", len(procs), "icd", len(cds), "nocd", len(noc), "->", OUT)


def main():
    src = source_text()
    if "--dump" in sys.argv:
        DUMP.write_text(src, encoding="utf-8")
        print("dumped", len(src), "chars ->", DUMP)
        return
    items = parse_map(table_body(src, "ITEM_DATA") or "")
    cooldowns = parse_map(table_body(src, "COOLDOWNS_DATA") or "")
    nocd = parse_map(table_body(src, "NO_COOLDOWN_ITEMS_DATA") or "")
    if not items:
        sys.exit("ITEM_DATA empty")
    write_lua(items, cooldowns, nocd)


if __name__ == "__main__":
    main()
