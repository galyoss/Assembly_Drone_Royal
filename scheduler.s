
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
string_format: db "%s", 10, 0			
	decimal_format: db "%d", 0  			
	float_format: db "%.2f", 0 			    ;2digit precision
    new_line_format: db 10, 0
    comma_format: db ",", 0
    DroneStructLen: equ 37 ; 8xpox, 8ypos, 8angle, 8speed, 4kills, 1isActive
    DRONE_STRUCT_XPOS_OFFSET: equ 0
    DRONE_STRUCT_YPOS_OFFSET: equ 8
    DRONE_STRUCT_HEADING_OFFSET: equ 16
    DRONE_STRUCT_SPEED_OFFSET: equ 24
    DRONE_STRUCT_KILLS_OFFSET: equ 32
    DRONE_STRUCT_ACTIVE_OFFSET: equ 36
    DRONE_STRUCT_KILLS:
    TARGET_STRUCT_SIZE: equ 17
    TARGET_STRUCT_XPOS_OFFSET: equ 0
    TARGET_STRUCT_YPOS_OFFSET: equ 8
    TARGET_STRUCT_IS_DESTROYED_OFFSET: equ 16
    MAX_DEGREE: equ 360
    CO_STK_SIZE: equ 16384 ; 16*1024
    BIT_MASK_16: equ 1
    BIT_MASK_14: equ 4
    BIT_MASK_13: equ 8
    BIT_MASK_11: equ 32
    MAX_SEED: equ 65535
    MAX_SPEED: equ 50
    MAX_ANGLE_DELTA_LIM: equ 60
    MIN_ANGLE_DELTA_LIM: equ -60
    BOARD_SIZE: equ 100
    format_d:   db "%d", 0
    format_f:   db "%f", 0
    MAX_DELTA_DEG_RANGE: equ 120
    MAX_DELTA_POS_RANGE: equ 10
    scaled_rnd_format: db "Scaled rnd with limit of %d, resuly is %d", 10, 0
    loop_sched_format: db "looping sched", 10, 0


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
    extern printf
    extern currDrone
    extern cors
    extern DronesArrayPointer
    extern DRONE_STRUCT_ACTIVE
    extern DronesArrayPointer
    extern DronesArrayPointer
    extern printer_co_index
    extern target_co_index
    global run_schedueler
    global num_of_drones_left



    ; N<int> – number of drones
    ; R<int> - number of full scheduler cycles between each elimination
    ; K<int> – how many drone steps between game board printings
    ; T<int> – how many drone steps between target moves randomly
    ; d<float> – maximum distance that allows to destroy a target (at most 20)
    ; seed<int> - seed for initialization of LFSR shift register 

run_schedueler:
    func_start
    mov dword[curr_step], 0
    mov ebx, dword[Nval]
    mov dword[num_of_drones_left], ebx 

    _loop: 
        push loop_sched_format
        call printf
        add esp, 4
        ;checking if elimination is next
        modulu curr_step, Rval    ;now edx hold curr_step%R
        cmp edx, 0
        je _eliminate

        ;checking if print is next
        _check_print: 
        modulu curr_step, Kval    ;now edx hold curr_step%K
        cmp edx, 0
        je _print_board

        _check_move_target:
        modulu curr_step, Tval    ;now edx hold curr_step%T
        cmp edx, 0
        je _move_target

        _check_drone_alive:
        modulu curr_step, Nval    ;now edx hold curr_step%R
        mov dword[currDrone], edx           ;saving curr_drone index for later use
        mov ebx, dword[DronesArrayPointer]
        add ebx, dword[edx * 4]          ;now ebx points to curr drone
        cmp byte [ebx + DRONE_STRUCT_ACTIVE_OFFSET], 1
        je _call_drone_cor
        jmp _loop_end


        _eliminate:
            xor ecx, ecx        ; index
            mov esi, 2147483647 ; min KILL VALUE
            xor edx, edx        ;   curr min kill drone index


            _eliminate_loop:
                cmp ecx, dword[Nval]        ; while i<N
                je _end_eliminate_loop
                mov eax, dword [DronesArrayPointer]
                ;shl ecx, 2
                ;add eax, ecx
                ;shr ecx, 2
                mov eax, dword[eax+ecx*4]              ;eax = curr drone*
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
                mov eax, [DronesArrayPointer]
                mov eax, dword[eax + edx*4]           ;eax = loser drone*
                mov byte[eax+DRONE_STRUCT_ACTIVE_OFFSET], 0         ;loser was eliminated

                ; cmp dword [num_of_drones_left], 1
                ; jle _end_game
                dec dword [num_of_drones_left]
                cmp dword [num_of_drones_left], 1
                jle _end_game
                ;TODO JUMP EQUALS END GAME (print board, return to main, free all cors)
                inc dword [drones_eliminated_this_round]
                cmp dword [drones_eliminated_this_round], 1
                je _eliminate
                mov dword [drones_eliminated_this_round], 0
                jmp _check_print

        _print_board:
            push ecx
            mov ebx, [cors]
            mov ecx, [printer_co_index]
            shl ecx, 3
            add ebx, ecx                    ;מow ebx points to printer co
            pop ecx
            call resume                     ; resume printer
            jmp _check_move_target          ; board was printed
        _move_target:
            push ecx
            mov ebx, [cors]
            mov ecx, [target_co_index]
            shl ecx, 3
            add ebx, ecx                    ;מow ebx points to target co
            pop ecx
            call resume                     ; resume printer
            jmp _check_drone_alive          ; target was moved
        _call_drone_cor:
            ;edx holds i%N
            mov ebx, cors
            shl edx, 3
            add ebx, edx
            shr edx, 3
            call resume                     ; resume curr drone
        _loop_end:
            inc dword [curr_step]                 ; i++
            jmp _loop

func_end

_end_game:
    ; print end game
    ; exit
    mov eax, 1
    mov ebx, 0
    int 0x80
;TODO -> check if func start and func end are needed here, because resume and do resume take care of same things i think


