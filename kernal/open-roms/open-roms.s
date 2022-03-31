;----------------------------------------------------------------------
; open-roms Glue
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

;
; Config
;

CONFIG_CPU_MOS_6502 = 0
CONFIG_BCD_SAFE_INTERRUPTS = 0
HAS_RS232 = 1
CONFIG_IEC = 1
CONFIG_EDIT_STOPQUOTE = 1
CONFIG_EDIT_TABULATORS = 1

;
; Macros
;

.macro branch_16 target, opcode8
;.if     .def(target) .and ((*+2)-(target) <= 127)
;.byte opcode8
;.byte (target - * - 2) & $ff
;.else
.byte opcode8 ^ $20
.byte 3
	jmp target
;.endif
.endmacro

.macro bpl_16 target
branch_16 target, $10
.endmacro
.macro bmi_16 target
branch_16 target, $30
.endmacro
.macro bvc_16 target
branch_16 target, $50
.endmacro
.macro bvs_16 target
branch_16 target, $70
.endmacro
.macro bra_16 target
branch_16 target, $80
.endmacro
.macro bcc_16 target
branch_16 target, $90
.endmacro
.macro bcs_16 target
branch_16 target, $b0
.endmacro
.macro bne_16 target
branch_16 target, $d0
.endmacro
.macro beq_16 target
branch_16 target, $f0
.endmacro

.macro phx_trash_a
	txa
	pha
.endmacro

.macro plx_trash_a
	pla
	tax
.endmacro

.macro phy_trash_a
	tya
	pha
.endmacro

.macro ply_trash_a
	pla
	tay
.endmacro

.macro skip_2_bytes_trash_nvz
	.byte $2c
.endmacro

;
; Serial
;

.import secnd, tksa, acptr, ciout, untlk, unlsn, listn, talk
SECND = secnd
TKSA = tksa
ACPTR = acptr
CIOUT = ciout
UNTLK = untlk
UNLSN = unlsn
LISTN = listn
TALK = talk

;
; RS232
;

.import opn232, cls232, cko232, cki232, bso232, bsi232
chkin_rs232 = cki232
chrin_rs232 = bsi232
chrout_rs232 = bso232
ckout_rs232 = cko232
close_rs232 = cls232
getin_rs232 = bsi232
open_rs232 = opn232

.import iload, isave
ILOAD = iload
ISAVE = isave

;
; Jump table
;

JCINT    = $FF81
JIOINIT  = $FF84
JRAMTAS  = $FF87
JRESTOR  = $FF8A
JVECTOR  = $FF8D
JSETMSG  = $FF90
JSECOND  = $FF93
JTKSA    = $FF96
JMEMTOP  = $FF99
JMEMBOT  = $FF9C
JSCNKEY  = $FF9F
JSETTMO  = $FFA2
JACPTR   = $FFA5
JCIOUT   = $FFA8
JUNTLK   = $FFAB
JUNLSN   = $FFAE
JLISTEN  = $FFB1
JTALK    = $FFB4
JREADST  = $FFB7
JSETFLS  = $FFBA
JSETNAM  = $FFBD
JOPEN    = $FFC0
JCLOSE   = $FFC3
JCHKIN   = $FFC6
JCKOUT   = $FFC9
JCLRCHN  = $FFCC
JCHRIN   = $FFCF
JCHROUT  = $FFD2
JLOAD    = $FFD5
JSAVE    = $FFD8
JSETTIM  = $FFDB
JRDTIM   = $FFDE
JSTOP    = $FFE1
JGETIN   = $FFE4
JCLALL   = $FFE7
JUDTIM   = $FFEA
JSCREEN  = $FFED
JPLOT    = $FFF0
JIOBASE  = $FFF3

;
; Externally declared zp/var sybols
;

.import cbinv, cinv, ioinit, nminv, ramtas, kbd_scan, shflag, time, pnt

BLNCT = blnct
BLNON = blnon
BLNSW = blnsw
CBINV = cbinv
CINV = cinv
COLOR = color
CRSW = crsw
DFLTN = dfltn
DFLTO = dflto
EAL = eal
FA = fa
FAT = fat
FNADDR = fnadr
FNLEN = fnlen
GDBLN = gdbln
GDCOL = gdcol
INDX = indx
INSRT = insrt
IOINIT = ioinit
IOSTATUS = status
LA = la
LAT = lat
LDTBL = ldtb1 ; XXX TODO typo
LDTND = ldtnd
LNMX = lnmx
LXSP = lsxp ; XXX TODO typo!
MEMSIZK = memsiz
MEMSTR = memstr
MEMUSS = memuss
MODE = mode
MSGFLG = msgflg
NMINV = nminv
PNTR = pntr
QTSW = qtsw
RAMTAS = ramtas
RVS = rvs
SA = sa
SAL = sal
SAT = sat
SCHAR = data
SCNKEY = kbd_scan
SHFLAG = shflag
STAL = stal
TBLX = tblx
VERCKK = verck ; typo
XSAV = xsav

;
; Exported code symbols
;

.export cint, color, cursor_blink, dfltn, dflto, llen, sah, sal, status, t1
.export plot, readst, setmsg, setnam, settmo
.export restor, memtop, membot, vector, readst, loadsp, savesp
.export scrorg
.export setlfs
.export udst

cint = CINT
plot = PLOT
readst = READST
setmsg = SETMSG
setnam = SETNAM
settmo = SETTMO
restor = RESTOR
memtop = MEMTOP
membot = MEMBOT
vector = VECTOR
loadsp = LOAD
savesp = SAVE
scrorg = SCREEN
setlfs = SETFLS
udst = UDST

.export puls, nmi, start

puls = hw_entry_irq
nmi = hw_entry_nmi
start = hw_entry_reset

;
; Imported driver symbols
;

.import screen_set_char, screen_set_color, screen_set_position, screen_get_char, screen_get_color, screen_copy_line, screen_clear_line, screen_init, screen_mode, screen_set_charset
.import enter_basic
.import kbd_config
.import irq_ack
.import emulator_get_data

;
; Internal constants
;

K_ERR_ROUTINE_TERMINATED     = $00
K_ERR_TOO_MANY_OPEN_FILES    = $01
K_ERR_FILE_ALREADY_OPEN      = $02
K_ERR_FILE_NOT_OPEN          = $03
K_ERR_FILE_NOT_FOUND         = $04
K_ERR_DEVICE_NOT_FOUND       = $05
K_ERR_FILE_NOT_INPUT         = $06
K_ERR_FILE_NOT_OUTPUT        = $07
K_ERR_FILE_NAME_MISSING      = $08
K_ERR_ILLEGAL_DEVICE_NUMBER  = $09
K_ERR_TOP_MEM_RS232          = $F0

K_STS_TIMEOUT_WRITE          = $01
K_STS_TIMEOUT_READ           = $02
K_STS_EOI                    = $40
K_STS_DEVICE_NOT_FOUND       = $80

B_ERR_VERIFY                 = $1C
B_ERR_LOAD                   = $1D

KEY_NA           = $00  ; to indicate that no key is presed
KEY_TAB_FW       = $8F  ; CTRL+>, TAB       - Open ROMs unofficial, original TAB conflicts with C64 PETSCII
KEY_TAB_BW       = $80  ; CTRL+<, SHIFT+TAB - Open ROMs unofficial, original TAB conflicts with C64 PETSCII
KEY_BELL         = $07  ; no key, originally CTRL+G ; XXX implement BELL
KEY_ESC          = $1B
KEY_STOP         = $03
KEY_RUN          = $83
KEY_F1           = $85
KEY_F2           = $89
KEY_F3           = $86
KEY_F4           = $8A
KEY_F5           = $87
KEY_F6           = $8B
KEY_F7           = $88
KEY_F8           = $8C
KEY_F9           = $10
KEY_F10          = $15
KEY_F11          = $16
KEY_F12          = $17
KEY_F13          = $19
KEY_F14          = $1A
KEY_HELP         = $84  ; normally C65 only, also used for our C128 support
KEY_CRSR_UP      = $91
KEY_CRSR_DOWN    = $11
KEY_CRSR_LEFT    = $9D
KEY_CRSR_RIGHT   = $1D
KEY_RVS_ON       = $12  ; CTRL+9
KEY_RVS_OFF      = $92  ; CTRL+0
KEY_BLACK        = $90  ; CTRL+1
KEY_WHITE        = $05  ; CTRL+2
KEY_RED          = $1C  ; CTRL+3
KEY_CYAN         = $9F  ; CTRL+4
KEY_PURPLE       = $9C  ; CTRL+5
KEY_GREEN        = $1E  ; CTRL+6
KEY_BLUE         = $1F  ; CTRL+7
KEY_YELLOW       = $9E  ; CTRL+8
KEY_ORANGE       = $81  ; VENDOR+1
KEY_BROWN        = $95  ; VENDOR+2
KEY_LT_RED       = $96  ; VENDOR+3
KEY_GREY_1       = $97  ; VENDOR+4
KEY_GREY_2       = $98  ; VENDOR+5
KEY_LT_GREEN     = $99  ; VENDOR+6
KEY_LT_BLUE      = $9A  ; VENDOR+7
KEY_GREY_3       = $9B  ; VENDOR+8
KEY_SHIFT_ON     = $09  ; no key
KEY_SHIFT_OFF    = $08  ; no key
KEY_TXT          = $0E  ; no key
KEY_GFX          = $8E  ; no key
KEY_RETURN       = $0D
KEY_CLR          = $93
KEY_HOME         = $13
KEY_INS          = $94
KEY_DEL          = $14
KEY_SPACE        = $20
KEY_EXCLAMATION  = $21
KEY_QUOTE        = $22
KEY_HASH         = $23
KEY_DOLLAR       = $24
KEY_PERCENT      = $25
KEY_AMPERSAND    = $26
KEY_APOSTROPHE   = $27
KEY_R_BRACKET_L  = $28
KEY_R_BRACKET_R  = $29
KEY_ASTERISK     = $2A
KEY_PLUS         = $2B
KEY_COMA         = $2C
KEY_MINUS        = $2D
KEY_FULLSTOP     = $2E
KEY_SLASH        = $2F
KEY_0            = $30
KEY_1            = $31
KEY_2            = $32
KEY_3            = $33
KEY_4            = $34
KEY_5            = $35
KEY_6            = $36
KEY_7            = $37
KEY_8            = $38
KEY_9            = $39
KEY_COLON        = $3A
KEY_SEMICOLON    = $3B
KEY_LT           = $3C
KEY_EQ           = $3D
KEY_GT           = $3E
KEY_QUESTION     = $3F

KEY_FLAG_CTRL    = %00000100

;
; Internal variables
;

.segment "KVAR"
; memory
memstr:	.res 2           ; start of memory
memsiz:	.res 2           ; top of memory
rambks:	.res 1           ; number of ram banks (0 means 256)

.segment "KVAR2" ; more KERNAL vars
; XXX TODO only one bit per byte is used, this should be compressed!
ldtb1:	.res 61 +1
	;       ^^ XXX at label 'lps2', the code counts up to
	;              numlines+1, THEN writes the end marker,
	;              which seems like one too many. This was
	;              worked around for now by adding one more
	;              byte here, but we should have a look at
	;              whether there's an off-by-one error over
	;              at 'lps2'!

; Screen
;
.export mode; [ps2kbd]
.export data; [cpychr]
mode:	.res 1
gdcol:	.res 1
autodn:	.res 1
lintmp:	.res 1
color:	.res 1
rvs:	.res 1           ;$C7
indx:	.res 1           ;$C8
lsxp:	.res 1           ;$C9
lstp:	.res 1           ;$CA
blnsw:	.res 1           ;$CC
blnct:	.res 1           ;$CD
gdbln:	.res 1           ;$CE
blnon:	.res 1           ;$CF
crsw:	.res 1           ;$D0
pntr:	.res 1           ;$D3
qtsw:	.res 1           ;$D4
lnmx:	.res 1           ;$D5
tblx:	.res 1           ;$D6
data:	.res 1           ;$D7
insrt:	.res 1           ;$D8
llen:	.res 1           ;$D9 x resolution
nlinesm1: .res 1         ;    y resolution - 1
verbatim: .res 1

.segment "ZPCHANNEL" : zeropage
;                      C64 location
;                         VVV
sal:	.res 1           ;$AC
sah:	.res 1           ;$AD
eal:	.res 1           ;$AE
eah:	.res 1           ;$AF
fnadr:	.res 2           ;$BB
memuss:	.res 2           ;$C3

.segment "VARCHANNEL"

; Channel I/O
;
lat:	.res 10          ;
fat:	.res 10          ;
sat:	.res 10          ;
.assert * = status, error, "status must be at specific address"
status:
	.res 1           ;$90
verck:	.res 1           ;$93
xsav:	.res 1           ;$97
ldtnd:	.res 1           ;$98
dfltn:	.res 1           ;$99
dflto:	.res 1           ;$9A
msgflg:	.res 1           ;$9D
t1:	.res 1           ;$9E
fnlen:	.res 1           ;$B7
la:	.res 1           ;$B8
sa:	.res 1           ;$B9
fa:	.res 1           ;$BA
stal:	.res 1           ;$C1
stah:	.res 1           ;$C2

.segment "EDITOR"

.include "io.inc"

.include "assets/e8da.colour_codes.s"
.include "assets/fd30.vector_defaults.s"
.include "assets/kernal_messages.s"
.include "errors.s"
.include "init/cint_screen_keyboard.s"
.include "init/e518.cint_legacy.s"
.include "init/fce2.hw_entry_reset.s"
.include "init/ff5b.cint.s"
.include "interrupts/ea31.default_irq_handler.s"
.include "interrupts/ea7e.ack_cia1_return_from_interrupt.s"
.include "interrupts/ea81.return_from_interrupt.s"
.include "interrupts/fe47.default_nmi_handler.s"
.include "interrupts/fe66.default_brk_handler.s"
.include "interrupts/hw_entry_irq.s"
.include "interrupts/hw_entry_nmi.s"
.include "iostack/chkinout.s"
.include "iostack/clall_real.s"
.include "iostack/f13e.getin.s"
.include "iostack/f157.chrin.s"
.include "iostack/f1ca.chrout.s"
.include "iostack/f20e.chkin.s"
.include "iostack/f250.ckout.s"
.include "iostack/f291.close.s"
.include "iostack/f32f.clall.jmp.s"
.include "iostack/f333.clrchn.s"
.include "iostack/f34a.open.s"
.include "iostack/f49e.load_prep.s"
.include "iostack/f4a5.load.s"
.include "iostack/f5dd.save_prep.s"
.include "iostack/f5ed.save.s"
.include "iostack/findfls.s"
.include "iostack/getin_real.s"
.include "iostack/load_save_common.s"
.include "iostack/readst.s"
.include "iostack/setfls.s"
.include "iostack/setmsg.s"
.include "iostack/setnam.s"
.include "iostack/settmo.s"
.include "keyboard/chrin_keyboard.s"
.include "keyboard/f6ed.stop.s"
.include "memory/fd15.restor.s"
.include "memory/fe25.memtop.s"
.include "memory/membot.s"
.include "memory/vector_real.s"
.include "print/print_hex_byte.s"
.include "print/print_kernal_message.s"
.include "print/print_return.s"
.include "print/print_space.s"
.include "screen/chrout_screen.s"
.include "screen/chrout_screen_clr.s"
.include "screen/chrout_screen_control.s"
.include "screen/chrout_screen_crsr.s"
.include "screen/chrout_screen_del.s"
.include "screen/chrout_screen_gfxtxt.s"
.include "screen/chrout_screen_home.s"
.include "screen/chrout_screen_ins.s"
.include "screen/chrout_screen_jumptable_codes.s"
.include "screen/chrout_screen_quote.s"
.include "screen/chrout_screen_return.s"
.include "screen/chrout_screen_rvs.s"
.include "screen/chrout_screen_shift_onoff.s"
.include "screen/chrout_screen_stop.s"
.include "screen/chrout_screen_tab.s"
.include "screen/cursor.s"
.include "screen/cursor_enable.s"
.include "screen/cursor_show.s"
.include "screen/e50a.plot.s"
.include "screen/e544.clear_screen.s"
.include "screen/e566.cursor_home.s"
.include "screen/e56c.screen_calculate_pointers.s"
.include "screen/e8ea.screen_scroll_up.s"
.include "screen/screen.s"
.include "screen/screen_advance_to_next_line.s"
.include "screen/screen_calculate_pnt_user.s"
.include "screen/screen_calculate_pntr_lnmx.s"
.include "screen/screen_check_space_ends_line.s"
.include "screen/screen_code_to_petscii.s"
.include "screen/screen_get_cliped_pntr.s"
.include "screen/screen_get_logical_line_end_ptr.s"
.include "screen/screen_grow_logical_line.s"

.segment "CHANNEL"

.export lkupla, lkupsa
.export close_all
.export primm

; XXX TODO
lkupla:
lkupsa:
close_all:
primm:
	brk

.segment "SERIAL"

; XXX TODO
clrchn_iec:
	rts
chkin_iec:
chrin_iec:
chrout_iec:
ckout_iec:
close_iec:
load_iec:
open_iec:
save_iec:
	brk
iec_check_devnum_lvs:
iec_check_devnum_oc:
	sec
	rts

;
; Misc
;

wait_x_bars:
	; TODO
	rts

.export scnsiz
scnsiz:
	stx llen
	dey
	sty nlinesm1
	jmp clear_screen

.export iobase
iobase:
	ldx #<via1
	ldy #>via1
	rts

UDST:	ora status
	sta status
	rts
