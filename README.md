PERSONAL DOCUMENTATION AND PAPER PUBLISHING
Muhammad Riduwan Khafidi — Politeknik Negeri Batam

LaTeX papers, lecture notes, and a personal portfolio.
Papers are compiled to PDF, signed with GnuPG, and get
SHA-256 checksums.

BUILD
    make all        papers, signatures, HTML, portfolio PDF
    make html       HTML only
    make pdf        portfolio PDF only
    make clean      remove artifacts
    make rebuild    clean then all

Outputs land in dist/. Papers land in paper/ with .pdf,
.pdf.asc, and .pdf.sha256 siblings.

CAVEAT
    verify-papers runs inside `make all`, `make html`, and
    `make pdf`. It signs every paper/*.pdf with the author's
    GPG key. Without that key in your keyring, all three
    targets fail. To build without signing, edit the Makefile
    and drop verify-papers from the dependency list.

PAPERS
    ls paper/*.tex — one standalone document each.

VERIFY
    gpg --import public.asc
    sha256sum -c NAME.pdf.sha256
    gpg --verify NAME.pdf.asc NAME.pdf
    Full guide: VERIFY.md

STYLE
    guilde/README.md (Bahasa Indonesia).
    guilde/Examples.tex is a working reference.
    The directory name is "guilde" with an L; not a typo.

DO NOT EDIT
    content/changelog.tex
    content/auto-papers.tex
    content/auto-verification-table.tex
    All three are regenerated on each build.

REQUIRES
    TeX Live (latexmk, make4ht, pdflatex), GnuPG,
    Python 3, bash, git, sha256sum or shasum.

LICENSE
    CC BY-SA 4.0. See LICENSE.

CONTACT
    mroczect@proton.me
    github.com/mroczect