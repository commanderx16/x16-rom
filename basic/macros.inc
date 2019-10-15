;
; declare a string with the last char with msb=1 as terminator
;
.macro  tokString    str
	.byte .sprintf (.concat ("%.", .string (.strlen(str) - 1) ,"s%c"), str, $80 + .strat (str, .strlen(str) - 1))
.endmacro
