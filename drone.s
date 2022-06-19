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

section .bss
    
section .text
    extern Nval
    extern move_drone
    extern mayDestroy
    extern resume
    extern target_pointer
    extern TARGET_STRUCT_IS_DESTROYED_OFFSET
    extern DRONE_STRUCT_KILLS_OFFSET
    extern DronesArrayPointer
    extern currDrone
    extern cors
    global run_drone



    ; N<int> – number of drones
    ; R<int> - number of full scheduler cycles between each elimination
    ; K<int> – how many drone steps between game board printings
    ; T<int> – how many drone steps between target moves randomly
    ; d<float> – maximum distance that allows to destroy a target (at most 20)
    ; seed<int> - seed for initialization of LFSR shift register 


    run_drone:
        call move_drone         ;now drone has new position
        call mayDestroy        ;eax holds boolean , TODO ask gal what are the params
        cmp eax, 0
        je _drone_end
        ;may destroy = true
        mov esi, target_pointer
        add esi, TARGET_STRUCT_IS_DESTROYED_OFFSET
        mov byte[esi], 1     ;set target to destroyed, TODO check if need to use register first
        mov ebx, dword[DronesArrayPointer]
        mov esi, [currDrone]
        shl esi, 2
        add ebx, esi        ;now ebx points to curr drone
        add dword[ebx + DRONE_STRUCT_KILLS_OFFSET], 1 ;INC DRONE KILLS, TODO: check if register is needed first

    _drone_end:
        mov ebx, cors                   ;ebx = pointer to scheduler struct
        call resume