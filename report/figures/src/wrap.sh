#!/bin/sh
# usage: wrap.sh name  -> builds ../name.pdf and ../name.png from name.tex body
n=$1
cat > _$n.tex <<EOT
\documentclass[border=3pt]{standalone}
\usepackage[T1]{fontenc}\usepackage{mathptmx}
\usepackage{bytefield}
\input{style.tex}
\begin{document}
\input{$n.tex}
\end{document}
EOT
pdflatex -interaction=nonstopmode -halt-on-error _$n.tex > _$n.log 2>&1 || { grep -A5 '^!' _$n.log | head -20; exit 1; }
mv _$n.pdf ../$n.pdf; pdftoppm -png -r 300 -singlefile ../$n.pdf ../$n
