import io, re, codecs, sys
import pprint

REG   = 0
SHFT  = 1
CTRL  = 2
ALT   = 4
ALTGR = 6

def get_kbd_layout(filename_klc):
	f = io.open(filename_klc, mode="r", encoding="utf-16")
	lines = f.readlines()
	f.close()
	lines = [x.strip() for x in lines]
	
	keywords = [ 'KBD', 'COPYRIGHT', 'COMPANY', 'LOCALENAME', 'LOCALEID', 'VERSION', 'SHIFTSTATE', 'LAYOUT', 'DEADKEY', 'KEYNAME', 'KEYNAME_EXT', 'KEYNAME_DEAD', 'DESCRIPTIONS', 'LANGUAGENAMES', 'ENDKBD' ]
	
	sections = []
	section = []
	
	while len(lines) > 0:
		while True:
			line = lines[0]
			lines = lines[1:]
			i = line.find('//')
			if i != -1:
				line = line[:i]
			line = line.rstrip()
			if len(line) == 0:
				continue
			fields = re.split(r'\t', line)
			while '' in fields:
				fields.remove('')
			break
	
		if fields[0] in keywords:
			if (len(section)) > 0:
				sections.append(section)
			section = []
	
		section.append(fields)
				
	
	#	print(sections)
	
	kbd_layout = {}
	for lines in sections:
		fields = lines[0]
		if fields[0] == 'KBD':
			kbd_layout['short_id'] = fields[1]
			kbd_layout['name'] = fields[2].replace('"', '')
		elif fields[0] == 'COPYRIGHT':
			kbd_layout['copyright'] = fields[1].replace('"', '')
		elif fields[0] == 'COMPANY':
			kbd_layout['company'] = fields[1]
		elif fields[0] == 'LOCALENAME':
			kbd_layout['localename'] = fields[1].replace('"', '')
		elif fields[0] == 'LOCALEID':
			kbd_layout['localeid'] = fields[1].replace('"', '')
		elif fields[0] == 'VERSION':
			kbd_layout['version'] = fields[1]
		elif fields[0] == 'SHIFTSTATE':
			shiftstates = []
			for fields in lines[1:]:
				shiftstates.append(int(fields[0]))
			kbd_layout['shiftstates'] = shiftstates
		elif fields[0] == 'LAYOUT':
			layout = {}
			for fields in lines[1:]:
				chars = {}
				i = 3
				for shiftstate in shiftstates:
					c = fields[i]
					if c != '-1':
						if len(c) > 1:
							c = chr(int(c[0:4], 16))
						chars[shiftstate] = c
					i += 1
				# TODO: c[4] == '@' -> dead key
				layout[int(fields[0], 16)] = {
					#'vk_name': 'VK_' + fields[1],
					#'cap': int(fields[2]),
					'chars': chars
				}
			kbd_layout['layout'] = layout
		elif fields[0] == 'DEADKEY':
			# TODO
			pass	
		elif fields[0] == 'KEYNAME':
			# TODO
			pass	
		elif fields[0] == 'KEYNAME_EXT':
			# TODO
			pass	
		elif fields[0] == 'KEYNAME_DEAD':
			# TODO
			pass	
		elif fields[0] == 'DESCRIPTIONS':
			# TODO
			pass	
		elif fields[0] == 'LANGUAGENAMES':
			# TODO
			pass	

	return kbd_layout

def ps2_set2_code_from_hid_code(c):
	mapping = { 0x01: 0x76, 0x02: 0x16, 0x03: 0x1E, 0x04: 0x26, 0x05: 0x25, 0x06: 0x2E, 0x07: 0x36, 0x08: 0x3D, 0x09: 0x3E, 0x0A: 0x46, 0x0B: 0x45, 0x0C: 0x4E, 0x0D: 0x55, 0x0E: 0x66, 0x0F: 0x0D, 0x10: 0x15, 0x11: 0x1D, 0x12: 0x24, 0x13: 0x2D, 0x14: 0x2C, 0x15: 0x35, 0x16: 0x3C, 0x17: 0x43, 0x18: 0x44, 0x19: 0x4D, 0x1A: 0x54, 0x1B: 0x5B, 0x1C: 0x5A, 0x1E: 0x1C, 0x1F: 0x1B, 0x20: 0x23, 0x21: 0x2B, 0x22: 0x34, 0x23: 0x33, 0x24: 0x3B, 0x25: 0x42, 0x26: 0x4B, 0x27: 0x4C, 0x28: 0x52, 0x29: 0x0E, 0x2B: 0x5D, 0x2B: 0x5D, 0x2C: 0x1A, 0x2D: 0x22, 0x2E: 0x21, 0x2F: 0x2A, 0x30: 0x32, 0x31: 0x31, 0x32: 0x3A, 0x33: 0x41, 0x34: 0x49, 0x35: 0x4A, 0x39: 0x29, 0x3A: 0x58, 0x3B: 0x05, 0x3C: 0x06, 0x3D: 0x04, 0x3E: 0x0C, 0x3F: 0x03, 0x40: 0x0B, 0x41: 0x83, 0x42: 0x0A, 0x43: 0x01, 0x44: 0x09, 0x53: 0x71, 0x56: 0x61, 0x57: 0x78, 0x58: 0x07 }
	if c in mapping:
		return mapping[c]
	else:
		return 0

def petscii_from_ascii(c):
	if c == '\\' or c == '|' or c == '_' or c == '{' or c == '}' or c == '~':
		return chr(0)
	if ord(c) == 0xa3: # '£'
		return chr(0x5c)
	if ord(c) >= ord('A') and ord(c) <= ord('Z'):
		return chr(ord(c) + 0x80)
	if ord(c) >= ord('a') and ord(c) <= ord('z'):
		return chr(ord(c) - 0x20)
	if ord(c) < 0x20 and c != '\r':
		return chr(0)
	if ord(c) >= 0x7e:
		return chr(0)
	return c

# constants

# a string with all printable 7-bit PETSCII characters
all_petscii_chars = " !\"#$%&'()*+,-./0123456789:;<=>?@"
for c in "abcdefghijklmnopqrstuvwxyz":
	all_petscii_chars += chr(ord(c) - 0x20)
all_petscii_chars += "[£]^←ABCDEFGHIJKLMNOPQRSTUVWXYZπ"

# all PETSCII control codes and their descriptions
control_codes = {
	0x03: 'RUN/STOP',
	0x05: 'WHITE',
	0x08: 'SHIFT_DISABLE',
	0x09: 'SHIFT_ENABLE',
	0x0d: 'CR',
	0x0e: 'TEXT_MODE',
	0x11: 'CURSOR_DOWN',
	0x12: 'REVERSE_ON',
	0x13: 'HOME',
	0x14: 'DEL',
	0x1c: 'RED',
	0x1d: 'CURSOR_RIGHT',
	0x1e: 'GREEN',
	0x1f: 'BLUE',
	0x81: 'ORANGE',
	0x85: 'F1',
	0x86: 'F3',
	0x87: 'F5',
	0x88: 'F7',
	0x89: 'F2',
	0x8a: 'F4',
	0x8b: 'F6',
	0x8c: 'F8',
	0x8d: 'SHIFT+CR',
	0x8e: 'GRAPHICS',
	0x90: 'BLACK',
	0x91: 'CURSOR_UP',
	0x92: 'REVERSE_OFF',
	0x93: 'CLR',
	0x94: 'INSERT',
	0x95: 'BROWN',
	0x96: 'LIGHT_RED',
	0x97: 'DARK_GRAY',
	0x98: 'MIDDLE_GRAY',
	0x99: 'LIGHT_GREEN',
	0x9a: 'LIGHT_BLUE',
	0x9b: 'LIGHT_GRAY',
	0x9c: 'PURPLE',
	0x9d: 'CURSOR_LEFT',
	0x9e: 'YELLOW',
	0x9f: 'CYAN',
	0xa0: 'SHIFT+SPACE',
}
all_petscii_codes = ""
for c in control_codes.keys():
	all_petscii_codes += chr(c)

# all printable PETSCII graphics characters
all_petscii_graphs = ""
for c in range(0xa1, 0xc2):
	all_petscii_graphs += chr(c)
for c in range(0xe0, 0xff):
	all_petscii_graphs += chr(c)

# the following PETSCII control codes do not have to be reachable
# through the keyboard
all_petscii_codes_ok_if_missing = [
	chr(0x1d), # CURSOR_RIGHT - covered by cursor keys
	chr(0x8e), # GRAPHICS     - not covered on C64 either
	chr(0x91), # CURSOR_UP    - covered by cursor keys
	chr(0x93), # CLR          - convered by E0-prefixed key
	chr(0x9d), # CURSOR_LEFT  - covered by cursor keys
]

#filename_klc = '40C French.klc'
#filename_klc = '419 Russian.klc'
#filename_klc = '409 US.klc'
filename_klc = '407 German.klc'
#filename_klc = '809 United Kingdom.klc'

kbd_layout = get_kbd_layout(filename_klc)

layout = kbd_layout['layout']
shiftstates = kbd_layout['shiftstates']

keytab = {}
for shiftstate in shiftstates:
	keytab[shiftstate] = [ '\0' ] * 128
# some layouts don't define Alt at all
if not ALT in keytab:
	keytab[ALT] = [ '\0' ] * 128

# create PS/2 Code 2 -> PETSCII tables
ascii_not_reachable = ""
for hid_scancode in layout.keys():
	ps2_scancode = ps2_set2_code_from_hid_code(hid_scancode)
	l = layout[hid_scancode]['chars']
	for shiftstate in keytab.keys():
		if shiftstate in l:
			c_ascii = l[shiftstate]
			c_petscii = petscii_from_ascii(c_ascii)
			if c_petscii == chr(0):
				if not c_ascii in ascii_not_reachable:
					ascii_not_reachable += c_ascii
			keytab[shiftstate][ps2_scancode] = c_petscii


# fold AltGr into Alt
if ALTGR in keytab:
	if ALT in keytab:
		# combine
		for scancode in range(0, len(keytab[ALT])):
			if keytab[ALT][scancode] == chr(0):
				keytab[ALT][scancode] = keytab[ALTGR][scancode]
	else:
		# move
		keytab[ALT] = keytab[ALTGR]
	keytab.pop(ALTGR)
if SHFT+ALTGR in keytab:
	if SHFT+ALT in keytab:
		sys.exit("TODO: combine Shft+AltGr and Shft+Alt")
	keytab[SHFT+ALT] = keytab[SHFT+ALTGR]
	keytab.pop(SHFT+ALTGR)

# stamp in f-keys independent of shiftstate
for shiftstate in keytab.keys():
	keytab[shiftstate][2] = chr(0x88)
	keytab[shiftstate][3] = chr(0x87)
	keytab[shiftstate][4] = chr(0x86)
	keytab[shiftstate][5] = chr(0x85)
	keytab[shiftstate][6] = chr(0x89)
	keytab[shiftstate][10] = chr(0x8c)
	keytab[shiftstate][11] = chr(0x8b)
	keytab[shiftstate][12] = chr(0x8a)

# stamp in Ctrl/Alt color codes
petscii_from_ctrl_scancode = [ # Ctrl
	(0x16, 0x90), # '1'
	(0x1e, 0x05), # '2'
	(0x26, 0x1c), # '3'
	(0x25, 0x9f), # '4'
	(0x2e, 0x9c), # '5'
	(0x36, 0x1e), # '6'
	(0x3d, 0x1f), # '7'
	(0x3e, 0x9e), # '8'
	(0x46, 0x12), # '9' REVERSE ON
	(0x45, 0x92), # '0' REVERSE OFF
]
petscii_from_alt_scancode = [ # Alt
	(0x16, 0x81), # '1'
	(0x1e, 0x95), # '2'
	(0x26, 0x96), # '3'
	(0x25, 0x97), # '4'
	(0x2e, 0x98), # '5'
	(0x36, 0x99), # '6'
	(0x3d, 0x9a), # '7'
	(0x3e, 0x9b), # '8'
]
for (scancode, petscii) in petscii_from_ctrl_scancode:
	if keytab[CTRL][scancode] == chr(0): # only if unassigned
		keytab[CTRL][scancode] = chr(petscii)
for (scancode, petscii) in petscii_from_alt_scancode:
	if keytab[ALT][scancode] == chr(0): # only if unassigned
		keytab[ALT][scancode] = chr(petscii)

# stamp in Alt graphic characters
petscii_from_alt_scancode = [
	(0x1c, 0xb0), # 'A'
	(0x32, 0xbf), # 'B'
	(0x21, 0xbc), # 'C'
	(0x23, 0xac), # 'D'
	(0x24, 0xb1), # 'E'
	(0x2b, 0xbb), # 'F'
	(0x34, 0xa5), # 'G'
	(0x33, 0xb4), # 'H'
	(0x43, 0xa2), # 'I'
	(0x3b, 0xb5), # 'J'
	(0x42, 0xa1), # 'K'
	(0x4b, 0xb6), # 'L'
	(0x3a, 0xa7), # 'M'
	(0x31, 0xaa), # 'N'
	(0x44, 0xb9), # 'O'
	(0x4d, 0xaf), # 'P'
	(0x15, 0xab), # 'Q'
	(0x2d, 0xb2), # 'R'
	(0x1b, 0xae), # 'S'
	(0x2c, 0xa3), # 'T'
	(0x3c, 0xb8), # 'U'
	(0x2a, 0xbe), # 'V'
	(0x1d, 0xb3), # 'W'
	(0x22, 0xbd), # 'X'
	(0x35, 0xb7), # 'Y'
	(0x1a, 0xad), # 'Z'
]
for (scancode, petscii) in petscii_from_alt_scancode:
	if keytab[ALT][scancode] == chr(0): # only if unassigned
		keytab[ALT][scancode] = chr(petscii)

# generate Ctrl codes for A-Z
for i in range(0, len(keytab[0])):
	c = keytab[0][i]
	if ord(c) >= ord('A') and ord(c) <= ord('Z'):
		c = chr(ord(c) - 0x40)
		if keytab[2][i] == chr(0): # only if unassigned
			keytab[2][i] = c

# stamp in backspace and TAB
for shiftstate in keytab.keys():
	if shiftstate == 0:
		keytab[shiftstate][0x66] = chr(0x14) # backspace
		keytab[shiftstate][0x0d] = chr(0x09) # TAB
		keytab[shiftstate][0x5a] = chr(0x0d) # CR
		keytab[shiftstate][0x29] = chr(0x20) # SPACE
	else:
		keytab[shiftstate][0x66] = chr(0x94) # insert
		keytab[shiftstate][0x0d] = chr(0x18) # shift-TAB
		keytab[shiftstate][0x5a] = chr(0x8d) # shift-CR
		keytab[shiftstate][0x29] = chr(0xA0) # shift-SPACE


# analyze problems
petscii_chars_not_reachable = ""
for c in all_petscii_chars:
	if not c in keytab[REG] and not c in keytab[SHFT] and not c in keytab[CTRL] and not c in keytab[ALT]:
		petscii_chars_not_reachable += c

petscii_codes_not_reachable = ""
for c in all_petscii_codes:
	if not c in keytab[REG] and not c in keytab[SHFT] and not c in keytab[CTRL] and not c in keytab[ALT]:
		if not c in all_petscii_codes_ok_if_missing:
			petscii_codes_not_reachable += c

petscii_graphs_not_reachable = ""
for c in all_petscii_graphs:
	if not c in keytab[REG] and not c in keytab[SHFT] and not c in keytab[CTRL] and not c in keytab[ALT]:
#		pprint.pprint(c)
		petscii_graphs_not_reachable += c


petscii_chars_not_reachable = ''.join(sorted(petscii_chars_not_reachable))
petscii_codes_not_reachable = ''.join(sorted(petscii_codes_not_reachable))
petscii_graphs_not_reachable = ''.join(sorted(petscii_graphs_not_reachable))
ascii_not_reachable = ''.join(sorted(ascii_not_reachable))

# print

name = kbd_layout['name'].replace(' - Custom', '')
kbd_id = kbd_layout['short_id'].lower()

print("// Name:   " + name)
print("// Locale: " + kbd_layout['localename'])
print("// KLID:   " + kbd_id)
print("//")
if len(petscii_chars_not_reachable) > 0 or len(petscii_codes_not_reachable) > 0 or len(petscii_graphs_not_reachable) > 0:
	print("// PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:")
	if len(petscii_chars_not_reachable) > 0:
		print("// chars: " + pprint.pformat(petscii_chars_not_reachable))
	if len(petscii_codes_not_reachable) > 0:
		print("// codes: ", end = '')
		for c in petscii_codes_not_reachable:
			if ord(c) in control_codes:
				print(control_codes[ord(c)] + ' ', end = '')
			else:
				print(hex(ord(c)) + ' ', end = '')
		print()
	if len(petscii_graphs_not_reachable) > 0:
		print("// graph: '", end = '')
		for c in petscii_graphs_not_reachable:
			print("\\x{0:02x}".format(ord(c)), end = '')
		print("'")
if len(ascii_not_reachable) > 0:
	print("// ASCII characters reachable with this layout on Windows but not covered by PETSCII:")
	print("// " + pprint.pformat(ascii_not_reachable))
print()

for shiftstate in [REG, SHFT, CTRL, ALT]:
	print("kbtab_{}_{}: // ".format(kbd_id, shiftstate), end = '')
	if shiftstate == 0:
		print('Unshifted', end='')
	if shiftstate & 1:
		print('Shft ', end='')
	if shiftstate & 6 == 6:
		print('AltGr ', end='')
	else:
		if shiftstate & 2:
			print('Ctrl ', end='')
		if shiftstate & 4:
			print('Alt ', end='')
	print()
	for i in range(0, 128):
		if i & 7 == 0:
			if i != 0:
				print()
			print('\t.byte ', end='')
		c = keytab[shiftstate][i]
		if ord(c) >= 0x20 and ord(c) <= 0x7e:
			print("'{}'".format(c), end = '')
		else:
			print("${:02x}".format(ord(c)), end = '')
		if i & 7 != 7:
			print(',', end = '')
	print()

