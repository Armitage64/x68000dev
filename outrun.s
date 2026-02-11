* ============================================================================
* OUT RUN Music Player for Sharp X68000
* ============================================================================
* This program plays the four Out Run music tracks using MXDRV
* ============================================================================

	section text

* Human68k DOS call numbers
_PRINT		equ	$09
_INKEY		equ	$01
_GETC		equ	$08
_EXIT		equ	$4c
_OPEN		equ	$3d
_CLOSE		equ	$3e
_READ		equ	$3f
_SUPER		equ	$20
_MALLOC		equ	$48
_MFREE		equ	$49
_EXEC		equ	$4b

* MXDRV function numbers
MXDRV_START	equ	$00
MXDRV_END	equ	$01
MXDRV_STAT	equ	$02
MXDRV_PLAY	equ	$03
MXDRV_STOP	equ	$04
MXDRV_PAUSE	equ	$05
MXDRV_CONT	equ	$06
MXDRV_FADEOUT	equ	$07

* Program start
start:
	* Print banner
	pea	banner
	move.w	#_PRINT,-(sp)
	trap	#15
	addq.l	#6,sp

	* Load MXDRV driver
	bsr	load_mxdrv
	tst.l	d0
	bne	error_mxdrv

main_loop:
	* Print menu
	pea	menu_text
	move.w	#_PRINT,-(sp)
	trap	#15
	addq.l	#6,sp

	* Wait for key press
	move.w	#_INKEY,-(sp)
	trap	#15
	addq.l	#2,sp

	* Check which key was pressed
	cmp.b	#'1',d0
	beq	play_magical
	cmp.b	#'2',d0
	beq	play_passing
	cmp.b	#'3',d0
	beq	play_splash
	cmp.b	#'4',d0
	beq	play_last
	cmp.b	#'S',d0
	beq	stop_music
	cmp.b	#'s',d0
	beq	stop_music
	cmp.b	#'Q',d0
	beq	exit_program
	cmp.b	#'q',d0
	beq	exit_program
	cmp.b	#$1b,d0		* ESC key
	beq	exit_program

	bra	main_loop

play_magical:
	pea	magical_file
	pea	playing_magical
	bsr	play_track
	addq.l	#8,sp
	bra	main_loop

play_passing:
	pea	passing_file
	pea	playing_passing
	bsr	play_track
	addq.l	#8,sp
	bra	main_loop

play_splash:
	pea	splash_file
	pea	playing_splash
	bsr	play_track
	addq.l	#8,sp
	bra	main_loop

play_last:
	pea	last_file
	pea	playing_last
	bsr	play_track
	addq.l	#8,sp
	bra	main_loop

stop_music:
	* Stop current music
	move.w	#MXDRV_STOP,-(sp)
	trap	#10
	addq.l	#2,sp

	pea	stopped_msg
	move.w	#_PRINT,-(sp)
	trap	#15
	addq.l	#6,sp

	bra	main_loop

exit_program:
	* Stop music
	move.w	#MXDRV_STOP,-(sp)
	trap	#10
	addq.l	#2,sp

	* Unload MXDRV
	move.w	#MXDRV_END,-(sp)
	trap	#10
	addq.l	#2,sp

	pea	goodbye_msg
	move.w	#_PRINT,-(sp)
	trap	#15
	addq.l	#6,sp

	move.w	#0,-(sp)
	move.w	#_EXIT,-(sp)
	trap	#15

error_mxdrv:
	pea	error_msg
	move.w	#_PRINT,-(sp)
	trap	#15
	addq.l	#6,sp

	move.w	#1,-(sp)
	move.w	#_EXIT,-(sp)
	trap	#15

* ============================================================================
* Load MXDRV driver
* ============================================================================
load_mxdrv:
	* Load MXDRV.X as a process
	move.w	#0,-(sp)		* mode
	move.w	#0,-(sp)		* load only
	pea	mxdrv_path
	move.w	#_EXEC,-(sp)
	trap	#15
	lea	12(sp),sp

	tst.l	d0
	bmi	.error

	* Initialize MXDRV
	move.w	#MXDRV_START,-(sp)
	trap	#10
	addq.l	#2,sp

	moveq	#0,d0
	rts

.error:
	moveq	#-1,d0
	rts

* ============================================================================
* Play a track
* Parameters:
*   4(sp) = pointer to status message
*   8(sp) = pointer to filename
* ============================================================================
play_track:
	movem.l	d0-d7/a0-a6,-(sp)

	* Stop current music first
	move.w	#MXDRV_STOP,-(sp)
	trap	#10
	addq.l	#2,sp

	* Print status message
	move.l	4+60(sp),-(sp)		* status message
	move.w	#_PRINT,-(sp)
	trap	#15
	addq.l	#6,sp

	* Open the MDX file
	move.w	#0,-(sp)		* mode (read)
	move.l	8+60(sp),-(sp)		* filename
	move.w	#_OPEN,-(sp)
	trap	#15
	addq.l	#8,sp

	tst.l	d0
	bmi	.error_open
	move.w	d0,d7			* save file handle

	* Allocate 64KB buffer for MDX data
	move.l	#$10000,-(sp)		* 64KB
	move.w	#_MALLOC,-(sp)
	trap	#15
	addq.l	#6,sp

	tst.l	d0
	bmi	.error_malloc
	move.l	d0,a5			* save buffer address

	* Read file into buffer
	move.l	a5,-(sp)		* buffer
	move.l	#$10000,-(sp)		* size
	move.w	d7,-(sp)		* handle
	move.w	#_READ,-(sp)
	trap	#15
	lea	12(sp),sp

	* Close file
	move.w	d7,-(sp)
	move.w	#_CLOSE,-(sp)
	trap	#15
	addq.l	#4,sp

	* Play the MDX data
	move.l	a5,-(sp)		* pointer to MDX data
	move.w	#MXDRV_PLAY,-(sp)
	trap	#10
	addq.l	#6,sp

	* Free buffer
	move.l	a5,-(sp)
	move.w	#_MFREE,-(sp)
	trap	#15
	addq.l	#6,sp

	movem.l	(sp)+,d0-d7/a0-a6
	rts

.error_open:
	pea	error_file_msg
	move.w	#_PRINT,-(sp)
	trap	#15
	addq.l	#6,sp
	movem.l	(sp)+,d0-d7/a0-a6
	rts

.error_malloc:
	* Close file first
	move.w	d7,-(sp)
	move.w	#_CLOSE,-(sp)
	trap	#15
	addq.l	#4,sp

	pea	error_mem_msg
	move.w	#_PRINT,-(sp)
	trap	#15
	addq.l	#6,sp
	movem.l	(sp)+,d0-d7/a0-a6
	rts

* ============================================================================
* Data section
* ============================================================================
	section data

banner:
	dc.b	$1b,'[','2','J'		* Clear screen
	dc.b	$1b,'[','H'		* Home cursor
	dc.b	'============================================',$0d,$0a
	dc.b	'   OUT RUN Music Player for X68000',$0d,$0a
	dc.b	'============================================',$0d,$0a
	dc.b	$0d,$0a,0

menu_text:
	dc.b	$0d,$0a
	dc.b	'Select a track:',$0d,$0a
	dc.b	'  1. Magical Sound Shower',$0d,$0a
	dc.b	'  2. Passing Breeze',$0d,$0a
	dc.b	'  3. Splash Wave',$0d,$0a
	dc.b	'  4. Last Wave',$0d,$0a
	dc.b	$0d,$0a
	dc.b	'  S. Stop music',$0d,$0a
	dc.b	'  Q. Quit',$0d,$0a
	dc.b	$0d,$0a
	dc.b	'Your choice: ',0

playing_magical:
	dc.b	$0d,$0a
	dc.b	'Now playing: Magical Sound Shower',$0d,$0a,0

playing_passing:
	dc.b	$0d,$0a
	dc.b	'Now playing: Passing Breeze',$0d,$0a,0

playing_splash:
	dc.b	$0d,$0a
	dc.b	'Now playing: Splash Wave',$0d,$0a,0

playing_last:
	dc.b	$0d,$0a
	dc.b	'Now playing: Last Wave',$0d,$0a,0

stopped_msg:
	dc.b	$0d,$0a
	dc.b	'Music stopped.',$0d,$0a,0

goodbye_msg:
	dc.b	$0d,$0a
	dc.b	'Thanks for listening!',$0d,$0a,0

error_msg:
	dc.b	$0d,$0a
	dc.b	'ERROR: Could not load MXDRV.X driver!',$0d,$0a
	dc.b	'Make sure MXDRV.X is in the current directory.',$0d,$0a,0

error_file_msg:
	dc.b	$0d,$0a
	dc.b	'ERROR: Could not open MDX file!',$0d,$0a,0

error_mem_msg:
	dc.b	$0d,$0a
	dc.b	'ERROR: Could not allocate memory!',$0d,$0a,0

mxdrv_path:
	dc.b	'MXDRV.X',0

magical_file:
	dc.b	'MAGICAL.MDX',0

passing_file:
	dc.b	'PASSING.MDX',0

splash_file:
	dc.b	'SPLASH.MDX',0

last_file:
	dc.b	'LAST.MDX',0

	even

	end
