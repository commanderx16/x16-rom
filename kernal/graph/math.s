; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; *COPY* of the GEOS version

.global k_Dabs
.global k_Dnegate
.global k_Ddec

.segment "GRAPH"

;---------------------------------------------------------------
; Dabs                                                    $C16F
;
; Function:  Compute the absolute value of a twos-complement
;            word.
;
; Pass:      x   add. of zpage contaning the nbr
; Return:    x   zpage : contains the absolute value
; Destroyed: a
;---------------------------------------------------------------
k_Dabs:
	lda 1,x
	bmi k_Dnegate
	rts
;---------------------------------------------------------------
; Dnegate                                                 $C172
;
; Function:  Negate a twos-complement word
;
; Pass:      x   add. of zpage : word
; Return:    destination zpage gets negated
; Destroyed: a, y
;---------------------------------------------------------------
k_Dnegate:
	lda 1,x
	eor #$FF
	sta 1,x
	lda 0,x
	eor #$FF
	sta 0,x
	inc 0,x
	bne @1
	inc 1,x
@1:	rts

;---------------------------------------------------------------
; Ddec                                                    $C175
;
; Function:  Decrements an unsigned word
;
; Pass:      x   add. of zpage contaning the nbr
; Return:    x   zpage: contains the decremented nbr
; Destroyed: a
;---------------------------------------------------------------
k_Ddec:
	lda 0,x
	bne @1
	dec 1,x
@1:	dec 0,x
	lda 0,x
	ora 1,x
	rts

.export k_BitMaskPow2, k_BitMaskLeadingSet, k_BitMaskLeadingClear
k_BitMaskPow2:
	.byte %00000001 
	.byte %00000010
	.byte %00000100
	.byte %00001000
	.byte %00010000
	.byte %00100000
	.byte %01000000
	.byte %10000000
k_BitMaskLeadingSet:
	.byte %00000000
	.byte %10000000
	.byte %11000000
	.byte %11100000
	.byte %11110000
	.byte %11111000
	.byte %11111100
	.byte %11111110
k_BitMaskLeadingClear:
	.byte %01111111
	.byte %00111111
	.byte %00011111
	.byte %00001111
	.byte %00000111
	.byte %00000011
	.byte %00000001
	.byte %00000000
