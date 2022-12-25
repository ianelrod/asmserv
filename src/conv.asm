; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Convert IP and port string to binary
; -----------------------------------------

section .text
        global  _conv
        extern  _end

error:  mov     rax,1
        mov     rdi,1
        mov     rsi,[error2]
        mov     rdx,13
        syscall
        mov     rdi,2           ; ip/port error exit code
        jmp     _end

ip_aton:                        ; ip ascii to network byte order
        xor     rax,rax
        xor     rbx,rbx
        mov     rsi,[binary]    ; load ip binary
        mov     bl,4            ; set loop counter
.top:   xor     cl,cl
        mov     cl,[rdi]        ; load char
        cmp     cl,'0'          ; if below ascii 0, done
        jb      .done
        cmp     cl,'.'
        je      .next           ; if period, go next
        sub     cl,'0'
        imul    rax,10          ; multiply accumulator by 10
        add     al,cl           ; add int to accumulator
        cmp     al,0xff
        ja      error           ; if accumulator > 255, error
        inc     rdi
        jmp     .top
.next:  mov     [rsi],al          ; store & clear accumulator
        xor     al,al
        inc     rsi
        dec     bl
        jnz     .top
.done:  ret

pt_atoi:                        ; port ascii to integer
        xor     rax,rax
        mov     si,[binary+4]   ; load port binary
.top:   xor     cl,cl
        mov     cl,[rdi]        ; load char
        cmp     cl,0            ; if null, done
        jb      .done
        sub     cl,'0'
        imul    rax,10          ; multiply accumulator by 10
        add     al,cl           ; add int to accumulator
        cmp     ax,0xffff
        ja      error           ; if accumulator > 65535, error
        inc     rdi
        jmp     .top
.done:  mov     si,ax
        mov     [binary+4],si   ; store accumulator
        ret

_conv:
        mov     [str_ptr],rdi   ; store ip pointer
        mov     [str_ptr+8],rsi ; store port pointer
        call    ip_aton         ; convert ip
        lea     rdi,[str_ptr+8] ; load port pointer
        call    pt_atoi         ; convert port
        lea     rax,[binary]    ; load binary
        ret

section .rodata
error2: db      "Error: Invalid IP or port",0xa,0

section .bss
str_ptr:resq    1
        resq    1
binary: resd    1
        resw    1