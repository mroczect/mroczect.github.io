#!/usr/bin/env python3
"""
Generate content/changelog.tex from git history.

The output is a LaTeX fragment intended to be \\input by main.tex.
It is NOT a standalone document.

Usage:
    python3 scripts/gen_changelog.py [--since YYYY-MM-DD] [--limit N]
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import defaultdict
from datetime import date, datetime
from pathlib import Path


def get_repo_root() -> Path:
    out = subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True
    ).strip()
    return Path(out)


def read_config(repo_root: Path) -> tuple[str, str]:
    cfg = repo_root / "zola.toml"
    gh_repo = "mroczect/lectures"
    gh_branch = "master"

    if not cfg.exists():
        return gh_repo, gh_branch

    text = cfg.read_text()
    for line in text.splitlines():
        m = re.match(r'\s*github_repo\s*=\s*"([^"]+)"', line)
        if m:
            gh_repo = m.group(1)
            continue
        m = re.match(r'\s*github_branch\s*=\s*"([^"]+)"', line)
        if m:
            gh_branch = m.group(1)

    return gh_repo, gh_branch


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

CC_PATTERN = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[^)]+)\))?!?:\s*(?P<message>.+)$",
    re.IGNORECASE,
)

PR_PATTERN = re.compile(r"\(#(\d+)\)")
PR_PATTERN_ALT = re.compile(r"#(\d+)")


def parse_subject(subject: str) -> tuple[str, str, str | None]:
    m = CC_PATTERN.match(subject)
    if not m:
        return "other", subject, None
    t = TYPES.get(m.group("type").lower(), "other")
    msg = m.group("message").strip()
    scope = m.group("scope")
    return t, msg, scope


def extract_pr(subject: str) -> str | None:
    m = PR_PATTERN.search(subject)
    if m:
        return m.group(1)
    m = PR_PATTERN_ALT.search(subject)
    if m:
        return m.group(1)
    return None


def collect_commits(limit: int, since: str | None) -> list[dict]:
    marker = "@@@COMMIT@@@"
    fmt = f"{marker}%h|%H|%ad|%an|%s"

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

    out = subprocess.check_output(args, text=True)
    commits = []
    current = None

    for line in out.splitlines():
        if line.startswith(marker):
            if current:
                commits.append(current)
            payload = line[len(marker) :]
            parts = payload.split("|", 4)
            if len(parts) != 5:
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
            current["stats"] = line.strip()

    if current:
        commits.append(current)
    return commits


def escape_latex(s: str) -> str:
    s = s.replace("\\", "__BACKSLASH__")
    replacements = [
        ("&", r"\&"),
        ("%", r"\%"),
        ("$", r"\$"),
        ("#", r"\#"),
        ("_", r"\_"),
        ("{", r"\{"),
        ("}", r"\}"),
        ("~", r"\textasciitilde{}"),
        ("^", r"\textasciicircum{}"),
    ]
    for orig, repl in replacements:
        s = s.replace(orig, repl)
    return s.replace("__BACKSLASH__", r"\textbackslash{}")


def render_commit(commit: dict, gh_repo: str) -> str:
    subject = commit["subject"]
    ctype, message, scope = parse_subject(subject)
    pr = extract_pr(subject)
    author = escape_latex(commit["author"])
    full = commit["full"]
    stats = commit.get("stats", "")

    parts = ["  \\item "]
    parts.append(f"\\textbf{{{escape_latex(ctype)}}} ")

    if scope:
        parts.append(f"\\texttt{{{escape_latex(scope)}}} ")

    parts.append(
        f"\\href{{https://github.com/{gh_repo}/commit/{full}}}"
        f"{{{escape_latex(message)}}}"
    )

    if pr:
        parts.append(f" (\\href{{https://github.com/{gh_repo}/pull/{pr}}}{{\\#{pr}}})")

    parts.append(f" --- \\textit{{{author}}}")
    line = "".join(parts)

    if stats:
        stats_esc = escape_latex(stats)
        line += (
            f"\n  \\begin{{itemize}}[leftmargin=1.5em]\n"
            f"    \\item \\small\\textit{{{stats_esc}}}\n"
            f"  \\end{{itemize}}"
        )

    return line


def pretty_month(month: str) -> str:
    try:
        d = datetime.strptime(month + "-01", "%Y-%m-%d")
        return d.strftime("%B %Y")
    except ValueError:
        return month


def pretty_date(date_str: str) -> str:
    try:
        d = datetime.strptime(date_str, "%Y-%m-%d")
        return d.strftime("%A, %b %d, %Y")
    except ValueError:
        return date_str


def build_latex(commits: list[dict], gh_repo: str, gh_branch: str) -> str:
    if not commits:
        return ""

    by_date = defaultdict(list)
    for c in commits:
        by_date[c["date"]].append(c)

    by_month = defaultdict(list)
    for d in sorted(by_date.keys(), reverse=True):
        by_month[d[:7]].append(d)

    today = date.today().isoformat()
    total = len(commits)

    out = [
        "\\section*{Changelog}",
        "\\addcontentsline{toc}{section}{Changelog}",
        "",
        "All notable changes to this project, generated automatically "
        "from the git commit history.",
        "",
        "\\begin{table}[H]",
        "  \\centering",
        "  \\begin{tabularx}{\\textwidth}{@{} l X @{}}",
        "    \\toprule",
        f"    Repository & \\href{{https://github.com/{gh_repo}}}{{{gh_repo}}} \\\\",
        f"    Branch     & \\texttt{{{gh_branch}}} \\\\",
        f"    Generated  & {today} \\\\",
        f"    Commits    & {total} \\\\",
        "    \\bottomrule",
        "  \\end{tabularx}",
        "\\end{table}",
        "",
    ]

    for month in sorted(by_month.keys(), reverse=True):
        out.append(f"\\section*{{{pretty_month(month)}}}")
        out.append(f"\\addcontentsline{{toc}}{{section}}{{{pretty_month(month)}}}")
        out.append("")
        for d in sorted(by_month[month], reverse=True):
            out.append(f"\\subsection*{{{pretty_date(d)}}}")
            out.append("")
            out.append("\\begin{itemize}[leftmargin=1.5em]")
            for c in by_date[d]:
                out.append(render_commit(c, gh_repo))
            out.append("\\end{itemize}")
            out.append("")

    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate LaTeX changelog from git history."
    )
    parser.add_argument(
        "--limit", type=int, default=500, help="Max commits to include."
    )
    parser.add_argument(
        "--since",
        type=str,
        default=None,
        help="Only commits since YYYY-MM-DD.",
    )
    parser.add_argument(
        "--output", type=str, default=None, help="Override output path."
    )
    args = parser.parse_args()

    repo_root = get_repo_root()
    gh_repo, gh_branch = read_config(repo_root)

    output = (
        Path(args.output) if args.output else repo_root / "content" / "changelog.tex"
    )
    output.parent.mkdir(parents=True, exist_ok=True)

    commits = collect_commits(args.limit, args.since)
    if not commits:
        print("No commits found.", file=sys.stderr)
        return 0

    tex = build_latex(commits, gh_repo, gh_branch)
    output.write_text(tex, encoding="utf-8")
    print(f"Wrote {output} ({len(commits)} commits)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
