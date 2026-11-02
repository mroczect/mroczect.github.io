#!/usr/bin/env bash
# ==============================================================================
# generate_verification.sh - Sign PDFs and generate LaTeX verification table
# Requirements: gpg, sha256sum (or shasum on mac), basename
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

OUTPUT="content/auto-verification-table.tex"
SHA_FILE="paper/SHA256SUMS"
GPG_KEY_EMAIL="${GPG_KEY_EMAIL:-mroczect@proton.me}"

echo "🛡️  Memulai proses signing & verifikasi..."
mkdir -p content paper
: > "$SHA_FILE"

# Trap untuk cleanup
trap 'rm -f "${OUTPUT}.tmp"' EXIT

# --- HEADER TABEL LATEX ---
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
} > "${OUTPUT}.tmp"

i=1
shopt -s nullglob
for pdf_file in paper/*.pdf; do
    filename=$(basename "$pdf_file")
    base="${filename%.pdf}"
    sig_file="${pdf_file}.asc"

    # 1. Sign PDF jika belum ada atau PDF lebih baru dari signature
    if [ ! -e "$sig_file" ] || [ "$pdf_file" -nt "$sig_file" ]; then
        echo "  ✍️  Signing: $filename"
        if ! gpg --yes --armor --detach-sign --local-user "$GPG_KEY_EMAIL" \
                -o "$sig_file" "$pdf_file" 2>/dev/null; then
            echo "❌ GAGAL: Tidak bisa sign $filename. Cek kunci GPG ($GPG_KEY_EMAIL)."
            exit 1
        fi
    else
        echo "  ✅ Signature OK: $filename"
    fi

    # 2. Ekstrak Timestamp dari GPG signature
    # Mengganti 'grep -oP' (Linux only) dengan 'awk' (Portabel)
    sig_ts=$(gpg --list-packets "$sig_file" 2>/dev/null | awk '/created/ {print $3}' | head -n 1 || true)
    
    if [ -n "${sig_ts:-}" ]; then
        # Bedakan format date antara macOS (BSD) dan Linux (GNU)
        if date -r 0 +%s >/dev/null 2>&1; then
            # macOS / BSD
            timestamp=$(date -r "$sig_ts" +%Y-%m-%d)
        else
            # Linux / GNU
            timestamp=$(date -d "@$sig_ts" +%Y-%m-%d)
        fi
    else
        timestamp="UNKNOWN"
    fi

    # 3. Hitung SHA-256 (Gunakan shasum di macOS, sha256sum di Linux)
    if command -v sha256sum >/dev/null 2>&1; then
        hash=$(sha256sum "$pdf_file" | cut -d' ' -f1)
    else
        hash=$(shasum -a 256 "$pdf_file" | cut -d' ' -f1)
    fi
    
    echo "$hash  $filename" >> "$SHA_FILE"
    short_hash="${hash:0:16}"

    # 4. Escape filename untuk LaTeX
    esc_name="${base//_/\\_}"

    # 5. Buat link signature
    if [ -e "$sig_file" ]; then
        sig_link="\href{paper/$(basename "$sig_file")}{\texttt{.asc}}"
    else
        sig_link="---"
    fi

    # 6. Tulis baris ke tabel LaTeX
    echo "$i & $timestamp & \texttt{\scriptsize $esc_name} & \texttt{\scriptsize $short_hash} & $sig_link \\\\" >> "${OUTPUT}.tmp"
    i=$((i+1))
done
shopt -u nullglob

# --- FOOTER TABEL LATEX ---
{
    echo "\bottomrule"
    echo "\end{tabularx}"
    echo "\end{table}"
    echo ""
    echo "\noindent\textit{Catatan: SHA-256 di atas ditampilkan 16 karakter pertama. Hash lengkap tersedia di \texttt{paper/SHA256SUMS}.}"
} >> "${OUTPUT}.tmp"

# Pindahkan hasil
mv "${OUTPUT}.tmp" "$OUTPUT"

# 7. Export kunci publik jika belum ada
if [ ! -e "public.asc" ]; then
    echo "🔑 Mengeksport kunci publik ke public.asc..."
    if ! gpg --armor --export "$GPG_KEY_EMAIL" > public.asc 2>/dev/null || [ ! -s public.asc ]; then
        rm -f public.asc
        echo "❌ PERINGATAN: Gagal eksport public.asc. Kunci GPG belum dibuat?"
        exit 1
    fi
fi

echo ""
echo "🎉 Tabel verifikasi dibuat: $OUTPUT"
echo "🧾 Daftar hash lengkap   : $SHA_FILE"
echo "📄 Total paper           : $((i-1))"