format ELF64

section '.text' executable

; public _start

public printfWrapper

; _start:
;     push 127d
;     push 33d
;     push 100d
;     push 3802d
;     push msg1
;     push -1d
;     push str1
;     ; push 10101b
;     ;push str1
;     call printf
;     add rsp, 7h * 8h
; 
;     mov rax, 3Ch
;     xor rdi, rdi
;     syscall

BUFFER_SIZE     equ 100h
SUB_BUFFER_SIZE equ 40h

macro convertWrapper func
{
    sub rsp, SUB_BUFFER_SIZE
    
    mov rbx, rsp
    add rbx, SUB_BUFFER_SIZE - 1h

    push rcx
    push rbx
    push qword [10h + rbp + r8 * 8h]

    call func
    add rsp, 10h
    pop rcx

    mov rbx, rsp
    add rbx, SUB_BUFFER_SIZE
    sub rbx, rax
    push rbx
    push rax
    call nputs
    add rsp, 10h
    
    add rsp, SUB_BUFFER_SIZE
}

;==========================================
printfWrapper:
    pop r12
    
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    call printf
    add rsp, 6h * 8h
    
    push r12

    ret
;==========================================

;==========================================
printf:
    push rbp
    mov rbp, rsp

    push rbx

    mov r8, 0h              ; R8 is used to accumulate the count of arguments
    mov rsi, [rbp + 10h]    ; RSI is used for format string address
    mov r9, 0h              ; R9 is used for buffer index
    xor rcx, rcx            ; RCS is used to accumulate the part of string to print without formatting
    xor rax, rax            ; RAX is used for symbol loading

    jmp .next

.next_inc:
    add rcx, 1h
    
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
    jae .case_above_o

    jmp .next_inc

.case_above_o:
    cmp al, 'x'
    jbe .case_osx
    
    jmp .next_inc

.case_below_equal_d:
    cmp al, 'b'
    jae .case_bcd

    cmp al, '%'
    je .case_percent

    jmp .next_inc
;==========================================

.case_percent:
    cmp r9, BUFFER_SIZE
    jb @f
        call flush
@@:
    mov [printBuffer + r9], '%'
    inc r9 

    jmp .next

.case_bcd:
    and rax, 0FFh
    ; sub rax, 'b'
    jmp qword [jmp_bcd_table + (rax - 'b') * 8h]

;==========================================
    .case_b:
        inc r8

        convertWrapper convertBinary 
        jmp .next

    .case_c:
        inc r8

        cmp r9, BUFFER_SIZE
        jb @f
            call flush
    @@:
        mov rax, [10h + rbp + r8 * 8h]
        mov [printBuffer + r9], al
        inc r9

        jmp .next

    .case_d:
        inc r8

        convertWrapper convertDecimal 
        jmp .next
;==========================================

.case_osx:
    and rax, 0FFh
    ; sub rax, 'o'
    jmp qword [jmp_osx_table + (rax - 'o') * 8h]

;==========================================
    .case_o:
        inc r8

        convertWrapper convertOctal
        jmp .next

    .case_s:
        inc r8

        mov rdi, [10h + rbp + r8 * 8h]
        mov rbx, rdi
        push rdi

        cld
        mov al, 0h
        mov rcx, BUFFER_SIZE * 2h
        repne scasb
        sub rdi, rbx
        push rdi
        
        call nputs
        add rsp, 10h

        jmp .next

    .case_x:
        inc r8

        convertWrapper convertHexadecimal
        jmp .next
;==========================================

.end:
    sub rsi, rcx
    push rsi
    push rcx
    call nputs
    call flush

    pop rbx

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
    push rsi
    push rcx

    mov rax, 1h             ; syscall write
    mov rdi, 1h             ; fd    = 1h (console output)
    mov rsi, printBuffer    ; buf   = offset printBuffer
    mov rdx, r9             ; count = bufferIndex
    syscall
        
    pop rcx
    pop rsi

    mov r9, 0h
    ret
;==========================================

;==========================================
; 
; 
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
    mov rcx, SUB_BUFFER_SIZE
    std

.next:
    shr rbx, 1h
    lahf
    mov al, ah
    and al, 1h
    add al, '0'
    stosb

    dec rcx
    cmp rcx, 0h
    je .end

    cmp rbx, 0h
    jne .next

.end:
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
    mov rcx, SUB_BUFFER_SIZE

    push rax
    shl rax, 1h
    jnc .pos
        not rax
        shr rax, 1h
        add rax, 1h
        jmp @f
.pos:
    shr rax, 1h
@@:
    mov rbx, 0Ah

.next:
    xor rdx, rdx
    div rbx
    
    mov cl, [numBase + rdx]
    mov [rdi], cl
    dec rdi

    dec rcx
    cmp rcx, 0h
    je .end

    cmp rax, 0h
    jne .next

.end:
    pop rax
    shl rax, 1h
    jnc @f
        mov byte [rdi], '-'
        dec rdi
@@:
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
convertOctal:
    push rbp
    mov rbp, rsp

    mov rdi, [rbp + 18h]
    mov rax, [rbp + 10h]
    mov rcx, SUB_BUFFER_SIZE

.next:
    mov rdx, rax
    and rdx, 7h
    shr rax, 3h
    
    mov cl, [numBase + rdx]
    mov [rdi], cl
    dec rdi

    dec rcx
    cmp rcx, 0h
    je .end

    cmp rax, 0h
    jne .next

.end:
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
convertHexadecimal:
    push rbp
    mov rbp, rsp

    mov rdi, [rbp + 18h]
    mov rax, [rbp + 10h]
    mov rcx, SUB_BUFFER_SIZE

.next:
    mov rdx, rax
    and rdx, 0Fh
    shr rax, 4h
    
    mov cl, [numBase + rdx]
    mov [rdi], cl
    dec rdi

    dec rcx
    cmp rcx, 0h
    je .end

    cmp rax, 0h
    jne .next

.end:
    mov rax, [rbp + 18h]
    sub rax, rdi

    mov rsp, rbp
    pop rbp
    ret
;==========================================

section '.data' writeable align 8

; str1 db "%b hehehe", 0Ah, 0h
str1 db "%d %s %x %d%%%c%b hehehe", 0Ah, 0h
msg1 db "Love", 0h

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
    dq 3h dup (printf.next_inc) ; 1h-3h
    dq printf.case_s            ; == 4h ==
    dq 4h dup (printf.next_inc) ; 5h-8h
    dq printf.case_x            ; == 9h ==
    
section '.bss' writeable

printBuffer rb BUFFER_SIZE

