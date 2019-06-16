NAMES := Chaosknoten

GNETLIST := gnetlist
GSCHEM := gschem
PCB := pcb
PS2PDF := ps2pdf

SUFFIXES :=

.PHONY: all nets pdfs gbrs tidy clean
.SUFFIXES:
.SECONDARY:

all: nets pdfs gbrs tidy

nets: $(addsuffix .net,$(NAMES))

pdfs: $(addsuffix .sch.pdf,$(NAMES)) $(addsuffix .pcb.pdf,$(NAMES))

gbrs: $(addsuffix .gerber.zip,$(NAMES))

%.net: %.sch
	$(GNETLIST) -q -g PCB -o $@ $<

%.sch.ps: %.sch gschem-print.scm
	$(GSCHEM) -p -s gschem-print.scm -o $@ $<

%.pcb.ps: %.pcb
	$(PCB) -x ps --psfile $@ --media A4 --ps-color --fill-page $<

%.pdf: %.ps
	$(PS2PDF) $< $@

%.gerber.zip: %.pcb
	rm -rf $*.gerber $@
	mkdir -p $*.gerber/tmp
	$(PCB) -x gerber --gerberfile $*.gerber/$* $<
	{ head -n $$(grep -n Via $< | head -n 1 | cut -d ':' -f 1) $<; \
	  tail -n +$$(grep -n Layer $< | head -n 1 | cut -d ':' -f 1) $<; } \
	  | sed 's/ 6.00mil / 1.00mil /g' > $*.gerber/tmp/$<
	$(PCB) -x gerber --gerberfile $*.gerber/tmp/$* $*.gerber/tmp/$<
	mv $*.gerber/tmp/$*.group7.gbr $*.gerber/$*.milling.gbr
	rm $(foreach X,group7,$*.gerber/$*.$X.gbr)
	rm -rf $*.gerber/tmp
	zip -r $@ $*.gerber

tidy:
	rm -f *~ *- *.log *.ps

clean: tidy
	rm -rf *.net *.pdf *.gerber *.gerber.zip

