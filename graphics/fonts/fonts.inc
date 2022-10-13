; values of currentMode
; bit numbers
UNDERLINE_BIT           =       7
BOLD_BIT                =       6
REVERSE_BIT             =       5
ITALIC_BIT              =       4
OUTLINE_BIT             =       3
; bit 0 means "OPAQUE"; it is passed by GEOS,
; and will always draw explicit background pixels

; masks
SET_UNDERLINE           =       %10000000
SET_BOLD                =       %01000000
SET_REVERSE             =       %00100000
SET_ITALIC              =       %00010000
SET_OUTLINE             =       %00001000
SET_PLAINTEXT           =       %00000000
