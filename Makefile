TARGET = main

all: setup gen-papers compile-papers html pdf

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

html: setup
	make4ht -v -d dist -u $(TARGET).tex "xhtml, charset=utf-8"
	mv dist/$(TARGET).html dist/index.html
	cp styles/style.css dist/style.css
	@if [ -d "paper" ]; then \
		mkdir -p dist/paper; \
		cp paper/*.pdf dist/paper/ 2>/dev/null || true; \
	fi

pdf: setup
	latexmk -pdf -interaction=nonstopmode -file-line-error -outdir=dist $(TARGET).tex

clean:
	latexmk -C
	@if [ -d "paper" ]; then cd paper && latexmk -C; fi
	rm -rf dist *.html *.css *.4ct *.4tc *.idv *.lg *.tmp *.xref *.dvi

rebuild: clean all

.PHONY: all setup gen-papers compile-papers pdf html clean rebuild
