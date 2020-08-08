.include "../vera.inc"

.importzp fat32_bufptr, fat32_lfn_bufptr, fat32_ptr, fat32_ptr2

;-----------------------------------------------------------------------------
; Registers
;-----------------------------------------------------------------------------
SPI_CTRL      = VERA_SPI_CTRL
SPI_DATA      = VERA_SPI_DATA

;-----------------------------------------------------------------------------
; Kernel variables
;-----------------------------------------------------------------------------
.struct dirent           ; FILE             PARTITION
name          .res 256   ; file name        partition name (if FAT32, else empty)
attributes    .byte      ; file attributes  partition type
start         .dword     ; start cluster    start LBA
size          .dword     ; size in bytes    size in sectors
mtime_year    .byte
mtime_month   .byte
mtime_day     .byte
mtime_hours   .byte
mtime_minutes .byte
mtime_seconds .byte
.endstruct

; Maximum number of open files
; Optionally, fat32_alloc_context / fat32_free_context can be used to manage contexts
FAT32_CONTEXTS = 4

; Maximum number of partitions
FAT32_VOLUMES = 4

;-----------------------------------------------------------------------------
; errno
;-----------------------------------------------------------------------------
ERRNO_OK               = 0
ERRNO_READ             = 1
ERRNO_WRITE            = 2
ERRNO_ILLEGAL_FILENAME = 3
ERRNO_FILE_EXISTS      = 4
ERRNO_FILE_NOT_FOUND   = 5
ERRNO_FILE_READ_ONLY   = 6
ERRNO_DIR_NOT_EMPTY    = 7
ERRNO_NO_MEDIA         = 8
ERRNO_NO_FS            = 9
ERRNO_FS_INCONSISTENT  = 10
ERRNO_WRITE_PROTECT_ON = 11
ERRNO_OUT_OF_RESOURCES = 12

;-----------------------------------------------------------------------------
; Register bits
;-----------------------------------------------------------------------------
SPI_CTRL_SELECT_SDCARD = $01
SPI_CTRL_SELECT_MASK   = $01
SPI_CTRL_SLOWCLK       = $02
SPI_CTRL_AUTOTX        = $08
SPI_CTRL_BUSY          = $80
