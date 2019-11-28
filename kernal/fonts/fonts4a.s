; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; Font drawing: indirect jump helper

FntIndirectJMP:
	ldy #0
	jmp (r13)

