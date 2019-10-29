.include "../banks.inc"

.import jsrfar, banked_irq

.macro bridge_internal segment, symbol
	.local address
	.segment segment
address = *
	.segment "KERNSUP"
symbol:
	jsr jsrfar
	.word address
	.byte BANK_KERNAL
	rts
	.segment segment
	jmp symbol
.endmacro

.macro bridge symbol
	bridge_internal "KERNSUPV", symbol
.endmacro

.macro bridge2 symbol
	bridge_internal "KERNSUPV2", symbol
.endmacro

.macro bridge3 symbol
	bridge_internal "KERNSUPV3", symbol
.endmacro

.segment "KERNSUPV3"
	bridge3 monitor         ; $FF00: MONITOR
	bridge3 restore_basic   ; $FF03
	bridge3 query_joysticks ; $FF06: GETJOY
	bridge3 mouse           ; $FF09: MOUSE

.segment "KERNSUPV2"

	.byte 0,0,0             ; $FF47: SPIN_SPOUT – setup fast serial ports for I/O
	bridge2 close_all       ; $FF4A: CLOSE_ALL – close all files on a device
	.byte 0,0,0             ; $FF4D: C64MODE – reconfigure system as a C64
	.byte 0,0,0             ; $FF50: DMA_CALL – send command to DMA device
	.byte 0,0,0             ; $FF53: BOOT_CALL – boot load program from disk
	.byte 0,0,0             ; $FF56: PHOENIX – init function cartridges
	bridge2 lkupla          ; $FF59: LKUPLA
	bridge2 lkupsa          ; $FF5C: LKUPSA
	bridge2 swapper         ; $FF5F: SWAPPER – switch between 40 and 80 columns
	.byte 0,0,0             ; $FF62: DLCHR – init 80-col character RAM
	.byte 0,0,0             ; $FF65: PFKEY – program a function key
	.byte 0,0,0             ; $FF68: SETBNK – set bank for I/O operations
	.byte 0,0,0             ; $FF6B: GETCFG – lookup MMU data for given bank
	jmp jsrfar              ; $FF6E: JSRFAR – gosub in another bank
	.byte 0,0,0             ; $FF71: JMPFAR – goto another bank
	bridge2 indfet          ; $FF74: FETCH – LDA (fetvec),Y from any bank
	bridge2 stash           ; $FF77: STASH – STA (stavec),Y to any bank
	bridge2 cmpare          ; $FF7A: CMPARE – CMP (cmpvec),Y to any bank
	bridge2 primm           ; $FF7D: PRIMM – print string following the caller’s code

.segment "KERNSUPV"

	.byte $ff       ;

	bridge cint
	bridge ioinit
	bridge ramtas

	bridge restor
	bridge vector

	bridge setmsg
	bridge secnd
	bridge tksa
	bridge memtop
	bridge membot
	bridge scnkey
	bridge settmo
	bridge acptr
	bridge ciout
	bridge untlk
	bridge unlsn
	bridge listn
	bridge talk
	bridge readst
	bridge setlfs
	bridge setnam
	bridge open
	bridge close
	bridge chkin
	bridge ckout
	bridge clrch
	bridge basin
	bridge bsout
	bridge loadsp
	bridge savesp
	bridge settim
	bridge rdtim
	bridge stop
	bridge getin
	bridge clall
	bridge udtim
	bridge scrorg
	bridge plot
	bridge iobase

	;private
	jmp monitor
	.byte 0

	.word $ffff ; nmi
	.word $ffff ; reset
	.word banked_irq

