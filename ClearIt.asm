;****************************************
;*           ClearIt v.61 beta          *
;*             Keith Batten             *
;****************************************
;*            -What it Does-            *
;* Installs and returns a 1 in ans      *
;* Uninstalls and returns a 0 in ans    *
;* Fakes Reset All                      *
;* Fakes Reset Mem                      *
;* Resets Contrast After Reset All      *
;****************************************
;*         -What it Doesn't Do-         *
;* Doesn't Clear Screen After Key Press *
;* Doesn't Fake Mem View                *
;* Doesn't Fake Custom Menu             *
;* Doesn't Fake Program Names Menu      *
;****************************************


#include "asm86.h"
#include "Ti86abs.inc"
#include "Ti86asm.inc"
#include "Ti86ops.inc"

_CXCURAPP                 equ         0C1B4h

;*********************************************
;* 01 for the home screen                    *
;* 02 for the polynomial solver              *
;* 03 for the simultaneous equation solver   *
;* 05 for the constant editor                *
;* 06 for the vector editor                  *
;* 07 for the matrix editor                  *
;* 08 for the program editor                 *
;* 0c for the interpolate/extrapolate editor *
;* 0e for the list/stat editor               *
;* 12 for tolerance                          *
;* 19 for the table                          *
;* 1a for table setup                        *
;* 1b for link                               *
;* 1d for reset mem prompt                   *
;* 1e for reset defaults prompt              *
;* 1f for reset all prompt                   *
;* 20 for RAM                                *
;* 21 for mode/self test                     *
;* 23 for delete variables                   *
;* 49 for the function editor                *
;* 4a for the window editor                  *
;* 4c for the graph                          *
;* 53 initial conditions                     *
;* 54 axes something                         *
;* 62 for format                             *
;* 96 for cat/var                            *
;* 98 for an error message                   *
;*********************************************

.org _asm_exec_ram

   nop
   jp    Start
   .dw   0000h
   .dw   Description          ; set the description for a shell
Description:
   .db   "ClearIt v.61 KWB",0

Start:
   ld    hl,op_info           ; check for (sqrt) program already installed
   rst   20h                  ; ld (op1) with (hl)
   call  _FINDSYM             ; is there a variable (sqrt)key?
   jr    c, Install           ; didn't find it so install ours :)

Uninstall:
   call  _delvar              ; delete (sqrt)key using data from _FINDSYM
   ld    hl, uninstalled
   call  _puts
   call  _newline
   call  _OP1SET0             ; store float 0 into op1
   call  _stoans              ; return float 0 in ans
   jp    $409c                ; clean exit

Install:
   ld    hl, installed
   call  _puts
   call  _newline

   call  _op1set1             ; store float 1 into op1
   call  _stoans              ; return float 1 in ans

   ld    hl, op_info
   rst   20h                  ;[sqrt]KEY -> OP1
   ld    hl, code_end - code
   call  $474f                ;creates program
   ld    a, b
   ex    de, hl
   call  $4c3f
   call  _SET_ABS_DEST_ADDR
   xor   a
   ld    hl,code_end - code
   call  _SET_MM_NUM_BYTES
   xor   a
   ld    hl, code
   call  _SET_ABS_SRC_ADDR
   call  _mm_ldir
   set   6,(iy+$24)           ; enables program
   jp    $409c                ; clean exit

op_info:
   .db   $12,$4,$10
   .db   "KEY",0

code:
   .db   $8e,$28
   call  $479f                ;special call
   ld    a, ($d625)           ;get saved a register
   bit   0, (iy+$20)
   jr    nz, skip_and_pop
   push  af                   ;push getkey
   ld    a, ($c1b4)           ;load calc state

check_reset_all:              ;checks if state is reset all
   cp    $1f
   jr    nz, check_reset_mem
   pop   af
   cp    $32                  ;check for [f4]
   jr    nz, skip_key

   ld    a, $0A               ; load default contrast value
   ld    (CONTRAST), a        ; write it back to memory
   out   (2), a               ; and to the port

   call  _clrLCD
   jr    Reset_All_Disp

check_reset_mem:              ;checks if state is reset mem
   cp    $1d
   jr    nz, skip_and_pop
   pop   af
   cp    $32                  ;check for [f4]
   jr    nz, skip_key
   call  _clrLCD
   jr    Mem_Cleared_Disp

Reset_All_Disp:
   ld    hl, $0504
   ld    (_curRow), hl
   ld    hl, $d746 + defaults_set - code
   call  _puts

Mem_Cleared_Disp:
   ld    hl, $0403
   ld    (_curRow), hl
   ld    hl, $d746 + mem_cleared - code
   call  _puts

;   ??? send a to homescreen ???

   call  _homeup
;   set curAble, (iy + curflags)
;   call _getkey
   
;   call  _clrLCD
;   call  _clrScrn
;   call  $4ab5                ; clear _cmdShadow???

	ld		a, $37
	cp		a

   jp    $4109                ; reset calc
	ret

skip_key:
   cp    a                    ;set zero flag
   ret

skip_and_pop:
   pop   af
   jr    skip_key

uninstalled:
   .db   "ClearIt Uninstalled",0
installed:
   .db   "ClearIt Installed",0

mem_cleared:
   .db   " Mem Cleared ",0
defaults_set:
   .db   "Defaults Set",0

test:
	.db	"test",0

code_end:

.end
