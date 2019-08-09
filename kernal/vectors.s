.ifndef C64
	.segment "JMPTBL2"
; *** this is space for new X16 KERNAL vectors ***
; for now, these are private API, they have not been
; finalized

; $ff00
	jmp monitor
; $ff03
	jmp restore_basic

	; this should not live in the vector area, but it's ok for now
monitor:
	lda #1
	sta d1prb ; ROM bank
	jmp ($c000)
restore_basic:
	lda #0
	sta d1prb ; ROM bank
	jmp ($c002)

	.segment "JMPTB128"
; C128 KERNAL API
; $FF47: SPIN_SPOUT – setup fast serial ports for I/O
	.byte 0,0,0
; $FF4A: CLOSE_ALL – close all files on a device
	.byte 0,0,0
; $FF4D: C64MODE – reconfigure system as a C64
	.byte 0,0,0
; $FF50: DMA_CALL – send command to DMA device
	.byte 0,0,0
; $FF53: BOOT_CALL – boot load program from disk
	.byte 0,0,0
; $FF56: PHOENIX – init function cartridges
	.byte 0,0,0
; $FF59: LKUPLA
	.byte 0,0,0
; $FF5C: LKUPSA
	.byte 0,0,0
; $FF5F: SWAPPER – switch between 40 and 80 columns
	.byte 0,0,0
; $FF62: DLCHR – init 80-col character RAM
	.byte 0,0,0
; $FF65: PFKEY – program a function key
	; TODO
	.byte 0,0,0
; $FF68: SETBNK – set bank for I/O operations
	; we do not want to support this
	.byte 0,0,0
; $FF6B: GETCFG – lookup MMU data for given bank
	; we do not want to support this
	.byte 0,0,0
; $FF6E: JSRFAR – gosub in another bank
	jmp jsrfar
; $FF71: JMPFAR – goto another bank
	.byte 0,0,0     ; not sure we want this
; $FF74: FETCH – LDA (fetvec),Y from any bank
	jmp indfet
; $FF77: STASH – STA (stavec),Y to any bank
	jmp stash       ; (*note* user must setup 'stavec')
; $FF7A: CMPARE – CMP (cmpvec),Y to any bank
	jmp cmpare      ; (*note*  user must setup 'cmpvec')
; $FF7D: PRIMM – print string following the caller’s code
	jmp primm
.endif


	.segment "JMPTBL"

	;KERNAL revision
	.byte $ff       ;pre-release version

	jmp cint
	jmp ioinit
	jmp ramtas

	jmp restor      ;restore vectors to initial system
	jmp vector      ;change vectors for user

	jmp setmsg      ;control o.s. messages
	jmp secnd       ;send sa after listen
	jmp tksa        ;send sa after talk
	jmp memtop      ;set/read top of memory
	jmp membot      ;set/read bottom of memory
	jmp scnkey      ;scan keyboard
	jmp settmo      ;set timeout in ieee
	jmp acptr       ;handshake ieee byte in
	jmp ciout       ;handshake ieee byte out
	jmp untlk       ;send untalk out ieee
	jmp unlsn       ;send unlisten out ieee
	jmp listn       ;send listen out ieee
	jmp talk        ;send talk out ieee
	jmp readss      ;return i/o status byte
	jmp setlfs      ;set la, fa, sa
	jmp setnam      ;set length and fn adr
open	jmp (iopen)     ;open logical file
close	jmp (iclose)    ;close logical file
chkin	jmp (ichkin)    ;open channel in
ckout	jmp (ickout)    ;open channel out
clrch	jmp (iclrch)    ;close i/o channel
basin	jmp (ibasin)    ;input from channel
bsout	jmp (ibsout)    ;output to channel
	jmp loadsp      ;load from file
	jmp savesp      ;save to file
	jmp settim      ;set internal clock
	jmp rdtim       ;read internal clock
stop	jmp (istop)     ;scan stop key
getin	jmp (igetin)    ;get char from q
clall	jmp (iclall)    ;close all files
	jmp udtim       ;increment clock
jscrog	jmp scrorg      ;screen org
jplot	jmp plot        ;read/set x,y coord
jiobas	jmp iobase      ;return i/o base

	;signature
	.byte "MIST"

	.segment "VECTORS"
	.word nmi        ;program defineable
	.word start      ;initialization code
	.word puls       ;interrupt handler

