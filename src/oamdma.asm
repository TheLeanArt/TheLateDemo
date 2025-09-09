; Adapted from Simple GB ASM Examples by Dave VanEe
; License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)


include "hardware.inc"


SECTION "ScreenOff", ROM0[$00]
ScreenOff::
	rst WaitVBlank
	xor a
	ldh [rLCDC], a
	ret


SECTION "WaitVRAM", ROM0[$30]
WaitVRAM::
	ldh a, [rSTAT]             ; Check the STAT register to figure out which mode the LCD is in
	and STAT_BUSY              ; AND the value to see if VRAM access is safe
	jr nz, WaitVRAM            ; If not, proceed to loop
	nop                        ; Wait for 1 M-cycle
	ret                        ; Return when VRAM access is safe


SECTION "WaitVBlank", ROM0[$38]
WaitVBlank::
	halt                       ; Wait for interrupt
	ldh a, [rLY]               ; Read the LY register to check the current scanline
	cp SCREEN_HEIGHT_PX        ; Compare the current scanline to the first scanline of VBlank
	ret nc                     ; Return as soon as the carry flag is clear
	jr WaitVBlank              ; Proceed to loop otherwise


SECTION "VBlank Vector", ROM0[$40]
VBlank::
	push af
	push bc
	call hFixedOAMDMA
	ld b, a
	jr STAT.cont


SECTION "STAT Vector", ROM0[$48]
STAT:
	push af
	push bc
	ldh a, [rLYC]
	ld b, a
	add 8
.cont
	ldh [rLYC], a
	rst WaitVRAM
	ld c, LOW(rBGPI)
	ld a, BGPI_AUTOINC
	ldh [c], a
	inc c
	ldh a, [hColorLow]
	ldh [c], a
	ld a, [hColorHigh]
	ldh [c], a
	ld a, b
	rrca
	rrca
	rrca
	and $1E
	ld c, a
	ld b, HIGH(ColorLUT)
	ld a, [bc]
	ldh [hColorLow], a
	inc c
	ld a, [bc]
	ldh [hColorHigh], a
	pop bc
	pop af
	reti


SECTION "ColorLUT", ROM0, ALIGN[8]
ColorLUT:
FOR I, 28, 0, -1
	dw %11111 << 10 | I << 5 | %11100
ENDR


SECTION "Fixed OAM DMA Subroutine", ROM0

FixedOAMDMA::
	ld a, HIGH(wShadowOAM)
    ldh [rDMA], a
    ld a, OAM_COUNT
.loop
    dec a
    jr nz, .loop
    ret
.end::


SECTION "OAM DMA", HRAM

hFixedOAMDMA::
	ds FixedOAMDMA.end - FixedOAMDMA


SECTION FRAGMENT "HRAM", HRAM

hColorLow::
	db
hColorHigh::
	db


SECTION "Shadow OAM", WRAM0, ALIGN[8]

wShadowOAM::
	ds OAM_SIZE
