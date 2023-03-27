format ELF
entry start

section '.text'

start:

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
jmp_table1 dq offset 


; jmp table for %o, %s, %x
; ascii codes are 111d, 115d, 120d
; sub 111d = 0h, 4h, 9h


    sub rsp, BUFFER_SIZE    ; buffer allocation
    mov r10, rsp            ; save buffer address

    mov rsi, [rbp]
    xor rcx, rcx
    
.next:
    cmp byte ptr [rsi], '%'
    je .format
    cmp byte ptr [rsi], 0h
    je .end
    
    inc rcx
    jmp .next

.format:
    inc rsi
    lodsb

    cmp al, 'o'
    jge .case_osx

    cmp al, 'b'
    jge .case_bcd

    cmp al, '

.case_percent:
    ; putc('%')

.case_bcd:
    sub al, 'b'
    jmp [jmp_bcd_table + al * 8h]

.case_b:
    
    jmp .next

.case_c:

    jmp .next

.case_d:
    
    jmp .next

.case_osx:
    sub al, 'o'
    jmp .next

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

section '.data'

str db "%%c: %c, %%s: %s, %%d: %d, %%o: %o, %%x: %x, %%b: %b, %%", 0h

align 8
jmp_bcd_table:
    dq printf.case_b
    dq printf.case_c
    dq printf.case_d

jmp_osx_table:
    dq printf.case_o
    dq printf.

section '.bss'

printBuffer rb BUFFER_SIZE

