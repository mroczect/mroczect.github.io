#!/bin/bash

OUTPUT="content/auto-papers.tex"

echo "\section*{My Paper Publish}" > $OUTPUT
echo "\begin{itemize}" >> $OUTPUT

for file in paper/*.tex; do
    [ -e "$file" ] || continue

    filename=$(basename "$file" .tex)

    echo "	\item \href{paper/$filename.pdf}{$filename}" >> $OUTPUT
done

echo "\end{itemize}" >> $OUTPUT

echo "✅ Auto-generated content/auto-papers.tex"
