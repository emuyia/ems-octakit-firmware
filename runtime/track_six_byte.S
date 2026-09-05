        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_track_six_byte_abort_fatal,@function
gk_track_six_byte_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        bra.w   gk_track_six_byte_fatal
        .size   gk_track_six_byte_abort_fatal,.-gk_track_six_byte_abort_fatal
        .type   gk_track_six_byte_release_abort_fatal,@function
gk_track_six_byte_release_abort_fatal:
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        bra.w   gk_track_six_byte_abort_fatal
        .size   gk_track_six_byte_release_abort_fatal,.-gk_track_six_byte_release_abort_fatal
        .type   gk_track_six_byte_prepare,@function
gk_track_six_byte_prepare:
        cmpi.l  #7,%d0
        bhi.w   gk_track_six_byte_fatal
        movea.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_track_six_byte_fatal
        movea.l %d0,%a2
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_track_six_byte_prepare_busy
        tst.l   %d0
        bmi.w   gk_track_six_byte_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_track_six_byte_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_track_six_byte_prepare_busy
        tst.l   %d0
        bmi.w   gk_track_six_byte_fatal
        cmp.l   %d6,%d0
        bne.w   gk_track_six_byte_abort_fatal
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_track_six_byte_abort_fatal
        move.l  %a0,%d3
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_track_six_byte_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_track_six_byte_release_abort_fatal
        movea.l %d3,%a1
        cmpa.l  %a1,%a0
        bne.w   gk_track_six_byte_release_abort_fatal
        move.l  %d6,%d7
        move.l  %a3,%d0
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
        moveq   #GK_OK,%d0
        rts
.Lgk_track_six_byte_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_track_six_byte_prepare,.-gk_track_six_byte_prepare
        .type   gk_track_six_byte_post_validate,@function
gk_track_six_byte_post_validate:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_track_six_byte_fatal
        cmp.l   %d4,%d0
        bne.w   gk_track_six_byte_fatal
        cmp.l   %d5,%d1
        bne.w   gk_track_six_byte_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_track_six_byte_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a3,%d1
        cmp.l   %d1,%d0
        bne.w   gk_track_six_byte_fatal
        rts
        .size   gk_track_six_byte_post_validate,.-gk_track_six_byte_post_validate
        .type   gk_track_six_byte_single_finish,@function
gk_track_six_byte_single_finish:
        lea     -4(%sp),%sp
        move.w  %sr,%d1
        move.w  %d1,(%sp)
        andi.l  #0x0700,%d1
        cmpi.l  #0x0200,%d1
        bhs.s   .Lgk_track_six_byte_single_guarded
        move.w  #0x2200,%sr
.Lgk_track_six_byte_single_guarded:
        move.l  %d7,%d1
        cmp.l   %d1,%d0
        beq.s   .Lgk_track_six_byte_single_no_write
        andi.l  #GK_TRACK_SIX_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_TRACK_SIX_SINGLE_TOKEN_WRITTEN,%d1
        cmp.l   %d1,%d0
        bne.w   gk_track_six_byte_fatal
        moveq   #1,%d7
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        bra.s   .Lgk_track_six_byte_single_validate
.Lgk_track_six_byte_single_no_write:
        moveq   #0,%d7
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
.Lgk_track_six_byte_single_validate:
        bsr.w   gk_track_six_byte_post_validate
        tst.l   %d7
        beq.s   .Lgk_track_six_byte_single_return
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
.Lgk_track_six_byte_single_return:
        moveq   #0,%d0
        move.w  (%sp),%d0
        move.w  %d0,%sr
        lea     4(%sp),%sp
        rts
        .size   gk_track_six_byte_single_finish,.-gk_track_six_byte_single_finish
        .type   gk_track_six_byte_commit_finish,@function
gk_track_six_byte_commit_finish:
        lea     -4(%sp),%sp
        move.w  %sr,%d2
        move.w  %d2,(%sp)
        andi.l  #0x0700,%d2
        cmpi.l  #0x0200,%d2
        bhs.s   .Lgk_track_six_byte_commit_guarded
        move.w  #0x2200,%sr
.Lgk_track_six_byte_commit_guarded:
        cmpi.l  #6,%d1
        bne.w   gk_track_six_byte_fatal
        move.l  %d7,%d2
        andi.l  #GK_TRACK_SIX_TOKEN_CONTEXT_MASK,%d2
        ori.l   #GK_TRACK_SIX_COMMIT_TOKEN_WRITTEN,%d2
        cmp.l   %d2,%d0
        bne.w   gk_track_six_byte_fatal
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        bsr.w   gk_track_six_byte_post_validate
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        moveq   #0,%d0
        move.w  (%sp),%d0
        move.w  %d0,%sr
        lea     4(%sp),%sp
        rts
        .size   gk_track_six_byte_commit_finish,.-gk_track_six_byte_commit_finish
        .global gk_stock_track_six_byte_single
        .type   gk_stock_track_six_byte_single,@function
gk_stock_track_six_byte_single:
        move.l  4(%sp),%d0
        cmpi.l  #0x38,%d0
        blo.w   gk_track_six_byte_fatal
        cmpi.l  #0x3d,%d0
        bhi.w   gk_track_six_byte_fatal
        move.l  8(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_track_six_byte_single_event_negative
        tst.l   %d1
        bne.w   gk_track_six_byte_fatal
        bra.s   .Lgk_track_six_byte_single_event_ok
.Lgk_track_six_byte_single_event_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_track_six_byte_fatal
.Lgk_track_six_byte_single_event_ok:
        tst.l   %d0
        bne.w   .Lgk_track_six_byte_single_passthrough
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_track_six_byte_single_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_track_six_byte_busy_early
        bra.w   gk_track_six_byte_fatal
.Lgk_track_six_byte_single_lifecycle_active:
        .incbin "stock/0286.bin", 0, 4
        .incbin "stock/0286.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_track_six_byte_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_track_six_byte_busy_saved
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        ori.l   #GK_TRACK_SIX_SINGLE_TOKEN_ARMED,%d7
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_track_six_byte_single_stock_call
gk_track_six_byte_single_stock_call:
        jsr     GK_STOCK_TRACK_SIX_BYTE_SINGLE
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        bsr.w   gk_track_six_byte_single_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_track_six_byte_single_passthrough:
        jmp     GK_STOCK_TRACK_SIX_BYTE_SINGLE
        .size   gk_stock_track_six_byte_single,.-gk_stock_track_six_byte_single
        .global gk_stock_track_six_byte_commit
        .type   gk_stock_track_six_byte_commit,@function
gk_stock_track_six_byte_commit:
        move.l  4(%sp),%d0
        cmpi.l  #0x31,%d0
        bne.w   gk_track_six_byte_fatal
        move.l  8(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_track_six_byte_commit_event_negative
        tst.l   %d1
        bne.w   gk_track_six_byte_fatal
        bra.s   .Lgk_track_six_byte_commit_event_ok
.Lgk_track_six_byte_commit_event_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_track_six_byte_fatal
.Lgk_track_six_byte_commit_event_ok:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_track_six_byte_commit_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_track_six_byte_busy_early
        bra.w   gk_track_six_byte_fatal
.Lgk_track_six_byte_commit_lifecycle_active:
        .incbin "stock/0287.bin", 0, 4
        .incbin "stock/0287.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_track_six_byte_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_track_six_byte_busy_saved
        tst.l   %d0
        bne.w   gk_track_six_byte_fatal
        ori.l   #GK_TRACK_SIX_COMMIT_TOKEN_ARMED,%d7
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        clr.l   -(%sp)
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_track_six_byte_commit_stock_call
gk_track_six_byte_commit_stock_call:
        jsr     GK_STOCK_TRACK_SIX_BYTE_COMMIT
        move.l  %d0,60(%sp)
        move.l  8(%sp),%d0
        move.l  12(%sp),%d1
        lea     16(%sp),%sp
        bsr.w   gk_track_six_byte_commit_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_track_six_byte_busy_saved:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
.Lgk_track_six_byte_busy_early:
        moveq   #0,%d0
        rts
        .size   gk_stock_track_six_byte_commit,.-gk_stock_track_six_byte_commit
        .global gk_track_six_byte_single_write_marker
        .type   gk_track_six_byte_single_write_marker,@function
gk_track_six_byte_single_write_marker:
        move.l  %d0,-(%sp)
        cmpi.l  #1,%d1
        bne.w   gk_track_six_byte_fatal
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_TRACK_SIX_BYTE_SINGLE_DIRTY_RETURN,%d0
        bne.w   gk_track_six_byte_fatal
        move.l  %a3,%d0
        cmpi.l  #5,%d0
        bhi.w   gk_track_six_byte_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_TRACK_SIX_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_TRACK_SIX_SINGLE_TOKEN_ARMED,%d0
        bne.w   gk_track_six_byte_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_TRACK_SIX_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_TRACK_SIX_SINGLE_TOKEN_WRITTEN,%d0
        move.l  %d0,40(%sp)
        move.l  (%sp)+,%d0
        .global gk_track_six_byte_single_stock_dirty_store
gk_track_six_byte_single_stock_dirty_store:
        .incbin "stock/0288.bin", 0, 6
        rts
        .size   gk_track_six_byte_single_write_marker,.-gk_track_six_byte_single_write_marker
        .global gk_track_six_byte_commit_write_marker
        .type   gk_track_six_byte_commit_write_marker,@function
gk_track_six_byte_commit_write_marker:
        move.l  %d1,-(%sp)
        cmpi.l  #1,%d0
        bne.w   gk_track_six_byte_fatal
        move.l  4(%sp),%d1
        cmpi.l  #GK_STOCK_TRACK_SIX_BYTE_COMMIT_DIRTY_RETURN,%d1
        bne.w   gk_track_six_byte_fatal
        move.l  68(%sp),%d1
        cmpi.l  #5,%d1
        bhi.w   gk_track_six_byte_fatal
        cmp.l   %a3,%d1
        bne.w   gk_track_six_byte_fatal
        tst.l   %d1
        beq.s   .Lgk_track_six_byte_commit_first_marker
        move.l  64(%sp),%d1
        andi.l  #GK_TRACK_SIX_TOKEN_STATE_MASK,%d1
        cmpi.l  #GK_TRACK_SIX_COMMIT_TOKEN_WRITTEN,%d1
        bne.w   gk_track_six_byte_fatal
        bra.s   .Lgk_track_six_byte_commit_marker_state_ok
.Lgk_track_six_byte_commit_first_marker:
        move.l  64(%sp),%d1
        andi.l  #GK_TRACK_SIX_TOKEN_STATE_MASK,%d1
        cmpi.l  #GK_TRACK_SIX_COMMIT_TOKEN_ARMED,%d1
        bne.w   gk_track_six_byte_fatal
.Lgk_track_six_byte_commit_marker_state_ok:
        move.l  64(%sp),%d1
        andi.l  #GK_TRACK_SIX_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_TRACK_SIX_COMMIT_TOKEN_WRITTEN,%d1
        move.l  %d1,64(%sp)
        addq.l  #1,68(%sp)
        move.l  (%sp)+,%d1
        .global gk_track_six_byte_commit_stock_dirty_store
gk_track_six_byte_commit_stock_dirty_store:
        .incbin "stock/0289.bin", 0, 6
        rts
        .size   gk_track_six_byte_commit_write_marker,.-gk_track_six_byte_commit_write_marker
        .global gk_track_six_byte_fatal
gk_track_six_byte_fatal:
        illegal
        bra.s   gk_track_six_byte_fatal
