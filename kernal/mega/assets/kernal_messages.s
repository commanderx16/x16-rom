;
; Messages to be prined out by Kernal
;

.encoding "petscii_upper"


; Double underscore prevents labels from being passed to VICE (would confuse monitor)

.label __MSG_KERNAL_SEARCHING_FOR      = __msg_kernalsearching_for      - __msg_kernal_first
.label __MSG_KERNAL_LOADING            = __msg_kernalloading            - __msg_kernal_first
.label __MSG_KERNAL_VERIFYING          = __msg_kernalverifying          - __msg_kernal_first
.label __MSG_KERNAL_SAVING             = __msg_kernalsaving             - __msg_kernal_first
.label __MSG_KERNAL_FROM_HEX           = __msg_kernalfrom_hex           - __msg_kernal_first
.label __MSG_KERNAL_TO_HEX             = __msg_kernalto_hex             - __msg_kernal_first

__msg_kernal_first:

__msg_kernalsearching_for:
	.byte $0D
	.text "SEARCHING FOR"
	.byte $80 + $20 ; end of string mark + space

__msg_kernalloading:
	.byte $0D
	.text "LOADIN"
	.byte $80 + $47 ; end of string mark + 'G'

__msg_kernalverifying:
	.byte $0D
	.text "VERIFYIN"
	.byte $80 + $47 ; end of string mark + 'G'

__msg_kernalsaving:
	.byte $0D
	.text "SAVING"
	.byte $80 + $20 ; end of string mark + space

__msg_kernalfrom_hex:
	.text " FROM "
	.byte $80 + $24 ; end of string mark + '$'

__msg_kernalto_hex:
	.text " TO "
	.byte $80 + $24 ; end of string mark + '$'
