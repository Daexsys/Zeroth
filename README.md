###Zeroth###
A 64-bit operating system

This project uses FASM (http://flatassembler.net) and VM VirtualBox (http://www.virtualbox.org).

For those on Windows, to build, run `make.bat` with FASM in your PATH variable.

To run, first add a new virtual machine to VirtualBox called "Zeroth" and of type "Other (x64)". Add a floppy disk drive controller and select the floppy image 'disk.ima', which is produced in the make process.

If you wish to use the command line to start the emulator, run `run.bat` with the VirtualBox program directory in your PATH variable.
