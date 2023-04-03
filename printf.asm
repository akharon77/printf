format ELF64

section '.text' executable

public _start

_start:
    push 42d
    push 'a'
    push 101010b
    push msg1
    call printf
    add rsp, 10h

    mov rax, 3Ch
    xor rdi, rdi
    syscall

BUFFER_SIZE equ 100h

;==========================================
printf:
    push rbp
    mov rbp, rsp

    mov r8, 0h              ; R8 is used to accumulate the count of arguments
    mov rsi, [rbp + 10h]    ; RSI is used for format string address
    mov r9, 0h              ; R9 is used for buffer index
    xor rcx, rcx            ; RCS is used to accumulate the part of string to print without formatting
    xor rax, rax            ; RAX is used for symbol loading
    
.next:
    mov al, [rsi]

    cmp al, '%'
    je .format

    cmp al, 0h
    je .end
                            ;   If not EOS (end-of-string for future) and not format beginning
    inc rcx                 ; increase the length of string's part
    inc rsi             
    jmp .next

.format:                    ; |beg|...|...|...|RSI| => RSI - beg + 1 = RCX => beg = RSI - RCX + 1
    mov rax, rsi
    sub rax, rcx

    inc rsi
    
    push rsi

    push rax
    push rcx
    call nputs              ; nputs(ptr = rax, len = rcx)
    add rsp, 10h

    xor rcx, rcx
    pop rsi

    mov al, [rsi]
    inc rsi

;=============== BIN SEARCH ===============
    cmp al, 'd'
    ja .case_above_d
    jmp .case_below_equal_d

.case_above_d:
    cmp al, 'o'
    jae .case_osx
    jmp .next

.case_below_equal_d:
    cmp al, 'b'
    jae .case_bcd
    cmp al, '%'
    je .case_percent
    jmp .next
;==========================================

.case_percent:
    inc r8
    cmp r9, BUFFER_SIZE
    jb @f
        call flush
@@:
    mov [printBuffer + r9], '%'
    inc r9 

    jmp .next

.case_bcd:
    inc r8
    and rax, 0FFh
    sub rax, 'b'
    jmp qword [jmp_bcd_table + rax * 8h]

;==========================================
    .case_b:
        sub rsp, 40h
        
        mov rbx, rsp
        add rbx, 40h - 1h

        push rbx
        push qword [10h + rbp + r8 * 8h]

        call convertBinary
        add rsp, 10h

        mov rbx, rsp
        add rbx, 40h
        sub rbx, rax
        push rbx
        push rax
        call nputs
        add rsp, 10h
        
        add rsp, 40h
        
        jmp .next

    .case_c:
        cmp r9, BUFFER_SIZE
        jb @f
            call flush
    @@:
        mov rax, [10h + rbp + r8 * 8h]
        mov [printBuffer + r9], al
        inc r9

        jmp .next

    .case_d:
        sub rsp, 40h
        mov rbx, rsp
        add rbx, 40h - 1h
        push rbx
        push qword [10h + rbp + r8 * 8h]

        call convertDecimal
        add rsp, 10h

        mov rbx, rsp
        add rbx, 40h
        sub rbx, rax
        push rbx
        push rax
        call nputs
        add rsp, 10h

        add rsp, 40h
        
        jmp .next
;==========================================

.case_osx:
    inc r8
    and rax, 0FFh
    sub rax, 'o'
    jmp qword [jmp_osx_table + rax * 8h]

;==========================================
    .case_o:

        jmp .next

    .case_s:

        jmp .next

    .case_x:

        jmp .next
;==========================================

.end:
    call flush

    mov rsp, rbp
    pop rbp
    ret
;==========================================

;==========================================
; ASSUME:
;   R9 = buffer index
;==========================================
; DESTROY:
;   RAX, RDX, RSI, RDI
;==========================================
flush:
    mov rax, 1h             ; syscall write
    mov rdi, 1h             ; fd    = 1h (console output)
    mov rsi, printBuffer    ; buf   = offset printBuffer
    mov rdx, r9             ; count = bufferIndex
    syscall

    mov r9, 0h
    ret
;==========================================

;==========================================
; len = qword [rbp + 10h]
; ptr = qword [rbp + 18h]
;==========================================
nputs:
    push rbp
    mov rbp, rsp

    push rsi

    cmp qword [rbp + 10h], BUFFER_SIZE
    jae .over_buf

    mov rcx, BUFFER_SIZE
    sub rcx, r9

    cmp [rbp + 10h], rcx
    jbe .no_flush
        call flush

.no_flush:
    cld
    mov rsi, [rbp + 18h]
    mov rdi, r9
    add rdi, printBuffer
    mov rcx, [rbp + 10h]
    add r9, rcx
    rep movsb

    jmp .end
    
.over_buf:
    mov rax, 1h             ; syscall write
    mov rdi, 1h             ; fd    = 1h (console output)
    mov rsi, [rbp + 18h]    ; buf   = arg_ptr
    mov rdx, [rbp + 10h]    ; count = arg_len
    syscall

    jmp .end

.end:
    pop rsi

    mov rsp, rbp
    pop rbp
    ret
;==========================================

;==========================================
; ASSUME:
;   num     = [rbp + 10h]
;   ptr_end = [rbp + 18h]
;==========================================
; DESTROY:
;   RAX, RBX, RCX, RDI
;==========================================
convertBinary:
    push rbp
    mov rbp, rsp

    mov rdi, [rbp + 18h]
    mov rbx, [rbp + 10h]
    std

.next:
    shr rbx, 1h
    lahf
    mov al, ah
    and al, 1h
    add al, '0'
    stosb
    cmp rbx, 0h
    jne .next

    mov rax, [rbp + 18h]
    sub rax, rdi

    mov rsp, rbp
    pop rbp
    ret
;==========================================

;==========================================
; ASSUME:
;   num     = [rbp + 10h]
;   ptr_end = [rbp + 18h]
;==========================================
; DESTROY:
;   RAX, RBX, RCX, RDI
;==========================================
convertDecimal:
    push rbp
    mov rbp, rsp

    mov rdi, [rbp + 18h]
    mov rax, [rbp + 10h]
    push rax

    cmp rax, 0h
    jae @f
        mov rbx, -1h
        imul rbx
@@:
    mov rbx, 0Ah

.next:
    xor rdx, rdx
    div rbx
    
    mov cl, [numBase + rdx]
    mov [rdi], cl
    dec rdi

    cmp rax, 0h
    jne .next

    pop rax
    cmp rax, 0h
    jae @f
        mov byte [rdi], '-'
        dec rdi
@@:

    mov rax, [rbp + 18h]
    sub rax, rdi

    mov rsp, rbp
    pop rbp
    ret
;==========================================

section '.data' writeable

msg1 db "%b lolo%c %d", 0Ah, 0h

formatString db "%%c: %c, %%s: %s, %%d: %d, %%o: %o, %%x: %x, %%b: %b, %%", 0h

numBase      db "0123456789ABCDEF"

align 8

; special case %%
; ascii code is 37d

; jmp table for %b, %c and %d
; ascii codes are 98d, 99d, 100d
; sub 98d = 0h, 1h, 2h
; jmp_table1 dq offset 

jmp_bcd_table:
    dq printf.case_b            ; == 0h ==
    dq printf.case_c            ; == 1h ==
    dq printf.case_d            ; == 2h ==

; jmp table for %o, %s, %x
; ascii codes are 111d, 115d, 120d
; sub 111d = 0h, 4h, 9h

jmp_osx_table:
    dq printf.case_o            ; == 0h ==
    dq 3h dup (printf.next)     ; 1h-3h
    dq printf.case_s            ; == 4h ==
    dq 4h dup (printf.next)     ; 5h-8h
    dq printf.case_x            ; == 9h ==
    
section '.bss' writeable

printBuffer rb BUFFER_SIZE

