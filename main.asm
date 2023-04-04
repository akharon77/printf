format ELF64

section '.text' executable

public _start
extrn printf

_start:
    mov rdi, str1
    mov rsi, -1h
    mov rdx, msg1
    mov rcx, 3802d
    mov r8, 100d
    mov r9, 33d

    mov [rspBuf], rsp
    and rsp, -16

    xor rax, rax

    push msg1
    push 127d

    call printf

    mov rsp, [rspBuf]
    
    mov rax, 3Ch
    xor rdi, rdi
    syscall

section '.data' writeable

str1 db "%d %s %x %d%%%c%b hehehe %s", 0Ah, 0h
msg1 db "Love", 0h

rspBuf dq 0h
    
