* Hello World for X68000
* Uses Human68k DOS calls via F-line opcodes (dc.w $FFxx)
* NOT trap #15 - that is IOCS (hardware BIOS), not DOS
	section	text

start:
	* _PRINT: push pointer to null-terminated string, then dc.w $ff09
	pea	msg(pc)
	dc.w	$ff09		* DOS _PRINT (F-line exception, dispatched by Human68k)
	addq.l	#4,sp		* clean up: 4 bytes for the pea

	* _EXIT: terminate process
	dc.w	$ff00		* DOS _EXIT

	section	data
msg:
	dc.b	'Hello from X68000!',13,10,0	* null-terminated (NOT '$')

	end	start
