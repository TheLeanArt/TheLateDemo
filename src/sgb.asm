; Adapted from https://github.com/gb-archive/snek-gbc/blob/main/code/sub.sm83
;
; Copyright (c) 2023 zlago

include "hardware.inc"
include "common.inc"
include "sgb.inc"


MACRO SEND_BIT
	ldh [rJOYP], a      ; 5 cycles
	ld a, $FF           ; end pulse
	ldh [rJOYP], a      ; 15 cycles
ENDM

SECTION "SGB_SendPacket", ROM0
SGB_Freeze::
	ld hl, FreezeSGB
	jr SGB_SendPacket

SGB_TryFreeze::
	ld hl, FreezeSGB
	jr SGB_TrySendPacket

SGB_Unfreeze::
	ld hl, UnfreezeSGB
	jr SGB_SendPacket

SGB_TryUnfreeze::
	ld hl, UnfreezeSGB
	; Fall through

SGB_TrySendPacket::
	ldh a, [hFlags]
	cp FLAGS_SGB
	ret nz
	; Fall through

SGB_SendPacket::
	ld b, SGB_PACKET_SIZE
	xor a               ; start bit
	SEND_BIT

.byteLoop
	ld d, [hl]
	inc hl
	ld c, 8

.bitLoop
	xor a               ; load A with SGB bit
	rr d                ; fetch next bit
	ccf                 ; set accumulator in the dumbest way i could come up with
	adc a
	inc a
	swap a
	nop
	SEND_BIT

	dec c
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
	ldh [rJOYP], a
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


SECTION "SGB_SendBorder", ROM0
SGB_SendBorder::
	rst ScreenOff
	ld hl, STARTOF(VRAM)
	call MemCopyAndClear
	ld b, 32
.loop
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, .loop
.cont::
	push de
	call DoSound2
	call ScreenOn
	pop hl
	call SGB_SendPacket
	call DoSound2
	; Fall through

SGB_Wait4Frames:
	call SGB_Wait2Frames
	; Fall through

SGB_Wait2Frames:
	call SGB_Wait1Frame
	; Fall through

SGB_Wait1Frame:
	halt
	jp DoSound


SECTION "FreezeSGB", ROM0
FreezeSGB:
	db SGB_MASK_EN | $01
	db SGB_MASK_EN_MASK_FREEZE
	ds 14


SECTION "UnfreezeSGB", ROM0
UnfreezeSGB:
	db SGB_MASK_EN | $01
	db SGB_MASK_EN_MASK_CANCEL
	ds 14
