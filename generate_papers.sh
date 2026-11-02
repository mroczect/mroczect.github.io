#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

OUTPUT="content/auto-papers.tex"
TMP="${OUTPUT}.tmp"

trap 'rm -f "${TMP}"' EXIT

echo "[gen-papers] Building ${OUTPUT}..."
mkdir -p content

printf '%s\n' '\section*{My Paper Publish}' >  "${TMP}"
printf '%s\n' '\begin{itemize}'             >> "${TMP}"

shopt -s nullglob
count=0
for file in paper/*.tex; do
    filename=$(basename "$file" .tex)

    escaped_filename="${filename//_/\\_}"

    printf '  \\item \\href{paper/%s.pdf}{%s}\n' \
        "${filename}" "${escaped_filename}" >> "${TMP}"

    count=$((count + 1))
done
shopt -u nullglob

printf '%s\n' '\end{itemize}' >> "${TMP}"

mv "${TMP}" "${OUTPUT}"

if [ "$count" -eq 0 ]; then
    echo "[gen-papers] WARN: no paper/*.tex found; wrote empty list"
else
    echo "[gen-papers] Wrote ${count} entries to ${OUTPUT}"
fi