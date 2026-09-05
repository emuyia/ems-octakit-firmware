        .include "abi.inc"
        .equ    GK_RP_FRAME_SIZE,184
        .equ    GK_RP_INPUT_D0,44
        .equ    GK_RP_INPUT_D1,48
        .equ    GK_RP_INPUT_A0,52
        .equ    GK_RP_INPUT_A1,56
        .equ    GK_RP_INPUT_SR,60
        .equ    GK_RP_OUTPUT_D0,64
        .equ    GK_RP_OUTPUT_D1,68
        .equ    GK_RP_OUTPUT_A0,72
        .equ    GK_RP_OUTPUT_A1,76
        .equ    GK_RP_OUTPUT_SR,80
        .equ    GK_RP_SOURCE,84
        .equ    GK_RP_BANK,88
        .equ    GK_RP_PATTERN,92
        .equ    GK_RP_PART,96
        .equ    GK_RP_TRACK,100
        .equ    GK_RP_DESCRIPTOR,104
        .equ    GK_RP_PAYLOAD,108
        .equ    GK_RP_BANK_POINTER,112
        .equ    GK_RP_PAGE,116
        .equ    GK_RP_MODE,120
        .equ    GK_RP_OBJECT_POINTER,124
        .equ    GK_RP_OBJECT_FLAG,128
        .equ    GK_RP_SELECTION,132
        .equ    GK_RP_ROUTE,136
        .equ    GK_RP_TOKEN,140
        .equ    GK_RP_TOKEN_INVERSE,144
        .equ    GK_RP_MAGIC,148
        .equ    GK_RP_MAGIC_INVERSE,152
        .equ    GK_RP_OLD_BANK_EDITED,156
        .equ    GK_RP_OLD_MIRROR_EDITED,160
        .equ    GK_RP_OLD_BANK_DIRTY,164
        .equ    GK_RP_OLD_GLOBAL_DIRTY,168
        .equ    GK_RP_KIT,172
        .equ    GK_RP_GATE,176
        .equ    GK_RP_MARKER_COUNT,180
        .equ    GK_RP_MAGIC_VALUE,0x5250464d
        .equ    GK_RPM_SOURCE,152
        .equ    GK_RPM_PART,164
        .equ    GK_RPM_TRACK,168
        .equ    GK_RPM_DESCRIPTOR,172
        .equ    GK_RPM_ROUTE,204
        .equ    GK_RPM_TOKEN,208
        .equ    GK_RPM_TOKEN_INVERSE,212
        .equ    GK_RPM_MAGIC,216
        .equ    GK_RPM_MAGIC_INVERSE,220
        .equ    GK_RPM_COUNT,248
        .equ    GK_RPM_RETURN,8
        .section .runtime,"ax"
        .align  4
        .type   gk_reload_page_clear_private,@function
gk_reload_page_clear_private:
        clr.l   __gk_reload_page_state_start
        rts
        .size   gk_reload_page_clear_private,.-gk_reload_page_clear_private
        .type   gk_reload_page_private_fatal,@function
gk_reload_page_private_fatal:
        bsr.w   gk_reload_page_clear_private
        bra.w   gk_reload_page_fatal
        .size   gk_reload_page_private_fatal,.-gk_reload_page_private_fatal
        .type   gk_reload_page_abort_fatal,@function
gk_reload_page_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_reload_page_private_fatal
        bra.w   gk_reload_page_private_fatal
        .size   gk_reload_page_abort_fatal,.-gk_reload_page_abort_fatal
        .type   gk_reload_page_release_d0_abort_fatal,@function
gk_reload_page_release_d0_abort_fatal:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_reload_page_private_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_reload_page_private_fatal
        bra.w   gk_reload_page_abort_fatal
        .size   gk_reload_page_release_d0_abort_fatal,.-gk_reload_page_release_d0_abort_fatal
        .type   gk_reload_page_release_abort_fatal,@function
gk_reload_page_release_abort_fatal:
        move.l  %d6,%d0
        bra.w   gk_reload_page_release_d0_abort_fatal
        .size   gk_reload_page_release_abort_fatal,.-gk_reload_page_release_abort_fatal
        .type   gk_reload_page_release_fatal,@function
gk_reload_page_release_fatal:
        move.l  %d6,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_reload_page_private_fatal
        jsr     gk_descriptor_release
        bra.w   gk_reload_page_private_fatal
        .size   gk_reload_page_release_fatal,.-gk_reload_page_release_fatal
        .type   gk_reload_page_marker_fatal,@function
gk_reload_page_marker_fatal:
        move.l  GK_RPM_DESCRIPTOR(%sp),%d0
        addq.l  #8,%sp
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_reload_page_private_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_reload_page_private_fatal
        bra.w   gk_reload_page_abort_fatal
        .size   gk_reload_page_marker_fatal,.-gk_reload_page_marker_fatal
        .type   gk_reload_page_context_token,@function
gk_reload_page_context_token:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_rp_token_corrupt
        cmpi.l  #15,%d1
        bhi.s   .Lgk_rp_token_corrupt
        cmpi.l  #3,%d2
        bhi.s   .Lgk_rp_token_corrupt
        cmpi.l  #7,%d3
        bhi.s   .Lgk_rp_token_corrupt
        lsl.l   #7,%d3
        or.l    %d3,%d0
        lsl.l   #8,%d2
        lsl.l   #2,%d2
        or.l    %d2,%d0
        lsl.l   #8,%d1
        lsl.l   #4,%d1
        or.l    %d1,%d0
        ori.l   #GK_RELOAD_PAGE_TOKEN_ARMED,%d0
        rts
.Lgk_rp_token_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_reload_page_context_token,.-gk_reload_page_context_token
        .type   gk_reload_page_classify,@function
gk_reload_page_classify:
        move.l  GK_RP_PAGE(%a6),%d0
        cmpi.l  #4,%d0
        bhi.w   .Lgk_rp_route_page_out
        tst.l   GK_RP_MODE(%a6)
        bne.s   .Lgk_rp_route_midi
        cmpi.l  #0,%d0
        beq.w   .Lgk_rp_route_audio_0
        cmpi.l  #2,%d0
        beq.w   .Lgk_rp_route_audio_2
        cmpi.l  #3,%d0
        beq.w   .Lgk_rp_route_audio_3
        cmpi.l  #4,%d0
        beq.w   .Lgk_rp_route_audio_4
        tst.l   GK_RP_OBJECT_FLAG(%a6)
        beq.w   .Lgk_rp_route_audio_1_normal
        move.l  GK_RP_SELECTION(%a6),%d0
        cmpi.l  #2,%d0
        bhi.w   .Lgk_rp_route_special_out
        addi.l  #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_0,%d0
        rts
.Lgk_rp_route_midi:
        cmpi.l  #0,%d0
        beq.w   .Lgk_rp_route_midi_0
        cmpi.l  #2,%d0
        beq.w   .Lgk_rp_route_midi_2
        cmpi.l  #3,%d0
        beq.w   .Lgk_rp_route_midi_3
        cmpi.l  #4,%d0
        beq.w   .Lgk_rp_route_midi_4
        tst.l   GK_RP_OBJECT_FLAG(%a6)
        beq.s   .Lgk_rp_route_midi_1_normal
        move.l  GK_RP_SELECTION(%a6),%d0
        cmpi.l  #2,%d0
        bhi.s   .Lgk_rp_route_special_out
        addi.l  #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_0,%d0
        rts
.Lgk_rp_route_audio_0:
        moveq   #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_0,%d0
        rts
.Lgk_rp_route_audio_2:
        moveq   #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_2,%d0
        rts
.Lgk_rp_route_audio_1_normal:
        moveq   #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_1_NORMAL,%d0
        rts
.Lgk_rp_route_audio_3:
        moveq   #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_3,%d0
        rts
.Lgk_rp_route_audio_4:
        moveq   #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_4,%d0
        rts
.Lgk_rp_route_midi_0:
        moveq   #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_0,%d0
        rts
.Lgk_rp_route_midi_2:
        moveq   #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_2,%d0
        rts
.Lgk_rp_route_midi_1_normal:
        moveq   #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_1_NORMAL,%d0
        rts
.Lgk_rp_route_midi_3:
        moveq   #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_3,%d0
        rts
.Lgk_rp_route_midi_4:
        moveq   #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_4,%d0
        rts
.Lgk_rp_route_page_out:
        moveq   #GK_RELOAD_PAGE_ROUTE_PAGE_OUT_OF_RANGE,%d0
        rts
.Lgk_rp_route_special_out:
        moveq   #GK_RELOAD_PAGE_ROUTE_SPECIAL_OUT_OF_RANGE,%d0
        rts
        .size   gk_reload_page_classify,.-gk_reload_page_classify
        .type   gk_reload_page_capture_context,@function
gk_reload_page_capture_context:
        tst.l   __gk_lifecycle_state
        bne.w   gk_reload_page_private_fatal
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        tst.b   __gk_reload_page_active
        bne.w   .Lgk_rp_claim_busy
        move.l  GK_RP_SOURCE(%a6),%d0
        move.b  %d0,__gk_reload_page_active
        not.l   %d0
        move.b  %d0,__gk_reload_page_active_inverse
        moveq   #-1,%d0
        move.b  %d0,__gk_reload_page_part
        move.b  %d0,__gk_reload_page_track
        move.w  %d1,%sr
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_reload_page_private_fatal
        movea.l %d0,%a2
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   gk_reload_page_private_fatal
        move.b  %d0,__gk_reload_page_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_reload_page_private_fatal
        movea.l %d0,%a3
        move.b  %d0,__gk_reload_page_track
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_reload_page_private_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_reload_page_private_fatal
        move.l  %d4,GK_RP_BANK(%a6)
        move.l  %d5,GK_RP_PATTERN(%a6)
        move.l  %a2,GK_RP_PART(%a6)
        move.l  %a3,GK_RP_TRACK(%a6)
        move.l  %d6,GK_RP_DESCRIPTOR(%a6)
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        move.l  %d0,GK_RP_KIT(%a6)
        move.l  GK_STOCK_BANK_POINTER,%d0
        move.l  %d0,GK_RP_BANK_POINTER(%a6)
        movea.l %d0,%a5
        moveq   #0,%d0
        move.b  GK_STOCK_RELOAD_PAGE,%d0
        move.l  %d0,GK_RP_PAGE(%a6)
        move.l  GK_STOCK_RELOAD_PAGE_MODE,%d0
        move.l  %d0,GK_RP_MODE(%a6)
        clr.l   GK_RP_OBJECT_POINTER(%a6)
        clr.l   GK_RP_OBJECT_FLAG(%a6)
        clr.l   GK_RP_SELECTION(%a6)
        clr.l   GK_RP_GATE(%a6)
        move.l  GK_RP_SOURCE(%a6),%d0
        cmpi.l  #GK_RELOAD_PAGE_SOURCE_CONDITIONAL,%d0
        bne.s   .Lgk_rp_gate_captured
        move.l  GK_STOCK_RELOAD_PAGE_GATE,%d0
        tst.l   %d0
        beq.w   gk_reload_page_private_fatal
        move.l  %d0,GK_RP_GATE(%a6)
.Lgk_rp_gate_captured:
        move.l  GK_RP_PAGE(%a6),%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_rp_special_captured
        movea.l GK_STOCK_RELOAD_PAGE_OBJECT_POINTER,%a0
        move.l  %a0,%d0
        beq.w   gk_reload_page_private_fatal
        move.l  %d0,GK_RP_OBJECT_POINTER(%a6)
        move.l  8(%a0),%d0
        move.l  %d0,GK_RP_OBJECT_FLAG(%a6)
        beq.s   .Lgk_rp_special_captured
        move.l  GK_STOCK_RELOAD_PAGE_SELECTION,%d0
        move.l  %d0,GK_RP_SELECTION(%a6)
.Lgk_rp_special_captured:
        rts
.Lgk_rp_claim_busy:
        move.w  %d1,%sr
        bra.w   gk_reload_page_private_fatal
        .size   gk_reload_page_capture_context,.-gk_reload_page_capture_context
        .type   gk_reload_page_prepare,@function
gk_reload_page_prepare:
        bsr.w   gk_reload_page_capture_context
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  GK_RP_KIT(%a6),%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_reload_page_private_fatal
        cmp.l   %d6,%d0
        bne.w   gk_reload_page_abort_fatal
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_reload_page_abort_fatal
        movea.l %a0,%a4
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_reload_page_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_reload_page_release_d0_abort_fatal
        cmpa.l  %a4,%a0
        bne.w   gk_reload_page_release_abort_fatal
        move.l  %a2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        movea.l %a5,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        cmpa.l  %a4,%a0
        bne.w   gk_reload_page_release_abort_fatal
        move.l  %a4,GK_RP_PAYLOAD(%a6)
        bsr.w   gk_reload_page_classify
        move.l  %d0,%d7
        move.l  %d0,GK_RP_ROUTE(%a6)
        clr.l   GK_RP_MARKER_COUNT(%a6)
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %a2,%d2
        move.l  %a3,%d3
        bsr.w   gk_reload_page_context_token
        tst.l   %d0
        bmi.w   gk_reload_page_release_abort_fatal
        move.l  %d0,GK_RP_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_RP_TOKEN_INVERSE(%a6)
        move.l  #GK_RP_MAGIC_VALUE,%d0
        move.l  %d0,GK_RP_MAGIC(%a6)
        not.l   %d0
        move.l  %d0,GK_RP_MAGIC_INVERSE(%a6)
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  %d0,GK_RP_OLD_BANK_EDITED(%a6)
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        move.l  %d0,GK_RP_OLD_MIRROR_EDITED(%a6)
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        move.l  %d0,GK_RP_OLD_BANK_DIRTY(%a6)
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        move.l  %d0,GK_RP_OLD_GLOBAL_DIRTY(%a6)
        rts
        .size   gk_reload_page_prepare,.-gk_reload_page_prepare
        .type   gk_reload_page_validate_current,@function
gk_reload_page_validate_current:
        move.l  GK_RP_MAGIC(%a6),%d0
        cmpi.l  #GK_RP_MAGIC_VALUE,%d0
        bne.w   .Lgk_rp_validate_corrupt
        not.l   %d0
        cmp.l   GK_RP_MAGIC_INVERSE(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %a2,%d2
        move.l  %a3,%d3
        bsr.w   gk_reload_page_context_token
        tst.l   %d0
        bmi.w   .Lgk_rp_validate_corrupt
        andi.l  #GK_RELOAD_PAGE_TOKEN_CONTEXT_MASK,%d0
        move.l  GK_RP_TOKEN(%a6),%d1
        move.l  %d1,%d2
        andi.l  #GK_RELOAD_PAGE_TOKEN_CONTEXT_MASK,%d2
        cmp.l   %d2,%d0
        bne.w   .Lgk_rp_validate_corrupt
        move.l  %d1,%d0
        andi.l  #GK_RELOAD_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_RELOAD_PAGE_TOKEN_ARMED,%d0
        beq.s   .Lgk_rp_validate_token_state
        cmpi.l  #GK_RELOAD_PAGE_TOKEN_WRITTEN,%d0
        bne.w   .Lgk_rp_validate_corrupt
.Lgk_rp_validate_token_state:
        not.l   %d1
        cmp.l   GK_RP_TOKEN_INVERSE(%a6),%d1
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_reload_page_active,%d0
        cmp.l   GK_RP_SOURCE(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        not.l   %d0
        andi.l  #0xff,%d0
        moveq   #0,%d1
        move.b  __gk_reload_page_active_inverse,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_reload_page_part,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_reload_page_track,%d0
        move.l  %a3,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_validate_corrupt
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   GK_RP_KIT(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a3,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_validate_corrupt
        move.l  GK_STOCK_BANK_POINTER,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_validate_corrupt
        move.l  %a4,%d0
        cmp.l   GK_RP_PAYLOAD(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_RELOAD_PAGE,%d0
        cmp.l   GK_RP_PAGE(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        move.l  GK_STOCK_RELOAD_PAGE_MODE,%d0
        cmp.l   GK_RP_MODE(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        move.l  GK_RP_SOURCE(%a6),%d0
        cmpi.l  #GK_RELOAD_PAGE_SOURCE_CONDITIONAL,%d0
        bne.s   .Lgk_rp_validate_gate
        move.l  GK_STOCK_RELOAD_PAGE_GATE,%d0
        cmp.l   GK_RP_GATE(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
.Lgk_rp_validate_gate:
        move.l  GK_RP_PAGE(%a6),%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_rp_validate_special
        movea.l GK_STOCK_RELOAD_PAGE_OBJECT_POINTER,%a0
        move.l  %a0,%d0
        cmp.l   GK_RP_OBJECT_POINTER(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        move.l  8(%a0),%d0
        cmp.l   GK_RP_OBJECT_FLAG(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        tst.l   %d0
        beq.s   .Lgk_rp_validate_special
        move.l  GK_STOCK_RELOAD_PAGE_SELECTION,%d0
        cmp.l   GK_RP_SELECTION(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
.Lgk_rp_validate_special:
        bsr.w   gk_reload_page_classify
        cmp.l   %d7,%d0
        bne.w   .Lgk_rp_validate_corrupt
        cmp.l   GK_RP_ROUTE(%a6),%d0
        bne.w   .Lgk_rp_validate_corrupt
        move.l  %d4,%d0
        lsl.l   #2,%d0
        add.l   %a2,%d0
        jsr     gk_physical_validate
        cmp.l   %d6,%d0
        bne.s   .Lgk_rp_validate_corrupt
        cmpa.l  %a4,%a0
        bne.s   .Lgk_rp_validate_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_rp_validate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_reload_page_validate_current,.-gk_reload_page_validate_current
        .type   gk_reload_page_validate_result,@function
gk_reload_page_validate_result:
        cmpi.l  #GK_RELOAD_PAGE_ROUTE_PAGE_OUT_OF_RANGE,%d7
        bhs.w   .Lgk_rp_result_no_write
        move.l  GK_RP_MARKER_COUNT(%a6),%d0
        cmpi.l  #6,%d0
        bne.w   .Lgk_rp_result_corrupt
        move.l  GK_RP_TOKEN(%a6),%d0
        andi.l  #GK_RELOAD_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_RELOAD_PAGE_TOKEN_WRITTEN,%d0
        bne.w   .Lgk_rp_result_corrupt
        moveq   #1,%d1
        move.l  %a2,%d0
        lsl.l   %d0,%d1
        or.l    GK_RP_OLD_BANK_EDITED(%a6),%d1
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_result_corrupt
        moveq   #1,%d1
        move.l  %a2,%d0
        lsl.l   %d0,%d1
        or.l    GK_RP_OLD_MIRROR_EDITED(%a6),%d1
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_rp_result_corrupt
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_rp_result_corrupt
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_rp_result_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_rp_result_no_write:
        tst.l   GK_RP_MARKER_COUNT(%a6)
        bne.s   .Lgk_rp_result_corrupt
        move.l  GK_RP_TOKEN(%a6),%d0
        andi.l  #GK_RELOAD_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_RELOAD_PAGE_TOKEN_ARMED,%d0
        bne.s   .Lgk_rp_result_corrupt
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   GK_RP_OLD_BANK_EDITED(%a6),%d0
        bne.s   .Lgk_rp_result_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        cmp.l   GK_RP_OLD_MIRROR_EDITED(%a6),%d0
        bne.s   .Lgk_rp_result_corrupt
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        cmp.l   GK_RP_OLD_BANK_DIRTY(%a6),%d0
        bne.s   .Lgk_rp_result_corrupt
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmp.l   GK_RP_OLD_GLOBAL_DIRTY(%a6),%d0
        bne.s   .Lgk_rp_result_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_rp_result_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_reload_page_validate_result,.-gk_reload_page_validate_result
        .type   gk_reload_page_return_stock,@function
gk_reload_page_return_stock:
        bsr.w   gk_reload_page_clear_private
        moveq   #0,%d2
        move.w  GK_RP_OUTPUT_SR(%a6),%d2
        move.w  %d2,%sr
        move.l  GK_RP_OUTPUT_D0(%a6),%d0
        move.l  GK_RP_OUTPUT_D1(%a6),%d1
        movea.l GK_RP_OUTPUT_A0(%a6),%a0
        movea.l GK_RP_OUTPUT_A1(%a6),%a1
        movem.l (%a6),%d2-%d7/%a2-%a6
        lea     GK_RP_FRAME_SIZE(%sp),%sp
        rts
        .size   gk_reload_page_return_stock,.-gk_reload_page_return_stock
        .type   gk_reload_page_finish,@function
gk_reload_page_finish:
        bsr.w   gk_reload_page_validate_current
        tst.l   %d0
        bne.w   gk_reload_page_release_abort_fatal
        bsr.w   gk_reload_page_validate_result
        tst.l   %d0
        bne.w   gk_reload_page_release_abort_fatal
        cmpi.l  #GK_RELOAD_PAGE_ROUTE_PAGE_OUT_OF_RANGE,%d7
        bhs.s   .Lgk_rp_finish_no_write
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_reload_page_release_abort_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_reload_page_release_abort_fatal
        bsr.w   gk_reload_page_validate_current
        tst.l   %d0
        bne.w   gk_reload_page_release_fatal
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_reload_page_private_fatal
        bra.w   gk_reload_page_return_stock
.Lgk_rp_finish_no_write:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_reload_page_private_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_reload_page_private_fatal
        bra.w   gk_reload_page_return_stock
        .size   gk_reload_page_finish,.-gk_reload_page_finish
        .global gk_stock_reload_page_direct_callback
        .type gk_stock_reload_page_direct_callback,@function
gk_stock_reload_page_direct_callback:
        move.l %d0,-(%sp)
        move.l 8(%sp),%d0
        cmpi.l #0x32,%d0
        bne.w gk_reload_page_private_fatal
        tst.l 12(%sp)
        beq.w gk_reload_page_private_fatal
        move.l (%sp)+,%d0
.Lgk_rp_wrapper_owned_0:
        lea -GK_RP_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l %d0,GK_RP_INPUT_D0(%a6)
        move.l %d1,GK_RP_INPUT_D1(%a6)
        move.l %a0,GK_RP_INPUT_A0(%a6)
        move.l %a1,GK_RP_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_RP_INPUT_SR(%a6)
        moveq #GK_RELOAD_PAGE_SOURCE_DIRECT,%d2
        move.l %d2,GK_RP_SOURCE(%a6)
        bsr.w gk_reload_page_prepare
        move.l GK_RP_FRAME_SIZE+8(%a6),-(%sp)
        move.l GK_RP_FRAME_SIZE+4(%a6),-(%sp)
        move.l GK_RP_INPUT_D0(%a6),%d0
        move.l GK_RP_INPUT_D1(%a6),%d1
        movea.l GK_RP_INPUT_A0(%a6),%a0
        movea.l GK_RP_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_RP_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        .global gk_reload_page_direct_stock_call
gk_reload_page_direct_stock_call:
        jsr GK_STOCK_RELOAD_PAGE_WRITER
        addq.l #8,%sp
        move.l %d0,GK_RP_OUTPUT_D0(%a6)
        move.l %d1,GK_RP_OUTPUT_D1(%a6)
        move.l %a0,GK_RP_OUTPUT_A0(%a6)
        move.l %a1,GK_RP_OUTPUT_A1(%a6)
        move.w %sr,%d0
        move.w %d0,GK_RP_OUTPUT_SR(%a6)
        jmp gk_reload_page_finish
        .size gk_stock_reload_page_direct_callback,.-gk_stock_reload_page_direct_callback
        .global gk_stock_reload_page_conditional_callback
        .type gk_stock_reload_page_conditional_callback,@function
gk_stock_reload_page_conditional_callback:
        move.l %d0,-(%sp)
        move.l 8(%sp),%d0
        cmpi.l #0x32,%d0
        bne.w gk_reload_page_private_fatal
        tst.l 12(%sp)
        beq.w gk_reload_page_private_fatal
        move.l (%sp)+,%d0
        tst.l GK_STOCK_RELOAD_PAGE_GATE
        bne.s .Lgk_rp_wrapper_owned_2
        jmp GK_STOCK_RELOAD_PAGE_CONDITIONAL
.Lgk_rp_wrapper_owned_2:
        lea -GK_RP_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l %d0,GK_RP_INPUT_D0(%a6)
        move.l %d1,GK_RP_INPUT_D1(%a6)
        move.l %a0,GK_RP_INPUT_A0(%a6)
        move.l %a1,GK_RP_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_RP_INPUT_SR(%a6)
        moveq #GK_RELOAD_PAGE_SOURCE_CONDITIONAL,%d2
        move.l %d2,GK_RP_SOURCE(%a6)
        bsr.w gk_reload_page_prepare
        move.l GK_RP_FRAME_SIZE+8(%a6),-(%sp)
        move.l GK_RP_FRAME_SIZE+4(%a6),-(%sp)
        move.l GK_RP_INPUT_D0(%a6),%d0
        move.l GK_RP_INPUT_D1(%a6),%d1
        movea.l GK_RP_INPUT_A0(%a6),%a0
        movea.l GK_RP_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_RP_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        .global gk_reload_page_conditional_stock_call
gk_reload_page_conditional_stock_call:
        jsr GK_STOCK_RELOAD_PAGE_CONDITIONAL
        addq.l #8,%sp
        move.l %d0,GK_RP_OUTPUT_D0(%a6)
        move.l %d1,GK_RP_OUTPUT_D1(%a6)
        move.l %a0,GK_RP_OUTPUT_A0(%a6)
        move.l %a1,GK_RP_OUTPUT_A1(%a6)
        move.w %sr,%d0
        move.w %d0,GK_RP_OUTPUT_SR(%a6)
        jmp gk_reload_page_finish
        .size gk_stock_reload_page_conditional_callback,.-gk_stock_reload_page_conditional_callback
        .align  4
gk_reload_page_marker_return_table:
        .long   0x4005aa46
        .long   0x4005ab40
        .long   0x4005ac4e
        .long   0x4005ad72
        .long   0x4005ae2c
        .long   0x4005af16
        .long   0x4005b09a
        .long   0x4005b216
        .long   0x4005b320
        .long   0x4005b3fa
        .long   0x4005b4e2
        .long   0x4005b5fc
        .long   0x4005b6bc
        .long   0x4005b794
        .long   0x4005b86e
        .long   0x4005b948
        .global gk_reload_page_write_marker_d0
        .type   gk_reload_page_write_marker_d0,@function
gk_reload_page_write_marker_d0:
        move.l  %d1,-(%sp)
        move.l  %a0,-(%sp)
        cmpi.l  #1,%d0
        bne.w   gk_reload_page_marker_fatal
        move.l GK_RPM_MAGIC(%sp),%d1
        cmpi.l #GK_RP_MAGIC_VALUE,%d1
        bne.w gk_reload_page_marker_fatal
        not.l %d1
        cmp.l GK_RPM_MAGIC_INVERSE(%sp),%d1
        bne.w gk_reload_page_marker_fatal
        move.l GK_RPM_TOKEN(%sp),%d1
        not.l %d1
        cmp.l GK_RPM_TOKEN_INVERSE(%sp),%d1
        bne.w gk_reload_page_marker_fatal
        move.l GK_RPM_TOKEN(%sp),%d1
        andi.l #GK_RELOAD_PAGE_TOKEN_STATE_MASK,%d1
        cmpi.l #GK_RELOAD_PAGE_TOKEN_ARMED,%d1
        beq.s .Lgk_rpm_state_ok_4
        cmpi.l #GK_RELOAD_PAGE_TOKEN_WRITTEN,%d1
        bne.w gk_reload_page_marker_fatal
.Lgk_rpm_state_ok_4:
        moveq #0,%d1
        move.b __gk_reload_page_active,%d1
        cmp.l GK_RPM_SOURCE(%sp),%d1
        bne.w gk_reload_page_marker_fatal
        not.l %d1
        andi.l #0xff,%d1
        cmp.b __gk_reload_page_active_inverse,%d1
        bne.w gk_reload_page_marker_fatal
        moveq #0,%d1
        move.b __gk_reload_page_part,%d1
        cmp.l GK_RPM_PART(%sp),%d1
        bne.w gk_reload_page_marker_fatal
        moveq #0,%d1
        move.b __gk_reload_page_track,%d1
        cmp.l GK_RPM_TRACK(%sp),%d1
        bne.w gk_reload_page_marker_fatal
        move.l GK_RPM_COUNT(%sp),%d1
        cmpi.l #5,%d1
        bhi.w gk_reload_page_marker_fatal
        addq.l #1,%d1
        move.l %d1,GK_RPM_COUNT(%sp)
        move.l GK_RPM_TOKEN(%sp),%d1
        andi.l #GK_RELOAD_PAGE_TOKEN_STATE_MASK,%d1
        cmpi.l #GK_RELOAD_PAGE_TOKEN_WRITTEN,%d1
        beq.s .Lgk_rpm_written_4
        move.l GK_RPM_TOKEN(%sp),%d1
        andi.l #GK_RELOAD_PAGE_TOKEN_CONTEXT_MASK,%d1
        ori.l #GK_RELOAD_PAGE_TOKEN_WRITTEN,%d1
        move.l %d1,GK_RPM_TOKEN(%sp)
        not.l %d1
        move.l %d1,GK_RPM_TOKEN_INVERSE(%sp)
.Lgk_rpm_written_4:
        move.l  GK_RPM_ROUTE(%sp),%d1
        cmpi.l  #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_0,%d1
        bcs.s   .Lgk_rpm_d0_nonspecial
        cmpi.l  #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_2,%d1
        bhi.s   .Lgk_rpm_d0_nonspecial
        move.l  GK_RPM_COUNT(%sp),%d1
        subq.l  #1,%d1
        lsr.l   #1,%d1
        addq.l  #GK_RELOAD_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_0,%d1
        bra.s   .Lgk_rpm_d0_route_ready
.Lgk_rpm_d0_nonspecial:
        cmpi.l  #1,%d1
        bcs.w   gk_reload_page_marker_fatal
        cmpi.l  #7,%d1
        bhi.w   gk_reload_page_marker_fatal
.Lgk_rpm_d0_route_ready:
        lsl.l   #2,%d1
        lea     gk_reload_page_marker_return_table,%a0
        move.l  (%a0,%d1.l),%d1
        cmp.l   GK_RPM_RETURN(%sp),%d1
        bne.w   gk_reload_page_marker_fatal
        movea.l (%sp)+,%a0
        move.l  (%sp)+,%d1
        .global gk_reload_page_stock_dirty_store_d0
gk_reload_page_stock_dirty_store_d0:
        .incbin "stock/0329.bin", 0, 6
        rts
        .size   gk_reload_page_write_marker_d0,.-gk_reload_page_write_marker_d0
        .global gk_reload_page_write_marker_d2
        .type   gk_reload_page_write_marker_d2,@function
gk_reload_page_write_marker_d2:
        move.l  %d0,-(%sp)
        move.l  %a0,-(%sp)
        cmpi.l  #1,%d2
        bne.w   gk_reload_page_marker_fatal
        move.l GK_RPM_MAGIC(%sp),%d0
        cmpi.l #GK_RP_MAGIC_VALUE,%d0
        bne.w gk_reload_page_marker_fatal
        not.l %d0
        cmp.l GK_RPM_MAGIC_INVERSE(%sp),%d0
        bne.w gk_reload_page_marker_fatal
        move.l GK_RPM_TOKEN(%sp),%d0
        not.l %d0
        cmp.l GK_RPM_TOKEN_INVERSE(%sp),%d0
        bne.w gk_reload_page_marker_fatal
        move.l GK_RPM_TOKEN(%sp),%d0
        andi.l #GK_RELOAD_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l #GK_RELOAD_PAGE_TOKEN_ARMED,%d0
        beq.s .Lgk_rpm_state_ok_5
        cmpi.l #GK_RELOAD_PAGE_TOKEN_WRITTEN,%d0
        bne.w gk_reload_page_marker_fatal
.Lgk_rpm_state_ok_5:
        moveq #0,%d0
        move.b __gk_reload_page_active,%d0
        cmp.l GK_RPM_SOURCE(%sp),%d0
        bne.w gk_reload_page_marker_fatal
        not.l %d0
        andi.l #0xff,%d0
        cmp.b __gk_reload_page_active_inverse,%d0
        bne.w gk_reload_page_marker_fatal
        moveq #0,%d0
        move.b __gk_reload_page_part,%d0
        cmp.l GK_RPM_PART(%sp),%d0
        bne.w gk_reload_page_marker_fatal
        moveq #0,%d0
        move.b __gk_reload_page_track,%d0
        cmp.l GK_RPM_TRACK(%sp),%d0
        bne.w gk_reload_page_marker_fatal
        move.l GK_RPM_COUNT(%sp),%d0
        cmpi.l #5,%d0
        bhi.w gk_reload_page_marker_fatal
        addq.l #1,%d0
        move.l %d0,GK_RPM_COUNT(%sp)
        move.l GK_RPM_TOKEN(%sp),%d0
        andi.l #GK_RELOAD_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l #GK_RELOAD_PAGE_TOKEN_WRITTEN,%d0
        beq.s .Lgk_rpm_written_5
        move.l GK_RPM_TOKEN(%sp),%d0
        andi.l #GK_RELOAD_PAGE_TOKEN_CONTEXT_MASK,%d0
        ori.l #GK_RELOAD_PAGE_TOKEN_WRITTEN,%d0
        move.l %d0,GK_RPM_TOKEN(%sp)
        not.l %d0
        move.l %d0,GK_RPM_TOKEN_INVERSE(%sp)
.Lgk_rpm_written_5:
        move.l  GK_RPM_ROUTE(%sp),%d0
        cmpi.l  #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_0,%d0
        bcs.s   .Lgk_rpm_d2_nonspecial
        cmpi.l  #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_2,%d0
        bhi.s   .Lgk_rpm_d2_nonspecial
        move.l  GK_RPM_COUNT(%sp),%d0
        subq.l  #1,%d0
        lsr.l   #1,%d0
        addi.l  #GK_RELOAD_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_0,%d0
        bra.s   .Lgk_rpm_d2_route_ready
.Lgk_rpm_d2_nonspecial:
        tst.l   %d0
        beq.s   .Lgk_rpm_d2_route_ok
        cmpi.l  #8,%d0
        bcs.w   gk_reload_page_marker_fatal
        cmpi.l  #15,%d0
        bhi.w   gk_reload_page_marker_fatal
.Lgk_rpm_d2_route_ok:
.Lgk_rpm_d2_route_ready:
        lsl.l   #2,%d0
        lea     gk_reload_page_marker_return_table,%a0
        move.l  (%a0,%d0.l),%d0
        cmp.l   GK_RPM_RETURN(%sp),%d0
        bne.w   gk_reload_page_marker_fatal
        movea.l (%sp)+,%a0
        move.l  (%sp)+,%d0
        .global gk_reload_page_stock_dirty_store_d2
gk_reload_page_stock_dirty_store_d2:
        .incbin "stock/0330.bin", 0, 6
        rts
        .size   gk_reload_page_write_marker_d2,.-gk_reload_page_write_marker_d2
        .global gk_reload_page_fatal
gk_reload_page_fatal:
        illegal
        bra.s   gk_reload_page_fatal
