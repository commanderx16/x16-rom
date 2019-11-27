lower
	cmp #$0e        ;does he want lower case?
	bne upper       ;branch if not
	bit mode
	bvs outhre      ;ISO
	lda #2
	jsr cpychr
	jmp loop2

upper
	cmp #$8e        ;does he want upper case
	bne lock        ;branch if not
	bit mode
	bvs outhre      ;ISO
	lda #1
	jsr cpychr
outhre	jmp loop2

lock
	cmp #8          ;does he want to lock in this mode?
	bne unlock      ;branch if not
	lda #$80        ;else set lock switch on
	ora mode        ;don't hurt anything - just in case
	bmi lexit

unlock
	cmp #9          ;does he want to unlock the keyboard?
	bne isoon       ;branch if not
	lda #$7f        ;clear the lock switch
	and mode        ;dont hurt anything
lexit	sta mode
	jmp loop2       ;get out

isoon
	cmp #$0f        ;switch to ISO mode?
	bne isooff      ;branch if not
	lda #0
	jsr cpychr
	lda mode
	ora #$40
	bra isosto

isooff
	cmp #$8f        ;switch to PETSCII mode?
	bne outhre      ;branch if not
	lda #1
	jsr cpychr
	lda mode
	and #$ff-$40
isosto	sta mode
	lda #$ff
	jsr kbd_config  ;reload keymap
	jsr clsr        ;clear screen
	jmp loop2

;
runtb	.byt "LOAD",$d,"RUN",$d
runtb_end:
;
fkeytb	.byt $8D, "LIST:", 13, 0
	.byt $8D, "M", 'O' + $80, ":", 13, 0
	.byt $8D, "RUN:", 13, 0
	.byt $93, "S", 'C' + $80, "255:", 13, 0
	.byt "LOAD", 13, 0
	.byt "SAVE", '"', 0
	.byt $8D, $93, "DOS",'"', "$",13, 0
	.byt "DOS", '"', 0

