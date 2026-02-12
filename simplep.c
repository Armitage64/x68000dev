/*
 * Simple MDX Player - No work area check
 * Just try to load and play LAST.MDX directly
 * Filename: simplep.c (no underscores for X68000 keyboard)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iocslib.h>
#include <doslib.h>

extern int mxdrvset(void *data);
extern int mxdrvplay(void);
extern int mxdrvcall(int func);

#define MDX_MAX_SIZE 65536

int main(int argc, char *argv[]) {
    void *mdx_data;
    int result;
    const char *filename = "LAST.MDX";
    FILE *fp;
    long file_size;

    printf("Simple MDX Player\r\n");
    printf("=================\r\n\r\n");

    if (argc > 1) {
        filename = argv[1];
    }

    printf("Loading: %s\r\n", filename);

    /* Open MDX file */
    fp = fopen(filename, "rb");
    if (!fp) {
        printf("ERROR: Cannot open file\r\n");
        return 1;
    }

    /* Get file size */
    fseek(fp, 0, SEEK_END);
    file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    printf("File size: %ld bytes\r\n", file_size);

    if (file_size <= 0 || file_size > MDX_MAX_SIZE) {
        printf("ERROR: Invalid file size\r\n");
        fclose(fp);
        return 1;
    }

    /* Allocate memory */
    mdx_data = malloc(file_size);
    if (!mdx_data) {
        printf("ERROR: Cannot allocate memory\r\n");
        fclose(fp);
        return 1;
    }

    /* Read MDX data */
    if (fread(mdx_data, 1, file_size, fp) != file_size) {
        printf("ERROR: Cannot read file\r\n");
        free(mdx_data);
        fclose(fp);
        return 1;
    }
    fclose(fp);

    printf("MDX data loaded at: 0x%08lx\r\n\r\n", (unsigned long)mdx_data);

    /* Step 1: Load MDX with SETMDX (function 2) */
    printf("Calling MXDRV SETMDX...\r\n");
    result = mxdrvset(mdx_data);
    printf("SETMDX result: %d (0x%08x)\r\n", result, result);

    if (result < 0) {
        printf("\r\nERROR: SETMDX failed!\r\n");
        free(mdx_data);
        return 1;
    }

    /* Step 2: Start playback with PLAY (function 4) */
    printf("\r\nCalling MXDRV PLAY...\r\n");
    result = mxdrvplay();
    printf("PLAY result: %d (0x%08x)\r\n", result, result);

    if (result < 0) {
        printf("\r\nERROR: PLAY failed!\r\n");
        free(mdx_data);
        return 1;
    }

    printf("\r\n** Music should be playing now! **\r\n");
    printf("Press any key to stop...\r\n");

    /* Wait for keypress */
    _dos_getchar();

    /* Stop playback (function 5) */
    printf("\r\nStopping playback...\r\n");
    mxdrvcall(5);  /* STOP function */

    free(mdx_data);
    printf("Done.\r\n");

    return 0;
}
