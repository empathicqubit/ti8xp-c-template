#include "../3rdparty/z88dk-gdbstub/src/gdb.h"
#include "../lib/debug-impl.h"
#include <conio.h>

unsigned char main (void) {
    // This is needed to set up the debugger
    // To disable it, comment out GDB=1 in the Makefile
    // With this option can leave debug.h references in your code
    // If debugging is enabled, you MUST attach a debugger to continue
    puts("running");
    debug_init();
    gdb_swbreak();

    do
    {
        puts("hello world");
        puts("goodbye world");
    }
    while
        (
         1
        )
            ;

    while(1);

    return 0;
}
