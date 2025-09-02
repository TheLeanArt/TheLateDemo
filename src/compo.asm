; GB Compo 2025 logo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"


DEF tCompoBtn    EQU  $3F
DEF pCompoBtn    EQU    1
DEF yCompoBtn    EQU  107
DEF xCompoBtn1   EQU  187
DEF xCompoBtn2   EQU  196

DEF tCompoObj    EQU  $A9
DEF vCompoObj    EQU   35

DEF yCompoObj    EQU   32
DEF xCompoObj    EQU  183
DEF yCompoDelta  EQU   64
DEF xCompoDelta  EQU   64

DEF yCompoBottom EQU yCompoObj + yCompoDelta
DEF xCompoRight  EQU xCompoObj + xCompoDelta

DEF xCompoInit1  EQU -160
DEF xCompoWin2   EQU  152 + WX_OFS

DEF xCompoStop1  EQU  -64
DEF xCompoStop2  EQU   88
DEF xCompoStop3  EQU   96

DEF cOffWhiteSGB EQU %0_11111_11011_11100
DEF cOffWhite    EQU %0_11111_10110_11011


SECTION "Compo", ROM0

Compo::	
	ld a, %11100100     ; Default
	ld hl, rBGP
	ld [hli], a         ; Set background palette
	ld [hli], a         ; Set object palette 0

	ld a, %11000100     ; White
	ld [hli], a         ; Set object palette 1

	call SetBank

	ldh a, [hFlags]
	bit B_FLAGS_SGB, a
	call nz, InitSGB

	ldh a, [hFlags]
	bit B_FLAGS_GBC, a
	call nz, InitGBC

	rst ScreenOff
	ldh [hFrameCount], a
	call CopyCompo

.copyObjs
	ld bc, CompoObjMap
	ld hl, wShadowOAM
	ld d, yCompoObj
.loop1
	ld e, xCompoObj
.loop2
	ld a, [bc]
	inc c
	cp tCompoObj
	jr z, .cont0
	ld [hl], d
	inc l
	ld [hl], e
	inc l
	ld [hli], a
	xor a
	ld [hli], a

.cont0
	ld a, e
	add TILE_WIDTH
	ld e, a
	cp xCompoRight
	jr nz, .loop2
	ld a, d
	add TILE_HEIGHT
	ld d, a
	cp yCompoBottom
	jr nz, .loop1
	call AddButtons
	inc l
	ld e, l

.compo1
	xor a
	ldh [rSCY], a
	ld a, xCompoInit1
	ldh [rSCX], a
	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_OBJ_ON
	ld d, xCompoStop1
	call LoopCompo

.compo2
	xor a
	ldh [rWY], a
	ld a, xCompoWin2
	ldh [rWX], a
	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_OBJ_ON | LCDC_WIN_ON | LCDC_WIN_9C00
	ld d, xCompoStop2
	call LoopCompo

.compo3
	xor a
	ldh [rSCX], a
	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_BG_9C00
	ld d, xCompoStop3
	call LoopCompo

	rst ScreenOff
	ldh [hFrameCount], a
	call DoSound
	jr .copyObjs


SECTION "Compo Subroutines", ROM0

LoopCompo:
	ldh [rLCDC], a
.loop3
	rst WaitVBlank
	ldh a, [hFrameCount]
	inc a
	ldh [hFrameCount], a
	ld b, a
	and $3F
	ld hl, wShadowOAM + OAMA_TILEID
	jr nz, .cont2

	ld a, b
	and $40
	add LOW(CompoObjMap)
	ld c, a
	ld b, HIGH(CompoObjMap)
.loop4
	ld a, [bc]
	inc c
	cp tCompoObj
	jr z, .loop4
	ld [hl], a
	ld a, l
	add OBJ_SIZE
	ld l, a
	cp vCompoObj * OBJ_SIZE + OAMA_TILEID
	jr nz, .loop4
	ld l, OAMA_X
	jr .loop5

.cont2
	bit 0, a
	jr nz, .cont4
	dec l

.loop5
	dec [hl]
	ld a, l
	add OBJ_SIZE
	ld l, a
	cp e
	jr nz, .loop5

.cont3
	ldh a, [rWX]
	dec a
	ldh [rWX], a
	ldh a, [rSCX]
	inc a
	ldh [rSCX], a
	cp d
	ret z
	call hFixedOAMDMA

.cont4
	call DoSound
	jr .loop3

CopyCompo:
	ld hl, STARTOF(VRAM)
	ld de, CompoTiles
	COPY_2BPP Compo

	ld h, HIGH(TILEMAP0)
	call CopyRow
	ld h, HIGH(TILEMAP1)
	; Fall through

CopyRow:
	call CopyHalfRow
	; Fall through

CopyHalfRow::
	ld a, [de]
	ld [hli], a
	inc e
	jr nz, CopyHalfRow
	inc d
	ret

AddButtons:
	ldh a, [hFlags]
	bit B_FLAGS_GBC, a
	ret z

	ld b, xCompoBtn1
	call .do
	ld b, xCompoBtn2
	; Fall through

.do
	ld a, yCompoBtn
	ld [hli], a
	ld a, b
	ld [hli], a
	ld a, tCompoBtn
	ld [hli], a
	ld a, pCompoBtn
	ld [hli], a
	ret

DoSound:
	ld a, BANK(song_ending)
	ld [rROMB0], a
	push de
	call hUGE_dosound
	pop de
	; Fall through

SetBank:
	ldh a, [hFlags]
	bit B_FLAGS_GBA, a
	jr nz, .GBA
	bit B_FLAGS_GBC, a
	jr nz, .GBC
	bit B_FLAGS_SGB, a
	jr nz, .SGB

.DMG
	ld a, BANK(CompoTiles)
	ld [rROMB0], a
	ret

.GBA
	ld a, BANK(TilesGBA)
	ld [rROMB0], a
	ret

.GBC
	ld a, BANK(TilesGBC)
	ld [rROMB0], a
	ret

.SGB
	ld a, BANK(TilesSGB)
	ld [rROMB0], a
	ret


SECTION "InitSGB", ROM0

MACRO SEND_BIT
	ldh [c], a          ; 5 cycles
	ld a, $FF           ; end pulse
	nop
	ldh [c], a          ; 15 cycles
ENDM

InitSGB:
	ld hl, CompoPalette
	; Fall through

; Adapted from https://github.com/gb-archive/snek-gbc/blob/main/code/sub.sm83
SGB_SendPacket:
	ld bc, 16 << 8 | LOW(rP1)
	xor a               ; start bit
	SEND_BIT

.byteLoop
	ld d, [hl]
	inc hl
	ld e, 8

.bitLoop
	xor a               ; load A with SGB bit
	rr d                ; fetch next bit
	ccf                 ; set accumulator in the dumbest way i could come up with
	adc a
	inc a
	swap a
	nop
	nop
	SEND_BIT

	dec e
	jr nz, .bitLoop
	dec b
	jr nz, .byteLoop

	REPT 6
		nop
	ENDR

	ld a, $20           ; stop bit
	SEND_BIT

	REPT 11
		nop
	ENDR

	ld a, JOYP_GET_CTRL_PAD
	ldh [c], a
	ret


SECTION "InitGBC", ROM0

InitGBC::
	ld a, OPRI_COORD
	ldh [rOPRI], a
	
	rst WaitVBlank
	ld hl, rBGPI
	ld de, CompoPalette
	call .do
	inc l
	; Fall through

.do
	ld a, BGPI_AUTOINC
	ld [hli], a
	ld b, 16
.loop
	ld a, [de]
	ld [hl], a
	inc e
	dec b
	jr nz, .loop
	ret


SECTION "Tiles", ROMX[$4000], BANK[1]
CompoTiles:
	INCBIN "compo_logo.2bpp"
	INCBIN "compo_text.2bpp"
	INCBIN "compo_obj.2bpp"
.end
	INCBIN "compo_logo.tilemap"
	INCBIN "compo_text.tilemap"
CompoObjMap:
	INCBIN "compo_obj.tilemap"
	ds 8, 0
CompoPalette:


SECTION "TilesGBC", ROMX[$4000], BANK[3]
TilesGBC:
.compo
	INCBIN "compo_logo_gbc.2bpp"
	INCBIN "compo_button.2bpp"
	INCBIN "compo_text.2bpp"
	INCBIN "compo_obj.2bpp"
.end
	INCBIN "compo_logo_gbc.tilemap"
	INCBIN "compo_text.tilemap"
CompoObjMapGBC:
	INCBIN "compo_obj.tilemap"
	ds 8, 0
CompoPaletteGBC:
	dw cOffWhite
	INCBIN "compo_logo_gbc.pal", 2, 6
	INCBIN "compo_button_gbc.pal"
	INCBIN "compo_obj_gbc.pal"
	INCBIN "compo_button_gbc.pal"


SECTION "TilesGBA", ROMX[$4000], BANK[4]
TilesGBA:
.compo
	INCBIN "compo_logo_gbc.2bpp"
	INCBIN "compo_button.2bpp"
	INCBIN "compo_text.2bpp"
	INCBIN "compo_obj.2bpp"
.end
	INCBIN "compo_logo_gbc.tilemap"
	INCBIN "compo_text.tilemap"
CompoObjMapGBA:
	INCBIN "compo_obj.tilemap"
	ds 8, 0
CompoPaletteGBA:
	dw cOffWhiteSGB
	INCBIN "compo_logo.pal", 2, 6
	INCBIN "compo_button.pal"
	INCBIN "compo_obj.pal"
	INCBIN "compo_button.pal"


SECTION "TilesSGB", ROMX[$4000], BANK[2]
TilesSGB:
.compo
	INCBIN "compo_logo_sgb.2bpp"
	ds 16
	INCBIN "compo_text.2bpp"
	INCBIN "compo_obj_sgb.2bpp"
.end
	INCBIN "compo_logo_gbc.tilemap"
	INCBIN "compo_text.tilemap"
CompoObjMapSGB:
	INCBIN "compo_obj.tilemap"
	ds 8, 0
CompoPaletteSGB:
	db SGB_PAL01 | $01
	dw cOffWhiteSGB
	INCBIN "compo_logo.pal", 2, 6
	INCBIN "compo_obj.pal",  2, 6
	db 0


SECTION "HRAM", HRAM
hFrameCount:
	ds 1
