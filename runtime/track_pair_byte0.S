        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_track_pair_byte0_d3_pad_start
gk_track_pair_byte0_d3_pad_start:
        .global gk_sequencer_engine_acquire
        .type   gk_sequencer_engine_acquire,@function
gk_sequencer_engine_acquire:
        jsr     gk_selector_acquire
        tst.l   %d0
        bmi.s   .Lgk_sequencer_engine_acquire_negative
        move.l  %d0,-(%sp)
        moveq   #0,%d1
        move.b  __gk_runtime_flags,%d1
        andi.l  #0xfe,%d1
        bne.s   .Lgk_sequencer_engine_stable_corrupt
        move.l  __gk_pending_workspace_descriptor,%d1
        cmpi.l  #-1,%d1
        bne.s   .Lgk_sequencer_engine_stable_corrupt
        tst.b   __gk_pending_transition_flags
        bne.s   .Lgk_sequencer_engine_stable_corrupt
        move.l  (%sp)+,%d0
        rts
.Lgk_sequencer_engine_stable_corrupt:
        move.l  (%sp)+,%d0
        jsr     gk_descriptor_release
        moveq   #GK_ERR_CORRUPT,%d0
        rts
.Lgk_sequencer_engine_acquire_negative:
        cmpi.l  #GK_ERR_UPDATING,%d0
        bne.w   .Lgk_sequencer_engine_return
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        moveq   #0,%d2
        move.w  (%a0),%d2
        move.l  %d2,%d3
        andi.l  #0xff,%d3
        cmpi.l  #GK_ID_NONE,%d3
        beq.w   .Lgk_sequencer_engine_pending_corrupt
        lsr.l   #8,%d2
        andi.l  #0xff,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_sequencer_engine_pending_corrupt
        cmp.l   %d3,%d2
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        moveq   #0,%d3
        move.b  __gk_runtime_flags,%d3
        btst    #7,%d3
        beq.w   .Lgk_sequencer_engine_pending_corrupt
        andi.l  #0x7e,%d3
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        moveq   #0,%d3
        move.b  __gk_pending_workspace_descriptor,%d3
        cmp.l   %d2,%d3
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        moveq   #0,%d3
        move.b  __gk_workspace_descriptor,%d3
        cmp.l   %d2,%d3
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        moveq   #0,%d3
        move.b  __gk_pending_transition_flags,%d3
        cmpi.l  #GK_TRANSITION_PRESERVE_NAME,%d3
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        moveq   #0,%d3
        move.b  __gk_current_bank,%d3
        cmpi.l  #15,%d3
        bhi.w   .Lgk_sequencer_engine_pending_corrupt
        moveq   #0,%d4
        move.b  __gk_pending_bank,%d4
        cmp.l   %d3,%d4
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        moveq   #0,%d4
        move.b  __gk_current_pattern,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_sequencer_engine_pending_corrupt
        cmp.b   __gk_pending_pattern,%d4
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        .global gk_track_pair_byte0_d3_old_pc_guard
gk_track_pair_byte0_d3_old_pc_guard:
        nop
        nop
        moveq   #0,%d4
        move.b  __gk_current_kit,%d4
        cmp.b   __gk_pending_kit,%d4
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        moveq   #0,%d4
        move.b  __gk_workspace_bound,%d4
        cmpi.l  #1,%d4
        bhi.w   .Lgk_sequencer_engine_pending_corrupt
        cmp.b   __gk_pending_workspace_bound,%d4
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_sequencer_engine_pending_corrupt
        move.l  %d3,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_ENGINE_PART,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.s   .Lgk_sequencer_engine_pending_corrupt
        cmp.l   %d2,%d0
        bne.s   .Lgk_sequencer_engine_pending_release_corrupt
        bra.s   .Lgk_sequencer_engine_pending_restore
.Lgk_sequencer_engine_pending_release_corrupt:
        jsr     gk_descriptor_release
.Lgk_sequencer_engine_pending_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_sequencer_engine_pending_restore:
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
.Lgk_sequencer_engine_return:
        rts
        .global gk_sequencer_engine_acquire_end
gk_sequencer_engine_acquire_end:
        .size   gk_sequencer_engine_acquire,.-gk_sequencer_engine_acquire
        .global gk_workspace_save_as_latch_reader_validate
        .type   gk_workspace_save_as_latch_reader_validate,@function
gk_workspace_save_as_latch_reader_validate:
        tst.w   GK_DESC_READERS(%a2)
        beq.s   .Lgk_save_as_latch_safe
        cmp.l   %d6,%d3
        beq.s   .Lgk_save_as_latch_safe
        moveq   #1,%d1
        move.w  GK_DESC_READERS(%a2),%d0
        cmp.w   %d1,%d0
        bne.s   .Lgk_save_as_latch_busy
        addq.l  #2,%d1
        move.w  GK_DESC_ROOTS(%a2),%d0
        cmp.w   %d1,%d0
        blo.s   .Lgk_save_as_latch_corrupt
        moveq   #0,%d0
        move.w  __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%d0
        move.l  %d0,%d1
        andi.l  #0xff,%d1
        cmpi.l  #GK_ID_NONE,%d1
        bne.s   .Lgk_save_as_latch_corrupt
        lsr.l   #8,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_save_as_latch_corrupt
.Lgk_save_as_latch_safe:
        moveq   #GK_OK,%d0
        rts
.Lgk_save_as_latch_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
.Lgk_save_as_latch_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_workspace_save_as_latch_reader_validate,.-gk_workspace_save_as_latch_reader_validate
        .global gk_track_pair_byte0_d3_pad_end
gk_track_pair_byte0_d3_pad_end:
        .type   gk_track_pair_byte0_abort_fatal,@function
gk_track_pair_byte0_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal_cleanup
        bra.w   gk_track_pair_byte0_fatal_workspace_consistency
        .size   gk_track_pair_byte0_abort_fatal,.-gk_track_pair_byte0_abort_fatal
        .type   gk_track_pair_byte0_release_abort_fatal,@function
gk_track_pair_byte0_release_abort_fatal:
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal_cleanup
        bra.w   gk_track_pair_byte0_abort_fatal
        .size   gk_track_pair_byte0_release_abort_fatal,.-gk_track_pair_byte0_release_abort_fatal
        .type   gk_track_pair_byte0_context_diagnose,@function
gk_track_pair_byte0_context_diagnose:
        move.w  #0x2700,%sr
        moveq   #0,%d4
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d4
        cmpi.l  #15,%d4
        bhi.w   gk_track_pair_byte0_fatal_context_bank
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   gk_track_pair_byte0_fatal_context_bank
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   gk_track_pair_byte0_fatal_context_bank
        moveq   #0,%d5
        move.b  GK_STOCK_CURRENT_PATTERN,%d5
        cmpi.l  #15,%d5
        bhi.w   gk_track_pair_byte0_fatal_context_pattern
        moveq   #0,%d6
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d6
        cmpi.l  #3,%d6
        bhi.w   gk_track_pair_byte0_fatal_context_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d6,%d0
        bne.w   gk_track_pair_byte0_fatal_context_part
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w   gk_track_pair_byte0_fatal_context_part
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        .incbin "stock/0278.bin", 0, 6
        cmpa.l  %a2,%a0
        bne.w   gk_track_pair_byte0_fatal_context_bank_pointer
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d6,%d1
        bne.w   gk_track_pair_byte0_fatal_context_assignment
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d6,%d1
        bne.w   gk_track_pair_byte0_fatal_context_assignment
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        bne.w   gk_track_pair_byte0_fatal_context_transition
        andi.l  #0x7e,%d0
        bne.w   gk_track_pair_byte0_fatal_context_runtime
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        cmpi.l  #GK_ID_NONE,%d7
        beq.w   gk_track_pair_byte0_fatal_context_workspace_absent
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bhi.w   gk_track_pair_byte0_fatal_context_workspace
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w   gk_track_pair_byte0_fatal_context_workspace
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   gk_track_pair_byte0_fatal_context_workspace
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        cmp.l   %d2,%d1
        bne.w   gk_track_pair_byte0_fatal_context_kit_assignment
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a4
        adda.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a4),%d0
        move.l  %d0,%d1
        andi.l  #0x84,%d1
        bne.w   gk_track_pair_byte0_fatal_context_descriptor_flags
        move.l  %d0,%d1
        andi.l  #0x62,%d1
        beq.s   .Lgk_track_pair_diagnose_flags_stable
        cmpi.l  #GK_DESC_CLONE_COPY,%d1
        beq.w   gk_track_pair_byte0_fatal_context_descriptor_busy
        cmpi.l  #GK_DESC_PROMOTION_COPY,%d1
        beq.w   gk_track_pair_byte0_fatal_context_descriptor_busy
        bra.w   gk_track_pair_byte0_fatal_context_descriptor_flags
.Lgk_track_pair_diagnose_flags_stable:
        btst    #0,%d0
        beq.w   gk_track_pair_byte0_fatal_context_descriptor_flags
        btst    #3,%d0
        beq.w   gk_track_pair_byte0_fatal_context_descriptor_flags
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a4),%d0
        cmp.l   %d2,%d0
        bne.w   gk_track_pair_byte0_fatal_context_descriptor_kit
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a4),%d3
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w   gk_track_pair_byte0_fatal_context_descriptor_physical
        move.l  %d3,%d0
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        bne.w   gk_track_pair_byte0_fatal_context_descriptor_physical
        andi.l  #3,%d3
        cmp.l   %d6,%d3
        bne.w   gk_track_pair_byte0_fatal_context_descriptor_physical
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.l   %d1,%d0
        bne.w   gk_track_pair_byte0_fatal_context_sidecar
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a4),%d0
        jsr     gk_physical_validate
        cmp.l   %d7,%d0
        bne.w   gk_track_pair_byte0_fatal_context_physical_map
        bra.w   gk_track_pair_byte0_fatal_context_transient
        .size   gk_track_pair_byte0_context_diagnose,.-gk_track_pair_byte0_context_diagnose
        .global gk_track_pair_byte0_prepare
        .type   gk_track_pair_byte0_prepare,@function
gk_track_pair_byte0_prepare:
        cmpi.l  #7,%d0
        bhi.w   gk_track_pair_byte0_fatal_entry_track
        movea.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_track_pair_byte0_fatal_entry_part
        movea.l %d0,%a2
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_track_pair_byte0_prepare_busy
        tst.l   %d0
        bpl.s   .Lgk_track_pair_byte0_context_valid
        bsr.w   gk_track_pair_byte0_context_diagnose
        bra.w   gk_track_pair_byte0_fatal
.Lgk_track_pair_byte0_context_valid:
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        moveq   #GK_DESCRIPTOR_COUNT - 1,%d0
        cmp.l   %d0,%d6
        bhi.w   gk_track_pair_byte0_fatal_workspace_descriptor
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_track_pair_byte0_prepare_busy
        tst.l   %d0
        bpl.s   .Lgk_track_pair_byte0_workspace_prepared
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   gk_track_pair_byte0_fatal_workspace_busy
        bra.w   gk_track_pair_byte0_fatal_workspace_prepare
.Lgk_track_pair_byte0_workspace_prepared:
        cmp.l   %d6,%d0
        bne.w   gk_track_pair_byte0_abort_fatal
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_track_pair_byte0_abort_fatal
        move.l  %a0,%d3
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bpl.s   .Lgk_track_pair_byte0_physical_acquired
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal_cleanup
        bra.w   gk_track_pair_byte0_fatal_physical_acquire
.Lgk_track_pair_byte0_physical_acquired:
        cmp.l   %d6,%d0
        bne.w   gk_track_pair_byte0_release_abort_fatal
        movea.l %d3,%a1
        cmpa.l  %a1,%a0
        bne.w   gk_track_pair_byte0_release_abort_fatal
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
        ori.l   #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d7
        moveq   #GK_OK,%d0
        rts
.Lgk_track_pair_byte0_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_track_pair_byte0_prepare,.-gk_track_pair_byte0_prepare
        .global gk_track_pair_byte0_finish
        .type   gk_track_pair_byte0_finish,@function
gk_track_pair_byte0_finish:
        lea     -4(%sp),%sp
        move.w  %sr,%d1
        move.w  %d1,(%sp)
        andi.l  #0x0700,%d1
        cmpi.l  #0x0200,%d1
        bhs.s   .Lgk_track_pair_byte0_finish_guarded
        move.w  #0x2200,%sr
.Lgk_track_pair_byte0_finish_guarded:
        move.l  %d7,%d1
        cmp.l   %d1,%d0
        beq.s   .Lgk_track_pair_byte0_no_write
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d1
        cmp.l   %d1,%d0
        bne.w   gk_track_pair_byte0_fatal_finish_token
        moveq   #1,%d7
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal_mark_dirty
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal_commit
        bra.s   .Lgk_track_pair_byte0_post_validate
.Lgk_track_pair_byte0_no_write:
        moveq   #0,%d7
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal_no_write_release
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal_no_write_abort
.Lgk_track_pair_byte0_post_validate:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_track_pair_byte0_fatal_post_context
        cmp.l   %d4,%d0
        bne.w   gk_track_pair_byte0_fatal_post_bank_pattern
        cmp.l   %d5,%d1
        bne.w   gk_track_pair_byte0_fatal_post_bank_pattern
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_track_pair_byte0_fatal_post_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a3,%d1
        cmp.l   %d1,%d0
        bne.w   gk_track_pair_byte0_fatal_post_track
        tst.l   %d7
        beq.s   .Lgk_track_pair_byte0_finish_return
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal_final_release
.Lgk_track_pair_byte0_finish_return:
        moveq   #0,%d0
        move.w  (%sp),%d0
        move.w  %d0,%sr
        lea     4(%sp),%sp
        rts
        .size   gk_track_pair_byte0_finish,.-gk_track_pair_byte0_finish
        .global gk_stock_track_pair_byte0
        .type   gk_stock_track_pair_byte0,@function
gk_stock_track_pair_byte0:
        lea     gk_track_pair_byte0_d3_old_pc_guard+0x08000000,%a0
        move.l  (%a0),%d0
        cmpi.l  #0x4e714e71,%d0
        bne.w   gk_track_pair_byte0_fatal_runtime_image
        move.l  4(%sp),%d0
        cmpi.l  #6,%d0
        bne.w   gk_track_pair_byte0_fatal_entry_id
        move.l  8(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_track_pair_byte0_delta_negative
        tst.l   %d1
        bne.w   gk_track_pair_byte0_fatal_entry_delta
        bra.s   .Lgk_track_pair_byte0_delta_ok
.Lgk_track_pair_byte0_delta_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_track_pair_byte0_fatal_entry_delta
.Lgk_track_pair_byte0_delta_ok:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_track_pair_byte0_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_track_pair_byte0_busy_early
        bra.w   gk_track_pair_byte0_fatal_entry_lifecycle
.Lgk_track_pair_byte0_lifecycle_active:
        .incbin "stock/0279.bin", 0, 4
        .incbin "stock/0279.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bsr.w   gk_track_pair_byte0_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_track_pair_byte0_busy_saved
        tst.l   %d0
        bne.w   gk_track_pair_byte0_fatal
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        move.l  #GK_STOCK_TRACK_PAIR_BYTE0,%d0
        moveq   #6,%d1
        lea     GK_STOCK_TRACK_PAIR_BYTE0_REGISTRY,%a0
        movea.l %d0,%a1
        .global gk_track_pair_byte0_stock_call
gk_track_pair_byte0_stock_call:
        jsr     GK_STOCK_TRACK_PAIR_BYTE0
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        bsr.w   gk_track_pair_byte0_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_track_pair_byte0_busy_saved:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
.Lgk_track_pair_byte0_busy_early:
        moveq   #0,%d0
        rts
        .size   gk_stock_track_pair_byte0,.-gk_stock_track_pair_byte0
        .global gk_track_pair_byte0_write_marker
        .type   gk_track_pair_byte0_write_marker,@function
gk_track_pair_byte0_write_marker:
        move.l  %d0,-(%sp)
        cmpi.l  #1,%d1
        bne.w   gk_track_pair_byte0_fatal_marker_dirty
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_TRACK_PAIR_BYTE0_DIRTY_RETURN,%d0
        bne.w   gk_track_pair_byte0_fatal_marker_return
        move.l  36(%sp),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d0
        bne.w   gk_track_pair_byte0_fatal_marker_token
        move.l  36(%sp),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d0
        move.l  %d0,36(%sp)
        move.l  (%sp)+,%d0
        .global gk_track_pair_byte0_stock_dirty_store
gk_track_pair_byte0_stock_dirty_store:
        .incbin "stock/0280.bin", 0, 6
        rts
        .size   gk_track_pair_byte0_write_marker,.-gk_track_pair_byte0_write_marker
        .global gk_track_pair_byte0_fatal_context_bank
        .type gk_track_pair_byte0_fatal_context_bank,@function
gk_track_pair_byte0_fatal_context_bank:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_bank
        .size gk_track_pair_byte0_fatal_context_bank,.-gk_track_pair_byte0_fatal_context_bank
        .global gk_track_pair_byte0_fatal_context_pattern
        .type gk_track_pair_byte0_fatal_context_pattern,@function
gk_track_pair_byte0_fatal_context_pattern:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_pattern
        .size gk_track_pair_byte0_fatal_context_pattern,.-gk_track_pair_byte0_fatal_context_pattern
        .global gk_track_pair_byte0_fatal_context_part
        .type gk_track_pair_byte0_fatal_context_part,@function
gk_track_pair_byte0_fatal_context_part:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_part
        .size gk_track_pair_byte0_fatal_context_part,.-gk_track_pair_byte0_fatal_context_part
        .global gk_track_pair_byte0_fatal_context_bank_pointer
        .type gk_track_pair_byte0_fatal_context_bank_pointer,@function
gk_track_pair_byte0_fatal_context_bank_pointer:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_bank_pointer
        .size gk_track_pair_byte0_fatal_context_bank_pointer,.-gk_track_pair_byte0_fatal_context_bank_pointer
        .global gk_track_pair_byte0_fatal_context_assignment
        .type gk_track_pair_byte0_fatal_context_assignment,@function
gk_track_pair_byte0_fatal_context_assignment:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_assignment
        .size gk_track_pair_byte0_fatal_context_assignment,.-gk_track_pair_byte0_fatal_context_assignment
        .global gk_track_pair_byte0_fatal_context_transition
        .type gk_track_pair_byte0_fatal_context_transition,@function
gk_track_pair_byte0_fatal_context_transition:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_transition
        .size gk_track_pair_byte0_fatal_context_transition,.-gk_track_pair_byte0_fatal_context_transition
        .global gk_track_pair_byte0_fatal_context_runtime
        .type gk_track_pair_byte0_fatal_context_runtime,@function
gk_track_pair_byte0_fatal_context_runtime:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_runtime
        .size gk_track_pair_byte0_fatal_context_runtime,.-gk_track_pair_byte0_fatal_context_runtime
        .global gk_track_pair_byte0_fatal_context_workspace_absent
        .type gk_track_pair_byte0_fatal_context_workspace_absent,@function
gk_track_pair_byte0_fatal_context_workspace_absent:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_workspace_absent
        .size gk_track_pair_byte0_fatal_context_workspace_absent,.-gk_track_pair_byte0_fatal_context_workspace_absent
        .global gk_track_pair_byte0_fatal_context_workspace
        .type gk_track_pair_byte0_fatal_context_workspace,@function
gk_track_pair_byte0_fatal_context_workspace:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_workspace
        .size gk_track_pair_byte0_fatal_context_workspace,.-gk_track_pair_byte0_fatal_context_workspace
        .global gk_track_pair_byte0_fatal_context_kit_assignment
        .type gk_track_pair_byte0_fatal_context_kit_assignment,@function
gk_track_pair_byte0_fatal_context_kit_assignment:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_kit_assignment
        .size gk_track_pair_byte0_fatal_context_kit_assignment,.-gk_track_pair_byte0_fatal_context_kit_assignment
        .global gk_track_pair_byte0_fatal_context_descriptor_flags
        .type gk_track_pair_byte0_fatal_context_descriptor_flags,@function
gk_track_pair_byte0_fatal_context_descriptor_flags:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_descriptor_flags
        .size gk_track_pair_byte0_fatal_context_descriptor_flags,.-gk_track_pair_byte0_fatal_context_descriptor_flags
        .global gk_track_pair_byte0_fatal_context_descriptor_busy
        .type gk_track_pair_byte0_fatal_context_descriptor_busy,@function
gk_track_pair_byte0_fatal_context_descriptor_busy:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_descriptor_busy
        .size gk_track_pair_byte0_fatal_context_descriptor_busy,.-gk_track_pair_byte0_fatal_context_descriptor_busy
        .global gk_track_pair_byte0_fatal_context_descriptor_kit
        .type gk_track_pair_byte0_fatal_context_descriptor_kit,@function
gk_track_pair_byte0_fatal_context_descriptor_kit:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_descriptor_kit
        .size gk_track_pair_byte0_fatal_context_descriptor_kit,.-gk_track_pair_byte0_fatal_context_descriptor_kit
        .global gk_track_pair_byte0_fatal_context_descriptor_physical
        .type gk_track_pair_byte0_fatal_context_descriptor_physical,@function
gk_track_pair_byte0_fatal_context_descriptor_physical:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_descriptor_physical
        .size gk_track_pair_byte0_fatal_context_descriptor_physical,.-gk_track_pair_byte0_fatal_context_descriptor_physical
        .global gk_track_pair_byte0_fatal_context_sidecar
        .type gk_track_pair_byte0_fatal_context_sidecar,@function
gk_track_pair_byte0_fatal_context_sidecar:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_sidecar
        .size gk_track_pair_byte0_fatal_context_sidecar,.-gk_track_pair_byte0_fatal_context_sidecar
        .global gk_track_pair_byte0_fatal_context_physical_map
        .type gk_track_pair_byte0_fatal_context_physical_map,@function
gk_track_pair_byte0_fatal_context_physical_map:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_physical_map
        .size gk_track_pair_byte0_fatal_context_physical_map,.-gk_track_pair_byte0_fatal_context_physical_map
        .global gk_track_pair_byte0_fatal_context_transient
        .type gk_track_pair_byte0_fatal_context_transient,@function
gk_track_pair_byte0_fatal_context_transient:
        illegal
        bra.s gk_track_pair_byte0_fatal_context_transient
        .size gk_track_pair_byte0_fatal_context_transient,.-gk_track_pair_byte0_fatal_context_transient
        .global gk_track_pair_byte0_fatal_cleanup
        .type gk_track_pair_byte0_fatal_cleanup,@function
gk_track_pair_byte0_fatal_cleanup:
        illegal
        bra.s gk_track_pair_byte0_fatal_cleanup
        .size gk_track_pair_byte0_fatal_cleanup,.-gk_track_pair_byte0_fatal_cleanup
        .global gk_track_pair_byte0_fatal_workspace_consistency
        .type gk_track_pair_byte0_fatal_workspace_consistency,@function
gk_track_pair_byte0_fatal_workspace_consistency:
        illegal
        bra.s gk_track_pair_byte0_fatal_workspace_consistency
        .size gk_track_pair_byte0_fatal_workspace_consistency,.-gk_track_pair_byte0_fatal_workspace_consistency
        .global gk_track_pair_byte0_fatal_entry_track
        .type gk_track_pair_byte0_fatal_entry_track,@function
gk_track_pair_byte0_fatal_entry_track:
        illegal
        bra.s gk_track_pair_byte0_fatal_entry_track
        .size gk_track_pair_byte0_fatal_entry_track,.-gk_track_pair_byte0_fatal_entry_track
        .global gk_track_pair_byte0_fatal_entry_part
        .type gk_track_pair_byte0_fatal_entry_part,@function
gk_track_pair_byte0_fatal_entry_part:
        illegal
        bra.s gk_track_pair_byte0_fatal_entry_part
        .size gk_track_pair_byte0_fatal_entry_part,.-gk_track_pair_byte0_fatal_entry_part
        .global gk_track_pair_byte0_fatal_workspace_descriptor
        .type gk_track_pair_byte0_fatal_workspace_descriptor,@function
gk_track_pair_byte0_fatal_workspace_descriptor:
        illegal
        bra.s gk_track_pair_byte0_fatal_workspace_descriptor
        .size gk_track_pair_byte0_fatal_workspace_descriptor,.-gk_track_pair_byte0_fatal_workspace_descriptor
        .global gk_track_pair_byte0_fatal_workspace_busy
        .type gk_track_pair_byte0_fatal_workspace_busy,@function
gk_track_pair_byte0_fatal_workspace_busy:
        illegal
        bra.s gk_track_pair_byte0_fatal_workspace_busy
        .size gk_track_pair_byte0_fatal_workspace_busy,.-gk_track_pair_byte0_fatal_workspace_busy
        .global gk_track_pair_byte0_fatal_workspace_prepare
        .type gk_track_pair_byte0_fatal_workspace_prepare,@function
gk_track_pair_byte0_fatal_workspace_prepare:
        illegal
        bra.s gk_track_pair_byte0_fatal_workspace_prepare
        .size gk_track_pair_byte0_fatal_workspace_prepare,.-gk_track_pair_byte0_fatal_workspace_prepare
        .global gk_track_pair_byte0_fatal_physical_acquire
        .type gk_track_pair_byte0_fatal_physical_acquire,@function
gk_track_pair_byte0_fatal_physical_acquire:
        illegal
        bra.s gk_track_pair_byte0_fatal_physical_acquire
        .size gk_track_pair_byte0_fatal_physical_acquire,.-gk_track_pair_byte0_fatal_physical_acquire
        .global gk_track_pair_byte0_fatal_finish_token
        .type gk_track_pair_byte0_fatal_finish_token,@function
gk_track_pair_byte0_fatal_finish_token:
        illegal
        bra.s gk_track_pair_byte0_fatal_finish_token
        .size gk_track_pair_byte0_fatal_finish_token,.-gk_track_pair_byte0_fatal_finish_token
        .global gk_track_pair_byte0_fatal_mark_dirty
        .type gk_track_pair_byte0_fatal_mark_dirty,@function
gk_track_pair_byte0_fatal_mark_dirty:
        illegal
        bra.s gk_track_pair_byte0_fatal_mark_dirty
        .size gk_track_pair_byte0_fatal_mark_dirty,.-gk_track_pair_byte0_fatal_mark_dirty
        .global gk_track_pair_byte0_fatal_commit
        .type gk_track_pair_byte0_fatal_commit,@function
gk_track_pair_byte0_fatal_commit:
        illegal
        bra.s gk_track_pair_byte0_fatal_commit
        .size gk_track_pair_byte0_fatal_commit,.-gk_track_pair_byte0_fatal_commit
        .global gk_track_pair_byte0_fatal_no_write_release
        .type gk_track_pair_byte0_fatal_no_write_release,@function
gk_track_pair_byte0_fatal_no_write_release:
        illegal
        bra.s gk_track_pair_byte0_fatal_no_write_release
        .size gk_track_pair_byte0_fatal_no_write_release,.-gk_track_pair_byte0_fatal_no_write_release
        .global gk_track_pair_byte0_fatal_no_write_abort
        .type gk_track_pair_byte0_fatal_no_write_abort,@function
gk_track_pair_byte0_fatal_no_write_abort:
        illegal
        bra.s gk_track_pair_byte0_fatal_no_write_abort
        .size gk_track_pair_byte0_fatal_no_write_abort,.-gk_track_pair_byte0_fatal_no_write_abort
        .global gk_track_pair_byte0_fatal_post_context
        .type gk_track_pair_byte0_fatal_post_context,@function
gk_track_pair_byte0_fatal_post_context:
        illegal
        bra.s gk_track_pair_byte0_fatal_post_context
        .size gk_track_pair_byte0_fatal_post_context,.-gk_track_pair_byte0_fatal_post_context
        .global gk_track_pair_byte0_fatal_post_bank_pattern
        .type gk_track_pair_byte0_fatal_post_bank_pattern,@function
gk_track_pair_byte0_fatal_post_bank_pattern:
        illegal
        bra.s gk_track_pair_byte0_fatal_post_bank_pattern
        .size gk_track_pair_byte0_fatal_post_bank_pattern,.-gk_track_pair_byte0_fatal_post_bank_pattern
        .global gk_track_pair_byte0_fatal_post_part
        .type gk_track_pair_byte0_fatal_post_part,@function
gk_track_pair_byte0_fatal_post_part:
        illegal
        bra.s gk_track_pair_byte0_fatal_post_part
        .size gk_track_pair_byte0_fatal_post_part,.-gk_track_pair_byte0_fatal_post_part
        .global gk_track_pair_byte0_fatal_post_track
        .type gk_track_pair_byte0_fatal_post_track,@function
gk_track_pair_byte0_fatal_post_track:
        illegal
        bra.s gk_track_pair_byte0_fatal_post_track
        .size gk_track_pair_byte0_fatal_post_track,.-gk_track_pair_byte0_fatal_post_track
        .global gk_track_pair_byte0_fatal_final_release
        .type gk_track_pair_byte0_fatal_final_release,@function
gk_track_pair_byte0_fatal_final_release:
        illegal
        bra.s gk_track_pair_byte0_fatal_final_release
        .size gk_track_pair_byte0_fatal_final_release,.-gk_track_pair_byte0_fatal_final_release
        .global gk_track_pair_byte0_fatal_entry_id
        .type gk_track_pair_byte0_fatal_entry_id,@function
gk_track_pair_byte0_fatal_entry_id:
        illegal
        bra.s gk_track_pair_byte0_fatal_entry_id
        .size gk_track_pair_byte0_fatal_entry_id,.-gk_track_pair_byte0_fatal_entry_id
        .global gk_track_pair_byte0_fatal_entry_delta
        .type gk_track_pair_byte0_fatal_entry_delta,@function
gk_track_pair_byte0_fatal_entry_delta:
        illegal
        bra.s gk_track_pair_byte0_fatal_entry_delta
        .size gk_track_pair_byte0_fatal_entry_delta,.-gk_track_pair_byte0_fatal_entry_delta
        .global gk_track_pair_byte0_fatal_entry_lifecycle
        .type gk_track_pair_byte0_fatal_entry_lifecycle,@function
gk_track_pair_byte0_fatal_entry_lifecycle:
        illegal
        bra.s gk_track_pair_byte0_fatal_entry_lifecycle
        .size gk_track_pair_byte0_fatal_entry_lifecycle,.-gk_track_pair_byte0_fatal_entry_lifecycle
        .global gk_track_pair_byte0_fatal_marker_dirty
        .type gk_track_pair_byte0_fatal_marker_dirty,@function
gk_track_pair_byte0_fatal_marker_dirty:
        illegal
        bra.s gk_track_pair_byte0_fatal_marker_dirty
        .size gk_track_pair_byte0_fatal_marker_dirty,.-gk_track_pair_byte0_fatal_marker_dirty
        .global gk_track_pair_byte0_fatal_marker_return
        .type gk_track_pair_byte0_fatal_marker_return,@function
gk_track_pair_byte0_fatal_marker_return:
        illegal
        bra.s gk_track_pair_byte0_fatal_marker_return
        .size gk_track_pair_byte0_fatal_marker_return,.-gk_track_pair_byte0_fatal_marker_return
        .global gk_track_pair_byte0_fatal_marker_token
        .type gk_track_pair_byte0_fatal_marker_token,@function
gk_track_pair_byte0_fatal_marker_token:
        illegal
        bra.s gk_track_pair_byte0_fatal_marker_token
        .size gk_track_pair_byte0_fatal_marker_token,.-gk_track_pair_byte0_fatal_marker_token
        .global gk_track_pair_byte0_fatal_runtime_image
        .type gk_track_pair_byte0_fatal_runtime_image,@function
gk_track_pair_byte0_fatal_runtime_image:
        illegal
        bra.s gk_track_pair_byte0_fatal_runtime_image
        .size gk_track_pair_byte0_fatal_runtime_image,.-gk_track_pair_byte0_fatal_runtime_image
        .global gk_track_pair_byte0_fatal
        .type   gk_track_pair_byte0_fatal,@function
gk_track_pair_byte0_fatal:
        illegal
        bra.s   gk_track_pair_byte0_fatal
        .size   gk_track_pair_byte0_fatal,.-gk_track_pair_byte0_fatal
