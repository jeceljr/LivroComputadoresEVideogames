#!/usr/bin/python

# le um arquivo com formato de caracteres de 8x16 pixels
# no estilo de https://github.com/epto/epto-fonts.git e
# salva como Intel hex

import sys
import re
import io

f = io.open( sys.argv[1], mode="r", encoding="utf-8")

inChar = False
cCount = 0

for line in f:
	if "@CH " in line:
		inChar = True
		cCount = 0
		cDec = re.search("[0-9]+",line)
		cVal = int(cDec.group()) 
		hLine = ":100{:02X}000".format(cVal)
		chkSum = 16+(cVal>>4)+((cVal&15)<<4)
	elif inChar:
		byte = 0
		for c in line[0:7]:
			byte <<= 1
			if c != " ":
				byte += 1
		hLine += "{:02X}".format(byte&255)
		chkSum += byte
		cCount += 1
		if cCount > 15:
			hLine += "{:02X}".format((256-(chkSum&255)&255))
			print (hLine)
			inChar = False

