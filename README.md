# A Slightly More Stable Every Request Version

of my old assembly web server found here: https://github.com/igoforth/codesamples/blob/master/x86-64/getpostserver.s

The vision is to create an x86_64 web server that can handle GET and POST requests.

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
- Will GET/POST content up to 2GB
- Handle file names up to 255B, linux max
- Will not parse url encoding

Forbidden
In paths:
- Spaces " " (0x20) (By nature of the program, this will just break things)
- More than one dot "." (0x2E)
- More than one forward slash "/" (0x2F)
- Bad ASCII bytes \:*?%"<>| (0x5C 0x3A 0x2A 0x3F 0x22 0x3C 0x3E 0x7C)

Future ideas:
- Handle SIGINT to exit gracefully

## Build:
```bash
nasm -f elf64 -o obj/main.o src/main.asm
nasm -f elf64 -o obj/error.o src/error.asm
nasm -f elf64 -o obj/conv.o src/conv.asm
nasm -f elf64 -o obj/get.o src/get.asm
nasm -f elf64 -o obj/post.o src/post.asm
nasm -f elf64 -o obj/404.o src/404.asm
ld -o bin/asmserv obj/main.o obj/error.o obj/conv.o obj/get.o obj/post.o obj/404.o
```