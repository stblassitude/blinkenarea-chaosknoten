NAME := Chaosknoten
PAPER := a4
PHOTOS := battery_holder.jpg capacitor.jpg Chaosknoten_back.jpg \
          Chaosknoten_front.jpg led.jpg microcontroller.jpg resistor.jpg \
          switch.jpg transistor.jpg
SYMBOLS := battery_holder.svg capacitor.svg Chaosknoten_back.svg \
           Chaosknoten_front.svg led.svg microcontroller.svg resistor.svg \
           schematic.svg smd_solder_done.svg smd_solder_pads.svg \
           smd_solder_part.svg smd_solder_start.svg smd_solder_tin.svg \
           switch.svg transistor.svg

CONVERT := convert
INKSCAPE := inkscape
LATEX := latex
BIBTEX := bibtex
DVIPS := dvips
PS2PDF := ps2pdf
PDFVIEWER := acroread

IMAGES := $(addprefix photos/,$(PHOTOS)) $(addprefix symbols/,$(SYMBOLS))
IMAGES_EPS := $(addsuffix .eps,$(IMAGES))

SUFFIXES :=

.PHONY: all show clean
.SUFFIXES:
.SECONDARY:

all: $(NAME).dvi $(NAME).ps $(NAME).pdf

show: $(NAME).pdf
	$(PDFVIEWER) $<

clean:
	rm -f $(NAME).d $(NAME).log $(NAME).out $(NAME).dvi $(NAME).ps \
	      $(NAME).pdf $(IMAGES_EPS)

%.jpg.eps: %.jpg
	$(CONVERT) $< $@

%.svg.eps: %.svg
	$(INKSCAPE) -f $< -E $@

%.dvi: %.tex $(IMAGES_EPS)
	yes x | $(LATEX) $< || { rm -f $@; false; }
	yes x | $(LATEX) $< || { rm -f $@; false; }

%.ps: %.dvi
	$(DVIPS) -t$(PAPER) -Ppdf -o $@ $<

%.pdf: %.ps
	$(PS2PDF) $< $@

