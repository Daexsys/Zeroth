
%define fix define

%define _loaderSector 0x2000

org 0x7C00

start:

    ; Setup segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Setup pointer to cover free memory area below the boot sector
    mov ax, 0x50
    mov ss, ax
    mov sp, 0x7C00
    
    ; More environment initialization
    cld
    
    ; Load second stage loader from diskette using BIOS services.
    ; This OS is meant to be booted from a CD with floppy virtualization,
    ; so no drive retries should be necessary.
    mov si, hello
    call printString
    
    mov ah, 0x02
    mov al, 3
    mov ch, 0
    mov cl, 2
    mov dh, 0
    push _loaderSector
    pop es
    xor bx, bx
    int 0x13
    
    ; If second loader signature does not exist, then it was not loaded.
    cmp word [es:bx], 0x051D
    je @f
    mov si, err_
    call printString
    cli
    hlt
    jmp $-2
    @@:
    
    ; Start executing second loader
    jmp _loaderSector:2
    
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
    
hello: db 0x0D, 0x0A, "Loading second stage loader...", 0
err_:  db 0x0D, 0x0A, "***Error loading second stage loader.", 0

times 510-($-$$) nop
dw 0xAA55
