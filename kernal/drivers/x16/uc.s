.segment "I2C"

.import i2c_read_byte, i2c_write_byte

.export smc_set_power_led, smc_set_activity_led

uc_address = $42

smc_set_power_led:
	ldx #uc_address
	ldy #4
	jmp i2c_write_byte

smc_set_activity_led:
	ldx #uc_address
	ldy #5
	jmp i2c_write_byte
