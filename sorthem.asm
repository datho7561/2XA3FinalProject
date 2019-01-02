
%include "asm_io.inc"

SEGMENT .data

    ; Strings
    error1:      db "Incorrect number of command line arguments!",0
    error2:      db "Number of disks out of range!",0
    usage:       db "Usage: n",10,"n: Number of disks, 2 <= n <= 9",0

    initial      db "Initial configuration:",0
    final        db "Final configuration:",0
    
    peg_base:    db "XXXXXXXXXXXXXXXXXXXXX",0
    
    ; Intialize an array for the peg to zero
    peg_arr:     dd 0,0,0,0,0,0,0,0,0



SEGMENT .bss

    ; Number of disks
    num_disks:   resd 1



SEGMENT .text

global asm_main



; Sort the disks recursively using a variation of insertion sort (I think that's what this algorithm is)
sorthem:


    enter 0, 0
    pusha


    ; Access the command line arguments
    mov edx, [ebp + 8]              ; get the pointer to the array
    mov ebx, [ebp + 12]             ; get the size of the array

    
 
    cmp ebx, dword 1                ; if the array is of size one it is sorted
    je SORTHEM_END                  ; Might as well skip checking if printing 
                                    ; is needed because we already know that no

    
    ; Recursive call to sorthem with parameters (arraypointer + 4) and (sizeofarray - 1)
    mov eax, ebx
    sub eax, 1
    push eax
    mov eax, edx
    add eax, 4
    push eax
    call sorthem
    add esp, 8
    

    ; The top pegs are now sorted

    ; Iterate through the disks and swap the current disk until it is in the right spot
    SWAPPING_LOOP:

    mov eax, [edx + 4]              ; The value of the next element in the array is now in eax
    cmp [edx], eax
    ja SORTHEM_PRINT                ; If the next value is smaller, disk is in place, no need to do more swapping
    
    ; Swap this value and the next value using ecx as the intermediary variable
    mov ecx, [edx]
    mov [edx], eax
    mov [edx + 4], ecx

    ; Decrement the counter (ebx) and move the array pointer to the next value
    sub ebx, 1
    add edx, 4

    ; If there are still possible swaps, keep going (otherwise fall through)
    cmp ebx, dword 1
    ja SWAPPING_LOOP



    SORTHEM_PRINT:

    ; Check if no swaps were done. If this is the case, don't bother printing
    cmp ebx, [ebp + 12]             ; Check counter against original value. If same, no swaps were performed
    je SORTHEM_END

    ; Call showp to see the current configuration
    mov eax, [num_disks]            ; Push the FULL array size
    push eax
    mov eax, peg_arr                ; Push the FULL array pointer
    push eax
    call showp
    add esp, 8

    SORTHEM_END:

    popa
    leave
    ret



; Subroutine to draw a disk
display_disk:
    
    enter 0,0
    pusha

    ; Get the size of the disk
    mov ecx, [ebp + 8]


    mov ebx, 10
    sub ebx, ecx               ; Set ebx to the number of spaces that need to be printed

    ; Print the spaces before the start of the disk
    SPACE_PRINT_LOOP:
    mov al, byte ' '
    call print_char
    
    sub ebx, 1           ; Decrement counter
    cmp ebx, 0
    jg SPACE_PRINT_LOOP


    ; Set up ebx as a counter
    mov ebx, ecx
    mov al, byte 'o'           ; Put the character for the disk in al

    LETTER_PRINT_LOOP_1:

    call print_char

    ; Check if we need to keep going
    sub ebx, 1
    cmp ebx, 0
    jg LETTER_PRINT_LOOP_1


    ; Print the pipe
    mov al, byte '|'
    call print_char
    

    ; Set up ebx as a counter and put the character for the disk in al
    mov ebx, ecx
    mov al, byte 'o'


    ; Print the rest of the disk
    LETTER_PRINT_LOOP_2:

    call print_char

    ; Check if we need to keep going
    sub ebx, 1
    cmp ebx, 0
    jg LETTER_PRINT_LOOP_2


    ; Print a newline to make things look pretty
    call print_nl
    popa
    leave
    ret



; Print the current configuration of the disks
showp:

    enter 0, 0
    pusha


    ; Get the value of the parameters
    mov ebx, dword [ebp + 8]            ; Holds the address of the peg array
    mov ecx, dword [ebp + 12]           ; Holds the number of items on the peg


    ; Set up ebx to point at the last element instead of the first
    mov eax, ecx
    sub eax, 1
    shl eax, 2                          ; Multiply eax by 4 using bitshifts because multiplying 
    add ebx, eax                        ;  by a constant is less efficient and harder to figure out


    ; print the configuration to the standard output using a loop

    mov edx, 0                          ; Use edx as a counter for the printing loop

    PEGPRINTLooP:
    
    mov eax, dword [ebx]
    push eax
    call display_disk                   ; Set up and call the function to print the disk
    add esp, 4
 
    inc edx                             ; increment the counter
    sub ebx, dword 4                    ; Move ebx to the next number, recalling 
                                        ; that we are printing starting the end of the array


    ; Check if we are done printing or not
    cmp edx, ecx 
    jb PEGPRINTLooP


    ; Print the base
    mov eax, peg_base
    call print_string
    call print_nl


    ; Wait for the user to press a character
    call read_char


    ; Return to the calling function
    popa
    leave
    ret



; Entry point for c driver code
asm_main:
    
    enter 0,0
    pusha


    ; Get the number of command line args and store in register b
    mov ebx, dword [ebp+8]

    ; Check number against 2, the expected number of command line arguments
    cmp ebx, dword 2
    je NUM_GOOD
    
    ; Print that the number of arguments was incorrect
    mov eax, error1
    call print_string
    
    ; Print a newline
    call print_nl
    
    ; Print usage
    mov eax, usage
    call print_string
    call print_nl

    ; Jump to error ending
    jmp END_BAD


    ; If the correct number of arguments are input
    NUM_GOOD:

    ; Move the address of the first string into reg b
    mov ebx, [ebp+12]
    mov ebx, [ebx + 4]                 ; Put pointer to first char of second string in ebx
    mov cl, byte [ebx+1]               ; Move the second character into cl reg

    ; Check if the second character is the null-terminator
    cmp cl, byte 0
    je INPUT_LENGTH_GOOD


    ; If the length of the input string is wrong
    mov eax, error2
    call print_string
    call print_nl
    mov eax, usage
    call print_string
    call print_nl
    
    jmp END_BAD


    ; If the length of the input string is good
    INPUT_LENGTH_GOOD:
    
    mov cl, byte [ebx]                 ; Move the first character of the string into the al reg
    
    cmp cl, byte '1'
    jg LOWER_BOUNDS_GOOD

    
    ; Number is out of range; output error message, usage, and exit with error code
    mov eax, error2
    call print_string
    call print_nl
    mov eax, usage
    call print_string
    call print_nl
    
    jmp END_BAD


    ; If lower bounds are good, then the upper bounds are good because 10 requires two characters
    LOWER_BOUNDS_GOOD:

    

    ; This is where the error handling ends and the interesting part of
    ; the program begins



    ; Calculate the number and stow it away in the .bss segment
    sub cl, '0'                        ; Convert the input into an unsigned number
    mov edx, 0
    add dl, cl                         ; Cleanup the number and put into edx for pushing
    mov [num_disks], edx               ; Stow


    ; Make the peg configuration using rconf
    mov eax, peg_arr
    push edx                           ; Push the number of items on the peg
    push eax                           ; Push the pointer to the array for rconf
    call rconf                         ; Call the randomization function and cleanup parameters
    add esp, 8


    ; Print the initial configuration string
    mov eax, initial
    call print_string
    call print_nl
    call print_nl


    ; Call the function to print the configuration of the stack
    mov edx, [num_disks]
    mov eax, peg_arr
    push edx
    push eax
    call showp
    add esp, 8


    ; Call the function to sort the disks
    mov edx, [num_disks]
    mov eax, peg_arr
    push edx
    push eax
    call sorthem
    add esp, 8


    ; Print the final configuration string
    mov eax, final
    call print_string
    call print_nl
    call print_nl


    ; Call the function to print the configuration of the stack
    mov edx, [num_disks]
    mov eax, peg_arr
    push edx
    push eax
    call showp
    add esp, 8



    END:
    
    ; Return values to registers, leave the stack frame, and return control to the c driver
    popa
    mov eax, 0                    ; Don't forget that you are returning 0 for success
    leave
    ret

    ; Same as the first end, excepts puts 1 in eax to indicate an error
    END_BAD:
 
    popa
    mov eax, 1
    leave
    ret

