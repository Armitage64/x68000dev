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

| int mxdrv_setmdx(void *data);
| Load MDX data using MXDRV SETMDX function (function 2)
| A1=MDX pointer, A2=0 (no PDX)
| Returns D0 (error code or 0 if success)
	.global	mxdrv_setmdx
	.type	mxdrv_setmdx,@function
mxdrv_setmdx:
	movem.l	%a1-%a2,-(%sp)	| Save registers (8 bytes)
	move.l	12(%sp),%a1	| A1 = MDX data pointer (4+8=12)
	suba.l	%a2,%a2		| A2 = 0 (no PDX data)
	move.l	#2,%d0		| D0 = SETMDX function
	trap	#4		| Call MXDRV SETMDX
	movem.l	(%sp)+,%a1-%a2	| Restore registers
	rts			| Return with result in D0

| int mxdrv_play_only(void);
| Start playback using MXDRV PLAY function
| Function 3 = PLAY (from outrun.s)
| MUST call mxdrv_setmdx first!
| Returns D0 (error code or 0 if success)
	.global	mxdrv_play_only
	.type	mxdrv_play_only,@function
mxdrv_play_only:
	movem.l	%d1/%a1-%a2,-(%sp)	| Save registers
	move.w	#0xFFFF,%d1	| D1 = 0xFFFF (all channels)
	suba.l	%a1,%a1		| A1 = 0
	suba.l	%a2,%a2		| A2 = 0
	move.l	#3,%d0		| D0 = 3 (PLAY) - CORRECT!
	trap	#4		| Call MXDRV
	movem.l	(%sp)+,%d1/%a1-%a2	| Restore registers
	rts			| Return with result in D0

| int mxdrv_play(void *data);
| Load MDX data and play it using MXDRV
| IMPORTANT: Must call SETMDX (function 2) BEFORE PLAY (function 3)!
| SETMDX: D0=2, A1=MDX pointer, A2=0 (no PDX)
| PLAY:   D0=3, D1=$FFFF (all channels), takes NO parameters
| Returns D0 (error code or status from PLAY)
	.global	mxdrv_play
	.type	mxdrv_play,@function
mxdrv_play:
	movem.l	%d1/%a1-%a2,-(%sp)	| Save registers (12 bytes)
	move.l	16(%sp),%a1	| A1 = MDX data pointer (4+12=16)

	| Step 1: Call SETMDX to load the MDX data
	suba.l	%a2,%a2		| A2 = 0 (no PDX data)
	move.l	#2,%d0		| D0 = SETMDX function
	trap	#4		| Call MXDRV SETMDX
	tst.l	%d0		| Check return value
	bne	.play_error	| If error, return immediately

	| Step 2: Call PLAY to start playback (takes no parameters!)
	move.w	#0xFFFF,%d1	| D1 = channel mask (all channels)
	move.l	#3,%d0		| D0 = PLAY function (3, not 4!)
	trap	#4		| Call MXDRV PLAY

.play_error:
	movem.l	(%sp)+,%d1/%a1-%a2	| Restore registers
	rts			| Return with result in D0

| void* mxdrv_get_work_area(void);
| Get MXDRV work area pointer (function 0)
| Returns pointer to work area in D0
	.global	mxdrv_get_work_area
	.type	mxdrv_get_work_area,@function
mxdrv_get_work_area:
	move.l	#0,%d0		| D0 = 0 (get work area function)
	trap	#4		| Call MXDRV
	rts			| Return with work area pointer in D0

| void* mxdrv_get_work_ptr(void);
| Alias for mxdrv_get_work_area
	.global	mxdrv_get_work_ptr
	.type	mxdrv_get_work_ptr,@function
mxdrv_get_work_ptr:
	bra	mxdrv_get_work_area	| Jump to main function

| ============================================================================
| Compatibility aliases for mxprobe.c (no underscores)
| ============================================================================

| int mxdrvcall(int func) - alias for mxdrv_call
	.global	mxdrvcall
	.type	mxdrvcall,@function
mxdrvcall:
	bra	mxdrv_call

| void* mxdrvwork(void) - alias for mxdrv_get_work_area
	.global	mxdrvwork
	.type	mxdrvwork,@function
mxdrvwork:
	bra	mxdrv_get_work_area
