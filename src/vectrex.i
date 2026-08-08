; =====================================================================
; Vectrex BIOS/RAM symbol definitions used by VECPAC A.E.
; No Vectrex BIOS ROM is included in this repository.
; =====================================================================



Wait_Recal      equ     $F192


Reset0Ref       equ     $F354
DP_to_D0        equ     $F1AA
DP_to_C8        equ     $F1AF


Intensity_1F    equ     $F29D
Intensity_3F    equ     $F2A1
Intensity_5F    equ     $F2A5
Intensity_7F    equ     $F2A9
Intensity_a     equ     $F2AB


Moveto_d        equ     $F312
Moveto_d_7F     equ     $F2FC
Draw_Line_d     equ     $F3DF
Draw_VLc        equ     $F3CE
Draw_VL_mode    equ     $F46E
Dot_d           equ     $F2C3


Print_Str_d     equ     $F37A


Print_Str       equ     $F495


Print_Str_yx    equ     $F378
Print_Str_hwyx  equ     $F373


Read_Btns       equ     $F1BA
Joy_Digital     equ     $F1F8
Joy_Analog      equ     $F1F5


Clear_Sound     equ     $F272
Do_Sound        equ     $F289
Init_Music_chk  equ     $F687


Vec_Snd_Shadow  equ     $C800
Vec_Music_Work  equ     $C83F
SND_REG         equ     $C84C


Vec_Btn_State   equ     $C80F
Vec_Joy_Resltn  equ     $C81A
Vec_Joy_1_X     equ     $C81B
Vec_Joy_1_Y     equ     $C81C
Vec_Joy_2_X     equ     $C81D
Vec_Joy_2_Y     equ     $C81E


Vec_Joy_Mux_1_X equ     $C81F
Vec_Joy_Mux_1_Y equ     $C820
Vec_Joy_Mux_2_X equ     $C821
Vec_Joy_Mux_2_Y equ     $C822
Vec_Misc_Count  equ     $C823
Vec_Text_HW     equ     $C82A
Vec_Text_Width  equ     $C82B
Vec_Music_Flag  equ     $C856


music1          equ     $FD0D
music2          equ     $FD1D
music3          equ     $FD81
music4          equ     $FDD3
music5          equ     $FE38
music6          equ     $FE76
music7          equ     $FEC6
music8          equ     $FEF8
music9          equ     $FF26
musica          equ     $FF44
musicb          equ     $FF62
musicc          equ     $FF7A
musicd          equ     $FF8F
