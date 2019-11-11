; GEOS system variables
; by Maciej Witkowiak

.include "config.inc"

; GEOS Kernal internal zpage vectors (not for use by apps)
compatMode      =       $3f ; (on C128, this is graphMode)
imparm          =       $40
IconDescVec     =       $42
IconDescVecH    =       $43
CallRLo         =       $44
CallRHi         =       $45
DBoxDesc        =       $46
DBoxDescL       =       $46
DBoxDescH       =       $47
Z45             =       $48
Z46             =       $49
Z47             =       $4A

; GEOS Kernal internal vars (not for use by apps)

savedmoby2      =       $88bb ; ---
scr80polar      =       $88bc ; ---
scr80colors     =       $88bd ; ---
vdcClrMode      =       $88be ; --- (used with 128 only)
driveData       =       $88bf ; drv
ramExpSize      =       $88c3 ; reu
sysRAMFlg       =       $88c4 ; drv, filesys, memory, tobasic
firstBoot       =       $88c5 ; filesys
curType         =       $88c6 ; drv, filesys, boot
ramBase         =       $88c7 ; ---
inputDevName    =       $88cb ; ---
memBase         =       $88cf ; ---
DrCCurDkNm      =       $88dc ; files
DrDCurDkNm      =       $88ee ; files

dir2Head        =       $8900 ; drv
;

E87FC           =       $87fc
E87FD           =       $87fd
E87FE           =       $87fe
E87FF           =       $87ff
E8800           =       $8800
