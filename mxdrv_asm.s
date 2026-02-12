| ============================================================================
| MXDRV wrapper functions in pure assembly (GCC assembler syntax)
| ============================================================================
| MXDRV calling convention for X68000:
|   - trap #10 (MXDRV music driver trap)
|   - Function number pushed on STACK (word), not in registers
|   - Additional parameters pushed on stack before function number
|   - Stack must be cleaned up after trap (addq)
|   - Return value in D0
| ============================================================================

	.text
	.even

| int mxdrv_call(int func);
| Call MXDRV with function number on stack
| Returns result in D0
	.global	mxdrv_call
	.type	mxdrv_call,@function
mxdrv_call:
	move.l	4(%sp),%d0	| Get function number from argument (4 bytes = return addr)
	move.w	%d0,-(%sp)	| Push function number on stack (word)
	trap	#10		| Call MXDRV
	addq.l	#2,%sp		| Clean up stack (2 bytes)
	rts			| Return with result in D0

| void mxdrv_play(void *data);
| Play MDX data using MXDRV
| Pushes MDX pointer and PLAY function on stack, calls trap #10
	.global	mxdrv_play
	.type	mxdrv_play,@function
mxdrv_play:
	move.l	4(%sp),%a0	| Get MDX data pointer from argument
	move.l	%a0,-(%sp)	| Push MDX pointer on stack (4 bytes)
	move.w	#3,-(%sp)	| Push MXDRV_PLAY function 0x03 (2 bytes)
	trap	#10		| Call MXDRV
	addq.l	#6,%sp		| Clean up stack (6 bytes total)
	rts			| Return
