; SGB subroutines
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "common.inc"
include "sgb.inc"


SECTION "SGB_SendPacket", ROM0
SGB_TryFreeze::
	ldh a, [hFlags]            ; Load our flags into the A register
	and FLAGS_SGB              ; Are we running on SGB?
	ret z                      ; If not, return
	; Fall through

SGB_Freeze::
	ld a, SGB_MASK_EN_MASK_FREEZE
	jr SGB_Unfreeze.cont

SGB_TryUnfreeze::
	ldh a, [hFlags]            ; Load our flags into the A register
	and FLAGS_SGB              ; Are we running on SGB?
	ret z                      ; If not, return
	; Fall through

SGB_Unfreeze::
	ld a, SGB_MASK_EN_MASK_CANCEL
	; Fall through

.cont
	ld hl, wPacketBuffer + A_SGB_MASK_EN_MASK
	ld [hld], a                ; Set and move back
	ld a, SGB_MASK_EN | $01    ; Load packet header into A
	jr SGB_SetPalettes01.cont  ; Proceed to set packet header

SGB_SetColors01::
	ld hl, wPacketBuffer + A_SGB_PAL01_PAL_0_COLOR_3 + 1
	ld [hl], b                 ; Set the foreground's upper byte
	dec l                      ; Move back
	ld [hl], c                 ; Set the foreground's lower byte

	ld l, A_SGB_PAL01_COLOR_0 + 1
	ld [hl], d                 ; Set the background's upper byte
	jr SGB_SetBackground01.cont; Proceed to set the background's lower byte

SGB_SetBackground01::
	ld hl, wPacketBuffer + A_SGB_PAL01_COLOR_0 + 1
	ld [hl], b                 ; Set the background's upper byte
	ld a, c                    ; Load the background's lower byte into A
	; Fall through

.cont
	dec l                      ; Move back
	ld [hld], a                ; Set the background's lower byte and move back
	; Fall through

SGB_SetPalettes01::
	ld a, SGB_PAL01 | $01	   ; Load packet header into A
	; Fall through

.cont
	ld [hl], a                 ; Set packet header
	; Fall through


; Send SGB packet
;
; Optimized subroutine by nitro2k01
; https://github.com/nitro2k01
;
; @param HL Packet
; @param BC Clobbered
SGB_SendPacket::
	ld bc, SGB_PACKET_SIZE + 1 ; B = 0, C = SGB packet size + 1
	xor a                      ; A = 0, CF = 0
	ldh [rJOYP], a             ; Send start bit

.bitLoop
	ld a, JOYP_SGB_FINISH      ; Load idle state
	ldh [rJOYP], a             ; Send idle state

.bitCont
	rr b                       ; Get next bit, plus zero check
	jr z, .nextByte            ; If byte end reached, proceed to the next byte
	sbc a                      ; Transfer carry into all bits of A
	xor JOYP_SGB_ZERO          ; Select the relevant bit, CF = 0
	ldh [rJOYP], a             ; Send bit
	jr .bitLoop                ; Continue looping

.nextByte
	dec c                      ; Check length in bytes
	scf                        ; Set carry to inject sentinel bit
	jr z, .done                ; If packet end reached, proceed to send stop bit
	ld a, [hli]                ; Load next byte
	ld b, a                    ; Load into B
	jr .bitCont                ; Continue looping

.done
	ld a, JOYP_SGB_ZERO        ; Load stop bit
	ldh [rJOYP], a             ; Send stop bit
	sbc a                      ; Reuse the sentinel bit to save 1 byte/cycle loading $FF into A
	ldh [rJOYP], a             ; Send idle state
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


SECTION "SGB Packet Buffer", WRAM0, ALIGN[8]
wPacketBuffer::
	ds SGB_PACKET_SIZE
