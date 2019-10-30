.global monitor

	.segment "JMPTBL2"
; *** this is space for new X16 KERNAL vectors ***
; for now, these are private API, they have not been
; finalized

; $FF00: MONITOR
	jmp monitor
; $FF03
	jmp restore_basic
; $FF06: GETJOY
	jmp query_joysticks
; $FF09: MOUSE
	jmp mouse

	.segment "JMPTB128"
; C128 KERNAL API
;
; We are trying to support as many C128 calls as possible.
; Some make no sense on the X16 though, usually because
; their functionality is C128-specific.

; $FF47: SPIN_SPOUT – setup fast serial ports for I/O
	; UNSUPPORTED
	; no fast serial support
	.byte 0,0,0
; $FF4A: CLOSE_ALL – close all files on a device
	; COMPATIBLE
	jmp close_all
; $FF4D: C64MODE – reconfigure system as a C64
	; UNSUPPORTED
	; no C64 compatibility support
	.byte 0,0,0
; $FF50: DMA_CALL – send command to DMA device
	; UNSUPPORTED
	; no support for Commodore REU devices
	.byte 0,0,0
; $FF53: BOOT_CALL – boot load program from disk
	; TODO
	; We need better disk support first.
	.byte 0,0,0
; $FF56: PHOENIX – init function cartridges
	; UNSUPPORTED
	; no external ROM support
	.byte 0,0,0
; $FF59: LKUPLA
	; COMPATIBLE
	jmp lkupla
; $FF5C: LKUPSA
	; COMPATIBLE
	jmp lkupsa
; $FF5F: SCRMOD – get/set screen mode
	; NOT COMPATIBLE
	; On the C128, this is "SWAPPER", which takes no arguments
	; and switches between 40/80 column text modes.
	jmp scrmod
; $FF62: DLCHR – init 80-col character RAM
	; UNSUPPORTED
	; VDC8563-specific
	.byte 0,0,0
; $FF65: PFKEY – program a function key
	; TODO
	; Currently, the fkey strings are stored in ROM.
	; In order to make them editable, 256 bytes of RAM are
	; required. (C128: PKYBUF, PKYDEF)
	.byte 0,0,0
; $FF68: SETBNK – set bank for I/O operations
	; UNSUPPORTED
	; To keep things simple, the X16 KERNAL APIs do not
	; support banking. Data for use with KERNAL APIs must be
	; in non-banked RAM < $9F00.
	.byte 0,0,0
; $FF6B: GETCFG – lookup MMU data for given bank
	; UNSUPPORTED
	; no MMU
	.byte 0,0,0
; $FF6E: JSRFAR – gosub in another bank
	; NOT COMPATIBLE
	; This call takes the address (2 bytes) and bank (1 byte)
	; from the instruction stream.
	jmp jsrfar
; $FF71: JMPFAR – goto another bank
	; TODO/UNSUPPORTED
	; Not sure we want this. It is not very useful, and would
	; require a lot of new code.
	.byte 0,0,0
; $FF74: FETCH – LDA (fetvec),Y from any bank
	; COMPATIBLE
	jmp indfet
; $FF77: STASH – STA (stavec),Y to any bank
	; COMPATIBLE
	jmp stash       ; (*note* user must setup 'stavec')
; $FF7A: CMPARE – CMP (cmpvec),Y to any bank
	; COMPATIBLE
	jmp cmpare      ; (*note*  user must setup 'cmpvec')
; $FF7D: PRIMM – print string following the caller’s code
	; COMPATIBLE
	jmp primm


	.segment "JMPTBL"

	;KERNAL revision
.ifdef PRERELEASE_VERSION
	.byte <(-PRERELEASE_VERSION)
.elseif .defined(RELEASE_VERSION)
	.byte RELEASE_VERSION
.else
	.byte $ff       ;custom pre-release version
.endif

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
	jmp readst      ;return i/o status byte
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

