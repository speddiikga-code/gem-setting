# /// script
# requires-python = ">=3.12"
# dependencies = ["pymupdf"]
# ///
"""Trim a printed slide PDF to the slides: Microsoft Print to PDF only has standard paper sizes, so a
widescreen deck lands centred on A4/Letter with blank bands. Only each page's CropBox changes; the
printed content is kept as is.  uv run office-view-crop.py <in.pdf> <out.pdf> <slide width> <slide height>
"""

import sys

import pymupdf

src, dst = sys.argv[1:3]
aspect = float(sys.argv[4]) / float(sys.argv[3])
doc = pymupdf.open(src)
for page in doc:
    box = page.mediabox
    # the slide is fitted to the paper: full width, or full height when the slide is the taller shape
    w, h = (box.width, box.width * aspect) if box.width * aspect <= box.height else (box.height / aspect, box.height)
    x, y = (box.width - w) / 2, (box.height - h) / 2
    page.set_cropbox(pymupdf.Rect(x, y, x + w, y + h))
doc.save(dst)
