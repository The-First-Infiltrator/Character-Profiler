#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Validate that Xcode's compiled iOS app icon still resembles the source icon.

Supports ordinary 8-bit RGB/RGBA PNGs and Apple's CgBI PNG variant used in
built .app bundles. This intentionally uses only the Python standard library
so it runs on GitHub's macOS runner without extra packages.
"""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def read_png(path: Path) -> tuple[int, int, list[tuple[int, int, int, int]]]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path} is not a PNG")

    pos = len(PNG_SIGNATURE)
    width = height = bit_depth = color_type = None
    interlace = None
    idat = bytearray()
    is_cgbi = False

    while pos + 12 <= len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        kind = data[pos + 4 : pos + 8]
        payload = data[pos + 8 : pos + 8 + length]
        pos += 12 + length

        if kind == b"CgBI":
            is_cgbi = True
        elif kind == b"IHDR":
            width, height, bit_depth, color_type, _comp, _filter, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            break

    if None in (width, height, bit_depth, color_type, interlace):
        raise ValueError(f"{path} is missing IHDR data")
    if bit_depth != 8:
        raise ValueError(f"{path}: only 8-bit PNGs are supported")
    if interlace != 0:
        raise ValueError(f"{path}: interlaced PNGs are not supported")
    if color_type not in (2, 6):
        raise ValueError(f"{path}: unsupported PNG color type {color_type}")

    channels = 3 if color_type == 2 else 4
    raw = zlib.decompress(bytes(idat), -15 if is_cgbi else zlib.MAX_WBITS)
    stride = width * channels
    expected = height * (stride + 1)
    if len(raw) != expected:
        raise ValueError(
            f"{path}: unexpected decompressed size {len(raw)} (expected {expected})"
        )

    previous = bytearray(stride)
    pixels: list[tuple[int, int, int, int]] = []
    offset = 0

    for _y in range(height):
        filter_type = raw[offset]
        offset += 1
        scan = raw[offset : offset + stride]
        offset += stride

        recon = bytearray(stride)
        for x, value in enumerate(scan):
            left = recon[x - channels] if x >= channels else 0
            up = previous[x]
            up_left = previous[x - channels] if x >= channels else 0

            if filter_type == 0:
                out = value
            elif filter_type == 1:
                out = (value + left) & 0xFF
            elif filter_type == 2:
                out = (value + up) & 0xFF
            elif filter_type == 3:
                out = (value + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                out = (value + paeth(left, up, up_left)) & 0xFF
            else:
                raise ValueError(f"{path}: unsupported PNG filter {filter_type}")
            recon[x] = out

        previous = recon

        for x in range(0, stride, channels):
            if channels == 3:
                r, g, b = recon[x : x + 3]
                a = 255
            else:
                c0, c1, c2, a = recon[x : x + 4]
                if is_cgbi:
                    b, g, r = c0, c1, c2
                    if 0 < a < 255:
                        r = min(255, round(r * 255 / a))
                        g = min(255, round(g * 255 / a))
                        b = min(255, round(b * 255 / a))
                else:
                    r, g, b = c0, c1, c2
            pixels.append((r, g, b, a))

    return width, height, pixels


def sample(
    width: int,
    height: int,
    pixels: list[tuple[int, int, int, int]],
    nx: float,
    ny: float,
) -> tuple[int, int, int]:
    x = min(width - 1, max(0, round(nx * (width - 1))))
    y = min(height - 1, max(0, round(ny * (height - 1))))
    r, g, b, _a = pixels[y * width + x]
    return r, g, b


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("compiled", type=Path)
    parser.add_argument(
        "--max-mean-error",
        type=float,
        default=36.0,
        help="Maximum mean RGB absolute error across the normalized sample grid.",
    )
    args = parser.parse_args()

    sw, sh, source_pixels = read_png(args.source)
    cw, ch, compiled_pixels = read_png(args.compiled)

    if (sw, sh) != (1024, 1024):
        raise SystemExit(f"source icon must be 1024x1024, got {sw}x{sh}")
    if cw < 60 or ch < 60 or cw != ch:
        raise SystemExit(f"compiled icon has unexpected size {cw}x{ch}")

    coords = [0.08, 0.17, 0.26, 0.35, 0.44, 0.53, 0.62, 0.71, 0.80, 0.89]
    total_error = 0
    components = 0
    for ny in coords:
        for nx in coords:
            src = sample(sw, sh, source_pixels, nx, ny)
            dst = sample(cw, ch, compiled_pixels, nx, ny)
            total_error += sum(abs(a - b) for a, b in zip(src, dst))
            components += 3

    mean_error = total_error / components

    compiled_near_white = sum(
        1 for r, g, b, _a in compiled_pixels if r >= 245 and g >= 245 and b >= 245
    ) / len(compiled_pixels)
    source_near_white = sum(
        1 for r, g, b, _a in source_pixels if r >= 245 and g >= 245 and b >= 245
    ) / len(source_pixels)

    print(f"source={sw}x{sh} compiled={cw}x{ch}")
    print(f"normalized mean RGB error={mean_error:.2f}")
    print(
        f"near-white fraction source={source_near_white:.3f} "
        f"compiled={compiled_near_white:.3f}"
    )

    if mean_error > args.max_mean_error:
        print(
            f"compiled app icon does not resemble source "
            f"(mean error {mean_error:.2f} > {args.max_mean_error:.2f})",
            file=sys.stderr,
        )
        return 1

    if compiled_near_white > source_near_white + 0.20:
        print(
            "compiled app icon contains an unexpected excess of near-white pixels",
            file=sys.stderr,
        )
        return 1

    print("compiled app icon matches source within tolerance")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
