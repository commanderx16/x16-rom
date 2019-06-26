rd300	lda stah        ; restore starting address...
	sta sah         ;...pointers (sah & sal)
	lda stal
	sta sal
	rts
