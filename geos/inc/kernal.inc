; GEOS system variables
; by Maciej Witkowiak

.include "config.inc"

; GEOS Kernal internal zpage vectors (not for use by apps)
compatMode      =       $3f ; (on C128, this is graphMode)
;               =       $40 ; 2 bytes UNUSED
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

; X16 additions
cpyTmp0         =       $68 ; 2 bytes for Copy(F)String/Cmp(F)String
cpyTmp1         =       $6a ; 2 bytes for Copy(F)String/Cmp(F)String
; $6c-$7f used for a0-a9

; GEOS Kernal internal vars (not for use by apps)

savedmoby2      =       OS_VARS + $08bb ; ---
scr80polar      =       OS_VARS + $08bc ; ---
scr80colors     =       OS_VARS + $08bd ; ---
vdcClrMode      =       OS_VARS + $08be ; --- (used with 128 only)
driveData       =       OS_VARS + $08bf ; drv
ramExpSize      =       OS_VARS + $08c3 ; reu
sysRAMFlg       =       OS_VARS + $08c4 ; drv, filesys, memory, tobasic
firstBoot       =       OS_VARS + $08c5 ; filesys
curType         =       OS_VARS + $08c6 ; drv, filesys, boot
ramBase         =       OS_VARS + $08c7 ; ---
inputDevName    =       OS_VARS + $08cb ; ---
memBase         =       OS_VARS + $08cf ; ---
DrCCurDkNm      =       OS_VARS + $08dc ; files
DrDCurDkNm      =       OS_VARS + $08ee ; files

dir2Head        =       OS_VARS + $0900 ; drv
;
