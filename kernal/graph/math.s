; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; *COPY* of the GEOS version

.global k_Dabs
.global k_Dnegate

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

.global k_BitMaskPow2Rev

.segment "bitmask1"

k_BitMaskPow2Rev:
	.byte %10000000
	.byte %01000000
	.byte %00100000
	.byte %00010000
	.byte %00001000
	.byte %00000100
	.byte %00000010
	.byte %00000001
