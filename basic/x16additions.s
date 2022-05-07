
VERA_BASE = $9F20

VERA_ADDR_L   	  = (VERA_BASE + $00)
VERA_ADDR_M   	  = (VERA_BASE + $01)
VERA_ADDR_H   	  = (VERA_BASE + $02)
VERA_DATA0        = (VERA_BASE + $03)
VERA_DATA1        = (VERA_BASE + $04)
VERA_CTRL         = (VERA_BASE + $05)

VERA_IEN          = (VERA_BASE + $06)
VERA_ISR          = (VERA_BASE + $07)
VERA_IRQ_LINE_L   = (VERA_BASE + $08)

VERA_DC_VIDEO     = (VERA_BASE + $09)
VERA_DC_HSCALE    = (VERA_BASE + $0A)
VERA_DC_VSCALE    = (VERA_BASE + $0B)
VERA_DC_BORDER    = (VERA_BASE + $0C)

VERA_DC_HSTART    = (VERA_BASE + $09)
VERA_DC_HSTOP     = (VERA_BASE + $0A)
VERA_DC_VSTART    = (VERA_BASE + $0B)
VERA_DC_VSTOP     = (VERA_BASE + $0C)

VERA_L0_CONFIG    = (VERA_BASE + $0D)
VERA_L0_MAPBASE   = (VERA_BASE + $0E)
VERA_L0_TILEBASE  = (VERA_BASE + $0F)
VERA_L0_HSCROLL_L = (VERA_BASE + $10)
VERA_L0_HSCROLL_H = (VERA_BASE + $11)
VERA_L0_VSCROLL_L = (VERA_BASE + $12)
VERA_L0_VSCROLL_H = (VERA_BASE + $13)

VERA_L1_CONFIG    = (VERA_BASE + $14)
VERA_L1_MAPBASE   = (VERA_BASE + $15)
VERA_L1_TILEBASE  = (VERA_BASE + $16)
VERA_L1_HSCROLL_L = (VERA_BASE + $17)
VERA_L1_HSCROLL_H = (VERA_BASE + $18)
VERA_L1_VSCROLL_L = (VERA_BASE + $19)
VERA_L1_VSCROLL_H = (VERA_BASE + $1A)

VERA_AUDIO_CTRL   = (VERA_BASE + $1B)
VERA_AUDIO_RATE   = (VERA_BASE + $1C)
VERA_AUDIO_DATA   = (VERA_BASE + $1D)

VERA_SPI_DATA     = (VERA_BASE + $1E)
VERA_SPI_CTRL     = (VERA_BASE + $1F)

VERA_PSG_BASE     = $1F9C0
VERA_PALETTE_BASE = $1FA00
VERA_SPRITES_BASE = $1FC00

;***************
monitor:
	jsr bjsrfar
	.word $c000
	.byte BANK_MONITOR
	; does not return

;***************
codex:
   jsr bjsrfar
   .word $c000
   .byte BANK_CODEX
	; does not return

;***************
geos:
	jsr bjsrfar
	.word $c000 ; entry
	.byte BANK_GEOS
	; does not return

;***************
color	jsr getcol ; fg
	lda coltab,x
	jsr bsout
	jsr chrgot
	bne :+
	rts
:	jsr chkcom
	jsr getcol ; bg
	lda #1 ; swap fg/bg
	jsr bsout
	lda coltab,x
	jsr bsout
	lda #1 ; swap fg/bg
	jmp bsout


getcol	jsr getbyt
	cpx #16
	bcc :+
	jmp fcerr
:	rts

coltab	;this is an unavoidable duplicate from KERNAL
	.byt $90,$05,$1c,$9f,$9c,$1e,$1f,$9e
	.byt $81,$95,$96,$97,$98,$99,$9a,$9b

;***************
; convert byte to binary in zero terminated string and
; return it to BASIC
bind:	jsr chrget ; get char
	jsr chkopn ; check opening paren
	jsr frmadr ; get 16 bit word in Y/A
; lofbuf starts at address $00FF and continues into
; page 1 ($0100).
; Forcing address size to 16bit allows us to cross
; from zero page to page $01 when using .X as an index
	ldx #0
	phy	   ; save low byte
	tay	   ; save high byte to check for 0 later
	cmp #0
	bne @LOOP
	pla
@LOOP:	asl	   ; high bit to carry
	pha	   ; save .A for next iteration
	lda #'1'
	bcs :+
	dec
:	sta a:lofbuf,X
	pla	   ; restore .A
	inx
	cpy #0
	bne :+
	cpx #8
	bne @LOOP
	bra @DONE
:	cpx #8
	bcc @LOOP
	bne :+
	pla
:	cpx #16
	bne @LOOP
@DONE:	stz a:lofbuf,X ; zero terminate string
	jsr chkcls ; end of conversion, check closing paren
	pla        ; remove return address from stack
	pla
	jmp strlitl; allocate and return string value from lofbuf

;***************
; convert byte to hex in zero terminated string and
; return it to BASIC
hexd:	jsr chrget ; get char
	jsr chkopn ; check opening paren
	jsr frmadr ; get 16 bit word in Y/A
	ldx #0	   ; use .X for indexing
	phy	   ; Save low byte
	cmp #0	   ; If high-byte is 0, we only convert low byte
	beq @LOWBYTE
	jsr byte_to_hex_ascii
	sta a:lofbuf,X
	tya
	inx
	sta a:lofbuf,X
	inx
@LOWBYTE:
	pla	   ; restore low byte
	jsr byte_to_hex_ascii
	sta a:lofbuf,X
	tya
	inx
	sta a:lofbuf,X
	inx
	stz a:lofbuf,X
	jsr chkcls ; end of conversion, check closing paren
	pla        ; remove return address from stack
	pla
	jmp strlitl; allocate and return string value from lofbuf

; convert byte into hex ASCII in A/Y
; copied from monitor.s
byte_to_hex_ascii:
	pha
        and     #$0F
        jsr     @LBCC8
        tay
        pla
        lsr
        lsr
        lsr
        lsr
@LBCC8: clc
        adc     #$F6
        bcc     @LBCCF
        adc     #$06
@LBCCF: adc     #$3A
        rts

;***************
vpeek	jsr chrget
	jsr chkopn ; open paren
	jsr getbyt ; byte: bank
	phx
	jsr chkcom
	lda poker
	pha
	lda poker + 1
	pha
	jsr frmadr ; word: offset
	sty VERA_ADDR_L
	sta VERA_ADDR_M
	pla
	sta poker + 1
	pla
	sta poker
	pla
	sta VERA_ADDR_H
	jsr chkcls ; closing paren
	ldy VERA_DATA0
	jmp sngflt

;***************
vpoke	jsr getbyt ; bank
	phx
	jsr chkcom
	jsr getnum
	pla
	sta VERA_ADDR_H
	lda poker
	sta VERA_ADDR_L
	lda poker+1
	sta VERA_ADDR_M
	stx VERA_DATA0
	rts

;***************
bvrfy
	lda #1
	bra :+
bload
	lda #0
:	pha
	jsr plsvbin
	bcc bload2
	pla
	bcs :+
bload2
	jmp cld8        ; -> load command w/ ram bank switch to chosen bank

vload	jsr plsv        ;parse the parameters
	bcc vld1        ;require bank/addr
:	jmp snerr

bvload	jsr plsvbin	;parse, with SA=2 if successful
	bcs :-

vld1	lda andmsk      ;bank number
	adc #2
	jmp cld10       ;jump to load command

;***************
old	beq old1
	jmp snerr
old1	lda txttab+1
	ldy #1
	sta (txttab),y
	jsr lnkprg
	clc
	lda index
	adc #2
	sta vartab
	lda index+1
	adc #0
	sta vartab+1
	jmp init2

; ----------------------------------------------------------------
; XXX This is very similar to the code in MONITOR. When making
; XXX changes, have a look at both versions!
; ----------------------------------------------------------------
;***************
dos	beq ptstat      ;no argument: print status
	jsr frmevl
	bit valtyp
	bmi @str
; numeric
	jsr getadr
	cmp #0          ;lo
	beq :+
@fcerr	jmp fcerr
:	cpy #8           ;hi
	bcc @fcerr
	cpy #32
	bcs @fcerr
	tya
	jmp dossw

@str	jsr frefac      ;get ptr to string, length in .a
	cmp #0
	beq ptstat      ;no argument: print status
	sta verck       ;save length
	ldx index1
	ldy index1+1
	jsr setnam
	ldy #0
	lda (index1),y
; dir?
	cmp #'$'
	beq disk_dir
; switch default drive?
	cmp #'8'
	beq dossw
	cmp #'9'
	beq dossw

;***************
; DOS command
	sec
	jsr listen_cmd
	ldy #0
:	lda (index1),y
	jsr iecout
	iny
	cpy verck       ;length?
	bne :-
	jmp unlstn

; in:  C=1 show "DEVICE NOT PRESENT" on error
;      C=0 return error in C
; out: C=0 no error
;      C=1 error
listen_cmd:
	php
	jsr getfa
	jsr listen
	lda #$6f
	jsr second
	jsr readst
	bmi @error
	plp
	clc
	rts
@error:	plp
	bcs device_not_present
	sec
	rts
device_not_present:
	ldx #5 ; "DEVICE NOT PRESENT"
	jmp error


clear_disk_status:
	clc
	bra ptstat2
;***************
; print status
ptstat	sec
ptstat2	php
	; keep C:
	; for printing status, print error
	; for clearing status, return error
	jsr listen_cmd
	bcc :+
	plp
	rts
:	jsr unlstn
	jsr getfa
	jsr talk
	lda #$6f
	jsr tksa
dos11	jsr iecin
	plp
	php
	bcc :+
	jsr bsout
:	cmp #13
	bne dos11
	plp
	jmp untalk

;***************
; switch default drive
dossw	sta basic_fa
	rts

getfa:
	lda #8
	cmp basic_fa
	bcs :+
	lda basic_fa
:	rts


;***************
;  read & display the disk directory

LOGADD = 15

disk_dir
	jsr getfa
	tax
	lda #LOGADD     ;la
	ldy #$60        ;sa
	jsr setlfs
	jsr open        ;open directory channel
	jsr readst
	bpl :+
	lda #LOGADD
	jsr close
	jmp device_not_present
:	ldx #LOGADD
	jsr chkin       ;make it an input channel

	jsr crdo

	ldy #4          ;first pass only- trash first four bytes read

@d20
@d25	jsr basin
	jsr readst
	bne disk_done   ;...branch if error
	dey
	bne @d25        ;...loop until done

	jsr basin       ;get # blocks low
	pha
	jsr readst
	tay
	pla
	cpy #0
	bne disk_done   ;...branch if error
	tax
	jsr basin       ;get # blocks high
	pha
	jsr readst
	tay
	pla
	cpy #0
	bne disk_done   ;...branch if error
	jsr linprt      ;print # blocks

	lda #' '
	jsr bsout       ;print space  (to match loaded directory display)

@d30	jsr basin       ;read & print filename & filetype
	beq @d40        ;...branch if eol
	pha
	jsr readst
	tax
	pla
	cpx #0
	bne disk_done   ;...branch if error
	jsr bsout
	bcc @d30        ;...loop always

@d40	jsr crdo        ;start a new line
	jsr stop
	beq disk_done   ;...branch if user hit STOP
	ldy #2
	bne @d20        ;...loop always

disk_done
	jsr clrch
	lda #LOGADD
	sec
	jmp close

; like getbyt, but negative numbers will become $FF
getbytneg:
	jsr frmnum      ;get numeric value into FAC
	lda facsgn
	bpl @pos
	ldx #$ff
	rts
@pos:	jmp conint      ;convert to byte

;***************
mouse:
	jsr getbytneg
	phx
	sec
	jsr screen_mode
	pla
	jmp mouse_config

;***************
mx:
	jsr chrget
	ldx #fac
	jsr mouse_get
	lda fac+1
	ldy fac
	jmp givayf0

;***************
my:
	jsr chrget
	ldx #fac
	jsr mouse_get
	lda fac+3
	ldy fac+2
	jmp givayf0

;***************
mb:
	jsr chrget
	ldx #fac
	jsr mouse_get
	tay
	jmp sngflt

;***************
joy:
	jsr chrget
	jsr chkopn ; open paren
	jsr getbyt ; byte: joystick number (0-4)
	cpx #5
	bcc :+
	jmp fcerr
:	phx
	jsr chkcls ; closing paren
	pla
	jsr joystick_get
	iny
	bne :+
	lda #<minus1 ; not present?
	ldy #>minus1 ; then return -1
	jmp movfm
:	eor #$ff
	tay
	txa
	eor #$ff
	lsr
	lsr
	lsr
	lsr
	jmp givayf0

minus1:	.byte $81, $80, $00, $00, $00

;***************
reset:
	ldx #5
:	lda reset_copy,x
	sta $0100,x
	dex
	bpl :-
	jmp $0100

reset_copy:
	stz rom_bank
	jmp ($fffc)

;***************
cls:
	lda #$93
	jmp outch

;***************
locate:
	jsr screen
	stx poker
	sty poker+1

	jsr getbyt ; byte: line
	php
	dex
	bmi @error
	cpx poker+1
	bcs @error
	plp
	phx
	bne @1

; just set the line, leave the column the same
	sec
	jsr plot
	bra @2

@1:	jsr chkcom
	jsr getbyt
	txa
	tay
	dey
	bmi @error
	cpy poker
	bcs @error

@2:	plx
	clc
	jmp plot

@error:
	jmp fcerr

;***************
ckeymap:
	jsr frmstr
	cmp #6
	bcs @fcerr
	tay
	lda #0
	sta a:lofbuf,y  ;make a copy, so we can
	dey             ;zero-terminate it
:	lda (index1),y
	sta a:lofbuf,y
	dey
	bpl :-
	ldx #<lofbuf
	ldy #>lofbuf
	clc
	jsr keymap
	bcs @fcerr
	rts
@fcerr:	jmp fcerr

;***************
test:
	beq @test0
	jsr getbyt
	txa
	cmp #4
	bcc @run
	jmp fcerr

@test0:	lda #0
@run:
	pha	; index
	ldx #@copy_end-@copy-1
:	lda @copy,x
	sta $0400,x
	dex
	bpl :-
	jmp $0400

@copy:
	sei
	lda #8
	sta rom_bank
	lda #<$c000
	sta 2
	lda #>$c000
	sta 3
	lda #<$1000
	sta 4
	lda #>$1000
	sta 5
	ldx #$40
	ldy #0
:	lda (2),y
	sta (4),y
	iny
	bne :-
	inc 3
	inc 5
	dex
	bne :-
	lda #$6c
	sta $0400
	pla
	asl
	sta $0401
	lda #$10
	sta $0402
	stz rom_bank
	cli
	jmp $0400
@copy_end:

; BASIC's entry into jsrfar
.setcpu "65c02"
ram_bank = 0
rom_bank = 1
.export bjsrfar
bjsrfar:
.include "jsrfar.inc"
