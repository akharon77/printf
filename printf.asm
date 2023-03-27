format ELF64

section '.text' executable

public _start

_start:

    ; call printf

    mov rax, 3Ch
    xor rdi, rdi
    syscall
    

BUFFER_SIZE equ 100h

;==========================================
printf:
    push rbp
    mov rbp, rsp

; first case %%
; ascii code is 37d

; jmp table for %b, %c and %d
; ascii codes are 98d, 99d, 100d
; sub 98d = 0h, 1h, 2h
; jmp_table1 dq offset 


; jmp table for %o, %s, %x
; ascii codes are 111d, 115d, 120d
; sub 111d = 0h, 4h, 9h


    sub rsp, BUFFER_SIZE    ; buffer allocation
    mov r10, rsp            ; save buffer address

    mov rsi, [rbp]
    xor rcx, rcx
    xor rax, rax
    
.next:
    cmp byte [rsi], '%'
    je .format
    cmp byte [rsi], 0h
    je .end
    
    inc rcx
    jmp .next

.format:
    inc rsi
    lodsb

    cmp rax, 'o'
    jge .case_osx

    cmp rax, 'b'
    jge .case_bcd

    cmp rax, '%'

.case_percent:
    ; putc('%')

.case_bcd:
    sub rax, 'b'
    lea rdi, [jmp_bcd_table + rax * 8h]
    jmp qword [rdi]

.case_b:
    
    jmp .next

.case_c:

    jmp .next

.case_d:
    
    jmp .next

.case_osx:
    sub al, 'o'
    jmp .next

.case_o:

.case_s:

.case_x:

.skip:

.end:
    add rsp, BUFFER_SIZE
    pop rbp
;==========================================

;==========================================
flush:
    push rbp
    mov rbp, rsp

    pop rbp
;==========================================

;==========================================
puts:
    push rbp
    mov rbp, rsp

    pop rbp
;==========================================

section '.data' writeable

string db "%%", 0h
; str db "%%c: %c, %%s: %s, %%d: %d, %%o: %o, %%x: %x, %%b: %b, %%", 0h

align 8
jmp_bcd_table:
    dq printf.case_b
    dq printf.case_c
    dq printf.case_d

jmp_osx_table:
    dq printf.case_o
    dq 3h dup (printf.skip)
    dq printf.case_s
    dq 4h dup (printf.skip)
    dq printf.case_x
    
section '.bss' writeable

printBuffer rb BUFFER_SIZE

