To build the documentation:

- Download the docBook XSL stylesheets from:
    http://docbook.sourceforge.net/projects/xsl/index.html

- Download XSLTProc, Windows version available at:
    http://www.zlatkovic.com/libxml.en.html

- Modify the XSL files and point the include directive
  to the path where you extracted the docBook files.

- Run compile-html-chunk.bat for the multi-page output or
  compile-html.bat for a single-page output.