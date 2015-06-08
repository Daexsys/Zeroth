
%define fix define

org 0

signature:
    dw 0x05E9

start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov si, strings.hello
    call printString
    
    cli
    hlt
    jmp $-2

printString:
    push si
    push ax
    mov ah, 0x0E
    
    .next:
    lodsb
    cmp al, 0
    jz .end
    int 0x10
    jmp .next
    
    .end:
    pop ax
    pop si
    ret
    
strings:
    .hello      db 0x0D, 0x0A, "Kernel successfully loaded.", 0
    