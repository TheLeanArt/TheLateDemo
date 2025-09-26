; The Late Demo
;
; Copyright (c) 2025 Dmitry Shechtman

include "color.inc"


DEF BANK_INIT               EQU   1
DEF BANK_COMPO              EQU   2

DEF C_LILAC                 EQU %0_11111_10110_11011
DEF C_LILAC_SGB             EQU %0_11111_11011_11100

DEF COLOR8                  EQUS ""
DEF FADEOUT                 EQUS ""
DEF FADEOUT_START           EQU  48

DEF C_INTRO_BACK            EQU  C_LILAC
DEF C_INTRO_BACK_SGB        EQU  C_LILAC_SGB

DEF COMPO_GRADIENT          EQUS ""
DEF C_COMPO_GRADIENT_TOP    EQU  C_WHITE
DEF C_COMPO_GRADIENT_BOTTOM EQU  C_LILAC

DEF INTRO_SONG              EQUS "song_ending"
