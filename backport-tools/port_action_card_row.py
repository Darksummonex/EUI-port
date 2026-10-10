"""Copy Retail's BuildActionCardRow (and its inline layout) from the unloaded
EllesmereUI_Widgets_PageParts.lua into the loaded EllesmereUI_Widgets.lua,
right before BuildNoteRow, as the other page parts were merged."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "EllesmereUIOptions"
SRC = ROOT / "EllesmereUI_Widgets_PageParts.lua"
DST = ROOT / "EllesmereUI_Widgets.lua"

START = "-- A row of action cards across the page (icon, title, a short description;"
END = "-- Dim note row shown inside a card when its module is disabled."


def main():
    src = SRC.read_text(encoding="utf-8").replace("\r\n", "\n")
    block = src[src.index(START):src.index(END)]
    raw = DST.read_bytes()
    crlf = b"\r\n" in raw
    dst = raw.decode("utf-8").replace("\r\n", "\n")
    if "function EllesmereUI.BuildActionCardRow" in dst:
        print("already present")
        return
    i = dst.index(END)
    dst = dst[:i] + block + dst[i:]
    if crlf:
        dst = dst.replace("\n", "\r\n")
    DST.write_bytes(dst.encode("utf-8"))
    print(f"inserted {block.count(chr(10))} lines")


if __name__ == "__main__":
    main()
