;----------------------------------------------------------------------
; CMDR-DOS Jump Table
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.import dos_secnd, dos_tksa, dos_acptr, dos_ciout, dos_untlk, dos_unlsn, dos_listn, dos_talk, dos_macptr

.import dos_OpenDisk, dos_ReadBuff, dos_ReadBlock, dos_GetDirHead, dos_CalcBlksFree, dos_Get1stDirEntry, dos_GetNxtDirEntry

.import dos_init, dos_set_time

.segment "dos_jmptab"
; $C000

; IEEE
	jmp dos_secnd   ; 0
	jmp dos_tksa    ; 1
	jmp dos_acptr   ; 2
	jmp dos_ciout   ; 3
	jmp dos_untlk   ; 4
	jmp dos_unlsn   ; 5
	jmp dos_listn   ; 6
	jmp dos_talk    ; 7

; GEOS
	jmp dos_OpenDisk         ; 8
	jmp dos_ReadBuff         ; 9
	jmp dos_ReadBlock        ; 10
	jmp dos_GetDirHead       ; 11
	jmp dos_CalcBlksFree     ; 12
	jmp dos_Get1stDirEntry   ; 13
	jmp dos_GetNxtDirEntry   ; 14

; init/meta
	jmp dos_init              ; 15
	jmp dos_set_time          ; 16

	jmp dos_macptr            ; 17
