; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Convert IP and port string to binary
; -----------------------------------------

section .text
        global  _conv
        extern  _end

ip_aton:                            ; ip ascii to network byte order (rdi: ascii pointer, rsi: network byte order pointer)
        xor     rax,rax
        xor     rbx,rbx
        mov     bl,4                ; set loop counter
.top:   xor     rcx,rcx
        mov     cl,BYTE [rdi]       ; load char
        cmp     cl,'0'              ; if below ascii 0, done
        jb      .done
        cmp     cl,'.'
        je      .next               ; if period, go next
        sub     cl,'0'
        imul    rax,10              ; multiply accumulator by 10
        add     al,cl               ; add int to accumulator
        jo      _end                ; if accumulator > 255, error
        inc     rdi
        jmp     .top
.next:  mov     BYTE [rsi],al       ; store & clear accumulator
        xor     al,al
        inc     rsi
        dec     bl
        jnz     .top
.done:  ret

pt_atoi:                            ; port ascii to integer (rdi: ascii pointer, rsi: integer pointer)
        xor     rax,rax
        xor     rbx,rbx
        mov     bl,5                ; set failsafe
.top:   xor     rcx,rcx
        xor     rdx,rdx
        mov     cl,BYTE [rdi]       ; load char
        cmp     cl,'0'              ; if below ascii 0, done
        jb      .done
        sub     cl,'0'
        imul    rax,10              ; multiply accumulator by 10
        movzx   dx,cl
        add     ax,dx               ; add int to accumulator
        jo      _end                ; if accumulator > 65535, error
        inc     rdi
        dec     bl
        jnz     .top
.done:  mov     WORD [rsi],ax       ; store accumulator
        ret

pt_htons:                           ; port integer to network byte order (rdi: pointer to use)
        mov     ax,WORD [rdi]       ; load port integer
        xchg    al,ah               ; swap bytes
        mov     WORD [rdi],ax       ; store port result
        ret

_conv:
        push    rbp
        mov     rbp,rsp
        sub     rsp,0x18

        mov     r12,2               ; set code if error occurs
        mov     [rbp-0x8],rdi       ; store ip pointer
        mov     [rbp-0x10],rsi      ; store port pointer
        lea     rsi,[rbp-0x18]      ; ip network byte order
        call    ip_aton
        lea     rdi,[rbp-0x10]      ; port pointer
        lea     rsi,[rbp-0x14]      ; port integer
        call    pt_atoi
        lea     rdi,[rbp-0x14]      ; port integer
        call    pt_htons
        mov     ax,2                ; AF_INET
        mov     WORD [rbp-0x12],ax
        mov     rax,QWORD [rbp-0x18]; pack sockaddr_in (add sin_zero later)

        add     rsp,0x18
        mov     rsp,rbp
        pop     rbp
        ret