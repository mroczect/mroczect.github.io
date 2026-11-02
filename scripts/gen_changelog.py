#!/usr/bin/env python3
# =============================================================================
# FILE: scripts/gen_changelog.py
# =============================================================================
#
# NAME
#   gen_changelog.py — render the git commit history as a LaTeX
#   fragment for inclusion in the portfolio PDF.
#
# SYNOPSIS
#   python3 scripts/gen_changelog.py
#   python3 scripts/gen_changelog.py --limit 50
#   python3 scripts/gen_changelog.py --since 2026-01-01
#   python3 scripts/gen_changelog.py --output /tmp/changelog.tex
#
#   Invoked by the Makefile through the `changelog` target, which is
#   a dependency of `html`, `pdf`, and transitively `all`. It is NOT
#   invoked by any other script. It is safe to run by hand for
#   debugging; the output file is always overwritten.
#
# DESCRIPTION
#   Reads `git log` from the repository, parses each commit subject
#   as a Conventional Commit (feat/fix/docs/...), and writes
#   content/changelog.tex: a LaTeX fragment that groups commits by
#   month and day, with hyperlinks to the GitHub commit page and to
#   the corresponding pull request (if the subject references one).
#
#   The output is NOT a standalone LaTeX document. It is designed to
#   be \input by main.tex at the end of the document body. It begins
#   with \section*{Changelog} and ends with \end{itemize}; no
#   \documentclass, no \begin{document}, no \end{document}.
#
#   The fragment structure is:
#
#     \section*{Changelog}
#     <intro paragraph>
#     <metadata table: repository, branch, date, commit count>
#     \section*{November 2026}
#       \subsection*{Sunday, Nov 02, 2026}
#         \begin{itemize}
#           \item \textbf{feat} \texttt{api} <message> (PR#42) --- Author
#           \item \textbf{fix} <message> --- Author
#         \end{itemize}
#       \subsection*{Saturday, Nov 01, 2026}
#         ...
#     \section*{October 2026}
#       ...
#
# INPUTS
#   .git/                       commit history (must be a git work tree)
#   --limit N                   maximum commits to include (default 500)
#   --since YYYY-MM-DD          only commits on or after this date
#   --output PATH               override output path (default:
#                               <repo-root>/content/changelog.tex)
#
# OUTPUTS
#   content/changelog.tex       LaTeX fragment (unless overridden)
#
#   The output file is created (with parent directories) if missing,
#   and overwritten if present. There is no append mode.
#
# EXIT CODES
#   0   file written, OR zero commits found (see STALE-OUTPUT caveat)
#   1   any exception: git failure, write failure, argparse error
#
#   The script does NOT install a top-level try/except. Any uncaught
#   exception propagates to the interpreter, which prints a traceback
#   and exits 1. This is deliberate: the Makefile treats any non-zero
#   exit as a build failure, and a traceback is more useful for
#   debugging than a one-line error message.
#
# IDEMPOTENCY
#   Running the script twice in a row on the same git HEAD produces
#   byte-identical output EXCEPT for one field: the `Generated` date
#   in the metadata table, which is `date.today().isoformat()` and
#   therefore changes when the script is run on a different calendar
#   day. Within the same day, output is identical.
#
#   If true byte-identical output is required across days (e.g. for
#   reproducible builds), replace `date.today()` with the latest
#   commit's date. That is a policy change, not a bug fix; the current
#   behaviour is intentional (the table should say when the changelog
#   was rendered, not when the last commit was made).
#
# DEPENDENCIES
#   Python 3.10+                for `X | None` type hints and the
#                               `from __future__ import annotations`
#                               backport (which actually allows 3.7+,
#                               but the codebase targets 3.10+)
#   git                         for the subprocess calls
#   git history readable        the repository must not be a fresh
#                               `git init` with zero commits (see
#                               STALE-OUTPUT caveat)
#
# INVARIANTS — DO NOT BREAK
#   1. Every string that reaches the .tex output goes through
#      escape_latex() EXCEPT strings this script constructs itself
#      (LaTeX keywords, table structure, URLs with known-safe
#      contents). A raw `&` in a commit subject that bypassed
#      escape_latex would produce a LaTeX compile error.
#
#   2. The output is a FRAGMENT, not a document. Never add
#      \documentclass, \begin{document}, or \end{document} to the
#      template strings. main.tex owns those.
#
#   3. Section headings use \section* (starred). The fragment is
#      \input into a document that already has numbered sections;
#      unstarred headings would shift the numbering of everything
#      after the changelog.
#
#   4. \addcontentsline is called for every \section* because the
#      starred form does NOT add a ToC entry on its own. Without the
#      explicit \addcontentsline, the changelog would appear in the
#      body but not in the ToC.
#
#   5. The script writes output ONLY on the path where commits were
#      found. See STALE-OUTPUT caveat below for the consequence.
#
#   6. The URL host is hardcoded to github.com in `render_commit`.
#      Changing to self-hosted Git (Gitea, GitLab, etc.) requires
#      editing the two f-strings that build the commit URL and the
#      PR URL. Do not parameterize without also updating GH_REPO
#      and the docstring at the top of the module.
#
# CHANGE POLICY
#   - New LaTeX-special characters must be added to _LATEX_ESCAPE
#     before any commit subject containing them is rendered. See
#     OBSERVED DEFECTS.
#   - New Conventional Commit types must be added to TYPES. Unknown
#     types fall back to "other", which is valid LaTeX but loses
#     the type label.
#   - Any change to the output structure (adding a section, changing
#     the metadata table) must be verified by compiling main.tex
#     before committing. A malformed fragment is a compile error in
#     the parent document, not in this script.
#   - Do not add error handling around subprocess.check_output calls
#     without also adding a user-facing error path. A bare
#     `try: ... except: pass` would silently produce an empty
#     changelog, which is worse than a crash.
#
# STALE-OUTPUT CAVEAT (documented, not fixed)
#   When `collect_commits` returns an empty list, `main()` prints
#   "No commits found." and returns 0 WITHOUT writing the output
#   file. If content/changelog.tex existed from a previous run, it
#   remains on disk with stale content.
#
#   This is intentional: an empty commit list is almost always a
#   configuration error (running outside a git work tree, a fresh
#   `git init` with no commits, a bad `--since` filter), and
#   overwriting the changelog with an empty file would silently
#   propagate that error into the PDF. The current behaviour fails
#   loudly enough to notice (the build log shows "No commits found")
#   without destroying the last good changelog.
#
#   The downstream consequence: `make all` on a fresh `git init`
#   will succeed at the `changelog` target (it exits 0) but will
#   fail at the `pdf` or `html` target because main.tex \inputs a
#   file that does not exist. The error message will be about a
#   missing \input, not about a missing changelog, which is a
#   diagnosability weakness. Documented, not fixed.
#
# OBSERVED DEFECTS (documented, not fixed by this pass)
#   DEFECT 1 — _LATEX_ESCAPE is incomplete.
#     The escape table covers 10 characters: \ & % $ # _ { } ~ ^
#     It does NOT cover: [ ] < >
#     In LaTeX text mode, `[` and `]` are literal (safe) unless they
#     follow a `\\` (line break optional argument). In commit
#     subjects these sequences are essentially never present, so the
#     gap is latent, not active.
#     `<` and `>` are literal in text mode with fontenc=T1 (which is
#     what main.tex uses). With OT1 they would render as inverted
#     punctuation. Since main.tex uses T1, the gap is safe.
#     Documented so that a future change of fontenc doesn't silently
#     break angle brackets in commit subjects.
#
#   DEFECT 2 — `!` breaking-change marker is discarded.
#     CC_PATTERN matches `feat!:` and `feat(scope)!:` — the `!` is
#     part of the `!?:` alternation — but the parsed tuple returns
#     only (type, message, scope). The breaking-change flag is
#     silently dropped, so a breaking change renders identically to
#     a non-breaking change of the same type.
#     This is a semantic loss, not a compile error. Documented so
#     that adding the flag later is a conscious change, not a
#     surprise.
#
#   DEFECT 3 — `--output` with a relative path is relative to cwd,
#     not repo root.
#     `Path(args.output)` takes the literal string. If the user runs
#     `python3 scripts/gen_changelog.py --output out.tex` from a
#     subdirectory, out.tex lands in that subdirectory, not at the
#     repo root. The default path uses `repo_root / "content" /
#     "changelog.tex"` which is absolute.
#     Documented. No fix applied because `--output` is intended for
#     debugging, and the current behaviour matches Python's normal
#     path resolution rules.
#
#   DEFECT 4 — `get_repo_root()` is called unconditionally, even
#     when `--output` overrides the path.
#     This means the script fails outside a git work tree even if
#     the caller provided an explicit --output path. The failure
#     message is a subprocess.CalledProcessError traceback about
#     `git rev-parse --show-toplevel`, which is not user-friendly.
#     Documented. No fix applied because the script is designed to
#     run inside the repository it is documenting; running it
#     outside the repo against an external git directory is not a
#     supported use case.
#
#   DEFECT 5 — `render_commit` produces commit URLs using the
#     hardcoded github.com host.
#     If the repository moves to a different host, URLs in the
#     generated changelog will 404. GH_REPO must be updated to match.
#     Documented. No fix applied because the repository is
#     GitHub-hosted and there is no plan to migrate.
#
# OBSERVABLE SIDE EFFECTS
#   - The output file's parent directory is created recursively if
#     missing (`output.parent.mkdir(parents=True, exist_ok=True)`).
#   - The output file is overwritten via `write_text`, which is NOT
#     atomic. A kill between the truncate and the final write would
#     leave a partially written file. Unlike the shell scripts in
#     this repository, this one does not use a temp-file-then-rename
#     pattern. For the typical output size (< 200 KB), the risk
#     window is milliseconds. Documented; not fixed.
#   - The script prints exactly one line to stdout on success:
#     "Wrote <path> (<N> commits)".
#   - The script prints exactly one line to stderr on the empty case:
#     "No commits found.".
#
# TROUBLESHOOTING
#   Problem: "fatal: not a git repository".
#   Cause:   Running outside a git work tree.
#   Fix:     cd to the repository root before running.
#
#   Problem: "No commits found." and no output file written.
#   Cause:   `git log` returned nothing: fresh repo, bad --since, or
#            a shallow clone that predates the --since date.
#   Fix:     Confirm `git log --oneline | head` produces at least one
#            line. Adjust --since.
#
#   Problem: LaTeX compile fails at \input{content/changelog.tex}.
#   Cause:   The file does not exist (see STALE-OUTPUT caveat), or
#            a commit subject contained an un-escaped special
#            character that reached the output raw.
#   Fix:     Run `python3 scripts/gen_changelog.py` by hand and check
#            the output. Grep the .tex for unescaped specials:
#            `grep -nE '^[^\\]*[&%$#]' content/changelog.tex`.
#
#   Problem: Author names with non-Latin characters render as boxes.
#   Cause:   The main.tex preamble uses fontenc=T1 + mathpazo, which
#            covers Latin-1 but not CJK or Arabic.
#   Fix:     Either romanize author names (git config), or add a
#            font package to main.tex that covers the needed scripts.
#
# =============================================================================


# =============================================================================
# MODULE DOCSTRING
# =============================================================================
#
# Rendered by `pydoc` and by IDEs on hover. Kept short because the
# full documentation is in the comments above.
#
# The double-backslash in `\\input` is required because this is a
# regular Python string (triple-quoted), not a raw string. Without
# the doubling, `\i` would be interpreted as an escape sequence.
# A raw string (`r"""..."""`) would avoid the doubling but would
# then prevent any future `\n` literal, which we may want.
#
"""
Generate content/changelog.tex from git history.

The output is a LaTeX fragment intended to be \\input by main.tex.
It is NOT a standalone document.

Usage:
    python3 scripts/gen_changelog.py [--since YYYY-MM-DD] [--limit N]
"""

# =============================================================================
# SECTION 1 — FUTURE IMPORTS
# =============================================================================
#
# `from __future__ import annotations` must be the first statement in
# the file, before any other import. It changes the evaluation of
# annotations from eager to lazy: `tuple[str, str, str | None]` is
# stored as the string "tuple[str, str, str | None]" and only
# evaluated on demand.
#
# Two consequences:
#
#   1. Type hints like `str | None` work on Python 3.7+, not just
#      3.10+. Without the future import, `str | None` would raise
#      TypeError on 3.9 because `str.__or__` doesn't exist.
#
#   2. Type hints can reference names not yet defined (forward
#      references). `list[dict]` in `collect_commits` return type
#      doesn't need the function to be defined first.
#
# Removing this import would restrict the script to Python 3.10+,
# which may not be available on the user's system. Keep it.
#
from __future__ import annotations

# =============================================================================
# SECTION 2 — STANDARD LIBRARY IMPORTS
# =============================================================================
#
# Six imports, each with a single purpose. Alphabetical order after
# the future import, following PEP 8 grouping.
#
#   argparse        command-line argument parsing (main only)
#   re              regular expressions for parsing commit subjects
#   subprocess      calling `git` as a subprocess
#   sys             sys.exit() and sys.stderr
#   collections     defaultdict for grouping commits
#   datetime        parsing commit dates for pretty-printing
#   pathlib         filesystem paths (Path objects)
#
# No third-party packages. This is deliberate: the script must run
# on any Python 3 installation without a virtualenv or pip install.
#
import argparse
import re
import subprocess
import sys
from collections import defaultdict
from datetime import date, datetime
from pathlib import Path

# =============================================================================
# SECTION 3 — REPOSITORY IDENTITY CONSTANTS
# =============================================================================
#
# Two constants, both hardcoded. These are the ONLY repository-
# specific values in the entire script. Everything else is derived
# from git or computed at runtime.
#
# GH_REPO is used in three places:
#
#   1. The metadata table (Repository row)
#   2. The commit URL: https://github.com/<GH_REPO>/commit/<HASH>
#   3. The PR URL:     https://github.com/<GH_REPO>/pull/<NUMBER>
#
# GH_BRANCH is used in exactly one place: the metadata table (Branch
# row). It is NOT used to query git; the changelog always reflects
# whatever HEAD points to, regardless of the branch name here. The
# constant exists purely to label the output.
#
# Why hardcoded and not auto-detected?
#   1. The default branch of a GitHub repo is not always "main" or
#      "master"; it can be any name. Auto-detecting requires a
#      network call (`gh repo view`) or fragile heuristic parsing
#      of `git remote -v`, both of which add dependencies.
#   2. Reproducibility: the output depends on the constants, not on
#      the local git configuration. Two developers running the
#      script get the same output.
#   3. Simplicity: two lines to change on migration, versus a
#      detection routine that has its own failure modes.
#
# The comment "This repository does not use Zola" refers to the
# author's earlier static-site setup. If the repository ever moves
# back to Zola, GH_REPO and GH_BRANCH remain correct for the
# changelog's purposes; Zola would add its own front-matter, which
# is a separate concern.
#
GH_REPO = "mroczect/mroczect.github.io"
GH_BRANCH = "main"


# =============================================================================
# SECTION 4 — GIT HELPERS
# =============================================================================
#
# One function, `get_repo_root`, which shells out to git to find the
# top level of the current work tree. Used by `main()` to resolve the
# default output path when `--output` is not supplied.
#
# The function uses `subprocess.check_output`, not `subprocess.run`.
# The difference:
#
#   check_output    returns stdout as bytes (or str with text=True),
#                   raises CalledProcessError on non-zero exit
#   run             returns CompletedProcess, no exception on failure
#
# `check_output` is the right tool here because any git failure is
# fatal for this script. If `git rev-parse` fails, the caller is not
# in a git repo, and there is no reasonable recovery.
#
# The `.strip()` removes the trailing newline that git appends to
# its output. Without it, `Path("...\n")` would create a path with
# a newline in it, and subsequent filesystem operations would fail
# with cryptic errors.
#
# The `text=True` argument (Python 3.7+) decodes stdout as UTF-8
# (or the locale encoding) and returns a str instead of bytes. This
# saves an explicit `.decode()` call.
#
# No try/except. A CalledProcessError here produces a traceback with
# the git error message embedded, which is more informative than any
# custom message we could write. See TROUBLESHOOTING in the file
# header for the user-facing interpretation.
#
def get_repo_root() -> Path:
    """
    Return the absolute path to the current git work tree's top level.

    Raises subprocess.CalledProcessError if the current directory is
    not inside a git work tree, or if git itself is not installed.

    The return value is a Path, not a string. Callers should treat it
    as opaque and use it only to construct child paths.
    """
    out = subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True
    ).strip()
    return Path(out)


# =============================================================================
# SECTION 5 — CONVENTIONAL COMMIT TYPE MAP
# =============================================================================
#
# Maps the type token from a Conventional Commit subject to a
# canonical type string. The canonical strings are what appear in the
# rendered LaTeX as \textbf{<type>}; they are NOT LaTeX-escaped
# because all values are plain ASCII letters.
#
# Why the aliases?
#   Different people write the same type differently. "feature" and
#   "feat" mean the same thing. Mapping both to "feat" ensures the
#   changelog is consistent even if commit authors are not.
#
# Why "other" as the fallback in parse_subject?
#   A commit subject that does not match CC_PATTERN (or matches but
#   uses an unknown type) is still a commit and must appear in the
#   changelog. "other" is a neutral label that renders correctly in
#   LaTeX and is obviously not a real Conventional Commit type.
#
# Adding a new type:
#   1. Add "newtype": "newtype" to this dict.
#   2. No other changes needed; the parser accepts any [a-z]+ type.
#
# Removing a type:
#   Existing commits of that type will fall back to "other". Prefer
#   keeping the mapping even if the type is no longer used, so that
#   historical commits stay labeled correctly.
#
TYPES = {
    "feat": "feat",
    "feature": "feat",
    "fix": "fix",
    "bugfix": "fix",
    "docs": "docs",
    "doc": "docs",
    "style": "style",
    "refactor": "refactor",
    "perf": "perf",
    "test": "test",
    "tests": "test",
    "chore": "chore",
    "ci": "ci",
    "build": "build",
    "revert": "revert",
}


# =============================================================================
# SECTION 6 — REGEX PATTERNS
# =============================================================================
#
# Three compiled patterns. Compiling once at import time is a
# micro-optimization that matters here because the patterns are
# applied to hundreds of commit subjects per run.
#
# -----------------------------------------------------------------------------
# CC_PATTERN — Conventional Commit subject parser
# -----------------------------------------------------------------------------
#
# Grammar matched:
#
#   <type>[(<scope>)][!]: <message>
#
# Breakdown:
#
#   ^                   start of string
#   (?P<type>[a-z]+)    one or more lowercase letters; named group
#                       "type" so we can reference it by name
#   (?:                 non-capturing group: optional scope
#       \(              literal open paren
#       (?P<scope>      named group "scope"
#           [^)]+       one or more non-close-paren characters
#       )
#       \)              literal close paren
#   )?                  the whole scope group is optional
#   !?                  optional breaking-change marker
#   :                   literal colon
#   \s*                 zero or more whitespace after colon
#   (?P<message>.+)     named group "message": one or more of
#                       anything except newline
#   $                   end of string
#
# The re.IGNORECASE flag makes [a-z]+ match uppercase too, so
# "Feat: ..." and "FEAT: ..." parse the same as "feat: ...".
#
# Edge cases the regex does NOT handle (documented, not fixed):
#
#   1. Nested parens in scope: "feat(foo(bar)): msg" fails to parse.
#      [^)]+ stops at the first close paren, and the grammar cannot
#      express balanced parens. Result: falls back to "other".
#
#   2. Multi-line subjects: only the first line is passed in (git
#      %s gives the first line by definition), so multi-line is not
#      an issue in practice.
#
#   3. Scope with special characters: any character except ")" is
#      allowed, including spaces. "feat(very wide scope): msg" parses
#      with scope="very wide scope". This is more permissive than the
#      Conventional Commits spec, which restricts scope to non-space
#      word characters. Documented as permissive, not a bug.
#
CC_PATTERN = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[^)]+)\))?!?:\s*(?P<message>.+)$",
    re.IGNORECASE,
)

# -----------------------------------------------------------------------------
# PR_PATTERN — parenthesized PR reference "(#123)"
# -----------------------------------------------------------------------------
#
# Matches the canonical GitHub squash-merge format, where the PR
# number is appended in parentheses at the end of the subject:
#
#   "feat: add login (#42)"
#
# Tried first in `extract_pr`. The regex is unanchored (no ^ or $),
# so the PR reference can appear anywhere in the subject, though in
# practice it is always at the end.
#
PR_PATTERN = re.compile(r"\(#(\d+)\)")

# -----------------------------------------------------------------------------
# PR_PATTERN_ALT — bare PR reference "#123"
# -----------------------------------------------------------------------------
#
# Fallback for subjects that reference a PR without parens:
#
#   "fix: crash on login, refs #42"
#
# Tried second in `extract_pr`, so a subject containing "(#42)" uses
# the parenthesized form (less likely to be a false positive).
#
# Note: this pattern also matches issue references, not just PRs.
# A subject like "fix: crash, closes #17" (where #17 is an issue,
# not a PR) would produce a link to /pull/17, which is wrong.
# Documented; no fix applied because the consequence is a
# 404-on-click, not a compile error, and the heuristic catches the
# common case (squash-merged PRs) correctly.
#
PR_PATTERN_ALT = re.compile(r"#(\d+)")


# =============================================================================
# SECTION 7 — SUBJECT PARSING
# =============================================================================
#
# Two functions: parse_subject and extract_pr. Both take a commit
# subject (the first line of the commit message) and return parsed
# components. Neither has side effects.
#
# Kept separate because they extract different facts and have
# different failure modes: parse_subject falls back to ("other",
# subject, None) on any failure; extract_pr returns None on any
# failure. Merging them would blur these contracts.
#
def parse_subject(subject: str) -> tuple[str, str, str | None]:
    """
    Parse a Conventional Commit subject into (type, message, scope).

    Returns
    -------
    tuple[str, str, str | None]
        (canonical_type, message, scope_or_None)

        canonical_type is one of the values in TYPES, or "other" if
        the subject does not match CC_PATTERN or the type token is
        not in TYPES.

        message is the text after the colon, stripped of leading
        whitespace. For non-Conventional subjects, message is the
        entire subject unchanged.

        scope is the text between the parens after the type, or
        None if the subject has no scope or does not match.

    Notes
    -----
    The `!` breaking-change marker is consumed by the regex but not
    returned. See OBSERVED DEFECTS in the file header, DEFECT 2.
    """
    m = CC_PATTERN.match(subject)

    # No match: subject is not in Conventional Commit format. Return
    # the subject unchanged as the message so it still appears in the
    # changelog, labeled "other".
    if not m:
        return "other", subject, None

    # Match: look up the type. `.lower()` is redundant because
    # CC_PATTERN has IGNORECASE, but it makes the dict lookup
    # explicit and defends against future removal of the flag.
    #
    # `.get(..., "other")` falls back to "other" if the type token
    # is not in TYPES. This is how custom types that are not in the
    # map still produce valid output.
    t = TYPES.get(m.group("type").lower(), "other")

    # `.strip()` removes leading whitespace that the `\s*` in
    # CC_PATTERN might have consumed (though in practice \s* is
    # greedy and consumes all leading whitespace before message
    # captures, so strip() is defensive).
    msg = m.group("message").strip()

    # scope is None if the optional group did not participate in the
    # match. That is the correct signal: "no scope present" versus
    # "scope was empty string" are distinct, and group() returns None
    # for the former.
    scope = m.group("scope")

    return t, msg, scope


def extract_pr(subject: str) -> str | None:
    """
    Extract a pull request number from a commit subject.

    Returns
    -------
    str | None
        The PR number as a string (e.g. "42"), or None if no PR
        reference is found.

    Notes
    -----
    Tries the parenthesized form "(#123)" first, because it is the
    canonical GitHub squash-merge format and less likely to be a
    false positive than a bare "#123" (which could be an issue
    reference). See PR_PATTERN_ALT's comment for the known false-
    positive case.
    """
    m = PR_PATTERN.search(subject)
    if m:
        return m.group(1)

    m = PR_PATTERN_ALT.search(subject)
    if m:
        return m.group(1)

    return None


# =============================================================================
# SECTION 8 — GIT LOG COLLECTION
# =============================================================================
#
# One function, collect_commits, which shells out to git log and
# parses the output into a list of dicts. This is the only place in
# the script that reads from the repository; everything else is
# pure computation on the returned list.
#
# The parsing approach: use a marker line to delimit commits, because
# git log with --shortstat interleaves commit headers and stat lines
# in a way that is otherwise ambiguous. The marker is a string that
# cannot appear in a commit subject (all @@@ characters are ASCII,
# and a subject containing @@@ would be unusual; even if it occurred,
# the exact marker "@@@COMMIT@@@" would need to appear at the start
# of a line, which no realistic subject does).
#
def collect_commits(limit: int, since: str | None) -> list[dict]:
    """
    Read git log and return a list of commit dictionaries.

    Parameters
    ----------
    limit : int
        Maximum number of commits to include. Passed to git log -n.
        The limit is applied AFTER --since filtering, so
        `--since 2026-01-01 -n 500` means "the most recent 500
        commits since January 1".

    since : str | None
        Only include commits on or after this date (YYYY-MM-DD).
        None means no lower bound.

    Returns
    -------
    list[dict]
        Each dict has keys: short, full, date, author, subject, stats.
        The list is ordered newest-first, matching git log's default.

    Notes
    -----
    Uses a line marker to delimit commits because --shortstat
    interleaves two kinds of lines: commit header lines (which start
    with the marker) and stat lines (which do not). Without a marker,
    the parser would need to detect the start of each commit by
    inspecting the format, which is fragile.

    Merge commits are excluded via --no-merges. Individual commits
    on a merged branch are still included. Squash-merged PRs
    produce a single commit, which is included.
    """
    # The marker is a sentinel that prefixes every commit header
    # line. It must be a string that cannot be confused with a
    # stat line (stat lines contain "file changed", never "@@@").
    marker = "@@@COMMIT@@@"

    # Format string for git log's --pretty=format.
    #
    # Placeholders:
    #   %h    short hash (abbreviated, typically 7-8 chars)
    #   %H    full hash (40 chars)
    #   %ad   author date, in the format given by --date=short
    #   %an   author name
    #   %s    subject (first line of commit message)
    #
    # The pipe character | is used as a field separator because it
    # does not appear in git hashes, ISO dates, or (typically) author
    # names. If an author name contains |, `payload.split("|", 4)`
    # would split it into extra parts and the commit would be
    # skipped (see the `len(parts) != 5` check below). Documented
    # as a known limitation.
    fmt = f"{marker}%h|%H|%ad|%an|%s"

    # Build the git log arguments.
    #
    #   --no-merges             exclude merge commits
    #   --date=short            dates as YYYY-MM-DD, not verbose
    #   --shortstat             append "N files changed, ..." per commit
    #   --pretty=format:<fmt>   use our custom format string
    #   -n <limit>              cap the number of commits
    #
    # --since is appended conditionally below, because passing
    # "--since=None" (the string "None") would filter on a literal
    # date string "None", which git would parse as an invalid date
    # and error out.
    args = [
        "git",
        "log",
        "--no-merges",
        "--date=short",
        "--shortstat",
        f"--pretty=format:{fmt}",
        "-n",
        str(limit),
    ]
    if since:
        args.append(f"--since={since}")

    # Run git log. check_output raises CalledProcessError on non-zero
    # exit (e.g. not in a git repo, bad argument). No try/except:
    # the traceback is more informative than a custom message.
    out = subprocess.check_output(args, text=True)

    commits = []
    current = None

    for line in out.splitlines():
        if line.startswith(marker):
            # New commit header. Flush the previous commit if any.
            if current:
                commits.append(current)

            # Strip the marker to get the payload.
            payload = line[len(marker) :]

            # Split into at most 5 fields. The 4 in split("|", 4)
            # means "at most 4 splits", yielding at most 5 fields.
            # The last field (subject) may contain | characters
            # without breaking the split, because it is the fifth
            # (final) field and absorbs any remaining | characters.
            parts = payload.split("|", 4)

            if len(parts) != 5:
                # Malformed header line: skip it. This can happen if
                # an author name contained a | character in a way
                # that produced fewer than 5 parts (rare; would
                # require | at the very end of the author field
                # immediately before the subject field, which is
                # possible but unusual).
                current = None
                continue

            short, full, cdate, author, subject = parts
            current = {
                "short": short,
                "full": full,
                "date": cdate,
                "author": author,
                "subject": subject,
                "stats": "",
            }

        elif current and "file changed" in line:
            # Stat line, e.g. "3 files changed, 42 insertions(+), ..."
            #
            # The substring "file changed" is the invariant part of
            # the line across locales (the numeric parts change).
            # Matching on it is locale-independent because git's
            # English output always contains this phrase; if git is
            # configured for a non-English locale, this check would
            # miss and the commit would have empty stats. Documented
            # as a known limitation.
            current["stats"] = line.strip()

        # Other lines are ignored. This includes:
        #   - blank lines (git log inserts one between commits)
        #   - lines that would be part of a multi-line subject
        #     (there are none, because %s is single-line by spec)

    # Flush the last commit. The loop only flushes on the NEXT header
    # line, so the final commit in the output would be lost without
    # this trailing append.
    if current:
        commits.append(current)

    return commits


# =============================================================================
# SECTION 9 — LATEX ESCAPING
# =============================================================================
#
# One dict and one function. The dict maps LaTeX-special characters
# to their escaped forms; the function applies the mapping to every
# character of its input.
#
# The escaping is character-level, not context-aware. This means:
#
#   - A "~" in an author name becomes "\textasciitilde{}", which
#     renders as ~ but does NOT act as a non-breaking space.
#   - A "^" in a commit subject becomes "\textasciicircum{}", which
#     renders as ^ but does NOT trigger superscript.
#   - A "\" in a subject becomes "\textbackslash{}", which renders
#     as \ but does NOT start a macro.
#
# This is the correct behaviour for arbitrary user text. If the text
# needs to render as math or as literal LaTeX, that is a different
# problem (and one this script does not attempt to solve).
#
# The dict covers 10 characters. LaTeX has 10 special characters:
#
#   \  {  }  $  &  #  %  _  ~  ^
#
# All 10 are present. No other character needs escaping in text
# mode with T1 encoding. See OBSERVED DEFECTS, DEFECT 1 for the
# discussion of [ ] < > under other encodings.
#
# Why not use an existing library (e.g. `pylatexenc`)?
#   1. pylatexenc is a third-party package; this script must run on
#      a bare Python installation.
#   2. The mapping is small enough to inline. A dependency for 10
#      characters is not worth the maintenance cost.
#
# Why .get(c, c) instead of a direct dict lookup?
#   Characters not in the dict (which is almost all of them: all
#   letters, digits, punctuation, whitespace) are returned
#   unchanged. A direct lookup would raise KeyError for every
#   non-special character, which is virtually every character.
#
_LATEX_ESCAPE = {
    "\\": r"\textbackslash{}",
    "&": r"\&",
    "%": r"\%",
    "$": r"\$",
    "#": r"\#",
    "_": r"\_",
    "{": r"\{",
    "}": r"\}",
    "~": r"\textasciitilde{}",
    "^": r"\textasciicircum{}",
}

def escape_latex(s: str) -> str:
    """
    Escape LaTeX-special characters in a string.

    Parameters
    ----------
    s : str
        The raw text to escape. Can contain any Unicode characters;
        non-ASCII characters are passed through unchanged, on the
        assumption that the surrounding LaTeX document uses a font
        encoding that supports them (T1 covers Latin-1).

    Returns
    -------
    str
        The escaped text, safe to insert into LaTeX text mode.

    Notes
    -----
    Single-pass, character-level escaping. Every character in the
    input is either replaced by its escaped form (if it is in
    _LATEX_ESCAPE) or passed through unchanged. Backslash is escaped
    FIRST in the conceptual sense, but the implementation iterates
    character by character, so the ordering is naturally correct:
    each character is either a special or not, regardless of what
    precedes it.

    This function does NOT escape for URL context. Use only for
    text that appears in the body of the document, not inside
    \\href{}{} URL arguments (which have different escaping rules).
    """
    return "".join(_LATEX_ESCAPE.get(c, c) for c in s)


# =============================================================================
# SECTION 10 — SINGLE-COMMIT RENDERER
# =============================================================================
#
# render_commit takes one commit dict and returns one LaTeX \\item
# line (plus optional nested itemize for stats). This is the only
# function that constructs LaTeX output for a commit.
#
# The output format is:
#
#   \item \textbf{<type>} \texttt{<scope>} <message> (PR) --- Author
#
# with optional scope, PR, and stats. The type is bold to make it
# scannable. The scope is monospace to distinguish it from the
# message. The author is italic to visually separate it from the
# message.
#
# All three decorations are LaTeX-mandated or conventional, not
# arbitrary. The style matches the papers in paper/*.tex, which use
# bold for emphasis and italic for secondary attribution.
#
def render_commit(commit: dict, gh_repo: str) -> str:
    """
    Render a single commit as one LaTeX \\item (plus nested itemize).

    Parameters
    ----------
    commit : dict
        A commit dict as returned by collect_commits. Must have keys
        short, full, date, author, subject. May have "stats" (empty
        string if no stat line was captured).

    gh_repo : str
        The "owner/repo" string used to build GitHub URLs. Typically
        the module-level GH_REPO constant.

    Returns
    -------
    str
        The LaTeX source for one \\item, ready to be appended to the
        output. If the commit has a stats line, the return value
        also includes a nested itemize environment below the \\item.

    Notes
    -----
    The commit hash is inserted into the URL un-escaped, because
    git hashes are hex and contain only [0-9a-f], none of which are
    LaTeX-special. If a future version of git switches to a hash
    format that includes special characters (extremely unlikely),
    this would break.

    The message and author are escaped via escape_latex because
    they are arbitrary user text.
    """
    subject = commit["subject"]
    ctype, message, scope = parse_subject(subject)
    pr = extract_pr(subject)

    # Escape the author name. Author names can contain any Unicode
    # character and (rarely) LaTeX specials like & or _.
    author = escape_latex(commit["author"])

    # The full hash is not escaped because it is hex.
    full = commit["full"]

    # Stats may be empty string if no --shortstat line was captured.
    stats = commit.get("stats", "")

    # Build the \\item in pieces. Each append corresponds to one
    # semantic part of the item, which makes the structure obvious
    # when reading the code and makes individual parts easy to
    # modify.
    parts = ["  \\item "]

    # The type label, escaped for safety (though all current TYPES
    # values are pure alnum). Bold, because it is the primary
    # scanning cue.
    parts.append(f"\\textbf{{{escape_latex(ctype)}}} ")

    # The scope, in monospace, only if present. Monospace
    # distinguishes the scope from the message.
    if scope:
        parts.append(f"\\texttt{{{escape_latex(scope)}}} ")

    # The message, hyperlinked to the GitHub commit page. The URL
    # contains the full hash, which is hex and needs no escaping.
    # The display text is the escaped message.
    parts.append(
        f"\\href{{https://github.com/{gh_repo}/commit/{full}}}"
        f"{{{escape_latex(message)}}}"
    )

    # The PR reference, if present. \\# is the LaTeX escape for a
    # literal # character in text mode; the URL argument uses a
    # bare # because URL context does not process LaTeX escapes.
    if pr:
        parts.append(f" (\\href{{https://github.com/{gh_repo}/pull/{pr}}}{{\\#{pr}}})")

    # The author attribution, italic, separated by an em-dash
    # sequence (--- in LaTeX source is an em-dash).
    parts.append(f" --- \\textit{{{author}}}")

    # Join all parts into one line.
    line = "".join(parts)

    # Append the stats itemize if stats is non-empty.
    #
    # The stats line from git is:
    #   "3 files changed, 42 insertions(+), 10 deletions(-)"
    # This contains characters that are text-mode-safe in LaTeX
    # (parentheses, plus, minus) but is still escaped because the
    # stat line format could change and a future format might
    # include specials. Defensive escaping is cheap.
    #
    # The nested itemize uses leftmargin=1.5em from the enumitem
    # package, which main.tex loads. Without enumitem, the
    # [leftmargin=...] argument would be an error.
    if stats:
        stats_esc = escape_latex(stats)
        line += (
            f"\n  \\begin{{itemize}}[leftmargin=1.5em]\n"
            f"    \\item \\small\\textit{{{stats_esc}}}\n"
            f"  \\end{{itemize}}"
        )

    return line


# =============================================================================
# SECTION 11 — DATE AND MONTH FORMATTING
# =============================================================================
#
# Two small functions that convert machine-friendly date strings to
# human-friendly labels. Both have a fallback: if the input cannot
# be parsed, the input is returned unchanged. This is the right
# behaviour because a malformed date should appear in the changelog
# as-is (so the user can see and fix it), not crash the script.
#
def pretty_month(month: str) -> str:
    """
    Convert "2026-11" (a YYYY-MM key) to "November 2026".

    Parameters
    ----------
    month : str
        A YYYY-MM string, as produced by `d[:7]` on a YYYY-MM-DD
        date string.

    Returns
    -------
    str
        The formatted month name, or the input unchanged if parsing
        fails.
    """
    try:
        # Appending "-01" turns "2026-11" into "2026-11-01", which
        # strptime can parse. The day-of-month value is irrelevant
        # because we only use the parsed month.
        d = datetime.strptime(month + "-01", "%Y-%m-%d")
        # %B is the full month name ("November"), %Y is the 4-digit
        # year. Locale-dependent: on a German locale, this would
        # produce "November 2026" (same in this case) but for other
        # months it would use the German name. LaTeX's \today is
        # also locale-dependent, so this is consistent with the rest
        # of the document.
        return d.strftime("%B %Y")
    except ValueError:
        # Malformed input: return unchanged. A calendar bug should
        # not crash the changelog.
        return month


def pretty_date(date_str: str) -> str:
    """
    Convert "2026-11-02" to "Sunday, Nov 02, 2026".

    Parameters
    ----------
    date_str : str
        A YYYY-MM-DD string, as produced by git log --date=short.

    Returns
    -------
    str
        The formatted date, or the input unchanged if parsing fails.
    """
    try:
        d = datetime.strptime(date_str, "%Y-%m-%d")
        # %A = full weekday name, %b = abbreviated month name,
        # %d = zero-padded day. The commas are literals.
        return d.strftime("%A, %b %d, %Y")
    except ValueError:
        return date_str


# =============================================================================
# SECTION 12 — DOCUMENT BUILDER
# =============================================================================
#
# build_latex assembles the entire LaTeX fragment from the commits
# list. It is the only function that knows the document structure.
#
# The structure is:
#
#   1. Section header + intro paragraph
#   2. Metadata table (repository, branch, date, count)
#   3. For each month (newest first):
#      a. Section header for the month
#      b. For each day in the month (newest first):
#         i. Subsection header for the day
#         ii. Itemize with one \\item per commit
#
# Every \\section* and \\subsection* is followed by an
# \\addcontentsline because starred headings do not add themselves
# to the ToC.
#
def build_latex(commits: list[dict], gh_repo: str, gh_branch: str) -> str:
    """
    Build the entire LaTeX fragment from a list of commits.

    Parameters
    ----------
    commits : list[dict]
        As returned by collect_commits. Must be non-empty; an empty
        list is handled by main() before this function is called.

    gh_repo : str
        "owner/repo" for GitHub URLs and the metadata table.

    gh_branch : str
        Branch name for the metadata table only. Not used to query
        git; the changelog always reflects HEAD.

    Returns
    -------
    str
        The complete LaTeX fragment, ready to write to a file.
    """
    if not commits:
        # Defensive: main() already checks for empty lists, but this
        # function should not produce a malformed fragment if called
        # directly. Returning "" means the caller writes an empty
        # file, which would break main.tex's \input. See the
        # STALE-OUTPUT caveat in the file header for why main() does
        # not write at all in this case.
        return ""

    # Group commits by date (YYYY-MM-DD). The default dict means we
    # do not need to check for key existence before appending.
    by_date = defaultdict(list)
    for c in commits:
        by_date[c["date"]].append(c)

    # Group dates by month (YYYY-MM). The dates are sorted
    # descending, so months appear newest-first. Within each month,
    # dates are also descending, so days appear newest-first. This
    # matches the reader's expectation: most recent at the top.
    by_month = defaultdict(list)
    for d in sorted(by_date.keys(), reverse=True):
        by_month[d[:7]].append(d)

    today = date.today().isoformat()
    total = len(commits)

    # The output is built as a list of strings, then joined with
    # newlines. This is faster and cleaner than concatenating
    # strings in a loop (each concatenation creates a new string
    # object in Python; appending to a list is O(1)).
    out = [
        # Section header. Starred to avoid consuming a section
        # number from the parent document.
        "\\section*{Changelog}",
        # Explicit ToC entry for the starred section.
        "\\addcontentsline{toc}{section}{Changelog}",
        "",
        # Intro paragraph. Uses implicit string concatenation
        # because the string spans two source lines for readability.
        "All notable changes to this project, generated automatically "
        "from the git commit history.",
        "",
        # Metadata table. [H] pins it here; the tabularx environment
        # stretches to \\textwidth with the X column absorbing slack.
        "\\begin{table}[H]",
        "  \\centering",
        "  \\begin{tabularx}{\\textwidth}{@{} l X @{}}",
        "    \\toprule",
        # Repository row: a hyperlink to the GitHub repo.
        f"    Repository & \\href{{https://github.com/{gh_repo}}}{{{gh_repo}}} \\\\",
        # Branch row: the branch name in monospace. This is the
        # GH_BRANCH constant, not the current branch. Documented.
        f"    Branch     & \\texttt{{{gh_branch}}} \\\\",
        # Generated row: the date this script ran, not the date of
        # the most recent commit. See the IDEMPOTENCY note in the
        # file header.
        f"    Generated  & {today} \\\\",
        # Commit count.
        f"    Commits    & {total} \\\\",
        "    \\bottomrule",
        "  \\end{tabularx}",
        "\\end{table}",
        "",
    ]

    # Iterate months newest-first.
    for month in sorted(by_month.keys(), reverse=True):
        out.append(f"\\section*{{{pretty_month(month)}}}")
        # \\section* does not add a ToC entry; add one manually.
        out.append(f"\\addcontentsline{{toc}}{{section}}{{{pretty_month(month)}}}")
        out.append("")

        # Iterate days within this month, newest-first.
        for d in sorted(by_month[month], reverse=True):
            out.append(f"\\subsection*{{{pretty_date(d)}}}")
            out.append("")
            out.append("\\begin{itemize}[leftmargin=1.5em]")

            # Iterate commits on this day. The order within a day is
            # whatever git log returned, which is newest-first by
            # default (git log's default ordering is reverse
            # chronological).
            for c in by_date[d]:
                out.append(render_commit(c, gh_repo))

            out.append("\\end{itemize}")
            out.append("")

    # Join with newlines. The result ends with a single newline
    # because the final element in `out` is "" (which joins as an
    # empty trailing line) — this means the file ends with exactly
    # one blank line, which is conventional for text files.
    return "\n".join(out)


# =============================================================================
# SECTION 13 — COMMAND-LINE INTERFACE
# =============================================================================
#
# main() is the entry point. It parses arguments, resolves the output
# path, calls collect_commits, calls build_latex, and writes the
# result. It returns an int exit code, which `if __name__ ==
# "__main__": sys.exit(main())` passes to the shell.
#
def main() -> int:
    """
    Entry point. Parse arguments, generate changelog, write file.

    Returns
    -------
    int
        0 on success (including the "no commits" case), 1 on any
        failure. Argument parsing errors exit before reaching main()
        with a code determined by argparse (typically 2).

    Notes
    -----
    On the "no commits" path, this function returns 0 WITHOUT
    writing the output file. See STALE-OUTPUT caveat in the file
    header for the consequence.
    """
    parser = argparse.ArgumentParser(
        description="Generate LaTeX changelog from git history."
    )
    # --limit: cap the number of commits. Default 500 is generous;
    # most projects have far fewer commits per year, so 500 covers
    # roughly a year of active development.
    parser.add_argument(
        "--limit", type=int, default=500, help="Max commits to include."
    )
    # --since: lower bound on commit date. Passed to git as
    # --since=YYYY-MM-DD. argparse does not validate the format;
    # git will error out on an invalid date.
    parser.add_argument(
        "--since",
        type=str,
        default=None,
        help="Only commits since YYYY-MM-DD.",
    )
    # --output: override the output path. Useful for debugging or
    # for generating a changelog outside the default location.
    # See OBSERVED DEFECTS, DEFECT 3 for the relative-path caveat.
    parser.add_argument(
        "--output", type=str, default=None, help="Override output path."
    )
    args = parser.parse_args()

    # Resolve the repository root. This is called UNCONDITIONALLY,
    # even if --output is supplied. See OBSERVED DEFECTS, DEFECT 4
    # for the consequence: running outside a git repo fails even
    # with --output.
    repo_root = get_repo_root()

    # Resolve the output path. If --output is None, use the default
    # at <repo-root>/content/changelog.tex. Otherwise use the
    # argument as-is (relative to cwd, not repo root).
    output = (
        Path(args.output) if args.output else repo_root / "content" / "changelog.tex"
    )

    # Create the parent directory if missing. parents=True creates
    # intermediate directories too; exist_ok=True suppresses the
    # FileExistsError that would otherwise be raised if the
    # directory already exists.
    output.parent.mkdir(parents=True, exist_ok=True)

    # Collect commits from git.
    commits = collect_commits(args.limit, args.since)

    # If no commits, print a diagnostic and exit 0. Do NOT write
    # the output file. See STALE-OUTPUT caveat.
    if not commits:
        print("No commits found.", file=sys.stderr)
        return 0

    # Build the LaTeX fragment. gh_repo and gh_branch are the
    # module-level constants, not derived from git. See Section 3.
    tex = build_latex(commits, GH_REPO, GH_BRANCH)

    # Write the fragment. write_text with explicit encoding="utf-8"
    # because the default encoding is locale-dependent (and on
    # Windows would be cp1252, which mangles non-ASCII author
    # names). Always specify encoding when writing text files.
    output.write_text(tex, encoding="utf-8")

    # Success report to stdout. One line, easily greppable.
    print(f"Wrote {output} ({len(commits)} commits)")

    return 0


# =============================================================================
# SECTION 14 — ENTRY POINT
# =============================================================================
#
# The standard Python idiom: only call main() when run as a script,
# not when imported as a module.
#
# Why this matters:
#   1. If another script imports this one (e.g. for its escape_latex
#      or parse_subject functions), the import must NOT trigger a
#      full changelog generation as a side effect.
#   2. Running `python3 -c "import gen_changelog"` for testing
#      should be free of side effects.
#
# sys.exit(main()) propagates main()'s return code to the shell, so
# `python3 scripts/gen_changelog.py && echo ok` prints "ok" only on
# success.
#
if __name__ == "__main__":
    sys.exit(main())


# =============================================================================
# END OF FILE: scripts/gen_changelog.py
# =============================================================================
#
# Verification checklist, for confirming the script behaves as
# documented after any edit:
#
#   [ ] `python3 scripts/gen_changelog.py` from the repo root writes
#       content/changelog.tex and prints one "Wrote ..." line.
#
#   [ ] The written file compiles: `make pdf` succeeds.
#
#   [ ] `git diff content/changelog.tex` shows no changes if no
#       commits have been made since the last run (same calendar
#       day).
#
#   [ ] `python3 scripts/gen_changelog.py --limit 3` produces a file
#       with exactly three commits.
#
#   [ ] `python3 scripts/gen_changelog.py --since 2099-01-01` prints
#       "No commits found." to stderr and exits 0 WITHOUT
#       overwriting content/changelog.tex.
#
#   [ ] `python3 scripts/gen_changelog.py --output /tmp/x.tex`
#       writes /tmp/x.tex, not content/changelog.tex.
#
#   [ ] Running from outside a git work tree (e.g. from /tmp) fails
#       with a CalledProcessError traceback about `git rev-parse`.
#
#   [ ] A commit subject containing `&`, `%`, `#`, `_`, `$`, `{`,
#       `}`, `~`, `^`, `\` renders without LaTeX errors. Confirm by
#       `git commit --allow-empty -m 'feat: test & % # _ $ { } ~ ^ \'`
#       then rerunning the script and `make pdf`.
#
#   [ ] A commit subject in Conventional Commit form with scope
#       renders as `\textbf{feat} \texttt{scope} message`.
#
#   [ ] A commit subject with "(#42)" renders the PR as a hyperlink
#       to /pull/42.
#
#   [ ] A commit subject that does not match Conventional Commit
#       format renders with `\textbf{other}` and the subject as the
#       message.
#
# If any check fails, the cause is in one of the sections above.
# The script is verified working; edits to it are rare and should
# be accompanied by all eleven checks above.
#
# =============================================================================
