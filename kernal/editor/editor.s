.feature labels_without_colons
.setcpu "65c02"

;screen editor constants
;
white	=$01            ;white char color
blue	=$06            ;blue screen color

.export plot   ; set cursor position
.export scrorg ; return screen size
.export cint   ; initialize screen
.export prt    ; print character
.export loop5  ; input a line until carriage return

.importzp mhz  ; constant

.importzp sah, sal   ; XXX looks unused
.import dfltn, dflto ; XXX move "panic" out

.import jsrfar ; for banked_cpychr
.import iokeys

; kernal
.export crsw
.export hibase
.export indx
.export lnmx
.export lstp
.export lsxp
.export key
.export scrmod

; monitor and kernal
.export tblx
.export pntr

; monitor
.export blnon
.export blnsw
.export gdbln
.export insrt
.export ldtb1
.export nlines
.export nlinesm1
.export qtsw
.export rvs
.export stapnty
.export ldapnty
.export xmon1
.export loop4
.export bmt2
.export pnt

.include "../../banks.inc"
.include "../../io.inc"

.segment "ZPKERNAL" : zeropage
pnt	.res 2           ;$D1 pointer to row

.segment "KVAR"

; Screen Mode
;
cscrmd	.res 1           ;    X16: current screen mode (argument to scrmod)

.segment "KVAR2" ; more KERNAL vars
ldtb1	.res 61 +1       ;flags+endspace
	;       ^^ XXX at label 'lps2', the code counts up to
	;              numlines+1, THEN writes the end marker,
	;              which seems like one too many. This was
	;              worked around for now by adding one more
	;              byte here, but we should have a look at
	;              whether there's an off-by-one error over
	;              at 'lps2'!

; Screen
;
.export mode; [ps2kbd]
.export data; [cpychr]
mode	.res 1           ;    bit7=1: charset locked, bit6=1: ISO
gdcol	.res 1           ;    original color before cursor
hibase	.res 1           ;    base location of screen (top)
autodn	.res 1           ;    auto scroll down flag(=0 on,<>0 off)
lintmp	.res 1           ;    temporary for line index
color	.res 1           ;    activ color nybble
rvs	.res 1           ;$C7 rvs field on flag
indx	.res 1           ;$C8
lsxp	.res 1           ;$C9 x pos at start
lstp	.res 1           ;$CA
blnsw	.res 1           ;$CC cursor blink enab
blnct	.res 1           ;$CD count to toggle cur
gdbln	.res 1           ;$CE char before cursor
blnon	.res 1           ;$CF on/off blink flag
crsw	.res 1           ;$D0 input vs get flag
pntr	.res 1           ;$D3 pointer to column
qtsw	.res 1           ;$D4 quote switch
lnmx	.res 1           ;$D5 40/80 max positon
tblx	.res 1           ;$D6
data	.res 1           ;$D7
insrt	.res 1           ;$D8 insert mode flag
llen	.res 1           ;$D9 x resolution
nlines	.res 1           ;$DA y resolution
nlinesp1 .res 1          ;    X16: y resolution + 1
nlinesm1 .res 1          ;    X16: y resolution - 1

.segment "EDITOR"

.include "editor.1.s"
.include "editor.3.s"

