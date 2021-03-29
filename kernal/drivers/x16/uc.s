.segment "I2C"

.import _i2cStart, _i2cStop, _i2cWrite

.export set_power_led, set_activity_led

uc_address = $42 * 2

set_power_led:
	pha
	jsr _i2cStart
	lda #uc_address
	jsr _i2cWrite
	lda #4
	jsr _i2cWrite
	pla
	jsr _i2cWrite
	jmp _i2cStop

set_activity_led:
	pha
	jsr _i2cStart
	lda #uc_address
	jsr _i2cWrite
	lda #5
	jsr _i2cWrite
	pla
	jsr _i2cWrite
	jmp _i2cStop

