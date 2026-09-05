        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_current_context_validate
        .type   gk_stock_current_context_validate,@function
gk_stock_current_context_validate:
        lea     -44(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        move.w  %sr,%d0
        move.w  %d0,40(%sp)
        moveq   #0,%d0
        move.b  __gk_ui_transition_pending,%d0
        cmpi.l  #1,%d0
        bhi.w gk_project_load_post_diag_transition_missing
        tst.l   %d0
        beq.w   .Lgk_stock_context_settled
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bls.s   .Lgk_stock_context_pending_descriptor_source
        cmpi.l  #GK_ID_NONE,%d0
        bne.w gk_project_load_post_diag_pending_descriptor
        move.l  __gk_ui_transition_reserved,%d0
        cmpi.l  #GK_UI_TRANSITION_STOCK_SOURCE_MAGIC,%d0
        bne.w gk_project_load_diag_persistence_marker
        bra.s   .Lgk_stock_context_pending_source_valid
.Lgk_stock_context_pending_descriptor_source:
        tst.l   __gk_ui_transition_reserved
        bne.w gk_project_load_diag_snapshot_gate
.Lgk_stock_context_pending_source_valid:
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_bank,%d0
        cmpi.l  #15,%d0
        bhi.w gk_project_load_diag_pending_bank_range
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_part,%d0
        cmpi.l  #3,%d0
        bhi.w gk_project_load_diag_current_part_range
        moveq   #0,%d2
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d2
        cmpi.l  #15,%d2
        bhi.w gk_project_load_diag_stock_bank_primary
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.w gk_project_load_diag_stock_bank_mirror
        moveq   #0,%d2
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d2
        cmpi.l  #15,%d2
        bhi.w gk_project_load_diag_pattern_primary
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d2,%d0
        bne.w gk_project_load_diag_pattern_mirror
        moveq   #0,%d2
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d2
        cmpi.l  #3,%d2
        bhi.w gk_project_load_diag_old_workspace_present
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d2,%d0
        bne.w gk_project_load_diag_current_part_mirror
        moveq   #0,%d0
        move.b  GK_STOCK_PART_EVENT_TEMPLATE,%d0
        cmpi.l  #GK_STOCK_PART_EVENT_ID,%d0
        bne.w gk_project_load_diag_transition_missing
        moveq   #0,%d0
        move.b  GK_STOCK_PART_EVENT_TEMPLATE + 1,%d0
        cmp.b   GK_STOCK_ENGINE_PART,%d0
        bne.w gk_project_load_diag_engine_part
        tst.b   __gk_sequencer_latch_queue_handoff
        beq.s   .Lgk_stock_context_pending_engine_committed
        bsr.w   gk_stock_staged_audio_handoff_validate
        tst.l   %d0
        bne.w gk_project_load_diag_descriptor_readers
        moveq   #0,%d1
        moveq   #GK_ERR_BUSY,%d0
        bra.w   .Lgk_stock_context_restore
.Lgk_stock_context_pending_engine_committed:
        lea     __gk_lease_sidecars,%a0
        jsr     gk_selector_acquire
        tst.l   %d0
        bmi.s   .Lgk_stock_context_pending_acquire_failed
        move.l  %d0,%d7
        bsr.w   gk_stock_latest_engine_context_validate
        move.l  %d0,%d6
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w gk_project_load_diag_lease_sidecars
        tst.l   %d6
        bmi.s   .Lgk_stock_context_pending_status
        moveq   #1,%d1
        bra.w   .Lgk_stock_context_pending_busy
.Lgk_stock_context_pending_acquire_failed:
        move.l  %d0,%d6
.Lgk_stock_context_pending_status:
        cmpi.l  #GK_ERR_BUSY,%d6
        bne.w gk_project_load_post_diag_runtime_flags
        moveq   #0,%d1
        bra.w   .Lgk_stock_context_pending_busy
.Lgk_stock_context_settled:
        moveq   #0,%d4
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d4
        cmpi.l  #15,%d4
        bhi.w gk_project_load_post_diag_lifecycle_state
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w gk_project_load_diag_engine_bank
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w gk_project_load_post_diag_engine_bank
        moveq   #0,%d5
        move.b  GK_STOCK_CURRENT_PATTERN,%d5
        cmpi.l  #15,%d5
        bhi.w gk_project_load_diag_pending_pattern_range
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w gk_project_load_post_diag_pending_pattern
        moveq   #0,%d6
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d6
        cmpi.l  #3,%d6
        bhi.w gk_project_load_diag_old_workspace_dirty
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d6,%d0
        bne.w gk_project_load_diag_dirty_descriptor_clean
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w gk_project_load_diag_clean_descriptor_dirty
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        .incbin "stock/0171.bin", 0, 6
        cmpa.l  %a2,%a0
        bne.w gk_project_load_diag_bank_pointer
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d6,%d1
        bne.w gk_project_load_post_diag_resident_assignment
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d6,%d1
        bne.w gk_project_load_post_diag_mirror_assignment
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        bne.w   .Lgk_stock_context_busy
        andi.l  #0x7e,%d0
        bne.w gk_project_load_diag_runtime_flags
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        cmpi.l  #GK_ID_NONE,%d7
        beq.w   .Lgk_stock_context_busy
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bhi.w gk_project_load_diag_pending_descriptor_range
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w gk_project_load_post_diag_pending_bank
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d5,%d0
        bne.s   .Lgk_stock_context_pattern_lagged
        tst.l   __gk_ui_transition_reserved
        beq.s   .Lgk_stock_context_pattern_settled
.Lgk_stock_context_pattern_lagged:
        jsr     gk_stock_carried_pattern_lag_validate
        bra.w   .Lgk_stock_context_restore
.Lgk_stock_context_pattern_settled:
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        cmp.l   %d2,%d1
        bne.w gk_project_load_diag_global_assignment
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a4
        adda.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a4),%d0
        move.l  %d0,%d1
        andi.l  #0x84,%d1
        bne.w gk_project_load_diag_descriptor_flags
        move.l  %d0,%d1
        andi.l  #0x62,%d1
        beq.s   .Lgk_stock_context_flags_stable
        cmpi.l  #GK_DESC_CLONE_COPY,%d1
        beq.w   .Lgk_stock_context_busy
        cmpi.l  #GK_DESC_PROMOTION_COPY,%d1
        beq.w   .Lgk_stock_context_busy
        bra.w gk_project_load_diag_pending_flags
.Lgk_stock_context_flags_stable:
        btst    #0,%d0
        beq.w gk_project_load_diag_descriptor_invalid
        btst    #3,%d0
        beq.w gk_project_load_diag_descriptor_roots
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a4),%d0
        cmp.l   %d2,%d0
        bne.w gk_project_load_diag_descriptor_kit
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a4),%d3
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w gk_project_load_diag_descriptor_spill
        move.l  %d3,%d0
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        bne.w gk_project_load_diag_physical_bank
        andi.l  #3,%d3
        cmp.l   %d6,%d3
        bne.w gk_project_load_diag_physical_part
        lea     __gk_lease_sidecars,%a5
        moveq   #0,%d0
        move.w  (%a5),%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.l   %d1,%d0
        bne.w gk_project_load_post_diag_lease_sidecar
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a4),%d0
        bsr.w   gk_physical_validate
        cmp.l   %d7,%d0
        bne.w gk_project_load_post_diag_physical_reverse_map
        move.l  %d4,%d0
        move.l  %d5,%d1
        bra.s   .Lgk_stock_context_restore
.Lgk_stock_context_busy:
        moveq   #0,%d1
.Lgk_stock_context_pending_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_stock_context_restore
.Lgk_stock_context_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_stock_context_restore:
        moveq   #0,%d2
        move.w  40(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     44(%sp),%sp
        rts
        .size   gk_stock_current_context_validate,.-gk_stock_current_context_validate
        .type   gk_stock_staged_audio_handoff_validate,@function
gk_stock_staged_audio_handoff_validate:
        lea     -16(%sp),%sp
        movem.l %d2-%d3/%a0-%a1,(%sp)
        jsr     gk_pattern_queue_audio_handoff_ready
        tst.l   %d0
        bmi.w gk_arranger_fatal_queued_owner
        move.l  %d0,%d3
        cmp.b   __gk_ui_transition_source_part,%d2
        beq.s   .Lgk_stock_staged_audio_foreground_part_valid
        cmp.b   GK_STOCK_SEQUENCER_LATCH_PART,%d2
        bne.w gk_arranger_fatal_active_scene_rollback_a
.Lgk_stock_staged_audio_foreground_part_valid:
        .incbin "stock/0172.bin", 0, 6
        andi.l  #0xffff00fd,%d0
        cmpi.l  #1,%d0
        bne.w gk_arranger_fatal_latch_trigger_pending
        cmp.b   __gk_pending_ui_capture_created,%d0
        bne.w gk_arranger_fatal_transition_adopt_abort
        moveq   #0,%d2
        move.b  __gk_ui_transition_source_descriptor,%d2
        cmp.b   __gk_workspace_descriptor,%d2
        bne.w gk_arranger_fatal_active_scene_rollback_terminal
        moveq   #0,%d0
        move.w  __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%d0
        move.l  %d2,%d1
        lsl.l   #8,%d1
        or.l    %d3,%d1
        cmp.l   %d1,%d0
        bne.w gk_arranger_fatal_latch_begin
        move.b  __gk_ui_transition_source_bank,%d0
        cmp.b   __gk_current_bank,%d0
        bne.w gk_arranger_fatal_queued_bank_range
        cmp.b   GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        bne.w gk_arranger_fatal_pattern_publish_owner
        cmp.b   GK_STOCK_ENGINE_BANK,%d0
        bne.w gk_arranger_fatal_latch_commit
        move.b  __gk_ui_transition_source_part,%d0
        cmp.b   GK_STOCK_ENGINE_PART,%d0
        bne.w gk_arranger_fatal_active_scene_rollback_b
        move.l  %d2,%d0
        lsl.l   #4,%d0
        lea     __gk_descriptors,%a0
        adda.l  %d0,%a0
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a0),%d0
        move.l  %d0,%d1
        andi.l  #0xe6,%d1
        bne.w gk_arranger_fatal_producer_state_clear
        btst    #0,%d0
        beq.w gk_arranger_fatal_playback_prepare_guard_enter
        btst    #3,%d0
        beq.w gk_arranger_fatal_playback_exit_guard
        tst.w   GK_DESC_ROOTS(%a0)
        beq.w gk_arranger_fatal_active_scene_release
        tst.w   GK_DESC_READERS(%a0)
        beq.w gk_arranger_fatal_abort_owner
        moveq   #0,%d1
        move.b  GK_DESC_PHYSICAL(%a0),%d1
        move.l  %d1,%d0
        lsr.l   #2,%d0
        cmp.b   __gk_ui_transition_source_bank,%d0
        bne.w gk_arranger_fatal_pattern_schedule_guard_enter
        andi.l  #3,%d1
        cmp.b   __gk_ui_transition_source_part,%d1
        bne.w gk_arranger_fatal_notify_guard_exit
        move.b  GK_DESC_KIT(%a0),%d0
        cmp.b   __gk_current_kit,%d0
        bne.w gk_arranger_fatal_queued_publish
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a0),%d0
        jsr     gk_physical_validate
        cmp.l   %d2,%d0
        bne.w gk_arranger_fatal_abort_matching
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.b   __gk_current_pattern,%d0
        beq.s   .Lgk_stock_staged_audio_pattern_valid
        cmp.b   __gk_pending_pattern,%d0
        bne.w gk_arranger_fatal_queued_pattern_range
.Lgk_stock_staged_audio_pattern_valid:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_stock_staged_audio_restore
.Lgk_stock_staged_audio_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_stock_staged_audio_restore:
        movem.l (%sp),%d2-%d3/%a0-%a1
        lea     16(%sp),%sp
        rts
        .size   gk_stock_staged_audio_handoff_validate,.-gk_stock_staged_audio_handoff_validate
        .global gk_stock_current_context_validate_or_resume
        .type   gk_stock_current_context_validate_or_resume,@function
gk_stock_current_context_validate_or_resume:
        .global gk_load_pattern_publish_guard
gk_load_pattern_publish_guard:
        tst.b   __gk_sequencer_latch_queue_handoff
        bne.s   .Lgk_stock_context_resume_pending_uncommitted
        bsr.w   gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        bne.s   .Lgk_stock_context_resume_return
        moveq   #0,%d0
        move.b  __gk_ui_transition_pending,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_stock_context_resume_promotion
        cmpi.l  #1,%d1
        beq.s   .Lgk_stock_context_resume_pending_ui
.Lgk_stock_context_resume_pending_uncommitted:
        moveq   #GK_ERR_BUSY,%d0
        rts
.Lgk_stock_context_resume_promotion:
        tst.l   __gk_ui_transition_reserved
        bne.s   .Lgk_stock_context_resume_pending_ui
        bsr.w   gk_workspace_resume_promotion
        tst.l   %d0
        beq.s   gk_stock_current_context_validate_or_resume
        cmpi.l  #GK_ERR_INVALID,%d0
        bne.s   .Lgk_stock_context_resume_return
        moveq   #GK_ERR_BUSY,%d0
.Lgk_stock_context_resume_return:
        rts
.Lgk_stock_context_resume_pending_ui:
        jsr     gk_ui_transition_context_retry_ensure
        tst.l   %d0
        bne.s   .Lgk_stock_context_resume_return
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_stock_current_context_validate_or_resume,.-gk_stock_current_context_validate_or_resume
        .global gk_stock_engine_context_validate
        .type   gk_stock_engine_context_validate,@function
gk_stock_engine_context_validate:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_stock_engine_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_stock_engine_range
        cmpi.l  #3,%d2
        bhi.w   .Lgk_stock_engine_range
        .incbin "stock/0173.bin", 0, 4
        .incbin "stock/0173.bin", 4, 4
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %d2,%d6
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_stock_engine_corrupt
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        .incbin "stock/0174.bin", 0, 6
        cmpa.l  %a2,%a0
        bne.w   .Lgk_stock_engine_corrupt
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_stock_engine_corrupt
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        andi.l  #0xfe,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bhi.w   .Lgk_stock_engine_corrupt
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a4
        adda.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a4),%d0
        move.l  %d0,%d1
        andi.l  #0xe6,%d1
        bne.w   .Lgk_stock_engine_corrupt
        btst    #0,%d0
        beq.w   .Lgk_stock_engine_corrupt
        btst    #3,%d0
        beq.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a4),%d3
        move.l  %d3,%d0
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_engine_corrupt
        andi.l  #3,%d3
        cmp.l   %d6,%d3
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a4),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_stock_engine_corrupt
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        cmp.l   %d2,%d1
        bne.w   .Lgk_stock_engine_corrupt
        lea     __gk_lease_sidecars,%a5
        moveq   #0,%d0
        move.w  (%a5),%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a4),%d0
        bsr.w   gk_physical_validate
        cmp.l   %d7,%d0
        bne.w   .Lgk_stock_engine_corrupt
        moveq   #GK_OK,%d0
        bra.s   .Lgk_stock_engine_restore
.Lgk_stock_engine_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_stock_engine_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
.Lgk_stock_engine_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_stock_engine_context_validate,.-gk_stock_engine_context_validate
        .global gk_stock_load_kit_transaction
        .type   gk_stock_load_kit_transaction,@function
gk_stock_load_kit_transaction:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_stock_load_transaction_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_stock_load_transaction_range
        cmpi.l  #GK_KIT_COUNT,%d2
        bhi.w   .Lgk_stock_load_transaction_range
        .incbin "stock/0175.bin", 0, 4
        .incbin "stock/0175.bin", 4, 4
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %d2,%d6
        suba.l  %a5,%a5
        cmpi.l  #GK_KIT_COUNT,%d6
        bne.s   .Lgk_stock_load_target_ready
        tst.b   __gk_undo_kit_valid
        beq.w   .Lgk_stock_load_transaction_invalid
        moveq   #0,%d0
        move.b  __gk_undo_kit_bound,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_stock_load_transaction_corrupt
        moveq   #0,%d6
        move.b  __gk_undo_kit_kit,%d6
        moveq   #1,%d0
        movea.l %d0,%a5
.Lgk_stock_load_target_ready:
        move.l  %d4,-(%sp)
        move.l  %d5,-(%sp)
        .global gk_stock_pattern_has_content_call
gk_stock_pattern_has_content_call:
        jsr     GK_STOCK_PATTERN_HAS_CONTENT
        addq.l  #8,%sp
        cmpi.l  #1,%d0
        bhi.w   .Lgk_stock_load_transaction_corrupt
        move.l  %d0,%a6
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        tst.l   %a5
        beq.s   .Lgk_stock_load_prepare_normal
        moveq   #GK_TRANSITION_UNDO_PREPARE_FLAGS,%d3
        bra.s   .Lgk_stock_load_prepare_ready
.Lgk_stock_load_prepare_normal:
        moveq   #GK_TRANSITION_PREPARE_FLAGS,%d3
.Lgk_stock_load_prepare_ready:
        bsr.w   gk_workspace_prepare
        tst.l   %d0
        bmi.w   .Lgk_stock_load_transaction_restore
        move.l  %d0,%a2
        move.l  %d1,%d7
        .global gk_load_kit_mirror_sync_start
gk_load_kit_mirror_sync_start:
        move.l  %d7,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a1
        adda.l  %d0,%a1
        jsr     gk_copy_payload_interruptible
        .global gk_load_kit_mirror_sync_end
gk_load_kit_mirror_sync_end:
        move.l  %a2,%d0
        bsr.w   gk_ui_transition_prepare
        tst.l   %d0
        bmi.w   .Lgk_stock_load_transaction_capture_failed
        move.l  %d7,-(%sp)
        .global gk_load_kit_stock_setter_call
gk_load_kit_stock_setter_call:
        jsr     GK_STOCK_CURRENT_PATTERN_PART_SET
        .global gk_load_kit_stock_setter_return
gk_load_kit_stock_setter_return:
        addq.l  #4,%sp
        tst.l   %a5
        beq.s   .Lgk_stock_load_undo_staged
        jsr     gk_undo_kit_mark_pending_dirty
        tst.l   %d0
        bmi.w   .Lgk_stock_load_transaction_restore
.Lgk_stock_load_undo_staged:
        tst.l   %a6
        bne.s   .Lgk_stock_load_transaction_commit_assigned
        bsr.w   gk_stock_load_kit_commit_unassigned
        bra.s   .Lgk_stock_load_transaction_commit_done
.Lgk_stock_load_transaction_commit_assigned:
        bsr.w   gk_workspace_commit_update
.Lgk_stock_load_transaction_commit_done:
        tst.l   %d0
        bne.s   .Lgk_stock_load_transaction_restore
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d7,%d2
        .global gk_load_kit_transition_validate_call
gk_load_kit_transition_validate_call:
        jsr     gk_stock_engine_context_validate_and_retry
.Lgk_stock_load_transaction_capture_failed:
        move.l  %d0,%d3
        bsr.w   gk_workspace_abort_update
        tst.l   %d0
        bne.s   .Lgk_stock_load_transaction_corrupt
        move.l  %d3,%d0
        bra.s   .Lgk_stock_load_transaction_restore
.Lgk_stock_load_transaction_invalid:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_stock_load_transaction_restore
.Lgk_stock_load_transaction_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        .global gk_stock_load_transaction_restore
gk_stock_load_transaction_restore:
.Lgk_stock_load_transaction_restore:
        .incbin "stock/0176.bin", 0, 4
        .incbin "stock/0176.bin", 4, 4
        .incbin "stock/0176.bin", 8, 2
.Lgk_stock_load_transaction_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_stock_load_kit_transaction,.-gk_stock_load_kit_transaction
        .align  4
        .global gk_stock_load_kit_commit_unassigned
        .type   gk_stock_load_kit_commit_unassigned,@function
gk_stock_load_kit_commit_unassigned:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        moveq   #0,%d2
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   .Lgk_stock_load_unassigned_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_load_unassigned_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_stock_load_unassigned_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_kit,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_stock_load_unassigned_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_bound,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_stock_load_unassigned_corrupt
        moveq   #0,%d3
        move.b  __gk_pending_transition_flags,%d3
        btst    #1,%d3
        beq.w   .Lgk_stock_load_unassigned_corrupt
        move.l  %d3,%d0
        bclr    #1,%d0
        move.b  %d0,__gk_pending_transition_flags
        bsr.w   gk_workspace_commit_update
        tst.l   %d0
        bne.s   .Lgk_stock_load_unassigned_commit_failed
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        move.b  %d6,(%a0,%d0.l)
        move.l  %d0,%d3
        lsr.l   #3,%d0
        andi.l  #7,%d3
        lea     __gk_pattern_assignment_valid,%a1
        btst    %d3,(%a1,%d0.l)
        beq.s   .Lgk_stock_load_unassigned_clean
        bclr    %d3,(%a1,%d0.l)
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        ori.l   #GK_RUNTIME_STORAGE_DIRTY,%d0
        move.b  %d0,__gk_runtime_flags
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        move.l  %d6,%d1
        .global gk_pattern_unassignment_v3_dirty_call
gk_pattern_unassignment_v3_dirty_call:
        jsr     gk_persistence_v3_mark_assignment_dirty
.Lgk_stock_load_unassigned_clean:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_stock_load_unassigned_restore
.Lgk_stock_load_unassigned_commit_failed:
        move.b  %d3,__gk_pending_transition_flags
        bra.s   .Lgk_stock_load_unassigned_restore
.Lgk_stock_load_unassigned_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_stock_load_unassigned_restore:
        move.w  %d2,%sr
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts
        .size   gk_stock_load_kit_commit_unassigned,.-gk_stock_load_kit_commit_unassigned
        .align  4
        .global gk_stock_pattern_clear_unassign_empty
        .type   gk_stock_pattern_clear_unassign_empty,@function
gk_stock_pattern_clear_unassign_empty:
        .incbin "stock/0177.bin", 0, 4
        .incbin "stock/0177.bin", 4, 4
        move.l  24(%sp),%d2
        cmpi.l  #15,%d2
        bhi.w   .Lgk_pattern_clear_unassign_restore_stock
        moveq   #0,%d3
        move.b  __gk_current_bank,%d3
        cmpi.l  #15,%d3
        bhi.w   .Lgk_pattern_clear_unassign_restore_stock
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_pattern_clear_unassign_restore_stock
        move.l  %d2,-(%sp)
        .global gk_stock_pattern_clear_call
gk_stock_pattern_clear_call:
        .incbin "stock/0178.bin", 0, 6
        addq.l  #4,%sp
        move.l  %d0,%d4
        move.l  %d3,-(%sp)
        move.l  %d2,-(%sp)
        .global gk_empty_pattern_clear_has_content_call
gk_empty_pattern_clear_has_content_call:
        jsr     GK_STOCK_PATTERN_HAS_CONTENT
        addq.l  #8,%sp
        tst.l   %d0
        bne.s   .Lgk_pattern_clear_unassign_return_stock
        lsl.l   #4,%d3
        add.l   %d2,%d3
        move.l  %d3,%d5
        move.l  %d5,%d2
        andi.l  #7,%d2
        lea     __gk_pattern_assignment_valid,%a2
        move.w  %sr,%d3
        move.w  #0x2700,%sr
        move.l  %d5,%d0
        lsr.l   #3,%d0
        btst    %d2,(%a2,%d0.l)
        beq.s   .Lgk_pattern_clear_unassign_restore_sr
        bclr    %d2,(%a2,%d0.l)
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        ori.l   #GK_RUNTIME_STORAGE_DIRTY,%d0
        move.b  %d0,__gk_runtime_flags
        moveq   #0,%d1
        lea     __gk_pattern_assignments,%a2
        move.b  (%a2,%d5.l),%d1
        move.l  %d5,%d0
        .global gk_pattern_clear_unassignment_v3_dirty_call
gk_pattern_clear_unassignment_v3_dirty_call:
        jsr     gk_persistence_v3_mark_assignment_dirty
.Lgk_pattern_clear_unassign_restore_sr:
        move.w  %d3,%sr
.Lgk_pattern_clear_unassign_return_stock:
        move.l  %d4,%d0
        bra.s   .Lgk_pattern_clear_unassign_restore
.Lgk_pattern_clear_unassign_restore_stock:
        move.l  %d2,-(%sp)
        .incbin "stock/0179.bin", 0, 6
        addq.l  #4,%sp
.Lgk_pattern_clear_unassign_restore:
        movem.l (%sp),%d2-%d5/%a2
        lea     20(%sp),%sp
        rts
        .size   gk_stock_pattern_clear_unassign_empty,.-gk_stock_pattern_clear_unassign_empty
        .global gk_load_kit_menu_active
        .type   gk_load_kit_menu_active,@function
gk_load_kit_menu_active:
        jsr     gk_kit_list_context_owned
        cmpi.l  #GK_UI_MODE_LOAD,%d0
        bne.s   .Lgk_load_menu_not_active
        rts
.Lgk_load_menu_not_active:
        moveq   #0,%d0
        rts
        .size   gk_load_kit_menu_active,.-gk_load_kit_menu_active
        .global gk_load_kit_menu_open
        .type   gk_load_kit_menu_open,@function
gk_load_kit_menu_open:
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        tst.l   GK_STOCK_CALLBACK_MENU_OBJECT
        beq.s   .Lgk_load_menu_allocate
        bsr.w   gk_load_kit_menu_active
        tst.l   %d0
        beq.s   .Lgk_load_menu_allocate
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE
        clr.b   __gk_ui_mode
        moveq   #GK_OK,%d0
        rts
.Lgk_load_menu_allocate:
        .incbin "stock/0180.bin", 0, 4
        .incbin "stock/0180.bin", 4, 4
        bsr.w   gk_stock_current_context_validate_or_resume
        tst.l   %d0
        bmi.w   .Lgk_load_menu_restore
        move.l  %d0,%d4
        move.l  %d1,%d5
        lea     gk_load_kit_menu_confirm,%a0
        bsr.w   gk_ui_prepare_kit_tables
        tst.l   %d0
        bne.w   .Lgk_load_menu_restore
        movea.l %a0,%a2
        movea.l %a1,%a3
        moveq   #0,%d6
        move.b  __gk_current_kit,%d6
        move.b  %d4,__gk_ui_context_bank
        move.b  %d5,__gk_ui_context_pattern
        move.b  %d6,__gk_ui_context_kit
        moveq   #GK_UI_MODE_LOAD,%d0
        move.b  %d0,__gk_ui_mode
        move.l  %a3,-(%sp)
        move.l  %a2,-(%sp)
        pea     __gk_ui_selected_row
        move.l  __gk_ui_selected_row,-(%sp)
        pea     (GK_KIT_COUNT + 1).w
        .global gk_load_kit_stock_menu_call
gk_load_kit_stock_menu_call:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_OPEN
        lea     20(%sp),%sp
        moveq   #GK_OK,%d0
.Lgk_load_menu_restore:
        .incbin "stock/0181.bin", 0, 4
        .incbin "stock/0181.bin", 4, 4
        .incbin "stock/0181.bin", 8, 2
.Lgk_load_menu_busy_fast:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_load_kit_menu_open,.-gk_load_kit_menu_open
        .global gk_load_kit_menu_confirm
        .type   gk_load_kit_menu_confirm,@function
gk_load_kit_menu_confirm:
        .incbin "stock/0182.bin", 0, 4
        .incbin "stock/0182.bin", 4, 4
        .global gk_load_confirm_pattern_interlock_begin
gk_load_confirm_pattern_interlock_begin:
        move.w  %sr,%d7
        move.w  #0x2200,%sr
        .global gk_load_confirm_pattern_interlock_armed
gk_load_confirm_pattern_interlock_armed:
        moveq   #0,%d0
        move.b  __gk_ui_mode,%d0
        cmpi.l  #GK_UI_MODE_LOAD,%d0
        bne.w   .Lgk_load_confirm_invalid
        move.l  __gk_ui_selected_row,%d6
        cmpi.l  #GK_KIT_COUNT,%d6
        bhi.w   .Lgk_load_confirm_range
        .global gk_load_confirm_context_validate_call
gk_load_confirm_context_validate_call:
        bsr.w   gk_stock_current_context_validate_or_resume
        tst.l   %d0
        bmi.w   .Lgk_load_confirm_finish
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d0
        move.b  __gk_ui_context_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_load_confirm_corrupt
        moveq   #0,%d0
        move.b  __gk_ui_context_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_load_confirm_corrupt
        tst.l   %d6
        beq.s   .Lgk_load_confirm_undo_row
        subq.l  #1,%d6
        bra.s   .Lgk_load_confirm_target_ready
.Lgk_load_confirm_undo_row:
        move.l  #GK_KIT_COUNT,%d6
.Lgk_load_confirm_target_ready:
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        moveq   #0,%d0
        move.b  __gk_ui_context_kit,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_load_confirm_corrupt
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        bsr.w   gk_stock_load_kit_transaction
        bra.s   .Lgk_load_confirm_finish
.Lgk_load_confirm_invalid:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_load_confirm_finish
.Lgk_load_confirm_range:
        moveq   #GK_ERR_RANGE,%d0
        bra.s   .Lgk_load_confirm_finish
.Lgk_load_confirm_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_load_confirm_finish:
        clr.b   __gk_ui_mode
        .global gk_load_confirm_pattern_interlock_release
gk_load_confirm_pattern_interlock_release:
        move.w  %d7,%sr
        .incbin "stock/0183.bin", 0, 4
        .incbin "stock/0183.bin", 4, 4
        .incbin "stock/0183.bin", 8, 2
        .size   gk_load_kit_menu_confirm,.-gk_load_kit_menu_confirm
        .global gk_stock_part_status_format
        .type   gk_stock_part_status_format,@function
gk_stock_part_status_format:
        move.l  %a6,%d2
        addi.l  #-0x58,%d2
        lea     GK_STOCK_STRING_FORMAT,%a3
        movea.l %d2,%a0
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_part_status_ephemeral
        tst.b   __gk_workspace_bound
        beq.s   .Lgk_part_status_ephemeral
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        addq.l  #1,%d0
        moveq   #0,%d1
.Lgk_part_status_hundreds:
        cmpi.l  #100,%d0
        blo.s   .Lgk_part_status_hundreds_done
        subi.l  #100,%d0
        addq.l  #1,%d1
        bra.s   .Lgk_part_status_hundreds
.Lgk_part_status_hundreds_done:
        addi.l  #0x30,%d1
        move.b  %d1,(%a0)+
        moveq   #0,%d1
.Lgk_part_status_tens:
        cmpi.l  #10,%d0
        blo.s   .Lgk_part_status_tens_done
        subi.l  #10,%d0
        addq.l  #1,%d1
        bra.s   .Lgk_part_status_tens
.Lgk_part_status_tens_done:
        addi.l  #0x30,%d1
        move.b  %d1,(%a0)+
        addi.l  #0x30,%d0
        move.b  %d0,(%a0)+
        move.b  #0x20,(%a0)+
        lea     __gk_workspace_name,%a1
        tst.b   (%a1)
        bne.s   .Lgk_part_status_name_ready
        lea     .Lgk_part_status_default_name,%a1
.Lgk_part_status_name_ready:
        moveq   #GK_KIT_VISIBLE_NAME_SIZE,%d1
.Lgk_part_status_name_loop:
        moveq   #0,%d0
        move.b  (%a1)+,%d0
        beq.s   .Lgk_part_status_done
        move.b  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_part_status_name_loop
        bra.s   .Lgk_part_status_done
.Lgk_part_status_ephemeral:
        lea     .Lgk_part_status_ephemeral_text,%a1
.Lgk_part_status_ephemeral_loop:
        move.b  (%a1)+,(%a0)+
        bne.s   .Lgk_part_status_ephemeral_loop
        .global gk_part_status_ephemeral_continue_jump
gk_part_status_ephemeral_continue_jump:
        jmp     GK_STOCK_PART_STATUS_CONTINUE
.Lgk_part_status_done:
        clr.b   (%a0)
        .global gk_part_status_bound_continue_jump
gk_part_status_bound_continue_jump:
        jmp     GK_STOCK_PART_STATUS_CONTINUE
        .size   gk_stock_part_status_format,.-gk_stock_part_status_format
        .global gk_stock_reload_shortcut_format
        .type   gk_stock_reload_shortcut_format,@function
gk_stock_reload_shortcut_format:
        movea.l %a6,%a0
        adda.l  #-0x20,%a0
        lea     .Lgk_reload_message_save_first,%a1
        tst.l   %d0
        beq.s   .Lgk_reload_message_copy
        lea     .Lgk_reload_message_success,%a1
.Lgk_reload_message_copy:
        move.b  (%a1)+,(%a0)+
        bne.s   .Lgk_reload_message_copy
        .global gk_reload_shortcut_continue_jump
gk_reload_shortcut_continue_jump:
        jmp     GK_STOCK_RELOAD_SHORTCUT_FORMAT_CONTINUE
        .size   gk_stock_reload_shortcut_format,.-gk_stock_reload_shortcut_format
        .global gk_stock_relative_control_dispatch
        .type   gk_stock_relative_control_dispatch,@function
gk_stock_relative_control_dispatch:
        move.l  4(%sp),%d0
        cmpi.l  #6,%d0
        bne.w   .Lgk_relative_control_stock
        jsr     gk_kit_list_context_owned
        tst.l   %d0
        beq.w   .Lgk_relative_control_stock
        move.l  8(%sp),%d1
        beq.s   .Lgk_relative_control_done
        move.l  %d2,-(%sp)
        move.l  %d1,%d2
        .incbin "stock/0184.bin", 0, 4
        .incbin "stock/0184.bin", 4, 6
        .incbin "stock/0184.bin", 10, 2
        .incbin "stock/0184.bin", 12, 2
        .incbin "stock/0184.bin", 14, 2
        .incbin "stock/0184.bin", 16, 1
        .incbin "stock/0185.bin", 0, 1
        .incbin "stock/0185.bin", 1, 2
        .incbin "stock/0185.bin", 3, 2
        .incbin "stock/0185.bin", 5, 2
.Lgk_relative_control_scaled:
        tst.l   %d2
        bmi.s   .Lgk_relative_control_up
.Lgk_relative_control_down_loop:
        pea     GK_STOCK_CALLBACK_MENU_STATE
        .global gk_relative_control_stock_down_call
gk_relative_control_stock_down_call:
        jsr     GK_STOCK_CALLBACK_MENU_SCROLL_DOWN
        addq.l  #4,%sp
        subq.l  #1,%d2
        bne.s   .Lgk_relative_control_down_loop
.Lgk_relative_control_restore:
        move.l  (%sp)+,%d2
        .global gk_relative_control_stock_refresh_call
gk_relative_control_stock_refresh_call:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_REFRESH
.Lgk_relative_control_done:
        rts
.Lgk_relative_control_up:
        neg.l   %d2
.Lgk_relative_control_up_loop:
        pea     GK_STOCK_CALLBACK_MENU_STATE
        .global gk_relative_control_stock_up_call
gk_relative_control_stock_up_call:
        jsr     GK_STOCK_CALLBACK_MENU_SCROLL_UP
        addq.l  #4,%sp
        subq.l  #1,%d2
        bne.s   .Lgk_relative_control_up_loop
        bra.s   .Lgk_relative_control_restore
.Lgk_relative_control_stock:
        .global gk_relative_control_stock_dispatch_jump
gk_relative_control_stock_dispatch_jump:
        jmp     GK_STOCK_RELATIVE_CONTROL_DISPATCH
        .size   gk_stock_relative_control_dispatch,.-gk_stock_relative_control_dispatch
        .align  2
.Lgk_part_status_default_name:
        .ascii  "NEW KIT "
.Lgk_part_status_ephemeral_text:
        .asciz  "--- NEW KIT"
.Lgk_reload_message_success:
        .byte 0x4b,0x49,0x54
        .incbin "stock/0186.bin", 0, 10
.Lgk_reload_message_save_first:
        .incbin "stock/0187.bin", 0, 4
        .byte 0x20,0x4b,0x49,0x54
        .incbin "stock/0188.bin", 0, 8
