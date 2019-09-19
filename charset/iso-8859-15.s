;
;      ISO-8859-15        X16 Additions
;                           (inverted)
;
; 00|                | |@ABCDEFGHIJKLMNO|
; 10|                | |PQRSTUVWXYZ[\]^_|
; 20| !"#$%&'()*+,-./|
; 30|0123456789:;<=>?|
; 40|@ABCDEFGHIJKLMNO|
; 50|PQRSTUVWXYZ[\]^_|
; 60|`abcdefghijklmno|
; 70|pqrstuvwxyz{|}~ |
; 80|                | |`abcdefghijklmno|
; 90|                | |pqrstuvwxyz{|}~ |
; A0| ¡¢£€¥Š§š©ª«¬ ®¯|
; B0|°±²³Žµ¶·ž¹º»ŒœŸ¿|
; C0|ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ|
; D0|ÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß|
; E0|àáâãäåæçèéêëìíîï|
; F0|ðñòóôõö÷øùúûüýþÿ|

.segment "CHARISO"

;
; 00 Control Codes
;
; |@ABCDEFGHIJKLMNO| (inverted)
; |PQRSTUVWXYZ[\]^_| (inverted)
;

; These are taken from PXLfont
.byte %████████
.byte %██____██
.byte %█__██__█
.byte %█__█___█
.byte %█__█___█
.byte %█__█████
.byte %██____██
.byte %████████

.byte %████████
.byte %██____██
.byte %█__██__█
.byte %█__██__█
.byte %█______█
.byte %█__██__█
.byte %█__██__█
.byte %████████

.byte %████████
.byte %█_____██
.byte %█__██__█
.byte %█_____██
.byte %█__██__█
.byte %█__██__█
.byte %█_____██
.byte %████████

.byte %████████
.byte %██_____█
.byte %█__█████
.byte %█__█████
.byte %█__█████
.byte %█__█████
.byte %██_____█
.byte %████████

.byte %████████
.byte %█_____██
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█_____██
.byte %████████

.byte %████████
.byte %█______█
.byte %█__█████
.byte %█_____██
.byte %█__█████
.byte %█__█████
.byte %█______█
.byte %████████

.byte %████████
.byte %█______█
.byte %█__█████
.byte %█_____██
.byte %█__█████
.byte %█__█████
.byte %█__█████
.byte %████████

.byte %████████
.byte %██_____█
.byte %█__█████
.byte %█__█___█
.byte %█__██__█
.byte %█__██__█
.byte %██_____█
.byte %████████

.byte %████████
.byte %█__██__█
.byte %█__██__█
.byte %█______█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %████████

.byte %████████
.byte %██____██
.byte %███__███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %██____██
.byte %████████

.byte %████████
.byte %███___██
.byte %████__██
.byte %████__██
.byte %████__██
.byte %█__█__██
.byte %██___███
.byte %████████

.byte %████████
.byte %█__██__█
.byte %█__█__██
.byte %█____███
.byte %█____███
.byte %█__█__██
.byte %█__██__█
.byte %████████

.byte %████████
.byte %█__█████
.byte %█__█████
.byte %█__█████
.byte %█__█████
.byte %█__█████
.byte %█______█
.byte %████████

.byte %████████
.byte %█__███__
.byte %█___█___
.byte %█_______
.byte %█__█_█__
.byte %█__███__
.byte %█__███__
.byte %████████

.byte %████████
.byte %█__██__█
.byte %█___█__█
.byte %█______█
.byte %█__█___█
.byte %█__██__█
.byte %█__██__█
.byte %████████

.byte %████████
.byte %██____██
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %██____██
.byte %████████

.byte %████████
.byte %█_____██
.byte %█__██__█
.byte %█__██__█
.byte %█_____██
.byte %█__█████
.byte %█__█████
.byte %████████

.byte %████████
.byte %██____██
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %██____██
.byte %████___█

.byte %████████
.byte %█_____██
.byte %█__██__█
.byte %█__██__█
.byte %█_____██
.byte %█__██__█
.byte %█__██__█
.byte %████████

.byte %████████
.byte %██____██
.byte %█__█████
.byte %█____███
.byte %███____█
.byte %█████__█
.byte %█_____██
.byte %████████

.byte %████████
.byte %█______█
.byte %███__███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %████████

.byte %████████
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %██____██
.byte %████████

.byte %████████
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %██____██
.byte %███__███
.byte %████████

.byte %████████
.byte %█__███__
.byte %█__███__
.byte %█__█_█__
.byte %█__█_█__
.byte %█_______
.byte %██__█__█
.byte %████████

.byte %████████
.byte %█__██__█
.byte %█__██__█
.byte %██____██
.byte %██____██
.byte %█__██__█
.byte %█__██__█
.byte %████████

.byte %████████
.byte %█__██__█
.byte %█__██__█
.byte %██____██
.byte %███__███
.byte %███__███
.byte %███__███
.byte %████████

.byte %████████
.byte %█______█
.byte %████__██
.byte %███__███
.byte %██__████
.byte %█__█████
.byte %█______█
.byte %████████

.byte %████████
.byte %██____██
.byte %██__████
.byte %██__████
.byte %██__████
.byte %██__████
.byte %██____██
.byte %████████
; This is '/' from PXLfont, flipped
.byte %████████
.byte %██__████
.byte %██__████
.byte %███__███
.byte %███__███
.byte %████__██
.byte %████__██
.byte %████████

.byte %████████
.byte %██____██
.byte %████__██
.byte %████__██
.byte %████__██
.byte %████__██
.byte %██____██
.byte %████████
; This is the CBM/PXLfont character, edited
.byte %████████
.byte %███__███
.byte %██____██
.byte %█__██__█
.byte %████████
.byte %████████
.byte %████████
.byte %████████
; This is "_" taken from CP850 and inverted
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %________

;
; 20
;
; | !"#$%&'()*+,-./|
; |0123456789:;<=>?|

; These are taken from PXLfont
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________

.byte %________
.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %________
.byte %___██___
.byte %________

.byte %________
.byte %__██_██_
.byte %__██_██_
.byte %__█__█__
.byte %________
.byte %________
.byte %________
.byte %________

.byte %________
.byte %__██_██_
.byte %_███████
.byte %__██_██_
.byte %__██_██_
.byte %_███████
.byte %__██_██_
.byte %________

.byte %________
.byte %___██___
.byte %___███__
.byte %__██____
.byte %__████__
.byte %____██__
.byte %__███___
.byte %___██___

.byte %________
.byte %_███__██
.byte %_█_█_██_
.byte %_██_██__
.byte %___██_██
.byte %__██_█_█
.byte %_██__███
.byte %________

.byte %________
.byte %__███___
.byte %_██_██__
.byte %__███___
.byte %_██_████
.byte %_██__██_
.byte %__██████
.byte %________

.byte %________
.byte %___██___
.byte %___██___
.byte %___█____
.byte %________
.byte %________
.byte %________
.byte %________

.byte %________
.byte %___██___
.byte %__██____
.byte %__██____
.byte %__██____
.byte %__██____
.byte %___██___
.byte %________

.byte %________
.byte %___██___
.byte %____██__
.byte %____██__
.byte %____██__
.byte %____██__
.byte %___██___
.byte %________

.byte %________
.byte %________
.byte %_██__██_
.byte %__████__
.byte %████████
.byte %__████__
.byte %_██__██_
.byte %________

.byte %________
.byte %________
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %___██___
.byte %___██___
.byte %________

.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %___██___
.byte %___██___
.byte %__██____

.byte %________
.byte %________
.byte %________
.byte %________
.byte %_██████_
.byte %________
.byte %________
.byte %________

.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %___██___
.byte %___██___
.byte %________

.byte %________
.byte %____██__
.byte %____██__
.byte %___██___
.byte %___██___
.byte %__██____
.byte %__██____
.byte %________

.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██_███_
.byte %_███_██_
.byte %_██__██_
.byte %__████__
.byte %________

.byte %________
.byte %___██___
.byte %__███___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %________

.byte %________
.byte %_████___
.byte %____██__
.byte %____██__
.byte %___██___
.byte %__██____
.byte %_██████_
.byte %________

.byte %________
.byte %_██████_
.byte %____██__
.byte %___███__
.byte %_____██_
.byte %_____██_
.byte %_█████__
.byte %________

.byte %________
.byte %____██__
.byte %___██___
.byte %__██_██_
.byte %_██__██_
.byte %_██████_
.byte %_____██_
.byte %________

.byte %________
.byte %_█████__
.byte %_██_____
.byte %_█████__
.byte %_____██_
.byte %_____██_
.byte %_█████__
.byte %________

.byte %________
.byte %__████__
.byte %_██_____
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________

.byte %________
.byte %_██████_
.byte %_____██_
.byte %____██__
.byte %____██__
.byte %___██___
.byte %___██___
.byte %________

.byte %________
.byte %__████__
.byte %_██__██_
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________

.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %_____██_
.byte %__████__
.byte %________

.byte %________
.byte %________
.byte %___██___
.byte %___██___
.byte %________
.byte %___██___
.byte %___██___
.byte %________

.byte %________
.byte %________
.byte %___██___
.byte %___██___
.byte %________
.byte %___██___
.byte %___██___
.byte %__██____

.byte %________
.byte %________
.byte %____██__
.byte %___██___
.byte %__██____
.byte %___██___
.byte %____██__
.byte %________

.byte %________
.byte %________
.byte %________
.byte %_██████_
.byte %________
.byte %_██████_
.byte %________
.byte %________

.byte %________
.byte %________
.byte %__██____
.byte %___██___
.byte %____██__
.byte %___██___
.byte %__██____
.byte %________

.byte %________
.byte %__████__
.byte %_██__██_
.byte %____███_
.byte %___███__
.byte %________
.byte %___██___
.byte %________

;
; 40
;
; |@ABCDEFGHIJKLMNO|
; |PQRSTUVWXYZ[\]^_|

; These are taken from PXLfont
.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██_███_
.byte %_██_███_
.byte %_██_____
.byte %__████__
.byte %________

.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██████_
.byte %_██__██_
.byte %_██__██_
.byte %________

.byte %________
.byte %_█████__
.byte %_██__██_
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %________

.byte %________
.byte %__█████_
.byte %_██_____
.byte %_██_____
.byte %_██_____
.byte %_██_____
.byte %__█████_
.byte %________

.byte %________
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %________

.byte %________
.byte %_██████_
.byte %_██_____
.byte %_█████__
.byte %_██_____
.byte %_██_____
.byte %_██████_
.byte %________

.byte %________
.byte %_██████_
.byte %_██_____
.byte %_█████__
.byte %_██_____
.byte %_██_____
.byte %_██_____
.byte %________

.byte %________
.byte %__█████_
.byte %_██_____
.byte %_██_███_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %________

.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██████_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %________

.byte %________
.byte %__████__
.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %__████__
.byte %________

.byte %________
.byte %___███__
.byte %____██__
.byte %____██__
.byte %____██__
.byte %_██_██__
.byte %__███___
.byte %________

.byte %________
.byte %_██__██_
.byte %_██_██__
.byte %_████___
.byte %_████___
.byte %_██_██__
.byte %_██__██_
.byte %________

.byte %________
.byte %_██_____
.byte %_██_____
.byte %_██_____
.byte %_██_____
.byte %_██_____
.byte %_██████_
.byte %________

.byte %________
.byte %_██___██
.byte %_███_███
.byte %_███████
.byte %_██_█_██
.byte %_██___██
.byte %_██___██
.byte %________

.byte %________
.byte %_██__██_
.byte %_███_██_
.byte %_██████_
.byte %_██_███_
.byte %_██__██_
.byte %_██__██_
.byte %________

.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________

.byte %________
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %_██_____
.byte %_██_____
.byte %________

.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %____███_

.byte %________
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %________

.byte %________
.byte %__████__
.byte %_██_____
.byte %_████___
.byte %___████_
.byte %_____██_
.byte %_█████__
.byte %________

.byte %________
.byte %_██████_
.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %________

.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________

.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %___██___
.byte %________

.byte %________
.byte %_██___██
.byte %_██___██
.byte %_██_█_██
.byte %_██_█_██
.byte %_███████
.byte %__██_██_
.byte %________

.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %________

.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %___██___
.byte %___██___
.byte %___██___
.byte %________

.byte %________
.byte %_██████_
.byte %____██__
.byte %___██___
.byte %__██____
.byte %_██_____
.byte %_██████_
.byte %________

.byte %________
.byte %__████__
.byte %__██____
.byte %__██____
.byte %__██____
.byte %__██____
.byte %__████__
.byte %________
; This is '/' from PXLfont, flipped
.byte %________
.byte %__██____
.byte %__██____
.byte %___██___
.byte %___██___
.byte %____██__
.byte %____██__
.byte %________

.byte %________
.byte %__████__
.byte %____██__
.byte %____██__
.byte %____██__
.byte %____██__
.byte %__████__
.byte %________
; This is the CBM/PXLfont character, edited
.byte %________
.byte %___██___
.byte %__████__
.byte %_██__██_
.byte %________
.byte %________
.byte %________
.byte %________
; This is "_" taken from CP850
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %████████

;
; 60
;
; |`abcdefghijklmno|
; |pqrstuvwxyz{|}~ |

; This is ' from PXLfont, flipped
.byte %________
.byte %___██___
.byte %___██___
.byte %____█___
.byte %________
.byte %________
.byte %________
.byte %________
; These are taken from PXLfont
.byte %________
.byte %________
.byte %__████__
.byte %_____██_
.byte %__█████_
.byte %_██__██_
.byte %__█████_
.byte %________

.byte %________
.byte %_██_____
.byte %_██_██__
.byte %_███_██_
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %________

.byte %________
.byte %________
.byte %__█████_
.byte %_██_____
.byte %_██_____
.byte %_██_____
.byte %__█████_
.byte %________

.byte %________
.byte %_____██_
.byte %__██_██_
.byte %_██_███_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %________

.byte %________
.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██_____
.byte %__████__
.byte %________

.byte %________
.byte %___████_
.byte %__██____
.byte %__████__
.byte %__██____
.byte %__██____
.byte %__██____
.byte %________

.byte %________
.byte %________
.byte %__█████_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %_____██_
.byte %__████__

.byte %________
.byte %_██_____
.byte %_██_██__
.byte %_███_██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %________

.byte %___██___
.byte %________
.byte %_████___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %________

.byte %____██__
.byte %________
.byte %__████__
.byte %____██__
.byte %____██__
.byte %____██__
.byte %_██_██__
.byte %__███___

.byte %________
.byte %_██_____
.byte %_██__██_
.byte %_██_██__
.byte %_████___
.byte %_██_██__
.byte %_██__██_
.byte %________

.byte %________
.byte %__███___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %__████__
.byte %________

.byte %________
.byte %________
.byte %_██████_
.byte %_██_█_██
.byte %_██_█_██
.byte %_██_█_██
.byte %_██_█_██
.byte %________

.byte %________
.byte %________
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %________

.byte %________
.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________

.byte %________
.byte %________
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %_██_____

.byte %________
.byte %________
.byte %__█████_
.byte %_██__██_
.byte %_██__██_
.byte %_██_███_
.byte %__██_██_
.byte %_____██_

.byte %________
.byte %________
.byte %_███_██_
.byte %__███___
.byte %__██____
.byte %__██____
.byte %_████___
.byte %________

.byte %________
.byte %________
.byte %__████__
.byte %_██_____
.byte %_██████_
.byte %_____██_
.byte %_█████__
.byte %________

.byte %________
.byte %__██____
.byte %__████__
.byte %__██____
.byte %__██____
.byte %__██____
.byte %___███__
.byte %________

.byte %________
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %________

.byte %________
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %___██___
.byte %________

.byte %________
.byte %________
.byte %_██___██
.byte %_██_█_██
.byte %_██_█_██
.byte %_███████
.byte %__██_██_
.byte %________

.byte %________
.byte %________
.byte %_██__██_
.byte %__████__
.byte %___██___
.byte %__████__
.byte %_██__██_
.byte %________

.byte %________
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %_____██_
.byte %__████__

.byte %________
.byte %________
.byte %_██████_
.byte %____██__
.byte %___██___
.byte %__██____
.byte %_██████_
.byte %________
; These are taken from CP850
.byte %____███_
.byte %___██___
.byte %___██___
.byte %_███____
.byte %___██___
.byte %___██___
.byte %____███_
.byte %________

.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %________

.byte %_███____
.byte %___██___
.byte %___██___
.byte %____███_
.byte %___██___
.byte %___██___
.byte %_███____
.byte %________

.byte %_███_██_
.byte %██_███__
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
; This is 0x7F, which is non-printable
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________

;
; 80 Control Codes
;
; |`abcdefghijklmno| (inverted)
; |pqrstuvwxyz{|}~ | (inverted)

; This is ' from PXLfont, flipped
.byte %████████
.byte %███__███
.byte %███__███
.byte %████_███
.byte %████████
.byte %████████
.byte %████████
.byte %████████
; These are taken from PXLfont
.byte %████████
.byte %████████
.byte %██____██
.byte %█████__█
.byte %██_____█
.byte %█__██__█
.byte %██_____█
.byte %████████

.byte %████████
.byte %█__█████
.byte %█__█__██
.byte %█___█__█
.byte %█__██__█
.byte %█__██__█
.byte %█_____██
.byte %████████

.byte %████████
.byte %████████
.byte %██_____█
.byte %█__█████
.byte %█__█████
.byte %█__█████
.byte %██_____█
.byte %████████

.byte %████████
.byte %█████__█
.byte %██__█__█
.byte %█__█___█
.byte %█__██__█
.byte %█__██__█
.byte %██_____█
.byte %████████

.byte %████████
.byte %████████
.byte %██____██
.byte %█__██__█
.byte %█______█
.byte %█__█████
.byte %██____██
.byte %████████

.byte %████████
.byte %███____█
.byte %██__████
.byte %██____██
.byte %██__████
.byte %██__████
.byte %██__████
.byte %████████

.byte %████████
.byte %████████
.byte %██_____█
.byte %█__██__█
.byte %█__██__█
.byte %██_____█
.byte %█████__█
.byte %██____██

.byte %████████
.byte %█__█████
.byte %█__█__██
.byte %█___█__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %████████

.byte %███__███
.byte %████████
.byte %█____███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %█______█
.byte %████████

.byte %████__██
.byte %████████
.byte %██____██
.byte %████__██
.byte %████__██
.byte %████__██
.byte %█__█__██
.byte %██___███

.byte %████████
.byte %█__█████
.byte %█__██__█
.byte %█__█__██
.byte %█____███
.byte %█__█__██
.byte %█__██__█
.byte %████████

.byte %████████
.byte %██___███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %██____██
.byte %████████

.byte %████████
.byte %████████
.byte %█______█
.byte %█__█_█__
.byte %█__█_█__
.byte %█__█_█__
.byte %█__█_█__
.byte %████████

.byte %████████
.byte %████████
.byte %█_____██
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %████████

.byte %████████
.byte %████████
.byte %██____██
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %██____██
.byte %████████

.byte %████████
.byte %████████
.byte %█_____██
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█_____██
.byte %█__█████

.byte %████████
.byte %████████
.byte %██_____█
.byte %█__██__█
.byte %█__██__█
.byte %█__█___█
.byte %██__█__█
.byte %█████__█

.byte %████████
.byte %████████
.byte %█___█__█
.byte %██___███
.byte %██__████
.byte %██__████
.byte %█____███
.byte %████████

.byte %████████
.byte %████████
.byte %██____██
.byte %█__█████
.byte %█______█
.byte %█████__█
.byte %█_____██
.byte %████████

.byte %████████
.byte %██__████
.byte %██____██
.byte %██__████
.byte %██__████
.byte %██__████
.byte %███___██
.byte %████████

.byte %████████
.byte %████████
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %██_____█
.byte %████████

.byte %████████
.byte %████████
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %██____██
.byte %███__███
.byte %████████

.byte %████████
.byte %████████
.byte %█__███__
.byte %█__█_█__
.byte %█__█_█__
.byte %█_______
.byte %██__█__█
.byte %████████

.byte %████████
.byte %████████
.byte %█__██__█
.byte %██____██
.byte %███__███
.byte %██____██
.byte %█__██__█
.byte %████████

.byte %████████
.byte %████████
.byte %█__██__█
.byte %█__██__█
.byte %█__██__█
.byte %██_____█
.byte %█████__█
.byte %██____██

.byte %████████
.byte %████████
.byte %█______█
.byte %████__██
.byte %███__███
.byte %██__████
.byte %█______█
.byte %████████
; These are taken from CP850 and inverted
.byte %████___█
.byte %███__███
.byte %███__███
.byte %█___████
.byte %███__███
.byte %███__███
.byte %████___█
.byte %████████

.byte %███__███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %███__███
.byte %████████

.byte %█___████
.byte %███__███
.byte %███__███
.byte %████___█
.byte %███__███
.byte %███__███
.byte %█___████
.byte %████████

.byte %█___█__█
.byte %__█___██
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████
; This is based on 0x7F, which is non-printable
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████
.byte %████████

;
; A0
;
; | ¡¢£€¥Š§š©ª«¬ ®¯|
; |°±²³Žµ¶·ž¹º»ŒœŸ¿|

; NBSP
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
; ¡ (CP850 AD)
.byte %___██___
.byte %________
.byte %___██___
.byte %___██___
.byte %__████__
.byte %__████__
.byte %___██___
.byte %________
; ¢ (CP850 BD)
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %██______
.byte %██______
.byte %_██████_
.byte %___██___
.byte %___██___
; £ (PXLfont)
.byte %________
.byte %___███__
.byte %__██__█_
.byte %__██____
.byte %_████___
.byte %__██____
.byte %_██████_
.byte %________
; € (created from scratch)
.byte %___████_
.byte %__██__██
.byte %_████___
.byte %__██____
.byte %_████___
.byte %__██__██
.byte %___████_
.byte %________
; ¥ (CP850 BE)
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %_██████_
.byte %___██___
.byte %_██████_
.byte %___██___
.byte %___██___
; Š (based on PXLfont)
.byte %_██__██_
.byte %__████__
.byte %_██_____
.byte %_████___
.byte %___████_
.byte %_____██_
.byte %_█████__
.byte %________
; § (CP850 15)
.byte %__█████_
.byte %_██____█
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %█____██_
.byte %_█████__
; š (based on PXLfont)
.byte %_██__██_
.byte %___██___
.byte %__████__
.byte %_██_____
.byte %_██████_
.byte %_____██_
.byte %_█████__
.byte %________
; © (CP850 B8)
.byte %_██████_
.byte %█______█
.byte %█__███_█
.byte %█_█____█
.byte %█_█____█
.byte %█__███_█
.byte %█______█
.byte %_██████_
; ª (created from scratch)
.byte %__█████_
.byte %_██__██_
.byte %__█████_
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
; « (CP850 AE)
.byte %________
.byte %__██__██
.byte %_██__██_
.byte %██__██__
.byte %_██__██_
.byte %__██__██
.byte %________
.byte %________
; ¬ (based on CP850 AA)
.byte %________
.byte %________
.byte %________
.byte %_██████_
.byte %_____██_
.byte %_____██_
.byte %________
.byte %________
; SHY (nonprintable)
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
; ® (CP850 A9)
.byte %_██████_
.byte %█______█
.byte %█_███__█
.byte %█_█__█_█
.byte %█_███__█
.byte %█_█__█_█
.byte %█______█
.byte %_██████_
; ¯ (CP850 EE)
.byte %████████
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
.byte %________
; ° (CP850 F8)
.byte %__███___
.byte %_██_██__
.byte %_██_██__
.byte %__███___
.byte %________
.byte %________
.byte %________
.byte %________
; ± (CP850 F1)
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %___██___
.byte %___██___
.byte %________
.byte %_██████_
.byte %________
; ² (CP850 FD)
.byte %_████___
.byte %____██__
.byte %___██___
.byte %__██____
.byte %_█████__
.byte %________
.byte %________
.byte %________
; ³ (CP850 FC)
.byte %_████___
.byte %____██__
.byte %__███___
.byte %____██__
.byte %_████___
.byte %________
.byte %________
.byte %________
; Ž (based on PXLfont)
.byte %_██__██_
.byte %_██████_
.byte %____██__
.byte %___██___
.byte %__██____
.byte %_██_____
.byte %_██████_
.byte %________
; µ (CP850 E6)
.byte %________
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %██______
; ¶ (CP850 F4)
.byte %_███████
.byte %██_██_██
.byte %██_██_██
.byte %_████_██
.byte %___██_██
.byte %___██_██
.byte %___██_██
.byte %________
; · (CP850 FA)
.byte %________
.byte %________
.byte %________
.byte %___██___
.byte %________
.byte %________
.byte %________
.byte %________
; ž (based on PXLfont)
.byte %_██__██_
.byte %___██___
.byte %_██████_
.byte %____██__
.byte %___██___
.byte %__██____
.byte %_██████_
.byte %________
; ¹ (CP850 FB)
.byte %___██___
.byte %__███___
.byte %___██___
.byte %___██___
.byte %__████__
.byte %________
.byte %________
.byte %________
; º (based on CP850 A7, but one pixel higher)
.byte %__███___
.byte %_██_██__
.byte %_██_██__
.byte %_██_██__
.byte %__███___
.byte %________
.byte %________
.byte %________
; » (CP850 AF)
.byte %________
.byte %██__██__
.byte %_██__██_
.byte %__██__██
.byte %_██__██_
.byte %██__██__
.byte %________
.byte %________
; Œ (created from scratch)
.byte %________
.byte %__█████_
.byte %_██_██__
.byte %_██_███_
.byte %_██_██__
.byte %_██_██__
.byte %__█████_
.byte %________
; œ (created from scratch)
.byte %________
.byte %________
.byte %__█████_
.byte %_█_██_██
.byte %_█_█████
.byte %_█_██___
.byte %__█████_
.byte %________
; Ÿ (CP850 98)
.byte %_██__██_
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %___██___
.byte %___██___
.byte %________
; ¿ (CP850 A8)
.byte %___██___
.byte %________
.byte %___██___
.byte %___██___
.byte %__██____
.byte %_██___██
.byte %__█████_
.byte %________

;
; C0
;
; |ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ|
; |ÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß|

; À (based on PXLfont and CP850 B7)
.byte %___██___
.byte %____██__
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██__██_
.byte %_██__██_
.byte %________
; Á (based on PXLfont and CP850 B5)
.byte %___██___
.byte %__██____
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██__██_
.byte %_██__██_
.byte %________
; Â (based on PXLfont and CP850 B6)
.byte %__████__
.byte %_█____█_
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██__██_
.byte %_██__██_
.byte %________
; Ã (based on PXLfont and CP850 C7)
.byte %_███_██_
.byte %██_███__
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██__██_
.byte %_██__██_
.byte %________
; Ä (based on PXLfont and CP850 8E)
.byte %_██__██_
.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██__██_
.byte %_██__██_
.byte %________
; Å (based on PXLfont and CP850 8F)
.byte %__███___
.byte %_██_██__
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██__██_
.byte %_██__██_
.byte %________
; Æ (CP850 92)
.byte %__█████_
.byte %_██_██__
.byte %██__██__
.byte %███████_
.byte %██__██__
.byte %██__██__
.byte %██__███_
.byte %________
; Ç (based on PXLfont and CP850 80)
.byte %________
.byte %__█████_
.byte %_██_____
.byte %_██_____
.byte %_██_____
.byte %__█████_
.byte %____██__
.byte %_████___
; È (based on PXLfont and CP850 D4)
.byte %__██____
.byte %___██___
.byte %_██████_
.byte %_██_____
.byte %_█████__
.byte %_██_____
.byte %_██████_
.byte %________
; É (based on PXLfont and CP850 90)
.byte %___██___
.byte %__██____
.byte %_██████_
.byte %_██_____
.byte %_█████__
.byte %_██_____
.byte %_██████_
.byte %________
; Ê (based on PXLfont and CP850 D2)
.byte %__████__
.byte %_█____█_
.byte %_██████_
.byte %_██_____
.byte %_█████__
.byte %_██_____
.byte %_██████_
.byte %________
; Ë (based on PXLfont and CP850 D3)
.byte %_██__██_
.byte %________
.byte %_██████_
.byte %_██_____
.byte %_█████__
.byte %_██_____
.byte %_██████_
.byte %________
; Ì (CP850 DE)
.byte %__██____
.byte %___██___
.byte %__████__
.byte %___██___
.byte %___██___
.byte %___██___
.byte %__████__
.byte %________
; Í (CP850 D6)
.byte %____██__
.byte %___██___
.byte %__████__
.byte %___██___
.byte %___██___
.byte %___██___
.byte %__████__
.byte %________
; Î (CP850 D7)
.byte %__████__
.byte %_█____█_
.byte %__████__
.byte %___██___
.byte %___██___
.byte %___██___
.byte %__████__
.byte %________
; Ï (CP850 D8)
.byte %_██__██_
.byte %________
.byte %__████__
.byte %___██___
.byte %___██___
.byte %___██___
.byte %__████__
.byte %________
; Ð (based on PXLfont)
.byte %________
.byte %_█████__
.byte %_██__██_
.byte %████_██_
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %________
; Ñ (based on PXLfont and CP850 A5)
.byte %_███_██_
.byte %██_███__
.byte %_██__██_
.byte %_███_██_
.byte %_██████_
.byte %_██_███_
.byte %_██__██_
.byte %________
; Ò (based on PXLfont and CP850 E3)
.byte %____██__
.byte %_____██_
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; Ó (based on PXLfont and CP850 E0)
.byte %__██____
.byte %_██_____
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; Ô (based on PXLfont and CP850 E2)
.byte %__████__
.byte %_█____█_
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; Õ (based on PXLfont and CP850 E5)
.byte %_███_██_
.byte %██_███__
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; Ö (based on CP437 99)
.byte %██____██
.byte %___██___
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %___██___
.byte %________
; × (CP850 9E); TODO: should not use left column
.byte %________
.byte %██___██_
.byte %_██_██__
.byte %__███___
.byte %_██_██__
.byte %██___██_
.byte %________
.byte %________
; Ø (based on PXLfont)
.byte %________
.byte %__████__
.byte %_██__███
.byte %_██_███_
.byte %_███_██_
.byte %███__██_
.byte %__████__
.byte %________
; Ù (based on PXLfont and CP850 EB)
.byte %_██_____
.byte %__██____
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; Ú (based on PXLfont and based on PXLfont and CP850 E9)
.byte %___██___
.byte %__██____
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; Û (CP850 EA)
.byte %_█████__
.byte %█_____█_
.byte %________
.byte %██___██_
.byte %██___██_
.byte %██___██_
.byte %_█████__
.byte %________
; Ü (based on PXLfont and CP850 9A)
.byte %_██__██_
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; Ý (CP850 ED)
.byte %____██__
.byte %___██___
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %___██___
.byte %___██___
.byte %________
; Þ (CP850 E7): TODO
.byte %███_____
.byte %_██_____
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %_█████__
.byte %_██_____
.byte %████____
; ß (created from scratch)
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██_██__
.byte %_██__██_
.byte %_██__██_
.byte %_██_██__
.byte %_██_____


;
; E0
;
; |àáâãäåæçèéêëìíîï|
; |ðñòóôõö÷øùúûüýþÿ|

; à (based on PXLfont and CP850 85)
.byte %__██____
.byte %___██___
.byte %__████__
.byte %_____██_
.byte %__█████_
.byte %_██__██_
.byte %__█████_
.byte %________
; á (based on PXLfont and CP850 A0)
.byte %___██___
.byte %__██____
.byte %__████__
.byte %_____██_
.byte %__█████_
.byte %_██__██_
.byte %__█████_
.byte %________
; â (based on PXLfont and CP850 83)
.byte %__████__
.byte %_█____█_
.byte %__████__
.byte %_____██_
.byte %__█████_
.byte %_██__██_
.byte %__█████_
.byte %________
; ã (based on PXLfont and CP850 C6)
.byte %_███_██_
.byte %██_███__
.byte %_█████__
.byte %_____██_
.byte %_██████_
.byte %██___██_
.byte %_██████_
.byte %________
; ä (based on PXLfont and CP850 84)
.byte %_██__██_
.byte %________
.byte %__████__
.byte %_____██_
.byte %__█████_
.byte %_██__██_
.byte %__█████_
.byte %________
; å (based on PXLfont and CP850 86)
.byte %___███__
.byte %___█_█__
.byte %__████__
.byte %_____██_
.byte %__█████_
.byte %_██__██_
.byte %__█████_
.byte %________
; æ (CP850 91): TODO
.byte %________
.byte %________
.byte %_██████_
.byte %___█__█_
.byte %███████_
.byte %█__█____
.byte %███████_
.byte %________
; ç (based on PXLfont and CP850 87)
.byte %________
.byte %________
.byte %__█████_
.byte %_██_____
.byte %_██_____
.byte %__█████_
.byte %____██__
.byte %__███___
; è (based on PXLfont and CP850 8A)
.byte %__██____
.byte %___██___
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██_____
.byte %__████__
.byte %________
; é (based on PXLfont and CP850 82)
.byte %____██__
.byte %___██___
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██_____
.byte %__████__
.byte %________
; ê (based on PXLfont and CP850 88)
.byte %__████__
.byte %_█____█_
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██_____
.byte %__████__
.byte %________
; ë (based on PXLfont and CP850 89)
.byte %_██__██_
.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██████_
.byte %_██_____
.byte %__████__
.byte %________
; ì (based on PXLfont and CP850 8D)
.byte %__██____
.byte %___██___
.byte %________
.byte %_████___
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %________
; í (based on PXLfont and CP850 A1)
.byte %____██__
.byte %___██___
.byte %________
.byte %_████___
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %________
; î (based on PXLfont and CP850 8C)
.byte %_█████__
.byte %█_____█_
.byte %_████___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %________
; ï (based on PXLfont and CP850 8B)
.byte %_██__██_
.byte %________
.byte %_████___
.byte %___██___
.byte %___██___
.byte %___██___
.byte %_██████_
.byte %________
; ð (CP850 D0): TODO
.byte %__██____
.byte %_██████_
.byte %____██__
.byte %_█████__
.byte %██__██__
.byte %██__██__
.byte %_████___
.byte %________
; ñ (based on PXLfont and CP850 A4)
.byte %_███_██_
.byte %██_███__
.byte %________
.byte %_█████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %________
; ò (based on PXLfont and CP850 95)
.byte %__██____
.byte %___██___
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; ó (based on PXLfont and CP850 A2)
.byte %____██__
.byte %___██___
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; ô (based on PXLfont and CP850 93)
.byte %__████__
.byte %_█____█_
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; õ (based on PXLfont and CP850 E4)
.byte %_███_██_
.byte %██_███__
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; ö (based on PXLfont and CP850 94)
.byte %_██__██_
.byte %________
.byte %__████__
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__████__
.byte %________
; ÷ (CP850 F6)
.byte %________
.byte %___██___
.byte %________
.byte %_██████_
.byte %________
.byte %___██___
.byte %________
.byte %________
; ø (CP850 9B)
.byte %________
.byte %_____██_
.byte %__████__
.byte %_██_███_
.byte %_███_██_
.byte %_███_██_
.byte %__████__
.byte %_██_____
; ù (CP850 97)
.byte %__██____
.byte %___██___
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %________
; ú (CP850 A3)
.byte %____██__
.byte %___██___
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %________
; û (CP850 96)
.byte %__████__
.byte %_█____█_
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %________
; ü (CP850 81)
.byte %_██__██_
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %________
; ý (CP850 EC)
.byte %____██__
.byte %___██___
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %_____██_
.byte %__████__
; þ (CP850 E8): TODO
.byte %████____
.byte %_██_____
.byte %_█████__
.byte %_██__██_
.byte %_█████__
.byte %_██_____
.byte %████____
.byte %________
; ÿ (CP850 98)
.byte %_██__██_
.byte %________
.byte %_██__██_
.byte %_██__██_
.byte %_██__██_
.byte %__█████_
.byte %_____██_
.byte %__████__
