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

.ifndef __DEBUG_INC
.define	__DEBUG_INC "__DEBUG_INC"

.import _debugout, _debugout8, _debugout16, _debugout32
.import _debugout32p
.import _debugdump
.import _debugdirentry

.macro debugdirentry
.if .defined(debug_enabled)
	jsr _debugdirentry
	.byte 0
.endif
.endmacro

.macro debug msg
.if .defined(debug_enabled)
		jsr	_debugout
		.asciiz msg
.endif
.endmacro

.macro debug8 msg, ptr
.if .defined(debug_enabled)
		jsr	_debugout8
		.word ptr
		.asciiz msg
.endif
.endmacro

.macro debug16 msg, ptr
.if .defined(debug_enabled)
		jsr	_debugout16
		.word ptr
		.asciiz msg
.endif
.endmacro

.macro debug32 msg, addr
.if .defined(debug_enabled)
		jsr	_debugout32
		.word addr
		.asciiz msg
.endif
.endmacro

.macro debugdump msg, addr
.if .defined(debug_enabled)
		jsr _debugdump
		.word addr
		.asciiz msg
.endif
.endmacro

.macro debugdumpptr msg, ptr
.if .defined(debug_enabled)
		jsr _debugdump
		.word ptr
		.asciiz msg
.endif
.endmacro

.endif
