.import cbdos_secnd, cbdos_tksa, cbdos_acptr, cbdos_ciout, cbdos_untlk, cbdos_unlsn, cbdos_listn, cbdos_talk

.import cbmdos_OpenDisk, cbmdos_ReadBuff, cbmdos_ReadBlock, cbmdos_GetDirHead, cbmdos_CalcBlksFree, cbmdos_Get1stDirEntry, cbmdos_GetNxtDirEntry

.import cbdos_sdcard_detect

.segment "cbdos_jmptab"
; $C000

	jmp cbdos_secnd
	jmp cbdos_tksa
	jmp cbdos_acptr
	jmp cbdos_ciout
	jmp cbdos_untlk
	jmp cbdos_unlsn
	jmp cbdos_listn
	jmp cbdos_talk
; GEOS
	jmp cbmdos_OpenDisk
	jmp cbmdos_ReadBuff
	jmp cbmdos_ReadBlock
	jmp cbmdos_GetDirHead
	jmp cbmdos_CalcBlksFree
	jmp cbmdos_Get1stDirEntry
	jmp cbmdos_GetNxtDirEntry

; detection
	jmp cbdos_sdcard_detect

