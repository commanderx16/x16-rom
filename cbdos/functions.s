;----------------------------------------------------------------------
; CBDOS Functions
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "functions.inc"
.include "fat32/fat32.inc"
.include "fat32/regs.inc"

; main.s
.import cbdos_init

; parser.s
.import medium, medium1, unix_path, unix_path2, create_unix_path, create_unix_path_b
.import r0s, r0e, r1s, r1e, r2s, r2e, r3s, r3e

; main.s
.export soft_check_medium_a
.import convert_errno_status

.export create_fat32_path_only_dir, create_fat32_path_only_name

.import buffer

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

tmp0:
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

;---------------------------------------------------------------
create_fat32_path_only_dir:
	; pass in just the path, not the name
	ldx r0e
	cpx r0s
	beq @no_path
	stz buffer,x
	lda r0s
	clc
	adc #<buffer
	sta fat32_ptr + 0
	lda #>buffer
	adc #0
	sta fat32_ptr + 1
	bra @nempty

@no_path:
	; current directory
	stz fat32_ptr
	stz fat32_ptr + 1

@nempty:
	rts

;---------------------------------------------------------------
create_fat32_path_only_name:
	; pass in just the name, not the path
	ldx r1e
	cpx r1s
	beq @no_name
	stz buffer,x
	lda r1s
	clc
	adc #<buffer
	sta fat32_ptr + 0
	lda #>buffer
	adc #0
	sta fat32_ptr + 1
	bra @read_cont

@no_name:
	stz fat32_ptr
	stz fat32_ptr + 1

@read_cont:
	rts


;---------------------------------------------------------------
check_medium:
	lda medium
	jsr soft_check_medium_a
	bcc :+
	pla
	pla
	lda #$74
:	rts

;---------------------------------------------------------------
; soft_check_medium_a
;
; Checks whether a medium is valid, i.e. whether a partition
; exists.
;
; In:   a   medium
; Out:  c   =0: medium valid (partition exists)
;           =1: medium invalid (partition does not exist)
;---------------------------------------------------------------
soft_check_medium_a:
	; Since partitions are not currently supported,
	; only partitions 0 (current) and 1 (single partition)
	; are supported
	cmp #2
	rts

;---------------------------------------------------------------
; for all these implementations:
;
; Out:  a  status
;       c  (unused)
;---------------------------------------------------------------

;---------------------------------------------------------------
; initialize
;
; This is the "I" command, which is a hint that the physical
; media was changed, and the new media should be mounted.
;
; In:   medium  medium
;---------------------------------------------------------------
initialize:
	jsr check_medium
	; TODO
	lda #0
	rts

;---------------------------------------------------------------
; validate
;
; This is the "V" command, which should do a filesystem check
; and repair.
;
; In:   medium  medium
;---------------------------------------------------------------
validate:
	jsr check_medium

	; TODO
	lda #$31
	rts

;---------------------------------------------------------------
; new
;
; This is the "N" command, which should initialize a filesystem.
; FAT32 filesystems are large, so formatting is a rarely used
; and very dangerous function. Therefore, the standard syntax
; (NAME or NAME,ID) should not initialize the filesystem just
; yet. Here are a few ideas:
; * There has to be a format argument: "NAME,ID,FORMAT" - the
;   function is only actually performed if the format is 'Y'.
;   (as in "Yes, I'm sure.") Otherwise, an informational status
;   message (code $0x) explains what's going on.
; * The "N" command has to be sent twice. The first time, an
;   informational status message explains what's going on.
;
; In:   medium  medium
;       r0      name
;       r1      id
;       a       format (1st char)
;---------------------------------------------------------------
new:
	jsr check_medium

	; TODO
	lda #$31
	rts

;---------------------------------------------------------------
; scratch
;
; In:   medium/r0/r1  medium/path/name
; Out:  x             number of files scratched
;---------------------------------------------------------------
scratch:
@scratch_counter  = tmp0
	jsr check_medium

	stz @scratch_counter

	FAT32_CONTEXT_START
	jsr create_fat32_path
@loop:
	; TODO:
	; If there are wildcards in the name, and the first match
	; is a directory, this call will fail, and deleting
	; will end here. fat32_delete needs an option to skip
	; directories. Or maybe we should enumerate the directory
	; and call fat32_delete on specific filenames.
	jsr fat32_delete
	bcc :+
	inc @scratch_counter
	bra @loop

:	lda fat32_errno
	cmp #ERRNO_FILE_NOT_FOUND ; no more files
	beq @end
	cmp #ERRNO_WRITE_PROTECT_ON ; no more files
	; XXX locked files should be skipped, but because of the
	; issue described above, "beq @loop" would cause an infinite
	; loop
	beq @end

	FAT32_CONTEXT_END
	jsr convert_errno_status
	ldx @scratch_counter
	rts

@end:
	FAT32_CONTEXT_END
	ldx @scratch_counter
	lda #0
	rts

;---------------------------------------------------------------
; make_directory
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
make_directory:
	jsr check_medium

	FAT32_CONTEXT_START
	jsr create_fat32_path
	jsr fat32_mkdir
	bcc convert_status_end_context
	FAT32_CONTEXT_END
	lda #0
	rts

convert_status_end_context:
	FAT32_CONTEXT_END
	jmp convert_errno_status

;---------------------------------------------------------------
;
; remove_directory
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
remove_directory:
	jsr check_medium

	FAT32_CONTEXT_START
	jsr create_fat32_path
	jsr fat32_rmdir
	bcc convert_status_end_context
	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; change_directory
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
change_directory:
	jsr check_medium

	FAT32_CONTEXT_START
	jsr create_fat32_path

	lda unix_path
	cmp #'_'
	bne @regular_cd
	lda unix_path + 1
	bne @regular_cd

	; "cd .."
	lda #'.'
	sta unix_path
	sta unix_path + 1
	stz unix_path + 2

@regular_cd:
	jsr fat32_chdir
	bcc convert_status_end_context
	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; change_partition
;
; In:   a  partition
;---------------------------------------------------------------
change_partition:
	jsr soft_check_medium_a
	bcs @ill_part
	cmp #0
	beq @ill_part
	tax
	lda #$02
	rts

@ill_part:
	tax
	lda #$77
	rts

;---------------------------------------------------------------
; user
;
; In:   a  vector number
;---------------------------------------------------------------
user:
	cmp #0
	beq @user_0
	cmp #1
	beq @user_1
	cmp #2
	beq @user_2
	cmp #9
	beq @user_9
	cmp #10
	beq @user_10

	; U3-U8; execute code
	lda #$31
	rts

; U0 - init user vectors
@user_0:
	lda #0
	rts

; U1/UA - read block
@user_1:
	; TODO
	lda #$31
	rts

; U2/UB - write block
@user_2:
	; TODO
	lda #$31
	rts

; U9/UI - warm RESET
@user_9:
	lda #$73
	rts

; U:/UJ - cold RESET
@user_10:
	jsr cbdos_init
	lda #$73
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
	jmp convert_status_end_context
:	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; rename_header
;
; This is the "R-H" command, which should set the name of
;   * the filesystem (i.e. FAT volume name), if no path
;     is given.
;   * the "header" of a subdirectory, if a path is given.
;     FAT doesn't have any such concept, so this part must
;     remain unsupported.
;
; In:   medium  medium
;       r0      path
;               empty:     rename filesystem
;               not empty: rename subdirectory "header"
;       r1      new name
;---------------------------------------------------------------
rename_header:
	jsr check_medium

	lda r0s
	cmp r0e
	bne @rename_subdir_header

; TODO: set volume name
	lda #$31 ; unsupported
	rts

@rename_subdir_header:
	lda #$31 ; unsupported; FAT can't do this
	rts

;---------------------------------------------------------------
; rename_partition
;
; This is the "R-P" command, which should change the name of
; a partition as stored in the partition table.
; MBR partition tables don't support names, so this is
; unsupported.
;
; In:   r0  new name
;       r1  old name
;---------------------------------------------------------------
rename_partition:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; change_unit
;
; In:   a  unit number
;---------------------------------------------------------------
change_unit:
	; TODO
	lda #$31
	rts

;---------------------------------------------------------------
; copy_start
;
; Open destination file for writing.
;
; TODO:
; * create mode: fail if file exists
;
; In:   medium/r0/r1   destination
;---------------------------------------------------------------
copy_start:
	jsr check_medium

	jsr fat32_alloc_context
	bcc @error_70
	sta context_dst
	jsr fat32_set_context

	jsr create_fat32_path
	jsr fat32_create
	bcc @error_errno

	lda #0
	rts

@error_70:
	lda #$70
	rts

@error_errno:
	jmp convert_errno_status

;---------------------------------------------------------------
copy_do:
@context_src = tmp0
	jsr check_medium

	jsr fat32_alloc_context
	bcc @error_70
	sta @context_src
	jsr fat32_set_context
	bcc @error_errno

	jsr create_fat32_path
	jsr fat32_open
	bcc @error_errno

@cloop:
	; read
	lda @context_src
	jsr fat32_set_context
	bcc @error_errno
	lda #<unix_path
	sta fat32_ptr
	lda #>unix_path
	sta fat32_ptr + 1
	stz fat32_size
	lda #1
	sta fat32_size + 1
	jsr fat32_read
	bcs :+
	lda fat32_errno
	bne @error_errno

:	lda fat32_size
	ora fat32_size + 1
	beq @done

	; write
	lda context_dst
	jsr fat32_set_context
	bcc @error_errno
	lda #<unix_path
	sta fat32_ptr
	lda #>unix_path
	sta fat32_ptr + 1
	jsr fat32_write
	bcc @error_errno

	bra @cloop

@done:
	; close source
	lda @context_src
	jsr fat32_set_context
	bcc @error_errno
	jsr fat32_close
	bcc @error_errno
	lda @context_src
	jsr fat32_free_context

	lda #0
	rts

@error_70:
	lda #$70
	rts

@error_errno:
	jsr convert_errno_status
	pha
	lda @context_src
	jsr fat32_set_context
	jsr fat32_close
	lda @context_src
	jsr fat32_free_context
	pla
	rts

;---------------------------------------------------------------
copy_end:
	lda context_dst
	jsr fat32_set_context
	bcs @1

	jsr convert_errno_status
	pha
	jsr fat32_close
	lda context_dst
	jsr fat32_free_context
	pla
	rts

@1:	jsr fat32_close
	php
	lda context_dst
	jsr fat32_free_context
	plp
	bcs @2

	jmp convert_errno_status

@2:	lda #0
	rts

;---------------------------------------------------------------
; copy_all
;
; This is the variant of the "C" command with two media numbers
; as arguments, which should perform a file copy of all files
; between from one media to another. It is only supported on
; Commodore multi-drive units, not by CMD devices, so this
; implementation doesn't support it either.
;
; In:   x   destination medium
;       y   source medium
;---------------------------------------------------------------
copy_all:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; duplicate
;
; This is the "D" command, which should perform a block-by-block
; copy from one drive to another.It is only supported on
; Commodore multi-drive units, not by CMD devices, since it
; makes little sense on devices with differently sized
; partitions, so this implementation doesn't support it either.
;
; In:   x   destination medium
;       y   source medium
;---------------------------------------------------------------
duplicate:
	lda #$31 ; unsupported
	rts

;---------------------------------------------------------------
; file_lock
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_lock:
	lda #1
file_lock_unlock:
	sta tmp0
	jsr check_medium
	FAT32_CONTEXT_START
	jsr create_fat32_path
	lda tmp0
	jsr fat32_set_attribute
	bcs :+
	jmp convert_status_end_context
:	FAT32_CONTEXT_END
	lda #0
	rts

;---------------------------------------------------------------
; file_unlock
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_unlock:
	lda #0
	bra file_lock_unlock

;---------------------------------------------------------------
; file_lock_toggle
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_lock_toggle:
	jsr check_medium

	FAT32_CONTEXT_START
	jsr create_fat32_path_only_dir
	jsr fat32_open_dir
	bcc @error_errno

	jsr create_fat32_path_only_name
	jsr fat32_read_dirent_filtered
	php
	jsr fat32_close ; can't fail
	plp
	bcs :+
	lda fat32_errno
	bne @error_errno
	bra @error_file_not_found
:
	jsr create_fat32_path
	lda fat32_dirent + dirent::attributes
	eor #1
	jsr fat32_set_attribute
	bcs :+
	jmp convert_status_end_context

:	FAT32_CONTEXT_END
	lda #0
	rts

@error_file_not_found:
	FAT32_CONTEXT_END
	lda #$62 ; file not found
	rts

@error_errno:
	jmp convert_status_end_context

;---------------------------------------------------------------
; file_restore
;
; This is the "F-R" command, which should perform an undelete.
; It is only supported by the C65 drive.
;
; In:   medium/r0/r1  medium/path/name
;---------------------------------------------------------------
file_restore:
	jsr check_medium

	; TODO:
	; FAT32 keeps the directory entry and the FAT links,
	; but overwrites the first character. The user provides
	; the full filename to this function though.
	lda #$31
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
; This is the "U0>L" command, which enables/disables support for
; "large" REL files. It is only supported by the C65 drive, and
; unsupported in this implementation.
;
; In:   a  large REL support (0/1)
;---------------------------------------------------------------
set_large_rel_support:
	lda #$31 ; unsupported
	rts

