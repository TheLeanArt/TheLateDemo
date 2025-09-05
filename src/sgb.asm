; Adapted from https://github.com/gb-archive/snek-gbc/blob/main/code/sub.sm83
;
; Copyright (c) 2023 zlago

include "hardware.inc"
include "sgb.inc"
include "common.inc"


MACRO SEND_BIT
	ldh [c], a          ; 5 cycles
	ld a, $FF           ; end pulse
	nop
	ldh [c], a          ; 15 cycles
ENDM

SECTION "SGB_SendPacket", ROM0
SGB_SendPacket::
	ld bc, SGB_PACKET_SIZE << 8 | LOW(rP1)
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


SECTION "SGB_InitVRAM", ROM0
SGB_InitVRAM::
	rst ScreenOff
	ldh [rSCX], a
	ldh [rSCY], a
	ld hl, TILEMAP0
	ld b, SCREEN_HEIGHT
	ld de, TILEMAP_WIDTH - SCREEN_WIDTH
.rowLoop
	ld c, SCREEN_WIDTH
.columnLoop
	ld [hli], a
	inc a
	dec c
	jr nz, .columnLoop
	add hl, de
	dec b
	jr nz, .rowLoop
	; Fall through

ScreenOn:
	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK01
	ldh [rLCDC], a
	ret


SECTION "SGB_CopyVRAM", ROM0
SGB_CopyVRAM::
	push hl
	rst ScreenOff
	ld hl, STARTOF(VRAM)
	ld bc, $1000
.copyLoop
	ld a, [de]
	ld [hli], a
	inc e
	dec c
	jr nz, .copyLoop
	inc d
	dec b
	jr nz, .copyLoop

	call DoSoundSGB2

	call ScreenOn
	pop hl
	call SGB_SendPacket

	call DoSoundSGB2
	; Fall through

SGB_Wait4Frames:
	call SGB_Wait2Frames
	; Fall through

SGB_Wait2Frames:
	call SGB_Wait1Frame
	; Fall through

SGB_Wait1Frame:
	halt
	jp DoSoundSGB
