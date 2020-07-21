;----------------------------------------------------------------------
; CBDOS Functions
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "functions.inc"

; fat32.s
.import fat32_ptr, fat32_ptr2, fat32_size
.import fat32_alloc_context, fat32_free_context, fat32_set_context
.import fat32_mkdir, fat32_rmdir, fat32_chdir, fat32_rename, fat32_delete
.import fat32_open, fat32_close, fat32_read, fat32_write, fat32_create

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

.bss

context_src:
	.byte 0
context_dst:
	.byte 0

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
; change_unit
;
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
; copy
;
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
	jsr create_fat32_path_x2
	lda fat32_ptr2
	pha
	lda fat32_ptr2 + 1
	pha

	jsr fat32_alloc_context
	sta context_dst
	jsr fat32_alloc_context
	sta context_src

	; open source
	jsr fat32_set_context
	jsr fat32_open

	; create destination
	lda context_dst
	jsr fat32_set_context

	pla
	sta fat32_ptr + 1
	pla
	sta fat32_ptr
	jsr fat32_create

@loop:
	lda context_src
	jsr fat32_set_context

	lda #<unix_path
	sta fat32_ptr
	lda #>unix_path
	sta fat32_ptr + 1
	stz fat32_size
	lda #1
	sta fat32_size + 1
	jsr fat32_read

	lda fat32_size
	ora fat32_size + 1
	beq @done

	lda context_dst
	jsr fat32_set_context

	lda #<unix_path
	sta fat32_ptr
	lda #>unix_path
	sta fat32_ptr + 1
	jsr fat32_write

	bra @loop

@done:
	lda context_src
	jsr fat32_set_context
	jsr fat32_close

	lda context_dst
	jsr fat32_set_context
	jsr fat32_close

	lda #0
	rts

;---------------------------------------------------------------
; copy_all
;
; In:   x   destination medium
;       y   source medium
;---------------------------------------------------------------
copy_all:
	; This is the "C" command, with two media numbers as
	; arguments, which should perform a file copy of all
	; files between from one media to another. It is not
	; supported by CMD drives (partitions).

	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; duplicate
;
; In:   x   destination medium
;       y   source medium
;---------------------------------------------------------------
duplicate:
	; This is the "D" command, which should perform a
	; block-by-block copy from one drive to another.
	; It is only supported on Commodore multi-drive units,
	; but not by CMD devices, since it makes little sense
	; on devices with differently sized partitions.
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; file_lock
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_lock:
	; TODO: set read-only flag
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; file_unlock
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_unlock:
	; TODO: clear read-only flag
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; file_restore
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_restore:
	; TODO:
	; This is the "F-R" command, as added to the C65 drive,
	; which should perform an undelete.
	; FAT32 keeps the directory entry and the FAT links,
	; but overwrites the first character. The user provides
	; the full filename to this function though.
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; set_sector_interleave

; In:   a  sector interleave
;---------------------------------------------------------------
set_sector_interleave:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_retries
;
; In:   a  retries
;---------------------------------------------------------------
set_retries:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; test_rom_checksum
;
; In:   -
;---------------------------------------------------------------
test_rom_checksum:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_fast_serial
;
; In:   a  fast serial (0/1)
;---------------------------------------------------------------
set_fast_serial:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_verify
;
; In:   a  verify (0/1)
;---------------------------------------------------------------
set_verify:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_directory_interleave
;
; In:   a  directory interleave
;---------------------------------------------------------------
set_directory_interleave:
	; do nothing
	lda #0
	rts

;---------------------------------------------------------------
; set_large_rel_support
;
; In:   a  large REL support (0/1)
;---------------------------------------------------------------
set_large_rel_support:
	lda #$31 ; unsupported
	rts

