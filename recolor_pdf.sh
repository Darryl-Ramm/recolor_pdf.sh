#!/bin/bash
# recolor_pdf.sh

if [ "$#" -ne 1 ]; then
    echo "Usage: ./recolor_pdf.sh <input_pdf>"
    exit 1
fi

INPUT_PDF="$1"

if [ ! -f "$INPUT_PDF" ]; then
    echo "Error: File '$INPUT_PDF' not found."
    exit 1
fi

BASENAME="${INPUT_PDF%.pdf}"
OUTPUT_PDF="${BASENAME}_black.pdf"

if ! python3 -c "import fitz" &>/dev/null; then
    echo "pymupdf package not detected. Installing via user space..."
    python3 -m pip install --user pymupdf
fi

echo "Processing $INPUT_PDF..."

python3 - "$INPUT_PDF" "$OUTPUT_PDF" << 'EOF'
# recolor_pdf.sh
import sys
import re
import pymupdf

input_pdf = sys.argv[1]
output_pdf = sys.argv[2]

doc = pymupdf.open(input_pdf)
total_pages = len(doc)
avid_purple = (0.471, 0.149, 0.906)

# --- STEP 1: Pre-scan all pages to record logo signatures ---
print(f"[{total_pages} pages] Starting logo pre-scan...")
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

