        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_machine_selection_abort_fatal,@function
gk_machine_selection_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_machine_selection_fatal
        bra.w   gk_machine_selection_fatal
        .size   gk_machine_selection_abort_fatal,.-gk_machine_selection_abort_fatal
        .type   gk_machine_selection_release_abort_fatal_d0,@function
gk_machine_selection_release_abort_fatal_d0:
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_machine_selection_fatal
        bra.w   gk_machine_selection_abort_fatal
        .size   gk_machine_selection_release_abort_fatal_d0,.-gk_machine_selection_release_abort_fatal_d0
        .type   gk_machine_selection_release_abort_fatal,@function
gk_machine_selection_release_abort_fatal:
        move.l  %d6,%d0
        bra.w   gk_machine_selection_release_abort_fatal_d0
        .size   gk_machine_selection_release_abort_fatal,.-gk_machine_selection_release_abort_fatal
        .type   gk_machine_selection_release_fatal,@function
gk_machine_selection_release_fatal:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        bra.w   gk_machine_selection_fatal
        .size   gk_machine_selection_release_fatal,.-gk_machine_selection_release_fatal
        .type   gk_machine_selection_prepare,@function
gk_machine_selection_prepare:
        cmpi.l  #1,%d0
        beq.s   .Lgk_machine_prepare_effect_ok
        cmpi.l  #2,%d0
        bne.w   gk_machine_selection_fatal
.Lgk_machine_prepare_effect_ok:
        movea.l %d0,%a5
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_machine_selection_fatal
        movea.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_machine_selection_fatal
        movea.l %d0,%a3
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_machine_prepare_busy
        tst.l   %d0
        bmi.w   gk_machine_selection_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_machine_selection_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a3,%d1
        cmp.l   %d1,%d0
        bne.w   gk_machine_selection_fatal
        move.l  %a5,%d1
        cmpi.l  #1,%d1
        beq.s   .Lgk_machine_prepare_fx1
        move.l  GK_STOCK_MACHINE_SELECT_FX2_SELECTION,%d0
        cmpi.l  #14,%d0
        bhi.w   gk_machine_selection_fatal
        move.l  %d0,%d1
        lsl.l   #2,%d1
        lea     GK_STOCK_MACHINE_SELECT_FX2_TABLE,%a0
        movea.l (%a0,%d1.l),%a6
        lea     GK_STOCK_MACHINE_SELECT_FX2_DEFINITIONS,%a1
        bra.s   .Lgk_machine_prepare_definition
.Lgk_machine_prepare_fx1:
        move.l  GK_STOCK_MACHINE_SELECT_FX1_SELECTION,%d0
        cmpi.l  #10,%d0
        bhi.w   gk_machine_selection_fatal
        move.l  %d0,%d1
        lsl.l   #2,%d1
        lea     GK_STOCK_MACHINE_SELECT_FX1_TABLE,%a0
        movea.l (%a0,%d1.l),%a6
        lea     GK_STOCK_MACHINE_SELECT_FX1_DEFINITIONS,%a1
.Lgk_machine_prepare_definition:
        cmpa.l  #0,%a6
        beq.w   gk_machine_selection_fatal
        move.l  (%a6),%d1
        cmpi.l  #28,%d1
        bhi.w   gk_machine_selection_fatal
        lsl.l   #2,%d1
        movea.l (%a1,%d1.l),%a0
        cmpa.l  %a6,%a0
        bne.w   gk_machine_selection_fatal
        move.l  %a2,%d2
        lsl.l   #8,%d2
        lsl.l   #8,%d2
        move.l  %d0,%d1
        lsl.l   #8,%d1
        or.l    %d1,%d2
        move.l  %a3,%d1
        lsl.l   #4,%d1
        or.l    %d1,%d2
        move.l  %a5,%d1
        or.l    %d1,%d2
        movea.l %d2,%a5
        move.l  %a2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        movea.l GK_STOCK_BANK_POINTER,%a2
        adda.l  %d0,%a2
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a2
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        move.l  %a5,%d0
        lsr.l   #4,%d0
        andi.l  #7,%d0
        movea.l %a2,%a0
        adda.l  %d0,%a0
        move.l  %a5,%d1
        andi.l  #0x0f,%d1
        cmpi.l  #1,%d1
        beq.s   .Lgk_machine_prepare_old_read
        adda.l  #8,%a0
.Lgk_machine_prepare_old_read:
        moveq   #0,%d7
        move.b  (%a0),%d7
        cmpi.l  #28,%d7
        bhi.w   gk_machine_selection_fatal
        movea.l %a3,%a0
        move.l  %a5,%d0
        lsr.l   #4,%d0
        andi.l  #7,%d0
        adda.l  %d0,%a0
        move.l  %a5,%d1
        andi.l  #0x0f,%d1
        cmpi.l  #1,%d1
        beq.s   .Lgk_machine_prepare_mirror_read
        adda.l  #8,%a0
.Lgk_machine_prepare_mirror_read:
        cmp.b   (%a0),%d7
        bne.w   gk_machine_selection_fatal
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_machine_selection_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_machine_prepare_busy
        tst.l   %d0
        bmi.w   gk_machine_selection_fatal
        cmp.l   %d6,%d0
        bne.w   gk_machine_selection_abort_fatal
        cmpa.l  %a2,%a0
        bne.w   gk_machine_selection_abort_fatal
        move.l  %a5,%d2
        lsr.l   #8,%d2
        lsr.l   #8,%d2
        andi.l  #3,%d2
        cmp.l   %d2,%d1
        bne.w   gk_machine_selection_abort_fatal
        move.l  %d4,%d0
        move.l  %d2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_machine_selection_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_machine_selection_release_abort_fatal_d0
        cmpa.l  %a2,%a0
        bne.w   gk_machine_selection_release_abort_fatal
        moveq   #GK_OK,%d0
        rts
.Lgk_machine_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_machine_selection_prepare,.-gk_machine_selection_prepare
        .type   gk_machine_selection_validate_selection,@function
gk_machine_selection_validate_selection:
        move.l  %a5,%d0
        lsr.l   #8,%d0
        andi.l  #0x0f,%d0
        move.l  %a5,%d1
        andi.l  #0x0f,%d1
        cmpi.l  #1,%d1
        beq.s   .Lgk_machine_validate_fx1
        cmpi.l  #2,%d1
        bne.w   gk_machine_selection_release_abort_fatal
        cmp.l   GK_STOCK_MACHINE_SELECT_FX2_SELECTION,%d0
        bne.w   gk_machine_selection_release_abort_fatal
        lea     GK_STOCK_MACHINE_SELECT_FX2_TABLE,%a0
        lea     GK_STOCK_MACHINE_SELECT_FX2_DEFINITIONS,%a1
        bra.s   .Lgk_machine_validate_pointer
.Lgk_machine_validate_fx1:
        cmp.l   GK_STOCK_MACHINE_SELECT_FX1_SELECTION,%d0
        bne.w   gk_machine_selection_release_abort_fatal
        lea     GK_STOCK_MACHINE_SELECT_FX1_TABLE,%a0
        lea     GK_STOCK_MACHINE_SELECT_FX1_DEFINITIONS,%a1
.Lgk_machine_validate_pointer:
        lsl.l   #2,%d0
        movea.l (%a0,%d0.l),%a0
        cmpa.l  %a6,%a0
        bne.w   gk_machine_selection_release_abort_fatal
        move.l  (%a6),%d2
        cmpi.l  #28,%d2
        bhi.w   gk_machine_selection_release_abort_fatal
        move.l  %d2,%d0
        lsl.l   #2,%d0
        movea.l (%a1,%d0.l),%a0
        cmpa.l  %a6,%a0
        bne.w   gk_machine_selection_release_abort_fatal
        rts
        .size   gk_machine_selection_validate_selection,.-gk_machine_selection_validate_selection
        .type   gk_machine_selection_validate_payload,@function
gk_machine_selection_validate_payload:
        move.l  %a5,%d3
        lsr.l   #4,%d3
        andi.l  #7,%d3
        movea.l %a2,%a0
        movea.l %a3,%a1
        adda.l  %d3,%a0
        adda.l  %d3,%a1
        move.l  %a5,%d0
        andi.l  #0x0f,%d0
        cmpi.l  #1,%d0
        beq.s   .Lgk_machine_payload_selector
        adda.l  #8,%a0
        adda.l  #8,%a1
.Lgk_machine_payload_selector:
        cmp.b   (%a0),%d2
        bne.w   gk_machine_selection_release_abort_fatal
        cmp.b   (%a1),%d2
        bne.w   gk_machine_selection_release_abort_fatal
        move.l  %d3,%d0
        mulu.w  #24,%d0
        movea.l %a2,%a0
        movea.l %a3,%a1
        adda.l  %d0,%a0
        adda.l  %d0,%a1
        move.l  %a5,%d1
        andi.l  #0x0f,%d1
        cmpi.l  #1,%d1
        beq.s   .Lgk_machine_payload_fx1_first
        adda.l  #0x12c,%a0
        adda.l  #0x12c,%a1
        bra.s   .Lgk_machine_payload_first
.Lgk_machine_payload_fx1_first:
        adda.l  #0x126,%a0
        adda.l  #0x126,%a1
.Lgk_machine_payload_first:
        lea     94(%a6),%a4
        moveq   #5,%d1
.Lgk_machine_payload_first_loop:
        move.b  (%a4)+,%d0
        cmp.b   (%a0)+,%d0
        bne.w   gk_machine_selection_release_abort_fatal
        cmp.b   (%a1)+,%d0
        bne.w   gk_machine_selection_release_abort_fatal
        subq.l  #1,%d1
        bpl.s   .Lgk_machine_payload_first_loop
        move.l  %d3,%d0
        mulu.w  #30,%d0
        movea.l %a2,%a0
        movea.l %a3,%a1
        adda.l  %d0,%a0
        adda.l  %d0,%a1
        move.l  %a5,%d1
        andi.l  #0x0f,%d1
        cmpi.l  #1,%d1
        beq.s   .Lgk_machine_payload_fx1_second
        adda.l  #0x304,%a0
        adda.l  #0x304,%a1
        bra.s   .Lgk_machine_payload_second
.Lgk_machine_payload_fx1_second:
        adda.l  #0x2fe,%a0
        adda.l  #0x2fe,%a1
.Lgk_machine_payload_second:
        lea     100(%a6),%a4
        moveq   #5,%d1
.Lgk_machine_payload_second_loop:
        move.b  (%a4)+,%d0
        cmp.b   (%a0)+,%d0
        bne.w   gk_machine_selection_release_abort_fatal
        cmp.b   (%a1)+,%d0
        bne.w   gk_machine_selection_release_abort_fatal
        subq.l  #1,%d1
        bpl.s   .Lgk_machine_payload_second_loop
        rts
        .size   gk_machine_selection_validate_payload,.-gk_machine_selection_validate_payload
        .type   gk_machine_selection_post_context_match,@function
gk_machine_selection_post_context_match:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.s   .Lgk_machine_context_miss
        cmp.l   %d4,%d0
        bne.s   .Lgk_machine_context_miss
        cmp.l   %d5,%d1
        bne.s   .Lgk_machine_context_miss
        move.l  %a5,%d2
        lsr.l   #8,%d2
        lsr.l   #8,%d2
        andi.l  #3,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_machine_context_miss
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_machine_context_miss
        move.l  %a5,%d2
        lsr.l   #4,%d2
        andi.l  #7,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_machine_context_miss
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_machine_context_miss
        moveq   #0,%d0
        rts
.Lgk_machine_context_miss:
        moveq   #-1,%d0
        rts
        .size   gk_machine_selection_post_context_match,.-gk_machine_selection_post_context_match
        .type   gk_machine_selection_finish,@function
gk_machine_selection_finish:
        moveq   #0,%d0
        move.w  %sr,%d0
        andi.l  #0x0700,%d0
        cmpi.l  #0x0200,%d0
        bhs.s   .Lgk_machine_selection_finish_guarded
        move.w  #0x2200,%sr
.Lgk_machine_selection_finish_guarded:
        bsr.w   gk_machine_selection_validate_selection
        cmp.l   %d7,%d2
        beq.s   .Lgk_machine_selection_no_write
        bsr.w   gk_machine_selection_validate_payload
        move.l  %a5,%d3
        lsr.l   #8,%d3
        lsr.l   #8,%d3
        andi.l  #3,%d3
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_machine_selection_release_abort_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_machine_selection_fatal
        bra.s   .Lgk_machine_selection_post_validate
.Lgk_machine_selection_no_write:
        move.l  %a5,%d0
        lsr.l   #4,%d0
        andi.l  #7,%d0
        movea.l %a2,%a0
        adda.l  %d0,%a0
        move.l  %a5,%d1
        andi.l  #0x0f,%d1
        cmpi.l  #1,%d1
        beq.s   .Lgk_machine_no_write_compare
        adda.l  #8,%a0
.Lgk_machine_no_write_compare:
        cmp.b   (%a0),%d7
        bne.w   gk_machine_selection_release_abort_fatal
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_machine_selection_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_machine_selection_fatal
        bsr.w   gk_machine_selection_post_context_match
        tst.l   %d0
        bne.w   gk_machine_selection_fatal
        rts
.Lgk_machine_selection_post_validate:
        bsr.w   gk_machine_selection_post_context_match
        tst.l   %d0
        bne.w   gk_machine_selection_release_fatal
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_machine_selection_fatal
        rts
        .size   gk_machine_selection_finish,.-gk_machine_selection_finish
        .global gk_stock_machine_select_fx1
        .type gk_stock_machine_select_fx1,@function
gk_stock_machine_select_fx1:
        move.l %d0,-(%sp)
        move.l __gk_lifecycle_state,%d0
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_LIFECYCLE_QUIESCED,%d0
        beq.s 2f
        bra.w gk_machine_selection_fatal
1:
        move.l (%sp)+,%d0
        bra.s 3f
2:
        move.l (%sp)+,%d0
        rts
3:
        lea -64(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,44(%sp)
        move.l %d1,48(%sp)
        move.l %a0,52(%sp)
        move.l %a1,56(%sp)
        move.w %sr,%d2
        move.w %d2,60(%sp)
        moveq #1,%d0
        bsr.w gk_machine_selection_prepare
        cmpi.l #GK_ERR_BUSY,%d0
        beq.w gk_machine_selection_busy_saved
        tst.l %d0
        bne.w gk_machine_selection_fatal
        move.l 44(%sp),%d0
        move.l 48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        bsr.w gk_stock_machine_select_fx1_trampoline
        move.w %sr,%d2
        move.w %d2,60(%sp)
        move.l %d0,44(%sp)
        move.l %d1,48(%sp)
        move.l %a0,52(%sp)
        move.l %a1,56(%sp)
        bsr.w gk_machine_selection_finish
        movem.l (%sp),%d2-%d7/%a2-%a6
        move.l 44(%sp),%d0
        move.l 48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        move.w 60(%sp),%d2
        move.w %d2,%sr
        movem.l (%sp),%d2
        lea 64(%sp),%sp
        rts
        .size gk_stock_machine_select_fx1,.-gk_stock_machine_select_fx1
        .global gk_stock_machine_select_fx2
        .type gk_stock_machine_select_fx2,@function
gk_stock_machine_select_fx2:
        move.l %d0,-(%sp)
        move.l __gk_lifecycle_state,%d0
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_LIFECYCLE_QUIESCED,%d0
        beq.s 2f
        bra.w gk_machine_selection_fatal
1:
        move.l (%sp)+,%d0
        bra.s 3f
2:
        move.l (%sp)+,%d0
        rts
3:
        lea -64(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,44(%sp)
        move.l %d1,48(%sp)
        move.l %a0,52(%sp)
        move.l %a1,56(%sp)
        move.w %sr,%d2
        move.w %d2,60(%sp)
        moveq #2,%d0
        bsr.w gk_machine_selection_prepare
        cmpi.l #GK_ERR_BUSY,%d0
        beq.w gk_machine_selection_busy_saved
        tst.l %d0
        bne.w gk_machine_selection_fatal
        move.l 44(%sp),%d0
        move.l 48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        bsr.w gk_stock_machine_select_fx2_trampoline
        move.w %sr,%d2
        move.w %d2,60(%sp)
        move.l %d0,44(%sp)
        move.l %d1,48(%sp)
        move.l %a0,52(%sp)
        move.l %a1,56(%sp)
        bsr.w gk_machine_selection_finish
        movem.l (%sp),%d2-%d7/%a2-%a6
        move.l 44(%sp),%d0
        move.l 48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        move.w 60(%sp),%d2
        move.w %d2,%sr
        movem.l (%sp),%d2
        lea 64(%sp),%sp
        rts
        .size gk_stock_machine_select_fx2,.-gk_stock_machine_select_fx2
        .type   gk_machine_selection_busy_saved,@function
gk_machine_selection_busy_saved:
        move.l  44(%sp),%d0
        move.l  48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        move.w  60(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     64(%sp),%sp
        rts
        .size   gk_machine_selection_busy_saved,.-gk_machine_selection_busy_saved
        .global gk_stock_machine_select_fx1_trampoline
        .type   gk_stock_machine_select_fx1_trampoline,@function
gk_stock_machine_select_fx1_trampoline:
        .incbin "stock/0290.bin", 0, 4
        .incbin "stock/0290.bin", 4, 4
        jmp     GK_STOCK_MACHINE_SELECT_FX1_CONTINUE
        .size   gk_stock_machine_select_fx1_trampoline,.-gk_stock_machine_select_fx1_trampoline
        .global gk_stock_machine_select_fx2_trampoline
        .type   gk_stock_machine_select_fx2_trampoline,@function
gk_stock_machine_select_fx2_trampoline:
        .incbin "stock/0291.bin", 0, 4
        .incbin "stock/0291.bin", 4, 4
        jmp     GK_STOCK_MACHINE_SELECT_FX2_CONTINUE
        .size   gk_stock_machine_select_fx2_trampoline,.-gk_stock_machine_select_fx2_trampoline
        .global gk_machine_selection_fatal
        .type   gk_machine_selection_fatal,@function
gk_machine_selection_fatal:
        illegal
        bra.s   gk_machine_selection_fatal
        .size   gk_machine_selection_fatal,.-gk_machine_selection_fatal
