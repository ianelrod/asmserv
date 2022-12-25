; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Server Entry Point
; -----------------------------------------

section .text
        global  _start
        extern  _conv
        ; extern  _bind
        ; extern  _get
        ; extern  _post

;request:                            ; request handler

args:                               ; invalid args handler
        mov     rax,1
        mov     rdi,1
        lea     rsi,[error1]        ; error message
        mov     rdx,30
        syscall                     ; write to stdout
        mov     rdi,1               ; args exit code
        jmp     _end

_start:
        mov     rax,[rsp]           ; arg pointer
        cmp     rax,3               ; check for 3 args
        jne     args
        mov     rdi,[rsp+16]        ; ip pointer
        mov     rsi,[rsp+24]        ; port pointer
        call    _conv               ; convert ip and port
        mov     [rsp],rax           ; store ip/port

        mov     rax,41              ; syscall socket
        mov     rdi,2               ; AF_INET
        mov     rsi,1               ; SOCK_STREAM
        mov     rdx,0               ; 0
        syscall
        mov     rdi,rax             ; socket fd
        movzx   rsi,dword [rsp]     ; ip address
        movzx   rdx,word [rsp+4]    ; port number
        call    _bind               ; bind to socket

        mov     rax,50              ; operator listen
        mov     rdi,rax             ; socket fd
        mov     rsi,5               ; backlog
        syscall

_end:
        mov     rax,60              ; operator exit
        syscall

section .rodata
error1: db      "Syntax: ./server [ip] [port]",0xa,0