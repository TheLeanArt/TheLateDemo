; Common GBC subroutines
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"


SECTION "GBC_SetPalettes", ROM0

; Set GBC palettes
;
; @param E  Total color count (2 * byte count)
; @param BC Clobbered
GBC_SetPalettes::
	ld c, LOW(rBGPI)           ; Load the destination address to C
	call .do                   ; Set the background palettes
	                           ; Set the object palettes
.do
	ld a, BGPI_AUTOINC         ; Set index to 0 and enable auto-increment
	ldh [c], a                 ; Store the value of A in the index register
	inc c                      ; Advance to the value register
	ld b, e                    ; Load the byte count into B
.loop
	ld a, [hli]                ; Load the next value into A and increment HL
	ldh [c], a                 ; Store the value of A in the value register
	dec b                      ; Decrement the loop counter
	jr nz, .loop               ; Stop if B is zero, otherwise keep looping
	inc c                      ; Advance to the object index / priority register
	ret
