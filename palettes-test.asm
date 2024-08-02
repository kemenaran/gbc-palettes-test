; A test ROM, to see how many palettes colors we can replace during a single HBlank.
;
; It loads a repeated stripped tile and a grayscale palette – and 0.5s
; after enables an HBlank interrupt for 1 frame, which will try to push
; as many different colors as possible during one scanline.
;
; To compile: make palettes-test.gbc

INCLUDE "hardware.inc"
INCLUDE "pico8.inc"
INCLUDE "constants.asm"

DEF PALETTE_SWAP_START_VI EQU 30
DEF INTERRUPT_LOOP_LAST_SCANLINE EQU 128

SECTION "Interrupt VBlank", ROM0[$0040]
  jp VBlankInterrupt

SECTION "LCD Status interrupt", ROM0[$0048]
  ; Uncomment one of these lines to change the update method.
  jp ScanlineInterruptHardcodedSlideConsecutive
  ;jp ScanlineInterruptHardcodedSlideRandom
  ;jp ScanlineInterruptPopSlideConsecutive
  ;jp ScanlineInterruptPopSlideRandom

SECTION "Header", ROM0[$100]
  jp EntryPoint

ds $150 - @, 0 ; Make room for the header

EntryPoint:
  ; Shut down audio circuitry
  ld a, 0
  ld [rNR52], a

  ; Turn the LCD off
  ; (do not turn the LCD off outside of VBlank)
.waitVBlank
  ld a, [rLY]
  cp 144
  jr c, .waitVBlank
  ld a, 0
  ld [rLCDC], a

  ; Switch CPU to double-speed
  xor  a
  ldh  [rIE], a
  ld   a, P1F_5 | P1F_4
  ldh  [rP1], a
  ld   a, KEY1F_PREPARE
  ldh  [rKEY1], a
  stop

  ; Initialize stack
  ld sp, wStackTop

  ; Clear HRAM
  ld hl, _HRAM
  ld bc, $FFFE - _HRAM
  call ClearData

  ; Clear BG maps
  call ClearBGMap0
  call ClearBGMap1

  ; Load attributes map
  ld de, Attrmap ; source
  ld hl, _SCRN0  ; destination
  ld bc, 18      ; rows count
  call CopyAttrmap

  ; Load a grayscale BG palettes set
  ld hl, GrayscalePalettes
  call CopyBGPalettes

  ; Load a single grayscale tile
  call CopyGrayscaleTile

  ; Turn the LCD on
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_WINOFF | LCDCF_OBJOFF
  ld [rLCDC], a

  ; During the first (blank) frame, initialize display registers
  ld a, %11100100
  ld [rBGP], a

  ; Configure interrupts
  di
  ld a, IEF_VBLANK
  ldh [rIE], a
  ei

  ; Start the main loop
  jp MainLoop

MainLoop:
  ; Stop the CPU until the next interrupt
  halt
  nop
  ; Ensure we actually reached v-blank
.ensureVBlank
  ld a, [rLY]
  cp 144
  jr c, .ensureVBlank

  ; Prepare registers for the LCDStat interrupt
  ld hl, rBGPI

  ; Loop
  jp MainLoop

; Executed by the VBlank interrupt handler
VBlankInterrupt:
  ; Increment the VI count
  ld hl, hVICount
  inc [hl]

  ; If we reached the demo start, enable the palette swap code
  ld a, [hVICount]
  cp PALETTE_SWAP_START_VI
  jr nz, .done

.enableScanlineInterrupt
  ; Trigger the scanline interrupt on LYC == 0
  ld a, STATF_LYC
  ldh [rSTAT], a
  ld a, 0
  ldh [rLYC], a
  ; Enable the scanline interrupt
  ld a, IEF_VBLANK | IEF_STAT
  ldh [rIE], a

.done
  reti

CopyGrayscaleTile:
  ld hl, GrayscaleTile
  ld de, _VRAM + $0FF0
  ld bc, GrayscaleTile.end - GrayscaleTile
  jp CopyData

INCLUDE "memory.asm"
INCLUDE "gfx.asm"
INCLUDE "gfx/4.palettes.asm"
INCLUDE "variants/hardcoded-slide-consecutive.asm"
INCLUDE "variants/hardcoded-slide-random.asm"
INCLUDE "variants/pop-slide-consecutive.asm"
INCLUDE "variants/pop-slide-random.asm"

; -------------------------------------------------------------------------------
SECTION "Tilesets - frame 1-4", ROMX, BANK[$01]

ALIGN 4 ; Align to 16-bytes boundaries, for HDMA transfer
GrayscaleTile:
INCBIN "gfx/grayscale.2bpp"
  .end

Attrmap:
REPT 18
  db $00, $01, $02, $03, $04, $05, $06, $07, $00, $01, $02, $03, $04, $05, $06, $07, $00, $01, $02, $03
ENDR
  .end

; -------------------------------------------------------------------------------
SECTION "WRAM Stack", WRAM0[$CE00]

; Bottom of WRAM is used as the stack
wStack::
  ds $CFFF - @ + 1

; Init puts the SP here
DEF wStackTop EQU $CFFF

; -------------------------------------------------------------------------------
SECTION "HRAM", HRAM[$FF80]

; Number of vertical interrupts that occured
hVICount: ds 1

; Original address of the stack pointer (for popslide)
hStackPointer: ds 2
