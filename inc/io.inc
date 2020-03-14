
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

via1	=$9f60                  ;VIA 6522 #1
d1prb	=via1+0
d1pra	=via1+1
d1ddrb	=via1+2
d1ddra	=via1+3
d1t1l	=via1+4
d1t1h	=via1+5
d1t1ll	=via1+6
d1t1lh	=via1+7
d1t2l	=via1+8
d1t2h	=via1+9
d1sr	=via1+10
d1acr	=via1+11
d1pcr	=via1+12
d1ifr	=via1+13
d1ier	=via1+14
d1ora	=via1+15

via2	=$9f70                  ;VIA 6522 #2
d2prb	=via2+0
d2pra	=via2+1
d2ddrb	=via2+2
d2ddra	=via2+3
d2t1l	=via2+4
d2t1h	=via2+5
d2t1ll	=via2+6
d2t1lh	=via2+7
d2t2l	=via2+8
d2t2h	=via2+9
d2sr	=via2+10
d2acr	=via2+11
d2pcr	=via2+12
d2ifr	=via2+13
d2ier	=via2+14
d2ora	=via2+15

;
; VERA Video RAM Layout
;
; $0:0000 - $0:3BFF  Text Mode
; $0:3C00 - $0:77FF  -- unused --
; $0:7800 - $0:F7FF  Sprites
;                    $0:7800  Sprite #0
;                    $0:8800  Sprite #1
;                    $0:9800  Sprite #2
;                    $0:A800  Sprite #3
;                    $0:B800  Sprite #4
;                    $0:C800  Sprite #5
;                    $0:D800  Sprite #6
;                    $0:E800  Sprite #7
; $0:F800 - $0:FFFF  Charset
; $1:0000 - $1:F9FF  320x200@256c Bitmap
; $1:FA00 - $1:FFFF  -- unused --

sprite_addr = $07800
tilbas      = $0f800
