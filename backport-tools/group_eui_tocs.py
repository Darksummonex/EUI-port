"""Clean EUI addon-list titles and group modules under the Core in ACP.

ACP's "Group By Name" sorter nests any addon declaring X-Part-Of: <parent>
under a collapsible row for <parent>, the way DBM modules sit under DBM.
Idempotent: safe to run again.
"""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
TITLE = "|cff0cd29fEllesmereUI|r"
renames = {
    "EllesmereUI": TITLE,
    "EllesmereUIOptions": TITLE + " Options",
    "EllesmereUIDataBars": TITLE + " DataBars",
}

for toc in sorted(root.glob("EllesmereUI*/EllesmereUI*.toc")):
    folder = toc.parent.name
    if toc.stem != folder:
        continue
    raw = toc.read_bytes().decode("utf-8")
    newline = "\r\n" if "\r\n" in raw else "\n"
    lines = raw.split(newline)
    changed = False
    if folder in renames:
        for i, line in enumerate(lines):
            if line.startswith("## Title:"):
                wanted = "## Title: " + renames[folder]
                if line != wanted:
                    lines[i] = wanted
                    changed = True
                break
    if folder != "EllesmereUI" and not any(l.startswith("## X-Part-Of:") for l in lines):
        at = next((i + 1 for i, l in enumerate(lines) if l.startswith("## Dependencies:")), None)
        if at is None:
            at = next(i + 1 for i, l in enumerate(lines) if l.startswith("## Title:"))
        lines.insert(at, "## X-Part-Of: EllesmereUI")
        changed = True
    if changed:
        toc.write_bytes(newline.join(lines).encode("utf-8"))
        print("updated", toc.relative_to(root))
