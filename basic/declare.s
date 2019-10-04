addprc	=1
romloc	=$c000          ;x16 basic rom
linlen	=40             ;vic screen size ?why?
buflen	=89             ;vic buffer
bufpag	=2
buf	=512
stkend	=507
clmwid	=10             ;print window 10 chars
pi	=255
numlev	=23
strsiz	=3
.segment "ZPBASIC" : zeropage
blank0	.res 3           ;$00 unused (C64: 6510 register area)
adray1	.res 2           ;$03 convert float->integer
adray2	.res 2           ;$05 convert integer->float
integr                   ;$07
charac	.res 1           ;$07
endchr	.res 1           ;$08
trmpos	.res 1           ;$09
verck	.res 1           ;$0A
count	.res 1           ;$0B
dimflg	.res 1           ;$0C
valtyp	.res 1           ;$0D
intflg	.res 1           ;$0E
garbfl                   ;$0F
dores	.res 1           ;$0F
subflg	.res 1           ;$10
inpflg	.res 1           ;$11
domask                   ;$12
tansgn	.res 1           ;$12
channl	.res 1           ;$13
poker                    ;$14
linnum	.res 2           ;$14
temppt	.res 1           ;$16
lastpt	.res 2           ;$17
tempst	.res 9           ;$19
index                    ;$22
index1	.res 2           ;$22
index2	.res 2           ;$24
resho	.res 1           ;$26
resmoh	.res 1           ;$27
addend                   ;$28
resmo	.res 1           ;$28
reslo	.res 1           ;$29
	.res 1           ;$2A unused (MS: "OVERFLOW FOR RES")
txttab	.res 2           ;$2B
vartab	.res 2           ;$2D
arytab	.res 2           ;$2F
strend	.res 2           ;$31
fretop	.res 2           ;$33
frespc	.res 2           ;$35
memsiz	.res 2           ;$37
curlin	.res 2           ;$39
oldlin	.res 2           ;$3B
oldtxt	.res 2           ;$3D
datlin	.res 2           ;$3F
datptr	.res 2           ;$41
inpptr	.res 2           ;$43
varnam	.res 2           ;$45
fdecpt                   ;$47
varpnt	.res 2           ;$47
lstpnt                   ;$49
andmsk                   ;$49
forpnt	.res 2           ;$49
eormsk	=forpnt+1        ;$4A
vartxt                   ;$4B
opptr	.res 2           ;$4B
opmask	.res 1           ;$4D
grbpnt                   ;$4E
tempf3                   ;$4E
defpnt	.res 2           ;$4E
dscpnt	.res 2           ;$50
	.res 1           ;$52 unused (MS: "FOR TEMPF3.")
four6	.res 1           ;$53
jmper	.res 1           ;$54
size	.res 1           ;$55
oldov	.res 1           ;$56
tempf1	.res 1           ;$57
arypnt                   ;$58
highds	.res 2           ;$58
hightr	.res 2           ;$5A
tempf2	.res 1           ;$5C
deccnt                   ;$5D
lowds	.res 2           ;$5D
grbtop                   ;$5F
dptflg                   ;$5F
lowtr	.res 1           ;$5F
expsgn	.res 1           ;$60

tenexp	=lowds+1
epsgn	=lowtr+1

dsctmp                   ;$61
fac                      ;$61
facexp	.res 1           ;$61
facho	.res 1           ;$62
facmoh	.res 1           ;$63
indice                   ;$64
facmo	.res 1           ;$64
faclo	.res 1           ;$65
facsgn	.res 1           ;$66
degree                   ;$67
sgnflg	.res 1           ;$67
bits	.res 1           ;$68
argexp	.res 1           ;$69
argho	.res 1           ;$6A
argmoh	.res 1           ;$6B
argmo	.res 1           ;$6C
arglo	.res 1           ;$6D
argsgn	.res 1           ;$6E
strngi                   ;$6F
arisgn	.res 1           ;$6F
facov	.res 1           ;$70
bufptr                   ;$71
strng2                   ;$71
polypt                   ;$71
curtol                   ;$71
fbufpt	.res 2           ;$71
chrget	.res 6           ;$73
chrgot	.res 1           ;$79
txtptr	.res 6           ;$7A
qnum	.res 10          ;$80
chrrts	.res 1           ;$8A
rndx	.res 5           ;$8B

	.segment "STRTMP" : zeropage
lofbuf	.res 1           ;$FF
fbuffr	.res 1           ;$100
strng1	=arisgn          ;$6F
;
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

