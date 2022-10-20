#!/usr/bin/env python3

import re

table = open("build/kernel.lst")
rows = table.read().replace("\t", " ").splitlines()

oldname = ""
newname = ""
oldstartaddr = 0
firstaddrfound = False

for row in rows:
	el = list(filter(None, row.split(' ')))

	for e in el:
		if ";" in e:
			break

		match = re.findall("^[0-9a-z_]*:", e)

		if len(match) == 1 and (match[0].startswith("os_") or match[0].startswith("int_")):
			oldname = newname
			newname = match[0]
			firstaddrfound = False

	try:
		addr = int(el[1], base=16)

		if not firstaddrfound:
			if oldname != "":
				print("%d %s" % (addr - oldstartaddr, oldname))

			oldstartaddr = addr
			firstaddrfound = True

	except:
		pass

print("%d total" % oldstartaddr)
