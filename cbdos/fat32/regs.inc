.include "../vera.inc"

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

;-----------------------------------------------------------------------------
; errno
;-----------------------------------------------------------------------------
ERRNO_OK               = 0
ERRNO_READ             = 1
ERRNO_WRITE            = 2
ERRNO_ILLEGAL_FILENAME = 3
ERRNO_FILE_EXISTS      = 4
ERRNO_FILE_NOT_FOUND   = 5
ERRNO_DIR_NOT_EMPTY    = 6
ERRNO_NO_MEDIA         = 7
ERRNO_NO_FS            = 8
ERRNO_FS_INCONSISTENT  = 9
ERRNO_WRITE_PROTECT_ON = 10

;-----------------------------------------------------------------------------
; Register bits
;-----------------------------------------------------------------------------
SPI_CTRL_SELECT_SDCARD = $01
SPI_CTRL_SELECT_MASK   = $01
SPI_CTRL_SLOWCLK       = $02
SPI_CTRL_AUTOTX        = $08
SPI_CTRL_BUSY          = $80
