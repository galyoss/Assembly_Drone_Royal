
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
    extern target_pointer
    extern move_target
    extern create_target
    extern cors
    extern resume
    extern TARGET_STRUCT_IS_DESTROYED_OFFSET



    ; N<int> – number of drones
    ; R<int> - number of full scheduler cycles between each elimination
    ; K<int> – how many drone steps between game board printings
    ; T<int> – how many drone steps between target moves randomly
    ; d<float> – maximum distance that allows to destroy a target (at most 20)
    ; seed<int> - seed for initialization of LFSR shift register 


    run_target:
        mov esi, [target_pointer]
        add esi, TARGET_STRUCT_IS_DESTROYED_OFFSET
        cmp byte[esi], 1
        je _create_target

        _move_target:
            call move_target
            jmp _return_to_scheduler
        
        _create_target:
            call create_target

        _return_to_scheduler:
            mov ebx, [cors]     ; ebx = scheduler*
            call resume