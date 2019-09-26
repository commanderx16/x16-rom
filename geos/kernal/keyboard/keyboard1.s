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

.import KbdTab2
.import KbdTab1
.import KbdScanHelp6
.import KbdDecodeTab1
.import KbdDecodeTab2
.import KbdDMltTab
.import KbdDBncTab
.import KbdTestTab
.import KbdScanHelp5
.import KbdScanHelp2
.import KbdNextKey
.import KbdQueFlag
.import BitMaskPow2

.global _DoKeyboardScan

.segment "keyboard1"

_DoKeyboardScan:
	rts
