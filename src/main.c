#include "z80-stub.h"
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <stdbool.h>

unsigned char main (void) {
    unsigned char cont = 0;
    debug_swbreak();
    printf("hello world\n");
    while(!cont) {}
    printf("goodbye world\n");
    return 0;
}