layouts="406 407 409 40A 40B 40C 40E 410 414 415 416 41D 807 809 80C"

for layout in $layouts; do
	filename=$(ls klc/${layout}\ *.klc)
	python3 klc_to_asm.py "$filename" asm/$layout.s asm/$layout.bin asm/$layout.bin.lzsa
	lzsa -f 2 -r --prefer-ratio asm/$layout.bin asm/$layout.bin.lzsa
	rm asm/$layout.bin
done
