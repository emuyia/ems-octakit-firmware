        .include "abi.inc"
        .equ    GK_TSB_FRAME_SIZE,192
        .equ    GK_TSB_INPUT_D0,44
        .equ    GK_TSB_INPUT_D1,48
        .equ    GK_TSB_INPUT_A0,52
        .equ    GK_TSB_INPUT_A1,56
        .equ    GK_TSB_INPUT_SR,60
        .equ    GK_TSB_OUTPUT_D0,64
        .equ    GK_TSB_OUTPUT_D1,68
        .equ    GK_TSB_OUTPUT_A0,72
        .equ    GK_TSB_OUTPUT_A1,76
        .equ    GK_TSB_OUTPUT_SR,80
        .equ    GK_TSB_ARGUMENT,84
        .equ    GK_TSB_DELTA,88
        .equ    GK_TSB_FAMILY,92
        .equ    GK_TSB_FAMILY_INVERSE,96
        .equ    GK_TSB_BANK,100
        .equ    GK_TSB_PATTERN,104
        .equ    GK_TSB_KIT,108
        .equ    GK_TSB_PART,112
        .equ    GK_TSB_TRACK,116
        .equ    GK_TSB_DESCRIPTOR,120
        .equ    GK_TSB_PAYLOAD,124
        .equ    GK_TSB_BANK_POINTER,128
        .equ    GK_TSB_SELECTOR,132
        .equ    GK_TSB_SELECTOR_INVERSE,136
        .equ    GK_TSB_MARKER_COUNT,140
        .equ    GK_TSB_TOKEN,144
        .equ    GK_TSB_TOKEN_INVERSE,148
        .equ    GK_TSB_MAGIC,152
        .equ    GK_TSB_MAGIC_INVERSE,156
        .equ    GK_TSB_OLD_BANK_EDITED,160
        .equ    GK_TSB_OLD_MIRROR_EDITED,164
        .equ    GK_TSB_OLD_PROJECT_DIRTY,168
        .equ    GK_TSB_NEW_VALUE,172
        .equ    GK_TSB_STOCK_RETURN,176
        .equ    GK_TSB_ACTIVE,180
        .equ    GK_TSB_MAGIC_VALUE,0x5354464d
        .equ    GK_TSBM_SAVED_BYTES,64
        .equ    GK_TSBM_D0,0
        .equ    GK_TSBM_D1,4
        .equ    GK_TSBM_D2,8
        .equ    GK_TSBM_D3,12
        .equ    GK_TSBM_D4,16
        .equ    GK_TSBM_D5,20
        .equ    GK_TSBM_A2,40
        .equ    GK_TSBM_A3,44
        .equ    GK_TSBM_A6,56
        .equ    GK_TSBM_SR,60
        .equ    GK_TSBM_RETURN,64
        .section .runtime,"ax"
        .align  4
        .global gk_track_setup_byte_fatal
gk_track_setup_byte_fatal:
        illegal
        bra.s   gk_track_setup_byte_fatal
        .type   gk_track_setup_byte_abort_fatal,@function
gk_track_setup_byte_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_track_setup_byte_fatal
        bra.w   gk_track_setup_byte_fatal
        .size   gk_track_setup_byte_abort_fatal,.-gk_track_setup_byte_abort_fatal
        .type   gk_track_setup_byte_release_d0_abort_fatal,@function
gk_track_setup_byte_release_d0_abort_fatal:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_track_setup_byte_abort_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_setup_byte_fatal
        bra.w   gk_track_setup_byte_abort_fatal
        .size   gk_track_setup_byte_release_d0_abort_fatal,.-gk_track_setup_byte_release_d0_abort_fatal
        .type   gk_track_setup_byte_release_abort_fatal,@function
gk_track_setup_byte_release_abort_fatal:
        move.l  GK_TSB_DESCRIPTOR(%a6),%d0
        bra.w   gk_track_setup_byte_release_d0_abort_fatal
        .size   gk_track_setup_byte_release_abort_fatal,.-gk_track_setup_byte_release_abort_fatal
        .type   gk_track_setup_byte_release_fatal,@function
gk_track_setup_byte_release_fatal:
        move.l  GK_TSB_DESCRIPTOR(%a6),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_track_setup_byte_fatal
        jsr     gk_descriptor_release
        bra.w   gk_track_setup_byte_fatal
        .size   gk_track_setup_byte_release_fatal,.-gk_track_setup_byte_release_fatal
        .type   gk_track_setup_byte_context_token,@function
gk_track_setup_byte_context_token:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_tsb_token_corrupt
        cmpi.l  #15,%d1
        bhi.s   .Lgk_tsb_token_corrupt
        cmpi.l  #3,%d2
        bhi.s   .Lgk_tsb_token_corrupt
        cmpi.l  #7,%d3
        bhi.s   .Lgk_tsb_token_corrupt
        lsl.l   #7,%d3
        or.l    %d3,%d0
        lsl.l   #8,%d2
        lsl.l   #2,%d2
        or.l    %d2,%d0
        lsl.l   #8,%d1
        lsl.l   #4,%d1
        or.l    %d1,%d0
        ori.l   #GK_TRACK_SETUP_TOKEN_ARMED,%d0
        rts
.Lgk_tsb_token_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_track_setup_byte_context_token,.-gk_track_setup_byte_context_token
        .type   gk_track_setup_byte_read_selector,@function
gk_track_setup_byte_read_selector:
        move.l  GK_TSB_FAMILY(%a6),%d2
        cmpi.l  #GK_TRACK_SETUP_AMP,%d2
        beq.w   .Lgk_tsb_selector_amp
        movea.l GK_TSB_PAYLOAD(%a6),%a0
        move.l  GK_TSB_TRACK(%a6),%d3
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d2
        beq.s   .Lgk_tsb_selector_playback
        cmpi.l  #GK_TRACK_SETUP_EFFECT2,%d2
        beq.s   .Lgk_tsb_selector_effect2
        cmpi.l  #GK_TRACK_SETUP_EFFECT1,%d2
        bne.w   .Lgk_tsb_selector_corrupt
        adda.l  #GK_STOCK_EFFECT1_MACHINE_OFFSET,%a0
        bra.s   .Lgk_tsb_selector_payload
.Lgk_tsb_selector_effect2:
        adda.l  #GK_STOCK_EFFECT2_MACHINE_OFFSET,%a0
        bra.s   .Lgk_tsb_selector_payload
.Lgk_tsb_selector_playback:
        adda.l  #GK_STOCK_PLAYBACK_MACHINE_OFFSET,%a0
.Lgk_tsb_selector_payload:
        adda.l  %d3,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  GK_TSB_PART(%a6),%d1
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d1
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a1
        adda.l  %d1,%a1
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d2
        beq.s   .Lgk_tsb_selector_mirror_playback
        cmpi.l  #GK_TRACK_SETUP_EFFECT2,%d2
        beq.s   .Lgk_tsb_selector_mirror_effect2
        adda.l  #GK_STOCK_EFFECT1_MACHINE_OFFSET,%a1
        bra.s   .Lgk_tsb_selector_mirror_ready
.Lgk_tsb_selector_mirror_effect2:
        adda.l  #GK_STOCK_EFFECT2_MACHINE_OFFSET,%a1
        bra.s   .Lgk_tsb_selector_mirror_ready
.Lgk_tsb_selector_mirror_playback:
        adda.l  #GK_STOCK_PLAYBACK_MACHINE_OFFSET,%a1
.Lgk_tsb_selector_mirror_ready:
        adda.l  %d3,%a1
        moveq   #0,%d1
        move.b  (%a1),%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_tsb_selector_corrupt
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d2
        bne.s   .Lgk_tsb_selector_fx_range
        cmpi.l  #4,%d0
        bhi.s   .Lgk_tsb_selector_corrupt
        cmp.l   GK_STOCK_PLAYBACK_SETUP_MODE,%d0
        bne.s   .Lgk_tsb_selector_corrupt
        rts
.Lgk_tsb_selector_fx_range:
        cmpi.l  #31,%d0
        bhi.s   .Lgk_tsb_selector_corrupt
        rts
.Lgk_tsb_selector_amp:
        moveq   #0,%d0
        rts
.Lgk_tsb_selector_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_track_setup_byte_read_selector,.-gk_track_setup_byte_read_selector
        .type   gk_track_setup_byte_validate_selector,@function
gk_track_setup_byte_validate_selector:
        bsr.w   gk_track_setup_byte_read_selector
        tst.l   %d0
        bmi.s   .Lgk_tsb_validate_selector_corrupt
        cmp.l   GK_TSB_SELECTOR(%a6),%d0
        bne.s   .Lgk_tsb_validate_selector_corrupt
        not.l   %d0
        cmp.l   GK_TSB_SELECTOR_INVERSE(%a6),%d0
        bne.s   .Lgk_tsb_validate_selector_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_tsb_validate_selector_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_track_setup_byte_validate_selector,.-gk_track_setup_byte_validate_selector
        .type   gk_track_setup_byte_pointers,@function
gk_track_setup_byte_pointers:
        move.l  GK_TSB_TRACK(%a6),%d0
        move.l  %d0,%d1
        lsl.l   #5,%d1
        add.l   %d0,%d0
        sub.l   %d0,%d1
        add.l   GK_TSB_ARGUMENT(%a6),%d1
        move.l  GK_TSB_FAMILY(%a6),%d2
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d2
        bne.s   .Lgk_tsb_pointer_not_playback
        move.l  GK_TSB_SELECTOR(%a6),%d0
        move.l  %d0,%d3
        lsl.l   #3,%d0
        add.l   %d3,%d3
        sub.l   %d3,%d0
        add.l   %d0,%d1
        move.l  #GK_STOCK_PLAYBACK_SETUP_PAYLOAD_OFFSET,%d3
        bra.s   .Lgk_tsb_pointer_offset_ready
.Lgk_tsb_pointer_not_playback:
        cmpi.l  #GK_TRACK_SETUP_EFFECT2,%d2
        bne.s   .Lgk_tsb_pointer_not_effect2
        move.l  #GK_STOCK_EFFECT2_SETUP_PAYLOAD_OFFSET,%d3
        bra.s   .Lgk_tsb_pointer_offset_ready
.Lgk_tsb_pointer_not_effect2:
        cmpi.l  #GK_TRACK_SETUP_EFFECT1,%d2
        bne.s   .Lgk_tsb_pointer_amp
        move.l  #GK_STOCK_EFFECT1_SETUP_PAYLOAD_OFFSET,%d3
        bra.s   .Lgk_tsb_pointer_offset_ready
.Lgk_tsb_pointer_amp:
        move.l  #GK_STOCK_AMP_SETUP_PAYLOAD_OFFSET,%d3
.Lgk_tsb_pointer_offset_ready:
        movea.l GK_TSB_PAYLOAD(%a6),%a0
        adda.l  %d3,%a0
        adda.l  %d1,%a0
        move.l  GK_TSB_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a1
        adda.l  %d0,%a1
        adda.l  %d3,%a1
        adda.l  %d1,%a1
        rts
        .size   gk_track_setup_byte_pointers,.-gk_track_setup_byte_pointers
        .type   gk_track_setup_byte_ui_pointer,@function
gk_track_setup_byte_ui_pointer:
        move.l  GK_TSB_TRACK(%a6),%d0
        move.l  %d0,%d1
        lsl.l   #6,%d0
        lsl.l   #3,%d1
        add.l   %d1,%d0
        add.l   GK_TSB_ARGUMENT(%a6),%d0
        move.l  GK_TSB_FAMILY(%a6),%d1
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d1
        bne.s   .Lgk_tsb_ui_not_playback
        lea     GK_STOCK_PLAYBACK_SETUP_UI_CACHE,%a0
        bra.s   .Lgk_tsb_ui_ready
.Lgk_tsb_ui_not_playback:
        cmpi.l  #GK_TRACK_SETUP_EFFECT2,%d1
        bne.s   .Lgk_tsb_ui_not_effect2
        lea     GK_STOCK_EFFECT2_SETUP_UI_CACHE,%a0
        bra.s   .Lgk_tsb_ui_ready
.Lgk_tsb_ui_not_effect2:
        cmpi.l  #GK_TRACK_SETUP_EFFECT1,%d1
        bne.s   .Lgk_tsb_ui_amp
        lea     GK_STOCK_EFFECT1_SETUP_UI_CACHE,%a0
        bra.s   .Lgk_tsb_ui_ready
.Lgk_tsb_ui_amp:
        lea     GK_STOCK_AMP_SETUP_UI_CACHE,%a0
.Lgk_tsb_ui_ready:
        adda.l  %d0,%a0
        rts
        .size   gk_track_setup_byte_ui_pointer,.-gk_track_setup_byte_ui_pointer
        .type   gk_track_setup_byte_event_pointer,@function
gk_track_setup_byte_event_pointer:
        move.l  GK_TSB_ARGUMENT(%a6),%d0
        move.l  %d0,%d1
        lsl.l   #2,%d0
        add.l   %d1,%d0
        addq.l  #1,%d0
        lsl.l   #2,%d0
        lea     GK_STOCK_RELATIVE_EVENT_STATE,%a0
        adda.l  %d0,%a0
        rts
        .size   gk_track_setup_byte_event_pointer,.-gk_track_setup_byte_event_pointer
        .type   gk_track_setup_byte_tail_expected,@function
gk_track_setup_byte_tail_expected:
        move.l  GK_TSB_FAMILY(%a6),%d0
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d0
        bne.s   .Lgk_tsb_tail_not_playback
        move.l  #GK_STOCK_PLAYBACK_SETUP_TAIL,%d0
        rts
.Lgk_tsb_tail_not_playback:
        cmpi.l  #GK_TRACK_SETUP_EFFECT2,%d0
        bne.s   .Lgk_tsb_tail_not_effect2
        move.l  #GK_STOCK_EFFECT2_SETUP_TAIL,%d0
        rts
.Lgk_tsb_tail_not_effect2:
        cmpi.l  #GK_TRACK_SETUP_EFFECT1,%d0
        bne.s   .Lgk_tsb_tail_amp
        move.l  #GK_STOCK_EFFECT1_SETUP_TAIL,%d0
        rts
.Lgk_tsb_tail_amp:
        move.l  #GK_STOCK_AMP_SETUP_TAIL,%d0
        rts
        .size   gk_track_setup_byte_tail_expected,.-gk_track_setup_byte_tail_expected
        .type   gk_track_setup_byte_validate_current,@function
gk_track_setup_byte_validate_current:
        move.l  GK_TSB_MAGIC(%a6),%d0
        cmpi.l  #GK_TSB_MAGIC_VALUE,%d0
        bne.w   .Lgk_tsb_current_corrupt
        not.l   %d0
        cmp.l   GK_TSB_MAGIC_INVERSE(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  GK_TSB_FAMILY(%a6),%d0
        cmpi.l  #GK_TRACK_SETUP_AMP,%d0
        bhi.w   .Lgk_tsb_current_corrupt
        not.l   %d0
        cmp.l   GK_TSB_FAMILY_INVERSE(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  GK_TSB_ACTIVE(%a6),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  GK_TSB_ARGUMENT(%a6),%d0
        cmpi.l  #5,%d0
        bhi.w   .Lgk_tsb_current_corrupt
        bsr.w   gk_track_setup_byte_validate_selector
        tst.l   %d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  GK_TSB_DESCRIPTOR(%a6),%d0
        move.l  GK_TSB_BANK(%a6),%d1
        move.l  GK_TSB_PART(%a6),%d2
        move.l  GK_TSB_TRACK(%a6),%d3
        bsr.w   gk_track_setup_byte_context_token
        tst.l   %d0
        bmi.w   .Lgk_tsb_current_corrupt
        andi.l  #GK_TRACK_SETUP_TOKEN_CONTEXT_MASK,%d0
        move.l  GK_TSB_TOKEN(%a6),%d1
        move.l  %d1,%d2
        andi.l  #GK_TRACK_SETUP_TOKEN_CONTEXT_MASK,%d2
        cmp.l   %d2,%d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  %d1,%d0
        andi.l  #GK_TRACK_SETUP_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_TRACK_SETUP_TOKEN_ARMED,%d0
        beq.s   .Lgk_tsb_current_token_ok
        cmpi.l  #GK_TRACK_SETUP_TOKEN_WRITTEN,%d0
        bne.w   .Lgk_tsb_current_corrupt
.Lgk_tsb_current_token_ok:
        not.l   %d1
        cmp.l   GK_TSB_TOKEN_INVERSE(%a6),%d1
        bne.w   .Lgk_tsb_current_corrupt
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   GK_TSB_DESCRIPTOR(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   GK_TSB_BANK(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   GK_TSB_PATTERN(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   GK_TSB_KIT(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   GK_TSB_BANK(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   GK_TSB_BANK(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   GK_TSB_BANK(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   GK_TSB_PATTERN(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   GK_TSB_PATTERN(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   GK_TSB_PART(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   GK_TSB_PART(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   GK_TSB_PART(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmp.l   GK_TSB_TRACK(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d0
        cmp.l   GK_TSB_TRACK(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  GK_STOCK_BANK_POINTER,%d0
        cmp.l   GK_TSB_BANK_POINTER(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  GK_TSB_BANK(%a6),%d0
        lsl.l   #2,%d0
        add.l   GK_TSB_PART(%a6),%d0
        jsr     gk_physical_validate
        cmp.l   GK_TSB_DESCRIPTOR(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  %a0,%d0
        cmp.l   GK_TSB_PAYLOAD(%a6),%d0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  GK_TSB_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        movea.l GK_TSB_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        adda.l  %d0,%a0
        cmpa.l  GK_TSB_PAYLOAD(%a6),%a0
        bne.w   .Lgk_tsb_current_corrupt
        move.l  GK_TSB_MARKER_COUNT(%a6),%d0
        cmpi.l  #1,%d0
        bhi.s   .Lgk_tsb_current_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_tsb_current_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_track_setup_byte_validate_current,.-gk_track_setup_byte_validate_current
        .type   gk_track_setup_byte_prepare,@function
gk_track_setup_byte_prepare:
        move.l  GK_TSB_FAMILY(%a6),%d0
        cmpi.l  #GK_TRACK_SETUP_AMP,%d0
        bhi.w   gk_track_setup_byte_fatal
        move.l  GK_TSB_ARGUMENT(%a6),%d0
        cmpi.l  #5,%d0
        bhi.w   gk_track_setup_byte_fatal
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_tsb_prepare_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_tsb_prepare_busy
        bra.w   gk_track_setup_byte_fatal
.Lgk_tsb_prepare_lifecycle_active:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_track_setup_byte_fatal
        move.l  %d0,GK_TSB_PART(%a6)
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   gk_track_setup_byte_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_track_setup_byte_fatal
        move.l  %d0,GK_TSB_TRACK(%a6)
        moveq   #0,%d1
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d1
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_tsb_prepare_busy
        tst.l   %d0
        bmi.w   gk_track_setup_byte_fatal
        moveq   #0,%d2
        move.b  GK_STOCK_ENGINE_PART,%d2
        cmp.l   GK_TSB_PART(%a6),%d2
        bne.w   gk_track_setup_byte_fatal
        moveq   #0,%d2
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d2
        cmp.l   GK_TSB_TRACK(%a6),%d2
        bne.w   gk_track_setup_byte_fatal
        move.l  %d0,GK_TSB_BANK(%a6)
        move.l  %d1,GK_TSB_PATTERN(%a6)
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_track_setup_byte_fatal
        move.l  %d0,GK_TSB_DESCRIPTOR(%a6)
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        move.l  %d0,GK_TSB_KIT(%a6)
        move.l  GK_STOCK_BANK_POINTER,%d0
        move.l  %d0,GK_TSB_BANK_POINTER(%a6)
        move.l  GK_TSB_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        movea.l GK_TSB_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %a0,GK_TSB_PAYLOAD(%a6)
        bsr.w   gk_track_setup_byte_read_selector
        tst.l   %d0
        bmi.w   gk_track_setup_byte_fatal
        move.l  %d0,GK_TSB_SELECTOR(%a6)
        not.l   %d0
        move.l  %d0,GK_TSB_SELECTOR_INVERSE(%a6)
        move.l  GK_TSB_BANK(%a6),%d0
        move.l  GK_TSB_PATTERN(%a6),%d1
        move.l  GK_TSB_KIT(%a6),%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_tsb_prepare_busy
        tst.l   %d0
        bmi.w   gk_track_setup_byte_fatal
        cmp.l   GK_TSB_DESCRIPTOR(%a6),%d0
        bne.w   gk_track_setup_byte_abort_fatal
        cmp.l   GK_TSB_PART(%a6),%d1
        bne.w   gk_track_setup_byte_abort_fatal
        cmpa.l  GK_TSB_PAYLOAD(%a6),%a0
        bne.w   gk_track_setup_byte_abort_fatal
        move.l  GK_TSB_BANK(%a6),%d0
        move.l  GK_TSB_PART(%a6),%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_track_setup_byte_abort_fatal
        cmp.l   GK_TSB_DESCRIPTOR(%a6),%d0
        bne.w   gk_track_setup_byte_release_d0_abort_fatal
        cmpa.l  GK_TSB_PAYLOAD(%a6),%a0
        bne.w   gk_track_setup_byte_release_abort_fatal
        clr.l   GK_TSB_MARKER_COUNT(%a6)
        move.l  GK_TSB_DESCRIPTOR(%a6),%d0
        move.l  GK_TSB_BANK(%a6),%d1
        move.l  GK_TSB_PART(%a6),%d2
        move.l  GK_TSB_TRACK(%a6),%d3
        bsr.w   gk_track_setup_byte_context_token
        tst.l   %d0
        bmi.w   gk_track_setup_byte_release_abort_fatal
        move.l  %d0,GK_TSB_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_TSB_TOKEN_INVERSE(%a6)
        move.l  #GK_TSB_MAGIC_VALUE,%d0
        move.l  %d0,GK_TSB_MAGIC(%a6)
        not.l   %d0
        move.l  %d0,GK_TSB_MAGIC_INVERSE(%a6)
        movea.l GK_TSB_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  %d0,GK_TSB_OLD_BANK_EDITED(%a6)
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        move.l  %d0,GK_TSB_OLD_MIRROR_EDITED(%a6)
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        move.l  %d0,GK_TSB_OLD_PROJECT_DIRTY(%a6)
        moveq   #1,%d0
        move.l  %d0,GK_TSB_ACTIVE(%a6)
        moveq   #GK_OK,%d0
        rts
.Lgk_tsb_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_track_setup_byte_prepare,.-gk_track_setup_byte_prepare
        .type   gk_track_setup_byte_validate_result,@function
gk_track_setup_byte_validate_result:
        move.l  GK_TSB_MARKER_COUNT(%a6),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_tsb_result_corrupt
        move.l  GK_TSB_TOKEN(%a6),%d0
        andi.l  #GK_TRACK_SETUP_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_TRACK_SETUP_TOKEN_WRITTEN,%d0
        bne.w   .Lgk_tsb_result_corrupt
        bsr.w   gk_track_setup_byte_pointers
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   GK_TSB_NEW_VALUE(%a6),%d0
        bne.w   .Lgk_tsb_result_corrupt
        moveq   #0,%d0
        move.b  (%a1),%d0
        cmp.l   GK_TSB_NEW_VALUE(%a6),%d0
        bne.w   .Lgk_tsb_result_corrupt
        bsr.w   gk_track_setup_byte_ui_pointer
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   GK_TSB_NEW_VALUE(%a6),%d0
        bne.w   .Lgk_tsb_result_corrupt
        bsr.w   gk_track_setup_byte_event_pointer
        move.l  (%a0),%d0
        cmpi.l  #20,%d0
        bne.w   .Lgk_tsb_result_corrupt
        moveq   #1,%d1
        move.l  GK_TSB_PART(%a6),%d0
        lsl.l   %d0,%d1
        or.l    GK_TSB_OLD_BANK_EDITED(%a6),%d1
        movea.l GK_TSB_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   %d1,%d0
        bne.s   .Lgk_tsb_result_corrupt
        moveq   #1,%d1
        move.l  GK_TSB_PART(%a6),%d0
        lsl.l   %d0,%d1
        or.l    GK_TSB_OLD_MIRROR_EDITED(%a6),%d1
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        cmp.l   %d1,%d0
        bne.s   .Lgk_tsb_result_corrupt
        movea.l GK_TSB_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_tsb_result_corrupt
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_tsb_result_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_tsb_result_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_track_setup_byte_validate_result,.-gk_track_setup_byte_validate_result
        .type   gk_track_setup_byte_return_stock,@function
gk_track_setup_byte_return_stock:
        bsr.w   gk_track_setup_byte_tail_expected
        cmp.l   GK_TSB_OUTPUT_A1(%a6),%d0
        bne.w   gk_track_setup_byte_fatal
        move.l  GK_TSB_OUTPUT_D0(%a6),%d0
        move.l  GK_TSB_OUTPUT_D1(%a6),%d1
        movea.l GK_TSB_OUTPUT_A0(%a6),%a0
        movea.l GK_TSB_OUTPUT_A1(%a6),%a1
        moveq   #0,%d2
        move.w  GK_TSB_OUTPUT_SR(%a6),%d2
        move.w  %d2,%sr
        movem.l (%a6),%d2-%d7/%a2-%a6
        lea     GK_TSB_FRAME_SIZE(%sp),%sp
        jmp     (%a1)
        .size   gk_track_setup_byte_return_stock,.-gk_track_setup_byte_return_stock
        .type   gk_track_setup_byte_finish,@function
gk_track_setup_byte_finish:
        moveq   #0,%d0
        move.w  %sr,%d0
        andi.l  #0x0700,%d0
        cmpi.l  #0x0200,%d0
        bhs.s   .Lgk_tsb_finish_guarded
        move.w  #0x2200,%sr
.Lgk_tsb_finish_guarded:
        bsr.w   gk_track_setup_byte_validate_current
        tst.l   %d0
        bne.w   gk_track_setup_byte_release_abort_fatal
        bsr.w   gk_track_setup_byte_validate_result
        tst.l   %d0
        bne.w   gk_track_setup_byte_release_abort_fatal
        move.l  GK_TSB_DESCRIPTOR(%a6),%d0
        move.l  GK_TSB_BANK(%a6),%d1
        move.l  GK_TSB_PATTERN(%a6),%d2
        move.l  GK_TSB_PART(%a6),%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_track_setup_byte_release_abort_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_track_setup_byte_release_abort_fatal
        bsr.w   gk_track_setup_byte_validate_current
        tst.l   %d0
        bne.w   gk_track_setup_byte_release_fatal
        move.l  GK_TSB_DESCRIPTOR(%a6),%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_setup_byte_fatal
        clr.l   GK_TSB_ACTIVE(%a6)
        bra.w   gk_track_setup_byte_return_stock
        .size   gk_track_setup_byte_finish,.-gk_track_setup_byte_finish
        .type   gk_track_setup_byte_no_write_finish,@function
gk_track_setup_byte_no_write_finish:
        tst.l   GK_TSB_ACTIVE(%a6)
        bne.w   gk_track_setup_byte_fatal
        tst.l   GK_TSB_MARKER_COUNT(%a6)
        bne.w   gk_track_setup_byte_fatal
        move.l  GK_TSB_ARGUMENT(%a6),%d0
        cmpi.l  #6,%d0
        bne.w   gk_track_setup_byte_fatal
        move.l  GK_TSB_FAMILY(%a6),%d0
        cmpi.l  #GK_TRACK_SETUP_AMP,%d0
        bhs.w   gk_track_setup_byte_fatal
        bra.w   gk_track_setup_byte_return_stock
        .size   gk_track_setup_byte_no_write_finish,.-gk_track_setup_byte_no_write_finish
        .global gk_stock_playback_setup_editor
        .type gk_stock_playback_setup_editor,@function
gk_stock_playback_setup_editor:
        lea -GK_TSB_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l %d0,GK_TSB_INPUT_D0(%a6)
        move.l %d1,GK_TSB_INPUT_D1(%a6)
        move.l %a0,GK_TSB_INPUT_A0(%a6)
        move.l %a1,GK_TSB_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_TSB_INPUT_SR(%a6)
        move.l GK_TSB_FRAME_SIZE+4(%a6),%d0
        move.l %d0,GK_TSB_ARGUMENT(%a6)
        move.l GK_TSB_FRAME_SIZE+8(%a6),%d0
        move.l %d0,GK_TSB_DELTA(%a6)
        moveq #GK_TRACK_SETUP_PLAYBACK,%d0
        move.l %d0,GK_TSB_FAMILY(%a6)
        not.l %d0
        move.l %d0,GK_TSB_FAMILY_INVERSE(%a6)
        clr.l GK_TSB_ACTIVE(%a6)
        clr.l GK_TSB_MARKER_COUNT(%a6)
        bra.w gk_track_setup_byte_dispatch
        .size gk_stock_playback_setup_editor,.-gk_stock_playback_setup_editor
        .global gk_stock_effect2_setup_editor
        .type gk_stock_effect2_setup_editor,@function
gk_stock_effect2_setup_editor:
        lea -GK_TSB_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l %d0,GK_TSB_INPUT_D0(%a6)
        move.l %d1,GK_TSB_INPUT_D1(%a6)
        move.l %a0,GK_TSB_INPUT_A0(%a6)
        move.l %a1,GK_TSB_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_TSB_INPUT_SR(%a6)
        move.l GK_TSB_FRAME_SIZE+4(%a6),%d0
        move.l %d0,GK_TSB_ARGUMENT(%a6)
        move.l GK_TSB_FRAME_SIZE+8(%a6),%d0
        move.l %d0,GK_TSB_DELTA(%a6)
        moveq #GK_TRACK_SETUP_EFFECT2,%d0
        move.l %d0,GK_TSB_FAMILY(%a6)
        not.l %d0
        move.l %d0,GK_TSB_FAMILY_INVERSE(%a6)
        clr.l GK_TSB_ACTIVE(%a6)
        clr.l GK_TSB_MARKER_COUNT(%a6)
        bra.w gk_track_setup_byte_dispatch
        .size gk_stock_effect2_setup_editor,.-gk_stock_effect2_setup_editor
        .global gk_stock_effect1_setup_editor
        .type gk_stock_effect1_setup_editor,@function
gk_stock_effect1_setup_editor:
        lea -GK_TSB_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l %d0,GK_TSB_INPUT_D0(%a6)
        move.l %d1,GK_TSB_INPUT_D1(%a6)
        move.l %a0,GK_TSB_INPUT_A0(%a6)
        move.l %a1,GK_TSB_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_TSB_INPUT_SR(%a6)
        move.l GK_TSB_FRAME_SIZE+4(%a6),%d0
        move.l %d0,GK_TSB_ARGUMENT(%a6)
        move.l GK_TSB_FRAME_SIZE+8(%a6),%d0
        move.l %d0,GK_TSB_DELTA(%a6)
        moveq #GK_TRACK_SETUP_EFFECT1,%d0
        move.l %d0,GK_TSB_FAMILY(%a6)
        not.l %d0
        move.l %d0,GK_TSB_FAMILY_INVERSE(%a6)
        clr.l GK_TSB_ACTIVE(%a6)
        clr.l GK_TSB_MARKER_COUNT(%a6)
        bra.w gk_track_setup_byte_dispatch
        .size gk_stock_effect1_setup_editor,.-gk_stock_effect1_setup_editor
        .global gk_stock_amp_setup_editor
        .type gk_stock_amp_setup_editor,@function
gk_stock_amp_setup_editor:
        lea -GK_TSB_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l %d0,GK_TSB_INPUT_D0(%a6)
        move.l %d1,GK_TSB_INPUT_D1(%a6)
        move.l %a0,GK_TSB_INPUT_A0(%a6)
        move.l %a1,GK_TSB_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_TSB_INPUT_SR(%a6)
        move.l GK_TSB_FRAME_SIZE+4(%a6),%d0
        move.l %d0,GK_TSB_ARGUMENT(%a6)
        move.l GK_TSB_FRAME_SIZE+8(%a6),%d0
        move.l %d0,GK_TSB_DELTA(%a6)
        moveq #GK_TRACK_SETUP_AMP,%d0
        move.l %d0,GK_TSB_FAMILY(%a6)
        not.l %d0
        move.l %d0,GK_TSB_FAMILY_INVERSE(%a6)
        clr.l GK_TSB_ACTIVE(%a6)
        clr.l GK_TSB_MARKER_COUNT(%a6)
        bra.w gk_track_setup_byte_dispatch
        .size gk_stock_amp_setup_editor,.-gk_stock_amp_setup_editor
        .type   gk_track_setup_byte_dispatch,@function
gk_track_setup_byte_dispatch:
        move.l  GK_TSB_FAMILY(%a6),%d0
        cmpi.l  #GK_TRACK_SETUP_AMP,%d0
        bhi.w   gk_track_setup_byte_fatal
        move.l  GK_TSB_ARGUMENT(%a6),%d0
        cmpi.l  #5,%d0
        bls.s   .Lgk_tsb_dispatch_write
        cmpi.l  #6,%d0
        bne.w   gk_track_setup_byte_fatal
        move.l  GK_TSB_FAMILY(%a6),%d0
        cmpi.l  #GK_TRACK_SETUP_AMP,%d0
        bhs.w   gk_track_setup_byte_fatal
        bra.s   .Lgk_tsb_dispatch_stock
.Lgk_tsb_dispatch_write:
        bsr.w   gk_track_setup_byte_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   gk_track_setup_byte_busy_return
        tst.l   %d0
        bne.w   gk_track_setup_byte_fatal
.Lgk_tsb_dispatch_stock:
        move.l  GK_TSB_FAMILY(%a6),%d0
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d0
        beq.w   .Lgk_tsb_call_playback
        cmpi.l  #GK_TRACK_SETUP_EFFECT2,%d0
        beq.w   .Lgk_tsb_call_effect2
        cmpi.l  #GK_TRACK_SETUP_EFFECT1,%d0
        beq.w   .Lgk_tsb_call_effect1
        bra.w   .Lgk_tsb_call_amp
        .size   gk_track_setup_byte_dispatch,.-gk_track_setup_byte_dispatch
        .type   gk_track_setup_byte_busy_return,@function
gk_track_setup_byte_busy_return:
        move.l  GK_TSB_INPUT_D0(%a6),%d0
        move.l  GK_TSB_INPUT_D1(%a6),%d1
        movea.l GK_TSB_INPUT_A0(%a6),%a0
        movea.l GK_TSB_INPUT_A1(%a6),%a1
        moveq   #0,%d2
        move.w  GK_TSB_INPUT_SR(%a6),%d2
        move.w  %d2,%sr
        movem.l (%a6),%d2-%d7/%a2-%a6
        lea     GK_TSB_FRAME_SIZE(%sp),%sp
        rts
        .size   gk_track_setup_byte_busy_return,.-gk_track_setup_byte_busy_return
.Lgk_tsb_call_playback:
        move.l GK_TSB_DELTA(%a6),-(%sp)
        move.l GK_TSB_ARGUMENT(%a6),-(%sp)
        lea .Lgk_tsb_after_playback,%a0
        move.l %a0,GK_TSB_STOCK_RETURN(%a6)
        move.l GK_TSB_INPUT_D0(%a6),%d0
        move.l GK_TSB_INPUT_D1(%a6),%d1
        movea.l GK_TSB_INPUT_A0(%a6),%a0
        movea.l GK_TSB_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_TSB_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        jsr gk_track_setup_playback_trampoline
.Lgk_tsb_after_playback:
        lea 8(%sp),%sp
        move.w %sr,%d2
        move.w %d2,GK_TSB_OUTPUT_SR(%a6)
        move.l %d0,GK_TSB_OUTPUT_D0(%a6)
        move.l %d1,GK_TSB_OUTPUT_D1(%a6)
        move.l %a0,GK_TSB_OUTPUT_A0(%a6)
        move.l %a1,GK_TSB_OUTPUT_A1(%a6)
        tst.l GK_TSB_ACTIVE(%a6)
        beq.w gk_track_setup_byte_no_write_finish
        jmp gk_track_setup_byte_finish
.Lgk_tsb_call_effect2:
        move.l GK_TSB_DELTA(%a6),-(%sp)
        move.l GK_TSB_ARGUMENT(%a6),-(%sp)
        lea .Lgk_tsb_after_effect2,%a0
        move.l %a0,GK_TSB_STOCK_RETURN(%a6)
        move.l GK_TSB_INPUT_D0(%a6),%d0
        move.l GK_TSB_INPUT_D1(%a6),%d1
        movea.l GK_TSB_INPUT_A0(%a6),%a0
        movea.l GK_TSB_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_TSB_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        jsr gk_track_setup_effect2_trampoline
.Lgk_tsb_after_effect2:
        lea 8(%sp),%sp
        move.w %sr,%d2
        move.w %d2,GK_TSB_OUTPUT_SR(%a6)
        move.l %d0,GK_TSB_OUTPUT_D0(%a6)
        move.l %d1,GK_TSB_OUTPUT_D1(%a6)
        move.l %a0,GK_TSB_OUTPUT_A0(%a6)
        move.l %a1,GK_TSB_OUTPUT_A1(%a6)
        tst.l GK_TSB_ACTIVE(%a6)
        beq.w gk_track_setup_byte_no_write_finish
        jmp gk_track_setup_byte_finish
.Lgk_tsb_call_effect1:
        move.l GK_TSB_DELTA(%a6),-(%sp)
        move.l GK_TSB_ARGUMENT(%a6),-(%sp)
        lea .Lgk_tsb_after_effect1,%a0
        move.l %a0,GK_TSB_STOCK_RETURN(%a6)
        move.l GK_TSB_INPUT_D0(%a6),%d0
        move.l GK_TSB_INPUT_D1(%a6),%d1
        movea.l GK_TSB_INPUT_A0(%a6),%a0
        movea.l GK_TSB_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_TSB_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        jsr gk_track_setup_effect1_trampoline
.Lgk_tsb_after_effect1:
        lea 8(%sp),%sp
        move.w %sr,%d2
        move.w %d2,GK_TSB_OUTPUT_SR(%a6)
        move.l %d0,GK_TSB_OUTPUT_D0(%a6)
        move.l %d1,GK_TSB_OUTPUT_D1(%a6)
        move.l %a0,GK_TSB_OUTPUT_A0(%a6)
        move.l %a1,GK_TSB_OUTPUT_A1(%a6)
        tst.l GK_TSB_ACTIVE(%a6)
        beq.w gk_track_setup_byte_no_write_finish
        jmp gk_track_setup_byte_finish
.Lgk_tsb_call_amp:
        move.l GK_TSB_DELTA(%a6),-(%sp)
        move.l GK_TSB_ARGUMENT(%a6),-(%sp)
        lea .Lgk_tsb_after_amp,%a0
        move.l %a0,GK_TSB_STOCK_RETURN(%a6)
        move.l GK_TSB_INPUT_D0(%a6),%d0
        move.l GK_TSB_INPUT_D1(%a6),%d1
        movea.l GK_TSB_INPUT_A0(%a6),%a0
        movea.l GK_TSB_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_TSB_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        jsr gk_track_setup_amp_trampoline
.Lgk_tsb_after_amp:
        lea 8(%sp),%sp
        move.w %sr,%d2
        move.w %d2,GK_TSB_OUTPUT_SR(%a6)
        move.l %d0,GK_TSB_OUTPUT_D0(%a6)
        move.l %d1,GK_TSB_OUTPUT_D1(%a6)
        move.l %a0,GK_TSB_OUTPUT_A0(%a6)
        move.l %a1,GK_TSB_OUTPUT_A1(%a6)
        tst.l GK_TSB_ACTIVE(%a6)
        beq.w gk_track_setup_byte_no_write_finish
        jmp gk_track_setup_byte_finish
        .global gk_track_setup_playback_trampoline
        .type   gk_track_setup_playback_trampoline,@function
gk_track_setup_playback_trampoline:
        .incbin "stock/0356.bin", 0, 4
        .incbin "stock/0356.bin", 4, 4
        jmp     GK_STOCK_PLAYBACK_SETUP_CONTINUE
        .size   gk_track_setup_playback_trampoline,.-gk_track_setup_playback_trampoline
        .global gk_track_setup_effect2_trampoline
        .type   gk_track_setup_effect2_trampoline,@function
gk_track_setup_effect2_trampoline:
        .incbin "stock/0357.bin", 0, 4
        .incbin "stock/0357.bin", 4, 4
        jmp     GK_STOCK_EFFECT2_SETUP_CONTINUE
        .size   gk_track_setup_effect2_trampoline,.-gk_track_setup_effect2_trampoline
        .global gk_track_setup_effect1_trampoline
        .type   gk_track_setup_effect1_trampoline,@function
gk_track_setup_effect1_trampoline:
        .incbin "stock/0358.bin", 0, 4
        .incbin "stock/0358.bin", 4, 4
        jmp     GK_STOCK_EFFECT1_SETUP_CONTINUE
        .size   gk_track_setup_effect1_trampoline,.-gk_track_setup_effect1_trampoline
        .global gk_track_setup_amp_trampoline
        .type   gk_track_setup_amp_trampoline,@function
gk_track_setup_amp_trampoline:
        .incbin "stock/0359.bin", 0, 4
        .incbin "stock/0359.bin", 4, 4
        jmp     GK_STOCK_AMP_SETUP_CONTINUE
        .size   gk_track_setup_amp_trampoline,.-gk_track_setup_amp_trampoline
        .type   gk_track_setup_byte_marker_validate,@function
gk_track_setup_byte_marker_validate:
        move.l  %a1,-(%sp)
        move.l  %d3,-(%sp)
        bsr.w   gk_track_setup_byte_validate_current
        move.l  (%sp)+,%d3
        movea.l (%sp)+,%a1
        tst.l   %d0
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_TSB_FAMILY(%a6),%d4
        move.l  GK_TSBM_D0(%a1),%d0
        cmpi.l  #GK_STOCK_BANK_DIRTY_OFFSET,%d0
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_TSBM_D4(%a1),%d0
        cmp.l   GK_TSB_TRACK(%a6),%d0
        bne.w   .Lgk_tsbm_corrupt
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d4
        bne.s   .Lgk_tsbm_not_playback
        cmpi.l  #GK_STOCK_PLAYBACK_SETUP_DIRTY_RETURN,%d3
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_TSBM_D5(%a1),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_TSBM_A3(%a1),%d0
        cmp.l   GK_TSB_ARGUMENT(%a6),%d0
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_TSBM_A2(%a1),%d0
        cmp.l   GK_TSB_BANK_POINTER(%a6),%d0
        bne.w   .Lgk_tsbm_corrupt
        bra.s   .Lgk_tsbm_registers_ok
.Lgk_tsbm_not_playback:
        move.l  GK_TSBM_D1(%a1),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_TSBM_D5(%a1),%d0
        cmp.l   GK_TSB_PART(%a6),%d0
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_TSBM_A2(%a1),%d0
        cmp.l   GK_TSB_ARGUMENT(%a6),%d0
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_TSBM_A3(%a1),%d0
        cmp.l   GK_TSB_BANK_POINTER(%a6),%d0
        bne.w   .Lgk_tsbm_corrupt
        cmpi.l  #GK_TRACK_SETUP_EFFECT2,%d4
        bne.s   .Lgk_tsbm_not_effect2
        cmpi.l  #GK_STOCK_EFFECT2_SETUP_DIRTY_RETURN,%d3
        bne.w   .Lgk_tsbm_corrupt
        bra.s   .Lgk_tsbm_registers_ok
.Lgk_tsbm_not_effect2:
        cmpi.l  #GK_TRACK_SETUP_EFFECT1,%d4
        bne.s   .Lgk_tsbm_amp
        cmpi.l  #GK_STOCK_EFFECT1_SETUP_DIRTY_RETURN,%d3
        bne.w   .Lgk_tsbm_corrupt
        bra.s   .Lgk_tsbm_registers_ok
.Lgk_tsbm_amp:
        cmpi.l  #GK_TRACK_SETUP_AMP,%d4
        bne.w   .Lgk_tsbm_corrupt
        cmpi.l  #GK_STOCK_AMP_SETUP_DIRTY_RETURN,%d3
        bne.w   .Lgk_tsbm_corrupt
.Lgk_tsbm_registers_ok:
        movea.l %a1,%a3
        bsr.w   gk_track_setup_byte_pointers
        move.l  GK_TSBM_D2(%a3),%d0
        andi.l  #0xff,%d0
        move.l  %d0,GK_TSB_NEW_VALUE(%a6)
        moveq   #0,%d1
        move.b  (%a0),%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_tsbm_corrupt
        moveq   #0,%d1
        move.b  (%a1),%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_tsbm_corrupt
        moveq   #1,%d1
        move.l  GK_TSB_PART(%a6),%d0
        lsl.l   %d0,%d1
        or.l    GK_TSB_OLD_BANK_EDITED(%a6),%d1
        movea.l GK_TSB_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_tsbm_corrupt
        moveq   #1,%d1
        move.l  GK_TSB_PART(%a6),%d0
        lsl.l   %d0,%d1
        or.l    GK_TSB_OLD_MIRROR_EDITED(%a6),%d1
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_tsbm_corrupt
        movea.l GK_TSB_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_tsbm_corrupt
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmp.l   GK_TSB_OLD_PROJECT_DIRTY(%a6),%d0
        bne.w   .Lgk_tsbm_corrupt
        tst.l   GK_TSB_MARKER_COUNT(%a6)
        bne.s   .Lgk_tsbm_corrupt
        move.l  GK_TSB_TOKEN(%a6),%d0
        andi.l  #GK_TRACK_SETUP_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_TRACK_SETUP_TOKEN_ARMED,%d0
        bne.s   .Lgk_tsbm_corrupt
        moveq   #1,%d0
        move.l  %d0,GK_TSB_MARKER_COUNT(%a6)
        move.l  GK_TSB_TOKEN(%a6),%d0
        andi.l  #GK_TRACK_SETUP_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_TRACK_SETUP_TOKEN_WRITTEN,%d0
        move.l  %d0,GK_TSB_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_TSB_TOKEN_INVERSE(%a6)
        moveq   #GK_OK,%d0
        rts
.Lgk_tsbm_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_track_setup_byte_marker_validate,.-gk_track_setup_byte_marker_validate
        .global gk_track_setup_byte_write_marker
        .type   gk_track_setup_byte_write_marker,@function
gk_track_setup_byte_write_marker:
        lea     -GK_TSBM_SAVED_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.w  %sr,%d0
        move.w  %d0,GK_TSBM_SR(%sp)
        movea.l %sp,%a1
        move.l  GK_TSBM_RETURN(%sp),%d3
        move.l  GK_TSBM_A6(%a1),%d0
        cmp.l   %a6,%d0
        bne.w   gk_track_setup_byte_fatal
        lea     112(%a1),%a0
        cmpa.l  %a0,%a6
        bne.s   .Lgk_tsbm_geometry_not_playback
        moveq   #GK_TRACK_SETUP_PLAYBACK,%d4
        move.l  100(%a1),%d5
        move.l  104(%a1),%d6
        move.l  108(%a1),%d7
        lea     .Lgk_tsb_after_playback,%a2
        cmpi.l  #GK_STOCK_PLAYBACK_SETUP_DIRTY_RETURN,%d3
        bra.w   .Lgk_tsbm_geometry_ready
.Lgk_tsbm_geometry_not_playback:
        lea     108(%a1),%a0
        cmpa.l  %a0,%a6
        bne.s   .Lgk_tsbm_geometry_amp
        move.l  GK_TSB_FAMILY(%a6),%d4
        cmpi.l  #GK_TRACK_SETUP_EFFECT2,%d4
        beq.s   .Lgk_tsbm_geometry_effect2
        cmpi.l  #GK_TRACK_SETUP_EFFECT1,%d4
        bne.w   gk_track_setup_byte_release_abort_fatal
        move.l  96(%a1),%d5
        move.l  100(%a1),%d6
        move.l  104(%a1),%d7
        lea     .Lgk_tsb_after_effect1,%a2
        cmpi.l  #GK_STOCK_EFFECT1_SETUP_DIRTY_RETURN,%d3
        bra.s   .Lgk_tsbm_geometry_ready
.Lgk_tsbm_geometry_effect2:
        move.l  96(%a1),%d5
        move.l  100(%a1),%d6
        move.l  104(%a1),%d7
        lea     .Lgk_tsb_after_effect2,%a2
        cmpi.l  #GK_STOCK_EFFECT2_SETUP_DIRTY_RETURN,%d3
        bra.s   .Lgk_tsbm_geometry_ready
.Lgk_tsbm_geometry_amp:
        lea     104(%a1),%a0
        cmpa.l  %a0,%a6
        bne.w   gk_track_setup_byte_fatal
        moveq   #GK_TRACK_SETUP_AMP,%d4
        move.l  92(%a1),%d5
        move.l  96(%a1),%d6
        move.l  100(%a1),%d7
        lea     .Lgk_tsb_after_amp,%a2
        cmpi.l  #GK_STOCK_AMP_SETUP_DIRTY_RETURN,%d3
.Lgk_tsbm_geometry_ready:
        bne.w   gk_track_setup_byte_release_abort_fatal
        cmp.l   %a2,%d5
        bne.w   gk_track_setup_byte_release_abort_fatal
        cmp.l   GK_TSB_STOCK_RETURN(%a6),%d5
        bne.w   gk_track_setup_byte_release_abort_fatal
        cmp.l   GK_TSB_ARGUMENT(%a6),%d6
        bne.w   gk_track_setup_byte_release_abort_fatal
        cmp.l   GK_TSB_DELTA(%a6),%d7
        bne.w   gk_track_setup_byte_release_abort_fatal
        cmp.l   GK_TSB_FAMILY(%a6),%d4
        bne.w   gk_track_setup_byte_release_abort_fatal
        move.l  GK_TSB_ACTIVE(%a6),%d0
        cmpi.l  #1,%d0
        bne.w   gk_track_setup_byte_release_abort_fatal
        movea.l %sp,%a1
        move.l  GK_TSBM_RETURN(%sp),%d3
        bsr.w   gk_track_setup_byte_marker_validate
        tst.l   %d0
        bne.w   gk_track_setup_byte_release_abort_fatal
        move.l  GK_TSB_FAMILY(%a6),%d7
        cmpi.l  #GK_TRACK_SETUP_PLAYBACK,%d7
        beq.s   .Lgk_tsbm_restore_playback
        move.w  GK_TSBM_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     GK_TSBM_SAVED_BYTES(%sp),%sp
        .global gk_track_setup_byte_stock_dirty_store_d1
gk_track_setup_byte_stock_dirty_store_d1:
        .incbin "stock/0360.bin", 0, 6
        rts
.Lgk_tsbm_restore_playback:
        move.w  GK_TSBM_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     GK_TSBM_SAVED_BYTES(%sp),%sp
        .global gk_track_setup_byte_stock_dirty_store_d5
gk_track_setup_byte_stock_dirty_store_d5:
        .incbin "stock/0361.bin", 0, 6
        rts
        .size   gk_track_setup_byte_write_marker,.-gk_track_setup_byte_write_marker
