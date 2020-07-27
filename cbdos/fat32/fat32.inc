;-----------------------------------------------------------------------------
; fat32.inc
; Copyright (C) 2020 Frank van den Hoef
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Functions
;-----------------------------------------------------------------------------

; Global operations
.global fat32_init              ; Initialize FAT32 driver and SD card
.global fat32_alloc_context     ; Allocate context, result in A if C set
.global fat32_free_context      ; Free context in A, C set on success
.global fat32_set_context       ; Set current context to idx in A (0..FAT32_CONTEXTS-1)
.global fat32_get_context       ; Get current context, result in A
.global fat32_get_free_space    ; Get free space, result in KiB in fat32_size (32-bit)

; Directory operations
.global fat32_open_dir          ; Open directory with path in fat32_ptr
.global fat32_read_dirent       ; Read directory entry, result in fat32_dirent
.global fat32_read_dirent_filtered ; Same as above, but only matching names (fat32_ptr)
.global fat32_find_dirent       ; Find file with path in fat32_ptr in current directory

.global fat32_chdir             ; Change to directory with path in fat32_ptr
.global fat32_rename            ; Rename file with path in fat32_ptr to fat32_ptr2
.global fat32_set_attribute     ; Set attribute of file with path in fat32_ptr
.global fat32_delete            ; Delete file with path in fat32_ptr
.global fat32_mkdir             ; Create new directory with path in fat32_ptr
.global fat32_rmdir             ; Delete empty directory with path in fat32_ptr

; File operations
.global fat32_open              ; Open file with path in fat32_ptr
.global fat32_create            ; Create file with path in fat32_ptr (delete existing file)
.global fat32_close             ; Close file
.global fat32_read_byte         ; Read byte, result in A
.global fat32_read              ; Read fat32_size (16-bit) bytes to fat32_ptr
.global fat32_write_byte        ; Write byte in A
.global fat32_write             ; Write fat32_size (16-bit) bytes from fat32_ptr
.global fat32_get_offset        ; Get current file offset, result in fat32_size

.global fat32_size
.global fat32_dirent
.global sync_sector_buffer
.global fat32_errno

.global lba_partition
.global partition_type
.global partition_blocks

; debug
.global contexts_inuse

; TODO:
; fat32_seek

; Low level fast API
.global fat32_next_sector
