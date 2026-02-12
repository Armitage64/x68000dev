* ============================================================================
* MXDRV wrapper functions for XC compiler (Motorola assembler syntax)
* NO UNDERSCORES in function names (X68000 keyboard compatibility)
* ============================================================================
* MXDRV calling convention (from x68kd11s disassembly):
*   - trap #4 (MXDRV music driver trap)
*   - D0 = function number (0-31)
*   - D1 = parameter 1 (e.g., channel mask for PLAY)
*   - A1 = parameter 2 (e.g., MDX data pointer)
*   - A2 = parameter 3 (e.g., voice/PDX data pointer, or 0)
*   - Parameters passed in REGISTERS, not on stack
*   - Return value in D0
* ============================================================================

	.text

* int mxdrvcall(int func);
* Call MXDRV with function number in D0 (register-based)
* Returns result in D0
	.xdef	_mxdrvcall
_mxdrvcall:
	movem.l	d1-d7/a0-a6,-(sp)	; Save all registers except D0
	move.l	60(sp),d0		; Get function number in D0 (4 + 56 bytes saved = 60)

	* Clear all parameter registers (MXDRV might expect this)
	moveq	#0,d1
	moveq	#0,d2
	suba.l	a0,a0
	suba.l	a1,a1
	suba.l	a2,a2

	trap	#4			; Call MXDRV
	movem.l	(sp)+,d1-d7/a0-a6	; Restore all registers
	rts				; Return with result in D0

* int mxdrvset(void *data);
* Load MDX data using MXDRV SETMDX function (function 2)
* A1=MDX pointer, A2=0 (no PDX)
* Returns D0 (error code or 0 if success)
	.xdef	_mxdrvset
_mxdrvset:
	movem.l	a1-a2,-(sp)		; Save registers (8 bytes)
	move.l	12(sp),a1		; A1 = MDX data pointer (4+8=12)
	suba.l	a2,a2			; A2 = 0 (no PDX data)
	move.l	#2,d0			; D0 = SETMDX function
	trap	#4			; Call MXDRV SETMDX
	movem.l	(sp)+,a1-a2		; Restore registers
	rts				; Return with result in D0

* int mxdrvplay(void);
* Start playback using MXDRV PLAY function
* Function 4 = L_PLAY, Function 15 (0x0F) = L_PlayWithMask
* MUST call mxdrvset first!
* Returns D0 (error code or 0 if success)
	.xdef	_mxdrvplay
_mxdrvplay:
	movem.l	d1/a1-a2,-(sp)		; Save registers
	moveq	#0,d1			; D1 = 0
	suba.l	a1,a1			; A1 = 0
	suba.l	a2,a2			; A2 = 0
	move.l	#4,d0			; D0 = 4 (L_PLAY)
	trap	#4			; Call MXDRV
	movem.l	(sp)+,d1/a1-a2		; Restore registers
	rts				; Return with result in D0

* void* mxdrvwork(void);
* Get MXDRV work area pointer (function 0)
* Returns pointer to work area in D0
	.xdef	_mxdrvwork
_mxdrvwork:
	move.l	#0,d0			; D0 = 0 (get work area function)
	trap	#4			; Call MXDRV
	rts				; Return with work area pointer in D0

	.end
