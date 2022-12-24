; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Server Entry Point
; -----------------------------------------

section .text
extern  _bind
extern  _get
extern  _post
request:                            ; request handler
args:                               ; invalid args handler
        mov     rax,1
        mov     rdi,1
        lea     rsi,[error1]        ; error message
        mov     rdx,30
        syscall                     ; write to stdout
        mov     rdi,1               ; args exit
        jmp     _end
global  _main
_main:                              ; entry point
        mov     rdi,[rsp]
        cmp     rdi,3               ; check for 3 args
        jne     args
        movs    [ipaddr],[rsp+16]   ; ip address
        movs    [port],[rsp+24]     ; port number

        mov     rax,41              ; operator socket
        mov     rdi,2               ; AF_INET
        mov     rsi,1               ; SOCK_STREAM
        mov     rdx,0               ; 0
        syscall
        mov     rdi,rax             ; socket fd
        lea     rsi,[ipaddr]        ; ip address
        lea     rdx,[port]          ; port number
        call    _bind               ; bind and connect
        mov     rax,50              ; operator listen
        mov     rdi,rax             ; socket fd
        mov     rsi,5               ; backlog
        syscall
_end:
        mov     rax,60              ; operator exit
        syscall

section .rodata
error1: db      "Syntax: ./server [ip] [port]",0
section .bss
sock:   resb    16                  ; ip address
        resb    6                   ; port number