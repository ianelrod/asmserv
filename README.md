# A Slightly More Stable Every Request Version

of my old assembly web server found here: https://github.com/igoforth/codesamples/blob/master/x86-64/getpostserver.s

The vision is to create an x86_64 web server that can handle GET (and someday POST) requests consistently.

Objectives:
1. Lightweight
2. Elegant
3. Reliable

Features:
- A "security implementation" that checks the request path against a list of forbidden bytes to prevent file access beyond the cwd
- Parent/child process architecture that speeds up client request handling

The program does not use:
- libc
- IPv6

Constraints:
- Will GET content up to 2GiB-1
- Handle file names up to 255B, linux max-1
- Will not parse url encoding

Forbidden in paths:
- Spaces " " (0x20) (By nature of the program, this will just break things)
- More than one dot "." (0x2E)
- More than one forward slash "/" (0x2F)
- Bad ASCII bytes \:*?%"<>| (0x5C 0x3A 0x2A 0x3F 0x22 0x3C 0x3E 0x7C)

Future ideas:
- Implement POST request handling
- Handle SIGINT to exit gracefully
- More verbose connection logging
- Ensure server will respond to fully-featured browsers
- Clean up code to ensure consistent style

## Build
```bash
make
```

## Usage
```bash
./bin/asmserv 127.0.0.1 1485 &
curl -iv --http0.9 http://localhost:1485/index.html
```