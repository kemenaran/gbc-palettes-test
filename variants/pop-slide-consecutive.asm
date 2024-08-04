; A scanline interrupt that updates the palette during h-blank, using:
; - a popslide to read the data,
; - consecutive writing to the palettes set.
;
; Slower than a hardcoded slide, but takes less space in ROM.
;
; This method can copy up to 21 consecutive colors per scanline.
ScanlineInterruptPopSlideConsecutive:
  ; Mode 2 - OAM scan (40 GBC cycles)
  ; ------------------------------------------------------

  ; (ignore this mode 2, as it is for scanline 0, which we don't care about.)

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Save the stack pointer
  ld [hStackPointer], sp ; 5 cycles

  ; Move the stack pointer to the beginning of the palettes set
  ld sp, Pico8Palettes ; 3 cycles

  ; Prepare the color register (7 cycles)
  ld hl, rBGPI ; 3 cycles
  ld [hl], BGPIF_AUTOINC | 0 ; 3 cycles
  inc l ; rBGPD   ; 1 cycles

  ; Pre-pop two colors
  pop bc
  pop de

  ; Request an exit of `halt` on mode 0
  ld a, STATF_MODE00
  ldh [rSTAT], a
  ld a, IEF_STAT
  ldh [rIE], a
  ; (We're in an interrupt handler, so interrupts are already disabled)
  ; di

  ; Wait for HBlank (STAT mode 0)
  halt
  ; no need for a nop, as we're pretty sure no enabled interrupt was serviced during the halt

  ; Mode 0 - HBlank, VRAM accessible (102 GBC cycles without SCX/SCX and objects)
  ; Mode 2 - OAM scan, VRAM accessible (40 GBC cycles)
  ; Total: 142 GBC cycles
  ; ------------------------------------------------------

  ; Copy the two colors we stored in registers during Mode 3 (8 cycles)
  ld [hl], c  ; 2 cycles
  ld [hl], b  ; 2 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles

  ; Now copy as much colors as we can
  ; (using an unrolled loop)
REPT 19
  ; Copy a color (7 cycles)
  pop de      ; 3 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles
ENDR

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Manually mark the STAT Mode 0 interrupt as serviced
  ; (as IME was disabled, it wasn't done automatically by the CPU)
  ld hl, rIF         ;
  res IEB_STAT, [hl] ; 4 cycles

  ; Restore the stack pointer (8 cycles)
  ld sp, hStackPointer  ; 3 cycles
  pop hl                ; 3 cycles
  ld sp, hl             ; 2 cycles

  ; Restore interrupts (5 cycles)
  ld a, IEF_VBLANK      ; 2 cycles
  ldh [rIE], a          ; 3 cycles

  ; Return (4 cycles)
  reti                  ; 4 cycles
