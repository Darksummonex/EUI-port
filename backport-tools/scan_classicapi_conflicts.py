"""Read-only: count calls in TOC-loaded EUI files to widget methods that
!!!ClassicAPI replaces or stubs with behaviour EUI does not expect."""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from check_loaded_changes import loaded_files  # noqa: E402

METHODS = ['SetClipsChildren', 'DoesClipChildren', 'CreateMaskTexture', 'AddMaskTexture',
           'SetDrawSwipe', 'GetDrawSwipe', 'SetSwipeColor', 'SetSwipeTexture', 'SetHideCountdownNumbers',
           'SetDrawBling', 'SetDrawEdge', 'SetEdgeTexture', 'SetUseCircularEdge', 'SetReverse',
           'GetCooldownTimes', 'GetCooldownDuration', 'Pause', 'Resume', 'SetPaused', 'IsPaused',
           ':Clear()', 'SetIgnoreParentAlpha', 'SetIgnoreParentScale', 'SetUsingParentLevel',
           'SetObeyStepOnDrag', 'SetTextScale', 'GetUnboundedStringWidth', 'IsTruncated',
           'SetFromAlpha', 'SetToAlpha', 'SetScaleFrom', 'SetScaleTo', 'GetEffectiveScale',
           'CreateLine', 'SetResizeBounds', 'SetAtlas', 'SetMask', 'GetNumLines', 'GetLineHeight']

counts = {}
where = {}
for path in sorted(loaded_files()):
    if path.suffix.lower() != '.lua':
        continue
    text = path.read_text(encoding='utf-8-sig', errors='replace')
    for m in METHODS:
        pat = re.escape(m) if m.startswith(':') else r'[:.]' + m + r'\b'
        n = len(re.findall(pat, text))
        if n:
            counts[m] = counts.get(m, 0) + n
            where.setdefault(m, []).append('%s(%d)' % (path.name, n))
for m in METHODS:
    if m in counts:
        print('%-26s %4d  %s' % (m, counts[m], ', '.join(where[m][:8])))
