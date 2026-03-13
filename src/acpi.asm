; src/acpi.asm — Full ACPI 2.0 tables for Windows/macOS boot

%define ACPI_RSDP_ADDR   0x000F2000
%define ACPI_RSDT_ADDR   0x000F2400
%define ACPI_XSDT_ADDR   0x000F2800
%define ACPI_FADT_ADDR   0x000F2C00
%define ACPI_MADT_ADDR   0x000F3000
%define ACPI_HPET_ADDR   0x000F3400
%define ACPI_MCFG_ADDR   0x000F3800
%define ACPI_SSDT_ADDR   0x000F3C00

; ACPI Table Signatures
%define RSDP_SIG  'RSDP'
%define RSDT_SIG  'RSDT'
%define XSDT_SIG  'XSDT'
%define FADT_SIG  'FACP'
%define MADT_SIG  'APIC'
%define HPET_SIG  'HPET'
%define MCFG_SIG  'MCFG'
%define SSDT_SIG  'SSDT'

; ── ACPI Initialization ───────────────────────────
acpi_init:
    push ax
    push cx
    push di
    push es
    
    POST 0x20
    
    ; Build RSDP
    mov ax, 0xF200
    mov es, ax
    xor di, di
    call build_rsdp
    
    POST 0x21
    
    ; Build RSDT
    mov ax, 0xF240
    mov es, ax
    xor di, di
    call build_rsdt
    
    POST 0x22
    
    ; Build XSDT
    mov ax, 0xF280
    mov es, ax
    xor di, di
    call build_xsdt
    
    POST 0x23
    
    ; Build FADT
    mov ax, 0xF2C0
    mov es, ax
    xor di, di
    call build_fadt
    
    POST 0x24
    
    ; Build MADT
    mov ax, 0xF300
    mov es, ax
    xor di, di
    call build_madt
    
    POST 0x25
    
    ; Build HPET
    mov ax, 0xF340
    mov es, ax
    xor di, di
    call build_hpet
    
    POST 0x26
    
    ; Build MCFG
    mov ax, 0xF380
    mov es, ax
    xor di, di
    call build_mcfg
    
    POST 0x27
    
    ; Build SSDT (DSDT pointer)
    mov ax, 0xF3C0
    mov es, ax
    xor di, di
    call build_ssdt
    
    POST 0x28
    
    pop es
    pop di
    pop cx
    pop ax
    ret

; ── Build RSDP ──────────────────────────────────
build_rsdp:
    ; Signature "RSDP"
    mov dword [es:di+0x00], 0x20535052  ; 'RSP '
    mov dword [es:di+0x04], 0x20202054  ; 'T   '
    
    ; Revision (2 for ACPI 2.0)
    mov byte [es:di+0x08], 0x02
    
    ; OEM ID
    mov dword [es:di+0x09], 0x2058594E  ; 'NYX '
    mov word  [es:di+0x0D], 0x2020      ; '  '
    
    ; Creator ID
    mov dword [es:di+0x11], 0x2058594E  ; 'NYX '
    
    ; Creator Revision
    mov dword [es:di+0x15], 0x00010000
    
    ; RSDT Address
    mov dword [es:di+0x10], ACPI_RSDT_ADDR
    
    ; Length (36 for ACPI 2.0 RSDP)
    mov dword [es:di+0x14], 0x00000024
    
    ; XSDT Address (64-bit)
    mov dword [es:di+0x18], ACPI_XSDT_ADDR
    mov dword [es:di+0x1C], 0x00000000
    
    ; Extended Checksum (bytes 0-31)
    push di
    xor ax, ax
    mov cx, 32
.checksum_rsdp:
    add al, [es:di]
    inc di
    loop .checksum_rsdp
    neg al
    pop di
    mov [es:di+0x10], al
    
    ; Total checksum (bytes 0-35)
    push di
    add di, 32
    xor ah, ah
    mov cx, 4
.checksum_rsdp2:
    add ah, [es:di]
    inc di
    loop .checksum_rsdp2
    neg ah
    pop di
    mov [es:di+0x14], ah
    
    ret

; ── Build RSDT ──────────────────────────────────
build_rsdt:
    ; Signature "RSDT"
    mov dword [es:di+0x00], RSDT_SIG
    
    ; Length (will be filled)
    mov word [es:di+0x04], 0x0000
    mov word [es:di+0x06], 0x0000
    
    ; Revision (1)
    mov byte [es:di+0x08], 0x01
    
    ; OEM ID
    mov dword [es:di+0x09], 0x2058594E
    mov word  [es:di+0x0D], 0x2020
    
    ; OEM Table ID
    mov dword [es:di+0x0F], 0x52534454  ; 'RSDT'
    mov word  [es:di+0x13], 0x0000
    
    ; OEM Revision
    mov dword [es:di+0x15], 0x00010000
    
    ; Creator ID
    mov dword [es:di+0x19], 0x2058594E
    
    ; Creator Revision
    mov dword [es:di+0x1D], 0x00010000
    
    ; Table entries (pointers to other tables)
    ; FADT
    mov dword [es:di+0x24], ACPI_FADT_ADDR
    ; MADT
    mov dword [es:di+0x28], ACPI_MADT_ADDR
    ; HPET
    mov dword [es:di+0x2C], ACPI_HPET_ADDR
    ; MCFG
    mov dword [es:di+0x30], ACPI_MCFG_ADDR
    ; SSDT
    mov dword [es:di+0x34], ACPI_SSDT_ADDR
    
    ; Calculate and set length
    mov word [es:di+0x04], 0x0038    ; 56 bytes
    mov word [es:di+0x06], 0x0000
    
    ; Checksum
    push di
    xor ax, ax
    mov cx, 56
.checksum_rsdt:
    add al, [es:di]
    inc di
    loop .checksum_rsdt
    neg al
    pop di
    mov [es:di+0x10], al
    
    ret

; ── Build XSDT ──────────────────────────────────
build_xsdt:
    ; Signature "XSDT"
    mov dword [es:di+0x00], XSDT_SIG
    
    ; Length
    mov word [es:di+0x04], 0x0000
    mov word [es:di+0x06], 0x0000
    
    ; Revision (1)
    mov byte [es:di+0x08], 0x01
    
    ; OEM ID
    mov dword [es:di+0x09], 0x2058594E
    mov word  [es:di+0x0D], 0x2020
    
    ; OEM Table ID
    mov dword [es:di+0x0F], 0x58534454  ; 'XSDT'
    mov word  [es:di+0x13], 0x0000
    
    ; OEM Revision
    mov dword [es:di+0x15], 0x00010000
    
    ; Creator ID
    mov dword [es:di+0x19], 0x2058594E
    
    ; Creator Revision
    mov dword [es:di+0x1D], 0x00010000
    
    ; Table entries (64-bit pointers)
    ; FADT
    mov dword [es:di+0x24], ACPI_FADT_ADDR
    mov dword [es:di+0x28], 0x00000000
    ; MADT
    mov dword [es:di+0x2C], ACPI_MADT_ADDR
    mov dword [es:di+0x30], 0x00000000
    ; HPET
    mov dword [es:di+0x34], ACPI_HPET_ADDR
    mov dword [es:di+0x38], 0x00000000
    ; MCFG
    mov dword [es:di+0x3C], ACPI_MCFG_ADDR
    mov dword [es:di+0x40], 0x00000000
    ; SSDT
    mov dword [es:di+0x44], ACPI_SSDT_ADDR
    mov dword [es:di+0x48], 0x00000000
    
    ; Length
    mov word [es:di+0x04], 0x004C    ; 76 bytes
    mov word [es:di+0x06], 0x0000
    
    ; Checksum
    push di
    xor ax, ax
    mov cx, 76
.checksum_xsdt:
    add al, [es:di]
    inc di
    loop .checksum_xsdt
    neg al
    pop di
    mov [es:di+0x10], al
    
    ret

; ── Build FADT ──────────────────────────────────
build_fadt:
    ; Signature "FACP"
    mov dword [es:di+0x00], FADT_SIG
    
    ; Length
    mov dword [es:di+0x04], 0x00000084   ; 132 bytes
    
    ; Revision (3 for ACPI 2.0)
    mov byte [es:di+0x08], 0x03
    
    ; Checksum
    mov byte [es:di+0x09], 0x00
    
    ; OEM ID
    mov dword [es:di+0x0A], 0x2058594E
    mov word  [es:di+0x0E], 0x2020
    
    ; OEM Table ID
    mov dword [es:di+0x10], 0x46414350  ; 'FACP'
    mov word  [es:di+0x14], 0x0000
    
    ; OEM Revision
    mov dword [es:di+0x16], 0x00010000
    
    ; Creator ID
    mov dword [es:di+0x1A], 0x2058594E
    
    ; Creator Revision
    mov dword [es:di+0x1E], 0x00010000
    
    ; FACS address (32-bit)
    mov dword [es:di+0x24], 0x00000000
    
    ; DSDT address (32-bit) - point to SSDT
    mov dword [es:di+0x28], ACPI_SSDT_ADDR
    
    ; Reserved / INT_MODEL / Preferred_PM_Profile
    db 0x00, 0x00, 0x00
    
    ; SCI interrupt
    dw 0x0009
    
    ; SMI command port
    dw 0x0000
    
    ; ACPI enable
    db 0x00
    
    ; ACPI disable
    db 0x00
    
    ; S4BIOS_REQ
    db 0x00
    
    ; PSTATE control
    db 0x00
    
    ; PM1a event block
    dw 0x0000
    dw 0x0000
    
    ; PM1b event block
    dw 0x0000
    dw 0x0000
    
    ; PM1a control block
    dw 0x0000
    dw 0x0000
    
    ; PM1b control block
    dw 0x0000
    dw 0x0000
    
    ; PM2 control block
    dw 0x0000
    dw 0x0000
    
    ; PM timer block
    dw 0x0000
    dw 0x0000
    
    ; GPE0 block
    dw 0x0000
    dw 0x0000
    
    ; GPE1 block
    dw 0x0000
    dw 0x0000
    
    ; PM1 event length
    db 0x00
    
    ; PM1 control length
    db 0x00
    
    ; PM2 control length
    db 0x00
    
    ; PM timer length
    db 0x00
    
    ; GPE0 length
    db 0x00
    
    ; GPE1 length
    db 0x00
    
    ; GPE1 base
    db 0x00
    
    ; C-state control
    db 0x00
    
    ; P-level 2
    dw 0x0000
    
    ; P-level 3
    dw 0x0000
    
    ; P-state control
    dw 0x0000
    
    ; Reserved
    dw 0x0000
    
    ; Flags
    db 0x00, 0x00, 0x00, 0x00
    
    ; Reset register
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    
    ; Reset value
    db 0x00
    
    ; Reserved
    db 0x00, 0x00, 0x00
    
    ; X-FACS address (64-bit)
    mov dword [es:di+0x74], 0x00000000
    mov dword [es:di+0x78], 0x00000000
    
    ; X-DSDT address (64-bit)
    mov dword [es:di+0x7C], ACPI_SSDT_ADDR
    mov dword [es:di+0x80], 0x00000000
    
    ; Checksum
    push di
    xor ax, ax
    mov cx, 132
.checksum_fadt:
    add al, [es:di]
    inc di
    loop .checksum_fadt
    neg al
    pop di
    mov [es:di+0x09], al
    
    ret

; ── Build MADT ──────────────────────────────────
build_madt:
    ; Signature "APIC"
    mov dword [es:di+0x00], MADT_SIG
    
    ; Length
    mov dword [es:di+0x04], 0x0000003C   ; 60 bytes
    
    ; Revision
    mov byte [es:di+0x08], 0x01
    
    ; Checksum
    mov byte [es:di+0x09], 0x00
    
    ; OEM ID
    mov dword [es:di+0x0A], 0x2058594E
    mov word  [es:di+0x0E], 0x2020
    
    ; OEM Table ID
    mov dword [es:di+0x10], 0x414D4943  ; 'AMIC'
    mov word  [es:di+0x14], 0x0000
    
    ; OEM Revision
    mov dword [es:di+0x16], 0x00010000
    
    ; Creator ID
    mov dword [es:di+0x1A], 0x2058594E
    
    ; Creator Revision
    mov dword [es:di+0x1E], 0x00010000
    
    ; Local APIC address
    mov dword [es:di+0x24], 0xFEE00000
    
    ; Flags (LAPIC available)
    mov dword [es:di+0x28], 0x00000001
    
    ; LAPIC entry (type 0)
    db 0x00                ; Type: Local APIC
    db 0x08                ; Length
    db 0x00                ; ACPI processor ID
    db 0x01                ; APIC ID
    dd 0x00000000          ; Flags (enabled)
    
    ; IOAPIC entry (type 1)
    db 0x01                ; Type: IO APIC
    db 0x0C                ; Length
    db 0x00                ; IOAPIC ID
    db 0x00                ; Reserved
    dd 0xFEC00000          ; IOAPIC address
    dd 0x00000020          ; Global system interrupt base
    
    ; Interrupt source override (type 2)
    db 0x02                ; Type
    db 0x0A                ; Length
    db 0x00                ; Bus
    db 0x00                ; Source (IRQ 0)
    dd 0x00000002          ; Global interrupt (IRQ 2)
    db 0x00                ; Flags (edge, high)
    db 0x00
    
    ; Checksum
    push di
    xor ax, ax
    mov cx, 60
.checksum_madt:
    add al, [es:di]
    inc di
    loop .checksum_madt
    neg al
    pop di
    mov [es:di+0x09], al
    
    ret

; ── Build HPET ──────────────────────────────────
build_hpet:
    ; Signature "HPET"
    mov dword [es:di+0x00], HPET_SIG
    
    ; Length
    mov dword [es:di+0x04], 0x0000002C   ; 44 bytes
    
    ; Revision
    mov byte [es:di+0x08], 0x01
    
    ; Checksum
    mov byte [es:di+0x09], 0x00
    
    ; OEM ID
    mov dword [es:di+0x0A], 0x2058594E
    mov word  [es:di+0x0E], 0x2020
    
    ; OEM Table ID
    mov dword [es:di+0x10], 0x48504554  ; 'HPET'
    mov word  [es:di+0x14], 0x0000
    
    ; OEM Revision
    mov dword [es:di+0x16], 0x00010000
    
    ; Creator ID
    mov dword [es:di+0x1A], 0x2058594E
    
    ; Creator Revision
    mov dword [es:di+0x1E], 0x00010000
    
    ; HPET number
    dd 0x00000000
    
    ; Base address
    dd 0xFED00000
    db 0x00, 0x00, 0x00
    
    ; HPET flags
    db 0x01
    
    ; Main counter clock
    dd 0x001A89C0       ; 0x186A0 = 100MHz / 10ns period
    
    ; Checksum
    push di
    xor ax, ax
    mov cx, 44
.checksum_hpet:
    add al, [es:di]
    inc di
    loop .checksum_hpet
    neg al
    pop di
    mov [es:di+0x09], al
    
    ret

; ── Build MCFG ──────────────────────────────────
build_mcfg:
    ; Signature "MCFG"
    mov dword [es:di+0x00], MCFG_SIG
    
    ; Length
    mov dword [es:di+0x04], 0x0000001C   ; 28 bytes
    
    ; Revision
    mov byte [es:di+0x08], 0x01
    
    ; Checksum
    mov byte [es:di+0x09], 0x00
    
    ; OEM ID
    mov dword [es:di+0x0A], 0x2058594E
    mov word  [es:di+0x0E], 0x2020
    
    ; OEM Table ID
    mov dword [es:di+0x10], 0x4D434647  ; 'MCFG'
    mov word  [es:di+0x14], 0x0000
    
    ; OEM Revision
    mov dword [es:di+0x16], 0x00010000
    
    ; Creator ID
    mov dword [es:di+0x1A], 0x2058594E
    
    ; Creator Revision
    mov dword [es:di+0x1E], 0x00010000
    
    ; Reserved
    dd 0x00000000
    
    ; Configuration entry (64-bit)
    dd 0x00000000          ; Base address (will be set by hypervisor)
    dw 0x0000             ; PCI segment group
    db 0x00                ; Start bus
    db 0xFF                ; End bus
    dd 0x00000000         ; Reserved
    
    ; Checksum
    push di
    xor ax, ax
    mov cx, 28
.checksum_mcfg:
    add al, [es:di]
    inc di
    loop .checksum_mcfg
    neg al
    pop di
    mov [es:di+0x09], al
    
    ret

; ── Build SSDT/DSDT ──────────────────────────────
build_ssdt:
    ; Signature "SSDT"
    mov dword [es:di+0x00], SSDT_SIG
    
    ; Length
    mov dword [es:di+0x04], 0x00000018   ; 24 bytes
    
    ; Revision
    mov byte [es:di+0x08], 0x01
    
    ; Checksum
    mov byte [es:di+0x09], 0x00
    
    ; OEM ID
    mov dword [es:di+0x0A], 0x2058594E
    mov word  [es:di+0x0E], 0x2020
    
    ; OEM Table ID
    mov dword [es:di+0x10], 0x44534454  ; 'DSDT'
    mov word  [es:di+0x14], 0x0000
    
    ; OEM Revision
    mov dword [es:di+0x16], 0x00010000
    
    ; Creator ID
    mov dword [es:di+0x1A], 0x2058594E
    
    ; Creator Revision
    mov dword [es:di+0x1E], 0x00010000
    
    ; Checksum
    push di
    xor ax, ax
    mov cx, 24
.checksum_ssdt:
    add al, [es:di]
    inc di
    loop .checksum_ssdt
    neg al
    pop di
    mov [es:di+0x09], al
    
    ret
