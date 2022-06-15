;; init drones
;; mayDestroy
;; move



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
    extern N



    ; N<int> – number of drones
    ; R<int> - number of full scheduler cycles between each elimination
    ; K<int> – how many drone steps between game board printings
    ; T<int> – how many drone steps between target moves randomly
    ; d<float> – maximum distance that allows to destroy a target (at most 20)
    ; seed<int> - seed for initialization of LFSR shift register 


    run_drone:
        call move_drone         ;now drone has new position
        call may_destroy        ;eax holds boolean , TODO ask gal what are the params
        cmp eax, 0
        je _drone_end
        ;may destroy = true
        mov byte[target_pointer + TARGET_STRUCT_IS_DESTROYED_OFFSET], 1     ;set target to destroyed, TODO check if need to use register first
        mov ebx, dword[DronesArrayPointer]
        add ebx, dword[curr_drone * 4]          ;now ebx points to curr drone
        add [ebx + DRONE_STRUCT_KILLS_OFFSET], 1 ;INC DRONE KILLS, TODO: check if register is needed first

    _drone_end:
        mov ebx, dword[cors]                    ;ebx = pointer to scheduler struct
        call resume