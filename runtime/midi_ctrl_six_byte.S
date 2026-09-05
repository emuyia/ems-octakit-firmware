        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_midi_ctrl_abort_fatal,@function
gk_midi_ctrl_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        bra.w   gk_midi_ctrl_fatal
        .size   gk_midi_ctrl_abort_fatal,.-gk_midi_ctrl_abort_fatal
        .type   gk_midi_ctrl_release_abort_fatal,@function
gk_midi_ctrl_release_abort_fatal:
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        bra.w   gk_midi_ctrl_abort_fatal
        .size   gk_midi_ctrl_release_abort_fatal,.-gk_midi_ctrl_release_abort_fatal
        .type   gk_midi_ctrl_prepare,@function
gk_midi_ctrl_prepare:
        cmpi.l  #7,%d0
        bhi.w   gk_midi_ctrl_fatal
        movea.l %d0,%a3
        moveq   #0,%d1
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d1
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_midi_ctrl_fatal
        movea.l %d0,%a2
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_midi_ctrl_prepare_busy
        tst.l   %d0
        bmi.w   gk_midi_ctrl_fatal
        moveq   #0,%d2
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d2
        move.l  %a3,%d3
        cmp.l   %d3,%d2
        bne.w   gk_midi_ctrl_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_midi_ctrl_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_midi_ctrl_prepare_busy
        tst.l   %d0
        bmi.w   gk_midi_ctrl_fatal
        cmp.l   %d6,%d0
        bne.w   gk_midi_ctrl_abort_fatal
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_midi_ctrl_abort_fatal
        move.l  %a0,%d3
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_midi_ctrl_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_midi_ctrl_release_abort_fatal
        movea.l %d3,%a1
        cmpa.l  %a1,%a0
        bne.w   gk_midi_ctrl_release_abort_fatal
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
.Lgk_midi_ctrl_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_midi_ctrl_prepare,.-gk_midi_ctrl_prepare
        .type   gk_midi_ctrl_post_validate,@function
gk_midi_ctrl_post_validate:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_midi_ctrl_fatal
        cmp.l   %d4,%d0
        bne.w   gk_midi_ctrl_fatal
        cmp.l   %d5,%d1
        bne.w   gk_midi_ctrl_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_midi_ctrl_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a3,%d1
        cmp.l   %d1,%d0
        bne.w   gk_midi_ctrl_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_UI_TRACK,%d0
        cmp.l   %d1,%d0
        bne.w   gk_midi_ctrl_fatal
        rts
        .size   gk_midi_ctrl_post_validate,.-gk_midi_ctrl_post_validate
        .type   gk_midi_ctrl_commit_dirty,@function
gk_midi_ctrl_commit_dirty:
        lea     -4(%sp),%sp
        move.w  %sr,%d0
        move.w  %d0,(%sp)
        andi.l  #0x0700,%d0
        cmpi.l  #0x0200,%d0
        bhs.s   .Lgk_midi_ctrl_commit_guarded
        move.w  #0x2200,%sr
.Lgk_midi_ctrl_commit_guarded:
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        bsr.w   gk_midi_ctrl_post_validate
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        moveq   #0,%d0
        move.w  (%sp),%d0
        move.w  %d0,%sr
        lea     4(%sp),%sp
        rts
        .size   gk_midi_ctrl_commit_dirty,.-gk_midi_ctrl_commit_dirty
        .type   gk_midi_ctrl_written_finish,@function
gk_midi_ctrl_written_finish:
        move.l  %d7,%d1
        andi.l  #GK_MIDI_CTRL_TOKEN_CONTEXT_MASK,%d1
        or.l    %d2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_midi_ctrl_fatal
        bra.w   gk_midi_ctrl_commit_dirty
        .size   gk_midi_ctrl_written_finish,.-gk_midi_ctrl_written_finish
        .type   gk_midi_ctrl_gated_finish,@function
gk_midi_ctrl_gated_finish:
        cmp.l   %d7,%d0
        bne.s   .Lgk_midi_ctrl_gated_written
        lea     -4(%sp),%sp
        move.w  %sr,%d0
        move.w  %d0,(%sp)
        andi.l  #0x0700,%d0
        cmpi.l  #0x0200,%d0
        bhs.s   .Lgk_midi_ctrl_gated_guarded
        move.w  #0x2200,%sr
.Lgk_midi_ctrl_gated_guarded:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        bsr.w   gk_midi_ctrl_post_validate
        moveq   #0,%d0
        move.w  (%sp),%d0
        move.w  %d0,%sr
        lea     4(%sp),%sp
        rts
.Lgk_midi_ctrl_gated_written:
        bra.w   gk_midi_ctrl_written_finish
        .size   gk_midi_ctrl_gated_finish,.-gk_midi_ctrl_gated_finish
        .type   gk_midi_ctrl_commit_finish,@function
gk_midi_ctrl_commit_finish:
        cmpi.l  #6,%d1
        bne.w   gk_midi_ctrl_fatal
        bra.w   gk_midi_ctrl_written_finish
        .size   gk_midi_ctrl_commit_finish,.-gk_midi_ctrl_commit_finish
        .type   gk_midi_ctrl_event_validate,@function
gk_midi_ctrl_event_validate:
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_midi_ctrl_event_negative
        tst.l   %d1
        bne.w   gk_midi_ctrl_fatal
        rts
.Lgk_midi_ctrl_event_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_midi_ctrl_fatal
        rts
        .size   gk_midi_ctrl_event_validate,.-gk_midi_ctrl_event_validate
        .global gk_stock_midi_ctrl2_single
        .type   gk_stock_midi_ctrl2_single,@function
gk_stock_midi_ctrl2_single:
        move.l  4(%sp),%d0
        cmpi.l  #0x38,%d0
        blo.w   gk_midi_ctrl_fatal
        cmpi.l  #0x3d,%d0
        bhi.w   gk_midi_ctrl_fatal
        move.l  8(%sp),%d0
        bsr.w   gk_midi_ctrl_event_validate
        tst.l   %d0
        bne.w   .Lgk_midi_ctrl2_single_passthrough
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_midi_ctrl2_single_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   gk_midi_ctrl_busy_early
        bra.w   gk_midi_ctrl_fatal
.Lgk_midi_ctrl2_single_lifecycle_active:
        .incbin "stock/0251.bin", 0, 4
        .incbin "stock/0251.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_midi_ctrl_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   gk_midi_ctrl_busy_saved
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        ori.l   #GK_MIDI_CTRL2_SINGLE_TOKEN_ARMED,%d7
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_midi_ctrl2_single_stock_call
gk_midi_ctrl2_single_stock_call:
        jsr     GK_STOCK_MIDI_CTRL2_SINGLE
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        move.l  #GK_MIDI_CTRL2_SINGLE_TOKEN_WRITTEN,%d2
        bsr.w   gk_midi_ctrl_gated_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_midi_ctrl2_single_passthrough:
        jmp     GK_STOCK_MIDI_CTRL2_SINGLE
        .size   gk_stock_midi_ctrl2_single,.-gk_stock_midi_ctrl2_single
        .global gk_stock_midi_ctrl2_direct
        .type   gk_stock_midi_ctrl2_direct,@function
gk_stock_midi_ctrl2_direct:
        move.l  4(%sp),%d0
        subq.l  #4,%d0
        cmpi.l  #5,%d0
        bhi.w   .Lgk_midi_ctrl2_direct_passthrough
        move.l  8(%sp),%d0
        cmpi.l  #127,%d0
        bhi.w   .Lgk_midi_ctrl2_direct_passthrough
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_midi_ctrl2_direct_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   gk_midi_ctrl_busy_early
        bra.w   gk_midi_ctrl_fatal
.Lgk_midi_ctrl2_direct_lifecycle_active:
        .incbin "stock/0252.bin", 0, 4
        .incbin "stock/0252.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_midi_ctrl_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   gk_midi_ctrl_busy_saved
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        ori.l   #GK_MIDI_CTRL2_DIRECT_TOKEN_ARMED,%d7
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_midi_ctrl2_direct_stock_call
gk_midi_ctrl2_direct_stock_call:
        .incbin "stock/0253.bin", 0, 6
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        move.l  #GK_MIDI_CTRL2_DIRECT_TOKEN_WRITTEN,%d2
        bsr.w   gk_midi_ctrl_written_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_midi_ctrl2_direct_passthrough:
        jmp     GK_STOCK_MIDI_CTRL2_DIRECT
        .size   gk_stock_midi_ctrl2_direct,.-gk_stock_midi_ctrl2_direct
        .global gk_stock_midi_ctrl2_commit
        .type   gk_stock_midi_ctrl2_commit,@function
gk_stock_midi_ctrl2_commit:
        move.l  4(%sp),%d0
        cmpi.l  #0x31,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  8(%sp),%d0
        bsr.w   gk_midi_ctrl_event_validate
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_midi_ctrl2_commit_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   gk_midi_ctrl_busy_early
        bra.w   gk_midi_ctrl_fatal
.Lgk_midi_ctrl2_commit_lifecycle_active:
        .incbin "stock/0254.bin", 0, 4
        .incbin "stock/0254.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_midi_ctrl_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   gk_midi_ctrl_busy_saved
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        ori.l   #GK_MIDI_CTRL2_COMMIT_TOKEN_ARMED,%d7
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        clr.l   -(%sp)
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_midi_ctrl2_commit_stock_call
gk_midi_ctrl2_commit_stock_call:
        jsr     GK_STOCK_MIDI_CTRL2_COMMIT
        move.l  %d0,60(%sp)
        move.l  8(%sp),%d0
        move.l  12(%sp),%d1
        lea     16(%sp),%sp
        move.l  #GK_MIDI_CTRL2_COMMIT_TOKEN_WRITTEN,%d2
        bsr.w   gk_midi_ctrl_commit_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
        .size   gk_stock_midi_ctrl2_commit,.-gk_stock_midi_ctrl2_commit
        .global gk_stock_midi_ctrl1_single
        .type   gk_stock_midi_ctrl1_single,@function
gk_stock_midi_ctrl1_single:
        move.l  4(%sp),%d0
        cmpi.l  #0x38,%d0
        blo.w   gk_midi_ctrl_fatal
        cmpi.l  #0x3d,%d0
        bhi.w   gk_midi_ctrl_fatal
        move.l  8(%sp),%d0
        bsr.w   gk_midi_ctrl_event_validate
        tst.l   %d0
        bne.w   .Lgk_midi_ctrl1_single_passthrough
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_midi_ctrl1_single_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   gk_midi_ctrl_busy_early
        bra.w   gk_midi_ctrl_fatal
.Lgk_midi_ctrl1_single_lifecycle_active:
        .incbin "stock/0255.bin", 0, 4
        .incbin "stock/0255.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_midi_ctrl_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   gk_midi_ctrl_busy_saved
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        ori.l   #GK_MIDI_CTRL1_SINGLE_TOKEN_ARMED,%d7
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_midi_ctrl1_single_stock_call
gk_midi_ctrl1_single_stock_call:
        jsr     GK_STOCK_MIDI_CTRL1_SINGLE
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        move.l  #GK_MIDI_CTRL1_SINGLE_TOKEN_WRITTEN,%d2
        bsr.w   gk_midi_ctrl_gated_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_midi_ctrl1_single_passthrough:
        jmp     GK_STOCK_MIDI_CTRL1_SINGLE
        .size   gk_stock_midi_ctrl1_single,.-gk_stock_midi_ctrl1_single
        .global gk_stock_midi_ctrl1_direct
        .type   gk_stock_midi_ctrl1_direct,@function
gk_stock_midi_ctrl1_direct:
        move.l  4(%sp),%d0
        cmpi.l  #3,%d0
        bhi.w   .Lgk_midi_ctrl1_direct_passthrough
        move.l  8(%sp),%d0
        cmpi.l  #127,%d0
        bhi.w   .Lgk_midi_ctrl1_direct_passthrough
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_midi_ctrl1_direct_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   gk_midi_ctrl_busy_early
        bra.w   gk_midi_ctrl_fatal
.Lgk_midi_ctrl1_direct_lifecycle_active:
        .incbin "stock/0256.bin", 0, 4
        .incbin "stock/0256.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_midi_ctrl_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   gk_midi_ctrl_busy_saved
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        ori.l   #GK_MIDI_CTRL1_DIRECT_TOKEN_ARMED,%d7
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_midi_ctrl1_direct_stock_call
gk_midi_ctrl1_direct_stock_call:
        .incbin "stock/0257.bin", 0, 6
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        move.l  #GK_MIDI_CTRL1_DIRECT_TOKEN_WRITTEN,%d2
        bsr.w   gk_midi_ctrl_written_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_midi_ctrl1_direct_passthrough:
        jmp     GK_STOCK_MIDI_CTRL1_DIRECT
        .size   gk_stock_midi_ctrl1_direct,.-gk_stock_midi_ctrl1_direct
        .global gk_stock_midi_ctrl1_commit
        .type   gk_stock_midi_ctrl1_commit,@function
gk_stock_midi_ctrl1_commit:
        move.l  4(%sp),%d0
        cmpi.l  #0x31,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  8(%sp),%d0
        bsr.w   gk_midi_ctrl_event_validate
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_midi_ctrl1_commit_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   gk_midi_ctrl_busy_early
        bra.w   gk_midi_ctrl_fatal
.Lgk_midi_ctrl1_commit_lifecycle_active:
        .incbin "stock/0258.bin", 0, 4
        .incbin "stock/0258.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_midi_ctrl_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   gk_midi_ctrl_busy_saved
        tst.l   %d0
        bne.w   gk_midi_ctrl_fatal
        ori.l   #GK_MIDI_CTRL1_COMMIT_TOKEN_ARMED,%d7
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        clr.l   -(%sp)
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_midi_ctrl1_commit_stock_call
gk_midi_ctrl1_commit_stock_call:
        jsr     GK_STOCK_MIDI_CTRL1_COMMIT
        move.l  %d0,60(%sp)
        move.l  8(%sp),%d0
        move.l  12(%sp),%d1
        lea     16(%sp),%sp
        move.l  #GK_MIDI_CTRL1_COMMIT_TOKEN_WRITTEN,%d2
        bsr.w   gk_midi_ctrl_commit_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
        .size   gk_stock_midi_ctrl1_commit,.-gk_stock_midi_ctrl1_commit
        .type   gk_midi_ctrl_busy_saved,@function
gk_midi_ctrl_busy_saved:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
gk_midi_ctrl_busy_early:
        moveq   #0,%d0
        rts
        .size   gk_midi_ctrl_busy_saved,.-gk_midi_ctrl_busy_saved
        .global gk_midi_ctrl2_single_write_marker
        .type   gk_midi_ctrl2_single_write_marker,@function
gk_midi_ctrl2_single_write_marker:
        move.l  %d0,-(%sp)
        cmpi.l  #1,%d1
        bne.w   gk_midi_ctrl_fatal
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_MIDI_CTRL2_SINGLE_DIRTY_RETURN,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  %a3,%d0
        cmpi.l  #5,%d0
        bhi.w   gk_midi_ctrl_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_MIDI_CTRL_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_MIDI_CTRL2_SINGLE_TOKEN_ARMED,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_MIDI_CTRL_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_MIDI_CTRL2_SINGLE_TOKEN_WRITTEN,%d0
        move.l  %d0,40(%sp)
        move.l  (%sp)+,%d0
        .global gk_midi_ctrl2_single_stock_dirty_store
gk_midi_ctrl2_single_stock_dirty_store:
        .incbin "stock/0259.bin", 0, 6
        rts
        .size   gk_midi_ctrl2_single_write_marker,.-gk_midi_ctrl2_single_write_marker
        .global gk_midi_ctrl2_direct_write_marker
        .type   gk_midi_ctrl2_direct_write_marker,@function
gk_midi_ctrl2_direct_write_marker:
        move.l  %d0,-(%sp)
        cmpi.l  #1,%d1
        bne.w   gk_midi_ctrl_fatal
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_MIDI_CTRL2_DIRECT_DIRTY_RETURN,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  %a4,%d0
        cmpi.l  #5,%d0
        bhi.w   gk_midi_ctrl_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_MIDI_CTRL_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_MIDI_CTRL2_DIRECT_TOKEN_ARMED,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_MIDI_CTRL_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_MIDI_CTRL2_DIRECT_TOKEN_WRITTEN,%d0
        move.l  %d0,40(%sp)
        move.l  (%sp)+,%d0
        .global gk_midi_ctrl2_direct_stock_dirty_store
gk_midi_ctrl2_direct_stock_dirty_store:
        .incbin "stock/0260.bin", 0, 6
        rts
        .size   gk_midi_ctrl2_direct_write_marker,.-gk_midi_ctrl2_direct_write_marker
        .global gk_midi_ctrl1_single_write_marker
        .type   gk_midi_ctrl1_single_write_marker,@function
gk_midi_ctrl1_single_write_marker:
        move.l  %d0,-(%sp)
        cmpi.l  #1,%d1
        bne.w   gk_midi_ctrl_fatal
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_MIDI_CTRL1_SINGLE_DIRTY_RETURN,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  %a3,%d0
        cmpi.l  #5,%d0
        bhi.w   gk_midi_ctrl_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_MIDI_CTRL_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_MIDI_CTRL1_SINGLE_TOKEN_ARMED,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_MIDI_CTRL_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_MIDI_CTRL1_SINGLE_TOKEN_WRITTEN,%d0
        move.l  %d0,40(%sp)
        move.l  (%sp)+,%d0
        .global gk_midi_ctrl1_single_stock_dirty_store
gk_midi_ctrl1_single_stock_dirty_store:
        .incbin "stock/0261.bin", 0, 6
        rts
        .size   gk_midi_ctrl1_single_write_marker,.-gk_midi_ctrl1_single_write_marker
        .global gk_midi_ctrl1_direct_write_marker
        .type   gk_midi_ctrl1_direct_write_marker,@function
gk_midi_ctrl1_direct_write_marker:
        move.l  %d0,-(%sp)
        cmpi.l  #1,%d1
        bne.w   gk_midi_ctrl_fatal
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_MIDI_CTRL1_DIRECT_DIRTY_RETURN,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  %a3,%d0
        cmpi.l  #2,%d0
        blo.w   gk_midi_ctrl_fatal
        cmpi.l  #5,%d0
        bhi.w   gk_midi_ctrl_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_MIDI_CTRL_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_MIDI_CTRL1_DIRECT_TOKEN_ARMED,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  40(%sp),%d0
        andi.l  #GK_MIDI_CTRL_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_MIDI_CTRL1_DIRECT_TOKEN_WRITTEN,%d0
        move.l  %d0,40(%sp)
        move.l  (%sp)+,%d0
        .global gk_midi_ctrl1_direct_stock_dirty_store
gk_midi_ctrl1_direct_stock_dirty_store:
        .incbin "stock/0262.bin", 0, 6
        rts
        .size   gk_midi_ctrl1_direct_write_marker,.-gk_midi_ctrl1_direct_write_marker
        .global gk_midi_ctrl2_commit_write_marker
        .type   gk_midi_ctrl2_commit_write_marker,@function
gk_midi_ctrl2_commit_write_marker:
        move.l  %d1,-(%sp)
        cmpi.l  #1,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  4(%sp),%d1
        cmpi.l  #GK_STOCK_MIDI_CTRL2_COMMIT_DIRTY_RETURN,%d1
        bne.w   gk_midi_ctrl_fatal
        move.l  64(%sp),%d1
        cmpi.l  #5,%d1
        bhi.w   gk_midi_ctrl_fatal
        cmp.l   %a3,%d1
        bne.w   gk_midi_ctrl_fatal
        tst.l   %d1
        beq.s   .Lgk_midi_ctrl2_commit_first
        move.l  60(%sp),%d1
        andi.l  #GK_MIDI_CTRL_TOKEN_STATE_MASK,%d1
        cmpi.l  #GK_MIDI_CTRL2_COMMIT_TOKEN_WRITTEN,%d1
        bne.w   gk_midi_ctrl_fatal
        bra.s   .Lgk_midi_ctrl2_commit_state_ok
.Lgk_midi_ctrl2_commit_first:
        move.l  60(%sp),%d1
        andi.l  #GK_MIDI_CTRL_TOKEN_STATE_MASK,%d1
        cmpi.l  #GK_MIDI_CTRL2_COMMIT_TOKEN_ARMED,%d1
        bne.w   gk_midi_ctrl_fatal
.Lgk_midi_ctrl2_commit_state_ok:
        move.l  60(%sp),%d1
        andi.l  #GK_MIDI_CTRL_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_MIDI_CTRL2_COMMIT_TOKEN_WRITTEN,%d1
        move.l  %d1,60(%sp)
        addq.l  #1,64(%sp)
        move.l  (%sp)+,%d1
        .global gk_midi_ctrl2_commit_stock_dirty_store
gk_midi_ctrl2_commit_stock_dirty_store:
        .incbin "stock/0263.bin", 0, 6
        rts
        .size   gk_midi_ctrl2_commit_write_marker,.-gk_midi_ctrl2_commit_write_marker
        .global gk_midi_ctrl1_commit_write_marker
        .type   gk_midi_ctrl1_commit_write_marker,@function
gk_midi_ctrl1_commit_write_marker:
        move.l  %d1,-(%sp)
        cmpi.l  #1,%d0
        bne.w   gk_midi_ctrl_fatal
        move.l  4(%sp),%d1
        cmpi.l  #GK_STOCK_MIDI_CTRL1_COMMIT_DIRTY_RETURN,%d1
        bne.w   gk_midi_ctrl_fatal
        move.l  64(%sp),%d1
        cmpi.l  #5,%d1
        bhi.w   gk_midi_ctrl_fatal
        cmp.l   %a3,%d1
        bne.w   gk_midi_ctrl_fatal
        tst.l   %d1
        beq.s   .Lgk_midi_ctrl1_commit_first
        move.l  60(%sp),%d1
        andi.l  #GK_MIDI_CTRL_TOKEN_STATE_MASK,%d1
        cmpi.l  #GK_MIDI_CTRL1_COMMIT_TOKEN_WRITTEN,%d1
        bne.w   gk_midi_ctrl_fatal
        bra.s   .Lgk_midi_ctrl1_commit_state_ok
.Lgk_midi_ctrl1_commit_first:
        move.l  60(%sp),%d1
        andi.l  #GK_MIDI_CTRL_TOKEN_STATE_MASK,%d1
        cmpi.l  #GK_MIDI_CTRL1_COMMIT_TOKEN_ARMED,%d1
        bne.w   gk_midi_ctrl_fatal
.Lgk_midi_ctrl1_commit_state_ok:
        move.l  60(%sp),%d1
        andi.l  #GK_MIDI_CTRL_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_MIDI_CTRL1_COMMIT_TOKEN_WRITTEN,%d1
        move.l  %d1,60(%sp)
        addq.l  #1,64(%sp)
        move.l  (%sp)+,%d1
        .global gk_midi_ctrl1_commit_stock_dirty_store
gk_midi_ctrl1_commit_stock_dirty_store:
        .incbin "stock/0264.bin", 0, 6
        rts
        .size   gk_midi_ctrl1_commit_write_marker,.-gk_midi_ctrl1_commit_write_marker
        .global gk_midi_ctrl_fatal
gk_midi_ctrl_fatal:
        illegal
        bra.s   gk_midi_ctrl_fatal
