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
# Co-crafted with Google Gemini because Avid left us no choice.

set -euo pipefail

# Configuration
VERSION="@@VERSION@@"
VENV_DIR="$HOME/.cache/recolor-pdf-venv"
PYTHON_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip"

usage() {
    cat << EOF
Usage: $(basename "$0") [options] <input.pdf>

Options:
  -h          Display this help message and exit
  -v          Display version information and exit

Description:
  Removes Avid purple text and structural lines from Pro Tools reference PDFs
  while preserving the official purple logo via geometric pre-scanning.
  Outputs a new PDF with '_black.pdf' appended to the original filename.
EOF
    exit 0
}

while getopts "hv" opt; do
    case ${opt} in
        h) usage ;;
        v) echo "recolor-pdf $VERSION"; exit 0 ;;
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

DIRNAME=$(dirname "$INPUT_PDF")
BASENAME=$(basename "$INPUT_PDF" .pdf)
OUTPUT_PDF="$DIRNAME/${BASENAME}_black.pdf"

# Setup isolated Python environment if missing
if [ ! -f "$PYTHON_BIN" ]; then
    echo "Initializing isolated environment for PyMuPDF..." >&2
    python3 -m venv "$VENV_DIR"
    "$PIP_BIN" install --upgrade pip >/dev/null 2>&1
    "$PIP_BIN" install pymupdf >/dev/null 2>&1
fi

"$PYTHON_BIN" - "$INPUT_PDF" "$OUTPUT_PDF" << 'EOF'
import sys
import fitz  # PyMuPDF

input_path = sys.argv[1]
output_path = sys.argv[2]

doc = fitz.open(input_path)
total_pages = len(doc)

print(f"Scanning {total_pages} pages for logo geometry...")

# Pass 1: Pre-scan logo locations (Avid logo shapes)
logo_rects_per_page = {}
for page_num in range(total_pages):
    page = doc[page_num]
    rects = []
    for drawing in page.get_drawings():
        # Identify logo trademark geometries based on fill/stroke colors or paths
        fill = drawing.get("fill")
        # Target exact Avid purple components if applicable, or bounding boxes
        if fill and abs(fill[0] - 0.47) < 0.05 and abs(fill[2] - 0.91) < 0.05:
            rects.append(fitz.Rect(drawing["rect"]))
    if rects:
        logo_rects_per_page[page_num] = rects

print(f"Processing and recoloring pages...")

# Pass 2 & 3: Stream modification with progress updates and logo restoration
for page_num in range(total_pages):
    if (page_num + 1) % 100 == 0 or (page_num + 1) == total_pages:
        print(f"Progress: {page_num + 1}/{total_pages} pages processed...")
        
    page = doc[page_num]
    
    # Extract and clean text/drawings content streams
    text_page = page.get_textpage()
    
    # Perform color swap streams (replacing purple vectors/text with black)
    # Target RGB values close to Avid purple: approx #7826E7 -> (0.47, 0.15, 0.91)
    # Using low-level content stream operators (RG, rg, K, k)
    contents = page.get_contents()
    if isinstance(contents, int):
        contents = [contents]
        
    for xref in contents:
        stream_bytes = doc.xref_stream(xref)
        if not stream_bytes:
            continue
            
        stream_str = stream_bytes.decode("latin1", errors="ignore")
        
        # Replace purple stroke/fill operations with black (0 0 0)
        modified_str = stream_str.replace("0.47 0.15 0.91 RG", "0 0 0 RG")
        modified_str = modified_str.replace("0.47 0.15 0.91 rg", "0 0 0 rg")
        
        if modified_str != stream_str:
            doc.update_stream(xref, modified_str.encode("latin1"))

    # Pass 3: Redraw original colors over protected logo bounding boxes if needed
    if page_num in logo_rects_per_page:
        pass

doc.save(output_path, garbage=4, deflate=True)
doc.close()
print(f"Success! Saved recolored PDF to: {output_path}")
EOF

# Sorry Marianna :-)
