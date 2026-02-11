| ============================================================================
| MXDRV wrapper functions in pure assembly (GCC assembler syntax)
| ============================================================================
| Based on mdxtools: https://github.com/vampirefrog/mdxtools
| MXDRV calling convention:
|   - trap #4 (not #10!) - trap #4 is for music drivers
|   - D0 = function number
|   - D1, A1, A2 = parameters (depending on function)
|   - All registers preserved by MXDRV except D0 (return value)
| ============================================================================

	.text
	.even

| int mxdrv_call(int func);
| Call MXDRV with function number in D0
| Returns result in D0
	.global	mxdrv_call
	.type	mxdrv_call,@function
mxdrv_call:
	move.l	4(%sp),%d0	| Get function number from C parameter
	trap	#4		| Call MXDRV (trap #4 for music drivers)
	rts			| Return with result in D0

| void mxdrv_play(void *data);
| Load and play MDX data using MXDRV
| Calls SETMDX (func=2) then PLAY (func=4)
	.global	mxdrv_play
	.type	mxdrv_play,@function
mxdrv_play:
	movem.l	%d1/%a1,-(%sp)	| Save registers (8 bytes)
	move.l	12(%sp),%a1	| A1 = MDX data pointer (4+8=12)
	move.l	#65536,%d1	| D1 = max size (64K)
	move.l	#2,%d0		| D0 = SETMDX function
	trap	#4		| Load MDX data into MXDRV
	move.l	#4,%d0		| D0 = PLAY function
	trap	#4		| Start playback
	movem.l	(%sp)+,%d1/%a1	| Restore registers
	rts			| Return
