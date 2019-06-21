# Chaosknoten - animated logo board
# Copyright (C) 2019 Stefan Schuermans <stefan@blinkenarea.org>
# Copyleft: GNU public license - http://www.gnu.org/copyleft/gpl.html
# a BlinkenArea project - http://www.blinkenarea.org/

NAME := Chaosknoten
INC := tn2313def
LFUSE := 0x64
HFUSE := 0xDF
EFUSE := 0xFF
LOCK := 0xFC

PROGRAMMER := avrisp2
CONNECTION := usb
DEVICE := t2313

AVRA := avra
AVRDUDE := avrdude

AVRDUDE_CALL := $(AVRDUDE) -c $(PROGRAMMER) -P $(CONNECTION) -p $(DEVICE)

SUFFIXES :=

.PHONY: all prog prog_fuses prog_auto clean
.SUFFIXES:
.SECONDARY:

all: $(NAME).hex

$(NAME).hex: $(NAME).asm $(INC).inc Makefile
	$(AVRA) -l $(NAME).lst $(NAME).asm

prog_fuses: Makefile
	$(AVRDUDE_CALL) -u -e
	$(AVRDUDE_CALL) -u -U lfuse:w:$(LFUSE):m -U hfuse:w:$(HFUSE):m \
	                   -U efuse:w:$(EFUSE):m

prog: $(NAME).hex Makefile
	$(AVRDUDE_CALL) -u -e
	$(AVRDUDE_CALL) -u -U flash:w:$(NAME).hex
	$(AVRDUDE_CALL) -u -V -U lock:w:$(LOCK):m

prog_auto: $(NAME).hex Makefile
	while ! $(MAKE) prog_fuses || ! $(MAKE) prog; do echo -n; done

clean:
	rm -f $(addprefix $(NAME)., lst obj cof hex eep.hex)

