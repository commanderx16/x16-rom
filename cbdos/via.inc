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
via2        = $9f70
via2porta   = via2+1
via2portb   = via2
via2ddrb    = via2+2
via2ddra    = via2+3
via2t1cl    = via2+4
via2t1ch    = via2+5
via2t2cl    = via2+8
via2t2ch    = via2+9
via2sr      = via2 + $0a
via2acr     = via2 + $0b
via2pcr     = via2 + $0c
via2ifr     = via2 + $0d
via2ier     = via2 + $0e

SDCARD_WRITE_PROTECT  = 1<<5
SDCARD_DETECT         = 1<<6

.endif
