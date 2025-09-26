; GB Compo 2025 logo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "compo.inc"
include "gradient.inc"
include "sgb.inc"


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
	ld a, %11_10_01_00  ; Default
	ld [rBGP], a        ; Set the background palette
	ld [rOBP0], a       ; Set the default object palette
	ldh a, [hFlags]
	bit B_FLAGS_SGB, a
	jr z, .cont0

.SGB
	call InitSGB

.cont0
	rst ScreenOff
	call CopyCompo

	call SGB_TryUnfreeze

	ld a, BANK(song_ending)
	ld [rROMB0], a
	call hUGE_dosound

.compo0
	xor a
	ldh [hFrameCount], a

.copyObjs
	ld bc, CompoObjMap
	ld hl, wShadowOAM
	ld d, Y_COMPO_OBJ
.loop1
	ld e, X_COMPO_OBJ
.loop2
	ld a, [bc]
	inc c
	cp T_COMPO_OBJ
	jr z, .skipDisp

.addDisp
	push bc                    ; Save the current map address
	ld b, a                    ; Load tile ID
	ld c, 0                    ; Load attributes
	call SetObject             ; Add display object
	pop bc                     ; Restore the current map address
	jr .cont1                  ; Proceed to edge check

.skipDisp
	ld a, e                    ; Load the value in E into A
	add TILE_WIDTH             ; Add tile width
	ld e, a                    ; Load the value in A into E

.cont1
	cp X_COMPO_RIGHT           ; Right edge reached?
	jr nz, .loop2              ; If not, keep looping
	ld a, d                    ; Load the value in D into A
	add TILE_HEIGHT            ; Add tile height
	ld d, a                    ; Load the value in A into D
	cp Y_COMPO_BOTTOM          ; Bottom edge reached?
	jr nz, .loop1              ; If not, keep looping

	ldh a, [hFlags]            ; Load flags
	bit B_FLAGS_GBC, a         ; Are we running on GBC?
	jr z, .cont2               ; If not, skip

.addBtns
	ld bc, T_COMPO_BTN << 8 | P_COMPO_BTN
	ld de, Y_COMPO_BTN << 8 | X_COMPO_BTN
	call SetObject             ; Set button B object
	dec b                      ; Restore tile ID
	inc e                      ; Advance X
	call SetObject             ; Set button A object

.cont2
	call hFixedOAMDMA
	inc l
	ld e, l

.compo1
	ld a, Y_COMPO_INIT1
	ldh [rSCY], a
	ld a, X_COMPO_INIT1
	ldh [rSCX], a
	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_OBJ_ON
	ld d, X_COMPO_STOP1
	call LoopCompo

.compo2
	ld a, Y_COMPO_WIN2
	ldh [rWY], a
	ld a, X_COMPO_WIN2
	ldh [rWX], a
	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_OBJ_ON | LCDC_WIN_ON | LCDC_WIN_9C00
	ld d, X_COMPO_STOP2
	call LoopCompo

.compo3
	xor a
	ldh [rSCX], a
	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_BG_9C00
	ld d, X_COMPO_STOP3
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
	cp T_COMPO_OBJ
	jr z, .loop4
	ld [hl], a
	ld a, l
	add OBJ_SIZE
	ld l, a
	cp V_COMPO_OBJ * OBJ_SIZE + OAMA_TILEID
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
	MEM_COPY CompoTextTiles

.obj
	ld de, CompoObjTiles
	ldh a, [hFlags]
	cp FLAGS_SGB
	jr nz, .objCont
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
	ld h, HIGH(TILEMAP1) - 1
	call ClearShort     ; Clear 256 bytes (since C is zero from before)
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
	; Fall through

ClearShort:
	ld [hli], a         ; Load the byte in the A register to the address HL points to, increment HL
	dec c               ; Decrement the loop counter
	jr nz, ClearShort   ; Stop if C is zero, otherwise keep looping
	ret


SECTION "InitSGB", ROM0
InitSGB:
	call SGB_InitVRAM
	call SGB_Freeze
	rst ScreenOff
	ld hl, STARTOF(VRAM)
	ld c, 32
	call ClearShort
	MEM_COPY BorderTilesSGB
	call SGB_SendBorder.cont
	ld bc, BorderSGB.end - BorderSGB
	ld de, BorderSGB
	call SGB_SendBorder
	call ClearVRAM
	ld hl, CompoPaletteSGB
	call SGB_SendPacket
	jr SetBank

ClearVRAM:
	ld hl, TILEMAP0
.loop
	rst WaitVRAM
	ld a, T_COMPO_EMPTY
	ld [hli], a
	bit 2, h
	jr z, .loop
	; Fall through

DoSound4::
	call DoSound2
	; Fall through

DoSound2::
	call DoSound
	; Fall through

DoSound::
	ld a, BANK(song_ending)
	ld [rROMB0], a
	call hUGE_dosound
	; Fall through

SetBank:
	ld a, BANK_COMPO
	ld [rROMB0], a
	ret


InitGBC:
	rst WaitVBlank
	ld hl, CompoPaletteGBC
	ldh a, [hFlags]
	bit B_FLAGS_GBA, a
	jr z, .cont
	ld hl, CompoPaletteGBA
.cont
	ld e, 16
	call GBC_SetPalettes
	ld a, OPRI_COORD
	ldh [c], a

IF DEF(COMPO_GRADIENT)
	ld de, CompoColorLUT       ; Load the address of our color LUT into DE
	call CopyColorLUT          ; Copy the color LUT

IF !DEF(INTRO_GRADIENT)
	xor a                      ; Set A to zero
	ldh [rLYC], a              ; Set which line to trigger the LY=LYC interrupt on
	ld a, STAT_LYC             ; Load the flag to enable LYC STAT interrupts into A
	ldh [rSTAT], a             ; Load the prepared flag into rSTAT to enable the LY=LYC interrupt source 
	ld a, IE_VBLANK | IE_STAT  ; Load the flag to enable the VBlank and STAT interrupts into A
	ldh [rIE], a               ; Load the prepared flag into the interrupt enable register
	xor a                      ; Set A to zero
	ldh [rIF], a               ; Clear any lingering flags from the interrupt flag register to avoid false interrupts
ENDC

ENDC

	jr DoSound2


SECTION "CompoObjMap", ROMX, BANK[BANK_INIT], ALIGN[8]
CompoObjMap:
	INCBIN "compo_obj.tilemap"
.end


IF DEF(COMPO_GRADIENT)

SECTION "CompoColorLUT", ROMX, BANK[BANK_COMPO]
CompoColorLUT:
	GRADIENT_LUT C_COMPO_GRADIENT_TOP, C_COMPO_GRADIENT_BOTTOM

ENDC


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
	dw C_LILAC
	INCBIN "compo_logo_gbc.pal", 2, 6
	INCBIN "compo_button_gbc.pal"
	INCBIN "compo_obj_gbc.pal"
	INCBIN "compo_button_gbc.pal"


SECTION "CompoPaletteGBA", ROMX, BANK[BANK_COMPO]
CompoPaletteGBA:
	dw C_LILAC_SGB
	INCBIN "compo_logo.pal", 2, 6
	INCBIN "compo_button.pal"
	INCBIN "compo_obj.pal"
	INCBIN "compo_button.pal"


SECTION "BorderTilesSGB", ROMX, BANK[BANK_COMPO]
BorderTilesSGB:
	INCBIN "compo_border.4bpp", 32
.end
ChrTrn1SGB:
	db SGB_CHR_TRN | $01
	ds 15, 0


SECTION "BorderSGB", ROMX, BANK[BANK_COMPO]
BorderSGB:
	INCBIN "compo_border.tilemap"
.end
	dw C_LILAC_SGB
	INCBIN "compo_border.pal", 2
PctTrnSGB:
	db SGB_PCT_TRN | $01
	ds 15, 0


SECTION "CompoPaletteSGB", ROMX, BANK[BANK_COMPO]
CompoPaletteSGB:
	db SGB_PAL01 | $01
	dw C_LILAC_SGB
	INCBIN "compo_logo.pal", 2, 6
	INCBIN "compo_obj.pal",  2, 6
	db 0


SECTION "HRAM", HRAM
hFrameCount:
	ds 1
