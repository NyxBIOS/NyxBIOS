; src/boot_menu.asm — Boot menu with timeout and Nyx branding

%define BOOT_MENU_TIMEOUT 5       ; Default timeout in seconds
%define BOOT_MENU_ADDR   0xB8000  ; Video memory for text mode

; Boot device types
%define BOOT_DEVICE_HDD  0x80
%define BOOT_DEVICE_CD   0xE0
%define BOOT_DEVICE_NET  0x81

; ── Boot Menu Variables ──────────────────────────
NYX_BOOT_TIMEOUT:
    db BOOT_MENU_TIMEOUT
NYX_BOOT_DEFAULT:
    db 0x00        ; 0=HDD, 1=CD-ROM
NYX_BOOT_LAST:
    db 0x00        ; Last booted device

; ── Boot Menu Entry Point ───────────────────────
boot_menu:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    POST 0x50
    
    ; Check if menu key (F8 or Esc) was pressed
    ; For simplicity, we'll always show the menu
    
    ; Clear screen
    call boot_menu_clear
    
    ; Draw Nyx banner
    call boot_menu_banner
    
    ; Draw options
    call boot_menu_options
    
    ; Wait for input or timeout
    call boot_menu_wait
    
    POST 0x51
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ── Clear Menu Screen ───────────────────────────
boot_menu_clear:
    push ax
    push cx
    push di
    
    ; Set video to 80x25 color text mode
    mov ah, 0x00
    mov al, 0x03    ; 80x25 color text
    int 0x10
    
    ; Clear screen
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 80 * 25
.clear_loop:
    mov word [es:di], 0x0F00    ; Black background, white text
    add di, 2
    loop .clear_loop
    
    pop di
    pop cx
    pop ax
    ret

; ── Draw Nyx Banner ──────────────────────────────
boot_menu_banner:
    push si
    push di
    push cx
    
    ; Position banner at top
    mov di, (80 * 1 + 20) * 2
    
    ; Draw box
    mov si, str_menu_header
    mov cx, 40
.header_loop:
    lodsb
    test al, al
    jz .header_done
    mov [es:di], al
    inc di
    mov byte [es:di], 0x1F    ; Light cyan on blue
    inc di
    loop .header_loop
.header_done:
    
    ; Draw version
    mov di, (80 * 2 + 25) * 2
    mov si, str_menu_version
.version_loop:
    lodsb
    test al, al
    jz .version_done
    mov [es:di], al
    inc di
    mov byte [es:di], 0x1F
    inc di
    loop .version_loop
.version_done:
    
    pop cx
    pop di
    pop si
    ret

; ── Draw Boot Options ────────────────────────────
boot_menu_options:
    push si
    push di
    push cx
    
    ; Option 1: Boot from HDD
    mov di, (80 * 5 + 25) * 2
    mov si, str_menu_hdd
    mov cx, 30
    call boot_menu_draw_option
    
    ; Option 2: Boot from CD-ROM
    mov di, (80 * 7 + 25) * 2
    mov si, str_menu_cd
    mov cx, 30
    call boot_menu_draw_option
    
    ; Option 3: Boot from Network (PXE)
    mov di, (80 * 9 + 25) * 2
    mov si, str_menu_net
    mov cx, 30
    call boot_menu_draw_option
    
    ; Help text
    mov di, (80 * 12 + 15) * 2
    mov si, str_menu_help
    call boot_menu_draw_string
    
    pop cx
    pop di
    pop si
    ret

boot_menu_draw_option:
    ; Draw "[1] " prefix
    mov [es:di], byte '['
    inc di
    mov [es:di], byte 0x1F
    inc di
    mov al, [si-1]
    ; This won't work - fix it
    ; Instead just draw the string
.draw_string:
    lodsb
    test al, al
    jz .done
    mov [es:di], al
    inc di
    mov byte [es:di], 0x1F
    inc di
    loop .draw_string
.done:
    ret

boot_menu_draw_string:
.draw_loop:
    lodsb
    test al, al
    jz .done
    mov [es:di], al
    inc di
    mov byte [es:di], 0x17    ; Light gray on blue
    inc di
    jmp .draw_loop
.done:
    ret

; ── Wait for Input or Timeout ───────────────────
boot_menu_wait:
    push ax
    push bx
    push cx
    push dx
    
    ; Get timeout value
    mov bl, [NYX_BOOT_TIMEOUT]
    xor bh, bh
    
.wait_loop:
    ; Check for key press
    mov ah, 0x01
    int 0x16
    jnz .key_pressed
    
    ; Decrement counter (approx 1 second)
    ; Use PIT for accurate timing
    mov ah, 0x00
    int 0x1A
    mov dx, cx      ; Save current tick count
    
.timeout_wait:
    int 0x1A
    sub cx, dx
    cmp cx, 18      ; ~1 second (18.2 Hz)
    jb .timeout_wait
    
    dec bx
    jnz .wait_loop
    
    ; Timeout - boot default
    jmp .boot_default
    
.key_pressed:
    ; Read the key
    mov ah, 0x00
    int 0x16
    
    ; Check for 1, 2, 3
    cmp al, '1'
    je .boot_hdd
    cmp al, '2'
    je .boot_cd
    cmp al, '3'
    je .boot_net
    cmp al, 0x0D    ; Enter
    je .boot_default
    cmp al, 0x1B    ; Escape
    je .boot_default
    
    ; Other key - continue waiting
    jmp .wait_loop
    
.boot_hdd:
    mov byte [NYX_BOOT_LAST], 0x00
    mov dl, BOOT_DEVICE_HDD
    jmp .boot_done
    
.boot_cd:
    mov byte [NYX_BOOT_LAST], 0x01
    mov dl, BOOT_DEVICE_CD
    jmp .boot_done
    
.boot_net:
    mov byte [NYX_BOOT_LAST], 0x02
    mov dl, BOOT_DEVICE_NET
    jmp .boot_done
    
.boot_default:
    ; Default to HDD
    xor dl, dl
    mov dl, BOOT_DEVICE_HDD
    
.boot_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ── Nyx Custom INT 0x77 — Hypervisor Communication ─
int77_handler:
    ; Nyx extension: hypervisor↔BIOS communication
    ; AH = function:
    ;  0x00: Get BIOS version string
    ;  0x01: Get boot device
    ;  0x02: Set boot device
    ;  0x03: Get memory map
    ;  0x04: Get ACPI tables
    ;  0x05: Shutdown/reset control
    
    cmp ah, 0x00
    je .get_version
    cmp ah, 0x01
    je .get_bootdev
    cmp ah, 0x02
    je .set_bootdev
    cmp ah, 0x03
    je .get_memmap
    cmp ah, 0x04
    je .get_acpi
    cmp ah, 0x05
    je .control
    
    ; Unknown function
    mov al, 0xFF
    stc
    iret

.get_version:
    ; Return pointer to version string
    mov si, str_banner
    xor al, al
    iret

.get_bootdev:
    ; Return last booted device
    mov al, [NYX_BOOT_LAST]
    xor ah, ah
    iret

.set_bootdev:
    ; AL = boot device
    mov [NYX_BOOT_LAST], al
    xor al, al
    iret

.get_memmap:
    ; Return E820 table address
    mov ax, 0x5000
    xor bx, bx
    xor al, al
    iret

.get_acpi:
    ; Return RSDP address
    mov ax, 0xF200
    xor bx, bx
    xor al, al
    iret

.control:
    ; AH = control function:
    ;  0x00 = shutdown, 0x01 = warm reset, 0x02 = cold reset
    cmp al, 0x00
    je .shutdown
    cmp al, 0x01
    je .warm_reset
    cmp al, 0x02
    je .cold_reset
    
    stc
    iret

.shutdown:
    ; Signal hypervisor for shutdown
    ; Typically done via port 0xB0 or similar
    mov al, 0x00
    out 0xB0, al
.halt:
    cli
    hlt
    jmp .halt

.warm_reset:
    ; Jump to BIOS entry
    jmp 0xFFFF:0x0000

.cold_reset:
    ; Use keyboard controller for reset
    mov al, 0xFE
    out 0x64, al
    jmp .halt

; ── Boot Menu Strings ────────────────────────────
str_menu_header:
    db '=======================================', 0
str_menu_version:
    db '   NYX BIOS v1.0 - Boot Menu    ', 0
str_menu_hdd:
    db '[1] Boot from Hard Disk         ', 0
str_menu_cd:
    db '[2] Boot from CD-ROM            ', 0
str_menu_net:
    db '[3] Boot from Network (PXE)     ', 0
str_menu_help:
    db 'Press 1-3 or Enter to boot. Default: HDD', 0
str_menu_countdown:
    db 'Booting in  ', 0

; ── Nyx Branding Screen ──────────────────────────
nyx_brand_screen:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Set video mode
    mov ah, 0x00
    mov al, 0x13    ; 320x200 256 color
    int 0x10
    
    ; Draw Nyx logo (simple graphical representation)
    ; For now, just draw a nice gradient
    xor di, di
    mov dx, 200
.gradient_loop:
    mov cx, 320
    mov ah, byte [di]
    add ah, 1
    and ah, 0x3F
    mov al, ah
.inner_loop:
    mov [es:di], al
    inc di
    loop .inner_loop
    dec dx
    jnz .gradient_loop
    
    ; Wait for key
    xor ah, ah
    int 0x16
    
    ; Return to text mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
