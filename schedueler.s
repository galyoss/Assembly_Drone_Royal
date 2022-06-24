
%macro func_start 0
    push ebp
    mov ebp, esp
%endmacro

%macro func_end 0
    mov esp, ebp
    pop ebp
    ret
%endmacro

%macro modulu 2
    mov eax, [%1]         
    xor edx, edx             
    mov ebx, [%2]            
    div ebx       ; edx = %1 mod %2
%endmacro

section	.rodata

section .data
    curr_step: dd 0
    num_of_drones_left: dd 0
    drones_eliminated_this_round: dd 0

section .bss
    
section .text
    extern Nval
    extern Rval
    extern Kval
    extern Tval
    extern resume



    ; N<int> – number of drones
    ; R<int> - number of full scheduler cycles between each elimination
    ; K<int> – how many drone steps between game board printings
    ; T<int> – how many drone steps between target moves randomly
    ; d<float> – maximum distance that allows to destroy a target (at most 20)
    ; seed<int> - seed for initialization of LFSR shift register 

run_schedueler:
    func_start
    mov dword[curr_step], 0
    mov ebx, dword[N]
    mov dword[num_of_drones_left], ebx 

    _loop: 
        ;checking if elimination is next
        modulu dword[curr_step], dword[Rval]    ;now edx hold curr_step%R
        cmp edx, 0
        je _eliminate

        ;checking if print is next
        _check_print: 
        modulu dword[curr_step], dword[Kval]    ;now edx hold curr_step%K
        cmp edx, 0
        je _print_board

        _check_move_target:
        modulu dword[curr_step], dword[Tval]    ;now edx hold curr_step%T
        cmp edx, 0
        je _move_target

        _check_drone_alive:
        modulu dword[curr_step], dword[Nval]    ;now edx hold curr_step%R
        mov dword[currDrone], edx           ;saving curr_drone index for later use
        mov ebx, dword[DronesArrayPointer]
        add ebx, dword[edx * 4]          ;now ebx points to curr drone
        cmp [ebx + DRONE_STRUCT_ACTIVE], 1
        je _call_drone_cor
        jmp _loop_end


        _eliminate:
            xor ecx, ecx        ; index
            mov esi, 2147483647 ; min KILL VALUE
            xor edx, edx        ;   curr min kill drone index


            _eliminate_loop:
                cmp ecx, dword[Nval]        ; while i<N
                je _end_eliminate_loop
                mov eax, dword[DronesArrayPointer + ecx*4]              ;eax = curr drone*
                cmp byte[eax+DRONE_STRUCT_ACTIVE_OFFSET], 0         ;isAlive() ?
                je _continue
                cmp esi, dword[eax+DRONE_STRUCT_KILLS_OFFSET]        ; curr min > ? drone kills
                jb _continue
                mov esi, dword[eax+DRONE_STRUCT_KILLS_OFFSET]         ; curr min = curr drone kills
                mov edx, ecx
                _continue:
                inc ecx
                jmp _eliminate_loop

            _end_eliminate_loop:
                mov eax, dword[DronesArrayPointer + edx*4]           ;eax = loser drone*
                mov byte[eax+DRONE_STRUCT_ACTIVE_OFFSET], 0         ;loser was eliminated

                dec [num_of_drones_left]
                cmp [num_of_drones_left], 1
                ;TODO JUMP EQUALS END GAME (print board, return to main, free all cors)
                inc [drones_eliminated_this_round]
                cmp [drones_eliminated_this_round], 1
                je _eliminate
                mov [drones_eliminated_this_round], 0

            jmp _check_print
        _print_board:
            mov ebx, dword[cors+16]         ; move pointer of printer coroutine to ebx
            call resume                     ; resume printer
            jmp _check_move_target          ; board was printed
        _move_target:
            mov ebx, dword[cors+8]          ; move target of printer coroutine to ebx
            call resume                     ; resume target
            jmp _check_drone_alive          ; target was moved
        _call_drone_cor:
            ;edx holds i%N
            add edx, 3                      ;   drones corourtines start at index 3
            mov ebx, [cors + edx*8]         ; size of cors struct is 8, now ebx holds pointer to curr drone coroutine
            call resume                     ; resume curr drone
        _loop_end:
            inc [curr_step]                 ; i++
            jmp _loop

func_end

;TODO -> check if func start and func end are needed here, because resume and do resume take care of same things i think

