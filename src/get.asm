; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; GET Request Handler
; Only two security rules:
; 1. Do not allow path traversal
; 2. Prevent buffer overflows
; -----------------------------------------

section .text
        global  _get
        extern  _end
        extern  _fof

rd_cd:                              ; read connection
; rax: result pointer
; rdi: connection fd
; rsi: efficiency hop. This is read length given to kernel
; rdx: max bytes
; rcx: loop counter, rdx / rsi
        push    rbp
        mov     rbp,rsp

        ; find rcx
        push    rdx
        mov     rax,rdx
        idiv    rsi
        mov     rcx,rax
        pop     rdx

        ; declare buffer space
        sub     rsp,rsi

.top:   ; read into buffer
        push    rdi
        push    rsi
        push    rdx
        push    rcx
        mov     rdx,rsi
        lea     rsi,[rsp+0x10]
        mov     rax,0               ; operator read
        syscall
        pop     rcx
        pop     rdx
        pop     rsi
        pop     rdi

        ; was the path legal, or was the request malformed?
        push    rdi
        push    rsi
        push    rdx
        push    rcx
        lea     rsi,[rsp+0x10]
        mov     rax,0               ; operator read
        call    hmmm
        pop     rcx
        pop     rdx
        pop     rsi
        pop     rdi

        cmp     rax,-1
        je      _fof

rd_fd:                              ; read file

hmmm:                               ; did client mess up?
; al|rax: exit condition -> result count
; rdi: general purpose
; rsi: buffer pointer
; rcx: loop counter
; rdx: offset counter
; r8: general purpose
        xor     rdx,rdx
.top:   xor     rdi,rdi
        xor     r8,r8
        mov     rdi,[rsi+rdx]       ; get 8 bytes
        mov     rcx,8
.iter:  cmp     dil,0               ; compare for null
        je      .error
        cmp     dil,al              ; compare for exit condition
        je      .done
        push    al

.bb:    mov     r8,[bb]
        mov     rax,rdi             ; preserve original

        and     dil,r8b
        cmp     dil,r8b             ; compare for bad byte
        je      .error

        mov     rdi,rax             ; fetch original
        shl     r8,8
        cmp     r8b,0
        jnz     .bb

        pop     al
        shl     rdi,8
        inc     rdx                 ; offset increment
        dec     rcx
        jnz     .iter
        shr     rdi,64
        jmp     .top
.done:  mov     rax,rdx
        ret
.error: mov     rax,-1
        ret

_get:
        push    rbp
        mov     rbp,rsp
        sub     rsp,0x10

        mov     [rbp-0x2],di        ; connfd to stack
        mov     rax,57              ; operator fork
        syscall
        cmp     rax,0
        jne     .end

        ; read from socket up to path beginning
        mov     rax,0               ; operator read
        mov     di,[rbp-0x2]
        lea     rsi,[rbp-0x8]       ; char buffer
        mov     rdx,3               ; read 3 bytes
        syscall

        ; read from path up to 8192
        cmp     rax,0
        jl      .end
        ; clear buffer of rest

.end:   mov     rsp,rbp
        pop     rbp
        ret

section .rodata
bb:     db      "/","\","%",0       ; bad bytes