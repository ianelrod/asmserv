; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Server Entry Point
; -----------------------------------------

section .text
        global  _start
        extern  _conv
        extern  _error
        extern  _get
        extern  _post

_start:
        mov     rax,[rbp-0x8]       ; arg pointer
        cmp     rax,3               ; check for 3 args
        mov     rcx,1
        jne     _end

        lea     rdi,[rbp-0x18]      ; ip pointer (skip program name)
        lea     rsi,[rbp-0x20]      ; port pointer
        call    _conv               ; convert args to sockaddr_in struct

main:
        lea     rsp,[rbp-0x20]      ; new stack pointer
        mov     [rbp-0x8],rax       ; unpack sockaddr_in to stack
        xor     rax,rax
        mov     [rbp-0x10],rax      ; sin_zero

        mov     rax,41              ; operator socket
        mov     rdi,2               ; AF_INET
        mov     rsi,1               ; SOCK_STREAM
        mov     rdx,0               ; 0
        syscall
        cmp     rax,0               ; check for socket error
        mov     rcx,3
        jl      _end
        mov     [rbp-0x12],ax       ; sockfd to stack
        mov     rdi,rax
        mov     rax,49              ; operator bind
        lea     rsi,[rbp-0x10]      ; sockaddr_in from stack
        mov     rdx,16              ; sockaddr_in size
        syscall
        cmp     rax,0               ; check for bind error
        mov     rcx,4
        jl      _end
        mov     rax,50              ; operator listen
        mov     di,[rbp-0x12]       ; sockfd from stack
        mov     rsi,5               ; backlog
        syscall
        cmp     rax,0               ; check for listen error
        mov     rcx,5
        jl      _end
        mov     rax,1               ; operator write
        mov     rdi,1
        lea     rsi,[lt_str]        ; listen message
        mov     rdx,30
        syscall

listen:                             ; loop connections
        mov     rax,43              ; operator accept
        mov     di,[rbp-0x12]       ; sockfd from stack
        lea     rsi,[rbp-0x10]      ; sockaddr_in from stack
        mov     rdx,16              ; sockaddr_in size
        syscall
        mov     [rbp-0x14],ax       ; connfd to stack
        mov     rax,0               ; operator read
        mov     di,[rbp-0x14]
        lea     rsi,[rbp-0x17]      ; char buffer
        mov     rdx,1               ; read 1 byte
        syscall

        mov     al,[rbp-0x17]
        cmp     al,'G'              ; check for GET
        je      .get
        cmp     al,'P'              ; check for POST
        je      .post
        jmp     .next

.get:   call    _get
        jmp     .next
.post:  call    _post
.next:  mov     rax,3               ; operator close
        mov     di,[rbp-0x14]
        syscall
        jmp     listen

_end:
        mov     rdi,rcx             ; error code
        cmp     rdi,0
        je      .low
        call    _error
.low:   mov     rax,60              ; operator exit
        syscall

section .rodata
lt_str: db      "Listening for connections...",0xa,0