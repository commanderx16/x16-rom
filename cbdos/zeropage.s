.global krn_ptr1, krn_ptr2, krn_ptr3, filenameptr, dirptr, read_blkptr, write_blkptr, buffer, bank_save

.segment "ZPCBDOS" : zeropage

krn_ptr1:
	.res 2
krn_ptr2:
	.res 2
krn_ptr3:
	.res 2
filenameptr:
	.res 2
dirptr:
	.res 2
read_blkptr:
	.res 2
write_blkptr:
	.res 2
buffer:
	.res 2
bank_save:
	.res 1
