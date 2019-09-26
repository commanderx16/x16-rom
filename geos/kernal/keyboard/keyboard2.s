; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; C64/C128 keyboard driver

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.global KbdDecodeTab1
.global KbdDecodeTab2
.global KbdTab1
.global KbdTab2
.global KbdTestTab

.segment "keyboard2"
