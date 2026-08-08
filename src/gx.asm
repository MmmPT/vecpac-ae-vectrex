; =====================================================================
; VECPAC A.E. — Killer Queen mode
; Vector fixed-screen shooter with formation dives and a boss encounter.
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
        fcc     "KILLER QUEEN"
        fcb     $80
        fcb     $00


px              equ     $C880
pdead           equ     $C881
shot_on         equ     $C882
shot_x          equ     $C883
shot_y          equ     $C884
sway            equ     $C885
sway_d          equ     $C886
frame_count     equ     $C887
rnd             equ     $C889
score           equ     $C88A
score_str       equ     $C88D
lives           equ     $C894
n_form          equ     $C895
dive_t          equ     $C896
in_state        equ     $C897
tmp_cy          equ     $C898
tmp_cx          equ     $C899
tmp_cnt         equ     $C89A
tmp_col         equ     $C89B
tmp_row         equ     $C89C
tmp_n           equ     $C89D
game_state      equ     $C89E
ge_ready        equ     $C89F
init_sp         equ     $C8F0
darts           equ     $C8A0

level           equ     $C8E8
bee_x           equ     $C8E9
bee_dir         equ     $C8EA
bee_hits        equ     $C8EB
bee_st          equ     $C8EC
bee_fire        equ     $C8ED
bee_spawn       equ     $C8EE
bbul            equ     $C8F2

sA_t            equ     $C900
sA_p            equ     $C901
sA_d            equ     $C903
sB_t            equ     $C905
sB_p            equ     $C906
sB_d            equ     $C908
sC_t            equ     $C90A
sC_p            equ     $C90B
sC_d            equ     $C90D
shield_n        equ     $C90F
shield_t        equ     $C910
bee_boom        equ     $C911
lap             equ     $C912
cur_dive_gap    equ     $C913
cur_dive_spd    equ     $C914
cur_bee_fire    equ     $C915
cur_bee_spawn   equ     $C916
jing_p          equ     $C917
jing_t          equ     $C919
env_tog         equ     $C91A
bee_wait        equ     $C91B

MAX_LAP         equ     3


CART            equ     0

BOOM_FRAMES     equ     40

SFX_SHOT        equ     0
SFX_DART        equ     1
SFX_HIT         equ     2
SFX_DEATH       equ     3
SFX_BEEDIE      equ     4
SFX_BEEFIRE     equ     5
SFX_DIVE        equ     6
SFX_SHIELD      equ     7
SFX_BLOCK       equ     8
SFX_LEVEL       equ     9
SFX_OVER        equ     10

B_ON            equ     0
B_X             equ     1
B_Y             equ     2
BBUL_SZ         equ     3
MAX_BBUL        equ     2

BEE_Y           equ     50
BEE_MAX_X       equ     42
BEE_PER_PART    equ     10
BEE_HITS        equ     BEE_PER_PART*3
BEE_FIRE_GAP    equ     40


BEE_SPAWN_GAP   equ     20
BBUL_SPEED      equ     4
MAX_DIVE_L2     equ     4
SIDE_X          equ     64
SIDE_Y          equ      0


D_ST            equ     0
D_X             equ     1
D_Y             equ     2
D_SX            equ     3
D_SY            equ     4
D_T             equ     5

MAX_DARTS       equ     12
DART_SZ         equ     6
COLS            equ     6
DX              equ     21
DY              equ     20


FX0             equ     -53
FY0             equ     58

SWAY_MAX        equ     8


PLAYER_Y        equ     -68
PLAYER_MAX      equ     56
PLAYER_SPEED    equ     2
SHOT_SPEED      equ     8
DIVE_SPEED      equ     3
START_LIVES     equ     3
DEAD_FRAMES     equ     24
DIVE_GAP        equ     50

IN_LEFT         equ     $01
IN_RIGHT        equ     $02
IN_FIRE         equ     $08
IN_SHIELD       equ     $10

SHIELD_USES     equ     2
SHIELD_TIME     equ     90
SHIELD_X        equ     44


SCORE_Y         equ     72
SCORE_X         equ     -60
LIVES_X         equ     34


main:
        sts     init_sp
        lda     #$A5
        sta     rnd


new_game:
        lds     init_sp
        jsr     snd_init
        clr     jing_p
        clr     jing_p+1
        clr     game_state
        ldx     #score
        ldb     #3
ng_sc:
        clr     ,x+
        decb
        bne     ng_sc
        lda     #START_LIVES
        sta     lives
        clr     lap
        jsr     set_lap
        ldd     #0
        std     frame_count
        jsr     level_start


frame:
        jsr     Wait_Recal
        jsr     Intensity_5F
        ldd     frame_count
        addd    #1
        std     frame_count

        jsr     read_input
        jsr     snd_update
        lda     game_state
        lbne    frame_over
        lda     bee_wait
        lbne    frame_wait

        jsr     update_player
        jsr     update_shot
        jsr     update_darts
        lda     level
        bne     fr_bee
        jsr     launch_dives
        bra     fr_draw
fr_bee:
        jsr     update_bee
        jsr     update_bbul
fr_draw:
        jsr     draw_score
        jsr     draw_player
        jsr     draw_shot
        jsr     draw_darts
        lda     level
        beq     fr_end
        jsr     draw_bee
        jsr     draw_bbul
fr_end:
        bra     frame


frame_wait:
        jsr     draw_score
        jsr     draw_player
        jsr     draw_press
        lda     in_state
        bita    #IN_FIRE
        beq     fw_release
        lda     ge_ready
        lbeq    frame
        clr     bee_wait
        bra     bee_advance
fw_release:
        lda     #1
        sta     ge_ready
        lbra    frame


bee_advance:
        if      CART
        jsr     cart_gx_level
        endif
        inc     lap
        jsr     set_lap
        jsr     level_start
        jmp     frame


draw_press:
        lda     #$F8
        sta     Vec_Text_HW
        lda     #$50
        sta     Vec_Text_Width
        jsr     Reset0Ref
        lda     #20
        ldb     #-30
        jsr     Moveto_d
        ldu     #txt_press
        jmp     Print_Str

txt_press:
        fcc     "PRESS 4"
        fcb     $80

frame_over:
        jsr     draw_over
        lda     in_state
        bita    #IN_FIRE
        beq     fo_wait
        lda     ge_ready
        beq     fo_wait
        if      CART
        jmp     cart_menu
        else
        jmp     new_game
        endif
fo_wait:
        lda     in_state
        bita    #IN_FIRE
        lbne    frame
        lda     #1
        sta     ge_ready
        lbra    frame


level_start:
        clr     px
        clr     pdead
        clr     shot_on
        clr     sway
        lda     #1
        sta     sway_d
        lda     cur_dive_gap
        sta     dive_t
        ldx     #darts
        ldb     #MAX_DARTS
ls_loop:
        lda     #1
        sta     D_ST,x
        clr     D_T,x
        leax    DART_SZ,x
        decb
        bne     ls_loop
        lda     #MAX_DARTS
        sta     n_form
        clr     level
        clr     bee_wait
        clr     shield_n
        clr     shield_t
        rts


l1_done:
        if      CART
        jsr     cart_gx_level
        endif


level2_start:
        clr     px
        clr     pdead
        clr     shot_on
        lda     #1
        sta     level
        clr     bee_hits
        clr     bee_st
        clr     bee_boom
        clr     bee_x
        lda     #1
        sta     bee_dir
        lda     cur_bee_fire
        sta     bee_fire
        lda     cur_bee_spawn
        sta     bee_spawn
        lda     #SHIELD_USES
        sta     shield_n
        clr     shield_t
        ldb     #SFX_LEVEL
        jsr     snd_play
        ldx     #darts
        ldb     #MAX_DARTS
l2_darts:
        clr     D_ST,x
        leax    DART_SZ,x
        decb
        bne     l2_darts
        ldx     #bbul
        ldb     #MAX_BBUL
l2_bul:
        clr     B_ON,x
        leax    BBUL_SZ,x
        decb
        bne     l2_bul
        rts

        if      CART


gx_enter:
        pshs    a
        ldx     sup_sp
        stx     init_sp
        lds     init_sp
        jsr     snd_init
        clr     jing_p
        clr     jing_p+1
        clr     game_state
        clr     ge_ready
        ldd     #0
        std     frame_count
        lda     cycle
        sta     lap
        jsr     set_lap
        jsr     cart_load_gx
        jsr     level_start
        puls    a
        beq     gxe_go
        clr     sway
        clr     n_form
        jsr     level2_start
gxe_go:
        jmp     frame
        endif


update_bee:
        lda     bee_boom
        beq     ub_alive
        dec     bee_boom
        bne     ub_boom_on
        lda     #1
        sta     bee_wait
        clr     ge_ready
ub_boom_on:
        rts
ub_alive:
        lda     bee_x
        ldb     bee_dir
        bmi     ub_left
        inca
        cmpa    #BEE_MAX_X
        blt     ub_setx
        neg     bee_dir
        bra     ub_setx
ub_left:
        deca
        cmpa    #-BEE_MAX_X
        bgt     ub_setx
        neg     bee_dir
ub_setx:
        sta     bee_x

        lda     pdead
        bne     ub_done
        lda     bee_fire
        beq     ub_fire
        dec     bee_fire
        bra     ub_spawn
ub_fire:
        lda     cur_bee_fire
        sta     bee_fire
        jsr     bee_shoot
ub_spawn:
        lda     bee_spawn
        beq     ub_send
        dec     bee_spawn
ub_done:
        rts
ub_send:
        lda     cur_bee_spawn
        sta     bee_spawn
        jmp     bee_launch


bee_shoot:
        ldx     #bbul
        ldb     #MAX_BBUL
bs_loop:
        lda     B_ON,x
        beq     bs_free
        leax    BBUL_SZ,x
        decb
        bne     bs_loop
        rts
bs_free:
        lda     #1
        sta     B_ON,x
        lda     bee_x
        sta     B_X,x
        lda     #BEE_Y-20
        sta     B_Y,x
        ldb     #SFX_BEEFIRE
        jmp     snd_play


bee_launch:
        ldx     #darts
        ldb     #MAX_DARTS
        clr     tmp_n
bl_count:
        lda     D_ST,x
        beq     bl_c_next
        inc     tmp_n
bl_c_next:
        leax    DART_SZ,x
        decb
        bne     bl_count
        lda     tmp_n
        cmpa    #MAX_DIVE_L2
        bhs     bl_done

        ldx     #darts
        ldb     #MAX_DARTS
bl_find:
        lda     D_ST,x
        beq     bl_free
        leax    DART_SZ,x
        decb
        bne     bl_find
bl_done:
        rts


bl_free:
        lda     #2
        sta     D_ST,x
        jsr     next_rnd
        bita    #$40
        bne     bl_right
        lda     #-SIDE_X
        bra     bl_setx
bl_right:
        lda     #SIDE_X
bl_setx:
        sta     D_X,x
        jsr     next_rnd
        anda    #$0F
        adda    #SIDE_Y
        sta     D_Y,x
        ldb     #SFX_DIVE
        jmp     snd_play


update_bbul:
        ldx     #bbul
        ldb     #MAX_BBUL
ubl_loop:
        lda     B_ON,x
        beq     ubl_next
        lda     B_Y,x
        suba    #BBUL_SPEED
        sta     B_Y,x
        cmpa    #-90
        bgt     ubl_hit
        clr     B_ON,x
        bra     ubl_next
ubl_hit:
        pshs    b
        jsr     bbul_vs_player
        puls    b
ubl_next:
        leax    BBUL_SZ,x
        decb
        bne     ubl_loop
        rts

bbul_vs_player:
        lda     pdead
        bne     bvp_no
        lda     B_Y,x
        suba    #PLAYER_Y
        bpl     bvp_dy
        nega
bvp_dy:
        cmpa    #7
        bgt     bvp_no
        lda     B_X,x
        suba    px
        bpl     bvp_dx
        nega
bvp_dx:
        cmpa    #6
        bgt     bvp_no
        clr     B_ON,x
        lda     shield_t
        beq     bvp_hit
        pshs    x
        ldb     #SFX_BLOCK
        jsr     snd_play
        puls    x
        rts
bvp_hit:
        lda     #DEAD_FRAMES
        sta     pdead
        pshs    x
        ldb     #SFX_DEATH
        jsr     snd_play
        puls    x
bvp_no:
        rts


shot_vs_bee:
        lda     bee_boom
        bne     svb_no
        lda     shot_on
        beq     svb_no
        lda     shot_y
        suba    #BEE_Y
        bpl     svb_dy
        nega
svb_dy:
        cmpa    #18
        bgt     svb_no
        lda     shot_x
        suba    bee_x
        bpl     svb_dx
        nega
svb_dx:
        ldb     bee_st
        ldx     #bee_half
        abx
        cmpa    ,x
        bgt     svb_no
        clr     shot_on
        inc     bee_hits
        lda     bee_hits
        cmpa    #BEE_HITS
        bhs     bee_dies
        clrb
        cmpa    #BEE_PER_PART
        blo     svb_st
        incb
        cmpa    #BEE_PER_PART*2
        blo     svb_st
        incb
svb_st:
        stb     bee_st
        ldb     #SFX_HIT
        jsr     snd_play
        ldd     #$0010
        jmp     add_score
svb_no:
        rts


bee_half:
        fcb     20, 13, 11

bee_dies:
        ldb     #SFX_BEEDIE
        jsr     snd_play
        jsr     jingle_start
        ldd     #$1000
        jsr     add_score
        lda     #BOOM_FRAMES
        sta     bee_boom
        ldx     #bbul
        ldb     #MAX_BBUL
bd_bul:
        clr     B_ON,x
        leax    BBUL_SZ,x
        decb
        bne     bd_bul
        rts


draw_bee:
        lda     #BEE_Y
        sta     tmp_cy
        lda     bee_x
        sta     tmp_cx
        lda     bee_boom
        bne     db_boom
        lda     bee_st
        lsla
        ldx     #bee_shapes
        ldu     a,x
        jmp     draw_shape


db_boom:
        lda     bee_boom
        cmpa    #BOOM_FRAMES*3/4
        bhs     db_pequena
        cmpa    #BOOM_FRAMES/2
        bhs     db_media
        cmpa    #BOOM_FRAMES/4
        bhs     db_grande
        ldu     #shape_boom_xl
        jmp     draw_shape
db_grande:
        ldu     #shape_boom_l
        jmp     draw_shape
db_media:
        ldu     #shape_boom_m
        jmp     draw_shape
db_pequena:
        ldu     #shape_boom_s
        jmp     draw_shape

bee_shapes:
        fdb     shape_bee_1, shape_bee_2, shape_bee_3


draw_bbul:
        ldx     #bbul
        lda     #MAX_BBUL
        sta     tmp_cnt
dbl_loop:
        lda     B_ON,x
        beq     dbl_next
        pshs    x
        jsr     Reset0Ref
        puls    x
        lda     B_Y,x
        ldb     B_X,x
        pshs    x
        jsr     Moveto_d
        ldd     #$FA00
        jsr     Draw_Line_d
        puls    x
dbl_next:
        leax    BBUL_SZ,x
        dec     tmp_cnt
        bne     dbl_loop
        rts


set_lap:
        lda     lap
        cmpa    #MAX_LAP
        bls     sl_ok
        lda     #MAX_LAP
        sta     lap
sl_ok:
        lsla
        lsla
        ldx     #lap_table
        ldb     a,x
        stb     cur_dive_gap
        leax    1,x
        ldb     a,x
        stb     cur_dive_spd
        leax    1,x
        ldb     a,x
        stb     cur_bee_fire
        leax    1,x
        ldb     a,x
        stb     cur_bee_spawn
        rts


lap_table:
        fcb     50, 3, 40, 20
        fcb     38, 4, 32, 17
        fcb     29, 5, 26, 14
        fcb     22, 5, 20, 12


read_input:
        lda     #1
        sta     Vec_Joy_Mux_1_X
        clr     Vec_Joy_Mux_1_Y
        clr     Vec_Joy_Mux_2_X
        clr     Vec_Joy_Mux_2_Y
        jsr     Joy_Digital
        jsr     Read_Btns
        clra
        ldb     Vec_Joy_1_X
        beq     ri_no_lr
        bmi     ri_left
        ora     #IN_RIGHT
        bra     ri_no_lr
ri_left:
        ora     #IN_LEFT
ri_no_lr:
        ldb     Vec_Btn_State
        bitb    #$08
        beq     ri_nofire
        ora     #IN_FIRE
ri_nofire:
        bitb    #$01
        beq     ri_done
        ora     #IN_SHIELD
ri_done:
        sta     in_state
        rts


update_player:
        lda     pdead
        beq     up_alive
        dec     pdead
        bne     up_done
        lda     lives
        beq     up_over
        dec     lives
        clr     px
        ldx     #darts
        ldb     #MAX_DARTS


up_recall:
        lda     D_ST,x
        cmpa    #2
        bne     up_rec_next
        lda     level
        beq     up_rec_form
        clr     D_ST,x
        bra     up_rec_next
up_rec_form:
        lda     #1
        sta     D_ST,x
up_rec_next:
        leax    DART_SZ,x
        decb
        bne     up_recall


        lda     level
        bne     up_rec_done
        lda     n_form
        bne     up_rec_done
        jmp     l1_done
up_rec_done:
        rts
up_over:
        if      CART
        jsr     cart_gx_over
        endif
        lda     #1
        sta     game_state
        clr     ge_ready
        ldb     #SFX_OVER
        jsr     snd_play
up_done:
        rts
up_alive:
        lda     shield_t
        beq     up_shield_off
        dec     shield_t
        bra     up_move
up_shield_off:
        lda     in_state
        bita    #IN_SHIELD
        beq     up_move
        lda     shield_n
        beq     up_move
        dec     shield_n
        lda     #SHIELD_TIME
        sta     shield_t
        pshs    a
        ldb     #SFX_SHIELD
        jsr     snd_play
        puls    a
up_move:
        lda     in_state
        bita    #IN_RIGHT
        beq     up_left
        lda     px
        adda    #PLAYER_SPEED
        cmpa    #PLAYER_MAX
        ble     up_setx
        lda     #PLAYER_MAX
        bra     up_setx
up_left:
        lda     in_state
        bita    #IN_LEFT
        beq     up_fire
        lda     px
        suba    #PLAYER_SPEED
        cmpa    #-PLAYER_MAX
        bge     up_setx
        lda     #-PLAYER_MAX
up_setx:
        sta     px
up_fire:
        lda     in_state
        bita    #IN_FIRE
        beq     up_done
        lda     shot_on
        bne     up_done
        lda     #1
        sta     shot_on
        lda     px
        sta     shot_x
        lda     #PLAYER_Y+8
        sta     shot_y
        ldb     #SFX_SHOT
        jmp     snd_play


update_shot:
        lda     shot_on
        beq     us_done
        lda     shot_y
        adda    #SHOT_SPEED
        sta     shot_y
        cmpa    #88
        blt     us_hit
        clr     shot_on
        rts
us_hit:
        jsr     shot_vs_darts
        lda     level
        beq     us_done
        lda     shot_on
        beq     us_done
        jmp     shot_vs_bee
us_done:
        rts


update_darts:
        lda     sway
        ldb     sway_d
        bmi     ud_left
        inca
        cmpa    #SWAY_MAX
        blt     ud_sway
        neg     sway_d
        bra     ud_sway
ud_left:
        deca
        cmpa    #-SWAY_MAX
        bgt     ud_sway
        neg     sway_d
ud_sway:
        sta     sway

        ldx     #darts
        lda     #MAX_DARTS
        sta     tmp_cnt
ud_loop:
        lda     D_ST,x
        cmpa    #2
        bne     ud_next
        jsr     dive_step
ud_next:
        leax    DART_SZ,x
        dec     tmp_cnt
        bne     ud_loop
        rts


dive_step:
        lda     D_Y,x
        suba    cur_dive_spd
        sta     D_Y,x
        cmpa    #-92
        bgt     dv_move
        lda     level
        bne     dv_gone
        lda     #1
        sta     D_ST,x
        rts
dv_gone:
        clr     D_ST,x
        rts
dv_move:
        lda     D_X,x
        cmpa    px
        beq     dv_wrap
        blt     dv_right
        suba    #1
        bra     dv_setx
dv_right:
        adda    #1
dv_setx:
        sta     D_X,x
dv_wrap:
        jmp     dart_vs_player


launch_dives:
        lda     pdead
        bne     ld_done
        lda     dive_t
        beq     ld_go
        dec     dive_t
ld_done:
        rts
ld_go:
        lda     cur_dive_gap
        sta     dive_t
        jsr     next_rnd
        anda    #3
        beq     ld_trio
        lda     #1
        bra     ld_send
ld_trio:
        lda     #3
ld_send:
        sta     tmp_n
ld_send_loop:
        jsr     pick_one
        dec     tmp_n
        bne     ld_send_loop
        rts


pick_one:
        pshs    a,b,x
        jsr     next_rnd
        anda    #$0F
        cmpa    #MAX_DARTS
        blo     po_have
        suba    #MAX_DARTS
po_have:
        ldb     #MAX_DARTS
        sta     tmp_col
po_scan:
        lda     tmp_col
        jsr     dart_at
        lda     D_ST,x
        cmpa    #1
        beq     po_found
        inc     tmp_col
        lda     tmp_col
        cmpa    #MAX_DARTS
        blo     po_next
        clr     tmp_col
po_next:
        decb
        bne     po_scan
        puls    a,b,x
        rts
po_found:
        lda     tmp_col
        jsr     form_pos
        sta     D_Y,x
        stb     D_X,x
        lda     #2
        sta     D_ST,x
        ldb     #SFX_DIVE
        jsr     snd_play
        puls    a,b,x
        rts


dart_at:
        pshs    a,b
        ldb     #DART_SZ
        mul
        addd    #darts
        tfr     d,x
        puls    a,b
        rts


form_pos:
        pshs    x
        tfr     a,b
        clra
        cmpb    #COLS
        blo     fp_row0
        subb    #COLS
        lda     #1
fp_row0:
        pshs    a
        lda     #DX
        mul
        addb    #FX0
        addb    sway
        puls    a
        ldx     #0
        tsta
        beq     fp_y0
        lda     #FY0-DY
        bra     fp_done
fp_y0:
        lda     #FY0
fp_done:
        puls    x
        rts


shot_vs_darts:
        ldx     #darts
        lda     #MAX_DARTS
        sta     tmp_cnt
        clr     tmp_col
svd_loop:
        lda     D_ST,x
        beq     svd_next
        cmpa    #2
        beq     svd_pos_dive
        lda     tmp_col
        jsr     form_pos
        bra     svd_test
svd_pos_dive:
        lda     D_Y,x
        ldb     D_X,x
svd_test:
        sta     tmp_cy
        stb     tmp_cx
        lda     tmp_cx
        suba    shot_x
        bpl     svd_dx
        nega
svd_dx:
        cmpa    #6
        bgt     svd_next
        lda     tmp_cy
        suba    shot_y
        bpl     svd_dy
        nega
svd_dy:
        cmpa    #7
        bgt     svd_next
        clr     D_ST,x
        clr     shot_on
        pshs    x
        ldb     #SFX_DART
        jsr     snd_play
        puls    x
        ldd     #$0030
        jsr     add_score
        lda     level
        bne     svd_end
        dec     n_form
        bne     svd_end
        jmp     l1_done
svd_end:
        rts
svd_next:
        leax    DART_SZ,x
        inc     tmp_col
        dec     tmp_cnt
        bne     svd_loop
        rts


dart_vs_player:
        lda     pdead
        bne     dvp_no
        lda     D_Y,x
        suba    #PLAYER_Y
        bpl     dvp_dy
        nega
dvp_dy:
        cmpa    #7
        bgt     dvp_no
        lda     D_X,x
        suba    px
        bpl     dvp_dx
        nega
dvp_dx:
        cmpa    #7
        bgt     dvp_no
        lda     shield_t
        beq     dvp_hit
        clr     D_ST,x
        pshs    x
        ldb     #SFX_BLOCK
        jsr     snd_play
        puls    x
        rts
dvp_hit:
        clr     D_ST,x
        lda     level
        bne     dvp_kill
        dec     n_form
dvp_kill:
        lda     #DEAD_FRAMES
        sta     pdead
        pshs    x
        ldb     #SFX_DEATH
        jsr     snd_play
        puls    x
dvp_no:
        rts


next_rnd:
        pshs    b
        ldb     #8
nr_loop:
        lda     rnd
        lsra
        bcc     nr_no
        eora    #$B8
nr_no:
        sta     rnd
        decb
        bne     nr_loop
        puls    b
        lda     rnd
        rts


add_score:
        pshs    a
        tfr     b,a
        adda    score+2
        daa
        sta     score+2
        puls    a
        adca    score+1
        daa
        sta     score+1
        lda     score
        adca    #0
        daa
        sta     score
        rts


draw_player:
        lda     pdead
        bne     dp_boom
        lda     #PLAYER_Y
        sta     tmp_cy
        lda     px
        sta     tmp_cx
        ldu     #shape_ship
        jsr     draw_shape
        lda     shield_t
        beq     dp_done
        ldu     #shape_shield
        jmp     draw_shape
dp_done:
        rts
dp_boom:
        lda     #PLAYER_Y
        sta     tmp_cy
        lda     px
        sta     tmp_cx
        ldu     #shape_boom
        jmp     draw_shape

draw_shot:
        lda     shot_on
        beq     dsh_done
        jsr     Reset0Ref
        lda     shot_y
        ldb     shot_x
        jsr     Moveto_d
        ldd     #$0600
        jsr     Draw_Line_d
dsh_done:
        rts

draw_darts:
        ldx     #darts
        lda     #MAX_DARTS
        sta     tmp_cnt
        clr     tmp_col
dd_loop:
        lda     D_ST,x
        beq     dd_next
        cmpa    #2
        beq     dd_dive
        lda     tmp_col
        jsr     form_pos
        bra     dd_draw
dd_dive:
        lda     D_Y,x
        ldb     D_X,x
dd_draw:
        sta     tmp_cy
        stb     tmp_cx
        pshs    x
        ldu     #shape_dart
        jsr     draw_shape
        puls    x
dd_next:
        leax    DART_SZ,x
        inc     tmp_col
        dec     tmp_cnt
        bne     dd_loop
        rts


draw_score:
        ldu     #score
        jsr     bcd_to_text
        lda     #SCORE_Y
        ldb     #SCORE_X
        jsr     draw_number


draw_lives:
        lda     lives
        beq     dl_done
        cmpa    #5
        bls     dl_count
        lda     #5
dl_count:
        sta     tmp_cnt
        jsr     Reset0Ref
        lda     #SCORE_Y
        ldb     #LIVES_X
        jsr     Moveto_d
dl_loop:
        ldd     #$0800
        jsr     Draw_Line_d
        ldd     #$F805
        jsr     Moveto_d
        dec     tmp_cnt
        bne     dl_loop
dl_done:
        lda     shield_n
        beq     sc_done
        sta     tmp_cnt
        jsr     Reset0Ref
        lda     #SCORE_Y-12
        ldb     #SHIELD_X
        jsr     Moveto_d
sc_loop:
        ldd     #$0006
        jsr     Draw_Line_d
        ldd     #$0004
        jsr     Moveto_d
        dec     tmp_cnt
        bne     sc_loop
sc_done:
        rts

draw_over:
        lda     #$F8
        sta     Vec_Text_HW
        lda     #$50
        sta     Vec_Text_Width
        jsr     Reset0Ref
        lda     #20
        ldb     #-38
        jsr     Moveto_d
        ldu     #txt_over
        jsr     Print_Str
        ldu     #score
        jsr     bcd_to_text
        lda     #-10
        ldb     #-20
        jmp     draw_number

txt_over:
        fcc     "GAME OVER"
        fcb     $80


bcd_to_text:
        ldx     #score_str
        ldb     #3
btt_loop:
        lda     ,u+
        pshs    a
        lsra
        lsra
        lsra
        lsra
        adda    #'0
        sta     ,x+
        puls    a
        anda    #$0F
        adda    #'0
        sta     ,x+
        decb
        bne     btt_loop
        lda     #$80
        sta     ,x
        ldy     #score_str
        ldb     #5
btt_zeros:
        lda     ,y
        cmpa    #'0'
        bne     btt_done
        leay    1,y
        decb
        bne     btt_zeros
btt_done:
        rts


draw_number:
        pshs    a,b
        jsr     Reset0Ref
        puls    a,b
        jsr     Moveto_d
dn_digit:
        lda     ,y+
        cmpa    #$80
        beq     dn_done
        suba    #'0'
        lsla
        ldx     #digit_ptrs
        ldu     a,x
        pshs    y
        jsr     draw_digit
        puls    y
        bra     dn_digit
dn_done:
        rts

draw_digit:
        lda     ,u
        ldb     1,u
        leau    2,u
        jsr     Moveto_d
dg_loop:
        lda     ,u
        cmpa    #$80
        beq     dg_done
        cmpa    #$81
        beq     dg_skip
        ldb     1,u
        leau    2,u
        jsr     Draw_Line_d
        bra     dg_loop
dg_skip:
        lda     1,u
        ldb     2,u
        leau    3,u
        jsr     Moveto_d
        bra     dg_loop
dg_done:
        rts


draw_shape:
        jsr     Reset0Ref
        lda     ,u+
        ldb     ,u+
        adda    tmp_cy
        pshs    a
        tfr     b,a
        adda    tmp_cx
        tfr     a,b
        puls    a
        jsr     Moveto_d
ds_loop:
        lda     ,u
        cmpa    #$80
        beq     ds_done
        cmpa    #$81
        beq     ds_skip
        lda     ,u+
        ldb     ,u+
        jsr     Draw_Line_d
        bra     ds_loop
ds_skip:
        leau    1,u
        lda     ,u+
        ldb     ,u+
        jsr     Moveto_d
        bra     ds_loop
ds_done:
        rts


snd_init:
        jsr     Clear_Sound
        clr     Vec_Music_Flag
        ldx     #Vec_Music_Work
        ldb     #14
si_buf:
        clr     ,x+
        decb
        bne     si_buf
        ldx     #sA_t
        ldb     #15
si_own:
        clr     ,x+
        decb
        bne     si_own
        rts


snd_play:
        pshs    a,b,x,u
        lda     #6
        mul
        ldu     #sfx_table
        leau    d,u
        ldb     ,u
        ldx     #sA_t
        abx
        abx
        abx
        abx
        abx
        lda     1,u
        sta     ,x
        ldd     2,u
        std     1,x
        ldd     4,u
        std     3,x
        puls    a,b,x,u
        rts


sfx_table:
        fcb     0,  8, $00,$50, $00,$30
        fcb     1,  8, $00,$06, $00,$02
        fcb     0, 10, $02,$00, $FF,$E0
        fcb     1, 15, $00,$08, $00,$02
        fcb     1, 22, $00,$04, $00,$01
        fcb     0, 10, $04,$00, $00,$60


        fcb     2, 10, $01,$90, $FF,$E0
        fcb     0, 14, $03,$00, $FF,$B0
        fcb     0,  6, $00,$30, $FF,$F0
        fcb     0, 18, $02,$80, $FF,$D8
        fcb     0, 26, $00,$90, $00,$50


jingle_start:
        ldx     #fanfarra
        stx     jing_p
        clr     jing_t
        clr     env_tog
        rts

jingle_tick:
        lda     #%00111000
        sta     SND_REG-7
        lda     #$05
        sta     SND_REG-12
        clr     SND_REG-11

        lda     jing_t
        beq     jt_novo
        deca
        sta     jing_t
        jmp     su_send

jt_novo:
        ldx     jing_p
        lda     ,x
        cmpa    #$FF
        beq     jt_fim
        ldd     ,x++
        pshs    a,b
        stb     SND_REG-0
        anda    #$0F
        sta     SND_REG-1
        ldd     ,x++
        stb     SND_REG-2
        anda    #$0F
        sta     SND_REG-3
        ldd     ,x++
        stb     SND_REG-4
        anda    #$0F
        sta     SND_REG-5
        lda     ,x+
        sta     jing_t
        stx     jing_p
        puls    a,b
        tsta
        bne     jt_bate
        tstb
        beq     jt_calado
jt_bate:
        lda     #$10
        sta     SND_REG-8
        sta     SND_REG-9
        sta     SND_REG-10
        lda     env_tog
        eora    #$09
        sta     env_tog
        sta     SND_REG-13
        jmp     su_send
jt_calado:
        clr     SND_REG-8
        clr     SND_REG-9
        clr     SND_REG-10
        jmp     su_send
jt_fim:
        clr     jing_p
        clr     jing_p+1
        clr     SND_REG-8
        clr     SND_REG-9
        clr     SND_REG-10
        jmp     su_send


fanfarra:
        fcb     $00,179, $01, 28, $02,204,  6
        fcb     $00,142, $00,239, $02,204,  6
        fcb     $00,120, $00,179, $02,204,  6
        fcb     $00, 90, $00,142, $02,204, 22
        fcb     $00,  0, $00,  0, $00,  0,  5
        fcb     $00,120, $00,142, $01,222,  6
        fcb     $00, 90, $00,120, $02,204, 30
        fcb     $FF


snd_update:
        ldd     jing_p
        lbne    jingle_tick

        lda     sA_t
        beq     su_a_off
        deca
        sta     sA_t
        ldd     sA_p
        addd    sA_d
        std     sA_p
        stb     SND_REG-0
        anda    #$0F
        sta     SND_REG-1
        lda     sA_t
        bra     su_a_vol
su_a_off:
        clra
su_a_vol:
        sta     SND_REG-8

        lda     sB_t
        beq     su_b_off
        deca
        sta     sB_t
        ldd     sB_p
        addd    sB_d
        std     sB_p
        andb    #$1F
        stb     SND_REG-6
        lda     sB_t
        bra     su_b_vol
su_b_off:
        clra
su_b_vol:
        sta     SND_REG-9


        lda     sC_t
        beq     su_c_off
        deca
        sta     sC_t
        ldd     sC_p
        addd    sC_d
        std     sC_p
        stb     SND_REG-4
        anda    #$0F
        sta     SND_REG-5
        lda     sC_t
        cmpa    #10
        bls     su_c_vol
        lda     #10
        bra     su_c_vol
su_c_off:
        clra
su_c_vol:
        sta     SND_REG-10

        lda     #%00101010
        sta     SND_REG-7


su_send:
        jsr     DP_to_D0
        jmp     Do_Sound


shape_ship:
        fcb       6,    0
        fcb      -5,    2
        fcb      -7,    6
        fcb       1,   -4
        fcb       1,   -2
        fcb      -1,   -1
        fcb       0,   -2
        fcb       1,   -1
        fcb      -1,   -2
        fcb      -1,   -4
        fcb       7,    6
        fcb       5,    2
        fcb    $81,   -9,   -2
        fcb       9,    2
        fcb      -9,    2
        fcb      -2,   -1
        fcb       0,   -2
        fcb       2,   -1
        fcb     $80


shape_dart:
        fcb      -6,    0
        fcb      10,    4
        fcb      -2,   -3
        fcb       4,   -1
        fcb      -4,   -1
        fcb       2,   -3
        fcb     -10,    4
        fcb     $80


shape_bee_1:
        fcb      17,    0
        fcb      -3,    5
        fcb      -6,   -2
        fcb       0,   -6
        fcb       6,   -2
        fcb       3,    5
        fcb    $81,   -4,    8
        fcb      -8,   11
        fcb      -8,   -2
        fcb      11,  -12
        fcb       5,    3
        fcb    $81,    0,  -16
        fcb      -8,  -11
        fcb      -8,    2
        fcb      11,   12
        fcb       5,   -3
        fcb    $81,   -9,    4
        fcb       0,    8
        fcb      -6,    3
        fcb     -16,   -7
        fcb      16,   -7
        fcb       6,    3
        fcb    $81,   -6,   -3
        fcb       0,   14
        fcb    $81,   -5,  -11
        fcb       0,    8
        fcb    $81,   -5,   -6
        fcb       0,    4
        fcb     $80

shape_bee_2:
        fcb      17,    0
        fcb      -3,    5
        fcb      -6,   -2
        fcb       0,   -6
        fcb       6,   -2
        fcb       3,    5
        fcb    $81,  -13,   -4
        fcb       0,    8
        fcb      -6,    3
        fcb     -16,   -7
        fcb      16,   -7
        fcb       6,    3
        fcb    $81,   -6,   -3
        fcb       0,   14
        fcb    $81,   -5,  -11
        fcb       0,    8
        fcb    $81,   -5,   -6
        fcb       0,    4
        fcb     $80

shape_bee_3:
        fcb       4,   -4
        fcb       0,    8
        fcb      -6,    3
        fcb     -16,   -7
        fcb      16,   -7
        fcb       6,    3
        fcb    $81,   -6,   -3
        fcb       0,   14
        fcb    $81,   -5,  -11
        fcb       0,    8
        fcb    $81,   -5,   -6
        fcb       0,    4
        fcb     $80


shape_shield:
        fcb      10,    0
        fcb      -5,    9
        fcb     -10,    0
        fcb      -5,   -9
        fcb       5,   -9
        fcb      10,    0
        fcb       5,    9
        fcb     $80


shape_boom_s:
        fcb    -10,   0
        fcb     20,   0
        fcb    $81, -10, -10
        fcb      0,  20
        fcb    $81, -10, -20
        fcb     20,  20
        fcb    $81, -20,   0
        fcb     20, -20
        fcb     $80
shape_boom_m:
        fcb    -20,   0
        fcb     40,   0
        fcb    $81, -20, -20
        fcb      0,  40
        fcb    $81, -20, -40
        fcb     40,  40
        fcb    $81, -40,   0
        fcb     40, -40
        fcb     $80
shape_boom_l:
        fcb    -34,   0
        fcb     68,   0
        fcb    $81, -34, -34
        fcb      0,  68
        fcb    $81, -34, -68
        fcb     68,  68
        fcb    $81, -68,   0
        fcb     68, -68
        fcb     $80


shape_boom_xl:
        fcb    -52,   0
        fcb    104,   0
        fcb    $81, -52, -52
        fcb      0, 104
        fcb    $81, -52,-104
        fcb    104, 104
        fcb    $81,-104,   0
        fcb    104,-104
        fcb    $81, -32, -20
        fcb     84,  40
        fcb    $81, -84,  12
        fcb     84, -40
        fcb    $81, -20, -84
        fcb     40,  84
        fcb    $81,  12, -84
        fcb    -40,  84
        fcb     $80


shape_boom:
        fcb       0,   -6
        fcb       0,   12
        fcb    $81,   -6,   -6
        fcb      12,    0
        fcb    $81,   -6,   -6
        fcb      12,   12
        fcb    $81,  -12,    0
        fcb      12,  -12
        fcb     $80

digit_ptrs:
        fdb     digit_0, digit_1, digit_2, digit_3, digit_4
        fdb     digit_5, digit_6, digit_7, digit_8, digit_9

digit_0:
        fcb      0,  0
        fcb      0,  5
        fcb      8,  0
        fcb      0, -5
        fcb     -8,  0
        fcb     $81,  0,  7
        fcb     $80
digit_1:
        fcb      8,  5
        fcb     -8,  0
        fcb     $81,  0,  2
        fcb     $80
digit_2:
        fcb      8,  0
        fcb      0,  5
        fcb     -4,  0
        fcb      0, -5
        fcb     -4,  0
        fcb      0,  5
        fcb     $81,  0,  2
        fcb     $80
digit_3:
        fcb      8,  0
        fcb      0,  5
        fcb     -8,  0
        fcb      0, -5
        fcb     $81,  4,  5
        fcb      0, -5
        fcb     $81, -4,  7
        fcb     $80
digit_4:
        fcb      8,  5
        fcb     -8,  0
        fcb     $81,  8, -5
        fcb     -4,  0
        fcb      0,  5
        fcb     $81, -4,  2
        fcb     $80
digit_5:
        fcb      8,  5
        fcb      0, -5
        fcb     -4,  0
        fcb      0,  5
        fcb     -4,  0
        fcb      0, -5
        fcb     $81,  0,  7
        fcb     $80
digit_6:
        fcb      8,  5
        fcb      0, -5
        fcb     -8,  0
        fcb      0,  5
        fcb      4,  0
        fcb      0, -5
        fcb     $81, -4,  7
        fcb     $80
digit_7:
        fcb      8,  0
        fcb      0,  5
        fcb     -8,  0
        fcb     $81,  0,  2
        fcb     $80
digit_8:
        fcb      0,  0
        fcb      0,  5
        fcb      8,  0
        fcb      0, -5
        fcb     -8,  0
        fcb     $81,  4,  0
        fcb      0,  5
        fcb     $81, -4,  2
        fcb     $80
digit_9:
        fcb      4,  5
        fcb      0, -5
        fcb      4,  0
        fcb      0,  5
        fcb     -8,  0
        fcb      0, -5
        fcb     $81,  0,  7
        fcb     $80

        end     main
