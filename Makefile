
TARGET = main

all: setup gen-papers compile-papers verify-papers html pdf

setup:
	@mkdir -p dist
	@echo "[setup] Build directory ready: dist/"

gen-papers:
	@echo "[gen-papers] Generating paper manifest..."
	@bash generate_papers.sh

compile-papers:
	@echo "[compile-papers] Compiling papers..."
	@if [ -d "paper" ]; then \
		cd paper && for f in *.tex; do \
			[ -e "$$f" ] || continue; \
			echo "  -> Compiling $$f"; \
			latexmk -pdf -interaction=nonstopmode -file-line-error "$$f" > /dev/null; \
		done \
	fi

verify-papers:
	@echo "[verify-papers] Signing and verifying papers..."
	@bash generate_verification.sh

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

pdf: setup gen-papers verify-papers changelog
	@echo "[pdf] Building portfolio PDF..."
	@latexmk -pdf -interaction=nonstopmode -file-line-error -outdir=dist $(TARGET).tex > /dev/null

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

changelog:
	@echo "[changelog] Generating LaTeX fragment..."
	@python3 scripts/gen_changelog.py
	
rebuild: clean all

.PHONY: all setup gen-papers compile-papers verify-papers html pdf clean rebuild
