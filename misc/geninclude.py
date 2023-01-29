#!/usr/bin/env python3

import fnmatch
import os

main = open("kernel/main.asm")
rows = main.read().replace("\t", " ").splitlines()

# Search os_call_vectors

searching_vectors = False
org = None
found_calls = []

for row in rows:
	el = list(filter(None, row.split(' ')))
	
	if len(el) > 0 and el[0].upper() == "ORG":
		org = int(el[1])

	if searching_vectors:
		if org == None:
			print("ORG not found!")
			searching_vectors = False
			break

		if row.startswith(" jmp "):
			found_calls.append([el[1], org])
			org += 3

		else:
			break

	if row == "os_call_vectors:":
		searching_vectors = True

if not searching_vectors:
	print("Error, cannot find call vectors!")
	exit(1)

print("Discovered " + str(len(found_calls)) + " function calls.")

# Go through each file in kernel/features, generate output

output = open("include/syscalls.asm", "w")

output.write("; ------------------------------------------------------------------\n")
output.write("; Include file for MichalOS program development - syscalls\n")
output.write("; ------------------------------------------------------------------\n\n")

for root, dirnames, filenames in os.walk('kernel/features'):
	for filename in fnmatch.filter(filenames, '*.asm'):
		asm = open(os.path.join(root, filename))
		rows = asm.read().splitlines()

		header_printed = False

		for i in range(len(rows)):
			row = rows[i]

			if rows[i].startswith("os_") and rows[i].endswith(":"):
				# Found a function definition, find the match

				fncall = rows[i][:-1]
				matchcall = None

				for call in found_calls:
					if call[0] == fncall:
						matchcall = call
						break

				if matchcall != None:
					# Match found, search the comments above the function call

					doc = []

					for j in range(i - 1, -1, -1):
						if rows[j].startswith(";"):
							doc.append(rows[j])
						elif len(doc) > 0:
							break

					doc.reverse()

					# If the file's header has not been written yet, write it

					if not header_printed:
						header_printed = True

						for row in rows:
							if row.startswith(";"):
								output.write(row + "\n")
							else:
								output.write("\n")
								break

					# Output the function call

					for docline in doc:
						output.write(docline + "\n")

					output.write("\n" + matchcall[0] + " equ " + str(matchcall[1]) + "\n\n")