# A Slightly More Stable Every Request Version

of my old assembly web server found here: https://github.com/ianelrod/codesamples/blob/master/x86-64/getpostserver.s

The goal is to create a single x86-64 ELF binary that can handle get and post requests.

1. Lightweight
2. Elegant
3. Reliable

Constraints:
- Handle GET requests up to 8KB
- Handle POST requests of up to 2GB

## Build:
```bash
nasm -f elf -o obj/main.o src/main.asm
nasm -f elf -o obj/get.o src/get.asm
nasm -f elf -o obj/post.o src/post.asm
ld -o bin/server obj/main.o obj/get.o obj/post.o
```