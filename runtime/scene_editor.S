        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_scene_editor_abort_fatal,@function
gk_scene_editor_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_scene_editor_fatal
        bra.w   gk_scene_editor_fatal
        .size   gk_scene_editor_abort_fatal,.-gk_scene_editor_abort_fatal
        .type   gk_scene_editor_release_abort_fatal,@function
gk_scene_editor_release_abort_fatal:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_editor_fatal
        bra.w   gk_scene_editor_abort_fatal
        .size   gk_scene_editor_release_abort_fatal,.-gk_scene_editor_release_abort_fatal
        .type   gk_scene_editor_prepare,@function
gk_scene_editor_prepare:
        cmpi.l  #1,%d0
        bhi.w   gk_scene_editor_fatal
        movea.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_scene_editor_fatal
        movea.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_scene_editor_fatal
        movea.l %d0,%a5
        move.l  GK_STOCK_SCENE_EDITOR_MODE,%d0
        cmpi.l  #4,%d0
        bhi.w   gk_scene_editor_fatal
        movea.l %d0,%a6
        move.l  %a5,%d0
        .incbin "stock/0265.bin", 0, 6
        .incbin "stock/0265.bin", 6, 4
        .incbin "stock/0265.bin", 10, 6
        .incbin "stock/0265.bin", 16, 2
        .incbin "stock/0265.bin", 18, 6
        adda.l  %a2,%a0
        moveq   #0,%d3
        move.b  (%a0),%d3
        cmpi.l  #15,%d3
        bhi.w   gk_scene_editor_fatal
        move.l  %d3,%d0
        lsl.l   #8,%d0
        add.l   %a2,%d0
        movea.l %d0,%a2
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_scene_editor_prepare_busy
        tst.l   %d0
        bmi.w   gk_scene_editor_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_scene_editor_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_scene_editor_prepare_busy
        tst.l   %d0
        bmi.w   gk_scene_editor_fatal
        cmp.l   %d6,%d0
        bne.w   gk_scene_editor_abort_fatal
        move.l  %a5,%d2
        cmp.l   %d2,%d1
        bne.w   gk_scene_editor_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %a5,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_scene_editor_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_scene_editor_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_scene_editor_release_abort_fatal
        move.l  %d6,%d7
        move.l  %a4,%d0
        lsl.l   #7,%d0
        or.l    %d0,%d7
        move.l  %a5,%d0
        lsl.l   #8,%d0
        lsl.l   #2,%d0
        or.l    %d0,%d7
        move.l  %d4,%d0
        lsl.l   #8,%d0
        lsl.l   #4,%d0
        or.l    %d0,%d7
        ori.l   #GK_SCENE_EDITOR_TOKEN_ARMED,%d7
        moveq   #GK_OK,%d0
        rts
.Lgk_scene_editor_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_scene_editor_prepare,.-gk_scene_editor_prepare
        .type   gk_scene_editor_finish,@function
gk_scene_editor_finish:
        lea     -4(%sp),%sp
        move.w  %sr,%d1
        move.w  %d1,(%sp)
        andi.l  #0x0700,%d1
        cmpi.l  #0x0200,%d1
        bhs.s   .Lgk_scene_editor_finish_guarded
        move.w  #0x2200,%sr
.Lgk_scene_editor_finish_guarded:
        move.l  %d7,%d1
        cmp.l   %d1,%d0
        beq.s   .Lgk_scene_editor_no_write
        andi.l  #GK_SCENE_EDITOR_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_SCENE_EDITOR_TOKEN_WRITTEN,%d1
        cmp.l   %d1,%d0
        bne.w   gk_scene_editor_fatal
        moveq   #1,%d7
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a5,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_scene_editor_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_scene_editor_fatal
        bra.s   .Lgk_scene_editor_post_validate
.Lgk_scene_editor_no_write:
        moveq   #0,%d7
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_editor_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_scene_editor_fatal
.Lgk_scene_editor_post_validate:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_scene_editor_fatal
        cmp.l   %d4,%d0
        bne.w   gk_scene_editor_fatal
        cmp.l   %d5,%d1
        bne.w   gk_scene_editor_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   gk_scene_editor_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w   gk_scene_editor_fatal
        move.l  GK_STOCK_SCENE_EDITOR_MODE,%d0
        move.l  %a6,%d1
        cmp.l   %d1,%d0
        bne.w   gk_scene_editor_fatal
        move.l  %a5,%d0
        .incbin "stock/0266.bin", 0, 6
        .incbin "stock/0266.bin", 6, 4
        .incbin "stock/0266.bin", 10, 6
        .incbin "stock/0266.bin", 16, 2
        .incbin "stock/0266.bin", 18, 6
        move.l  %a2,%d1
        andi.l  #0xff,%d1
        adda.l  %d1,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  %a2,%d1
        lsr.l   #8,%d1
        andi.l  #0xff,%d1
        cmp.l   %d1,%d0
        bne.w   gk_scene_editor_fatal
        tst.l   %d7
        beq.s   .Lgk_scene_editor_finish_return
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_editor_fatal
.Lgk_scene_editor_finish_return:
        moveq   #0,%d0
        move.w  (%sp),%d0
        move.w  %d0,%sr
        lea     4(%sp),%sp
        rts
        .size   gk_scene_editor_finish,.-gk_scene_editor_finish
        .global gk_stock_scene_b_encoder
        .type gk_stock_scene_b_encoder,@function
gk_stock_scene_b_encoder:
        move.l __gk_lifecycle_state,%d0
        tst.l %d0
        beq.s .Lgk_scene_editor_lifecycle_active0
        cmpi.l #GK_LIFECYCLE_QUIESCED,%d0
        beq.w .Lgk_scene_editor_busy_early0
        bra.w gk_scene_editor_fatal
.Lgk_scene_editor_lifecycle_active0:
        .incbin "stock/0267.bin", 0, 4
        .incbin "stock/0267.bin", 4, 4
        move.l 48(%sp),%d0
        cmpi.l #0,%d0
        blo.w gk_scene_editor_fatal
        cmpi.l #6,%d0
        bhi.w gk_scene_editor_fatal
        moveq #1,%d0
        bsr.w gk_scene_editor_prepare
        cmpi.l #GK_ERR_BUSY,%d0
        beq.w .Lgk_scene_editor_busy_saved0
        tst.l %d0
        bne.w gk_scene_editor_fatal
        move.l 48(%sp),%d0
        move.l 52(%sp),%d1
        move.l %d7,-(%sp)
        move.l %d1,-(%sp)
        move.l %d0,-(%sp)
        .global gk_scene_b_encoder_stock_call
gk_scene_b_encoder_stock_call:
        jsr GK_STOCK_SCENE_B_ENCODER
        move.l 8(%sp),%d0
        lea 12(%sp),%sp
        bsr.w gk_scene_editor_finish
        .incbin "stock/0268.bin", 0, 4
        .incbin "stock/0268.bin", 4, 4
        .incbin "stock/0268.bin", 8, 2
.Lgk_scene_editor_busy_saved0:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea 44(%sp),%sp
.Lgk_scene_editor_busy_early0:
        moveq #0,%d0
        rts
        .size gk_stock_scene_b_encoder,.-gk_stock_scene_b_encoder
        .global gk_stock_scene_a_encoder
        .type gk_stock_scene_a_encoder,@function
gk_stock_scene_a_encoder:
        move.l __gk_lifecycle_state,%d0
        tst.l %d0
        beq.s .Lgk_scene_editor_lifecycle_active1
        cmpi.l #GK_LIFECYCLE_QUIESCED,%d0
        beq.w .Lgk_scene_editor_busy_early1
        bra.w gk_scene_editor_fatal
.Lgk_scene_editor_lifecycle_active1:
        .incbin "stock/0269.bin", 0, 4
        .incbin "stock/0269.bin", 4, 4
        move.l 48(%sp),%d0
        cmpi.l #0,%d0
        blo.w gk_scene_editor_fatal
        cmpi.l #6,%d0
        bhi.w gk_scene_editor_fatal
        moveq #0,%d0
        bsr.w gk_scene_editor_prepare
        cmpi.l #GK_ERR_BUSY,%d0
        beq.w .Lgk_scene_editor_busy_saved1
        tst.l %d0
        bne.w gk_scene_editor_fatal
        move.l 48(%sp),%d0
        move.l 52(%sp),%d1
        move.l %d7,-(%sp)
        move.l %d1,-(%sp)
        move.l %d0,-(%sp)
        .global gk_scene_a_encoder_stock_call
gk_scene_a_encoder_stock_call:
        jsr GK_STOCK_SCENE_A_ENCODER
        move.l 8(%sp),%d0
        lea 12(%sp),%sp
        bsr.w gk_scene_editor_finish
        .incbin "stock/0270.bin", 0, 4
        .incbin "stock/0270.bin", 4, 4
        .incbin "stock/0270.bin", 8, 2
.Lgk_scene_editor_busy_saved1:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea 44(%sp),%sp
.Lgk_scene_editor_busy_early1:
        moveq #0,%d0
        rts
        .size gk_stock_scene_a_encoder,.-gk_stock_scene_a_encoder
        .global gk_stock_scene_b_button
        .type gk_stock_scene_b_button,@function
gk_stock_scene_b_button:
        move.l __gk_lifecycle_state,%d0
        tst.l %d0
        beq.s .Lgk_scene_editor_lifecycle_active2
        cmpi.l #GK_LIFECYCLE_QUIESCED,%d0
        beq.w .Lgk_scene_editor_busy_early2
        bra.w gk_scene_editor_fatal
.Lgk_scene_editor_lifecycle_active2:
        .incbin "stock/0271.bin", 0, 4
        .incbin "stock/0271.bin", 4, 4
        move.l 48(%sp),%d0
        cmpi.l #0x38,%d0
        blo.w gk_scene_editor_fatal
        cmpi.l #0x3e,%d0
        bhi.w gk_scene_editor_fatal
        moveq #1,%d0
        bsr.w gk_scene_editor_prepare
        cmpi.l #GK_ERR_BUSY,%d0
        beq.w .Lgk_scene_editor_busy_saved2
        tst.l %d0
        bne.w gk_scene_editor_fatal
        move.l 48(%sp),%d0
        move.l 52(%sp),%d1
        move.l %d7,-(%sp)
        move.l %d1,-(%sp)
        move.l %d0,-(%sp)
        .global gk_scene_b_button_stock_call
gk_scene_b_button_stock_call:
        jsr GK_STOCK_SCENE_B_BUTTON
        move.l 8(%sp),%d0
        lea 12(%sp),%sp
        bsr.w gk_scene_editor_finish
        .incbin "stock/0272.bin", 0, 4
        .incbin "stock/0272.bin", 4, 4
        .incbin "stock/0272.bin", 8, 2
.Lgk_scene_editor_busy_saved2:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea 44(%sp),%sp
.Lgk_scene_editor_busy_early2:
        moveq #0,%d0
        rts
        .size gk_stock_scene_b_button,.-gk_stock_scene_b_button
        .global gk_stock_scene_a_button
        .type gk_stock_scene_a_button,@function
gk_stock_scene_a_button:
        move.l __gk_lifecycle_state,%d0
        tst.l %d0
        beq.s .Lgk_scene_editor_lifecycle_active3
        cmpi.l #GK_LIFECYCLE_QUIESCED,%d0
        beq.w .Lgk_scene_editor_busy_early3
        bra.w gk_scene_editor_fatal
.Lgk_scene_editor_lifecycle_active3:
        .incbin "stock/0273.bin", 0, 4
        .incbin "stock/0273.bin", 4, 4
        move.l 48(%sp),%d0
        cmpi.l #0x38,%d0
        blo.w gk_scene_editor_fatal
        cmpi.l #0x3e,%d0
        bhi.w gk_scene_editor_fatal
        moveq #0,%d0
        bsr.w gk_scene_editor_prepare
        cmpi.l #GK_ERR_BUSY,%d0
        beq.w .Lgk_scene_editor_busy_saved3
        tst.l %d0
        bne.w gk_scene_editor_fatal
        move.l 48(%sp),%d0
        move.l 52(%sp),%d1
        move.l %d7,-(%sp)
        move.l %d1,-(%sp)
        move.l %d0,-(%sp)
        .global gk_scene_a_button_stock_call
gk_scene_a_button_stock_call:
        jsr GK_STOCK_SCENE_A_BUTTON
        move.l 8(%sp),%d0
        lea 12(%sp),%sp
        bsr.w gk_scene_editor_finish
        .incbin "stock/0274.bin", 0, 4
        .incbin "stock/0274.bin", 4, 4
        .incbin "stock/0274.bin", 8, 2
.Lgk_scene_editor_busy_saved3:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea 44(%sp),%sp
.Lgk_scene_editor_busy_early3:
        moveq #0,%d0
        rts
        .size gk_stock_scene_a_button,.-gk_stock_scene_a_button
        .global gk_scene_b_encoder_write_marker
        .type   gk_scene_b_encoder_write_marker,@function
gk_scene_b_encoder_write_marker:
        move.l  (%sp),%d0
        cmpi.l  #0x40052fd6,%d0
        beq.s   .Lgk_scene_b_encoder_marker_ok
        cmpi.l  #0x400530b6,%d0
        beq.s   .Lgk_scene_b_encoder_marker_ok
        cmpi.l  #0x400531e2,%d0
        beq.s   .Lgk_scene_b_encoder_marker_ok
        cmpi.l  #0x400533f6,%d0
        bne.w   gk_scene_editor_fatal
.Lgk_scene_b_encoder_marker_ok:
        moveq   #48,%d1
        bra.w   gk_scene_editor_mark_written
        .size   gk_scene_b_encoder_write_marker,.-gk_scene_b_encoder_write_marker
        .global gk_scene_a_encoder_write_marker
        .type   gk_scene_a_encoder_write_marker,@function
gk_scene_a_encoder_write_marker:
        move.l  (%sp),%d0
        cmpi.l  #0x400535ae,%d0
        beq.s   .Lgk_scene_a_encoder_marker_ok
        cmpi.l  #0x40053690,%d0
        beq.s   .Lgk_scene_a_encoder_marker_ok
        cmpi.l  #0x40053786,%d0
        beq.s   .Lgk_scene_a_encoder_marker_ok
        cmpi.l  #0x400539c6,%d0
        bne.w   gk_scene_editor_fatal
.Lgk_scene_a_encoder_marker_ok:
        moveq   #52,%d1
        bra.w   gk_scene_editor_mark_written
        .size   gk_scene_a_encoder_write_marker,.-gk_scene_a_encoder_write_marker
        .global gk_scene_b_button_write_marker
        .type   gk_scene_b_button_write_marker,@function
gk_scene_b_button_write_marker:
        move.l  (%sp),%d0
        cmpi.l  #0x40053bde,%d0
        beq.s   .Lgk_scene_b_button_marker_ok
        cmpi.l  #0x40053cf4,%d0
        beq.s   .Lgk_scene_b_button_marker_ok
        cmpi.l  #0x40053e2a,%d0
        beq.s   .Lgk_scene_b_button_marker_ok
        cmpi.l  #0x40054008,%d0
        beq.s   .Lgk_scene_b_button_marker_ok
        cmpi.l  #0x40054170,%d0
        beq.s   .Lgk_scene_b_button_marker_ok
        cmpi.l  #0x400542bc,%d0
        bne.w   gk_scene_editor_fatal
.Lgk_scene_b_button_marker_ok:
        moveq   #60,%d1
        bra.w   gk_scene_editor_mark_written
        .size   gk_scene_b_button_write_marker,.-gk_scene_b_button_write_marker
        .global gk_scene_a_button_write_marker
        .type   gk_scene_a_button_write_marker,@function
gk_scene_a_button_write_marker:
        move.l  (%sp),%d0
        cmpi.l  #0x400544d0,%d0
        beq.s   .Lgk_scene_a_button_marker_ok
        cmpi.l  #0x400545e8,%d0
        beq.s   .Lgk_scene_a_button_marker_ok
        cmpi.l  #0x40054720,%d0
        beq.s   .Lgk_scene_a_button_marker_ok
        cmpi.l  #0x40054906,%d0
        beq.s   .Lgk_scene_a_button_marker_ok
        cmpi.l  #0x40054a6e,%d0
        beq.s   .Lgk_scene_a_button_marker_ok
        cmpi.l  #0x40054bbc,%d0
        bne.w   gk_scene_editor_fatal
.Lgk_scene_a_button_marker_ok:
        moveq   #56,%d1
        bra.w   gk_scene_editor_mark_written
        .size   gk_scene_a_button_write_marker,.-gk_scene_a_button_write_marker
        .type   gk_scene_editor_mark_written,@function
gk_scene_editor_mark_written:
        move.l  (%sp,%d1.l),%d0
        move.l  %d0,%d1
        andi.l  #GK_SCENE_EDITOR_TOKEN_STATE_MASK,%d1
        cmpi.l  #GK_SCENE_EDITOR_TOKEN_ARMED,%d1
        beq.s   .Lgk_scene_editor_mark_now
        cmpi.l  #GK_SCENE_EDITOR_TOKEN_WRITTEN,%d1
        bne.w   gk_scene_editor_fatal
        bra.s   .Lgk_scene_editor_dirty_tail
.Lgk_scene_editor_mark_now:
        andi.l  #GK_SCENE_EDITOR_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_SCENE_EDITOR_TOKEN_WRITTEN,%d0
        move.l  (%sp),%d1
        cmpi.l  #0x40053400,%d1
        blo.s   .Lgk_scene_editor_mark_b_encoder
        cmpi.l  #0x40053a00,%d1
        blo.s   .Lgk_scene_editor_mark_a_encoder
        cmpi.l  #0x4005435c,%d1
        blo.s   .Lgk_scene_editor_mark_b_button
        moveq   #56,%d1
        bra.s   .Lgk_scene_editor_mark_store
.Lgk_scene_editor_mark_b_encoder:
        moveq   #48,%d1
        bra.s   .Lgk_scene_editor_mark_store
.Lgk_scene_editor_mark_a_encoder:
        moveq   #52,%d1
        bra.s   .Lgk_scene_editor_mark_store
.Lgk_scene_editor_mark_b_button:
        moveq   #60,%d1
.Lgk_scene_editor_mark_store:
        move.l  %d0,(%sp,%d1.l)
.Lgk_scene_editor_dirty_tail:
        .global gk_scene_editor_stock_dirty_jump
gk_scene_editor_stock_dirty_jump:
        jmp     GK_STOCK_SCENE_DIRTY_HELPER
        .size   gk_scene_editor_mark_written,.-gk_scene_editor_mark_written
        .type   gk_scene_editor_identity_match,@function
gk_scene_editor_identity_match:
        cmpi.l  #7,%d0
        bhi.w   gk_scene_editor_fatal
        move.l  %d1,%d2
        andi.l  #GK_SCENE_EDITOR_TOKEN_STATE_MASK,%d2
        cmpi.l  #GK_SCENE_EDITOR_TOKEN_WRITTEN,%d2
        bne.w   gk_scene_editor_fatal
        move.l  %d1,%d2
        lsr.l   #7,%d2
        andi.l  #7,%d2
        cmp.l   %d2,%d0
        bne.w   gk_scene_editor_fatal
        add.l   %d0,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d1,%d2
        lsr.l   #8,%d2
        lsr.l   #2,%d2
        andi.l  #3,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.w   gk_scene_editor_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.w   gk_scene_editor_fatal
        move.l  %d1,%d2
        lsr.l   #8,%d2
        lsr.l   #4,%d2
        andi.l  #15,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.w   gk_scene_editor_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.w   gk_scene_editor_fatal
        andi.l  #0x7f,%d1
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        .global gk_scene_editor_identity_snapshot
gk_scene_editor_identity_snapshot:
        move.w  (%a0),%d0
        move.w  %d2,%sr
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.l   %d1,%d0
        seq     %d0
        andi.l  #1,%d0
        rts
        .size   gk_scene_editor_identity_match,.-gk_scene_editor_identity_match
        .global gk_scene_b_encoder_track_compare
        .type gk_scene_b_encoder_track_compare,@function
gk_scene_b_encoder_track_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (44+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_4
        move.l (44+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_ENCODER_TRACK_MATCH
.Lgk_scene_editor_compare_miss_4:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_ENCODER_TRACK_MISS
        .size gk_scene_b_encoder_track_compare,.-gk_scene_b_encoder_track_compare
        .global gk_scene_b_encoder_matrix_compare
        .type gk_scene_b_encoder_matrix_compare,@function
gk_scene_b_encoder_matrix_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (44+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_5
        move.l (44+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_ENCODER_MATRIX_MATCH
.Lgk_scene_editor_compare_miss_5:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_ENCODER_MATRIX_MISS
        .size gk_scene_b_encoder_matrix_compare,.-gk_scene_b_encoder_matrix_compare
        .global gk_scene_a_encoder_track_compare
        .type gk_scene_a_encoder_track_compare,@function
gk_scene_a_encoder_track_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (48+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_6
        move.l (48+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_ENCODER_TRACK_MATCH
.Lgk_scene_editor_compare_miss_6:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_ENCODER_TRACK_MISS
        .size gk_scene_a_encoder_track_compare,.-gk_scene_a_encoder_track_compare
        .global gk_scene_a_encoder_matrix_compare
        .type gk_scene_a_encoder_matrix_compare,@function
gk_scene_a_encoder_matrix_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (48+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_7
        move.l (48+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_ENCODER_MATRIX_MATCH
.Lgk_scene_editor_compare_miss_7:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_ENCODER_MATRIX_MISS
        .size gk_scene_a_encoder_matrix_compare,.-gk_scene_a_encoder_matrix_compare
        .global gk_scene_b_button_direct_compare
        .type gk_scene_b_button_direct_compare,@function
gk_scene_b_button_direct_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (56+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_8
        move.l (56+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_BUTTON_DIRECT_MATCH
.Lgk_scene_editor_compare_miss_8:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_BUTTON_DIRECT_MISS
        .size gk_scene_b_button_direct_compare,.-gk_scene_b_button_direct_compare
        .global gk_scene_b_button_page0_compare
        .type gk_scene_b_button_page0_compare,@function
gk_scene_b_button_page0_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d3,%d0
        move.l (56+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_9
        move.l (56+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_BUTTON_PAGE0_MATCH
.Lgk_scene_editor_compare_miss_9:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_BUTTON_PAGE0_MISS
        .size gk_scene_b_button_page0_compare,.-gk_scene_b_button_page0_compare
        .global gk_scene_b_button_pageN_compare
        .type gk_scene_b_button_pageN_compare,@function
gk_scene_b_button_pageN_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d3,%d0
        move.l (56+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_10
        move.l (56+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_BUTTON_PAGEN_MATCH
.Lgk_scene_editor_compare_miss_10:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_BUTTON_PAGEN_MISS
        .size gk_scene_b_button_pageN_compare,.-gk_scene_b_button_pageN_compare
        .global gk_scene_b_button_clear_compare
        .type gk_scene_b_button_clear_compare,@function
gk_scene_b_button_clear_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (56+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_11
        move.l (56+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_BUTTON_CLEAR_MATCH
.Lgk_scene_editor_compare_miss_11:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_B_BUTTON_CLEAR_MISS
        .size gk_scene_b_button_clear_compare,.-gk_scene_b_button_clear_compare
        .global gk_scene_a_button_direct_compare
        .type gk_scene_a_button_direct_compare,@function
gk_scene_a_button_direct_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (52+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_12
        move.l (52+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_BUTTON_DIRECT_MATCH
.Lgk_scene_editor_compare_miss_12:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_BUTTON_DIRECT_MISS
        .size gk_scene_a_button_direct_compare,.-gk_scene_a_button_direct_compare
        .global gk_scene_a_button_page0_compare
        .type gk_scene_a_button_page0_compare,@function
gk_scene_a_button_page0_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d4,%d0
        move.l (52+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_13
        move.l (52+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_BUTTON_PAGE0_MATCH
.Lgk_scene_editor_compare_miss_13:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_BUTTON_PAGE0_MISS
        .size gk_scene_a_button_page0_compare,.-gk_scene_a_button_page0_compare
        .global gk_scene_a_button_pageN_compare
        .type gk_scene_a_button_pageN_compare,@function
gk_scene_a_button_pageN_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d3,%d0
        move.l (52+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_14
        move.l (52+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_BUTTON_PAGEN_MATCH
.Lgk_scene_editor_compare_miss_14:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_BUTTON_PAGEN_MISS
        .size gk_scene_a_button_pageN_compare,.-gk_scene_a_button_pageN_compare
        .global gk_scene_a_button_clear_compare
        .type gk_scene_a_button_clear_compare,@function
gk_scene_a_button_clear_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (52+16)(%sp),%d1
        bsr.w gk_scene_editor_identity_match
        tst.l %d0
        beq.s .Lgk_scene_editor_compare_miss_15
        move.l (52+16)(%sp),%d1
        move.l %d1,%d2
        lsr.l #8,%d2
        lsr.l #2,%d2
        andi.l #3,%d2
        move.l %d1,%d0
        lsr.l #7,%d0
        andi.l #7,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d2,%d0
        bne.w gk_scene_editor_fatal
        lsr.l #8,%d1
        lsr.l #4,%d1
        andi.l #15,%d1
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        cmp.l %d1,%d0
        bne.w gk_scene_editor_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_BUTTON_CLEAR_MATCH
.Lgk_scene_editor_compare_miss_15:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_A_BUTTON_CLEAR_MISS
        .size gk_scene_a_button_clear_compare,.-gk_scene_a_button_clear_compare
        .global gk_scene_editor_fatal
gk_scene_editor_fatal:
        illegal
        bra.s   gk_scene_editor_fatal
