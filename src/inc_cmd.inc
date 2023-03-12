; ****************************************************************************
;
;                             Includes - program code
;
; ****************************************************************************

; ===== Internal program code

#define CMD_DIG		0		// 0..9 digit base (10 codes)
#define CMD_0		(CMD_DIG+0)	// 0 digit 0
#define CMD_1		(CMD_DIG+1)	// 1 digit 1
#define CMD_2		(CMD_DIG+2)	// 2 digit 2
#define CMD_3		(CMD_DIG+3)	// 3 digit 3
#define CMD_4		(CMD_DIG+4)	// 4 digit 4
#define CMD_5		(CMD_DIG+5)	// 5 digit 5
#define CMD_6		(CMD_DIG+6)	// 6 digit 6
#define CMD_7		(CMD_DIG+7)	// 7 digit 7
#define CMD_8		(CMD_DIG+8)	// 8 digit 8
#define CMD_9		(CMD_DIG+9)	// 9 digit 9

#define CMD_PARBEG	(CMD_DIG+10)	// 10 first command with parameter 0..9
#define CMD_STO		(CMD_DIG+10)	// 10..19 STO base (10 codes)
#define CMD_RCL		(CMD_STO+10)	// 20..29 RCL base (10 codes)
#define CMD_SUM		(CMD_RCL+10)	// 30..39 SUM base (10 codes)
#define CMD_EXC		(CMD_SUM+10)	// 40..49 Exc base (10 codes)
#define CMD_PRD		(CMD_EXC+10)	// 50..59 Prd base (10 codes)
#define CMD_INC		(CMD_PRD+10)	// 60..69 Inc base (10 codes)
#define CMD_INV_STO	(CMD_INC+10)	// 70..79 INV STO base (10 codes)
#define CMD_INV_RCL	(CMD_INV_STO+10) // 80..89 INV RCL base (10 codes)
#define CMD_INV_SUM	(CMD_INV_RCL+10) // 90..99 INV SUM base (10 codes)
#define CMD_INV_EXC	(CMD_INV_SUM+10) // 100..109 INV Exc base (10 codes)
#define CMD_INV_PRD	(CMD_INV_EXC+10) // 110..119 INV Prd base (10 codes)
#define CMD_INV_INC	(CMD_INV_PRD+10) // 120..129 INV Inc base (10 codes)
#define CMD_LBL		(CMD_INV_INC+10) // 130..139 Lbl (10 codes)
#define CMD_GTO		(CMD_LBL+10)	// 140..149 GTO (10 codes)
#define CMD_SBR		(CMD_GTO+10)	// 150..159 SBR (10 codes)
#define CMD_FIX		(CMD_SBR+10)	// 160..169 Fix (10 codes)
#define CMD_PGM		(CMD_FIX+10)	// 170..179 Pgm (10 codes)
#define CMD_PAREND	(CMD_PGM+9)	// 179 last command with parameter 0..9

#define CMD_ROW1	(CMD_PGM+10)	// 180..184 row1
#define CMD_LNX		(CMD_ROW1+0)	// 180 lnx
#define CMD_CE		(CMD_ROW1+1)	// 181 CE
#define CMD_CLR		(CMD_ROW1+2)	// 182 CLR
#define CMD_LOG		(CMD_ROW1+3)	// 183 log
#define CMD_CT		(CMD_ROW1+4)	// 184 C.t

#define CMD_ROW2	(CMD_ROW1+5)	// 185..193 row2
#define CMD_XT		(CMD_ROW2+0)	// 185 x<>t
#define CMD_X2		(CMD_ROW2+1)	// 186 x^2
#define CMD_SQRT	(CMD_ROW2+2)	// 187 Vx
#define CMD_1X		(CMD_ROW2+3)	// 188 1/x
#define CMD_DMS		(CMD_ROW2+4)	// 189 D.MS
#define CMD_PR		(CMD_ROW2+5)	// 190 P->R
#define CMD_SIN		(CMD_ROW2+6)	// 191 sin
#define CMD_COS		(CMD_ROW2+7)	// 192 cos
#define CMD_TAN		(CMD_ROW2+8)	// 193 tan

#define CMD_ROW3	(CMD_ROW2+9)	// 194..196 row3
#define CMD_YX		(CMD_ROW3+0)	// 194 y^x
#define CMD_PAUSE	(CMD_ROW3+1)	// 195 Pause
#define CMD_PI		(CMD_ROW3+2)	// 196 pi

#define CMD_ROW4	(CMD_ROW3+3)	// 197..202 row4
#define CMD_EE		(CMD_ROW4+0)	// 197 EE
#define CMD_LPAR	(CMD_ROW4+1)	// 198 (
#define CMD_RPAR	(CMD_ROW4+2)	// 199 )
#define CMD_DIV		(CMD_ROW4+3)	// 200 :
#define CMD_INT		(CMD_ROW4+4)	// 201 Int
#define CMD_ABS		(CMD_ROW4+5)	// 202 IxI

#define CMD_ROW5	(CMD_ROW4+6)	// 203..208 row5
#define CMD_MUL		(CMD_ROW5+0)	// 203 x
#define CMD_DSZ		(CMD_ROW5+1)	// 204 Dsz
#define CMD_STO_IND	(CMD_ROW5+2)	// 205 STO*
#define CMD_RCL_IND	(CMD_ROW5+3)	// 206 RCL*
#define CMD_SUM_IND	(CMD_ROW5+4)	// 207 SUM*
#define CMD_DEG		(CMD_ROW5+5)	// 208 Deg

#define CMD_ROW6	(CMD_ROW5+6)	// 209..214 row6
#define CMD_SUB		(CMD_ROW6+0)	// 209 -
#define CMD_EQ		(CMD_ROW6+1)	// 210 x=t
#define CMD_INC_IND	(CMD_ROW6+2)	// 211 Inc*
#define CMD_EXC_IND	(CMD_ROW6+3)	// 212 Exc*
#define CMD_PRD_IND	(CMD_ROW6+4)	// 213 Prd*
#define CMD_RAD		(CMD_ROW6+5)	// 214 Rad

#define CMD_ROW7	(CMD_ROW6+6)	// 215..219 row7
#define CMD_RST		(CMD_ROW7+0)	// 215 RST
#define CMD_ADD		(CMD_ROW7+1)	// 216 +
#define CMD_GE		(CMD_ROW7+2)	// 217 x>=t
#define CMD_RAND	(CMD_ROW7+3)	// 218 Rand
#define CMD_GRAD	(CMD_ROW7+4)	// 219 Grad

#define CMD_ROW8	(CMD_ROW7+5)	// 220..226 row8
#define CMD_RS		(CMD_ROW8+0)	// 220 R/S
#define CMD_DOT		(CMD_ROW8+1)	// 221 .
#define CMD_NEG		(CMD_ROW8+2)	// 222 +/-
#define CMD_RES		(CMD_ROW8+3)	// 223 =
#define CMD_FACT	(CMD_ROW8+4)	// 224 x!
#define CMD_STAT	(CMD_ROW8+5)	// 225 Stat
#define CMD_MEAN	(CMD_ROW8+6)	// 226 Mean
#define CMD_VAR		(CMD_ROW8+7)	// 227 Var

#define CMD_INVBASE	(CMD_ROW8+8)	// 228..254 INV base
#define CMD_INV_LNX	(CMD_INVBASE+0)	// 228 INV lnx
#define CMD_INV_LOG	(CMD_INVBASE+1)	// 229 INV log
#define CMD_INV_CT	(CMD_INVBASE+2)	// 230 INV C.t
#define CMD_INV_DMS	(CMD_INVBASE+3)	// 231 INV D.MS
#define CMD_INV_PR	(CMD_INVBASE+4)	// 232 INV P->R
#define CMD_INV_SIN	(CMD_INVBASE+5)	// 233 INV sin
#define CMD_INV_COS	(CMD_INVBASE+6)	// 234 INV cos
#define CMD_INV_TAN	(CMD_INVBASE+7)	// 235 INV tan
#define CMD_INV_YX	(CMD_INVBASE+8)	// 236 INV y^x
#define CMD_INV_EE	(CMD_INVBASE+9)	// 237 INV EE
#define CMD_INV_INT	(CMD_INVBASE+10) // 238 INV Int
#define CMD_INV_ABS	(CMD_INVBASE+11) // 239 INV IxI ... SGN
#define CMD_INV_DSZ	(CMD_INVBASE+12) // 240 INV Dsz
#define CMD_INV_STO_IND	(CMD_INVBASE+13) // 241 INV STO*
#define CMD_INV_RCL_IND	(CMD_INVBASE+14) // 242 INV RCL*
#define CMD_INV_SUM_IND	(CMD_INVBASE+15) // 243 INV SUM*
#define CMD_INV_EQ	(CMD_INVBASE+16) // 244 INV x=t
#define CMD_INV_INC_IND	(CMD_INVBASE+17) // 245 INV Inc*
#define CMD_INV_EXC_IND	(CMD_INVBASE+18) // 246 INV Exc*
#define CMD_INV_PRD_IND	(CMD_INVBASE+19) // 247 INV Prd*
#define CMD_INV_GE	(CMD_INVBASE+20) // 248 INV x>=t
#define CMD_INV_STAT	(CMD_INVBASE+21) // 249 INV Stat
#define CMD_INV_MEAN	(CMD_INVBASE+22) // 250 INV Mean
#define CMD_INV_VAR	(CMD_INVBASE+23) // 251 INV Var
#define CMD_INV_SBR	(CMD_INVBASE+24) // 252 INV SBR (RTN)
#define CMD_INV_FIX	(CMD_INVBASE+25) // 253 INV Fix
#define CMD_INV_DIV	(CMD_INVBASE+26) // 254 INV :
#define CMD_NOP		(CMD_INVBASE+27) // 255 Nop
