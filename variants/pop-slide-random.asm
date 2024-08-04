; A scanline interrupt that updates the palette during h-blank, using:
; - a popslide to read the data,
; - random access writing to the palettes set,
; - color pairs (as opposed to copying a single color every time).
;
; Slower than a hardcoded slide, but takes less space in ROM.
; Slower than a consecutive access, but allows for more flexibility.
; Faster than copying individual colors (usings pairs instead), but less flexible.
;
; This method can copy up to 8 color pairs (16 colors) at random locations per scanline.
ScanlineInterruptPopSlideRandom:
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

  ; Macro: copy the next pair of 2 colors to a specific location
MACRO copy_next_color_pair_to ; color index
  ; Update rBGPI to point to the correct color index
  dec l ; 1 cycle
  ld [hl], BGPIF_AUTOINC | \1 ; 3 cycles
  inc l ; 1 cycle
  ; Copy two consecutive colors
  pop de       ; 3 cycles
  ld [hl], e   ; 2 cycles
  ld [hl], d   ; 2 cycles
  pop de       ; 3 cycles
  ld [hl], e   ; 2 cycles
  ld [hl], d   ; 2 cycles
ENDM

  ; Now copy as much colors as we can
  ; (using an unrolled loop)
  copy_next_color_pair_to 8
  copy_next_color_pair_to 16
  copy_next_color_pair_to 24
  copy_next_color_pair_to 32
  copy_next_color_pair_to 40
  copy_next_color_pair_to 48
  copy_next_color_pair_to 56

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
