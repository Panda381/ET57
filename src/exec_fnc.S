; ****************************************************************************
;
;                                Execute functions
;
; ****************************************************************************

#include "include.inc"

	.text

; ----------------------------------------------------------------------------
;                           ln x
; ----------------------------------------------------------------------------

.global ExecLnx
ExecLnx:
	ldi	R_PARAM,C_LN	; function - ln x
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           INV ln x
; ----------------------------------------------------------------------------

.global ExecInvLnx
ExecInvLnx:
	ldi	R_PARAM,C_EXP	; function - exp x
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           log
; ----------------------------------------------------------------------------

.global ExecLog
ExecLog:
	ldi	R_PARAM,C_LOG10	; function - log10 x
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           INV log
; ----------------------------------------------------------------------------

.global ExecInvLog
ExecInvLog:
	ldi	R_PARAM,C_EXP10	; function - exp10 x
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           tan
; ----------------------------------------------------------------------------

.global ExecTan
ExecTan:
	ldi	R_PARAM,C_TAN	; function - tangent
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           INV tan
; ----------------------------------------------------------------------------

.global ExecInvTan
ExecInvTan:
	ldi	R_PARAM,C_ATN	; function - arcus tangent
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           x^2
; ----------------------------------------------------------------------------

.global ExecX2
ExecX2:
	ldi	R_PARAM,C_SQR	; function - x^2
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           Vx
; ----------------------------------------------------------------------------

.global ExecVx
ExecVx:
	ldi	R_PARAM,C_SQRT	; function - Vx
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           1/x
; ----------------------------------------------------------------------------

.global Exec1x
Exec1x:
	ldi	R_PARAM,C_REC	; function - 1/x
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           sin
; ----------------------------------------------------------------------------

.global ExecSin
ExecSin:
	ldi	R_PARAM,C_SIN	; function - sine
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           INV sin
; ----------------------------------------------------------------------------

.global ExecInvSin
ExecInvSin:
	ldi	R_PARAM,C_ASN	; function - arcus sine
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           cos
; ----------------------------------------------------------------------------

.global ExecCos
ExecCos:
	ldi	R_PARAM,C_COS	; function - cosine
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           INV cos
; ----------------------------------------------------------------------------

.global ExecInvCos
ExecInvCos:
	ldi	R_PARAM,C_ACS	; function - arcus cosine
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           |x|
; ----------------------------------------------------------------------------

.global ExecAbs
ExecAbs:
	ldi	R_PARAM,C_ABS	; function - abs x
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           INV |x|
; ----------------------------------------------------------------------------

.global ExecInvAbs
ExecInvAbs:
	ldi	R_PARAM,C_SGN	; function - sign x
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           Int
; ----------------------------------------------------------------------------

.global ExecInt
ExecInt:
	ldi	R_PARAM,C_TRUNC	; function - trunc x
	rjmp	ExecParFnc	; execute parameter function

; ----------------------------------------------------------------------------
;                           INV Int
; ----------------------------------------------------------------------------

.global ExecInvInt
ExecInvInt:
	ldi	R_PARAM,C_FRAC	; function - frac x
	rjmp	ExecParFnc	; execute parameter function
