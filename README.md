# recolor_pdf.sh
A macOS bash shell/Python script that replace the obnoxious overuse of purple in Avid PDF documentation with black. :-)

Avid loves purple, a lot. Your eyes, your printer, and your dark-mode aesthetic do not. Your designer oriented friends might actually throw up it they see Avid PDFs. 

`recolor_pdf.sh` fixes this. It uses low-level PDF stream manipulation to turn purple text and lines in Avid PDFs into crisp black, while performing a geometry pre-scan to make sure it does not harm the sacred Avid purple logo.

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

This will generate a new file named Pro Tools Reference Guide_black.pdf directly in the same folder as the original PDF.

Note: On first run, recolor_pdf.sh automatically sets up a lightweight, isolated Python sandbox in the background to handle dependencies safely without touching your system packages.

For basic usage info try

```
$ ./recolor_pdf.sh -h
```

*Built with assistance from Google Gemini.*
