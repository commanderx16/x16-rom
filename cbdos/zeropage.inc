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
.ifndef _ZEROPAGE_INC_ 
  _ZEROPAGE_INC_=1
  
; already defined in cc65 zeropage.inc
.globalzp ptr1, ptr2, ptr3, ptr4
.globalzp tmp1, tmp2, tmp3, tmp4

.globalzp vdp_ptr, vdp_tmp

; INIT0/SHELL

; shell related - TODO FIXME away from kernel stuff, conflicts with basic. but after basic start, we dont care about shell zp. maybe if we want to return to shell one day !!!
cmdptr		= $d6
paramptr	= $d8
retvec 		= $da

; GENERAL
addr    = $e0
adrl    = addr
adrh    = addr+1
; TEXTUI
crs_ptr = $e2
crs_x   = $028c
crs_y   = $028d

; OUT
msgptr  	= $e4		; 2 bytes

; kernel pointer (internally used)
krn_ptr1    	= $e6	; 2 bytes
krn_ptr2    	= $e8	; 2 bytes
krn_ptr3    	= $ea	; 2 bytes

krn_tmp     	= $ec		; 16 bit tmp
krn_tmp2		= krn_tmp+1	; single byte
krn_tmp3		= krn_tmp+2	; single byte

; FAT32
filenameptr 		= $f0   ; 2 byte
dirptr 	    		= $f2 	; 2 byte

; SDCARD/storage block pointer
read_blkptr  		= $f4
write_blkptr 		= $f6
sd_tmp	     		= $f8
ansi_state          = $f9
ansi_index          = $fa
ansi_param1         = $fb
ansi_param2         = $fc

lba_addr 			= $0280		; 4 bytes
blocks				= $0284		; 3 bytes blocks to read, 3 bytes sufficient to address 4GB -> 4294967296 >> 9 = 8388608 ($800000) max blocks/file
SYS_IRR				= $0287		; system interrupt request register - kernel collects all IRQ's of the various hardware and stores them so app's are able to identify thich kind of irq was requested
	IRQ_VDP			= 1<<7		; irq from video chip
	IRQ_SND			= 1<<6		; irq from sound card (ym3812)
	IRQ_VIA			= 1<<5		; irq from VIA (6522)
	IRQ_IO0			= 1<<4		; i/o port 0
	;...

max_cols      = $0288   ; 80 columns mode, 40 columns otherwise

trampolin     = $0010

.endif