* Simple X68000 test program for VASM
* Fills GVRAM with a visible pattern
	section text

start:
	* Fill GVRAM with pattern
	movea.l	#$C00000,a0
	move.w	#2000,d0

fill_loop:
	move.w	d0,(a0)+
	subq.w	#1,d0
	bne.s	fill_loop

	* Exit to Human68k
	move.w	#$FF00,d0
	trap	#15
	dc.w	$FF00
