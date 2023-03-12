; ****************************************************************************
;
;                          Includes - keyboard codes
;
; ****************************************************************************

; ===== User keyboard codes

; without INV
#define KEY_0		0 // digit 0
#define KEY_1		1 // digit 1
#define KEY_2		2 // digit 2
#define KEY_3		3 // digit 3
#define KEY_4		4 // digit 4
#define KEY_5		5 // digit 5
#define KEY_6		6 // digit 6
#define KEY_7		7 // digit 7
#define KEY_8		8 // digit 8
#define KEY_9		9 // digit 9

#define KEY_OFF		10 // OFF
#define KEY_2ND		11 // 2nd
#define KEY_INV		12 // INV
#define KEY_LNX		13 // lnx
#define KEY_CE		14 // CE
#define KEY_CLR		15 // CLR
#define KEY_2ND2	16 // 2nd 2nd
#define KEY_INV2	17 // 2nd INV
#define KEY_LOG		18 // log
#define KEY_CT		19 // C.t

#define KEY_TAN		20 // tan
#define KEY_LRN		21 // LRN
#define KEY_XT		22 // x<>t
#define KEY_X2		23 // x^2
#define KEY_VX		24 // Vx
#define KEY_1X		25 // 1/x
#define KEY_DMS		26 // D.MS
#define KEY_PR		27 // P->R
#define KEY_SIN		28 // sin
#define KEY_COS		29 // cos

#define KEY_PI		30 // pi
#define KEY_SST		31 // SST
#define KEY_STO		32 // STO
#define KEY_RCL		33 // RCL
#define KEY_SUM		34 // SUM
#define KEY_YX		35 // y^x
#define KEY_PAUSE	36 // Pause
#define KEY_INS		37 // Ins
#define KEY_EXC		38 // Exc
#define KEY_PRD		39 // Prd

#define KEY_ABS		40 // IxI
#define KEY_BST		41 // BST
#define KEY_EE		42 // EE
#define KEY_LPAR	43 // (
#define KEY_RPAR	44 // )
#define KEY_DIV		45 // :
#define KEY_NOP		46 // Nop
#define KEY_DEL		47 // Del
#define KEY_FIX		48 // Fix
#define KEY_INT		49 // Int

#define KEY_DEG		50 // Deg
#define KEY_GTO		51 // GTO
#define KEY_TMP_7	52 // (7)
#define KEY_TMP_8	53 // (8)
#define KEY_TMP_9	54 // (9)
#define KEY_MUL		55 // x
#define KEY_DSZ		56 // Dsz
#define KEY_STO_IND	57 // STO*
#define KEY_RCL_IND	58 // RCL*
#define KEY_SUM_IND	59 // SUM*

#define KEY_RAD		60 // Rad
#define KEY_SBR		61 // SBR
#define KEY_TMP_4	62 // (4)
#define KEY_TMP_5	63 // (5)
#define KEY_TMP_6	64 // (6)
#define KEY_SUB		65 // -
#define KEY_EQ		66 // x=t
#define KEY_INC_IND	67 // Inc*
#define KEY_EXC_IND	68 // Exc*
#define KEY_PRD_IND	69 // Prd*

#define KEY_GRAD	70 // Grad
#define KEY_RST		71 // RST
#define KEY_TMP_1	72 // (1)
#define KEY_TMP_2	73 // (2)
#define KEY_TMP_3	74 // (3)
#define KEY_ADD		75 // +
#define KEY_GE		76 // x>=t
#define KEY_INC		77 // Inc
#define KEY_PGM		78 // Pgm
#define KEY_RAND	79 // Rand

#define KEY_VAR		80 // Var
#define KEY_RS		81 // R/S
#define KEY_TMP_0	82 // (0)
#define KEY_DOT		83 // .
#define KEY_NEG		84 // +/-
#define KEY_RES		85 // =
#define KEY_LBL		86 // Lbl
#define KEY_FACT	87 // x!
#define KEY_STAT	88 // Stat
#define KEY_MEAN	89 // Mean

; with INV
#define KEY_INV_0	90 // INV digit 0
#define KEY_INV_1	91 // INV digit 1
#define KEY_INV_2	92 // INV digit 2
#define KEY_INV_3	93 // INV digit 3
#define KEY_INV_4	94 // INV digit 4
#define KEY_INV_5	95 // INV digit 5
#define KEY_INV_6	96 // INV digit 6
#define KEY_INV_7	97 // INV digit 7
#define KEY_INV_8	98 // INV digit 8
#define KEY_INV_9	99 // INV digit 9

#define KEY_INV_OFF	100 // INV OFF
#define KEY_INV_2ND	101 // INV 2nd
#define KEY_INV_INV	102 // INV INV
#define KEY_INV_LNX	103 // INV lnx
#define KEY_INV_CE	104 // INV CE
#define KEY_INV_CLR	105 // INV CLR
#define KEY_INV_2ND2	106 // INV 2nd 2nd
#define KEY_INV_INV2	107 // INV 2nd INV
#define KEY_INV_LOG	108 // INV log
#define KEY_INV_CT	109 // INV C.t

#define KEY_INV_TAN	110 // INV tan
#define KEY_INV_LRN	111 // INV LRN
#define KEY_INV_XT	112 // INV x<>t
#define KEY_INV_X2	113 // INV x^2
#define KEY_INV_VX	114 // INV Vx
#define KEY_INV_1X	115 // INV 1/x
#define KEY_INV_DMS	116 // INV D.MS
#define KEY_INV_PR	117 // INV P->R
#define KEY_INV_SIN	118 // INV sin
#define KEY_INV_COS	119 // INV cos

#define KEY_INV_PI	120 // INV pi
#define KEY_INV_SST	121 // INV SST
#define KEY_INV_STO	122 // INV STO
#define KEY_INV_RCL	123 // INV RCL
#define KEY_INV_SUM	124 // INV SUM
#define KEY_INV_YX	125 // INV y^x
#define KEY_INV_PAUSE	126 // INV Pause
#define KEY_INV_INS	127 // INV Ins
#define KEY_INV_EXC	128 // INV Exc
#define KEY_INV_PRD	129 // INV Prd

#define KEY_INV_ABS	130 // INV IxI
#define KEY_INV_BST	131 // INV BST
#define KEY_INV_EE	132 // INV EE
#define KEY_INV_LPAR	133 // INV (
#define KEY_INV_RPAR	134 // INV )
#define KEY_INV_DIV	135 // INV :
#define KEY_INV_NOP	136 // INV Nop
#define KEY_INV_DEL	137 // INV Del
#define KEY_INV_FIX	138 // INV Fix
#define KEY_INV_INT	139 // INV Int

#define KEY_INV_DEG	140 // INV Deg
#define KEY_INV_GTO	141 // INV GTO
#define KEY_INV_TMP_7	142 // INV (7)
#define KEY_INV_TMP_8	143 // INV (8)
#define KEY_INV_TMP_9	144 // INV (9)
#define KEY_INV_MUL	145 // INV x
#define KEY_INV_DSZ	146 // INV Dsz
#define KEY_INV_STO_IND	147 // INV STO*
#define KEY_INV_RCL_IND	148 // INV RCL*
#define KEY_INV_SUM_IND	149 // INV SUM*

#define KEY_INV_RAD	150 // INV Rad
#define KEY_INV_SBR	151 // INV SBR
#define KEY_INV_TMP_4	152 // INV (4)
#define KEY_INV_TMP_5	153 // INV (5)
#define KEY_INV_TMP_6	154 // INV (6)
#define KEY_INV_SUB	155 // INV -
#define KEY_INV_EQ	156 // INV x=t
#define KEY_INV_INC_IND	157 // INV Inc*
#define KEY_INV_EXC_IND	158 // INV Exc*
#define KEY_INV_PRD_IND	159 // INV Prd*

#define KEY_INV_GRAD	160 // INV Grad
#define KEY_INV_RST	161 // INV RST
#define KEY_INV_TMP_1	162 // INV (1)
#define KEY_INV_TMP_2	163 // INV (2)
#define KEY_INV_TMP_3	164 // INV (3)
#define KEY_INV_ADD	165 // INV +
#define KEY_INV_GE	166 // INV x>=t
#define KEY_INV_INC	167 // INV Inc
#define KEY_INV_PGM	168 // INV Pgm
#define KEY_INV_RAND	169 // INV Rand

#define KEY_INV_VAR	170 // INV Var
#define KEY_INV_RS	171 // INV R/S
#define KEY_INV_TMP_0	172 // INV (0)
#define KEY_INV_DOT	173 // INV .
#define KEY_INV_NEG	174 // INV +/-
#define KEY_INV_RES	175 // INV =
#define KEY_INV_LBL	176 // INV Lbl
#define KEY_INV_FACT	177 // INV x!
#define KEY_INV_STAT	178 // INV Stat
#define KEY_INV_MEAN	179 // INV Mean

#define NOKEY		255 // empty

#define INV_SHIFT 90	// INV shift flag
