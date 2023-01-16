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
        extern  _handle

_start:
        mov     eax,DWORD [rsp]     ; arg value
        cmp     rax,3               ; check for 3 args
        ; according to convention, we can assume r12 is not changed by callee, so we use it to keep track of error codes (could also use rbx?)
        mov     r12,1               ; arguments error: 1
        jne     _end

        mov     rdi,[rsp+0x10]      ; take pointer ip str
        mov     rsi,[rsp+0x18]      ; take pointer port str
        call    _conv               ; convert args to sockaddr_in struct
        add     rsp,0x18            ; clear shell args

main:
        push    rbp
        mov     rbp,rsp
        sub     rsp,0x20
        
        mov     QWORD [rbp-0x8],rax ; unpack sockaddr_in to stack
        xor     rax,rax
        mov     QWORD [rbp-0x10],rax; sin_zero

        mov     rax,41              ; operator socket
        mov     rdi,2               ; AF_INET
        mov     rsi,1               ; SOCK_STREAM
        mov     rdx,0               ; 0
        syscall
        cmp     rax,0               ; check for socket error
        inc     r12                 ; socket error: 3
        jl      _end
        mov     WORD [rbp-0x12],ax  ; sockfd to stack
        mov     rdi,rax
        mov     rax,49              ; operator bind
        lea     rsi,[rbp-0x10]      ; sockaddr_in from stack
        mov     rdx,16              ; sockaddr_in size
        syscall
        cmp     rax,0               ; check for bind error
        inc     r12                 ; bind error: 4
        jl      _end
        mov     rax,50              ; operator listen
        movzx   rdi,WORD [rbp-0x12]  ; sockfd from stack
        mov     rsi,5               ; backlog
        syscall
        cmp     rax,0               ; check for listen error
        inc     r12                 ; listen error: 5
        jl      _end
        mov     rax,1               ; operator write
        mov     rdi,1
        lea     rsi,[lt_str]        ; listen message
        mov     rdx,30
        syscall

listen: ; loop connections
        mov     rax,43              ; operator accept
        movzx   rdi,WORD [rbp-0x12]  ; socket fd
        lea     rsi,[rbp-0x10]      ; sockaddr_in from stack
        mov     rdx,16              ; sockaddr_in size
        syscall
        mov     WORD [rbp-0x14],ax  ; connection fd
        mov     rax,57              ; operator fork
        syscall
        movzx   rdi,WORD [rbp-0x14]  ; connection fd
        cmp     rax,0
        jg      .next
.handle:call    _handle
        jmp     _end
.next:  mov     rax,3               ; operator close
        syscall
        jmp     listen

_end:
        mov     rax,r12             ; transfer error to rax
        call    _error
        mov     rdi,rax             ; transfer error to rdi
        mov     rax,60              ; operator exit
        syscall

section .rodata
lt_str: db      "Listening for connections...",0xa,0