        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_pattern_queue_commit_guard_enter
        .type   gk_pattern_queue_commit_guard_enter,@function
gk_pattern_queue_commit_guard_enter:
        .incbin "stock/0383.bin", 0, 4
        .incbin "stock/0383.bin", 4, 4
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        tst.w   __gk_arranger_guard_reserved
        bne.w   .Lgk_queue_guard_corrupt
        tst.w   __gk_arranger_guard_saved_sr_pad
        bne.w   .Lgk_queue_guard_corrupt
        moveq   #0,%d2
        move.b  __gk_arranger_guard_depth,%d2
        cmpi.l  #GK_ARRANGER_GUARD_MAX_DEPTH,%d2
        bhi.w   .Lgk_queue_guard_corrupt
        tst.l   %d2
        beq.s   .Lgk_queue_guard_acquire
        cmpi.l  #1,%d2
        bne.w   .Lgk_queue_guard_busy
        moveq   #1,%d0
        cmp.b   __gk_arranger_playback_guard_active,%d0
        bne.w   .Lgk_queue_guard_busy
        moveq   #0,%d3
        move.w  __gk_arranger_guard_saved_sr,%d3
        beq.w   .Lgk_queue_guard_corrupt
        andi.l  #0x00000700,%d3
        cmpi.l  #0x00000200,%d3
        bcc.s   .Lgk_queue_guard_expected_ready
        move.l  #0x00000200,%d3
.Lgk_queue_guard_expected_ready:
        moveq   #0,%d0
        move.w  %d4,%d0
        andi.l  #0x00000700,%d0
        cmp.l   %d3,%d0
        bne.s   .Lgk_queue_guard_busy
        move.w  %d4,%sr
        movem.l (%sp),%d2-%d4/%a2
        lea     16(%sp),%sp
        moveq   #0,%d0
        rts
.Lgk_queue_guard_acquire:
        tst.b   __gk_arranger_playback_guard_active
        bne.s   .Lgk_queue_guard_corrupt
        tst.w   __gk_arranger_guard_saved_sr
        bne.s   .Lgk_queue_guard_corrupt
        move.w  %d4,%sr
        movem.l (%sp),%d2-%d4/%a2
        lea     16(%sp),%sp
        jsr     gk_arranger_guard_enter
        tst.l   %d0
        bne.s   .Lgk_queue_guard_acquire_return
        moveq   #1,%d0
.Lgk_queue_guard_acquire_return:
        rts
.Lgk_queue_guard_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_queue_guard_restore
.Lgk_queue_guard_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_queue_guard_restore:
        move.w  %d4,%sr
        .incbin "stock/0384.bin", 0, 4
        .incbin "stock/0384.bin", 4, 4
        .incbin "stock/0384.bin", 8, 2
        .size   gk_pattern_queue_commit_guard_enter,.-gk_pattern_queue_commit_guard_enter
        .align  4
        .global gk_pattern_queue_handoff_marker_publish
        .type   gk_pattern_queue_handoff_marker_publish,@function
gk_pattern_queue_handoff_marker_publish:
        .incbin "stock/0385.bin", 0, 4
        .incbin "stock/0385.bin", 4, 3
        .byte 0x06
        move.w  %sr,%d2
        move.w  %d2,8(%sp)
        move.w  #0x2700,%sr
        tst.b   __gk_sequencer_latch_queue_handoff
        bne.s   .Lgk_queue_marker_publish_corrupt
        moveq   #0,%d1
        move.b  __gk_pattern_queue_commit_prepared,%d1
        beq.s   .Lgk_queue_marker_publish_marker
        btst    #0,%d1
        bne.s   .Lgk_queue_marker_publish_corrupt
        move.l  %d1,%d0
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d0
        cmpi.l  #GK_PATTERN_QUEUE_PREPARED_BASE,%d0
        beq.s   .Lgk_queue_marker_publish_promote
        cmpi.l  #GK_PATTERN_QUEUE_DEFERRED_BASE,%d0
        beq.s   .Lgk_queue_marker_publish_promote
        cmpi.l  #GK_PATTERN_QUEUE_QUEUED_BASE,%d0
        beq.s   .Lgk_queue_marker_publish_promote
        cmpi.l  #GK_PATTERN_QUEUE_DISPATCHING_BASE,%d0
        bne.s   .Lgk_queue_marker_publish_corrupt
.Lgk_queue_marker_publish_promote:
        ori.l   #1,%d1
        move.b  %d1,__gk_pattern_queue_commit_prepared
.Lgk_queue_marker_publish_marker:
        moveq   #1,%d0
        .global gk_pattern_queue_handoff_marker_publication
gk_pattern_queue_handoff_marker_publication:
        move.b  %d0,__gk_sequencer_latch_queue_handoff
        moveq   #GK_OK,%d0
        bra.s   .Lgk_queue_marker_publish_restore
.Lgk_queue_marker_publish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_queue_marker_publish_restore:
        move.w  8(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d1-%d2
        lea     12(%sp),%sp
        tst.l   %d0
        bne.w   gk_pattern_queue_handoff_marker_fatal
        jsr     gk_pattern_queue_handoff_retry_arm
        tst.l   %d0
        bne.w   gk_pattern_queue_handoff_retry_arm_fatal
        rts
        .size   gk_pattern_queue_handoff_marker_publish,.-gk_pattern_queue_handoff_marker_publish
        .global gk_pattern_queue_commit_prepare
        .type   gk_pattern_queue_commit_prepare,@function
gk_pattern_queue_commit_prepare:
        lea     -36(%sp),%sp
        movem.l %d2-%d7/%a2-%a3,(%sp)
        move.w  %sr,%d0
        move.w  %d0,32(%sp)
        moveq   #0,%d0
        move.b  __gk_pattern_queue_commit_prepared,%d0
        beq.s   .Lgk_queue_prepare_owner_ready
        move.l  %d0,%d1
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d1
        cmpi.l  #GK_PATTERN_QUEUE_DEFERRED_BASE,%d1
        beq.s   .Lgk_queue_prepare_owner_ready
        cmpi.l  #GK_PATTERN_QUEUE_QUEUED_BASE,%d1
        beq.s   .Lgk_queue_prepare_owner_ready
        cmpi.l  #GK_PATTERN_QUEUE_DISPATCHING_BASE,%d1
        bne.w   .Lgk_queue_prepare_corrupt
.Lgk_queue_prepare_owner_ready:
        moveq   #0,%d0
        move.b  __gk_sequencer_latch_queue_handoff,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_queue_prepare_corrupt
        moveq   #0,%d1
        move.b  __gk_pattern_queue_commit_prepared,%d1
        beq.s   .Lgk_queue_prepare_marker_ready
        andi.l  #1,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_queue_prepare_corrupt
.Lgk_queue_prepare_marker_ready:
        move.l  %d0,%d3
        move.l  GK_STOCK_SCHEDULER_STATE,%d6
        cmpi.l  #2,%d6
        bhi.w   .Lgk_queue_prepare_corrupt
        tst.l   %d3
        beq.s   .Lgk_queue_prepare_stock_route
        cmpi.l  #1,%d6
        bne.w   .Lgk_queue_prepare_changed
        move.l  GK_STOCK_SCHEDULER_CHAINED,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_queue_prepare_corrupt
        moveq   #0x10,%d7
        or.l    %d0,%d7
        moveq   #0,%d4
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d4
        moveq   #0,%d5
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d5
        bra.s   .Lgk_queue_prepare_tuple_ready
.Lgk_queue_prepare_stock_route:
        move.l  GK_STOCK_SCHEDULER_CHAINED,%d0
        beq.s   .Lgk_queue_prepare_ordinary
        cmpi.l  #1,%d0
        bne.w   .Lgk_queue_prepare_corrupt
        tst.l   %d6
        bne.s   .Lgk_queue_prepare_chained
        tst.l   %d3
        bne.w   .Lgk_queue_prepare_corrupt
        tst.l   GK_STOCK_PATTERN_QUEUE_GATE
        bne.w   .Lgk_queue_prepare_changed
.Lgk_queue_prepare_chained:
        moveq   #1,%d7
        moveq   #0,%d4
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d4
        moveq   #0,%d5
        move.b  GK_STOCK_PATTERN_CHAIN_CURRENT,%d5
        bra.s   .Lgk_queue_prepare_tuple_ready
.Lgk_queue_prepare_ordinary:
        tst.l   %d6
        beq.w   .Lgk_queue_prepare_corrupt
        moveq   #0,%d7
        moveq   #0,%d4
        move.b  GK_STOCK_QUEUED_BANK,%d4
        moveq   #0,%d5
        move.b  GK_STOCK_QUEUED_PATTERN,%d5
.Lgk_queue_prepare_tuple_ready:
        cmpi.l  #15,%d4
        bhi.w   .Lgk_queue_prepare_corrupt
        cmpi.l  #15,%d5
        bhi.w   .Lgk_queue_prepare_corrupt
        lsl.l   #1,%d3
        or.l    %d3,%d7
        lsl.l   #2,%d6
        or.l    %d6,%d7
.Lgk_queue_prepare_mode_ready:
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        adda.l  #GK_STOCK_BANK_STATUS_OFFSET,%a2
        tst.l   (%a2)
        bne.w   .Lgk_queue_prepare_busy
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   .Lgk_queue_prepare_restore
        jsr     gk_ui_transition_prepare
        tst.l   %d0
        bmi.w   .Lgk_queue_prepare_abort
        move.w  #0x2700,%sr
        move.l  %d7,%d0
        lsr.l   #2,%d0
        andi.l  #3,%d0
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.w   .Lgk_queue_prepare_changed
        moveq   #0,%d0
        move.b  __gk_sequencer_latch_queue_handoff,%d0
        move.l  %d7,%d1
        lsr.l   #1,%d1
        andi.l  #1,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_queue_prepare_changed
        move.l  GK_STOCK_SCHEDULER_CHAINED,%d0
        move.l  %d7,%d1
        andi.l  #1,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_queue_prepare_changed
        move.l  %d7,%d0
        andi.l  #0x0c,%d0
        bne.s   .Lgk_queue_prepare_revalidate_target
        tst.l   GK_STOCK_PATTERN_QUEUE_GATE
        bne.w   .Lgk_queue_prepare_changed
.Lgk_queue_prepare_revalidate_target:
        btst    #4,%d7
        beq.s   .Lgk_queue_prepare_revalidate_stock_target
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_BANK,%d4
        bne.w   .Lgk_queue_prepare_changed
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d5
        bne.w   .Lgk_queue_prepare_changed
        bra.s   .Lgk_queue_prepare_revalidated
.Lgk_queue_prepare_revalidate_stock_target:
        btst    #0,%d7
        bne.s   .Lgk_queue_prepare_revalidate_chain
        cmp.b   GK_STOCK_QUEUED_BANK,%d4
        bne.w   .Lgk_queue_prepare_changed
        cmp.b   GK_STOCK_QUEUED_PATTERN,%d5
        bne.w   .Lgk_queue_prepare_changed
        bra.s   .Lgk_queue_prepare_revalidated
.Lgk_queue_prepare_revalidate_chain:
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_BANK,%d4
        bne.w   .Lgk_queue_prepare_changed
        cmp.b   GK_STOCK_PATTERN_CHAIN_CURRENT,%d5
        bne.w   .Lgk_queue_prepare_changed
.Lgk_queue_prepare_revalidated:
        tst.l   (%a2)
        bne.w   .Lgk_queue_prepare_changed
        move.l  %d7,%d0
        lsr.l   #1,%d0
        andi.l  #1,%d0
        ori.l   #GK_PATTERN_QUEUE_PREPARED_BASE,%d0
        .global gk_pattern_queue_commit_prepared_publication
gk_pattern_queue_commit_prepared_publication:
        move.b  %d0,__gk_pattern_queue_commit_prepared
        moveq   #GK_OK,%d0
        bra.s   .Lgk_queue_prepare_restore_locked
.Lgk_queue_prepare_abort:
        movea.l %d0,%a3
        move.w  32(%sp),%d1
        move.w  %d1,%sr
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.s   .Lgk_queue_prepare_corrupt
        move.l  %a3,%d0
        bra.s   .Lgk_queue_prepare_restore
.Lgk_queue_prepare_changed:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_queue_prepare_abort
.Lgk_queue_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_queue_prepare_restore
.Lgk_queue_prepare_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_queue_prepare_restore:
        move.w  32(%sp),%d1
        move.w  %d1,%sr
.Lgk_queue_prepare_restore_locked:
        movem.l (%sp),%d2-%d7/%a2-%a3
        lea     36(%sp),%sp
        rts
        .size   gk_pattern_queue_commit_prepare,.-gk_pattern_queue_commit_prepare
        .align  4
        .global gk_stock_pattern_queue_request_ipl_restore
        .type   gk_stock_pattern_queue_request_ipl_restore,@function
gk_stock_pattern_queue_request_ipl_restore:
        lea     -12(%sp),%sp
        movem.l %d0-%d2,(%sp)
        moveq   #0,%d0
        move.b  __gk_pattern_queue_commit_prepared,%d0
        move.l  %d0,%d1
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d1
        cmpi.l  #GK_PATTERN_QUEUE_PREPARED_BASE,%d1
        bne.w   .Lgk_queue_request_restore_replay
        move.l  12(%sp),%d1
        cmpi.l  #GK_STOCK_PATTERN_QUEUE_REQUEST_ZERO_CHAIN_RETURN,%d1
        beq.s   .Lgk_queue_request_caller_ready
        cmpi.l  #GK_STOCK_PATTERN_QUEUE_REQUEST_CHAIN_RETURN,%d1
        beq.s   .Lgk_queue_request_caller_ready
        cmpi.l  #GK_STOCK_PATTERN_QUEUE_REQUEST_ORDINARY_RETURN,%d1
        bne.w   .Lgk_queue_request_corrupt
.Lgk_queue_request_caller_ready:
        moveq   #0,%d1
        move.b  __gk_sequencer_latch_queue_handoff,%d1
        cmpi.l  #1,%d1
        bhi.w   .Lgk_queue_request_corrupt
        andi.l  #1,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_queue_request_corrupt
        moveq   #1,%d0
        cmp.b   __gk_arranger_guard_depth,%d0
        bne.w   .Lgk_queue_request_corrupt
        tst.w   __gk_arranger_guard_reserved
        bne.w   .Lgk_queue_request_corrupt
        tst.w   __gk_arranger_guard_saved_sr_pad
        bne.w   .Lgk_queue_request_corrupt
        tst.w   __gk_arranger_guard_saved_sr
        beq.w   .Lgk_queue_request_corrupt
        tst.l   GK_STOCK_SCHEDULER_STATE
        bne.w   .Lgk_queue_request_corrupt
        move.w  %sr,%d2
        moveq   #0,%d0
        move.w  %d2,%d0
        andi.l  #0x00000700,%d0
        cmpi.l  #0x00000700,%d0
        bne.s   .Lgk_queue_request_corrupt
        moveq   #0,%d0
        move.w  __gk_arranger_guard_saved_sr,%d0
        move.l  %d0,%d1
        andi.l  #0x00000700,%d1
        cmpi.l  #0x00000200,%d1
        bcc.s   .Lgk_queue_request_mask_ready
        andi.l  #0x0000f8ff,%d0
        ori.l   #0x00000200,%d0
.Lgk_queue_request_mask_ready:
        andi.l  #0x0000ff00,%d0
        move.l  %d2,%d1
        andi.l  #0x000000ff,%d1
        or.l    %d1,%d0
        move.w  %d0,%sr
.Lgk_queue_request_restore_replay:
        movem.l (%sp),%d0-%d2
        lea     12(%sp),%sp
.Lgk_queue_request_replay:
        .global gk_pattern_queue_request_stock_replay
gk_pattern_queue_request_stock_replay:
        .incbin "stock/0386.bin", 0, 2
        .incbin "stock/0386.bin", 2, 4
        jmp     GK_STOCK_PATTERN_SCHEDULE_REQUEST_CONTINUE
.Lgk_queue_request_corrupt:
        movem.l (%sp),%d0-%d2
        lea     12(%sp),%sp
        jmp     gk_pattern_queue_request_ipl_fatal
        .size   gk_stock_pattern_queue_request_ipl_restore,.-gk_stock_pattern_queue_request_ipl_restore
        .align  4
        .global gk_pattern_queue_commit_defer_publish
        .type   gk_pattern_queue_commit_defer_publish,@function
gk_pattern_queue_commit_defer_publish:
        lea     -24(%sp),%sp
        movem.l %d2-%d5/%a2,(%sp)
        move.w  %sr,%d5
        move.w  %d5,20(%sp)
        move.w  #0x2700,%sr
        moveq   #0,%d2
        move.b  __gk_sequencer_latch_queue_handoff,%d2
        cmpi.l  #1,%d2
        bhi.w   .Lgk_queue_defer_corrupt
        moveq   #0,%d3
        move.b  __gk_pattern_queue_commit_prepared,%d3
        beq.s   .Lgk_queue_defer_route
        move.l  %d3,%d0
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d0
        cmpi.l  #GK_PATTERN_QUEUE_PREPARED_BASE,%d0
        beq.w   .Lgk_queue_defer_prepared
        cmpi.l  #GK_PATTERN_QUEUE_DEFERRED_BASE,%d0
        beq.s   .Lgk_queue_defer_existing
        cmpi.l  #GK_PATTERN_QUEUE_QUEUED_BASE,%d0
        beq.s   .Lgk_queue_defer_existing
        cmpi.l  #GK_PATTERN_QUEUE_DISPATCHING_BASE,%d0
        bne.w   .Lgk_queue_defer_corrupt
.Lgk_queue_defer_existing:
        move.l  %d3,%d0
        andi.l  #1,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_queue_defer_corrupt
.Lgk_queue_defer_route:
        move.l  GK_STOCK_SCHEDULER_STATE,%d4
        cmpi.l  #2,%d4
        bhi.w   .Lgk_queue_defer_corrupt
        tst.l   %d4
        bne.s   .Lgk_queue_defer_state_nonzero
        tst.l   %d2
        bne.w   .Lgk_queue_defer_publish
        move.l  GK_STOCK_SCHEDULER_CHAINED,%d0
        beq.w   .Lgk_queue_defer_not_handled
        cmpi.l  #1,%d0
        bne.w   .Lgk_queue_defer_corrupt
        tst.l   GK_STOCK_PATTERN_QUEUE_GATE
        bne.w   .Lgk_queue_defer_not_handled
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_queue_defer_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_PATTERN_CHAIN_CURRENT,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_queue_defer_corrupt
        bra.s   .Lgk_queue_defer_publish
.Lgk_queue_defer_state_nonzero:
        move.l  GK_STOCK_SCHEDULER_CHAINED,%d0
        beq.s   .Lgk_queue_defer_ordinary
        cmpi.l  #1,%d0
        bne.w   .Lgk_queue_defer_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_queue_defer_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_PATTERN_CHAIN_CURRENT,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_queue_defer_corrupt
        bra.s   .Lgk_queue_defer_publish
.Lgk_queue_defer_ordinary:
        moveq   #0,%d0
        move.b  GK_STOCK_QUEUED_BANK,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_queue_defer_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_QUEUED_PATTERN,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_queue_defer_corrupt
.Lgk_queue_defer_publish:
        tst.l   %d3
        bne.s   .Lgk_queue_defer_ok
        move.l  %d2,%d0
        ori.l   #GK_PATTERN_QUEUE_DEFERRED_BASE,%d0
        .global gk_pattern_queue_commit_deferred_publication
gk_pattern_queue_commit_deferred_publication:
        move.b  %d0,__gk_pattern_queue_commit_prepared
.Lgk_queue_defer_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_queue_defer_restore
.Lgk_queue_defer_prepared:
        move.l  %d3,%d0
        andi.l  #1,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_queue_defer_corrupt
.Lgk_queue_defer_not_handled:
        moveq   #GK_ARRANGER_NOT_HANDLED,%d0
        bra.s   .Lgk_queue_defer_restore
.Lgk_queue_defer_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_queue_defer_restore:
        move.w  20(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d5/%a2
        lea     24(%sp),%sp
        rts
        .size   gk_pattern_queue_commit_defer_publish,.-gk_pattern_queue_commit_defer_publish
        .align  4
        .global gk_pattern_queue_commit_cancel_deferred
        .type   gk_pattern_queue_commit_cancel_deferred,@function
gk_pattern_queue_commit_cancel_deferred:
        lea     -12(%sp),%sp
        movem.l %d1-%d2,(%sp)
        move.w  %sr,%d2
        move.w  %d2,8(%sp)
        move.w  #0x2700,%sr
        tst.b   __gk_sequencer_latch_queue_handoff
        bne.w   .Lgk_queue_cancel_corrupt
        moveq   #0,%d1
        move.b  __gk_pattern_queue_commit_prepared,%d1
        beq.s   .Lgk_queue_cancel_ok
        btst    #0,%d1
        bne.s   .Lgk_queue_cancel_corrupt
        move.l  %d1,%d0
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d0
        cmpi.l  #GK_PATTERN_QUEUE_DEFERRED_BASE,%d0
        beq.s   .Lgk_queue_cancel_owner
        cmpi.l  #GK_PATTERN_QUEUE_QUEUED_BASE,%d0
        beq.s   .Lgk_queue_cancel_owner
        cmpi.l  #GK_PATTERN_QUEUE_DISPATCHING_BASE,%d0
        bne.s   .Lgk_queue_cancel_corrupt
.Lgk_queue_cancel_owner:
        moveq   #0,%d2
        move.b  __gk_runtime_flags,%d2
        move.l  %d2,%d0
        andi.l  #0x7e,%d0
        bne.s   .Lgk_queue_cancel_corrupt
        btst    #7,%d2
        bne.s   .Lgk_queue_cancel_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.s   .Lgk_queue_cancel_corrupt
        tst.b   __gk_pending_transition_flags
        bne.s   .Lgk_queue_cancel_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.s   .Lgk_queue_cancel_corrupt
        tst.b   __gk_pending_workspace_bound
        bne.s   .Lgk_queue_cancel_corrupt
        clr.b   __gk_pattern_queue_commit_prepared
.Lgk_queue_cancel_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_queue_cancel_restore
.Lgk_queue_cancel_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_queue_cancel_restore
.Lgk_queue_cancel_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_queue_cancel_restore:
        move.w  8(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d1-%d2
        .incbin "stock/0387.bin", 0, 4
        .incbin "stock/0387.bin", 4, 2
        .size   gk_pattern_queue_commit_cancel_deferred,.-gk_pattern_queue_commit_cancel_deferred
        .incbin "stock/0387.bin", 6, 2
        .global gk_pattern_queue_retry_event_ensure
        .type   gk_pattern_queue_retry_event_ensure,@function
gk_pattern_queue_retry_event_ensure:
        .incbin "stock/0388.bin", 0, 4
        .incbin "stock/0388.bin", 4, 4
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_pattern_queue_commit_prepared,%d0
        beq.w   .Lgk_queue_retry_ensure_ok
        move.l  %d0,%d1
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d1
        cmpi.l  #GK_PATTERN_QUEUE_PREPARED_BASE,%d1
        beq.w   .Lgk_queue_retry_ensure_ok
        cmpi.l  #GK_PATTERN_QUEUE_DEFERRED_BASE,%d1
        beq.s   .Lgk_queue_retry_ensure_owner
        cmpi.l  #GK_PATTERN_QUEUE_QUEUED_BASE,%d1
        beq.s   .Lgk_queue_retry_ensure_owner
        cmpi.l  #GK_PATTERN_QUEUE_DISPATCHING_BASE,%d1
        bne.w   .Lgk_queue_retry_ensure_corrupt
.Lgk_queue_retry_ensure_owner:
        moveq   #0,%d1
        move.b  __gk_sequencer_latch_queue_handoff,%d1
        cmpi.l  #1,%d1
        bhi.w   .Lgk_queue_retry_ensure_corrupt
        andi.l  #1,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_queue_retry_ensure_corrupt
        moveq   #0,%d3
        move.b  __gk_pattern_queue_commit_prepared,%d3
        move.l  %d3,%d0
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d0
        cmpi.l  #GK_PATTERN_QUEUE_DISPATCHING_BASE,%d0
        beq.w   .Lgk_queue_retry_ensure_ok
        lea     __gk_pattern_queue_retry_event,%a4
        moveq   #0,%d0
        move.b  (%a4),%d0
        cmpi.l  #GK_PATTERN_QUEUE_RETRY_EVENT_ID,%d0
        bne.w   .Lgk_queue_retry_ensure_corrupt
        tst.b   1(%a4)
        bne.w   .Lgk_queue_retry_ensure_corrupt
        move.l  2(%a4),%d0
        cmpi.l  #gk_pattern_queue_retry_callback,%d0
        bne.w   .Lgk_queue_retry_ensure_corrupt
        tst.l   6(%a4)
        bne.w   .Lgk_queue_retry_ensure_corrupt
        tst.l   10(%a4)
        bne.w   .Lgk_queue_retry_ensure_corrupt
        tst.l   14(%a4)
        bne.w   .Lgk_queue_retry_ensure_corrupt
        tst.l   18(%a4)
        bne.w   .Lgk_queue_retry_ensure_corrupt
        tst.l   22(%a4)
        bne.w   .Lgk_queue_retry_ensure_corrupt
        move.l  GK_STOCK_EVENT_OBJECT + 4,%d4
        cmpi.l  #GK_STOCK_EVENT_QUEUE_CAPACITY,%d4
        bhi.w   .Lgk_queue_retry_ensure_corrupt
        move.l  GK_STOCK_EVENT_OBJECT + 0x10,%d0
        cmpi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d0
        bne.w   .Lgk_queue_retry_ensure_corrupt
        movea.l GK_STOCK_EVENT_OBJECT + 0x14,%a2
        cmpa.l  #GK_STOCK_EVENT_QUEUE_BUFFER,%a2
        bne.w   .Lgk_queue_retry_ensure_corrupt
        move.l  GK_STOCK_EVENT_OBJECT + 0x18,%d5
        cmpi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d5
        bhi.w   .Lgk_queue_retry_ensure_corrupt
        move.l  GK_STOCK_EVENT_OBJECT + 0x1c,%d6
        cmpi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d6
        bhi.w   .Lgk_queue_retry_ensure_corrupt
        move.l  %d6,%d0
        add.l   %d4,%d0
        andi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_queue_retry_ensure_corrupt
        moveq   #0,%d1
        move.l  %d4,%d7
        beq.s   .Lgk_queue_retry_scan_done
.Lgk_queue_retry_scan:
        move.l  %d6,%d0
        lsl.l   #2,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        cmpa.l  (%a3),%a4
        bne.s   .Lgk_queue_retry_scan_next
        addq.l  #1,%d1
        cmpi.l  #1,%d1
        bhi.w   .Lgk_queue_retry_ensure_corrupt
.Lgk_queue_retry_scan_next:
        addq.l  #1,%d6
        andi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d6
        subq.l  #1,%d7
        bne.s   .Lgk_queue_retry_scan
.Lgk_queue_retry_scan_done:
        move.l  %d3,%d0
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d0
        cmpi.l  #GK_PATTERN_QUEUE_QUEUED_BASE,%d0
        bne.s   .Lgk_queue_retry_unarmed
        cmpi.l  #1,%d1
        bhi.w   .Lgk_queue_retry_ensure_corrupt
        bra.w   .Lgk_queue_retry_ensure_ok
.Lgk_queue_retry_unarmed:
        cmpi.l  #GK_PATTERN_QUEUE_DEFERRED_BASE,%d0
        bne.w   .Lgk_queue_retry_ensure_corrupt
        tst.l   %d1
        bne.s   .Lgk_queue_retry_publish_queued
.Lgk_queue_retry_enqueue:
        cmpi.l  #GK_STOCK_EVENT_QUEUE_CAPACITY,%d4
        beq.w   .Lgk_queue_retry_ensure_overflow
        move.l  %a4,-(%sp)
        pea     GK_STOCK_EVENT_OBJECT
        jsr     GK_STOCK_EVENT_POINTER_PUSH
        lea     8(%sp),%sp
        addq.l  #1,%d4
        cmp.l   GK_STOCK_EVENT_OBJECT + 4,%d4
        bne.s   .Lgk_queue_retry_ensure_corrupt
        move.l  %d5,%d0
        lsl.l   #2,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        cmpa.l  (%a3),%a4
        bne.s   .Lgk_queue_retry_ensure_corrupt
        addq.l  #1,%d5
        andi.l  #GK_STOCK_EVENT_QUEUE_MASK,%d5
        cmp.l   GK_STOCK_EVENT_OBJECT + 0x18,%d5
        bne.s   .Lgk_queue_retry_ensure_corrupt
        moveq   #0,%d0
        move.b  __gk_pattern_queue_commit_prepared,%d0
        cmp.l   %d3,%d0
        bne.s   .Lgk_queue_retry_ensure_corrupt
.Lgk_queue_retry_publish_queued:
        move.l  %d3,%d0
        andi.l  #1,%d0
        ori.l   #GK_PATTERN_QUEUE_QUEUED_BASE,%d0
        .global gk_pattern_queue_retry_queued_publication
gk_pattern_queue_retry_queued_publication:
        move.b  %d0,__gk_pattern_queue_commit_prepared
.Lgk_queue_retry_ensure_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_queue_retry_ensure_restore
.Lgk_queue_retry_ensure_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
        bra.s   .Lgk_queue_retry_ensure_restore
.Lgk_queue_retry_ensure_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_queue_retry_ensure_restore:
        move.w  %d2,%d1
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        move.w  %d1,%sr
        rts
        .size   gk_pattern_queue_retry_event_ensure,.-gk_pattern_queue_retry_event_ensure
        .align  4
        .global gk_pattern_queue_handoff_retry_arm
        .type   gk_pattern_queue_handoff_retry_arm,@function
gk_pattern_queue_handoff_retry_arm:
        lea     -56(%sp),%sp
        movem.l %d1-%d7/%a0-%a6,(%sp)
        jsr     gk_pattern_queue_commit_defer_publish
        tst.l   %d0
        beq.s   .Lgk_handoff_retry_arm_ensure
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        bne.s   .Lgk_handoff_retry_arm_corrupt
.Lgk_handoff_retry_arm_ensure:
        jsr     gk_pattern_queue_retry_event_ensure
        tst.l   %d0
        beq.s   .Lgk_handoff_retry_arm_ok
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.s   .Lgk_handoff_retry_arm_ok
.Lgk_handoff_retry_arm_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_handoff_retry_arm_restore
.Lgk_handoff_retry_arm_ok:
        moveq   #GK_OK,%d0
.Lgk_handoff_retry_arm_restore:
        movem.l (%sp),%d1-%d7/%a0-%a6
        lea     56(%sp),%sp
        rts
        .size   gk_pattern_queue_handoff_retry_arm,.-gk_pattern_queue_handoff_retry_arm
        .align  4
        .global gk_pattern_queue_playback_handoff_stage
        .type   gk_pattern_queue_playback_handoff_stage,@function
gk_pattern_queue_playback_handoff_stage:
        lea     -48(%sp),%sp
        movem.l %d2-%d7/%a2-%a4,(%sp)
        clr.l   36(%sp)
        moveq   #GK_ARRANGER_NO_TOKEN,%d0
        move.l  %d0,40(%sp)
        moveq   #1,%d0
        cmp.b   __gk_sequencer_latch_queue_handoff,%d0
        bne.w   .Lgk_playback_stage_busy
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.w   .Lgk_playback_stage_busy
        jsr     gk_pattern_queue_commit_guard_enter
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_playback_stage_restore
        tst.l   %d0
        bmi.w   .Lgk_playback_stage_fatal
        move.l  %d0,36(%sp)
        move.w  %sr,%d0
        move.w  %d0,44(%sp)
        jsr     gk_arranger_queue_token_issue
        cmpi.l  #GK_ARRANGER_NO_TOKEN,%d0
        beq.s   .Lgk_playback_stage_token_ready
        tst.l   %d0
        bmi.w   .Lgk_playback_stage_fatal
.Lgk_playback_stage_token_ready:
        move.l  %d0,40(%sp)
        jsr     gk_pattern_queue_commit_prepare
        tst.l   %d0
        beq.s   .Lgk_playback_stage_prepared
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_playback_stage_retry
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.w   .Lgk_playback_stage_retry
        cmpi.l  #GK_ERR_EXHAUSTED,%d0
        beq.w   .Lgk_playback_stage_retry
        bra.w   .Lgk_playback_stage_fatal
.Lgk_playback_stage_prepared:
        moveq   #0,%d4
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d4
        moveq   #0,%d5
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d5
        move.l  %d4,%d0
        move.l  %d5,%d1
        jsr     gk_pattern_queue_commit_prepared_take
        tst.l   %d0
        bmi.w   .Lgk_playback_stage_fatal
        move.l  %d0,%d6
        move.l  %d1,%d7
        move.l %d6,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.w  GK_DESC_READERS(%a2),%d0
        cmpi.l  #0xffff,%d0
        beq.w   .Lgk_playback_stage_preflight_overflow
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%a0
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a0),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_playback_stage_preflight_busy
        move.w  44(%sp),%d0
        move.w  %d0,%sr
        moveq   #0,%d2
        move.b  __gk_pending_kit,%d2
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #GK_ARRANGER_OWNER_TOKEN,%d3
        jsr     gk_arranger_transition_adopt
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        beq.s   .Lgk_playback_stage_no_arranger
        tst.l   %d0
        bmi.w   .Lgk_playback_stage_fatal
        cmp.l   %d6,%d1
        bne.w   .Lgk_playback_stage_fatal
        move.l  %a0,%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_playback_stage_fatal
        bra.s   .Lgk_playback_stage_publish
.Lgk_playback_stage_no_arranger:
        move.l  40(%sp),%d0
        cmpi.l  #GK_ARRANGER_NO_TOKEN,%d0
        bne.w   .Lgk_playback_stage_fatal
.Lgk_playback_stage_publish:
        move.w  #0x2700,%sr
        moveq   #GK_PATTERN_QUEUE_PREPARED_BASE + 1,%d0
        cmp.b   __gk_pattern_queue_commit_prepared,%d0
        bne.w   .Lgk_playback_stage_fatal
        moveq   #1,%d0
        cmp.b   __gk_sequencer_latch_queue_handoff,%d0
        bne.w   .Lgk_playback_stage_fatal
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.w   .Lgk_playback_stage_fatal
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_BANK,%d4
        bne.w   .Lgk_playback_stage_fatal
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d5
        bne.w   .Lgk_playback_stage_fatal
        cmp.b   GK_STOCK_SEQUENCER_LATCH_BANK,%d4
        bne.w   .Lgk_playback_stage_fatal
        tst.l   GK_STOCK_AUDIO_LATCH_TRIGGER
        beq.w   .Lgk_playback_stage_fatal
        moveq   #0,%d0
        move.w  GK_DESC_READERS(%a2),%d0
        cmpi.l  #0xffff,%d0
        beq.w   .Lgk_playback_stage_fatal
        addq.l  #1,%d0
        move.w  %d0,GK_DESC_READERS(%a2)
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%a0
        move.l  %d6,%d0
        jsr     gk_selector_begin_update
        tst.l   %d0
        bne.w   .Lgk_playback_stage_fatal
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d5,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a2
        move.b  %d7,(%a2)
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.s   .Lgk_playback_stage_latch_publish
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a0
        move.b  %d7,(%a0)
.Lgk_playback_stage_latch_publish:
        move.b  %d7,GK_STOCK_SEQUENCER_LATCH_PART
        move.w  44(%sp),%d0
        move.w  %d0,%sr
        tst.l   36(%sp)
        beq.s   .Lgk_playback_stage_ok
        jsr     gk_arranger_guard_exit
        tst.l   %d0
        bne.w   .Lgk_playback_stage_fatal
.Lgk_playback_stage_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_playback_stage_restore
.Lgk_playback_stage_preflight_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
        bra.s   .Lgk_playback_stage_preflight_abort
.Lgk_playback_stage_preflight_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_playback_stage_preflight_abort:
        movea.l %d0,%a4
        move.w  44(%sp),%d0
        move.w  %d0,%sr
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.s   .Lgk_playback_stage_fatal
        move.w  #0x2700,%sr
        moveq   #GK_PATTERN_QUEUE_PREPARED_BASE + 1,%d0
        cmp.b   __gk_pattern_queue_commit_prepared,%d0
        bne.s   .Lgk_playback_stage_fatal
        moveq   #GK_PATTERN_QUEUE_DISPATCHING_BASE + 1,%d0
        move.b  %d0,__gk_pattern_queue_commit_prepared
        move.w  44(%sp),%d0
        move.w  %d0,%sr
        move.l  %a4,%d0
.Lgk_playback_stage_retry:
        movea.l %d0,%a4
        move.l  40(%sp),%d0
        jsr     gk_arranger_queue_token_defer
        tst.l   %d0
        bne.s   .Lgk_playback_stage_fatal
        tst.l   36(%sp)
        beq.s   .Lgk_playback_stage_retry_status
        jsr     gk_arranger_guard_exit
        tst.l   %d0
        bne.s   .Lgk_playback_stage_fatal
.Lgk_playback_stage_retry_status:
        move.l  %a4,%d0
        bra.s   .Lgk_playback_stage_restore
.Lgk_playback_stage_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_playback_stage_restore
.Lgk_playback_stage_fatal:
        movem.l (%sp),%d2-%d7/%a2-%a4
        lea     48(%sp),%sp
        jmp     gk_pattern_queue_playback_stage_fatal
.Lgk_playback_stage_restore:
        movem.l (%sp),%d2-%d7/%a2-%a4
        lea     48(%sp),%sp
        rts
        .size   gk_pattern_queue_playback_handoff_stage,.-gk_pattern_queue_playback_handoff_stage
        .align  4
        .global gk_pattern_queue_audio_handoff_ready
        .type   gk_pattern_queue_audio_handoff_ready,@function
gk_pattern_queue_audio_handoff_ready:
        lea     -16(%sp),%sp
        movem.l %d1-%d3/%a1,(%sp)
        moveq   #1,%d0
        cmp.b   __gk_sequencer_latch_queue_handoff,%d0
        bne.s   .Lgk_playback_audio_not_ready
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.s   .Lgk_playback_audio_not_ready
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d1
        jsr     gk_pattern_queue_commit_prepared_take
        tst.l   %d0
        bmi.s   .Lgk_playback_audio_not_ready
        move.l  %d0,%d2
        move.l  %d1,%d3
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        cmp.b   GK_STOCK_SEQUENCER_LATCH_BANK,%d0
        bne.s   .Lgk_playback_audio_not_ready
        cmp.b   GK_STOCK_SEQUENCER_LATCH_PART,%d3
        bne.s   .Lgk_playback_audio_not_ready
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%a1
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a1),%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_playback_audio_not_ready
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        tst.w   GK_DESC_READERS(%a1)
        beq.s   .Lgk_playback_audio_not_ready
        move.l  %d2,%d0
        bra.s   .Lgk_playback_audio_restore
.Lgk_playback_audio_not_ready:
        moveq   #GK_ERR_UPDATING,%d0
.Lgk_playback_audio_restore:
        movem.l (%sp),%d1-%d3/%a1
        lea     16(%sp),%sp
        rts
        .size   gk_pattern_queue_audio_handoff_ready,.-gk_pattern_queue_audio_handoff_ready
        .align  4
        .global gk_pattern_queue_audio_handoff_finish
        .type   gk_pattern_queue_audio_handoff_finish,@function
gk_pattern_queue_audio_handoff_finish:
        .incbin "stock/0389.bin", 0, 4
        .incbin "stock/0389.bin", 4, 4
        moveq   #1,%d0
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.w   .Lgk_playback_audio_finish_corrupt
        tst.l   GK_STOCK_AUDIO_LATCH_TRIGGER
        bne.w   .Lgk_playback_audio_finish_corrupt
        moveq   #0,%d4
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d4
        moveq   #0,%d5
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d5
        move.l  %d4,%d0
        move.l  %d5,%d1
        jsr     gk_pattern_queue_commit_prepared_take
        tst.l   %d0
        bmi.w   .Lgk_playback_audio_finish_corrupt
        move.l  %d0,%d7
        move.l  %d1,%d6
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_playback_audio_finish_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_playback_audio_finish_corrupt
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   .Lgk_playback_audio_finish_corrupt
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        jsr     gk_selector_acquire
        tst.l   %d0
        bmi.w   .Lgk_playback_audio_finish_corrupt
        move.l  %d0,%d3
        cmp.l   %d7,%d0
        bne.w   .Lgk_playback_audio_finish_release_corrupt
        jsr     gk_stock_latest_engine_context_validate
        tst.l   %d0
        bmi.w   .Lgk_playback_audio_finish_release_corrupt
        cmp.l   %d4,%d0
        bne.w   .Lgk_playback_audio_finish_release_corrupt
        cmp.l   %d5,%d1
        bne.w   .Lgk_playback_audio_finish_release_corrupt
        move.l  %d3,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   .Lgk_playback_audio_finish_corrupt
        move.l  %d6,%d0
        jsr     gk_sequencer_latch_commit_part
        tst.l   %d0
        bne.w   .Lgk_playback_audio_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_kind,%d0
        beq.s   .Lgk_playback_audio_finish_ui
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d0
        beq.s   .Lgk_playback_audio_finish_arranger
        cmpi.l  #GK_ARRANGER_STATE_ARMED_DEFERRED,%d0
        beq.s   .Lgk_playback_audio_finish_ui
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d0
        bne.s   .Lgk_playback_audio_finish_corrupt
        bra.s   .Lgk_playback_audio_finish_ui
.Lgk_playback_audio_finish_arranger:
        jsr     gk_arranger_consume_finish
        tst.l   %d0
        bne.s   .Lgk_playback_audio_finish_corrupt
.Lgk_playback_audio_finish_ui:
        jsr     gk_ui_transition_retry_ensure
        tst.l   %d0
        beq.s   .Lgk_playback_audio_finish_retire
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.w   gk_pattern_queue_retry_overflow_fatal
        bra.s   .Lgk_playback_audio_finish_corrupt
.Lgk_playback_audio_finish_retire:
        moveq   #1,%d0
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.s   .Lgk_playback_audio_finish_corrupt
        jsr     gk_pattern_queue_handoff_marker_retire
        jsr     gk_audio_latch_ready
        cmp.l   %d7,%d0
        bne.s   .Lgk_playback_audio_finish_corrupt
        moveq   #GK_OK,%d0
        bra.s   .Lgk_playback_audio_finish_restore
.Lgk_playback_audio_finish_release_corrupt:
        move.l  %d3,%d0
        jsr     gk_descriptor_release
.Lgk_playback_audio_finish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_playback_audio_finish_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
        .size   gk_pattern_queue_audio_handoff_finish,.-gk_pattern_queue_audio_handoff_finish
        .align  4
        .global gk_stock_audio_pattern_part_load_commit
        .type   gk_stock_audio_pattern_part_load_commit,@function
gk_stock_audio_pattern_part_load_commit:
        tst.b   __gk_sequencer_latch_queue_handoff
        beq.s   .Lgk_playback_audio_load_stock
        moveq   #GK_PATTERN_QUEUE_PREPARED_BASE + 1,%d0
        cmp.b   __gk_pattern_queue_commit_prepared,%d0
        bne.s   .Lgk_playback_audio_load_fatal
        move.l  %d1,(%sp)
        jsr     GK_STOCK_ENGINE_PATTERN_PART_LOAD
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        jsr     gk_pattern_queue_audio_handoff_finish
        tst.l   %d0
        bne.s   .Lgk_playback_audio_load_post_fatal
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
        jmp     GK_STOCK_AUDIO_PATTERN_PART_LOAD_CONTINUE
.Lgk_playback_audio_load_post_fatal:
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
.Lgk_playback_audio_load_fatal:
        jmp     gk_pattern_queue_audio_handoff_fatal
.Lgk_playback_audio_load_stock:
        move.l  %d1,(%sp)
        jsr     GK_STOCK_ENGINE_PATTERN_PART_LOAD
        jmp     GK_STOCK_AUDIO_PATTERN_PART_LOAD_CONTINUE
        .size   gk_stock_audio_pattern_part_load_commit,.-gk_stock_audio_pattern_part_load_commit
        .align  4
        .global gk_pattern_queue_retry_callback
        .type   gk_pattern_queue_retry_callback,@function
gk_pattern_queue_retry_callback:
        lea     -20(%sp),%sp
        movem.l %d2-%d4/%a2,(%sp)
        move.w  %sr,%d4
        move.w  %d4,16(%sp)
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_pattern_queue_commit_prepared,%d0
        beq.w   .Lgk_queue_retry_callback_ok
        move.l  %d0,%d1
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d1
        cmpi.l  #GK_PATTERN_QUEUE_PREPARED_BASE,%d1
        beq.w   .Lgk_queue_retry_callback_ok
        cmpa.l  #__gk_pattern_queue_retry_event,%a2
        bne.w   gk_pattern_queue_retry_callback_fatal
        cmpi.l  #GK_PATTERN_QUEUE_QUEUED_BASE,%d1
        beq.s   .Lgk_queue_retry_callback_claim
        cmpi.l  #GK_PATTERN_QUEUE_DEFERRED_BASE,%d1
        bne.w   gk_pattern_queue_retry_callback_fatal
.Lgk_queue_retry_callback_claim:
        moveq   #0,%d2
        move.b  __gk_sequencer_latch_queue_handoff,%d2
        cmpi.l  #1,%d2
        bhi.w   gk_pattern_queue_retry_callback_fatal
        move.l  %d0,%d3
        andi.l  #1,%d3
        cmp.l   %d2,%d3
        bne.w   gk_pattern_queue_retry_callback_fatal
        ori.l   #GK_PATTERN_QUEUE_DISPATCHING_BASE,%d3
        .global gk_pattern_queue_retry_dispatch_publication
gk_pattern_queue_retry_dispatch_publication:
        move.b  %d3,__gk_pattern_queue_commit_prepared
        move.w  16(%sp),%d1
        move.w  %d1,%sr
        tst.l   %d2
        beq.s   .Lgk_queue_retry_callback_stock_consumer
        jsr     gk_pattern_queue_playback_handoff_stage
        tst.l   %d0
        beq.s   .Lgk_queue_retry_callback_playback_staged
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_queue_retry_callback_post_dispatch
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.s   .Lgk_queue_retry_callback_post_dispatch
        cmpi.l  #GK_ERR_EXHAUSTED,%d0
        beq.s   .Lgk_queue_retry_callback_post_dispatch
        bra.w   gk_pattern_queue_retry_callback_fatal
.Lgk_queue_retry_callback_playback_staged:
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_pattern_queue_commit_prepared,%d0
        beq.s   .Lgk_queue_retry_callback_playback_retired
        cmpi.l  #GK_PATTERN_QUEUE_PREPARED_BASE + 1,%d0
        bne.w   gk_pattern_queue_retry_callback_fatal
        moveq   #1,%d0
        cmp.b   __gk_sequencer_latch_queue_handoff,%d0
        bne.w   gk_pattern_queue_retry_callback_fatal
        bra.s   .Lgk_queue_retry_callback_ok
.Lgk_queue_retry_callback_playback_retired:
        tst.b   __gk_sequencer_latch_queue_handoff
        bne.w   gk_pattern_queue_retry_callback_fatal
        bra.s   .Lgk_queue_retry_callback_ok
.Lgk_queue_retry_callback_stock_consumer:
        jsr     GK_STOCK_PATTERN_QUEUE_COMMIT_ENTRY
.Lgk_queue_retry_callback_post_dispatch:
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_pattern_queue_commit_prepared,%d0
        beq.s   .Lgk_queue_retry_callback_ok
        move.l  %d0,%d1
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d1
        cmpi.l  #GK_PATTERN_QUEUE_DISPATCHING_BASE,%d1
        bne.w   gk_pattern_queue_retry_callback_fatal
        moveq   #0,%d2
        move.b  __gk_sequencer_latch_queue_handoff,%d2
        cmpi.l  #1,%d2
        bhi.w   gk_pattern_queue_retry_callback_fatal
        andi.l  #1,%d0
        cmp.l   %d2,%d0
        bne.w   gk_pattern_queue_retry_callback_fatal
        ori.l   #GK_PATTERN_QUEUE_DEFERRED_BASE,%d0
        .global gk_pattern_queue_retry_deferred_retirement
gk_pattern_queue_retry_deferred_retirement:
        move.b  %d0,__gk_pattern_queue_commit_prepared
.Lgk_queue_retry_callback_ok:
        move.w  16(%sp),%d1
        movem.l (%sp),%d2-%d4/%a2
        lea     20(%sp),%sp
        move.w  %d1,%sr
        moveq   #GK_OK,%d0
        rts
        .size   gk_pattern_queue_retry_callback,.-gk_pattern_queue_retry_callback
        .align  4
        .global gk_stock_pattern_queue_retry_event_epilogue
        .type   gk_stock_pattern_queue_retry_event_epilogue,@function
gk_stock_pattern_queue_retry_event_epilogue:
        cmpa.l  #__gk_pattern_queue_retry_event,%a2
        beq.s   .Lgk_queue_retry_epilogue_stock
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        jsr     gk_pattern_queue_retry_event_ensure
        tst.l   %d0
        beq.s   .Lgk_queue_retry_epilogue_restore
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.w   gk_pattern_queue_retry_overflow_fatal
        jmp     gk_pattern_queue_commit_defer_fatal
.Lgk_queue_retry_epilogue_restore:
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
.Lgk_queue_retry_epilogue_stock:
        .global gk_pattern_queue_retry_event_epilogue_stock_replay
gk_pattern_queue_retry_event_epilogue_stock_replay:
        .incbin "stock/0390.bin", 0, 6
        jmp     GK_STOCK_UI_EVENT_EPILOGUE_CONTINUE
        .size   gk_stock_pattern_queue_retry_event_epilogue,.-gk_stock_pattern_queue_retry_event_epilogue
        .align  2
        .global __gk_pattern_queue_retry_event
__gk_pattern_queue_retry_event:
        .byte   GK_PATTERN_QUEUE_RETRY_EVENT_ID,0
        .byte 0x45,0xd2,0xd2
        .incbin "stock/0391.bin", 0, 1
        .incbin "stock/0391.bin", 1, 4
        .incbin "stock/0391.bin", 5, 4
        .incbin "stock/0391.bin", 9, 4
        .incbin "stock/0391.bin", 13, 4
        .incbin "stock/0391.bin", 17, 4
        .global __gk_pattern_queue_retry_event_end
__gk_pattern_queue_retry_event_end:
        .global gk_pattern_queue_commit_prepared_take
        .type   gk_pattern_queue_commit_prepared_take,@function
gk_pattern_queue_commit_prepared_take:
        .incbin "stock/0392.bin", 0, 1
        .byte 0x80,0x00,0x00,0x00,0x0f
        bhi.w   .Lgk_queue_take_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_queue_take_range
        .incbin "stock/0393.bin", 0, 4
        .incbin "stock/0393.bin", 4, 4
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d3
        move.b  __gk_pattern_queue_commit_prepared,%d3
        move.l  %d3,%d0
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d0
        cmpi.l  #GK_PATTERN_QUEUE_PREPARED_BASE,%d0
        bne.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  __gk_sequencer_latch_queue_handoff,%d0
        andi.l  #1,%d3
        cmp.l   %d3,%d0
        bne.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   .Lgk_queue_take_corrupt
        andi.l  #0x7e,%d0
        bne.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_queue_take_corrupt
        moveq   #0,%d2
        move.b  __gk_pending_workspace_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        cmpi.l  #7,%d0
        bhi.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_bound,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_ui_capture_created,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_queue_take_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        btst    #0,%d0
        beq.w   .Lgk_queue_take_corrupt
        andi.l  #0xe6,%d0
        bne.w   .Lgk_queue_take_corrupt
        movea.l GK_DESC_PAYLOAD(%a2),%a3
        tst.l   %a3
        beq.w   .Lgk_queue_take_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_queue_take_corrupt
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_queue_take_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a2),%d0
        moveq   #0,%d1
        move.b  __gk_pending_kit,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_queue_take_corrupt
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a2),%d3
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w   .Lgk_queue_take_corrupt
        move.l  %d3,%d0
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_queue_take_corrupt
        move.l  %d3,%d0
        jsr     gk_physical_validate
        cmp.l   %d2,%d0
        bne.w   .Lgk_queue_take_corrupt
        lea     __gk_lease_sidecars,%a0
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a0),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_queue_take_corrupt
        move.l  %d2,%d0
        move.l  %d3,%d1
        andi.l  #3,%d1
        movea.l %a3,%a0
        bra.s   .Lgk_queue_take_restore
.Lgk_queue_take_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_queue_take_restore:
        .incbin "stock/0394.bin", 0, 4
        .incbin "stock/0394.bin", 4, 4
        rts
.Lgk_queue_take_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_pattern_queue_commit_prepared_take,.-gk_pattern_queue_commit_prepared_take
        .global gk_pattern_queue_commit_prepared_finish
        .type   gk_pattern_queue_commit_prepared_finish,@function
gk_pattern_queue_commit_prepared_finish:
        moveq   #0,%d0
        move.b  __gk_pattern_queue_commit_prepared,%d0
        beq.w   .Lgk_queue_finish_ok
        move.l  %d0,%d1
        andi.l  #GK_PATTERN_QUEUE_PREPARED_MASK,%d0
        cmpi.l  #GK_PATTERN_QUEUE_PREPARED_BASE,%d0
        bne.w   .Lgk_queue_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_sequencer_latch_queue_handoff,%d0
        andi.l  #1,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_queue_finish_corrupt
        tst.l   GK_STOCK_SCHEDULER_STATE
        bne.w   .Lgk_queue_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        bne.w   .Lgk_queue_finish_corrupt
        andi.l  #0x7e,%d0
        bne.w   .Lgk_queue_finish_corrupt
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_queue_finish_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_queue_finish_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_queue_finish_corrupt
        tst.b   __gk_pending_workspace_bound
        bne.w   .Lgk_queue_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        bne.w   .Lgk_queue_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d0
        bne.w   .Lgk_queue_finish_corrupt
        tst.l   %d1
        bne.s   .Lgk_queue_finish_ok
        .global gk_pattern_queue_commit_prepared_retirement
gk_pattern_queue_commit_prepared_retirement:
        clr.b   __gk_pattern_queue_commit_prepared
.Lgk_queue_finish_ok:
        moveq   #GK_OK,%d0
        rts
.Lgk_queue_finish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_pattern_queue_commit_prepared_finish,.-gk_pattern_queue_commit_prepared_finish
        .align  4
        .global gk_pattern_queue_handoff_marker_retire
        .type   gk_pattern_queue_handoff_marker_retire,@function
gk_pattern_queue_handoff_marker_retire:
        lea     -12(%sp),%sp
        movem.l %d1-%d2,(%sp)
        move.w  %sr,%d2
        move.w  %d2,8(%sp)
        move.w  #0x2700,%sr
        moveq   #1,%d0
        cmp.b   __gk_sequencer_latch_queue_handoff,%d0
        bne.s   .Lgk_queue_marker_retire_corrupt
        moveq   #GK_PATTERN_QUEUE_PREPARED_BASE + 1,%d1
        cmp.b   __gk_pattern_queue_commit_prepared,%d1
        bne.s   .Lgk_queue_marker_retire_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        andi.l  #0xfe,%d0
        bne.s   .Lgk_queue_marker_retire_corrupt
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.s   .Lgk_queue_marker_retire_corrupt
        tst.b   __gk_pending_transition_flags
        bne.s   .Lgk_queue_marker_retire_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.s   .Lgk_queue_marker_retire_corrupt
        tst.b   __gk_pending_workspace_bound
        bne.s   .Lgk_queue_marker_retire_corrupt
        .global gk_pattern_queue_commit_marked_retirement
gk_pattern_queue_commit_marked_retirement:
        clr.b   __gk_pattern_queue_commit_prepared
        clr.b   __gk_sequencer_latch_queue_handoff
        moveq   #GK_OK,%d0
        bra.s   .Lgk_queue_marker_retire_restore
.Lgk_queue_marker_retire_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_queue_marker_retire_restore:
        move.w  8(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d1-%d2
        lea     12(%sp),%sp
        tst.l   %d0
        bne.w   gk_pattern_queue_handoff_marker_retire_fatal
        rts
        .size   gk_pattern_queue_handoff_marker_retire,.-gk_pattern_queue_handoff_marker_retire
        .align  4
        .global gk_ui_transition_cross_bank_playback_validate
        .type   gk_ui_transition_cross_bank_playback_validate,@function
gk_ui_transition_cross_bank_playback_validate:
        moveq   #1,%d0
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.w   .Lgk_cross_bank_playback_corrupt
        cmp.b   __gk_sequencer_latch_queue_handoff,%d0
        bne.w   .Lgk_cross_bank_playback_corrupt
        move.l  GK_STOCK_AUDIO_LATCH_TRIGGER,%d1
        andi.l  #0xffff00fd,%d1
        cmpi.l  #1,%d1
        bne.w   .Lgk_cross_bank_playback_corrupt
        moveq   #GK_PATTERN_QUEUE_DISPATCHING_BASE + 1,%d0
        cmp.b   __gk_pattern_queue_commit_prepared,%d0
        bne.w   .Lgk_cross_bank_playback_corrupt
        move.l %d7,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a0
        adda.l %d1,%a0
        moveq   #0,%d1
        move.b  GK_DESC_PHYSICAL(%a0),%d1
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_cross_bank_playback_corrupt
        lsr.l   #2,%d1
        moveq   #0,%d0
        move.b  __gk_pending_bank,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_cross_bank_playback_corrupt
        cmp.l   %d1,%d0
        bne.w   .Lgk_cross_bank_playback_corrupt
        cmp.l   %d4,%d0
        beq.w   .Lgk_cross_bank_playback_corrupt
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        bne.w   .Lgk_cross_bank_playback_corrupt
        cmp.b   GK_STOCK_SEQUENCER_LATCH_BANK,%d0
        bne.w   .Lgk_cross_bank_playback_corrupt
        cmp.b   GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        bne.w   .Lgk_cross_bank_playback_corrupt
        cmp.b   GK_STOCK_CURRENT_BANK_MIRROR,%d0
        bne.w   .Lgk_cross_bank_playback_corrupt
        moveq   #0,%d1
        move.b  __gk_pending_pattern,%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_cross_bank_playback_corrupt
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d1
        bne.w   .Lgk_cross_bank_playback_corrupt
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a0
        adda.l  %d0,%a0
        movea.l GK_STOCK_BANK_POINTER,%a1
        cmpa.l  %a0,%a1
        bne.w   .Lgk_cross_bank_playback_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_cross_bank_playback_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_ui_transition_cross_bank_playback_validate,.-gk_ui_transition_cross_bank_playback_validate
        .align  4
        .global gk_pattern_queue_clone_reader_validate
        .type   gk_pattern_queue_clone_reader_validate,@function
gk_pattern_queue_clone_reader_validate:
        lea     -36(%sp),%sp
        movem.l %d1-%d6/%a0-%a2,(%sp)
        move.l  %d0,%d2
        move.l  %d1,%d3
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_clone_reader_busy
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w   .Lgk_clone_reader_busy
        cmp.l   %d3,%d2
        beq.w   .Lgk_clone_reader_busy
        moveq   #1,%d0
        cmp.b   __gk_sequencer_latch_queue_handoff,%d0
        bne.w   .Lgk_clone_reader_busy
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.w   .Lgk_clone_reader_busy
        move.l  GK_STOCK_AUDIO_LATCH_TRIGGER,%d1
        andi.l  #0xffff00fd,%d1
        cmpi.l  #1,%d1
        bne.w   .Lgk_clone_reader_busy
        moveq   #GK_PATTERN_QUEUE_DISPATCHING_BASE + 1,%d0
        cmp.b   __gk_pattern_queue_commit_prepared,%d0
        bne.w   .Lgk_clone_reader_busy
        moveq   #1,%d0
        cmp.b   __gk_arranger_guard_depth,%d0
        bne.w   .Lgk_clone_reader_busy
        tst.w   __gk_arranger_guard_reserved
        bne.w   .Lgk_clone_reader_busy
        tst.w   __gk_arranger_guard_saved_sr_pad
        bne.w   .Lgk_clone_reader_busy
        tst.w   __gk_arranger_guard_saved_sr
        beq.w   .Lgk_clone_reader_busy
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        andi.l  #0xfe,%d0
        bne.w   .Lgk_clone_reader_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_clone_reader_busy
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_clone_reader_busy
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_clone_reader_busy
        tst.b   __gk_pending_workspace_bound
        bne.w   .Lgk_clone_reader_busy
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_clone_reader_busy
        move.l  %d2,%d0
        lsl.l   #8,%d0
        or.l    %d3,%d0
        moveq   #0,%d1
        move.w  __gk_lease_sidecars,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_clone_reader_busy
        andi.l  #0xff00,%d0
        ori.l   #0xff,%d0
        moveq   #0,%d1
        move.w  __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_clone_reader_busy
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a0
        adda.l %d0,%a0
        moveq   #0,%d0
        move.w  GK_DESC_READERS(%a0),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_clone_reader_busy
        moveq   #0,%d4
        move.b  __gk_current_bank,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_clone_reader_busy
        moveq   #0,%d5
        move.b  __gk_current_pattern,%d5
        cmpi.l  #15,%d5
        bhi.w   .Lgk_clone_reader_busy
        moveq   #0,%d6
        move.b  __gk_current_kit,%d6
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a0),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_clone_reader_busy
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a0),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_clone_reader_busy
        move.l  %d0,%d1
        lsr.l   #2,%d1
        cmp.l   %d4,%d1
        bne.w   .Lgk_clone_reader_busy
        andi.l  #3,%d0
        cmp.b   GK_STOCK_ENGINE_PART,%d0
        bne.w   .Lgk_clone_reader_busy
        cmp.b   GK_STOCK_ENGINE_BANK,%d4
        bne.w   .Lgk_clone_reader_busy
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a1),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_clone_reader_busy
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a1),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_clone_reader_busy
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        beq.w   .Lgk_clone_reader_busy
        cmp.b   GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        bne.w   .Lgk_clone_reader_busy
        moveq   #0,%d1
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_clone_reader_busy
        lsl.l   #4,%d0
        add.l   %d1,%d0
        lea     __gk_pattern_assignments,%a2
        moveq   #0,%d1
        move.b  (%a2,%d0.l),%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_clone_reader_busy
        moveq   #GK_OK,%d0
        bra.s   .Lgk_clone_reader_restore
.Lgk_clone_reader_busy:
        moveq   #GK_ERR_BUSY,%d0
        .global gk_pattern_queue_clone_reader_validate_restore
gk_pattern_queue_clone_reader_validate_restore:
.Lgk_clone_reader_restore:
        movem.l (%sp),%d1-%d6/%a0-%a2
        lea     36(%sp),%sp
        rts
        .size   gk_pattern_queue_clone_reader_validate,.-gk_pattern_queue_clone_reader_validate
        .global gk_pattern_queue_commit_prepare_fatal
gk_pattern_queue_commit_prepare_fatal:
        illegal
        bra.s gk_pattern_queue_commit_prepare_fatal
        .global gk_pattern_queue_commit_guard_enter_fatal
gk_pattern_queue_commit_guard_enter_fatal:
        illegal
        bra.s gk_pattern_queue_commit_guard_enter_fatal
        .global gk_pattern_queue_commit_guard_exit_fatal
gk_pattern_queue_commit_guard_exit_fatal:
        illegal
        bra.s gk_pattern_queue_commit_guard_exit_fatal
        .global gk_pattern_queue_commit_defer_fatal
gk_pattern_queue_commit_defer_fatal:
        illegal
        bra.s gk_pattern_queue_commit_defer_fatal
        .global gk_pattern_queue_commit_prepared_fatal
gk_pattern_queue_commit_prepared_fatal:
        illegal
        bra.s gk_pattern_queue_commit_prepared_fatal
        .global gk_pattern_queue_commit_finish_fatal
gk_pattern_queue_commit_finish_fatal:
        illegal
        bra.s gk_pattern_queue_commit_finish_fatal
        .global gk_pattern_queue_commit_exit_fatal
gk_pattern_queue_commit_exit_fatal:
        illegal
        bra.s gk_pattern_queue_commit_exit_fatal
        .global gk_arranger_queue_commit_prepared_fatal
gk_arranger_queue_commit_prepared_fatal:
        illegal
        bra.s gk_arranger_queue_commit_prepared_fatal
        .global gk_pattern_queue_retry_callback_fatal
gk_pattern_queue_retry_callback_fatal:
        illegal
        bra.s gk_pattern_queue_retry_callback_fatal
        .global gk_pattern_queue_retry_overflow_fatal
gk_pattern_queue_retry_overflow_fatal:
        illegal
        bra.s gk_pattern_queue_retry_overflow_fatal
        .global gk_pattern_queue_handoff_marker_fatal
gk_pattern_queue_handoff_marker_fatal:
        illegal
        bra.s gk_pattern_queue_handoff_marker_fatal
        .global gk_pattern_queue_handoff_marker_retire_fatal
gk_pattern_queue_handoff_marker_retire_fatal:
        illegal
        bra.s gk_pattern_queue_handoff_marker_retire_fatal
        .global gk_pattern_queue_request_ipl_fatal
gk_pattern_queue_request_ipl_fatal:
        illegal
        bra.s gk_pattern_queue_request_ipl_fatal
        .global gk_pattern_queue_handoff_retry_arm_fatal
gk_pattern_queue_handoff_retry_arm_fatal:
        illegal
        bra.s gk_pattern_queue_handoff_retry_arm_fatal
        .global gk_pattern_queue_playback_stage_fatal
gk_pattern_queue_playback_stage_fatal:
        illegal
        bra.s gk_pattern_queue_playback_stage_fatal
        .global gk_pattern_queue_audio_handoff_fatal
gk_pattern_queue_audio_handoff_fatal:
        illegal
        bra.s gk_pattern_queue_audio_handoff_fatal
