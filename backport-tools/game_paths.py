"""Optional paths into a 3.3.5 game install.

The project never reads game client folders by default. Set EUI_GAME_DIR to an
install to enable the checks that compare against other addons there (ElvUI, DBM,
AbilityTimeline, ACP) or the scripts that read its Data MPQs / WTF; without it
every path here is None and those checks are skipped.
"""
import os
from pathlib import Path

_dir = os.environ.get('EUI_GAME_DIR')
GAME = Path(_dir) if _dir else None
ADDONS = GAME / 'Interface' / 'AddOns' if GAME else None
DATA = GAME / 'Data' if GAME else None
WTF = GAME / 'WTF' if GAME else None
