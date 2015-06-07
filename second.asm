
%define fix define

org 0

signature:
    dw 0x051D

start:
    mov ax, cs
    ;mov ax, 0x2000
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov si, strings.systeminfo
    call printString
    
getCpuFeatures:
    mov si, strings.cpufeat
    call printString
    
    ; Test for CPUID instruction
    mov si, strings.cpuid
    call printString
    
    pushfd
    pushfd
    xor dword [esp], 0x00200000
    popfd
    pushfd
    pop eax
    xor eax, dword [esp]
    popfd
    and eax, 0x00200000
    cmp eax, 0
    jz .notSupported
    mov si, strings.supported
    call printString
    
    ; Test for long mode support
    mov si, strings.longmode
    call printString
    
    mov eax, 0x80000001
    cpuid
    shr edx, 30
    jnc .notSupported
    mov si, strings.supported
    call printString
    
    jmp getFloppyGeometry
    
    .notSupported:
        mov si, strings.nsupported
        call printString
        mov si, strings.loadhalt
        call printString
        cli
        hlt
        jmp $-2
    
getFloppyGeometry:
    xor ax, ax
    mov es, ax
    mov di, ax
    mov ah, 0x08
    int 0x13
    
    mov byte [geometry.heads], dh
    push cx
    shl cl, 2
    shr cl, 2
    mov byte [geometry.sectors], cl
    pop cx
    shr cl, 6
    xchg ch, cl
    mov word [geometry.cylinders], cx
    
    ; Display CHS geometry on screen
    mov si, strings.diskgeom
    call printString
    
    mov di, strings.buffer
    
    ; Cylinders...
    mov si, strings.diskcyl
    call printString
    mov ax, cx
    call numberAsDecimal
    mov si, di
    call printString
    
    ; Heads...
    mov si, strings.diskhead
    call printString
    mov ah, 0
    mov al, dh
    call numberAsDecimal
    mov si, di
    call printString
    
    ; Sectors...
    mov si, strings.disksec
    call printString
    mov al, byte [geometry.sectors]
    call numberAsDecimal
    mov si, di
    call printString
    
getMemoryMap:
    ; Every entry is 24 bytes long, stored at es:di
    ; uint64_t baseAddress
    ; uint64_t length
    ; uint32_t type
    ; uint32_t extendedAttributes
    
    %define _smap 0x0534D4150

    mov si, strings.memorymap
    call printString
    
    push ds
    pop es
    mov di, eof
    xor ebx, ebx
    mov edx, _smap
    mov eax, 0xE820
    mov ecx, 24
    mov [es:di + 20], dword 1
    int 0x15
    
    push cx             ; CX = errorcode for printing error description
    mov cx, 1
    jc .fail            ; carry set if function not supported
    inc cx
    mov edx, _smap      
    cmp eax, edx        ; EAX == 'SMAP' if successful
    jne .fail
    inc cx
    test ebx, ebx       ; EBX == 0 if list is only 1 entry (worthless)
    je .fail
    pop cx
    jmp .start
    
    .nextEntry:
        push ds
        pop es
        mov eax, 0xE820
        mov [es:di + 20], dword 1
        mov ecx, 24
        int 0x15
        jc .success     ; carry set if end of list already reached
        mov edx, _smap
    
    .start:
        jcxz .skipEntry ; skip 0 length entries
        cmp cl, 20
        jbe .notACPI3
        test byte [es:di + 20], 1
        je .skipEntry   ; valid ACPI 3.x entry would have cleared that bit
        
    .notACPI3:
        mov ecx, dword [es:di + 8]
        or ecx, dword [es:di + 12]
        jz .skipEntry   ; OR bottom and top dwords of the qword memory
                        ; address against itself. If ECX == 0, skip entry
        inc byte [memoryMap.entryCount]
        add di, 24
    
    .skipEntry:
        test ebx, ebx
        jne .nextEntry  ; EBX == 0 if list is complete
        jmp .success
    
    .fail:
        mov si, strings.mmapfail
        call printString
        
        cmp cx, 1
        jne @f
        mov si, strings.mmaperr1
        jmp .fail.end
        
        @@:
        cmp cx, 2
        jne @f
        mov si, strings.mmaperr2
        jmp .fail.end
        
        @@:
        cmp cx, 3
        jne @f
        mov si, strings.mmaperr3
        jmp .fail.end
        
        @@:
        mov si, strings.mmaperru
        
        .fail.end:
        call printString
        
        mov ax, cx
        mov di, strings.buffer
        call numberAsDecimal
        mov si, di
        call printString
        
        mov si, strings.loadhalt
        call printString
        
        cli
        hlt
        jmp $-2
    
    .success:
    
    ; Display number of total memory map entries
    mov si, strings.mmapcount
    call printString
    mov ah, 0
    mov al, byte [memoryMap.entryCount]
    mov di, strings.buffer
    call numberAsDecimal
    mov si, di
    call printString
    
    ; Build table
    mov si, strings.mmaphead
    call printString
    
    mov dx, eof
    mov cx, ax
    .buildTable:
        mov si, strings.mmapspace
        call printString
        push cx
        mov cx, 2
        .displayQWords:
            mov di, strings.buffer
            push cx
            mov cx, 4
            add dx, 6
            .nextWord:
                mov si, dx
                std
                lodsw
                cld
                mov dx, si
                call numberAsHexadecimal
                mov si, di
                call printString
                loop .nextWord
            add dx, 10
            mov si, strings.mmapsep
            call printString
            pop cx
            loop .displayQWords
        .displayType:
            mov si, dx
            lodsd
            mov dx, si
            
            cmp eax, dword 1
            jne @f
            mov si, strings.mmapfree
            call printString
            jmp .displayType.end
            
            @@:
            cmp eax, dword 2
            jne @f
            mov si, strings.mmapres
            call printString
            jmp .displayType.end
            
            @@:
            cmp eax, dword 3
            jne @f
            mov si, strings.mmaprecl
            call printString
            jmp .displayType.end
            
            @@:
            cmp eax, dword 4
            jne @f
            mov si, strings.mmapnonv
            call printString
            jmp .displayType.end
            
            @@:
            cmp eax, dword 5
            jne @f
            mov si, strings.mmapbad
            call printString
            jmp .displayType.end
            
            @@:
            mov si, strings.mmapunkn
            call printString
            mov si, strings.equals
            call printString
            mov di, strings.buffer
            call numberAsHexadecimal
            push si
            mov si, di
            call printString
            pop si
            
            .displayType.end:
        
        ; Skip ACPI extended attributes dword
        add dx, 4
        
        ; Code in loop is too large, so LOOP must be done manually
        pop cx
        dec cx
        jnz .buildTable
    
    mov si, strings.newline
    call printString
    
    cli
    hlt
    jmp $-2
    
    jmp $
    
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
  
; si = ptr to old string
; di = ptr to new string
; RETURN
; di = ptr to new string  
reverseString:
    pusha
    
    xor cx, cx
    
    .gotoEnd:
        cmp byte [si], 0
        jz .nextChar.setup
        inc si
        inc cl
        jmp .gotoEnd
        
    .nextChar.setup:
        dec si
        
    .nextChar:
        mov al, [si]
        dec si
        mov [di], al
        inc di
        loop .nextChar
        
    .appendTerminator:
        mov [di], byte 0
        
    .return:
        popa
        ret
    
; ax = number
; di = ptr to new string
; RETURN
; di = ptr to new string
numberAsDecimal:
    pusha
    
    mov bx, 10
    mov si, .buffer
    xor dx, dx
    cmp ax, 0
    jz .isZero
    jmp .extractLeastSignificant
    
    .isZero:
        mov al, '0'
        stosb
        mov al, 0
        stosb
        jmp .return
        
    .extractLeastSignificant:
        div bx
        add dl, 48
        mov [si], dl
        inc si
        mov dl, 0
        cmp ax, 0
        jz .flipString
        jmp .extractLeastSignificant
        
    .flipString:
        mov [si], byte 0
        mov si, .buffer
        call reverseString
        
    .return:
        popa
        ret
        
    .buffer: db 6 dup (0)
    
; ax = number
; di = ptr to new string
; RETURN
; di = ptr to new string
numberAsHexadecimal:
    pusha
    push es
    
    push ds
    pop es
    mov bx, .charmap
    
    mov cx, ax
    and ax, 0xF000
    shr ax, 12
    xlatb
    stosb
    mov ax, cx
    and ax, 0x0F00
    shr ax, 8
    xlatb
    stosb
    mov ax, cx
    and ax, 0x00F0
    shr ax, 4
    xlatb
    stosb
    mov ax, cx
    and ax, 0x000F
    xlatb
    stosb
    mov al, 0
    stosb
    
    pop es
    popa
    ret
    
    .charmap    db "0123456789ABCDEF", 0
  
strings:
    .systeminfo db 0x0D, 0x0A, "Acquiring system information...", 0
    .cpufeat    db 0x0D, 0x0A, "CPU features:", 0
    .cpuid      db 0x0D, 0x0A, "  CPUID instruction is ", 0
    .longmode   db 0x0D, 0x0A, "  64-bit long mode is ", 0
    .diskgeom   db 0x0D, 0x0A, "Emulated floppy disk drive geometry:", 0 
    .diskcyl    db 0x0D, 0x0A, "  Cylinders: ", 0
    .disksec    db 0x0D, 0x0A, "  Sectors: ", 0
    .diskhead   db 0x0D, 0x0A, "  Heads: ", 0
    .memorymap  db 0x0D, 0x0A, "Memory map:", 0
    .mmapcount  db 0x0D, 0x0A, "  Total entries: ", 0
    .mmaphead   db 0x0D, 0x0A, "  -Base Address-----|-Length-----------|-Type-------------", 0
    .mmapspace  db 0x0D, 0x0A, "   ", 0
    .mmapsep    db             " | ", 0
    .mmapfree   db             "Free", 0
    .mmapres    db             "Reserved", 0
    .mmaprecl   db             "ACPI reclaimable", 0
    .mmapnonv   db             "ACPI non-volatile", 0
    .mmapbad    db             "Bad", 0
    .mmapunkn   db             "Unknown", 0
    .equals     db             " =", 0
    .newline    db 0x0D, 0x0A, 0
    .supported  db             "supported", 0
    .nsupported db             "not supported", 0
    .mmapfail   db 0x0D, 0x0A, "***Cannot acquire memory map using function 0xE820:", 0
    .mmaperr1   db 0x0D, 0x0A, "   ""Not supported by BIOS""", 0
    .mmaperr2   db 0x0D, 0x0A, "   ""EAX did not return 0x0534D4150 as expected""", 0
    .mmaperr3   db 0x0D, 0x0A, "   ""Only one map entry was returned""", 0
    .mmaperru   db 0x0D, 0x0A, "   ""Unknown errorcode""", 0
    .loadhalt   db 0x0D, 0x0A, "***Cannot continue loading operating system.", 0
    .buffer     db 6 dup (0)

geometry:
    .cylinders  dw ?
    .sectors    db ?
    .heads      db ?
memoryMap:
    .entryCount db ?
    
eof:
