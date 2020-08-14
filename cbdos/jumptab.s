;----------------------------------------------------------------------
; CBDOS Jump Table
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.import cbdos_secnd, cbdos_tksa, cbdos_acptr, cbdos_ciout, cbdos_untlk, cbdos_unlsn, cbdos_listn, cbdos_talk, cbdos_macptr

.import cbmdos_OpenDisk, cbmdos_ReadBuff, cbmdos_ReadBlock, cbmdos_GetDirHead, cbmdos_CalcBlksFree, cbmdos_Get1stDirEntry, cbmdos_GetNxtDirEntry

.import cbdos_init, cbdos_set_time

.segment "cbdos_jmptab"
; $C000

; IEEE
	jmp cbdos_secnd   ; 0
	jmp cbdos_tksa    ; 1
	jmp cbdos_acptr   ; 2
	jmp cbdos_ciout   ; 3
	jmp cbdos_untlk   ; 4
	jmp cbdos_unlsn   ; 5
	jmp cbdos_listn   ; 6
	jmp cbdos_talk    ; 7

; GEOS
	jmp cbmdos_OpenDisk         ; 8
	jmp cbmdos_ReadBuff         ; 9
	jmp cbmdos_ReadBlock        ; 10
	jmp cbmdos_GetDirHead       ; 11
	jmp cbmdos_CalcBlksFree     ; 12
	jmp cbmdos_Get1stDirEntry   ; 13
	jmp cbmdos_GetNxtDirEntry   ; 14

; init/meta
	jmp cbdos_init              ; 15
	jmp cbdos_set_time          ; 16

	jmp cbdos_macptr            ; 17
