;----------------------------------------------------------------------
; KERNAL: zp/vars
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

.include "banks.inc"

.export tmp2; [cpychr]
.export kvswitch_tmp1, kvswitch_tmp2
.export mhz

mhz     =8

.segment "ZPKERNAL" : zeropage
;                      C64 location
;                         VVV
tmp2	.res 2           ;$C3
.assert * = imparm, error, "imparm must be at specific address"
__imparm
	.res 2           ;    PRIMM utility string pointer

.segment "KVAR"

;                      C64 location
;                         VVV
buf	.res 2*40+1      ;    basic/monitor buffer
.assert buf = $0200, error, "buf has to be at $0200"

; Memory
kvswitch_tmp1
	.res 1
kvswitch_tmp2
	.res 1

	.segment "KVECTORS";rem kernal/os indirects(20)

.export cinv, cbinv, nminv, iopen, iclose, ichkin, ickout, iclrch, ibasin, ibsout, istop, igetin, iclall, keyhdl, iload, isave; [vectors]

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
keyhdl	.res 2
iload	.res 2
isave	.res 2           ;savesp
