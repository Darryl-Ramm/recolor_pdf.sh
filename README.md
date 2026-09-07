# recolor_pdf.sh
[![Latest Release](https://img.shields.io/github/v/release/Darryl-Ramm/recolor_pdf.sh?include_prereleases&sort=semver)](https://github.com/Darryl-Ramm/recolor_pdf.sh/releases/latest)

A macOS bash shell/Python script that replace the obnoxious overuse of purple in Avid PDF documentation with black. :-)

Avid loves purple, a lot. Your eyes, your printer, and your dark-mode aesthetic do not. Your designer oriented friends might actually throw up it they see Avid PDFs.

`recolor_pdf.sh` fixes this. It uses low-level PDF stream manipulation to turn purple text and lines in Avid PDFs into crisp black, while performing a geometry pre-scan to make sure it does not harm the sacred Avid purple logo.

## Download and Installation
Download the latest release script and make it executable:

```
curl -sL -O https://github.com/Darryl-Ramm/recolor_pdf.sh/releases/latest/download/recolor_pdf.sh
```
```
chmod +x recolor_pdf.sh
```
## Usage
Run the script against an Avid PDF. For example: 

```
./recolor_pdf.sh "Pro Tools Reference Guide.pdf"
```

This will generate a new file named Pro Tools Reference Guide_black.pdf directly in the same folder as the original PDF.

Note: recolor_pdf.sh relies on the PyMuPDF library. On its first run, the script automatically provisions a lightweight, isolated Python virtual environment and installs PyMuPDF locally, leaving your system Python entirely untouched. This initial setup requires an active internet connection; all subsequent runs are fully offline. Currently, dependencies within the sandbox are pinned and do not auto-update (though an update mechanism may be added in a future release).

For basic usage info try

```
$ ./recolor_pdf.sh -h
```

*Built with assistance from Google Gemini.*
