# =============================================================================
# FILE: Makefile
# =============================================================================
#
# NAME
#   Makefile — build orchestrator for the "Personal Documentation and
#   Paper Publishing" repository.
#
# SYNOPSIS
#   make [target] [variable=value]
#   make all
#   make html
#   make pdf
#   make clean
#   make rebuild
#
# DESCRIPTION
#   Single entry point for every build artefact in this repository.
#   Drives five external tools in a fixed order:
#
#     make, bash, python3, git, TeX Live (latexmk / make4ht / pdflatex),
#     GnuPG.
#
#   The pipeline is:
#
#     setup          create dist/
#     gen-papers     generate content/auto-papers.tex from paper/*.tex
#     compile-papers compile paper/*.tex to paper/*.pdf
#     verify-papers  sign each PDF, hash each PDF, export public.asc
#     html           run make4ht on main.tex, copy CSS, stage paper/
#     pdf            run latexmk on main.tex into dist/
#     changelog      regenerate content/changelog.tex from git history
#
#   The build is intentionally fragile on the signing step: every
#   publishing target (all, html, pdf) depends on verify-papers, and
#   verify-papers aborts with a hard error if the signing key is not
#   present. Publishing unsigned papers is considered worse than a
#   failed build.
#
# OUTPUTS
#   dist/index.html                 published HTML site
#   dist/main.css                   verbatim copy of styles/style.css
#   dist/main.pdf                   portfolio PDF
#   dist/paper/*.pdf                signed papers
#   dist/paper/*.asc                detached GnuPG signatures
#   dist/paper/*.sha256             SHA-256 checksum files
#   dist/public.asc                 exportable public key
#
# INPUTS
#   main.tex                        primary LaTeX document
#   paper/*.tex                     one standalone paper per file
#   styles/style.css                source of truth for dist/main.css
#   scripts/gen_changelog.py        git-driven changelog generator
#   generate_papers.sh              paper manifest generator
#   generate_verification.sh        signing, hashing, verification table
#   ~/.gnupg                        signing key matching $GPG_KEY_EMAIL
#
# CONFIGURATION VARIABLES
#   TARGET              Base name of the primary LaTeX document.
#                       Default: main. Referenced as $(TARGET).tex,
#                       $(TARGET).html, and $(TARGET).pdf.
#
#   GPG_KEY_EMAIL       Email of the signing key. Read by
#                       generate_verification.sh. Default:
#                       mroczect@proton.me.
#
#   GPG_PASSPHRASE      If set, signing runs non-interactively via
#                       gpg --pinentry-mode loopback. Typical use:
#                       exported from a CI secret. Must NEVER be
#                       committed to this file.
#
# INVARIANTS — DO NOT BREAK
#   1. Every named target is declared in .PHONY. None of the target
#      names may collide with a real file at the repository root.
#   2. dist/main.css is copied verbatim from styles/style.css. Never
#      edit dist/main.css; edit the source.
#   3. content/auto-papers.tex, content/auto-verification-table.tex,
#      and content/changelog.tex are generated. Never commit edits
#      to them; they are rewritten on every build.
#   4. verify-papers is idempotent: a signature is regenerated only
#      when the PDF is newer than the .asc or the .asc is missing;
#      a checksum file is rewritten only when the hash changes.
#   5. `make all` must run end-to-end on a clean checkout with a
#      working GnuPG key. Without the key, `make all` fails at
#      verify-papers, and so do `make html` and `make pdf`.
#   6. `make html` and `make pdf` do NOT depend on compile-papers.
#      They will succeed even if paper/*.pdf is empty; verify-papers
#      simply signs nothing. Use `make all` to compile papers first.
#
# CHANGE POLICY
#   - Add a new build stage as a new .PHONY target and insert it into
#     `all` at the right position. Do not inline logic into `all`.
#   - Never introduce a target name that shadows a real file.
#   - Do not commit secrets. GPG_PASSPHRASE must be supplied by the
#     caller.
#   - If a stage becomes optional, gate it with an explicit check
#     rather than letting it silently fail.
#   - Keep the dependency order: setup → gen-papers → compile-papers
#     → verify-papers → html / pdf. Reordering breaks the build.
#
# TROUBLESHOOTING
#   Problem: `make all` fails with "cannot sign".
#   Cause:   No GPG key matching $GPG_KEY_EMAIL in the keyring.
#   Fix:     Import the key, or export GPG_KEY_EMAIL for the session,
#            or temporarily drop verify-papers from the dependency
#            list of `all`, `html`, and `pdf`.
#
#   Problem: `make html` succeeds but dist/paper/ is empty.
#   Cause:   `html` does not depend on compile-papers.
#   Fix:     Run `make all` first, or run `make compile-papers` before
#            `make html`.
#
#   Problem: dist/main.css looks stale.
#   Cause:   The copy step happens on every `make html`; if the file
#            was edited in dist/, the next build overwrites it.
#   Fix:     Edit styles/style.css, not dist/main.css.
#
# =============================================================================


# =============================================================================
# SECTION 1 — CONFIGURATION
# =============================================================================
#
# TARGET
#   Base name of the primary LaTeX document. All downstream targets
#   derive $(TARGET).tex, $(TARGET).html, and $(TARGET).pdf from it.
#   Changing this requires renaming main.tex accordingly and updating
#   \hypersetup inside main.tex if the PDF metadata depends on the
#   file name.
#
TARGET = main


# =============================================================================
# SECTION 2 — PHONY DECLARATIONS
# =============================================================================
#
# Every named target in this file is a phony target. Without .PHONY,
# a file named "all", "clean", or "html" at the repository root would
# cause make to treat the target as up-to-date and skip its recipe.
#
.PHONY: all setup gen-papers compile-papers verify-papers \
        html pdf changelog clean rebuild help


# =============================================================================
# SECTION 3 — META TARGETS
# =============================================================================
#
# NAME
#   all — run the full publishing pipeline.
#
# SYNOPSIS
#   make
#   make all
#
# DESCRIPTION
#   Default target. Runs every stage in dependency order:
#
#     setup → gen-papers → compile-papers → verify-papers → html → pdf
#
#   The order is not arbitrary:
#     - setup must precede every stage that writes into dist/.
#     - gen-papers must precede compile-papers because the generated
#       manifest content/auto-papers.tex is \input by main.tex, and
#       compile-papers builds main.tex.
#     - compile-papers must precede verify-papers because
#       verify-papers signs the PDFs produced by compile-papers.
#     - verify-papers must precede html and pdf because both embed
#       the signature files into their output.
#
# OUTPUTS
#   Everything listed in the file header, under OUTPUTS.
#
# FAILURE MODE
#   Any stage that exits non-zero aborts the pipeline. The most common
#   failure is verify-papers when the GPG key is absent. See the
#   file-level TROUBLESHOOTING section.
#
all: setup gen-papers compile-papers verify-papers html pdf


# =============================================================================
# SECTION 4 — SETUP
# =============================================================================
#
# NAME
#   setup — create the build directory.
#
# SYNOPSIS
#   make setup
#
# DESCRIPTION
#   Creates dist/ if it does not exist. All subsequent stages write
#   into dist/. Running setup twice is harmless.
#
# SIDE EFFECTS
#   - Creates directory: dist/
#
# DOES NOT
#   - Remove existing dist/. Use `make clean` for that.
#   - Create dist/paper/. The html target creates that directory
#     when it stages the paper artefacts.
#
setup:
	@mkdir -p dist
	@echo "[setup] Build directory ready: dist/"


# =============================================================================
# SECTION 5 — PAPER MANIFEST
# =============================================================================
#
# NAME
#   gen-papers — generate the paper manifest fragment.
#
# SYNOPSIS
#   make gen-papers
#
# DESCRIPTION
#   Runs generate_papers.sh, which enumerates every paper/*.tex file
#   and writes content/auto-papers.tex: a LaTeX fragment containing
#   an itemized list of \href{} links to each paper's PDF.
#
#   The fragment is \input by main.tex. It must exist before the
#   compile step, because latexmk fails if an \input target is missing.
#
# INPUTS
#   paper/*.tex — one standalone LaTeX document per paper.
#
# OUTPUTS
#   content/auto-papers.tex — generated, do not edit by hand.
#
# SIDE EFFECTS
#   - Rewrites content/auto-papers.tex on every invocation.
#
# FAILURE MODE
#   - If paper/ is empty, generate_papers.sh writes an empty list and
#     prints a warning. The build continues.
#   - If paper/ does not exist, the script exits with an error, and
#     `make all` aborts.
#
gen-papers:
	@echo "[gen-papers] Generating paper manifest..."
	@bash generate_papers.sh


# =============================================================================
# SECTION 6 — PAPER COMPILATION
# =============================================================================
#
# NAME
#   compile-papers — compile every paper/*.tex to PDF.
#
# SYNOPSIS
#   make compile-papers
#
# DESCRIPTION
#   Iterates over every paper/*.tex and runs latexmk -pdf on it. The
#   resulting PDFs land in paper/, next to their source .tex.
#
#   The `[ -e "$$f" ] || continue` guard handles the case where the
#   glob does not match any file (the shell leaves the literal string
#   "*.tex" as the loop argument). Without this guard, latexmk would
#   try to compile a file named "*.tex" and fail.
#
#   Each latexmk invocation runs with:
#     -interaction=nonstopmode   never stop for user input
#     -file-line-error           errors carry a file:line prefix
#
#   stdout is redirected to /dev/null, but stderr is not: real errors
#   still surface on the terminal.
#
# INPUTS
#   paper/*.tex
#
# OUTPUTS
#   paper/*.pdf
#   paper/*.aux, *.log, *.fls, *.fdb_latexmk (latexmk intermediates)
#
# SIDE EFFECTS
#   - Overwrites existing PDFs and intermediates.
#   - Leaves latexmk auxiliary files in paper/. Only `make clean`
#     removes them.
#
# FAILURE MODE
#   - A paper that fails to compile does NOT abort the loop. The loop
#     continues to the next file. A failed paper simply lacks a PDF,
#     and verify-papers will not sign it.
#   - If paper/ does not exist, the entire if-block is skipped
#     silently. The build continues.
#
compile-papers:
	@echo "[compile-papers] Compiling papers..."
	@if [ -d "paper" ]; then \
		cd paper && for f in *.tex; do \
			[ -e "$$f" ] || continue; \
			echo "  -> Compiling $$f"; \
			latexmk -pdf -interaction=nonstopmode -file-line-error "$$f" > /dev/null; \
		done \
	fi


# =============================================================================
# SECTION 7 — PAPER VERIFICATION
# =============================================================================
#
# NAME
#   verify-papers — sign each paper, checksum each paper, regenerate
#   the verification table, export the public key.
#
# SYNOPSIS
#   make verify-papers
#   GPG_PASSPHRASE=secret make verify-papers
#
# DESCRIPTION
#   Runs generate_verification.sh. For each paper/*.pdf:
#     - produces paper/NAME.pdf.asc     detached ASCII-armored signature
#     - produces paper/NAME.pdf.sha256  one-line checksum
#     - emits one row into content/auto-verification-table.tex
#
#   Idempotent behaviour:
#     - a signature is regenerated only when the PDF is newer than
#       the .asc, or the .asc is missing.
#     - a checksum file is rewritten only when the hash has changed.
#
#   Also exports the public signing key to public.asc. That file is
#   what readers use to verify signatures; see VERIFY.md.
#
# INPUTS
#   paper/*.pdf
#   ~/.gnupg (signing key matching $GPG_KEY_EMAIL)
#
# OUTPUTS
#   paper/*.asc
#   paper/*.sha256
#   content/auto-verification-table.tex
#   public.asc
#
# ENVIRONMENT
#   GPG_KEY_EMAIL       default: mroczect@proton.me
#   GPG_PASSPHRASE      if set, signing runs non-interactively via
#                       gpg --pinentry-mode loopback. Must NEVER be
#                       committed. Supply it from CI secrets.
#
# FAILURE MODE
#   - If the signing key is absent, this target aborts the entire
#     build with a hard error. `make all`, `make html`, and `make
#     pdf` all depend on verify-papers, so all three fail without
#     the key. This is deliberate: publishing unsigned papers is
#     considered worse than failing the build.
#   - To build without signing during local development, temporarily
#     comment out verify-papers from the dependency lists of `all`,
#     `html`, and `pdf`. Do not delete the target.
#
verify-papers:
	@echo "[verify-papers] Signing and verifying papers..."
	@bash generate_verification.sh


# =============================================================================
# SECTION 8 — HTML BUILD
# =============================================================================
#
# NAME
#   html — build the published HTML site with make4ht.
#
# SYNOPSIS
#   make html
#
# DESCRIPTION
#   Runs make4ht on $(TARGET).tex with the "xhtml" output mode, into
#   dist/. Then performs four staging steps:
#
#     1. Rename dist/$(TARGET).html to dist/index.html, so the
#        published site has a conventional entry point.
#     2. Copy styles/style.css verbatim to dist/main.css. The HTML
#        that make4ht produces links main.css, not style.css.
#     3. If paper/ exists, create dist/paper/ and copy every *.pdf,
#        *.asc, and *.sha256 into it. Missing files are tolerated via
#        `2>/dev/null || true`.
#     4. If public.asc exists at the repository root, copy it to
#        dist/public.asc so readers can verify signatures without
#        fetching the key from elsewhere.
#
# INPUTS
#   $(TARGET).tex
#   content/auto-papers.tex         (from gen-papers)
#   content/auto-verification-table.tex  (from verify-papers)
#   content/changelog.tex           (from changelog)
#   styles/style.css
#   paper/*.pdf, paper/*.asc, paper/*.sha256
#   public.asc
#
# OUTPUTS
#   dist/index.html
#   dist/main.css
#   dist/paper/*.pdf
#   dist/paper/*.asc
#   dist/paper/*.sha256
#   dist/public.asc
#
# SIDE EFFECTS
#   - Overwrites every file listed under OUTPUTS.
#   - mv (not cp) on dist/$(TARGET).html: the file no longer exists
#     under its original name after this target completes.
#
# FAILURE MODE
#   - If make4ht exits non-zero, the recipe prints $(TARGET).log to
#     stderr and exits 1.
#   - If dist/$(TARGET).html does not exist after make4ht completes
#     successfully, the recipe prints a specific error and exits 1.
#     This catches the rare case where make4ht exits 0 but writes
#     nothing useful.
#   - If verify-papers fails first, html never runs.
#
# IMPORTANT
#   `html` does NOT depend on `compile-papers`. On a clean checkout,
#   `make html` will build the HTML site without any paper PDFs.
#   The staged dist/paper/ directory will be empty. Run `make all`
#   instead if you want the papers compiled before staging.
#
html: setup gen-papers verify-papers changelog
	@echo "[html] Building HTML with make4ht..."
	@make4ht -d dist -u $(TARGET).tex "xhtml" || \
		(echo "[html] ERROR: make4ht failed"; cat $(TARGET).log; exit 1)
	@if [ -f dist/$(TARGET).html ]; then \
		mv dist/$(TARGET).html dist/index.html; \
	else \
		echo "[html] ERROR: dist/$(TARGET).html not found"; \
		exit 1; \
	fi
	@cp styles/style.css dist/main.css
	@if [ -d "paper" ]; then \
			mkdir -p dist/paper; \
			cp paper/*.pdf    dist/paper/ 2>/dev/null || true; \
			cp paper/*.asc    dist/paper/ 2>/dev/null || true; \
			cp paper/*.sha256 dist/paper/ 2>/dev/null || true; \
	fi
	@if [ -f public.asc ]; then \
		cp public.asc dist/public.asc; \
	fi


# =============================================================================
# SECTION 9 — PORTFOLIO PDF BUILD
# =============================================================================
#
# NAME
#   pdf — build the portfolio PDF with latexmk.
#
# SYNOPSIS
#   make pdf
#
# DESCRIPTION
#   Runs latexmk -pdf on $(TARGET).tex with -outdir=dist, so the
#   resulting PDF lands at dist/$(TARGET).pdf.
#
#   The dist/$(TARGET).pdf output is the "portfolio PDF": a single
#   printable document containing the profile, license, verification
#   table, and changelog, but NOT the individual paper PDFs. Papers
#   remain separate files under paper/ and dist/paper/.
#
# INPUTS
#   $(TARGET).tex
#   content/auto-papers.tex
#   content/auto-verification-table.tex
#   content/changelog.tex
#
# OUTPUTS
#   dist/$(TARGET).pdf
#   dist/*.aux, *.log, *.fls, *.fdb_latexmk (latexmk intermediates)
#
# SIDE EFFECTS
#   - Overwrites dist/$(TARGET).pdf and its intermediates.
#   - Leaves latexmk auxiliary files in dist/. Only `make clean`
#     removes them.
#
# FAILURE MODE
#   - If latexmk exits non-zero, the recipe aborts the pipeline.
#     Unlike compile-papers, the exit code is NOT swallowed.
#   - If verify-papers fails first, pdf never runs.
#
pdf: setup gen-papers verify-papers changelog
	@echo "[pdf] Building portfolio PDF..."
	@latexmk -pdf -interaction=nonstopmode -file-line-error -outdir=dist $(TARGET).tex > /dev/null


# =============================================================================
# SECTION 10 — CHANGELOG GENERATION
# =============================================================================
#
# NAME
#   changelog — regenerate the LaTeX changelog fragment.
#
# SYNOPSIS
#   make changelog
#
# DESCRIPTION
#   Runs scripts/gen_changelog.py, which reads the git commit history
#   and writes content/changelog.tex: a LaTeX fragment grouping
#   commits by month and day, with conventional-commit type labels,
#   commit hashes as hyperlinks, and optional shortstat summaries.
#
#   The fragment is \input by main.tex. It is regenerated on every
#   build that depends on this target (html, pdf, all) so the
#   published changelog always reflects the current repository state.
#
# INPUTS
#   .git/                           commit history
#   scripts/gen_changelog.py        generator
#
# OUTPUTS
#   content/changelog.tex           generated, do not edit by hand
#
# SIDE EFFECTS
#   - Rewrites content/changelog.tex on every invocation.
#
# FAILURE MODE
#   - If python3 is missing, this target fails and aborts the build.
#   - If the repository is not a git working tree, the generator
#     exits non-zero and the build aborts.
#
changelog:
	@echo "[changelog] Generating LaTeX fragment..."
	@python3 scripts/gen_changelog.py


# =============================================================================
# SECTION 11 — CLEANUP
# =============================================================================
#
# NAME
#   clean — remove every build artefact.
#
# SYNOPSIS
#   make clean
#
# DESCRIPTION
#   Removes four categories of files:
#
#     1. latexmk intermediates from the repository root, via
#        `latexmk -C`.
#     2. latexmk intermediates from paper/, plus every *.pdf, *.asc,
#        *.aux, *.log, *.fls, *.fdb_latexmk, *.out, *.toc, *.sha256
#        in paper/.
#     3. The dist/ tree.
#     4. A wide glob at the repository root: *.html, *.css, *.4ct,
#        *.4tc, *.idv, *.lg, *.tmp, *.xref, *.dvi, *.pdf, *.sha256,
#        main.pdf, public.asc, paper/SHA256SUMS.
#
#   The wide glob (category 4) is aggressive: it removes any .html,
#   .css, .pdf, or .sha256 at the repository root, regardless of
#   whether this Makefile produced it. That is intentional, to
#   guarantee a clean checkout from a partial build, but it means
#   `make clean` must not be run in a tree with unrelated files of
#   those extensions at the top level.
#
# SIDE EFFECTS
#   - Deletes content/changelog.tex? No: that file is left in place
#     because the `changelog` target regenerates it on the next build.
#   - Deletes the generated content/auto-*.tex files? No: those are
#     left in place because gen-papers and verify-papers regenerate
#     them on the next build.
#   - Deletes public.asc at the repository root, forcing verify-papers
#     to re-export it on the next build.
#
# DOES NOT
#   - Remove dist/main.css before the next build: the html target
#     recreates it from styles/style.css.
#   - Remove source files: every deleted file is a build artefact.
#
clean:
	@echo "[clean] Removing build artifacts..."
	@latexmk -C
	@if [ -d "paper" ]; then \
		cd paper && latexmk -C; \
		rm -f *.pdf *.asc *.aux *.log *.fls *.fdb_latexmk *.out *.toc *.sha256 ; \
	fi
	@rm -rf dist *.html *.css *.4ct *.4tc *.idv *.lg *.tmp *.xref *.dvi *.pdf *.sha256 \
		main.pdf public.asc paper/SHA256SUMS
	@echo "[clean] Done."


# =============================================================================
# SECTION 12 — REBUILD
# =============================================================================
#
# NAME
#   rebuild — clean then all.
#
# SYNOPSIS
#   make rebuild
#
# DESCRIPTION
#   Convenience target equivalent to `make clean && make all`. Runs
#   clean first, then the full pipeline. Useful after large edits to
#   main.tex or styles/style.css, where latexmk's incremental build
#   cache could produce stale output.
#
# SIDE EFFECTS
#   All side effects of `clean`, followed by all side effects of
#   `all`. The net effect is a fully fresh build tree.
#
rebuild: clean all


# =============================================================================
# SECTION 13 — HELP
# =============================================================================
#
# NAME
#   help — print a one-page summary of every target.
#
# SYNOPSIS
#   make help
#
# DESCRIPTION
#   Prints the target list with one-line descriptions. This target
#   exists so that `make help` is always available as a discovery
#   mechanism, even if the file-level documentation above is not
#   read.
#
help:
	@echo "Targets:"
	@echo "  all              run setup, gen-papers, compile-papers,"
	@echo "                   verify-papers, html, pdf (default)"
	@echo "  setup            create dist/"
	@echo "  gen-papers       write content/auto-papers.tex"
	@echo "  compile-papers   compile paper/*.tex to paper/*.pdf"
	@echo "  verify-papers    sign and hash each paper, export public.asc"
	@echo "  html             build dist/index.html, dist/main.css, stage paper/"
	@echo "  pdf              build dist/main.pdf"
	@echo "  changelog        regenerate content/changelog.tex from git"
	@echo "  clean            remove all build artefacts"
	@echo "  rebuild          clean, then all"
	@echo "  help             print this message"
	@echo ""
	@echo "Variables:"
	@echo "  TARGET           base name of the primary document (default: main)"
	@echo "  GPG_KEY_EMAIL    signing key email (read by verify-papers)"
	@echo "  GPG_PASSPHRASE   non-interactive signing passphrase (CI only)"


# =============================================================================
# END OF FILE: Makefile
# =============================================================================
