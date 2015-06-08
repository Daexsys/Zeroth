
@rem BUILD THE DISK'S DIRECTORY TREE STRUCTURE
@mkdir tree>>nul
@cd tree
@mkdir efi>>nul
@cd efi
@mkdir boot>>nul
@cd ..\..

@rem BUILD SOURCE FILES
fasm bootx64.asm bootx64.efi

@rem COPY FILES INTO TREE STRUCTURE
@copy bootx64.efi tree\efi\boot /Y
