# header  & basic
dd if=/Users/mist/Library/Mobile\ Documents/com\~apple\~CloudDocs/Applications/xscpu64.app/Contents/Resources/ROM/SCPU64/scpu64 of=scpu64 bs=256 count=33

# kernal x2
cat c64-rom.bin >> scpu64
cat c64-rom.bin >> scpu64

# rest
dd if=/Users/mist/Library/Mobile\ Documents/com\~apple\~CloudDocs/Applications/xscpu64.app/Contents/Resources/ROM/SCPU64/scpu64 skip=97 bs=256 >> scpu64

# activate
mv scpu64 xscpu64.app/Contents/Resources/ROM/SCPU64