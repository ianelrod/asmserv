# A Slightly More Stable Every Request Version

of my old assembly web server found here: https://github.com/ianelrod/codesamples/blob/master/x86-64/getpostserver.s

The vision is to create an x86-64 web server that can handle GET and POST requests.

Objectives:
1. Lightweight
2. Elegant
3. Reliable

The program does use:
- NASM syntax
- IPv4

The program does not use:
- libc

Constraints:
- Handle GET requests up to 8KB
- Handle POST requests of up to 2GB

Future ideas:
- Handle SIGINT to exit gracefully

## Build:
```bash
nasm -f elf64 -o obj/main.o src/main.asm
nasm -f elf64 -o obj/error.o src/error.asm
nasm -f elf64 -o obj/conv.o src/conv.asm
ld -o bin/asmserv obj/main.o obj/error.o obj/conv.o
```