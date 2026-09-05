        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_track_parameter_abort_fatal,@function
gk_track_parameter_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_cleanup
        bra.w gk_track_pair_byte0_fatal_workspace_consistency
        .size   gk_track_parameter_abort_fatal,.-gk_track_parameter_abort_fatal
        .type   gk_track_parameter_release_abort_fatal,@function
gk_track_parameter_release_abort_fatal:
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_cleanup
        bra.w gk_track_pair_byte0_fatal_workspace_consistency
        .size   gk_track_parameter_release_abort_fatal,.-gk_track_parameter_release_abort_fatal
        .type   gk_track_parameter_prepare,@function
gk_track_parameter_prepare:
        cmpi.l  #7,%d0
        bhi.w gk_track_pair_byte0_fatal_entry_track
        movea.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmpi.l  #7,%d0
        bhi.w gk_track_pair_byte0_fatal_entry_track
        movea.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w gk_track_pair_byte0_fatal_entry_part
        movea.l %d0,%a5
        move.l  GK_STOCK_TRACK_MODE,%d0
        movea.l %d0,%a6
        move.l  GK_STOCK_PARAMETER_PAGE,%d0
        cmpi.l  #4,%d0
        bhi.w gk_track_pair_byte0_fatal_entry_id
        movea.l %d0,%a2
        .global gk_track_parameter_prepare_interlock_begin
gk_track_parameter_prepare_interlock_begin:
        move.w  %sr,%d7
        move.l  %d7,%d0
        andi.l  #0x0700,%d0
        cmpi.l  #0x0200,%d0
        bhs.s   .Lgk_track_parameter_prepare_interlock_armed
        move.w  #0x2200,%sr
.Lgk_track_parameter_prepare_interlock_armed:
        .global gk_track_parameter_prepare_interlock_armed
gk_track_parameter_prepare_interlock_armed:
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_track_parameter_prepare_busy_guarded
        tst.l   %d0
        bmi.w gk_track_pair_byte0_fatal_context_transient
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w gk_track_pair_byte0_fatal_workspace_descriptor
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        .global gk_track_parameter_prepare_interlock_release
gk_track_parameter_prepare_interlock_release:
        move.w  %d7,%sr
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_track_parameter_prepare_busy
        tst.l   %d0
        bmi.w gk_track_pair_byte0_fatal_workspace_prepare
        cmp.l   %d6,%d0
        bne.w gk_track_pair_byte0_fatal_workspace_consistency
        move.l  %a5,%d2
        cmp.l   %d2,%d1
        bne.w gk_track_pair_byte0_fatal_workspace_consistency
        move.l  %a0,%d3
        move.l  %d4,%d0
        move.l  %a5,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w gk_track_pair_byte0_fatal_physical_acquire
        cmp.l   %d6,%d0
        bne.w gk_track_pair_byte0_fatal_workspace_consistency
        movea.l %d3,%a1
        cmpa.l  %a1,%a0
        bne.w gk_track_pair_byte0_fatal_workspace_consistency
        move.l  %d6,%d7
        move.l  %a3,%d0
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
        ori.l   #GK_TRACK_PARAMETER_TOKEN_ARMED,%d7
        moveq   #GK_OK,%d0
        rts
.Lgk_track_parameter_prepare_busy_guarded:
        move.w  %d7,%sr
        bra.s   .Lgk_track_parameter_prepare_busy
.Lgk_track_parameter_prepare_fatal_guarded:
        move.w  %d7,%sr
        bra.w gk_track_pair_byte0_fatal_context_transient
.Lgk_track_parameter_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_track_parameter_prepare,.-gk_track_parameter_prepare
        .type   gk_track_parameter_finish,@function
gk_track_parameter_finish:
        lea     -4(%sp),%sp
        move.w  %sr,%d1
        move.w  %d1,(%sp)
        andi.l  #0x0700,%d1
        cmpi.l  #0x0200,%d1
        bhs.s   .Lgk_track_parameter_finish_guarded
        move.w  #0x2200,%sr
.Lgk_track_parameter_finish_guarded:
        move.l  %d7,%d1
        cmp.l   %d1,%d0
        beq.s   .Lgk_track_parameter_no_write
        andi.l  #GK_TRACK_PARAMETER_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_TRACK_PARAMETER_TOKEN_WRITTEN,%d1
        cmp.l   %d1,%d0
        bne.w gk_track_pair_byte0_fatal_finish_token
        moveq   #1,%d7
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a5,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_mark_dirty
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_commit
        bra.s   .Lgk_track_parameter_post_validate
.Lgk_track_parameter_no_write:
        moveq   #0,%d7
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_no_write_release
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_no_write_abort
.Lgk_track_parameter_post_validate:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w gk_track_pair_byte0_fatal_post_context
        cmp.l   %d4,%d0
        bne.w gk_track_pair_byte0_fatal_post_bank_pattern
        cmp.l   %d5,%d1
        bne.w gk_track_pair_byte0_fatal_post_bank_pattern
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w gk_track_pair_byte0_fatal_post_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w gk_track_pair_byte0_fatal_post_track
        move.l  GK_STOCK_TRACK_MODE,%d0
        move.l  %a6,%d1
        cmp.l   %d1,%d0
        bne.w gk_track_pair_byte0_fatal_post_track
        move.l  GK_STOCK_PARAMETER_PAGE,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w gk_track_pair_byte0_fatal_post_track
        tst.l   %d7
        beq.s   .Lgk_track_parameter_finish_return
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_final_release
.Lgk_track_parameter_finish_return:
        moveq   #0,%d0
        move.w  (%sp),%d0
        move.w  %d0,%sr
        lea     4(%sp),%sp
        rts
        .size   gk_track_parameter_finish,.-gk_track_parameter_finish
        .global gk_stock_track_parameter_absolute
        .type   gk_stock_track_parameter_absolute,@function
gk_stock_track_parameter_absolute:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_track_parameter_absolute_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_track_parameter_absolute_busy_early
        bra.w gk_track_pair_byte0_fatal_entry_lifecycle
.Lgk_track_parameter_absolute_lifecycle_active:
        .incbin "stock/0281.bin", 0, 4
        .incbin "stock/0281.bin", 4, 4
        move.l  48(%sp),%d0
        cmpi.l  #GK_STOCK_TRACK_PARAMETER_ABSOLUTE_RETURN_0,%d0
        beq.s   .Lgk_track_parameter_absolute_caller_ok
        cmpi.l  #GK_STOCK_TRACK_PARAMETER_ABSOLUTE_RETURN_1,%d0
        beq.s   .Lgk_track_parameter_absolute_caller_ok
        cmpi.l  #GK_STOCK_TRACK_PARAMETER_ABSOLUTE_RETURN_2,%d0
        bne.w gk_track_pair_byte0_fatal_runtime_image
.Lgk_track_parameter_absolute_caller_ok:
        move.l  52(%sp),%d0
        cmpi.l  #15,%d0
        bhi.w gk_track_pair_byte0_fatal_entry_track
        move.l  56(%sp),%d0
        cmpi.l  #29,%d0
        bhi.w gk_track_pair_byte0_fatal_entry_id
        move.l  60(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_track_parameter_absolute_negative
        tst.l   %d1
        bne.w gk_track_pair_byte0_fatal_entry_delta
        bra.s   .Lgk_track_parameter_absolute_value_ok
.Lgk_track_parameter_absolute_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w gk_track_pair_byte0_fatal_entry_delta
.Lgk_track_parameter_absolute_value_ok:
        move.l  52(%sp),%d0
        andi.l  #7,%d0
        bsr.w   gk_track_parameter_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_track_parameter_absolute_busy_saved
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_workspace_prepare
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  60(%sp),%d2
        move.l  %d7,-(%sp)
        move.l  %d2,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_track_parameter_absolute_stock_call
gk_track_parameter_absolute_stock_call:
        .incbin "stock/0282.bin", 0, 6
        move.l  %d0,60(%sp)
        move.l  12(%sp),%d0
        lea     16(%sp),%sp
        bsr.w   gk_track_parameter_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_track_parameter_absolute_busy_saved:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
.Lgk_track_parameter_absolute_busy_early:
        moveq   #-1,%d0
        rts
        .size   gk_stock_track_parameter_absolute,.-gk_stock_track_parameter_absolute
        .global gk_stock_track_parameter_relative
        .type   gk_stock_track_parameter_relative,@function
gk_stock_track_parameter_relative:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_track_parameter_relative_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_track_parameter_relative_busy_early
        bra.w gk_track_pair_byte0_fatal_entry_lifecycle
.Lgk_track_parameter_relative_lifecycle_active:
        .incbin "stock/0283.bin", 0, 4
        .incbin "stock/0283.bin", 4, 4
        move.l  52(%sp),%d0
        cmpi.l  #5,%d0
        bhi.w gk_track_pair_byte0_fatal_entry_id
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_track_parameter_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_track_parameter_relative_busy_saved
        tst.l   %d0
        bne.w gk_track_pair_byte0_fatal_workspace_prepare
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        .global gk_track_parameter_relative_stock_call
gk_track_parameter_relative_stock_call:
        jsr     GK_STOCK_TRACK_PARAMETER_RELATIVE
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        bsr.w   gk_track_parameter_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_track_parameter_relative_busy_saved:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
.Lgk_track_parameter_relative_busy_early:
        moveq   #0,%d0
        rts
        .size   gk_stock_track_parameter_relative,.-gk_stock_track_parameter_relative
        .global gk_track_parameter_absolute_write_marker
        .type gk_track_parameter_absolute_write_marker,@function
gk_track_parameter_absolute_write_marker:
        move.l %d0,-(%sp)
        cmpi.l #1,%d1
        bne.w gk_track_pair_byte0_fatal_marker_dirty
        move.l 4(%sp),%d0
        cmpi.l #GK_STOCK_TRACK_PARAMETER_ABSOLUTE_DIRTY_RETURN,%d0
        bne.w gk_track_pair_byte0_fatal_marker_return
        move.l 64(%sp),%d0
        andi.l #GK_TRACK_PARAMETER_TOKEN_STATE_MASK,%d0
        cmpi.l #GK_TRACK_PARAMETER_TOKEN_ARMED,%d0
        bne.w gk_track_pair_byte0_fatal_marker_token
        move.l 64(%sp),%d0
        andi.l #GK_TRACK_PARAMETER_TOKEN_CONTEXT_MASK,%d0
        ori.l #GK_TRACK_PARAMETER_TOKEN_WRITTEN,%d0
        move.l %d0,64(%sp)
        move.l (%sp)+,%d0
        .global gk_track_parameter_absolute_stock_dirty_store
gk_track_parameter_absolute_stock_dirty_store:
        .incbin "stock/0284.bin", 0, 6
        rts
        .size gk_track_parameter_absolute_write_marker,.-gk_track_parameter_absolute_write_marker
        .global gk_track_parameter_relative_write_marker
        .type gk_track_parameter_relative_write_marker,@function
gk_track_parameter_relative_write_marker:
        move.l %d0,-(%sp)
        cmpi.l #1,%d1
        bne.w gk_track_pair_byte0_fatal_marker_dirty
        move.l 4(%sp),%d0
        cmpi.l #GK_STOCK_TRACK_PARAMETER_RELATIVE_DIRTY_RETURN,%d0
        bne.w gk_track_pair_byte0_fatal_marker_return
        move.l 68(%sp),%d0
        andi.l #GK_TRACK_PARAMETER_TOKEN_STATE_MASK,%d0
        cmpi.l #GK_TRACK_PARAMETER_TOKEN_ARMED,%d0
        bne.w gk_track_pair_byte0_fatal_marker_token
        move.l 68(%sp),%d0
        andi.l #GK_TRACK_PARAMETER_TOKEN_CONTEXT_MASK,%d0
        ori.l #GK_TRACK_PARAMETER_TOKEN_WRITTEN,%d0
        move.l %d0,68(%sp)
        move.l (%sp)+,%d0
        .global gk_track_parameter_relative_stock_dirty_store
gk_track_parameter_relative_stock_dirty_store:
        .incbin "stock/0285.bin", 0, 6
        rts
        .size gk_track_parameter_relative_write_marker,.-gk_track_parameter_relative_write_marker
        .global gk_track_parameter_identity_match
        .type   gk_track_parameter_identity_match,@function
gk_track_parameter_identity_match:
        cmpi.l  #7,%d0
        bhi.w gk_track_pair_byte0_fatal_entry_track
        move.l  %d1,%d2
        andi.l  #GK_TRACK_PARAMETER_TOKEN_STATE_MASK,%d2
        cmpi.l  #GK_TRACK_PARAMETER_TOKEN_ARMED,%d2
        bne.w gk_track_pair_byte0_fatal_finish_token
        move.l  %d1,%d2
        lsr.l   #7,%d2
        andi.l  #7,%d2
        cmp.l   %d2,%d0
        bne.w gk_track_pair_byte0_fatal_post_track
        move.l  %d1,%d2
        lsr.l   #8,%d2
        lsr.l   #2,%d2
        andi.l  #3,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.w gk_track_pair_byte0_fatal_post_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.w gk_track_pair_byte0_fatal_post_part
        move.l  %d1,%d2
        lsr.l   #8,%d2
        lsr.l   #4,%d2
        andi.l  #15,%d2
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d2,%d0
        bne.w gk_track_pair_byte0_fatal_context_bank
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.w gk_track_pair_byte0_fatal_context_bank
        move.l  %d1,%d2
        andi.l  #0x7f,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w gk_track_pair_byte0_fatal_workspace_descriptor
        move.l  %d1,%d0
        lsr.l   #7,%d0
        andi.l  #7,%d0
        add.l   %d0,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        adda.l  %d0,%a0
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        .global gk_track_parameter_identity_snapshot
gk_track_parameter_identity_snapshot:
        move.w  (%a0),%d0
        move.w  %d2,%sr
        move.l  %d1,%d2
        andi.l  #0x7f,%d2
        lsl.l   #8,%d2
        ori.l   #0xff,%d2
        cmp.l   %d2,%d0
        beq.s   .Lgk_track_parameter_identity_stable
        moveq   #0,%d0
        rts
.Lgk_track_parameter_identity_stable:
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
        bne.w gk_track_pair_byte0_fatal_context_part
        suba.l  #8,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        lsr.l   #8,%d1
        lsr.l   #4,%d1
        andi.l  #15,%d1
        cmp.l   %d1,%d0
        bne.w gk_track_pair_byte0_fatal_context_bank
        moveq   #1,%d0
        rts
        .size   gk_track_parameter_identity_match,.-gk_track_parameter_identity_match
        .global gk_track_parameter_absolute_midi_compare
        .type gk_track_parameter_absolute_midi_compare,@function
gk_track_parameter_absolute_midi_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d2,%d0
        move.l (56+16)(%sp),%d1
        bsr.w gk_track_parameter_identity_match
        tst.l %d0
        beq.s .Lgk_track_parameter_compare_miss_58
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_TRACK_PARAMETER_ABSOLUTE_MIDI_MATCH
.Lgk_track_parameter_compare_miss_58:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_TRACK_PARAMETER_ABSOLUTE_MIDI_MISS
        .size gk_track_parameter_absolute_midi_compare,.-gk_track_parameter_absolute_midi_compare
        .global gk_track_parameter_relative_midi_compare
        .type gk_track_parameter_relative_midi_compare,@function
gk_track_parameter_relative_midi_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d3,%d0
        move.l (60+16)(%sp),%d1
        bsr.w gk_track_parameter_identity_match
        tst.l %d0
        beq.s .Lgk_track_parameter_compare_miss_59
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_TRACK_PARAMETER_RELATIVE_MIDI_MATCH
.Lgk_track_parameter_compare_miss_59:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_TRACK_PARAMETER_RELATIVE_MIDI_MISS
        .size gk_track_parameter_relative_midi_compare,.-gk_track_parameter_relative_midi_compare
        .global gk_track_parameter_fatal
gk_track_parameter_fatal:
        illegal
        bra.s   gk_track_parameter_fatal
