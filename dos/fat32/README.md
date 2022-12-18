# FAT32 Library for 65C02

*by Frank van den Hoef, Michael Steil*

This is a generic and reusable FAT32 filesystem read/write library written in 65C02 assembly.

## Features

* read and write support
* long filenames
* subdirectories
* time stamps
* volume label
* file system creation
* SD card driver – just add your own byte transmission code. e.g. [SPI for VIA 65c22](https://bitbucket.org/steckschwein/steckschwein-code/src/master/steckos/libsrc/spi/)
* detects swapping SD cards
* MBR partition table support
* multiple partitions mounted at the same time
* supports filesystems from 32 MB to 2 TB

## Requirements

* 65C02 CPU (could run on 6502 with help of [65c02inc](https://github.com/commanderx16/x16-rom/blob/68cec17c700bd9666dc49f801e0853af4e417ebf/cbdos/65c02.inc))
* about 8 KB of code space
* about 5 KB of RAM
* 8 bytes in the zero page

## API

Arguments and return data is passed in registers as well as following locations in memory:
* the `fat32_ptr`/`fat32_ptr2` zero page pointers, for zero-terminated paths.
* the `fat32_size` memory dword for sizes.
* the `fat32_dirent` structure for directory entries.
* `fat32_time_year`, `fat32_time_month`, `fat32_time_day`, `fat32_time_hours`, `fat32_time_minutes` and `fat32_time_seconds` for the current time, so the library can set file timestamps. (`fat32_time_year` is 1980-based.)

All paths use the Unix convention. `file.txt` specifies a file in the current directory, `subdir/file.txt` and `../file.txt` are relative paths, and `/subdir/file.txt` is an absolute path.

All API calls return C=1 for success and C=0 for error. If C=1, the `fat32_errno` global variable is set with the error code.

### Init

* `fat32_init`: Initialize library.

### Contexts

Most API calls require a context to be allocated and set. Contexts are associated with a partition. Partition numbers are 0-3 for the four primary MBR partitions. Partitions are mounted on demand.

* `fat32_alloc_context`: Allocate a context. Pass partition number in A. Returns context in A.
* `fat32_free_context`: Free a context. Pass context in A.
* `fat32_set_context`: Set current context. Pass context in A.
* `fat32_get_context`: Get current context. Returns context in A.

### File Contents

* `fat32_open`: Open existing file. Pass path in `fat32_ptr`.
* `fat32_create`: Create new file. Pass path in `fat32_ptr`, C=1 to overwrite.
* `fat32_close`: Close open file. The timestamp will be updated from `fat32_time_year` etc.
* `fat32_read`: Read from file. Pass pointer in `fat32_ptr`, size in `fat32_size`. Returns bytes read in `fat32_size`.
* `fat32_write`: Write to file. Pass pointer in `fat32_ptr`, size in `fat32_size`.
* `fat32_read_byte`: Read a byte from open file. Returns byte in A.
* `fat32_write_byte`: Write a byte to open file. Pass byte in A.
* `fat32_get_offset`: Get current offset in file. Returns value in `fat32_size`.
* `fat32_seek`: Set current offset in file. Pass value in `fat32_size`. Values greater than the file size will set the pointer to the end of the file.

### Directory Entry Enumeration

* `fat32_open_dir`: Start enumerating dir. Pass path in `fat32_ptr` (or NULL for current).
* `fat32_read_dirent`: Enumerate next dir entry. Returns dir entry in struct `fat32_dirent`.
* `fat32_read_dirent_filtered`: Same as above, but uses filename filer. Pass filter in `fat32_ptr`.
* `fat32_find_dirent`: Read single dir entry. Pass path in `fat32_ptr`, returns dir entry in struct `fat32_dirent`.
* `fat32_open_tree`: Reset the cwd enumeration state
* `fat32_walk_tree`: When called iteratively, first return the cwd in `fat32_dirent`, then its parent, and so on until you reach the root.

### Directory Entry Manipulation

* `fat32_delete`: Delete file. Pass path in `fat32_ptr`.
* `fat32_rename`: Rename file. Pass old path in `fat32_ptr`, and new path in `fat32_ptr2`.
* `fat32_set_attribute`: Set file/directory attribute. Pass path in `fat32_ptr`.

### Subdirectories

* `fat32_chdir`: Change directory. Pass path in `fat32_ptr`.
* `fat32_mkdir`: Make subdirectory. Pass path in `fat32_ptr`.
* `fat32_rmdir`: Remove subdirectory. Pass path in `fat32_ptr`.

### Other

* `fat32_get_vollabel`: Get volume label. Returns label in `fat32_dirent::name`.
* `fat32_set_vollabel`: Set volume label. Pass in `fat32_ptr`.
* `fat32_get_free_space`: Get free space in KB. Returns value in `fat32_size`.
* `fat32_mkfs`: Create a new filesystem. Pass partition number in A, sectors per cluster in X (0: default), volume label in `fat32_ptr`, volume ID (4 bytes) in `fat32_ptr2` and OEM name (8 chars) in `fat32_bufptr`.
	* *Note*: With the default cluster size, the implementation trades off storage efficiency for read/write speed, i.e. it uses the largest possible cluster size, which wastes space, but reduces the number of FAT accesses during the use of the filesystem.

### Partition Table

* `fat32_get_ptable_entry`: Get partition table entry. Requires a context with no partition allocated (A = $FF). Pass partition number (0-3) in A. Returns name, type, start LBA and size in sectors in `fat32_dirent`.

### Callbacks

Some following functions need to be implemented in user code.

The FAT32 filesystem uses UCS-2 (16 bit Unicode) and CP437 (IBM PC encoding) internally, and calls the user to convert between these and the user's preferred 8 bit character encoding:

* `filename_char_ucs2_to_internal`: Convert UCS-2 character to private 8 bit encoding. Passes char in A:X, return char in A.
* `filename_char_internal_to_ucs2`: Convert character in private 8 bit encoding to UCS-2. Passes char in A, return char in X:A.
* `filename_cp437_to_internal`: Convert CP437 character to private 8 bit encoding. Passes char in A, return char in A.
* `filename_char_internal_to_cp437`: Convert character in private 8 bit encoding to CP437. Passes char in A, return char in A.

The library does not have any policy on filename matching (i.e. case sensitive/insensitive) or wildcard semantics. It calls the user to match names and file types:

* `match_name`: Decide whether a name of a file on disk matches a given name/mask. Passes name in `fat32_ptr` at offet Y, mask in `fat32_dirent`, return C=1 if matched.
* `match_type`: Decide whether a type of a file on disk matches an arbitrary filter. Passes type in A, return C=1 if matched.

## License

Copyright 2020 Frank van den Hoef, Michael Steil <<mist64@mac.com>>

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

