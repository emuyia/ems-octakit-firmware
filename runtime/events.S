        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_latest_engine_context_validate
        .type   gk_stock_latest_engine_context_validate,@function
gk_stock_latest_engine_context_validate:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_latest_range
        .incbin "stock/0083.bin", 0, 4
        .incbin "stock/0083.bin", 4, 4
        move.l  %d0,%d7
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_latest_corrupt
        btst    #7,%d0
        bne.w   .Lgk_latest_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_latest_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_latest_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_latest_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_latest_corrupt
        moveq   #0,%d3
        move.b  __gk_current_bank,%d3
        cmpi.l  #15,%d3
        bhi.w   .Lgk_latest_corrupt
        moveq   #0,%d4
        move.b  __gk_current_pattern,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_latest_corrupt
        moveq   #0,%d5
        move.b  __gk_current_kit,%d5
        moveq   #0,%d6
        move.b  GK_STOCK_ENGINE_PART,%d6
        cmpi.l  #3,%d6
        bhi.w   .Lgk_latest_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_latest_corrupt
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0x84,%d1
        bne.w   .Lgk_latest_corrupt
        move.l  %d0,%d1
        andi.l  #0x62,%d1
        beq.s   .Lgk_latest_flags_stable
        cmpi.l  #GK_DESC_CLONE_COPY,%d1
        beq.w   .Lgk_latest_busy
        cmpi.l  #GK_DESC_PROMOTION_COPY,%d1
        beq.w   .Lgk_latest_busy
        bra.w   .Lgk_latest_corrupt
.Lgk_latest_flags_stable:
        btst    #0,%d0
        beq.w   .Lgk_latest_corrupt
        btst    #3,%d0
        beq.w   .Lgk_latest_corrupt
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_latest_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_latest_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a2),%d1
        cmpi.l  #GK_ID_NONE,%d1
        bne.w   .Lgk_latest_corrupt
        moveq   #0,%d1
        move.w  GK_DESC_ROOTS(%a2),%d1
        cmpi.l  #2,%d1
        blo.w   .Lgk_latest_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_KIT(%a2),%d1
        cmp.l   %d5,%d1
        bne.w   .Lgk_latest_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_PHYSICAL(%a2),%d1
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_latest_corrupt
        move.l  %d1,%d2
        lsr.l   #2,%d2
        cmp.l   %d3,%d2
        bne.w   .Lgk_latest_corrupt
        andi.l  #3,%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_latest_corrupt
        moveq   #0,%d1
        move.b  __gk_workspace_dirty,%d1
        cmpi.l  #1,%d1
        bhi.w   .Lgk_latest_corrupt
        tst.l   %d1
        beq.s   .Lgk_latest_expect_clean
        btst    #4,%d0
        beq.w   .Lgk_latest_corrupt
        bra.s   .Lgk_latest_dirty_ok
.Lgk_latest_expect_clean:
        btst    #4,%d0
        bne.w   .Lgk_latest_corrupt
.Lgk_latest_dirty_ok:
        lea     __gk_lease_sidecars,%a0
        moveq   #0,%d0
        move.w  (%a0),%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_latest_busy
        move.l  %d3,%d0
        lsl.l   #4,%d0
        add.l   %d4,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        cmp.l   %d5,%d1
        bne.w   .Lgk_latest_corrupt
        move.l  %d3,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        adda.l  %d0,%a3
        move.l  %d4,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d0
        move.b  (%a3),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_latest_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        bsr.w   gk_physical_validate
        cmp.l   %d7,%d0
        bne.w   .Lgk_latest_corrupt
        move.l  %d3,%d0
        move.l  %d4,%d1
        movea.l %d6,%a0
        bra.s   .Lgk_latest_restore
.Lgk_latest_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_latest_restore
.Lgk_latest_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_latest_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
.Lgk_latest_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_stock_latest_engine_context_validate,.-gk_stock_latest_engine_context_validate
        .global gk_ui_transition_prepare
        .type   gk_ui_transition_prepare,@function
gk_ui_transition_prepare:
        .global gk_ui_transition_prepare_entry_patch
gk_ui_transition_prepare_entry_patch:
        jmp     gk_ui_transition_prepare_entry_release
        .global gk_ui_transition_prepare_after_entry_compare
gk_ui_transition_prepare_after_entry_compare:
        bhi.w   .Lgk_ui_transition_prepare_range
        .incbin "stock/0084.bin", 0, 4
        .incbin "stock/0084.bin", 4, 4
        move.l  %d0,%d7
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   .Lgk_ui_transition_prepare_busy
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        move.l  %d0,%d1
        andi.l  #0xe8,%d1
        bne.w   .Lgk_ui_transition_prepare_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_ID_NONE,%d6
        beq.w   .Lgk_ui_transition_prepare_ok
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   .Lgk_ui_transition_prepare_corrupt
        cmp.l   %d7,%d6
        beq.w   .Lgk_ui_transition_prepare_ok
        moveq   #0,%d0
        move.b  __gk_ui_transition_pending,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_ui_transition_prepare_corrupt
        tst.l   %d0
        beq.s   .Lgk_ui_transition_prepare_capture
        .global gk_ui_transition_prepare_pending_snapshot_patch
gk_ui_transition_prepare_pending_snapshot_patch:
        jmp     gk_ui_transition_prepare_pending_snapshot_release
        .global gk_audio_periodic_queue_handoff_begin
        .type   gk_audio_periodic_queue_handoff_begin,@function
gk_audio_periodic_queue_handoff_begin:
        movea.l %a0,%a2
        move.l  %d0,%d6
        bsr.w   gk_selector_begin_physical
        btst    #1,%d0
        beq.s   .Lgk_audio_periodic_handoff_begin_return
        bsr.w   gk_audio_periodic_queue_handoff_validate
        tst.l   %d0
        bne.s   .Lgk_audio_periodic_handoff_begin_return
        movea.l %a2,%a0
        bsr.w   gk_selector_invalidate
.Lgk_audio_periodic_handoff_begin_return:
        rts
        .size   gk_audio_periodic_queue_handoff_begin,.-gk_audio_periodic_queue_handoff_begin
        .global gk_audio_periodic_queue_handoff_commit
        .type   gk_audio_periodic_queue_handoff_commit,@function
gk_audio_periodic_queue_handoff_commit:
        move.l  %d0,%d2
        bsr.w   gk_selector_commit_physical_part
        tst.l   %d0
        beq.s   .Lgk_audio_periodic_handoff_commit_return
        cmpi.b  #GK_ERR_BUSY,%d0
        bne.s   .Lgk_audio_periodic_handoff_commit_return
        bsr.w   gk_periodic_queue_handoff_current_validate
        tst.l   %d0
        bne.s   .Lgk_audio_periodic_handoff_commit_return
        move.b  %d2,(%a1)
        moveq   #GK_OK,%d0
.Lgk_audio_periodic_handoff_commit_return:
        rts
        .size   gk_audio_periodic_queue_handoff_commit,.-gk_audio_periodic_queue_handoff_commit
        .global gk_audio_periodic_queue_handoff_begin_or_defer
        .type   gk_audio_periodic_queue_handoff_begin_or_defer,@function
gk_audio_periodic_queue_handoff_begin_or_defer:
        bsr.w   gk_audio_periodic_queue_handoff_begin
        cmpi.b  #GK_ERR_BUSY,%d0
        bne.s   .Lgk_periodic_busy_defer_return
        tst.l   __gk_lifecycle_state
        bne.s   .Lgk_periodic_busy_defer_return
        cmpa.l  #__gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a2
        blo.s   .Lgk_periodic_busy_defer_voice
        lea     68(%sp),%sp
        jmp     GK_STOCK_AUDIO_PERIODIC_TRACK_SKIP
.Lgk_periodic_busy_defer_voice:
        move.l  32(%sp),%d7
        lea     64(%sp),%sp
        jmp     GK_STOCK_VOICE_PENDING_PERIODIC_TRACK_SKIP
.Lgk_periodic_busy_defer_return:
        rts
        .size   gk_audio_periodic_queue_handoff_begin_or_defer,.-gk_audio_periodic_queue_handoff_begin_or_defer
        .global gk_ui_transition_prepare_capture
gk_ui_transition_prepare_capture:
.Lgk_ui_transition_prepare_capture:
        move.l %d6,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d2
        move.b  GK_DESC_FLAGS(%a2),%d2
        move.l  %d2,%d0
        andi.l  #0xe6,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        btst    #0,%d2
        beq.w   .Lgk_ui_transition_prepare_corrupt
        btst    #3,%d2
        beq.w   .Lgk_ui_transition_prepare_corrupt
        movea.l GK_DESC_PAYLOAD(%a2),%a3
        tst.l   %a3
        beq.w   .Lgk_ui_transition_prepare_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d5
        move.b  GK_DESC_PHYSICAL(%a2),%d5
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d5
        bhi.w   .Lgk_ui_transition_prepare_corrupt
        move.l  %d5,%d4
        lsr.l   #2,%d4
        move.l  %d5,%d3
        andi.l  #3,%d3
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        beq.s   .Lgk_ui_transition_prepare_source_bank_visible
        jsr     gk_ui_transition_cross_bank_playback_validate
        tst.l   %d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        bset    #7,%d2
        bra.s   .Lgk_ui_transition_prepare_bank_valid
.Lgk_ui_transition_prepare_source_bank_visible:
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
.Lgk_ui_transition_prepare_bank_valid:
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        btst    #7,%d2
        beq.s   .Lgk_ui_transition_prepare_source_part_visible
        cmpi.l  #3,%d0
        bhi.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        cmp.l   %d3,%d0
        beq.s   .Lgk_ui_transition_prepare_part_visible
        bset    #5,%d2
        bra.s   .Lgk_ui_transition_prepare_part_visible
.Lgk_ui_transition_prepare_source_part_visible:
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
.Lgk_ui_transition_prepare_part_visible:
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d5
        move.b  GK_STOCK_CURRENT_PATTERN,%d5
        cmpi.l  #15,%d5
        bhi.w   .Lgk_ui_transition_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        btst    #7,%d2
        beq.s   .Lgk_ui_transition_prepare_pattern_visible
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d5,%d0
        beq.s   .Lgk_ui_transition_prepare_pattern_visible
        cmp.b   __gk_pending_pattern,%d5
        bne.w   .Lgk_ui_transition_prepare_corrupt
        bset    #6,%d2
.Lgk_ui_transition_prepare_pattern_visible:
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a4
        adda.l  %d0,%a4
        .incbin "stock/0085.bin", 0, 6
        btst    #7,%d2
        bne.s   .Lgk_ui_transition_prepare_bank_pointer_valid
        cmpa.l  %a4,%a0
        bne.w   .Lgk_ui_transition_prepare_corrupt
.Lgk_ui_transition_prepare_bank_pointer_valid:
        move.l  %d5,%d0
        btst    #6,%d2
        beq.s   .Lgk_ui_transition_prepare_source_pattern_ready
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
.Lgk_ui_transition_prepare_source_pattern_ready:
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a4,%a5
        adda.l  %d0,%a5
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a5
        moveq   #0,%d1
        move.b  (%a5),%d1
        cmp.l   %d3,%d1
        bne.w   .Lgk_ui_transition_prepare_corrupt
        btst    #7,%d2
        beq.s   .Lgk_ui_transition_prepare_source_mirror
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l GK_STOCK_BANK_POINTER,%a5
        adda.l  %d0,%a5
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a5
        moveq   #0,%d1
        move.b  (%a5),%d1
        cmpi.l  #3,%d1
        bhi.w   .Lgk_ui_transition_prepare_corrupt
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a5
        adda.l  %d0,%a5
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a5
        moveq   #0,%d0
        move.b  (%a5),%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        btst    #5,%d2
        beq.s   .Lgk_ui_transition_prepare_assignments_valid
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        bra.s   .Lgk_ui_transition_prepare_assignments_valid
.Lgk_ui_transition_prepare_source_mirror:
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a5
        adda.l  %d0,%a5
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a5
        moveq   #0,%d1
        move.b  (%a5),%d1
        cmp.l   %d3,%d1
        bne.w   .Lgk_ui_transition_prepare_corrupt
.Lgk_ui_transition_prepare_assignments_valid:
        lea     __gk_lease_sidecars,%a0
        moveq   #0,%d0
        move.w  (%a0),%d0
        move.l  %d6,%d1
        lsl.l   #8,%d1
        or.l    %d7,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_ui_transition_prepare_corrupt
        move.l  __gk_ui_transition_reserved,%d2
        beq.s   .Lgk_ui_transition_prepare_token_valid
        swap    %d2
        cmpi.w  #0x4c47,%d2
        bne.w   .Lgk_ui_transition_prepare_corrupt
        swap    %d2
        cmpi.b  #15,%d2
        bhi.s   .Lgk_ui_transition_prepare_corrupt
        cmp.b   __gk_current_pattern,%d2
        bne.s   .Lgk_ui_transition_prepare_corrupt
        cmp.b   %d5,%d2
        bne.s   .Lgk_ui_transition_prepare_token_visible
        btst    #15,%d2
        beq.s   .Lgk_ui_transition_prepare_corrupt
.Lgk_ui_transition_prepare_token_visible:
        lsr.l   #8,%d2
        andi.l  #GK_UI_TRANSITION_CARRIED_DESCRIPTOR_MASK,%d2
        cmp.b   %d6,%d2
        bne.s   .Lgk_ui_transition_prepare_corrupt
        tst.l   __gk_ui_transition_start
        bne.s   .Lgk_ui_transition_prepare_corrupt
        tst.l   __gk_ui_transition_start + 4
        bne.s   .Lgk_ui_transition_prepare_corrupt
        tst.l   __gk_ui_transition_start + 8
        bne.s   .Lgk_ui_transition_prepare_corrupt
.Lgk_ui_transition_prepare_token_valid:
        adda.l  #GK_PART_MACHINE_SELECTOR_OFFSET,%a3
        lea     __gk_ui_transition_old_machines,%a4
        moveq   #GK_PART_MACHINE_SELECTOR_COUNT,%d0
.Lgk_ui_transition_prepare_copy:
        move.b  (%a3)+,(%a4)+
        subq.l  #1,%d0
        bne.s   .Lgk_ui_transition_prepare_copy
        move.b  %d6,__gk_ui_transition_source_descriptor
        move.b  %d4,__gk_ui_transition_source_bank
        move.b  %d3,__gk_ui_transition_source_part
        clr.l   __gk_ui_transition_reserved
        moveq   #1,%d0
        move.b  %d0,__gk_pending_ui_capture_created
        .global gk_ui_transition_snapshot_publication
gk_ui_transition_snapshot_publication:
        move.b  %d0,__gk_ui_transition_pending
        .global gk_ui_transition_prepare_ok
gk_ui_transition_prepare_ok:
.Lgk_ui_transition_prepare_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_ui_transition_prepare_restore
.Lgk_ui_transition_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_ui_transition_prepare_restore
        .global gk_ui_transition_prepare_corrupt
gk_ui_transition_prepare_corrupt:
.Lgk_ui_transition_prepare_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_ui_transition_prepare_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
.Lgk_ui_transition_prepare_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_ui_transition_prepare,.-gk_ui_transition_prepare
        .global gk_ui_transition_event_begin
        .type   gk_ui_transition_event_begin,@function
gk_ui_transition_event_begin:
        tst.l   %a0
        beq.w   .Lgk_ui_event_invalid_fast
        .incbin "stock/0086.bin", 0, 4
        .incbin "stock/0086.bin", 4, 4
        movea.l %a0,%a5
        lea     __gk_lease_sidecars,%a0
        bsr.w   gk_selector_acquire
        tst.l   %d0
        bmi.w   .Lgk_ui_event_restore
        move.l  %d0,%d7
        movea.l %a0,%a4
        move.l  %d7,%d0
        bsr.w   gk_stock_latest_engine_context_validate
        tst.l   %d0
        bmi.w   .Lgk_ui_event_release_status
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %a0,%d5
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_event_release_busy
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_event_release_busy
        move.l  %d3,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        .incbin "stock/0087.bin", 0, 6
        cmpa.l  %a2,%a0
        bne.w   .Lgk_ui_event_release_busy
        move.l  %d4,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a2
        adda.l  %d0,%a2
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a2
        moveq   #0,%d0
        move.b  (%a2),%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_ui_event_release_busy
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   .Lgk_ui_event_release_corrupt
        movea.l %d0,%a3
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d0,%d1
        bne.w   .Lgk_ui_event_release_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_ui_event_release_corrupt
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PATTERN,%d1
        cmp.l   %d0,%d1
        bne.w   .Lgk_ui_event_release_corrupt
        moveq   #0,%d6
        move.b  __gk_ui_transition_pending,%d6
        cmpi.l  #1,%d6
        bhi.w   .Lgk_ui_event_release_corrupt
        tst.l   %d6
        bne.s   .Lgk_ui_event_snapshot
        cmp.l   %a3,%d5
        bne.w   .Lgk_ui_event_release_corrupt
        bra.s   .Lgk_ui_event_atomic
.Lgk_ui_event_snapshot:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_ui_event_release_busy
        .global gk_ui_transition_event_snapshot_patch
gk_ui_transition_event_snapshot_patch:
        jmp     gk_ui_transition_event_snapshot_release
        .global gk_audio_periodic_queue_handoff_validate
        .type   gk_audio_periodic_queue_handoff_validate,@function
gk_audio_periodic_queue_handoff_validate:
        moveq   #1,%d0
        cmp.b   __gk_sequencer_latch_queue_handoff,%d0
        bne.s   .Lgk_audio_periodic_handoff_validate_corrupt
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.s   .Lgk_audio_periodic_handoff_validate_corrupt
        move.w  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        nop
        nop
        moveq   #0,%d1
        move.b  %d6,%d1
        lsl.l   #8,%d1
        move.b  %d7,%d1
        cmp.w   %d0,%d1
        bne.s   .Lgk_audio_periodic_handoff_validate_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_audio_periodic_handoff_validate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_audio_periodic_queue_handoff_validate,.-gk_audio_periodic_queue_handoff_validate
        .global gk_ui_transition_event_snapshot_copy
gk_ui_transition_event_snapshot_copy:
        lea     __gk_ui_transition_old_machines,%a0
        moveq   #GK_PART_MACHINE_SELECTOR_COUNT,%d0
.Lgk_ui_event_snapshot_copy:
        move.b  (%a0)+,(%a5)+
        subq.l  #1,%d0
        bne.s   .Lgk_ui_event_snapshot_copy
.Lgk_ui_event_atomic:
        move.w  %sr,%d2
        .global gk_ui_transition_event_atomic_begin
gk_ui_transition_event_atomic_begin:
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_ui_event_atomic_corrupt
        btst    #7,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %a3,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %a3,%d0
        bne.w   .Lgk_ui_event_atomic_busy
        moveq   #0,%d0
        move.b  __gk_ui_transition_pending,%d0
        cmp.l   %d6,%d0
        bne.s   .Lgk_ui_event_atomic_busy
        tst.l   %d6
        beq.s   .Lgk_ui_event_atomic_done
        move.b  %d5,GK_STOCK_CURRENT_PART_MIRROR
        move.b  %d5,GK_STOCK_CURRENT_PART_PRIMARY
        .global gk_ui_transition_event_publication
gk_ui_transition_event_publication:
        clr.l   __gk_ui_transition_start
        clr.l   __gk_ui_transition_start + 4
        clr.l   __gk_ui_transition_start + 8
        clr.l   __gk_ui_transition_start + 12
.Lgk_ui_event_atomic_done:
        move.w  %d2,%sr
        move.l  %d5,%d1
        tst.l   %d6
        beq.s   .Lgk_ui_event_return
        ori.l   #0x100,%d1
.Lgk_ui_event_return:
        move.l  %d7,%d0
        movea.l %a4,%a0
        bra.s   .Lgk_ui_event_restore
.Lgk_ui_event_atomic_busy:
        move.w  %d2,%sr
        moveq   #GK_ERR_BUSY,%d6
        bra.s   .Lgk_ui_event_release_saved
.Lgk_ui_event_atomic_corrupt:
        move.w  %d2,%sr
        moveq   #GK_ERR_CORRUPT,%d6
        bra.s   .Lgk_ui_event_release_saved
.Lgk_ui_event_release_busy:
        moveq   #GK_ERR_BUSY,%d6
        bra.s   .Lgk_ui_event_release_saved
        .global gk_ui_transition_event_release_corrupt
gk_ui_transition_event_release_corrupt:
.Lgk_ui_event_release_corrupt:
        moveq   #GK_ERR_CORRUPT,%d6
.Lgk_ui_event_release_saved:
        move.l  %d7,%d0
        bsr.w   gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_ui_event_release_corrupt_result
        move.l  %d6,%d0
        bra.s   .Lgk_ui_event_restore
.Lgk_ui_event_release_status:
        move.l  %d0,%d6
        bra.s   .Lgk_ui_event_release_saved
.Lgk_ui_event_release_corrupt_result:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_ui_event_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
.Lgk_ui_event_invalid_fast:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .size   gk_ui_transition_event_begin,.-gk_ui_transition_event_begin
        .global gk_stock_part_event_publish
        .type   gk_stock_part_event_publish,@function
gk_stock_part_event_publish:
        addq.l  #1,%a2
        lea     -60(%sp),%sp
        movem.l %d2-%d7/%a0-%a6,(%sp)
        lea     52(%sp),%a0
        bsr.w   gk_ui_transition_event_begin
        tst.l   %d0
        bmi.w   .Lgk_stock_part_event_fail
        move.l  %d0,%d6
        move.l  %d1,%d7
        andi.l  #3,%d7
        btst    #8,%d1
        beq.w   .Lgk_stock_part_event_equal
        move.l  %d6,%a6
        moveq   #7,%d0
        moveq   #0,%d1
        jsr     gk_machine_transition_prepare
        move.l  %a6,%d0
        cmp.l   %d6,%d0
        beq.s   .Lgk_stock_part_event_machine_owner_ok
        jmp     gk_machine_transition_fatal
.Lgk_stock_part_event_machine_owner_ok:
        moveq   #0,%d2
.Lgk_stock_part_event_track_loop:
        move.l  %d2,%d0
        jsr     gk_machine_transition_event_arm
        moveq   #0,%d0
        move.b  52(%sp,%d2.l),%d0
        move.l  %d0,-(%sp)
        move.l  %d2,-(%sp)
        move.l  %d7,-(%sp)
        .global gk_stock_part_event_machine_call
gk_stock_part_event_machine_call:
        jsr     GK_STOCK_PART_MACHINE_TRANSITION
        .global gk_stock_part_event_machine_return
gk_stock_part_event_machine_return:
        addq.l  #1,%d2
        lea     12(%sp),%sp
        subq.l  #1,%d2
        move.l  %d2,%d0
        jsr     gk_machine_transition_event_step_finish
        addq.l  #1,%d2
        cmpi.l  #GK_PART_MACHINE_SELECTOR_COUNT,%d2
        bne.s   .Lgk_stock_part_event_track_loop
        .global gk_stock_part_event_commit_call
gk_stock_part_event_commit_call:
        .incbin "stock/0088.bin", 0, 6
        .incbin "stock/0088.bin", 6, 2
        .global gk_stock_part_event_transition_refresh_call
gk_stock_part_event_transition_refresh_call:
        .incbin "stock/0088.bin", 8, 6
        .incbin "stock/0088.bin", 14, 2
        jsr     gk_machine_transition_finish
        bra.s   .Lgk_stock_part_event_dirty
.Lgk_stock_part_event_equal:
        .global gk_stock_part_event_equal_a_call
gk_stock_part_event_equal_a_call:
        jsr     GK_STOCK_PART_EVENT_EQUAL_A
        .global gk_stock_part_event_equal_b_call
gk_stock_part_event_equal_b_call:
        jsr     GK_STOCK_PART_EVENT_EQUAL_B
.Lgk_stock_part_event_dirty:
        lea     GK_STOCK_PART_EVENT_DIRTY_START,%a0
        moveq   #1,%d3
.Lgk_stock_part_event_dirty_loop:
        move.l  %d3,(%a0)+
        cmpa.l  #GK_STOCK_PART_EVENT_DIRTY_END,%a0
        bne.s   .Lgk_stock_part_event_dirty_loop
        .global gk_stock_part_event_redraw_call
gk_stock_part_event_redraw_call:
        .incbin "stock/0089.bin", 0, 6
        .incbin "stock/0090.bin", 0, 4
        .global gk_stock_part_event_track_redraw_call
gk_stock_part_event_track_redraw_call:
        .incbin "stock/0090.bin", 4, 6
        addq.l  #4,%sp
        .incbin "stock/0091.bin", 0, 6
        .incbin "stock/0091.bin", 6, 6
        .incbin "stock/0091.bin", 12, 6
        .incbin "stock/0091.bin", 18, 4
        .incbin "stock/0091.bin", 22, 6
        addq.l  #4,%sp
        pea     (-1).w
        jsr     GK_STOCK_PART_EVENT_REFRESH_E
        addq.l  #4,%sp
        jsr     gk_stock_part_refresh_writer
        .global gk_stock_part_event_refresh_f_return
gk_stock_part_event_refresh_f_return:
        move.l  %d6,%d0
        bsr.w   gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_stock_part_event_fail
.Lgk_stock_part_event_done:
        movem.l (%sp),%d2-%d7/%a0-%a6
        lea     60(%sp),%sp
        jmp     GK_STOCK_PART_EVENT_DONE
.Lgk_stock_part_event_fail:
        bra.s   .Lgk_stock_part_event_done
        .size   gk_stock_part_event_publish,.-gk_stock_part_event_publish
