
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

.ifndef IMPORTED_FROM_MAIN
.import fd_area, sd_blktarget
.endif

; TODO FIXME replace with errno.inc from cc65 api
fat_bad_block_signature      = $01
fat_invalid_partition_type   = $02
fat_invalid_sector_size      = $03
fat_invalid_num_fats      = $04
fat_open_error         = $05
fat_file_not_open      = $08
fat_file_not_dir      = $10
fat_file_too_large      = $11


;--------------------------------------------------------------------------------------
; partition entry
;--------------------------------------------------------------------------------------
.struct PartitionEntry
   Bootflag   .byte
   CHSBegin   .byte 3
   TypeCode   .byte
   CHSEnd      .byte 3
   LBABegin   .dword
   NumSectors   .dword
.endstruct

PartType_FAT32        = $0b
PartType_FAT32_LBA    = $0c

;--------------------------------------------------------------------------------------
; FAT bootsector and partition table
;--------------------------------------------------------------------------------------
.struct PartTable
   Partition_0   .tag PartitionEntry
   Partition_1   .tag PartitionEntry
   Partition_2   .tag PartitionEntry
   Partition_3   .tag PartitionEntry
.endstruct

.struct BootSector
   Bootcode   .byte 446
   Partitions   .tag PartTable
   Signature   .word
.endstruct

;BS_VolLab2      = 71



.struct EBPB
   FATSz32      .dword   ; 36-39 ; sectors per FAT
   MirrorFlags   .word   ; 40-41; Bits 0-3: number of active FAT (if bit 7 is 1)
                  ; Bits 4-6: reserved
                  ; Bit 7: one: single active FAT; zero: all FATs are updated at runtime
                  ; Bits 8-15: reserved
                  ; https://www.win.tue.nl/~aeb/linux/fs/fat/fat-1.html

   Version      .word   ; 42-43
   RootClus   .dword   ; 44-47
   FSInfoSec   .word   ; 48-49
   BootSectCpy .word   ; 50-51
   Reserved3   .byte 12 ; 52-63
   PhysDrvNum   .byte   ; 64
   Reserved4   .byte   ; 65
   ExtBootSig  .byte   ; 66
   VolumeID   .dword  ; 67-70
   VolumeLabel .byte 11 ; 71-82
   FSType      .byte 8   ; 83-90
.endstruct

.struct BPB
   BytsPerSec   .word ; 11-12   ; 512 usually
   SecPerClus   .byte ; 13   ; Sectors per Cluster as power of 2. valid are: 1,2,4,8,16,32,64,128
   RsvdSecCnt   .word ; 14-15   ; number of reserved sectors
   NumFATs      .byte ; 16
   Reserved   .byte 4 ; 17-20 (max root entries, total logical sectors skipped)
   Media      .byte   ; 21 ; For removable media, 0xF0 is frequently used.
            ; The legal values for this field are
            ; 0xF0, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, and 0xFF.
   SectsPerFAT .word   ; 22-23 ; Number of sectors per FAT. 0 for fat32
.endstruct

; struct VolumeID like we keep in in memory
.struct VolumeID
   BPB         .tag BPB
   EBPB      .tag EBPB
.endstruct

; struct VolumeID like found on FAT-media (bootsector)
.struct F32_VolumeID
   JmpToBoot   .byte 3     ; JMP command to bootstrap code ( in x86-world )
   OEMName      .byte 8     ; OEM name/version (E.g. "IBM  3.3", "IBM 20.0", "MSDOS5.0", "MSWIN4.0".
                       ; Various format utilities leave their own name, like "CH-FOR18".
                       ; Sometimes just garbage. Microsoft recommends "MSWIN4.1".)
                     ; https://www.win.tue.nl/~aeb/linux/fs/fat/fat-1.html

   BPB         .tag BPB

   Reserved2   .byte 12; 24-35 Placeholder until FAT32 EBPB

   ; FAT32 Extended BIOS Parameter Block begins here
   EBPB      .tag EBPB
.endstruct




;--------------------------------------------------------------------------------------
; FAT32 FSInfo Sector Offsets
;--------------------------------------------------------------------------------------
.struct F32FSInfo
   Signature1      .byte 4
   Reserved1      .byte $1e0
   Signature2      .byte 4
   FreeClus        .byte 4   ; amount of free clusters
   LastClus      .byte 4   ; last known cluster number
   Reserved2      .byte 11
   Signature      .word
.endstruct
;--------------------------------------------------------------------------------------
; FAT32 Directory Entry
;--------------------------------------------------------------------------------------
.struct F32DirEntry      ; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system
   Name            .byte 8
   Ext            .byte 3
   Attr            .byte
   Reserved         .byte
   CrtTimeMillis   .byte
   CrtTime         .word   ; hours as 0-23 bit 15-11, minutes as 0-59 bit 10-5, seconds/2 as 0-29 bit 4-0
   CrtDate         .word   ; year 0-119 (0=1980...127=2107) bit 15-9, month 1-12 bit 8-5, day 1-31 bit 4-0
   LstModDate      .word   ; -""-
   FstClusHI      .word
   WrtTime         .word   ; hours as 0-23 bit 15-11, minutes as 0-59 bit 10-5, seconds/2 as 0-29 bit 4-0
   WrtDate         .word   ; year 0-119 (0=1980...127=2107) bit 15-9, month 1-12 bit 8-5, day 1-31 bit 4-0
   FstClusLO      .word
   FileSize         .dword
.endstruct

DIR_Attr_Mask_ReadOnly  = 1<<0;
DIR_Attr_Mask_Hidden    = 1<<1;
DIR_Attr_Mask_System    = 1<<2;
DIR_Attr_Mask_Volume    = 1<<3;
DIR_Attr_Mask_Dir       = 1<<4;
DIR_Attr_Mask_Archive   = 1<<5;

DIR_Attr_Mask_LongFilename   = 1<<0 | 1<<1 | 1<<2 | 1<<3;
DIR_Entry_Size               = .sizeof(F32DirEntry)
DIR_Entry_Deleted            = $e5
;--------------------------------------------------------------------------------------
; File descriptor struct
;--------------------------------------------------------------------------------------

.struct Seek
			Whence	.byte		; SEEK_SET - OFFSET is the absolute file position (an offset from the beginning of the file) desired.  OFFSET must be positive.
									; SEEK_CUR - OFFSET is relative to the current file position.  OFFSET can meaningfully be either positive or negative.
									; SEEK_END - OFFSET is relative to the current end of file.  OFFSET can meaningfully be either positive (to increase the size of the file) or negative.
			Offset	.dword
.endstruct

.struct F32_fd
    CurrentCluster  .dword; (4bt)
    FileSize        .dword; (4bt)
    Attr            .byte;  (1bt)
    DirEntryLBA     .dword; (4bt)	LBA of the block where the dir entry of the file is located
    DirEntryPos     .byte;  (1bt)	block offset within the block (DirEntryPos * DIR_Entry_Size)
    offset          .byte;  (1bt) 7Bit block number of the CurrentCluster
;	TODO FIXME offset          .word;	(2bt) 9Bit (MSB) offset within block, 7Bit (LSB) block number of the CurrentCluster
;   SeekPos        .dword;	(4bt) seek position within the opened file
;   openFlags     .byte; +1 flags during open
.endstruct

FD_Entry_Size         = .sizeof(F32_fd)
FD_Entries_Max        = <((sd_blktarget - fd_area) / FD_Entry_Size)
FD_INDEX_CURRENT_DIR  = 0*FD_Entry_Size    ; current dir always go to fd #0
FD_INDEX_TEMP_DIR     = 1*FD_Entry_Size   ; temp dir always go to fd #1

; TODO: do we need these?
;BS_BootSig      = 38
;BS_VolID      = 39
;BS_VolLab      = 43
;BS_FilSysType   = 54   ; One of the strings “FAT12 ”, “FAT16 ”, or “FAT ”.

FAT_EOC         = $0fffffff   ; end of cluster chain marker

sd_blocksize          = $200


