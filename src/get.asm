; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; GET request related actions
; -----------------------------------------

section .text
        global  _get
        extern  _read
        extern  _end

_get:   ; this function is called from handle.asm to perform actions related to GET requests
; REGISTERS
; rax: result handler
; rdi: connection fd / general register
; rsi: general register
; rcx: counter
; OPTIONS
; dh:  offset
; dl:  handle + read state
; 0000 0001 read security (1)
; 0000 0010 keep verify   (2)
; 0000 0100 read not done (4)
; 0000 1000 none          (8)
; STACK
; rbp-256:  local path buffer
; rbp-257:  local path offset
; rbp-258:  file fd
; rbp-259:  connection fd
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,258

        ; get HTTP request path
        xor     rax,rax
        mov     BYTE [rbp-257],al   ; zero local path offset
        mov     rsi," "             ; delimit strings by space
        bts     dx,0                ; security
.top1:  btr     dx,2
        call    _read

        ; interpret HTTP request path
        ; 1. check read result
        mov     BYTE [rbp-260],dil  ; put connection fd
        xor     rdi,rdi
        xor     rsi,rsi
        xchg    dl,dh               ; buffer offset from dh to sil
        mov     sil,dl
        xchg    dh,dl
        mov     dil,BYTE [rax+rsi]  ; offset value
        cmp     dil," "             ; offset value = delimiter?
        je      .i                  ; store FULL path
        xor     rcx,rcx
        mov     cl,255
        sub     cl,32
        cmp     dil,cl              ; offset > BUF_SIZE - MAX_READ?
        jg      .j                  ; store WHAT WE HAVE OF path (case: path is longer than BUF_SIZE - MAX_READ but less than linux max of 255B)
        jmp     .top1

        ; 2. store request path in local variable
.i:     btc     dx,2                ; delimiter found, done reading request path
        jmp     .l
.j:     bt      dx,2                ; is this not our first read?
        jnc     .k
        add     BYTE [rbp-257],dh   ; add offset to local path offset
.k:     bts     dx,2                ; offset > BUF_SIZE - MAX_READ
.l:     xor     rcx,rcx
        mov     cl,BYTE [rbp-257]   ; local path offset set to 0 in the beginning, optionally picking up where we left off in subsequent loops
        inc     r12                 ; path error: 7
        cmp     rcx,255             ; if our path is longer than 255 bytes, something has gone seriously wrong
        jge     .end

        lea     rsi,[rbp+rcx-256]
        mov     cl,dh               ; loop counter
        push    rax                 ; retain buffer pointer
.top2:  mov     dil,BYTE [rax]      ; take byte
        mov     BYTE [rsi],dil      ; put byte
        inc     rax
        inc     rsi
        dec     cl
        jz      .done
        jmp     .top2
.done:  pop     rax
        bt      dx,2
        jc      .top1

        ; interpret file path
        push    rdx                 ; retain options
        mov     rax,2               ; operator open
        mov     rdi,[rbp-255]       ; ignore beginning forward slash
        xor     rsi,rsi
        xor     rdx,rdx
        syscall
        inc     r12                 ; file error: 8
        cmp     rax,0
        jl      .end
        mov     BYTE [rbp-258],al   ; put file descriptor

        ; flush socket
        mov     dil,BYTE [rbp-259]  ; take connection fd
        mov     rsi,0
        mov     rdx,8
.sys:   mov     rax,0               ; operator read
        syscall
        cmp     rax,0
        jge     .sys                ; read from socket until error to clear buffer

        ; send contents of file back to client, we can use sendfile for this
        ; 1. get file size using lseek
        mov     rax,8               ; operator lseek
        mov     dil,BYTE [rbp-258]  ; in fd (file)
        mov     rsi,0               ; offset
        mov     rdx,2               ; SEEK_END
        syscall
        cmp     rax,2147483647      ; file over 2GiB-1 limit?
        jo      .end                ; file error: 8
        push    rax

        ; 2. reset file offset using lseek
        mov     rax,8               ; operator lseek
        mov     rdx,0               ; SEEK_SET
        syscall

        ; 3. transfer file using sendfile
        mov     rax,40              ; operator sendfile
        mov     dil,BYTE [rbp-259]  ; out fd (connection)
        mov     sil,BYTE [rbp-258]  ; in fd (file)
        mov     rdx,0               ; offset 0
        pop     r10                 ; file size, also count to send
        syscall

        ; epilogue
        pop     rdx                 ; empty stack
.end:   mov     rsp,rbp
        pop     rbp
        ret