# ***
# *** Create VICE SuperCPU ROM image
# ***

# header
dd if=scpu64-orig.bin of=scpu64 bs=256 count=1
# basic #1
# hi_basic #1
cat basic-orig.bin >> scpu64
# kernal #1
dd if=c64-rom.bin bs=256 skip=5 count=27 >> scpu64
# hi_basic #2
dd if=basic-orig.bin bs=256 skip=32 >> scpu64
# kernal #2
dd if=c64-rom.bin bs=256 skip=5 count=27 >> scpu64
# rest
dd if=scpu64-orig.bin skip=97 bs=256 >> scpu64

# ***
# Create VICE C64 KERNAL ROM image
# ***

dd if=basic-orig.bin bs=256 skip=32         >  e000.bin
dd if=c64-rom.bin    bs=256 skip=5 count=27 >> e000.bin
