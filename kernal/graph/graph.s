
.include "../../mac.inc"
.include "../../regs.inc"
.include "../../io.inc"
.include "graph.inc"

.setcpu "65c02"

.import col1, col2, col_bg, k_dispBufferOn; [declare]
.importzp ptr_fg, ptr_bg

.segment "GRAPH"

.include "color.s"
.include "line.s"
.include "math.s"
.include "point.s"
.include "rect.s"
.include "scanline.s"
