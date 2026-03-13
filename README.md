# Nyx BIOS

Minimal x86 real-mode BIOS ROM intended for use with emulators like QEMU.

## Requirements

- `nasm`
- Optional: `qemu-system-i386` (for `make run`)

## Build

```sh
make
```

Outputs:
- `build/bios.bin` (primary artifact)
- `bios.bin` (convenience copy)

The build runs a ROM sanity check that validates:
- exact ROM size (default: 128KiB)
- reset vector location and far-jump segment (`F000`)

## Check

```sh
make check
```

## Run (QEMU)

```sh
make run
```

Serial output is routed to your terminal via `-serial stdio`.

## HDD Boot Smoke Test (QEMU)

Creates a tiny raw HDD image with a test MBR, then boots it via Nyx:

```sh
make run-hdd
```
