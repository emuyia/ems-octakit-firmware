        .include "abi.inc"
        .equ    GK_PC_FRAME_SIZE,208
        .equ    GK_PC_INPUT_D0,44
        .equ    GK_PC_INPUT_D1,48
        .equ    GK_PC_INPUT_A0,52
        .equ    GK_PC_INPUT_A1,56
        .equ    GK_PC_INPUT_SR,60
        .equ    GK_PC_OUTPUT_D0,64
        .equ    GK_PC_OUTPUT_D1,68
        .equ    GK_PC_OUTPUT_A0,72
        .equ    GK_PC_OUTPUT_A1,76
        .equ    GK_PC_OUTPUT_SR,80
        .equ    GK_PC_KIND,84
        .equ    GK_PC_BANK,88
        .equ    GK_PC_PATTERN,92
        .equ    GK_PC_PART,96
        .equ    GK_PC_TRACK,100
        .equ    GK_PC_DESCRIPTOR,104
        .equ    GK_PC_PAYLOAD,108
        .equ    GK_PC_BANK_POINTER,112
        .equ    GK_PC_PAGE,116
        .equ    GK_PC_MODE,120
        .equ    GK_PC_KIT,124
        .equ    GK_PC_ROUTE,128
        .equ    GK_PC_OUTCOME,132
        .equ    GK_PC_TOKEN,136
        .equ    GK_PC_TOKEN_INVERSE,140
        .equ    GK_PC_MAGIC,144
        .equ    GK_PC_MAGIC_INVERSE,148
        .equ    GK_PC_OLD_BANK_EDITED,152
        .equ    GK_PC_OLD_MIRROR_EDITED,156
        .equ    GK_PC_OLD_BANK_DIRTY,160
        .equ    GK_PC_OLD_GLOBAL_DIRTY,164
        .equ    GK_PC_PRIMARY_COUNT,168
        .equ    GK_PC_HELPER_COUNT,172
        .equ    GK_PC_EXPECTED_COUNT,176
        .equ    GK_PC_PRE_UNDO_TAG,180
        .equ    GK_PC_PRE_UNDO_ACTION,184
        .equ    GK_PC_PRE_COPY_TAG,188
        .equ    GK_PC_MAGIC_VALUE,0x5043464d
        .equ    GK_PCM_SAVED_BYTES,44
        .equ    GK_PCM_RETURN,44
        .equ    GK_PCM_CLEAR_FRAME,104
        .equ    GK_PCM_PASTE_RESTORE_FRAME,176
        .equ    GK_PCM_CLEAR_RESTORE_FRAME,220
        .equ    GK_PCM_PASTE_HELPER_FRAME,212
        .equ    GK_PCM_CLEAR_HELPER_FRAME,256
        .section .runtime,"ax"
        .align  4
        .type   gk_page_clipboard_clear_private,@function
gk_page_clipboard_clear_private:
        clr.l   __gk_page_clipboard_state_start
        rts
        .size   gk_page_clipboard_clear_private,.-gk_page_clipboard_clear_private
        .type   gk_page_clipboard_private_fatal,@function
gk_page_clipboard_private_fatal:
        bsr.w   gk_page_clipboard_clear_private
        bra.w   gk_page_clipboard_fatal
        .size   gk_page_clipboard_private_fatal,.-gk_page_clipboard_private_fatal
        .type   gk_page_clipboard_abort_fatal,@function
gk_page_clipboard_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_page_clipboard_private_fatal
        bra.w   gk_page_clipboard_private_fatal
        .size   gk_page_clipboard_abort_fatal,.-gk_page_clipboard_abort_fatal
        .type   gk_page_clipboard_release_d0_abort_fatal,@function
gk_page_clipboard_release_d0_abort_fatal:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_page_clipboard_private_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_page_clipboard_private_fatal
        bra.w   gk_page_clipboard_abort_fatal
        .size   gk_page_clipboard_release_d0_abort_fatal,.-gk_page_clipboard_release_d0_abort_fatal
        .type   gk_page_clipboard_release_abort_fatal,@function
gk_page_clipboard_release_abort_fatal:
        move.l  %d6,%d0
        bra.w   gk_page_clipboard_release_d0_abort_fatal
        .size   gk_page_clipboard_release_abort_fatal,.-gk_page_clipboard_release_abort_fatal
        .type   gk_page_clipboard_release_fatal,@function
gk_page_clipboard_release_fatal:
        move.l  %d6,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_page_clipboard_private_fatal
        jsr     gk_descriptor_release
        bra.w   gk_page_clipboard_private_fatal
        .size   gk_page_clipboard_release_fatal,.-gk_page_clipboard_release_fatal
        .type   gk_page_clipboard_marker_fatal,@function
gk_page_clipboard_marker_fatal:
        move.l  GK_PC_DESCRIPTOR(%a0),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_page_clipboard_private_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_page_clipboard_private_fatal
        bra.w   gk_page_clipboard_abort_fatal
        .size   gk_page_clipboard_marker_fatal,.-gk_page_clipboard_marker_fatal
        .type   gk_page_clipboard_expected_tag,@function
gk_page_clipboard_expected_tag:
        move.l  GK_PC_PAGE(%a0),%d0
        cmpi.l  #4,%d0
        bhi.s   .Lgk_pc_tag_invalid
        tst.l   GK_PC_MODE(%a0)
        bne.s   .Lgk_pc_tag_midi
        lea     .Lgk_pc_audio_tags,%a1
        bra.s   .Lgk_pc_tag_load
.Lgk_pc_tag_midi:
        lea     .Lgk_pc_midi_tags,%a1
.Lgk_pc_tag_load:
        moveq   #0,%d1
        move.b  (%a1,%d0.l),%d1
        move.l  %d1,%d0
        rts
.Lgk_pc_tag_invalid:
        moveq   #-1,%d0
        rts
        .align  2
.Lgk_pc_audio_tags:
        .byte   0x1a,0x1c,0x1b,0x1d,0x1d
.Lgk_pc_midi_tags:
        .byte   0x1e,0x20,0x1f,0x21,0x22
        .align  2
        .size   gk_page_clipboard_expected_tag,.-gk_page_clipboard_expected_tag
        .type   gk_page_clipboard_undo_matches,@function
gk_page_clipboard_undo_matches:
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        bsr.w   gk_page_clipboard_expected_tag
        tst.l   %d0
        bmi.s   .Lgk_pc_undo_miss
        cmp.l   GK_STOCK_UNDO_TAG,%d0
        bne.s   .Lgk_pc_undo_miss
        cmp.l   GK_STOCK_UNDO_ACTION,%d2
        bne.s   .Lgk_pc_undo_miss
        move.l  GK_PC_TRACK(%a0),%d0
        cmp.l   GK_STOCK_PAGE_UNDO_TRACK,%d0
        bne.s   .Lgk_pc_undo_miss
        move.l  GK_PC_PART(%a0),%d0
        cmp.l   GK_STOCK_UNDO_PART,%d0
        bne.s   .Lgk_pc_undo_miss
        move.l  GK_PC_PAGE(%a0),%d0
        cmp.l   GK_STOCK_PAGE_UNDO_PAGE,%d0
        bne.s   .Lgk_pc_undo_miss
        move.l  GK_PC_MODE(%a0),%d0
        cmp.l   GK_STOCK_PAGE_UNDO_MODE,%d0
        bne.s   .Lgk_pc_undo_miss
        moveq   #1,%d0
        bra.s   .Lgk_pc_undo_restore
.Lgk_pc_undo_miss:
        moveq   #0,%d0
.Lgk_pc_undo_restore:
        move.l  (%sp)+,%d2
        rts
        .size   gk_page_clipboard_undo_matches,.-gk_page_clipboard_undo_matches
        .type   gk_page_clipboard_classify,@function
gk_page_clipboard_classify:
        move.l  GK_PC_PAGE(%a0),%d0
        cmpi.l  #4,%d0
        bhi.w   .Lgk_pc_classify_out_of_range
        move.l  GK_PC_KIND(%a0),%d0
        cmpi.l  #GK_PAGE_CLIPBOARD_CLEAR,%d0
        beq.s   .Lgk_pc_classify_clear
        cmpi.l  #GK_PAGE_CLIPBOARD_PASTE,%d0
        bne.w   .Lgk_pc_classify_corrupt
        moveq   #0x2d,%d0
        bsr.w   gk_page_clipboard_undo_matches
        tst.l   %d0
        bne.s   .Lgk_pc_classify_paste_undo
        bsr.w   gk_page_clipboard_expected_tag
        cmp.l   GK_STOCK_PASTE_TAG,%d0
        beq.s   .Lgk_pc_classify_paste_copy
        moveq   #GK_PAGE_OUTCOME_PASTE_NONE,%d0
        move.l  %d0,GK_PC_OUTCOME(%a0)
        moveq   #GK_PAGE_ROUTE_NO_WRITE,%d0
        move.l  %d0,GK_PC_ROUTE(%a0)
        rts
.Lgk_pc_classify_paste_undo:
        moveq   #GK_PAGE_OUTCOME_PASTE_UNDO,%d0
        move.l  %d0,GK_PC_OUTCOME(%a0)
        bra.s   .Lgk_pc_classify_restore_route
.Lgk_pc_classify_paste_copy:
        moveq   #GK_PAGE_OUTCOME_PASTE_COPY,%d0
        move.l  %d0,GK_PC_OUTCOME(%a0)
        bra.s   .Lgk_pc_classify_restore_route
.Lgk_pc_classify_clear:
        moveq   #0x2e,%d0
        bsr.w   gk_page_clipboard_undo_matches
        tst.l   %d0
        beq.s   .Lgk_pc_classify_clear_new
        moveq   #GK_PAGE_OUTCOME_CLEAR_UNDO,%d0
        move.l  %d0,GK_PC_OUTCOME(%a0)
        bra.s   .Lgk_pc_classify_restore_route
.Lgk_pc_classify_clear_new:
        moveq   #GK_PAGE_OUTCOME_CLEAR_NEW,%d0
        move.l  %d0,GK_PC_OUTCOME(%a0)
        move.l  GK_PC_PAGE(%a0),%d0
        tst.l   GK_PC_MODE(%a0)
        beq.s   .Lgk_pc_classify_clear_audio
        addq.l  #5,%d0
.Lgk_pc_classify_clear_audio:
        addi.l  #GK_PAGE_ROUTE_CLEAR_AUDIO_0,%d0
        move.l  %d0,GK_PC_ROUTE(%a0)
        rts
.Lgk_pc_classify_restore_route:
        move.l  GK_PC_PAGE(%a0),%d0
        tst.l   GK_PC_MODE(%a0)
        beq.s   .Lgk_pc_classify_restore_ready
        addq.l  #5,%d0
.Lgk_pc_classify_restore_ready:
        move.l  %d0,GK_PC_ROUTE(%a0)
        rts
.Lgk_pc_classify_out_of_range:
        move.l  GK_PC_KIND(%a0),%d0
        cmpi.l  #GK_PAGE_CLIPBOARD_CLEAR,%d0
        bne.s   .Lgk_pc_classify_out_paste
        moveq   #GK_PAGE_OUTCOME_CLEAR_NONE,%d0
        bra.s   .Lgk_pc_classify_out_store
.Lgk_pc_classify_out_paste:
        cmpi.l  #GK_PAGE_CLIPBOARD_PASTE,%d0
        bne.s   .Lgk_pc_classify_corrupt
        moveq   #GK_PAGE_OUTCOME_PASTE_NONE,%d0
.Lgk_pc_classify_out_store:
        move.l  %d0,GK_PC_OUTCOME(%a0)
        moveq   #GK_PAGE_ROUTE_NO_WRITE,%d0
        move.l  %d0,GK_PC_ROUTE(%a0)
        rts
.Lgk_pc_classify_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_page_clipboard_classify,.-gk_page_clipboard_classify
        .type   gk_page_clipboard_context_token,@function
gk_page_clipboard_context_token:
        move.l  GK_PC_DESCRIPTOR(%a0),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_pc_token_corrupt
        move.l  GK_PC_TRACK(%a0),%d1
        cmpi.l  #7,%d1
        bhi.s   .Lgk_pc_token_corrupt
        lsl.l   #7,%d1
        or.l    %d1,%d0
        move.l  GK_PC_PART(%a0),%d1
        cmpi.l  #3,%d1
        bhi.s   .Lgk_pc_token_corrupt
        lsl.l   #8,%d1
        lsl.l   #2,%d1
        or.l    %d1,%d0
        move.l  GK_PC_BANK(%a0),%d1
        cmpi.l  #15,%d1
        bhi.s   .Lgk_pc_token_corrupt
        lsl.l   #8,%d1
        lsl.l   #4,%d1
        or.l    %d1,%d0
        ori.l   #GK_PAGE_TOKEN_ARMED,%d0
        rts
.Lgk_pc_token_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_page_clipboard_context_token,.-gk_page_clipboard_context_token
        .type   gk_page_clipboard_capture_context,@function
gk_page_clipboard_capture_context:
        tst.l   __gk_lifecycle_state
        bne.w   gk_page_clipboard_fatal
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        tst.b   __gk_page_clipboard_active
        bne.w   .Lgk_pc_claim_busy
        move.l  GK_PC_KIND(%a6),%d0
        move.b  %d0,__gk_page_clipboard_active
        not.l   %d0
        move.b  %d0,__gk_page_clipboard_active_inverse
        moveq   #-1,%d0
        move.b  %d0,__gk_page_clipboard_part
        move.b  %d0,__gk_page_clipboard_track
        move.w  %d1,%sr
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_page_clipboard_private_fatal
        movea.l %d0,%a2
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   gk_page_clipboard_private_fatal
        move.b  %d0,__gk_page_clipboard_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_page_clipboard_private_fatal
        movea.l %d0,%a3
        move.b  %d0,__gk_page_clipboard_track
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_page_clipboard_private_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_page_clipboard_private_fatal
        move.l  %d4,GK_PC_BANK(%a6)
        move.l  %d5,GK_PC_PATTERN(%a6)
        move.l  %a2,GK_PC_PART(%a6)
        move.l  %a3,GK_PC_TRACK(%a6)
        move.l  %d6,GK_PC_DESCRIPTOR(%a6)
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        move.l  %d0,GK_PC_KIT(%a6)
        move.l  GK_STOCK_BANK_POINTER,%d0
        move.l  %d0,GK_PC_BANK_POINTER(%a6)
        movea.l %d0,%a5
        moveq   #0,%d0
        move.b  GK_STOCK_PAGE_SELECTOR,%d0
        move.l  %d0,GK_PC_PAGE(%a6)
        move.l  GK_STOCK_TRACK_MODE,%d0
        move.l  %d0,GK_PC_MODE(%a6)
        move.l  GK_STOCK_UNDO_TAG,%d0
        move.l  %d0,GK_PC_PRE_UNDO_TAG(%a6)
        move.l  GK_STOCK_UNDO_ACTION,%d0
        move.l  %d0,GK_PC_PRE_UNDO_ACTION(%a6)
        move.l  GK_STOCK_PASTE_TAG,%d0
        move.l  %d0,GK_PC_PRE_COPY_TAG(%a6)
        rts
.Lgk_pc_claim_busy:
        move.w  %d1,%sr
        bra.w   gk_page_clipboard_fatal
        .size   gk_page_clipboard_capture_context,.-gk_page_clipboard_capture_context
        .type   gk_page_clipboard_prepare,@function
gk_page_clipboard_prepare:
        bsr.w   gk_page_clipboard_capture_context
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  GK_PC_KIT(%a6),%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_page_clipboard_private_fatal
        cmp.l   %d6,%d0
        bne.w   gk_page_clipboard_abort_fatal
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_page_clipboard_abort_fatal
        movea.l %a0,%a4
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_page_clipboard_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_page_clipboard_release_d0_abort_fatal
        cmpa.l  %a4,%a0
        bne.w   gk_page_clipboard_release_abort_fatal
        move.l  %a2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        movea.l %a5,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        cmpa.l  %a4,%a0
        bne.w   gk_page_clipboard_release_abort_fatal
        move.l  %a4,GK_PC_PAYLOAD(%a6)
        movea.l %a6,%a0
        bsr.w   gk_page_clipboard_classify
        tst.l   %d0
        bmi.w   gk_page_clipboard_release_abort_fatal
        move.l  GK_PC_ROUTE(%a6),%d7
        cmpi.l  #GK_PAGE_ROUTE_NO_WRITE,%d7
        bhi.w   gk_page_clipboard_release_abort_fatal
        clr.l   GK_PC_PRIMARY_COUNT(%a6)
        clr.l   GK_PC_HELPER_COUNT(%a6)
        clr.l   GK_PC_EXPECTED_COUNT(%a6)
        cmpi.l  #GK_PAGE_ROUTE_NO_WRITE,%d7
        beq.s   .Lgk_pc_prepare_count_ready
        lea     gk_page_clipboard_expected_counts,%a0
        moveq   #0,%d0
        move.b  (%a0,%d7.l),%d0
        move.l  %d0,GK_PC_EXPECTED_COUNT(%a6)
.Lgk_pc_prepare_count_ready:
        movea.l %a6,%a0
        bsr.w   gk_page_clipboard_context_token
        tst.l   %d0
        bmi.w   gk_page_clipboard_release_abort_fatal
        move.l  %d0,GK_PC_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_PC_TOKEN_INVERSE(%a6)
        move.l  #GK_PC_MAGIC_VALUE,%d0
        move.l  %d0,GK_PC_MAGIC(%a6)
        not.l   %d0
        move.l  %d0,GK_PC_MAGIC_INVERSE(%a6)
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  %d0,GK_PC_OLD_BANK_EDITED(%a6)
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        move.l  %d0,GK_PC_OLD_MIRROR_EDITED(%a6)
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),GK_PC_OLD_BANK_DIRTY(%a6)
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        move.l  %d0,GK_PC_OLD_GLOBAL_DIRTY(%a6)
        rts
        .size   gk_page_clipboard_prepare,.-gk_page_clipboard_prepare
        .type   gk_page_clipboard_validate_frame,@function
gk_page_clipboard_validate_frame:
        lea     -12(%sp),%sp
        movem.l %d2-%d3/%a2,(%sp)
        movea.l %a0,%a2
        move.l  GK_PC_MAGIC(%a2),%d0
        cmpi.l  #GK_PC_MAGIC_VALUE,%d0
        bne.w   .Lgk_pc_validate_corrupt
        not.l   %d0
        cmp.l   GK_PC_MAGIC_INVERSE(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        movea.l %a2,%a0
        bsr.w   gk_page_clipboard_context_token
        tst.l   %d0
        bmi.w   .Lgk_pc_validate_corrupt
        andi.l  #GK_PAGE_TOKEN_CONTEXT_MASK,%d0
        move.l  GK_PC_TOKEN(%a2),%d1
        move.l  %d1,%d2
        andi.l  #GK_PAGE_TOKEN_CONTEXT_MASK,%d2
        cmp.l   %d2,%d0
        bne.w   .Lgk_pc_validate_corrupt
        move.l  %d1,%d0
        andi.l  #GK_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_PAGE_TOKEN_ARMED,%d0
        beq.s   .Lgk_pc_validate_token_state
        cmpi.l  #GK_PAGE_TOKEN_WRITTEN,%d0
        bne.w   .Lgk_pc_validate_corrupt
.Lgk_pc_validate_token_state:
        not.l   %d1
        cmp.l   GK_PC_TOKEN_INVERSE(%a2),%d1
        bne.w   .Lgk_pc_validate_corrupt
        move.l  GK_PC_KIND(%a2),%d2
        cmpi.l  #GK_PAGE_CLIPBOARD_CLEAR,%d2
        beq.s   .Lgk_pc_validate_kind_clear
        cmpi.l  #GK_PAGE_CLIPBOARD_PASTE,%d2
        bne.w   .Lgk_pc_validate_corrupt
        move.l  GK_PC_OUTCOME(%a2),%d0
        cmpi.l  #GK_PAGE_OUTCOME_PASTE_UNDO,%d0
        beq.s   .Lgk_pc_validate_kind_ready
        cmpi.l  #GK_PAGE_OUTCOME_PASTE_COPY,%d0
        beq.s   .Lgk_pc_validate_kind_ready
        cmpi.l  #GK_PAGE_OUTCOME_PASTE_NONE,%d0
        bne.w   .Lgk_pc_validate_corrupt
        bra.s   .Lgk_pc_validate_kind_ready
.Lgk_pc_validate_kind_clear:
        move.l  GK_PC_OUTCOME(%a2),%d0
        cmpi.l  #GK_PAGE_OUTCOME_CLEAR_UNDO,%d0
        beq.s   .Lgk_pc_validate_kind_ready
        cmpi.l  #GK_PAGE_OUTCOME_CLEAR_NEW,%d0
        beq.s   .Lgk_pc_validate_kind_ready
        cmpi.l  #GK_PAGE_OUTCOME_CLEAR_NONE,%d0
        bne.w   .Lgk_pc_validate_corrupt
.Lgk_pc_validate_kind_ready:
        move.l  GK_PC_ROUTE(%a2),%d0
        cmpi.l  #GK_PAGE_ROUTE_NO_WRITE,%d0
        bhi.w   .Lgk_pc_validate_corrupt
        move.l  GK_PC_OUTCOME(%a2),%d1
        cmpi.l  #GK_PAGE_OUTCOME_CLEAR_NEW,%d1
        beq.s   .Lgk_pc_validate_clear_route
        cmpi.l  #GK_PAGE_OUTCOME_CLEAR_NONE,%d1
        beq.s   .Lgk_pc_validate_none_route
        cmpi.l  #GK_PAGE_OUTCOME_PASTE_NONE,%d1
        beq.s   .Lgk_pc_validate_none_route
        cmpi.l  #GK_PAGE_ROUTE_RESTORE_MIDI_4,%d0
        bhi.w   .Lgk_pc_validate_corrupt
        bra.s   .Lgk_pc_validate_route_ready
.Lgk_pc_validate_clear_route:
        cmpi.l  #GK_PAGE_ROUTE_CLEAR_AUDIO_0,%d0
        bcs.w   .Lgk_pc_validate_corrupt
        cmpi.l  #GK_PAGE_ROUTE_CLEAR_MIDI_4,%d0
        bhi.w   .Lgk_pc_validate_corrupt
        bra.s   .Lgk_pc_validate_route_ready
.Lgk_pc_validate_none_route:
        cmpi.l  #GK_PAGE_ROUTE_NO_WRITE,%d0
        bne.w   .Lgk_pc_validate_corrupt
.Lgk_pc_validate_route_ready:
        moveq   #0,%d0
        move.b  __gk_page_clipboard_active,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_pc_validate_corrupt
        not.l   %d0
        andi.l  #0xff,%d0
        cmp.b   __gk_page_clipboard_active_inverse,%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_page_clipboard_part,%d0
        cmp.l   GK_PC_PART(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_page_clipboard_track,%d0
        cmp.l   GK_PC_TRACK(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   GK_PC_DESCRIPTOR(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   GK_PC_BANK(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   GK_PC_PATTERN(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   GK_PC_KIT(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   GK_PC_BANK(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   GK_PC_BANK(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   GK_PC_BANK(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   GK_PC_PATTERN(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   GK_PC_PATTERN(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   GK_PC_PART(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   GK_PC_PART(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   GK_PC_PART(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmp.l   GK_PC_TRACK(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_PAGE_SELECTOR,%d0
        cmp.l   GK_PC_PAGE(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        move.l  GK_STOCK_TRACK_MODE,%d0
        cmp.l   GK_PC_MODE(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        move.l  GK_STOCK_BANK_POINTER,%d0
        cmp.l   GK_PC_BANK_POINTER(%a2),%d0
        bne.w   .Lgk_pc_validate_corrupt
        move.l  GK_PC_BANK(%a2),%d0
        lsl.l   #2,%d0
        add.l   GK_PC_PART(%a2),%d0
        jsr     gk_physical_validate
        cmp.l   GK_PC_DESCRIPTOR(%a2),%d0
        bne.s   .Lgk_pc_validate_corrupt
        move.l  %a0,%d0
        cmp.l   GK_PC_PAYLOAD(%a2),%d0
        bne.s   .Lgk_pc_validate_corrupt
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pc_validate_restore
.Lgk_pc_validate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_pc_validate_restore:
        movea.l %a2,%a0
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        rts
        .size   gk_page_clipboard_validate_frame,.-gk_page_clipboard_validate_frame
        .type   gk_page_clipboard_primary_marker_validate,@function
gk_page_clipboard_primary_marker_validate:
        movea.l %a0,%a2
        move.l  %d3,%d7
        bsr.w   gk_page_clipboard_validate_frame
        tst.l   %d0
        bne.w   .Lgk_pcm_primary_corrupt
        move.l  GK_PC_ROUTE(%a2),%d4
        cmpi.l  #GK_PAGE_ROUTE_CLEAR_MIDI_4,%d4
        bhi.w   .Lgk_pcm_primary_corrupt
        move.l  GK_PC_PRIMARY_COUNT(%a2),%d5
        moveq   #0,%d0
        lea     gk_page_clipboard_expected_counts,%a0
        move.b  (%a0,%d4.l),%d0
        cmp.l   %d0,%d5
        bhs.w   .Lgk_pcm_primary_corrupt
        cmp.l   GK_PC_EXPECTED_COUNT(%a2),%d0
        bne.w   .Lgk_pcm_primary_corrupt
        move.l  %d5,%d1
        tst.l   %d4
        bne.s   .Lgk_pcm_primary_not_restore_zero
        cmpi.l  #2,%d1
        bcs.s   .Lgk_pcm_primary_index_ready
        subq.l  #2,%d1
        andi.l  #1,%d1
        addq.l  #2,%d1
        bra.s   .Lgk_pcm_primary_index_ready
.Lgk_pcm_primary_not_restore_zero:
        cmpi.l  #GK_PAGE_ROUTE_RESTORE_AUDIO_3,%d4
        beq.s   .Lgk_pcm_primary_restore_tail
        cmpi.l  #GK_PAGE_ROUTE_RESTORE_AUDIO_4,%d4
        bne.s   .Lgk_pcm_primary_regular
.Lgk_pcm_primary_restore_tail:
        tst.l   %d1
        beq.s   .Lgk_pcm_primary_index_ready
        subq.l  #1,%d1
        andi.l  #1,%d1
        addq.l  #1,%d1
        bra.s   .Lgk_pcm_primary_index_ready
.Lgk_pcm_primary_regular:
        moveq   #0,%d0
        lea     gk_page_clipboard_group_counts,%a0
        move.b  (%a0,%d4.l),%d0
.Lgk_pcm_primary_modulo:
        cmp.l   %d0,%d1
        bcs.s   .Lgk_pcm_primary_index_ready
        sub.l   %d0,%d1
        bra.s   .Lgk_pcm_primary_modulo
.Lgk_pcm_primary_index_ready:
        moveq   #0,%d0
        lea     gk_page_clipboard_group_offsets,%a0
        move.b  (%a0,%d4.l),%d0
        add.l   %d0,%d1
        lsl.l   #2,%d1
        lea     gk_page_clipboard_group_returns,%a0
        move.l  (%a0,%d1.l),%d0
        cmp.l   %d7,%d0
        bne.s   .Lgk_pcm_primary_corrupt
        addq.l  #1,%d5
        move.l  %d5,GK_PC_PRIMARY_COUNT(%a2)
        move.l  GK_PC_TOKEN(%a2),%d0
        andi.l  #GK_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_PAGE_TOKEN_WRITTEN,%d0
        beq.s   .Lgk_pcm_primary_ok
        cmpi.l  #GK_PAGE_TOKEN_ARMED,%d0
        bne.s   .Lgk_pcm_primary_corrupt
        move.l  GK_PC_TOKEN(%a2),%d0
        andi.l  #GK_PAGE_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_PAGE_TOKEN_WRITTEN,%d0
        move.l  %d0,GK_PC_TOKEN(%a2)
        not.l   %d0
        move.l  %d0,GK_PC_TOKEN_INVERSE(%a2)
.Lgk_pcm_primary_ok:
        movea.l %a2,%a0
        moveq   #GK_OK,%d0
        rts
.Lgk_pcm_primary_corrupt:
        movea.l %a2,%a0
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_page_clipboard_primary_marker_validate,.-gk_page_clipboard_primary_marker_validate
        .type   gk_page_clipboard_helper_marker_validate,@function
gk_page_clipboard_helper_marker_validate:
        movea.l %a0,%a2
        cmpi.l  #0x400973a0,%d3
        bne.s   .Lgk_pcm_helper_corrupt
        bsr.w   gk_page_clipboard_validate_frame
        tst.l   %d0
        bne.s   .Lgk_pcm_helper_corrupt
        move.l  GK_PC_ROUTE(%a2),%d0
        cmpi.l  #GK_PAGE_ROUTE_RESTORE_AUDIO_0,%d0
        bne.s   .Lgk_pcm_helper_corrupt
        move.l  GK_PC_PRIMARY_COUNT(%a2),%d0
        cmpi.l  #2,%d0
        bne.s   .Lgk_pcm_helper_corrupt
        tst.l   GK_PC_HELPER_COUNT(%a2)
        bne.s   .Lgk_pcm_helper_corrupt
        moveq   #1,%d0
        move.l  %d0,GK_PC_HELPER_COUNT(%a2)
        movea.l %a2,%a0
        moveq   #GK_OK,%d0
        rts
.Lgk_pcm_helper_corrupt:
        movea.l %a2,%a0
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_page_clipboard_helper_marker_validate,.-gk_page_clipboard_helper_marker_validate
        .align  4
gk_page_clipboard_expected_counts:
        .byte   14,18,12,13,13,12,18,12,12,12
        .byte   12,18,12,12,12,12,18,12,12,12
gk_page_clipboard_group_counts:
        .byte   4,3,2,3,3,2,3,2,2,2
        .byte   2,3,2,2,2,2,3,2,2,2
gk_page_clipboard_group_offsets:
        .byte   0,4,7,9,12,15,17,20,22,24
        .byte   26,28,31,33,35,37,39,42,44,46
        .align  4
gk_page_clipboard_group_returns:
        .long   0x40027f12,0x40027f98,0x4002809a,0x4002811a
        .long   0x4002836e,0x400283f6,0x4002845c
        .long   0x40028200,0x40028282
        .long   0x4002850c,0x400285d2,0x40028656
        .long   0x40028704,0x400287ca,0x4002884e
        .long   0x40028944,0x400289a6
        .long   0x40028bc0,0x40028c24,0x40028c86
        .long   0x40028a80,0x40028ae2
        .long   0x40028d62,0x40028dc4
        .long   0x40028e9e,0x40028f00
        .long   0x4005cd86,0x4005ce82
        .long   0x4005d118,0x4005d1f4,0x4005d2b6
        .long   0x4005cf72,0x4005d03c
        .long   0x4005d3b2,0x4005d47c
        .long   0x4005d56c,0x4005d636
        .long   0x4005d744,0x4005d7f2
        .long   0x4005da58,0x4005db18,0x4005dbd0
        .long   0x4005d8d2,0x4005d980
        .long   0x4005dcbe,0x4005dd6c
        .long   0x4005de4c,0x4005defa
        .type   gk_page_clipboard_compare_payloads,@function
gk_page_clipboard_compare_payloads:
        movea.l GK_PC_PAYLOAD(%a6),%a0
        move.l  GK_PC_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a1
        adda.l  %d0,%a1
        move.l  #1580,%d2
.Lgk_pc_compare_long:
        move.l  (%a0)+,%d0
        cmp.l   (%a1)+,%d0
        bne.s   .Lgk_pc_compare_miss
        subq.l  #1,%d2
        bne.s   .Lgk_pc_compare_long
        move.b  (%a0)+,%d0
        cmp.b   (%a1)+,%d0
        bne.s   .Lgk_pc_compare_miss
        move.b  (%a0),%d0
        cmp.b   (%a1),%d0
        bne.s   .Lgk_pc_compare_miss
        moveq   #GK_OK,%d0
        rts
.Lgk_pc_compare_miss:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_page_clipboard_compare_payloads,.-gk_page_clipboard_compare_payloads
        .type   gk_page_clipboard_validate_undo_context,@function
gk_page_clipboard_validate_undo_context:
        move.l  %d0,%d3
        movea.l %a6,%a0
        bsr.w   gk_page_clipboard_expected_tag
        tst.l   %d0
        bmi.s   .Lgk_pc_result_corrupt
        cmp.l   GK_STOCK_UNDO_TAG,%d0
        bne.s   .Lgk_pc_result_corrupt
        cmp.l   GK_STOCK_UNDO_ACTION,%d3
        bne.s   .Lgk_pc_result_corrupt
        move.l  GK_PC_TRACK(%a6),%d0
        cmp.l   GK_STOCK_PAGE_UNDO_TRACK,%d0
        bne.s   .Lgk_pc_result_corrupt
        move.l  GK_PC_PART(%a6),%d0
        cmp.l   GK_STOCK_UNDO_PART,%d0
        bne.s   .Lgk_pc_result_corrupt
        move.l  GK_PC_PAGE(%a6),%d0
        cmp.l   GK_STOCK_PAGE_UNDO_PAGE,%d0
        bne.s   .Lgk_pc_result_corrupt
        move.l  GK_PC_MODE(%a6),%d0
        cmp.l   GK_STOCK_PAGE_UNDO_MODE,%d0
        bne.s   .Lgk_pc_result_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_pc_result_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_page_clipboard_validate_undo_context,.-gk_page_clipboard_validate_undo_context
        .type   gk_page_clipboard_validate_result,@function
gk_page_clipboard_validate_result:
        .incbin "stock/0331.bin", 0, 4
        .incbin "stock/0331.bin", 4, 4
        movea.l %a6,%a0
        bsr.w   gk_page_clipboard_validate_frame
        tst.l   %d0
        bne.w   .Lgk_pc_result_restore
        cmpi.l  #GK_PAGE_ROUTE_NO_WRITE,%d7
        beq.w   .Lgk_pc_result_no_write
        move.l  GK_PC_PRIMARY_COUNT(%a6),%d0
        cmp.l   GK_PC_EXPECTED_COUNT(%a6),%d0
        bne.w   .Lgk_pc_result_fail
        move.l  GK_PC_TOKEN(%a6),%d0
        andi.l  #GK_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_PAGE_TOKEN_WRITTEN,%d0
        bne.w   .Lgk_pc_result_fail
        tst.l   GK_PC_HELPER_COUNT(%a6)
        beq.s   .Lgk_pc_result_helper_ready
        cmpi.l  #GK_PAGE_ROUTE_RESTORE_AUDIO_0,%d7
        bne.w   .Lgk_pc_result_fail
        move.l  GK_PC_HELPER_COUNT(%a6),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_pc_result_fail
.Lgk_pc_result_helper_ready:
        moveq   #1,%d1
        move.l  %a2,%d0
        lsl.l   %d0,%d1
        or.l    GK_PC_OLD_BANK_EDITED(%a6),%d1
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_pc_result_fail
        moveq   #1,%d1
        move.l  %a2,%d0
        lsl.l   %d0,%d1
        or.l    GK_PC_OLD_MIRROR_EDITED(%a6),%d1
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_pc_result_fail
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_pc_result_fail
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        move.l  GK_PC_OUTCOME(%a6),%d1
        cmpi.l  #GK_PAGE_OUTCOME_CLEAR_UNDO,%d1
        beq.s   .Lgk_pc_result_undo_dirty
        cmpi.l  #GK_PAGE_OUTCOME_PASTE_UNDO,%d1
        beq.s   .Lgk_pc_result_undo_dirty
        cmpi.l  #1,%d0
        bne.w   .Lgk_pc_result_fail
        bra.s   .Lgk_pc_result_dirty_ok
.Lgk_pc_result_undo_dirty:
        cmpi.l  #1,%d0
        bhi.w   .Lgk_pc_result_fail
.Lgk_pc_result_dirty_ok:
        bsr.w   gk_page_clipboard_compare_payloads
        tst.l   %d0
        bne.w   .Lgk_pc_result_fail
        move.l  GK_PC_OUTCOME(%a6),%d0
        cmpi.l  #GK_PAGE_OUTCOME_CLEAR_NEW,%d0
        beq.s   .Lgk_pc_result_clear_new
        cmpi.l  #GK_PAGE_OUTCOME_PASTE_COPY,%d0
        beq.s   .Lgk_pc_result_paste_copy
        cmpi.l  #GK_PAGE_OUTCOME_CLEAR_UNDO,%d0
        beq.s   .Lgk_pc_result_undo_complete
        cmpi.l  #GK_PAGE_OUTCOME_PASTE_UNDO,%d0
        bne.w   .Lgk_pc_result_fail
.Lgk_pc_result_undo_complete:
        tst.l   GK_STOCK_UNDO_TAG
        bne.w   .Lgk_pc_result_fail
        tst.l   GK_STOCK_UNDO_ACTION
        bne.w   .Lgk_pc_result_fail
        moveq   #GK_OK,%d0
        bra.w   .Lgk_pc_result_restore
.Lgk_pc_result_clear_new:
        moveq   #0x2e,%d0
        bsr.w   gk_page_clipboard_validate_undo_context
        bra.w   .Lgk_pc_result_restore
.Lgk_pc_result_paste_copy:
        moveq   #0x2d,%d0
        bsr.w   gk_page_clipboard_validate_undo_context
        tst.l   %d0
        bne.w   .Lgk_pc_result_restore
        movea.l %a6,%a0
        bsr.w   gk_page_clipboard_expected_tag
        cmp.l   GK_STOCK_PASTE_TAG,%d0
        bne.w   .Lgk_pc_result_fail
        moveq   #GK_OK,%d0
        bra.w   .Lgk_pc_result_restore
.Lgk_pc_result_no_write:
        tst.l   GK_PC_PRIMARY_COUNT(%a6)
        bne.w   .Lgk_pc_result_fail
        tst.l   GK_PC_HELPER_COUNT(%a6)
        bne.w   .Lgk_pc_result_fail
        move.l  GK_PC_TOKEN(%a6),%d0
        andi.l  #GK_PAGE_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_PAGE_TOKEN_ARMED,%d0
        bne.w   .Lgk_pc_result_fail
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   GK_PC_OLD_BANK_EDITED(%a6),%d0
        bne.w   .Lgk_pc_result_fail
        moveq   #0,%d0
        move.b  GK_STOCK_WORKING_EDITED_MIRROR,%d0
        cmp.l   GK_PC_OLD_MIRROR_EDITED(%a6),%d0
        bne.w   .Lgk_pc_result_fail
        movea.l %a5,%a0
        adda.l  #GK_STOCK_BANK_DIRTY_OFFSET,%a0
        move.l  (%a0),%d0
        cmp.l   GK_PC_OLD_BANK_DIRTY(%a6),%d0
        bne.w   .Lgk_pc_result_fail
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmp.l   GK_PC_OLD_GLOBAL_DIRTY(%a6),%d0
        bne.w   .Lgk_pc_result_fail
        bsr.w   gk_page_clipboard_compare_payloads
        tst.l   %d0
        bne.s   .Lgk_pc_result_fail
        move.l  GK_PC_OUTCOME(%a6),%d0
        cmpi.l  #GK_PAGE_OUTCOME_PASTE_NONE,%d0
        bne.s   .Lgk_pc_result_no_write_ok
        tst.l   GK_STOCK_UNDO_TAG
        bne.s   .Lgk_pc_result_fail
        move.l  GK_PC_PAGE(%a6),%d0
        cmpi.l  #4,%d0
        bhi.s   .Lgk_pc_result_no_write_out_of_range
        tst.l   GK_STOCK_UNDO_ACTION
        bne.s   .Lgk_pc_result_fail
        bra.s   .Lgk_pc_result_no_write_ok
.Lgk_pc_result_no_write_out_of_range:
        move.l  GK_STOCK_UNDO_ACTION,%d0
        cmpi.l  #0x2d,%d0
        bne.s   .Lgk_pc_result_fail
.Lgk_pc_result_no_write_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pc_result_restore
.Lgk_pc_result_fail:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_pc_result_restore:
        movem.l (%sp),%d2-%d3/%a2-%a3
        lea     16(%sp),%sp
        rts
        .size   gk_page_clipboard_validate_result,.-gk_page_clipboard_validate_result
        .type   gk_page_clipboard_return_stock,@function
gk_page_clipboard_return_stock:
        bsr.w   gk_page_clipboard_clear_private
        moveq   #0,%d2
        move.w  GK_PC_OUTPUT_SR(%a6),%d2
        move.w  %d2,%sr
        move.l  GK_PC_OUTPUT_D0(%a6),%d0
        move.l  GK_PC_OUTPUT_D1(%a6),%d1
        movea.l GK_PC_OUTPUT_A0(%a6),%a0
        movea.l GK_PC_OUTPUT_A1(%a6),%a1
        movem.l (%a6),%d2-%d7/%a2-%a6
        lea     GK_PC_FRAME_SIZE(%sp),%sp
        rts
        .size   gk_page_clipboard_return_stock,.-gk_page_clipboard_return_stock
        .type   gk_page_clipboard_finish,@function
gk_page_clipboard_finish:
        bsr.w   gk_page_clipboard_validate_result
        tst.l   %d0
        bne.w   gk_page_clipboard_release_abort_fatal
        cmpi.l  #GK_PAGE_ROUTE_NO_WRITE,%d7
        beq.s   .Lgk_pc_finish_no_write
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_page_clipboard_release_abort_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_page_clipboard_release_abort_fatal
        movea.l %a6,%a0
        bsr.w   gk_page_clipboard_validate_frame
        tst.l   %d0
        bne.w   gk_page_clipboard_release_fatal
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_page_clipboard_private_fatal
        bra.w   gk_page_clipboard_return_stock
.Lgk_pc_finish_no_write:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_page_clipboard_private_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_page_clipboard_private_fatal
        bra.w   gk_page_clipboard_return_stock
        .size   gk_page_clipboard_finish,.-gk_page_clipboard_finish
        .global gk_stock_page_paste_callback
        .type gk_stock_page_paste_callback,@function
gk_stock_page_paste_callback:
        move.l %d0,-(%sp)
        move.l 8(%sp),%d0
        cmpi.l #GK_PAGE_CLIPBOARD_PASTE,%d0
        bne.w gk_page_clipboard_fatal
        move.l (%sp)+,%d0
        lea -GK_PC_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l %d0,GK_PC_INPUT_D0(%a6)
        move.l %d1,GK_PC_INPUT_D1(%a6)
        move.l %a0,GK_PC_INPUT_A0(%a6)
        move.l %a1,GK_PC_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_PC_INPUT_SR(%a6)
        moveq #GK_PAGE_CLIPBOARD_PASTE,%d2
        move.l %d2,GK_PC_KIND(%a6)
        bsr.w gk_page_clipboard_prepare
        move.l GK_PC_FRAME_SIZE+8(%a6),-(%sp)
        move.l GK_PC_FRAME_SIZE+4(%a6),-(%sp)
        move.l GK_PC_INPUT_D0(%a6),%d0
        move.l GK_PC_INPUT_D1(%a6),%d1
        movea.l GK_PC_INPUT_A0(%a6),%a0
        movea.l GK_PC_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_PC_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        .global gk_page_clipboard_paste_stock_call
gk_page_clipboard_paste_stock_call:
        jsr GK_STOCK_PAGE_PASTE_CALLBACK
        addq.l #8,%sp
        move.l %d0,GK_PC_OUTPUT_D0(%a6)
        move.l %d1,GK_PC_OUTPUT_D1(%a6)
        move.l %a0,GK_PC_OUTPUT_A0(%a6)
        move.l %a1,GK_PC_OUTPUT_A1(%a6)
        move.w %sr,%d0
        move.w %d0,GK_PC_OUTPUT_SR(%a6)
        jmp gk_page_clipboard_finish
        .size gk_stock_page_paste_callback,.-gk_stock_page_paste_callback
        .global gk_stock_page_clear_callback
        .type gk_stock_page_clear_callback,@function
gk_stock_page_clear_callback:
        move.l %d0,-(%sp)
        move.l 8(%sp),%d0
        cmpi.l #GK_PAGE_CLIPBOARD_CLEAR,%d0
        bne.w gk_page_clipboard_fatal
        move.l (%sp)+,%d0
        lea -GK_PC_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        movea.l %sp,%a6
        move.l %d0,GK_PC_INPUT_D0(%a6)
        move.l %d1,GK_PC_INPUT_D1(%a6)
        move.l %a0,GK_PC_INPUT_A0(%a6)
        move.l %a1,GK_PC_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_PC_INPUT_SR(%a6)
        moveq #GK_PAGE_CLIPBOARD_CLEAR,%d2
        move.l %d2,GK_PC_KIND(%a6)
        bsr.w gk_page_clipboard_prepare
        move.l GK_PC_FRAME_SIZE+8(%a6),-(%sp)
        move.l GK_PC_FRAME_SIZE+4(%a6),-(%sp)
        move.l GK_PC_INPUT_D0(%a6),%d0
        move.l GK_PC_INPUT_D1(%a6),%d1
        movea.l GK_PC_INPUT_A0(%a6),%a0
        movea.l GK_PC_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_PC_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        .global gk_page_clipboard_clear_stock_call
gk_page_clipboard_clear_stock_call:
        jsr GK_STOCK_PAGE_CLEAR_CALLBACK
        addq.l #8,%sp
        move.l %d0,GK_PC_OUTPUT_D0(%a6)
        move.l %d1,GK_PC_OUTPUT_D1(%a6)
        move.l %a0,GK_PC_OUTPUT_A0(%a6)
        move.l %a1,GK_PC_OUTPUT_A1(%a6)
        move.w %sr,%d0
        move.w %d0,GK_PC_OUTPUT_SR(%a6)
        jmp gk_page_clipboard_finish
        .size gk_stock_page_clear_callback,.-gk_stock_page_clear_callback
        .global gk_page_clipboard_clear_marker_d0
        .type gk_page_clipboard_clear_marker_d0,@function
gk_page_clipboard_clear_marker_d0:
        lea -GK_PCM_SAVED_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        lea GK_PCM_CLEAR_FRAME(%sp),%a0
        move.l GK_PCM_RETURN(%sp),%d3
        bsr.w gk_page_clipboard_primary_marker_validate
        tst.l %d0
        bne.w gk_page_clipboard_marker_fatal
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea GK_PCM_SAVED_BYTES(%sp),%sp
        .incbin "stock/0332.bin", 0, 6
        rts
        .size gk_page_clipboard_clear_marker_d0,.-gk_page_clipboard_clear_marker_d0
        .global gk_page_clipboard_clear_marker_d2
        .type gk_page_clipboard_clear_marker_d2,@function
gk_page_clipboard_clear_marker_d2:
        lea -GK_PCM_SAVED_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        lea GK_PCM_CLEAR_FRAME(%sp),%a0
        move.l GK_PCM_RETURN(%sp),%d3
        bsr.w gk_page_clipboard_primary_marker_validate
        tst.l %d0
        bne.w gk_page_clipboard_marker_fatal
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea GK_PCM_SAVED_BYTES(%sp),%sp
        .incbin "stock/0333.bin", 0, 6
        rts
        .size gk_page_clipboard_clear_marker_d2,.-gk_page_clipboard_clear_marker_d2
        .global gk_page_clipboard_restore_marker_d0
        .type gk_page_clipboard_restore_marker_d0,@function
gk_page_clipboard_restore_marker_d0:
        lea -GK_PCM_SAVED_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        moveq #0,%d0
        move.b __gk_page_clipboard_active,%d0
        cmpi.l #GK_PAGE_CLIPBOARD_PASTE,%d0
        beq.s .Lgk_pcm_restore_paste_10
        cmpi.l #GK_PAGE_CLIPBOARD_CLEAR,%d0
        bne.w gk_page_clipboard_private_fatal
        lea GK_PCM_CLEAR_RESTORE_FRAME(%sp),%a0
        bra.s .Lgk_pcm_restore_frame_10
.Lgk_pcm_restore_paste_10:
        lea GK_PCM_PASTE_RESTORE_FRAME(%sp),%a0
.Lgk_pcm_restore_frame_10:
        move.l GK_PCM_RETURN(%sp),%d3
        bsr.w gk_page_clipboard_primary_marker_validate
        tst.l %d0
        bne.w gk_page_clipboard_marker_fatal
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea GK_PCM_SAVED_BYTES(%sp),%sp
        .incbin "stock/0334.bin", 0, 6
        rts
        .size gk_page_clipboard_restore_marker_d0,.-gk_page_clipboard_restore_marker_d0
        .global gk_page_clipboard_restore_marker_d1
        .type gk_page_clipboard_restore_marker_d1,@function
gk_page_clipboard_restore_marker_d1:
        lea -GK_PCM_SAVED_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        moveq #0,%d0
        move.b __gk_page_clipboard_active,%d0
        cmpi.l #GK_PAGE_CLIPBOARD_PASTE,%d0
        beq.s .Lgk_pcm_restore_paste_13
        cmpi.l #GK_PAGE_CLIPBOARD_CLEAR,%d0
        bne.w gk_page_clipboard_private_fatal
        lea GK_PCM_CLEAR_RESTORE_FRAME(%sp),%a0
        bra.s .Lgk_pcm_restore_frame_13
.Lgk_pcm_restore_paste_13:
        lea GK_PCM_PASTE_RESTORE_FRAME(%sp),%a0
.Lgk_pcm_restore_frame_13:
        move.l GK_PCM_RETURN(%sp),%d3
        bsr.w gk_page_clipboard_primary_marker_validate
        tst.l %d0
        bne.w gk_page_clipboard_marker_fatal
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea GK_PCM_SAVED_BYTES(%sp),%sp
        .incbin "stock/0335.bin", 0, 6
        rts
        .size gk_page_clipboard_restore_marker_d1,.-gk_page_clipboard_restore_marker_d1
        .global gk_page_clipboard_helper_marker_d1
        .type   gk_page_clipboard_helper_marker_d1,@function
gk_page_clipboard_helper_marker_d1:
        move.l  %d0,-(%sp)
        move.l  28(%sp),%d0
        cmpi.l  #GK_STOCK_PAGE_MACHINE_HELPER_RETURN,%d0
        beq.s   .Lgk_pcm_helper_page
        move.l  (%sp)+,%d0
        bra.s   .Lgk_pcm_helper_stock
.Lgk_pcm_helper_page:
        move.l  (%sp)+,%d0
        lea -GK_PCM_SAVED_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        moveq   #0,%d0
        move.b  __gk_page_clipboard_active,%d0
        cmpi.l  #GK_PAGE_CLIPBOARD_PASTE,%d0
        beq.s   .Lgk_pcm_helper_paste
        cmpi.l  #GK_PAGE_CLIPBOARD_CLEAR,%d0
        bne.w   gk_page_clipboard_private_fatal
        lea     GK_PCM_CLEAR_HELPER_FRAME(%sp),%a0
        bra.s   .Lgk_pcm_helper_frame
.Lgk_pcm_helper_paste:
        lea     GK_PCM_PASTE_HELPER_FRAME(%sp),%a0
.Lgk_pcm_helper_frame:
        move.l  GK_PCM_RETURN(%sp),%d3
        bsr.w   gk_page_clipboard_helper_marker_validate
        tst.l   %d0
        bne.w   gk_page_clipboard_marker_fatal
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea GK_PCM_SAVED_BYTES(%sp),%sp
.Lgk_pcm_helper_stock:
        .incbin "stock/0336.bin", 0, 6
        rts
        .size   gk_page_clipboard_helper_marker_d1,.-gk_page_clipboard_helper_marker_d1
        .global gk_page_clipboard_fatal
gk_page_clipboard_fatal:
        illegal
        bra.s   gk_page_clipboard_fatal
