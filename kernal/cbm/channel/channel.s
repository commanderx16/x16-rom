;----------------------------------------------------------------------
; Channel
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

.feature labels_without_colons

.include "io.inc"
.include "banks.inc"

bsout = $ffd2
close = $ffc3
clrch = $ffcc
stop  = $ffe1

; keyboard
.import kbdbuf_clear
.import kbdbuf_get
.import kbdbuf_get_stop

; rs232
.import bsi232
.import bso232
.import cki232
.import cko232
.import cls232
.import opn232
.export t1

; serial
acptr = $ffa5
macptr= $ff44
ciout = $ffa8
listn = $ffb1
secnd = $ff93
talk  = $ffb4
tksa  = $ff96
unlsn = $ffae
untlk = $ffab
.import scatn
.import tkatn

; vectors
.import iload
.import isave

; editor
.import crsw
.import indx
.import lnmx
.import loop5
.import lstp
.import lsxp
.import pntr
.import prt
.import tblx

; KERNAL API
.export savesp
.export loadsp
.export setnam
.export setlfs
.export readst
.export settmo
.export setmsg
.export lkupsa
.export lkupla
.export close_all
; vecors
.export nsave
.export nload
.export nclall
.export ngetin
.export nstop
.export nbsout
.export nbasin
.export nclrch
.export nckout
.export nchkin
.export nclose
.export nopen

; serial
.export udst

; XXX exports that shouldn't be
.export dfltn
.export dflto
.export la, sa, fa, fnlen
.export status
.export sal, sah

.segment "ZPCHANNEL" : zeropage
;                      C64 location
;                         VVV
sal	.res 1           ;$AC
sah	.res 1           ;$AD
eal	.res 1           ;$AE
eah	.res 1           ;$AF
fnadr	.res 2           ;$BB addr current file name str
memuss	.res 2           ;$C3 load temps

.segment "VARCHANNEL"

; Channel I/O
;
lat	.res 10          ;    logical file numbers
fat	.res 10          ;    primary device numbers
sat	.res 10          ;    secondary addresses
.assert * = status, error, "update banks.inc!"
__status
	.res 1           ;$90 i/o operation status byte
verck	.res 1           ;$93 load or verify flag
xsav	.res 1           ;$97 temp for basin
ldtnd	.res 1           ;$98 index to logical file
dfltn	.res 1           ;$99 default input device #
dflto	.res 1           ;$9A default output device #
msgflg	.res 1           ;$9D os message flag
t1	.res 1           ;$9E temporary 1
fnlen	.res 1           ;$B7 length current file n str
la	.res 1           ;$B8 current file logical addr
sa	.res 1           ;$B9 current file 2nd addr
fa	.res 1           ;$BA current file primary addr
stal	.res 1           ;$C1
stah	.res 1           ;$C2

.segment "CHANNEL"

.include "messages.s"
.include "channelio.s"
.include "openchannel.s"
.include "close.s"
.include "clall.s"
.include "open.s"
.include "load.s"
.include "save.s"
.include "errorhandler.s"

