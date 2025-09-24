; The Late Demo
;
; Copyright (c) 2025 Dmitry Shechtman


DEF tCompoBtn    EQUS "${T_COMPO_BTN}"
DEF pCompoBtn    EQU    1
DEF yCompoBtn    EQU  111
DEF xCompoBtn    EQU  187

DEF tCompoObj    EQUS "${T_COMPO_OBJ}"
DEF vCompoObj    EQU   35

DEF tCompoEmpty  EQU  $70

DEF yCompoObj    EQU   36
DEF xCompoObj    EQU  183
DEF yCompoDelta  EQU   64
DEF xCompoDelta  EQU   64

DEF yCompoBottom EQU yCompoObj + yCompoDelta
DEF xCompoRight  EQU xCompoObj + xCompoDelta

DEF yCompoInit1  EQU   -4
DEF xCompoInit1  EQU -160
DEF yCompoWin2   EQU    4
DEF xCompoWin2   EQU  152 + WX_OFS

DEF xCompoStop1  EQU  -64
DEF xCompoStop2  EQU   88
DEF xCompoStop3  EQU   96
