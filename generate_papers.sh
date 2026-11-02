#!/usr/bin/env bash
# ==============================================================================
# generate_papers.sh - Generate LaTeX list of papers
# Strict mode: Exit on error, undefined variables, or pipe failures.
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

OUTPUT="content/auto-papers.tex"

echo "⏳ Memulai generasi daftar paper..."
mkdir -p content

# Trap untuk memastikan output tidak corrupt jika script dihentikan paksa
trap 'rm -f "${OUTPUT}.tmp"' EXIT

echo "\section*{My Paper Publish}" > "${OUTPUT}.tmp"
echo "\begin{itemize}" >> "${OUTPUT}.tmp"

count=0
# Gunakan nullglob agar jika tidak ada file .tex, loop tidak error
shopt -s nullglob
for file in paper/*.tex; do
    filename=$(basename "$file" .tex)
    
    # Cross-platform safe: Hanya replace underscore dengan escaped underscore
    # Menggunakan parameter expansion bawaan bash (lebih cepat & aman dari sed)
    escaped_filename="${filename//_/\\_}"
    
    echo "	\item \href{paper/${filename}.pdf}{${escaped_filename}}" >> "${OUTPUT}.tmp"
    count=$((count + 1))
done
shopt -u nullglob

echo "\end{itemize}" >> "${OUTPUT}.tmp"

# Atomically move hasil akhir
mv "${OUTPUT}.tmp" "$OUTPUT"

if [ "$count" -eq 0 ]; then
    echo "⚠️  PERINGATAN: Tidak ada file .tex ditemukan di folder paper/."
else
    echo "✅ Sukses! ${count} paper didaftarkan ke ${OUTPUT}"
fi