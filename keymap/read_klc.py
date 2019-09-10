import io, re, codecs
import pprint

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
			kbd_layout['name'] = fields[2]
		elif fields[0] == 'COPYRIGHT':
			kbd_layout['copyright'] = fields[1]
		elif fields[0] == 'COMPANY':
			kbd_layout['company'] = fields[1]
		elif fields[0] == 'LOCALENAME':
			kbd_layout['localename'] = fields[1]
		elif fields[0] == 'LOCALEID':
			kbd_layout['localeid'] = fields[1]
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
	if ord(c) < 0x20 and c != '\r':
		return chr(0)
	if ord(c) >= 0x7e:
		return chr(0)
	if c == '\\' or c == '|' or c == '_' or c == '{' or c == '}' or c == '~':
		return chr(0)
	if ord(c) >= ord('A') and ord(c) <= ord('Z'):
		return chr(ord(c) + 0x80)
	if ord(c) >= ord('a') and ord(c) <= ord('z'):
		return chr(ord(c) - 0x20)
	return c

all_petscii_chars = " !\"#$%&'()*+,-./0123456789:;<=>?@"
for c in "abcdefghijklmnopqrstuvwxyz":
	all_petscii_chars += chr(ord(c) - 0x20)
all_petscii_chars += "[£]^←ABCDEFGHIJKLMNOPQRSTUVWXYZπ"

#filename_klc = '40C French.klc'
#filename_klc = '419 Russian.klc'
#filename_klc = '409 US.klc'
filename_klc = '407 German.klc'

kbd_layout = get_kbd_layout(filename_klc)

layout = kbd_layout['layout']
shiftstates = kbd_layout['shiftstates']

keytab = {}
for shiftstate in shiftstates:
	keytab[shiftstate] = [ '\0' ] * 128

ascii_not_reachable = ""

for hid_scancode in layout.keys():
	ps2_scancode = ps2_set2_code_from_hid_code(hid_scancode)
	l = layout[hid_scancode]['chars']
	#print(hid_scancode, ps2_scancode, l)
	for shiftstate in shiftstates:
		if shiftstate in l:
			c_ascii = l[shiftstate]
			c_petscii = petscii_from_ascii(c_ascii)
			if c_petscii == chr(0):
				if not c_ascii in ascii_not_reachable:
					ascii_not_reachable += c_ascii
			keytab[shiftstate][ps2_scancode] = c_petscii

# stamp in backspace/insert
keytab[0][0x66] = chr(0x14) # backspace
keytab[1][0x66] = chr(0x94) # insert

# stamp in f-keys independent of shiftstate
for shiftstate in shiftstates:
	keytab[shiftstate][2] = chr(0x88)
	keytab[shiftstate][3] = chr(0x87)
	keytab[shiftstate][4] = chr(0x86)
	keytab[shiftstate][5] = chr(0x85)
	keytab[shiftstate][6] = chr(0x89)
	keytab[shiftstate][10] = chr(0x8c)
	keytab[shiftstate][11] = chr(0x8b)
	keytab[shiftstate][12] = chr(0x8a)

# stamp in TAB
for shiftstate in shiftstates:
	if shiftstate == 0:
		keytab[shiftstate][0x0d] = chr(0x09) # TAB
	else:
		keytab[shiftstate][0x0d] = chr(0x18) # shift-TAB

# generate Ctrl codes for A-Z
for i in range(0, len(keytab[0])):
	c = keytab[0][i]
	if ord(c) >= ord('A') and ord(c) <= ord('Z'):
		c = chr(ord(c) - 0x40)
		if keytab[2][i] == chr(0): # only is unassigned
			keytab[2][i] = c

# print

for shiftstate in shiftstates:
	print("\n// {}: ".format(shiftstate), end = '')
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

petscii_not_reachable = ""
for c in all_petscii_chars:
	if not c in keytab[0] and not c in keytab[1]:
		petscii_not_reachable += c
print("PETSCII not reachable: \"" + petscii_not_reachable + "\"")
print("ASCII   not reachable: \"" + ascii_not_reachable + "\"")
