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

/* MXDRV interface - implemented in mxdrv_asm.s */
extern int mxdrv_call(int func);
extern int mxdrv_set_mdx(void *data, int size);
extern int mxdrv_set_pdx(const char *filename);
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
    static void *mdx_buffer = NULL;  /* Static buffer that persists - MXDRV keeps pointer to it! */
    static void *mdx_buffer_orig = NULL;  /* Original malloc pointer for free() */
    size_t bytes_read;
    int result;
    Track *track;
    char pdx_filename[256];  /* Function-level so MXDRV can access it during playback */

    if (track_num < 0 || track_num >= 4) {
        return -1;
    }

    track = &tracks[track_num];

    /* Stop current music first */
    mxdrv_call(MXDRV_STOP);

    /* Free old buffer if it exists (use original pointer!) */
    if (mdx_buffer_orig) {
        free(mdx_buffer_orig);
        mdx_buffer_orig = NULL;
        mdx_buffer = NULL;
    }

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
    /* Add 1 extra byte to ensure we can align to even address */
    mdx_buffer_orig = malloc(65536 + 1);
    if (!mdx_buffer_orig) {
        printf("\r\nERROR: Could not allocate memory!\r\n");
        fclose(fp);
        return -1;
    }

    /* Ensure buffer is aligned to even address (required by 68000) */
    mdx_buffer = mdx_buffer_orig;
    if ((unsigned long)mdx_buffer & 1) {
        mdx_buffer = (void *)((unsigned long)mdx_buffer + 1);
        printf("DEBUG: Aligned buffer from 0x%08lx to 0x%08lx\r\n",
               (unsigned long)mdx_buffer_orig, (unsigned long)mdx_buffer);
    } else {
        printf("DEBUG: Buffer already aligned at 0x%08lx\r\n", (unsigned long)mdx_buffer);
    }
    fflush(stdout);

    /* Read file into buffer */
    bytes_read = fread(mdx_buffer, 1, 65536, fp);
    fclose(fp);

    if (bytes_read == 0) {
        printf("\r\nERROR: Could not read file data!\r\n");
        free(mdx_buffer_orig);
        mdx_buffer_orig = NULL;
        mdx_buffer = NULL;
        return -1;
    }

    printf("DEBUG: Read %d bytes from %s\r\n", (int)bytes_read, track->filename);
    fflush(stdout);

    /* Try using the integrated mxdrv_play function that does SETMDX+PLAY in one go */
    printf("DEBUG: Calling mxdrv_play (does SETMDX+PLAY in assembly)...\r\n");
    fflush(stdout);

    mxdrv_play(mdx_buffer);

    printf("DEBUG: mxdrv_play completed!\r\n");
    fflush(stdout);

    /* DON'T free buffer - MXDRV keeps a pointer to it and uses it during playback! */
    /* Buffer will be freed when loading next track or when program exits */

    printf("Playback started successfully!\r\n");
    fflush(stdout);

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
