* Simple test program to verify console output
	section text

start:
	* Try the simplest possible print using DOS function 9
	move.l	#message,-(sp)
	move.w	#9,-(sp)
	trap	#15
	addq.l	#6,sp

	* Exit
	move.w	#0,-(sp)
	move.w	#$4c,-(sp)
	trap	#15

	section data
message:
	dc.b	'Hello from X68000!',13,10,'$'
