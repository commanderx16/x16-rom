; empty space in the KERNAL zeropage
cbdos_zp = $df

krn_ptr1     = cbdos_zp + 0 ; 2 bytes
krn_ptr2     = cbdos_zp + 2 ; 2 bytes
krn_ptr3     = cbdos_zp + 4 ; 2 bytes
filenameptr  = cbdos_zp + 6 ; 2 bytes
dirptr       = cbdos_zp + 8 ; 2 bytes
read_blkptr  = cbdos_zp + 10 ; 2 bytes
write_blkptr = cbdos_zp + 12 ; 2 bytes
buffer       = cbdos_zp + 14 ; 2 bytes

bank_save = $a4 ; shared with KERNAL "bsour1", used by IEC
