#!/bin/bash
# recolor_pdf.sh
###
# MIT License
#
# Copyright (c) 2026 Darryl Ramm
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###
# Crafted with help from my dense friend Google Gemini.
###

set -euo pipefail

GIT_TAG_VERSION=@@VERSION@@

usage() {
    cat << EOF
Usage: $(basename "$0") [options] <input.pdf>

Options:
  -p          Show progress during processing
  -h          Display this help message and exit
  -v          Display version information and exit

Description:
  Removes Avid purple text and structural lines from Pro Tools reference PDFs
  while preserving the official purple logo via geometric pre-scanning.
  Outputs a new PDF with '_black.pdf' appended to the original filename.
EOF
    exit 0
}

# Parse CLI flags
SHOW_PROGRESS=0
while getopts "phv" opt; do
    case ${opt} in
        p) SHOW_PROGRESS=1 ;;
        h) usage ;;
        v) echo "$(basename "$0") $GIT_TAG_VERSION"; exit 0 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
    echo "Error: No input PDF specified." >&2
    echo "Run '$(basename "$0") -h' for usage information." >&2
    exit 1
fi

INPUT_PDF="$1"

if [ ! -f "$INPUT_PDF" ]; then
    echo "Error: File '$INPUT_PDF' not found." >&2
    exit 1
fi

BASENAME="${INPUT_PDF%.pdf}"
OUTPUT_PDF="${BASENAME}_black.pdf"

if ! python3 -c "import fitz" &>/dev/null; then
    echo "pymupdf package not detected. Installing via user space..." >&2
    python3 -m pip install --user pymupdf
fi

if [ "$SHOW_PROGRESS" -eq 1 ]; then
    echo "Processing $INPUT_PDF..."
fi

# Execute Python worker script
python3 - "$INPUT_PDF" "$OUTPUT_PDF" "$SHOW_PROGRESS" << 'EOF'
# recolor_pdf.sh
import sys
import re
import pymupdf

input_pdf = sys.argv[1]
output_pdf = sys.argv[2]
show_progress = sys.argv[3] == "1"

def log(msg):
    if show_progress:
        print(msg, flush=True)

doc = pymupdf.open(input_pdf)
total_pages = len(doc)
avid_purple = (0.471, 0.149, 0.906)

# --- STEP 1: Pre-scan all pages to record logo signatures ---
log(f"[{total_pages} pages] Starting logo pre-scan...")
logo_signatures = {}

for page_num in range(total_pages):
    page = doc[page_num]
    drawings = page.get_drawings()
    purple_drawings = []

    for item in drawings:
        fill_color = item.get("fill")
        if fill_color and len(fill_color) >= 3:
            fr, fg, fb = fill_color[:3]
            if (0.43 <= fr <= 0.51) and (0.11 <= fg <= 0.19) and (0.86 <= fb <= 0.95):
                rect = item.get("rect")
                if rect and (rect.width < 80 and rect.height < 80):
                    purple_drawings.append(item)

    if len(purple_drawings) >= 3:
        logo_signatures[page_num] = purple_drawings

    if show_progress and ((page_num + 1) % 100 == 0 or (page_num + 1) == total_pages):
        print(f"  Pre-scan progress: {page_num + 1}/{total_pages} pages checked...", flush=True)

log(f"Pre-scan complete. Found logo signatures on pages: {list(logo_signatures.keys())}")

# --- STEP 2: Global Content Stream Color Substitution (Purple -> Black) ---
log("Starting global stream color swap...")
color_pattern = re.compile(
    r'([+-]?\d*\.?\d+(?:[eE][+-]?\d+)?)\s+'
    r'([+-]?\d*\.?\d+(?:[eE][+-]?\d+)?)\s+'
    r'([+-]?\d*\.?\d+(?:[eE][+-]?\d+)?)\s+'
    r'(rg|RG)\b'
)

def swap_purple_to_black(match):
    r = float(match.group(1))
    g = float(match.group(2))
    b = float(match.group(3))
    op = match.group(4)

    if (0.43 <= r <= 0.51) and (0.11 <= g <= 0.19) and (0.86 <= b <= 0.95):
        return f"0 0 0 {op}"
    return match.group(0)

for page_num in range(total_pages):
    page = doc[page_num]
    contents = page.get_contents()
    if contents:
        for xref in contents:
            stream_bytes = doc.xref_stream(xref)
            if stream_bytes:
                stream_text = stream_bytes.decode("latin1", errors="ignore")
                new_stream_text = color_pattern.sub(swap_purple_to_black, stream_text)
                if new_stream_text != stream_text:
                    doc.update_stream(xref, new_stream_text.encode("latin1"))

    if show_progress and ((page_num + 1) % 100 == 0 or (page_num + 1) == total_pages):
        print(f"  Stream swap progress: {page_num + 1}/{total_pages} pages processed...", flush=True)

# --- STEP 3: Restore Pre-Recorded Logo Signatures Back to Avid Purple ---
log("Restoring logo signatures...")
for page_num, purple_drawings in logo_signatures.items():
    page = doc[page_num]
    shape = page.new_shape()
    for item in purple_drawings:
        for subpath in item.get("items", []):
            ptype = subpath[0]
            if ptype == "l":
                shape.draw_line(subpath[1], subpath[2])
            elif ptype == "re":
                shape.draw_rect(subpath[1])
            elif ptype == "c":
                shape.draw_bezier(subpath[1], subpath[2], subpath[3], subpath[4])
    shape.finish(color=None, fill=avid_purple)
    shape.commit()

doc.save(output_pdf)
doc.close()
print(f"Success! Saved processed PDF to: {output_pdf}", flush=True)
EOF

# Sorry Marianna :-)
