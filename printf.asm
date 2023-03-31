format ELF64

section '.text' executable

public _start

_start:

    mov rax, 3Ch
    xor rdi, rdi
    syscall

BUFFER_SIZE equ 100h

;==========================================
printf:
    push rbp
    mov rbp, rsp

    mov rsi, [rbp]          ; RSI is used for format string address
    xor rcx, rcx            ; RCS is used to accumulate the part of string to print without formatting
    xor rax, rax            ; RAX is used for symbol loading
    
.next:
    cmp byte [rsi], '%'
    je .format

    cmp byte [rsi], 0h
    je .end
                            ;   If not EOS (end-of-string for future) and not format beginning
    inc rcx                 ; increase the length of string's part
    inc rsi             
    jmp .next

.format:                    ; |beg|   |   |   |RSI| => RSI - beg + 1 = RCX => beg = RSI - RCX + 1
    inc rsi
    mov rax, rsi
    sub rax, rcx
    
    push rax
    push rcx
    call nputs              ; (ptr = rax, len = rcx)

    mov al, [rsi]

    cmp al, 'o'
    jge .case_osx

    cmp al, 'b'
    jge .case_bcd

    cmp al, '%'
    je .case_percent
    
    jmp .next

.case_percent:
    ; putc('%')
    jmp .next

.case_bcd:
    sub rax, 'b'
    jmp qword [jmp_bcd_table + rax * 8h]

;==========================================
    .case_b:
        
        jmp .next

    .case_c:

        jmp .next

    .case_d:
        
        jmp .next
;==========================================

.case_osx:
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
    ; call flush

    mov rsp, rbp
    pop rbp
    ret
;==========================================

;==========================================
; DESTROY:
;   RAX, RDX, RSI, RDI
;==========================================
flush:
    mov rax, 1h             ; syscall write
    mov rdi, 1h             ; fd    = 1h (console output)
    mov rsi, printBuffer    ; buf   = offset printBuffer
    mov rdx, [bufferIndex]  ; count = bufferIndex
    syscall

    mov [bufferIndex], 0h
    ret
;==========================================

;==========================================
; len = qword [rbp + 10h]
; ptr = qword [rbp + 18h]
;==========================================
nputs:
    push rbp
    mov rbp, rsp

    cmp qword [rbp + 10h], BUFFER_SIZE
    jae .over_buf

    mov rcx, BUFFER_SIZE
    sub rcx, [bufferIndex]

    cmp [rbp + 10h], rcx
    jbe .no_flush
        call flush

.no_flush:
    cld
    mov rsi, [rbp + 18h]
    mov rdi, [bufferIndex]
    add rdi, printBuffer
    mov rcx, [rbp + 10h]
    add [bufferIndex], rcx
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
    mov rsp, rbp
    pop rbp
    ret
;==========================================

section '.data' writeable

bufferIndex  dq 0h
formatString db "%%c: %c, %%s: %s, %%d: %d, %%o: %o, %%x: %x, %%b: %b, %%", 0h

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

