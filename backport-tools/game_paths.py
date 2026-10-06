"""Paths into the 3.3.5 game install.

The project folder holds the git repo, these tools and the real EllesmereUI* addon
folders; the game's Interface/AddOns links each EllesmereUI* folder back here as a
directory junction. Other addons the validators read as references (ElvUI, DBM,
AbilityTimeline, Questie, ACP), the client Data MPQs and WTF stay in the game install.
Set EUI_GAME_DIR to point the tools at another install.
"""
import os
from pathlib import Path

GAME = Path(os.environ.get('EUI_GAME_DIR', 'D:/Jogo/Whitemane/Games/FrostmourneRebuffed'))
ADDONS = GAME / 'Interface' / 'AddOns'
DATA = GAME / 'Data'
WTF = GAME / 'WTF'
