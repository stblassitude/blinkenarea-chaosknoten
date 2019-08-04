; Chaosknoten - animated logo board
; Copyright (C) 2019 Stefan Schuermans <stefan@blinkenarea.org>
; Copyleft: GNU public license - http://www.gnu.org/copyleft/gpl.html

; ATtiny2313A, clock frequency: 8 MHz (internal oscillator)

; PA0: unused
; PA1: unused
; PA2: reset
; PB0: column 0 output (output, low)
; PB1: column 1 output (output, low)
; PB2: column 2 output (output, low)
; PB3: column 3 output (output, low)
; PB4: column 4 output (output, low)
; PB5: column 5 output (output, low)
; PB6: column 6 output (output, low)
; PB7: unused (input, pull-up enabled)
; PD0: row 0 output (output, high)
; PD1: row 1 output (output, high)
; PD2: row 2 output (output, high)
; PD3: row 3 output (output, high)
; PD4: row 4 output (output, high)
; PD5: row 5 output (output, high)
; PD6: mode switch (input, pull-up enabled)



.INCLUDE        "tn2313def.inc"



; IO pins
.equ    COL_PORT                =       PORTB   ; column outputs
.equ    ROW_PORT                =       PORTD   ; row outputs
.equ    MODE_SW_PIN             =       PIND
.equ    MODE_SW_BIT             =       6



; general purpose registers
.def    TMP                     =       r16
.def    TMP2                    =       r17
.def    CNT                     =       r18
.def    DATA                    =       r19
.def    GRAY                    =       r20

; current mode
.def    MODE                    =       r21
.equ    MODE_ALL                =       0       ; play all animations
.equ    MODE_SINGLE             =       1       ; play single animation only
.equ    MODE_UNKNOWN            =       0xFF    ; unknown mode

; current animation number and iterations
.def    ANI_NO                  =       r22
.def    ANI_IT                  =       r23



.DSEG
.ORG    0x060



; current frame
FRAME:                  .BYTE   42



.CSEG
.ORG    0x000
        rjmp    ENTRY                   ; RESET
        reti                            ; INT0
        reti                            ; INT1
        reti                            ; TIMER1_CAPT
        reti                            ; TIMER1_COMPA
        reti                            ; TIMER1_OVF
        reti                            ; TIMER0_OVF
        reti                            ; USART0_RX
        reti                            ; USART0_UDRE
        reti                            ; USART0_TX
        reti                            ; ANALOG_COMP
        reti                            ; PC_INT0
        reti                            ; TIMER1_COMPB
        reti                            ; TIMER0_COMPA
        reti                            ; TIMER0_COMPB
        reti                            ; USI_START
        reti                            ; USI_OVERFLOW
        reti                            ; EE_READY
        reti                            ; WDT
        reti                            ; PC_INT1
        reti                            ; PC_INT2



; code entry point
ENTRY:
; set system clock prescaler to 1:1
        ldi     TMP,1<<CLKPCE
        out     CLKPR,TMP
        ldi     TMP,0
        out     CLKPR,TMP
; initialize output ports
        ldi     TMP,0x00                ; PA[01] to output, low
        out     PORTA,TMP
        ldi     TMP,0x03
        out     DDRA,TMP
        ldi     TMP,0x80                ; PB[0-6] to output, low - PB7 to input, pull-up enabled
        out     PORTB,TMP
        ldi     TMP,0x7F
        out     DDRB,TMP
        ldi     TMP,0x7F                ; PD[0-5] to output, high - PD6 to input, pull-up enabled
        out     PORTD,TMP
        ldi     TMP,0x3F
        out     DDRD,TMP
; initialize stack pointer
        ldi     TMP,RAMEND
        out     SPL,TMP
; enable watchdog (64ms)
        wdr
        ldi     TMP,1<<WDCE|1<<WDE
        out     WDTCR,TMP
        ldi     TMP,1<<WDE|1<<WDP1
        out     WDTCR,TMP
        wdr
; disable analog comparator
        ldi     TMP,1<<ACD
        out     ACSR,TMP
; jump to main program
        rjmp    MAIN



; wait 61 cycles
; input: -
; output: -
; changes: TMP
; cycles: 61 (including rcall and ret)
WAIT61:
        ldi     TMP,18
WAIT61_LOOP:
        dec     TMP
        brne    WAIT61_LOOP
; done
        ret



; output row for grayscale (black/white) and wait
; input: X = ptr to pixel data (0..15)
;        GRAY = grayscale value (1..15)
; output: -
; changes: TMP, TMP2, DATA
; cycles: GRAY * 64 + 1 (including rcall and ret)
ROW_BW_WAIT:
; get data for LEDs
        ldi     TMP2,7                  ; 7 pixels
ROW_BW_WAIT_PIXEL:
        ld      TMP,X+                  ; get pixel value
        cp      TMP,GRAY                ; compare with grayscale value
        ror     DATA                    ; store result as output bit
        dec     TMP2                    ; next pixel
        brne    ROW_BW_WAIT_PIXEL
; restore data pointer
        subi    XL,7                    ;   XH not there on ATtiny2313
; output
        lsr     DATA                    ; ensure remaining bit stays high
                                        ;   (pull-up for unused pin)
        com     DATA
        out     COL_PORT,DATA
; wait 5 + (GRAY - 1) * 64
        mov     TMP2,GRAY
        rjmp    ROW_BW_WAIT_LOOP_ENTRY
ROW_BW_WAIT_LOOP:
        rcall   WAIT61
ROW_BW_WAIT_LOOP_ENTRY:
        dec     TMP2
        brne    ROW_BW_WAIT_LOOP
        ret



; turn off row (with same timing as ROW_BW_WAIT)
; input: -
; output: -
; changes: TMP
; cycles: 60 (including rcall and ret)
ROW_OFF:
        ldi     TMP,17
ROW_OFF_LOOP:
        dec     TMP
        brne    ROW_OFF_LOOP
        ldi     TMP,0x80                ; ensure remaining bit stays high
                                        ;   (pull-up for unused pin)
        out     COL_PORT,TMP
        ret



; output row (grayscales)
; input: X = ptr to pixel data (0..15)
; output: -
; changes: TMP, TMP2, DATA
; cycles: 7822 (including rcall and ret)
; time: 1ms
ROW_GRAY:
        ldi     GRAY,1
ROW_GRAY_LOOP:
        rcall   ROW_BW_WAIT
        inc     GRAY
        cpi     GRAY,16
        brlo    ROW_GRAY_LOOP
        rcall   ROW_OFF
; done
        ret



; output a frame
; input: FRAME = pixel data (0..15)
; output: -
; changes: TMP, TMP2, CNT, DATA, X
; time: 6ms
OUT_FRAME:
        wdr
        ldi     XL,low(FRAME)           ; ptr to pixel data
                                        ;   XH not there on ATtiny2313
        ldi     CNT,0x01                ; bitmask loop over rows
OUT_FRAME_LOOP:
        mov     TMP,CNT                 ; select row
        com     TMP
        andi    TMP,0x3F
        ori     TMP,0x40                ; ensure bit 6 stays high
                                        ;   (pull-up for switch input)
        out     ROW_PORT,TMP
        rcall   ROW_GRAY                ; display row
        subi    XL,-7                   ; ptr to next row
                                        ;   XH not there on ATtiny2313
        lsl     CNT                     ; bitmask loop over rows
        cpi     CNT,0x40
        brne    OUT_FRAME_LOOP
; done
        ret



; output a frame for some time
; input: FRAME = pixel data (0..15)
;        TMP = time to show frame (1..255, in 6 ms steps)
; output: -
; changes: X, TMP, TMP2
; time: TMP * 6 ms
OUT_FRAME_TIME:
; output frame
        push    TMP
        push    CNT
        push    DATA
        rcall   OUT_FRAME               ; 6 ms
        pop     DATA
        pop     CNT
        pop     TMP
; loop
        dec     TMP
        brne    OUT_FRAME_TIME
; done
        ret



; clear frame
; input: -
; output: -
; changes: X, FRAME, TMP
; time: short
CLEAR:
        ldi     XL,low(FRAME)           ; ptr to pixel data
                                        ;   XH not there on ATtiny2313
        clr     TMP
CLEAR_LOOP:
        st      X+,TMP                  ; clear pixel
        cpi     XL,low(FRAME)+42        ; bottom of loop
                                        ;   XH not there on ATtiny2313
        brne    CLEAR_LOOP
; done
        ret



; set frame to solid color
; input: DATA = value (0..15)
; output: -
; changes: X, FRAME
; time: short
SET_COLOR:
        ldi     XL,low(FRAME)           ; ptr to pixel data
                                        ;   XH not there on ATtiny2313
SET_COLOR_LOOP:
        st      X+,DATA                 ; set pixel value
        cpi     XL,low(FRAME)+42        ; bottom of loop
                                        ;   XH not there on ATtiny2313
        brne    SET_COLOR_LOOP
; done
        ret



; set pixel
; input: CNT = pixel number (0..41, nothing is done for 42..255)
;        DATA = value (0..15)
; output: -
; changes: X, FRAME, TMP
; time: short
SET_PIXEL:
        cpi     CNT,42                  ; invalid pixel number -> done
        brsh    SET_PIXEL_END
        ldi     XL,low(FRAME)           ; ptr to pixel (base + offset)
        add     XL,CNT                  ;   XH not there on ATtiny2313
        st      X,DATA                  ; set pixel
SET_PIXEL_END:
; done
        ret



; blink animation
; input: -
; output: -
; changes: X, FRAME, CNT, DATA, TMP, TMP2
ANIM_BLINK:
; off
        ldi     DATA,0                  ; minimum color
        rcall   SET_COLOR               ; paint
        ldi     TMP,100                 ; show frame 600 ms
        rcall   OUT_FRAME_TIME
; on
        ldi     DATA,15                 ; maximum color
        rcall   SET_COLOR               ; paint
        ldi     TMP,100                 ; show frame 600 ms
        rcall   OUT_FRAME_TIME
; done
        ret



; fade up and down animation
; input: -
; output: -
; changes: X, FRAME, CNT, DATA, TMP, TMP2
ANIM_FADE:
; fade up
        ldi     DATA,0                  ; start dark
ANIM_FADE_UP:
        rcall   SET_COLOR               ; paint
        ldi     TMP,10                  ; show frame 60 ms
        rcall   OUT_FRAME_TIME
        inc     DATA                    ; fade up
        cpi     DATA,15                 ; loop until almost full on
        brne    ANIM_FADE_UP
; fade down
ANIM_FADE_DOWN:
        rcall   SET_COLOR               ; paint
        ldi     TMP,10                  ; show frame 60 ms
        rcall   OUT_FRAME_TIME
        dec     DATA                    ; fade up
        cpi     DATA,255                ; loop until full off
        brne    ANIM_FADE_DOWN
; done
        ret



; movie data format
;   movie = frame ... frame end
;   frame = 0x0_ ... -> plain frame
;           0x1_ ... -> rle (run length encoded) frame
;           0x2_ ... -> back reference
;   plain frame = duration_high (0x00..0x0F), duration_low (0x00..0xFF),
;                 21 * ( pixel (0x00..0x0F)) << 4 | pixel (0x00..0x0F) )
;   rle frame = 0x10 | duration_high (0x00..0x0F), duration_low (0x00..0xFF),
;               rle entry, ..., rle_entry (until 42 pixels are encoded)
;   rle_entry = repeat (0x00..0x0F) << 4 | value (0x00..0x0F)
;               meaning: repeat + 1 pixels of value
;   back reference = 0x20 | back_high (0x00..0x0F), back_low (0x00..0xFF)
;                    meaning: read frame from earlier position,
;                             frame data start = pos after back ref - back
;   end = 0xF_



; play animation - process code and following section
; input: Z = pointer to movie data
;        TMP2 = 0 -> initial call, 1 -> nested call
; output: Z = pointer to behind processed movie data (only for initial call)
;         TMP = 0 -> go on, 1 -> end
; changes: X, FRAME, TMP, DATA, CNT
;          Z (only for nested call)
ANIM_MOVIE_CODE:
; get 4 bit code and 12 bit value
        lpm     DATA,Z+
        lpm     CNT,Z+
        mov     TMP,DATA
        andi    TMP,0xF0                ; 4 bit code (shifted left 4) is in TMP
        andi    DATA,0x0F               ; 12 bit value is in DATA:CNT
; interpret code
        cpi     TMP,0x20
        brsh    ANIM_MOVIE_CODE_2_TO_F
        cpi     TMP,0x00
        breq    ANIM_MOVIE_CODE_0
        rjmp    ANIM_MOVIE_CODE_1
ANIM_MOVIE_CODE_2_TO_F:
        cpi     TMP,0x20
        breq    ANIM_MOVIE_CODE_2
; unknown code -> end
        ldi     TMP,1                   ; end
        ret

; plain frame
ANIM_MOVIE_CODE_0:
; save 12 bit value
        push    DATA
        push    CNT
; extract frame to frame buffer
        ldi     XL,low(FRAME)           ; ptr to pixel data
                                        ;   XH not there on ATtiny2313
ANIM_MOVIE_CODE_FRAME_PLAIN_LOOP:
        lpm     DATA,Z+                 ; get two pixels
        mov     TMP,DATA                ; write first pixel
        swap    TMP
        andi    TMP,0x0F
        st      X+,TMP
        andi    DATA,0x0F               ; write second pixel
        st      X+,DATA
        cpi     XL,low(FRAME)+42        ; bottom of loop
                                        ;   XH not there on ATtiny2313
        brlo    ANIM_MOVIE_CODE_FRAME_PLAIN_LOOP
; restore 12 bit value
        pop     CNT
        pop     DATA
; show frame
        rjmp    ANIM_MOVIE_CODE_SHOW

; rle frame
ANIM_MOVIE_CODE_1:
; save 12 bit value
        push    DATA
        push    CNT
; extract frame to frame buffer
        ldi     XL,low(FRAME)           ; ptr to pixel data
                                        ;   XH not there on ATtiny2313
        ldi     CNT,0                   ; no pixel data yet
ANIM_MOVIE_CODE_FRAME_RLE_LOOP:
; load new pixel data if none available
        cpi     CNT,0
        brne    ANIM_MOVIE_CODE_FRAME_RLE_DATA_OK
        lpm     DATA,Z+                 ; get repeat count and pixel value
        mov     CNT,DATA
        andi    DATA,0x0F               ; pixel value in DATA
        swap    CNT
        andi    CNT,0x0F                ; repeat count in CNT
        inc     CNT                     ; use for repeat count + 1 pixels
ANIM_MOVIE_CODE_FRAME_RLE_DATA_OK:
; write pixel data to frame
        st      X+,DATA
; count down available pixel data
        dec     CNT
; bottom of loop
        cpi     XL,low(FRAME)+42        ;   XH not there on ATtiny2313
        brlo    ANIM_MOVIE_CODE_FRAME_RLE_LOOP
; restore 12 bit value
        pop     CNT
        pop     DATA
; show frame
        rjmp    ANIM_MOVIE_CODE_SHOW

; back reference
ANIM_MOVIE_CODE_2:
; check if in nested call
        cpi     TMP2,0
        brne    ANIM_MOVIE_CODE_2_NESTED
; save pointer to frame data
        push    ZL
        push    ZH
; go back by 12 bit value in DATA:CNT
        sub     ZL,CNT
        sbc     ZH,DATA
; recursive call
        ldi     TMP2,1                  ; nested call
        rcall   ANIM_MOVIE_CODE
; restore pointer to frame data
        pop     ZH
        pop     ZL
; done
        ldi     TMP,0                   ; continue
        ret

; back reference - nested call
ANIM_MOVIE_CODE_2_NESTED:
; go back by 12 bit value in DATA:CNT
        sub     ZL,CNT
        sbc     ZH,DATA
; recursive tail call (no need to save Z on nested call)
        ldi     TMP2,1                  ; nested call
        rjmp    ANIM_MOVIE_CODE

; show frame
ANIM_MOVIE_CODE_SHOW:
; high part of frame time
        cpi     DATA,0
        breq    ANIM_MOVIE_CODE_SHOW_HIGH_DONE
        ldi     TMP,0                   ; means 256 frames times
        rcall   OUT_FRAME_TIME
        dec     DATA
        rjmp    ANIM_MOVIE_CODE_SHOW
ANIM_MOVIE_CODE_SHOW_HIGH_DONE:
; low part of frame time
        cpi     CNT,0
        breq    ANIM_MOVIE_CODE_SHOW_LOW_DONE
        mov     TMP,CNT
        rcall   OUT_FRAME_TIME
ANIM_MOVIE_CODE_SHOW_LOW_DONE:
; done
        ldi     TMP,0                   ; continue
        ret



; play animation
; input: Z = pointer to movie data
; output: -
; changes: X, Z, FRAME, CNT, DATA, TMP, TMP2
ANIM_MOVIE:
; process code block
        ldi     TMP2,0                  ; initial call
        rcall   ANIM_MOVIE_CODE
; continue if not yet end
        cpi     TMP,0
        breq    ANIM_MOVIE
; done
        ret



.INCLUDE        "movie_funcs.inc"



; read mode from switch and (store animation number)
; input: MODE = old mode, CNT = animation number
; output: MODE = new mode
; changes: TMP, DATA
MODE_READ:
; read new mode (into DATA)
        ldi     DATA,MODE_ALL
        sbic    MODE_SW_PIN,MODE_SW_BIT
        ldi     DATA,MODE_SINGLE
; mode was changed from all to single -> save animation number
        cpi     MODE,MODE_ALL           ; old mode not all -> do nothing
        brne    MODE_READ_NOT_0_TO_1
        cpi     DATA,MODE_SINGLE        ; new mode not single -> do nothing
        brne    MODE_READ_NOT_0_TO_1
        sbic    EECR,EEPE               ; EEPROM write ongoing -> do nothing
        rjmp    MODE_READ_NOT_0_TO_1
        ldi     TMP,0<<EEPM1|0<<EEPM0   ; set EEPROM programming mode
        out     EECR,TMP
        ldi     TMP,0                   ; set EEPROM address
        out     EEARL,TMP
        mov     TMP,CNT                 ; set EEPROM data to animation number
        com     TMP                     ;   with NOTed number in upper nibble
        swap    TMP
        andi    TMP,0xF0
        or      TMP,CNT
        out     EEDR,TMP
        sbi     EECR,EEMPE              ; begin writing EEPROM
        sbi     EECR,EEPE
MODE_READ_NOT_0_TO_1:
; remember new mode (in MODE)
        mov     MODE,DATA
; done
        ret



; animation table: animation function, iteration count (<= 255)
ANIM_TAB:
.INCLUDE        "movie_tab.inc"
        .dw     ANIM_BLINK
        .dw     3
        .dw     ANIM_FADE
        .dw     2
ANIM_TAB_END:


; main program
MAIN:
        wdr

; initialization
        ldi     MODE,MODE_UNKNOWN       ; unknown mode

; get number of fist animation from EEPROM (into CNT)
        ldi     TMP,0                   ; set EEPROM address
        out     EEARL,TMP
        sbi     EECR,EERE               ; start EEPROM read
        in      ANI_NO,EEDR                ; get read value
        mov     TMP,ANI_NO              ; check if high nibble contains NOTed
        com     TMP                     ;   value
        swap    TMP
        cp      ANI_NO,TMP
        brne    MAIN_FIRST_ANIM_INVALID
        andi    ANI_NO,0x0F             ; throw away check value in high nibble
        cpi     ANI_NO,(ANIM_TAB_END - ANIM_TAB) / 2
        brlo    MAIN_FIRST_ANIM_OK
MAIN_FIRST_ANIM_INVALID:
        ldi     ANI_NO,0
MAIN_FIRST_ANIM_OK:
; first iteration of animation (into DATA)
        ldi     ANI_IT,0

; main loop
MAIN_LOOP:
        wdr

; load pointer to animation function and repetition count from table
        ldi     ZL,low(2 * ANIM_TAB)
        ldi     ZH,high(2 * ANIM_TAB)
        mov     TMP,ANI_NO
        lsl     TMP
        lsl     TMP
        add     ZL,TMP
        clr     TMP
        adc     ZH,TMP
        lpm     DATA,Z+                 ; address of function -> TMP:DATA
        lpm     TMP,Z+
        lpm     CNT,Z+                  ; iteration count -> CNT
        mov     ZL,DATA                 ; address of function  -> Z
        mov     ZH,TMP
; save iteration count
        push    CNT
; call animation
        icall
; read new mode
        mov     CNT,ANI_NO
        rcall   MODE_READ
; restore iteration count
        pop     CNT

; keep playing animation in single animation mode
        cpi     MODE,MODE_SINGLE
        breq    MAIN_NEXT_END
; next iteration
        inc     ANI_IT
        cp      ANI_IT,CNT
        brlo    MAIN_NEXT_END
        clr     ANI_IT
; next animation
        inc     ANI_NO
        cpi     ANI_NO,(ANIM_TAB_END - ANIM_TAB) / 2
        brlo    MAIN_NEXT_END
        clr     ANI_NO
MAIN_NEXT_END:

; bottom of main loop
        rjmp     MAIN_LOOP

