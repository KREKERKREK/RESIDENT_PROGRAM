.model tiny
.code
org 100h



VIDEO_SEG           equ 0B800h
COLOR_TEXT          equ 00101110b
HOT_KEY_PRINT_FRAME equ 31                          ; symbol 's'
HOT_KEY_UPD_REGS    equ 20                          ; symbol 't'



;--------------------------------------------------------------;
;                     set the new handlers                     ;
;--------------------------------------------------------------;
Start:
                mov ax, 0
                mov es, ax                          ; reset ES (for access to change adress of handler)


                mov bx, 09h * 4d                    ; set the offset to change the adress of keyboard handler
                mov ax, es:[bx]

                mov cs:[offs_old_hand09], ax        ; save the offset of the old handler
                mov ax, es:[bx + 2]
                mov cs:[segm_old_hand09], ax        ; save the segment of the old handler


                cli                                 ; throw off the flag of interruptions

                mov es:[bx], offset ShowRegisters   ; change the offset of address of handler
                mov ax, cs
                mov es:[bx + 2], ax                 ; change the segment of address of handler

                sti                                 ; allow interruptions


                mov bx, 08h * 4d                    ; set the offset to change the adress of timer handler
                mov ax, es:[bx]

                mov cs:[offs_old_hand08], ax        ; save the offset of the old handler
                mov ax, es:[bx + 2]
                mov cs:[segm_old_hand08], ax        ; save the segment of the old handler


                cli                                 ; throw off the flag of interruptions

                mov es:[bx], offset NewTimeHand     ; set the offset of the new timer handler
                mov ax, cs
                mov es:[bx + 2], ax                 ; set the segment of the new timer handler

                sti                                 ; allow interruptions


                mov ax, 3100h                       ; keep resident after finish the program (don't clear the products of the program)
                mov dx, offset EndOfProgram         ;
                shr dx, 4d                          ;
                inc dx                              ;
                int 21h                             ;
;--------------------------------------------------------------;
;              the end to setting the new handlers             ;
;--------------------------------------------------------------;



ShowRegisters PROC NEAR
                mov cs:[value_sp], sp               ; save the values from 
                mov cs:[value_bp], bp               ; save the value from BP
                mov cs:[value_ax], ax               ; save the values of registers to print

                mov bp, cs:[value_sp]               ; SP can be change, so we save the value SP in BP
                mov ax, [bp]                        ; save values of registers (IP, CS) from stack
                mov cs:[value_ip], ax               ;
                mov ax, [bp + 2]                    ;
                mov cs:[value_cs], ax               ;

                mov cs:[value_bx], bx               ;
                mov cs:[value_cx], cx               ;
                mov cs:[value_dx], dx               ;
                mov cs:[value_si], si               ;
                mov cs:[value_di], di               ;
                mov cs:[value_ds], ds               ;
                mov cs:[value_es], es               ;
                mov cs:[value_ss], ss               ;

                                                    ; push isn't necessary, because we already saved values of registers

                mov ax, VIDEO_SEG                   ; set the ES:BX (segment:offset) to the place of screen, where will be printing a first symbol
                mov es, ax                          ;
                mov bx, (80d * 2d + 64d) * 2d       ;

                in al, 60h                          ; set symbol code to AL from the port 60h
                cmp al, HOT_KEY_PRINT_FRAME
                jne CheckHotKeyUpdRegs              ; if (AL != HOT_KEY_PRINT_FRAME): go to CheckHotKeyUpdRegs
                call PrintFrame                     ; else: go to PrintFrame
                jmp SkipPrintFrame

CheckHotKeyUpdRegs:
                cmp cs:[flg_frame_on_scrn], 0
                je SkipPrintFrame                   ; if (frame isn't on the screen) go to SkipPrintFrame
                cmp al, HOT_KEY_UPD_REGS            ;
                je SwitchFlagUpdatingRegs           ; if (AL == HOT_KEY_UPD_REGS) go to SwitchFlagUpdatingRegs
                jmp SkipPrintFrame                  ; else: go to SkipPrintFrame



SwitchFlagUpdatingRegs:                             ; change the value of the updating flag
                cmp cs:[flg_updating_regs], 0       ;
                jne TurnOffFlagUpdatingRegs         ; (if the flag was be 1, he will be 0)
                                                    ; (if the flag was be 0, he will be 1)
                mov cs:[flg_updating_regs], 1d      ;
                jmp SkipPrintFrame                  ;
                                                    ;
TurnOffFlagUpdatingRegs:                            ;
                mov cs:[flg_updating_regs], 0d      ;
                jmp SkipPrintFrame                  ;




SkipPrintFrame:
;                in al, 61h                          ; tell the keyboard that the signal has been read
;                or al, 80h                          ;
;                out 61h, al                         ;
;                and al, not 80h                     ;
;                out 61h, al                         ;

;                mov al, 20h                         ; tell the interrupts handler that the handling is finish
;                out 20h, al                         ;


                mov sp, cs:[value_sp]               ; return the values to the registers
                mov bp, cs:[value_bp]               ; instead of "pop"
                mov ax, cs:[value_ax]               ;
                mov bx, cs:[value_bx]               ;
                mov cx, cs:[value_cx]               ;
                mov dx, cs:[value_dx]               ;
                mov si, cs:[value_si]               ;
                mov di, cs:[value_di]               ;
                mov ds, cs:[value_ds]               ;
                mov es, cs:[value_es]               ;
                mov ss, cs:[value_ss]               ;


                db 0eah                             ; JMP FAR (return the management to the old handler)
offs_old_hand09 dw 0                                ;
segm_old_hand09 dw 0                                ;

                ret                                 ; will not to complete

ShowRegisters ENDP



PrintFrame PROC NEAR
                push ax bx cx dx si di bp sp ds es ss


                mov cs:[flg_frame_on_scrn], 1       ; set the flag of frame on the screen

                mov si, 1d                          ; SI is a number of register to the print (AX - 1; BX - 2; CX - 3; DX - 4; SI - 5; DI - 6; BP - 7; SP - 8; DS - 9; ES - 10; SS - 11; CS - 12; IP - 13)

PrintString:
;--------------------------------------------------------------;
;            prepare the data to printing registers            ;
;--------------------------------------------------------------;
                mov cx, 0                           ; counter (we need to print 4 symbols for each register) for label "PrintValue"

                                                    ; switch (si) {
                cmp si, 1d                          ;   case 1:
                    je PrepareAX                    ;       go to PrepareAX
                cmp si, 2d                          ;   case 2:
                    je PrepareBX                    ;       go to PrepareBX
                cmp si, 3d                          ;   case 3:
                    je PrepareCX                    ;       go to PrepareCX
                cmp si, 4d                          ;   case 4:
                    je PrepareDX                    ;       go to PrepareDX
                cmp si, 5d                          ;   case 5:
                    je PrepareSI                    ;       go to PrepareSI
                cmp si, 6d                          ;   case 6:
                    je PrepareDI                    ;       go to PrepareDI
                cmp si, 7d                          ;   case 7:
                    je PrepareBP                    ;       go to PrepareBP
                cmp si, 8d                          ;   case 8:
                    je PrepareSP                    ;       go to PrepareSP
                cmp si, 9d                          ;   case 9:
                    je PrepareDS                    ;       go to PrepareDS
                cmp si, 10d                         ;   case 10:
                    je PrepareES                    ;       go to PrepareES
                cmp si, 11d                         ;   case 11:
                    jne CheckCS                     ;
                    jmp near ptr PrepareSS          ;       go to PrepareSS
CheckCS:        cmp si, 12d                         ;   case 12:
                    jne CheckIP                     ;
                    jmp near ptr PrepareCS          ;       go to PrepareCS
CheckIP:        cmp si, 13d                         ;   case 13:
                    jne CheckDefault                ;
                    jmp near ptr PrepareIP          ;       go to PrepareIP
CheckDefault:   jmp DefaultRegister                 ;   default:
                                                    ;       go to DefaultRegister}



PrepareAX:
                mov di, offset base_text_ax         ; set offset the symbol for print to DI

                mov dx, cs:[value_ax]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareBX:
                mov di, offset base_text_bx         ; set offset the symbol for print to DI

                mov dx, cs:[value_bx]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareCX:
                mov di, offset base_text_cx         ; set offset the symbol for print to DI

                mov dx, cs:[value_cx]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareDX:
                mov di, offset base_text_dx         ; set offset the symbol for print to DI

                mov dx, cs:[value_dx]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareSI:
                mov di, offset base_text_si         ; set offset the symbol for print to DI

                mov dx, cs:[value_si]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareDI:
                mov di, offset base_text_di         ; set offset the symbol for print to DI

                mov dx, cs:[value_di]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareBP:
                mov di, offset base_text_bp         ; set offset the symbol for print to DI

                mov dx, cs:[value_bp]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareSP:
                mov di, offset base_text_sp         ; set offset the symbol for print to DI

                mov dx, cs:[value_sp]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareDS:
                mov di, offset base_text_ds         ; set offset the symbol for print to DI

                mov dx, cs:[value_ds]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareES:
                mov di, offset base_text_es         ; set offset the symbol for print to DI

                mov dx, cs:[value_es]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareSS:
                mov di, offset base_text_ss         ; set offset the symbol for print to DI

                mov dx, cs:[value_ss]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareCS:
                mov di, offset base_text_cs         ; set offset the symbol for print to DI

                mov dx, cs:[value_cs]               ; the value will be keep in DX
                jmp PrintBaseString

PrepareIP:
                mov di, offset base_text_ip         ; set offset the symbol for print to DI

                mov dx, cs:[value_ip]               ; the value will be keep in DX
                jmp PrintBaseString

DefaultRegister:
                mov ax, 4c00h
                int 21h
;--------------------------------------------------------------;
;                     the end of preparing                     ;
;--------------------------------------------------------------;



;--------------------------------------------------------------;
;                   start to print registers                   ;
;--------------------------------------------------------------;
PrintBaseString:
                mov al, cs:[di]                     ; transfer the symbol from CS:[DI] to AL (exacly CS, cause CS - segment where saved all functions and strings)
                mov ah, COLOR_TEXT

                cmp al, '$'                         ; if (symbol == '$'): go to PrintValue
                je PrintValue                       ;

                mov es:[bx], ax                     ; print symbol in his place
                add bx, 2d                          ; moving the place of print to 1 position (2 bytes)

                inc di                              ; get the next adress of symbol in base_text_ax
                jmp PrintBaseString


PrintValue:
                rol dx, 4d                          ; set to position 4 bits
                mov di, dx
                and di, 0000000000001111b           ; reset the remaining bits
                add di, offset convert_num          ; DI - offset to the right symbol in str convert_num, so CS:[DI] - symbol in HEX

                mov al, cs:[di]                     ; transfer the symbol from CS:[DI] to AL
                mov ah, COLOR_TEXT

                mov es:[bx], ax                     ; update the place (ES:[BX]) and print the symbol
                add bx, 2d                          ;

                inc cx                              ; counter++
                cmp cx, 4d                          ; if (cx < 4): go to PrintValue
                jb PrintValue                       ;


                add bx, 2 * (80 - 9)                ; transfer BX on the next string
                inc si
                cmp si, 13d                         ; if (SI > 13):        //13 - number of registers to print
                ja MakeFrame                        ; go to MakeFrame
                jmp near ptr PrintString            ; else: go to PrintString
;--------------------------------------------------------------;
;                   the end printing registers                 ;
;--------------------------------------------------------------;



MakeFrame:
;--------------------------------------------------------------;
;                    start to make a frame                     ;
;--------------------------------------------------------------;
                mov cx, 0                           ; CX - counter of symbols
MakeHorizontalLowerLine:
                mov al, 205                         ; ASCII code of the horizontal symbol
                mov ah, COLOR_TEXT
                mov es:[bx], ax

                add bx, 2d                          ; change the position of printing
                inc cx

                cmp cx, 9d                          ; if (cx < 9):
                jb MakeHorizontalLowerLine          ; go to MakeHorizontalLowerLine


MakeLowerRightCornerCharacter:
                mov al, 188                         ; ASCII code of the lower-right corner character
                mov ah, COLOR_TEXT
                mov es:[bx], ax


                sub bx, 2d * 80d                    ; change the position of printing to the next part of frame
                mov cx, 0                           ; CX - counter of symbols
MakeVerticalRightLine:
                mov al, 186                         ; ASCII code of the vertical symbol
                mov ah, COLOR_TEXT
                mov es:[bx], ax

                sub bx, 2d * 80d                    ; change the position of printing
                inc cx

                cmp cx, 13d                         ; if (cx < 9):
                jb MakeVerticalRightLine            ; go to MakeVerticalRightLine


MakeUpperRightCornerCharacter:
                mov al, 187                         ; ASCII code of the upper-right corner character
                mov ah, COLOR_TEXT
                mov es:[bx], ax


                sub bx, 2d                          ; change the position of printing to the next part of frame
                mov cx, 0                           ; CX - counter of symbols
MakeHorizontalUpperLine:
                mov al, 205                         ; ASCII code of the horizontal symbol
                mov ah, COLOR_TEXT
                mov es:[bx], ax

                sub bx, 2d                          ; change the position of printing
                inc cx

                cmp cx, 9d                          ; if (cx < 9):
                jb MakeHorizontalUpperLine          ; go to MakeHorizontalUpperLine


MakeUpperLeftCornerCharacter:
                mov al, 201                         ; ASCII code of the upper-right corner character
                mov ah, COLOR_TEXT
                mov es:[bx], ax


                add bx, 2d * 80d                    ; change the position of printing to the next part of frame
                mov cx, 0                           ; CX - counter of symbols
MakeVerticalLeftLine:
                mov al, 186                         ; ASCII code of the vertical symbol
                mov ah, COLOR_TEXT
                mov es:[bx], ax

                add bx, 2d * 80d                    ; change the position of printing
                inc cx

                cmp cx, 13d                         ; if (cx < 9):
                jb MakeVerticalLeftLine             ; go to MakeVerticalLeftLine


MakeLowerLeftCornerCharacter:
                mov al, 200                         ; ASCII code of the upper-right corner character
                mov ah, COLOR_TEXT
                mov es:[bx], ax
;--------------------------------------------------------------;
;                   the end to make a frame                    ;
;--------------------------------------------------------------;



EndOfPrintingRegisters:
                pop ss es ds sp bp di si dx cx bx ax
                ret

PrintFrame ENDP



;--------------------------------------------------------------;
;               updating registers in real time                ;
;--------------------------------------------------------------;
NewTimeHand PROC NEAR
                mov cs:[value_sp], sp               ; save the values from 
                mov cs:[value_bp], bp               ; save the value from BP
                mov cs:[value_ax], ax               ; save the values of registers to print

                mov bp, cs:[value_sp]               ; SP can be change, so we save the value SP in BP
                mov ax, [bp]                        ; save values of registers (IP, CS) from stack
                mov cs:[value_ip], ax               ;
                mov ax, [bp + 2]                    ;
                mov cs:[value_cs], ax               ;

                mov cs:[value_bx], bx               ;
                mov cs:[value_cx], cx               ;
                mov cs:[value_dx], dx               ;
                mov cs:[value_si], si               ;
                mov cs:[value_di], di               ;
                mov cs:[value_ds], ds               ;
                mov cs:[value_es], es               ;
                mov cs:[value_ss], ss               ;


                pushf
                call dword ptr cs:[offs_old_hand08]


                cmp cs:[flg_updating_regs], 0       ; if (flag of the udating registers is ON):
                jne UpdateRegisters                 ;   go to UpdateRegisters
                jmp EndOfUpdatingRegisters          ; else: go to EndOfUpdatingRegisters

UpdateRegisters:
                mov ax, VIDEO_SEG                   ; set the ES:BX (segment:offset) to the place of screen, where will be printing a first symbol
                mov es, ax                          ;
                mov bx, (80d * 2d + 64d) * 2d       ;

                call PrintFrame


EndOfUpdatingRegisters:
                mov sp, cs:[value_sp]               ; return the values to the registers
                mov bp, cs:[value_bp]               ; instead of "pop"
                mov ax, cs:[value_ax]               ;
                mov bx, cs:[value_bx]               ;
                mov cx, cs:[value_cx]               ;
                mov dx, cs:[value_dx]               ;
                mov si, cs:[value_si]               ;
                mov di, cs:[value_di]               ;
                mov ds, cs:[value_ds]               ;
                mov es, cs:[value_es]               ;
                mov ss, cs:[value_ss]               ;

                iret

NewTimeHand ENDP
;--------------------------------------------------------------;
;          the end of updating registers in real time          ;
;--------------------------------------------------------------;



.data
base_text_ax db 'AX = ', '$'
base_text_bx db 'BX = ', '$'
base_text_cx db 'CX = ', '$'
base_text_dx db 'DX = ', '$'
base_text_si db 'SI = ', '$'
base_text_di db 'DI = ', '$'
base_text_bp db 'BP = ', '$'
base_text_sp db 'SP = ', '$'
base_text_ds db 'DS = ', '$'
base_text_es db 'ES = ', '$'
base_text_ss db 'SS = ', '$'
base_text_cs db 'CS = ', '$'
base_text_ip db 'IP = ', '$'
value_ax     dw 0
value_bx     dw 0
value_cx     dw 0
value_dx     dw 0
value_si     dw 0
value_di     dw 0
value_bp     dw 0
value_sp     dw 0
value_ds     dw 0
value_es     dw 0
value_ss     dw 0
value_cs     dw 0
value_ip     dw 0
convert_num  db "0123456789ABCDEF"

offs_old_hand08     dw 0
segm_old_hand08     dw 0

flg_frame_on_scrn   db 0
flg_updating_regs   db 0



EndOfProgram:
End             Start