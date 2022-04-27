# CMDR-DOS: Commodore DOS on FAT32

**CMDR-DOS** is an open source 65c02 reimplementation of Commodore DOS, the OS and disk API of Commodore 8 bit disk drives (like the 1541). It works on FAT32 filesystems (32 MB to 2 TB) and supports CMD-style partitions, subdirectories, timestamps and filenames up to 255 characters. It is the DOS built into the [Commander X16](https://www.commanderx16.com).

This is the base features set compared to other Commodore DOS devices:

| Feature          | 1541 | 1571/1581 | CMD HD/FD | SD2IEC   | *CMDR-DOS*      |
|------------------|------|-----------|-----------|----------|-----------------|
| Sequential files | yes  | yes       | yes       | yes      | yes             |
| Relative files   | yes  | yes       | yes       | yes      | not yet         |
| Block access     | yes  | yes       | yes       | yes      | not yet         |
| Code execution   | yes  | yes       | yes       | no       | yes             |
| Burst commands   | no   | yes       | yes       | no       | no              |
| Timestamps       | no   | no        | yes       | yes      | yes             |
| Time API         | no   | no        | yes       | yes      | not yet         |
| Partitions       | no   | no        | yes       | yes      | yes             |
| Subdirectories   | no   | no        | yes       | yes      | yes             |

It consists of the following components:

* Commodore DOS interface
	* `main.s`: TALK/LISTEN dispatching
	* `parser.s`: filename/path parsing
	* `cmdch.s`: command channel parsing, status messages
	* `file.s`: file read/write
* FAT32 interface
	* `match.s`: FAT32 character set conversion, wildcard matching
	* `dir.s`: FAT32 directory listing
	* `function.s`: command implementations for FAT32
* FAT32 implementation
	* `fat32/*`: [FAT32 for 65c02 library](https://github.com/commanderx16/x16-rom/tree/master/dos/fat32)

CMDR-DOS implements the TALK/LISTEN layer (Commodore Peripheral Bus layer 3), it can therefore be directly hooked up to the Commodore IEEE KERNAL API (`talk`, `tksa`, `untlk`, `listn`, `secnd`, `unlsn`, `acptr`, `ciout`) and be used as a computer-based DOS, like on the C65 and the X16.

CMDR-DOS does not contain a layer 2 implementation, i.e. IEEE-488 (PET) or Commodore Serial (C64, C128, ...). By adding a Commodore Serial (aka "IEC") implementation, CMDR-DOS could be adapted for use as the system software of a standalone 65c02-based Serial device for Commodore computers, similar to an sd2iec device.

The Commodore DOS side and the FAT32 side are well separated, so a lot of code could be reused for a DOS that uses a different filesystem.

Or the core feature set, these are the supported functions:

| Feature                   | Syntax                        | Supported | Comment |
|---------------------------|-------------------------------|-----------|---------|
| Reading                   | `,?,R`                        | yes       |         |
| Writing                   | `,?,W`                        | yes       |         |
| Appending                 | `,?,A`                        | not yet   |         |
| Recovery                  | `,?,M`                        | no        | not useful on FAT32 |
| Types                     | `,S`/`,P`/`,U`/`,L`           | yes       | ignored on FAT32 |
| Overwriting               | `@:`                          | yes       |         |
| Magic channels 0/1        |                               | yes       |         |
| Channel 15 command        | _command_`:`_args_...         | yes       |         |
| Channel 15 status         | _code_`,`_string_`,`_a_`,`_b_ | yes       |         |
| CMD partition syntax      | `0:`/`1:`/...                 | yes       |         |
| CMD subdirectory syntax   | `//DIR/:`/`/DIR/:`            | yes       |         |
| Directory listing         | `$`                           | yes       |         |
| Dir with name filtering   | `$:FIL*`                      | yes       |         |
| Dir with type filtering   | `$:*=P`/`$:*=D`/`$:*=A`       | yes       |         |
| Dir with timestamps       | `$=T`                         | yes       | but with ISO syntax |
| Dir with time filtering   | `$=T<`/`$=T<`                 | not yet   |         |
| Partition listing         | `$=P`                         | yes       |         |
| Partition filtering       | `$:NAME*=P`                   | no        |         |

And this table shows which of the standard commands are supported:

| Name             | Syntax                                                | Description                     | Supported |
|------------------|-------------------------------------------------------|---------------------------------|-----------|
| BLOCK-ALLOCATE   | `B-A` _medium_ _medium_ _track_ _sector_              | Allocate a block in the BAM     | no<sup>1</sup>|
| BLOCK-EXECUTE    | `B-E` _channel_ _medium_ _track_ _sector_             | Load and execute a block        | not yet   |
| BLOCK-FREE       | `B-F` _medium_ _medium_ _track_ _sector_              | Free a block in the BAM         | no<sup>1</sup>|
| BLOCK-READ       | `B-R` _channel_ _medium_ _track_ _sector_             | Read block                      | no<sup>1</sup>|
| BLOCK-STATUS     | `B-S` _channel_ _medium_ _track_ _sector_             | Check if block is allocated     | no<sup>1</sup>|
| BLOCK-WRITE      | `B-W` _channel_ _medium_ _track_ _sector_             | Write block                     | no<sup>1</sup>|
| BUFFER-POINTER   | `B-P` _channel_ _index_                               | Set r/w pointer within buffer   | not yet   |
| CHANGE DIRECTORY | `CD`[_path_]`:`_name_                                 | Change the current sub-directory| yes       |
| CHANGE DIRECTORY | `CD`[_medium_]`:←`                                    | Change sub-directory up         | yes       |
| CHANGE PARTITION | `CP` _num_                                            | Make a partition the default    | yes       |
| COPY             | `C`[_path_a_]`:`_target_name_`=`[_path_b_]`:`_source_name_[`,`...] | Copy/concatenate files | yes   |
| COPY             | `C`_dst_medium_`=`_src_medium_                        | Copy all files between disk     | no<sup>1</sup>|
| DUPLICATE        | `D:`_dst_medium_``=``_src_medium_                     | Duplicate disk                  | no<sup>1</sup>|
| FILE LOCK        | `F-L`[_path_]`:`_name_[`,`...]                        | Enable file write-protect       | yes       |
| FILE RESTORE     | `F-R`[_path_]`:`_name_[`,`...]                        | Restore a deleted file          | not yet   |
| FILE UNLOCK      | `F-U`[_path_]`:`_name_[`,`...]                        | Disable file write-protect      | yes       |
| GET DISKCHANGE   | `G-D`                                                 | Query disk change               | yes       |
| GET PARTITION    | `G-P` _num_                                           | Get information about partition | yes       |
| INITIALIZE       | `I`[_medium_]                                         | Re-mount filesystem             | yes       |
| LOCK             | `L`[_path_]`:`_name_                                  | Toggle file write protect       | yes       |
| MAKE DIRECTORY   | `MD`[_path_]`:`_name_                                 | Create a sub-directory          | yes       |
| MEMORY-EXECUTE   | `M-E` _addr_lo_ _addr_hi_                             | Execute code                    | yes       |
| MEMORY-READ      | `M-R` _addr_lo_ _addr_hi_ [_count_]                   | Read RAM                        | yes       |
| MEMORY-WRITE     | `M-W` _addr_lo_ _addr_hi_ _count_ _data_              | Write RAM                       | yes       |
| NEW              | `N`[_medium_]`:`_name_`,`_id_`,FAT32`                 | File system creation            | yes<sup>3</sup>|
| PARTITION        | `/`[_medium_][`:`_name_]                              | Select 1581 partition           | no        |
| PARTITION        | `/`[_medium_]`:`_name_`,`_track_ _sector_ _count_lo_ _count_hi_ `,C` | Create 1581 partition | no   |
| POSITION         | `P` _channel_ _record_lo_ _record_hi_ _offset_        | Set record index in REL file    | not yet   |
| REMOVE DIRECTORY | `RD`[_path_]`:`_name_                                 | Delete a sub-directory          | yes       |
| RENAME           | `R`[_path_]`:`_new_name_`=`_old_name_                 | Rename file                     | yes       |
| RENAME-HEADER    | `R-H`[_medium_]`:`_new_name_                          | Rename a filesystem             | yes       |
| RENAME-PARTITION | `R-P:`_new_name_`=`_old_name_                         | Rename a partition              | no<sup>1</sup>|
| SCRATCH          | `S`[_path_]`:`_pattern_[`,`...]                       | Delete files                    | yes       |
| SWAP             | `S-`{`8`&#x7c;`9`&#x7c;`D`}                           | Change primary address          | yes       |
| TIME READ ASCII  | `T-RA`                                                | Read Time/Date (ASCII)          | no<sup>4</sup>|
| TIME READ BCD    | `T-RB`                                                | Read Time/Date (BCD)            | no<sup>4</sup>|
| TIME READ DECIMAL| `T-RD`                                                | Read Time/Date (Decimal)        | no<sup>4</sup>|
| TIME READ ISO    | `T-RI`                                                | Read Time/Date (ISO)            | no<sup>4</sup>|
| TIME WRITE ASCII | `T-WA` _dow_ _mo_`/`_da_`/`_yr_ _hr_`:`_mi_`:`_se_ _ampm_ | Write Time/Date (ASCII)     | no<sup>4</sup>|
| TIME WRITE BCD   | `T-WB` _b0_ _b1_ _b2_ _b3_ _b4_ _b5_ _b6_ _b7_ _b8_   | Write Time/Date (BCD)           | no<sup>4</sup>|
| TIME WRITE DECIMAL| `T-WD` _b0_ _b1_ _b2_ _b3_ _b4_ _b5_ _b6_ _b7_       | Write Time/Date (Decimal)       | no<sup>4</sup>|
| TIME WRITE ISO   | `T-WI` _yyyy_`-`_mm_`-`_dd_`T`_hh_`:`_mm_`:`_ss_ _dow_| Write Time/Date (ISO)           | no<sup>4</sup>|
| U1/UA            | `U1` _channel_ _medium_ _track_ _sector_              | Raw read of a block             | not yet   |
| U2/UB            | `U2` _channel_ _medium_ _track_ _sector_              | Raw write of a block            | not yet   |
| U3-U8/UC-UH      | `U3` - `U8`                                           | Execute in user buffer          | not yet   |
| U9/UI            | `UI`                                                  | Soft RESET                      | yes       |
| U:/UJ            | `UJ`                                                  | Hard RESET                      | yes       |
| USER             | `U0>` _pa_                                            | Set unit primary address        | yes       |
| USER             | `U0>B` _flag_                                         | Enable/disable Fast Serial      | no        |
| USER             | `U0>D`_val_                                           | Set directory sector interleave | no<sup>1</sup>|
| USER             | `U0>H` _number_                                       | Select head 0/1                 | no<sup>1</sup>|
| USER             | `U0>L`_flag_                                          | Large REL file support on/off   | no        |
| USER             | `U0>M` _flag_                                         | Enable/disable 1541 emulation mode| no<sup>1</sup>|
| USER             | `U0>R` _num_                                          | Set number fo retries           | no<sup>1</sup>|
| USER             | `U0>S` _val_                                          | Set sector interleave           | no<sup>1</sup>|
| USER             | `U0>T`                                                | Test ROM checksum               | no<sup>5</sup>|
| USER             | `U0>V` _flag_                                         | Enable/disable verify           | no<sup>1</sup>|
| USER             | `U0>` _pa_                                            | Set unit primary address        | yes       |
| USER             | `UI`{`+`&#x7c;`-`}                                    | Use C64/VIC-20 Serial protocol  | no<sup>1</sup>|
| UTILITY LOADER   | `&`[[_path_]`:`]_name_                                | Load and execute program        | no<sup>1</sup>|
| VALIDATE         | `V`[_medium_]                                         | Filesystem check                | no<sup>2</sup>|
| WRITE PROTECT    | `W-`{`0`&#x7c;`1`}                                    | Set/unset device write protect  | yes       |

* <sup>1</sup>: outdated API, not useful, or can't be supported on FAT32
* <sup>2</sup>: is a no-op, returns `00, OK,00,00`
* <sup>3</sup>: third argument `FAT32` *has* to be passed
* <sup>4</sup>: CMDR-DOS was architected to run on the main computer, so it shouldn't be DOS that keeps track of the time
* <sup>5</sup>: Instead of testing the ROM, this command currently verifies that no buffers are allocated, otherwise it halts. This is used by unit tests to detect leaks.

The following added commands and features are specific to CMDR-DOS:

| Feature               | Syntax      | Description                                                                    |
|-----------------------|-------------|--------------------------------------------------------------------------------|
| Open for Read & Write | `,?,M`      | Allows arbitrarily reading, writing and setting the position (`P`)<sup>1</sup> |
| POSITION              | `P` _channel_ _p0_ _p1_ _p2_ _p3_  | Set position within file (like sd2iec); all args binary |

* <sup>1</sup>: once the EOF has been reached while reading, no further reads or writes are possible.

All currently unsupported commands are decoded in `cmdch.s` anyway, but hooked into `31,SYNTAX ERROR,00,00`, so adding features should be as easy as adding the implementation.

## License

Copyright 2020 Michael Steil <<mist64@mac.com>>

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

