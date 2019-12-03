; GEOS system variables
; by Maciej Witkowiak

.include "config.inc"

; GEOS Kernal internal zpage vectors (not for use by apps)
; unused        =       $3f ; (on C128, this is graphMode)
imparm          =       $40 ; 2 bytes
IconDescVec     =       $42 ; [icon]
IconDescVecH    =       $43 ; [icon]
CallRLo         =       $44 ; [CallRoutine]
CallRHi         =       $45 ; [CallRoutine]
DBoxDesc        =       $46 ; [dlgbox]
DBoxDescL       =       $46 ; [dlgbox]
DBoxDescH       =       $47 ; [dlgbox]

g_PrvCharWidth  =       $48 ; 1 byte
tmp1            =       $49 ; 1 byte

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
