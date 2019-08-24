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


.ifdef DEBUG_FAT32 ; debug switch for this module
	debug_enabled=1
.endif

; TODO OPTIMIZATIONS
; 	1. __calc_lba_addr - check whether we can skip the cluster_begin adc if we can proof that the cluster_begin is a multiple of sec/cl. if so we can setup the lba_addr as a cluster number, we can safe one addition
;							  => a + (b * c) => with a = n * c => n * c + b * c => c * (n + b)
;  2. avoid fat block read - calculate fat lba address, but before reading a the fat block, compare the new lba_addr with the previously saved fat_lba 
;
;
.include "zeropage.inc"
.include "common.inc"
.include "fat32.inc"
.include "rtc.inc"
.include "errno.inc"	; from ca65 api
.include "fcntl.inc"	; from ca65 api

.include "debug.inc"

; external deps - block layer
.import read_block, write_block
; TODO FIXME - encapsulate within sd layer
.import sd_read_multiblock

.import __rtc_systime_update
.import string_fat_name, fat_name_string, put_char
.import string_fat_mask
.import dirname_mask_matcher, cluster_nr_matcher
.import path_inverse

.export fat_mount
.export fat_open, fat_chdir, fat_unlink
.export fat_mkdir, fat_rmdir
.export fat_read_block, fat_fread ; TODO FIXME update exec, use fat_fread
.export fat_read
.export fat_fseek
.export fat_find_first, fat_find_next, fat_write
.export fat_get_root_and_pwd
.export fat_close_all, fat_close, fat_getfilesize
.export inc_lba_address

;.ifdef TEST_EXPORT TODO FIXME - any ideas?
.export __fat_isOpen
.export __fat_alloc_fd
.export __calc_fat_lba_addr
.export __calc_lba_addr
.export __fat_isroot
.export __fat_init_fdarea
;.endif

.code

		;	seek n bytes within file denoted by the given FD
		;in:
		;	X	 - offset into fd_area
		;	A/Y - pointer to seek_struct - @see 
		;out:
		;	Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_fseek:
		rts
		
		;in:
		;	X	 - offset into fd_area
		;out:
		;	Z=1 on success (A=0), Z=0 and A=error code otherwise
__fat_fseek:
		;SetVector block_data, read_blkptr
		rts
		
    ; TODO FIXME currently until end of cluster is read
    ;
		;	read n blocks from file denoted by the given FD and maintains FD.offset
		;in:
		;	X - offset into fd_area
		;	Y - number of blocks to read at once - !!!NOTE!!! it's currently limited to $ff
		;	read_blkptr - address where the data of the read blocks should be stored
		;out:
		;	Z=1 on success (A=0), Z=0 and A=error code otherwise
		; 	Y - number of blocks which where successfully read
fat_fread:
		jsr __fat_isOpen
		bne @_l_read_start
		lda #EINVAL
		rts
@_l_read_start:
		sty krn_tmp3												; safe requested block number
		stz krn_tmp2												; init counter
@_l_read_loop:
		ldy krn_tmp2
		cpy krn_tmp3
		beq @l_exit_ok
		
		lda fd_area+F32_fd::offset+0,x
		cmp volumeID+VolumeID::BPB + BPB::SecPerClus  ; last block of cluster reached?
		bne @_l_read												          ; no, go on reading...
		
		copypointer read_blkptr, krn_ptr1					; backup read_blkptr
		jsr __fat_read_cluster_block_and_select		; read fat block of the current cluster
		bne @l_exit_err                           ; read error...
		bcs @l_exit                               ; EOC reached?	return ok, and block counter
		jsr __fat_next_cln                        ; select next cluster
		stz fd_area+F32_fd::offset+0,x            ; and reset offset within cluster		
		copypointer krn_ptr1, read_blkptr					; restore read_blkptr
		
@_l_read:
		jsr __calc_lba_addr
		jsr __fat_read_block
		bne @l_exit_err
		inc read_blkptr+1                     ; read address + $0200 (block size)
		inc read_blkptr+1
		inc fd_area+F32_fd::offset+0,x        ; inc block counter
		inc krn_tmp2
		bra @_l_read_loop
@l_exit:
		ldy krn_tmp2
@l_exit_ok:
		lda #EOK														; A=0 (EOK)
@l_exit_err:
		rts		


		;	@deprecated - use fat_read_blocks instead, just for backward compatibility
		;
		; read one block, TODO - update seek position within FD
		;in:
		;	X	- offset into fd_area
		;	read_blkptr has to be set to target address - TODO FIXME ptr. parameter
		;out:
		;	Z=1 on success (A=0), Z=0 and A=error code otherwise
		;  X	- number of bytes read
fat_read_block:
		jsr __fat_isOpen
		beq @l_err_exit

		jsr __calc_blocks
		jsr __calc_lba_addr
		jmp read_block
@l_err_exit:
		lda #EINVAL
		rts

		;in:
		;	X - offset into fd_area
		;out:
		;	Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_read:
		jsr __fat_isOpen
		beq @l_err_exit

		jsr __calc_blocks
		beq @l_exit					; if Z=0, no blocks to read. we return with "EOK", 0 bytes read
		jsr __calc_lba_addr
		jsr sd_read_multiblock
;		jsr read_block
		rts
@l_err_exit:
		lda #EINVAL
@l_exit:
		rts

		; in:
		;	X - offset into fd_area
		;	write_blkptr - set to the address with data we have to write
		; out:
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_write:
		debug "fws"
		stx fat_tmp_fd										; save fd

		jsr __fat_isOpen
		beq @l_not_open

		lda	fd_area + F32_fd::Attr, x
		bit #DIR_Attr_Mask_Dir								; regular file?
		beq @l_isfile
@l_not_open:
		lda #EINVAL
		bra @l_exit
@l_isfile:
		jsr __fat_isroot									; check whether the start cluster of the file is the root cluster - @see fat_alloc_fd, fat_open)
		bne	@l_write										; if not, we can directly update dir entry and write data afterwards

		saveptr write_blkptr								;
		jsr __fat_reserve_cluster							; otherwise start cluster is root, we try to find a free cluster, fat_tmp_fd has to be set
		bne @l_exit
		restoreptr write_blkptr								; restore write ptr
		;debug "fw1"
		ldx fat_tmp_fd										; restore fd, go on with writing data
@l_write:
		jsr __calc_blocks
		jsr __calc_lba_addr									; calc lba and blocks of file payload
.ifdef MULTIBLOCK_WRITE
.warning "SD multiblock writes are EXPERIMENTAL"
		.import sd_write_multiblock
		jsr sd_write_multiblock
.else
@l:
		jsr write_block
		bne @l_exit
		jsr inc_lba_address
		dec blocks
		bne @l
.endif
		ldx fat_tmp_fd										; restore fd
		jsr __fat_read_direntry

		jsr __fat_set_direntry_cluster						; set cluster number of direntry entry via dirptr - TODO FIXME only necessary on first write
		jsr __fat_set_direntry_filesize						; set filesize of directory entry via dirptr
		jsr __fat_set_direntry_timedate						; set time and date

		; set archive bit
		ldy #F32DirEntry::Attr
		lda #DIR_Attr_Mask_Archive
		ora (dirptr),y
		sta (dirptr),y

		jsr __fat_write_block_data							; lba_addr is already set from read, see above
@l_exit:
		;debug16 "f_w_e", dirptr
		rts

		; read the block with the directory entry of the given file descriptor, dirptr is adjusted accordingly
		; in:
		;	X - file descriptor of the file the directory entry should be read
		; out:
		;	dirptr pointing to the corresponding directory entry of type F32DirEntry
__fat_read_direntry:
		jsr __fat_set_lba_from_fd_dirlba					; setup lba address from fd
		SetVector block_data, read_blkptr
		jsr __fat_read_block								   ; and read the block with the dir entry
		bne @l_exit

		lda fd_area + F32_fd::DirEntryPos , x			; setup dirptr
@set_dirptr_from_entry_nr:
		stz dirptr

		lsr
		ror dirptr
		ror
		ror dirptr
		ror
		ror dirptr

		clc
		adc #>block_data
		sta dirptr+1

		lda #EOK
@l_exit:
		rts

		; write new timestamp to direntry entry given as dirptr
		; in:
		;	dirptr
__fat_set_direntry_timedate:
		phx
		jsr __rtc_systime_update									; update systime struct
		jsr __fat_rtc_time

		ldy #F32DirEntry::WrtTime
		sta (dirptr), y
		txa
		iny ; #F32DirEntry::WrtTime+1
		sta (dirptr), y

		jsr __fat_rtc_date
		ldy #F32DirEntry::WrtDate+0
		sta (dirptr), y
		ldy #F32DirEntry::LstModDate+0
		sta (dirptr), y
		txa
		ldy #F32DirEntry::WrtDate+1
		sta (dirptr), y
		ldy #F32DirEntry::LstModDate+1
		sta (dirptr), y
		plx
		rts

__fat_set_direntry_filesize:
		lda fd_area + F32_fd::FileSize+3 , x
		ldy #F32DirEntry::FileSize+3
		sta (dirptr),y
		lda fd_area + F32_fd::FileSize+2 , x
		dey
		sta (dirptr),y
		lda fd_area + F32_fd::FileSize+1 , x
		dey
		sta (dirptr),y
		lda fd_area + F32_fd::FileSize+0 , x
		dey
		sta (dirptr),y
		rts

		; copy cluster number from file descriptor to direntry given as dirptr
		; in:
		;	dirptr
__fat_set_direntry_cluster:
		ldy #F32DirEntry::FstClusHI+1
		lda fd_area + F32_fd::CurrentCluster+3 , x
		sta (dirptr), y
		dey
		lda fd_area + F32_fd::CurrentCluster+2 , x
		sta (dirptr), y

		ldy #F32DirEntry::FstClusLO+1
		lda fd_area + F32_fd::CurrentCluster+1 , x
		sta (dirptr), y
		dey
		lda fd_area + F32_fd::CurrentCluster+0 , x
		sta (dirptr), y
		rts

	;in:
        ;   A/X - pointer to the result buffer
		;	Y	- size of result buffer
        ;out:
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_get_root_and_pwd:
		sta	fat_tmp_dw2
		stx	fat_tmp_dw2+1
;		tya
;		eor	#$ff
		;sta	krn_ptr3					;TODO FIXME - length check of output buffer, save -size-1 for easy loop
		SetVector block_fat, krn_ptr3		;TODO FIXME - we use the 512 byte fat block buffer as temp space - FTW!
		stz krn_tmp3

		jsr __fat_clone_cd_td							; start from current directory, clone the cd fd

@l_rd_dir:
		lda #'/'										; put the / char to result string
		jsr put_char
		ldx #FD_INDEX_TEMP_DIR							; if root, exit to inverse the path string
		jsr __fat_isroot
		beq @l_inverse
		m_memcpy fd_area+FD_INDEX_TEMP_DIR+F32_fd::CurrentCluster, fat_tmp_dw, 4	; save the cluster from the fd of the "current" dir which is stored in FD_INDEX_TEMP_DIR (see clone above)
		lda #<l_dot_dot
		ldx #>l_dot_dot
		ldy #FD_INDEX_TEMP_DIR							; call opendir function with "..", on success the fd (FD_INDEX_TEMP_DIR) is updated now and we reached the parent directory
		jsr __fat_opendir
		bne @l_exit
		SetVector cluster_nr_matcher, fat_vec_matcher	; set the matcher strategy to the cluster number matcher
		jsr __fat_find_first							; and call find first to find the entry with that cluster number we saved in fat_tmp_dw before we did the cd ".."
		bcc @l_exit
		jsr fat_name_string								; found, dirptr points to the entry and we can simply extract the name - fat_name_string formats and appends the dir entry name:attr
		bra @l_rd_dir									; go on with bottom up walk until root is reached
@l_inverse:
		copypointer fat_tmp_dw2, krn_ptr2				; fat_tmp_dw2 is the pointer to the result string, given by the caller (eg. pwd.prg)
		jsr path_inverse								; since we captured the dir entry names bottom up, the path segments are in inverse order, we have to inverse them per segment and write them to the target string
		lda #EOK										; that's it...
@l_exit:
		rts

		; open directory by given path starting from current directory
		;in:
        ;   A/X - pointer to string with the file path
        ;out:
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
        ;   X - index into fd_area of the opened directory - !!! ATTENTION !!! X is exactly the FD_INDEX_TEMP_DIR on success
__fat_opendir_cd:
		ldy #FD_INDEX_CURRENT_DIR   ; clone current dir fd to temp dir fd
		; open directory by given path starting from directory given as file descriptor
		;in:
        ;   A/X - pointer to string with the file path
		;	Y 	- the file descriptor of the base directory which should be used, defaults to current directory (FD_INDEX_CURRENT_DIR)
        ;out:
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
        ;   X - index into fd_area of the opened directory - !!! ATTENTION !!! X is exactly the FD_INDEX_TEMP_DIR on success
__fat_opendir:
		jsr __fat_open_path
		bne	@l_exit					; exit on error
		lda	fd_area + F32_fd::Attr, x
		bit #DIR_Attr_Mask_Dir		; check that there is no error and we have a directory
		bne	@l_ok
		jsr fat_close				; not a directory, so we opened a file. just close them immediately and free the allocated fd
		lda	#ENOTDIR				; error "Not a directory"
		bra @l_exit
@l_ok:
    lda #EOK					; ok
@l_exit:
		debug "fod"
		rts

		;in:
        ;   A/X - pointer to string with the file path
        ;out:
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
        ;   X - index into fd_area of the opened directory (which is FD_INDEX_CURRENT_DIR)
fat_chdir:
		jsr __fat_opendir_cd
		bne	@l_exit
		ldy #FD_INDEX_TEMP_DIR        ; the temp dir fd is now set to the last dir of the path and we proofed that it's valid with the code above
		ldx #FD_INDEX_CURRENT_DIR
		jsr	__fat_clone_fd            ; therefore we can simply clone the temp dir to current dir fd - FTW!
		lda #EOK						; ok
@l_exit:
		;debug "fcd"
		rts

		; unlink a file denoted by given path in A/X
        ; in:
        ;   A/X - pointer to string with the file path
		; out:
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_unlink:
		ldy #O_RDONLY
		jsr fat_open		; try to open as regular file
		bne @l_exit
		jsr __fat_unlink
		jsr fat_close
@l_exit:
		;debug "unlnk"
		rts

		; delete a directory entry denoted by given path in A/X
        ;in:
        ;   A/X - pointer to the directory path
		; out:
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_rmdir:
		jsr __fat_opendir_cd
		bne @l_exit
		;debugdirentry
		jsr __fat_isroot
		beq @l_err_root					; cannot delete the root dir ;)
		jsr __fat_is_dot_dir
		beq @l_err_einval
		jsr __fat_dir_isempty
		bcs @l_exit
		jsr __fat_unlink
		bra @l_exit
@l_err_root:
@l_err_einval:
		lda #EINVAL
@l_exit:
		;debug "rmdir"
		rts

        ; in:
        ; 	A/X - pointer to the directory name
		; out:
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_mkdir:
		jsr __fat_opendir_cd
		beq	@err_exists
		cmp	#ENOENT									; we expect 'no such file or directory' error, otherwise a file with same name already exists
		bne @l_exit

		copypointer dirptr, krn_ptr2
		jsr string_fat_name							; build fat name upon input string (filenameptr) and store them directly to current dirptr!
		bne @l_exit

		jsr __fat_alloc_fd							; alloc a fd for the new directory - try to allocate a new fd here, right before any fat writes, cause they may fail
		bne @l_exit									; and we want to avoid an error in between the different block writes
		jsr __fat_set_fd_direntry					; update dir lba addr and dir entry number within fd from lba_addr and dir_ptr which where setup during __fat_opendir_cd from above

		jsr __fat_reserve_cluster					; try to find and reserve next free cluster and store them in fd_area at fd (X)
		bne @l_exit_close

		jsr __fat_set_lba_from_fd_dirlba			; setup lba_addr from fd
		lda #DIR_Attr_Mask_Dir						; set type directory
		jsr __fat_write_dir_entry					; create dir entry at current dirptr
		bne @l_exit_close

		jsr __fat_write_newdir_entry				; write the data of the newly created directory with prepared data from dirptr
@l_exit_close:
		jsr fat_close						 		; free the allocated file descriptor
		bra @l_exit
@err_exists:
		lda	#EEXIST
@l_exit:
		;debug "mkdir"
		rts

		;TODO check valid fsinfo block
		;TODO check whether clnr is maintained, test 0xFFFFFFFF ?
		;TODO improve calc, currently fixed to cluster-=1
		;TODO A - update amount of free clusters to be reserved/freed [-128...127]
__fat_update_fsinfo_inc:
		jsr __fat_read_fsinfo
		bne __fat_update_fsinfo_exit
		;debug32 "fi_fcl+", block_fat+F32FSInfo::FreeClus
		_inc32 block_fat+F32FSInfo::FreeClus
		jmp __fat_write_block_fat
__fat_update_fsinfo_dec:
		jsr __fat_read_fsinfo
		bne __fat_update_fsinfo_exit
		;debug32 "fi_fcl-", block_fat+F32FSInfo::FreeClus
		_dec32 block_fat+F32FSInfo::FreeClus
		jmp __fat_write_block_fat
__fat_read_fsinfo:
		m_memcpy fat_fsinfo_lba, lba_addr, 4
		SetVector block_fat, read_blkptr
		jmp __fat_read_block
__fat_update_fsinfo_exit:
		rts



		; create the "." and ".." entry of the new directory
		; in:
		;	X - the file descriptor into fd_area of the the new dir entry
		;	dirptr - set to current dir entry within block_data
__fat_write_newdir_entry:
		ldy #F32DirEntry::Attr																			; copy from (dirptr), start with F32DirEntry::Attr, the name is skipped and overwritten below
@l_dir_cp:
		lda (dirptr), y
		sta block_data, y																				; 1st dir entry
		sta block_data+1*.sizeof(F32DirEntry), y														; 2nd dir entry
		iny
		cpy #.sizeof(F32DirEntry)
		bne @l_dir_cp

		ldy #.sizeof(F32DirEntry::Name) + .sizeof(F32DirEntry::Ext)	-1			; erase name and build the "." and ".." entries
		lda #$20
@l_clr_name:
		sta block_data, y														; 1st dir entry
		sta block_data+1*.sizeof(F32DirEntry), y								; 2nd dir entry
		dey
		bne @l_clr_name
		lda #'.'
		sta block_data+F32DirEntry::Name+0										; 1st entry "."
		sta block_data+1*.sizeof(F32DirEntry)+F32DirEntry::Name+0				; 2nd entry ".."
		sta block_data+1*.sizeof(F32DirEntry)+F32DirEntry::Name+1

		ldy #FD_INDEX_TEMP_DIR													; due to fat_opendir/fat_open within fat_mkdir the fd of temp dir (FD_INDEX_TEMP_DIR) represents the last visited directory which must be the parent of this one ("..") - FTW!
		;debug32 "cd_cln", fd_area + FD_INDEX_TEMP_DIR + F32_fd::CurrentCluster
		lda fd_area+F32_fd::CurrentCluster+0,y
		sta block_data+1*.sizeof(F32DirEntry)+F32DirEntry::FstClusLO+0
		lda fd_area+F32_fd::CurrentCluster+1,y
		sta block_data+1*.sizeof(F32DirEntry)+F32DirEntry::FstClusLO+1
		lda fd_area+F32_fd::CurrentCluster+2,y
		sta block_data+1*.sizeof(F32DirEntry)+F32DirEntry::FstClusHI+0
		lda fd_area+F32_fd::CurrentCluster+3,y
		sta block_data+1*.sizeof(F32DirEntry)+F32DirEntry::FstClusHI+1

		ldy #$80
		lda #$00
@l_1st_block:
		sta block_data+2*.sizeof(F32DirEntry), y								; all dir entries, but "." and ".." (+2), are set to 0
		sta block_data+$080, y
		sta block_data+$100, y
		sta block_data+$180, y
		dey
		bpl @l_1st_block

		jsr __calc_lba_addr
		jsr __fat_write_block_data
		bne @l_exit

		m_memset block_data, 0, 2*.sizeof(F32DirEntry)							; now erase the "." and ".." entries too
		ldy volumeID+ VolumeID:: BPB + BPB::SecPerClus							; fill up (VolumeID::SecPerClus - 1) reamining blocks of the cluster with empty dir entries
		;debug32 "er_d", lba_addr
		bra @l_remain_blocks_e
@l_remain_blocks:
		jsr inc_lba_address														; next block within cluster
		jsr __fat_write_block_data
		bne @l_exit
@l_remain_blocks_e:
		dey
		bne @l_remain_blocks													; write until VolumeID::SecPerClus - 1
@l_exit:
		rts

		; internal sd read block
		; requires: read_blkptr and lba_addr already calculated
__fat_read_block:
      phx
      jsr read_block
      dec read_blkptr+1		; TODO FIXME clarification with TW - read_block increments block ptr highbyte - which is a sideeffect and should be avoided		
      plx
      cmp #0
      rts

__fat_write_block_fat:
		;debug32 "wb_lba", lba_addr
.ifdef FAT_DUMP_FAT_WRITE
		;debugdump "wbf", block_fat
.endif
		lda #>block_fat
		bra	__fat_write_block
__fat_write_block_data:
		lda #>block_data
__fat_write_block:
		sta write_blkptr+1
		stz write_blkptr	;page aligned
.ifndef FAT_NOWRITE
		jmp write_block
.else
		lda #EOK
		rts
.endif


		; write new dir entry to dirptr and set new end of directory marker
		; in:
		;	X - file descriptor
		;	dirptr - set to current dir entry within block_data
		; out:
		;	Z=1 on success, Z=0 otherwise, A=error code
__fat_write_dir_entry:
		jsr __fat_prepare_dir_entry
		;debug16 "f_w_dp", dirptr

		;TODO FIXME duplicate code here! - @see fat_find_next:
		lda dirptr+1
		sta krn_ptr1+1
		lda dirptr														; create the end of directory entry
		clc
		adc #DIR_Entry_Size
		sta krn_ptr1
		bcc @l2
		inc krn_ptr1+1
@l2:
		lda krn_ptr1+1 												; end of block reached? :/ edge-case, we have to create the end-of-directory entry at the next block
		cmp #>(block_data + sd_blocksize)
		bne @l_eod														; no, write one block only

		; new dir entry
		jsr __fat_write_block_data					  ; write the current block with the updated dir entry first
		bne @l_exit
		ldy #$80														  ; safely, fill the new dir block with 0 to mark eod
@l_erase:; A=0 here
		sta block_data+$000, y
		sta block_data+$080, y
		sta block_data+$100, y
		sta block_data+$180, y
		dey
		bpl @l_erase

		;TODO FIXME test end of cluster, if so reserve a new one, update cluster chain for directory ;)
		;debug32 "eod_lba", lba_addr
		;debug32 "eod_cln", fd_area+FD_INDEX_TEMP_DIR
;		lda lba_addr+0
;		adc #02
;		sbc volumeID+VolumeID::BPB + BPB::SecPerClus
;		lda fd_area+F32_fd::CurrentCluster+0
;		sbc lba_addr+0
		jsr inc_lba_address												; increment lba address to write to next block

@l_eod:
		;TODO FIXME erase the rest of the block, currently 0 is assumed
		jsr __fat_write_block_data										; write the updated dir entry to device
@l_exit:
		debug "f_wde"
		rts

__fat_rtc_high_word:
		lsr
		ror	krn_tmp2
		lsr
		ror	krn_tmp2
		lsr
		ror	krn_tmp2
		ora krn_tmp
		tax
		rts

		; out
		;	A/X with time from rtc struct in fat format
__fat_rtc_time:
		stz krn_tmp2
		lda rtc_systime_t+time_t::tm_hour								; hour
		asl
		asl
		asl
		sta krn_tmp
		lda rtc_systime_t+time_t::tm_min								; minutes 0..59
		jsr __fat_rtc_high_word
		lda rtc_systime_t+time_t::tm_sec								; seconds/2
		lsr
		ora krn_tmp2
		rts

		; out
		;	A/X with date from rtc struct in fat format
__fat_rtc_date:
		stz krn_tmp2
		lda rtc_systime_t+time_t::tm_year							; years since 1900
		sec
		sbc #80																; fat year is 1980..2107 (bit 15-9), we have to adjust 80 years
		asl
		sta krn_tmp
		lda rtc_systime_t+time_t::tm_mon								; month from rtc is (0..11), adjust +1
		inc
		jsr __fat_rtc_high_word
		lda rtc_systime_t+time_t::tm_mday							; day of month (1..31)
		ora krn_tmp2
		rts

		; prepare dir entry, expects cluster number set in fd_area of newly allocated fd given in X
		; in:
		;	X - file descriptor
		;	A - attribute flag for new directory entry
		;	dirptr of the directory entry to prepare
__fat_prepare_dir_entry:
		ldy #F32DirEntry::Attr										; store attribute
		sta (dirptr), y

		lda #0
		ldy #F32DirEntry::Reserved									; unused
		sta (dirptr), y

		ldy #F32DirEntry::CrtTimeMillis
		sta (dirptr), y												; ms to 0, ms not supported by rtc

		jsr __fat_set_direntry_timedate

		ldy #F32DirEntry::WrtTime									; creation date/time copy over from modified date/time
		lda (dirptr),y
		ldy #F32DirEntry::CrtTime
		sta (dirptr),y
		ldy #F32DirEntry::WrtTime+1
		lda (dirptr),y
		ldy #F32DirEntry::CrtTime+1
		sta (dirptr),y

		ldy #F32DirEntry::WrtDate
		lda (dirptr),y
		ldy #F32DirEntry::CrtDate
		sta (dirptr),y
		ldy #F32DirEntry::WrtDate+1
		lda (dirptr),y
		ldy #F32DirEntry::CrtDate+1
		sta (dirptr),y

		jsr __fat_set_direntry_cluster
		jmp __fat_set_direntry_filesize

__fat_write_fat_blocks:
		jsr __fat_write_block_fat				; lba_addr is already setup by __fat_find_free_cluster
		bne @err_exit
		clc										; calc fat2 lba_addr = lba_addr + VolumeID::FATSz32
		.repeat 4, i
			lda lba_addr + i
			adc volumeID + VolumeID::EBPB + EBPB::FATSz32 + i
			sta lba_addr + i
		.endrepeat
		jsr __fat_write_block_fat				; write to fat mirror (fat2)
@err_exit:
		rts

		; find and reserve next free cluster and maintains the fsinfo block
		; in:
		;	X - the file descriptor into fd_area where the found cluster should be stored
		; out:
		;	Z=1 on success, Z=0 otherwise and A=error code
__fat_reserve_cluster:
		jsr __fat_find_free_cluster					; find free cluster, stored in fd_area for the fd given within X
		bne @l_err_exit
		jsr __fat_mark_cluster_eoc					; mark cluster in block with EOC - TODO cluster chain support
		jsr __fat_write_fat_blocks					; write the updated fat block for 1st and 2nd FAT to the device
		bne @l_err_exit
		jmp __fat_update_fsinfo_dec					; update the fsinfo sector/block
@l_err_exit:
		rts

		; in:
		;	X - file descriptor
		; out:
		;	read_blkptr - setup to block_fat either low/high page
		;	Y - offset within block_fat to clnr
		;	Z=1 on success, Z=0 otherwise and A=error code
		;	C=1 if the cluster number is the EOC, C=0 otherwise
__fat_read_cluster_block_and_select:
		jsr __calc_fat_lba_addr
		SetVector block_fat, read_blkptr
		jsr __fat_read_block
		bne @l_exit
		jsr __fat_isroot							; is root clnr?
		bne @l_clnr_fd
		lda volumeID + VolumeID::EBPB + EBPB::RootClus+0
		bra @l_clnr_page
@l_clnr_fd:
		lda fd_area+F32_fd::CurrentCluster+0,x 	; offset within block_fat, clnr<<2 (* 4)		
@l_clnr_page:
		bit #$40										; clnr within 2nd page of the 512 byte block ?
		beq @l_clnr
		ldy #>(block_fat+$0100)					; yes, set read_blkptr to 2nd page of block_fat
		sty read_blkptr+1
@l_clnr:
		asl											; block offset = clnr*4
		asl
		tay
		jsr __fat_is_cln_eoc						; C is returned accordingly
		lda #EOK
@l_exit:
		debug16 "f_rcbs", read_blkptr
		rts


		; free cluster and maintain the fsinfo block
		; in:
		;	X - the file descriptor into fd_area (F32_fd::CurrentCluster)
		; out:
		;	Z=1 on success, Z=0 otherwise and A=error code
__fat_free_cluster:
		jsr __fat_read_cluster_block_and_select
		bne @l_exit								; read error...
		bcc @l_exit								; TODO FIXME cluster chain during deletion not supported yet - therefore EOC (C=1) expected here !!!
		;debug "f_fc"
		jsr __fat_mark_cluster				; mark cluster as free (A=0)
		jsr __fat_write_fat_blocks			; write back fat blocks
		bne @l_exit
		jmp __fat_update_fsinfo_inc
@l_exit:
		rts

		; mark cluster as EOC
		; in:
		;	Y - offset in block
		; 	read_blkptr - points to block_fat either 1st or 2nd page
__fat_mark_cluster_eoc:
		lda #$ff
__fat_mark_cluster:
		sta (read_blkptr), y
		iny
		sta (read_blkptr), y
		iny
		sta (read_blkptr), y
		iny
      and #$0f
      sta (read_blkptr), y
		rts

		; in:
		;	X - file descriptor
		; out:
		;	Z=1 on success
		;		Y=offset in block_fat of found cluster
		;		lba_addr with fat block where the found cluster resides
		;		the found cluster is stored within the given file descriptor (fd_area+F32_fd::CurrentCluster,x)
		;	Z=0 on error, A=error code
__fat_find_free_cluster:
		;TODO improve, use a previously saved lba_addr and/or found cluster number
		stz lba_addr+3			; init lba_addr with fat_begin lba addr
		stz lba_addr+2			; TODO FIXME we assume that 16 bit are sufficient for fat lba address
		lda fat_lba_begin+1
		sta lba_addr+1
		lda fat_lba_begin+0
		sta lba_addr+0

		SetVector	block_fat, read_blkptr
@next_block:
		;debug32 "fr_lba", lba_addr
		jsr __fat_read_block	; read fat block
		bne @exit

		ldy #0
@l1:	lda block_fat+0,y		; 1st page find cluster entry with 00 00 00 00
		ora block_fat+1,y
		ora block_fat+2,y
		ora block_fat+3,y
		beq @l_found_lb			; branch, A=0 here
		lda block_fat+$100+0,y	; 2nd page find cluster entry with 00 00 00 00
		ora block_fat+$100+1,y
		ora block_fat+$100+2,y
		ora block_fat+$100+3,y
		beq @l_found_hb
		iny
		iny
		iny
		iny
		bne @l1
		jsr inc_lba_address	; inc lba_addr, next fat block
		lda lba_addr+1			; end of fat reached?
		cmp fat2_lba_begin+1	; cmp with fat2_begin_lba
		bne @next_block
		lda lba_addr+0
		cmp fat2_lba_begin+0
		bne @next_block		;
		lda #ENOSPC				; end reached, answer ENOSPC () - "No space left on device"
@exit:	
    ;debug32 "free_cl", fd_area+(2*.sizeof(F32_fd)) + F32_fd::CurrentCluster ; almost the 3rd entry
		rts
@l_found_hb: ; found in "high" block (2nd page of the sd_blocksize)
		lda #>(block_fat+$100)	; set read_blkptr to begin 2nd page of fat_buffer - @see __fat_mark_free_cluster
		sta read_blkptr+1
		lda #$40				; adjust clnr with +$40 (256 / 4 byte/clnr) clusters since it was found in 2nd page
@l_found_lb:				; A=0 here, if called from above
		;debug32 "f_ffc_lba", lba_addr
		sta fd_area+F32_fd::CurrentCluster+0, x
		tya
		lsr						; offset Y>>2 (div 4, 32 bit clnr)
		lsr
		adc fd_area+F32_fd::CurrentCluster+0, x	; C=0 always here, y is multiple of 4 and 2 lsr
		sta fd_area+F32_fd::CurrentCluster+0, x	; safe clnr
		;debug32 "fc_tmp2", fd_area+F32_fd::CurrentCluster+.sizeof(F32_fd)*3 ;(new fd is almost the 3rd entry)

		;m_memcpy lba_addr, safe_lba TODO FIXME fat lba address, reuse them at next search
		; to calc them we have to clnr = (block number * 512) / 4 + (Y / 4) => (lba_addr - fat_lba_begin) << 7 + (Y>>2)
		; to avoid the <<7, we simply <<8 and do one ror
		sec
		lda lba_addr+0
		sbc fat_lba_begin+0
		sta krn_tmp				; save A
		lda lba_addr+1
		sbc fat_lba_begin+1		; now we have 16bit blocknumber
		lsr						; clnr = blocks<<7
		sta fd_area+F32_fd::CurrentCluster+2, x
		lda krn_tmp				; restore A
		ror
		sta fd_area+F32_fd::CurrentCluster+1, x
		lda #0
		ror						; clnr += offset within block - already saved in F32_fd::CurrentCluster+0, x s.above
		adc fd_area+F32_fd::CurrentCluster+0, x
		sta fd_area+F32_fd::CurrentCluster+0, x
		lda #0					; exit found
		sta fd_area+F32_fd::CurrentCluster+3, x
		bra @exit

        ; in:
        ;   A/X - pointer to string with the file path
		;	  Y - file mode constant
		;		O_RDONLY        = $01
		;		O_WRONLY        = $02
		;		O_RDWR          = $03
		;		O_CREAT         = $10
		;		O_TRUNC         = $20
		;		O_APPEND        = $40
		;		O_EXCL          = $80
        ; out:
        ;   X - index into fd_area of the opened file
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_open:
		sty fat_tmp_mode				; save open flag
		ldy #FD_INDEX_CURRENT_DIR   	; use current dir fd as start directory
		jsr __fat_open_path
		bne	@l_error
		lda	fd_area + F32_fd::Attr, x	;
		and #DIR_Attr_Mask_Dir			; regular file or directory?
		beq	@l_exit_ok					; not dir, ok
		bra @l_err_dir					;
@l_error:
		cmp #ENOENT					; no such file or directory ?
		bne @l_exit					; other error, then exit
		lda fat_tmp_mode			; check if we should create a new file
		and #O_CREAT | O_WRONLY | O_APPEND
		beq @l_err_enoent			; nothing set, exit with ENOENT

		;debug "r+"
		copypointer dirptr, krn_ptr2
		jsr string_fat_name							; build fat name upon input string (filenameptr)
		bne @l_exit
		jsr __fat_alloc_fd							; alloc a fd for the new file we want to create to make sure we get one before
		bne @l_exit									; we do any sd block writes which may result in various errors
		jsr __fat_set_fd_direntry					; update dir lba addr and dir entry number within fd

		lda #DIR_Attr_Mask_Archive				    ; create as regular file with archive bit set
		jsr __fat_write_dir_entry					; create dir entry at current dirptr
		beq @l_exit_ok
		jsr fat_close						 		; free the allocated file descriptor on any errors
		bra @l_exit
@l_err_enoent:
		lda	#ENOENT
		bra @l_exit
@l_err_dir:											; was directory, we must not free any fd
		lda	#EISDIR									; error "Is a directory"
		bra @l_exit
@l_exit_ok:
		lda #EOK									; A=0 (EOK)
@l_exit:
		;debug "fop"
		rts

		; open a path to a file or directory starting from current directory
		; in:
		;	A/X - pointer to string with the file path
		;	Y	- file descriptor of fd_area denoting the start directory. usually FD_INDEX_CURRENT_DIR is used
		; out:
		;  X - index into fd_area of the opened file. if a directory was opened then X == FD_INDEX_TEMP_DIR
		;	Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
		;	Note: regardless of return value, the dirptr points to the last visited directory entry and the corresponding lba_addr is set to the block where the dir entry resides.
		;		  furthermore the filenameptr points to the last inspected path fragment of the given input path
.macro _open
		stz	filename_buf, x	;\0 terminate the current path fragment
		jsr	__fat_open_file
		bne @l_exit
.endmacro
__fat_open_path:
		sta krn_ptr1
		stx krn_ptr1+1			    ; save path arg given in a/x

		ldx #FD_INDEX_TEMP_DIR	; we use the temp dir fd to not clobber the current dir (Y parameter!), maybe we will run into an error
		jsr __fat_clone_fd			; Y is given as param

		ldy #0						      ; trim wildcard at the beginning
@l1:
    lda (krn_ptr1), y
		cmp #' '
		bne @l2
		iny
		bne @l1
		bra @l_err_einval		; overflow, >255 chars
@l2:	;	starts with '/' ? - we simply cd root first
		cmp #'/'
		bne @l31
		jsr fat_open_rootdir
		iny
		lda	(krn_ptr1), y		;end of input?
		beq	@l_exit				;yes, so it was just the '/', exit with A=0
@l31:
		SetVector   filename_buf, filenameptr	; filenameptr to filename_buf
@l3:	;	parse input path fragments into filename_buf try to change dirs accordingly
		ldx #0
@l_parse_1:
		lda	(krn_ptr1), y
		beq	@l_openfile
		cmp	#' '                ;TODO FIXME support file/dir name with spaces? it's beyond 8.3 file support
		beq	@l_openfile
		cmp	#'/'
		beq	@l_open

		sta filename_buf, x
		iny
		inx
		cpx	#8+1+3		+1		; buffer overflow ? - only 8.3 file support yet
		bne	@l_parse_1
		bra @l_err_einval
@l_open:
		_open
		iny
		bne	@l3					;overflow - <path argument> exceeds 255 chars
@l_err_einval:
		lda	#EINVAL
@l_exit:
		;debug	"fop"
		rts
@l_openfile:
		_open					; return with X as offset into fd_area with new allocated file descriptor
		lda #EOK
		bra @l_exit

        ;in:
        ;   filenameptr - ptr to the filename
        ;out:
        ;   X - index into fd_area of the opened file
		;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
__fat_open_file:
		phy

		ldx #FD_INDEX_TEMP_DIR
		jsr __fat_find_first_mask
		bcs fat_open_found
		lda #ENOENT
		bra end_open_err

fat_open_found:						; found...
		ldy #F32DirEntry::Attr
		lda (dirptr),y
		bit #DIR_Attr_Mask_Dir 		; directory?
		bne @l2						; yes, do not allocate a new fd, use index (X) which is already set to FD_INDEX_TEMP_DIR and just update the fd data
		jsr __fat_alloc_fd			; no, then regular file and we allocate a new fd for them
		bne end_open_err
@l2:
		;save 32 bit cluster number from dir entry
		ldy #F32DirEntry::FstClusHI +1
		lda (dirptr),y
		sta fd_area + F32_fd::CurrentCluster + 3, x
		dey
		lda (dirptr),y
		sta fd_area + F32_fd::CurrentCluster + 2, x

		ldy #F32DirEntry::FstClusLO +1
		lda (dirptr),y
		sta fd_area + F32_fd::CurrentCluster + 1, x
		dey
		lda (dirptr),y
		sta fd_area + F32_fd::CurrentCluster + 0, x

		ldy #F32DirEntry::FileSize + 3
		lda (dirptr),y
		sta fd_area + F32_fd::FileSize + 3, x
		dey
		lda (dirptr),y
		sta fd_area + F32_fd::FileSize + 2, x
		dey
		lda (dirptr),y
		sta fd_area + F32_fd::FileSize + 1, x
		dey
		lda (dirptr),y
		sta fd_area + F32_fd::FileSize + 0, x

		ldy #F32DirEntry::Attr
		lda (dirptr),y
		sta fd_area + F32_fd::Attr, x

		jsr __fat_set_fd_direntry

		lda #EOK ; no error
end_open_err:
		ply
		cmp	#0			;restore z flag
		rts

fat_check_signature:
		lda #$55
		cmp sd_blktarget + BootSector::Signature
		bne @l1
		asl ; $aa
		cmp sd_blktarget + BootSector::Signature + 1
		beq @l2
@l1:	lda #fat_bad_block_signature
@l2:	rts


		; in:
		;	X - file descriptor
		; out:
		;	Z=1 (A=0) if no blocks to read (file has zero length)
__calc_blocks: ;blocks = filesize / BLOCKSIZE -> filesize >> 9 (div 512) +1 if filesize LSB is not 0
		lda fd_area + F32_fd::FileSize + 3,x
		lsr
		sta blocks + 2
		lda fd_area + F32_fd::FileSize + 2,x
		ror
		sta blocks + 1
		lda fd_area + F32_fd::FileSize + 1,x
		ror
		sta blocks + 0
		bcs @l1
		lda fd_area + F32_fd::FileSize + 0,x
		beq @l2
@l1:	inc blocks
		bne @l2
		inc blocks+1
		bne @l2
		inc blocks+2
@l2:	lda blocks+2
		ora blocks+1
		ora blocks+0
		;debug16 "bl", blocks
		rts
		
		; in:
		;	X - file descriptor
		; out:
		;	lba_addr setup with lba address from given file descriptor
		;	A - with bit 0-7 of lba address
__prepare_calc_lba_addr:
		jsr	__fat_isroot
		bne	@l_scl
		.repeat 4,i
			lda volumeID + VolumeID::EBPB + EBPB::RootClus + i
			sta lba_addr + i
		.endrepeat
		rts
@l_scl:
		.repeat 4,i
			lda fd_area + F32_fd::CurrentCluster + i,x
			sta lba_addr + i
		.endrepeat
		rts


; 		calculate LBA address of first block from cluster number found in file descriptor entry. file descriptor index must be in x
;		Note: lba_addr = cluster_begin_lba_m2 + (cluster_number * VolumeID::SecPerClus)
;		in:
;			X - file descriptor index
__calc_lba_addr:
		pha
		phx

		jsr __prepare_calc_lba_addr

		;SecPerClus is a power of 2 value, therefore cluster << n, where n is the number of bit set in VolumeID::SecPerClus
		lda volumeID+VolumeID::BPB + BPB::SecPerClus
@lm:	lsr
		beq @lme    ; until 1 sector/cluster
		tax
		asl lba_addr +0
		rol lba_addr +1
		rol lba_addr +2
		rol lba_addr +3
		txa
		bra @lm
@lme:
		plx												; restore X - the fd

		clc												; add cluster_begin_lba and lba_addr => TODO may be an optimization
      .repeat 4, i
			lda cluster_begin_lba+i
			adc lba_addr+i
			sta lba_addr+i
		.endrepeat
		
		lda fd_area+F32_fd::offset+0,x			; load the current block counter
		adc lba_addr+0									; add to lba_addr
		sta lba_addr+0
		bcc :+
      .repeat 3, i
			lda lba_addr+1+i
			adc #0
			sta lba_addr+1+i
		.endrepeat
:		
		;debug32 "f_lba", lba_addr
		
		pla
		rts

inc_lba_address:
		_inc32 lba_addr
		rts

		; in:
		;	X - file descriptor
		; out:
		;	vol->LbaFat + (cluster_nr>>7);// div 128 -> 4 (32bit) * 128 cluster numbers per block (512 bytes)
__calc_fat_lba_addr:
		;instead of shift right 7 times in a loop, we copy over the hole byte (same as >>8) - and simply shift left 1 bit (<<1)
		jsr __prepare_calc_lba_addr
		lda lba_addr+0
		asl
		lda lba_addr+1
		rol
		sta lba_addr+0
		lda lba_addr+2
		rol
		sta lba_addr+1
		lda lba_addr+3
		rol
		sta lba_addr+2
		lda #0									;$0f (see EOC) highest value for cluster MSB, due to >>7 the $0f from the MSB is erased completely
		rol
		sta lba_addr+3
		clc										; add fat_lba_begin and lba_addr
		lda fat_lba_begin+0
		adc lba_addr +0
		sta lba_addr +0
		lda fat_lba_begin+1
		adc lba_addr +1
		sta lba_addr +1

		stz lba_addr +2							; TODO FIXME only 16 Bit Blocks Fat-Sizes supported
		stz lba_addr +3
;		lda fat_lba_begin+2
;		adc lba_addr +2
;		sta lba_addr +2
;		lda fat_lba_begin+3
;		adc lba_addr +3
;		sta lba_addr +3
		;debug32 "f_flba", lba_addr
		rts

		; check whether cluster of fd is the root cluster number as given in VolumeID::RootClus
		; in:
		;	X - file descriptor
		; out:
		;	Z=1 if it is the root cluster, Z=0 otherwise
__fat_isroot:
		;TODO improve performance, do the check only if type is directory
		lda fd_area+F32_fd::CurrentCluster+3,x				; check whether start cluster is the root dir cluster nr (0x00000000) as initial set by fat_alloc_fd
		ora fd_area+F32_fd::CurrentCluster+2,x
		ora fd_area+F32_fd::CurrentCluster+1,x
		ora fd_area+F32_fd::CurrentCluster+0,x
		rts

		; check whether the EOC (end of cluster chain) cluster number is reached
		; out:
		;	C = 1 if clnr is EOC, C=0 otherwise
__fat_is_cln_eoc:
		phy
		lda (read_blkptr),y
		cmp #<FAT_EOC
		bne @l_neoc
		iny
		lda (read_blkptr),y
		cmp #<(FAT_EOC>>8)
		iny
		lda (read_blkptr),y
		cmp #<(FAT_EOC>>16)
		bne @l_neoc
		iny
		lda (read_blkptr),y
		cmp #<(FAT_EOC>>24)
		beq @l_eoc
@l_neoc:
		clc
@l_eoc:
		ply
		rts

		; extract next cluster number from the 512 fat block buffer
		; unsigned int offs = (clnr << 2 & (BLOCK_SIZE-1));//offset within 512 byte block, cluster nr * 4 (32 Bit) and Bit 8-0 gives the offset
		; in:
		;	X - file descriptor
		;	Y - offset from target address denoted by pointer (read_blkptr)
		; out:
		;  Z=1 on success
__fat_next_cln:
		lda (read_blkptr), y
		;debug "nc0"
		sta fd_area + F32_fd::CurrentCluster+0, x
		iny
		lda (read_blkptr), y
		;debug "nc1"
		sta fd_area + F32_fd::CurrentCluster+1, x
		iny
		lda (read_blkptr), y
		;debug "nc2"
		sta fd_area + F32_fd::CurrentCluster+2, x
		iny
		lda (read_blkptr), y
		;debug "nc3"
		sta fd_area + F32_fd::CurrentCluster+3, x
		;TODO stz offset here?!?
		lda #EOK
		rts


;---------------------------------------------------------------------
; Mount FAT32 on Partition 0
;---------------------------------------------------------------------
fat_mount:
		; set lba_addr to $00000000 since we want to read the bootsector
		.repeat 4, i
			stz lba_addr + i
		.endrepeat

		SetVector sd_blktarget, read_blkptr
		jsr read_block

		jsr fat_check_signature
		bne @l_exit
@l1:
		@part0 = sd_blktarget + BootSector::Partitions + PartTable::Partition_0

		lda @part0 + PartitionEntry::TypeCode
		cmp #PartType_FAT32_LBA
		beq @l2
		lda #fat_invalid_partition_type	; type code not  PartType_FAT32_LBA ($0C)
		bra @l_exit
@l2:
		m_memcpy @part0 + PartitionEntry::LBABegin, lba_addr, 4
		;debug32 "p_lba", lba_addr

		SetVector sd_blktarget, read_blkptr
		; Read FAT Volume ID at LBABegin and Check signature
		jsr read_block
		bne @l_exit
		jsr fat_check_signature
		bne @l_exit
@l4:
		;m_memcpy	sd_blktarget+11, volumeID, .sizeof(VolumeID) ; +11 skip first 11 bytes, we are not interested in
		m_memcpy	sd_blktarget + F32_VolumeID::BPB, volumeID + VolumeID::BPB, .sizeof(BPB) ; +11 skip first 11 bytes, we are not interested in
		m_memcpy	sd_blktarget + F32_VolumeID::EBPB, volumeID + VolumeID::EBPB, .sizeof(EBPB) ; +11 skip first 11 bytes, we are not interested in

		; Bytes per Sector, must be 512 = $0200
		lda	volumeID + VolumeID::BPB + BPB::BytsPerSec+0
		bne @l_exit
		lda	volumeID + VolumeID::BPB + BPB::BytsPerSec+1
		cmp #$02
		beq @l6
		lda #fat_invalid_sector_size
@l_exit:
		jmp @end_mount
@l6:
		; cluster_begin_lba = Partition_LBA_Begin + Number_of_Reserved_Sectors + (Number_of_FATs * Sectors_Per_FAT) -  (2 * sec/cluster);
		; fat_lba_begin = Partition_LBA_Begin + Number_of_Reserved_Sectors
		; fat2_lba_begin = Partition_LBA_Begin + Number_of_Reserved_Sectors + Sectors_Per_FAT

		; add number of reserved sectors to calculate fat_lba_begin. also store in cluster_begin_lba for further calculation
		clc
		lda lba_addr + 0
		adc volumeID + VolumeID::BPB + BPB::RsvdSecCnt + 0
		sta cluster_begin_lba + 0
		sta fat_lba_begin + 0
		lda lba_addr + 1
		adc volumeID + VolumeID::BPB + BPB::RsvdSecCnt + 1
		sta cluster_begin_lba + 1
		sta fat_lba_begin + 1
		lda lba_addr + 2
		adc #$00
		sta cluster_begin_lba + 2
		sta fat_lba_begin + 2
		lda lba_addr + 3
		adc #$00
		sta cluster_begin_lba + 3
		sta fat_lba_begin + 3

		; Number of FATs. Must be 2
		; cluster_begin_lba = fat_lba_begin + (sectors_per_fat * VolumeID::NumFATs (2))
		ldy volumeID + VolumeID::BPB + BPB::NumFATs
@l7:	clc
		ldx #$00
@l8:	ror ; get carry flag back
		lda volumeID + VolumeID::EBPB + EBPB::FATSz32,x ; sectors per fat
		adc cluster_begin_lba,x
		sta cluster_begin_lba,x
		inx
		rol ; save status register before cpx to save carry
		cpx #$04 ; 32Bit
		bne @l8
		dey
		bne @l7

		; calc begin of 2nd fat (end of 1st fat)
		; TODO FIXME - we assume 16bit are sufficient for now since fat is placed at the beginning of the device
		clc
		lda volumeID +  VolumeID::EBPB + EBPB::FATSz32+0 ; sectors/blocks per fat
		adc fat_lba_begin	+0
		sta fat2_lba_begin	+0
		lda volumeID +  VolumeID::EBPB + EBPB::FATSz32+1
		adc fat_lba_begin	+1
		sta fat2_lba_begin	+1

		; calc fs_info lba address
		clc
		lda lba_addr+0
		adc volumeID+ VolumeID::EBPB + EBPB::FSInfoSec+0
		sta fat_fsinfo_lba+0
		lda lba_addr+1
		adc volumeID+ VolumeID::EBPB + EBPB::FSInfoSec+1
		sta fat_fsinfo_lba+1
		lda #0
		sta fat_fsinfo_lba+3
		adc #0				; 0 + C
		sta fat_fsinfo_lba+2

		; cluster_begin_lba_m2 -> cluster_begin_lba - (VolumeID::RootClus*VolumeID::SecPerClus)
		; cluster_begin_lba_m2 -> cluster_begin_lba - (2*sec/cluster) => cluster_begin_lba - (sec/cluster << 1)
		;TODO FIXME we assume 2 here instead of using the value in VolumeID::RootClus
		lda volumeID+VolumeID::BPB + BPB::SecPerClus ; max sec/cluster can be 128, with 2 (BPB_RootClus) * 128 wie may subtract max 256
		asl
		sta lba_addr        ;   used as tmp
		stz lba_addr +1     ;   safe carry
		rol lba_addr +1
		sec	                ;   subtract from cluster_begin_lba
		lda cluster_begin_lba
		sbc lba_addr
		sta cluster_begin_lba
		lda cluster_begin_lba +1
		sbc lba_addr +1
		sta cluster_begin_lba +1
		lda cluster_begin_lba +2
		sbc #0
		sta cluster_begin_lba +2
		lda cluster_begin_lba +3
		sbc #0
		sta cluster_begin_lba +3

		;debug8 "sec/cl", volumeID+VolumeID::BPB + BPB::SecPerClus
		;debug32 "r_cl", volumeID+VolumeID::EBPB + EBPB::RootClus
		;debug32 "s_lba", lba_addr
		;debug16 "r_sc", volumeID + VolumeID::BPB + BPB::RsvdSecCnt
		;debug16 "f_lba", fat_lba_begin
		;debug32 "f_sc", volumeID +  VolumeID::EBPB + EBPB::FATSz32
		;debug16 "f2_lba", fat2_lba_begin
		;debug16 "fi_sc", volumeID+ VolumeID::EBPB + EBPB::FSInfoSec
		;debug32 "fi_lba", fat_fsinfo_lba
		;debug32 "cl_lba", cluster_begin_lba
		;debug16 "fbuf", filename_buf

		; init file descriptor area
    ldx #0
		jsr __fat_init_fdarea

		; alloc file descriptor for current dir. which is cluster number 0 on fat32 - Note: the RootClus offset is compensated within calc_lba_addr
		ldx #FD_INDEX_CURRENT_DIR
		jsr __fat_init_fd
@end_mount:
		debug "f_mnt"
		rts


__fat_clone_cd_td:
		ldy #FD_INDEX_CURRENT_DIR
		ldx #FD_INDEX_TEMP_DIR
		; clone source file descriptor with offset y into fd_area to target fd with x
		; in:
		;   Y - source file descriptor (offset into fd_area)
		;   X - target file descriptor (offset into fd_area)
__fat_clone_fd:
		phx
		lda #FD_Entry_Size
		sta krn_tmp
@l1:	lda fd_area, y
		sta fd_area, x
		inx
		iny
		dec krn_tmp
		bne @l1
		plx
		rts

		; in:
		;	x - offset to fd_area
		; out:
		;	Z=0 if file is open, Z=1 otherwise
__fat_isOpen:
		lda fd_area + F32_fd::CurrentCluster +3, x
		cmp #$ff		;#$ff means not open
		rts

fat_close_all:
      ldx #(2*FD_Entry_Size)	; skip first 2 entries, they're reserverd for current and temp dir
__fat_init_fdarea:
      lda #$ff
@l1:
      sta fd_area + F32_fd::CurrentCluster, x
      inx
      cpx #(FD_Entry_Size*FD_Entries_Max)
      bne @l1
      rts

		; in:
		;	X - file descriptor
		; out:
		;	lba_addr setup with direntry lba
__fat_set_lba_from_fd_dirlba:
		lda fd_area + F32_fd::DirEntryLBA+3 , x				; set lba addr of dir entry...
		sta lba_addr+3
		lda fd_area + F32_fd::DirEntryLBA+2 , x
		sta lba_addr+2
		lda fd_area + F32_fd::DirEntryLBA+1 , x
		sta lba_addr+1
		lda fd_area + F32_fd::DirEntryLBA+0 , x
		sta lba_addr+0
		debug32 "f_slba", lba_addr
		rts

		; update the dir entry position and dir lba_addr of the given file descriptor
		; in:
		;	X - file descriptor
		; out:
		;	updated file descriptor, DirEntryLBA and DirEntryPos setup accordingly
__fat_set_fd_direntry:
	 	lda lba_addr + 3
		sta fd_area + F32_fd::DirEntryLBA + 3, x
	 	lda lba_addr + 2
		sta fd_area + F32_fd::DirEntryLBA + 2, x
	 	lda lba_addr + 1
		sta fd_area + F32_fd::DirEntryLBA + 1, x
	 	lda lba_addr + 0
		sta fd_area + F32_fd::DirEntryLBA + 0, x

		lda dirptr
		sta krn_tmp

		lda dirptr+1
		and #$01		; div 32, just bit 0 of high byte must be taken into account. dirptr must be $0200 aligned
		.assert >block_data & $01 = 0, error, "block_data must be $0200 aligned!"
		clc
		rol krn_tmp
		rol
		rol krn_tmp
		rol
		rol krn_tmp
		rol

		sta fd_area + F32_fd::DirEntryPos, x
		rts

    ; out:
    ;   X - with index to fd_area
    ;   Z - Z=1 on success (A=0), Z=0 and A=error code otherwise
__fat_alloc_fd:
      ldx #(2*FD_Entry_Size)							; skip 2 entries, they're reserverd for current and temp dir
@l1:	lda fd_area + F32_fd::CurrentCluster +3, x
      cmp #$ff	;#$ff means unused, return current x as offset
      beq __fat_init_fd

      txa
      adc #FD_Entry_Size; carry must be clear from cmp #$ff above
      tax

      cpx #(FD_Entry_Size*FD_Entries_Max)
      bne @l1
      lda #EMFILE								; Too many open files, no free file descriptor found
      rts

		; out:
		;   x - FD_INDEX_TEMP_DIR offset to fd area
fat_open_rootdir:
		ldx #FD_INDEX_TEMP_DIR					; set temp directory to cluster number 0 - Note: the RootClus offset is compensated within calc_lba_addr
__fat_init_fd:
		stz fd_area+F32_fd::CurrentCluster+3,x	; init start cluster with root dir cluster which is 0 - @see Note in calc_lba_addr
		stz fd_area+F32_fd::CurrentCluster+2,x
		stz fd_area+F32_fd::CurrentCluster+1,x
		stz fd_area+F32_fd::CurrentCluster+0,x
		stz fd_area+F32_fd::FileSize+3,x		; init file size with 0, it's maintained during open
		stz fd_area+F32_fd::FileSize+2,x
		stz fd_area+F32_fd::FileSize+1,x
		stz fd_area+F32_fd::FileSize+0,x
		stz fd_area+F32_fd::offset+0,x		; init block offset/block counter
    lda #EOK
		rts

		; free file descriptor quietly
        ; in:
        ;   X - offset into fd_area
fat_close:
		debug "f_cls"
		pha
		lda #$ff    ; otherwise mark as closed
		sta fd_area + F32_fd::CurrentCluster +3, x
		pla
		rts


		; get size of file in fd
		; in:
		;   x - fd offset
		; out:
		;   a - filesize lo
		;   x - filesize hi
fat_getfilesize:
		lda fd_area + F32_fd::FileSize + 0, x
		pha
		lda fd_area + F32_fd::FileSize + 1, x
		tax
		pla
		rts

		; find first dir entry
		; in:
		;   X - file descriptor (index into fd_area) of the directory
		;	filenameptr	- with file name to search
		; out:
        ;   Z=1 on success (A=0), Z=0 and A=error code otherwise
		;	C=1 if found and dirptr is set to the dir entry found (requires Z=1), C=0 otherwise
fat_find_first:
      txa										; use the given fd as source (Y)
      tay
      ldx #FD_INDEX_TEMP_DIR					; we use the temp dir with a copy of given fd, cause F32_fd::CurrentCluster is adjusted if end of cluster is reached
      jsr __fat_clone_fd
		; in:
		;   X - file descriptor (index into fd_area) of the directory
__fat_find_first_mask:
      SetVector fat_dirname_mask, krn_ptr2	; build fat dir entry mask from user input
      jsr	string_fat_mask
      SetVector dirname_mask_matcher, fat_vec_matcher
		; in:
		;   X - file descriptor (index into fd_area) of the directory
__fat_find_first:
      SetVector block_data, read_blkptr
      lda volumeID+VolumeID::BPB + BPB::SecPerClus
      sta blocks
      jsr __calc_lba_addr
ff_l3:
      SetVector block_data, dirptr			; dirptr to begin of target buffer
      jsr __fat_read_block
      bne ff_exit
ff_l4:
      lda (dirptr)
      beq ff_exit								   ; first byte of dir entry is $00 (end of directory)
@l5:
      ldy #F32DirEntry::Attr					; else check if long filename entry
      lda (dirptr),y 							; we are only going to filter those here (or maybe not?)
      cmp #DIR_Attr_Mask_LongFilename
      beq fat_find_next

      jsr __fat_matcher           ; call matcher strategy
      lda #EOK                    ; Z=1 (success) and no error 
      bcs ff_end                  ; if C=1 we had a match

		; in:
		;   X - directory fd index into fd_area
        ; out:
        ;   Z=1 on success (A=0), Z=0 and A=error code otherwise
fat_find_next:
      lda dirptr
      clc
      adc #DIR_Entry_Size
      sta dirptr
      bcc @l6
      inc dirptr+1
@l6:
      lda dirptr+1
      cmp #>(sd_blktarget + sd_blocksize)	; end of block reached?
      bcc ff_l4			; no, process entry
      dec blocks			;
      beq @ff_eoc			; end of cluster reached?
      jsr inc_lba_address	; increment lba address to read next block
      bra ff_l3
@ff_eoc:
      ldx #FD_INDEX_TEMP_DIR					; TODO FIXME dont know if this is a good idea... FD_INDEX_TEMP_DIR was setup above and following the cluster chain is done with the FD_INDEX_TEMP_DIR to not clobber the FD_INDEX_CURRENT_DIR
      jsr __fat_read_cluster_block_and_select
      debug "feoc"
      bne ff_exit								; read error...
      bcs ff_exit								; EOC reached?
      jsr __fat_next_cln        ; select next cluster
      bra __fat_find_first		  ; C=0, go on with next cluster
ff_exit:
      clc										    ; we are at the end, C=0 and return
      debug "ffex"
ff_end:
      rts

		; in:
		;	X - file descriptor of directory
		; out:
		;	C=0 if directory is empty or contains <=2 entries ("." and ".."), C=1 otherwise
__fat_dir_isempty:
		phx
		jsr __fat_count_direntries
		cmp #3							; >= 3 dir entries, must be more then only the "." and ".."
		bcc @l_exit
		lda #ENOTEMPTY
@l_exit:
		plx
		rts

__fat_count_direntries:
		stz krn_tmp3
		SetVector @l_all, filenameptr
		jsr __fat_find_first_mask		; find within dir given in X
		bcc @l_exit
@l_next:
		lda (dirptr)
		cmp #DIR_Entry_Deleted
		beq @l_find_next
		inc	krn_tmp3
@l_find_next:
		jsr fat_find_next
		bcs	@l_next
@l_exit:
		lda krn_tmp3
		;debug "f_cnt_d"
		rts
@l_all:
		.asciiz "*.*"

__fat_unlink:
		jsr __fat_isroot						; no clnr assigned yet, file was just touched
		beq @l_unlink_direntry					; if so, we can skip freeing clusters from fat

		jsr __fat_free_cluster					; free cluster, update fsinfo
		bne	@l_exit
@l_unlink_direntry:
		jsr __fat_read_direntry					; read the dir entry
		bne	@l_exit
		lda	#DIR_Entry_Deleted					; mark dir entry as deleted ($e5)
		sta (dirptr)
		jsr __fat_write_block_data				; write back dir entry
@l_exit:
		;debug "_ulnk"
		rts

__fat_is_dot_dir:
		lda #'.'
		cmp (dirptr)
		bne @l_exit
		ldy #10
		lda #' '
@l_next:
		cmp (dirptr),y
		bne @l_exit
		dey
		bne @l_next
@l_exit:
		rts

__fat_matcher:
		jmp	(fat_vec_matcher)

l_dot_dot:
		.asciiz ".."