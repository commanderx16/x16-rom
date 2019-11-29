.segment "GRAPH"

.setcpu "65c02"

.include "../../regs.inc"
.include "../../io.inc"
.include "../../mac.inc"
.include "fonts.inc"

.import k_col1, k_col2

.if 0
; GEOS public
.import baselineOffset ; 1 byte
.import curSetWidth ; 2 bytes
.import curHeight ; 1 byte
.importzp curIndexTable ; 2 bytes
.import cardDataPntr ; 2 bytes
.import currentMode ; 1 byte
.import windowTop ; 1 byte
.import windowBottom ; 1 byte
.import leftMargin ; 2 bytes
.import rightMargin ; 2 bytes

; GEOS private
.import compatMode ; 1 byte
.import fontTemp1 ; 8 bytes
.import fontTemp2 ; 9 bytes
.import PrvCharWidth ; 1 byte
.import FontTVar1 ; 1 byte
.import FontTVar2 ; 2 bytes
.import FontTVar3 ; 1 byte
.import FontTVar4 ; 1 byte
.else
baselineOffset = $26 ; [fonts; conio; menu] ;;
curSetWidth    = $27 ; [fonts]              ;;
curHeight      = $29 ; [fonts; conio; menu] ;;
curIndexTable  = $2a ; [fonts; conio]       ;;
cardDataPntr   = $2c ; [fonts; conio]       ;;

currentMode    = $2e ; [fonts; conio; menu; dlgbox]
windowTop      = $33 ; [fonts]
windowBottom   = $34 ; [fonts]
leftMargin     = $35 ; [fonts; conio; menu]
rightMargin    = $37 ; [fonts; conio; menu; dlgbox]

compatMode      =       $3f ; (on C128, this is graphMode)
CallRLo         =       $44 ; [CallRoutine]
CallRHi         =       $45 ; [CallRoutine]
fontTemp1       =       $48 ; 8 bytes
fontTemp2       =       $50 ; 9 bytes
PrvCharWidth    =       $59 ; 1 byte
FontTVar1       =       $5a ; 1 byte
FontTVar2       =       $5b ; 2 bytes
FontTVar3       =       $5d ; 1 byte
FontTVar4       =       $5e ; 1 byte
.endif

.include "fonts1.s"
.include "fonts2.s"
.include "fonts3.s"
.include "fonts4.s"
.include "fonts4a.s"
.include "fonts4b.s"
.include "conio3b.s"
.include "sysfont.s"

