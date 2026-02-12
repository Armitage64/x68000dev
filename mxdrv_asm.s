| ============================================================================
| MXDRV wrapper functions in pure assembly (GCC assembler syntax)
| ============================================================================
| Based on mdxtools: https://github.com/vampirefrog/mdxtools
| MXDRV calling convention:
|   - trap #4 (music driver trap)
|   - D0 = function number
|   - D1, A1, A2 = parameters (depending on function)
|   - Parameters passed in REGISTERS, not on stack
|   - All registers preserved except D0 (return value)
| ============================================================================

	.text
	.even

| int mxdrv_call(int func);
| Call MXDRV with function number in D0
| Returns result in D0
| Save ALL registers except D0 (just to be safe)
	.global	mxdrv_call
	.type	mxdrv_call,@function
mxdrv_call:
	movem.l	%d1-%d7/%a0-%a6,-(%sp)	| Save all registers except D0
	move.l	60(%sp),%d0	| Get function number in D0 (4 + 56 bytes saved = 60)
	trap	#4		| Call MXDRV (trap #4 for music drivers)
	movem.l	(%sp)+,%d1-%d7/%a0-%a6	| Restore all registers
	rts			| Return with result in D0

| int mxdrv_set_mdx(void *data, int size);
| Load MDX data into MXDRV
| Returns result from SETMDX in D0
	.global	mxdrv_set_mdx
	.type	mxdrv_set_mdx,@function
mxdrv_set_mdx:
	movem.l	%d1/%a1,-(%sp)	| Save registers (8 bytes)
	move.l	12(%sp),%a1	| A1 = MDX data pointer (4+8=12)
	move.l	16(%sp),%d1	| D1 = size (4+8+4=16)
	move.l	#2,%d0		| D0 = SETMDX function
	trap	#4		| Load MDX data into MXDRV
	movem.l	(%sp)+,%d1/%a1	| Restore registers
	rts			| Return with result in D0

| int mxdrv_set_pdx(const char *filename);
| Set PDX file path (or NULL if no PDX file)
| Returns result from SETPDX in D0
	.global	mxdrv_set_pdx
	.type	mxdrv_set_pdx,@function
mxdrv_set_pdx:
	move.l	%a1,-(%sp)	| Save A1 (4 bytes)
	move.l	8(%sp),%a1	| A1 = filename pointer (4+4=8)
	move.l	#3,%d0		| D0 = SETPDX function
	trap	#4		| Set PDX file path
	move.l	(%sp)+,%a1	| Restore A1
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

| void mxdrv_int(void);
| Call MXDRV interrupt handler - must be called periodically for music playback
| This is typically function 0x0A or the interrupt entry point
	.global	mxdrv_int
	.type	mxdrv_int,@function
mxdrv_int:
	movem.l	%d0-%d7/%a0-%a6,-(%sp)	| Save all registers
	move.l	#0x0A,%d0	| D0 = INT function (interrupt handler)
	trap	#4		| Call MXDRV interrupt
	movem.l	(%sp)+,%d0-%d7/%a0-%a6	| Restore all registers
	rts			| Return
