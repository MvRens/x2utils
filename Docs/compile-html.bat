@Echo Off
echo Compiling paged HTML documentation...
cd html
xsltproc ..\X2Utils-html.xsl ..\X2Utils.xml
cd ..
copy html.css html