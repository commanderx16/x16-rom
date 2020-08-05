# FAT32 Library for 65C02

This is a generic and reusable FAT32 filesystem read/write library written in 65C02 assembly.

## Features

* read and write support
* subdirectories
* long filenames
* SD card interface included
* multiple MBR partitions mounted at the same time

## Missing Features

* time stamps
* seek

## API

Arguments and return data is passed in registers as well as following locations in memory:
* the `fat32_ptr`/`fat32_ptr2` zero page pointers, for zero-terminated paths.
* the `fat32_size` memory dword for sizes.
* the `fat32_dirent` structure for directory entries.

All paths use the Unix convention. `file.txt` specifies a file in the current directory, `subdir/file.txt` and `../file.txt` are relative paths, and `/subdir/file.txt` is an absolute path.

All API calls return C=1 for success and C=0 for error. If C=1, the `fat32_errno` global variable is set with the error code.

### Generic

* `fat32_init`: Mount filesystem
* `fat32_get_free_space`: Get free space in KB. Returns value in `fat32_size`.

### Contexts

* `fat32_alloc_context`: Allocate a context. Pass partition number (0-3, or $FF for none) in A. Returns context in A.
* `fat32_free_context`: Free a context. Pass context in A.
* `fat32_set_context`: Set current context. Pass context in A.
* `fat32_get_context`: Get current context. Returns context in A.

Contexts are associated with a partition. All calls of the following sections require a context allocated and set.

### File Contents

* `fat32_open`: Open existing file. Pass path in `fat32_ptr`.
* `fat32_create`: Create new file. Pass path in `fat32_ptr`, C=1 to overwrite.
* `fat32_close`: Close open file.
* `fat32_read`: Read from file. Pass pointer in `fat32_ptr`, size in `fat32_size`. Returns bytes read in `fat32_size`.
* `fat32_write`: Write to file. Pass pointer in `fat32_ptr`, size in `fat32_size`.
* `fat32_read_byte`: Read a byte from open file. Returns byte in A.
* `fat32_write_byte`: Write a byte to open file. Pass byte in A.
* `fat32_get_offset`: Get current offset in file. Returns value in `fat32_size`.

### Generic File Access

* `fat32_delete`: Delete file. Pass path in `fat32_ptr`.
* `fat32_rename`: Rename file. Pass old path in `fat32_ptr`, and new path in `fat32_ptr2`.
* `fat32_set_attribute`: Set file/directory attribute. Pass path in `fat32_ptr`.

### Directory Enumeration

* `fat32_open_dir`: Start enumerating dir. Pass path in `fat32_ptr` (or NULL for current).
* `fat32_read_dirent`: Enumerate next dir entry. Returns dir entry in struct `fat32_dirent`.
* `fat32_read_dirent_filtered`: Same as above, but uses filename filer. Pass filter in `fat32_ptr`.
* `fat32_find_dirent`: Read single dir entry. Pass path in `fat32_ptr`, returns dir entry in struct `fat32_dirent`.

### Subdirectories

* `fat32_chdir`: Change directory. Pass path in `fat32_ptr`.
* `fat32_mkdir`: Make subdirectory. Pass path in `fat32_ptr`.
* `fat32_rmdir`: Remove subdirectory. Pass path in `fat32_ptr`.

### Other

* `fat32_get_vollabel`: Get volume label. Returns label in `fat32_dirent::name`.
* `fat32_set_vollabel`: Set volume label. Pass in `fat32_ptr`.

### Partition Table

* `fat32_get_ptable_entry`: Get partition table entry. Requires a context with no partition allocated (A = $FF). Pass index (0-3) in A. Returns name, type, start LBA and size in sectors in `fat32_dirent`.

### Callbacks

Some following functions need to be implemented in user code.

The FAT32 library uses UCS-2 (16 bit Unicode) internally, and calls the user to convert between UCS-2 and the user's preferred 8 bit character encoding:

* `filename_char_16_to_8`: Convert UCS-2 character to private 8 bit encoding. Passes char in A:X, return char in A.
* `filename_char_8_to_16`: Convert character in private 8 bit encoding to UCS-2. Passes char in A, return char in X:A

The library does not have any policy on filename matching (i.e. case sensitive/insensitive) or wildcard semantics. It calls the user to match names and file types:

* `match_name`: Decide whether a name of a file on disk matches a given name/mask. Passes name in `fat32_ptr` at offet Y, mask in `fat32_dirent`, return C=1 if matched.
* `match_type`: Decide whether a type of a file on disk matches an arbitrary filter. Passes type in A, return C=1 if matched.

## Authors

Written by Frank van den Hoef. LFN support by Michael Steil.
