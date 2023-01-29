#!/usr/bin/env python3

import re
from xml.etree.ElementInclude import include

table = open("build/kernel.lst")
rows = table.read().replace("\t", " ").splitlines()

oldname = ""
newname = ""
oldinclude = ""
newinclude = ""
oldstartaddr = 0
includefound = False
firstaddrfound = False

for row in rows:
	el = list(filter(None, row.split(' ')))

	includefound = False

	for e in el:
		if ";" in e:
			break

		match = re.findall("^[0-9a-z_]*:", e)

		if len(match) == 1 and (match[0].startswith("os_") or match[0].startswith("int_")):
			oldname = newname
			newname = match[0]
			firstaddrfound = False

		if "%INCLUDE" in e:
			includefound = True

		if includefound:
			newinclude = e

	try:
		addr = int(el[1], base=16)

		if not firstaddrfound:
			if oldname != "":
				print("%d %s %s" % (addr - oldstartaddr, oldname, oldinclude))

			oldinclude = newinclude
			oldstartaddr = addr
			firstaddrfound = True

	except:
		pass

print("%d total" % oldstartaddr)
