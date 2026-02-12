| ============================================================================
| MXDRV wrapper functions in pure assembly (GCC assembler syntax)
| ============================================================================
| MXDRV calling convention (from x68kd11s disassembly):
|   - trap #4 (MXDRV music driver trap)
|   - D0 = function number (0-31)
|   - D1 = parameter 1 (e.g., channel mask for PLAY)
|   - A1 = parameter 2 (e.g., MDX data pointer)
|   - A2 = parameter 3 (e.g., voice/PDX data pointer, or 0)
|   - Parameters passed in REGISTERS, not on stack
|   - Return value in D0
| ============================================================================

	.text
	.even

| int mxdrv_call(int func);
| Call MXDRV with function number in D0 (register-based)
| Returns result in D0
	.global	mxdrv_call
	.type	mxdrv_call,@function
mxdrv_call:
	movem.l	%d1-%d7/%a0-%a6,-(%sp)	| Save all registers except D0
	move.l	60(%sp),%d0	| Get function number in D0 (4 + 56 bytes saved = 60)
	trap	#4		| Call MXDRV
	movem.l	(%sp)+,%d1-%d7/%a0-%a6	| Restore all registers
	rts			| Return with result in D0

| void mxdrv_play(void *data);
| Play MDX data using MXDRV function 4 (PLAY)
| D0=4 (function), D1=$FFFF (all channels), A1=MDX pointer, A2=0 (no PDX)
	.global	mxdrv_play
	.type	mxdrv_play,@function
mxdrv_play:
	movem.l	%d1/%a1-%a2,-(%sp)	| Save registers (12 bytes)
	move.l	16(%sp),%a1	| A1 = MDX data pointer (4+12=16)
	move.w	#0xFFFF,%d1	| D1 = channel mask (all channels)
	suba.l	%a2,%a2		| A2 = 0 (no PDX data)
	move.l	#4,%d0		| D0 = PLAY function
	trap	#4		| Call MXDRV
	movem.l	(%sp)+,%d1/%a1-%a2	| Restore registers
	rts			| Return
