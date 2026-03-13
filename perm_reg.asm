.model tiny
.code
org 100h



Start:
                mov ax, 1111h
                mov bx, 2222h
                mov cx, 3333h
                mov dx, 4444h
                mov si, 5555h
                mov di, 6666h
                mov bp, 7777h
                mov sp, 8888h

                ;push 9999h
                ;pop ds
                ;push 0aaaah
                ;pop es

EternalCycle:
                nop
                jmp EternalCycle


End             Start