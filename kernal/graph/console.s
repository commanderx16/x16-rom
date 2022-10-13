.export console_get_char
.export console_init
.export console_put_char
.export console_put_image
.export console_set_paging_message

.import jsrfar
.include "banks.inc"
.include "graphics.inc"

.segment "GRAPH"
console_get_char:
    jsr jsrfar
    .word gr_console_get_char
    .byte BANK_GRAPH
    rts
  
console_init:
    jsr jsrfar
    .word gr_console_init
    .byte BANK_GRAPH
    rts
  
console_put_char:
    jsr jsrfar
    .word gr_console_put_char
    .byte BANK_GRAPH
    rts
  
console_put_image:
    jsr jsrfar
    .word gr_console_put_image
    .byte BANK_GRAPH
    rts
  
console_set_paging_message:
    jsr jsrfar
    .word gr_console_set_paging_message
    .byte BANK_GRAPH
    rts