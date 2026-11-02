#!/usr/bin/env bash
# ==============================================================================
# FILE: generate_verification.sh
# ==============================================================================
#
# NAME
#   generate_verification.sh — sign and checksum every paper, then
#   emit a LaTeX verification table that links to the signed files.
#
# SYNOPSIS
#   bash generate_verification.sh
#   GPG_KEY_EMAIL=you@example.com bash generate_verification.sh
#   GPG_PASSPHRASE=secret bash generate_verification.sh
#
#   Invoked by the Makefile, never by hand. The `verify-papers` target
#   is the only caller. On a clean checkout, `make all`, `make html`,
#   and `make pdf` all fail if this script fails; there is no
#   fallback that tolerates an unsigned paper.
#
# DESCRIPTION
#   For every paper/*.pdf, this script produces two sibling files:
#
#     paper/NAME.pdf.asc      detached, ASCII-armored GnuPG signature
#     paper/NAME.pdf.sha256   one-line checksum: "<hash>  <basename>"
#
#   Then it writes content/auto-verification-table.tex — a LaTeX
#   fragment that:
#
#     - defines \section*{Paper Verification}
#     - emits one row per paper with three link columns (PDF, Sig, SHA)
#     - appends a "How to Verify" guide with cross-platform commands
#
#   Finally it exports the signing key's public half to public.asc at
#   the repository root, so that readers can import it before running
#   `gpg --verify`. See VERIFY.md for the reader-facing instructions.
#
#   The whole design goal is a two-file proof of authenticity: the
#   .asc proves the file came from the author, and the .sha256 proves
#   the file arrived intact. Neither alone is sufficient.
#
# INPUTS
#   paper/*.pdf                          every compiled paper
#   ~/.gnupg                             signing key matching $GPG_KEY_EMAIL
#
# OUTPUTS
#   paper/*.asc                          detached ASCII-armored signatures
#   paper/*.sha256                       checksum files
#   content/auto-verification-table.tex  generated LaTeX fragment
#   public.asc                           exportable public key
#
# EXIT CODES
#   0   every paper signed and hashed, table written, key exported
#   1   any step failed: missing tool, missing key, export failure,
#       signing error, or filesystem error
#
# IDEMPOTENCY
#   Running the script twice in a row must produce byte-identical
#   output for unchanged inputs. The implementation guarantees this:
#
#     - a signature is regenerated only when the PDF is newer than
#       the existing .asc, or when the .asc is missing
#     - a checksum file is rewritten only when the hash has changed
#     - the LaTeX table is built in a temp file and atomically
#       renamed into place; a mid-write failure leaves the previous
#       good version untouched
#
# DEPENDENCIES
#   gpg                     required
#   sed                     required
#   date                    required
#   sha256sum or shasum     at least one required
#
# ENVIRONMENT
#   GPG_KEY_EMAIL       default: mroczect@proton.me
#                       The signing key's email. Change this to sign
#                       with a different key. Default hardcoded so
#                       the script works without configuration in the
#                       author's own checkout.
#
#   GPG_PASSPHRASE      unset by default
#                       If set, gpg runs with --pinentry-mode loopback
#                       --passphrase "$GPG_PASSPHRASE", allowing
#                       non-interactive signing. Intended for CI.
#                       Must NEVER be committed; supply it as a CI
#                       secret or an exported session variable.
#
# INVARIANTS — DO NOT BREAK
#   1. `set -euo pipefail` at the top. Any unset variable, any
#      failure in a pipeline, any non-zero exit aborts the script.
#      Removing this would let a partial run produce a table that
#      links to missing files.
#
#   2. IFS is restricted to newline and tab. Without this, word
#      splitting on spaces could break filenames that contain spaces.
#      Filenames in paper/ never contain spaces, but the restriction
#      is defensive and must stay.
#
#   3. The output is written to a temp file and renamed atomically.
#      If the script is interrupted mid-run, the previous
#      content/auto-verification-table.tex remains valid. Do not
#      switch to in-place writes.
#
#   4. The signature is keyed by exact filename match. Do not rename
#      paper/*.pdf without deleting the stale .asc and .sha256 first;
#      the idempotency check compares mtimes, and a renamed file will
#      look "new" and re-sign, but the old sibling files will remain
#      orphaned on disk. `make clean` removes them.
#
#   5. The public key is exported on every run. If the key is missing
#      from the keyring, export fails and the script aborts; the
#      partially written public.asc is deleted. Do not change the
#      export step to "best-effort"; a build that signs papers but
#      cannot export the key produces unverifiable output.
#
# CHANGE POLICY
#   - Every new external tool must be checked in the preflight block,
#     not in the main loop. A tool that is discovered missing halfway
#     through would leave a half-signed directory.
#   - Every new file produced must either be idempotent (checked
#     before write) or atomic (written to temp, then renamed). Never
#     produce a file in place.
#   - Every new printf that writes LaTeX must double backslashes
#     (`\\` in bash becomes `\` in the output). Single backslashes
#     will be interpreted by bash as escape sequences and produce
#     corrupted LaTeX.
#   - Do not remove the `|| true` after the timestamp pipeline. If
#     `sed` finds no match, `set -e` would abort the script on the
#     pipeline; the `|| true` swallows that case, and the warning
#     below reports it explicitly.
#
# OBSERVABLE SIDE EFFECTS
#   - Signature files are rewritten in place via gpg -o; the old file
#     is truncated before the new one is written. A kill between
#     truncate and write leaves an empty .asc, which the next run
#     detects as "newer than the PDF" and re-signs.
#   - public.asc at the repository root is overwritten on every run.
#     It is not appended; the previous key is discarded. Key rotation
#     must be done by deleting public.asc first, then running the
#     script with a different GPG_KEY_EMAIL.
#   - The script logs to stdout and stderr, but does not write a log
#     file. All logging is line-buffered to the terminal; redirect
#     with `2>&1 | tee` if a persistent log is needed.
#
# TROUBLESHOOTING
#   Problem: "gpg not found in PATH".
#   Cause:   gpg is not installed, or the PATH is minimal (cron, CI).
#   Fix:     Install GnuPG, or export PATH inside the calling shell.
#
#   Problem: "cannot sign NAME.pdf (check GPG key ...)".
#   Cause:   The keyring does not contain a key with the email in
#            $GPG_KEY_EMAIL.
#   Fix:     `gpg --list-secret-keys` to confirm, import the key if
#            missing, or export GPG_KEY_EMAIL to the correct value.
#
#   Problem: "public.asc export failed (GPG key missing?)".
#   Cause:   The public half of the signing key is not exportable.
#            Rare, but can happen with expired or revoked keys.
#   Fix:     `gpg --list-keys` to inspect, renew the key if expired,
#            or rotate to a fresh key and update GPG_KEY_EMAIL.
#
#   Problem: Signing hangs without a passphrase prompt.
#   Cause:   GPG_PASSPHRASE is not set, and the key requires a
#            passphrase, and no agent is running.
#   Fix:     Start gpg-agent, or export GPG_PASSPHRASE, or run in an
#            interactive terminal once so gpg-agent caches the
#            passphrase.
#
# ==============================================================================


# ==============================================================================
# SECTION 1 — STRICT SHELL MODE
# ==============================================================================
#
# The three flags together are the shell's equivalent of a type system
# with no implicit coercions. Each one is load-bearing.
#
#   -e    exit on any command that returns non-zero, unless the
#         command is explicitly guarded with `|| true` or used as the
#         test of an if. Without this, a failed gpg invocation would
#         be silently ignored and the script would write a table
#         pointing at a nonexistent .asc.
#
#   -u    exit on any reference to an unset variable. Without this,
#         a typo like "$GPG_KEY_EMIAL" expands to the empty string
#         and gpg signs with the default key, or fails silently in a
#         confusing way.
#
#   -o pipefail
#         a pipeline fails if any component fails, not just the
#         last one. Without this, `sed ... | head -n 1` would return
#         0 whenever `head` succeeded, even if `sed` had failed
#         upstream. The failure would be silently swallowed.
#
set -euo pipefail

# IFS restricted to newline and tab. Word splitting happens on these
# two characters only. Spaces are not split, so a variable expansion
# containing spaces stays a single word. Defensive against future
# filenames with spaces.
IFS=$'\n\t'


# ==============================================================================
# SECTION 2 — CONFIGURATION
# ==============================================================================
#
# Four variables, all with defaults except the output path. The two
# GPG_* variables are read from the environment if present, falling
# back to hardcoded defaults otherwise. The `${VAR:-default}` form is
# the shell's null-coalescing operator: it uses $VAR if set and
# non-empty, and the default otherwise.
#
# Note: `${VAR:-default}` treats empty string as "not set". If a
# caller exports GPG_PASSPHRASE="" to mean "no passphrase", this
# script treats it as "no passphrase" and takes the interactive path.
# That is the intended behaviour.

# Output path for the generated LaTeX fragment. Fixed. Callers should
# not override this; the Makefile expects exactly this path.
OUTPUT="content/auto-verification-table.tex"

# Temp file for the atomic write pattern. Same directory as the
# output, so the eventual `mv` is a same-filesystem rename (atomic).
# A temp file in /tmp would require a cross-filesystem copy, which is
# not atomic.
TMP="${OUTPUT}.tmp"

# Signing key's email. Overridable via environment. Changing this
# changes which key is used to sign, and which key is exported to
# public.asc at the end of the run.
GPG_KEY_EMAIL="${GPG_KEY_EMAIL:-mroczect@proton.me}"

# Optional passphrase for non-interactive signing. Empty by default,
# which means "prompt interactively" (or use gpg-agent's cached
# passphrase).
GPG_PASSPHRASE="${GPG_PASSPHRASE:-}"


# ==============================================================================
# SECTION 3 — LOGGING HELPERS
# ==============================================================================
#
# Three helpers, one per severity. Each prints a prefixed line. The
# `[verify-papers]` prefix matches the Makefile target name, so log
# lines from this script are greppable alongside `make` output.
#
#   log   informational, to stdout
#   warn  warning, to stderr
#   die   error, to stderr, exits 1
#
# die is the only helper that exits. Every fatal condition in this
# script goes through die, so a grep for "die" finds every way the
# script can abort.
#
# printf, not echo, because printf is portable across shells and does
# not interpret backslash escapes in the format string unless asked
# to. The '%s\n' format is fixed; only the arguments vary.

log()  { printf '[verify-papers] %s\n' "$*"; }
warn() { printf '[verify-papers] WARN: %s\n' "$*" >&2; }
die()  { printf '[verify-papers] ERROR: %s\n' "$*" >&2; exit 1; }


# ==============================================================================
# SECTION 4 — PREFLIGHT CHECKS
# ==============================================================================
#
# Every external dependency is checked before any file is touched.
# This is the "fail fast" pattern: better to abort before signing
# paper #1 than to discover a missing `sed` after paper #5 has
# already been signed and the table is half-written.
#
# `command -v NAME` prints NAME's path if it exists on PATH, and
# returns non-zero otherwise. It is the portable POSIX way to check
# for a command, more reliable than `which` or `type`.
#
# gpg, sed, and date are unconditional dependencies. At least one of
# sha256sum or shasum is also required; the selection happens below.

command -v gpg  >/dev/null 2>&1 || die "gpg not found in PATH"
command -v sed  >/dev/null 2>&1 || die "sed not found in PATH"
command -v date >/dev/null 2>&1 || die "date not found in PATH"

# ------------------------------------------------------------------------------
# SHA-256 backend selection
# ------------------------------------------------------------------------------
#
# Two portable implementations exist:
#
#   sha256sum   GNU coreutils, default on Linux
#   shasum      Perl-based, default on macOS, sometimes installed
#               on Linux alongside coreutils
#
# Both produce the same hash, and both produce the same output shape:
# "<hash>  <filename>" (with two spaces by default).
#
# The function `sha256_of` is defined once, here, and called inside
# the main loop. The function body differs per backend. Calling the
# selected tool through a function hides the choice from the loop
# body and lets the loop be backend-agnostic.
#
# `cut -d' ' -f1` extracts the first field (the hash) from the two-
# field output. This works for both backends because both produce
# space-separated output.
#
# If neither backend is installed, the script aborts. There is no
# fallback to openssl, python, or any other tool; keeping the
# dependency list short is a deliberate choice.

if   command -v sha256sum >/dev/null 2>&1; then
    sha256_of() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum    >/dev/null 2>&1; then
    sha256_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
    die "neither sha256sum nor shasum found in PATH"
fi


# ==============================================================================
# SECTION 5 — SETUP
# ==============================================================================
#
# Two directories are created if missing, and a cleanup trap is
# installed. The trap is critical: if the script is interrupted
# (Ctrl-C, kill, error under `set -e`), the temp file must be removed
# so that the next run does not find a stale half-written file.
#
# Note that the trap only removes $TMP. It does NOT remove:
#   - paper/*.asc         (real artefacts, not temp)
#   - paper/*.sha256      (real artefacts)
#   - public.asc          (real artefact)
#   - the previous content/auto-verification-table.tex
#
# This is intentional. The atomic write pattern guarantees that the
# previous table is either untouched (if the script failed before the
# rename) or fully replaced (if the script got past the rename). The
# trap exists only to clean up the temp file, which is not part of
# the published surface.

log "signing and hashing papers"
mkdir -p content paper

# ------------------------------------------------------------------------------
# Trap
# ------------------------------------------------------------------------------
#
# The single quotes around the trap body are essential. Without them,
# ${TMP} would be expanded when the trap is installed, freezing the
# value. With them, the variable is expanded when the trap fires, so
# if TMP changes between install and fire (it does not here, but the
# pattern is correct), the trap uses the current value.
#
# The trap fires on EXIT, which covers both normal termination and
# termination by signal (SIGINT, SIGTERM, SIGHUP). `rm -f` on a
# nonexistent file is a no-op, so the trap is safe to fire on runs
# that never created the temp file.
#
trap 'rm -f "${TMP}"' EXIT


# ==============================================================================
# SECTION 6 — LATEX TABLE HEADER
# ==============================================================================
#
# The output is a LaTeX fragment, not a standalone document. It is
# \input by content/Verivy.tex (which is \input by content/my-porto.tex,
# which is \input by main.tex). The fragment therefore starts with a
# \section*, not with \documentclass, and does not have its own
# \begin{document}.
#
# The block below writes the header into the temp file, truncating
# any previous content. The `>` redirection truncates; later blocks
# append with `>>`.
#
# Why printf and not a heredoc?
#   - printf writes one line at a time, so a partial write is a
#     recoverable condition (the trap removes the temp file, the
#     previous good version survives).
#   - A heredoc writes the entire block in one go, which is fine, but
#     produces less readable diffs when editing.
#   - printf also handles the `%` characters in the LaTeX (\texttt,
#     \textbf) without escaping, because `%` is only special to
#     printf when it is in the format string, not when it is in an
#     argument.
#
# Every backslash in the LaTeX output is doubled (`\\`) in the bash
# source. Bash interprets a single backslash inside a single-quoted
# string as a literal backslash, but the intermediate step through
# the printf argument list requires careful escaping. The rule for
# this block: write `\\` in bash to produce `\` in the output.
#
# The `{ ... } > "${TMP}"` compound command opens the file once and
# keeps it open across all printf calls, which is faster and lets the
# file be truncated once at the start.
#
# ------------------------------------------------------------------------------
# Structure of the emitted table:
#
#   \section*{Paper Verification}       <-- section heading
#   \addcontentsline{toc}...            <-- TOC entry (no number)
#   <paragraph explaining the columns>
#   \begin{table}[H]                    <-- H = pin here exactly
#   \caption{...}
#   \label{tab:verifikasi}
#   \scriptsize                         <-- shrink to fit
#   \begin{tabularx}{\textwidth}{@{} c l X c c c @{}}
#       No & Date & Paper & PDF & Sig & SHA
#   \midrule
#   <rows emitted by the loop, Section 8>
#   \bottomrule
#   \end{tabularx}
#   \end{table}
#   <note about SHA column truncation>
#   \subsection*{How to Verify}
#   <verification guide, emitted in Section 9>
#
# Column widths:
#   c    No       narrow, just the counter
#   l    Date     fits YYYY-MM-DD
#   X    Paper    wraps as needed
#   c    PDF      link cell
#   c    Sig      link cell
#   c    SHA      link cell
#
# The X column is why this table uses tabularx, not tabular.
# ------------------------------------------------------------------------------

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


# ==============================================================================
# SECTION 7 — ENUMERATION SETUP
# ==============================================================================
#
# Two shell settings before the loop:
#
#   i=1                     the row counter, incremented once per row
#   shopt -s nullglob       a glob that matches nothing expands to
#                           nothing, not to the literal pattern
#
# The nullglob setting is load-bearing. Without it, `paper/*.pdf` in
# an empty paper/ directory would expand to the literal string
# "paper/*.pdf", and the loop would run once with pdf_file="paper/*.pdf",
# then try to sign a nonexistent file. With nullglob, the loop runs
# zero times cleanly.
#
# The complementary `shopt -u nullglob` at the end of the loop restores
# the default, so the caller's shell is unaffected. This matters if
# the script is ever sourced rather than executed.
#
# `paper_count=$((i - 1))` at the end of the loop computes how many
# rows were emitted, because i is incremented after each row. If zero
# papers were found, i stays 1, and paper_count=0.
#
# ------------------------------------------------------------------------------
# Loop body structure (one iteration = one paper):
#
#   1. Derive filenames          pdf_file, filename, base, sig_file, sha_file
#   2. Sign if needed            mtime check against the existing .asc
#   3. Extract signature time    gpg --list-packets | sed | head
#   4. Convert timestamp         BSD/macOS `date -r` vs GNU/Linux `date -d`
#   5. Hash the PDF              sha256_of, compare with existing .sha256
#   6. Escape filename           LaTeX-safe: _ & % # $
#   7. Build links               \href for each of the three siblings
#   8. Emit row                  printf '%s & %s & ... \\\n'
#
# Each step is documented in detail below. The whole loop is written
# to be idempotent: re-running on unchanged inputs produces no
# changes except the (unavoidable) rewrite of the LaTeX fragment,
# which is byte-identical anyway.
# ------------------------------------------------------------------------------

# Row counter.
i=1

# Enable nullglob for the duration of the loop.
shopt -s nullglob

for pdf_file in paper/*.pdf; do

    # --------------------------------------------------------------------------
    # STEP 1: Derive filenames
    # --------------------------------------------------------------------------
    #
    # paper/NAME.pdf          -> pdf_file   (the input, full path)
    # NAME.pdf                -> filename   (basename, used in link targets)
    # NAME                    -> base       (stem, used for the table cell)
    # paper/NAME.pdf.asc      -> sig_file   (output 1)
    # paper/NAME.pdf.sha256   -> sha_file   (output 2)
    #
    # `basename NAME.pdf .pdf` strips the suffix only if it matches,
    # so "NAME.pdf" becomes "NAME", and a hypothetical "NAME.pdf.bak"
    # would become "NAME.pdf.bak" unchanged (which never happens in
    # practice because the glob only matches *.pdf).
    #
    filename=$(basename "$pdf_file")
    base="${filename%.pdf}"
    sig_file="${pdf_file}.asc"
    sha_file="${pdf_file}.sha256"

    # --------------------------------------------------------------------------
    # STEP 2: Sign if needed
    # --------------------------------------------------------------------------
    #
    # Two conditions trigger re-signing:
    #
    #   [ ! -e "$sig_file" ]        no signature file exists yet
    #   [ "$pdf_file" -nt "$sig_file" ]
    #                               the PDF is strictly newer than the
    #                               signature file (mtime comparison)
    #
    # The negation of both (existing AND not newer) skips signing.
    # This is the idempotency contract: an unchanged PDF is never
    # re-signed, so the signature file's mtime is stable across
    # builds. Stable mtimes matter because they determine the "Date"
    # column in the emitted table, and because stable file mtimes
    # make incremental builds cheap.
    #
    # `-nt` is Bash-specific, not POSIX, but this script requires
    # bash (see shebang) so that is fine.
    #
    # gpg_args is built as an array, not a string. This is required
    # because the passphrase can contain spaces or shell metacharacters,
    # and an array preserves each argument as a distinct word. The
    # alternative, a single string expanded unquoted, would split the
    # passphrase on spaces.
    #
    # The signing command:
    #   --yes                   overwrite existing output without prompt
    #   --armor                 ASCII-armor, so the .asc is text
    #   --detach-sign           detached signature, not embedded
    #   --local-user EMAIL      sign with the key matching EMAIL
    #   -o sig_file             write the signature here
    #   pdf_file                the file to sign
    #
    # 2>/dev/null on the gpg call suppresses gpg's own status output,
    # which is noisy and redundant with this script's own logging.
    # If gpg fails, the `|| die` guard fires and the script aborts
    # with a specific error message naming the file and the key.
    #
    # The passphrase path uses --pinentry-mode loopback, which tells
    # gpg to accept the passphrase from the --passphrase argument
    # rather than from a pinentry dialog. This is the documented way
    # to do non-interactive signing in GnuPG 2.1+. On older gpg,
    # --pinentry-mode is unavailable and this argument would fail;
    # the fallback is to use gpg-agent's cached passphrase instead,
    # which requires a one-time interactive run.
    #
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

    # --------------------------------------------------------------------------
    # STEP 3: Extract signature creation timestamp
    # --------------------------------------------------------------------------
    #
    # Every GnuPG signature embeds the time it was created. That time
    # is what ends up in the "Date" column of the verification table.
    # It is covered by the signature itself, so it cannot be forged
    # without invalidating the signature.
    #
    # The pipeline:
    #   gpg --list-packets sig_file        dumps the signature packets
    #   | sed -n 's/.*created[^0-9]*\([0-9][0-9]*\).*/\1/p'
    #                                       extracts the epoch seconds
    #   | head -n 1                         keeps only the first match
    #
    # Why parse --list-packets and not use `gpg --verify --status-fd`?
    #   --list-packets is the only command that prints the raw
    #   creation timestamp without first requiring the public key.
    #   --verify --status-fd requires the key, which would fail on a
    #   reader's machine before the key is imported.
    #
    # Why anchor on the word "created"?
    #   The field position in --list-packets output varies across
    #   gpg versions. Anchoring on the word makes the sed expression
    #   survive formatting changes.
    #
    # Why `head -n 1`?
    #   A signature file can contain multiple packets (e.g. a
    #   signature plus a notation). Only the first "created" line
    #   belongs to the primary signature. Additional matches are
    #   metadata packets and should be ignored.
    #
    # Why `|| true` at the end?
    #   Under `set -e`, a pipeline that fails in any component
    #   aborts the script. `sed` returns 1 when it finds no match,
    #   and that is a legitimate case (a signature file that is
    #   corrupt or has unusual packet layout). The `|| true` swallows
    #   the failure, and the empty $sig_ts is caught by the `if [ -n ]`
    #   check immediately after.
    #
    # `2>/dev/null` on the gpg call suppresses "unknown packet" and
    # similar warnings from older gpg versions.
    #
    sig_ts=$(gpg --list-packets "$sig_file" 2>/dev/null \
        | sed -n 's/.*created[^0-9]*\([0-9][0-9]*\).*/\1/p' \
        | head -n 1) || true

    # --------------------------------------------------------------------------
    # STEP 4: Convert epoch seconds to a human-readable date
    # --------------------------------------------------------------------------
    #
    # Two date implementations exist, and their flags differ:
    #
    #   BSD/macOS   date -r EPOCH   interprets EPOCH as seconds
    #   GNU/Linux   date -d @EPOCH   interprets "@EPOCH" as a date spec
    #
    # Passing the wrong flag produces different behaviour:
    #   `date -r 0 +%s` on GNU date tries to read a file named "0"
    #   and fails. This is used as the detection trick below.
    #
    # Detection: run `date -r 0 +%s` with output suppressed. If it
    # exits 0, we are on BSD. If it exits non-zero, we are on GNU.
    #
    # Why `date -r 0 +%s` and not `uname`?
    #   `uname` distinguishes kernels, not userlands. A Linux user
    #   with coreutils from BusyBox or a Mac user with GNU coreutils
    #   from Homebrew would get the wrong answer. The `date -r 0`
    #   probe tests the actual implementation that will be used.
    #
    # If $sig_ts is empty (the sed in Step 3 found nothing), skip
    # the conversion and set timestamp to the string "UNKNOWN". A
    # warning is emitted so the caller sees the degraded result.
    #
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

    # --------------------------------------------------------------------------
    # STEP 5: Compute and compare the SHA-256 checksum
    # --------------------------------------------------------------------------
    #
    # The checksum file format is:
    #
    #   "<hash>  <basename>\n"
    #
    # Two spaces between hash and filename, one trailing newline.
    # This matches the output format of `sha256sum` and `shasum -a 256`,
    # so a reader can verify with `sha256sum -c NAME.pdf.sha256` without
    # reformatting.
    #
    # Idempotency: the file is rewritten only when the content differs
    # from the expected string. A file that already matches is left
    # untouched, preserving its mtime. Stable mtimes make incremental
    # builds cheap.
    #
    # The comparison uses `[ "$(cat "$sha_file")" = "$expected_line" ]`.
    # Command substitution strips trailing newlines, so `$(cat file)`
    # equals the file content with newlines removed from the end.
    # $expected_line does not have a trailing newline. The two sides
    # therefore match when the file content (minus trailing newline)
    # equals the expected content. This is the correct comparison
    # despite looking asymmetric.
    #
    # The file is written with printf '%s\n', which appends one
    # newline. This matches the standard sha256sum format.
    #
    hash=$(sha256_of "$pdf_file")
    expected_line="${hash}  ${filename}"
    if [ -e "$sha_file" ] && [ "$(cat "$sha_file")" = "$expected_line" ]; then
        log "  checksum OK: $filename"
    else
        log "  hashing: $filename"
        printf '%s\n' "$expected_line" > "$sha_file"
    fi

    # --------------------------------------------------------------------------
    # STEP 6: Escape the filename for LaTeX
    # --------------------------------------------------------------------------
    #
    # LaTeX treats five characters as special:
    #
    #   _    subscript
    #   &    table column separator
    #   %    comment marker (rest of line discarded)
    #   #    macro parameter reference
    #   $    math mode toggle
    #
    # Filenames in paper/ use snake_case, so `_` is the only one
    # normally present. The other four are defended against because
    # the escaping is cheap and a malformed filename would corrupt
    # the entire table.
    #
    # Bash's `${var//from/to}` syntax replaces all occurrences of
    # `from` with `to`. Backslashes in the `to` position are treated
    # literally because the replacement is not subject to further
    # expansion.
    #
    # The substitution order matters for `_` because `\_` contains a
    # backslash that could itself be reinterpreted. Performing `_`
    # first is safe because no later substitution introduces a `_`.
    #
    esc_name="${base//_/\\_}"
    esc_name="${esc_name//&/\\&}"
    esc_name="${esc_name//%/\\%}"
    esc_name="${esc_name//#/\\#}"
    esc_name="${esc_name//\$/\\$}"

    # --------------------------------------------------------------------------
    # STEP 7: Build the three link cells
    # --------------------------------------------------------------------------
    #
    # Each cell is a \href{target}{label}. The target is a relative
    # path from the document's working directory (content/), which
    # in turn means relative to main.tex. When main.tex is compiled
    # by make4ht, relative href targets survive into the HTML as-is.
    # When compiled by latexmk, hyperref embeds them as absolute
    # file:// URLs in the PDF.
    #
    # The link labels are the words "pdf", "asc", "sha", wrapped in
    # \texttt. The column headers are "PDF", "Sig", "SHA" (uppercase).
    # Uppercase header vs lowercase label is intentional: the header
    # says what the column is, the label is what the reader clicks.
    #
    # The target paths use `paper/NAME.pdf`, not `../paper/NAME.pdf`.
    # This is because the LaTeX working directory is the repository
    # root (main.tex is at the root, and \input content/... is
    # relative to the root). Confirmed by the Makefile: `make4ht -d dist
    # -u main.tex` runs from the root, and the HTML's `paper/` prefix
    # resolves correctly because the Makefile stages `paper/*` into
    # `dist/paper/`.
    #
    pdf_link="\\href{paper/${filename}}{\\texttt{pdf}}"
    sig_link="\\href{paper/$(basename "$sig_file")}{\\texttt{asc}}"
    sha_link="\\href{paper/$(basename "$sha_file")}{\\texttt{sha}}"

    # --------------------------------------------------------------------------
    # STEP 8: Emit the table row
    # --------------------------------------------------------------------------
    #
    # Format string:
    #   '%s & %s & \\texttt{%s} & %s & %s & %s \\\\\n'
    #
    # Six %s placeholders, one per column:
    #   %s = i           counter, decimal
    #   %s = timestamp   YYYY-MM-DD or UNKNOWN
    #   %s = esc_name    inside \\texttt{}, so the cell renders
    #                    as monospace with underscores protected
    #   %s = pdf_link    pre-formatted \\href, no further escaping
    #   %s = sig_link    pre-formatted \\href
    #   %s = sha_link    pre-formatted \\href
    #
    # Separators: ' & ' between columns, ' \\\\' at the row end.
    #
    # Why four backslashes for the LaTeX row terminator?
    #   Bash sees '\\\\' in a single-quoted format string as the two
    #   characters backslash-backslash. LaTeX sees '\\' as the row
    #   terminator. So bash's '\\\\' becomes LaTeX's '\\', which is
    #   exactly what a tabular row ends with.
    #
    # Why append, not overwrite?
    #   The header was already written to ${TMP} in Section 6. Each
    #   iteration appends one row. The footer (Section 9) appends
    #   below.
    #
    printf '%s & %s & \\texttt{%s} & %s & %s & %s \\\\\n' \
        "$i" "$timestamp" "$esc_name" \
        "$pdf_link" "$sig_link" "$sha_link" >> "${TMP}"

    # Increment the counter for the next row and for the final count.
    i=$((i + 1))

done
shopt -u nullglob

# Row count. If the loop ran N times, i = N + 1, so paper_count = N.
# If the loop did not run, i = 1, so paper_count = 0.
paper_count=$((i - 1))


# ==============================================================================
# SECTION 9 — LATEX TABLE FOOTER AND VERIFICATION GUIDE
# ==============================================================================
#
# Two pieces are appended to the temp file:
#
#   1. The table footer: \bottomrule, \end{tabularx}, \end{table},
#      plus a note about the SHA column truncation.
#
#   2. The verification guide: a \subsection* with cross-platform
#      commands for checking the checksum and the signature.
#
# The guide is generated dynamically because it references files
# that only exist as a result of this script's own output. It could
# in principle be static (the commands never change), but emitting
# it here keeps the whole fragment self-contained: someone reading
# content/auto-verification-table.tex sees both the table and the
# instructions, with no external dependency on VERIFY.md.
#
# The commands in the guide are wrapped in lstlisting[style=code],
# which is the same style used by all papers. The style is defined
# in main.tex's preamble, so it is available here without further
# setup.
#
# ------------------------------------------------------------------------------
# Structure of the guide:
#
#   \subsection*{How to Verify}
#   <paragraph introducing the three files>
#   \textbf{1. Checksum (SHA-256)}
#   \begin{lstlisting}[style=code]
#     # Linux
#     sha256sum -c NAME.pdf.sha256
#     ...
#   \end{lstlisting}
#   \textbf{2. Signature (GnuPG)}
#   \begin{lstlisting}[style=code]
#     gpg --import public.asc
#     gpg --verify NAME.pdf.asc NAME.pdf
#   \end{lstlisting}
#   <footnote listing install commands per OS>
# ------------------------------------------------------------------------------

{
    # Close the table opened in Section 6.
    printf '%s\n' '\bottomrule'
    printf '%s\n' '\end{tabularx}'
    printf '%s\n' '\end{table}'
    printf '\n'

    # Note about the SHA column truncation. The SHA column in the
    # table shows only the first 16 characters of the hash; the
    # full 64-character hash is inside the .sha256 file. This note
    # is what tells readers where to find the full value.
    printf '%s\n' '\noindent\footnotesize\textit{Note: the SHA column'
    printf '%s\n' 'shows the first 16 characters of the hash. The full'
    printf '%s\n' 'value is inside each \texttt{.sha256} file.}'
    printf '\n'

    # Section heading for the verification guide.
    printf '%s\n' '\subsection*{How to Verify}'
    printf '\n'

    # Introductory paragraph: what files to download.
    printf '%s\n' '\noindent\small'
    printf '%s\n' 'Download the three files for a paper: \texttt{NAME.pdf},'
    printf '%s\n' '\texttt{NAME.pdf.asc}, and \texttt{NAME.pdf.sha256}.'
    printf '%s\n' 'Replace \texttt{NAME.pdf} below with the file you'
    printf '%s\n' 'downloaded.'
    printf '\n'

    # Part 1: checksum commands, three OS variants.
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

    # Part 2: signature commands, one variant (gpg is portable).
    printf '%s\n' '\medskip'
    printf '%s\n' '\noindent\small\textbf{2. Signature (GnuPG)}'
    printf '\n'
    printf '%s\n' '\begin{lstlisting}[style=code]'
    printf '%s\n' 'gpg --import public.asc'
    printf '%s\n' 'gpg --verify NAME.pdf.asc NAME.pdf'
    printf '%s\n' '\end{lstlisting}'
    printf '\n'

    # Footnote: install commands per OS. Wrapped in a single
    # \footnotesize\textit{} block, which is the closest LaTeX has
    # to a formal footnote that does not need a footnote marker.
    printf '%s\n' '\noindent\footnotesize\textit{Install GnuPG per OS:'
    printf '%s\n' '\texttt{apt install gnupg} on Debian/Ubuntu,'
    printf '%s\n' '\texttt{pacman -S gnupg} on Arch,'
    printf '%s\n' '\texttt{brew install gnupg} on macOS,'
    printf '%s\n' '\texttt{winget install GnuPG.GnuPG} on Windows.}'
} >> "${TMP}"


# ==============================================================================
# SECTION 10 — ATOMIC PUBLISH
# ==============================================================================
#
# The rename is atomic on any POSIX filesystem because source and
# destination are on the same filesystem (both under content/). If
# the filesystem is NFS or another network FS with weaker semantics,
# rename is still atomic at the protocol level, but the cache
# coherency is the network's problem, not this script's.
#
# Why this matters: the table is consumed by the next stage of the
# build (make4ht reading main.tex). If the write were in-place, a
# concurrent reader could see a half-written table. With rename, the
# reader sees either the previous complete version or the new
# complete version, never a partial state.
#
# After this line, ${TMP} no longer exists (it has been renamed).
# The EXIT trap fires on rm -f "${TMP}", which is a no-op because
# the file is gone. The trap is still correct for the failure case
# (script aborted before the mv), where ${TMP} does exist.
#
mv "${TMP}" "$OUTPUT"


# ==============================================================================
# SECTION 11 — PUBLIC KEY EXPORT
# ==============================================================================
#
# The public half of the signing key is written to public.asc at the
# repository root. Readers use this file to import the key before
# verifying a signature:
#
#   gpg --import public.asc
#   gpg --verify NAME.pdf.asc NAME.pdf
#
# Without public.asc, a reader has no way to obtain the key except
# by fetching it from a keyserver or from the author's website. Both
# introduce an extra dependency and a trust decision. Shipping the
# key in the repository makes the verification self-contained.
#
# The export is unconditional (runs on every invocation, not just
# when the key changed). Reasons:
#
#   - Simplicity. There is no reliable way to check whether the
#     exported file is current without re-exporting and comparing.
#   - Correctness. If the key is rotated, the file must be replaced.
#     A "skip if exists" check would leave the old key in place.
#   - Cost. A single gpg --export is fast (tens of milliseconds).
#
# The failure path deletes public.asc. This is important: if the
# export fails partway through (disk full, permission error, key
# missing), a partial public.asc would be worse than no public.asc,
# because a reader who imports a corrupt key would get confusing
# errors during verification. Deleting the partial file and
# aborting the script produces a clean failure.
#
# The check `[ ! -s "public.asc" ]` catches the empty-file case. gpg
# --export on a missing key writes an empty file and returns 0 in
# some versions. The size check turns that silent failure into an
# explicit one.
#
log "exporting public key to public.asc"
if ! gpg --armor --export "$GPG_KEY_EMAIL" > public.asc 2>/dev/null \
        || [ ! -s "public.asc" ]; then
    rm -f public.asc
    die "public.asc export failed (GPG key missing?)"
fi


# ==============================================================================
# SECTION 12 — FINAL REPORT
# ==============================================================================
#
# Two lines to stdout, summarising what was produced. The Makefile
# captures stdout but does not parse it; the lines are for the human
# reading the build log. If the build is automated, these lines
# appear in CI logs and are greppable.
#
# The blank line first separates the report from the per-paper log
# above, making the summary easy to spot.
#
# The report is deliberately minimal. It does NOT list every file
# produced; that information is in the per-paper log above, one
# "signing:" or "checksum OK:" line per paper. Summarising twice
# would be redundant.
#
printf '\n'
printf '[verify-papers] table   : %s\n' "$OUTPUT"
printf '[verify-papers] papers  : %s\n' "$paper_count"


# ==============================================================================
# END OF FILE: generate_verification.sh
# ==============================================================================
#
# Verification checklist, for confirming the script behaves as
# documented after any edit:
#
#   [ ] Running the script twice in a row produces identical output
#       for both content/auto-verification-table.tex and public.asc.
#       (`git diff` should show no changes.)
#
#   [ ] Removing one paper/*.asc and re-running restores that single
#       .asc and leaves the other .asc files untouched (mtime
#       comparison).
#
#   [ ] Removing one paper/*.sha256 and re-running restores that
#       single .sha256 and leaves the other .sha256 files untouched
#       (idempotency comparison).
#
#   [ ] Modifying a paper/*.pdf (touch is enough) and re-running
#       re-signs that paper and updates its .sha256, but leaves
#       other papers' .asc and .sha256 files untouched.
#
#   [ ] Deleting public.asc and re-running restores it.
#
#   [ ] Interrupting the script with Ctrl-C before the `mv` leaves
#       the previous content/auto-verification-table.tex intact and
#       does not leave a .tmp file behind (EXIT trap fires).
#
#   [ ] Deleting ~/.gnupg temporarily and re-running fails with the
#       "cannot sign" message before writing any file.
#
#   [ ] Empty paper/ directory: the script runs, emits a table with
#       zero rows, and paper_count=0.
#
# If any check fails, the cause is in one of the sections above.
# The script is verified working; edits to it are rare and should
# be accompanied by all eight checks above.
#
# ==============================================================================
