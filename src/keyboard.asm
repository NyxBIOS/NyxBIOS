; src/keyboard.asm — PS/2 keyboard + INT 0x16

%define KBD_DATA    0x60
%define KBD_STATUS  0x64
%define KBD_CMD     0x64

; BIOS keyboard buffer in the BDA (we keep pointers as absolute addresses with DS=0).
; - Head pointer at 0x041A
; - Tail pointer at 0x041C
; - Buffer is 32 bytes at 0x041E..0x043E (16 entries of 2 bytes: ASCII, scancode)
%define KBD_BUF_START 0x041E
%define KBD_BUF_END   0x043E
%define KBD_BUF_HEAD  0x041A
%define KBD_BUF_TAIL  0x041C

kbd_init:
    push ax
    push cx

    ; Flush keyboard buffer
    mov cx, 0xFFFF
.flush:
    in al, KBD_STATUS
    test al, 0x01
    jz .flush_done
    in al, KBD_DATA
    loop .flush
.flush_done:
    ; Keep init minimal and tolerant (avoid hangs on missing/quirky controllers).
    ; Enable keyboard interface (0xAE) and enable scanning (0xF4).
    mov al, 0xAE
    call kbd_send_cmd
    mov al, 0xF4
    out KBD_DATA, al
    call kbd_wait_data

    ; Init keyboard buffer
    mov word [KBD_BUF_HEAD], KBD_BUF_START
    mov word [KBD_BUF_TAIL], KBD_BUF_START

    pop cx
    pop ax
    ret

kbd_send_cmd:
    ; AL = command
    push ax
    push cx
    mov cx, 0x1000
.wait:
    in al, KBD_STATUS
    test al, 0x02
    jz .send
    loop .wait
.send:
    pop cx
    pop ax
    out KBD_CMD, al
    ret

kbd_wait_data:
    push cx
    mov cx, 0xFFFF
.wait:
    in al, KBD_STATUS
    test al, 0x01
    jnz .got
    loop .wait
.got:
    in al, KBD_DATA
    pop cx
    ret

kbd_a20_enable:
    push ax
    push cx
    ; Wait for controller ready
    mov cx, 0x1000
.wait1:
    in al, KBD_STATUS
    test al, 0x02
    jz .ok1
    loop .wait1
.ok1:
    ; Write output port command
    mov al, 0xD1
    out KBD_CMD, al
    mov cx, 0x1000
.wait2:
    in al, KBD_STATUS
    test al, 0x02
    jz .ok2
    loop .wait2
.ok2:
    ; Enable A20
    mov al, 0xDF
    out KBD_DATA, al
    mov cx, 0x1000
.wait3:
    in al, KBD_STATUS
    test al, 0x02
    jz .ok3
    loop .wait3
.ok3:
    pop cx
    pop ax
    ret

; ── IRQ1 keyboard handler ───────────────────────
irq1_keyboard:
    push ax
    push bx
    push ds
    xor ax, ax
    mov ds, ax

    ; Read scancode
    in al, KBD_DATA

    ; Only process key-down (bit 7 clear) for set 1.
    test al, 0x80
    jnz .done

    ; Convert to ASCII (basic set 1 only)
    mov ah, al              ; preserve scancode
    call scancode_to_ascii
    test al, al
    jz .done

    ; Add to keyboard buffer (word: AL=ASCII, AH=scancode)
    mov bx, [KBD_BUF_TAIL]
    mov [bx], ax
    add bx, 2
    cmp bx, KBD_BUF_END
    jl .no_wrap
    mov bx, KBD_BUF_START
.no_wrap:
    cmp bx, [KBD_BUF_HEAD]
    je .full                ; buffer full
    mov [KBD_BUF_TAIL], bx
.full:

.done:
    call pic_eoi_master
    pop ds
    pop bx
    pop ax
    iret

scancode_to_ascii:
    ; Basic scancode set 1 → ASCII
    cmp al, 0x3A
    jge .special
    mov bx, scancode_table
    xlat
    ret
.special:
    xor al, al
    ret

scancode_table:
    db 0x00,0x1B,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38
    db 0x39,0x30,0x2D,0x3D,0x08,0x09,0x71,0x77,0x65,0x72
    db 0x74,0x79,0x75,0x69,0x6F,0x70,0x5B,0x5D,0x0D,0x00
    db 0x61,0x73,0x64,0x66,0x67,0x68,0x6A,0x6B,0x6C,0x3B
    times 10 db 0x00

; ── INT 0x16 handler ────────────────────────────
int16_handler:
    cmp ah, 0x00
    je .read_key
    cmp ah, 0x01
    je .check_key
    cmp ah, 0x02
    je .get_flags
    cmp ah, 0x10
    je .read_key_ext
    cmp ah, 0x11
    je .check_key_ext
    cmp ah, 0x12
    je .get_flags_ext
    iret

.read_key:
    ; Wait for keypress
    sti
.rk_wait:
    mov ax, [KBD_BUF_HEAD]
    cmp ax, [KBD_BUF_TAIL]
    je .rk_wait
    ; Get from buffer
    mov bx, [KBD_BUF_HEAD]
    mov ax, [bx]
    add bx, 2
    cmp bx, KBD_BUF_END
    jl .rk_no_wrap
    mov bx, KBD_BUF_START
.rk_no_wrap:
    mov [KBD_BUF_HEAD], bx
    iret

.check_key:
    ; ZF=1 if no key
    mov ax, [KBD_BUF_HEAD]
    cmp ax, [KBD_BUF_TAIL]
    je .no_key
    mov bx, [KBD_BUF_HEAD]
    mov ax, [bx]
    or ax, ax               ; clear ZF
    iret
.no_key:
    xor ax, ax
    cmp ax, ax              ; ZF=1
    iret

.get_flags:
    mov al, [BDA_KBDFLAG]
    iret

.read_key_ext:
    jmp .read_key

.check_key_ext:
    jmp .check_key

.get_flags_ext:
    mov ax, [BDA_KBDFLAG]
    iret
