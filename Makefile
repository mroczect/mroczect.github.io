TARGET = main

# Target default
all: setup gen-papers compile-papers verify-papers html pdf

setup:
	@mkdir -p dist
	@echo "📁 Folder dist/ siap."

gen-papers:
	@echo "🚀 Generate daftar paper..."
	@bash generate_papers.sh

compile-papers:
	@echo "🔨 Mengompilasi paper..."
	@if [ -d "paper" ]; then \
		cd paper && for f in *.tex; do \
			[ -e "$$f" ] || continue; \
			echo "  -> Compiling $$f..."; \
			latexmk -pdf -interaction=nonstopmode -file-line-error "$$f" > /dev/null; \
		done \
	fi

verify-papers:
	@echo "🛡️  Sign & verifikasi paper..."
	@bash generate_verification.sh

html: setup gen-papers verify-papers
	@echo "🌐 Membangun HTML dengan make4ht..."
	@make4ht -d dist -u $(TARGET).tex "xhtml" || (echo "❌ make4ht GAGAL"; cat $(TARGET).log; exit 1)
	@if [ -f dist/$(TARGET).html ]; then \
		mv dist/$(TARGET).html dist/index.html; \
	else \
		echo "❌ ERROR: File HTML tidak ditemukan."; \
		exit 1; \
	fi
	@cp styles/style.css dist/style.css
	@if [ -d "paper" ]; then \
		mkdir -p dist/paper; \
		cp paper/*.pdf dist/paper/ 2>/dev/null || true; \
		cp paper/*.asc dist/paper/ 2>/dev/null || true; \
		cp paper/SHA256SUMS dist/paper/ 2>/dev/null || true; \
	fi
	@if [ -f public.asc ]; then \
		cp public.asc dist/public.asc; \
	fi

pdf: setup gen-papers verify-papers
	@echo "📄 Membangun PDF portofolio..."
	@latexmk -pdf -interaction=nonstopmode -file-line-error -outdir=dist $(TARGET).tex > /dev/null

clean:
	@echo "🧹 Membersihkan artefak build..."
	@latexmk -C
	@if [ -d "paper" ]; then \
		cd paper && latexmk -C; \
		rm -f *.pdf *.asc *.aux *.log *.fls *.fdb_latexmk *.out *.toc; \
	fi
	@rm -rf dist *.html *.css *.4ct *.4tc *.idv *.lg *.tmp *.xref *.dvi *.pdf main.pdf public.asc paper/SHA256SUMS
	@echo "✅ Bersih."

rebuild: clean all

.PHONY: all setup gen-papers compile-papers verify-papers pdf html clean rebuild