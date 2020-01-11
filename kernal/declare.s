.export buf; [monitor]
.export tmp2; [cpychr]
.export ckbtab; [ps2kbd]
.export imparm; [jsrfar]
.export ptr_fg; [graph]
.export kvswitch_tmp1, kvswitch_tmp2
.export mhz

mhz     =8

.segment "ZPKERNAL" : zeropage
;                      C64 location
;                         VVV
tmp2	.res 2           ;$C3
.assert * = imparm, error, "imparm must be at specific address"
;imparm
	.res 2           ;    PRIMM utility string pointer
ckbtab	.res 2           ;    used for keyboard lookup
ptr_fg	.res 2

.segment "KVAR"

;                      C64 location
;                         VVV
buf	.res 2*40+1      ;    basic/monitor buffer
.assert buf = $0200, error, "buf has to be at $0200"

; Memory
memstr	.res 2           ;    start of memory
memsiz	.res 2           ;    top of memory
rambks	.res 1           ;    X16: number of ram banks (0 means 256)
kvswitch_tmp1
	.res 1
kvswitch_tmp2
	.res 1

.segment "GDRVVEC"

.export I_FB_BASE, I_FB_END; [graph]
I_FB_BASE:
I_FB_init:
	.res 2
I_FB_get_info:
	.res 2
I_FB_set_palette
	.res 2
I_FB_cursor_position:
	.res 2
I_FB_cursor_next_line:
	.res 2
I_FB_get_pixel:
	.res 2
I_FB_get_pixels:
	.res 2
I_FB_set_pixel:
	.res 2
I_FB_set_pixels:
	.res 2
I_FB_set_8_pixels:
	.res 2
I_FB_set_8_pixels_opaque:
	.res 2
I_FB_fill_pixels:
	.res 2
I_FB_filter_pixels:
	.res 2
I_FB_move_pixels:
	.res 2
I_FB_END:

	.segment "KVECTORS";rem kernal/os indirects(20)
cinv	.res 2           ;irq ram vector
cbinv	.res 2           ;brk instr ram vector
nminv	.res 2           ;nmi ram vector
iopen	.res 2           ;indirects for code
iclose	.res 2           ; conforms to kernal spec 8/19/80
ichkin	.res 2
ickout	.res 2
iclrch	.res 2
ibasin	.res 2
ibsout	.res 2
istop	.res 2
igetin	.res 2
iclall	.res 2
usrcmd	.res 2
iload	.res 2
isave	.res 2           ;savesp
