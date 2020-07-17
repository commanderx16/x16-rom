.global krn_ptr1, read_blkptr, buffer, bank_save
.global fat32_bufptr, fat32_ptr, fat32_ptr2

.segment "ZPCBDOS" : zeropage

; CBDOS
krn_ptr1:
	.res 2
read_blkptr:
	.res 2
bank_save:
	.res 1

; FAT 32
fat32_bufptr:
	.res 2 ; word - Internally used by FAT32 code
fat32_ptr:
	.res 2 ; word - Buffer pointer to various functions
fat32_ptr2:
	.res 2 ; word - Buffer pointer to various functions
