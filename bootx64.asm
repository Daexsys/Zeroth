
format pe64 dll efi
entry main

section '.text' code executable readable

include 'uefi.inc'

main:
    InitializeLib
    jc @f
    
    uefi_call_wrapper ConOut, OutputString, ConOut, strings.hello
    
    jmp $
    
    @@:
    mov eax, EFI_SUCCESS
    retn
    
section '.data' data readable writeable

strings:
    .hello          du "Hello world!", 0x0D, 0x0A, 0

section '.reloc' fixups data discardable
