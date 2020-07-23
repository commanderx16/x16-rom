;----------------------------------------------------------------------
; CBDOS Parser
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.setcpu "65c02"

.include "functions.inc"

.export execute_command
.export parse_cbmdos_filename
.import buffer, buffer_len, buffer_overflow
.import set_status

; functions.s
.export medium, medium1, unix_path, create_unix_path, create_unix_path_b
.export r0s, r0e, r1s, r1e, r2s, r2e, r3s, r3e, file_mode

; main.s
.export overwrite_flag
.export find_wildcards

.code

execute_command:
	ldx #0
	ldy buffer_len
	beq @rts ; empty

	jsr parse_command
	bcc @1
	lda #$30 ; generic syntax error
	jmp set_status

@1:	cmp #$ff ; command has already put data into the status buffer
	beq @rts
	jmp set_status

@rts:	rts

.bss

overwrite_flag:
	.byte 0
medium:
	.byte 0
medium1:
	.byte 0
file_type:
	.byte 0
file_mode:
	.byte 0

.if 1
unix_path:
	.res 256, 0
r0s:	.byte 0
r0e:	.byte 0
r1s:	.byte 0
r1e:	.byte 0
r2s:	.byte 0
r2e:	.byte 0
r3s:	.byte 0
r3e:	.byte 0
.else
unix_path = $0200

r0s = 2
r0e = 3
r1s = 4
r1e = 5
r2s = 6
r2e = 7
r3s = 8
r3e = 9
.endif

; temp variables, must only be used in leaf functions
tmp0:	.byte 0
tmp1:	.byte 0
tmp2:	.byte 0

; temp variable, must only be used by command implementation
ctmp0:	.byte 0
ctmp1:	.byte 0


.code

;***************************************************************
; PARSING
;***************************************************************

;---------------------------------------------------------------
; search_char
;
; In:   a     character
;       x->y  input buffer
; Out:  c     =0: character found
;                 x  index of character
;             =1: character not found
;                 x  input buffer end + 1
;       y     (unchanged)
;---------------------------------------------------------------
search_char:
@tmp_end = tmp0
	sty @tmp_end
@loop:
	cpx @tmp_end
	beq @not_found
	cmp buffer,x
	beq @found
	inx
	bra @loop
@not_found:
	sec
	rts
@found:
	clc
	rts

;---------------------------------------------------------------
; get_number
;
; In:   r0  input buffer
; Out:  x   index of first non-numeric character or end
;       c   =1: overflow
;---------------------------------------------------------------
get_number:
@tmp_end = tmp0
@tmp_number = tmp1
@tmp_number_overflow = tmp2
	ldx r0s
	ldy r0e
	sty @tmp_end
	stz @tmp_number
	stz @tmp_number_overflow
@loop:
	cpx @tmp_end
	beq @end

	lda buffer,x
	sec
	sbc #'0'
	bcc @end
	cmp #10
	bcs @end
	pha

	; multiply existing number by 10
	asl @tmp_number
	bcc :+
	rol @tmp_number_overflow
:	lda @tmp_number
	asl @tmp_number
	bcc :+
	rol @tmp_number_overflow
:	asl @tmp_number
	bcc :+
	rol @tmp_number_overflow
:	clc
	adc @tmp_number
	bcc :+
	rol @tmp_number_overflow
:	sta @tmp_number

	; add new digit
	pla
	adc @tmp_number
	bcc :+
	rol @tmp_number_overflow
:	sta @tmp_number

	inx
	bra @loop

@end:
	lda @tmp_number
	ror @tmp_number_overflow
	rts

;---------------------------------------------------------------
; get_src_dst_numbers
;
; Get two numbers in the format
;  12=23
;
; In:   r0  input buffer
; Out:  x   first number  (dst)
;       y   second number (src)
;       c   =1: overflow
;       r0  (unchanged)
;---------------------------------------------------------------
get_src_dst_numbers:
	jsr get_number
	bcs @error
	tay
	lda buffer,x
	cmp #'='
	bne @error
	phy ; target medium
	inx
	stx r0s
	jsr get_number
	bcs @error2
	tay
	plx
	rts

@error2:
	pla
@error:	sec
	rts

;---------------------------------------------------------------
; copy_chars
;
; In:   x/a   source
;       y     target start
; Out:  x     source end + 1
; Out:  y     target end + 1
;---------------------------------------------------------------
copy_chars:
	sta tmp0
@loop:	cpx tmp0
	beq @1
	lda buffer,x
	sta unix_path,y
	inx
	iny
	bra @loop
@1:	rts

;---------------------------------------------------------------
; split
;
; Split buffer into two parts using delimiter
;
; In:   a    delimiter
;       r0   input buffer
;       c    =1: if not found, r0 will be full range, r1 empty
;            =0: if not found, r1 will be full range, r0 empty
;
; Out:  r0   characters before delimiter
;       r1   characters after delimiter
;       c     =0: delimiter found
;             =1: delimiter not found
;---------------------------------------------------------------
split:
	ldx r0s
	ldy r0e
	bcs @1

	; default: no range 0, all range 1
	stx r0s
	stx r0e
	stx r1s
	sty r1e
	bra @2

@1:	; default: all range 0, no range 1
	stx r0s
	sty r0e
	sty r1s
	sty r1e
@2:
	jsr search_char
	bcs @end ; delimiter not found

	; path is specified
	stx r0e
	inx
	stx r1s

@end:	rts


;---------------------------------------------------------------
; consume_cmd
;
; Consume all characters until numeric or '/'.
;
; In:   r0  buffer
; Out:  r0  buffer
;---------------------------------------------------------------
consume_cmd:
	ldx r0s
	cpx r0e
	beq @end
	lda buffer,x
	cmp #'/'
	beq @end
	cmp #':'
	beq @end
	cmp #'0'
	bcc @next
	cmp #'9'+1
	bcc @end
@next:	inc r0s
	bra consume_cmd
@end:	rts

;---------------------------------------------------------------
; consume_get_path_and_name
;
; Consume remainder of cmd, extract medium, path and filename
;
; In:   r0   input buffer
;
; Out:  medium  medium
;       r0      path
;       r1      name
;       c       =1: syntax error
;---------------------------------------------------------------
consume_get_path_and_name:
	jsr consume_cmd

;---------------------------------------------------------------
; get_path_and_name
;
; Extract medium, path and filename
;
; In:   r0   input buffer
;
; Out:  medium  medium
;       r0      path
;       r1      name
;       c       =1: syntax error
;---------------------------------------------------------------
get_path_and_name:
	lda #':'
	clc
	jsr split
	jmp parse_path

;---------------------------------------------------------------
; consume_get_path_and_name_remove_options
;
; Consume remainder of cmd, extract medium, path and filename,
; remove options (',[...]') from filename.
;
; In:   r0   input buffer
;
; Out:  medium  medium
;       r0      path
;       r1      name
;       c       =1: syntax error
;---------------------------------------------------------------
consume_get_path_and_name_remove_options:
	jsr consume_get_path_and_name
	bcs @error
	jsr remove_options_r1
	clc
	rts
@error:	sec
	rts

;---------------------------------------------------------------
; remove_options_r0
;
; Remove ",[...]" from r0
;
; In:   r0   buffer
; Out:  r0   buffer
;---------------------------------------------------------------
remove_options_r0:
	ldx r0s
	ldy r0e
	lda #','
	jsr search_char
	stx r0e
	rts

;---------------------------------------------------------------
; remove_options_r1
;
; Remove ",[...]" from r1
;
; In:   r1   buffer
; Out:  r1   buffer
;---------------------------------------------------------------
remove_options_r1:
	ldx r1s
	ldy r1e
	lda #','
	jsr search_char
	stx r1e
	rts

;---------------------------------------------------------------
; parse_path
;
; Converts a full CBMDOS path/name like
;   "123//DIR1/DIR2/:FILE.TXT,OPT"
; into a medium
;   #123
; a path
;   "/DIR1/DIR2/"
; and a filename
;   "FILE.TXT,OPT"
; * type/options (",[...]") are not removed.
; * medium > 255 causes a syntax error.
; * Illegal path syntax causes an empty path and medium 0.
;
; In:   r0      CBMDOS path/name
;
; Out:  medium
;       r0      path
;       r1      name
;       c       =1: syntax error
;---------------------------------------------------------------
parse_path:
	; get medium
	jsr get_number
	bcs @error ; behavior matches CMD drives
	sta medium

	; x now points to the path
	stx r0s

	; is the path empty?
	cpx r0e
	beq @done

@nempty_path:
	; path not empty
	; path must start with '/'
	lda #'/'
	cmp buffer,x
	bne @no_path
	inc r0s ; skip leading '/'
	inx
	cpx r0e
	beq @no_path ; catch single '/'
	; path must end with '/'
	ldy r0e
	dey
	cmp buffer,y
	beq @done

@no_path:
	; path syntax error -> empty path, medium 0
	stz medium
	stz r0s
	stz r0e

@done:
	clc
	rts

@error:
	sec
	rts

;---------------------------------------------------------------
; create_unix_path
;
; Concatenates CBMDOS path and CBMDOS name to a zero-terminated
; UNIX path.
;
; In:   r0         CBMDOS path
;       r1         CBMDOS name
;       y          offset in unix_path
;
; Out:  unix_path  UNIX path
;       y          points to after terminating zero
;---------------------------------------------------------------
create_unix_path:
	ldx r0s
	lda r0e
	jsr copy_chars
	ldx r1s
	lda r1e
	jsr copy_chars
	lda #0
	sta unix_path,y
	iny
	rts
create_unix_path_b:
	ldx r2s
	lda r2e
	jsr copy_chars
	ldx r3s
	lda r3e
	jsr copy_chars
	lda #0
	sta unix_path,y
	iny
	rts

;---------------------------------------------------------------
; find_wildcards
;
; Checks whether there are any wildcards in the filename.
;
; In:   r1         CBMDOS name
;
; Out:
;---------------------------------------------------------------
find_wildcards:
	ldx r1s
@loop:
	cpx r1e
	beq @not_found
	lda buffer,x
	cmp #'*'
	beq @found
	cmp #'?'
	beq @found
	inx
	bra @loop

@found:
	sec
	rts

@not_found:
	clc
	rts

;***************************************************************
; FILE NAMES
;***************************************************************

;---------------------------------------------------------------
; parse_cbmdos_filename
;
; Converts a CBMDOS filename into medium, UNIX file path, file
; type, file mode
;
; In:   x->y       input buffer
; Out:  medium     medium (0-255; defaults to 0)
;       r0         CBMDOS path
;       r1         CBMDOS file
;       file_type  file type (defaults to 'S')
;       file_mode  file mode (defaults to 'R')
;       c          =1: syntax error
;---------------------------------------------------------------
parse_cbmdos_filename:
	stx r0s
	sty r0e

	; defaults
	stz overwrite_flag
	lda #'S'
	sta file_type
	lda #'R'
	sta file_mode

	lda #':'
	clc
	jsr split

	ldx r0s
	cpx r0e
	beq @no_overwrite

	; check for overwrite flag '@'
	lda buffer,x
	cmp #'@'
	bne @no_overwrite

	inc r0s
	inc overwrite_flag

@no_overwrite:
	jsr parse_path
	bcs @syntax_error

	; extract options from name
	ldx r1s
	ldy r1e
	lda #','
	jsr search_char
	bcs @no_comma

	phx ; end of filename

	inx ; skip over comma
	cpx r1e
	beq @comma_done
	lda buffer,x
	cmp #','
	beq :+
	sta file_type
:
	ldy r1e
	lda #','
	jsr search_char
	bcs @comma_done
	inx ; skip over comma
	cpx r1e
	beq @comma_done
	lda buffer,x
	cmp #','
	beq :+
	sta file_mode
:

@comma_done:
	plx
	stx r1e

@no_comma:
	clc
	rts

@syntax_error:
	sec
	rts

;***************************************************************
; DISPATCHING
;***************************************************************

;---------------------------------------------------------------
; parse_command
;
;
;---------------------------------------------------------------
parse_command:
	stx r0s
	sty r0e
	; zero terminate, so we don't have to worry
	; about overrunning the buffer when comparing
	lda #0
	sta buffer,y

	lda buffer,x
	ldx #cmds_end - cmds - 1
@loop:	cmp cmds,x
	beq @found
	dex
	bpl @loop

	lda #$31 ; syntax error: unknown command
	clc
	rts

@found:
	txa
	asl
	tax
	jmp (cmd_ptrs,x)

;---------------------------------------------------------------
; R* dispatcher
;---------------------------------------------------------------
cmd_r:
	nop
	ldx r0s
	inx
	lda buffer,x
	cmp #'D'
	bne :+
	jmp cmd_rd
:	cmp #'-'
	beq @minus
	jmp cmd_rename
@minus:
	inx
	lda buffer,x
	cmp #'H'
	bne :+
	jmp cmd_rh
:	cmp #'P'
	bne :+
	jmp cmd_rp
:	lda #$31 ; syntax error: unknown command
	clc
	rts

;---------------------------------------------------------------
; S* dispatcher
;---------------------------------------------------------------
cmd_s:
	ldx r0s
	inx
	lda buffer,x
	cmp #'-'
	beq @minus
	jmp cmd_scratch
@minus:
	inx
	lda buffer,x
	cmp #'8'
	bne :+
	jmp cmd_s8
:	cmp #'9'
	bne :+
	jmp cmd_s9
:	cmp #'D'
	bne :+
	jmp cmd_sd
:	lda #$31 ; syntax error: unknown command
	clc
	rts

;---------------------------------------------------------------
; C* dispatcher
;---------------------------------------------------------------
cmd_c:
	ldx r0s
	inx
	lda buffer,x
	cmp #'P'
	bne :+
	jmp cmd_cp_decimal
:	cmp #$d0 ; (shifted 'P')
	bne :+
	jmp cmd_cp_binary
:	cmp #'D'
	bne :+
	jmp cmd_cd
:	jmp cmd_copy

;---------------------------------------------------------------
; G* dispatcher
;---------------------------------------------------------------
cmd_g:
	ldx r0s
	inx
	lda buffer,x
	cmp #'-'
	beq @minus
	lda #$31 ; syntax error: unknown command
	clc
	rts
@minus:
	inx
	lda buffer,x
	cmp #'P'
	bne :+
	jmp cmd_gp
:	lda buffer,x
	cmp #'D'
	bne :+
	jmp cmd_gd
:	lda #$31 ; syntax error: unknown command
	clc
	rts

;---------------------------------------------------------------
; M* dispatcher
;---------------------------------------------------------------
cmd_m:
	ldx r0s
	inx
	lda buffer,x
	cmp #'D'
	bne :+
	jmp cmd_md
:	cmp #'-'
	beq @minus
	lda #$31 ; syntax error: unknown command
	clc
	rts
@minus:
	inx
	lda buffer,x
	cmp #'R'
	bne :+
	jmp cmd_mr
:	cmp #'W'
	bne :+
	jmp cmd_mw
:	cmp #'E'
	bne :+
	jmp cmd_me
:	lda #$31 ; syntax error: unknown command
	clc
	rts

;---------------------------------------------------------------
; F* dispatcher
;---------------------------------------------------------------
cmd_f:
	ldx r0s
	inx
	lda buffer,x
	cmp #'-'
	beq @minus
	lda #$31 ; syntax error: unknown command
	clc
	rts
@minus:
	inx
	lda buffer,x
	cmp #'L'
	bne :+
	jmp cmd_fl
:	cmp #'U'
	bne :+
	jmp cmd_fu
:	cmp #'R'
	bne :+
	jmp cmd_fr
:	lda #$31 ; syntax error: unknown command
	clc
	rts

;---------------------------------------------------------------
; U0>* dispatcher
;---------------------------------------------------------------
cmd_u0ext:
	lda buffer+3,x

	cmp #8
	bcc :+
	cmp #16
	bcs :+
	; change unit address
	jsr change_unit
	clc
	rts

:	ldx #u0ext_cmds_end - u0ext_cmds - 1
@loop:	cmp u0ext_cmds,x
	beq @found
	dex
	bpl @loop

	lda #$31 ; syntax error: unknown command
	clc
	rts

@found:
	txa
	asl
	tax
	jmp (u0ext_cmd_ptrs,x)

;---------------------------------------------------------------
; U0>M* dispatcher
;---------------------------------------------------------------
cmd_u0_m:
	ldx r0s
	lda buffer+4,x
	cmp #'R'
	bne :+
	jmp cmd_u0_mr
:	cmp #'W'
	bne :+
	jmp cmd_u0_mw
:	lda #$31 ; syntax error: unknown command
	clc
	rts

;---------------------------------------------------------------
cmds:
	.byte 'I' ; initialize
	.byte 'V' ; validate
	.byte 'N' ; new
	.byte 'R' ; rename
	          ; 'RD'  remove directory
	          ; 'R-H' rename header
	          ; 'R-P' rename partition
	.byte 'S' ; scratch
	          ; 'S-*' swap
	.byte 'C' ; copy
	          ; 'CP'  change partition
	          ; 'CD'  change directory
	.byte 'D' ; duplicate
	.byte 'L' ; toggle lock
	.byte 'G' ; 'GP'  get partition
	          ; 'G-D' get disk change
	.byte 'M' ; 'MD'  make directory
	          ; 'M-R' memory read      [unsupported]
	          ; 'M-W' memory write     [unsupported]
	          ; 'M-E' memory execute   [unsupported]
;	.byte 'B' ; 'B-P' buffer pointer   [unsupported]
	          ; 'B-A' block allocate   [unsupported]
	          ; 'B-F' block free       [unsupported]
	          ; 'B-S' block status     [unsupported]
	          ; 'B-R' block read       [unsupported]
	          ; 'B-W' block write      [unsupported]
	          ; 'B-E' block execute    [unsupported]
	.byte 'U' ; 'Ux'  user
	.byte 'F' ; 'F-L' file lock
	          ; 'F-U' file unlock
	          ; 'F-R' file restore     [unsupported]
cmds_end:
cmd_ptrs:
	.word cmd_i
	.word cmd_v
	.word cmd_n
	.word cmd_r
	.word cmd_s
	.word cmd_c
	.word cmd_d
	.word cmd_l
	.word cmd_g
	.word cmd_m
;	.word cmd_b
	.word cmd_u
	.word cmd_f

;---------------------------------------------------------------
u0ext_cmds:
	.byte 'S' ; set sector interleave
	.byte 'R' ; set retries
	.byte 'T' ; test ROM checksum
	.byte 'B' ; enable/disable fast serial
	.byte 'V' ; enable/disable verify
	.byte 'D' ; set directory sector interleave
	.byte 'L' ; enable/disable large REL file support
	.byte 'M' ; 'MR' burst memory read
	          ; 'MW' burst memory write
u0ext_cmds_end:
u0ext_cmd_ptrs:
	.word cmd_u0_s
	.word cmd_u0_r
	.word cmd_u0_t
	.word cmd_u0_b
	.word cmd_u0_v
	.word cmd_u0_d
	.word cmd_u0_l
	.word cmd_u0_m

;***************************************************************
; COMMANDS
;***************************************************************

;---------------------------------------------------------------
; I - initialize
;---------------------------------------------------------------
cmd_i:
	jsr consume_cmd
	jsr get_number
	bcs @error
	sta medium
	jsr initialize
	clc
	rts
@error:	sec
	rts

;---------------------------------------------------------------
; V - validate
;---------------------------------------------------------------
cmd_v:
	jsr consume_cmd
	jsr get_number
	bcs @error
	sta medium
	jsr validate
	clc
	rts
@error:	sec
	rts

;---------------------------------------------------------------
; N - new
;---------------------------------------------------------------
cmd_n:
	jsr consume_cmd
	lda #':'
	clc
	jsr split
	jsr parse_path ; path is ignored, we only care about the "file" part
	bcs @error

	jsr find_wildcards
	bcs @error_wildcards

	; split into NAME and ID[,FMT]
	ldx r1s
	stx r0s
	ldy r1e
	sty r0e
	lda #','
	sec
	jsr split

	; remove [,FMT] from ID
	; and extract first char of FMT
	ldx r1s
	ldy r1e
	lda #','
	jsr search_char
	cpx r1e
	beq @no_fmt
	stx r1e
	inx
	cpx r1e
	beq @no_fmt
	lda buffer,x
	bra @end

@no_fmt:
	lda #0 ; no FMT
@end:	jsr new
	clc
	rts

@error:	sec
	rts

@error_wildcards:
	lda #$33; syntax error (wildcards)
	clc
	rts

;---------------------------------------------------------------
; R - rename
;---------------------------------------------------------------
cmd_rename:
	jsr consume_cmd

	; split into two files
	lda #'='
	sec
	jsr split
	bcs @error ; no '=' -> missing filename

	lda r1s
	pha
	lda r1e
	pha

	; parse new file and store it in medium1/r2/r3
	jsr get_path_and_name
	jsr remove_options_r1

	jsr find_wildcards
	bcs @error_wildcards

	lda r0s
	sta r2s
	lda r0e
	sta r2e
	lda r1s
	sta r3s
	lda r1e
	sta r3e
	lda medium
	sta medium1

	pla
	sta r0e
	pla
	sta r0s

	lda r3s
	cmp r3e
	beq @error ; empty new name

	; parse old file and store it in medium/r0/r1
	jsr get_path_and_name
	jsr remove_options_r1

	lda r1s
	cmp r1e
	beq @error ; empty old name

	jsr rename
	clc
	rts
@error:
	lda #$34 ; syntax error (empty filename)
	clc
	rts

@error_wildcards:
	pla
	pla
	lda #$33; syntax error (wildcards)
	clc
	rts

;---------------------------------------------------------------
; S - scratch
;---------------------------------------------------------------
cmd_scratch:
@scratch_counter = ctmp0
@loop_counter = ctmp1
	jsr consume_cmd

	stz @scratch_counter
	stz @loop_counter

@loop:	ldx r0s
	ldy r0e
	lda #','
	jsr search_char
	phx
	phy ; save remainder

	; r0 points to current name
	stx r0e
	jsr get_path_and_name
	bcs @syntax_error

	lda r1s
	cmp r1e
	beq @empty_error

	jsr scratch
	cmp #0
	bne @error

	txa
	clc
	adc @scratch_counter
	sta @scratch_counter

	ply
	sty r0e
	plx
	stx r0s

	lda buffer,x
	cmp #','
	bne @end
	inc r0s
	bra @loop

@end:
	ldx @scratch_counter
	lda #1 ; files scratched
	clc
	rts
@syntax_error:
	pla
	pla
	sec
	rts
@error:
	stx @scratch_counter ; preserve X
	plx
	plx
	ldx @scratch_counter
@error2:
	clc
	rts

@empty_error:
	pla
	pla
	lda #$34 ; syntax error (empty filename)
	clc
	rts

;---------------------------------------------------------------
; MD - make directory [CMD]
;---------------------------------------------------------------
cmd_md:
	jsr consume_get_path_and_name_remove_options
	bcs @error

	jsr find_wildcards
	bcs @error_wildcards

	jsr make_directory
	clc
	rts
@error:	sec
	rts

@error_wildcards:
	lda #$33; syntax error (wildcards)
	clc
	rts

;---------------------------------------------------------------
; RD - remove directory [CMD]
;---------------------------------------------------------------
cmd_rd:
	jsr consume_get_path_and_name_remove_options
	bcs @error
	jsr remove_directory
	clc
	rts
@error:	sec
	rts

;---------------------------------------------------------------
; CD - change directory [CMD]
;---------------------------------------------------------------
cmd_cd:
	jsr consume_get_path_and_name_remove_options
	bcs @error
	jsr change_directory
	clc
	rts
@error:	sec
	rts

;---------------------------------------------------------------
; R-H - rename header [CMD]
;---------------------------------------------------------------
cmd_rh:
	jsr consume_get_path_and_name_remove_options
	bcs @error

	jsr find_wildcards
	bcs @error_wildcards

	jsr rename_header
	clc
	rts
@error:	sec
	rts

@error_wildcards:
	lda #$33; syntax error (wildcards)
	clc
	rts

;---------------------------------------------------------------
; R-P - rename partition [CMD]
;---------------------------------------------------------------
cmd_rp:
	; remove part before ':'
	lda #':'
	sec
	jsr split
	bcs @error

	jsr find_wildcards
	bcs @error_wildcards

	lda r1s
	sta r0s
	lda r1e
	sta r0e

	; split into old and new
	lda #'='
	sec
	jsr split
	bcs @error_missing

	jsr find_wildcards
	bcs @error_wildcards

	jsr remove_options_r0
	jsr remove_options_r1

	lda r0s
	cmp r0e
	beq @error_missing
	lda r1s
	cmp r1e
	beq @error_missing

	jsr rename_partition
	clc
	rts
@error:	sec
	rts

@error_wildcards:
	lda #$33; syntax error (wildcards)
	clc
	rts

@error_missing:
	lda #$34 ; syntax error (empty filename)
	clc
	rts

;---------------------------------------------------------------
; S-8 - switch to drive #8 [CMD]
; U0>8 - set primary address to 8 [1571]
;---------------------------------------------------------------
cmd_s8:
	lda #8
	jsr change_unit
	clc
	rts

;---------------------------------------------------------------
; S-9 - switch to drive #9 [CMD]
; U0>9 - set primary address to 9 [1571]
;---------------------------------------------------------------
cmd_s9:
	lda #9
	jsr change_unit
	clc
	rts

;---------------------------------------------------------------
; S-D - switch to default drive number [CMD]
;---------------------------------------------------------------
cmd_sd:
	lda #8
	jsr change_unit
	clc
	rts

;---------------------------------------------------------------
; CP - change partition (decimal) [CMD]
;---------------------------------------------------------------
cmd_cp_decimal:
	jsr consume_cmd
	jsr get_number
	jsr change_partition
	clc
	rts

;---------------------------------------------------------------
; CP - change partition (binary) [CMD]
;---------------------------------------------------------------
cmd_cp_binary:
	ldx r0s
	lda buffer+2,x
	jsr change_partition
	clc
	rts

;---------------------------------------------------------------
; C - copy
;---------------------------------------------------------------
cmd_copy:
	; if it contains a ':', it's file copy, else copy-all
	ldx r0s
	ldy r0e
	lda #':'
	jsr search_char
	bcc @copy_file
	jmp cmd_copy_all

@copy_file:
@loop_counter = ctmp0
	; file copy
	jsr consume_cmd

	; split into target and sources
	lda #'='
	sec
	jsr split
	bcc :+
	jmp @error_empty ; no '=' -> missing filename
:
	; r0 is left string, r1 is right string

	lda r1s
	pha
	lda r1e
	pha

	; parse target file name
	jsr get_path_and_name
	jsr find_wildcards
	bcc :+
	jmp @error_ill_name_pop2
:	lda r1s
	cmp r1e
	beq @error_empty_pop2 ; empty new name

	; open target for writing
	jsr copy_start

	pla
	sta r0e
	pla
	sta r0s

	stz @loop_counter

@loop:
	lda r0s
	cmp r0e
	bne @1

	; empty/end?
	lda @loop_counter
	beq @error_empty
	bra @end

@1:	inc @loop_counter

	; split into current source and rest
	lda #','
	sec
	jsr split

	; remember rest
	lda r1s
	pha
	lda r1e
	pha

	; parse source file name
	jsr get_path_and_name
	lda r1s
	cmp r1e
	beq @error_empty_pop2 ; empty new name

	; copy into open file
	jsr copy_do
	cmp #0
	bne @error_copy
	pla
	sta r0e
	pla
	sta r0s
	bra @loop

@end:
	jsr copy_end
	lda #0
	clc
	rts

@error_empty_pop2:
	pla
	pla

@error_empty:
	lda #$34 ; syntax error (empty filename)
	clc
	rts

@error_ill_name_pop2:
	pla
	pla
	lda #$33; syntax error (wildcards)
	clc
	rts

@error_copy:
	plx
	plx
	pha
	jsr copy_end
	pla
	clc
	rts

;---------------------------------------------------------------
cmd_copy_all:
	inc r0s

	jsr get_src_dst_numbers
	bcc @1
	lda #$34 ; syntax error (empty filename)
	clc
	rts
@1:	jsr copy_all
	clc
	rts

;---------------------------------------------------------------
; D - duplicate
;---------------------------------------------------------------
cmd_d:
	; remove part before ':'
	lda #':'
	sec
	jsr split
	bcs @error
	lda r1s
	sta r0s
	lda r1e
	sta r0e

	jsr get_src_dst_numbers
	bcs @error

	jsr duplicate
	clc
	rts

@error:
	sec
	rts

;---------------------------------------------------------------
; L - lock [CMD]
;---------------------------------------------------------------
cmd_l:
	jsr consume_get_path_and_name_remove_options
	bcs @error
	lda r1s
	cmp r1e
	beq @error_empty
	jsr file_lock_toggle
	clc
	rts
@error:	sec
	rts

@error_empty:
	lda #$34 ; syntax error (empty filename)
	clc
	rts

;---------------------------------------------------------------
; F-L - file lock [C65]
;---------------------------------------------------------------
cmd_fl:
	; TODO: support a list of files
	jsr consume_get_path_and_name_remove_options
	bcs @error
	lda r1s
	cmp r1e
	beq @error_empty
	jsr file_lock
	clc
	rts
@error:	sec
	rts

@error_empty:
	lda #$34 ; syntax error (empty filename)
	clc
	rts

;---------------------------------------------------------------
; F-U - file unlock [C65]
;---------------------------------------------------------------
cmd_fu:
	; TODO: support a list of files
	jsr consume_get_path_and_name_remove_options
	bcs @error
	lda r1s
	cmp r1e
	beq @error_empty
	jsr file_unlock
	clc
	rts
@error:	sec
	rts

@error_empty:
	lda #$34 ; syntax error (empty filename)
	clc
	rts

;---------------------------------------------------------------
; F-R - file restore [C65]
;---------------------------------------------------------------
cmd_fr:
	; TODO: support a list of files
	jsr consume_get_path_and_name_remove_options
	bcs @error

	jsr find_wildcards
	bcs @error_wildcards

	lda r1s
	cmp r1e
	beq @error_empty
	jsr file_restore
	clc
	rts
@error:	sec
	rts

@error_wildcards:
	lda #$33; syntax error (wildcards)
	clc
	rts

@error_empty:
	lda #$34 ; syntax error (empty filename)
	clc
	rts

;---------------------------------------------------------------
; U
;---------------------------------------------------------------
cmd_u:
	ldx r0s
	lda buffer+1,x
	and #$0f
	beq cmd_u0
	jsr user
	clc
	rts

;---------------------------------------------------------------
; U0
;---------------------------------------------------------------
cmd_u0:
	lda buffer+2,x
	cmp #'>'
	bne :+
	jmp cmd_u0ext
:	lda #0
	jsr user
	clc
	rts

;---------------------------------------------------------------
; GP - get partition [CMD]
;---------------------------------------------------------------
cmd_gp:
	lda #$ff

	ldx buffer_len
	cpx #4
	bcc @1
	lda buffer+3

@1:	jsr get_partition
	cmp #0
	bne :+

	lda #$ff ; don't set status
:	clc
	rts

;---------------------------------------------------------------
; G-D - get disk change [CMD]
;---------------------------------------------------------------
cmd_gd:
	; TODO
	lda #$31
	clc
	rts

;---------------------------------------------------------------
; M-R - memory read
;---------------------------------------------------------------
cmd_mr:
	ldx buffer+3
	ldy buffer+4
	lda buffer+5
	jsr memory_read
	lda #$ff ; don't set status
	clc
	rts

;---------------------------------------------------------------
; M-W - memory write
;---------------------------------------------------------------
cmd_mw:
	ldx #<(buffer+3)
	ldy #>(buffer+3)
	jsr memory_write
	lda #0
	clc
	rts

;---------------------------------------------------------------
; M-E - memory exectue
;---------------------------------------------------------------
cmd_me:
	ldx buffer+3
	ldy buffer+4
	jsr memory_execute
	lda #0
	clc
	rts

;---------------------------------------------------------------
; U0>S - set sector interleave [1571]
;---------------------------------------------------------------
cmd_u0_s:
	ldx r0s
	lda buffer+4,x
	jsr set_sector_interleave
	clc
	rts

;---------------------------------------------------------------
; U0>R - set retries [1571]
;---------------------------------------------------------------
cmd_u0_r:
	ldx r0s
	lda buffer+4,x
	jsr set_retries
	clc
	rts

;---------------------------------------------------------------
; U0>T - test ROM checksum [1571]
;---------------------------------------------------------------
cmd_u0_t:
	jsr test_rom_checksum
	clc
	rts

;---------------------------------------------------------------
; U0>B - enable/disable fast serial [1581]
;---------------------------------------------------------------
cmd_u0_b:
	ldx r0s
	lda buffer+4,x
	jsr set_fast_serial
	clc
	rts

;---------------------------------------------------------------
; U0>V - enable/disable verify [1581]
;---------------------------------------------------------------
cmd_u0_v:
	ldx r0s
	lda buffer+4,x
	jsr set_verify
	clc
	rts

;---------------------------------------------------------------
; U0>D - set directory sector interleave [C65]
;---------------------------------------------------------------
cmd_u0_d:
	ldx r0s
	lda buffer+4,x
	jsr set_directory_interleave
	clc
	rts

;---------------------------------------------------------------
; U0>L - enable/disable large REL file support [C65]
;---------------------------------------------------------------
cmd_u0_l:
	ldx r0s
	lda buffer+4,x
	jsr set_large_rel_support
	clc
	rts

;---------------------------------------------------------------
; U0>MR - burst memory read [1571]
;---------------------------------------------------------------
cmd_u0_mr:
	; TODO
	lda #$31
	clc
	rts

;---------------------------------------------------------------
; U0>MW - burst memory write [1571]
;---------------------------------------------------------------
cmd_u0_mw:
	; TODO
	lda #$31
	clc
	rts
