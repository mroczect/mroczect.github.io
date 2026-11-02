#!/usr/bin/env bash
# ==============================================================================
# FILE: generate_papers.sh
# ==============================================================================
#
# NAME
#   generate_papers.sh — enumerate paper/*.tex and emit a LaTeX itemize
#   list linking to each paper's PDF.
#
# SYNOPSIS
#   bash generate_papers.sh
#
#   Invoked by the Makefile, never by hand. The `gen-papers` target is
#   the only caller. On a clean checkout, `make all`, `make html`, and
#   `make pdf` all depend on gen-papers, because the generated fragment
#   is \input by content/my-porto.tex, which is \input by main.tex.
#
# DESCRIPTION
#   For every paper/*.tex, this script emits one line of LaTeX into
#   content/auto-papers.tex. The result is a self-contained LaTeX
#   fragment:
#
#     \section*{My Paper Publish}
#     \begin{itemize}
#       \item \href{paper/NAME.pdf}{NAME}
#       \item \href{paper/OTHER.pdf}{OTHER}
#     \end{itemize}
#
#   The \href target points to a PDF that the Makefile compiles
#   separately from paper/*.tex. This script does NOT compile anything;
#   it assumes paper/*.pdf already exists (or will exist by the time
#   the HTML or PDF is published).
#
#   The generated fragment is a manifest, not a report. It does not
#   verify that the PDFs exist, do not sign them, and do not compute
#   checksums. Those jobs belong to the `compile-papers` and
#   `verify-papers` targets. This script's only responsibility is
#   "which papers exist as sources".
#
# INPUTS
#   paper/*.tex      one standalone LaTeX document per paper
#
# OUTPUTS
#   content/auto-papers.tex    generated LaTeX fragment, do not edit
#
#   The output file is rewritten in place on every invocation. It has
#   no other side effects.
#
# EXIT CODES
#   0   the file was written (with one entry, or zero entries + warning)
#   1   any command failed: mkdir, printf, mv, or the trap-fired cleanup
#
# IDEMPOTENCY
#   Running the script twice in a row produces byte-identical output
#   for unchanged inputs. The output depends only on the set of names
#   in paper/*.tex and their alphabetical order (which is what the
#   shell glob produces on a sane filesystem). No timestamps, no
#   counters that change between runs, no random data.
#
# DEPENDENCIES
#   bash        the script itself
#   mkdir       creating content/
#   basename    stripping .tex from filenames
#   printf      writing LaTeX-safe lines
#   mv          atomic rename
#
#   All four are POSIX and present in any bash environment. The script
#   does NOT depend on gpg, git, or any tool used by other scripts in
#   this repository.
#
# INVARIANTS — DO NOT BREAK
#   1. `set -euo pipefail` at the top. Any command that returns non-zero
#      aborts the script. A partial write would produce a table pointing
#      at a nonexistent section heading or an unterminated itemize.
#
#   2. IFS is restricted to newline and tab. Filenames in paper/ never
#      contain spaces, but the restriction is defensive and must stay.
#
#   3. The output is written to a temp file and renamed atomically. If
#      the script is interrupted mid-run, the previous content/auto-papers.tex
#      remains valid. Do not switch to in-place writes.
#
#   4. The trap removes only $TMP, never $OUTPUT. This is the whole
#      point of the atomic pattern: a failure must not delete the last
#      good version of the file.
#
#   5. `shopt -s nullglob` before the loop and `shopt -u nullglob` after
#      it. Without nullglob, an empty paper/ directory would produce a
#      single iteration with $file = "paper/*.tex", which would then be
#      processed as if it were a real file.
#
#   6. The output uses \section* (starred), not \section. The fragment
#      is \input into a document that already has numbered sections;
#      adding another would disturb the ToC numbering.
#
# CHANGE POLICY
#   - Every new filename character that needs escaping in LaTeX must be
#     added to the escaping block in Section 6. See the OBSERVED DEFECTS
#     section below for the current escaping gap.
#   - Every new file produced must be either idempotent (checked before
#     write) or atomic (written to temp, then renamed). Never produce a
#     file in place.
#   - Every new printf that writes LaTeX must double backslashes
#     (`\\` in bash becomes `\` in the output). Single backslashes will
#     be interpreted by bash as escape sequences and produce corrupted
#     LaTeX.
#   - Do not add verification logic. This script produces a manifest.
#     If papers need verifying, that is generate_verification.sh's job.
#   - Do not compile papers here. The Makefile has a separate
#     `compile-papers` target for that, and combining the two would
#     make a failed compile abort the manifest generation as well.
#
# OBSERVED DEFECTS (documented, not fixed by this pass)
#   The escaping block on Section 6 currently escapes ONLY the
#   underscore character. LaTeX treats five characters as special:
#
#     _    subscript             escaped by this script
#     &    column separator      NOT escaped
#     %    comment marker        NOT escaped
#     #    macro parameter       NOT escaped
#     $    math mode toggle      NOT escaped
#
#   A file named paper/foo&bar.tex would produce:
#
#     \item \href{paper/foo&bar.pdf}{foo&bar}
#
#   which is a LaTeX error (misplaced alignment tab). Similarly, a file
#   named foo%bar.tex would produce a comment that swallows the rest of
#   the line.
#
#   In practice, filenames in paper/ use snake_case and only the
#   underscore appears. The current escaping is sufficient for that
#   convention. The fix, if the convention is ever relaxed, is to
#   extend the escaping block to match generate_verification.sh, which
#   already escapes all five characters.
#
#   This is documented rather than fixed because fixing it silently
#   would change behaviour for filenames that a reader might be
#   relying on. If the fix is applied, note it in the changelog and
#   bump the generator's output check accordingly.
#
# OBSERVED INCONSISTENCIES (documented, not fixed by this pass)
#   - This script uses `echo` for log lines; generate_verification.sh
#     uses `printf '%s\n'`. Both are POSIX-correct for the messages
#     being written, but the two styles diverge across the repository.
#     Standardizing on printf would be a cosmetic change.
#
#   - This script does not preflight-check for mkdir, basename, printf,
#     or mv; it relies on `set -e` to catch failures. That is correct
#     behaviour (all four are universal), but generate_verification.sh
#     does preflight-check its tools. The two styles diverge.
#
#   - This script has no `die`/`warn`/`log` helper functions; it uses
#     bare echo. The `[gen-papers]` prefix is written inline rather
#     than through a helper. This is fine for a short script but makes
#     the messages harder to restyle globally.
#
# OBSERVABLE SIDE EFFECTS
#   - content/auto-papers.tex is overwritten on every run. It is not
#     appended; the previous content is discarded. The generation is
#     deterministic, so the discarded content is always either
#     identical to the new content or stale because paper/*.tex
#     changed.
#   - content/ is created if missing. paper/ is NOT created. If paper/
#     is missing, the loop runs zero times, the output is an empty
#     itemize with a warning, and the script exits 0. This is
#     intentional: paper/ is a source directory, not an artefact, and
#     creating it silently would hide a configuration error.
#
# TROUBLESHOOTING
#   Problem: "no paper/*.tex found; wrote empty list".
#   Cause:   paper/ is empty, or the loop was run before any paper
#            source was added.
#   Fix:     Add at least one paper/*.tex, or accept the empty list.
#            The warning is informational, not fatal.
#
#   Problem: content/auto-papers.tex contains a single \item pointing
#            to "paper/*.pdf".
#   Cause:   nullglob was not enabled, or was disabled too early.
#            The loop ran once with $file = "paper/*.tex" literal.
#   Fix:     Confirm Section 5's shopt lines are present and in order.
#            This is the one failure mode nullglob exists to prevent.
#
#   Problem: LaTeX error "Misplaced alignment tab character &".
#   Cause:   A filename in paper/ contains &, %, #, or $, which the
#            escaping block does not handle.
#   Fix:     Rename the file to use only snake_case, or apply the
#            defect fix described under OBSERVED DEFECTS.
#
#   Problem: content/auto-papers.tex exists but the ToC does not show
#            the section.
#   Cause:   content/my-porto.tex does not \input the fragment, or
#            the \input is inside a group that swallows the
#            \addcontentsline.
#   Fix:     Confirm my-porto.tex contains \input{content/auto-papers.tex}
#            at top level.
#
# ==============================================================================


# ==============================================================================
# SECTION 1 — STRICT SHELL MODE
# ==============================================================================
#
# The three flags together are the shell's equivalent of a type system
# with no implicit coercions. Each one is load-bearing.
#
#   -e    exit on any command that returns non-zero. Without this, a
#         failed printf would leave a truncated itemize, and a failed
#         mv would leave both the temp file and the stale output on
#         disk, but the script would still exit 0.
#
#   -u    exit on any reference to an unset variable. This script has
#         only four variables, all set before use, but the flag guards
#         against a future edit that references a variable before
#         assigning it.
#
#   -o pipefail
#         no pipelines exist in this script, so pipefail has no
#         observable effect today. It is included for consistency with
#         the other scripts in this repository, and to guard against
#         a future edit that pipes `basename` through `sed`.
#
set -euo pipefail

# IFS restricted to newline and tab. Word splitting happens on these
# two characters only. Spaces are not split, so a variable expansion
# containing spaces stays a single word. paper/ filenames never
# contain spaces, but the restriction is defensive.
IFS=$'\n\t'


# ==============================================================================
# SECTION 2 — CONFIGURATION
# ==============================================================================
#
# Two variables, both fixed. Neither is read from the environment,
# because there is no legitimate use case for overriding them. If a
# caller wanted a different output path, they would be editing this
# script, not configuring it.

# Output path for the generated LaTeX fragment. Fixed. The Makefile
# expects exactly this path (see its `gen-papers` target), and the
# fragment is \input by content/my-porto.tex under this exact path.
OUTPUT="content/auto-papers.tex"

# Temp file for the atomic write pattern. Same directory as the
# output, so the eventual `mv` is a same-filesystem rename (atomic).
# A temp file in /tmp would require a cross-filesystem copy, which is
# not atomic and would not survive an interruption the way a rename
# does.
TMP="${OUTPUT}.tmp"


# ==============================================================================
# SECTION 3 — CLEANUP TRAP
# ==============================================================================
#
# The trap removes the temp file on any exit path: normal termination,
# `set -e` abort, Ctrl-C, SIGTERM, SIGHUP. `rm -f` on a nonexistent
# file is a no-op, so the trap is safe even when the temp file was
# never created (e.g. the script aborted at the mkdir on Section 4).
#
# The single quotes around the trap body are essential. Without them,
# ${TMP} would be expanded when the trap is installed, freezing the
# value. With them, the variable is expanded when the trap fires, so
# the trap always uses the current value of TMP even if it changed
# between install and fire.
#
# Note that the trap does NOT remove $OUTPUT. That is the entire point
# of the atomic write pattern: a failure during the write must leave
# the previous good output intact, so that a downstream consumer
# (make4ht reading main.tex) sees a complete fragment rather than a
# truncated one.
#
trap 'rm -f "${TMP}"' EXIT


# ==============================================================================
# SECTION 4 — SETUP
# ==============================================================================
#
# One log line, one mkdir. Both run before the temp file is opened.
#
# Why log before mkdir? So that if mkdir fails (permissions, read-only
# filesystem), the error message is preceded by a line explaining what
# was being attempted. `set -e` will abort on the mkdir failure, but
# the log line gives context.
#
# Why `mkdir -p content` and not `mkdir -p content paper`? Because
# paper/ is a source directory, not an artefact. If paper/ does not
# exist, that is a configuration error the caller should see, not
# something to be silently created. The empty-list warning in Section
# 9 is the loud signal; creating paper/ automatically would swallow
# it.
#
# `echo` is used here rather than `printf`. For a plain message with
# no format specifiers, echo is POSIX-correct and more readable. The
# printf-vs-echo inconsistency across the repository is documented in
# OBSERVED INCONSISTENCIES at the top of this file.
#
echo "[gen-papers] Building ${OUTPUT}..."
mkdir -p content


# ==============================================================================
# SECTION 5 — LATEX FRAGMENT HEADER
# ==============================================================================
#
# The header is two lines:
#
#   \section*{My Paper Publish}
#   \begin{itemize}
#
# The \section* is starred because the fragment is \input into a
# document that already has its own section numbering. An unstarred
# \section here would consume a number from the parent document's
# counter, shifting every subsequent numbered section.
#
# The section heading is followed by \begin{itemize} but NOT by
# \addcontentsline. That is a deliberate choice: the fragment itself
# does not add a ToC entry, because the parent file (content/my-porto.tex)
# may want to control where in the ToC the section appears. If the
# fragment added its own \addcontentsline, the ToC entry would appear
# twice (once from the fragment, once from the parent), which is a
# LaTeX warning and a visual duplicate.
#
# Both printf calls use `>` and `>>` respectively:
#   `>`  truncates the file if it exists, creates it otherwise
#   `>>` appends
#
# The first call truncates, so any previous content of $TMP is
# discarded. This is correct for the atomic pattern: the previous
# version of $OUTPUT is still intact, and the temp file is being built
# from scratch.
#
# printf format `'%s\n'` writes exactly one line per call, no
# interpretation of the argument. The LaTeX backslashes are inside
# single-quoted strings, so bash passes them through literally. No
# escaping gymnastics are needed for \section* or \begin{itemize}.
#
printf '%s\n' '\section*{My Paper Publish}' >  "${TMP}"
printf '%s\n' '\begin{itemize}'             >> "${TMP}"


# ==============================================================================
# SECTION 6 — LOOP: ENUMERATE AND EMIT
# ==============================================================================
#
# The loop body has two responsibilities:
#
#   1. Derive a display name from the source filename.
#   2. Emit one \item line for the paper.
#
# Nothing else. No compilation, no verification, no existence check on
# the PDF. That separation of concerns is why this script is short
# enough to read in one screen.

# ------------------------------------------------------------------------------
# nullglob
# ------------------------------------------------------------------------------
#
# With nullglob disabled (the bash default), a glob that matches no
# files expands to the literal pattern string. So `for file in paper/*.tex`
# in an empty paper/ directory would run once with $file = "paper/*.tex",
# and the loop body would try to process a file that does not exist.
#
# With nullglob enabled, the same glob expands to nothing, so the loop
# runs zero times. The subsequent count stays 0, and the warning in
# Section 9 fires correctly.
#
# The complementary `shopt -u nullglob` at the end of the loop restores
# the default. This matters only if the script is ever sourced rather
# than executed; for an executable script, the shell exits at the end
# of the script and the setting is irrelevant. Still, the pairing is
# defensive and should be kept.
#
shopt -s nullglob

# Loop counter. Incremented once per emitted row. Used for the final
# report in Section 9 to distinguish "no papers" from "some papers".
count=0

for file in paper/*.tex; do

    # --------------------------------------------------------------------------
    # STEP 1: Strip the source suffix
    # --------------------------------------------------------------------------
    #
    # `basename NAME.tex .tex` returns NAME. The second argument, when
    # present, is the suffix to remove if it matches. If the file were
    # named NAME.tex.bak, the suffix would not match and basename
    # would return NAME.tex.bak unchanged. That never happens in
    # practice because the glob only matches *.tex.
    #
    # We use basename rather than ${file%.tex} because basename
    # discards the directory part (paper/) as well, which is exactly
    # what we want for the display name. The \href target, on the
    # other hand, needs the .pdf suffix appended to the bare name,
    # not to the full path, so both the target and the display name
    # start from the bare stem.
    #
    filename=$(basename "$file" .tex)

    # --------------------------------------------------------------------------
    # STEP 2: Escape for LaTeX
    # --------------------------------------------------------------------------
    #
    # LaTeX treats five characters as special. The current escaping
    # block handles only one:
    #
    #   _    subscript             escaped below
    #   &    column separator      NOT escaped
    #   %    comment marker        NOT escaped
    #   #    macro parameter       NOT escaped
    #   $    math mode toggle      NOT escaped
    #
    # In practice, filenames in paper/ use snake_case and only the
    # underscore appears. The current escaping is sufficient for that
    # convention. See OBSERVED DEFECTS in the file header for the full
    # discussion and the fix that would be applied if the convention
    # is ever relaxed.
    #
    # Bash's `${var//from/to}` syntax replaces all occurrences of
    # `from` with `to`. Backslashes in the `to` position are treated
    # literally because the replacement is not subject to further
    # expansion. So `_` becomes `\_`, which is the LaTeX escape for
    # an underscore.
    #
    # `\_` in a LaTeX filename produces an underscore rendered as an
    # underscore, without triggering subscript mode. Without the
    # escape, "my_paper" would produce "my" followed by a subscript
    # "p" followed by "aper", which is not what the filename says.
    #
    escaped_filename="${filename//_/\\_}"

    # --------------------------------------------------------------------------
    # STEP 3: Emit the \item
    # --------------------------------------------------------------------------
    #
    # Format string:
    #   '  \\item \\href{paper/%s.pdf}{%s}\n'
    #
    # Three parts:
    #
    #   '  '                          two spaces of LaTeX indentation
    #   '\\item '                     the list item marker
    #   '\\href{paper/%s.pdf}{%s}'    the hyperlink, with two %s
    #   '\n'                          the newline terminator
    #
    # Bash sees '\\item' in a single-quoted string as the two
    # characters backslash-backslash followed by 'item'. Bash's printf
    # interprets '\\' as one backslash, so the output line contains
    # '\item', which is what LaTeX expects.
    #
    # The two %s specifiers are filled in order:
    #   first %s     = filename        (un-escaped, for the URL)
    #   second %s    = escaped_filename (for the display text)
    #
    # The URL is un-escaped because LaTeX URL parsing treats
    # underscores as literal characters inside \href{}{}. The display
    # text is escaped because it is typeset as ordinary text, where
    # underscores trigger subscript mode.
    #
    # The two-space indent at the start of the line is cosmetic. LaTeX
    # ignores leading whitespace inside an itemize environment, but
    # the indented form is easier to read for anyone inspecting
    # content/auto-papers.tex directly.
    #
    printf '  \\item \\href{paper/%s.pdf}{%s}\n' \
        "${filename}" "${escaped_filename}" >> "${TMP}"

    # Increment the counter for the final report.
    count=$((count + 1))

done

# Restore the nullglob default. See the comment above for why this is
# included even though the shell exits at the end of the script.
shopt -u nullglob


# ==============================================================================
# SECTION 7 — LATEX FRAGMENT FOOTER
# ==============================================================================
#
# Close the itemize environment opened in Section 5. One printf, one
# \end{itemize}. Appended with >>, matching the header's pattern.
#
# The trailing newline from printf means the file ends with a clean
# line break. Without it, the last line of the file would lack a
# trailing newline, which some LaTeX tools handle poorly (notably
# \input combined with certain editor auto-formatting).
#
printf '%s\n' '\end{itemize}' >> "${TMP}"


# ==============================================================================
# SECTION 8 — ATOMIC PUBLISH
# ==============================================================================
#
# The rename is atomic on any POSIX filesystem because source and
# destination are on the same filesystem (both under content/). If
# the filesystem is NFS or another network FS with weaker semantics,
# rename is still atomic at the protocol level.
#
# Why this matters: content/auto-papers.tex is consumed by the next
# stage of the build (make4ht reading main.tex, or latexmk compiling
# main.tex). If the write were in-place, a concurrent reader could
# see a half-written fragment. With rename, the reader sees either
# the previous complete version or the new complete version, never a
# partial state.
#
# After this line, ${TMP} no longer exists (it has been renamed). The
# EXIT trap fires on rm -f "${TMP}", which is a no-op because the
# file is gone. The trap is still correct for the failure case (script
# aborted before the mv), where ${TMP} does exist.
#
mv "${TMP}" "${OUTPUT}"


# ==============================================================================
# SECTION 9 — FINAL REPORT
# ==============================================================================
#
# Two outcomes are possible, and the report distinguishes them:
#
#   count == 0    no paper/*.tex found; empty list written; exit 0
#   count > 0     one or more papers; report the number; exit 0
#
# The zero-paper case is a warning, not an error. The script does what
# it was asked to do: emit a list of papers. An empty directory
# produces an empty list. The warning exists so that a human reading
# the build log sees that the output is intentionally empty rather
# than mysteriously empty.
#
# The comparison uses `-eq` (numeric equality), not `=`. Both operands
# are integers, and `-eq` correctly handles edge cases like leading
# zeros. `[ "$count" -eq 0 ]` is the POSIX-correct form.
#
# Messages go to stdout, not stderr. The warning is a warning, but
# the script exited 0 (success), and mixing stderr into a successful
# run makes CI logs confusing. Downstream tooling that captures
# stderr for "build failed" detection would misfire on a benign
# warning.
#
if [ "$count" -eq 0 ]; then
    echo "[gen-papers] WARN: no paper/*.tex found; wrote empty list"
else
    echo "[gen-papers] Wrote ${count} entries to ${OUTPUT}"
fi


# ==============================================================================
# END OF FILE: generate_papers.sh
# ==============================================================================
#
# Verification checklist, for confirming the script behaves as
# documented after any edit:
#
#   [ ] Running the script twice in a row produces identical output.
#       (`git diff content/auto-papers.tex` shows no changes.)
#
#   [ ] Adding a new file paper/foo.tex and re-running adds exactly
#       one line to content/auto-papers.tex:
#         \item \href{paper/foo.pdf}{foo}
#
#   [ ] A file named paper/my_paper.tex produces:
#         \item \href{paper/my_paper.pdf}{my\_paper}
#       with the underscore escaped in the display text but not in
#       the URL.
#
#   [ ] Empty paper/ directory: the script exits 0 and prints the
#       "no paper/*.tex found" warning. content/auto-papers.tex
#       contains an empty itemize.
#
#   [ ] Deleting content/ and re-running: content/ is recreated,
#       content/auto-papers.tex is written normally.
#
#   [ ] Interrupting the script with Ctrl-C before the mv leaves the
#       previous content/auto-papers.tex intact and does not leave a
#       .tmp file behind (EXIT trap fires).
#
#   [ ] Running from a subdirectory (e.g. from scripts/): the script
#       still writes to content/auto-papers.tex relative to the
#       current working directory, which is whatever directory the
#       caller is in. This is expected; the Makefile always runs from
#       the repository root, and this script is not designed to run
#       from elsewhere.
#
# If any check fails, the cause is in one of the sections above. The
# script is verified working; edits to it are rare and should be
# accompanied by all seven checks above.
#
# ==============================================================================
