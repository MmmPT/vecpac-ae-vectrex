; =====================================================================
; VECPAC A.E. cartridge supervisor
; Main menu and shared campaign logic for the three cartridge modes.
; 6809 assembly for the GCE/Milton Bradley Vectrex.
; =====================================================================



        include "vectrex.i"

        org     $0000

        fcc     "g GCE 2026"
        fcb     $80
        fdb     music1
        fcb     $F8
        fcb     $50
        fcb     $20
        fcb     $C0
        fcc     "VECPAC A.E."
        fcb     $80
        fcb     $00


mode            equ     $C940
glevel          equ     $C941
cycle           equ     $C942
menu_sel        equ     $C943
menu_rdy        equ     $C944
sup_sp          equ     $C945
menu_last       equ     $C947
sh_score        equ     $C948
sh_lives        equ     $C94B

MODE_FULL       equ     1
MODE_JETPAC     equ     2
MODE_GX         equ     3
TOTAL_LEVELS    equ     30
JP_PER_CYCLE    equ     8
CYCLE_LEN       equ     10
MENU_X          equ     -58
MARK_X          equ     -66
MENU_W          equ     $40


CART            equ     1


main:
        sts     sup_sp
        lda     #MODE_FULL
        sta     menu_sel
        clr     menu_rdy
        ldx     #hi_table
        ldb     #HI_COUNT*3
mn_hi:
        clr     ,x+
        decb
        bne     mn_hi


menu:
        jsr     Wait_Recal
        jsr     Intensity_5F
        jsr     menu_input

        lda     #$F8
        sta     Vec_Text_HW
        lda     #$50
        sta     Vec_Text_Width

        lda     #70
        ldb     #-30
        ldu     #txt_t1
        jsr     mn_print


        lda     #MENU_W
        sta     Vec_Text_Width

        lda     #12
        ldb     #MENU_X
        ldu     #txt_m1
        jsr     mn_print
        lda     #-12
        ldb     #MENU_X
        ldu     #txt_m2
        jsr     mn_print
        lda     #-36
        ldb     #MENU_X
        ldu     #txt_m3
        jsr     mn_print

        jsr     mn_mark

        lda     #$50
        sta     Vec_Text_Width
        lda     #-72
        ldb     #-40
        ldu     #txt_go
        jsr     mn_print

        lda     menu_rdy
        beq     menu
        jsr     Read_Btns
        lda     Vec_Btn_State
        bita    #$08
        beq     menu
        jmp     start_mode


mn_mark:
        lda     menu_sel
        deca
        ldb     #24
        mul
        tfr     b,a
        nega
        adda    #12
        pshs    a
        jsr     Reset0Ref
        puls    a
        ldb     #MARK_X
        jsr     Moveto_d
        ldd     #$FC06
        jsr     Draw_Line_d
        ldd     #$FCFA
        jsr     Draw_Line_d
        ldd     #$0800
        jmp     Draw_Line_d


mn_print:
        pshs    a,b,u
        jsr     Reset0Ref
        puls    a,b
        jsr     Moveto_d
        puls    u
        jmp     Print_Str


menu_input:
        lda     #3
        sta     Vec_Joy_Mux_1_Y
        clr     Vec_Joy_Mux_1_X
        clr     Vec_Joy_Mux_2_X
        clr     Vec_Joy_Mux_2_Y
        jsr     Joy_Digital
        jsr     Read_Btns

        lda     Vec_Btn_State
        bita    #$08
        bne     mi_held
        lda     #1
        sta     menu_rdy
mi_held:
        ldb     Vec_Joy_1_Y
        cmpb    menu_last
        beq     mi_done
        stb     menu_last
        tstb
        beq     mi_done
        bpl     mi_up
        lda     menu_sel
        cmpa    #MODE_GX
        bhs     mi_done
        inca
        sta     menu_sel
        rts
mi_up:
        lda     menu_sel
        cmpa    #MODE_FULL
        bls     mi_done
        deca
        sta     menu_sel
mi_done:
        rts

txt_t1:
        fcc     "VECPAC A.E."
        fcb     $80
txt_m1:
        fcc     "1 GAME"
        fcb     $80
txt_m2:
        fcc     "2 MINI GAME JETPAC"
        fcb     $80
txt_m3:
        fcc     "3 MINI GAME KILLER QUEEN"
        fcb     $80
txt_go:
        fcc     "PRESS 4"
        fcb     $80


start_mode:
        lda     menu_sel
        sta     mode
        clr     glevel
        clr     cycle
        clr     sh_score
        clr     sh_score+1
        clr     sh_score+2
        clr     sh_lives
        lda     mode
        cmpa    #MODE_GX
        beq     sm_gx
        jmp     jp_main
sm_gx:
        jmp     gx_main


cart_menu:
        lds     sup_sp
        jsr     Clear_Sound
        clr     Vec_Music_Flag
        clr     menu_rdy
        clr     menu_last
        jmp     menu


sup_pos:
        clr     cycle
sp_loop:
        cmpa    #CYCLE_LEN
        blo     sp_done
        suba    #CYCLE_LEN
        inc     cycle
        bra     sp_loop
sp_done:
        rts


sup_next:
        lds     sup_sp
        lda     glevel
        cmpa    #TOTAL_LEVELS
        bhs     sup_win
        jsr     sup_pos
        cmpa    #JP_PER_CYCLE
        bhs     sn_gx
        pshs    a
        lda     cycle
        ldb     #JP_PER_CYCLE
        mul
        addb    ,s+
        tfr     b,a
        jmp     jp_enter
sn_gx:
        suba    #JP_PER_CYCLE
        jmp     gx_enter
sup_win:
        jmp     jp_win_screen


cart_jp_level:
        lda     mode
        cmpa    #MODE_FULL
        bne     cjl_no
        inc     glevel
        lda     glevel
        cmpa    #TOTAL_LEVELS
        bhs     cjl_hand
        jsr     sup_pos
        cmpa    #JP_PER_CYCLE
        blo     cjl_no
cjl_hand:
        jsr     cart_save_jp
        jmp     sup_next
cjl_no:
        rts


cart_gx_level:
        lda     mode
        cmpa    #MODE_FULL
        bne     cgl_no
        inc     glevel
        lda     glevel
        cmpa    #TOTAL_LEVELS
        bhs     cgl_hand
        jsr     sup_pos
        cmpa    #JP_PER_CYCLE
        bhs     cgl_no
cgl_hand:
        jsr     cart_save_gx
        jmp     sup_next
cgl_no:
        rts


cart_save_jp:
        ldx     #score
        ldu     #sh_score
        jsr     cart_copy3
        lda     lives
        sta     sh_lives
        rts

cart_load_jp:
        ldx     #sh_score
        ldu     #score
        jsr     cart_copy3
        lda     sh_lives
        sta     lives
        rts

cart_save_gx:
        ldx     #g_score
        ldu     #sh_score
        jsr     cart_copy3
        lda     g_lives
        sta     sh_lives
        rts

cart_load_gx:
        ldx     #sh_score
        ldu     #g_score
        jsr     cart_copy3
        lda     sh_lives
        sta     g_lives
        rts

cart_copy3:
        ldb     #3
cc3_loop:
        lda     ,x+
        sta     ,u+
        decb
        bne     cc3_loop
        rts


cart_want_table:
        lda     mode
        cmpa    #MODE_FULL
        rts


cart_gx_over:
        lda     mode
        cmpa    #MODE_FULL
        bne     cgo_no
        jsr     cart_save_gx
        jmp     jp_over_screen
cgo_no:
        rts
