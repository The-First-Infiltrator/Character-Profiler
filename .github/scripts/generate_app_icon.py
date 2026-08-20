#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Generate the Character Profiler application icon deterministically.

The repository keeps this generator as the canonical source so GitHub Actions
can recreate the binary PNG without passing image bytes through API tooling.
Only Python's standard library is required.
"""

from __future__ import annotations

import binascii
import struct
import zlib
from pathlib import Path

SIZE = 1024
BG = (31, 54, 105)
GOLD = (255, 190, 52)
WHITE = (248, 250, 253)
TEAL = (28, 128, 145)
NAVY = BG

pixels = bytearray(BG * (SIZE * SIZE))


def put(x: int, y: int, color: tuple[int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        i = (y * SIZE + x) * 3
        pixels[i : i + 3] = bytes(color)


def rect(x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int]) -> None:
    x0 = max(0, min(SIZE, x0))
    y0 = max(0, min(SIZE, y0))
    x1 = max(0, min(SIZE, x1))
    y1 = max(0, min(SIZE, y1))
    row = bytes(color) * max(0, x1 - x0)
    for y in range(y0, y1):
        i = (y * SIZE + x0) * 3
        pixels[i : i + len(row)] = row


def circle(cx: int, cy: int, r: int, color: tuple[int, int, int]) -> None:
    rr = r * r
    for y in range(max(0, cy - r), min(SIZE, cy + r + 1)):
        dy = y - cy
        dx = int((rr - dy * dy) ** 0.5)
        rect(cx - dx, y, cx + dx + 1, y + 1, color)


def ring(cx: int, cy: int, outer: int, inner: int, color: tuple[int, int, int]) -> None:
    outer2 = outer * outer
    inner2 = inner * inner
    for y in range(max(0, cy - outer), min(SIZE, cy + outer + 1)):
        dy2 = (y - cy) ** 2
        ox = int((outer2 - dy2) ** 0.5)
        if dy2 >= inner2:
            rect(cx - ox, y, cx + ox + 1, y + 1, color)
            continue
        ix = int((inner2 - dy2) ** 0.5)
        rect(cx - ox, y, cx - ix, y + 1, color)
        rect(cx + ix + 1, y, cx + ox + 1, y + 1, color)


def polygon(points: list[tuple[int, int]], color: tuple[int, int, int]) -> None:
    ys = [p[1] for p in points]
    ymin = max(0, min(ys))
    ymax = min(SIZE - 1, max(ys))
    n = len(points)
    for y in range(ymin, ymax + 1):
        intersections: list[float] = []
        scan_y = y + 0.5
        for i in range(n):
            x1, y1 = points[i]
            x2, y2 = points[(i + 1) % n]
            if y1 == y2:
                continue
            if (y1 <= scan_y < y2) or (y2 <= scan_y < y1):
                t = (scan_y - y1) / (y2 - y1)
                intersections.append(x1 + t * (x2 - x1))
        intersections.sort()
        for i in range(0, len(intersections) - 1, 2):
            x0 = int(intersections[i] + 0.999999)
            x1 = int(intersections[i + 1])
            rect(x0, y, x1 + 1, y + 1, color)


def line_rect(x0: int, y0: int, x1: int, y1: int, thickness: int, color: tuple[int, int, int]) -> None:
    dx = x1 - x0
    dy = y1 - y0
    length = (dx * dx + dy * dy) ** 0.5
    if length == 0:
        circle(x0, y0, thickness // 2, color)
        return
    ox = -dy / length * thickness / 2
    oy = dx / length * thickness / 2
    polygon(
        [
            (round(x0 + ox), round(y0 + oy)),
            (round(x1 + ox), round(y1 + oy)),
            (round(x1 - ox), round(y1 - oy)),
            (round(x0 - ox), round(y0 - oy)),
        ],
        color,
    )


ring(512, 346, 194, 168, GOLD)
circle(512, 346, 142, WHITE)
circle(532, 284, 22, NAVY)
polygon([(586, 308), (676, 354), (590, 390)], TEAL)

rect(246, 314, 306, 326, GOLD)
rect(270, 290, 282, 350, GOLD)
rect(722, 250, 808, 262, GOLD)
rect(759, 212, 771, 300, GOLD)
rect(790, 414, 838, 426, GOLD)
rect(808, 396, 820, 444, GOLD)

circle(512, 610, 246, WHITE)
polygon([(212, 610), (812, 610), (812, 680), (212, 680)], WHITE)

left_page = [(204, 650), (472, 608), (486, 664), (486, 840), (230, 792)]
right_page = [(820, 650), (552, 608), (538, 664), (538, 840), (794, 792)]
polygon(left_page, WHITE)
polygon(right_page, WHITE)

for y in (674, 722, 770):
    line_rect(270, y, 442, y - 26, 10, TEAL)
    line_rect(582, y - 26, 754, y, 10, TEAL)

rect(501, 606, 523, 848, GOLD)


def chunk(kind: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", binascii.crc32(kind + data) & 0xFFFFFFFF)
    )


def write_png(path: Path) -> None:
    raw = bytearray()
    stride = SIZE * 3
    for y in range(SIZE):
        raw.append(0)
        start = y * stride
        raw.extend(pixels[start : start + stride])

    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)))
    png.extend(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
    png.extend(chunk(b"IEND", b""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


if __name__ == "__main__":
    out = Path("CharacterProfiler/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
    write_png(out)
    print(f"generated {out} ({out.stat().st_size} bytes)")
