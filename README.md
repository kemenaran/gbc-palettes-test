How much Game Boy Color palettes can be updated during a single scanline?

This code tests differents methods to find out.

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

1. Install rgbds >= 0.6
2. `make`

Running
=======

When running the resulting ROM, you will see a grayscale pattern. After 0.5s, the code to update palettes will run during scanline 0, and attempt to update as much palettes as possible.

Keep an eye on the "Color Palettes" tool of your favorite GBC debugger to see how many grayscale colors were successfully replaced by actual colors during a single scanline.

Methods
=======

- Hardcoded vs popslide

  _#TODO_
- Consecutive access vs random access

  _#TODO_

Results
=======

_Note: all this code assumes that we want hand-picked arbitrary colors to be copied._

_If a sequential computer-generated pattern is fine with you, it can be made even faster, and more colors can be copied per scanline. But it doesn't have a lot of practical use, so we'll stick with hand-picked colors here._

_#TODO_
