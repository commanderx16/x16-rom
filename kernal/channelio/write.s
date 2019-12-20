;compare start and end load/save
;addresses.  subroutine called by
;tape read, save, tape write
;
cmpste	sec
	lda sal
	sbc eal
	lda sah
	sbc eah
	rts

;increment address pointer sal
;
incsal	inc sal
	bne incr
	inc sah
incr	rts
