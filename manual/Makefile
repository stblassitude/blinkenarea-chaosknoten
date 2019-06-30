NAMES := Chaosknoten ChaosknotenOnePage
PAPER := a4
PHOTOS := battery_holder capacitor Chaosknoten_back Chaosknoten_front led \
          microcontroller resistor switch transistor
SYMBOLS := battery_holder capacitor Chaosknoten_back Chaosknoten_front led \
           microcontroller resistor schematic smd_solder_done smd_solder_pads \
           smd_solder_part smd_solder_start smd_solder_tin switch transistor

CONVERT := convert
INKSCAPE := inkscape
PDFLATEX := pdflatex

IMAGES := $(addsuffix .jpg,$(addprefix photos/,$(PHOTOS))) \
          $(addsuffix .svg,$(addprefix symbols/,$(SYMBOLS)))
IMAGES_PDF := $(addsuffix .pdf,$(addprefix photos/,$(PHOTOS))) \
              $(addsuffix .pdf,$(addprefix symbols/,$(SYMBOLS)))

SUFFIXES :=

.PHONY: all show clean
.SUFFIXES:
.SECONDARY:

all: $(addsuffix .pdf,$(NAMES))

clean:
	rm -f $(foreach N,$(NAMES),$(foreach E,aux log out pdf,$N.$E))
	rm -f $(IMAGES_PDF)

%.pdf: %.jpg
	$(CONVERT) $< $@

%.pdf: %.svg
	$(INKSCAPE) -f $< -A $@

ChaosknotenOnePage.pdf: Chaosknoten.pdf

%.pdf: %.tex $(IMAGES_PDF)
	yes x | $(PDFLATEX) $< || { rm -f $@; false; }
	yes x | $(PDFLATEX) $< || { rm -f $@; false; }

