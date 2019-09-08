import io



def read_keymap_file(filename):
	f = io.open(filename, mode="r", encoding="utf-8")
	lines = f.readlines()
	f.close()
	
	indexes = [
		# top row, shifted
		(1, 2 + 4 * 0),
		(1, 2 + 4 * 1),
		(1, 2 + 4 * 2),
		(1, 2 + 4 * 3),
		(1, 2 + 4 * 4),
		(1, 2 + 4 * 5),
		(1, 2 + 4 * 6),
		(1, 2 + 4 * 7),
		(1, 2 + 4 * 8),
		(1, 2 + 4 * 9),
		(1, 2 + 4 * 10),
		(1, 2 + 4 * 11),
		(1, 2 + 4 * 12),
	
		# QWERTY row, shifted
		(4, 8 + 4 * 0),
		(4, 8 + 4 * 1),
		(4, 8 + 4 * 2),
		(4, 8 + 4 * 3),
		(4, 8 + 4 * 4),
		(4, 8 + 4 * 5),
		(4, 8 + 4 * 6),
		(4, 8 + 4 * 7),
		(4, 8 + 4 * 8),
		(4, 8 + 4 * 9),
		(4, 8 + 4 * 10),
		(4, 8 + 4 * 11),
		(4, 8 + 4 * 12),
	
		# ASDF row, shifted
		(7, 9 + 4 * 0),
		(7, 9 + 4 * 1),
		(7, 9 + 4 * 2),
		(7, 9 + 4 * 3),
		(7, 9 + 4 * 4),
		(7, 9 + 4 * 5),
		(7, 9 + 4 * 6),
		(7, 9 + 4 * 7),
		(7, 9 + 4 * 8),
		(7, 9 + 4 * 9),
		(7, 9 + 4 * 10),
	
		# ZXCV row, shifted
		(10, 8 + 4 * 0),
		(10, 8 + 4 * 1),
		(10, 8 + 4 * 2),
		(10, 8 + 4 * 3),
		(10, 8 + 4 * 4),
		(10, 8 + 4 * 5),
		(10, 8 + 4 * 6),
		(10, 8 + 4 * 7),
		(10, 8 + 4 * 8),
		(10, 8 + 4 * 9),
		(10, 8 + 4 * 10),
	
	]
	
	# extract characters from ASCII art
	chars_shifted = ""
	chars_unshifted = ""
	for index in indexes:
		chars_shifted += lines[index[0]][index[1]]
		chars_unshifted += lines[index[0] + 1][index[1]]
	
	# it's okay to write characters into just
	# the top row; for consistency, put them
	# into the bottom row instead (unshifted)
	chars_shifted2 = ""
	chars_unshifted2 = ""
	for i in range(0, len(chars_shifted)):
		c_shifted = chars_shifted[i]
		c_unshifted = chars_unshifted[i]
		if c_unshifted == ' ':
			c_unshifted = c_shifted
			c_shifted = ' '
		chars_shifted2 += c_shifted
		chars_unshifted2 += c_unshifted
	
	chars_shifted = chars_shifted2
	chars_unshifted = chars_unshifted2

	return (chars_unshifted, chars_shifted)


# main

# US layout is the reference
(chars_unshifted_us, chars_shifted_us) = read_keymap_file("keymap_us.txt")

(chars_unshifted, chars_shifted) = read_keymap_file("keymap_de.txt")

print(chars_shifted_us)
print(chars_unshifted_us)

print(chars_shifted)
print(chars_unshifted)

# check what keys are not reachable by localized keyboard

not_reachable = ""
for c in chars_unshifted_us + chars_shifted_us:
	if c not in (chars_unshifted + chars_shifted):
		not_reachable += c

extra_chars = ""
for c in chars_unshifted + chars_shifted:
	if c != u"\ufffd" and c not in (chars_unshifted_us + chars_shifted_us):
		extra_chars += c

print("not reachable: \"" + not_reachable + "\"")
print("extra chars:   \"" + extra_chars + "\"")
