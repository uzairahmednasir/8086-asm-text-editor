.MODEL SMALL
.DATA
    matrix      db 80*25 dup(?),'$' ;25 lines of 80 chars each 
    matrix_2    db 22 dup(?)        ;   
    row         db 2                ;for navigating columns/character cells with arrow keys
    column      db 0                ;for navigating rows/lines with arrow keys
    curr_line   db 2                ;rows/lines while editing
    curr_char   db 0                ;columns/chars while editing
    ;for main menu
    deco1       db '  =================================================$'
    deco2       db '||            Command Line Text Editor             ||$'
    deco3       db '||                                                 ||$'
    deco4       db '||         ESC = Exit || CTRL+S = Save File        ||$'
    deco5       db '||              ARROW KEYS = Navigate              ||$'
    deco6       db '  =================================================$'
    docPrompt   db 'Enter Document Name (.txt): $'
    docName     dw 50 dup(?),'$'
    openPrompt  db 'Enter Document Name to Open: $'
    HANDLE      dw ? 
    header      db 80 dup('='),'$'    
    color       db 3*15+15
    
          
.CODE 

;=========== MACROS ===========
newline macro
    mov dl, 10       ;newline ASCII
    mov ah, 2
    int 21h   
    mov dl, 13       ;linefeed (return) ASCII
    mov ah, 2
    int 21h
endm
remove macro
    mov dx, 8        ;backspace to go back one char
    mov ah, 2
    int 21h
    mov dx, 32       ;space to remove that char
    mov ah, 2
    int 21h
    mov dx, 8        ;backspace to go back at removed char position
    mov ah, 2
    int 21h
endm
goto_pos macro row, col
    mov ah, 02h      ;set text position in middle screen
    mov dh, row
    mov dl, col
    int 10h
endm
clrScrn macro
    mov ah, 02h    ;set cursor to upper left corner
    mov dh, 0
    mov dl, 0
    int 10h            
    mov ah, 0Ah    ;overwrite with blank chars & remove all chars
    mov al, 00h    ;character
    mov cx, 2000  ;how many times to write
    int 10h        ;graphics interrupt
endm 
debug macro arg
    mov dx, arg    ;for debugging purpose
    mov ah, 2
    int 21h
endm

;=============== PROCEDURES ===============
start_menu proc
    ;DISPLAY MAIN MENU
    goto_pos 5, 12
    mov dx, offset deco1      ;decoration 1
    mov ah, 9
    int 21h
    goto_pos 6, 12
    mov dx, offset deco2      ;decoration 2
    mov ah, 9
    int 21h
    goto_pos 7, 12
    mov dx, offset deco3      ;decoration 3
    mov ah, 9
    int 21h
    goto_pos 8, 12
    mov dx, offset deco4      ;decoration 4
    mov ah, 9
    int 21h
    goto_pos 9, 12
    mov dx, offset deco5      ;decoration 5
    mov ah, 9
    int 21h
    goto_pos 10, 12
    mov dx, offset deco6      ;decoration 6
    mov ah, 9
    int 21h
    goto_pos 13, 12
    mov dx, offset docPrompt  ;prompt doc name field
    mov ah, 9
    int 21h
    
    ;INPUT CHARS IN DOC NAME FIELD 
    mov cx, 0  ;array size counter
    mov si, offset docName
    input_char: 
    mov ah, 1
    int 21h
    cmp al, 13          ;check if return key hit
    je return
    cmp al, 8           ;check if backspace key hit
    je remove_char
    inc cx              ;increment array size by 1
    mov [si], al
    inc si
    jmp input_char
    
    remove_char:
    cmp cx, 0
    je setPos_ret
    dec cx              ;decrement array size by 1
    dec si
    mov [si], 00h
    
    mov dl, 32          ;for removing char
    mov ah, 2           ;
    int 21h             ;
    mov dl, 8           ;
    mov ah, 2           ;
    int 21h             ;
    jmp input_char
    
    setPos_ret:
    goto_pos 13, 40
    jmp input_char 
    
    return:    ;clear the screen and return procedure
    ret 
start_menu endp

upper_bar proc
    goto_pos 0 0
    mov dx, offset docName  ;display DOCNAME on upper corner
    mov ah, 9
    int 21h
    goto_pos 1 0
    mov dx, offset header
    mov ah, 9
    int 21h
    
    ret            
upper_bar endp

;=============== MAIN ===============
MAIN PROC
    mov ax, @DATA
    mov ds, ax 
    
    mov ah, 01h        ;Define Text Cursor Shape
    mov cx, 07h        ;
    int 10h            ; 
    clrScrn
    call start_menu    ;call start menu 
    clrScrn            ;clear screen macro
    call upper_bar     ;call upper stats bar in editor UI
    
    goto_pos 2, 0      ;set cursor position beneath upper bar
    
    mov si, offset matrix 
    mov di, offset matrix_2
    MAIN_LOOP:                                   
    ; Get keystroke
    mov ah, 00h
    int 16h
    ; AH = BIOS scan code
    cmp ah, 01h            ;if escape key
    je EXIT
    cmp al, 13h            ;if CTRL+S
    je SAVE
    cmp al, 0Fh            ;if CTRL+O
    je OPEN
    cmp ah, 48h            ;if up arrow
    je UP
    cmp ah, 50h            ;if down arrow
    je DOWN
    cmp ah, 4Bh            ;if left arrow
    je LEFT
    cmp ah, 4Dh            ;if right arrow
    je RIGHT                             
    cmp ah, 1Ch            ;if enter (newline) key
    je ENTER                                    
    cmp ah, 0Eh            ;if backspace (remove character)
    je BACKSPACE       
    
    cmp column, 79
    je ENTER
    mov dl, al             ;if any other key then write char on screen
    mov ah, 2
    int 21h        
    mov [si], al           ;add char in matrix array
    inc si
    inc curr_char          ;increment char position on current row
    inc column             ;also increment the current character count
    goto_pos row, column
    jmp MAIN_LOOP
         
    EXIT:
    mov ah, 4ch
    int 21h
        
    SAVE:
    mov ah, 3Ch             ;creating a file
    mov cx, 0               ;read-only file
    mov dx, offset docName  ;giving name which we took from Main Menu Doc Name Input
    int 21h                 
    mov ah, 3Dh             ;opening file
    mov al, 1               ;for writing mode
    mov dx, offset docName  ;which file
    int 21h
    mov HANDLE, ax          ;setting up handler
    mov ah, 40h             ;function for writing files
    mov bx, HANDLE          ;search for file handler
    mov cx, 2000            ;how many bytes to write in file
    mov dx, offset matrix   ;what to write
    int 21h
    jmp MAIN_LOOP  
    
    OPEN:
    goto_pos 22 0    ;go to bottom to write open file prompt
    mov dx, offset openPrompt
    mov ah, 9
    int 21h
    ;INPUT CHARS IN DOC NAME FIELD 
    mov cx, 0  ;array size counter
    mov di, offset docName
    input_char2: 
    mov ah, 1
    int 21h
    cmp al, 13          ;check if return key hit
    je return2
    cmp al, 8           ;check if backspace key hit
    je remove_char2
    inc cx              ;increment array size by 1
    mov [di], al
    inc di
    jmp input_char2
    remove_char2:
    cmp cx, 0
    je setPos_ret2
    dec cx              ;decrement array size by 1
    dec di
    mov [di], 00h
    mov dl, 32          ;for removing char
    mov ah, 2           ;
    int 21h             ;
    mov dl, 8           ;
    mov ah, 2           ;
    int 21h             ;
    jmp input_char2
    setPos_ret2:
    goto_pos 22, 29
    jmp input_char2
    return2:            ;clear the screen and return procedure
    clrScrn
    call upper_bar 
    goto_pos 2, 0           ;set cursor position beneath upper bar
    mov ah, 0x3d             ;to open files
    mov al, 00               ;file handler for reading files
    mov dx, offset docName
    int 21h
    mov HANDLE, ax           ;setting up handler
    mov ah, 0x3f             ;function for reading files
    mov bx, HANDLE
    mov cx, 1760             ;how many bytes to write
    mov dx, offset matrix    ;where to save read data
    int 21h       
    mov dx, offset matrix    ;print the text on editor canvas
    mov ah, 9                ;
    int 21h                  ;
    jmp MAIN_LOOP            
           
    UP:
    cmp row, 2
    je MAIN_LOOP 
    dec curr_line
    dec row
    goto_pos row, column
    jmp MAIN_LOOP
         
    DOWN:
    inc curr_line
    inc row
    goto_pos row, column 
    jmp MAIN_LOOP
           
    LEFT:
    dec column
    goto_pos row, column
    jmp MAIN_LOOP
    
    RIGHT:
    inc column
    goto_pos row, column
    jmp MAIN_LOOP
    
    ENTER:      
    newline         ;newline macro
    mov [si], 10    ;move newline into array 
    inc si
    mov dl, curr_char
    mov [di], dl
    inc di
    inc curr_line
    mov curr_char, 0
    inc row             ;increment row number
    mov column, 0       ;get hold of 0th Col for Navigation
    goto_pos row, 0     ;to get on newline 0th column
    jmp MAIN_LOOP
    
    BACKSPACE:
    ;IF TRUE
    cmp curr_line, 2    ;see if cursor is on the very 1st line of document
    ;THEN DO THIS
    je rmv              ;if TRUE, then just Remove the chars from matrix
    ;IF TRUE
    cmp curr_char, 0    ;see if cursor is on the 0th POS on most left
    ;THEN DO THIS
    je goBackLine       ;if TRUE, then go back to upper row at the latest character's POS
    ;ELSE DO THIS
    remove
    dec curr_char
    dec column
    dec si
    mov [si], 00h
    jmp MAIN_LOOP
    rmv:
    remove
    dec curr_char
    dec column
    dec si              ;decrement si
    mov [si], 00h       ;fill NULL in removed char space in array 
    jmp MAIN_LOOP
    goBackLine:
    dec curr_line
    dec row
    dec di
    mov dl, [di]
    mov column, dl
    goto_pos curr_line, dl  ;go to the last character position in previous row
    mov dl, [di]        ;moving in another register because size doesn't match
    mov curr_char, dl   ;to reset the cursor to the last position of previous line
    jmp MAIN_LOOP
        
MAIN ENDP
END MAIN 