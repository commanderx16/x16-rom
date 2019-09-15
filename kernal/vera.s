.ifdef C64
vera_base = $df00
.else
vera_base = $9f20
.endif

vera_addr_hi  = vera_base + 0
vera_addr_mid = vera_base + 1
vera_addr_lo  = vera_base + 2
vera_data0    = vera_base + 3
vera_data1    = vera_base + 4
vera_ctrl     = vera_base + 5
vera_ien      = vera_base + 6
vera_isr      = vera_base + 7

composer_base    = $0000
palette_base     = $1000
layer0_base      = $2000
layer1_base      = $3000
sprite_reg_base  = $4000
sprite_attr_base = $5000
audio_base       = $6000
spi_base         = $7000
uart_base        = $8000

dc_video        = (composer_base + 0)
dc_hscale       = (composer_base + 1)
dc_vscale       = (composer_base + 2)
dc_border_color = (composer_base + 3)
dc_hstart_l     = (composer_base + 4)
dc_hstop_l      = (composer_base + 5)
dc_vstart_l     = (composer_base + 6)
dc_vstop_l      = (composer_base + 7)
dc_startstop_h  = (composer_base + 8)
dc_irq_line_l   = (composer_base + 9)
dc_irq_line_h   = (composer_base + 10)

l0_ctrl0        = (layer0_base + 0)
l0_ctrl1        = (layer0_base + 1)
l0_map_base_l   = (layer0_base + 2)
l0_map_base_h   = (layer0_base + 3)
l0_tile_base_l  = (layer0_base + 4)
l0_tile_base_h  = (layer0_base + 5)
l0_hscroll_l    = (layer0_base + 6)
l0_hscroll_h    = (layer0_base + 7)
l0_vscroll_l    = (layer0_base + 8)
l0_vscroll_h    = (layer0_base + 9)

l1_ctrl0        = (layer1_base + 0)
l1_ctrl1        = (layer1_base + 1)
l1_map_base_l   = (layer1_base + 2)
l1_map_base_h   = (layer1_base + 3)
l1_tile_base_l  = (layer1_base + 4)
l1_tile_base_h  = (layer1_base + 5)
l1_hscroll_l    = (layer1_base + 6)
l1_hscroll_h    = (layer1_base + 7)
l1_vscroll_l    = (layer1_base + 8)
l1_vscroll_h    = (layer1_base + 9)

spr_ctrl        = (sprite_reg_base + 0)
spr_collision   = (sprite_reg_base + 1)

uart_data       = (uart_base + 0)
uart_status     = (uart_base + 1)
uart_bauddiv_l  = (uart_base + 2)
uart_bauddiv_h  = (uart_base + 3)

; Save VERA registers (only data port 0)
; Clobbers: A
vera_save:
	; Save control register
	lda veractl
	sta vera_irq_save+0

	; Switch to data port 0
	and #$FE
	sta veractl

	; Save address registers of data port 0
	lda verahi
	sta vera_irq_save+1
	lda veramid
	sta vera_irq_save+2
	lda veralo
	sta vera_irq_save+3

	rts

; Restore VERA registers
; Data port 0 should be selected when calling this function
; Clobbers: A
vera_restore:
	; Restore address registers
	lda vera_irq_save+1
	sta verahi
	lda vera_irq_save+2
	sta veramid
	lda vera_irq_save+3
	sta veralo

	; Restore data port
	lda vera_irq_save+0
	sta veractl

	rts

.macro vera_addr hi, addr
	lda #>addr
	sta veralo
	lda #<addr
	sta veramid
	lda #hi
	sta verahi
.endmacro

.macro lda_vaddr hi, addr
	lda #>addr
	sta veralo
	lda #<addr
	sta veramid
	lda #hi
	sta verahi
	lda veradat
.endmacro

.macro lda_vaddr_lo addr
	lda #>addr
	sta veralo
	lda veradat
.endmacro

.macro ldx_vaddr_lo addr
	ldx #>addr
	stx veralo
	ldx veradat
.endmacro
