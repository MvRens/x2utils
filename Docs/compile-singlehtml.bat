@Echo Off
echo Compiling single-HTML documentation...
xsltproc X2Utils-singlehtml.xsl X2Utils.xml > singlehtml\index.html
cd ..
copy html.css singlehtml