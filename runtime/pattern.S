        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_pattern_schedule_prepare
        .type   gk_stock_pattern_schedule_prepare,@function
gk_stock_pattern_schedule_prepare:
        move.l  %d0,-(%sp)
        move.l  48(%sp),%d0
        cmpi.l  #GK_STOCK_PATTERN_PROJECT_LOAD_REQUEST_RETURN,%d0
        beq.s   .Lgk_pattern_schedule_quiesced_stock_check
        cmpi.l  #GK_STOCK_PATTERN_BOOT_REQUEST_RETURN,%d0
        bne.s   .Lgk_pattern_schedule_global_kit_restore
.Lgk_pattern_schedule_quiesced_stock_check:
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_pattern_schedule_boot_stock_restore
.Lgk_pattern_schedule_global_kit_restore:
        move.l  (%sp)+,%d0
.Lgk_pattern_schedule_global_kit:
        bra.s   .Lgk_pattern_schedule_global_kit_ready
.Lgk_pattern_schedule_boot_stock_restore:
        move.l  (%sp)+,%d0
        bra.w   .Lgk_pattern_schedule_boot_stock
.Lgk_pattern_schedule_global_kit_ready:
        .global gk_pattern_schedule_global_kit_entry
gk_pattern_schedule_global_kit_entry:
        lea     -16(%sp),%sp
        movem.l %d2-%d3/%d7/%a2,(%sp)
        move.l  36(%sp),%d0
        bsr.w   gk_arranger_publisher_owner_from_return
        tst.l   %d0
        bmi.w   gk_arranger_fatal_pattern_publish_owner
        move.l  %d0,%d3
        cmpi.l  #15,%d4
        bhi.w   .Lgk_pattern_schedule_cancel
        cmpi.l  #15,%d5
        bhi.w   .Lgk_pattern_schedule_cancel
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        tst.l   %d3
        beq.s   .Lgk_pattern_schedule_ordinary_prepare
        move.l  %d4,%d0
        move.l  %d5,%d1
        bsr.w   gk_arranger_transition_adopt
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        beq.s   .Lgk_pattern_schedule_ordinary_prepare
        tst.l   %d0
        bmi.w   .Lgk_pattern_schedule_cancel
        moveq   #1,%d3
        move.l  %d1,%d7
        movea.l %a0,%a2
        bra.s   .Lgk_pattern_schedule_publish_assignment
.Lgk_pattern_schedule_ordinary_prepare:
        tst.b   __gk_pattern_queue_commit_prepared
        beq.s   .Lgk_pattern_schedule_ordinary_prepare_new
        cmpi.l  #GK_ARRANGER_OWNER_TOKEN,%d3
        beq.s   .Lgk_pattern_schedule_prepared_owner
        jmp     gk_pattern_queue_commit_prepared_fatal
.Lgk_pattern_schedule_prepared_owner:
        move.l  %d4,%d0
        move.l  %d5,%d1
        jsr     gk_pattern_queue_commit_prepared_take
        tst.l   %d0
        bpl.s   .Lgk_pattern_schedule_prepared_taken
        jmp     gk_pattern_queue_commit_prepared_fatal
.Lgk_pattern_schedule_prepared_taken:
        move.l  %d0,%d7
        movea.l %d1,%a2
        moveq   #0,%d3
        bra.w   .Lgk_pattern_schedule_publish_assignment
.Lgk_pattern_schedule_ordinary_prepare_new:
        moveq   #0,%d3
        move.l  %d4,%d0
        move.l  %d5,%d1
        bsr.w   gk_workspace_prepare
        tst.l   %d0
        bmi.w   .Lgk_pattern_schedule_cancel
        move.l  %d0,%d7
        movea.l %d1,%a2
        move.l  %d7,%d0
        bsr.w   gk_ui_transition_prepare
        tst.l   %d0
        bmi.w   .Lgk_pattern_schedule_capture_failed
.Lgk_pattern_schedule_publish_assignment:
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        jsr     gk_ui_carried_pattern_lag_publish
        tst.l   %d0
        bne.w   gk_pattern_transition_pre_engine_fatal
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d5,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a0
        move.l  %a2,%d0
        .global gk_pattern_resident_assignment_publication
gk_pattern_resident_assignment_publication:
        move.b  %d0,(%a0)
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.s   .Lgk_pattern_schedule_engine
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a0
        move.l  %a2,%d0
        .global gk_pattern_mirror_assignment_publication
gk_pattern_mirror_assignment_publication:
        move.b  %d0,(%a0)
.Lgk_pattern_schedule_engine:
        move.l  %a2,-(%sp)
        move.l  %d4,-(%sp)
        .global gk_pattern_stock_engine_call
gk_pattern_stock_engine_call:
        jsr     GK_STOCK_ENGINE_PATTERN_PART_LOAD
        bsr.w   gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_pattern_transition_post_engine_fatal
        lea     __gk_lease_sidecars,%a0
        jsr     gk_selector_acquire
        tst.l   %d0
        bmi.w   gk_pattern_transition_post_engine_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   .Lgk_pattern_schedule_release_fatal
        bsr.w   gk_stock_latest_engine_context_validate
        tst.l   %d0
        bmi.w   .Lgk_pattern_schedule_release_fatal
        cmp.l   %d4,%d0
        bne.w   .Lgk_pattern_schedule_release_fatal
        cmp.l   %d5,%d1
        bne.w   .Lgk_pattern_schedule_release_fatal
        cmpa.l  %a2,%a0
        bne.w   .Lgk_pattern_schedule_release_fatal
        move.l  %d2,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_pattern_transition_post_engine_fatal
        tst.l   %d3
        beq.s   .Lgk_pattern_schedule_retry_ui
        bsr.w   gk_arranger_consume_finish
        tst.l   %d0
        bne.w   gk_pattern_transition_post_engine_fatal
.Lgk_pattern_schedule_retry_ui:
        jsr     gk_ui_transition_retry_ensure
        tst.l   %d0
        beq.s   .Lgk_pattern_schedule_complete
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.w   gk_pattern_transition_retry_overflow_fatal
        bra.w   gk_pattern_transition_retry_corrupt_fatal
.Lgk_pattern_schedule_complete:
        movem.l 8(%sp),%d2-%d3/%d7/%a2
        lea     16(%sp),%sp
        jmp     GK_STOCK_PATTERN_SCHEDULE_CONTINUE
.Lgk_pattern_schedule_release_fatal:
        move.l  %d2,%d0
        jsr     gk_descriptor_release
        bra.w   gk_pattern_transition_post_engine_fatal
.Lgk_pattern_schedule_capture_failed:
        bsr.w   gk_workspace_abort_update
        tst.l   %d0
        bne.s   gk_pattern_transition_pre_engine_fatal
.Lgk_pattern_schedule_cancel:
        movem.l (%sp),%d2-%d3/%d7/%a2
        lea     16(%sp),%sp
        jmp     GK_STOCK_PATTERN_SCHEDULE_ABORT
.Lgk_pattern_schedule_boot_stock:
        .global gk_pattern_schedule_boot_stock_passthrough
gk_pattern_schedule_boot_stock_passthrough:
        .incbin "stock/0148.bin", 0, 6
        .incbin "stock/0148.bin", 6, 4
        .incbin "stock/0148.bin", 10, 2
        .incbin "stock/0148.bin", 12, 2
        .incbin "stock/0148.bin", 14, 6
        jmp     GK_STOCK_PATTERN_SCHEDULE_CONTINUE
        .global gk_pattern_transition_pre_engine_fatal
gk_pattern_transition_pre_engine_fatal:
        illegal
        bra.s   gk_pattern_transition_pre_engine_fatal
        .global gk_pattern_transition_post_engine_fatal
gk_pattern_transition_post_engine_fatal:
        illegal
        bra.s   gk_pattern_transition_post_engine_fatal
        .align  4
        .global gk_pattern_transition_retry_overflow_fatal
gk_pattern_transition_retry_overflow_fatal:
        illegal
        bra.s   gk_pattern_transition_retry_overflow_fatal
        .align  4
        .global gk_pattern_transition_retry_corrupt_fatal
gk_pattern_transition_retry_corrupt_fatal:
        illegal
        bra.s   gk_pattern_transition_retry_corrupt_fatal
        .size   gk_stock_pattern_schedule_prepare,.-gk_stock_pattern_schedule_prepare
