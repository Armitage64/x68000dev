* Minimal Hello World for X68000
	section text

start:
	pea	msg
	move.w	#9,-(sp)
	trap	#15
	addq.l	#6,sp

	move.w	#0,-(sp)
	move.w	#$4c,-(sp)
	trap	#15

	section data
msg:
	dc.b	'Hello from X68000!',13,10,'$'

	end start
