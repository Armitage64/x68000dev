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

/* MXDRV function numbers - based on mdxtools documentation */
#define MXDRV_FREE          0x00
#define MXDRV_ERROR         0x01
#define MXDRV_SETMDX        0x02  /* Load MDX data */
#define MXDRV_SETPDX        0x03  /* Load PDX data */
#define MXDRV_PLAY          0x04  /* Start playback */
#define MXDRV_STOP          0x05  /* Stop playback */
#define MXDRV_PAUSE         0x06  /* Pause */
#define MXDRV_CONT          0x07  /* Continue */
#define MXDRV_FADEOUT       0x0C  /* Fade out */
#define MXDRV_GET_STATUS    0x12  /* Get playback flags/status */

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

/* External MXDRV functions from mxdrv_asm.s (known working implementation) */
extern int mxdrv_call(int func);
extern void mxdrv_play(void *data);

/* DOS functions - defined later in this file */
int dos_inkey(void);

/* Initialize MXDRV driver */
int load_mxdrv(void) {
    int result;

    printf("Checking MXDRV driver...\r\n");
    printf("\r\n");
    printf("NOTE: Make sure MXDRV.X is loaded before running!\r\n");
    printf("      If the system crashes here, run: MXDRV.X\r\n");
    printf("\r\n");
    fflush(stdout);

    printf("DEBUG: About to call trap #4 with MXDRV_GET_STATUS (func=0x%02x)...\r\n", MXDRV_GET_STATUS);
    fflush(stdout);

    /* Check if MXDRV is loaded using GET_STATUS */
    result = mxdrv_call(MXDRV_GET_STATUS);

    printf("DEBUG: trap #4 returned successfully! Result = %d (0x%04x)\r\n", result, result & 0xFFFF);
    fflush(stdout);

    if (result < 0) {
        printf("ERROR: MXDRV not loaded (returned %d / $%04x)\r\n", result, result & 0xFFFF);
        printf("Please run MXDRV.X first, then try again.\r\n");
        printf("\r\nPress any key to exit...\r\n");
        dos_inkey();
        return -1;
    }

    printf("MXDRV is loaded and ready (status: %d).\r\n", result);
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

    /* Cleanup - stop music but don't unload MXDRV (we didn't load it) */
    mxdrv_call(MXDRV_STOP);
    /* Note: We don't call MXDRV_END because MXDRV.X was loaded externally as TSR */

    printf("\r\nThanks for listening!\r\n");

    return 0;
}
