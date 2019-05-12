NAMES = Chaosknoten

GNETLIST = gnetlist
GSCHEM = gschem
PCB = pcb
PS2PDF = ps2pdf

.PHONY: all nets pdfs tidy clean
.SUFFIXES:

all: nets pdfs tidy

nets: $(addsuffix .net,$(NAMES))

pdfs: $(addsuffix .sch.pdf,$(NAMES)) $(addsuffix .pcb.pdf,$(NAMES))

%.net: %.sch
	$(GNETLIST) -q -g PCB -o $@ $<

%.sch.ps: %.sch
	$(GSCHEM) -p -s gschem-print.scm -o $@ $<

%.pcb.ps: %.pcb
	$(PCB) -x ps --psfile $@ --media A4 --ps-color --fill-page $<

%.pdf: %.ps
	$(PS2PDF) $< $@

tidy:
	rm -f *~ *- *.log *.ps

clean: tidy
	rm -f *.net *.pdf

