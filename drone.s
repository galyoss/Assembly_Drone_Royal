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
        push ecx
        mov ecx, target_pointer
        add ecx, TARGET_STRUCT_IS_DESTROYED_OFFSET
        mov [ecx], 1     ;set target to destroyed, TODO check if need to use register first
        mov ebx, dword[DronesArrayPointer]
        mov ecx, [currDrone]
        add edx, [currDrone]
        add edx, [currDrone]
        add edx, [currDrone] ;Yes this is the most ugly thing, I just want it to fucking work already
        add ebx, [ecx]         ;now ebx points to curr drone
        add dword [ebx + 32], 1                       ;INC DRONE KILLS, TODO: check if register is needed first
        pop ecx

    _drone_end:
        mov ebx, dword[cors]                    ;ebx = pointer to scheduler struct
        call resume