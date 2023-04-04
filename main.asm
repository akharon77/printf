format ELF64

section '.text' executable

extrn printf
public main

main:
    push rbp
    mov rbp, rsp

    mov rdi, str1
    mov rsi, -1h
    mov rdx, msg1
    mov rcx, 3802d
    mov r8, 100d
    mov r9, 33d

    mov [rspBuf], rsp
    and rsp, not 0Fh

    push msg1

    xor rax, rax

    call printf

    mov rsp, [rspBuf]
    
    mov rsp, rbp
    pop rbp
    ret

section '.data' writeable

str1 db "%d %s %x %d%%%c hehehe %s", 0Ah, 0h
msg1 db "Love", 0h

rspBuf dq 0h
    
