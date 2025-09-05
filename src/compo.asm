; GB Compo 2025 logo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "sgb.inc"
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
	call SetBank
	call CompoInit
	rst ScreenOff
	call CopyCompo
	call CompoPostInit

	ld a, BANK(song_ending)
	ld [rROMB0], a

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
	ld de, CompoTiles
	COPY_2BPP Compo

	ld h, HIGH(TILEMAP0)
	call CopyRow
	CLEAR_LONG 1
	ld h, HIGH(TILEMAP1)
	ld d, HIGH(CompoTextMap)
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

SetBank:
	ldh a, [hFlags]
	or a
	jr nz, .cont
	ld a, FLAGS_DMG0
.cont
	ld [rROMB0], a
	ret


SECTION "InitDMG", ROM0
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
	call InitDMG
	call SGB_InitVRAM
	call SetBankSGB
	ld hl, FreezeSGB
	call SGB_SendPacket
	ld de, BorderTilesSGB
	ld hl, ChrTrn1SGB
	call SGB_CopyVRAM
	ld de, BorderSGB
	ld hl, PctTrnSGB
	call SGB_CopyVRAM
	ld de, BorderPalettesSGB
	ld hl, PalTrnSGB
	call SGB_CopyVRAM
	ld hl, CompoPaletteSGB
	call SGB_SendPacket
	ld a, FLAGS_SGB
	ld [rROMB0], a
	ret


SECTION "PostInitSGB", ROM0
PostInitSGB:
	call SetBankSGB
	ld hl, UnfreezeSGB
	jp SGB_SendPacket


SECTION "DoSoundSGB", ROM0
DoSoundSGB2::
	call DoSoundSGB
	; Fall through

DoSoundSGB::
	ld a, BANK(song_ending)
	ld [rROMB0], a
	call hUGE_dosound
	; Fall through

SetBankSGB:
	ld a, BANK_SGB
	ld [rROMB0], a
	ret


SECTION "InitGBC", ROM0
InitGBC:
	ld a, OPRI_COORD
	ldh [rOPRI], a
	
	rst WaitVBlank
	ld hl, rBGPI
	ld de, CompoPaletteGBC
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


SECTION "Common Compo Maps", ROM0, ALIGN[8]
CompoTextMap:
	INCBIN "compo_text.tilemap"
CompoObjMap:
	INCBIN "compo_obj.tilemap"


SECTION "Tiles", ROMX[$4000], BANK[FLAGS_DMG0]
CompoTiles:
	INCBIN "compo_logo.2bpp"
	INCBIN "compo_text.2bpp"
	INCBIN "compo_obj.2bpp"
.end
	INCBIN "compo_logo.tilemap"
CompoInit:
	jp InitDMG
CompoPostInit:
	ret


SECTION "TilesGBC", ROMX[$4000], BANK[FLAGS_GBC]
CompoTilesGBC:
	INCBIN "compo_logo_gbc.2bpp"
	INCBIN "compo_button.2bpp"
	INCBIN "compo_text.2bpp"
	INCBIN "compo_obj.2bpp"
.end
	INCBIN "compo_logo_gbc.tilemap"
CompoInitGBC:
	jp InitGBC
CompoPostInitGBC:
	ret
CompoPaletteGBC:
	dw cOffWhite
	INCBIN "compo_logo_gbc.pal", 2, 6
	INCBIN "compo_button_gbc.pal"
	INCBIN "compo_obj_gbc.pal"
	INCBIN "compo_button_gbc.pal"


SECTION "TilesGBA", ROMX[$4000], BANK[FLAGS_GBA]
CompoTilesGBA:
	INCBIN "compo_logo_gbc.2bpp"
	INCBIN "compo_button.2bpp"
	INCBIN "compo_text.2bpp"
	INCBIN "compo_obj.2bpp"
.end
	INCBIN "compo_logo_gbc.tilemap"
CompoInitGBA:
	jp InitGBC
CompoPostInitGBA:
	ret
CompoPaletteGBA:
	dw cOffWhiteSGB
	INCBIN "compo_logo.pal", 2, 6
	INCBIN "compo_button.pal"
	INCBIN "compo_obj.pal"
	INCBIN "compo_button.pal"


SECTION "TilesSGB", ROMX[$4000], BANK[FLAGS_SGB]
CompoTilesSGB:
	INCBIN "compo_logo_sgb.2bpp"
	ds 16
	INCBIN "compo_text.2bpp"
	INCBIN "compo_obj_sgb.2bpp"
.end
	INCBIN "compo_logo_gbc.tilemap"
CompoInitSGB:
	jp InitSGB
CompoPostInitSGB:
	jp PostInitSGB


SECTION "BorderTilesSGB", ROMX, BANK[BANK_SGB], ALIGN[8]
BorderTilesSGB:
	INCBIN "sgb_border_tiles.bin"


SECTION "BorderSGB", ROMX, BANK[BANK_SGB], ALIGN[8]
BorderSGB:
	INCBIN "sgb_border_map.bin"


SECTION "BorderPalettesSGB", ROMX, BANK[BANK_SGB], ALIGN[8]
BorderPalettesSGB:
	INCBIN "sgb_border_palettes.bin"


SECTION "SGB Packets", ROMX, BANK[BANK_SGB], ALIGN[8]
ChrTrn1SGB:
	db SGB_CHR_TRN | $01
	ds 15, 0
PctTrnSGB:
	db SGB_PCT_TRN | $01
	ds 15, 0
PalTrnSGB:
	db SGB_PAL_TRN | $01
	ds 15, 0
CompoPaletteSGB:
	db SGB_PAL01 | $01
	dw cOffWhiteSGB
	INCBIN "compo_logo.pal", 2, 6
	INCBIN "compo_obj.pal",  2, 6
	db 0
FreezeSGB:
	db SGB_MASK_EN | $01
	db SGB_MASK_EN_MASK_FREEZE
	ds 14
UnfreezeSGB:
	db SGB_MASK_EN | $01
	db SGB_MASK_EN_MASK_CANCEL
	ds 14


SECTION "HRAM", HRAM
hFrameCount:
	ds 1
