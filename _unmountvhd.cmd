@echo off
setlocal enabledelayedexpansion

if {%1}=={} (
    echo Usage: %~nx0 [vhd]
    exit /b 1
)
set vhdPath=%~dpnx1

echo Unmounting !vhdPath!

REM
REM create dispart script
REM
set diskPartScript=%~nx0.diskpart
echo sel vdisk file="!vhdPath!">!diskPartScript!
echo detach vdisk>>!diskPartScript!

REM
REM diskpart
REM
diskpart /s !diskPartScript!
del /q !diskPartScript!

echo Done!

endlocal
