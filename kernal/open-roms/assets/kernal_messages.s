;
; Messages to be prined out by Kernal
;

; Double underscore prevents labels from being passed to VICE (would confuse monitor)

__MSG_KERNAL_SEARCHING_FOR      = __msg_kernalsearching_for      - __msg_kernal_first
__MSG_KERNAL_LOADING            = __msg_kernalloading            - __msg_kernal_first
__MSG_KERNAL_VERIFYING          = __msg_kernalverifying          - __msg_kernal_first
__MSG_KERNAL_SAVING             = __msg_kernalsaving             - __msg_kernal_first
__MSG_KERNAL_FROM_HEX           = __msg_kernalfrom_hex           - __msg_kernal_first
__MSG_KERNAL_TO_HEX             = __msg_kernalto_hex             - __msg_kernal_first

__msg_kernal_first:

__msg_kernalsearching_for:
	.byte $0D
	.byte "SEARCHING FOR"
	.byte $80 + $20 ; end of string mark + space

__msg_kernalloading:
	.byte $0D
	.byte "LOADIN"
	.byte $80 + $47 ; end of string mark + 'G'

__msg_kernalverifying:
	.byte $0D
	.byte "VERIFYIN"
	.byte $80 + $47 ; end of string mark + 'G'

__msg_kernalsaving:
	.byte $0D
	.byte "SAVING"
	.byte $80 + $20 ; end of string mark + space

__msg_kernalfrom_hex:
	.byte " FROM "
	.byte $80 + $24 ; end of string mark + '$'

__msg_kernalto_hex:
	.byte " TO "
	.byte $80 + $24 ; end of string mark + '$'
