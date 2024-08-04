; A scanline interrupt that updates the palette during h-blank, using:
; - colors data hardcoded into the unrolled loop,
; - consecutive writing to the palettes set.
;
; Faster than a popslide slide, but takes mode space in ROM
; (as the loop contains both colors data and assembly code).
;
; This method can copy up to 24 consecutive colors per scanline.
ScanlineInterruptHardcodedSlideConsecutive:
  ; Mode 2 - OAM scan (40 GBC cycles)
  ; ------------------------------------------------------

  ; (ignore this mode 2, as it is for scanline 0, which we don't care about.)

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Prepare the color register (7 cycles)
  ld hl, rBGPI ; 3 cycles
  ld [hl], BGPIF_AUTOINC | 0  ; 3 cycles
  inc l ; rBGPD               ; 1 cycles

  ; Pre-load two colors
  ld bc, C_RED
  ld de, C_ORANGE

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

  ; Macro: copy an hardcoded color
MACRO copy_color
  ld [hl], LOW(\1)  ; 3 cycles
  ld [hl], HIGH(\1) ; 3 cycles
ENDM

  ; Now copy as much colors as we can
  ; (using an unrolled loop)
  copy_color C_DARK_BLUE
  copy_color C_BLACK

  copy_color C_ORANGE
  copy_color C_YELLOW
  copy_color C_DARK_PURPLE
  copy_color C_BLACK

  copy_color C_YELLOW
  copy_color C_GREEN
  copy_color C_DARK_GREEN
  copy_color C_BLACK

  copy_color C_GREEN
  copy_color C_BLUE
  copy_color C_BROWN
  copy_color C_BLACK

  copy_color C_BLUE
  copy_color C_LAVENDER
  copy_color C_DARK_GREY
  copy_color C_BLACK

  copy_color C_LAVENDER
  copy_color C_PINK
  copy_color C_LIGHT_GREY
  copy_color C_RED

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Manually mark the STAT Mode 0 interrupt as serviced
  ; (as IME was disabled, it wasn't done automatically by the CPU)
  ld hl, rIF         ;
  res IEB_STAT, [hl] ; 4 cycles

  ; Restore interrupts (5 cycles)
  ld a, IEF_VBLANK      ; 2 cycles
  ldh [rIE], a          ; 3 cycles

  reti ; 4 cycles
