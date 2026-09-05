        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_midi_bit_toggle_abort_fatal,@function
gk_midi_bit_toggle_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_midi_bit_toggle_fatal
        bra.w   gk_midi_bit_toggle_fatal
        .size   gk_midi_bit_toggle_abort_fatal,.-gk_midi_bit_toggle_abort_fatal
        .type   gk_midi_bit_toggle_release_abort_fatal,@function
gk_midi_bit_toggle_release_abort_fatal:
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_midi_bit_toggle_fatal
        bra.w   gk_midi_bit_toggle_abort_fatal
        .size   gk_midi_bit_toggle_release_abort_fatal,.-gk_midi_bit_toggle_release_abort_fatal
        .type   gk_midi_bit_toggle_prepare,@function
gk_midi_bit_toggle_prepare:
        cmpi.l  #7,%d0
        bhi.w   gk_midi_bit_toggle_fatal
        movea.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_midi_bit_toggle_fatal
        movea.l %d0,%a2
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_midi_bit_toggle_prepare_busy
        tst.l   %d0
        bmi.w   gk_midi_bit_toggle_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_midi_bit_toggle_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_midi_bit_toggle_prepare_busy
        tst.l   %d0
        bmi.w   gk_midi_bit_toggle_fatal
        cmp.l   %d6,%d0
        bne.w   gk_midi_bit_toggle_abort_fatal
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_midi_bit_toggle_abort_fatal
        move.l  %a0,%d3
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_midi_bit_toggle_abort_fatal
        cmp.l   %d6,%d0
        bne.w   gk_midi_bit_toggle_release_abort_fatal
        movea.l %d3,%a1
        cmpa.l  %a1,%a0
        bne.w   gk_midi_bit_toggle_release_abort_fatal
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
        ori.l   #GK_MIDI_BIT_TOKEN_ARMED,%d7
        moveq   #GK_OK,%d0
        rts
.Lgk_midi_bit_toggle_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_midi_bit_toggle_prepare,.-gk_midi_bit_toggle_prepare
        .type   gk_midi_bit_toggle_finish,@function
gk_midi_bit_toggle_finish:
        lea     -4(%sp),%sp
        move.w  %sr,%d1
        move.w  %d1,(%sp)
        andi.l  #0x0700,%d1
        cmpi.l  #0x0200,%d1
        bhs.s   .Lgk_midi_bit_toggle_finish_guarded
        move.w  #0x2200,%sr
.Lgk_midi_bit_toggle_finish_guarded:
        move.l  %d7,%d1
        cmp.l   %d1,%d0
        beq.s   .Lgk_midi_bit_toggle_no_write
        andi.l  #GK_MIDI_BIT_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_MIDI_BIT_TOKEN_WRITTEN,%d1
        cmp.l   %d1,%d0
        bne.w   gk_midi_bit_toggle_fatal
        moveq   #1,%d7
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_midi_bit_toggle_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_midi_bit_toggle_fatal
        bra.s   .Lgk_midi_bit_toggle_post_validate
.Lgk_midi_bit_toggle_no_write:
        moveq   #0,%d7
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_midi_bit_toggle_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_midi_bit_toggle_fatal
.Lgk_midi_bit_toggle_post_validate:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_midi_bit_toggle_fatal
        cmp.l   %d4,%d0
        bne.w   gk_midi_bit_toggle_fatal
        cmp.l   %d5,%d1
        bne.w   gk_midi_bit_toggle_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_midi_bit_toggle_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a3,%d1
        cmp.l   %d1,%d0
        bne.w   gk_midi_bit_toggle_fatal
        tst.l   %d7
        beq.s   .Lgk_midi_bit_toggle_finish_return
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_midi_bit_toggle_fatal
.Lgk_midi_bit_toggle_finish_return:
        moveq   #0,%d0
        move.w  (%sp),%d0
        move.w  %d0,%sr
        lea     4(%sp),%sp
        rts
        .size   gk_midi_bit_toggle_finish,.-gk_midi_bit_toggle_finish
        .global gk_stock_midi_bit_toggle
        .type   gk_stock_midi_bit_toggle,@function
gk_stock_midi_bit_toggle:
        move.l  4(%sp),%d0
        cmpi.l  #0x38,%d0
        blo.w   gk_midi_bit_toggle_fatal
        cmpi.l  #0x3e,%d0
        bhi.w   gk_midi_bit_toggle_fatal
        move.l  8(%sp),%d1
        cmpi.l  #1,%d1
        bne.w   .Lgk_midi_bit_toggle_passthrough
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_midi_bit_toggle_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_midi_bit_toggle_busy_early
        bra.w   gk_midi_bit_toggle_fatal
.Lgk_midi_bit_toggle_lifecycle_active:
        .incbin "stock/0249.bin", 0, 4
        .incbin "stock/0249.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_midi_bit_toggle_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_midi_bit_toggle_busy_saved
        tst.l   %d0
        bne.w   gk_midi_bit_toggle_fatal
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_midi_bit_toggle_stock_call
gk_midi_bit_toggle_stock_call:
        jsr     GK_STOCK_MIDI_BIT_TOGGLE
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        bsr.w   gk_midi_bit_toggle_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_midi_bit_toggle_busy_saved:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
.Lgk_midi_bit_toggle_busy_early:
        moveq   #0,%d0
        rts
.Lgk_midi_bit_toggle_passthrough:
        jmp     GK_STOCK_MIDI_BIT_TOGGLE
        .size   gk_stock_midi_bit_toggle,.-gk_stock_midi_bit_toggle
        .global gk_midi_bit_toggle_write_marker
        .type   gk_midi_bit_toggle_write_marker,@function
gk_midi_bit_toggle_write_marker:
        move.l  %d0,-(%sp)
        cmpi.l  #1,%d1
        bne.w   gk_midi_bit_toggle_fatal
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_MIDI_BIT_TOGGLE_BYTE0_DIRTY_RETURN,%d0
        beq.s   .Lgk_midi_bit_toggle_marker_return_ok
        cmpi.l  #GK_STOCK_MIDI_BIT_TOGGLE_BYTE1_DIRTY_RETURN,%d0
        bne.w   gk_midi_bit_toggle_fatal
.Lgk_midi_bit_toggle_marker_return_ok:
        move.l  36(%sp),%d0
        andi.l  #GK_MIDI_BIT_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_MIDI_BIT_TOKEN_ARMED,%d0
        bne.w   gk_midi_bit_toggle_fatal
        move.l  36(%sp),%d0
        andi.l  #GK_MIDI_BIT_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_MIDI_BIT_TOKEN_WRITTEN,%d0
        move.l  %d0,36(%sp)
        move.l  (%sp)+,%d0
        .global gk_midi_bit_toggle_stock_dirty_store
gk_midi_bit_toggle_stock_dirty_store:
        .incbin "stock/0250.bin", 0, 6
        rts
        .size   gk_midi_bit_toggle_write_marker,.-gk_midi_bit_toggle_write_marker
        .global gk_midi_bit_toggle_identity_match
        .type   gk_midi_bit_toggle_identity_match,@function
gk_midi_bit_toggle_identity_match:
        cmpi.l  #7,%d0
        bhi.w   gk_midi_bit_toggle_fatal
        move.l  %d1,%d2
        andi.l  #GK_MIDI_BIT_TOKEN_STATE_MASK,%d2
        cmpi.l  #GK_MIDI_BIT_TOKEN_WRITTEN,%d2
        bne.w   gk_midi_bit_toggle_fatal
        move.l  %d1,%d2
        lsr.l   #7,%d2
        andi.l  #7,%d2
        cmp.l   %d2,%d0
        bne.w   gk_midi_bit_toggle_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.w   gk_midi_bit_toggle_fatal
        move.l  %d1,%d2
        lsr.l   #8,%d2
        lsr.l   #2,%d2
        andi.l  #3,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.w   gk_midi_bit_toggle_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.w   gk_midi_bit_toggle_fatal
        move.l  %d1,%d2
        lsr.l   #8,%d2
        lsr.l   #4,%d2
        andi.l  #15,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.w   gk_midi_bit_toggle_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.w   gk_midi_bit_toggle_fatal
        move.l  %d1,%d2
        andi.l  #0x7f,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   gk_midi_bit_toggle_fatal
        move.l  %d1,%d0
        lsr.l   #7,%d0
        andi.l  #7,%d0
        add.l   %d0,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        adda.l  %d0,%a0
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        .global gk_midi_bit_toggle_identity_snapshot
gk_midi_bit_toggle_identity_snapshot:
        move.w  (%a0),%d0
        move.w  %d2,%sr
        move.l  %d1,%d2
        andi.l  #0x7f,%d2
        lsl.l   #8,%d2
        ori.l   #0xff,%d2
        cmp.l   %d2,%d0
        beq.s   .Lgk_midi_bit_toggle_identity_stable
        moveq   #0,%d0
        rts
.Lgk_midi_bit_toggle_identity_stable:
        move.l  %d1,%d2
        lsr.l   #7,%d2
        andi.l  #7,%d2
        lea     GK_STOCK_SEQUENCER_TRACK_PARTS,%a0
        adda.l  %d2,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  %d1,%d2
        lsr.l   #8,%d2
        lsr.l   #2,%d2
        andi.l  #3,%d2
        cmp.l   %d2,%d0
        bne.w   gk_midi_bit_toggle_fatal
        suba.l  #8,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        lsr.l   #8,%d1
        lsr.l   #4,%d1
        andi.l  #15,%d1
        cmp.l   %d1,%d0
        bne.w   gk_midi_bit_toggle_fatal
        moveq   #1,%d0
        rts
        .size   gk_midi_bit_toggle_identity_match,.-gk_midi_bit_toggle_identity_match
        .global gk_midi_bit_toggle_byte0_compare
        .type gk_midi_bit_toggle_byte0_compare,@function
gk_midi_bit_toggle_byte0_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l 44(%sp),%d1
        bsr.w gk_midi_bit_toggle_identity_match
        tst.l %d0
        beq.s .Lgk_midi_bit_compare_miss_0
        moveq #0,%d0
        tst.l %d0
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_MIDI_BIT_TOGGLE_BYTE0_MATCH
.Lgk_midi_bit_compare_miss_0:
        moveq #1,%d0
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_MIDI_BIT_TOGGLE_MISS
        .size gk_midi_bit_toggle_byte0_compare,.-gk_midi_bit_toggle_byte0_compare
        .global gk_midi_bit_toggle_byte1_compare
        .type gk_midi_bit_toggle_byte1_compare,@function
gk_midi_bit_toggle_byte1_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l 44(%sp),%d1
        bsr.w gk_midi_bit_toggle_identity_match
        tst.l %d0
        beq.s .Lgk_midi_bit_compare_miss_1
        moveq #0,%d0
        tst.l %d0
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_MIDI_BIT_TOGGLE_BYTE1_MATCH
.Lgk_midi_bit_compare_miss_1:
        moveq #1,%d0
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_MIDI_BIT_TOGGLE_MISS
        .size gk_midi_bit_toggle_byte1_compare,.-gk_midi_bit_toggle_byte1_compare
        .global gk_midi_bit_toggle_fatal
gk_midi_bit_toggle_fatal:
        illegal
        bra.s   gk_midi_bit_toggle_fatal
