addprc	=1
romloc	=$c000          ;x16 basic rom
buflen	=89             ;vic buffer
bufpag	=2
buf	=512
stkend	=507
clmwid	=10             ;print window 10 chars
pi	=255
numlev	=23
strsiz	=3

.segment "ZPBASIC" : zeropage

.segment "BVARS"
;                      C64 location
;                         VVV
charac	.res 1           ;$07 a delimiting character
integr	=charac          ;$07 a one-byte integer from "qint"
endchr	.res 1           ;$08 the other delimiting character
trmpos	.res 1           ;$09 position of terminal carriage
verck	.res 1           ;$0A CBM: single-use tmp for LOAD
count	.res 1           ;$0B a general counter
dimflg	.res 1           ;$0C in getting a pointer to a variable
                         ;    it is important to remember whether it
                         ;    is being done for "dim" or not.
                         ;    dimflg and valtyp must be
                         ;    consecutive locations.
valtyp	.res 1           ;$0D the type indicator
                         ;    0=numeric 1=string
intflg	.res 1           ;$0E tells if integer
dores	.res 1           ;$0F whether can or can't crunch res'd words YYY
                         ;    turned on when "data"
                         ;    being scanned by crunch so unquoted
                         ;    strings won't be crunched
garbfl	=dores           ;$0F whether to do garbage collection

subflg	.res 1           ;$10 flag whether sub'd variable allowed.
                         ;    "for" and user-defined function
                         ;    pointer fetching turn
                         ;    this on before calling "ptrget"
                         ;    so arrays won't be detected.
                         ;    "stkini" and "ptrget" clear it.
                         ;    also disallows integers there.
inpflg	.res 1           ;$11 flags whether we are doing "input"
                         ;    or "read".

tansgn	.res 1           ;$12 used in determining sign of tangent
domask	=tansgn          ;$12 mask in use by relation operations

channl	.res 1           ;$13 holds channel number
.segment "ZPBASIC"
linnum	.res 2           ;$14 location to store line number before buf
                         ;    so that "bltuc" can store it all away at once.
                         ;    a comma (preload or from rom)
                         ;    used by input statement since the
                         ;    data pointer always starts on a
                         ;    comma or terminator.

poker	=linnum          ;$14 set up location used by poke
                         ;    temporary for input and read code

.segment "BVARS"
temppt	.res 1           ;$16 pointer at first free temp descriptor
                         ;    initialized to point to tempst

lastpt	.res 2           ;$17 pointer to last-used string temporary
.segment "ZPBASIC"
tempst	.res 9           ;$19 storage for numtmp temp descriptors
index1	.res 2           ;$22 indexes
index	=index1          ;$22
index2	.res 2           ;$24

resho	.res 1           ;$26 result of multiplier and divider
resmoh	.res 1           ;$27
resmo	.res 1           ;$28
reslo	.res 1           ;$29
	.res 1           ;$2A fifth byte for res
addend	=resmo           ;$28 temporary used by "umult"

; --- pointers into dynamic data structures ---;
txttab	.res 2           ;$2B pointer to beginning of text.
                         ;    doesn't change after being
                         ;    setup by "init".
.segment "BVARS"
vartab	.res 2           ;$2D pointer to start of simple
                         ;    variable space.
                         ;    updated whenever the size of the
                         ;    program changes, set to [txttab]
                         ;    by "scratch" ("new").
arytab	.res 2           ;$2F pointer to beginning of array
                         ;    table.
                         ;    incremented by 6 whenever
                         ;    a new simple variable is found, and
                         ;    set to [vartab] by "clearc".
strend	.res 2           ;$31end of storage in use.
                         ;    increased whenever a new array
                         ;    or simple variable is encountered.
                         ;    set to [vartab] by "clearc".
fretop	.res 2           ;$33 top of string free space
.segment "ZPBASIC"
frespc	.res 2           ;$35 pointer to new string
.segment "BVARS"
memsiz	.res 2           ;$37 highest location in memory

; --- line numbers and textual pointers ---:
curlin	.res 2           ;$39 current line #.
                         ;    set to 0,255 for direct statements
oldlin	.res 2           ;$3B old line number (setup by ^c,"stop"
                         ;    or "end" in a program).
oldtxt	.res 2           ;$3D old line number (setup by ^c,"stop"
                         ;    or "end" in a program).
datlin	.res 2           ;$3F data line # -- remember for errors
datptr	.res 2           ;$41 pointer to data. initialized to point
                         ;    at the zero in front of [txttab]
                         ;    by "restore" which is called by "clearc".
                         ;    updated by execution of a "read"
.segment "ZPBASIC"
inpptr	.res 2           ;$43 this remembers where input is coming from

; --- stuff used in evaluations ---:
.segment "BVARS"
varnam	.res 2           ;$45 variable's name is stored here
.segment "ZPBASIC"
varpnt	.res 2           ;$47 pointer to variable in memory
fdecpt	=varpnt          ;$47 pointer into power of tens of "fout"

forpnt	.res 2           ;$49 a variable's pointer for "for" loops
                         ;    and "let" statements
lstpnt	=forpnt          ;$49 pntr to list string
andmsk	=forpnt          ;$49 the mask used by wait for anding
eormsk	=forpnt+1        ;$4A the mask for eoring in wait

.segment "BVARS"
opptr	.res 2           ;$4B pointer to current op's entry in "optab"
vartxt	=opptr           ;$4B pointer into list of variables
opmask	.res 1           ;$4D mask created by current operator

.segment "ZPBASIC"
defpnt	.res 2           ;$4E pointer used in function definition
grbpnt	=defpnt          ;$4E another used in garbage collection
tempf3	=defpnt          ;$4E a third fac temporary (5 bytes)
dscpnt	.res 2           ;$50 pointer to a string descriptor
	.res 1           ;$52 fifth byte of tempf3

.segment "BVARS"
four6	.res 1           ;$53 variable constant used by garb collect

; --- ET CETERA ---:
jmper	.res 3           ;$54
size	=jmper+1         ;$55
oldov	=jmper+2         ;$56 the old overflow

.segment "ZPBASIC"
tempf1	.res 1           ;$57 5 bytes temp fac
highds	.res 2           ;$58 desination of highest element in blt
arypnt	=highds          ;$58 a pointer used in array building
hightr	.res 2           ;$5A source of highest element to move

tempf2	.res 1           ;$5C 5 bytes temp fac
deccnt	.res 1           ;$5D number of places before decimal point
tenexp	.res 1           ;$5E has a dpt been input?
lowtr	.res 2           ;$5F last thing to move in blt
grbtop	=lowtr           ;$5F a pointer used in garbage collection
dptflg	=lowtr           ;$5F base ten exponent
expsgn	=lowtr+1         ;$60 sign of base ten exponent

; --- the floating accumulator ---:
fac                      ;$61
facexp	.res 1           ;$61
facho	.res 1           ;$62 most significant byte of mantissa
facmoh	.res 1           ;$63 one more
facmo	.res 1           ;$64 middle order of mantissa
faclo	.res 1           ;$65 least sig byte of mantissa
facsgn	.res 1           ;$66 sign of fac (0 or -1) when unpacked
sgnflg	.res 1           ;$67 sign of fac is preserved bere by "fin".
dsctmp	=fac             ;$61 this is where temp descs are built
indice	=facmo           ;$64 indice is set up here by "qint"
degree	=sgnflg          ;$67 a count used by polynomials

.segment "BVARS"
bits	.res 1           ;$68 something for "shiftr" to use

; --- the floating argument (unpacked) ---:
.segment "ZPBASIC"
argexp	.res 1           ;$69
argho	.res 1           ;$6A
argmoh	.res 1           ;$6B
argmo	.res 1           ;$6C
arglo	.res 1           ;$6D
argsgn	.res 1           ;$6E
arisgn	.res 1           ;$6F a sign reflecting the result
facov	.res 1           ;$70 overflow byte of the fac
strng1	=arisgn          ;$6F

fbufpt	.res 2           ;$71 pointer into fbuffr used by fout
bufptr	=fbufpt          ;$71 pointer to buf used by "crunch".
strng2	=fbufpt          ;$71 pointer to string or desc.
polypt	=fbufpt          ;$71 pointer into polynomial coefficients.
curtol	=fbufpt          ;$71 absolute linear index is formed here.

; CHRGET
chrget	.res 6           ;$73
chrgot	.res 1           ;$79
txtptr	.res 6           ;$7A
qnum	.res 11          ;$80

.segment "BVARS"
rndx	.res 5           ;$8B

.segment "STRTMP" : zeropage

lofbuf	.res 1           ;$FF the low fac buffer. copyable
fbuffr	.res 1           ;$100 buffer for "fout".
                         ;     on page 1 so that string is not copied

.segment "BVECTORS" ;basic indirects

ierror	.res 2           ;$0300 indirect error (output error in .x)
imain	.res 2           ;$0302 indirect main (system direct loop)
icrnch	.res 2           ;$0304 indirect crunch (tokenization routine)
iqplop	.res 2           ;$0306 indirect list (char list)
igone	.res 2           ;$0308 indirect gone (char dispatch)
ieval	.res 2           ;$030A indirect eval (symbol evaluation)
;temp storage untill system intergration
; sys 6502 regs
sareg	.res 1           ;$030C .a reg
sxreg	.res 1           ;$030D .x reg
syreg	.res 1           ;$030E .y reg
spreg	.res 1           ;$030F .p reg
usrpok	.res 3           ;$0310 user function dispatch

