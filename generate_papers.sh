#!/bin/bash

OUTPUT="content/auto-papers.tex"

echo "\section*{My Paper Publish}" > $OUTPUT
echo "\begin{itemize}" >> $OUTPUT

for file in paper/*.tex; do
    [ -e "$file" ] || continue

    filename=$(basename "$file" .tex)

    # Escape underscores for LaTeX text mode (e.g., file_name -> file\_name)
    escaped_filename=$(echo "$filename" | sed 's/_/\\_/g')

    echo "	\item \href{paper/$filename.pdf}{$escaped_filename}" >> $OUTPUT
done

echo "\end{itemize}" >> $OUTPUT

echo "✅ Auto-generated content/auto-papers.tex"
