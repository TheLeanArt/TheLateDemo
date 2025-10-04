; Not licensed by Nintendo
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "defs.inc"
include "intro.inc"


SECTION FRAGMENT "Intro", ROM0
CopyIntro:
	ldh a, [rLY]               ; Read the LY register to check the current scanline
	cp SCREEN_HEIGHT_PX        ; Compare the current scanline to the first scanline of VBlank
	jr c, CopyIntro            ; Loop until the carry flag is set

	ld hl, STARTOF(VRAM) | T_INTRO_REG << 4
	ld de, RegTiles
	COPY_1BPP_PRE_SAFE Reg     ; Copy ® tiles
	ld e, LOW(TopTiles)
	dec b                      ; Clear bitplane 1
	call Copy1bppOdd           ; Copy top N
	ld c, b                    ; Set bitplane 0
	call Copy1bppEven          ; Copy top T
	ld e, LOW(TopTiles.i)
	ld c, a                    ; Clear bitplane 0
	call Copy1bppOdd           ; Copy top I

	ld e, LOW(TopTiles.e)
	call Copy1bppEven          ; Copy top E
	ld c, b                    ; Set bitplane 1
	call Copy1bppOdd           ; Copy top N
	ld e, LOW(TopTiles.d)
	call Copy1bppEven          ; Copy top D

	ld e, LOW(TopTiles)
	COPY_1BPP_PRE_SAFE Top     ; Copy top tiles

	ld e, LOW(ByTiles.b)
	ld b, a                    ; Clear bitplane 1
	call Copy1bppEven          ; Copy B
	call FillSafe              ; Clear the odd tile
	call Copy2bppEven          ; Copy Y
	call FillSafe              ; Clear the last tile in the 2nd row

	COPY_1BPP_SAFE TopO        ; Copy top O tiles

	ld bc, IntroTiles.end - IntroTiles
.loop
	rst WaitVRAM               ; Wait for VRAM to become accessible
REPT 2
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	xor a                      ; Clear the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
ENDR
	inc de                     ; Increment the source pointer in DE
	dec bc                     ; Decrement the loop counter in BC
	ld a, b                    ; Load the value in B into A
	or c                       ; Logical OR the value in A (from B) with C
	jr nz, .loop               ; If B and C are both zero, OR B will be zero, otherwise keep looping


SECTION "Copy1bpp", ROM0[$28]
Copy1bpp:
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	and c                      ; Filter bitplane 0
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	and b                      ; Filter bitplane 1
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	ret


SECTION "Copy2bppEven", ROM0
Copy2bppEven:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld a, [de]                 ; Load a byte from the address DE points to into the A register
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	inc e                      ; Increment the source pointer in E
	bit 4, l                   ; Odd tile address reached?
	jr z, Copy2bppEven         ; If not, continue looping
	ret


SECTION "Copy1bppEven", ROM0
Copy1bppEven:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	rst Copy1bpp               ; Copy row
	bit 4, l                   ; Odd tile address reached?
	jr z, Copy1bppEven         ; If not, continue looping
	ret


SECTION "Copy1bppOdd", ROM0
Copy1bppOdd:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	rst Copy1bpp               ; Copy row
	bit 4, l                   ; Even tile address reached?
	jr nz, Copy1bppOdd         ; If not, continue looping
	ret


SECTION "FillSafe", ROM0
FillSafe:
	rst WaitVRAM               ; Wait for VRAM to become accessible
	ld [hli], a                ; Load the byte in the A register to the address HL points to, increment HL
	bit 4, l                   ; Even tile address reached?
	jr nz, FillSafe            ; If not, keep looping
	ret


SECTION "Intro Tile data", ROM0, ALIGN[8]
RegTiles:
	INCBIN "intro_reg.1bpp"
.end

TopTiles:
	INCBIN "intro_top_n.1bpp"
.t
	INCBIN "intro_top_t.1bpp"
.l
	INCBIN "intro_top.1bpp",  0,  8
.i
	INCBIN "intro_top.1bpp",  8,  8
.c
	INCBIN "intro_top.1bpp", 16,  8
.e
	INCBIN "intro_top.1bpp", 24,  8
.n
	INCBIN "intro_top.1bpp", 32,  8
.s
	INCBIN "intro_top.1bpp", 40,  8
.d
	INCBIN "intro_top.1bpp", 48,  8
.end

ByTiles:
.b
FOR I, 0, 16, 2
	INCBIN "intro_by.2bpp", I, 1
ENDR
.y
	INCBIN "intro_by.2bpp", 16, 16

TopOTiles:
	INCBIN "intro_top_o.1bpp"
.end

IntroTiles:
	_0_5_BPP "intro_n.1bpp"
	_0_5_BPP "intro_e.1bpp"
	_0_5_BPP "intro_n0.1bpp"
	_0_5_BPP "intro_d.1bpp"
	_0_5_BPP "intro_o.1bpp"
	_0_5_BPP "intro_i.1bpp"
	_0_5_BPP "intro_t.1bpp"
.end
