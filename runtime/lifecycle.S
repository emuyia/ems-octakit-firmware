        .include "abi.inc"
        .equ    GK_LIFECYCLE_ROOT_COUNTS,0x000
        .equ    GK_LIFECYCLE_SPILL_SEEN,0x100
        .equ    GK_LIFECYCLE_VALIDATION_SIZE,0x110
        .section .runtime,"ax"
        .align  4
        .global gk_lifecycle_quiesce_reset
        .type   gk_lifecycle_quiesce_reset,@function
gk_lifecycle_quiesce_reset:
        .incbin "stock/0237.bin", 0, 4
        .incbin "stock/0237.bin", 4, 4
        move.w  %sr,%d0
        move.w  %d0,44(%sp)
        clr.l   48(%sp)
        bra.s   .Lgk_lifecycle_quiesce_body
        .global gk_lifecycle_quiesce_capture_reset
        .type   gk_lifecycle_quiesce_capture_reset,@function
gk_lifecycle_quiesce_capture_reset:
        .incbin "stock/0238.bin", 0, 4
        .incbin "stock/0238.bin", 4, 4
        move.w  %sr,%d0
        move.w  %d0,44(%sp)
        moveq   #GK_LIFECYCLE_CAPTURE_LIBRARY,%d0
        move.l  %d0,48(%sp)
.Lgk_lifecycle_quiesce_body:
        lea     __gk_io_buffer,%a0
        moveq   #0,%d0
        move.l  #(GK_LIFECYCLE_VALIDATION_SIZE / 4),%d1
.Lgk_lifecycle_scratch_clear:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_lifecycle_scratch_clear
        move.w  #0x2700,%sr
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_lifecycle_gate_valid
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   .Lgk_lifecycle_corrupt
.Lgk_lifecycle_gate_valid:
        move.l  __gk_persistence_snapshot_gate,%d0
        tst.l   %d0
        beq.s   .Lgk_lifecycle_snapshot_free
        cmpi.l  #GK_PERSIST_SNAPSHOT_ACTIVE,%d0
        beq.w   .Lgk_lifecycle_busy
        bra.w   .Lgk_lifecycle_corrupt
.Lgk_lifecycle_snapshot_free:
        moveq   #0,%d0
        move.b  __gk_undo_pending_owner,%d0
        cmpi.l  #GK_UNDO_PENDING_SAVE,%d0
        bhi.w   .Lgk_lifecycle_corrupt
        tst.l   %d0
        bne.w   .Lgk_lifecycle_busy
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_lifecycle_corrupt
        btst    #7,%d0
        bne.w   .Lgk_lifecycle_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_lifecycle_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_lifecycle_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_lifecycle_corrupt
        tst.b   __gk_pending_workspace_bound
        bne.w   .Lgk_lifecycle_corrupt
        tst.b   __gk_promotion_assign
        bne.w   .Lgk_lifecycle_corrupt
        lea     __gk_lease_sidecars,%a2
        lea     __gk_io_buffer + GK_LIFECYCLE_ROOT_COUNTS,%a3
        moveq   #GK_LEASE_SIDECAR_COUNT,%d2
.Lgk_lifecycle_sidecar_loop:
        moveq   #0,%d0
        move.w  (%a2),%d0
        move.l  %d0,%d1
        andi.l  #0xff,%d1
        cmpi.l  #GK_ID_NONE,%d1
        bne.w   .Lgk_lifecycle_busy
        lsr.l   #8,%d0
        andi.l  #0xff,%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_lifecycle_sidecar_next
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_lifecycle_corrupt
        add.l   %d0,%d0
        moveq   #0,%d1
        move.w  (%a3,%d0.l),%d1
        cmpi.l  #0xffff,%d1
        beq.w   .Lgk_lifecycle_corrupt
        addq.l  #1,%d1
        move.w  %d1,(%a3,%d0.l)
.Lgk_lifecycle_sidecar_next:
        addq.l  #2,%a2
        subq.l  #1,%d2
        bne.s   .Lgk_lifecycle_sidecar_loop
        moveq   #0,%d5
        move.b  __gk_workspace_descriptor,%d5
        cmpi.l  #GK_ID_NONE,%d5
        bne.s   .Lgk_lifecycle_workspace_present
        move.l  __gk_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_lifecycle_corrupt
        tst.b   __gk_workspace_dirty
        bne.w   .Lgk_lifecycle_corrupt
        tst.b   __gk_workspace_bound
        bne.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        cmpi.l  #0xffff,%d0
        bne.w   .Lgk_lifecycle_corrupt
        bra.w   .Lgk_lifecycle_workspace_counted
.Lgk_lifecycle_workspace_present:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d5
        bhi.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_dirty,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_bound,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        move.l  %d5,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_lifecycle_corrupt
        move.l  %d5,%d0
        add.l   %d0,%d0
        moveq   #0,%d1
        move.w  (%a3,%d0.l),%d1
        cmpi.l  #0xffff,%d1
        beq.w   .Lgk_lifecycle_corrupt
        addq.l  #1,%d1
        move.w  %d1,(%a3,%d0.l)
.Lgk_lifecycle_workspace_counted:
        moveq   #0,%d6
        move.b  __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%d6
        lea     __gk_descriptors,%a2
        lea     __gk_descriptor_bitmap,%a5
        lea     __gk_io_buffer + GK_LIFECYCLE_SPILL_SEEN,%a4
        moveq   #0,%d2
.Lgk_lifecycle_descriptor_loop:
        move.l  %d2,%d0
        add.l   %d0,%d0
        moveq   #0,%d4
        move.w  (%a3,%d0.l),%d4
        move.l  %d2,%d0
        lsr.l   #3,%d0
        moveq   #0,%d3
        move.b  (%a5,%d0.l),%d3
        move.l  %d2,%d1
        andi.l  #7,%d1
        btst    %d1,%d3
        bne.s   .Lgk_lifecycle_descriptor_allocated
        tst.l   %d4
        bne.w   .Lgk_lifecycle_corrupt
        move.l  (%a2),%d0
        or.l    4(%a2),%d0
        or.l    8(%a2),%d0
        or.l    12(%a2),%d0
        bne.w   .Lgk_lifecycle_corrupt
        bra.w   .Lgk_lifecycle_descriptor_next
.Lgk_lifecycle_descriptor_allocated:
        moveq   #0,%d3
        move.b  GK_DESC_FLAGS(%a2),%d3
        btst    #0,%d3
        beq.w   .Lgk_lifecycle_corrupt
        move.l  %d3,%d0
        andi.l  #0x80,%d0
        bne.w   .Lgk_lifecycle_corrupt
        move.l  %d3,%d0
        andi.l  #0x62,%d0
        bne.w   .Lgk_lifecycle_busy
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_lifecycle_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a2),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_READERS(%a2),%d0
        cmp.l   %d6,%d2
        bne.s   .Lgk_lifecycle_no_latch_reader
        cmpi.l  #1,%d0
        beq.s   .Lgk_lifecycle_reader_valid
        bhi.w   .Lgk_lifecycle_busy
        bra.w   .Lgk_lifecycle_corrupt
.Lgk_lifecycle_no_latch_reader:
        tst.l   %d0
        bne.w   .Lgk_lifecycle_busy
.Lgk_lifecycle_reader_valid:
        cmp.l   %d5,%d2
        bne.s   .Lgk_lifecycle_not_workspace
        btst    #3,%d3
        beq.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a2),%d0
        moveq   #0,%d1
        move.b  __gk_current_kit,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        move.l  %d0,%d1
        lsr.l   #2,%d1
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d0,%d1
        bne.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_dirty,%d0
        lsr.l   #4,%d3
        andi.l  #1,%d3
        cmp.l   %d3,%d0
        bne.w   .Lgk_lifecycle_corrupt
        bra.s   .Lgk_lifecycle_workspace_flag_valid
.Lgk_lifecycle_not_workspace:
        btst    #3,%d3
        bne.w   .Lgk_lifecycle_corrupt
.Lgk_lifecycle_workspace_flag_valid:
        btst    #2,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_lifecycle_descriptor_physical
        cmp.l   %d5,%d2
        beq.w   .Lgk_lifecycle_corrupt
        cmp.l   %d6,%d2
        beq.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d7
        move.b  GK_DESC_SPILL(%a2),%d7
        cmpi.l  #GK_SPILL_ALLOC_COUNT - 1,%d7
        bhi.w   .Lgk_lifecycle_corrupt
        move.l  %d7,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_spill_payloads,%a0
        adda.l  %d0,%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.w   .Lgk_lifecycle_corrupt
        move.l  %d7,%d0
        lsr.l   #3,%d0
        move.l  %d7,%d1
        andi.l  #7,%d1
        btst    %d1,(%a4,%d0.l)
        bne.w   .Lgk_lifecycle_corrupt
        bset    %d1,(%a4,%d0.l)
        bra.s   .Lgk_lifecycle_descriptor_next
.Lgk_lifecycle_descriptor_physical:
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_lifecycle_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_lifecycle_corrupt
        jsr     gk_physical_validate
        cmp.l   %d2,%d0
        bne.w   .Lgk_lifecycle_corrupt
.Lgk_lifecycle_descriptor_next:
        lea     GK_DESC_SIZE(%a2),%a2
        addq.l  #1,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT,%d2
        blo.w   .Lgk_lifecycle_descriptor_loop
        lea     __gk_spill_bitmap,%a0
        lea     __gk_io_buffer + GK_LIFECYCLE_SPILL_SEEN,%a1
        moveq   #(GK_SPILL_COUNT / 32),%d0
.Lgk_lifecycle_spill_bitmap_loop:
        move.l  (%a0)+,%d1
        cmp.l   (%a1)+,%d1
        bne.w   .Lgk_lifecycle_corrupt
        subq.l  #1,%d0
        bne.s   .Lgk_lifecycle_spill_bitmap_loop
        lea     __gk_coherence_sidecars,%a0
        moveq   #GK_COHERENCE_COUNT,%d2
.Lgk_lifecycle_coherence_loop:
        moveq   #0,%d7
        move.b  (%a0)+,%d7
        cmpi.l  #GK_ID_NONE,%d7
        beq.s   .Lgk_lifecycle_coherence_next
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bhi.w   .Lgk_lifecycle_corrupt
        move.l  %d7,%d0
        lsr.l   #3,%d0
        moveq   #0,%d1
        move.b  (%a5,%d0.l),%d1
        move.l  %d7,%d0
        andi.l  #7,%d0
        btst    %d0,%d1
        beq.w   .Lgk_lifecycle_corrupt
.Lgk_lifecycle_coherence_next:
        subq.l  #1,%d2
        bne.s   .Lgk_lifecycle_coherence_loop
        moveq   #0,%d2
.Lgk_lifecycle_physical_loop:
        move.l  %d2,%d0
        jsr     gk_physical_validate
        tst.l   %d0
        bpl.s   .Lgk_lifecycle_physical_next
        cmpi.l  #GK_ERR_INVALID,%d0
        bne.w   .Lgk_lifecycle_corrupt
.Lgk_lifecycle_physical_next:
        addq.l  #1,%d2
        cmpi.l  #GK_PHYSICAL_COUNT,%d2
        blo.s   .Lgk_lifecycle_physical_loop
        move.l  48(%sp),%d0
        tst.l   %d0
        beq.w   .Lgk_lifecycle_capture_discard
        cmpi.l  #GK_LIFECYCLE_CAPTURE_LIBRARY,%d0
        bne.w   .Lgk_lifecycle_corrupt
        clr.l   __gk_lifecycle_scratch_magic
        clr.l   __gk_lifecycle_scratch_flags
        clr.l   __gk_lifecycle_scratch_runtime_flags
        moveq   #-1,%d0
        move.b  %d0,__gk_lifecycle_scratch_kit
        move.b  %d0,__gk_lifecycle_scratch_bank
        move.b  %d0,__gk_lifecycle_scratch_pattern
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        move.b  %d0,__gk_lifecycle_scratch_runtime_flags
        lea     __gk_persistence_state,%a0
        lea     __gk_lifecycle_scratch_persistence,%a1
        moveq   #(GK_PERSIST_SIZE / 4),%d1
.Lgk_lifecycle_capture_persistence:
        move.l  (%a0)+,(%a1)+
        subq.l  #1,%d1
        bne.s   .Lgk_lifecycle_capture_persistence
        lea     __gk_pattern_assignments,%a0
        lea     __gk_lifecycle_scratch_library,%a1
        move.l  #(GK_FORMAT_META_BODY_SIZE / 4),%d1
.Lgk_lifecycle_capture_library:
        move.l  (%a0)+,(%a1)+
        subq.l  #1,%d1
        bne.s   .Lgk_lifecycle_capture_library
        moveq   #GK_LIFECYCLE_CAPTURE_LIBRARY,%d3
        cmpi.l  #GK_ID_NONE,%d5
        beq.w   .Lgk_lifecycle_capture_publish
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        move.b  %d0,__gk_lifecycle_scratch_kit
        move.b  __gk_current_bank,%d0
        move.b  %d0,__gk_lifecycle_scratch_bank
        move.b  __gk_current_pattern,%d0
        move.b  %d0,__gk_lifecycle_scratch_pattern
        moveq   #0,%d0
        move.b  __gk_workspace_bound,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_lifecycle_corrupt
        move.b  %d0,__gk_lifecycle_scratch_bound
        move.l  __gk_workspace_name,%d0
        move.l  %d0,__gk_lifecycle_scratch_workspace_name
        move.l  __gk_workspace_name + 4,%d0
        move.l  %d0,__gk_lifecycle_scratch_workspace_name + 4
        ori.l   #GK_LIFECYCLE_CAPTURE_WORKSPACE,%d3
        tst.b   __gk_workspace_dirty
        beq.s   .Lgk_lifecycle_capture_publish
        move.l %d5,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        movea.l GK_DESC_PAYLOAD(%a2),%a0
        tst.l   %a0
        beq.w   .Lgk_lifecycle_corrupt
        lea     __gk_lifecycle_scratch_payload,%a1
        move.l  #(GK_PART_PAYLOAD_SIZE / 4),%d1
.Lgk_lifecycle_capture_payload:
        move.l  (%a0)+,(%a1)+
        subq.l  #1,%d1
        bne.s   .Lgk_lifecycle_capture_payload
        move.w  (%a0)+,(%a1)+
        ori.l   #GK_LIFECYCLE_CAPTURE_WORKSPACE_DIRTY,%d3
.Lgk_lifecycle_capture_publish:
        move.b  %d3,__gk_lifecycle_scratch_flags
        move.l  #GK_LIFECYCLE_SCRATCH_MAGIC,%d0
        .global gk_lifecycle_capture_publication
gk_lifecycle_capture_publication:
        move.l  %d0,__gk_lifecycle_scratch_magic
        bra.s   .Lgk_lifecycle_publish_quiesced
.Lgk_lifecycle_capture_discard:
        clr.l   __gk_lifecycle_scratch_magic
        clr.l   __gk_lifecycle_scratch_flags
.Lgk_lifecycle_publish_quiesced:
        move.l  #GK_LIFECYCLE_QUIESCED,%d0
        .global gk_lifecycle_quiesce_publication
gk_lifecycle_quiesce_publication:
        move.l  %d0,__gk_lifecycle_state
        lea     __gk_lease_sidecars,%a0
        moveq   #-1,%d0
        moveq   #(0x100 / 4),%d1
.Lgk_lifecycle_invalidate_sidecars:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_lifecycle_invalidate_sidecars
        lea     __gk_descriptors,%a0
        move.l  #GK_DESCRIPTOR_COUNT,%d1
.Lgk_lifecycle_clear_counters:
        clr.l   GK_DESC_ROOTS(%a0)
        lea     GK_DESC_SIZE(%a0),%a0
        subq.l  #1,%d1
        bne.s   .Lgk_lifecycle_clear_counters
        moveq   #-1,%d0
        move.l  %d0,__gk_workspace_descriptor
        move.l  %d0,__gk_pending_workspace_descriptor
        clr.b   __gk_workspace_dirty
        clr.b   __gk_pending_transition_flags
        clr.b   __gk_pending_ui_capture_created
        move.l  #GK_RUNTIME_TRANSITION,%d0
        move.b  %d0,__gk_runtime_flags
        move.w  44(%sp),%d0
        move.w  %d0,%sr
        jsr     gk_runtime_metadata_reset_preserve_lifecycle
        moveq   #GK_OK,%d0
        move.w  44(%sp),%d1
        move.w  %d1,%sr
        bra.s   .Lgk_lifecycle_restore
.Lgk_lifecycle_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_lifecycle_failure
.Lgk_lifecycle_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_lifecycle_failure:
        move.w  44(%sp),%d1
        move.w  %d1,%sr
.Lgk_lifecycle_restore:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     52(%sp),%sp
        rts
        .size   gk_lifecycle_quiesce_reset,.-gk_lifecycle_quiesce_reset
        .size   gk_lifecycle_quiesce_capture_reset,.-gk_lifecycle_quiesce_capture_reset
        .global gk_lifecycle_boot_quiesce_reset
        .type   gk_lifecycle_boot_quiesce_reset,@function
gk_lifecycle_boot_quiesce_reset:
        move.w  %sr,%d0
        move.l  %d2,-(%sp)
        move.w  %d0,%d2
        move.w  #0x2700,%sr
        clr.l   __gk_lifecycle_scratch_magic
        clr.l   __gk_lifecycle_scratch_flags
        move.l  #GK_LIFECYCLE_QUIESCED,%d0
        .global gk_lifecycle_boot_publication
gk_lifecycle_boot_publication:
        move.l  %d0,__gk_lifecycle_state
        move.w  %d2,%sr
        jsr     gk_runtime_metadata_reset_preserve_lifecycle
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.s   .Lgk_lifecycle_boot_corrupt
        moveq   #GK_OK,%d0
        bra.s   .Lgk_lifecycle_boot_restore
.Lgk_lifecycle_boot_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_lifecycle_boot_restore:
        move.w  %d2,%d1
        move.l  (%sp)+,%d2
        move.w  %d1,%sr
        rts
        .size   gk_lifecycle_boot_quiesce_reset,.-gk_lifecycle_boot_quiesce_reset
        .global gk_lifecycle_capture_validate
        .type   gk_lifecycle_capture_validate,@function
gk_lifecycle_capture_validate:
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   .Lgk_lifecycle_capture_validate_busy
        move.l  __gk_lifecycle_scratch_magic,%d0
        cmpi.l  #GK_LIFECYCLE_SCRATCH_MAGIC,%d0
        bne.w   .Lgk_lifecycle_capture_validate_invalid
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_flags,%d0
        move.l  %d0,%d1
        andi.l  #~GK_LIFECYCLE_CAPTURE_KNOWN_FLAGS,%d1
        bne.w   .Lgk_lifecycle_capture_validate_corrupt
        btst    #0,%d0
        beq.w   .Lgk_lifecycle_capture_validate_corrupt
        btst    #2,%d0
        beq.s   .Lgk_lifecycle_capture_dirty_shape_valid
        btst    #1,%d0
        beq.w   .Lgk_lifecycle_capture_validate_corrupt
.Lgk_lifecycle_capture_dirty_shape_valid:
        moveq   #0,%d1
        move.b  __gk_lifecycle_scratch_runtime_flags,%d1
        andi.l  #~GK_RUNTIME_STORAGE_DIRTY,%d1
        bne.w   .Lgk_lifecycle_capture_validate_corrupt
        lea     __gk_lifecycle_scratch_persistence,%a0
        moveq   #0,%d1
        move.b  GK_PERSIST_FLAGS(%a0),%d1
        move.l  %d1,%a1
        andi.l  #~GK_PERSIST_KNOWN_FLAGS,%d1
        bne.w   .Lgk_lifecycle_capture_validate_corrupt
        moveq   #0,%d1
        move.b  GK_PERSIST_RESERVED(%a0),%d1
        cmpi.l  #GK_PERSIST_RELOAD_MAX,%d1
        bhi.w   .Lgk_lifecycle_capture_validate_corrupt
        tst.l   16(%a0)
        bne.w   .Lgk_lifecycle_capture_validate_corrupt
        tst.l   20(%a0)
        bne.w   .Lgk_lifecycle_capture_validate_corrupt
        move.l  %a1,%d1
        btst    #0,%d1
        beq.s   .Lgk_lifecycle_capture_work_unknown
        moveq   #0,%d1
        move.b  GK_PERSIST_WORK_SLOT(%a0),%d1
        cmpi.l  #1,%d1
        bhi.w   .Lgk_lifecycle_capture_validate_corrupt
        bra.s   .Lgk_lifecycle_capture_stored
.Lgk_lifecycle_capture_work_unknown:
        moveq   #0,%d1
        move.b  GK_PERSIST_WORK_SLOT(%a0),%d1
        cmpi.l  #GK_PERSIST_SLOT_NONE,%d1
        bne.w   .Lgk_lifecycle_capture_validate_corrupt
.Lgk_lifecycle_capture_stored:
        move.l  %a1,%d1
        btst    #1,%d1
        beq.s   .Lgk_lifecycle_capture_stored_unknown
        moveq   #0,%d1
        move.b  GK_PERSIST_STORED_SLOT(%a0),%d1
        cmpi.l  #1,%d1
        bhi.w   .Lgk_lifecycle_capture_validate_corrupt
        bra.s   .Lgk_lifecycle_capture_identity
.Lgk_lifecycle_capture_stored_unknown:
        moveq   #0,%d1
        move.b  GK_PERSIST_STORED_SLOT(%a0),%d1
        cmpi.l  #GK_PERSIST_SLOT_NONE,%d1
        bne.w   .Lgk_lifecycle_capture_validate_corrupt
.Lgk_lifecycle_capture_identity:
        btst    #1,%d0
        beq.s   .Lgk_lifecycle_capture_no_workspace
        moveq   #0,%d1
        move.b  __gk_lifecycle_scratch_bank,%d1
        cmpi.l  #15,%d1
        bhi.s   .Lgk_lifecycle_capture_validate_corrupt
        moveq   #0,%d1
        move.b  __gk_lifecycle_scratch_pattern,%d1
        cmpi.l  #15,%d1
        bhi.s   .Lgk_lifecycle_capture_validate_corrupt
        moveq   #0,%d1
        move.b  __gk_lifecycle_scratch_bound,%d1
        cmpi.l  #1,%d1
        bhi.s   .Lgk_lifecycle_capture_validate_corrupt
        rts
.Lgk_lifecycle_capture_no_workspace:
        moveq   #0,%d1
        move.b  __gk_lifecycle_scratch_kit,%d1
        cmpi.l  #GK_ID_NONE,%d1
        bne.s   .Lgk_lifecycle_capture_validate_corrupt
        move.b  __gk_lifecycle_scratch_bank,%d1
        cmpi.l  #GK_ID_NONE,%d1
        bne.s   .Lgk_lifecycle_capture_validate_corrupt
        move.b  __gk_lifecycle_scratch_pattern,%d1
        cmpi.l  #GK_ID_NONE,%d1
        bne.s   .Lgk_lifecycle_capture_validate_corrupt
        tst.b   __gk_lifecycle_scratch_bound
        bne.s   .Lgk_lifecycle_capture_validate_corrupt
        rts
.Lgk_lifecycle_capture_validate_invalid:
        moveq   #GK_ERR_INVALID,%d0
        rts
.Lgk_lifecycle_capture_validate_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
.Lgk_lifecycle_capture_validate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_lifecycle_capture_validate,.-gk_lifecycle_capture_validate
        .global gk_lifecycle_restore_persistence
        .type   gk_lifecycle_restore_persistence,@function
gk_lifecycle_restore_persistence:
        move.l  %d2,-(%sp)
        bsr.w   gk_lifecycle_capture_validate
        tst.l   %d0
        bmi.s   .Lgk_lifecycle_restore_persistence_done
        lea     __gk_lifecycle_scratch_persistence,%a0
        lea     __gk_persistence_state,%a1
        moveq   #(GK_PERSIST_SIZE / 4),%d1
.Lgk_lifecycle_restore_persistence_loop:
        move.l  (%a0)+,(%a1)+
        subq.l  #1,%d1
        bne.s   .Lgk_lifecycle_restore_persistence_loop
        moveq   #0,%d1
        move.b  __gk_lifecycle_scratch_runtime_flags,%d1
        move.b  %d1,__gk_runtime_flags
        moveq   #GK_OK,%d0
.Lgk_lifecycle_restore_persistence_done:
        move.l  (%sp)+,%d2
        rts
        .size   gk_lifecycle_restore_persistence,.-gk_lifecycle_restore_persistence
        .global gk_lifecycle_restore_library
        .type   gk_lifecycle_restore_library,@function
gk_lifecycle_restore_library:
        move.l  %d2,-(%sp)
        bsr.w   gk_lifecycle_restore_persistence
        tst.l   %d0
        bmi.s   .Lgk_lifecycle_restore_library_done
        lea     __gk_lifecycle_scratch_library,%a0
        lea     __gk_pattern_assignments,%a1
        move.l  #(GK_FORMAT_META_BODY_SIZE / 4),%d1
.Lgk_lifecycle_restore_library_loop:
        move.l  (%a0)+,(%a1)+
        subq.l  #1,%d1
        bne.s   .Lgk_lifecycle_restore_library_loop
        moveq   #GK_OK,%d0
.Lgk_lifecycle_restore_library_done:
        move.l  (%sp)+,%d2
        rts
        .size   gk_lifecycle_restore_library,.-gk_lifecycle_restore_library
        .global gk_lifecycle_scratch_clear
        .type   gk_lifecycle_scratch_clear,@function
gk_lifecycle_scratch_clear:
        jmp     gk_lifecycle_scratch_clear_release
        .global gk_sequencer_latch_queue_handoff_repeat_validate
        .type   gk_sequencer_latch_queue_handoff_repeat_validate,@function
gk_sequencer_latch_queue_handoff_repeat_validate:
        cmp.w   GK_STOCK_QUEUED_BANK,%d2
        beq.s   .Lgk_lifecycle_queue_repeat_tuple_validate
        cmp.l   GK_STOCK_SCHEDULER_CHAINED,%d0
        bne.s   .Lgk_lifecycle_queue_repeat_return
.Lgk_lifecycle_queue_repeat_tuple_validate:
        move.l  GK_STOCK_QUEUED_BANK,%d0
        andi.l  #0xf0f0f0f0,%d0
.Lgk_lifecycle_queue_repeat_return:
        rts
        .size   gk_sequencer_latch_queue_handoff_repeat_validate,.-gk_sequencer_latch_queue_handoff_repeat_validate
        .size   gk_lifecycle_scratch_clear,.-gk_lifecycle_scratch_clear
