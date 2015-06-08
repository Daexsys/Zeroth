
file 'boot.bin'
file 'second.bin'
times 512*(10-1)-($-$$) db 0
file 'kernel.bin'
times 1474560-($-$$) db 0
