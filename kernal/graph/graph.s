
.include "../../mac.inc"
.include "../../regs.inc"
.include "../../io.inc"
.include "graph.inc"

.setcpu "65c02"

.import k_col1, k_col2, k_col_bg, k_dispBufferOn; [declare]

.segment "GRAPH"

.include "color.s"
.include "line.s"
.include "math.s"
.include "point.s"
.include "rect.s"
.include "scanline.s"
