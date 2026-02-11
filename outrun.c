/*
 * ============================================================================
 * OUT RUN Music Player for Sharp X68000 - C Version
 * ============================================================================
 * This program plays the four Out Run music tracks using MXDRV
 * ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* MXDRV function numbers */
#define MXDRV_START   0x00
#define MXDRV_END     0x01
#define MXDRV_STAT    0x02
#define MXDRV_PLAY    0x03
#define MXDRV_STOP    0x04
#define MXDRV_PAUSE   0x05
#define MXDRV_CONT    0x06
#define MXDRV_FADEOUT 0x07

/* Human68k DOS call numbers */
#define DOS_EXEC   0x4b
#define DOS_INKEY  0x01

/* Track definitions */
typedef struct {
    const char *name;
    const char *filename;
    const char *message;
} Track;

Track tracks[] = {
    {"Magical Sound Shower", "MAGICAL.MDX", "Now playing: Magical Sound Shower\r\n"},
    {"Passing Breeze",       "PASSING.MDX", "Now playing: Passing Breeze\r\n"},
    {"Splash Wave",          "SPLASH.MDX",  "Now playing: Splash Wave\r\n"},
    {"Last Wave",            "LAST.MDX",    "Now playing: Last Wave\r\n"}
};

/* MXDRV interface using trap #2 - function number in d0, returns result in d0 */
int mxdrv_call(int func) {
    register int d0 __asm__("d0") = func;

    __asm__ volatile (
        "trap #2"
        : "+r" (d0)
        :
        : "d1", "d2", "a0", "a1", "a2", "memory"
    );

    return d0;
}

void mxdrv_play(void *data) {
    register int d0 __asm__("d0") = MXDRV_PLAY;

    __asm__ volatile (
        "pea (%1)\n\t"
        "trap #2\n\t"
        "addq.l #4,%%sp"
        : "+r" (d0)
        : "a" (data)
        : "d1", "d2", "a0", "a1", "a2", "memory"
    );
}

/* Initialize MXDRV driver */
int load_mxdrv(void) {
    int result;

    printf("Initializing MXDRV driver...\r\n");
    printf("\r\n");
    printf("NOTE: If you get an error here, make sure to run:\r\n");
    printf("      MXDRV.X\r\n");
    printf("      before running this program!\r\n");
    printf("\r\n");
    fflush(stdout);

    /* Try to initialize MXDRV - this will fail if MXDRV.X hasn't been run */
    result = mxdrv_call(MXDRV_START);

    if (result < 0) {
        printf("ERROR: MXDRV initialization failed (returned %d)\r\n", result);
        printf("Please run MXDRV.X first, then try again.\r\n");
        return -1;
    }

    printf("MXDRV initialized successfully.\r\n");
    fflush(stdout);

    return 0;
}

/* Play a track */
int play_track(int track_num) {
    FILE *fp;
    void *buffer;
    size_t bytes_read;
    Track *track;

    if (track_num < 0 || track_num >= 4) {
        return -1;
    }

    track = &tracks[track_num];

    /* Stop current music first */
    mxdrv_call(MXDRV_STOP);

    /* Print status message */
    printf("%s", track->message);
    fflush(stdout);

    /* Open the MDX file */
    fp = fopen(track->filename, "rb");
    if (!fp) {
        printf("\r\nERROR: Could not open %s!\r\n", track->filename);
        return -1;
    }

    /* Allocate 64KB buffer for MDX data */
    buffer = malloc(65536);
    if (!buffer) {
        printf("\r\nERROR: Could not allocate memory!\r\n");
        fclose(fp);
        return -1;
    }

    /* Read file into buffer */
    bytes_read = fread(buffer, 1, 65536, fp);
    fclose(fp);

    if (bytes_read == 0) {
        printf("\r\nERROR: Could not read file data!\r\n");
        free(buffer);
        return -1;
    }

    /* Play the MDX data */
    mxdrv_play(buffer);

    /* Free buffer */
    free(buffer);

    return 0;
}

/* Stop music playback */
void stop_music(void) {
    mxdrv_call(MXDRV_STOP);
    printf("\r\nMusic stopped.\r\n");
    fflush(stdout);
}

/* Print banner and menu */
void print_banner(void) {
    printf("\033[2J\033[H");  /* Clear screen and home cursor */
    printf("============================================\r\n");
    printf("   OUT RUN Music Player for X68000\r\n");
    printf("============================================\r\n");
    printf("\r\n");
    fflush(stdout);
}

void print_menu(void) {
    printf("\r\n");
    printf("Select a track:\r\n");
    printf("  1. Magical Sound Shower\r\n");
    printf("  2. Passing Breeze\r\n");
    printf("  3. Splash Wave\r\n");
    printf("  4. Last Wave\r\n");
    printf("\r\n");
    printf("  S. Stop music\r\n");
    printf("  Q. Quit\r\n");
    printf("\r\n");
    printf("Your choice: ");
    fflush(stdout);
}

/* Read a character using DOS _INKEY */
int dos_inkey(void) {
    int ch;
    __asm__ volatile (
        "move.w #0x01,-(%%sp)\n\t"    /* DOS _INKEY function */
        "trap #15\n\t"                 /* DOS call */
        "addq.l #2,%%sp\n\t"           /* Clean up stack */
        "move.w %%d0,%0"               /* Get result */
        : "=r" (ch)
        :
        : "d0", "d1", "memory"
    );
    return ch & 0xFF;
}

/* Main program */
int main(void) {
    int ch;
    int running = 1;

    /* Print banner */
    print_banner();

    /* Initialize MXDRV driver */
    if (load_mxdrv() < 0) {
        printf("\r\nERROR: MXDRV driver is not loaded!\r\n");
        printf("Please run MXDRV.X first, then run this program.\r\n");
        printf("Example: MXDRV.X\r\n");
        return 1;
    }

    /* Main loop */
    while (running) {
        print_menu();

        /* Read character using DOS _INKEY (direct DOS call) */
        ch = dos_inkey();

        /* Process input */
        switch (toupper(ch)) {
            case '1':
                play_track(0);
                break;
            case '2':
                play_track(1);
                break;
            case '3':
                play_track(2);
                break;
            case '4':
                play_track(3);
                break;
            case 'S':
                stop_music();
                break;
            case 'Q':
            case 0x1B:  /* ESC key */
                running = 0;
                break;
        }
    }

    /* Cleanup */
    mxdrv_call(MXDRV_STOP);
    mxdrv_call(MXDRV_END);

    printf("\r\nThanks for listening!\r\n");

    return 0;
}
