| ============================================================================
| MXDRV wrapper functions in pure assembly (GCC assembler syntax)
| ============================================================================

	.text
	.even

| int mxdrv_call(int func);
| Call MXDRV with function number in func
| Returns result in D0
	.globl	mxdrv_call
mxdrv_call:
	move.l	4(%sp),%d0	| Get function number (32-bit int)
	move.w	%d0,-(%sp)	| Push only low 16 bits
	trap	#4		| Call MXDRV (was #10, changed to #4)
	addq.l	#2,%sp		| Clean up stack (pop 2 bytes)
	rts			| Return with result in D0

| void mxdrv_play(void *data);
| Call MXDRV play function with MDX data pointer
	.globl	mxdrv_play
mxdrv_play:
	move.l	4(%sp),-(%sp)	| Push data pointer (4 bytes)
	move.w	#3,-(%sp)	| Push function number 3 (MXDRV_PLAY) (2 bytes)
	trap	#4		| Call MXDRV (was #10, changed to #4)
	addq.l	#6,%sp		| Clean up stack (pop 6 bytes)
	rts			| Return
