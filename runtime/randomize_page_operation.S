        .include "abi.inc"
        .equ    GK_RZ_FRAME_SIZE,196
        .equ    GK_RZ_INPUT_D0,44
        .equ    GK_RZ_INPUT_D1,48
        .equ    GK_RZ_INPUT_A0,52
        .equ    GK_RZ_INPUT_A1,56
        .equ    GK_RZ_INPUT_SR,60
        .equ    GK_RZ_OUTPUT_D0,64
        .equ    GK_RZ_OUTPUT_D1,68
        .equ    GK_RZ_OUTPUT_A0,72
        .equ    GK_RZ_OUTPUT_A1,76
        .equ    GK_RZ_OUTPUT_SR,80
        .equ    GK_RZ_BANK,84
        .equ    GK_RZ_PATTERN,88
        .equ    GK_RZ_PART,92
        .equ    GK_RZ_TRACK,96
        .equ    GK_RZ_DESCRIPTOR,100
        .equ    GK_RZ_PAYLOAD,104
        .equ    GK_RZ_BANK_POINTER,108
        .equ    GK_RZ_PAGE,112
        .equ    GK_RZ_MODE,116
        .equ    GK_RZ_OBJECT_POINTER,120
        .equ    GK_RZ_OBJECT_FLAG,124
        .equ    GK_RZ_SELECTION,128
        .equ    GK_RZ_ROUTE,132
        .equ    GK_RZ_DEFINITION,136
        .equ    GK_RZ_EXPECTED_MASK,140
        .equ    GK_RZ_OBSERVED_MASK,144
        .equ    GK_RZ_NEXT_INDEX,148
        .equ    GK_RZ_MARKER_COUNT,152
        .equ    GK_RZ_TOKEN,156
        .equ    GK_RZ_TOKEN_INVERSE,160
        .equ    GK_RZ_MAGIC,164
        .equ    GK_RZ_MAGIC_INVERSE,168
        .equ    GK_RZ_OLD_BANK_EDITED,172
        .equ    GK_RZ_OLD_MIRROR_EDITED,176
        .equ    GK_RZ_OLD_BANK_DIRTY,180
        .equ    GK_RZ_OLD_GLOBAL_DIRTY,184
        .equ    GK_RZ_KIT,188
        .equ    GK_RZ_ENABLE_BYTE,192
        .equ    GK_RZ_MAGIC_VALUE,0x525a464d
        .equ    GK_RZ_ACTIVE_VALUE,0x31
        .equ    GK_RZM_SAVED_BYTES,60
        .equ    GK_RZM_D0,0
        .equ    GK_RZM_D2,8
        .equ    GK_RZM_D4,16
        .equ    GK_RZM_D5,20
        .equ    GK_RZM_D6,24
        .equ    GK_RZM_A2,40
        .equ    GK_RZM_RETURN,60
        .equ    GK_RZM_FRAME,128
        .equ    GK_RZM_SOURCE_D0,0
        .equ    GK_RZM_SOURCE_D2,2
        .section .runtime,"ax"
        .align  4
        .type   gk_randomize_page_clear_private,@function
gk_randomize_page_clear_private:
        clr.l   __gk_randomize_page_state_start
        rts
        .size   gk_randomize_page_clear_private,.-gk_randomize_page_clear_private
        .type   gk_randomize_page_private_fatal,@function
gk_randomize_page_private_fatal:
        bsr.w   gk_randomize_page_clear_private
        bra.w   gk_randomize_page_fatal
        .size   gk_randomize_page_private_fatal,.-gk_randomize_page_private_fatal
        .type   gk_randomize_page_abort_fatal,@function
gk_randomize_page_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_randomize_page_private_fatal
        bra.w   gk_randomize_page_private_fatal
        .size   gk_randomize_page_abort_fatal,.-gk_randomize_page_abort_fatal
        .type   gk_randomize_page_release_d0_abort_fatal,@function
gk_randomize_page_release_d0_abort_fatal:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_randomize_page_private_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_randomize_page_private_fatal
        bra.w   gk_randomize_page_abort_fatal
        .size   gk_randomize_page_release_d0_abort_fatal,.-gk_randomize_page_release_d0_abort_fatal
        .type   gk_randomize_page_release_abort_fatal,@function
gk_randomize_page_release_abort_fatal:
        move.l  GK_RZ_DESCRIPTOR(%a6),%d0
        bra.w   gk_randomize_page_release_d0_abort_fatal
        .size   gk_randomize_page_release_abort_fatal,.-gk_randomize_page_release_abort_fatal
        .type   gk_randomize_page_release_fatal,@function
gk_randomize_page_release_fatal:
        move.l  GK_RZ_DESCRIPTOR(%a6),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_randomize_page_private_fatal
        jsr     gk_descriptor_release
        bra.w   gk_randomize_page_private_fatal
        .size   gk_randomize_page_release_fatal,.-gk_randomize_page_release_fatal
        .type   gk_randomize_page_marker_fatal,@function
gk_randomize_page_marker_fatal:
        move.l  GK_RZ_DESCRIPTOR(%a6),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_randomize_page_private_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_randomize_page_private_fatal
        bra.w   gk_randomize_page_abort_fatal
        .size   gk_randomize_page_marker_fatal,.-gk_randomize_page_marker_fatal
        .type   gk_randomize_page_context_token,@function
gk_randomize_page_context_token:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_rz_token_corrupt
        cmpi.l  #15,%d1
        bhi.s   .Lgk_rz_token_corrupt
        cmpi.l  #3,%d2
        bhi.s   .Lgk_rz_token_corrupt
        cmpi.l  #7,%d3
        bhi.s   .Lgk_rz_token_corrupt
        lsl.l   #7,%d3
        or.l    %d3,%d0
        lsl.l   #8,%d2
        lsl.l   #2,%d2
        or.l    %d2,%d0
        lsl.l   #8,%d1
        lsl.l   #4,%d1
        or.l    %d1,%d0
        ori.l   #GK_RANDOMIZE_PAGE_TOKEN_ARMED,%d0
        rts
.Lgk_rz_token_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_randomize_page_context_token,.-gk_randomize_page_context_token
        .type   gk_randomize_page_classify,@function
gk_randomize_page_classify:
        move.l  GK_RZ_PAGE(%a6),%d0
        tst.l   GK_RZ_OBJECT_FLAG(%a6)
        beq.s   .Lgk_rz_object_gate_ok
        cmpi.l  #1,%d0
        bne.w   .Lgk_rz_route_object_out
.Lgk_rz_object_gate_ok:
        cmpi.l  #4,%d0
        bhi.w   .Lgk_rz_route_page_out
        tst.l   GK_RZ_MODE(%a6)
        bne.s   .Lgk_rz_route_midi
        cmpi.l  #0,%d0
        beq.w   .Lgk_rz_route_audio_0
        cmpi.l  #2,%d0
        beq.w   .Lgk_rz_route_audio_2
        cmpi.l  #3,%d0
        beq.w   .Lgk_rz_route_audio_3
        cmpi.l  #4,%d0
        beq.w   .Lgk_rz_route_audio_4
        tst.l   GK_RZ_OBJECT_FLAG(%a6)
        beq.w   .Lgk_rz_route_audio_1_normal
        move.l  GK_RZ_SELECTION(%a6),%d0
        cmpi.l  #2,%d0
        bhi.w   .Lgk_rz_route_special_out
        addi.l  #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_0,%d0
        rts
.Lgk_rz_route_midi:
        cmpi.l  #0,%d0
        beq.w   .Lgk_rz_route_midi_0
        cmpi.l  #2,%d0
        beq.w   .Lgk_rz_route_midi_2
        cmpi.l  #3,%d0
        beq.w   .Lgk_rz_route_midi_3
        cmpi.l  #4,%d0
        beq.w   .Lgk_rz_route_midi_4
        tst.l   GK_RZ_OBJECT_FLAG(%a6)
        beq.s   .Lgk_rz_route_midi_1_normal
        move.l  GK_RZ_SELECTION(%a6),%d0
        cmpi.l  #2,%d0
        bhi.s   .Lgk_rz_route_special_out
        addi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_0,%d0
        rts
.Lgk_rz_route_audio_0:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_0,%d0
        rts
.Lgk_rz_route_audio_2:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_2,%d0
        rts
.Lgk_rz_route_audio_1_normal:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_1_NORMAL,%d0
        rts
.Lgk_rz_route_audio_3:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_3,%d0
        rts
.Lgk_rz_route_audio_4:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_4,%d0
        rts
.Lgk_rz_route_midi_0:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_0,%d0
        rts
.Lgk_rz_route_midi_2:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_2,%d0
        rts
.Lgk_rz_route_midi_1_normal:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_1_NORMAL,%d0
        rts
.Lgk_rz_route_midi_3:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_3,%d0
        rts
.Lgk_rz_route_midi_4:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_4,%d0
        rts
.Lgk_rz_route_object_out:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_OBJECT_MODE_NO_WRITE,%d0
        rts
.Lgk_rz_route_page_out:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_PAGE_OUT_OF_RANGE,%d0
        rts
.Lgk_rz_route_special_out:
        moveq   #GK_RANDOMIZE_PAGE_ROUTE_SPECIAL_OUT_OF_RANGE,%d0
        rts
        .size   gk_randomize_page_classify,.-gk_randomize_page_classify
        .type   gk_randomize_page_resolve_definition,@function
gk_randomize_page_resolve_definition:
        move.l  GK_RZ_PAGE(%a6),-(%sp)
        move.l  GK_RZ_TRACK(%a6),-(%sp)
        jsr     GK_STOCK_PAGE_DEFINITION_WRAPPER
        addq.l  #8,%sp
        rts
        .size   gk_randomize_page_resolve_definition,.-gk_randomize_page_resolve_definition
        .type   gk_randomize_page_live_enable,@function
gk_randomize_page_live_enable:
        move.l  GK_RZ_ROUTE(%a6),%d0
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_3,%d0
        beq.s   .Lgk_rz_enable_address
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_4,%d0
        bne.s   .Lgk_rz_enable_zero
.Lgk_rz_enable_address:
        movea.l GK_RZ_PAYLOAD(%a6),%a0
        move.l  GK_RZ_TRACK(%a6),%d1
        addi.l  #32,%d1
        lsl.l   #5,%d1
        adda.l  %d1,%a0
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_4,%d0
        bne.s   .Lgk_rz_enable_load
        addq.l  #1,%a0
.Lgk_rz_enable_load:
        moveq   #0,%d0
        move.b  (%a0),%d0
        rts
.Lgk_rz_enable_zero:
        moveq   #0,%d0
        rts
        .size   gk_randomize_page_live_enable,.-gk_randomize_page_live_enable
        .type   gk_randomize_page_expected_mask,@function
gk_randomize_page_expected_mask:
        move.l  GK_RZ_ROUTE(%a6),%d3
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_4,%d3
        bhi.w   .Lgk_rz_mask_zero
        movea.l GK_RZ_DEFINITION(%a6),%a0
        move.l  %a0,%d0
        beq.w   .Lgk_rz_mask_corrupt
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_0,%d3
        bcs.s   .Lgk_rz_mask_regular
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_2,%d3
        bls.s   .Lgk_rz_mask_special
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_0,%d3
        bcs.s   .Lgk_rz_mask_regular
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_2,%d3
        bhi.s   .Lgk_rz_mask_regular
.Lgk_rz_mask_special:
        lea     0x172(%a0),%a1
        moveq   #0,%d0
        moveq   #0,%d1
.Lgk_rz_mask_special_four:
        tst.l   (%a1)+
        beq.s   .Lgk_rz_mask_special_next
        moveq   #1,%d2
        lsl.l   %d1,%d2
        or.l    %d2,%d0
.Lgk_rz_mask_special_next:
        addq.l  #1,%d1
        cmpi.l  #4,%d1
        bcs.s   .Lgk_rz_mask_special_four
        move.l  GK_RZ_SELECTION(%a6),%d1
        cmpi.l  #2,%d1
        bhi.s   .Lgk_rz_mask_corrupt
        movea.l GK_RZ_DEFINITION(%a6),%a1
        adda.l  #0x15a,%a1
        lsl.l   #2,%d1
        adda.l  %d1,%a1
        tst.l   (%a1)
        beq.s   .Lgk_rz_mask_special_last
        ori.l   #0x10,%d0
.Lgk_rz_mask_special_last:
        tst.l   12(%a1)
        beq.s   .Lgk_rz_mask_ready
        ori.l   #0x20,%d0
        bra.s   .Lgk_rz_mask_ready
.Lgk_rz_mask_regular:
        lea     0x15a(%a0),%a1
        moveq   #0,%d0
        moveq   #0,%d1
.Lgk_rz_mask_regular_loop:
        tst.l   (%a1)+
        beq.s   .Lgk_rz_mask_regular_next
        moveq   #1,%d2
        lsl.l   %d1,%d2
        or.l    %d2,%d0
.Lgk_rz_mask_regular_next:
        addq.l  #1,%d1
        cmpi.l  #6,%d1
        bcs.s   .Lgk_rz_mask_regular_loop
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_3,%d3
        bcs.s   .Lgk_rz_mask_ready
        move.l  GK_RZ_ENABLE_BYTE(%a6),%d1
        andi.l  #0x3f,%d1
        and.l   %d1,%d0
.Lgk_rz_mask_ready:
        andi.l  #0x3f,%d0
        rts
.Lgk_rz_mask_zero:
        moveq   #0,%d0
        rts
.Lgk_rz_mask_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_randomize_page_expected_mask,.-gk_randomize_page_expected_mask
        .type   gk_randomize_page_first_expected,@function
gk_randomize_page_first_expected:
        moveq   #0,%d1
.Lgk_rz_first_loop:
        btst    %d1,%d0
        bne.s   .Lgk_rz_first_ready
        addq.l  #1,%d1
        cmpi.l  #6,%d1
        bcs.s   .Lgk_rz_first_loop
.Lgk_rz_first_ready:
        move.l  %d1,%d0
        rts
        .size   gk_randomize_page_first_expected,.-gk_randomize_page_first_expected
        .type   gk_randomize_page_capture_context,@function
gk_randomize_page_capture_context:
        tst.l   __gk_lifecycle_state
        bne.w   gk_randomize_page_private_fatal
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        tst.b   __gk_randomize_page_active
        bne.w   .Lgk_rz_claim_busy
        moveq   #GK_RZ_ACTIVE_VALUE,%d0
        move.b  %d0,__gk_randomize_page_active
        not.l   %d0
        move.b  %d0,__gk_randomize_page_active_inverse
        moveq   #-1,%d0
        move.b  %d0,__gk_randomize_page_part
        move.b  %d0,__gk_randomize_page_track
        move.w  %d1,%sr
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_randomize_page_private_fatal
        movea.l %d0,%a2
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   gk_randomize_page_private_fatal
        move.b  %d0,__gk_randomize_page_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_randomize_page_private_fatal
        movea.l %d0,%a3
        move.b  %d0,__gk_randomize_page_track
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_randomize_page_private_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_randomize_page_private_fatal
        move.l  %d4,GK_RZ_BANK(%a6)
        move.l  %d5,GK_RZ_PATTERN(%a6)
        move.l  %a2,GK_RZ_PART(%a6)
        move.l  %a3,GK_RZ_TRACK(%a6)
        move.l  %d6,GK_RZ_DESCRIPTOR(%a6)
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        move.l  %d0,GK_RZ_KIT(%a6)
        move.l  GK_STOCK_BANK_POINTER,%d0
        move.l  %d0,GK_RZ_BANK_POINTER(%a6)
        movea.l %d0,%a5
        moveq   #0,%d0
        move.b  GK_STOCK_RELOAD_PAGE,%d0
        move.l  %d0,GK_RZ_PAGE(%a6)
        move.l  GK_STOCK_RELOAD_PAGE_MODE,%d0
        move.l  %d0,GK_RZ_MODE(%a6)
        movea.l GK_STOCK_RELOAD_PAGE_OBJECT_POINTER,%a0
        move.l  %a0,%d0
        beq.w   gk_randomize_page_private_fatal
        move.l  %d0,GK_RZ_OBJECT_POINTER(%a6)
        move.l  8(%a0),%d0
        move.l  %d0,GK_RZ_OBJECT_FLAG(%a6)
        clr.l   GK_RZ_SELECTION(%a6)
        tst.l   %d0
        beq.s   .Lgk_rz_selection_captured
        move.l  GK_RZ_PAGE(%a6),%d1
        cmpi.l  #1,%d1
        bne.s   .Lgk_rz_selection_captured
        move.l  GK_STOCK_RELOAD_PAGE_SELECTION,%d0
        move.l  %d0,GK_RZ_SELECTION(%a6)
.Lgk_rz_selection_captured:
        rts
.Lgk_rz_claim_busy:
        move.w  %d1,%sr
        bra.w   gk_randomize_page_private_fatal
        .size   gk_randomize_page_capture_context,.-gk_randomize_page_capture_context
        .type   gk_randomize_page_prepare,@function
gk_randomize_page_prepare:
        bsr.w   gk_randomize_page_capture_context
        move.l  GK_RZ_BANK(%a6),%d0
        move.l  GK_RZ_PATTERN(%a6),%d1
        move.l  GK_RZ_KIT(%a6),%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_randomize_page_private_fatal
        cmp.l   GK_RZ_DESCRIPTOR(%a6),%d0
        bne.w   gk_randomize_page_abort_fatal
        cmp.l   GK_RZ_PART(%a6),%d1
        bne.w   gk_randomize_page_abort_fatal
        movea.l %a0,%a4
        move.l  GK_RZ_BANK(%a6),%d0
        move.l  GK_RZ_PART(%a6),%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_randomize_page_abort_fatal
        cmp.l   GK_RZ_DESCRIPTOR(%a6),%d0
        bne.w   gk_randomize_page_release_d0_abort_fatal
        cmpa.l  %a4,%a0
        bne.w   gk_randomize_page_release_abort_fatal
        move.l  GK_RZ_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        movea.l GK_RZ_BANK_POINTER(%a6),%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        cmpa.l  %a4,%a0
        bne.w   gk_randomize_page_release_abort_fatal
        move.l  %a4,GK_RZ_PAYLOAD(%a6)
        bsr.w   gk_randomize_page_classify
        move.l  %d0,GK_RZ_ROUTE(%a6)
        clr.l   GK_RZ_DEFINITION(%a6)
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_OBJECT_MODE_NO_WRITE,%d0
        beq.s   .Lgk_rz_definition_ready
        bsr.w   gk_randomize_page_resolve_definition
        move.l  %d0,GK_RZ_DEFINITION(%a6)
        move.l  GK_RZ_ROUTE(%a6),%d1
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_4,%d1
        bhi.s   .Lgk_rz_definition_ready
        tst.l   %d0
        beq.w   gk_randomize_page_release_abort_fatal
.Lgk_rz_definition_ready:
        bsr.w   gk_randomize_page_live_enable
        move.l  %d0,GK_RZ_ENABLE_BYTE(%a6)
        bsr.w   gk_randomize_page_expected_mask
        tst.l   %d0
        bmi.w   gk_randomize_page_release_abort_fatal
        move.l  %d0,GK_RZ_EXPECTED_MASK(%a6)
        clr.l   GK_RZ_OBSERVED_MASK(%a6)
        clr.l   GK_RZ_MARKER_COUNT(%a6)
        bsr.w   gk_randomize_page_first_expected
        move.l  %d0,GK_RZ_NEXT_INDEX(%a6)
        move.l  GK_RZ_DESCRIPTOR(%a6),%d0
        move.l  GK_RZ_BANK(%a6),%d1
        move.l  GK_RZ_PART(%a6),%d2
        move.l  GK_RZ_TRACK(%a6),%d3
        bsr.w   gk_randomize_page_context_token
        tst.l   %d0
        bmi.w   gk_randomize_page_release_abort_fatal
        move.l  %d0,GK_RZ_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_RZ_TOKEN_INVERSE(%a6)
        move.l  #GK_RZ_MAGIC_VALUE,%d0
        move.l  %d0,GK_RZ_MAGIC(%a6)
        not.l   %d0
        move.l  %d0,GK_RZ_MAGIC_INVERSE(%a6)
        movea.l GK_RZ_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  %d0,GK_RZ_OLD_BANK_EDITED(%a6)
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        move.l  %d0,GK_RZ_OLD_MIRROR_EDITED(%a6)
        movea.l GK_RZ_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),GK_RZ_OLD_BANK_DIRTY(%a6)
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        move.l  %d0,GK_RZ_OLD_GLOBAL_DIRTY(%a6)
        rts
        .size   gk_randomize_page_prepare,.-gk_randomize_page_prepare
        .type   gk_randomize_page_validate_current,@function
gk_randomize_page_validate_current:
        move.l  GK_RZ_MAGIC(%a6),%d0
        cmpi.l  #GK_RZ_MAGIC_VALUE,%d0
        bne.w   .Lgk_rz_validate_corrupt
        not.l   %d0
        cmp.l   GK_RZ_MAGIC_INVERSE(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  GK_RZ_DESCRIPTOR(%a6),%d0
        move.l  GK_RZ_BANK(%a6),%d1
        move.l  GK_RZ_PART(%a6),%d2
        move.l  GK_RZ_TRACK(%a6),%d3
        bsr.w   gk_randomize_page_context_token
        tst.l   %d0
        bmi.w   .Lgk_rz_validate_corrupt
        andi.l  #GK_RANDOMIZE_PAGE_TOKEN_CONTEXT_MASK,%d0
        move.l  GK_RZ_TOKEN(%a6),%d1
        move.l  %d1,%d2
        andi.l  #GK_RANDOMIZE_PAGE_TOKEN_CONTEXT_MASK,%d2
        cmp.l   %d2,%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  %d1,%d0
        andi.l  #GK_RANDOMIZE_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_RANDOMIZE_PAGE_TOKEN_ARMED,%d0
        beq.s   .Lgk_rz_validate_token_state
        cmpi.l  #GK_RANDOMIZE_PAGE_TOKEN_WRITTEN,%d0
        bne.w   .Lgk_rz_validate_corrupt
.Lgk_rz_validate_token_state:
        not.l   %d1
        cmp.l   GK_RZ_TOKEN_INVERSE(%a6),%d1
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_randomize_page_active,%d0
        cmpi.l  #GK_RZ_ACTIVE_VALUE,%d0
        bne.w   .Lgk_rz_validate_corrupt
        not.l   %d0
        andi.l  #0xff,%d0
        cmp.b   __gk_randomize_page_active_inverse,%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_randomize_page_part,%d0
        cmp.l   GK_RZ_PART(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_randomize_page_track,%d0
        cmp.l   GK_RZ_TRACK(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   GK_RZ_DESCRIPTOR(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   GK_RZ_BANK(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   GK_RZ_PATTERN(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   GK_RZ_KIT(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   GK_RZ_BANK(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   GK_RZ_BANK(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   GK_RZ_BANK(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   GK_RZ_PATTERN(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   GK_RZ_PATTERN(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   GK_RZ_PART(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   GK_RZ_PART(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   GK_RZ_PART(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmp.l   GK_RZ_TRACK(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  GK_STOCK_BANK_POINTER,%d0
        cmp.l   GK_RZ_BANK_POINTER(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_RELOAD_PAGE,%d0
        cmp.l   GK_RZ_PAGE(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  GK_STOCK_RELOAD_PAGE_MODE,%d0
        cmp.l   GK_RZ_MODE(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        movea.l GK_STOCK_RELOAD_PAGE_OBJECT_POINTER,%a0
        move.l  %a0,%d0
        cmp.l   GK_RZ_OBJECT_POINTER(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  8(%a0),%d0
        cmp.l   GK_RZ_OBJECT_FLAG(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        tst.l   %d0
        beq.s   .Lgk_rz_validate_selection
        move.l  GK_RZ_PAGE(%a6),%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_rz_validate_selection
        move.l  GK_STOCK_RELOAD_PAGE_SELECTION,%d0
        cmp.l   GK_RZ_SELECTION(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
.Lgk_rz_validate_selection:
        bsr.w   gk_randomize_page_classify
        cmp.l   GK_RZ_ROUTE(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  GK_RZ_BANK(%a6),%d0
        lsl.l   #2,%d0
        add.l   GK_RZ_PART(%a6),%d0
        jsr     gk_physical_validate
        cmp.l   GK_RZ_DESCRIPTOR(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  %a0,%d0
        cmp.l   GK_RZ_PAYLOAD(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  GK_RZ_ROUTE(%a6),%d1
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_OBJECT_MODE_NO_WRITE,%d1
        beq.s   .Lgk_rz_validate_definition_zero
        bsr.w   gk_randomize_page_resolve_definition
        cmp.l   GK_RZ_DEFINITION(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        bra.s   .Lgk_rz_validate_definition_ready
.Lgk_rz_validate_definition_zero:
        tst.l   GK_RZ_DEFINITION(%a6)
        bne.w   .Lgk_rz_validate_corrupt
.Lgk_rz_validate_definition_ready:
        bsr.w   gk_randomize_page_live_enable
        cmp.l   GK_RZ_ENABLE_BYTE(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        bsr.w   gk_randomize_page_expected_mask
        tst.l   %d0
        bmi.w   .Lgk_rz_validate_corrupt
        cmp.l   GK_RZ_EXPECTED_MASK(%a6),%d0
        bne.w   .Lgk_rz_validate_corrupt
        move.l  GK_RZ_OBSERVED_MASK(%a6),%d0
        andi.l  #0xffffffc0,%d0
        bne.s   .Lgk_rz_validate_corrupt
        move.l  GK_RZ_NEXT_INDEX(%a6),%d0
        cmpi.l  #6,%d0
        bhi.s   .Lgk_rz_validate_corrupt
        move.l  GK_RZ_MARKER_COUNT(%a6),%d0
        cmpi.l  #6,%d0
        bhi.s   .Lgk_rz_validate_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_rz_validate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_randomize_page_validate_current,.-gk_randomize_page_validate_current
        .type   gk_randomize_page_compare_payloads,@function
gk_randomize_page_compare_payloads:
        movea.l GK_RZ_PAYLOAD(%a6),%a0
        move.l  GK_RZ_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a1
        adda.l  %d0,%a1
        move.l  #1580,%d2
.Lgk_rz_compare_long:
        move.l  (%a0)+,%d0
        cmp.l   (%a1)+,%d0
        bne.s   .Lgk_rz_compare_miss
        subq.l  #1,%d2
        bne.s   .Lgk_rz_compare_long
        move.b  (%a0)+,%d0
        cmp.b   (%a1)+,%d0
        bne.s   .Lgk_rz_compare_miss
        move.b  (%a0),%d0
        cmp.b   (%a1),%d0
        bne.s   .Lgk_rz_compare_miss
        moveq   #GK_OK,%d0
        rts
.Lgk_rz_compare_miss:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_randomize_page_compare_payloads,.-gk_randomize_page_compare_payloads
        .type   gk_randomize_page_validate_result,@function
gk_randomize_page_validate_result:
        move.l  GK_RZ_EXPECTED_MASK(%a6),%d3
        cmp.l   GK_RZ_OBSERVED_MASK(%a6),%d3
        bne.w   .Lgk_rz_result_corrupt
        move.l  GK_RZ_NEXT_INDEX(%a6),%d0
        cmpi.l  #6,%d0
        bne.w   .Lgk_rz_result_corrupt
        moveq   #0,%d1
        moveq   #0,%d2
.Lgk_rz_result_popcount:
        btst    %d2,%d3
        beq.s   .Lgk_rz_result_popcount_next
        addq.l  #1,%d1
.Lgk_rz_result_popcount_next:
        addq.l  #1,%d2
        cmpi.l  #6,%d2
        bcs.s   .Lgk_rz_result_popcount
        cmp.l   GK_RZ_MARKER_COUNT(%a6),%d1
        bne.w   .Lgk_rz_result_corrupt
        tst.l   %d3
        beq.w   .Lgk_rz_result_no_write
        move.l  GK_RZ_TOKEN(%a6),%d0
        andi.l  #GK_RANDOMIZE_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_RANDOMIZE_PAGE_TOKEN_WRITTEN,%d0
        bne.w   .Lgk_rz_result_corrupt
        moveq   #1,%d1
        move.l  GK_RZ_PART(%a6),%d0
        lsl.l   %d0,%d1
        or.l    GK_RZ_OLD_BANK_EDITED(%a6),%d1
        movea.l GK_RZ_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_rz_result_corrupt
        moveq   #1,%d1
        move.l  GK_RZ_PART(%a6),%d0
        lsl.l   %d0,%d1
        or.l    GK_RZ_OLD_MIRROR_EDITED(%a6),%d1
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_rz_result_corrupt
        movea.l GK_RZ_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_rz_result_corrupt
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_rz_result_corrupt
        bra.s   .Lgk_rz_result_payload
.Lgk_rz_result_no_write:
        move.l  GK_RZ_TOKEN(%a6),%d0
        andi.l  #GK_RANDOMIZE_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_RANDOMIZE_PAGE_TOKEN_ARMED,%d0
        bne.s   .Lgk_rz_result_corrupt
        movea.l GK_RZ_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   GK_RZ_OLD_BANK_EDITED(%a6),%d0
        bne.s   .Lgk_rz_result_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        cmp.l   GK_RZ_OLD_MIRROR_EDITED(%a6),%d0
        bne.s   .Lgk_rz_result_corrupt
        movea.l GK_RZ_BANK_POINTER(%a6),%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        cmp.l   GK_RZ_OLD_BANK_DIRTY(%a6),%d0
        bne.s   .Lgk_rz_result_corrupt
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmp.l   GK_RZ_OLD_GLOBAL_DIRTY(%a6),%d0
        bne.s   .Lgk_rz_result_corrupt
.Lgk_rz_result_payload:
        bsr.w   gk_randomize_page_compare_payloads
        tst.l   %d0
        bne.s   .Lgk_rz_result_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_rz_result_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_randomize_page_validate_result,.-gk_randomize_page_validate_result
        .type   gk_randomize_page_return_stock,@function
gk_randomize_page_return_stock:
        bsr.w   gk_randomize_page_clear_private
        moveq   #0,%d2
        move.w  GK_RZ_OUTPUT_SR(%a6),%d2
        move.w  %d2,%sr
        move.l  GK_RZ_OUTPUT_D0(%a6),%d0
        move.l  GK_RZ_OUTPUT_D1(%a6),%d1
        movea.l GK_RZ_OUTPUT_A0(%a6),%a0
        movea.l GK_RZ_OUTPUT_A1(%a6),%a1
        movem.l (%a6),%d2-%d7/%a2-%a6
        lea     GK_RZ_FRAME_SIZE(%sp),%sp
        rts
        .size   gk_randomize_page_return_stock,.-gk_randomize_page_return_stock
        .type   gk_randomize_page_finish,@function
gk_randomize_page_finish:
        bsr.w   gk_randomize_page_validate_current
        tst.l   %d0
        bne.w   gk_randomize_page_release_abort_fatal
        bsr.w   gk_randomize_page_validate_result
        tst.l   %d0
        bne.w   gk_randomize_page_release_abort_fatal
        tst.l   GK_RZ_EXPECTED_MASK(%a6)
        beq.s   .Lgk_rz_finish_no_write
        move.l  GK_RZ_DESCRIPTOR(%a6),%d0
        move.l  GK_RZ_BANK(%a6),%d1
        move.l  GK_RZ_PATTERN(%a6),%d2
        move.l  GK_RZ_PART(%a6),%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_randomize_page_release_abort_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_randomize_page_release_abort_fatal
        bsr.w   gk_randomize_page_validate_current
        tst.l   %d0
        bne.w   gk_randomize_page_release_fatal
        move.l  GK_RZ_DESCRIPTOR(%a6),%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_randomize_page_private_fatal
        bra.w   gk_randomize_page_return_stock
.Lgk_rz_finish_no_write:
        move.l  GK_RZ_DESCRIPTOR(%a6),%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_randomize_page_private_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_randomize_page_private_fatal
        bra.w   gk_randomize_page_return_stock
        .size   gk_randomize_page_finish,.-gk_randomize_page_finish
        .global gk_stock_randomize_page_callback
        .type   gk_stock_randomize_page_callback,@function
gk_stock_randomize_page_callback:
        move.l  %d0,-(%sp)
        move.l  8(%sp),%d0
        cmpi.l  #0x31,%d0
        bne.w   gk_randomize_page_private_fatal
        tst.l   12(%sp)
        beq.w   gk_randomize_page_private_fatal
        .global gk_randomize_page_transition_defer_start
gk_randomize_page_transition_defer_start:
        moveq   #0,%d0
        move.b  __gk_ui_transition_pending,%d0
        beq.s   .Lgk_rz_transition_settled
        cmpi.b  #1,%d0
        bne.w   gk_randomize_page_private_fatal
        move.l  (%sp)+,%d0
        rts
.Lgk_rz_transition_settled:
        move.l  (%sp)+,%d0
        .global gk_randomize_page_transition_defer_end
gk_randomize_page_transition_defer_end:
        lea     -GK_RZ_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l  %d0,GK_RZ_INPUT_D0(%a6)
        move.l  %d1,GK_RZ_INPUT_D1(%a6)
        move.l  %a0,GK_RZ_INPUT_A0(%a6)
        move.l  %a1,GK_RZ_INPUT_A1(%a6)
        move.w  %sr,%d2
        move.w  %d2,GK_RZ_INPUT_SR(%a6)
        bsr.w   gk_randomize_page_prepare
        move.l  GK_RZ_FRAME_SIZE + 8(%a6),-(%sp)
        move.l  GK_RZ_FRAME_SIZE + 4(%a6),-(%sp)
        move.l  GK_RZ_INPUT_D0(%a6),%d0
        move.l  GK_RZ_INPUT_D1(%a6),%d1
        movea.l GK_RZ_INPUT_A0(%a6),%a0
        movea.l GK_RZ_INPUT_A1(%a6),%a1
        moveq   #0,%d2
        move.w  GK_RZ_INPUT_SR(%a6),%d2
        move.w  %d2,%sr
        .global gk_randomize_page_stock_call
gk_randomize_page_stock_call:
        jsr     GK_STOCK_RANDOMIZE_PAGE_WRITER
        addq.l  #8,%sp
        move.l %d0,GK_RZ_OUTPUT_D0(%a6)
        move.l %d1,GK_RZ_OUTPUT_D1(%a6)
        move.l %a0,GK_RZ_OUTPUT_A0(%a6)
        move.l %a1,GK_RZ_OUTPUT_A1(%a6)
        move.w %sr,%d0
        move.w %d0,GK_RZ_OUTPUT_SR(%a6)
        jmp     gk_randomize_page_finish
        .size   gk_stock_randomize_page_callback,.-gk_stock_randomize_page_callback
        .align  4
gk_randomize_page_regular_returns:
        .long   0x4005bb36
        .long   0x4005bc52
        .long   0x4005bd7a
        .long   0
        .long   0
        .long   0
        .long   0x4005c1ba
        .long   0x4005c2dc
        .long   0x4005c41a
        .long   0x4005c516
        .long   0x4005c618
        .long   0
        .long   0
        .long   0
        .long   0x4005ca38
        .long   0x4005cb66
        .global gk_randomize_page_marker_validate
        .type   gk_randomize_page_marker_validate,@function
gk_randomize_page_marker_validate:
        move.l  %d3,-(%sp)
        move.l  %d7,-(%sp)
        move.l  %a1,-(%sp)
        bsr.w   gk_randomize_page_validate_current
        movea.l (%sp)+,%a1
        move.l  (%sp)+,%d7
        move.l  (%sp)+,%d3
        tst.l   %d0
        bne.w   .Lgk_rzm_corrupt
        move.l  GK_RZ_ROUTE(%a6),%d4
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_4,%d4
        bhi.w   .Lgk_rzm_corrupt
        cmpi.l  #GK_RZM_SOURCE_D0,%d7
        bne.s   .Lgk_rzm_source_d2
        move.l  GK_RZM_D0(%a1),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_rzm_corrupt
        tst.l   %d4
        beq.w   .Lgk_rzm_corrupt
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_4,%d4
        bhi.w   .Lgk_rzm_corrupt
        bra.s   .Lgk_rzm_source_ready
.Lgk_rzm_source_d2:
        cmpi.l  #GK_RZM_SOURCE_D2,%d7
        bne.w   .Lgk_rzm_corrupt
        move.l  GK_RZM_D2(%a1),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_rzm_corrupt
        tst.l   %d4
        beq.s   .Lgk_rzm_source_ready
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_0,%d4
        bcs.w   .Lgk_rzm_corrupt
.Lgk_rzm_source_ready:
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_0,%d4
        bcs.s   .Lgk_rzm_regular
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_AUDIO_PAGE_1_SPECIAL_2,%d4
        bls.s   .Lgk_rzm_special_audio
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_0,%d4
        bcs.s   .Lgk_rzm_regular
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_1_SPECIAL_2,%d4
        bhi.s   .Lgk_rzm_regular
        bra.s   .Lgk_rzm_special_midi
.Lgk_rzm_regular:
        move.l  %d4,%d0
        lsl.l   #2,%d0
        lea     gk_randomize_page_regular_returns,%a0
        move.l  (%a0,%d0.l),%d0
        beq.w   .Lgk_rzm_corrupt
        cmp.l   %d3,%d0
        bne.w   .Lgk_rzm_corrupt
        tst.l   %d4
        bne.s   .Lgk_rzm_regular_not_audio_zero
        move.l  GK_RZM_D6(%a1),%d5
        bra.w   .Lgk_rzm_candidate_ready
.Lgk_rzm_regular_not_audio_zero:
        cmpi.l  #GK_RANDOMIZE_PAGE_ROUTE_MIDI_PAGE_3,%d4
        bcs.s   .Lgk_rzm_regular_a2
        move.l  GK_RZM_D4(%a1),%d5
        bra.w   .Lgk_rzm_candidate_ready
.Lgk_rzm_regular_a2:
        move.l  GK_RZM_A2(%a1),%d5
        bra.w   .Lgk_rzm_candidate_ready
.Lgk_rzm_special_audio:
        cmpi.l  #0x4005beb2,%d3
        beq.s   .Lgk_rzm_special_first_a
        cmpi.l  #0x4005bf76,%d3
        beq.s   .Lgk_rzm_special_first_b
        cmpi.l  #0x4005c08e,%d3
        beq.s   .Lgk_rzm_special_pair
        bra.w   .Lgk_rzm_corrupt
.Lgk_rzm_special_midi:
        cmpi.l  #0x4005c740,%d3
        beq.s   .Lgk_rzm_special_first_a
        cmpi.l  #0x4005c804,%d3
        beq.s   .Lgk_rzm_special_first_b
        cmpi.l  #0x4005c90a,%d3
        beq.s   .Lgk_rzm_special_pair
        bra.w   .Lgk_rzm_corrupt
.Lgk_rzm_special_first_a:
        move.l  GK_RZM_D5(%a1),%d5
        cmpi.l  #1,%d5
        bhi.w   .Lgk_rzm_corrupt
        bra.s   .Lgk_rzm_candidate_ready
.Lgk_rzm_special_first_b:
        move.l  GK_RZM_D5(%a1),%d5
        cmpi.l  #2,%d5
        bcs.w   .Lgk_rzm_corrupt
        cmpi.l  #3,%d5
        bhi.w   .Lgk_rzm_corrupt
        bra.s   .Lgk_rzm_candidate_ready
.Lgk_rzm_special_pair:
        move.l  GK_RZM_A2(%a1),%d0
        move.l  GK_RZ_SELECTION(%a6),%d1
        cmp.l   %d1,%d0
        beq.s   .Lgk_rzm_special_pair_first
        addq.l  #3,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_rzm_corrupt
        moveq   #5,%d5
        bra.s   .Lgk_rzm_candidate_ready
.Lgk_rzm_special_pair_first:
        moveq   #4,%d5
.Lgk_rzm_candidate_ready:
        cmpi.l  #5,%d5
        bhi.w   .Lgk_rzm_corrupt
        cmp.l   GK_RZ_NEXT_INDEX(%a6),%d5
        bne.w   .Lgk_rzm_corrupt
        moveq   #1,%d0
        lsl.l   %d5,%d0
        move.l  GK_RZ_EXPECTED_MASK(%a6),%d1
        move.l  %d1,%d2
        and.l   %d0,%d2
        beq.w   .Lgk_rzm_corrupt
        move.l  GK_RZ_OBSERVED_MASK(%a6),%d2
        move.l  %d2,%d3
        and.l   %d0,%d3
        bne.w   .Lgk_rzm_corrupt
        or.l    %d0,%d2
        move.l  %d2,GK_RZ_OBSERVED_MASK(%a6)
        move.l  GK_RZ_MARKER_COUNT(%a6),%d0
        cmpi.l  #5,%d0
        bhi.w   .Lgk_rzm_corrupt
        addq.l  #1,%d0
        move.l  %d0,GK_RZ_MARKER_COUNT(%a6)
        addq.l  #1,%d5
.Lgk_rzm_next_loop:
        cmpi.l  #6,%d5
        bhs.s   .Lgk_rzm_next_ready
        btst    %d5,%d1
        bne.s   .Lgk_rzm_next_ready
        addq.l  #1,%d5
        bra.s   .Lgk_rzm_next_loop
.Lgk_rzm_next_ready:
        move.l  %d5,GK_RZ_NEXT_INDEX(%a6)
        move.l  GK_RZ_TOKEN(%a6),%d0
        andi.l  #GK_RANDOMIZE_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_RANDOMIZE_PAGE_TOKEN_WRITTEN,%d0
        beq.s   .Lgk_rzm_ok
        cmpi.l  #GK_RANDOMIZE_PAGE_TOKEN_ARMED,%d0
        bne.s   .Lgk_rzm_corrupt
        move.l  GK_RZ_TOKEN(%a6),%d0
        andi.l  #GK_RANDOMIZE_PAGE_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_RANDOMIZE_PAGE_TOKEN_WRITTEN,%d0
        move.l  %d0,GK_RZ_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_RZ_TOKEN_INVERSE(%a6)
.Lgk_rzm_ok:
        moveq   #GK_OK,%d0
        rts
.Lgk_rzm_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_randomize_page_marker_validate,.-gk_randomize_page_marker_validate
        .global gk_randomize_page_write_marker_d0
        .type gk_randomize_page_write_marker_d0,@function
gk_randomize_page_write_marker_d0:
        lea -GK_RZM_SAVED_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        lea GK_RZM_FRAME(%sp),%a6
        movea.l %sp,%a1
        move.l GK_RZM_RETURN(%sp),%d3
        moveq #GK_RZM_SOURCE_D0,%d7
        bsr.w gk_randomize_page_marker_validate
        tst.l %d0
        bne.w gk_randomize_page_marker_fatal
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea GK_RZM_SAVED_BYTES(%sp),%sp
        .global gk_randomize_page_stock_dirty_store_d0
gk_randomize_page_stock_dirty_store_d0:
        .incbin "stock/0337.bin", 0, 6
        rts
        .size gk_randomize_page_write_marker_d0,.-gk_randomize_page_write_marker_d0
        .global gk_randomize_page_write_marker_d2
        .type gk_randomize_page_write_marker_d2,@function
gk_randomize_page_write_marker_d2:
        lea -GK_RZM_SAVED_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        lea GK_RZM_FRAME(%sp),%a6
        movea.l %sp,%a1
        move.l GK_RZM_RETURN(%sp),%d3
        moveq #GK_RZM_SOURCE_D2,%d7
        bsr.w gk_randomize_page_marker_validate
        tst.l %d0
        bne.w gk_randomize_page_marker_fatal
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea GK_RZM_SAVED_BYTES(%sp),%sp
        .global gk_randomize_page_stock_dirty_store_d2
gk_randomize_page_stock_dirty_store_d2:
        .incbin "stock/0338.bin", 0, 6
        rts
        .size gk_randomize_page_write_marker_d2,.-gk_randomize_page_write_marker_d2
        .global gk_randomize_page_fatal
gk_randomize_page_fatal:
        illegal
        bra.s   gk_randomize_page_fatal
