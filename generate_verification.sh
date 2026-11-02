#!/bin/bash
set -euo pipefail

OUTPUT="content/auto-verification-table.tex"
SHA_FILE="paper/SHA256SUMS"
GPG_KEY_EMAIL="${GPG_KEY_EMAIL:-mroczect@proton.me}"

mkdir -p content
mkdir -p paper

: > "$SHA_FILE"

{
    echo "\section*{Verifikasi Paper}"
    echo ""
    echo "Setiap paper ditandatangani secara kriptografis menggunakan GnuPG."
    echo "Kunci publik tersedia di \texttt{public.asc}. Prosedur verifikasi lengkap"
    echo "ada di \texttt{VERIFY.md}."
    echo ""
    echo "\begin{table}[H]"
    echo "\centering"
    echo "\caption{Metadata dan Tanda Tangan Digital Paper}"
    echo "\label{tab:verifikasi}"
    echo "\footnotesize"
    echo "\begin{tabularx}{\textwidth}{@{} c l X l c @{}}"
    echo "\toprule"
    echo "No & Tanggal & Nama File & SHA-256 & Sign \\\\"
    echo "\midrule"
} > "$OUTPUT"

i=1
for pdf_file in paper/*.pdf; do
    [ -e "$pdf_file" ] || continue

    filename=$(basename "$pdf_file")
    base="${filename%.pdf}"
    sig_file="${pdf_file}.asc"

    if [ ! -e "$sig_file" ] || [ "$pdf_file" -nt "$sig_file" ]; then
        if gpg --armor --detach-sign --local-user "$GPG_KEY_EMAIL" \
                -o "$sig_file" "$pdf_file" 2>/dev/null; then
            echo "  [signed] $filename"
        else
            echo "  [GAGAL]  $filename -- cek kunci GPG ($GPG_KEY_EMAIL)"
        fi
    fi

    sig_ts=$(gpg --list-packets "$sig_file" 2>/dev/null \
             | grep -oP 'created \K\d+' | head -1 || true)
    if [ -n "${sig_ts:-}" ]; then
        timestamp=$(date -d "@$sig_ts" +%Y-%m-%d)
    else
        timestamp=$(date -r "$pdf_file" +%Y-%m-%d)
    fi

    hash=$(sha256sum "$pdf_file" | cut -d' ' -f1)
    echo "$hash  $filename" >> "$SHA_FILE"
    short_hash="${hash:0:16}"

    esc_name=$(echo "$base" | sed 's/_/\\_/g')

    if [ -e "$sig_file" ]; then
        sig_link="\href{paper/$(basename "$sig_file")}{\texttt{.asc}}"
    else
        sig_link="---"
    fi

    echo "$i & $timestamp & \texttt{\scriptsize $esc_name} & \texttt{\scriptsize $short_hash} & $sig_link \\\\" >> "$OUTPUT"
    i=$((i+1))
done

{
    echo "\bottomrule"
    echo "\end{tabularx}"
    echo "\end{table}"
    echo ""
    echo "\noindent\textit{Catatan: SHA-256 di atas ditampilkan 16 karakter pertama. Hash lengkap tersedia di \texttt{paper/SHA256SUMS}.}"
} >> "$OUTPUT"

if [ ! -e "public.asc" ]; then
    if gpg --armor --export "$GPG_KEY_EMAIL" > public.asc 2>/dev/null \
            && [ -s public.asc ]; then
        echo "  [export] public.asc"
    else
        rm -f public.asc
        echo "  [PERINGATAN] Kunci GPG belum dibuat."
        echo "  Jalankan: gpg --full-generate-key"
    fi
fi

echo ""
echo "Tabel verifikasi dibuat: $OUTPUT"
echo "Daftar hash lengkap    : $SHA_FILE"
echo "Total paper            : $((i-1))"
