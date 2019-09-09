import io, re, codecs
import pprint

filename_klc = '407 German.klc'

f = io.open(filename_klc, mode="r", encoding="utf-16")
lines = f.readlines()
f.close()
lines = [x.strip() for x in lines]

#print(lines)

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
		pass	
	elif fields[0] == 'KEYNAME':
		pass	
	elif fields[0] == 'KEYNAME_EXT':
		pass	
	elif fields[0] == 'KEYNAME_DEAD':
		pass	
	elif fields[0] == 'DESCRIPTIONS':
		pass	
	elif fields[0] == 'LANGUAGENAMES':
		pass	

pprint.pprint(kbd_layout)


#{ 0x01: 0x76, 0x02: 0x16, 0x03: 0x1E, 0x04: 0x26, 0x05: 0x25, 0x06: 0x2E, 0x07: 0x36, 0x08: 0x3D, 0x09: 0x3E, 0x0A: 0x46, 0x0B: 0x45, 0x0C: 0x4E, 0x0D: 0x55, 0x0E: 0x66, 0x0F: 0x0D, 0x10: 0x15, 0x11: 0x1D, 0x12: 0x24, 0x13: 0x2D, 0x14: 0x2C, 0x15: 0x35, 0x16: 0x3C, 0x17: 0x43, 0x18: 0x44, 0x19: 0x4D, 0x1A: 0x54, 0x1B: 0x5B, 0x1C: 0x5A, 0x1E: 0x1C, 0x1F: 0x1B, 0x20: 0x23, 0x21: 0x2B, 0x22: 0x34, 0x23: 0x33, 0x24: 0x3B, 0x25: 0x42, 0x26: 0x4B, 0x27: 0x4C, 0x28: 0x52, 0x29: 0x0E, 0x2B: 0x5D, 0x2B: 0x5D, 0x2C: 0x1A, 0x2D: 0x22, 0x2E: 0x21, 0x2F: 0x2A, 0x30: 0x32, 0x31: 0x31, 0x32: 0x3A, 0x33: 0x41, 0x34: 0x49, 0x35: 0x4A, 0x39: 0x29, 0x3A: 0x58, 0x3B: 0x05, 0x3C: 0x06, 0x3D: 0x04, 0x3E: 0x0C, 0x3F: 0x03, 0x40: 0x0B, 0x41: 0x83, 0x42: 0x0A, 0x43: 0x01, 0x44: 0x09, 0x57: 0x78, 0x58: 0x07 }


