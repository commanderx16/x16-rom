
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

;***************
geos:
	jsr bjsrfar
	.word $c000 ; entry
	.byte BANK_GEOS

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
vpeek	jsr chrget
	jsr chkopn ; open paren
	jsr getbyt ; byte: bank
	stx VERA_ADDR_H
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
	jsr chkcls ; closing paren
	ldy VERA_DATA0
	jmp sngflt

;***************
vpoke	jsr getbyt ; bank
	stx VERA_ADDR_H
	jsr chkcom
	jsr getnum
	lda poker
	sta VERA_ADDR_L
	lda poker+1
	sta VERA_ADDR_M
	stx VERA_DATA0
	rts

;***************
vload	jsr plsv   ;parse the parameters
	bcc vld1   ;require bank/addr
	jmp snerr
vld1	lda andmsk ;bank number
	adc #2
	jmp cld10  ;jump to load command

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

;***************
dos	beq ptstat      ;no argument: print status
	jsr frmstr      ;length in .a
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
	jsr listen_cmd
	ldy #0
:	lda (index1),y
	jsr iecout
	iny
	cpy verck       ;length?
	bne :-
	jmp unlstn

listen_cmd:
	jsr getfa
	jsr listen
	lda #$6f
	jsr second
	jsr readst
	bmi device_not_present
	rts
device_not_present:
	ldx #5 ; "DEVICE NOT PRESENT"
	jmp error


;***************
; print status
ptstat	jsr listen_cmd
	jsr unlstn
	jsr getfa
	jsr talk
	lda #$6f
	jsr tksa
dos11	jsr iecin
	jsr bsout
	cmp #13
	bne dos11
	jmp untalk

;***************
; switch default drive
dossw	and #$0f
	sta basic_fa
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

mouse:
	jsr getbyt
	txa
	ldx #0 ; keep scale
	jmp mouse_config

mx:
	jsr chrget
	ldx #fac
	jsr mouse_get
	lda fac+1
	ldy fac
	jmp givayf

my:
	jsr chrget
	ldx #fac
	jsr mouse_get
	lda fac+3
	ldy fac+2
	jmp givayf

mb:
	jsr chrget
	ldx #fac
	jsr mouse_get
	tay
	jmp sngflt

joy:
	jsr chrget
	jsr chkopn ; open paren
	jsr getbyt ; byte: joystick number (1 or 2)
	cpx #1
	beq :+
	cpx #2
	beq :+
	jmp fcerr
:	phx
	jsr chkcls ; closing paren
	pla
	dec ; KERNAL uses #0 and #1
	jsr joystick_get
	eor #$ff
	tay
	jmp sngflt

reset:	
	ldx #5
:	lda reset_copy,x 
	sta $0100,x 
	dex
	bpl :-
	jmp $0100

reset_copy:
	stz d1prb 
	jmp ($fffc)

cls:
	lda #$93
	jmp outch

; BASIC's entry into jsrfar
.setcpu "65c02"
via1	=$9f60                  ;VIA 6522 #1
d1prb	=via1+0
d1pra	=via1+1
.export bjsrfar
bjsrfar:
.include "jsrfar.inc"
