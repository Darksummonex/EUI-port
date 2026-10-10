"""Decodes a WeakAuras "!WA:2!" export (LibDeflate EncodeForPrint + raw deflate) and
prints the readable strings of the LibSerialize payload (names, custom Lua code).
Usage: decode_weakaura.py <file with the export string> [out.txt]"""
import re
import sys
import zlib

ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()'
VALUE = {c: i for i, c in enumerate(ALPHABET)}


def decode_for_print(s):
    out = bytearray()
    cache, bits = 0, 0
    for ch in s:
        if ch not in VALUE:
            continue
        cache |= VALUE[ch] << bits
        bits += 6
        while bits >= 8:
            out.append(cache & 0xFF)
            cache >>= 8
            bits -= 8
    return bytes(out)


def main():
    text = open(sys.argv[1], encoding='utf-8').read().strip()
    text = re.sub(r'^!WA:\d+!', '', text)
    raw = zlib.decompress(decode_for_print(text), -15)
    strings = re.findall(rb'[\x09\x0a\x0d\x20-\x7e]{4,}', raw)
    result = '\n----\n'.join(s.decode('latin-1') for s in strings)
    if len(sys.argv) > 2:
        open(sys.argv[2], 'w', encoding='utf-8').write(result)
        print('bytes', len(raw), 'strings', len(strings))
    else:
        print(result)


if __name__ == '__main__':
    main()
