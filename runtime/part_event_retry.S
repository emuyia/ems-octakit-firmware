        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_lifecycle_scratch_clear_release
        .type   gk_lifecycle_scratch_clear_release,@function
gk_lifecycle_scratch_clear_release:
        move.w  %sr,%d0
        move.l  %d2,-(%sp)
        move.w  %d0,%d2
        move.w  #0x2700,%sr
        .global gk_lifecycle_scratch_invalidation
gk_lifecycle_scratch_invalidation:
        clr.l   __gk_lifecycle_scratch_magic
        clr.l   __gk_lifecycle_scratch_flags
        move.l  4(%sp),%d0
        cmpi.l  #gk_lifecycle_activation_scratch_return,%d0
        beq.s   .Lgk_scratch_clear_activation
        moveq   #GK_OK,%d0
        move.w  %d2,%d1
        move.l  (%sp)+,%d2
        move.w  %d1,%sr
        rts
.Lgk_scratch_clear_activation:
        moveq   #GK_OK,%d0
        move.w  %d2,%d1
        move.l  (%sp)+,%d2
        move.w  %d1,%sr
        jmp     gk_lifecycle_activation_finalize_release
        .size   gk_lifecycle_scratch_clear_release,.-gk_lifecycle_scratch_clear_release
        .align  4
        .global gk_ui_transition_retry_ensure
        .type   gk_ui_transition_retry_ensure,@function
gk_ui_transition_retry_ensure:
        moveq   #0,%d0
        bra.s   .Lgk_retry_entry
        .global gk_ui_transition_context_retry_ensure
        .type   gk_ui_transition_context_retry_ensure,@function
gk_ui_transition_context_retry_ensure:
        moveq   #1,%d0
.Lgk_retry_entry:
        .incbin "stock/0341.bin", 0, 4
        .incbin "stock/0341.bin", 4, 4
        movea.l %d0,%a5
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_ui_transition_pending,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_retry_corrupt
        tst.l   %d0
        bne.s   .Lgk_retry_pending_ready
        tst.l   %a5
        beq.w   .Lgk_retry_ok
        move.l  __gk_ui_transition_reserved,%d0
        beq.w   .Lgk_retry_ok
        movea.l %d0,%a4
        move.l  %d0,%d1
        andi.l  #GK_UI_TRANSITION_CARRIED_PATTERN_MASK,%d1
        cmpi.l  #GK_UI_TRANSITION_CARRIED_PATTERN_MAGIC,%d1
        bne.w   .Lgk_retry_corrupt
        move.l  %d0,%d1
        lsr.l   #8,%d1
        andi.l  #GK_UI_TRANSITION_CARRIED_DESCRIPTOR_MASK,%d1
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.w   .Lgk_retry_corrupt
        moveq   #0,%d3
        move.b  __gk_workspace_descriptor,%d3
        cmp.l   %d3,%d1
        bne.w   .Lgk_retry_corrupt
        tst.l   __gk_ui_transition_start
        bne.w   .Lgk_retry_corrupt
        tst.l   __gk_ui_transition_start + 4
        bne.w   .Lgk_retry_corrupt
        tst.l   __gk_ui_transition_start + 8
        bne.w   .Lgk_retry_corrupt
        andi.l  #0xff,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_retry_corrupt
        moveq   #2,%d0
        movea.l %d0,%a5
.Lgk_retry_pending_ready:
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_retry_corrupt
        btst    #7,%d0
        beq.w   .Lgk_retry_inactive
        cmpa.l  #2,%a5
        bne.w   .Lgk_retry_ok
        move.l  %a4,%d0
        move.l  %d0,%d1
        lsr.l   #8,%d1
        andi.l  #GK_UI_TRANSITION_CARRIED_DESCRIPTOR_MASK,%d1
        moveq   #0,%d3
        move.b  __gk_pending_workspace_descriptor,%d3
        cmp.l   %d3,%d1
        bne.w   .Lgk_retry_corrupt
        andi.l  #0xff,%d0
        moveq   #0,%d3
        move.b  __gk_pending_pattern,%d3
        cmp.l   %d3,%d0
        bne.w   .Lgk_retry_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_retry_corrupt
        moveq   #0,%d3
        move.b  __gk_pending_bank,%d3
        cmp.l   %d3,%d0
        bne.w   .Lgk_retry_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_kit,%d0
        cmp.b   __gk_current_kit,%d0
        bne.w   .Lgk_retry_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        cmpi.l  #GK_TRANSITION_PRESERVE_NAME,%d0
        bne.w   .Lgk_retry_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_bound,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_retry_corrupt
        cmp.b   __gk_workspace_bound,%d0
        bne.w   .Lgk_retry_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_retry_corrupt
        bra.w   .Lgk_retry_ok
.Lgk_retry_inactive:
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_retry_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_retry_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_retry_corrupt
        cmpa.l  #2,%a5
        bne.s   .Lgk_retry_committed_ready
        move.l  %a4,%d0
        andi.l  #0xff,%d0
        moveq   #0,%d3
        move.b  __gk_current_pattern,%d3
        cmp.l   %d3,%d0
        bne.w   .Lgk_retry_corrupt
.Lgk_retry_committed_ready:
        tst.l   %a5
        beq.w   .Lgk_retry_select_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_retry_corrupt
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PATTERN,%d1
        cmp.l   %d0,%d1
        bne.w   .Lgk_retry_corrupt
        moveq   #0,%d3
        move.b  __gk_current_pattern,%d3
        cmpi.l  #15,%d3
        bhi.w   .Lgk_retry_corrupt
        cmp.l   %d3,%d0
        bne.s   .Lgk_retry_pattern_lagging
        cmpa.l  #2,%a5
        bne.s   .Lgk_retry_select_part
        move.l  %a4,%d0
        lsr.l   #8,%d0
        btst    #7,%d0
        beq.w   .Lgk_retry_corrupt
.Lgk_retry_pattern_lagging:
.Lgk_retry_pattern_event_validate:
        moveq   #0,%d0
        move.b  GK_STOCK_PATTERN_EVENT_TEMPLATE,%d0
        cmpi.l  #GK_STOCK_PATTERN_EVENT_ID,%d0
        bne.w   .Lgk_retry_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_PATTERN_EVENT_TEMPLATE + 1,%d0
        cmp.l   %d3,%d0
        beq.s   .Lgk_retry_pattern_template
        cmpi.l  #15,%d0
        bhi.w   .Lgk_retry_corrupt
        move.l  40(%sp),%d4
        cmpi.l  #gk_stock_pattern_event_context_retry_return,%d4
        bne.w   .Lgk_retry_corrupt
        cmp.l   %d1,%d0
        bne.w   .Lgk_retry_corrupt
        bra.w   .Lgk_retry_ok
.Lgk_retry_pattern_template:
        move.l  #GK_STOCK_PATTERN_EVENT_TEMPLATE,%d3
        bra.s   .Lgk_retry_target_ready
.Lgk_retry_select_part:
        moveq   #0,%d3
        move.b  GK_STOCK_ENGINE_PART,%d3
        cmpi.l  #GK_PARTS_PER_BANK - 1,%d3
        bhi.w   .Lgk_retry_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_PART_EVENT_TEMPLATE,%d0
        cmpi.l  #GK_STOCK_PART_EVENT_ID,%d0
        bne.w   .Lgk_retry_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_PART_EVENT_TEMPLATE + 1,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_retry_corrupt
        move.l  #GK_STOCK_PART_EVENT_TEMPLATE,%d3
.Lgk_retry_target_ready:
        move.l  GK_STOCK_EVENT_OBJECT + 4,%d4
        cmpi.l  #GK_STOCK_EVENT_QUEUE_CAPACITY,%d4
        bhi.w   .Lgk_retry_corrupt
        move.l  GK_STOCK_EVENT_OBJECT + 0x10,%d0
        cmpi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d0
        bne.w   .Lgk_retry_corrupt
        movea.l GK_STOCK_EVENT_OBJECT + 0x14,%a2
        cmpa.l  #GK_STOCK_EVENT_QUEUE_BUFFER,%a2
        bne.w   .Lgk_retry_corrupt
        move.l  GK_STOCK_EVENT_OBJECT + 0x18,%d5
        cmpi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d5
        bhi.w   .Lgk_retry_corrupt
        move.l  GK_STOCK_EVENT_OBJECT + 0x1c,%d6
        cmpi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d6
        bhi.w   .Lgk_retry_corrupt
        move.l  %d6,%d0
        add.l   %d4,%d0
        andi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_retry_corrupt
        move.l  %d4,%d7
        beq.s   .Lgk_retry_enqueue
.Lgk_retry_scan:
        move.l  %d6,%d0
        lsl.l   #2,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        move.l  (%a3),%d0
        cmp.l   %d3,%d0
        beq.w   .Lgk_retry_ok
        addq.l  #1,%d6
        andi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d6
        subq.l  #1,%d7
        bne.s   .Lgk_retry_scan
.Lgk_retry_enqueue:
        cmpi.l  #GK_STOCK_EVENT_QUEUE_CAPACITY,%d4
        beq.w   .Lgk_retry_overflow
        move.l  %d3,-(%sp)
        pea     GK_STOCK_EVENT_OBJECT
        jsr     GK_STOCK_EVENT_POINTER_PUSH
        lea     8(%sp),%sp
        addq.l  #1,%d4
        cmp.l   GK_STOCK_EVENT_OBJECT + 4,%d4
        bne.s   .Lgk_retry_corrupt
        move.l  %d5,%d0
        lsl.l   #2,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        move.l  (%a3),%d0
        cmp.l   %d3,%d0
        bne.s   .Lgk_retry_corrupt
        addq.l  #1,%d5
        andi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d5
        cmp.l   GK_STOCK_EVENT_OBJECT + 0x18,%d5
        bne.s   .Lgk_retry_corrupt
        moveq   #0,%d0
        move.b  __gk_ui_transition_pending,%d0
        cmpa.l  #2,%a5
        bne.s   .Lgk_retry_enqueue_pending
        tst.l   %d0
        bne.s   .Lgk_retry_corrupt
        cmp.l   __gk_ui_transition_reserved,%a4
        bne.s   .Lgk_retry_corrupt
        bra.s   .Lgk_retry_ok
.Lgk_retry_enqueue_pending:
        cmpi.l  #1,%d0
        bne.s   .Lgk_retry_corrupt
.Lgk_retry_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_retry_restore
.Lgk_retry_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
        bra.s   .Lgk_retry_restore
.Lgk_retry_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_retry_restore:
        move.w  %d2,%d1
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        move.w  %d1,%sr
        rts
        .size   gk_ui_transition_retry_ensure,.-gk_ui_transition_retry_ensure
        .size   gk_ui_transition_context_retry_ensure,.-gk_ui_transition_context_retry_ensure
        .align  4
        .global gk_lifecycle_activation_finalize_release
        .type   gk_lifecycle_activation_finalize_release,@function
gk_lifecycle_activation_finalize_release:
        bsr.w   gk_ui_transition_retry_ensure
        .global gk_lifecycle_activation_retry_return
gk_lifecycle_activation_retry_return:
        tst.l   %d0
        beq.s   .Lgk_activation_finalize_ok
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.s   gk_ui_transition_retry_overflow_fatal
        bra.s   gk_ui_transition_retry_corrupt_fatal
.Lgk_activation_finalize_ok:
        rts
        .size   gk_lifecycle_activation_finalize_release,.-gk_lifecycle_activation_finalize_release
        .align  4
        .global gk_ui_transition_retry_overflow_fatal
gk_ui_transition_retry_overflow_fatal:
        illegal
        bra.s   gk_ui_transition_retry_overflow_fatal
        .align  4
        .global gk_ui_transition_retry_corrupt_fatal
gk_ui_transition_retry_corrupt_fatal:
        illegal
        bra.s   gk_ui_transition_retry_corrupt_fatal
        .align  4
        .global gk_stock_pattern_event_retry_bridge
        .type   gk_stock_pattern_event_retry_bridge,@function
gk_stock_pattern_event_retry_bridge:
        lea     -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.w  %sr,%d0
        move.w  %d0,60(%sp)
        jsr     gk_ui_carried_pattern_lag_event_finish
        tst.l   %d0
        bne.s   gk_pattern_event_retry_corrupt_fatal
        bsr.w   gk_ui_transition_context_retry_ensure
        .global gk_stock_pattern_event_context_retry_return
gk_stock_pattern_event_context_retry_return:
        tst.l   %d0
        beq.s   .Lgk_pattern_event_retry_ok
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.s   gk_pattern_event_retry_overflow_fatal
        bra.s   gk_pattern_event_retry_corrupt_fatal
.Lgk_pattern_event_retry_ok:
        move.w  60(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     64(%sp),%sp
        jmp     GK_STOCK_PATTERN_EVENT_REFRESH
        .size   gk_stock_pattern_event_retry_bridge,.-gk_stock_pattern_event_retry_bridge
        .align  4
        .global gk_pattern_event_retry_overflow_fatal
gk_pattern_event_retry_overflow_fatal:
        illegal
        bra.s   gk_pattern_event_retry_overflow_fatal
        .align  4
        .global gk_pattern_event_retry_corrupt_fatal
gk_pattern_event_retry_corrupt_fatal:
        illegal
        bra.s   gk_pattern_event_retry_corrupt_fatal
