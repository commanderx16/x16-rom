;-----------------------------------------------------------------------------
; Zero-page kernel variables
;-----------------------------------------------------------------------------
fat32_bufptr = $F2      ; word - Internally used by FAT32 code
fat32_ptr    = $F4      ; word - Buffer pointer to various functions
fat32_ptr2   = $F6      ; word - Buffer pointer to various functions
SRC_PTR      = $F8      ; 3 bytes
DST_PTR      = $FB      ; 3 bytes
LENGTH       = $FE      ; word

;-----------------------------------------------------------------------------
; Registers
;-----------------------------------------------------------------------------
VRAM_BASE     = $0200
SPRITE_IDX    = $0300
SPRITE_ATTR   = $0320
SPRITE_X_L    = $0340
SPRITE_X_H    = $0360
SPRITE_Y      = $0380
PSG_FWL       = $03A0
PSG_FWH       = $03A8
PSG_VOL       = $03B0
PSG_WAVEFORM  = $03B8
PALETTE0_BASE = $03C0
PALETTE1_BASE = $03E0
IEN           = $0400
ISR           = $0401
SYSCTRL       = $0402
VID_CTRL      = $0403
VID_IRQLINE   = $0404
VID_RAMBANK   = $0405
VID_SCRX_L    = $0406
VID_SCRX_H    = $0407
VID_SCRY_L    = $0408
VID_SCRY_H    = $0409
SPI_CTRL      = $040A
SPI_DATA      = $040B
PCM_CTRL      = $040C
PCM_RATE      = $040D
PCM_DATA      = $040E
USB_PORT1     = $040F
USB_PORT2     = $0410
USB_STATUS    = $0411
USB_XFER      = $0412
USB_FIFO      = $0413
DBG_STATUS    = $0414
DBG_DATA      = $0415
WIFI_STATUS   = $0416
WIFI_DATA     = $0417

RAM_START      = $0418
USER_RAM_START = $0A00
KERNEL_START   = $D800

VEC_NMI   = $FFFA
VEC_RESET = $FFFC
VEC_IRQ   = $FFFE

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
FAT32_CONTEXTS = 8

mouse_updated          = $6CA
mouse_x                = $6CB  ; signed 16-bit value
mouse_y                = $6CD  ; signed 16-bit value
mouse_scroll           = $6CF
mouse_buttons          = $6D0
mouse_buttons_pressed  = $6D1
mouse_buttons_released = $6D2
sdcard_param           = $6D3  ; 6 bytes
sector_lba             = $6D4  ; dword (part of sdcard_param) - LBA of sector to read/write
fat32_size             = $6D9  ; dword - Used for fat32_get_free_space result
fat32_cwd_cluster      = $6DD  ; dword - Cluster of current directory
fat32_dirent           = $6E1  ; 22 bytes - Buffer containing decoded directory entry
val32                  = $6F7  ; dword
padch                  = $6FB  ; byte
text_color             = $6FC
cancelled              = $6FD
line_idx               = $6FE
line_len               = $6FF
line_buf               = $700  ; 256 bytes
sector_buffer          = $800
sector_buffer_end      = $A00

;-----------------------------------------------------------------------------
; Register bits
;-----------------------------------------------------------------------------
ISR_VBLANK        = $01
ISR_LINE          = $02
ISR_USB_XFER_DONE = $04
ISR_USB_SOF       = $08
ISR_DBG_RXFIFO    = $10
ISR_WIFI_RXFIFO   = $20

IEN_VBLANK        = $01
IEN_LINE          = $02
IEN_USB_XFER_DONE = $04
IEN_USB_SOF       = $08
IEN_DBG_RXFIFO    = $10
IEN_WIFI_RXFIFO   = $20

USB_STATUS_RX_CRC16_OK = $01
USB_STATUS_TIMEOUT     = $02
USB_STATUS_BUSY        = $40
USB_STATUS_RXFNE       = $80

SPI_CTRL_SELECT_SDCARD = $01
SPI_CTRL_SELECT_FLASH  = $02
SPI_CTRL_SELECT_MASK   = $03
SPI_CTRL_SLOWCLK       = $04
SPI_CTRL_AUTOTX        = $08
SPI_CTRL_BUSY          = $80
