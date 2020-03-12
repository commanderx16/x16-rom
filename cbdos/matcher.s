; MIT License
;
; Copyright (c) 2018 Thomas Woinke, Marko Lauke, www.steckschwein.de
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
.importzp dirptr
.include	"fat32.inc"

.import fat_dirname_mask

.export dirname_mask_matcher

.code
; 	match input name[.[ext]] (8.3 filename) against 11 byte dir entry <name><ext>
;	note:
;		*.*	- matches any file or directory with extension
;		*	- matches any file or directory without extension
; in:
;	dirptr - pointer to dir entry (F32DirEntry)
; out:
;	C=1 on match, C=0 otherwise
dirname_mask_matcher:
		ldy #.sizeof(F32DirEntry::Name) + .sizeof(F32DirEntry::Ext) - 1
__dmm:
		lda fat_dirname_mask, y
		cmp #'?'
		beq __dmm_next
		cmp (dirptr), y
		bne __dmm_neq
__dmm_next:
		dey
		bpl __dmm
		rts ;exit, C=! here from cmp above
__dmm_neq:
		clc
		rts
