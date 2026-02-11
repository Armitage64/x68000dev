| ============================================================================
| MXDRV wrapper functions in pure assembly (GCC assembler syntax)
| ============================================================================

	.text
	.even

| int mxdrv_call(int func);
| Call MXDRV with function number in func
| Returns result in D0
	.global	_mxdrv_call
	.type	_mxdrv_call,@function
_mxdrv_call:
	move.w	4(%sp),-(%sp)	| Push function number parameter
	trap	#10		| Call MXDRV
	addq.l	#2,%sp		| Clean up stack (pop 2 bytes)
	rts			| Return with result in D0

| void mxdrv_play(void *data);
| Call MXDRV play function with MDX data pointer
	.global	_mxdrv_play
	.type	_mxdrv_play,@function
_mxdrv_play:
	move.l	4(%sp),-(%sp)	| Push data pointer (4 bytes)
	move.w	#3,-(%sp)	| Push function number 3 (MXDRV_PLAY) (2 bytes)
	trap	#10		| Call MXDRV
	addq.l	#6,%sp		| Clean up stack (pop 6 bytes)
	rts			| Return
