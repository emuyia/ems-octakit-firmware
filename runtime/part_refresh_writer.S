        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_part_refresh_abort_fatal,@function
gk_part_refresh_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_part_refresh_fatal_cleanup
        bra.w   gk_part_refresh_fatal_workspace
        .size   gk_part_refresh_abort_fatal,.-gk_part_refresh_abort_fatal
        .type   gk_part_refresh_release_abort_fatal,@function
gk_part_refresh_release_abort_fatal:
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_part_refresh_fatal_cleanup
        bra.w   gk_part_refresh_abort_fatal
        .size   gk_part_refresh_release_abort_fatal,.-gk_part_refresh_release_abort_fatal
        .global gk_stock_part_refresh_writer
        .type   gk_stock_part_refresh_writer,@function
gk_stock_part_refresh_writer:
        lea     -12(%sp),%sp
        movem.l %d0-%d1/%a0,(%sp)
        move.w  %sr,%d0
        movea.l %d0,%a0
        move.l  __gk_lifecycle_state,%d1
        beq.s   .Lgk_part_refresh_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_part_refresh_fatal_lifecycle
        move.l  %a0,%d1
        move.w  %d1,%sr
        movem.l (%sp),%d0-%d1/%a0
        lea     12(%sp),%sp
        bra.w   gk_stock_part_refresh_writer_trampoline
.Lgk_part_refresh_active:
        move.l  %a0,%d1
        move.w  %d1,%sr
        movem.l (%sp),%d0-%d1/%a0
        lea     12(%sp),%sp
        .incbin "stock/0342.bin", 0, 4
        .incbin "stock/0342.bin", 4, 4
        move.l  68(%sp),%d0
        moveq   #0,%d3
        cmpi.l  #GK_STOCK_PART_REFRESH_WRITER_RETURN_UI_A,%d0
        beq.s   .Lgk_part_refresh_caller_ok
        cmpi.l  #GK_STOCK_PART_REFRESH_WRITER_RETURN_UI_B,%d0
        beq.s   .Lgk_part_refresh_caller_ok
        cmpi.l  #GK_STOCK_PART_REFRESH_WRITER_RETURN_TRACK,%d0
        beq.s   .Lgk_part_refresh_caller_ok
        cmpi.l  #gk_stock_part_event_refresh_f_return,%d0
        bne.w   gk_part_refresh_fatal_caller
        moveq   #2,%d3
.Lgk_part_refresh_caller_ok:
        move.w  %d3,62(%sp)
        moveq   #7,%d1
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmp.l   %d0,%d1
        bcs.w   gk_part_refresh_fatal_track
        movea.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d0
        cmp.l   %d0,%d1
        bcs.w   gk_part_refresh_fatal_engine_track
        movea.l %d0,%a5
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_UI_TRACK_SECONDARY,%d0
        cmp.l   %d0,%d1
        bcs.w   gk_part_refresh_fatal_engine_track
        movea.l %d0,%a6
        move.l  GK_STOCK_TRACK_MODE,%d0
        move.l  %d0,64(%sp)
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        moveq   #3,%d1
        cmp.l   %d0,%d1
        bcs.w   gk_part_refresh_fatal_part
        movea.l %d0,%a2
        tst.l   %d3
        beq.s   .Lgk_part_refresh_settled_context
        move.l  %d6,%d0
        jsr     gk_stock_latest_engine_context_validate
        tst.l   %d0
        bmi.w   gk_part_refresh_fatal_context
        move.l  %d7,%d2
        cmp.l   %a2,%d2
        bne.w   gk_part_refresh_fatal_context
        move.l  %a0,%d2
        cmp.l   %a2,%d2
        bne.w   gk_part_refresh_fatal_context
        bra.s   .Lgk_part_refresh_context_ok
.Lgk_part_refresh_settled_context:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_part_refresh_fatal_context
.Lgk_part_refresh_context_ok:
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        moveq   #GK_DESCRIPTOR_COUNT - 1,%d0
        cmp.l   %d6,%d0
        bcs.w   gk_part_refresh_fatal_descriptor
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_part_refresh_fatal_workspace
        cmp.l   %d6,%d0
        bne.w   gk_part_refresh_abort_fatal
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_part_refresh_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_part_refresh_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_part_refresh_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_part_refresh_release_abort_fatal
        move.l  %d6,%d7
        move.l  %a4,%d0
        lsl.l   #7,%d0
        or.l    %d0,%d7
        move.l  %a2,%d0
        lsl.l   #8,%d0
        lsl.l   #2,%d0
        or.l    %d0,%d7
        move.l  %d4,%d0
        lsl.l   #8,%d0
        lsl.l   #4,%d0
        or.l    %d0,%d7
        ori.l   #GK_PART_REFRESH_TOKEN_ARMED,%d7
        .global gk_part_refresh_stock_call
gk_part_refresh_stock_call:
        bsr.w   gk_stock_part_refresh_writer_trampoline
        move.l  %d0,44(%sp)
        move.l  %d1,48(%sp)
        move.l  %a0,52(%sp)
        move.l  %a1,56(%sp)
        move.w  %sr,%d2
        move.w  %d2,60(%sp)
        move.l  %d7,%d0
        andi.l  #GK_PART_REFRESH_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_PART_REFRESH_TOKEN_WRITTEN,%d0
        beq.s   .Lgk_part_refresh_written
        cmpi.l  #GK_PART_REFRESH_TOKEN_ARMED,%d0
        bne.w   gk_part_refresh_fatal_token
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_part_refresh_fatal_release
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_part_refresh_fatal_abort
        bra.s   .Lgk_part_refresh_post_validate
.Lgk_part_refresh_written:
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_part_refresh_fatal_mark_dirty
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_part_refresh_fatal_commit
        moveq   #0,%d3
        move.w  62(%sp),%d3
        ori.l   #1,%d3
        move.w  %d3,62(%sp)
.Lgk_part_refresh_post_validate:
        moveq   #0,%d3
        move.w  62(%sp),%d3
        btst    #1,%d3
        beq.s   .Lgk_part_refresh_post_settled
        move.l  %d6,%d0
        jsr     gk_stock_latest_engine_context_validate
        bra.s   .Lgk_part_refresh_post_context_result
.Lgk_part_refresh_post_settled:
        jsr     gk_stock_current_context_validate
.Lgk_part_refresh_post_context_result:
        tst.l   %d0
        bmi.w   gk_part_refresh_fatal_post_context
        cmp.l   %d4,%d0
        bne.w   gk_part_refresh_fatal_post_context
        cmp.l   %d5,%d1
        bne.w   gk_part_refresh_fatal_post_context
        btst    #1,%d3
        beq.s   .Lgk_part_refresh_post_part
        move.l  %a0,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_part_refresh_fatal_post_context
.Lgk_part_refresh_post_part:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_part_refresh_fatal_post_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w   gk_part_refresh_fatal_post_track
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   gk_part_refresh_fatal_post_track
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_UI_TRACK_SECONDARY,%d0
        move.l  %a6,%d1
        cmp.l   %d1,%d0
        bne.w   gk_part_refresh_fatal_post_track
        move.l  GK_STOCK_TRACK_MODE,%d0
        cmp.l   64(%sp),%d0
        bne.w   gk_part_refresh_fatal_post_mode
        btst    #0,%d3
        beq.s   .Lgk_part_refresh_restore
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_part_refresh_fatal_release
.Lgk_part_refresh_restore:
        move.l  44(%sp),%d0
        move.l  48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        move.w  60(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     68(%sp),%sp
        rts
        .size   gk_stock_part_refresh_writer,.-gk_stock_part_refresh_writer
        .global gk_stock_part_refresh_writer_trampoline
        .type   gk_stock_part_refresh_writer_trampoline,@function
gk_stock_part_refresh_writer_trampoline:
        .incbin "stock/0343.bin", 0, 4
        .incbin "stock/0343.bin", 4, 4
        .global gk_stock_part_refresh_writer_trampoline_jump
gk_stock_part_refresh_writer_trampoline_jump:
        jmp     GK_STOCK_PART_REFRESH_WRITER_CONTINUE
        .size   gk_stock_part_refresh_writer_trampoline,.-gk_stock_part_refresh_writer_trampoline
        .global gk_part_refresh_write_marker
        .type   gk_part_refresh_write_marker,@function
gk_part_refresh_write_marker:
        move.l  %d1,-(%sp)
        move.l  __gk_lifecycle_state,%d1
        beq.s   .Lgk_part_refresh_marker_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_part_refresh_fatal_lifecycle
        move.l  (%sp)+,%d1
        bra.s   gk_part_refresh_stock_dirty_store
.Lgk_part_refresh_marker_active:
        cmpi.l  #1,%d0
        bne.w   gk_part_refresh_fatal_marker
        cmpi.l  #1,%d6
        bne.w   gk_part_refresh_fatal_marker
        move.l  4(%sp),%d1
        cmpi.l  #GK_STOCK_PART_REFRESH_WRITER_DIRTY_RETURN,%d1
        bne.w   gk_part_refresh_fatal_marker
        moveq   #7,%d1
        cmp.l   %a3,%d1
        bcs.w   gk_part_refresh_fatal_marker
        moveq   #-128,%d1
        add.l   %a3,%d1
        cmp.l   %d2,%d1
        bne.w   gk_part_refresh_fatal_marker
        cmp.b   (%a1),%d2
        bne.w   gk_part_refresh_fatal_marker
        cmp.b   (%a0,%a5.l),%d2
        bne.w   gk_part_refresh_fatal_marker
        move.l  %d7,%d1
        andi.l  #GK_PART_REFRESH_TOKEN_STATE_MASK,%d1
        cmpi.l  #GK_PART_REFRESH_TOKEN_ARMED,%d1
        beq.s   .Lgk_part_refresh_mark_written
        cmpi.l  #GK_PART_REFRESH_TOKEN_WRITTEN,%d1
        bne.w   gk_part_refresh_fatal_marker
        bra.s   .Lgk_part_refresh_replay_dirty
.Lgk_part_refresh_mark_written:
        andi.l  #GK_PART_REFRESH_TOKEN_CONTEXT_MASK,%d7
        ori.l   #GK_PART_REFRESH_TOKEN_WRITTEN,%d7
.Lgk_part_refresh_replay_dirty:
        move.l  (%sp)+,%d1
        .global gk_part_refresh_stock_dirty_store
gk_part_refresh_stock_dirty_store:
        .incbin "stock/0344.bin", 0, 6
        rts
        .size   gk_part_refresh_write_marker,.-gk_part_refresh_write_marker
        .global gk_part_refresh_fatal_caller
        .type gk_part_refresh_fatal_caller,@function
gk_part_refresh_fatal_caller:
        illegal
        bra.s gk_part_refresh_fatal_caller
        .size gk_part_refresh_fatal_caller,.-gk_part_refresh_fatal_caller
        .global gk_part_refresh_fatal_marker
        .type gk_part_refresh_fatal_marker,@function
gk_part_refresh_fatal_marker:
        illegal
        bra.s gk_part_refresh_fatal_marker
        .size gk_part_refresh_fatal_marker,.-gk_part_refresh_fatal_marker
        .global gk_part_refresh_fatal_runtime
        .type gk_part_refresh_fatal_runtime,@function
gk_part_refresh_fatal_runtime:
        illegal
        bra.s gk_part_refresh_fatal_runtime
        .size gk_part_refresh_fatal_runtime,.-gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_lifecycle
        .set gk_part_refresh_fatal_lifecycle,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_track
        .set gk_part_refresh_fatal_track,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_engine_track
        .set gk_part_refresh_fatal_engine_track,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_part
        .set gk_part_refresh_fatal_part,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_context
        .set gk_part_refresh_fatal_context,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_descriptor
        .set gk_part_refresh_fatal_descriptor,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_workspace
        .set gk_part_refresh_fatal_workspace,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_cleanup
        .set gk_part_refresh_fatal_cleanup,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_token
        .set gk_part_refresh_fatal_token,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_release
        .set gk_part_refresh_fatal_release,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_abort
        .set gk_part_refresh_fatal_abort,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_mark_dirty
        .set gk_part_refresh_fatal_mark_dirty,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_commit
        .set gk_part_refresh_fatal_commit,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_post_context
        .set gk_part_refresh_fatal_post_context,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_post_part
        .set gk_part_refresh_fatal_post_part,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_post_track
        .set gk_part_refresh_fatal_post_track,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal_post_mode
        .set gk_part_refresh_fatal_post_mode,gk_part_refresh_fatal_runtime
        .global gk_part_refresh_fatal
        .set    gk_part_refresh_fatal,gk_part_refresh_fatal_runtime
