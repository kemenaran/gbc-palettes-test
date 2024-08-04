; A scanline interrupt that updates the palette during h-blank, using:
; - colors data hardcoded into the unrolled loop,
; - random access writing to the palettes set,
; - color pairs (as opposed to copying a single color every time).
;
; Faster than a popslide slide, but takes mode space in ROM
; (as the loop contains both colors data and assembly code).
;
; This method can copy up to 9 color pairs (18 colors) per scanline.
ScanlineInterruptHardcodedSlideRandom:
  ; Mode 2 - OAM scan (40 GBC cycles)
  ; ------------------------------------------------------

  ; (ignore this mode 2, as it is for scanline 0, which we don't care about.)

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Prepare the color registers
  ld de, rBGPI
  ld hl, rBGPD

  ; Set the initial palettes register index
  ld a, BGPIF_AUTOINC | 0 ; 2 cycles
  ld [de], a              ; 2 cycles

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

  ; Copy the first pair of colors, using the pre-configured register index
  ld [hl], LOW(C_RED)
  ld [hl], HIGH(C_RED)
  ld [hl], LOW(C_ORANGE)
  ld [hl], HIGH(C_ORANGE)

  ; Macro: copy a pair of 2 colors to a specific location
MACRO copy_color_pair_to ; index, color1, color2
  ld a, BGPIF_AUTOINC | \1 ; 2 cycles
  ld [de], a               ; 2 cycles

  ld [hl], LOW(\2)         ; 3 cycles
  ld [hl], HIGH(\2)        ; 3 cycles
  ld [hl], LOW(\3)         ; 3 cycles
  ld [hl], HIGH(\3)        ; 3 cycles
ENDM

  ; Copy the rest of the colors (with random access)
  ;copy_color_pair_to 0, C_RED, C_ORANGE
  copy_color_pair_to 4, C_DARK_BLUE, C_BLACK

  copy_color_pair_to 8, C_ORANGE, C_YELLOW
  copy_color_pair_to 12, C_DARK_PURPLE, C_BLACK

  copy_color_pair_to 16, C_YELLOW, C_GREEN
  copy_color_pair_to 20, C_DARK_GREEN, C_BLACK

  copy_color_pair_to 24, C_GREEN, C_BLUE
  ;copy_color_pair_to 28, C_BROWN, C_BLACK

  copy_color_pair_to 32, C_BLUE, C_LAVENDER
  ;copy_color_pair_to 36, C_DARK_GREY, C_BLACK

  copy_color_pair_to 40, C_LAVENDER, C_PINK
  ;copy_color_pair_to 44, C_LIGHT_GREY, C_BLACK

  ; Manually mark the STAT Mode 0 interrupt as serviced
  ; (as IME was disabled, it wasn't done automatically by the CPU)
  ld hl, rIF         ;
  res IEB_STAT, [hl] ; 4 cycles

  ; Restore interrupts (5 cycles)
  ld a, IEF_VBLANK      ; 2 cycles
  ldh [rIE], a          ; 3 cycles

  reti ; 4 cycles
