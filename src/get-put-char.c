#include "z80-stub.h"
#include <conio.h>
#include <stdbool.h>

__asm
	INCLUDE "Ti83p.def"
__endasm;

static bool getting = false;

#define BUF_SIZE 16*8

static unsigned char buf[BUF_SIZE];
static unsigned char bufLength = 0;

static void peekChar(unsigned char c, bool get) {
	if(getting != get) {
		getting = get;
		printf("%.*s", bufLength, buf);
		bufLength = 0;
	}
	else {
		clrscr();
	}

	if(bufLength < BUF_SIZE - 1) {
		buf[bufLength] = c;
		bufLength++;
	}
}

void _putDebugChar (unsigned char ch) {
	ch;
	__asm
		DI
		ld iy,2
		add iy,sp

		ld a,(iy)

		LD IY,_IY_TABLE

		ld hl,__putDebugChar
		CALL APP_PUSH_ERRORH

		SET indicOnly,(IY+indicFlags)
		rst 0x28
		DEFW _SendAByte
		RES indicOnly,(IY+indicFlags)

		CALL APP_POP_ERRORH

		EI
	__endasm;
}

void putDebugChar (unsigned char ch) {
	_putDebugChar(ch);
}

unsigned char getDebugChar (void) {
	__asm
		DI
		LD IY,_IY_TABLE

		ld hl,_getDebugChar
		CALL APP_PUSH_ERRORH

		SET indicOnly,(IY+indicFlags)
		rst 0x28
		DEFW _RecAByteIO
		RES indicOnly,(IY+indicFlags)

		LD L,A

		CALL APP_POP_ERRORH

		EI
	__endasm;
}