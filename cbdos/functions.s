;----------------------------------------------------------------------
; CBDOS Functions
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "functions.inc"

; fat32.s
.import fat32_ptr, fat32_ptr2
.import fat32_alloc_context, fat32_free_context, fat32_set_context
.import fat32_mkdir, fat32_rmdir, fat32_chdir, fat32_rename, fat32_delete

; parser.s
.import medium, unix_path, unix_path2, create_unix_path, create_unix_path_b

.macro debug_print text
	ldx #0
:	lda @txt,x
	beq :+
	jsr bsout
	inx
	bra :-
:	lda #$0d
	jsr bsout
	bra :+
@txt:	.asciiz text
:
.endmacro

.macro FAT32_CONTEXT_START
	jsr fat32_alloc_context
	pha
	jsr fat32_set_context
.endmacro

.macro FAT32_CONTEXT_END
	pla
	jsr fat32_free_context
.endmacro

.code

;---------------------------------------------------------------
create_fat32_path:
	lda #<unix_path
	sta fat32_ptr + 0
	lda #>unix_path
	sta fat32_ptr + 1
	ldy #0
	jmp create_unix_path

create_fat32_path_x2:
	jsr create_fat32_path

	tya
	clc
	adc #<unix_path
	sta fat32_ptr2 + 0
	lda #>unix_path
	adc #0
	sta fat32_ptr2 + 1

	jmp create_unix_path_b

check_medium:
	lda medium
check_medium_a:
	cmp #2
	bcc :+
	pla
	pla
	lda #$74
:	rts

;---------------------------------------------------------------
; for all these implementations:
;
; Out:  a  status
;       c  (unused)
;---------------------------------------------------------------

;---------------------------------------------------------------
; In:   medium  medium
;---------------------------------------------------------------
initialize:
.ifdef DEBUG
	debug_print "I"
	jsr print_medium
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium  medium
;---------------------------------------------------------------
validate:
.ifdef DEBUG
	debug_print "V"
	jsr print_medium
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium  medium
;       r0      name
;       r1      id
;       a       format (1st char)
;---------------------------------------------------------------
new:
.ifdef DEBUG
	pha
	debug_print "N"
	jsr print_medium
	jsr print_r0
	jsr print_r1
	pla
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1  medium/path/name
; Out:  x             number of files scratched
;---------------------------------------------------------------
scratch:
	jsr check_medium
	FAT32_CONTEXT_START
	jsr create_fat32_path
	jsr fat32_delete
	bcc @error
	FAT32_CONTEXT_END
	lda #0
	ldx #1
	rts
@error:
	FAT32_CONTEXT_END
	lda #0
	tax
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
make_directory:
	jsr check_medium
	FAT32_CONTEXT_START
	jsr create_fat32_path
	jsr fat32_mkdir
	bcs :+
	jmp write_error
:	FAT32_CONTEXT_END
	lda #0
	rts

write_error:
	FAT32_CONTEXT_END
	lda #$26 ; XXX write protect on
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
remove_directory:
	jsr check_medium
	FAT32_CONTEXT_START
	jsr create_fat32_path
	jsr fat32_rmdir
	bcs :+
	jmp write_error
:	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
change_directory:
	jsr check_medium
	FAT32_CONTEXT_START
	jsr create_fat32_path
	jsr fat32_chdir
	bcs :+
	jmp write_error
:	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  partition
;---------------------------------------------------------------
change_partition:
	jsr check_medium_a
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  vector number
;---------------------------------------------------------------
user:
.ifdef DEBUG
	pha
	debug_print "U"
	pla
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1   old medium/path/name
;       medium1/r2/r3  new medium/path/name
;---------------------------------------------------------------
rename:
	FAT32_CONTEXT_START
	jsr create_fat32_path_x2
	jsr fat32_rename
	bcs :+
	jmp write_error
:	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium  medium
;       r0      path
;               empty:     rename filesystem
;               not empty: rename subdirectory "header"
;       r1      new name
;---------------------------------------------------------------
rename_header:
.ifdef DEBUG
	debug_print "R-H"
	jsr print_medium
	jsr print_r0
	jsr print_r1
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   r0  new name
;       r1  old name
;---------------------------------------------------------------
rename_partition:
.ifdef DEBUG
	debug_print "R-P"
	jsr print_r1
	jsr print_r0
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  unit number
;---------------------------------------------------------------
change_unit:
.ifdef DEBUG
	pha
	debug_print "S-*"
	pla
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   a              =0:  create
;                      !=0: append
;       medium/r0/r1   source
;       medium1/r2/r3  destination
;---------------------------------------------------------------
copy:
.ifdef DEBUG
	pha
	lda #13
	jsr bsout
	debug_print "C"
	pla
	jsr print_a
	jsr print_medium1
	jsr print_r2
	jsr print_r3
	jsr print_medium
	jsr print_r0
	jsr print_r1
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   x   destination medium
;       y   source medium
;---------------------------------------------------------------
copy_all:
.ifdef DEBUG
	phx
	debug_print "COPY ALL"
	plx
	txa
	jsr print_a
	tya
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   x   destination medium
;       y   source medium
;---------------------------------------------------------------
duplicate:
.ifdef DEBUG
	phx
	debug_print "D"
	plx
	txa
	jsr print_a
	tya
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_lock:
.ifdef DEBUG
	debug_print "F-L"
	jsr print_medium
	jsr print_r0
	jsr print_r1
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_unlock:
.ifdef DEBUG
	debug_print "F-U"
	jsr print_medium
	jsr print_r0
	jsr print_r1
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_restore:
.ifdef DEBUG
	debug_print "F-R"
	jsr print_medium
	jsr print_r0
	jsr print_r1
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  sector interleave
;---------------------------------------------------------------
set_sector_interleave:
.ifdef DEBUG
	pha
	debug_print "U0>S"
	pla
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  retries
;---------------------------------------------------------------
set_retries:
.ifdef DEBUG
	pha
	debug_print "U0>R"
	pla
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   -
;---------------------------------------------------------------
test_rom_checksum:
.ifdef DEBUG
	debug_print "U0>T"
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  fast serial (0/1)
;---------------------------------------------------------------
set_fast_serial:
.ifdef DEBUG
	pha
	debug_print "U0>B"
	pla
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  verify (0/1)
;---------------------------------------------------------------
set_verify:
.ifdef DEBUG
	pha
	debug_print "U0>V"
	pla
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  directory interleave
;---------------------------------------------------------------
set_directory_interleave:
.ifdef DEBUG
	pha
	debug_print "U0>D"
	pla
	jsr print_a
.endif
	lda #0
	rts

;---------------------------------------------------------------
; In:   a  large REL support (0/1)
;---------------------------------------------------------------
set_large_rel_support:
.ifdef DEBUG
	pha
	debug_print "U0>L"
	pla
	jsr print_a
.endif
	lda #0
	rts

