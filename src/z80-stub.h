#ifndef __Z80_STUB_H__
#define __Z80_STUB_H__

/* Enter to debug mode from software or hardware breakpoint.
   Assume address of next instruction after breakpoint call is on top of stack.
   Do JP _debug_swbreak or JP _debug_hwbreak from RST handler, for example.
 */
void debug_swbreak (void);
void debug_hwbreak (void);

/* Jump to this function from NMI handler. Just replace RETN instruction by
   JP _debug_nmi
   Use if NMI detects request to enter to debug mode.
 */
void debug_nmi (void);

/* Jump to this function from INT handler. Just replace EI+RETI instructions by
   JP _debug_int
   Use if INT detects request to enter to debug mode.
 */
void debug_int (void);

/* Prints to debugger console. */
void debug_print(const char *str);
/******************************************************************************\
			      Required functions
\******************************************************************************/

unsigned char getDebugChar (void);
void putDebugChar (unsigned char ch);

#endif