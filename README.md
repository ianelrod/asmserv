# A Slightly More Stable Every Request Version

of my old assembly web server found here: https://github.com/ianelrod/codesamples/blob/master/x86-64/getpostserver.s

The vision is to create an x86-64 executable that can handle GET and POST requests.

The program does not use libc.

Objectives:
1. Lightweight
2. Elegant
3. Reliable

Constraints:
- Handle GET requests up to 8KB
- Handle POST requests of up to 2GB

## Build:
```bash
nasm -f elf64 -o obj/main.o src/main.asm
nasm -f elf64 -o obj/conv.o src/conv.asm
nasm -f elf64 -o obj/bind.o src/bind.asm
nasm -f elf64 -o obj/get.o src/get.asm
nasm -f elf64 -o obj/post.o src/post.asm
ld -o bin/asmserv obj/main.o obj/conv.o
```