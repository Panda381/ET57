; ****************************************************************************
;
;                     Includes - calculator macro literals
;
; ****************************************************************************

; ... control operations (20)
#define C_CT_BASE	0
#define C_NOP		(C_CT_BASE+0)	// no function (required by byte align, hardcoded to 0)
#define C_END		(C_CT_BASE+1)	// end calculator macro
#define C_DEL		(C_CT_BASE+2)	// delete top number
#define C_DUP		(C_CT_BASE+3)	// duplicate last number
#define C_DUP2		(C_CT_BASE+4)	// duplicate pre2-last number
#define C_EXC		(C_CT_BASE+5)	// exchange 2 top numbers
#define C_EXC2		(C_CT_BASE+6)	// exchange 2 pre-top2 numbers
#define C_JMP		(C_CT_BASE+7)	// relative jump (offset is relative to next byte)
#define C_JUMPT		(C_CT_BASE+8)	// relative jump if true, top number<>0, delete it (offset is relative to next byte)
#define C_JUMPF		(C_CT_BASE+9)	// relative jump if false, top number=0, delete it (offset is relative to next byte)
#define C_JUMPNZ	(C_CT_BASE+10)	// relative jump if top number is not zero, do not delete it
#define C_JUMPZ		(C_CT_BASE+11)	// relative jump if top number is zero, do not delete it
#define C_ERROR		(C_CT_BASE+12)	// set error flag
#define C_CONST1	(C_CT_BASE+13)	// load constant 1
#define C_CONST0	(C_CT_BASE+14)	// load constant 0
#define C_ADDLOOP	(C_CT_BASE+15)	// add serie member to accumulator and loop if meaningful
#define C_OVER		(C_CT_BASE+16)	// load overflow number
#define C_UNDER		(C_CT_BASE+17)	// load underflow number
#define C_BYTE		(C_CT_BASE+18)	// load unsigned byte, will follow
#define C_EXECPAR	(C_CT_BASE+19)	// execute command from R_PARAM register
#define C_GETSEED	(C_CT_BASE+20)	// load random seed into stack
#define C_SETSEED	(C_CT_BASE+21)	// save random seed from stack

; ... arithmetics and bitwise operations (2 operands) (7)
#define C_AR_BASE	(C_CT_BASE+22)
#define C_MUL		(C_AR_BASE+0)	// multiply
#define C_DIV		(C_AR_BASE+1)	// division
#define C_MOD		(C_AR_BASE+2)	// modulus with trunc rounding
#define C_MOD2		(C_AR_BASE+3)	// modulus with floor rounding
#define C_SUB		(C_AR_BASE+4)	// - subtract
#define C_ADD		(C_AR_BASE+5)	// +
#define C_POW		(C_AR_BASE+6)	// ^ power (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)

; ... comparisons: do not change order of comparison codes - hardcoded in function CalcCmp (10)
#define C_CP_BASE	(C_AR_BASE+7)
#define C_LTEQ		(C_CP_BASE+0)	// <=
#define C_GREQ		(C_CP_BASE+1)	// >=
#define C_NEQU		(C_CP_BASE+2)	// <>
#define C_LT0		(C_CP_BASE+3)	// < 0 (less 0, but not equ)
#define C_GR		(C_CP_BASE+4)	// >
#define C_LT		(C_CP_BASE+5)	// <
#define C_EQU		(C_CP_BASE+6)	// =
#define C_GR0		(C_CP_BASE+7)	// > 0 (greater 0, but not equ)
#define C_LTEQ0		(C_CP_BASE+8)	// <= 0 (less or equ 0)
#define C_GREQ0		(C_CP_BASE+9)	// >= 0 (greater or equ 0)

; ... functions 1 (misc) (14)
#define C_F1_BASE	(C_CP_BASE+10)
#define C_REC		(C_F1_BASE+0)	// reciprocal value
#define C_INC		(C_F1_BASE+1)	// increment +1
#define C_DEC		(C_F1_BASE+2)	// decrement -1
#define C_NEG		(C_F1_BASE+3)	// unary- (NEG)
#define C_SGN		(C_F1_BASE+4)	// SGN
#define C_ABS		(C_F1_BASE+5)	// ABS
#define C_TRUNC		(C_F1_BASE+6)	// truncate (round towards zero)
#define C_FRAC		(C_F1_BASE+7)	// fraction
#define C_FLOOR		(C_F1_BASE+8)	// round down
#define C_CEIL		(C_F1_BASE+9)	// round up
#define C_ROUND		(C_F1_BASE+10)	// round nearest
#define C_NOT		(C_F1_BASE+11)	// boolean NOT
#define C_FACT		(C_F1_BASE+12)	// x!
#define C_RAND		(C_F1_BASE+13)	// random

; ... funcions 2 (angle, convert angle to/from radians) (12)
#define C_F2_BASE	(C_F1_BASE+14)
#define C_ARG		(C_F2_BASE+0)	// normalize angle argument
#define C_SIN		(C_F2_BASE+1)	// SIN (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
#define C_COS		(C_F2_BASE+2)	// COS (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
#define C_TAN		(C_F2_BASE+3)	// TAN (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
#define C_ASN		(C_F2_BASE+4)	// ASN (uses TEMP_1, TEMP_2, TEMP_3)
#define C_ASNRAD	(C_F2_BASE+5)	// ASN in radians (uses TEMP_1, TEMP_2, TEMP_3)
#define C_ACS		(C_F2_BASE+6)	// ACS (uses TEMP_1, TEMP_2, TEMP_3)
#define C_ATN		(C_F2_BASE+7)	// ATN (uses TEMP_1, TEMP_2, TEMP_3)
#define C_TORAD		(C_F2_BASE+8)	// TORAD - angle to radians
#define C_FROMRAD	(C_F2_BASE+9)	// FROMRAD - angle from radians
#define C_PR		(C_F2_BASE+10)	// Convert polar to cartesian (r,a in radians) -> (x,y)
#define C_RP		(C_F2_BASE+11)	// Convert cartesian to polar (x,y) -> (r,a in radians)

; ... functions 3 (logarithm) (6)
#define C_F3_BASE	(C_F2_BASE+12)
#define C_LN		(C_F3_BASE+0)	// LN (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
#define C_EXP		(C_F3_BASE+1)	// EXP (uses TEMP_1, TEMP_2, TEMP_3)
#define C_LOG10		(C_F3_BASE+2)	// LOG10 (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
#define C_EXP10		(C_F3_BASE+3)	// EXP10 (uses TEMP_1, TEMP_2, TEMP_3)
#define C_SQRT		(C_F3_BASE+4)	// SQRT (uses TEMP_1, TEMP_2, TEMP_3, TEMP_4)
#define C_SQR		(C_F3_BASE+5)	// square

; ... groups (compound literals) (4)
;	bit 7: flag of compound literal
;	bit 5..6: group 0..3
;	bit 0..4: parameter 0..31
#define C_GROUP_BASE	(C_F3_BASE+6)
#define C_CONST_GRP	(C_GROUP_BASE+0)	// stack tabled constant (parameter is index of the constant)
#define C_SETMEM_GRP	(C_GROUP_BASE+1)	// set user memory from stack (parameter is index of the number)
#define C_GETMEM_GRP	(C_GROUP_BASE+2)	// get number from user memory into stack (parameter is index of the number)
#define C_SETMEMDEL_GRP	(C_GROUP_BASE+3)	// set user memory from stack and delete (parameter is index of the number)

#define C_CHECK		(C_GROUP_BASE+4)	// check - number of entries (must be < 128)

#define C_CONST(par) (B7+((C_CONST_GRP-C_GROUP_BASE)<<5)+par)  // stack tabled constant (par=index of constant 0..31)
#define C_SETMEM(par) (B7+((C_SETMEM_GRP-C_GROUP_BASE)<<5)+par)  // set user memory from stack (par=index of number 0..31)
#define C_GETMEM(par) (B7+((C_GETMEM_GRP-C_GROUP_BASE)<<5)+par)  // get user number from memory into stack (par=index of number 0..31)
#define C_SETMEMDEL(par) (B7+((C_SETMEMDEL_GRP-C_GROUP_BASE)<<5)+par)  // set user memory from stack and delete (par=index of number 0..31)

; Indices of constants (max. 32 constants)
#define CONST_05	0	// 0.5
#define CONST_075	1	// 0.75
#define CONST_100	2	// 100
#define CONST_001	3	// 0.01
#define CONST_00001	4	// 0.0001
#define CONST_LN2	5	// ln(2)
#define CONST_RLN2	6	// 1/ln(2)
#define CONST_LN10	7	// ln(10)
#define CONST_RLN10	8	// 1/ln(10)
#define CONST_EXPMAX	9	// exp(x) max
#define CONST_EXPMIN	10	// exp(x) min
#define CONST_PI05	11	// PI/2
#define CONST_PI	12	// PI
#define CONST_PI2	13	// PI*2
#define CONST_180PI	14	// 180/PI
#define CONST_PI180	15	// PI/180
#define CONST_200PI	16	// 200/PI
#define CONST_PI200	17	// PI/200
#define CONST_RANDA	18	// random number multiplier 214013
#define CONST_RANDC	19	// random number addition 2531011
#define CONST_RANDM	20	// random number modulus 2^32=4294967296
