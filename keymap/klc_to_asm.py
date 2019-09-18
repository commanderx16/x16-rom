import io, re, codecs, sys, os.path
import pprint

REG   = 0
SHFT  = 1
CTRL  = 2
ALT   = 4
ALTGR = 6

COMPRESSED_OUTPUT=1

def get_kbd_layout(base_filename, load_patch = False):
	filename_klc = base_filename
	filename_changes = base_filename + 'patch'

	f = io.open(filename_klc, mode="r", encoding="utf-8")
	lines = f.readlines()
	f.close()
	lines = [x.strip() for x in lines]
	
	if (load_patch and os.path.isfile(filename_changes)):
		f = io.open(filename_changes, mode="r", encoding="utf-8")
		lines_changes = f.readlines()
		f.close()
		lines_changes = [x.strip() for x in lines_changes]
	else:
		lines_changes = []
	
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
		
	section_changes = []
	while len(lines_changes) > 0:
		line = lines_changes[0]
		lines_changes = lines_changes[1:]
		i = line.find('//')
		if i != -1:
			line = line[:i]
		line = line.rstrip()
		if len(line) == 0:
			continue
		fields = re.split(r'\t', line)
		while '' in fields:
			fields.remove('')
		section_changes.append(fields)

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
			# The US layout does not use "Alt" *at all*. We add it, so that the
			# .klcpatch file can define keys with "Alt" in an extra column.

			if not ALT in shiftstates:
				shiftstates.append(ALT)
			kbd_layout['shiftstates'] = shiftstates
		elif fields[0] == 'LAYOUT':
			all_originally_reachable_characters = ""
			layout = {}
			line_number = 0
			for fields in lines[1:] + section_changes:
				if fields[0] == '-1':
					# TODO: 807 has extension lines we don't support
					continue
				chars = {}
				i = 3
				for shiftstate in shiftstates:
					if i > len(fields) - 1:
						break
					c = fields[i]
					if c != '-1':
						if len(c) > 1:
							c = chr(int(c[0:4], 16))
						chars[shiftstate] = c
						if (line_number < len(lines[1:])):
							all_originally_reachable_characters += c
					i += 1
				# TODO: c[4] == '@' -> dead key
				layout[int(fields[0], 16)] = {
					#'vk_name': 'VK_' + fields[1],
					#'cap': int(fields[2]),
					'chars': chars
				}
				line_number += 1
			kbd_layout['layout'] = layout
			kbd_layout['all_originally_reachable_characters'] = ''.join(sorted(all_originally_reachable_characters))
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

def petscii_from_unicode(c):
	if ord(c) >= 0xf800 and ord(c) <= 0xf8ff: # PETSCII code encoded into private Unicode area
		return chr(ord(c) - 0xf800)
	if c == '\\' or c == '|' or c == '_' or c == '{' or c == '}' or c == '~':
		return chr(0)
	if ord(c) == 0xa3: # '£'
		return chr(0x5c)
	if ord(c) == 0x2190: # '←'
		return chr(0x5f)
	if ord(c) == 0x03c0: # 'π'
		return chr(0xde)
	if ord(c) >= ord('A') and ord(c) <= ord('Z'):
		return chr(ord(c) + 0x80)
	if ord(c) >= ord('a') and ord(c) <= ord('z'):
		return chr(ord(c) - 0x20)
	if ord(c) < 0x20 and c != '\r':
		return chr(0)
	if ord(c) >= 0x7e:
		return chr(0)
	return c

def latin15_from_unicode(c):
	# Latin-15 and 8 bit Unicode are almost the same
	if ord(c) <= 0xff:
		# Latin-1 characters (i.e. 8 bit Unicode) not included in Latin-15
		if ord(c) in [0xA4, 0xA6, 0xA8, 0xB4, 0xB8, 0xBC, 0xBD, 0xBE]: #'¤¦¨´¸¼½¾'
			return chr(0);
		else:
			return c
	
	# Latin-15 supports some other Unicode characters
	latin15_from_unicode_tab = { 
		0x20ac: 0xa4, # '€'
		0x160: 0xa6,  # 'Š'
		0x161: 0xa8,  # 'š'
		0x17d: 0xb4,  # 'Ž'
		0x17e: 0xb8,  # 'ž'
		0x152: 0xbc,  # 'Œ'
		0x153: 0xbd,  # 'œ'
		0x178: 0xbe   # 'Ÿ'
	}
	if ord(c) in latin15_from_unicode_tab:
		return chr(latin15_from_unicode_tab[ord(c)])
	
	# all other characters are unsupported		
	return chr(0)

def unicode_from_petscii(c):
	# only does the minumum
	if ord(c) == 0x5c: # '£'
		return chr(0xa3)
	if ord(c) == 0x5f: # '←'
		return chr(0x2190)
	if ord(c) == 0xde: # 'π'
		return chr(0x03c0)
	return c

# constants

# a string with all printable 7-bit PETSCII characters
all_petscii_chars = " !\"#$%&'()*+,-./0123456789:;<=>?@"
for c in "abcdefghijklmnopqrstuvwxyz":
	all_petscii_chars += chr(ord(c) - 0x20)
all_petscii_chars += "[\]^_ABCDEFGHIJKLMNOPQRSTUVWXYZ"
all_petscii_chars += "\xde" # π

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
for c in range(0xa1, 0xc0):
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

if len(sys.argv) >= 3 and sys.argv[2] == '-iso':
	iso_mode = True
else:
	iso_mode = False

load_patch = not iso_mode
kbd_layout = get_kbd_layout(sys.argv[1], load_patch)

layout = kbd_layout['layout']
shiftstates = kbd_layout['shiftstates']

keytab = {}
for shiftstate in shiftstates:
	keytab[shiftstate] = [ '\0' ] * 128
# some layouts don't define Alt at all
if not ALT in keytab:
	keytab[ALT] = [ '\0' ] * 128

# create PS/2 Code 2 -> PETSCII tables
for hid_scancode in layout.keys():
	ps2_scancode = ps2_set2_code_from_hid_code(hid_scancode)
	l = layout[hid_scancode]['chars']
	for shiftstate in keytab.keys():
		if shiftstate in l:
			c_unicode = l[shiftstate]
			if iso_mode:
				keytab[shiftstate][ps2_scancode] = latin15_from_unicode(c_unicode)
			else:
				keytab[shiftstate][ps2_scancode] = petscii_from_unicode(c_unicode)

# stamp in f-keys independent of shiftstate
for shiftstate in keytab.keys():
	keytab[shiftstate][5]    = chr(0x85) # f1
	keytab[shiftstate][6]    = chr(0x89) # f2
	keytab[shiftstate][4]    = chr(0x86) # f3
	keytab[shiftstate][12]   = chr(0x8a) # f4
	keytab[shiftstate][3]    = chr(0x87) # f5
	keytab[shiftstate][11]   = chr(0x8b) # f6
	keytab[shiftstate][2]    = chr(0x88) # f7
	keytab[shiftstate][10]   = chr(0x8c) # f8

	# C65 additions
	keytab[shiftstate][1]    = chr(0x10) # f9
	keytab[shiftstate][9]    = chr(0x15) # f10
	keytab[shiftstate][0x78] = chr(0x16) # f11
	keytab[shiftstate][7]    = chr(0x17) # f12

	# * PS/2 keyboards don't have the C65 f13 (chr(0x19)) and f14 (chr(0x1a))
	#   -> we don't map them
	# * PS/2 keyboards don't have the C128/C65 "HELP" (chr(0x83))
	#   -> TODO

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
if not iso_mode:
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
for i in range(0, len(keytab[REG])):
	c = keytab[REG][i]
	if iso_mode and ord(c) >= ord('a') and ord(c) <= ord('z'):
		c = chr(ord(c) - ord('a') + 1)
	elif not iso_mode and ord(c) >= ord('A') and ord(c) <= ord('Z'):
		c = chr(ord(c) - ord('A') + 1)
	else:
		c = None
		
	if c and keytab[CTRL][i] == chr(0): # only if unassigned
		keytab[CTRL][i] = c

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
all_keytabs = keytab[REG] + keytab[SHFT] + keytab[CTRL] + keytab[ALT]
if ALTGR in keytab:
	all_keytabs += keytab[ALTGR]
petscii_chars_not_reachable = ""
for c in all_petscii_chars:
	if not c in all_keytabs:
		petscii_chars_not_reachable += unicode_from_petscii(c)

petscii_codes_not_reachable = ""
for c in all_petscii_codes:
	if not c in all_keytabs:
		if not c in all_petscii_codes_ok_if_missing:
			petscii_codes_not_reachable += c

petscii_graphs_not_reachable = ""
for c in all_petscii_graphs:
	if not c in all_keytabs:
		petscii_graphs_not_reachable += c

unicode_not_reachable = ""
for c_unicode in kbd_layout['all_originally_reachable_characters']:
	if iso_mode:
		c_encoded = latin15_from_unicode(c_unicode)
	else:
		c_encoded = petscii_from_unicode(c_unicode)
	if (c_encoded == chr(0) or not c_encoded in all_keytabs) and not c_unicode in unicode_not_reachable:
		unicode_not_reachable += c_unicode

petscii_chars_not_reachable = ''.join(sorted(petscii_chars_not_reachable))
petscii_codes_not_reachable = ''.join(sorted(petscii_codes_not_reachable))
petscii_graphs_not_reachable = ''.join(sorted(petscii_graphs_not_reachable))
unicode_not_reachable = ''.join(sorted(unicode_not_reachable))

# print

name = kbd_layout['name'].replace(' - Custom', '')
kbd_id = kbd_layout['short_id'].lower()

print("; Name:   " + name)
print("; Locale: " + kbd_layout['localename'])
print("; KLID:   " + kbd_id)
print(";")
if len(petscii_chars_not_reachable) > 0 or len(petscii_codes_not_reachable) > 0 or len(petscii_graphs_not_reachable) > 0:
	print("; PETSCII characters reachable on a C64 keyboard that are not reachable with this layout:")
	if len(petscii_chars_not_reachable) > 0:
		print("; chars: " + pprint.pformat(petscii_chars_not_reachable))
	if len(petscii_codes_not_reachable) > 0:
		print("; codes: ", end = '')
		for c in petscii_codes_not_reachable:
			if ord(c) in control_codes:
				print(control_codes[ord(c)] + ' ', end = '')
			else:
				print(hex(ord(c)) + ' ', end = '')
		print()
	if len(petscii_graphs_not_reachable) > 0:
		print("; graph: '", end = '')
		for c in petscii_graphs_not_reachable:
			print("\\x{0:02x}".format(ord(c)), end = '')
		print("'")
if len(unicode_not_reachable) > 0:
	if iso_mode:
		print("; Unicode characters reachable with this layout on Windows but not covered by ISO-8859-15:")
	else:
		print("; Unicode characters reachable with this layout on Windows but not covered by PETSCII:")
	print("; '", end = '')
	for c in unicode_not_reachable:
		if ord(c) < 0x20:
			print("\\x{0:02x}".format(ord(c)), end = '')
		else:
			print(c, end = '')
	print("'")
	
print()

if iso_mode:
	print('.segment "IKBDMETA"\n')
	prefix = 'i'
else:
	print('.segment "KBDMETA"\n')
	prefix = ''
locale1 = kbd_layout['localename'][0:2].upper()
locale2 = kbd_layout['localename'][3:5].upper()
if locale1 != locale2:
	locale1 = kbd_layout['localename'].upper()
if len(kbd_layout['localename']) != 5:
	sys.exit("unknown locale format: " + kbd_layout['localename'])
print('\t.byte "' + locale1 + '"', end = '')
for i in range(0, 6 - len(locale1)):
	print(", 0", end = '')
print()
for shiftstate in [SHFT, ALT, CTRL, ALTGR, REG]:
	if shiftstate == ALTGR and not ALTGR in keytab.keys():
		print_shiftstate = ALT
	else:
		print_shiftstate = shiftstate
	print("\t.word {}kbtab_{}_{}".format(prefix, kbd_id, print_shiftstate), end = '')
	if shiftstate == REG:
		print()
	else:
		print("-13")
print()


if iso_mode:
	print('.segment "IKBDTABLES"\n')
else:
	print('.segment "KBDTABLES"\n')

for shiftstate in [REG, SHFT, CTRL, ALT, ALTGR]:
	if shiftstate == ALTGR and not ALTGR in keytab.keys():
		continue
	print("{}kbtab_{}_{}: ; ".format(prefix, kbd_id, shiftstate), end = '')
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
	if COMPRESSED_OUTPUT == 1 and shiftstate != REG:
		start = 13
		end = 104
	else:
		start = 0
		end = 128
	for i in range(start, end):
		if i == start or i & 7 == 0:
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

