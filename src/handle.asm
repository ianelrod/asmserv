; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Child Connection Handler
; -----------------------------------------

section .text
        global  _handle
        extern  _read
        extern  _error
        extern  _end

open:   ; this subroutine attempts to open a file fd
; r8:  path string pointer
; r9:  file fd
; r10: general register

get:    ; this subroutine handles GET requests
; rax: result handler
; rdi: connection fd / general register
; rsi: general register
; rdx: general register
; rcx: counter
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,257

        ; get HTTP request path
        xor     rax,rax
        mov     BYTE [rbp-0x1],rax  ; zero local path offset
        mov     rsi," "             ; delimit strings by space
        bts     dx,0                ; security
.top1:  btr     dx,2
        call    _read

        ; interpret HTTP request path
        ; 1. check read result
        push    rdi
        xor     rdi,rdi
        xor     rsi,rsi
        mov     sil,dh              ; buffer offset
        mov     dil,BYTE [rax+rsi]  ; offset value
        cmp     dil," "             ; offset value = delimiter?
        je      .i                  ; store FULL path
        xor     rcx,rcx
        mov     cl,255
        sub     cl,32
        cmp     dil,cl              ; offset > BUF_SIZE - MAX_READ?
        jg      .j                  ; store WHAT WE HAVE OF path (case: path is longer than BUF_SIZE - MAX_READ but less than linux max of 255B)
        pop     rdi
        jmp     .top1

        ; 2. store request path in local variable
.i:     jmp     .k                  ; offset value = delimiter
.j:     bts     dx,2                ; offset > BUF_SIZE - MAX_READ
        mov     BYTE [rbp-0x1],dh   ; copy offset to local path offset
.k:     pop     rdi
        xor     rcx,rcx
        mov     rcx,BYTE [rbp-0x1]  ; local path offset

        ; WORK ON THIS SECTION LOGIC ^
        lea     rsi,[rbp+rcx-256]
        mov     cl,dh               ; buffer offset
.top2:  mov     dil,BYTE [rax]      ; take byte
        mov     BYTE [rsi],dil      ; put byte
        inc     rax
        inc     rsi
        dec     cl
        jz      .done
        jmp     .top2
.done:  bt      dx,2
        jc      .top1

        ; interpret file path
.done:  

        ; epilogue
        mov     rsp,rbp
        pop     rbp
        ret

post:   ; this subroutine handles POST requests
; rax: result handler
; rdi: connection fd / general register
; rsi: general register
; rdx: general register
; rcx: counter
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,0x8

        ; local variables
        mov     WORD [rbp-0x2],rdi  ; connection fd

        ; get file path
        xor     rax,rax
        xor     rdi,rdi
        xor     rsi,rsi
        mov     rdi,WORD [rbp-0x2]  ; connection fd
        mov     rsi," "             ; delimit strings by space
        bts     dx,0                ; security
        call    _read
        mov     [rbp-0xa],rax       ; store buffer pointer

        ; interpret file path

        ; epilogue
        mov     rsp,rbp
        pop     rbp
        ret

_handle:; this function receives a child forked from main and performs all steps necessary to handle a connection
; It closely interoperates with read.asm to parse data
; rax: result handler
; rdi: connection fd / general register
; rsi: general register
; dh:  offset
; dl:  handle + read state
; 0000 0001 read security (1)
; 0000 0010 keep verify   (2)
; 0000 0100 read not done (4)
; 0000 1000 none          (8)
; rcx: counter
        ; prologue
        push    rdi                 ; put connection fd
        xor     dx,dx               ; clear options for new child

        ; get HTTP request method
        xor     rax,rax
        mov     rsi," "             ; delimit strings by space
        btr     dx,0                ; no security
        call    _read
        push    rax                 ; put buffer pointer

        ; interpret HTTP request method
        ; 1. check read result
        xor     rdi,rdi
        inc     r12                 ; method error: 6
        cmp     dh,8                ; verify length
        jg      end
        mov     dil,BYTE [rax+dh]
        cmp     dil," "             ; verify delimiter
        jne     end

        ; 2. store request method in local variable
        xor     rcx,rcx
        xor     rsi,rsi
        mov     cl,dh
.top:   mov     dil,BYTE [rax]      ; take byte
        mov     sil,dil             ; put byte
        shl     rsi,8
        inc     rax
        dec     cl
        jz      .done
        jmp     .top

        ; 3. compare request method to "GET" or "POST"
.done:  pop     rax                 ; get buffer pointer
        pop     rdi                 ; get connection fd
        cmp     rsi,"GET"
        jne     .i
        call    get
        jmp     end
.i:     cmp     rsi,"POST"
        jne     end
        call    post

        ; epilogue
end:    ret
