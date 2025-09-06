; GB Compo 2025 logo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "sgb.inc"
include "common.inc"


DEF tCompoBtn    EQUS "${T_COMPO_BTN}"
DEF pCompoBtn    EQU    1
DEF yCompoBtn    EQU  107
DEF xCompoBtn1   EQU  187
DEF xCompoBtn2   EQU  196

DEF tCompoObj    EQUS "${T_COMPO_OBJ}"
DEF vCompoObj    EQU   35

DEF tCompoEmpty  EQU  $70

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


SECTION "Compo", ROM0

Compo::
	call SetBank

	ldh a, [hFlags]
	bit B_FLAGS_GBC, a
	jr z, .nonGBC

.GBC
	call InitGBC
	jr .cont0

.nonGBC
	call InitDMG
	ldh a, [hFlags]
	bit B_FLAGS_SGB, a
	jr z, .cont0

.SGB
	call InitSGB

.cont0
	rst ScreenOff
	call CopyCompo

	ldh a, [hFlags]
	cp FLAGS_SGB
	ld hl, UnfreezeSGB
	call z, SGB_SendPacket

	ld a, BANK(song_ending)
	ld [rROMB0], a
	call hUGE_dosound

.compo0
	xor a
	ldh [hFrameCount], a

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
	jr z, .cont
	ld [hl], d
	inc l
	ld [hl], e
	inc l
	ld [hli], a
	xor a
	ld [hli], a

.cont
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
	call hFixedOAMDMA
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

	jr .compo0


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
	push de
	call hUGE_dosound
	pop de
	jr .loop3

CopyCompo:
	ld hl, STARTOF(VRAM)
	ld bc, CompoTiles.end - CompoTiles
	ldh a, [hFlags]
	and FLAGS_MASK
	add a
	add a
	add HIGH(CompoTiles)
	ld d, a
	ld e, 0
	call MemCopy

.text
	ld de, CompoTextTiles
	ld bc, CompoTextTiles.end - CompoTextTiles
	call MemCopy

.obj
	ld de, CompoObjTiles
	ldh a, [hFlags]
	bit B_FLAGS_SGB, a
	jr z, .objCont
	ld de, CompoObjTilesSGB
.objCont
	ld bc, CompoObjTiles.end - CompoObjTiles
	call MemCopy

.map
	ld de, CompoLogoMap
	ldh a, [hFlags]
	and FLAGS_GBC | FLAGS_SGB
	jr z, .mapCont
	ld de, CompoLogoMapGBC
.mapCont
	ld b, HIGH(CompoLogoMap.end - CompoLogoMap)
	ld hl, TILEMAP0
	call MemCopyAndClear

.textMap
	ld h, HIGH(TILEMAP1)
	ld d, HIGH(CompoTextMap)
	ld b, HIGH(CompoTextMap.end - CompoTextMap)
	; Fall through

; Adapted from Simple GB ASM Examples by Dave VanEe
; License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)

MemCopy::
	ld a, [de]          ; Load a byte from the address DE points to into the register A
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	inc de              ; Increment the destination pointer in DE
	dec bc              ; Decrement the loop counter in BC
	ld a, b             ; Load the value in B into A
	or c                ; Logical OR the value in A (from B) with C
	jr nz, MemCopy      ; If B and C are both zero, OR B will be zero, otherwise keep looping
	ret

MemCopyAndClear::
	call MemCopy        ; Copy memory
	xor a               ; Clear the A register
.loop
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	dec c               ; Decrement the loop counter
	jr nz, .loop        ; Stop if C is zero, otherwise keep looping
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


SECTION "InitDMG", ROMX, BANK[BANK_COMPO]
InitDMG:
	ld a, %11100100     ; Default
	ld hl, rBGP
	ld [hli], a         ; Set background palette
	ld [hli], a         ; Set object palette 0

	ld a, %11000100     ; White
	ld [hli], a         ; Set object palette 1
	ret


SECTION "InitSGB", ROM0
InitSGB:
	call SGB_InitVRAM
	call SetBankSGB
	ld hl, FreezeSGB
	call SGB_SendPacket
	ld bc, BorderTilesSGB.end - BorderTilesSGB
	ld de, BorderTilesSGB
	call SGB_SendBorderTiles
	ld bc, BorderSGB.end - BorderSGB
	ld de, BorderSGB
	call SGB_SendBorder
	call ClearVRAM
	ld hl, CompoPaletteSGB
	call SGB_SendPacket
	; Fall through

SetBank:
	ld a, BANK_COMPO
	ld [rROMB0], a
	ret


SECTION "ClearVRAM", ROM0
ClearVRAM:
	ld hl, TILEMAP0
.loop
	rst WaitVRAM
	ld a, tCompoEmpty
	ld [hli], a
	bit 2, h
	jr z, .loop
	call DoSoundSGB2
	; Fall through

DoSoundSGB2::
	call DoSoundSGB
	; Fall through

DoSoundSGB::
	ld a, BANK(song_ending)
	ld [rROMB0], a
	call hUGE_dosound
	; Fall through

SetBankSGB:
	ld a, BANK_COMPO
	ld [rROMB0], a
	ret


SECTION "InitGBC", ROMX, BANK[BANK_COMPO]
InitGBC:
	ld a, OPRI_COORD
	ldh [rOPRI], a
	
	rst WaitVBlank
	ld hl, rBGPI
	ld de, CompoPaletteGBC
	ldh a, [hFlags]
	bit B_FLAGS_GBA, a
	jr z, .cont
	ld de, CompoPaletteGBA

.cont
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


SECTION "CompoObjMap", ROMX, BANK[BANK_INIT], ALIGN[8]
CompoObjMap:
	INCBIN "compo_obj.tilemap"
.end


SECTION "CompoTiles", ROMX[$4000], BANK[BANK_COMPO]
CompoTiles:
	INCBIN "compo_logo.2bpp"
.end


SECTION "CompoTilesSGB", ROMX[$4400], BANK[BANK_COMPO]
CompoTilesSGB:
	INCBIN "compo_logo_sgb.2bpp"
.end


SECTION "CompoTilesGBC", ROMX[$4800], BANK[BANK_COMPO]
CompoTilesGBC:
	INCBIN "compo_logo_gbc.2bpp"
	INCBIN "compo_button.2bpp"
.end


SECTION "CompoTextTiles", ROMX, BANK[BANK_COMPO]
CompoTextTiles:
	INCBIN "compo_text.2bpp"
.end


SECTION "CompoObjTiles", ROMX, BANK[BANK_COMPO]
CompoObjTiles:
	INCBIN "compo_obj.2bpp"
.end


SECTION "CompoObjTilesSGB", ROMX, BANK[BANK_COMPO]
CompoObjTilesSGB:
	INCBIN "compo_obj_sgb.2bpp"
.end


SECTION "CompoLogoMap", ROMX, BANK[BANK_COMPO]
CompoLogoMap:
	INCBIN "compo_logo.tilemap"
.end


SECTION "CompoLogoMapGBC", ROMX, BANK[BANK_COMPO]
CompoLogoMapGBC:
	INCBIN "compo_logo_gbc.tilemap"
.end


SECTION "CompoTextMap", ROMX, BANK[BANK_COMPO]
CompoTextMap:
	INCBIN "compo_text.tilemap"
.end


SECTION "CompoPaletteGBC", ROMX, BANK[BANK_COMPO]
CompoPaletteGBC:
	dw cOffWhite
	INCBIN "compo_logo_gbc.pal", 2, 6
	INCBIN "compo_button_gbc.pal"
	INCBIN "compo_obj_gbc.pal"
	INCBIN "compo_button_gbc.pal"


SECTION "CompoPaletteGBA", ROMX, BANK[BANK_COMPO]
CompoPaletteGBA:
	dw cOffWhiteSGB
	INCBIN "compo_logo.pal", 2, 6
	INCBIN "compo_button.pal"
	INCBIN "compo_obj.pal"
	INCBIN "compo_button.pal"


SECTION "BorderTilesSGB", ROMX, BANK[BANK_COMPO]
BorderTilesSGB:
	INCBIN "compo_border.4bpp"
.end
ChrTrn1SGB:
	db SGB_CHR_TRN | $01
	ds 15, 0


SECTION "BorderSGB", ROMX, BANK[BANK_COMPO]
BorderSGB:
	INCBIN "compo_border.tilemap"
.end
	dw cOffWhiteSGB
	INCBIN "compo_border.pal", 2
PctTrnSGB:
	db SGB_PCT_TRN | $01
	ds 15, 0


SECTION "CompoPaletteSGB", ROMX, BANK[BANK_COMPO]
CompoPaletteSGB:
	db SGB_PAL01 | $01
	dw cOffWhiteSGB
	INCBIN "compo_logo.pal", 2, 6
	INCBIN "compo_obj.pal",  2, 6
	db 0


SECTION "FreezeSGB", ROMX, BANK[BANK_COMPO]
FreezeSGB:
	db SGB_MASK_EN | $01
	db SGB_MASK_EN_MASK_FREEZE
	ds 14


SECTION "UnfreezeSGB", ROMX, BANK[BANK_COMPO]
UnfreezeSGB:
	db SGB_MASK_EN | $01
	db SGB_MASK_EN_MASK_CANCEL
	ds 14


SECTION "HRAM", HRAM
hFrameCount:
	ds 1
