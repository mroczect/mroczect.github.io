TARGET = main

all: setup gen-papers compile-papers verify-papers html pdf

setup:
	mkdir -p dist

gen-papers:
	./generate_papers.sh

compile-papers:
	@if [ -d "paper" ]; then \
		cd paper && for f in *.tex; do \
			[ -e "$$f" ] || continue; \
			echo "Compiling $$f..."; \
			latexmk -pdf -interaction=nonstopmode -file-line-error "$$f"; \
		done \
	fi

verify-papers:
	./generate_verification.sh

html: setup
	make4ht -d dist -u $(TARGET).tex "xhtml" || (echo "=== make4ht GAGAL ==="; cat $(TARGET).log; exit 1)
	@if [ -f dist/$(TARGET).html ]; then \
		mv dist/$(TARGET).html dist/index.html; \
	else \
		echo "ERROR: File HTML tidak ditemukan setelah make4ht berjalan."; \
		exit 1; \
	fi
	cp styles/style.css dist/style.css
	@if [ -d "paper" ]; then \
		mkdir -p dist/paper; \
		cp paper/*.pdf dist/paper/ 2>/dev/null || true; \
		cp paper/*.asc dist/paper/ 2>/dev/null || true; \
		cp paper/SHA256SUMS dist/paper/ 2>/dev/null || true; \
	fi
	@if [ -f public.asc ]; then \
		cp public.asc dist/public.asc; \
	fi

pdf: setup
	latexmk -pdf -interaction=nonstopmode -file-line-error -outdir=dist $(TARGET).tex

clean:
	latexmk -C
	@if [ -d "paper" ]; then \
		cd paper && latexmk -C; \
		rm -f *.pdf *.aux *.log *.fls *.fdb_latexmk *.out *.toc; \
	fi
	rm -rf dist *.html *.css *.4ct *.4tc *.idv *.lg *.tmp *.xref *.dvi *.pdf

ci-deploy: setup
	@test -f content/auto-papers.tex || (echo "ERROR: content/auto-papers.tex belum di-commit. Jalankan 'make gen-papers' lokal lalu commit."; exit 1)
	@test -f content/auto-verification-table.tex || (echo "ERROR: content/auto-verification-table.tex belum di-commit. Jalankan 'make verify-papers' lokal lalu commit."; exit 1)
	@ls paper/*.pdf >/dev/null 2>&1 || (echo "ERROR: paper/*.pdf belum di-commit. Jalankan 'make all' lokal lalu commit."; exit 1)
	make4ht -d dist -u $(TARGET).tex "xhtml" || (echo "=== make4ht GAGAL ==="; cat $(TARGET).log; exit 1)
	@if [ -f dist/$(TARGET).html ]; then mv dist/$(TARGET).html dist/index.html; fi
	cp styles/style.css dist/style.css
	mkdir -p dist/paper
	cp paper/*.pdf dist/paper/
	cp paper/*.asc dist/paper/ 2>/dev/null || true
	cp paper/SHA256SUMS dist/paper/ 2>/dev/null || true
	@if [ -f public.asc ]; then cp public.asc dist/public.asc; fi
	@echo "✅ dist/ siap untuk deploy"

	
rebuild: clean all

.PHONY: all setup gen-papers compile-papers verify-papers ci-deploy pdf html clean rebuild
