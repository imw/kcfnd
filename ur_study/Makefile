## TEX COMPILATION SEQUENCE
## 1st) generates a doc with question marks in place of unknown refs ("first pass")
## 	make pdf
## IMPORTANT: only if \cite{} command is used
## 2nd) parses all the .bib files that were included in the doc and generate metainformation regarding refs (extracts reference data)
## 	make bib
## 3rd) generate doc with all the refs in the correct places (matches citations/references/acronyms)
## make pdf
## 	make pdf
## IMPORTANT: only if \cite{} command is used NOTE: otherwise is like starting from setp 1st) => no references at all!
## 4th) just in case if adding references broke page numbering somewhere (finishes all cross-referencing)
## 	make pdf

## rootfiles without (.tex) extension
ROOTFILE ?= feasibility_study

PDFLATEX = /usr/bin/pdflatex
BIBTEX = /usr/bin/bibtex

LATEX_CMD = $(PDFLATEX) --shell-escape -synctex=1 -interaction=nonstopmode -halt-on-error $(ROOTFILE).tex
BIBTEX_CMD = $(BIBTEX) $(ROOTFILE)

all:
	$(LATEX_CMD)
#	$(BIBTEX_CMD)  #uncomment in case of inclusion of Bibliography
#	$(LATEX_CMD)  #uncomment in case of inclusion of Bibliography
	$(LATEX_CMD)

clean:
	rm -rf *.aux *.bbl *.blg *.brf *.log *.nav *.out *.lof *.lot *.snm *.synctex.gz *.toc

cleanall: clean
	rm -rf *.pdf
