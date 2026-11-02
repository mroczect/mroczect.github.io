#!/usr/bin/env bash
# ==============================================================================
# generate_verification.sh
#
# For every paper/*.pdf, produce two sibling files:
#   Name.pdf.asc      detached, ASCII-armored GnuPG signature
#   Name.pdf.sha256   one-line checksum: "<hash>  <basename>"
#
# Then emit content/auto-verification-table.tex: a LaTeX table linking
# each paper's PDF, .asc, and .sha256, plus a short verification guide
# that works on Linux, macOS, and Windows.
#
# Idempotent:
#   - signature is regenerated only when the PDF is newer than the sig
#   - checksum file is rewritten only when the hash actually changes
#   - the LaTeX table is built in a tmp file and atomically renamed
#
# CI integration: if GPG_PASSPHRASE is set, it is passed to gpg via
# --pinentry-mode loopback so signing works non-interactively.
#
# Requires: gpg, sed, date, and either sha256sum or shasum.
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

OUTPUT="content/auto-verification-table.tex"
TMP="${OUTPUT}.tmp"
GPG_KEY_EMAIL="${GPG_KEY_EMAIL:-mroczect@proton.me}"
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"

log()  { printf '[verify-papers] %s\n' "$*"; }
warn() { printf '[verify-papers] WARN: %s\n' "$*" >&2; }
die()  { printf '[verify-papers] ERROR: %s\n' "$*" >&2; exit 1; }

# --- Preflight ---------------------------------------------------------------
command -v gpg  >/dev/null 2>&1 || die "gpg not found in PATH"
command -v sed  >/dev/null 2>&1 || die "sed not found in PATH"
command -v date >/dev/null 2>&1 || die "date not found in PATH"

if   command -v sha256sum >/dev/null 2>&1; then
    sha256_of() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum    >/dev/null 2>&1; then
    sha256_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
    die "neither sha256sum nor shasum found in PATH"
fi

# --- Setup -------------------------------------------------------------------
log "signing and hashing papers"
mkdir -p content paper

trap 'rm -f "${TMP}"' EXIT

# --- LaTeX table header ------------------------------------------------------
{
    printf '%s\n' '\section*{Paper Verification}'
    printf '%s\n' '\addcontentsline{toc}{section}{Paper Verification}'
    printf '\n'
    printf '%s\n' 'Each paper ships as three sibling files: the PDF,'
    printf '%s\n' 'a detached GnuPG signature (\texttt{.asc}), and a'
    printf '%s\n' 'SHA-256 checksum (\texttt{.sha256}). The \textbf{PDF},'
    printf '%s\n' '\textbf{Sig}, and \textbf{SHA} columns below link'
    printf '%s\n' 'to the three files. Click \textbf{PDF} to open in'
    printf '%s\n' 'the browser, or right-click and choose'
    printf '%s\n' '"Save link as" to download.'
    printf '\n'
    printf '%s\n' '\begin{table}[H]'
    printf '%s\n' '\centering'
    printf '%s\n' '\caption{Papers, Signatures, and Checksums}'
    printf '%s\n' '\label{tab:verifikasi}'
    printf '%s\n' '\scriptsize'
    printf '%s\n' '\begin{tabularx}{\textwidth}{@{} c l X c c c @{}}'
    printf '%s\n' '\toprule'
    printf '%s\n' 'No & Date & Paper & PDF & Sig & SHA \\'
    printf '%s\n' '\midrule'
} > "${TMP}"

# --- Enumerate ---------------------------------------------------------------
i=1
shopt -s nullglob
for pdf_file in paper/*.pdf; do
    filename=$(basename "$pdf_file")
    base="${filename%.pdf}"
    sig_file="${pdf_file}.asc"
    sha_file="${pdf_file}.sha256"

    # 1. Signature (skip when the existing sig is not older than the PDF).
    if [ ! -e "$sig_file" ] || [ "$pdf_file" -nt "$sig_file" ]; then
        log "  signing: $filename"

        gpg_args=(--yes --armor --detach-sign --local-user "$GPG_KEY_EMAIL")
        if [ -n "${GPG_PASSPHRASE:-}" ]; then
            gpg_args+=(--pinentry-mode loopback --passphrase "$GPG_PASSPHRASE")
        fi

        gpg "${gpg_args[@]}" -o "$sig_file" "$pdf_file" 2>/dev/null \
            || die "cannot sign $filename (check GPG key $GPG_KEY_EMAIL)"
    else
        log "  signature OK: $filename"
    fi

    # 2. Signature creation time.
    #    gpg --list-packets prints: "version 4, created 1699123456, ..."
    #    Anchor on the word "created" rather than a field index, so
    #    this survives formatting changes across gpg versions.
    sig_ts=$(gpg --list-packets "$sig_file" 2>/dev/null \
        | sed -n 's/.*created[^0-9]*\([0-9][0-9]*\).*/\1/p' \
        | head -n 1) || true

    if [ -n "${sig_ts:-}" ]; then
        if date -r 0 +%s >/dev/null 2>&1; then
            timestamp=$(date -r "$sig_ts" +%Y-%m-%d)   # BSD / macOS
        else
            timestamp=$(date -d "@$sig_ts" +%Y-%m-%d)  # GNU / Linux
        fi
    else
        warn "no signature timestamp found for $filename"
        timestamp="UNKNOWN"
    fi

    # 3. Checksum (rewrite the .sha256 file only when the hash changed).
    hash=$(sha256_of "$pdf_file")
    expected_line="${hash}  ${filename}"
    if [ -e "$sha_file" ] && [ "$(cat "$sha_file")" = "$expected_line" ]; then
        log "  checksum OK: $filename"
    else
        log "  hashing: $filename"
        printf '%s\n' "$expected_line" > "$sha_file"
    fi

    # 4. LaTeX-safe filename for the table cell.
    esc_name="${base//_/\\_}"
    esc_name="${esc_name//&/\\&}"
    esc_name="${esc_name//%/\\%}"
    esc_name="${esc_name//#/\\#}"
    esc_name="${esc_name//\$/\\$}"

    # 5. Links to the three sibling files.
    pdf_link="\\href{paper/${filename}}{\\texttt{pdf}}"
    sig_link="\\href{paper/$(basename "$sig_file")}{\\texttt{asc}}"
    sha_link="\\href{paper/$(basename "$sha_file")}{\\texttt{sha}}"

    # 6. Emit one table row.
    printf '%s & %s & \\texttt{%s} & %s & %s & %s \\\\\n' \
        "$i" "$timestamp" "$esc_name" \
        "$pdf_link" "$sig_link" "$sha_link" >> "${TMP}"

    i=$((i + 1))
done
shopt -u nullglob

paper_count=$((i - 1))

# --- LaTeX table footer + verification guide ---------------------------------
{
    printf '%s\n' '\bottomrule'
    printf '%s\n' '\end{tabularx}'
    printf '%s\n' '\end{table}'
    printf '\n'
    printf '%s\n' '\noindent\footnotesize\textit{Note: the SHA column'
    printf '%s\n' 'shows the first 16 characters of the hash. The full'
    printf '%s\n' 'value is inside each \texttt{.sha256} file.}'
    printf '\n'
    printf '%s\n' '\subsection*{How to Verify}'
    printf '\n'
    printf '%s\n' '\noindent\small'
    printf '%s\n' 'Download the three files for a paper: \texttt{NAME.pdf},'
    printf '%s\n' '\texttt{NAME.pdf.asc}, and \texttt{NAME.pdf.sha256}.'
    printf '%s\n' 'Replace \texttt{NAME.pdf} below with the file you'
    printf '%s\n' 'downloaded.'
    printf '\n'
    printf '%s\n' '\medskip'
    printf '%s\n' '\noindent\small\textbf{1. Checksum (SHA-256)}'
    printf '\n'
    printf '%s\n' '\begin{lstlisting}[style=code]'
    printf '%s\n' '# Linux'
    printf '%s\n' 'sha256sum -c NAME.pdf.sha256'
    printf '%s\n' ''
    printf '%s\n' '# macOS'
    printf '%s\n' 'shasum -a 256 -c NAME.pdf.sha256'
    printf '%s\n' ''
    printf '%s\n' '# Windows PowerShell'
    printf '%s\n' 'certutil -hashfile NAME.pdf SHA256'
    printf '%s\n' '# then compare output with the line in NAME.pdf.sha256'
    printf '%s\n' '\end{lstlisting}'
    printf '\n'
    printf '%s\n' '\medskip'
    printf '%s\n' '\noindent\small\textbf{2. Signature (GnuPG)}'
    printf '\n'
    printf '%s\n' '\begin{lstlisting}[style=code]'
    printf '%s\n' 'gpg --import public.asc'
    printf '%s\n' 'gpg --verify NAME.pdf.asc NAME.pdf'
    printf '%s\n' '\end{lstlisting}'
    printf '\n'
    printf '%s\n' '\noindent\footnotesize\textit{Install GnuPG per OS:'
    printf '%s\n' '\texttt{apt install gnupg} on Debian/Ubuntu,'
    printf '%s\n' '\texttt{pacman -S gnupg} on Arch,'
    printf '%s\n' '\texttt{brew install gnupg} on macOS,'
    printf '%s\n' '\texttt{winget install GnuPG.GnuPG} on Windows.}'
} >> "${TMP}"

# --- Atomic publish ----------------------------------------------------------
mv "${TMP}" "$OUTPUT"

# --- Export public key -------------------------------------------------------
# Regenerated on every run so public.asc always reflects the current
# signing key. Old keys are not preserved: rotate keys by deleting the
# file first, or by exporting both keys manually.
log "exporting public key to public.asc"
if ! gpg --armor --export "$GPG_KEY_EMAIL" > public.asc 2>/dev/null \
        || [ ! -s "public.asc" ]; then
    rm -f public.asc
    die "public.asc export failed (GPG key missing?)"
fi

# --- Report ------------------------------------------------------------------
printf '\n'
printf '[verify-papers] table   : %s\n' "$OUTPUT"
printf '[verify-papers] papers  : %s\n' "$paper_count"
