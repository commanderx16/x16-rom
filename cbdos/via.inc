; MIT License
;
; Copyright (c) 2018 Thomas Woinke, Marko Lauke, www.steckschein.de
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
.ifndef _VIA_INC_
  _VIA_INC_=1

; VIA address and registers
via1        = $0210
via1porta   = via1+1
via1portb   = via1
via1ddrb    = via1+2
via1ddra    = via1+3
via1t1cl    = via1+4
via1t1ch    = via1+5
via1t2cl    = via1+8
via1t2ch    = via1+9
via1sr      = via1 + $0a
via1acr     = via1 + $0b
via1pcr     = via1 + $0c
via1ifr     = via1 + $0d
via1ier     = via1 + $0e

SDCARD_WRITE_PROTECT  = 1<<5
SDCARD_DETECT         = 1<<6

.endif
