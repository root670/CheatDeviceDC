#include <kos.h>
#include "version.h"

int main(int argc, char *argv[])
{
    int x, y, o;

    for(y = 0; y < 480; y++)
        for(x = 0; x < 640; x++) {
            int c = (x ^ y) & 255;
            vram_s[y * 640 + x] = ((c >> 3) << 12)
                                  | ((c >> 2) << 5)
                                  | ((c >> 3) << 0);
        }

    o = 20 * 640 + 20;

    /* Test with ISO8859-1 encoding */
    bfont_set_encoding(BFONT_CODE_ISO8859_1);
    bfont_draw_str(vram_s + o, 640, 1, "Cheat Device " GIT_VERSION);

    /* Pause to see the results */
    usleep(5 * 1000 * 1000);

    return 0;
}
