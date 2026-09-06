# recolor_pdf.sh
Replace the obnoxious overuse of purple in Avid PDF documentation with black. :-)

Avid loves purple, a lot. Your eyes, your printer, and your dark-mode aesthetic do not. Your designer friends might actually throw up it they see this. 

Pro Tools reference PDFs are flooded with aggressive purple text and more. `recolor_pdf.sh` fixes this. It uses low-level PDF stream manipulation to turn Avid purple text and structural lines into crisp black, while performing a geometry pre-scan to make sure it does not harm the sacred Avid purple logo.

## Download and Installation
Download the script and make it executable:

```
$ curl -sO [https://raw.githubusercontent.com/Darryl_Ramm/recolor-pdf/main/recolor_pdf.sh](https://raw.githubusercontent.com/Darryl_Ramm/recolor-pdf/main/recolor_pdf.sh)
$ chmod +x recolor_pdf.sh
```
## Usage
Run the script against your Pro Tools reference PDFs:

e.g.

```
$ ./recolor_pdf.sh "Pro Tools Reference Guide.pdf"
```

Note: On first run, recolor_pdf.sh automatically sets up a lightweight, isolated Python sandbox in the background to handle dependencies safely without touching your system packages.

For basic usage info try

```
$ ./recolor_pdf.sh -h
```

*Built with assistance from Google Gemini.*
