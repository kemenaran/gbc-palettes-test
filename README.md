How much Game Boy Color palettes can be updated during a single scanline?

This code tests different methods to find out.

Configuring
===========

To select a method (popslide or hardcoded slide, consecutive access or random access), uncomment the proper line at the top of `palettes-test.asm`:

```asm
SECTION "LCD Status interrupt", ROM0[$0048]
  jp ScanlineInterruptHardcodedSlideConsecutive
  jp ScanlineInterruptHardcodedSlideRandom
  jp ScanlineInterruptPopSlideConsecutive
  jp ScanlineInterruptPopSlideRandom
```

Building
========

1. Install `rgbds` >= 0.6
2. `make`

Running
=======

When running the resulting ROM, you will see a grayscale pattern. After 0.5s, the code to update palettes will run during scanline 0, and attempt to update as much palettes as possible.

Keep an eye on the "Color Palettes" tool of your favorite GBC debugger, to see how many grayscale colors were successfully replaced by actual colors during a single scanline.

Variants and tradeoffs
======================

- **Hand-picked vs programatic colors**:

  When using programmatically generated colors, it is possible to craft a sequence that can be loaded very fast (up to [31 1/2 colors per scanline](https://github.com/EmmaEwert/gameboy/tree/master/scanlines)).

  But then the pattern of colors is seemingly random, and not very useful practically.

  In this benchmark, we only consider hand-picked colors.
- **Hardcoded vs popslide**

  The fastest way to load a hand-picked color is to use an absolute operand, with the color value hardcoded in the assembly code:

  ```asm
    ld [hl], LOW($0E3F)  ; 3 cycles
    ld [hl], HIGH($0E3F) ; 3 cycles
  ```

  However, this has the downside of making the code bigger (each color requires space for encoding both the color bytes and the instruction bytes) and less flexible (it can't load external data).

  Another solution is to use a [popslide](https://www.nesdev.org/wiki/Stack#Pop_slide): relocate the stack pointer on top of the data we want to read, and use `pop` to quickly read the data in registers.

  ```asm
    pop de      ; 3 cycles
    ld [hl], e  ; 2 cycles
    ld [hl], d  ; 2 cycles
  ```

  A popslide takes 7 cycles per color (vs 6 for hardcoded operands), but is more compact and flexible.

  Both methods are benchmarked in this repo.
- **Consecutive access vs random access**

  The palette index can be automatically incremented by the hardware on each write. Copying consecutive colors take advantage of this to avoid a manual increment; that is why it is faster to copy consecutive colors than accessing colors randomly.

  However sometimes random access is needed - but each new address costs 5 cycles.

  Both accesses types are benchmarked in this repo.

  For a slightly more realistic usage, the random access benchmarks actually copy color pairs (instead of individual colors), which avoids to pay the cost of addressing for each and every color.

Results
=======

- **Hardcoded colors with consecutive access**: up to 24 colors per scanline.
- **Hardcoded colors with random access**: up to 9 color pairs (18 colors) per scanline.
- **Popslide with consecutive access**: up to 21 colors per scanline.
- **Popslide with random access**: up to 8 color pairs (16 colors) per scanline.
