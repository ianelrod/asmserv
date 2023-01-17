; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Convert IP and port string to binary
; -----------------------------------------

struc sockaddr_in                   ; preprocessor macro
    .sin_family:    resw    1
    .sin_port:      resw    1
    .sin_addr:      resb    4
    .sin_zero:      resb    8
endstruc

section .text
        global  _conv
        extern  _end

ip_aton:                            ; ip ascii to network order (big-endian)
; rax: accumulator
; rdi: ascii pointer
; rsi: network byte order pointer
; rcx: loop counter
; rdx: general purpose
        xor     rax,rax
        xor     rcx,rcx
        mov     cl,4                ; set loop counter
.top:   xor     rdx,rdx
        mov     dl,BYTE [rdi]       ; load char
        cmp     dl,'0'
        jb      .next               ; if not number, next
        sub     dl,'0'
        imul    ax,10               ; multiply accumulator by 10
        add     al,dl               ; add int to accumulator
        jo      _end                ; if accumulator > 255, error
        inc     rdi
        jmp     .top
.next:  mov     BYTE [rsi],al       ; store & clear accumulator
        xor     al,al
        inc     rsi
        inc     rdi
        dec     cl
        jnz     .top
        ret

pt_atons:                           ; port ascii to network short (big-endian)
; rax: accumulator
; rdi: ascii pointer
; rsi: integer pointer
; rcx: general purpose
; rdx: general purpose
        xor     rax,rax
        mov     WORD [rsi],ax       ; init with 0s
.top:   xor     rcx,rcx
        xor     rdx,rdx
        movzx   dx,BYTE [rdi]       ; load char
        cmp     dx,'0'              ; if below ascii 0, done
        jb      .done
        sub     dx,'0'
        imul    ax,10               ; multiply accumulator by 10
        add     ax,dx               ; add int to accumulator
        jo      _end                ; if accumulator > 65535, error
        inc     rdi
        jmp     .top
.done:  xchg    ah,al               ; convert to big-endian
        mov     WORD [rsi],ax       ; store accumulator
        ret

_conv:
        push    rbp
        mov     rbp,rsp
        sub     rsp,0x18

        inc     r12                 ; conversion error: 2
        mov     [rbp-0x8],rdi       ; store pointer ip str
        mov     [rbp-0x10],rsi      ; store pointer port str
        lea     rsi,[mystruc+sockaddr_in.sin_addr] ; make pointer ip network byte order
        call    ip_aton
        mov     rdi,[rbp-0x10]      ; take pointer port str
        lea     rsi,[mystruc+sockaddr_in.sin_port] ; make pointer port integer
        call    pt_atons
        mov     ax,2                ; AF_INET
        ;xchg    ah,al
        mov     WORD [mystruc+sockaddr_in.sin_family],ax
        lea     rax,[mystruc]       ; return pointer to mystruc

        mov     rsp,rbp
        pop     rbp
        ret

section .bss
mystruc:resb    sockaddr_in_size    ; nasm defines sockaddr_in_size for us