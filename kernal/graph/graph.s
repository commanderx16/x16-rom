; Commander X16 KERNAL
;
; Graphics library

.include "../../mac.inc"
.include "../../regs.inc"
.include "../../io.inc"
.include "graph.inc"

.setcpu "65c02"

.import col1, col2, col_bg, k_dispBufferOn; [declare]
.importzp ptr_fg, ptr_bg

.import leftMargin, windowTop, rightMargin, windowBottom

.segment "GRAPH"

.include "color.s"
.include "line.s"
.include "point.s"
.include "rect.s"
.include "scanline.s"
.include "vera320x200x256.s"
