; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "sgb.inc"
include "common.inc"
include "intro.inc"


MACRO INTRO_META_INIT
	ld hl, MAP_INTRO_\1 + ROW_INTRO_\1 * TILEMAP_WIDTH + COL_INTRO_\1
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, T_INTRO_\1           ; Load top left tile ID
	ld [hli], a                ; Set top left tile and advance to the right
	ld a, T_INTRO_\1 + 2       ; Load top right tile ID
	ld [hld], a                ; Set top right tile and go back to the left
	set 5, l                   ; Move to second row
	dec a                      ; Base + 1
	ld [hli], a                ; Set bottom left tile and advance to the right
	ld a, T_INTRO_\1 + 3       ; Load bottom right tile ID
	ld [hl], a                 ; Set bottom right tile
ENDM

MACRO INTRO_TOP_INIT
	ld [hl], d                 ; Set Y
	inc l                      ; Advance to X
	ld a, X_INTRO_TOP_\1       ; Load X
	ld [hli], a                ; Set X
	ld [hl], b                 ; Set tile ID
	inc l                      ; Advance to attributes
	inc b                      ; Advance tile ID
	inc b                      ; ...
	xor a                      ; Set A to zero
	ld [hli], a                ; Set attributes
ENDM

MACRO INTRO_BOTTOM_INIT
FOR I, 0, INTRO_\1_WIDTH
	ld [hl], d                 ; Set Y
	inc l                      ; Advance to X
	ld a, X_INTRO_\1 + I * 8   ; Load X
	ld [hli], a                ; Set X
	ld a, T_INTRO_\1 + I * 2   ; Load tile ID
	ld [hli], a                ; Set tile ID
	xor a                      ; Set A to zero
	ld [hli], a                ; Set attributes
ENDR
ENDM


; Initialization portion adapted from Simple GB ASM Examples by Dave VanEe
; License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)

SECTION "Start", ROM0[$0100]
	di                         ; Disable interrupts during setup
	jr EntryPoint              ; Jump past the header space to our actual code
	ds $150 - @, 0             ; Allocate space for RGBFIX to insert our ROM header

EntryPoint:
	ld sp, $E000               ; Set the stack pointer to the end of WRAM

	ld d, FLAGS_DMG            ; Set flags to DMG
	cp BOOTUP_A_CGB            ; Are we running on GBC/GBA?
	jr nz, .cont               ; If not, proceed

.GBC:
	call SetPalettes           ; Set GBC palettes
	set B_FLAGS_GBC, d         ; Set the GBC flag
	ld a, b                    ; Load the initial value of B into A
	cp BOOTUP_B_AGB            ; Are we running on GBA?
	jr nz, .cont               ; If not, proceed

.GBA:
	set B_FLAGS_GBA, d         ; Set the GBA flag

.cont:
	ld a, c                    ; Load the initial value of C into A
	cp BOOTUP_C_SGB            ; Are we running on SGB/SGB2?
	jr nz, .notSGB             ; If not, proceed to setting flags

.SGB:
	set B_FLAGS_SGB, d         ; Set the SGB flag
	jr .setFlags               ; Proceed to setting flags

.notSGB:
	ld a, b                    ; Load the initial value of B into A
	cp BOOTUP_B_DMG0           ; Are we running on DMG0?
	jr nz, .setFlags           ; If not, proceed to setting flags

.DMG0
	set B_FLAGS_DMG0, d        ; Set the DMG0 flag

.setFlags
	ld a, d                    ; Load the flags into A
	ldh [hFlags], a            ; Set our flags

	cp FLAGS_SGB               ; Are we running on SGB/SGB2?
	call z, SetPalettesSGB     ; If yes, set SGB palettes

	; Load the length of the OAMDMA routine into B
    ; and the low byte of the destination into C
	ld bc, (FixedOAMDMA.end - FixedOAMDMA) << 8 | LOW(hFixedOAMDMA)
	ld hl, FixedOAMDMA         ; Load the source address of our routine into HL
.copyOAMDMAloop
	ld a, [hli]                ; Load a byte from the address HL points to into the register A, increment HL
	ldh [c], a                 ; Load the byte in the A register to the address in HRAM with the low byte stored in C
	inc c                      ; Increment the low byte of the HRAM pointer in C
	dec b                      ; Decrement the loop counter in B
	jr nz, .copyOAMDMAloop     ; If B isn't zero, continue looping

	call InitTop               ; Initialize our objects

.clearOAMLoop
	xor a                      ; Set A to zero
	ld [hli], a                ; Set and advance
	ld a, l                    ; Load the lower address byte into A
	cp OAM_SIZE                ; End of OAM reached?
	jr nz, .clearOAMLoop       ; If not, continue looping

	ld de, IntroTiles
	ld hl, STARTOF(VRAM) | T_INTRO_REG << 4
	COPY_1BPP_SAFE Intro       ; Copy 1bpp tiles
	COPY_0_5BPP_SAFE Intro2    ; Copy 0.5bpp tiles

	call ClearBackground       ; Clear the logo from the background
	INTRO_META_INIT BY         ; Draw BY on the background
	call SetWindow             ; Draw the logo on the window

	ld a, Y_INTRO_TOP          ; Load the initial Y value into A
	ldh [rSCY], a              ; Set the background's Y coordinate
	ldh [rWY], a               ; Set the window's Y coordinate
	ld a, WX_OFS               ; Load the window's X value into A
	ldh [rWX], a               ; Set the window's X coordinate

	ld a, %11_11_01_00         ; Display dark gray as black
	ldh [rOBP0], a             ; Set the default object palette
	xor a                      ; Display everything as white
	ldh [rOBP1], a             ; Set the alternate object palette

	ld a, IE_VBLANK            ; Load the flag to enable the VBlank and STAT interrupts into A
	ldh [rIE], a               ; Load the prepared flag into the interrupt enable register
	xor a                      ; Set A to zero
	ldh [rIF], a               ; Clear any lingering flags from the interrupt flag register to avoid false interrupts

	call VBlank                ; Perform our OAM DMA and enable interrupts!

	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01 | LCDC_OBJ_ON | LCDC_OBJ_16 | LCDC_WIN_ON | LCDC_WIN_9C00
	ldh [rLCDC], a             ; Enable and configure the LCD

	ldh a, [hFlags]            ; Load our flags into the A register
	ld c, a                    ; Store the flags in the C register
	cp FLAGS_SGB               ; Are we running on SGB?
	jr nz, .drop               ; If not, skip the SGB delay

	ld b, INTRO_SGB_DELAY      ; ~1 sec delay to make up for the SGB bootup animation
.waitLoop
	rst WaitVBlank             ; Wait for the next VBlank
	dec b                      ; Decrement the counter
	jr nz, .waitLoop           ; Continue to loop unless zero

.drop
	ld e, 0                    ; Use E as our step counter
.dropLoop
	rst WaitVBlank             ; Wait for the next VBlank
	ld hl, wShadowOAM          ; Start from the top
	ld d, HIGH(IntroDropLUT)   ; Set the upper address byte to the start of our LUT
	ld a, [de]                 ; Load the Y coordinate value
	ld b, a                    ; Store the Y coordinate in B

.objLoop
	ld [hl], b                 ; Set the Y coordinate
	ld a, l                    ; Advance to the next object
	add OBJ_SIZE               ; ...
	ld l, a                    ; ...
	cp OBJ_INTRO_TOP_END * OBJ_SIZE ; Bottom object reached?
	jr nz, .objLoop            ; If not, continue to loop

	inc d                      ; Advance to the background LUT
	ld a, [de]                 ; Load the background's Y value
	ldh [rSCY], a              ; Set the Y coordinate

	inc d                      ; Advance to the window LUT
	ld a, [de]                 ; Load the window's Y value
	ldh [rWY], a               ; Set the Y coordinate

	ld a, c                    ; Load our flags into the A register
	cp FLAGS_DMG0              ; Are we running on DMG0?
	jr z, .regDone             ; If yes, skip the � object

REPT 4
	inc d                      ; Advance to the next page
	ld a, [de]                 ; Load Y/X/tile ID/attributes value
	ld [hli], a                ; Set the value
ENDR

.regDone
	call hFixedOAMDMA          ; Prevent lag
	inc e                      ; Increment the step counter
	jr nz, .dropLoop           ; Continue to loop unless 256 reached

	call ClearWindow           ; Remove the logo from the window
	INTRO_META_INIT E          ; Draw E on the background
	INTRO_META_INIT N2         ; Draw N2 on the window
	call InitBottom            ; Draw the rest of the logo with objects
	call hFixedOAMDMA          ; Prevent flicker
	
	ld a, X_INTRO_N2           ; Set the window's X coordinate
	ldh [rWX], a               ; ...

ASSERT (BANK(song_ending) == 1)
	ld hl, song_ending         ; Load the song address into HL
	call hUGE_init             ; Initialize song

	ld e, 0                    ; Use E as our step counter
.mainLoop
	rst WaitVBlank             ; Wait for the next VBlank
	ld hl, wShadowOAM          ; Start from the top
	ld b, OBJ_INTRO_END * 2    ; Loop all the way to the end
	ld d, HIGH(IntroLUT)       ; Set the upper address byte to the start of our LUT

.pageLoop
	ld a, [de]                 ; Load the Y/tile ID value
	ld [hli], a                ; Set Y/tile ID
	set 7, e                   ; Advance to the second half-page
	ld a, [de]                 ; Load the X/attributes value
	ld [hli], a                ; Set X/attributes
	res 7, e                   ; Go back to the first half-page
	inc d                      ; Advance to the next page
	dec b                      ; Decrement the page counter
	jr nz, .pageLoop           ; Continue to loop until the end

	ld c, LOW(rSCY)            ; Start from the screen's Y coordinate
	call SetOddball            ; Update the background's coordinates + E's tiles

	ld c, LOW(rWY)             ; Start from the background's Y coordinate
	call SetOddball            ; Update the window's coordinates + N2's tiles

	ld hl, MAP_INTRO_E + ROW_INTRO_E * TILEMAP_WIDTH + COL_INTRO_E
	call SetOddballMetaTile
	set 7, e                   ; Advance to the second half-page
	ld hl, MAP_INTRO_N2 + ROW_INTRO_N2 * TILEMAP_WIDTH + COL_INTRO_N2
	call SetOddballMetaTile
	res 7, e

	call hFixedOAMDMA          ; Prevent lag

	push de                    ; Save the step counter
	call hUGE_dosound          ; Play sound
	pop de                     ; Restore the step counter

	inc e                      ; Increment the step counter
	bit 7, e                   ; Step 128 reached?
	jr z, .mainLoop            ; If not, continue to loop

	jp Compo                   ; Proceed to compo animation


SECTION "Intro Subroutines", ROM0

SetOddball:
	ld a, [de]                 ; Load the Y value
	ldh [c], a                 ; Set the Y coordinate
	set 7, e                   ; Advance to the second half-page
	inc c                      ; Advance to the X coordinate
	ld a, [de]                 ; Load the X value
	ldh [c], a                 ; Set the X coordinate
	res 7, e                   ; Go back to the first half-page
	inc d
	ret

SetOddballMetaTile:
	ld a, [de]
	; Fall through

SetMetaTile:
	ld [hli], a                ; Set top left tile
	set 1, a                   ; Base + 2
	ld [hld], a                ; Set top right tile
	set 5, l                   ; Move to second row
	dec a                      ; Base + 1
	ld [hli], a                ; Set bottom left tile
	set 1, a                   ; Base + 3
	ld [hl], a                 ; Set bottom right tile
	ret

ClearBackground:
	ld hl, MAP_LOGO + ROW_LOGO * TILEMAP_WIDTH + COL_LOGO
	call ClearLogo
	ld l, LOW(((ROW_LOGO + 1) * TILEMAP_WIDTH) + COL_LOGO)
	; Fall through

ClearLogo:
	ld c, LOGO_WIDTH + 1       ; Clear �
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	xor a
	ld [hli], a
	dec c
	jr nz, .loop
	ret

ClearWindow:
	ld hl, TILEMAP1 + COL_LOGO
	call ClearLogo
	ld l, TILEMAP_WIDTH + COL_LOGO
	jr ClearLogo

SetWindow:
	ld hl, TILEMAP1 + COL_LOGO
	ld b, T_LOGO
	call .logo
	ld l, TILEMAP_WIDTH + COL_LOGO
	; Fall through

.logo:
	ld c, LOGO_WIDTH
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld [hl], b
	inc l
	inc b
	dec c
	jr nz, .loop
	ret

InitTop:
	ld hl, wShadowOAM + OBJ_INTRO_NOT * OBJ_SIZE
	ld b, T_INTRO_NOT
	ld de, Y_INTRO_INIT << 8 | X_INTRO_TOP
	call SetTwoObjects16

FOR I, 8
	INTRO_TOP_INIT {d:I}
ENDR
	; Fall through

InitReg:
	ld a, Y_INTRO_REG          ; Load the Y value
	ld [hli], a                ; Set the Y coordinate
	ld a, X_INTRO_REG          ; Load the X value
	ld [hli], a                ; Set the X coordinate
	ld a, T_INTRO_REG          ; Load the tile ID
	ld [hli], a                ; Store tile ID
ASSERT (B_FLAGS_DMG0 == B_OAM_PAL1)
	ldh a, [hFlags]            ; Load our flags into the A register
	and 1 << B_FLAGS_DMG0      ; Isolate the DMG0 flag
	ld [hli], a                ; Set attributes
	ret

InitBottom:
	ld hl, wShadowOAM + OBJ_INTRO_0 * OBJ_SIZE
	ld b, T_INTRO_0
	ld de, Y_INTRO_BOTTOM << 8 | X_INTRO_0
	call SetTwoObjects16

FOR I, 1, 6
	INTRO_BOTTOM_INIT {d:I}
ENDR
	ret

SetTwoObjects16:
	call SetObject16
	; Fall through

SetObject16:
	ld a, d
	ld [hli], a
	ld a, e
	ld [hli], a
	add TILE_WIDTH
	ld e, a
	ld a, b
	ld [hli], a
	inc b
	inc b
	xor a
	ld [hli], a
	ret

SetPalettes:
	ld hl, rBGPI
	call SetPalette
	; Fall through

SetPalette:
	ld a, BGPI_AUTOINC
	ld [hli], a
	ld a, $FF
	ld [hl], a
	ld [hl], a
	cpl
REPT 5
	ld [hl], a
ENDR
	ld [hli], a
	ret

SetPalettesSGB:
	ld hl, PaletteSGB
	jp SGB_SendPacket

PaletteSGB:
	db SGB_PAL01 | $01
	dw cOffWhiteSGB
REPT 6
	dw cBlack
ENDR
	db 0



SECTION "Intro Flags", HRAM

hFlags::
	ds 1


SECTION "Intro Tile data", ROM0, ALIGN[8]

IntroTiles:
	INCBIN "intro_reg.1bpp"
	INCBIN "intro_not.1bpp"
	INCBIN "intro_top.1bpp"
	INCBIN "intro_by.1bpp"
.end

Intro2Tiles:
FOR I, 0, 256, 2
	INCBIN "intro_n0.1bpp", I, 1
ENDR
FOR I, 0, 64, 2
	INCBIN "intro_i.1bpp", I, 1
ENDR
FOR I, 0, 64, 2
	INCBIN "intro_t.1bpp", I, 1
ENDR
FOR I, 0, 128, 2
	INCBIN "intro_d.1bpp", I, 1
ENDR
FOR I, 0, 128, 2
	INCBIN "intro_o.1bpp", I, 1
ENDR
FOR I, 0, 256, 2
	INCBIN "intro_n.1bpp", I, 1
ENDR
FOR I, 0, 256, 2
	INCBIN "intro_e.1bpp", I, 1
ENDR
.end
