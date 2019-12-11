; Commander X16 KERNAL
;
; Graphics library

.include "../../mac.inc"
.include "../../regs.inc"
.include "graph.inc"

.setcpu "65c02"

.import col1, col2, col_bg; [declare]

.import leftMargin, windowTop, rightMargin, windowBottom

.import GRAPH_LL_get_info
.import GRAPH_LL_cursor_position
.import GRAPH_LL_get_pixel
.import GRAPH_LL_get_pixels
.import GRAPH_LL_set_pixel
.import GRAPH_LL_set_pixels
.import GRAPH_LL_set_8_pixels
.import GRAPH_LL_set_8_pixels_opaque
.import GRAPH_LL_fill_pixels
.import GRAPH_LL_filter_pixels
.import GRAPH_LL_move_pixels

.segment "GRAPH"

.include "color.s"
.include "line.s"
.include "point.s"
.include "rect.s"
.include "scanline.s"
