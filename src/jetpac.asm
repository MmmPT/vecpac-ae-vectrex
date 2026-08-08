; =====================================================================
; VECPAC A.E. — Jetpac mode
; Vectrex adaptation of the 1983 Jetpac game mechanics.
; 6809 assembly for the GCE/Milton Bradley Vectrex.
; =====================================================================



        include "vectrex.i"


PF_GROUND       equ     -80
PF_TOP          equ      64
PF_HALF_W       equ      64


JET_HALF_W      equ      5
JET_HALF_H      equ      8

ROCKET_X        equ      20
ROCKET_Y        equ     PF_GROUND


SCORE_Y         equ      72
SCORE_X         equ     -52
LIVES_X         equ      30


ACC             equ      8
VX_MAX          equ     64
VY_MAX          equ     63
VX_WALK         equ     32

FIX_MUL         equ      4


MOV_DOWN        equ     $80
MOV_LEFT        equ     $40
FACE_LEFT       equ     $01


MODE_WALK       equ      0
MODE_FLY        equ      1


IN_LEFT         equ     $01
IN_RIGHT        equ     $02
IN_THRUST       equ     $04


MAX_ALIENS      equ     6
ALIEN_SZ        equ     8
ALIEN_HALF      equ     5


A_TYPE          equ     0
A_X             equ     1
A_XF            equ     2
A_Y             equ     3
A_YF            equ     4
A_SX            equ     5
A_SY            equ     6
A_ST            equ     7


T_METEOR        equ     1
T_SQUID         equ     2
T_SPHERE        equ     3
T_FIGHT         equ     4
T_UFO           equ     5
T_CROSS         equ     6

UFO_MAX         equ     40
FIGHT_DASH      equ     56
START_DELAY     equ     100


MAX_LASERS      equ     4
LASER_SZ        equ     6
L_ACTIVE        equ     0
L_X             equ     1
L_Y             equ     2
L_SX            equ     3
L_LIFE          equ     4

LASER_SPEED     equ     6
LASER_DASH      equ     5
LASER_GAP       equ     9
LASER_SPAN      equ     36

IN_FIRE         equ     $08


MAX_ITEMS       equ     2
ITEM_SZ         equ     6
ITEM_HALF       equ     4
I_TYPE          equ     0
I_X             equ     1
I_Y             equ     2
I_STATE         equ     3
I_HOME_X        equ     4
I_HOME_Y        equ     5

IT_MODULE       equ     1
IT_FUEL         equ     2

MODULE_H        equ     10
ROCKET_HALF_W   equ     6
ROCKET_MID      equ     15

FUEL_NEEDED     equ     6


SH_A            equ      0
SH_B            equ      2
SH_C            equ      4
SH_LEGS         equ      6
SH_FIRE_A       equ      8
SH_FIRE_B       equ     10
SHIP_SZ         equ     12

RS_PAD          equ     0
RS_UP           equ     1
RS_DOWN         equ     2

START_LIVES     equ     4
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


jet_x           equ     $C880
jet_xf          equ     $C881
jet_y           equ     $C882
jet_yf          equ     $C883
jet_vx          equ     $C884
jet_vy          equ     $C885
jet_flags       equ     $C886
jet_mode        equ     $C887
in_state        equ     $C888
step            equ     $C889
frame_count     equ     $C88B


rnd             equ     $C88D
level           equ     $C88E
start_delay     equ     $C88F
tmp_cnt         equ     $C890
tmp_cy          equ     $C891
tmp_cx          equ     $C892
tmp_cnt2        equ     $C893
aliens          equ     $C8A0
lasers          equ     $C8D0
score           equ     $C8E8
score_str       equ     $C8EB
items           equ     $C8F2
rocket_state    equ     $C8FE
rocket_y        equ     $C8FF
rocket_mods     equ     $C900
rocket_fuel     equ     $C901
carrying        equ     $C902
lives           equ     $C903
shape_flip      equ     $C904
init_sp         equ     $C905
tmp_rnd         equ     $C907
dying           equ     $C908

DYING_FRAMES    equ     18


sA_t            equ     $C910
sA_p            equ     $C911
sA_d            equ     $C913
sB_t            equ     $C915
sB_p            equ     $C916
sB_d            equ     $C918
sC_t            equ     $C91A
sC_p            equ     $C91B
sC_d            equ     $C91D


jseq_p          equ     $C920
jseq_t          equ     $C922
env_toggle      equ     $C923

game_state      equ     $C924
GS_PLAYING      equ     0
GS_OVER         equ     1
GS_WON          equ     2
ge_ready        equ     $C925
hi_table        equ     $C926
HI_COUNT        equ     4
HI_SHOWN        equ     1


tmp_ptr         equ     $C932
ship_base       equ     $C934

plat_ptr        equ     $C936

lap             equ     $C938
spawn_mask      equ     $C939
lap_bonus       equ     $C93A
ufo_top         equ     $C93B
ufo_bot         equ     $C93C

MAX_LEVELS      equ     24


MAX_LAP         equ     2


ALIEN_VMAX      equ     52


CART            equ     0

SFX_LASER       equ     0
SFX_PICKUP      equ     1
SFX_DOCK        equ     2
SFX_DEATH       equ     3
SFX_ALIEN       equ     4


main:
        sts     init_sp
        ldd     #0
        std     frame_count
        lda     #$A5
        sta     rnd
        ldx     #hi_table
        ldb     #HI_COUNT*3
mi_hi:
        clr     ,x+
        decb
        bne     mi_hi


new_game:
        lds     init_sp
        jsr     wipe_state
        clr     level
        jsr     set_level
        clr     carrying
        lda     #START_LIVES
        sta     lives
        jsr     level_build
        jsr     jetman_reset


frame:
        jsr     Wait_Recal


        jsr     Intensity_5F

        ldd     frame_count
        addd    #1
        std     frame_count

        jsr     read_input
        jsr     snd_update
        lda     game_state
        beq     fr_playing
        cmpa    #GS_WON
        lbeq    frame_win
        lbra    frame_over
fr_playing:
        lda     rocket_state
        bne     frame_flight

        jsr     update_dying
        jsr     update_jetman
        jsr     fire_laser
        jsr     update_lasers
        jsr     spawn_alien
        jsr     update_aliens
        jsr     update_rocket
        jsr     update_items

        jsr     draw_platforms
        jsr     draw_rocket
        jsr     draw_items
        jsr     draw_aliens
        jsr     draw_lasers
        jsr     draw_jetman
        jsr     draw_score
        bra     frame


frame_over:
        jsr     draw_game_over
        lda     in_state
        bita    #IN_FIRE
        beq     ff_wait
        lda     ge_ready
        beq     ff_wait
        if      CART
        jmp     cart_menu
        else
        jmp     new_game
        endif
ff_wait:
        lda     in_state
        bita    #IN_FIRE
        bne     frame
        lda     #1
        sta     ge_ready
        bra     frame


frame_win:
        jsr     draw_win
        lda     in_state
        bita    #IN_FIRE
        beq     fw_wait
        lda     ge_ready
        beq     fw_wait
        if      CART
        jmp     cart_menu
        else
        jmp     new_game
        endif
fw_wait:
        lda     in_state
        bita    #IN_FIRE
        lbne    frame
        lda     #1
        sta     ge_ready
        lbra    frame


frame_flight:
        jsr     update_rocket
        jsr     draw_platforms
        jsr     draw_rocket
        jsr     draw_score
        lbra    frame


wipe_state:
        clr     game_state
        clr     shape_flip
        jsr     Clear_Sound
        clr     Vec_Music_Flag
        ldx     #Vec_Music_Work
        ldb     #14
ng_buf:
        clr     ,x+
        decb
        bne     ng_buf
        ldx     #sA_t
        ldb     #15
ng_sound:
        clr     ,x+
        decb
        bne     ng_sound
        ldx     #aliens
        lda     #MAX_ALIENS*ALIEN_SZ+MAX_LASERS*LASER_SZ+3+7+MAX_ITEMS*ITEM_SZ
        sta     tmp_cnt
ng_clear:
        clr     ,x+
        dec     tmp_cnt
        bne     ng_clear
        rts

        if      CART


jp_enter:
        ldx     sup_sp
        stx     init_sp
        lds     init_sp
        pshs    a
        jsr     wipe_state
        puls    a
        sta     level
        jsr     set_level
        clr     carrying
        clr     rocket_fuel
        jsr     cart_load_jp
        lda     level
        anda    #1
        bne     jpe_refuel
        jsr     level_build
        jsr     jetman_reset
        jmp     frame
jpe_refuel:
        lda     #3
        sta     rocket_mods
        lda     #PF_TOP
        sta     rocket_y
        lda     #RS_DOWN
        sta     rocket_state
        jsr     jetman_reset
        jmp     frame


jp_win_screen:
        lda     #GS_WON
        bra     jp_end_screen


jp_over_screen:
        lda     #GS_OVER
jp_end_screen:
        ldx     sup_sp
        stx     init_sp
        lds     init_sp
        pshs    a
        jsr     wipe_state
        jsr     cart_load_jp
        jsr     hi_insert
        puls    a
        sta     game_state
        clr     ge_ready
        jmp     frame
        endif


jetman_reset:
        clra
        sta     jet_x
        sta     jet_xf
        sta     jet_yf
        sta     jet_vx
        sta     jet_vy
        sta     jet_flags
        sta     jet_mode
        sta     dying
        lda     #PF_GROUND+JET_HALF_H
        sta     jet_y
        lda     #START_DELAY
        ldb     lap
        beq     jr_delay
jr_sub:
        suba    #START_DELAY/(MAX_LAP+1)
        decb
        bne     jr_sub
jr_delay:
        sta     start_delay
        rts


update_dying:
        lda     dying
        beq     ud_done
        dec     dying
        bne     ud_done
        lda     lives
        beq     ud_over
        dec     lives
        jmp     jetman_reset
ud_over:
        if      CART
        jsr     cart_want_table
        bne     ud_no_table
        endif
        jsr     hi_insert
ud_no_table:
        lda     #GS_OVER
        sta     game_state
        clr     ge_ready
ud_done:
        rts


hi_insert:
        ldx     #hi_table
        ldb     #HI_COUNT
hi_search:
        lda     score
        cmpa    ,x
        blo     hi_next
        bhi     hi_place
        lda     score+1
        cmpa    1,x
        blo     hi_next
        bhi     hi_place
        lda     score+2
        cmpa    2,x
        bls     hi_next
hi_place:
        stx     tmp_ptr
        ldy     #hi_table+(HI_COUNT-1)*3
hi_shift:
        cmpy    tmp_ptr
        bls     hi_write
        lda     -3,y
        sta     ,y
        lda     -2,y
        sta     1,y
        lda     -1,y
        sta     2,y
        leay    -3,y
        bra     hi_shift
hi_write:
        ldx     tmp_ptr
        lda     score
        sta     ,x
        lda     score+1
        sta     1,x
        lda     score+2
        sta     2,x
        rts
hi_next:
        leax    3,x
        decb
        bne     hi_search
        rts


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
        bitb    #$01
        beq     ri_no_thrust
        ora     #IN_THRUST
ri_no_thrust:
        bitb    #$08
        beq     ri_no_fire
        ora     #IN_FIRE
ri_no_fire:
        sta     in_state
        rts


update_jetman:
        lda     dying
        bne     uj_frozen
        lda     jet_mode
        lbeq    jetman_walk

        bra     jetman_fly
uj_frozen:
        rts


jetman_fly:

        lda     in_state
        bita    #IN_RIGHT
        bne     fly_right
        bita    #IN_LEFT
        bne     fly_left


        lda     frame_count+1
        anda    #1
        beq     fly_h_move
        bra     fly_h_brake

fly_right:
        lda     jet_flags
        anda    #$FF-FACE_LEFT
        sta     jet_flags
        bita    #MOV_LEFT
        bne     fly_h_brake
        bra     fly_h_accel

fly_left:
        lda     jet_flags
        ora     #FACE_LEFT
        sta     jet_flags
        bita    #MOV_LEFT
        bne     fly_h_accel


fly_h_brake:
        lda     jet_vx
        suba    #ACC
        bpl     fly_h_store
        clra
        sta     jet_vx
        lda     jet_flags
        eora    #MOV_LEFT
        sta     jet_flags
        bra     fly_h_move
fly_h_store:
        sta     jet_vx
        bra     fly_h_move

fly_h_accel:
        lda     jet_vx
        adda    #ACC
        cmpa    #VX_MAX
        bls     fly_h_store2
        lda     #VX_MAX
fly_h_store2:
        sta     jet_vx

fly_h_move:
        lda     jet_vx
        ldb     #FIX_MUL
        mul
        std     step
        lda     jet_flags
        bita    #MOV_LEFT
        bne     fly_h_left
        ldd     jet_x
        addd    step
        bra     fly_h_set
fly_h_left:
        ldd     jet_x
        subd    step
fly_h_set:
        std     jet_x


        lda     jet_x
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        sta     jet_x


        lda     in_state
        bita    #IN_THRUST
        bne     fly_thrusting

        lda     jet_flags
        bita    #MOV_DOWN
        bne     fly_v_accel
        bra     fly_v_brake

fly_thrusting:
        lda     jet_flags
        bita    #MOV_DOWN
        bne     fly_v_brake


fly_v_accel:
        lda     jet_vy
        adda    #ACC
        cmpa    #VY_MAX
        bls     fly_v_store
        lda     #VY_MAX
        bra     fly_v_store

fly_v_brake:
        lda     jet_vy
        suba    #ACC
        bpl     fly_v_store
        clra
        sta     jet_vy
        lda     jet_flags
        eora    #MOV_DOWN
        sta     jet_flags
        bra     fly_v_move
fly_v_store:
        sta     jet_vy

fly_v_move:
        lda     jet_vy
        ldb     #FIX_MUL
        mul
        std     step
        lda     jet_flags
        bita    #MOV_DOWN
        bne     fly_v_down
        ldd     jet_y
        addd    step
        bra     fly_v_set
fly_v_down:
        ldd     jet_y
        subd    step
fly_v_set:
        std     jet_y


        lda     jet_y
        cmpa    #PF_TOP-JET_HALF_H
        blt     fly_no_ceiling
        lda     #PF_TOP-JET_HALF_H
        sta     jet_y
        clr     jet_yf
        lda     jet_flags
        ora     #MOV_DOWN
        sta     jet_flags
        lsr     jet_vy
fly_no_ceiling:

        jmp     check_platforms


jetman_walk:
        lda     in_state
        bita    #IN_RIGHT
        bne     walk_right
        bita    #IN_LEFT
        bne     walk_left
        clr     jet_vx
        bra     walk_wrap

walk_right:
        lda     jet_flags
        anda    #$FF-FACE_LEFT-MOV_LEFT
        sta     jet_flags
        inc     jet_x
        lda     #VX_WALK
        sta     jet_vx
        bra     walk_wrap

walk_left:
        lda     jet_flags
        ora     #FACE_LEFT+MOV_LEFT
        sta     jet_flags
        dec     jet_x
        lda     #VX_WALK
        sta     jet_vx

walk_wrap:
        lda     jet_x
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        sta     jet_x

        lda     in_state
        bita    #IN_THRUST
        bne     walk_thrust_off

        jsr     platform_support
        bne     walk_done


        jsr     walk_to_fly
        lda     jet_flags
        ora     #MOV_DOWN
        sta     jet_flags
        rts

walk_thrust_off:
        jsr     walk_to_fly
        lda     jet_flags
        anda    #$FF-MOV_DOWN
        sta     jet_flags
        lda     jet_y
        adda    #2
        sta     jet_y
walk_done:
        rts

walk_to_fly:
        lda     #MODE_FLY
        sta     jet_mode
        clr     jet_vx
        clr     jet_vy
        clr     jet_xf
        clr     jet_yf
        rts


check_platforms:
        ldu     plat_ptr
cp_loop:
        lda     ,u
        cmpa    #$80
        beq     cp_done

        ldb     jet_flags
        bitb    #MOV_DOWN
        beq     cp_rising


        ldb     jet_y
        subb    #JET_HALF_H
        subb    ,u
        cmpb    #1
        bgt     cp_next
        cmpb    #-3
        blt     cp_next
        jsr     plat_overlap
        beq     cp_next

        lda     ,u
        adda    #JET_HALF_H
        sta     jet_y
        clr     jet_yf
        clr     jet_xf
        clr     jet_vx
        clr     jet_vy
        clr     jet_mode
        rts

cp_rising:

        ldb     jet_y
        addb    #JET_HALF_H
        subb    ,u
        cmpb    #-1
        blt     cp_next
        cmpb    #3
        bgt     cp_next
        jsr     plat_overlap
        beq     cp_next

        lda     jet_flags
        ora     #MOV_DOWN
        sta     jet_flags
        clr     jet_vy
        rts

cp_next:
        leau    3,u
        bra     cp_loop
cp_done:
        rts


platform_support:
        ldu     plat_ptr
ps_loop:
        lda     ,u
        cmpa    #$80
        beq     ps_no
        ldb     jet_y
        subb    #JET_HALF_H
        cmpb    ,u
        bne     ps_next
        jsr     plat_overlap
        bne     ps_yes
ps_next:
        leau    3,u
        bra     ps_loop
ps_no:
        clra
        rts
ps_yes:
        lda     #1
        rts


plat_overlap:
        lda     jet_x
        adda    #JET_HALF_W
        cmpa    1,u
        blt     po_no
        lda     jet_x
        suba    #JET_HALF_W
        ldb     1,u
        addb    2,u
        pshs    b
        cmpa    ,s+
        bgt     po_no
        lda     #1
        rts
po_no:
        clra
        rts


next_rnd:
        pshs    b
        ldb     #8
        lda     rnd
nr_step:
        lsra
        bcc     nr_no_xor
        eora    #$B8
nr_no_xor:
        decb
        bne     nr_step
        sta     rnd
        puls    b
        rts


count_aliens:
        ldx     #aliens
        clrb
        lda     #MAX_ALIENS
        sta     tmp_cnt
ca_loop:
        tst     ,x
        beq     ca_next
        incb
ca_next:
        leax    ALIEN_SZ,x
        dec     tmp_cnt
        bne     ca_loop
        rts


find_free:
        ldu     #aliens
        lda     #MAX_ALIENS
        sta     tmp_cnt
ff_loop:
        lda     ,u
        beq     ff_found
        leau    ALIEN_SZ,u
        dec     tmp_cnt
        bne     ff_loop
        clra
        rts
ff_found:
        lda     #1
        rts


spawn_alien:
        lda     start_delay
        beq     sa_free
        dec     start_delay
        rts
sa_free:
        jsr     count_aliens
        cmpb    #3
        blo     sa_spawn
        cmpb    #MAX_ALIENS
        bhs     sa_no
        jsr     next_rnd
        anda    spawn_mask
        bne     sa_no
sa_spawn:
        jsr     find_free
        beq     sa_no

        lda     level
        anda    #7
        ldx     #level_alien_types
        lda     a,x
        sta     A_TYPE,u

        ldb     A_TYPE,u
        decb
        lslb
        ldx     #alien_speed
        abx
        lda     ,x
        jsr     speed_up
        sta     A_SX,u
        lda     1,x
        jsr     speed_up
        sta     A_SY,u

        clr     A_XF,u
        clr     A_YF,u
        clr     A_ST,u

        lda     frame_count+1
        anda    #$40
        bne     sa_right
        lda     #-PF_HALF_W
        sta     A_X,u
        bra     sa_height
sa_right:
        lda     #PF_HALF_W-1
        sta     A_X,u
        neg     A_SX,u

sa_height:
        jsr     next_rnd
        anda    #$7F
        suba    #64
        cmpa    #PF_TOP-8
        blt     sa_h1
        lda     #PF_TOP-8
sa_h1:
        cmpa    #PF_GROUND+14
        bgt     sa_h2
        lda     #PF_GROUND+14
sa_h2:
        sta     A_Y,u
sa_no:
        rts


level_alien_types:
        fcb     T_METEOR, T_SQUID, T_SPHERE, T_FIGHT
        fcb     T_UFO,    T_CROSS, T_METEOR, T_UFO


alien_speed:
        fcb     36, -20
        fcb     32,  32
        fcb     32,   0
        fcb      0,   0
        fcb     20,  20
        fcb     32,  24


update_aliens:
        ldx     #aliens
        lda     #MAX_ALIENS
        sta     tmp_cnt
ua_loop:
        lda     ,x
        beq     ua_next
        pshs    x
        tfr     x,u
        jsr     alien_dispatch
        puls    x
ua_next:
        leax    ALIEN_SZ,x
        dec     tmp_cnt
        bne     ua_loop
        rts

alien_dispatch:
        ldb     A_TYPE,u
        decb
        lslb
        ldx     #alien_jump
        abx
        ldx     ,x
        jmp     ,x

alien_jump:
        fdb     upd_meteor,  upd_squid, upd_sphere
        fdb     upd_fighter, upd_ufo,   upd_cross


alien_move:
        ldb     A_SX,u
        sex
        aslb
        rola
        aslb
        rola
        pshs    d
        ldd     A_X,u
        addd    ,s++
        std     A_X,u
        lda     A_X,u
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        sta     A_X,u

        ldb     A_SY,u
        sex
        aslb
        rola
        aslb
        rola
        pshs    d
        ldd     A_Y,u
        addd    ,s++
        std     A_Y,u
        rts


alien_platform_hit:
        ldy     plat_ptr
aph_loop:
        lda     ,y
        cmpa    #$80
        beq     aph_none

        lda     A_X,u
        adda    #ALIEN_HALF
        cmpa    1,y
        blt     aph_next
        lda     A_X,u
        suba    #ALIEN_HALF
        ldb     1,y
        addb    2,y
        pshs    b
        cmpa    ,s+
        bgt     aph_next

        lda     A_SY,u
        beq     aph_next
        bpl     aph_rising

        lda     A_Y,u
        suba    #ALIEN_HALF
        suba    ,y
        cmpa    #2
        bgt     aph_next
        cmpa    #-3
        blt     aph_next
        lda     ,y
        adda    #ALIEN_HALF+1
        sta     A_Y,u
        clr     A_YF,u
        lda     #1
        rts

aph_rising:
        lda     A_Y,u
        adda    #ALIEN_HALF
        suba    ,y
        cmpa    #-2
        blt     aph_next
        cmpa    #3
        bgt     aph_next
        lda     ,y
        suba    #ALIEN_HALF+1
        sta     A_Y,u
        clr     A_YF,u
        lda     #2
        rts

aph_next:
        leay    3,y
        bra     aph_loop
aph_none:
        clra
        rts


alien_bounds:
        lda     A_Y,u
        cmpa    #PF_TOP-ALIEN_HALF
        blt     ab_below
        lda     #PF_TOP-ALIEN_HALF
        sta     A_Y,u
        clr     A_YF,u
        bra     alien_sy_neg
ab_below:
        cmpa    #PF_GROUND+ALIEN_HALF
        bgt     ab_done
        lda     #PF_GROUND+ALIEN_HALF
        sta     A_Y,u
        clr     A_YF,u
        bra     alien_sy_pos
ab_done:
        rts

alien_sy_pos:
        lda     A_SY,u
        bpl     asp_done
        nega
        sta     A_SY,u
asp_done:
        rts

alien_sy_neg:
        lda     A_SY,u
        bmi     asn_done
        nega
        sta     A_SY,u
asn_done:
        rts

alien_kill:
        clr     A_TYPE,u
        rts


alien_bounce:
        cmpa    #1
        bne     ar_down
        bra     alien_sy_pos
ar_down:
        bra     alien_sy_neg


upd_meteor:
        jsr     alien_move
        jsr     alien_platform_hit
        tsta
        bne     alien_kill
        lda     A_Y,u
        cmpa    #PF_TOP-ALIEN_HALF
        bge     alien_kill
        jmp     alien_vs_jetman


upd_squid:
        jsr     alien_move
        jsr     alien_platform_hit
        tsta
        beq     um_none
        jsr     alien_bounce
um_none:
        jsr     alien_bounds
        jmp     alien_vs_jetman


upd_sphere:
        lda     A_ST,u
        bne     ue_hopping
        clr     A_SY,u
        jsr     next_rnd
        anda    #$0F
        bne     ue_move
        jsr     next_rnd
        anda    #$1F
        adda    #16
        sta     A_ST,u
        jsr     next_rnd
        anda    #$80
        beq     ue_up
        lda     #-32
        bra     ue_set
ue_up:
        lda     #32
ue_set:
        jsr     speed_up
        sta     A_SY,u
        bra     ue_move
ue_hopping:
        dec     A_ST,u
ue_move:
        jsr     alien_move
        jsr     alien_platform_hit
        tsta
        beq     ue_none
        jsr     alien_bounce
ue_none:
        jsr     alien_bounds
        jmp     alien_vs_jetman


upd_cross:
        lda     A_SY,u
        bmi     ucr_down
        adda    #2
        cmpa    #56
        ble     ucr_set
        lda     #56
        bra     ucr_set
ucr_down:
        suba    #2
        cmpa    #-56
        bge     ucr_set
        lda     #-56
ucr_set:
        sta     A_SY,u
        jsr     alien_move
        jsr     alien_platform_hit
        tsta
        beq     ucr_none
        jsr     cross_bounce
ucr_none:
        jsr     alien_bounds
        jmp     alien_vs_jetman

cross_bounce:
        jsr     next_rnd
        anda    #$1F
        adda    #8
        ldb     A_SY,u
        bmi     ucr_bounce_set
        nega
ucr_bounce_set:
        sta     A_SY,u
        neg     A_SX,u
        rts


upd_ufo:
        lda     jet_x
        suba    A_X,u
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        tsta
        beq     uo_y
        bmi     uo_x_neg
        lda     A_SX,u
        adda    #2
        cmpa    ufo_top
        ble     uo_x_set
        lda     ufo_top
        bra     uo_x_set
uo_x_neg:
        lda     A_SX,u
        suba    #2
        cmpa    ufo_bot
        bge     uo_x_set
        lda     ufo_bot
uo_x_set:
        sta     A_SX,u

uo_y:
        lda     A_Y,u
        cmpa    jet_y
        beq     uo_move
        blt     uo_y_up
        lda     A_SY,u
        suba    #2
        cmpa    ufo_bot
        bge     uo_y_set
        lda     ufo_bot
        bra     uo_y_set
uo_y_up:
        lda     A_SY,u
        adda    #2
        cmpa    ufo_top
        ble     uo_y_set
        lda     ufo_top
uo_y_set:
        sta     A_SY,u

uo_move:
        jsr     alien_move
        jsr     alien_platform_hit
        tsta
        beq     uo_none
        jsr     alien_bounce
        neg     A_SX,u
uo_none:
        jsr     alien_bounds
        jmp     alien_vs_jetman


upd_fighter:
        lda     A_ST,u
        bne     uf_charge

        clr     A_SX,u
        clr     A_SY,u
        lda     A_Y,u
        suba    #3
        cmpa    jet_y
        bgt     uf_roll
        lda     A_Y,u
        adda    #3
        cmpa    jet_y
        bge     uf_launch
uf_roll:
        jsr     next_rnd
        anda    #$07
        bne     uf_move

uf_launch:
        jsr     next_rnd
        anda    #$7F
        adda    #32
        sta     A_ST,u
        lda     jet_x
        suba    A_X,u
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        bmi     uf_left
        lda     #FIGHT_DASH
        bra     uf_set_sx
uf_left:
        lda     #-FIGHT_DASH
uf_set_sx:
        sta     A_SX,u
        bra     uf_move

uf_charge:
        dec     A_ST,u
        lbeq    alien_kill
        lda     A_Y,u
        cmpa    jet_y
        blt     uf_up
        lda     #-16
        bra     uf_set_sy
uf_up:
        lda     #16
uf_set_sy:
        jsr     speed_up
        sta     A_SY,u


uf_move:
        jsr     alien_move
        jsr     alien_platform_hit
        tsta
        lbne    alien_kill
        jmp     alien_vs_jetman


alien_vs_jetman:
        lda     dying
        bne     avj_no
        lda     jet_x
        suba    A_X,u
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        bpl     avj_dx
        nega
avj_dx:
        cmpa    #JET_HALF_W+ALIEN_HALF
        bgt     avj_no
        lda     A_Y,u
        suba    #JET_HALF_H+ALIEN_HALF
        cmpa    jet_y
        bgt     avj_no
        lda     A_Y,u
        adda    #JET_HALF_H+ALIEN_HALF
        cmpa    jet_y
        blt     avj_no
        clr     A_TYPE,u
        jsr     jetman_dies
avj_no:
        rts


jetman_dies:
        jsr     drop_carried
        ldb     #SFX_DEATH
        jsr     snd_play
        lda     #DYING_FRAMES
        sta     dying
        rts


drop_carried:
        clr     carrying
        ldx     #items
        ldb     #MAX_ITEMS
dc_loop:
        lda     ,x
        beq     dc_next
        lda     I_STATE,x
        cmpa    #1
        bne     dc_next
        lda     I_TYPE,x
        cmpa    #IT_FUEL
        beq     dc_drop

        lda     I_HOME_X,x
        sta     I_X,x
        lda     I_HOME_Y,x
        sta     I_Y,x
dc_drop:
        clr     I_STATE,x
dc_next:
        leax    ITEM_SZ,x
        decb
        bne     dc_loop
        rts


next_level:
        inc     level
        if      CART
        jsr     cart_jp_level
        endif


        lda     level
        cmpa    #MAX_LEVELS
        bhs     game_won
        jsr     set_level
        clr     rocket_fuel
        jsr     clear_items
        clr     carrying
        lda     level
        anda    #1
        bne     nl_refuel
        jsr     level_build
        jmp     jetman_reset
nl_refuel:
        lda     #3
        sta     rocket_mods
        clr     rocket_fuel
        lda     #PF_TOP
        sta     rocket_y
        lda     #RS_DOWN
        sta     rocket_state
        rts


game_won:
        if      CART
        jsr     cart_want_table
        bne     gw_no_table
        endif
        jsr     hi_insert
gw_no_table:
        lda     #GS_WON
        sta     game_state
        clr     ge_ready
        rts


level_build:
        clr     rocket_fuel
        lda     #1
        sta     rocket_mods
        lda     #PF_GROUND
        sta     rocket_y
        clr     rocket_state


place_modules:
        ldx     #items
        lda     #IT_MODULE
        sta     I_TYPE,x
        clr     I_STATE,x
        lda     #-40
        sta     I_X,x
        lda     #50
        sta     I_Y,x
        leax    ITEM_SZ,x
        lda     #IT_MODULE
        sta     I_TYPE,x
        clr     I_STATE,x
        lda     #40
        sta     I_X,x
        lda     #16
        sta     I_Y,x
        rts

clear_items:
        ldx     #items
        clr     ,x
        clr     ITEM_SZ,x
        rts


update_rocket:
        lda     rocket_state
        beq     ur_pad
        cmpa    #RS_UP
        beq     ur_rise

        dec     rocket_y
        lda     rocket_y
        cmpa    #PF_GROUND
        bgt     ur_done
        lda     #PF_GROUND
        sta     rocket_y
        clr     rocket_state
        jmp     jetman_reset
ur_done:
        rts

ur_rise:
        inc     rocket_y
        lda     rocket_y
        cmpa    #PF_TOP
        blt     ur_done
        jmp     next_level


ur_pad:
        lda     rocket_mods
        cmpa    #3
        blo     ur_done
        lda     rocket_fuel
        cmpa    #FUEL_NEEDED
        blo     spawn_fuel
        jsr     jetman_at_ship
        beq     ur_done
        lda     #RS_UP
        sta     rocket_state


        ldx     #fanfare_data
        stx     jseq_p
        clr     jseq_t
        clr     env_toggle
        jmp     clear_for_flight


jetman_at_ship:
        lda     jet_x
        suba    #ROCKET_X
        bpl     jn_dx
        nega
jn_dx:
        cmpa    #10
        bgt     jn_no
        lda     rocket_y
        cmpa    jet_y
        bgt     jn_no
        lda     rocket_y
        adda    #24
        cmpa    jet_y
        blt     jn_no
        lda     #1
        rts
jn_no:
        clra
        rts


clear_for_flight:
        clr     carrying
        ldx     #aliens
        ldb     #MAX_ALIENS
lpv_a:
        clr     ,x
        leax    ALIEN_SZ,x
        decb
        bne     lpv_a
        ldx     #lasers
        ldb     #MAX_LASERS
lpv_l:
        clr     ,x
        leax    LASER_SZ,x
        decb
        bne     lpv_l
        ldx     #items
        clr     ,x
        clr     ITEM_SZ,x
        rts


spawn_fuel:
        ldx     #items
        lda     #MAX_ITEMS
        sta     tmp_cnt
sf_loop:
        lda     ,x
        bne     sf_no
        leax    ITEM_SZ,x
        dec     tmp_cnt
        bne     sf_loop
        jsr     next_rnd
        anda    #$0F
        bne     sf_no
        ldx     #items
        lda     #IT_FUEL
        sta     I_TYPE,x
        clr     I_STATE,x
        lda     #PF_TOP-ITEM_HALF
        sta     I_Y,x
        jsr     next_rnd
        lsra
        lsra
        lsra
        lsra
        lsra
        anda    #7
        ldy     #fuel_cols
        lda     a,y
        sta     I_X,x
sf_no:
        rts


fuel_cols:
        fcb     -56, -40, -24, -8, 8, 24, 40, 56


update_items:
        ldx     #items
        lda     #MAX_ITEMS
        sta     tmp_cnt
ui_loop:
        lda     ,x
        beq     ui_next
        lda     I_STATE,x
        beq     ui_fall
        cmpa    #1
        beq     ui_carried
        jsr     item_deliver
        bra     ui_next
ui_fall:
        jsr     item_fall
        bra     ui_next
ui_carried:
        jsr     item_carried
ui_next:
        leax    ITEM_SZ,x
        dec     tmp_cnt
        bne     ui_loop
        rts


item_fall:
        jsr     item_support
        bne     item_pickup

        lda     I_Y,x
        suba    #2
        sta     I_Y,x
        cmpa    #PF_GROUND+ITEM_HALF
        bgt     ic_platforms
        lda     #PF_GROUND+ITEM_HALF
        sta     I_Y,x
        bra     item_pickup

ic_platforms:
        ldy     plat_ptr
ic_loop:
        lda     ,y
        cmpa    #$80
        beq     item_pickup
        jsr     item_overlap
        beq     ic_next
        lda     I_Y,x
        suba    #ITEM_HALF
        suba    ,y
        cmpa    #1
        bgt     ic_next
        cmpa    #-4
        blt     ic_next
        lda     ,y
        adda    #ITEM_HALF
        sta     I_Y,x
        bra     item_pickup
ic_next:
        leay    3,y
        bra     ic_loop


item_pickup:
        lda     dying
        bne     ia_no
        lda     carrying
        bne     ia_no

        lda     jet_x
        suba    I_X,x
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        bpl     ia_dx
        nega
ia_dx:
        cmpa    #JET_HALF_W+ITEM_HALF
        bgt     ia_no
        lda     I_Y,x
        suba    #JET_HALF_H+ITEM_HALF
        cmpa    jet_y
        bgt     ia_no
        lda     I_Y,x
        adda    #JET_HALF_H+ITEM_HALF
        cmpa    jet_y
        blt     ia_no
        lda     I_X,x
        sta     I_HOME_X,x
        lda     I_Y,x
        sta     I_HOME_Y,x
        lda     #1
        sta     I_STATE,x
        sta     carrying
        pshs    x
        ldb     #SFX_PICKUP
        jsr     snd_play
        puls    x
        ldd     #$0100
        jmp     add_score16
ia_no:
        rts


item_carried:
        lda     jet_x
        sta     I_X,x
        lda     jet_y
        suba    #JET_HALF_H-ITEM_HALF
        sta     I_Y,x


        lda     I_X,x
        suba    #ROCKET_X
        bpl     icl_dx
        nega
icl_dx:
        cmpa    #ROCKET_HALF_W
        bgt     icl_done
        lda     #ROCKET_X
        sta     I_X,x
        lda     #2
        sta     I_STATE,x
        clr     carrying
icl_done:
        rts


item_deliver:
        lda     I_Y,x
        suba    #2
        sta     I_Y,x
        lda     I_TYPE,x
        cmpa    #IT_FUEL
        beq     ie_fuel

        lda     rocket_mods
        ldb     #MODULE_H
        mul
        tfr     b,a
        adda    rocket_y
        adda    #ITEM_HALF
        cmpa    I_Y,x
        blt     ie_done
        inc     rocket_mods
        bra     ie_consume

ie_fuel:
        lda     rocket_y
        adda    #8
        cmpa    I_Y,x
        blt     ie_done
        inc     rocket_fuel
ie_consume:
        pshs    x
        ldb     #SFX_DOCK
        jsr     snd_play
        puls    x
        clr     I_TYPE,x
        clr     I_STATE,x
ie_done:
        rts


item_support:
        lda     I_Y,x
        suba    #ITEM_HALF
        cmpa    #PF_GROUND
        beq     is_yes
        ldy     plat_ptr
is_loop:
        lda     ,y
        cmpa    #$80
        beq     is_no
        lda     I_Y,x
        suba    #ITEM_HALF
        cmpa    ,y
        bne     is_next
        jsr     item_overlap
        bne     is_yes
is_next:
        leay    3,y
        bra     is_loop
is_no:
        clra
        rts
is_yes:
        lda     #1
        rts


item_overlap:
        lda     I_X,x
        adda    #ITEM_HALF
        cmpa    1,y
        blt     io_no
        lda     I_X,x
        suba    #ITEM_HALF
        ldb     1,y
        addb    2,y
        pshs    b
        cmpa    ,s+
        bgt     io_no
        lda     #1
        rts
io_no:
        clra
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
        fcb     0, 10, $00,$60, $00,$28
        fcb     0, 12, $02,$80, $FF,$D0
        fcb     0, 14, $03,$00, $FF,$C0
        fcb     1, 15, $00,$08, $00,$02
        fcb     1, 10, $00,$04, $00,$03


snd_update:
        lda     rocket_state
        cmpa    #RS_UP
        lbeq    jingle_tick


        lda     sA_t
        beq     su_a_silent
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
su_a_silent:
        clra
su_a_vol:
        sta     SND_REG-8


        lda     sB_t
        beq     su_b_silent
        deca
        sta     sB_t
        ldd     sB_p
        addd    sB_d
        std     sB_p
        andb    #$1F
        stb     SND_REG-6
        lda     sB_t
        bra     su_b_vol
su_b_silent:
        clra
su_b_vol:
        sta     SND_REG-9


        lda     rocket_state
        cmpa    #RS_DOWN
        beq     su_c_on
        lda     in_state
        bita    #IN_THRUST
        beq     su_c_release
su_c_on:
        lda     #10
        sta     sC_t
        bra     su_c_set
su_c_release:
        lda     sC_t
        beq     su_c_set
        deca
        deca
        bpl     su_c_store
        clra
su_c_store:
        sta     sC_t
su_c_set:
        lda     sC_t
        sta     SND_REG-10
        beq     su_mixer
        lda     frame_count+1
        anda    #3
        adda    #12
        sta     SND_REG-6

su_mixer:


        lda     #%00001110
        sta     SND_REG-7
su_send:
        jsr     DP_to_D0
        jmp     Do_Sound


jingle_tick:
        lda     #%00111000
        sta     SND_REG-7
        lda     #$05
        sta     SND_REG-12
        clr     SND_REG-11

        lda     jseq_t
        beq     jt_new
        deca
        sta     jseq_t
        jmp     su_send

jt_new:
        ldx     jseq_p
        lda     ,x
        cmpa    #$FF
        beq     jt_silent
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
        sta     jseq_t
        stx     jseq_p
        puls    a,b
        tsta
        bne     jt_hit
        tstb
        beq     jt_silent
jt_hit:
        lda     #$10
        sta     SND_REG-8
        sta     SND_REG-9
        sta     SND_REG-10
        lda     env_toggle
        eora    #$09
        sta     env_toggle
        sta     SND_REG-13
        jmp     su_send
jt_silent:
        clr     SND_REG-8
        clr     SND_REG-9
        clr     SND_REG-10
        jmp     su_send


fanfare_data:
        fcb     $00,239, $01, 28, $02,204,  5
        fcb     $00,239, $01, 28, $02,204,  5
        fcb     $00,179, $00,239, $02,204, 18
        fcb     $00,  0, $00,  0, $00,  0,  4
        fcb     $00,179, $00,239, $02,204,  5
        fcb     $00,179, $00,239, $02,204,  5
        fcb     $00,142, $00,179, $02,204, 18
        fcb     $00,  0, $00,  0, $00,  0,  4
        fcb     $00,142, $00,179, $01,222,  5
        fcb     $00,120, $00,142, $01,222,  5
        fcb     $00, 90, $00,120, $01,222, 22
        fcb     $00,  0, $00,  0, $00,  0,  4
        fcb     $00,120, $00,142, $01,222,  5
        fcb     $00,142, $00,179, $01,222,  5
        fcb     $00,179, $00,239, $02,204, 25
        fcb     $FF


fire_laser:
        lda     in_state
        bita    #IN_FIRE
        beq     fl_no
        lda     frame_count+1
        anda    #3
        bne     fl_no

        ldu     #lasers
        lda     #MAX_LASERS
        sta     tmp_cnt
fl_loop:
        lda     ,u
        beq     fl_found
        leau    LASER_SZ,u
        dec     tmp_cnt
        bne     fl_loop
fl_no:
        rts

fl_found:
        lda     #1
        sta     L_ACTIVE,u
        lda     jet_x
        sta     L_X,u
        lda     jet_y
        sta     L_Y,u
        lda     jet_flags
        bita    #FACE_LEFT
        bne     fl_left
        lda     #LASER_SPEED
        bra     fl_set
fl_left:
        lda     #-LASER_SPEED
fl_set:
        sta     L_SX,u
        jsr     next_rnd
        anda    #7
        adda    #12
        sta     L_LIFE,u
        ldb     #SFX_LASER
        jmp     snd_play


update_lasers:
        ldx     #lasers
        lda     #MAX_LASERS
        sta     tmp_cnt
ul_loop:
        lda     ,x
        beq     ul_next
        lda     L_X,x
        adda    L_SX,x
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        sta     L_X,x
        dec     L_LIFE,x
        bne     ul_hit
        clr     L_ACTIVE,x
        bra     ul_next
ul_hit:
        pshs    x
        jsr     laser_vs_aliens
        puls    x
ul_next:
        leax    LASER_SZ,x
        dec     tmp_cnt
        bne     ul_loop
        rts


laser_vs_aliens:
        ldu     #aliens
        lda     #MAX_ALIENS
        sta     tmp_cnt2
lva_loop:
        lda     ,u
        beq     lva_next

        lda     A_Y,u
        suba    #ALIEN_HALF+2
        cmpa    L_Y,x
        bgt     lva_next
        lda     A_Y,u
        adda    #ALIEN_HALF+2
        cmpa    L_Y,x
        blt     lva_next

        lda     A_X,u
        suba    L_X,x
        adda    #PF_HALF_W
        anda    #$7F
        suba    #PF_HALF_W
        ldb     L_SX,x
        bmi     lva_leftward
        cmpa    #ALIEN_HALF
        bgt     lva_next
        cmpa    #-LASER_SPAN
        blt     lva_next
        bra     lva_hit
lva_leftward:
        cmpa    #-ALIEN_HALF
        blt     lva_next
        cmpa    #LASER_SPAN
        bgt     lva_next

lva_hit:
        ldb     A_TYPE,u
        decb
        pshs    x
        ldx     #alien_points
        abx
        ldb     ,x
        clra
        puls    x
        jsr     add_score16
        clr     A_TYPE,u
        clr     L_ACTIVE,x
        ldb     #SFX_ALIEN
        jmp     snd_play

lva_next:
        leau    ALIEN_SZ,u
        dec     tmp_cnt2
        bne     lva_loop
        rts


alien_points:
        fcb     $25
        fcb     $80
        fcb     $40
        fcb     $55
        fcb     $50
        fcb     $60


add_score16:
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


draw_platforms:
        ldu     plat_ptr
dp_loop:
        lda     ,u
        cmpa    #$80
        beq     dp_done
        jsr     Reset0Ref
        ldd     ,u++
        jsr     Moveto_d
        clra
        ldb     ,u+
        jsr     Draw_Line_d
        bra     dp_loop
dp_done:
        rts


set_level:
        lda     level
        anda    #7
        ldb     #PLAT_SET_SZ
        mul
        addd    #plat_sets
        std     plat_ptr


set_difficulty:
        lda     level
        lsra
        lsra
        lsra
        cmpa    #MAX_LAP
        bls     sd_ok
        lda     #MAX_LAP
sd_ok:
        sta     lap
        lsla
        ldx     #lap_table
        ldb     a,x
        stb     spawn_mask
        leax    1,x
        ldb     a,x
        stb     lap_bonus
        lda     #UFO_MAX
        jsr     speed_up
        sta     ufo_top
        nega
        sta     ufo_bot
        rts


lap_table:
        fcb     $1F,  0
        fcb     $07,  6
        fcb     $03, 12


speed_up:
        tsta
        beq     su_done
        bmi     su_neg
        adda    lap_bonus
        cmpa    #ALIEN_VMAX
        bls     su_done
        lda     #ALIEN_VMAX
        rts
su_neg:
        suba    lap_bonus
        cmpa    #-ALIEN_VMAX
        bge     su_done
        lda     #-ALIEN_VMAX
su_done:
        rts


plat_sets:
        fcb     PF_GROUND, -PF_HALF_W, 127
        fcb     -48, -57, 35
        fcb     -14, -16, 27
        fcb      30,  26, 35
        fcb     $80

        fcb     PF_GROUND, -PF_HALF_W, 127
        fcb     -46,  28, 34
        fcb      -6, -60, 35
        fcb      34, -20, 27
        fcb     $80

        fcb     PF_GROUND, -PF_HALF_W, 127
        fcb     -52, -14, 26
        fcb      -8,  30, 32
        fcb      28, -58, 35
        fcb     $80

        fcb     PF_GROUND, -PF_HALF_W, 127
        fcb     -34, -62, 34
        fcb       2,  30, 30
        fcb      38, -24, 28
        fcb     $80

        fcb     PF_GROUND, -PF_HALF_W, 127
        fcb     -50,  32, 30
        fcb     -18, -40, 34
        fcb      26,  -8, 20
        fcb     $80

        fcb     PF_GROUND, -PF_HALF_W, 127
        fcb     -44, -30, 30
        fcb      -4,  32, 30
        fcb      32, -62, 32
        fcb     $80

        fcb     PF_GROUND, -PF_HALF_W, 127
        fcb     -52, -60, 32
        fcb     -20,  28, 34
        fcb      20, -34, 34
        fcb     $80

        fcb     PF_GROUND, -PF_HALF_W, 127
        fcb     -38,  30, 32
        fcb       0, -58, 30
        fcb      36,  -6, 18
        fcb     $80

PLAT_SET_SZ     equ     13


draw_rocket:
        lda     rocket_y
        adda    #ROCKET_MID
        sta     tmp_cy
        lda     #ROCKET_X
        sta     tmp_cx
        clr     shape_flip

        lda     level
        lsra
        anda    #3
        ldb     #SHIP_SZ
        mul
        addd    #ship_models
        std     ship_base

        ldx     ship_base
        ldu     SH_A,x
        jsr     draw_shape
        lda     rocket_mods
        cmpa    #2
        blo     dr_legs
        ldx     ship_base
        ldu     SH_B,x
        jsr     draw_shape
        lda     rocket_mods
        cmpa    #3
        blo     dr_legs
        ldx     ship_base
        ldu     SH_C,x
        jsr     draw_shape


dr_legs:
        lda     rocket_state
        beq     dr_put_legs
        lda     frame_count+1
        anda    #4
        bne     dr_fire
dr_put_legs:
        ldx     ship_base
        ldu     SH_LEGS,x
        cmpu    #0
        beq     dr_fire
        jsr     draw_shape

dr_fire:
        lda     rocket_state
        beq     dr_fuel
        lda     frame_count+1
        anda    #4
        bne     dr_fire_tall
        ldx     ship_base
        ldu     SH_FIRE_A,x
        jsr     draw_shape
        bra     dr_fuel
dr_fire_tall:
        ldx     ship_base
        ldu     SH_FIRE_B,x
        jsr     draw_shape

dr_fuel:
        lda     rocket_fuel
        beq     dr_done
        ldb     #3
        mul
        stb     tmp_cnt2
        jsr     Reset0Ref
        lda     rocket_y
        adda    #6
        ldb     #ROCKET_X
        jsr     Moveto_d
        lda     tmp_cnt2
        clrb
        jsr     Draw_Line_d
dr_done:
        rts


shape_ship1_a:
        fcb      0, -6
        fcb     -1,  0
        fcb     -4, -5
        fcb     -4,  0
        fcb      1,  5
        fcb      0,  2
        fcb     -3,  0
        fcb      0,  8
        fcb      3,  0
        fcb      0,  2
        fcb     -1,  5
        fcb      4,  0
        fcb      4, -5
        fcb      1,  0
        fcb      0,-12
        fcb     $80


shape_ship1_b:
        fcb      0, -6
        fcb     10,  2
        fcb      0,  8
        fcb    -10,  2
        fcb     $80


shape_ship1_c:
        fcb     10,  4
        fcb      5, -3
        fcb      0, -2
        fcb     -5, -3
        fcb     $80


shape_ship1_legs:
        fcb    -11, -3
        fcb     -4,  0
        fcb    $81,  4,  6
        fcb     -4,  0
        fcb     $80


shape_ship1_fire_a:
        fcb    -11, -2
        fcb     -4,  0
        fcb    $81,  4,  2
        fcb     -6,  0
        fcb    $81,  6,  2
        fcb     -4,  0
        fcb     $80
shape_ship1_fire_b:
        fcb    -11, -2
        fcb     -6,  0
        fcb    $81,  6,  2
        fcb    -10,  0
        fcb    $81, 10,  2
        fcb     -6,  0
        fcb     $80


shape_ship2_a:
        fcb     -3, -16
        fcb      0,  32
        fcb     -2,   0
        fcb     -2,  -4
        fcb      0,  -6
        fcb     -4,  -1
        fcb      0, -10
        fcb      4,  -1
        fcb      0,  -6
        fcb      2,  -4
        fcb      2,   0
        fcb     $80


shape_ship2_b:
        fcb     -3,  16
        fcb      8,  -6
        fcb      0, -20
        fcb     -8,  -6
        fcb     $80


shape_ship2_c:
        fcb      5, -10
        fcb      6,   1
        fcb      4,   3
        fcb      0,  12
        fcb     -4,   3
        fcb     -6,   1
        fcb     $80


shape_ship2_legs:
        fcb     -5,  16
        fcb    -10,   5
        fcb    $81,  10, -37
        fcb    -10,  -5
        fcb     $80


shape_ship2_fire_a:
        fcb    -11, -3
        fcb     -4,   0
        fcb    $81,   4,  3
        fcb     -6,   0
        fcb    $81,   6,  3
        fcb     -4,   0
        fcb     $80
shape_ship2_fire_b:
        fcb    -11, -3
        fcb     -6,   0
        fcb    $81,   6,  3
        fcb    -10,   0
        fcb    $81,  10,  3
        fcb     -6,   0
        fcb     $80


shape_ship3_a:
        fcb      3,   4
        fcb    -12,  10
        fcb     -6,   0
        fcb      6, -10
        fcb      0,  -2
        fcb     -3,   0
        fcb      0,  -4
        fcb      3,   0
        fcb      0,  -2
        fcb     -6, -10
        fcb      6,   0
        fcb     12,  10
        fcb      0,   8
        fcb    -12,   0
        fcb    $81,  12,  -8
        fcb    -12,   0
        fcb     $80


shape_ship3_b:
        fcb      3,   4
        fcb      6,   0
        fcb      0,  -8
        fcb     -6,   0
        fcb     $80


shape_ship3_c:
        fcb      9,  -4
        fcb      6,   3
        fcb      0,   2
        fcb     -6,   3
        fcb     $80


shape_ship3_fire_a:
        fcb    -12,  -2
        fcb     -4,   0
        fcb    $81,   4,   2
        fcb     -6,   0
        fcb    $81,   6,   2
        fcb     -4,   0
        fcb     $80
shape_ship3_fire_b:
        fcb    -12,  -2
        fcb     -6,   0
        fcb    $81,   6,   2
        fcb    -10,   0
        fcb    $81,  10,   2
        fcb     -6,   0
        fcb     $80


shape_ship4_a:
        fcb      1,  16
        fcb    -10, -10
        fcb      0, -12
        fcb     10, -10
        fcb      0,  32
        fcb    -16,  11
        fcb    $81,  16, -43
        fcb    -16, -11
        fcb    $81,   6,  27
        fcb     -6,   0
        fcb     $80


shape_ship4_b:
        fcb      1,  16
        fcb      5,  -5
        fcb      0, -22
        fcb     -5,  -5
        fcb     $80


shape_ship4_c:
        fcb      6, -11
        fcb      7,   4
        fcb      2,   1
        fcb      0,  12
        fcb     -2,   1
        fcb     -7,   4
        fcb     $80


shape_ship4_fire_a:
        fcb     -9,  -5
        fcb     -4,   0
        fcb    $81,   4,  10
        fcb     -4,   0
        fcb     $80
shape_ship4_fire_b:
        fcb     -9,  -5
        fcb     -7,   0
        fcb    $81,   7,  10
        fcb     -7,   0
        fcb     $80


ship_models:
        fdb     shape_ship1_a, shape_ship1_b, shape_ship1_c
        fdb     shape_ship1_legs, shape_ship1_fire_a, shape_ship1_fire_b
        fdb     shape_ship2_a, shape_ship2_b, shape_ship2_c
        fdb     shape_ship2_legs, shape_ship2_fire_a, shape_ship2_fire_b
        fdb     shape_ship3_a, shape_ship3_b, shape_ship3_c
        fdb     0,                shape_ship3_fire_a, shape_ship3_fire_b
        fdb     shape_ship4_a, shape_ship4_b, shape_ship4_c
        fdb     0,                shape_ship4_fire_a, shape_ship4_fire_b


draw_items:
        ldx     #items
        lda     #MAX_ITEMS
        sta     tmp_cnt
di_loop:
        ldb     ,x
        beq     di_next
        lda     I_Y,x
        sta     tmp_cy
        lda     I_X,x
        sta     tmp_cx
        decb
        lslb
        pshs    x
        ldx     #item_shapes
        abx
        ldu     ,x
        jsr     draw_shape
        puls    x
di_next:
        leax    ITEM_SZ,x
        dec     tmp_cnt
        bne     di_loop
        rts

item_shapes:
        fdb     shape_module, shape_fuel


shape_module:
        fcb     -4, -5
        fcb      0, 10
        fcb      4, -2
        fcb      0, -6
        fcb     -4, -2
        fcb     $80
shape_fuel:
        fcb     -4, -4
        fcb      0,  8
        fcb      8,  0
        fcb      0, -8
        fcb     -8,  0
        fcb      4,  0
        fcb      0,  8
        fcb     $80


draw_lasers:
        ldx     #lasers
        lda     #MAX_LASERS
        sta     tmp_cnt
dl_loop:
        lda     ,x
        beq     dl_next
        pshs    x
        jsr     draw_one_laser
        puls    x
dl_next:
        leax    LASER_SZ,x
        dec     tmp_cnt
        bne     dl_loop
        rts


draw_one_laser:
        jsr     Reset0Ref
        lda     L_Y,x
        ldb     L_X,x
        jsr     Moveto_d
        lda     #4
        sta     tmp_cnt2
dol_loop:
        clra
        ldb     L_SX,x
        bmi     dol_stroke_left
        ldb     #-LASER_DASH
        bra     dol_stroke
dol_stroke_left:
        ldb     #LASER_DASH
dol_stroke:
        jsr     Draw_Line_d
        dec     tmp_cnt2
        beq     dol_done

        clra
        ldb     L_SX,x
        bmi     dol_skip_left
        ldb     #-(LASER_GAP-LASER_DASH)
        bra     dol_skip
dol_skip_left:
        ldb     #LASER_GAP-LASER_DASH
dol_skip:
        jsr     Moveto_d
        bra     dol_loop
dol_done:
        rts


draw_score:
        ldu     #score
        jsr     bcd_to_text
        lda     #SCORE_Y
        ldb     #SCORE_X
        jsr     draw_number
        jmp     draw_lives


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


draw_game_over:
        lda     #$F8
        sta     Vec_Text_HW
        lda     #$50
        sta     Vec_Text_Width

        lda     #66
        ldb     #-38
        ldu     #txt_over
        jsr     print_at

        ldu     #score
        jsr     bcd_to_text
        lda     #38
        ldb     #-14
        jsr     draw_number

        if      CART
        jsr     cart_want_table
        bne     dgo_press
        endif
        lda     #-18
        jsr     draw_best

dgo_press:
        lda     #-64
        ldb     #-30
        ldu     #txt_press
        jmp     print_at


draw_best:
        sta     tmp_cy
        adda    #24
        ldb     #-16
        ldu     #txt_best
        jsr     print_at
        ldx     #hi_table
        lda     #HI_SHOWN
        sta     tmp_cnt
db_list:
        pshs    x
        tfr     x,u
        jsr     bcd_to_text
        lda     tmp_cy
        ldb     #-20
        jsr     draw_number
        puls    x
        leax    3,x
        lda     tmp_cy
        suba    #18
        sta     tmp_cy
        dec     tmp_cnt
        bne     db_list
        rts


print_at:
        pshs    a,b,u
        jsr     Reset0Ref
        puls    a,b
        jsr     Moveto_d
        puls    u
        jmp     Print_Str


draw_win:
        lda     #$F8
        sta     Vec_Text_HW
        lda     #$50
        sta     Vec_Text_Width

        lda     #80
        ldb     #-38
        ldu     #txt_win
        jsr     print_at

        ldu     #score
        jsr     bcd_to_text
        lda     #54
        ldb     #-20
        jsr     draw_number

        if      CART
        jsr     cart_want_table
        bne     dw_ship
        endif
        lda     #6
        jsr     draw_best


dw_ship:
        lda     #-30
        sta     tmp_cy
        clr     tmp_cx
        clr     shape_flip
        ldu     #shape_ship1_a
        jsr     draw_shape
        ldu     #shape_ship1_b
        jsr     draw_shape
        ldu     #shape_ship1_c
        jsr     draw_shape
        lda     frame_count+1
        anda    #4
        bne     dw_tall
        ldu     #shape_ship1_fire_a
        bra     dw_fire
dw_tall:
        ldu     #shape_ship1_fire_b
dw_fire:
        jsr     draw_shape

        lda     #-64
        ldb     #-30
        ldu     #txt_press
        jmp     print_at

txt_win:
        fcc     "WELL DONE"
        fcb     $80
txt_win2:
        fcc     "ALL 24 LEVELS"
        fcb     $80
txt_over:
        fcc     "GAME OVER"
        fcb     $80
txt_best:
        fcc     "BEST"
        fcb     $80
txt_press:
        fcc     "PRESS 4"
        fcb     $80


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
dd_loop:
        lda     ,u
        cmpa    #$80
        beq     dd_done
        cmpa    #$81
        beq     dd_skip
        ldb     1,u
        leau    2,u
        jsr     Draw_Line_d
        bra     dd_loop
dd_skip:
        lda     1,u
        ldb     2,u
        leau    3,u
        jsr     Moveto_d
        bra     dd_loop
dd_done:
        rts

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


draw_lives:
        lda     lives
        beq     dv_done
        cmpa    #6
        bls     dv_count
        lda     #6
dv_count:
        sta     tmp_cnt
        jsr     Reset0Ref
        lda     #SCORE_Y-2
        ldb     #LIVES_X
        jsr     Moveto_d
dv_loop:
        ldd     #$0800
        jsr     Draw_Line_d
        ldd     #$F804
        jsr     Moveto_d
        dec     tmp_cnt
        bne     dv_loop
dv_done:
        rts


draw_aliens:
        ldx     #aliens
        lda     #MAX_ALIENS
        sta     tmp_cnt
da_loop:
        ldb     ,x
        beq     da_next
        lda     A_Y,x
        sta     tmp_cy
        lda     A_X,x
        sta     tmp_cx
        decb
        lslb
        pshs    x
        ldx     #shape_ptrs
        abx
        ldu     ,x
        jsr     draw_shape
        puls    x
da_next:
        leax    ALIEN_SZ,x
        dec     tmp_cnt
        bne     da_loop
        rts


draw_shape:
        jsr     Reset0Ref
        jsr     ds_pair
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
        jsr     ds_pair
        jsr     Draw_Line_d
        bra     ds_loop
ds_skip:
        leau    1,u
        jsr     ds_pair
        jsr     Moveto_d
        bra     ds_loop
ds_done:
        rts


ds_pair:
        lda     ,u+
        ldb     ,u+
        tst     shape_flip
        beq     dsp_done
        negb
dsp_done:
        rts

shape_ptrs:
        fdb     shape_meteor, shape_squid,  shape_sphere
        fdb     shape_fighter,    shape_ufo,  shape_cross


shape_meteor:
        fcb      5, -5
        fcb      0, 10
        fcb    -10, -5
        fcb     10, -5
        fcb     $80
shape_squid:
        fcb      5,  0
        fcb     -5,  5
        fcb     -5, -5
        fcb      5, -5
        fcb      5,  5
        fcb     $80
shape_sphere:
        fcb      5, -5
        fcb      0, 10
        fcb    -10,  0
        fcb      0,-10
        fcb     10,  0
        fcb     $80
shape_fighter:
        fcb      4, -5
        fcb     -4, 10
        fcb     -4,-10
        fcb      8,  0
        fcb     $80
shape_ufo:
        fcb      0, -6
        fcb      3,  3
        fcb      0,  6
        fcb     -3,  3
        fcb     -3, -3
        fcb      0, -6
        fcb      3, -3
        fcb     $80
shape_cross:
        fcb      5, -5
        fcb    -10, 10
        fcb     10,  0
        fcb    -10,-10
        fcb     10,  0
        fcb     $80


draw_jetman:
        lda     jet_y
        sta     tmp_cy
        lda     jet_x
        sta     tmp_cx
        clr     shape_flip
        lda     dying
        bne     dj_boom
        lda     jet_flags
        bita    #FACE_LEFT
        beq     dj_draw
        lda     #1
        sta     shape_flip
dj_draw:
        ldu     #shape_jetman
        jsr     draw_shape
        jsr     draw_flames
        clr     shape_flip
        rts


dj_boom:
        cmpa    #13
        bhs     dj_small
        cmpa    #7
        bhs     dj_medium
        ldu     #shape_star_l
        jmp     draw_shape
dj_medium:
        ldu     #shape_star_m
        jmp     draw_shape
dj_small:
        ldu     #shape_star_s
        jmp     draw_shape


draw_flames:
        lda     in_state
        bita    #IN_THRUST
        beq     df_done
        lda     frame_count+1
        anda    #4
        bne     df_tall
        ldu     #shape_flame_a
        jmp     draw_shape
df_tall:
        ldu     #shape_flame_b
        jmp     draw_shape
df_done:
        rts


shape_flame_a:
        fcb     -2, -6
        fcb     -2,  0
        fcb     $81,  2,  1
        fcb     -3,  0
        fcb     $81,  3,  1
        fcb     -2,  0
        fcb     $80
shape_flame_b:
        fcb     -2, -6
        fcb     -3,  0
        fcb     $81,  3,  1
        fcb     -5,  0
        fcb     $81,  5,  1
        fcb     -3,  0
        fcb     $80


shape_star_s:
        fcb     -4,  0
        fcb      8,  0
        fcb     $81, -4, -4
        fcb      0,  8
        fcb     $81, -4, -8
        fcb      8,  8
        fcb     $81, -8,  0
        fcb      8, -8
        fcb     $80
shape_star_m:
        fcb     -7,  0
        fcb     14,  0
        fcb     $81, -7, -7
        fcb      0, 14
        fcb     $81, -7,-14
        fcb     14, 14
        fcb     $81,-14,  0
        fcb     14,-14
        fcb     $80
shape_star_l:
        fcb    -10,  0
        fcb     20,  0
        fcb     $81,-10,-10
        fcb      0, 20
        fcb     $81,-10,-20
        fcb     20, 20
        fcb     $81,-20,  0
        fcb     20,-20
        fcb     $80


shape_jetman:


        fcb      7,   1
        fcb     -1,   1
        fcb     -2,   0
        fcb     -1,  -1
        fcb      0,  -3
        fcb      1,  -2
        fcb      2,   0
        fcb      2,   2
        fcb      0,   2
        fcb     -1,   1


        fcb    $81,  -4,  -4
        fcb      0,  -2
        fcb     -4,  -1
        fcb      0,   3


        fcb    $81,   4,   0
        fcb     -5,   0
        fcb     -2,   2
        fcb     -3,  -1


        fcb    $81,  10,   2
        fcb     -1,   0
        fcb     -1,   1
        fcb      0,   3
        fcb      0,   2
        fcb      0,  -2
        fcb     -1,   0
        fcb      0,  -4
        fcb     -2,   0
        fcb     -2,   1
        fcb     -3,  -1


        fcb    $81,  15,  -2
        fcb     -2,  -1
        fcb     -1,   0
        fcb     -2,   1
        fcb      0,   3
        fcb      1,   0
        fcb      1,  -2
        fcb      1,   0
        fcb      0,   2
        fcb      2,  -1
        fcb      0,  -2


        fcb    $81,  -2,   3
        fcb      0,  -2
        fcb     -1,   0
        fcb     -1,   2
        fcb      1,   1
        fcb      1,   0
        fcb      0,  -1
        fcb     $80

        end     main
