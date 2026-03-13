; src/boot.asm — Boot device manager

%define BOOT_DRIVE_HD    0x80
%define BOOT_DRIVE_CDROM 0xE0

boot_sequence:
    ; Try boot devices in order:
    ; 1. CD-ROM
    ; 2. Hard disk
    ; 3. Network (PXE stub)

    POST 0x19
    mov si, str_boot_seq
    call serial_puts

    ; Try CD-ROM first
    POST 0x20
    mov si, str_try_cdrom
    call serial_puts
    call cdrom_boot
    jnc .done

    ; Try hard disk
    POST 0x21
    mov si, str_try_hd
    call serial_puts
    call hd_boot
    jnc .done

    ; Nothing worked
    POST 0x22
    mov si, str_no_boot
    call serial_puts
    stc
    ret

.done:
    clc
    ret

hd_boot:
    ; Read MBR from hard disk 0x80
    POST 0x40
    push ds
    push es
    xor ax, ax
    mov ds, ax
    mov es, ax
    ; DAP for sector 0
    mov word [0x7000+0],  16   ; size
    mov word [0x7000+2],   1   ; 1 sector
    mov word [0x7000+4], 0x7C00 ; buffer
    mov word [0x7000+6],  0    ; segment
    mov dword [0x7000+8], 0    ; LBA 0
    mov dword [0x7000+12], 0

    mov ah, 0x42
    mov dl, BOOT_DRIVE_HD
    mov si, 0x7000
    int 0x13
    jc .fail_int13

    ; Check MBR signature
    cmp word [0x7DFE], 0xAA55
    jne .fail_sig

    POST 0x41
    mov si, str_mbr_ok
    call serial_puts

    ; Set DL to boot drive
    mov dl, BOOT_DRIVE_HD
    pop es
    pop ds
    xor ax, ax
    mov ds, ax
    mov es, ax
    ; Jump to MBR
    jmp 0x0000:0x7C00

.fail_int13:
    mov si, str_hd_int13_fail
    call serial_puts
    xor al, al
    call serial_puthex16      ; prints AH in high byte
    mov si, str_log_nl
    call serial_puts
    stc
    pop es
    pop ds
    ret

.fail_sig:
    mov si, str_hd_sig_fail
    call serial_puts
    mov ax, [0x7DFE]
    call serial_puthex16
    mov si, str_hd_sig_mid
    call serial_puts
    mov ax, [0x7C00]
    call serial_puthex16
    mov si, str_log_nl
    call serial_puts
    stc
    pop es
    pop ds
    ret

str_boot_seq:  db 'Boot sequence starting...', 13, 10, 0
str_try_cdrom: db 'Trying CD-ROM...', 13, 10, 0
str_try_hd:    db 'Trying hard disk...', 13, 10, 0
str_mbr_ok:    db 'MBR loaded OK', 13, 10, 0
str_no_boot:   db 'No bootable device!', 13, 10, 0
str_hd_int13_fail: db 'HD INT13 fail AH=', 0
str_hd_sig_fail:   db 'HD bad sig=', 0
str_hd_sig_mid:    db ' first=', 0
