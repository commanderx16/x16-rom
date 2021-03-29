;----------------------------------------------------------------------
; X16 System Management Controller Driver
;----------------------------------------------------------------------
; (C)2021 Michael Steil, License: 2-clause BSD

.segment "I2C"

.import i2c_write_byte

.export smc_set_activity_led

uc_address = $42

; 0x01 0x00      - Power Off
; 0x01 0x01      - Hard Reboot
; 0x02 0x00      - Reset Button Press
; 0x03 0x00      - NMI Button Press
; 0x04 0x00-0xFF - Power LED Level (PWM)
; 0x05 0x00-0xFF - Activity LED Level (PWM)

smc_set_activity_led:
	ldx #uc_address
	ldy #5
	jmp i2c_write_byte
