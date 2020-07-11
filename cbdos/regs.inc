.include "vera.inc"

.importzp fat32_bufptr, fat32_ptr, fat32_ptr2

;-----------------------------------------------------------------------------
; Registers
;-----------------------------------------------------------------------------
SPI_CTRL      = VERA_SPI_CTRL
SPI_DATA      = VERA_SPI_DATA

;-----------------------------------------------------------------------------
; Kernel variables
;-----------------------------------------------------------------------------
.struct dirent
name       .res 13
attributes .byte
size       .dword
cluster    .dword
.endstruct

; Maximum number of open files
; Optionally, fat32_alloc_context / fat32_free_context can be used to manage contexts
FAT32_CONTEXTS = 4

sdcard_param        = $414  ; 6 bytes
sector_lba          = $415  ; dword (part of sdcard_param) - LBA of sector to read/write
fat32_size          = $41A  ; dword - Used for fat32_get_free_space result
fat32_cwd_cluster   = $41E  ; dword - Cluster of current directory
fat32_dirent        = $422  ; 22 bytes - Buffer containing decoded directory entry
sector_buffer       = $600
sector_buffer_end   = $800

;-----------------------------------------------------------------------------
; Register bits
;-----------------------------------------------------------------------------
SPI_CTRL_SELECT_SDCARD = $01
SPI_CTRL_SELECT_FLASH  = $02
SPI_CTRL_SELECT_MASK   = $03
SPI_CTRL_SLOWCLK       = $04
SPI_CTRL_AUTOTX        = $08
SPI_CTRL_BUSY          = $80
