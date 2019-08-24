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

; adapted from ca65 errno.inc and extended

; Variables and functions

        .global         __errno, __oserror
        .global         __osmaperrno
        .global         __seterrno
        .global         __directerrno, __mappederrno

; Error codes, must match the values in the C headers
.enum
			EOK                     ; No error
			ENOENT                  ; No such file or directory
			ENOMEM                  ; Out of memory
			EACCES                  ; Permission denied
			ENODEV                  ; No such device
			EMFILE                  ; Too many open files
			EBUSY                   ; Device or resource busy
			EINVAL                  ; Invalid argument
			ENOSPC                  ; No space left on device
			EEXIST                  ; File exists
			EAGAIN                  ; Try again
			EIO                     ; I/O error
			EINTR                   ; Interrupted system call
			ENOSYS                  ; Function not implemented
			ESPIPE                  ; Illegal seek
			ERANGE                  ; Range error
			EBADF                   ; Bad file number
			ENOEXEC                 ; Exec format error

			EISDIR      			; Is a directory		; 0x12
			ENOTDIR     			; Not a directory		; 0x13
			ENOTEMPTY				; Directory not empty	; 0x14

			EUNKNOWN                ; Unknown OS specific error - must be last!

			EMAX    = EUNKNOWN      ; Highest error code
.endenum
