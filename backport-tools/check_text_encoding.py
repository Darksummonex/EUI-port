"""Report whether each given file decodes as UTF-8 (and where it does not)."""
import sys
from pathlib import Path

for arg in sys.argv[1:]:
    data = Path(arg).read_bytes()
    try:
        data.decode('utf-8')
        print('utf-8 ', arg)
    except UnicodeDecodeError as e:
        print('NOT utf-8', arg, 'at', e.start, data[max(0, e.start - 20):e.start + 10])
