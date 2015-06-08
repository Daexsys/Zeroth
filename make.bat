
@rem BUILD THE DISK'S DIRECTORY TREE STRUCTURE
@mkdir tree 2>nul
@cd tree
@mkdir efi 2>nul
@cd efi
@mkdir boot 2>nul
@cd ..\..

@rem BUILD SOURCE FILES
fasm bootx64.asm bootx64.efi

@rem COPY FILES INTO TREE STRUCTURE
@copy bootx64.efi tree\efi\boot /Y
