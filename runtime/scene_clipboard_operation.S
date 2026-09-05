        .include "abi.inc"
        .equ    GK_SC_FRAME_SIZE,104
        .equ    GK_SC_INPUT_D0,44
        .equ    GK_SC_INPUT_D1,48
        .equ    GK_SC_INPUT_A0,52
        .equ    GK_SC_INPUT_A1,56
        .equ    GK_SC_INPUT_SR,60
        .equ    GK_SC_OUTPUT_D0,64
        .equ    GK_SC_OUTPUT_D1,68
        .equ    GK_SC_OUTPUT_A0,72
        .equ    GK_SC_OUTPUT_A1,76
        .equ    GK_SC_OUTPUT_SR,80
        .equ    GK_SC_TOKEN,84
        .equ    GK_SC_TOKEN_INVERSE,88
        .equ    GK_SC_KIND,92
        .equ    GK_SC_ROUTE,96
        .equ    GK_SC_PAYLOAD,100
        .equ    GK_SCENE_ROWS_OFFSET,0x662
        .equ    GK_SCENE_TAIL_OFFSET,0x1662
        .equ    GK_SCENE_PAYLOAD_SIZE,266
        .section .runtime,"ax"
        .align  4
        .type   gk_scene_clipboard_clear_private,@function
gk_scene_clipboard_clear_private:
        clr.l   __gk_scene_clipboard_state_start
        rts
        .size   gk_scene_clipboard_clear_private,.-gk_scene_clipboard_clear_private
        .type   gk_scene_clipboard_private_fatal,@function
gk_scene_clipboard_private_fatal:
        bsr.w   gk_scene_clipboard_clear_private
        bra.w   gk_scene_clipboard_fatal
        .size   gk_scene_clipboard_private_fatal,.-gk_scene_clipboard_private_fatal
        .type   gk_scene_clipboard_abort_fatal,@function
gk_scene_clipboard_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_scene_clipboard_private_fatal
        bra.w   gk_scene_clipboard_private_fatal
        .size   gk_scene_clipboard_abort_fatal,.-gk_scene_clipboard_abort_fatal
        .type   gk_scene_clipboard_release_d0_abort_fatal,@function
gk_scene_clipboard_release_d0_abort_fatal:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_scene_clipboard_private_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_clipboard_private_fatal
        bra.w   gk_scene_clipboard_abort_fatal
        .size   gk_scene_clipboard_release_d0_abort_fatal,.-gk_scene_clipboard_release_d0_abort_fatal
        .type   gk_scene_clipboard_release_abort_fatal,@function
gk_scene_clipboard_release_abort_fatal:
        move.l  %d6,%d0
        bra.w   gk_scene_clipboard_release_d0_abort_fatal
        .size   gk_scene_clipboard_release_abort_fatal,.-gk_scene_clipboard_release_abort_fatal
        .type   gk_scene_clipboard_release_d0_fatal,@function
gk_scene_clipboard_release_d0_fatal:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_scene_clipboard_private_fatal
        jsr     gk_descriptor_release
        bra.w   gk_scene_clipboard_private_fatal
        .size   gk_scene_clipboard_release_d0_fatal,.-gk_scene_clipboard_release_d0_fatal
        .type   gk_scene_clipboard_release_fatal,@function
gk_scene_clipboard_release_fatal:
        move.l  %d6,%d0
        bra.w   gk_scene_clipboard_release_d0_fatal
        .size   gk_scene_clipboard_release_fatal,.-gk_scene_clipboard_release_fatal
        .type   gk_scene_clipboard_context_token,@function
gk_scene_clipboard_context_token:
        move.l  %d4,%d0
        cmpi.l  #15,%d0
        bhi.s   .Lgk_sc_token_corrupt
        lsl.l   #8,%d0
        lsl.l   #8,%d0
        lsl.l   #4,%d0
        ori.l   #GK_SCENE_CLIPBOARD_TOKEN_TAG,%d0
        move.l  %a2,%d1
        cmpi.l  #3,%d1
        bhi.s   .Lgk_sc_token_corrupt
        lsl.l   #8,%d1
        lsl.l   #8,%d1
        lsl.l   #2,%d1
        or.l    %d1,%d0
        move.l  %a3,%d1
        cmpi.l  #1,%d1
        bhi.s   .Lgk_sc_token_corrupt
        lsl.l   #8,%d1
        lsl.l   #8,%d1
        lsl.l   #1,%d1
        or.l    %d1,%d0
        move.l  %a4,%d1
        cmpi.l  #15,%d1
        bhi.s   .Lgk_sc_token_corrupt
        lsl.l   #8,%d1
        lsl.l   #5,%d1
        or.l    %d1,%d0
        move.l  %d6,%d1
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.s   .Lgk_sc_token_corrupt
        lsl.l   #6,%d1
        or.l    %d1,%d0
        move.l  GK_SC_KIND(%a6),%d1
        cmpi.l  #GK_SCENE_CLIPBOARD_PASTE,%d1
        beq.s   .Lgk_sc_token_kind_ok
        cmpi.l  #GK_SCENE_CLIPBOARD_CLEAR,%d1
        beq.s   .Lgk_sc_token_kind_ok
        cmpi.l  #GK_SCENE_CLIPBOARD_COPY,%d1
        bne.s   .Lgk_sc_token_corrupt
.Lgk_sc_token_kind_ok:
        or.l    %d1,%d0
        rts
.Lgk_sc_token_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_scene_clipboard_context_token,.-gk_scene_clipboard_context_token
        .type   gk_scene_clipboard_capture_context,@function
gk_scene_clipboard_capture_context:
        tst.l   __gk_lifecycle_state
        bne.w   gk_scene_clipboard_fatal
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        tst.b   __gk_scene_clipboard_active
        bne.w   .Lgk_sc_claim_busy
        move.l  GK_SC_KIND(%a6),%d0
        move.b  %d0,__gk_scene_clipboard_active
        moveq   #-1,%d0
        move.b  %d0,__gk_scene_clipboard_part
        move.w  %d1,%sr
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_scene_clipboard_private_fatal
        movea.l %d0,%a2
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   gk_scene_clipboard_private_fatal
        move.b  %d0,__gk_scene_clipboard_part
        suba.l  %a3,%a3
        move.l  GK_STOCK_SCENE_SIDE,%d0
        cmpi.l  #1,%d0
        beq.s   .Lgk_sc_side_ready
        moveq   #1,%d0
        movea.l %d0,%a3
.Lgk_sc_side_ready:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_scene_clipboard_private_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_scene_clipboard_private_fatal
        move.l  %d6,%d0
        move.b  %d0,__gk_scene_clipboard_descriptor
        moveq   #-1,%d1
        eor.l   %d1,%d0
        move.b  %d0,__gk_scene_clipboard_descriptor_inverse
        rts
.Lgk_sc_claim_busy:
        move.w  %d1,%sr
        bra.w   gk_scene_clipboard_fatal
        .size   gk_scene_clipboard_capture_context,.-gk_scene_clipboard_capture_context
        .type   gk_scene_clipboard_finish_prepare,@function
gk_scene_clipboard_finish_prepare:
        cmp.l   %d6,%d0
        bne.s   .Lgk_sc_finish_prepare_corrupt
        movea.l %a0,%a5
        move.l  %a2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        .incbin "stock/0323.bin", 0, 6
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        cmpa.l  %a5,%a0
        bne.s   .Lgk_sc_finish_prepare_corrupt
        lea     0x10(%a5),%a0
        adda.l  %a3,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmpi.l  #15,%d0
        bhi.s   .Lgk_sc_finish_prepare_corrupt
        movea.l %d0,%a4
        move.l  %a5,GK_SC_PAYLOAD(%a6)
        bsr.w   gk_scene_clipboard_context_token
        tst.l   %d0
        bmi.s   .Lgk_sc_finish_prepare_corrupt
        move.l  %d0,GK_SC_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_SC_TOKEN_INVERSE(%a6)
        moveq   #GK_OK,%d0
        rts
.Lgk_sc_finish_prepare_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_scene_clipboard_finish_prepare,.-gk_scene_clipboard_finish_prepare
        .type   gk_scene_clipboard_prepare_copy,@function
gk_scene_clipboard_prepare_copy:
        bsr.w   gk_scene_clipboard_capture_context
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_scene_clipboard_private_fatal
        cmp.l   %d6,%d0
        bne.w   gk_scene_clipboard_release_d0_fatal
        bsr.w   gk_scene_clipboard_finish_prepare
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_fatal
        moveq   #GK_SCENE_CLIPBOARD_ROUTE_COPY,%d7
        move.l  %d7,GK_SC_ROUTE(%a6)
        rts
        .size   gk_scene_clipboard_prepare_copy,.-gk_scene_clipboard_prepare_copy
        .type   gk_scene_clipboard_prepare_update,@function
gk_scene_clipboard_prepare_update:
        bsr.w   gk_scene_clipboard_capture_context
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_scene_clipboard_private_fatal
        cmp.l   %d6,%d0
        bne.w   gk_scene_clipboard_abort_fatal
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_scene_clipboard_abort_fatal
        movea.l %a0,%a5
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_scene_clipboard_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_scene_clipboard_release_d0_abort_fatal
        cmpa.l  %a5,%a0
        bne.w   gk_scene_clipboard_release_abort_fatal
        bsr.w   gk_scene_clipboard_finish_prepare
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_abort_fatal
        rts
        .size   gk_scene_clipboard_prepare_update,.-gk_scene_clipboard_prepare_update
        .type   gk_scene_clipboard_classify_paste,@function
gk_scene_clipboard_classify_paste:
        moveq   #GK_SCENE_CLIPBOARD_ROUTE_PASTE_UNDO,%d7
        move.l  GK_STOCK_SCENE_UNDO_TAG,%d0
        cmpi.l  #0x10,%d0
        bne.s   .Lgk_sc_paste_not_undo
        move.l  GK_STOCK_SCENE_UNDO_ACTION,%d0
        cmpi.l  #0x21,%d0
        bne.s   .Lgk_sc_paste_not_undo
        move.l  %a2,%d0
        cmp.l   GK_STOCK_SCENE_UNDO_PART,%d0
        bne.s   .Lgk_sc_paste_not_undo
        move.l  %a4,%d0
        cmp.l   GK_STOCK_SCENE_UNDO_SCENE,%d0
        beq.s   .Lgk_sc_paste_classified
.Lgk_sc_paste_not_undo:
        moveq   #GK_SCENE_CLIPBOARD_ROUTE_PASTE_COPY,%d7
        move.l  GK_STOCK_SCENE_COPY_TAG,%d0
        cmpi.l  #0x10,%d0
        beq.s   .Lgk_sc_paste_classified
        moveq   #GK_SCENE_CLIPBOARD_ROUTE_PASTE_NONE,%d7
.Lgk_sc_paste_classified:
        move.l  %d7,GK_SC_ROUTE(%a6)
        rts
        .size   gk_scene_clipboard_classify_paste,.-gk_scene_clipboard_classify_paste
        .type   gk_scene_clipboard_classify_clear,@function
gk_scene_clipboard_classify_clear:
        moveq   #GK_SCENE_CLIPBOARD_ROUTE_CLEAR_UNDO,%d7
        move.l  GK_STOCK_SCENE_UNDO_TAG,%d0
        cmpi.l  #0x10,%d0
        bne.s   .Lgk_sc_clear_new
        move.l  GK_STOCK_SCENE_UNDO_ACTION,%d0
        cmpi.l  #0x22,%d0
        bne.s   .Lgk_sc_clear_new
        move.l  %a2,%d0
        cmp.l   GK_STOCK_SCENE_UNDO_PART,%d0
        bne.s   .Lgk_sc_clear_new
        move.l  %a4,%d0
        cmp.l   GK_STOCK_SCENE_UNDO_SCENE,%d0
        beq.s   .Lgk_sc_clear_classified
.Lgk_sc_clear_new:
        moveq   #GK_SCENE_CLIPBOARD_ROUTE_CLEAR_NEW,%d7
.Lgk_sc_clear_classified:
        move.l  %d7,GK_SC_ROUTE(%a6)
        rts
        .size   gk_scene_clipboard_classify_clear,.-gk_scene_clipboard_classify_clear
        .type   gk_scene_clipboard_validate_current,@function
gk_scene_clipboard_validate_current:
        bsr.w   gk_scene_clipboard_context_token
        tst.l   %d0
        bmi.w   .Lgk_sc_validate_current_corrupt
        cmp.l   GK_SC_TOKEN(%a6),%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        not.l   %d0
        cmp.l   GK_SC_TOKEN_INVERSE(%a6),%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        move.l  %a5,%d0
        cmp.l   GK_SC_PAYLOAD(%a6),%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        move.l  %d7,%d0
        cmp.l   GK_SC_ROUTE(%a6),%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  __gk_scene_clipboard_active,%d0
        cmp.l   GK_SC_KIND(%a6),%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  __gk_scene_clipboard_part,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        move.l  GK_STOCK_SCENE_SIDE,%d0
        cmpi.l  #1,%d0
        beq.s   .Lgk_sc_validate_side_a
        moveq   #1,%d0
        bra.s   .Lgk_sc_validate_side_ready
.Lgk_sc_validate_side_a:
        moveq   #0,%d0
.Lgk_sc_validate_side_ready:
        move.l  %a3,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        lea     0x10(%a5),%a0
        adda.l  %a3,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_sc_validate_current_corrupt
        move.l  %d4,%d0
        lsl.l   #2,%d0
        add.l   %a2,%d0
        jsr     gk_physical_validate
        cmp.l   %d6,%d0
        bne.s   .Lgk_sc_validate_current_corrupt
        cmpa.l  %a5,%a0
        bne.s   .Lgk_sc_validate_current_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_sc_validate_current_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_scene_clipboard_validate_current,.-gk_scene_clipboard_validate_current
        .type   gk_scene_clipboard_scene_equals_buffer,@function
gk_scene_clipboard_scene_equals_buffer:
        lea     -12(%sp),%sp
        movem.l %d2-%d3/%a2,(%sp)
        move.l  %d0,%d2
        cmpi.l  #15,%d2
        bhi.s   .Lgk_sc_scene_buffer_miss
        movea.l %a0,%a2
        lsl.l   #8,%d0
        adda.l  %d0,%a0
        adda.l  #GK_SCENE_ROWS_OFFSET,%a0
        move.l  #256,%d3
.Lgk_sc_scene_buffer_rows:
        move.b  (%a0)+,%d0
        cmp.b   (%a1)+,%d0
        bne.s   .Lgk_sc_scene_buffer_miss
        subq.l  #1,%d3
        bne.s   .Lgk_sc_scene_buffer_rows
        move.l  %d2,%d0
        mulu.w  #10,%d0
        movea.l %a2,%a0
        adda.l  %d0,%a0
        adda.l  #GK_SCENE_TAIL_OFFSET,%a0
        moveq   #10,%d3
.Lgk_sc_scene_buffer_tail:
        move.b  (%a0)+,%d0
        cmp.b   (%a1)+,%d0
        bne.s   .Lgk_sc_scene_buffer_miss
        subq.l  #1,%d3
        bne.s   .Lgk_sc_scene_buffer_tail
        moveq   #GK_OK,%d0
        bra.s   .Lgk_sc_scene_buffer_restore
.Lgk_sc_scene_buffer_miss:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_sc_scene_buffer_restore:
        .incbin "stock/0324.bin", 0, 4
        .incbin "stock/0324.bin", 4, 4
        .incbin "stock/0324.bin", 8, 2
        .size   gk_scene_clipboard_scene_equals_buffer,.-gk_scene_clipboard_scene_equals_buffer
        .type   gk_scene_clipboard_scene_is_clear,@function
gk_scene_clipboard_scene_is_clear:
        .incbin "stock/0324.bin", 10, 4
        .incbin "stock/0324.bin", 14, 4
        .incbin "stock/0324.bin", 18, 1
        .byte 0x00
        cmpi.l  #15,%d2
        bhi.s   .Lgk_sc_scene_clear_miss
        movea.l %a0,%a2
        lsl.l   #8,%d0
        adda.l  %d0,%a0
        adda.l  #GK_SCENE_ROWS_OFFSET,%a0
        move.l  #256,%d3
.Lgk_sc_scene_clear_rows:
        moveq   #0,%d0
        move.b  (%a0)+,%d0
        cmpi.b  #0xff,%d0
        bne.s   .Lgk_sc_scene_clear_miss
        subq.l  #1,%d3
        bne.s   .Lgk_sc_scene_clear_rows
        move.l  %d2,%d0
        mulu.w  #10,%d0
        movea.l %a2,%a0
        adda.l  %d0,%a0
        adda.l  #GK_SCENE_TAIL_OFFSET,%a0
        moveq   #10,%d3
.Lgk_sc_scene_clear_tail:
        moveq   #0,%d0
        move.b  (%a0)+,%d0
        cmpi.b  #0xff,%d0
        bne.s   .Lgk_sc_scene_clear_miss
        subq.l  #1,%d3
        bne.s   .Lgk_sc_scene_clear_tail
        moveq   #GK_OK,%d0
        bra.s   .Lgk_sc_scene_clear_restore
.Lgk_sc_scene_clear_miss:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_sc_scene_clear_restore:
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        rts
        .size   gk_scene_clipboard_scene_is_clear,.-gk_scene_clipboard_scene_is_clear
        .type   gk_scene_clipboard_validate_dirty,@function
gk_scene_clipboard_validate_dirty:
        moveq   #1,%d1
        move.l  %a2,%d0
        lsl.l   %d0,%d1
        .incbin "stock/0325.bin", 0, 6
        move.l  #0x95048,%d0
        move.b  (%a0,%d0.l),%d0
        andi.l  #0xff,%d0
        and.l   %d1,%d0
        beq.s   .Lgk_sc_dirty_miss
        moveq   #0,%d0
        move.b  0x100b145e,%d0
        and.l   %d1,%d0
        beq.s   .Lgk_sc_dirty_miss
        move.l  #0x9b332,%d0
        move.l  (%a0,%d0.l),%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_sc_dirty_miss
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_sc_dirty_miss
        moveq   #GK_OK,%d0
        rts
.Lgk_sc_dirty_miss:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_scene_clipboard_validate_dirty,.-gk_scene_clipboard_validate_dirty
        .type   gk_scene_clipboard_compare_both,@function
gk_scene_clipboard_compare_both:
        move.l  %a1,-(%sp)
        movea.l %a5,%a0
        move.l  %a4,%d0
        bsr.w   gk_scene_clipboard_scene_equals_buffer
        tst.l   %d0
        bne.s   .Lgk_sc_compare_both_restore
        movea.l (%sp),%a1
        move.l  %a2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a0
        adda.l  %d0,%a0
        move.l  %a4,%d0
        bsr.w   gk_scene_clipboard_scene_equals_buffer
.Lgk_sc_compare_both_restore:
        movea.l (%sp)+,%a1
        rts
        .size   gk_scene_clipboard_compare_both,.-gk_scene_clipboard_compare_both
        .type   gk_scene_clipboard_clear_both,@function
gk_scene_clipboard_clear_both:
        movea.l %a5,%a0
        move.l  %a4,%d0
        bsr.w   gk_scene_clipboard_scene_is_clear
        tst.l   %d0
        bne.s   .Lgk_sc_clear_both_return
        move.l  %a2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a0
        adda.l  %d0,%a0
        move.l  %a4,%d0
        bsr.w   gk_scene_clipboard_scene_is_clear
.Lgk_sc_clear_both_return:
        rts
        .size   gk_scene_clipboard_clear_both,.-gk_scene_clipboard_clear_both
        .type   gk_scene_clipboard_validate_result,@function
gk_scene_clipboard_validate_result:
        cmpi.l  #GK_SCENE_CLIPBOARD_ROUTE_COPY,%d7
        bne.s   .Lgk_sc_result_paste_none
        move.l  GK_STOCK_SCENE_COPY_TAG,%d0
        cmpi.l  #0x10,%d0
        bne.w   .Lgk_sc_result_miss
        tst.l   GK_STOCK_SCENE_UNDO_TAG
        bne.w   .Lgk_sc_result_miss
        tst.l   GK_STOCK_SCENE_UNDO_ACTION
        bne.w   .Lgk_sc_result_miss
        lea     GK_STOCK_SCENE_COPY_BUFFER,%a1
        movea.l %a5,%a0
        move.l  %a4,%d0
        bra.w   gk_scene_clipboard_scene_equals_buffer
.Lgk_sc_result_paste_none:
        cmpi.l  #GK_SCENE_CLIPBOARD_ROUTE_PASTE_NONE,%d7
        bne.s   .Lgk_sc_result_paste_undo
        tst.l   GK_STOCK_SCENE_UNDO_TAG
        bne.w   .Lgk_sc_result_miss
        tst.l   GK_STOCK_SCENE_UNDO_ACTION
        bne.w   .Lgk_sc_result_miss
        lea     GK_STOCK_SCENE_UNDO_BUFFER,%a1
        bra.w   gk_scene_clipboard_compare_both
.Lgk_sc_result_paste_undo:
        cmpi.l  #GK_SCENE_CLIPBOARD_ROUTE_PASTE_UNDO,%d7
        bne.s   .Lgk_sc_result_paste_copy
        tst.l   GK_STOCK_SCENE_UNDO_TAG
        bne.w   .Lgk_sc_result_miss
        tst.l   GK_STOCK_SCENE_UNDO_ACTION
        bne.w   .Lgk_sc_result_miss
        lea     GK_STOCK_SCENE_UNDO_BUFFER,%a1
        bsr.w   gk_scene_clipboard_compare_both
        bra.w   .Lgk_sc_result_written
.Lgk_sc_result_paste_copy:
        cmpi.l  #GK_SCENE_CLIPBOARD_ROUTE_PASTE_COPY,%d7
        bne.s   .Lgk_sc_result_clear_undo
        move.l  GK_STOCK_SCENE_UNDO_TAG,%d0
        cmpi.l  #0x10,%d0
        bne.w   .Lgk_sc_result_miss
        move.l  GK_STOCK_SCENE_UNDO_ACTION,%d0
        cmpi.l  #0x21,%d0
        bne.w   .Lgk_sc_result_miss
        move.l  %a2,%d0
        cmp.l   GK_STOCK_SCENE_UNDO_PART,%d0
        bne.w   .Lgk_sc_result_miss
        move.l  %a4,%d0
        cmp.l   GK_STOCK_SCENE_UNDO_SCENE,%d0
        bne.w   .Lgk_sc_result_miss
        lea     GK_STOCK_SCENE_COPY_BUFFER,%a1
        bsr.w   gk_scene_clipboard_compare_both
        bra.s   .Lgk_sc_result_written
.Lgk_sc_result_clear_undo:
        cmpi.l  #GK_SCENE_CLIPBOARD_ROUTE_CLEAR_UNDO,%d7
        bne.s   .Lgk_sc_result_clear_new
        tst.l   GK_STOCK_SCENE_UNDO_TAG
        bne.w   .Lgk_sc_result_miss
        tst.l   GK_STOCK_SCENE_UNDO_ACTION
        bne.w   .Lgk_sc_result_miss
        lea     GK_STOCK_SCENE_UNDO_BUFFER,%a1
        bsr.w   gk_scene_clipboard_compare_both
        bra.s   .Lgk_sc_result_written
.Lgk_sc_result_clear_new:
        cmpi.l  #GK_SCENE_CLIPBOARD_ROUTE_CLEAR_NEW,%d7
        bne.s   .Lgk_sc_result_miss
        move.l  GK_STOCK_SCENE_UNDO_TAG,%d0
        cmpi.l  #0x10,%d0
        bne.s   .Lgk_sc_result_miss
        move.l  GK_STOCK_SCENE_UNDO_ACTION,%d0
        cmpi.l  #0x22,%d0
        bne.s   .Lgk_sc_result_miss
        move.l  %a2,%d0
        cmp.l   GK_STOCK_SCENE_UNDO_PART,%d0
        bne.s   .Lgk_sc_result_miss
        move.l  %a4,%d0
        cmp.l   GK_STOCK_SCENE_UNDO_SCENE,%d0
        bne.s   .Lgk_sc_result_miss
        bsr.w   gk_scene_clipboard_clear_both
.Lgk_sc_result_written:
        tst.l   %d0
        bne.s   .Lgk_sc_result_miss
        bra.w   gk_scene_clipboard_validate_dirty
.Lgk_sc_result_miss:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_scene_clipboard_validate_result,.-gk_scene_clipboard_validate_result
        .type   gk_scene_clipboard_return_stock,@function
gk_scene_clipboard_return_stock:
        bsr.w   gk_scene_clipboard_clear_private
        moveq   #0,%d2
        move.w  GK_SC_OUTPUT_SR(%a6),%d2
        move.w  %d2,%sr
        move.l  GK_SC_OUTPUT_D0(%a6),%d0
        move.l  GK_SC_OUTPUT_D1(%a6),%d1
        movea.l GK_SC_OUTPUT_A0(%a6),%a0
        movea.l GK_SC_OUTPUT_A1(%a6),%a1
        movem.l (%a6),%d2-%d7/%a2-%a6
        lea     GK_SC_FRAME_SIZE(%sp),%sp
        rts
        .size   gk_scene_clipboard_return_stock,.-gk_scene_clipboard_return_stock
        .type   gk_scene_clipboard_finish_copy,@function
gk_scene_clipboard_finish_copy:
        bsr.w   gk_scene_clipboard_validate_current
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_fatal
        bsr.w   gk_scene_clipboard_validate_result
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_fatal
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_clipboard_private_fatal
        bra.w   gk_scene_clipboard_return_stock
        .size   gk_scene_clipboard_finish_copy,.-gk_scene_clipboard_finish_copy
        .type   gk_scene_clipboard_finish_update,@function
gk_scene_clipboard_finish_update:
        bsr.w   gk_scene_clipboard_validate_current
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_abort_fatal
        bsr.w   gk_scene_clipboard_validate_result
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_abort_fatal
        cmpi.l  #GK_SCENE_CLIPBOARD_ROUTE_PASTE_NONE,%d7
        bne.s   .Lgk_sc_finish_written
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_clipboard_private_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_scene_clipboard_private_fatal
        bra.w   gk_scene_clipboard_return_stock
.Lgk_sc_finish_written:
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_abort_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_abort_fatal
        bsr.w   gk_scene_clipboard_validate_current
        tst.l   %d0
        bne.w   gk_scene_clipboard_release_fatal
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_clipboard_private_fatal
        bra.w   gk_scene_clipboard_return_stock
        .size   gk_scene_clipboard_finish_update,.-gk_scene_clipboard_finish_update
        .global gk_stock_scene_copy_callback
        .type gk_stock_scene_copy_callback,@function
gk_stock_scene_copy_callback:
        move.l %d0,-(%sp)
        move.l 8(%sp),%d0
        cmpi.l #GK_SCENE_CLIPBOARD_COPY,%d0
        bne.w gk_scene_clipboard_fatal
        move.l 12(%sp),%d0
        cmpi.l #1,%d0
        beq.s .Lgk_sc_wrapper_accepted_0
        move.l (%sp)+,%d0
        jmp GK_STOCK_SCENE_COPY_CALLBACK
.Lgk_sc_wrapper_accepted_0:
        move.l (%sp)+,%d0
        .incbin "stock/0326.bin", 0, 4
        .incbin "stock/0326.bin", 4, 4
        movea.l %sp,%a6
        move.l %d0,GK_SC_INPUT_D0(%a6)
        move.l %d1,GK_SC_INPUT_D1(%a6)
        move.l %a0,GK_SC_INPUT_A0(%a6)
        move.l %a1,GK_SC_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_SC_INPUT_SR(%a6)
        moveq #GK_SCENE_CLIPBOARD_COPY,%d2
        move.l %d2,GK_SC_KIND(%a6)
        bsr.w gk_scene_clipboard_prepare_copy
        move.l GK_SC_FRAME_SIZE+8(%a6),-(%sp)
        move.l GK_SC_FRAME_SIZE+4(%a6),-(%sp)
        move.l GK_SC_INPUT_D0(%a6),%d0
        move.l GK_SC_INPUT_D1(%a6),%d1
        movea.l GK_SC_INPUT_A0(%a6),%a0
        movea.l GK_SC_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_SC_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        .global gk_scene_clipboard_copy_stock_call
gk_scene_clipboard_copy_stock_call:
        jsr GK_STOCK_SCENE_COPY_CALLBACK
        addq.l #8,%sp
        move.l %d0,GK_SC_OUTPUT_D0(%a6)
        move.l %d1,GK_SC_OUTPUT_D1(%a6)
        move.l %a0,GK_SC_OUTPUT_A0(%a6)
        move.l %a1,GK_SC_OUTPUT_A1(%a6)
        move.w %sr,%d0
        move.w %d0,GK_SC_OUTPUT_SR(%a6)
        jmp gk_scene_clipboard_finish_copy
        .size gk_stock_scene_copy_callback,.-gk_stock_scene_copy_callback
        .global gk_stock_scene_paste_callback
        .type gk_stock_scene_paste_callback,@function
gk_stock_scene_paste_callback:
        move.l %d0,-(%sp)
        move.l 8(%sp),%d0
        cmpi.l #GK_SCENE_CLIPBOARD_PASTE,%d0
        bne.w gk_scene_clipboard_fatal
        move.l 12(%sp),%d0
        cmpi.l #1,%d0
        beq.s .Lgk_sc_wrapper_accepted_2
        move.l (%sp)+,%d0
        jmp GK_STOCK_SCENE_PASTE_CALLBACK
.Lgk_sc_wrapper_accepted_2:
        move.l (%sp)+,%d0
        .incbin "stock/0327.bin", 0, 4
        .incbin "stock/0327.bin", 4, 4
        movea.l %sp,%a6
        move.l %d0,GK_SC_INPUT_D0(%a6)
        move.l %d1,GK_SC_INPUT_D1(%a6)
        move.l %a0,GK_SC_INPUT_A0(%a6)
        move.l %a1,GK_SC_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_SC_INPUT_SR(%a6)
        moveq #GK_SCENE_CLIPBOARD_PASTE,%d2
        move.l %d2,GK_SC_KIND(%a6)
        bsr.w gk_scene_clipboard_prepare_update
        bsr.w gk_scene_clipboard_classify_paste
        move.l GK_SC_FRAME_SIZE+8(%a6),-(%sp)
        move.l GK_SC_FRAME_SIZE+4(%a6),-(%sp)
        move.l GK_SC_INPUT_D0(%a6),%d0
        move.l GK_SC_INPUT_D1(%a6),%d1
        movea.l GK_SC_INPUT_A0(%a6),%a0
        movea.l GK_SC_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_SC_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        .global gk_scene_clipboard_paste_stock_call
gk_scene_clipboard_paste_stock_call:
        jsr GK_STOCK_SCENE_PASTE_CALLBACK
        addq.l #8,%sp
        move.l %d0,GK_SC_OUTPUT_D0(%a6)
        move.l %d1,GK_SC_OUTPUT_D1(%a6)
        move.l %a0,GK_SC_OUTPUT_A0(%a6)
        move.l %a1,GK_SC_OUTPUT_A1(%a6)
        move.w %sr,%d0
        move.w %d0,GK_SC_OUTPUT_SR(%a6)
        jmp gk_scene_clipboard_finish_update
        .size gk_stock_scene_paste_callback,.-gk_stock_scene_paste_callback
        .global gk_stock_scene_clear_callback
        .type gk_stock_scene_clear_callback,@function
gk_stock_scene_clear_callback:
        move.l %d0,-(%sp)
        move.l 8(%sp),%d0
        cmpi.l #GK_SCENE_CLIPBOARD_CLEAR,%d0
        bne.w gk_scene_clipboard_fatal
        move.l 12(%sp),%d0
        cmpi.l #1,%d0
        beq.s .Lgk_sc_wrapper_accepted_4
        move.l (%sp)+,%d0
        jmp GK_STOCK_SCENE_CLEAR_CALLBACK
.Lgk_sc_wrapper_accepted_4:
        move.l (%sp)+,%d0
        .incbin "stock/0328.bin", 0, 4
        .incbin "stock/0328.bin", 4, 4
        movea.l %sp,%a6
        move.l %d0,GK_SC_INPUT_D0(%a6)
        move.l %d1,GK_SC_INPUT_D1(%a6)
        move.l %a0,GK_SC_INPUT_A0(%a6)
        move.l %a1,GK_SC_INPUT_A1(%a6)
        move.w %sr,%d2
        move.w %d2,GK_SC_INPUT_SR(%a6)
        moveq #GK_SCENE_CLIPBOARD_CLEAR,%d2
        move.l %d2,GK_SC_KIND(%a6)
        bsr.w gk_scene_clipboard_prepare_update
        bsr.w gk_scene_clipboard_classify_clear
        move.l GK_SC_FRAME_SIZE+8(%a6),-(%sp)
        move.l GK_SC_FRAME_SIZE+4(%a6),-(%sp)
        move.l GK_SC_INPUT_D0(%a6),%d0
        move.l GK_SC_INPUT_D1(%a6),%d1
        movea.l GK_SC_INPUT_A0(%a6),%a0
        movea.l GK_SC_INPUT_A1(%a6),%a1
        moveq #0,%d2
        move.w GK_SC_INPUT_SR(%a6),%d2
        move.w %d2,%sr
        .global gk_scene_clipboard_clear_stock_call
gk_scene_clipboard_clear_stock_call:
        jsr GK_STOCK_SCENE_CLEAR_CALLBACK
        addq.l #8,%sp
        move.l %d0,GK_SC_OUTPUT_D0(%a6)
        move.l %d1,GK_SC_OUTPUT_D1(%a6)
        move.l %a0,GK_SC_OUTPUT_A0(%a6)
        move.l %a1,GK_SC_OUTPUT_A1(%a6)
        move.w %sr,%d0
        move.w %d0,GK_SC_OUTPUT_SR(%a6)
        jmp gk_scene_clipboard_finish_update
        .size gk_stock_scene_clear_callback,.-gk_stock_scene_clear_callback
        .global gk_scene_clipboard_fatal
gk_scene_clipboard_fatal:
        illegal
        bra.s   gk_scene_clipboard_fatal
