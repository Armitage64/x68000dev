| ============================================================================
| MXDRV wrapper functions in pure assembly (GCC assembler syntax)
| ============================================================================

	.text
	.even

| int mxdrv_call(int func);
| Call MXDRV with function number in D0
| Returns result in D0
	.global	mxdrv_call
	.type	mxdrv_call,@function
mxdrv_call:
	move.l	4(%sp),%d0	| Get function number in D0
	trap	#4		| Call MXDRV (trap #4, not #10!)
	rts			| Return with result in D0

| void mxdrv_play(void *data);
| Call MXDRV SETMDX+PLAY with MDX data pointer
| MXDRV wants: A1=data pointer, D1=size, D0=function
	.global	mxdrv_play
	.type	mxdrv_play,@function
mxdrv_play:
	move.l	%d1,-(%sp)	| Save D1
	move.l	%a1,-(%sp)	| Save A1
	move.l	12(%sp),%a1	| A1 = MDX data pointer (4+4+4=12)
	move.l	#65536,%d1	| D1 = max size (64K)
	move.l	#2,%d0		| D0 = SETMDX function
	trap	#4		| Load MDX data
	move.l	#4,%d0		| D0 = PLAY function
	trap	#4		| Start playback
	move.l	(%sp)+,%a1	| Restore A1
	move.l	(%sp)+,%d1	| Restore D1
	rts			| Return
