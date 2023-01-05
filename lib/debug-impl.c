#ifdef GDB_ENABLED

#include <stdbool.h>
#include <string.h>
#include <stdio.h>

#include "../3rdparty/z88dk-gdbstub/src/gdb.h"
#include "debug-impl.h"

//#define DBG_SIMULATED

__asm
	INCLUDE "Ti83p.def"
__endasm;

#ifdef DBG_SIMULATED
#define SCREENSIZE 16*8
static unsigned char screenCount = 16;

static char dbg_cmdbuf[] =
    "+$qSupported#37+";
static char* dbg_cmdcursor = dbg_cmdbuf;
unsigned char gdb_getDebugChar (void) {
    if(dbg_cmdcursor >= dbg_cmdbuf + sizeof(dbg_cmdbuf)) {
        while(1);
    }

    return *dbg_cmdcursor++;
}
void gdb_putDebugChar (unsigned char ch) {
    screenCount++;
    putchar(ch);
}
#else
static unsigned char unsentByte = '\0';
void gdb_putDebugChar (unsigned char ch) __z88dk_fastcall {
	ch;
	__asm
		LD IY,_IY_TABLE
		LD A,L
		LD (_unsentByte),A
retry_putDebugChar:
		DI
		LD A,(_unsentByte)

		ld hl,retry_putDebugChar
		CALL APP_PUSH_ERRORH

		SET indicOnly,(IY+indicFlags)
		rst 0x28
		DEFW _SendAByte
		RES indicOnly,(IY+indicFlags)

		CALL APP_POP_ERRORH

		EI
	__endasm;
}

unsigned char gdb_getDebugChar (void) __z88dk_fastcall {
	__asm
		DI

		ld hl,_gdb_getDebugChar
		CALL APP_PUSH_ERRORH

		LD IY,_IY_TABLE

		SET indicOnly,(IY+indicFlags)
		rst 0x28
		DEFW _RecAByteIO
		RES indicOnly,(IY+indicFlags)

		LD L,A

		CALL APP_POP_ERRORH

		EI
	__endasm;
}
#endif

extern unsigned char _CODE_head;
extern unsigned char _CODE_END_tail;

#define NOP 0x00

int toggle_swbreak(int set, void *addr) {
    unsigned char str[10];
	static unsigned char call_swbreak[3] = { 0xcd, 0x00, 0x00 };
	unsigned char *insert = addr;
    // Clean up all breaks
    if(addr == NULL) {
        insert = &_CODE_END_tail;
        insert -= sizeof(call_swbreak);
    }

	*(void**)&call_swbreak[1] = &gdb_swbreak;
    do {
        if(
            memcmp(insert, "\0\0\0", sizeof(call_swbreak)) == 0
            || memcmp(insert, call_swbreak, sizeof(call_swbreak)) == 0
        ) {
            if(set) {
                memcpy(insert, call_swbreak, sizeof(call_swbreak));
            }
            else {
                memset(insert, NOP, sizeof(call_swbreak));
            }

            if(addr) {
                break;
            }
        }
        insert--;
    } while(insert >= &_CODE_head);

	return 0;
}

void debug_enter(void) {
}

int toggle_step(int set) {
	static unsigned char call_step[3] = { 0xcd, 0x00, 0x00 };
	*(void**)&call_step[1] = &gdb_step;
    unsigned char str[3] = "   ";
	unsigned char* pos;
	if(set) {
        unsigned char count = 0;
        for(pos = &_CODE_END_tail - sizeof(call_step); pos >= _CODE_head; pos--) {
            if(*pos == 0) {
                count++;
            }
            else {
                count = 0;
                continue;
            }

            if(count == sizeof(call_step)) {
                count = 0;
                memcpy(pos, call_step, sizeof(call_step));
            }
        }
	}
	else {
        for(pos = &_CODE_END_tail - sizeof(call_step); pos >= _CODE_head; pos--) {
            if(memcmp(pos, call_step, sizeof(call_step)) == 0) {
                memset(pos, NOP, sizeof(call_step));
            }
        }
	}

	return 0;
}

void debug_init (void) {
    gdb_set_enter(&debug_enter);
    gdb_set_swbreak_toggle(&toggle_swbreak);
    gdb_set_step_toggle(&toggle_step);
}
#else /* GDB_ENABLED */
void debug_init (void) {}
void debug_swbreak(void) {}
#endif /* GDB_ENABLED */
