        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_descriptor_begin_promotion
        .type   gk_descriptor_begin_promotion,@function
gk_descriptor_begin_promotion:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_promotion_begin_range
        cmpi.l  #0xff,%d1
        bhi.w   .Lgk_promotion_begin_range
        cmpi.l  #1,%d2
        bhi.w   .Lgk_promotion_begin_range
        lea     -44(%sp),%sp
        movem.l %d2-%d7/%a2-%a4,(%sp)
        clr.l   36(%sp)
        move.l  %d2,40(%sp)
        move.l  %d0,%d2
        move.l  %d1,%d3
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        move.l  %d3,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a3
        adda.l  %d0,%a3
        move.w  %sr,%d7
        move.w  #0x2700,%sr
.Lgk_promotion_begin_revalidate:
        move.l  __gk_persistence_snapshot_gate,%d0
        tst.l   %d0
        beq.s   .Lgk_promotion_begin_snapshot_free
        cmpi.l  #GK_PERSIST_SNAPSHOT_ACTIVE,%d0
        beq.w   .Lgk_promotion_begin_busy
        bra.w   .Lgk_promotion_begin_corrupt
.Lgk_promotion_begin_snapshot_free:
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        andi.l  #0xfe,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d4
        move.b  __gk_current_kit,%d4
        moveq   #0,%d0
        move.b  __gk_workspace_bound,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_promotion_begin_corrupt
        tst.l   40(%sp)
        bne.s   .Lgk_promotion_begin_mode_valid
        tst.l   %d0
        beq.w   .Lgk_promotion_begin_invalid
        cmp.l   %d4,%d3
        bne.w   .Lgk_promotion_begin_corrupt
.Lgk_promotion_begin_mode_valid:
        tst.l   40(%sp)
        bne.s   .Lgk_promotion_begin_name_ready_v9
        move.l  %d3,%d0
        move.l  %d3,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.w   .Lgk_promotion_begin_invalid
        move.l  %d3,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a0
        adda.l  %d0,%a0
        move.l  (%a0),%d0
        cmp.l   __gk_workspace_name,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        move.l  4(%a0),%d0
        cmp.l   __gk_workspace_name + 4,%d0
        bne.w   .Lgk_promotion_begin_corrupt
.Lgk_promotion_begin_name_ready_v9:
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d1
        move.b  __gk_current_pattern,%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_promotion_begin_corrupt
        move.l  %d2,%d0
        lsl.l   #8,%d0
        ori.l   #0x00ff,%d0
        moveq   #0,%d1
        move.w  __gk_lease_sidecars,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        move.l  %d2,%d0
        lsr.l   #3,%d0
        move.l  %d2,%d1
        andi.l  #7,%d1
        lea     __gk_descriptor_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d6
        move.b  GK_DESC_FLAGS(%a2),%d6
        btst    #0,%d6
        beq.w   .Lgk_promotion_begin_corrupt
        btst    #3,%d6
        beq.w   .Lgk_promotion_begin_corrupt
        move.l  %d6,%d0
        andi.l  #0xa4,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        move.l  %d6,%d0
        andi.l  #GK_DESC_PROMOTION_COPY,%d0
        beq.w   .Lgk_promotion_begin_stable
        cmpi.l  #GK_DESC_PROMOTION_COPY,%d0
        bne.w   .Lgk_promotion_begin_corrupt
.Lgk_promotion_begin_descriptor_common:
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a2),%d0
        cmpi.l  #2,%d0
        blo.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a2),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d5
        move.b  GK_DESC_PHYSICAL(%a2),%d5
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d5
        bhi.w   .Lgk_promotion_begin_corrupt
        move.l  %d5,%d0
        lsr.l   #2,%d0
        moveq   #0,%d1
        move.b  __gk_current_bank,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_dirty,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_promotion_begin_corrupt
        tst.l   %d0
        beq.s   .Lgk_promotion_begin_expect_clean
        btst    #4,%d6
        beq.w   .Lgk_promotion_begin_corrupt
        bra.s   .Lgk_promotion_begin_dirty_valid
.Lgk_promotion_begin_expect_clean:
        btst    #4,%d6
        bne.w   .Lgk_promotion_begin_corrupt
.Lgk_promotion_begin_dirty_valid:
        move.l  %d5,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.w   .Lgk_promotion_begin_corrupt
        move.l %d5,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a4
        adda.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a4),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a4),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        tst.b   GK_PHYS_STATE(%a4)
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a4),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        btst    #6,%d6
        beq.s   .Lgk_promotion_begin_new
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        move.l  %d0,%d1
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a0
        adda.l  %d0,%a0
        cmpa.l  GK_DESC_CANDIDATE(%a2),%a0
        bne.w   .Lgk_promotion_begin_corrupt
        cmp.l   %d3,%d1
        bne.w   .Lgk_promotion_begin_busy
        cmpa.l  %a3,%a0
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d0
        move.b  __gk_promotion_assign,%d0
        cmp.l   40(%sp),%d0
        bne.w   .Lgk_promotion_begin_busy
        move.l  %d3,%d0
        jsr     gk_undo_kit_validate_pending_save
        tst.l   %d0
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #GK_OK,%d0
        bra.w   .Lgk_promotion_begin_restore
.Lgk_promotion_begin_new:
        tst.b   __gk_promotion_assign
        bne.w   .Lgk_promotion_begin_corrupt
        tst.l   36(%sp)
        bne.s   .Lgk_promotion_begin_capture_validated
        move.l  %d3,%d0
        moveq   #0,%d1
        move.w  %d7,%d1
        jsr     gk_undo_kit_capture_save_target
        tst.l   %d0
        bne.w   .Lgk_promotion_begin_restore
        moveq   #1,%d0
        move.l  %d0,36(%sp)
        bra.w   .Lgk_promotion_begin_revalidate
.Lgk_promotion_begin_capture_validated:
        move.l  %d3,%d0
        jsr     gk_undo_kit_validate_pending_save
        tst.l   %d0
        bne.w   .Lgk_promotion_begin_corrupt
        bra.s   .Lgk_promotion_begin_publish
.Lgk_promotion_begin_stable:
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_promotion_begin_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_promotion_begin_corrupt
        bra.w   .Lgk_promotion_begin_descriptor_common
.Lgk_promotion_begin_publish:
        move.l  %a3,GK_DESC_CANDIDATE(%a2)
        move.b  %d3,GK_DESC_SPILL(%a2)
        moveq   #0,%d0
        move.b  43(%sp),%d0
        move.b  %d0,__gk_promotion_assign
        move.l  %d6,%d0
        ori.l   #GK_DESC_PROMOTION_COPY,%d0
        .global gk_descriptor_promotion_publication
gk_descriptor_promotion_publication:
        move.b  %d0,GK_DESC_FLAGS(%a2)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_promotion_begin_restore
.Lgk_promotion_begin_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_promotion_begin_failure
.Lgk_promotion_begin_invalid:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_promotion_begin_failure
.Lgk_promotion_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_promotion_begin_failure:
        tst.l   36(%sp)
        beq.s   .Lgk_promotion_begin_restore
        move.l  %d0,-(%sp)
        jsr     gk_undo_kit_discard_pending_save
        tst.l   %d0
        beq.s   .Lgk_promotion_begin_failure_discarded
        addq.l  #4,%sp
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_promotion_begin_restore
.Lgk_promotion_begin_failure_discarded:
        move.l  (%sp)+,%d0
.Lgk_promotion_begin_restore:
        move.w  %d7,%sr
        movem.l (%sp),%d2-%d7/%a2-%a4
        lea     44(%sp),%sp
        rts
.Lgk_promotion_begin_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_begin_promotion,.-gk_descriptor_begin_promotion
        .global gk_workspace_finish_promotion
        .type   gk_workspace_finish_promotion,@function
gk_workspace_finish_promotion:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_promotion_finish_range
        cmpi.l  #0xff,%d1
        bhi.w   .Lgk_promotion_finish_range
        lea     -44(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        move.l  %d0,%d2
        move.l  %d1,%d3
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        move.l  %d3,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a3
        adda.l  %d0,%a3
        move.w  %sr,%d7
        .global gk_workspace_save_atomic_begin
gk_workspace_save_atomic_begin:
        move.w  #0x2700,%sr
        tst.l   __gk_persistence_snapshot_gate
        bne.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        andi.l  #0xfe,%d0
        bne.w   .Lgk_promotion_finish_corrupt
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_promotion_finish_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d6
        move.b  __gk_current_kit,%d6
        moveq   #0,%d4
        move.b  __gk_current_bank,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_bound,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d1
        move.b  __gk_promotion_assign,%d1
        cmpi.l  #1,%d1
        bhi.w   .Lgk_promotion_finish_corrupt
        move.l  %d1,40(%sp)
        tst.l   %d1
        bne.s   .Lgk_promotion_finish_mode_valid
        tst.l   %d0
        beq.w   .Lgk_promotion_finish_corrupt
        cmp.l   %d6,%d3
        bne.w   .Lgk_promotion_finish_corrupt
.Lgk_promotion_finish_mode_valid:
        move.l  %d3,%d0
        jsr     gk_undo_kit_validate_pending_save
        tst.l   %d0
        bne.w   .Lgk_promotion_finish_corrupt
        move.l  %d2,%d1
        lsl.l   #8,%d1
        ori.l   #0x00ff,%d1
        moveq   #0,%d5
        move.w  __gk_lease_sidecars,%d5
        cmp.l   %d5,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        move.l  %d2,%d1
        lsr.l   #3,%d1
        move.l  %d2,%d5
        andi.l  #7,%d5
        lea     __gk_descriptor_bitmap,%a0
        btst    %d5,(%a0,%d1.l)
        beq.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d5
        move.b  GK_DESC_FLAGS(%a2),%d5
        move.l  %d5,%d1
        andi.l  #0xef,%d1
        cmpi.l  #GK_DESC_WORKSPACE_PROMOTING,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_promotion_finish_corrupt
        cmpa.l  GK_DESC_CANDIDATE(%a2),%a3
        bne.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a2),%d1
        cmp.l   %d3,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d1
        move.w  GK_DESC_ROOTS(%a2),%d1
        cmpi.l  #2,%d1
        blo.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_KIT(%a2),%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d1
        move.b  __gk_workspace_dirty,%d1
        cmpi.l  #1,%d1
        bhi.w   .Lgk_promotion_finish_corrupt
        tst.l   %d1
        beq.s   .Lgk_promotion_finish_expect_clean
        btst    #4,%d5
        beq.w   .Lgk_promotion_finish_corrupt
        bra.s   .Lgk_promotion_finish_dirty_valid
.Lgk_promotion_finish_expect_clean:
        btst    #4,%d5
        bne.w   .Lgk_promotion_finish_corrupt
.Lgk_promotion_finish_dirty_valid:
        moveq   #0,%d5
        move.b  GK_DESC_PHYSICAL(%a2),%d5
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d5
        bhi.w   .Lgk_promotion_finish_corrupt
        move.l  %d5,%d1
        lsr.l   #2,%d1
        cmp.l   %d4,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        move.l  %d5,%d1
        lsl.l   #2,%d1
        lea     __gk_physical_payload_table,%a5
        move.l  (%a5,%d1.l),%a5
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a5
        bne.w   .Lgk_promotion_finish_corrupt
        move.l %d5,%d1
        andi.l #0xff,%d1
        lsl.l #2,%d1
        lea __gk_physical_cache,%a4
        adda.l %d1,%a4
        moveq   #0,%d1
        move.b  GK_PHYS_OWNER(%a4),%d1
        cmp.l   %d2,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d1
        move.b  GK_PHYS_KIT(%a4),%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        tst.b   GK_PHYS_STATE(%a4)
        bne.w   .Lgk_promotion_finish_corrupt
        moveq   #0,%d1
        move.b  GK_PHYS_RESERVED(%a4),%d1
        cmpi.l  #GK_ID_NONE,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        move.l  %d4,%d1
        lsl.l   #4,%d1
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        add.l   %d0,%d1
        lea     __gk_pattern_assignments,%a1
        adda.l  %d1,%a1
        moveq   #0,%d0
        move.b  (%a1),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_promotion_finish_corrupt
        tst.l   40(%sp)
        bne.s   .Lgk_promotion_finish_name_valid
        cmp.l   %d6,%d3
        bne.s   .Lgk_promotion_finish_name_valid
        tst.b   __gk_workspace_bound
        beq.s   .Lgk_promotion_finish_name_valid
        move.l  %d6,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a0
        adda.l  %d0,%a0
        move.l  (%a0),%d1
        cmp.l   __gk_workspace_name,%d1
        bne.w   .Lgk_promotion_finish_corrupt
        move.l  4(%a0),%d1
        cmp.l   __gk_workspace_name + 4,%d1
        bne.w   .Lgk_promotion_finish_corrupt
.Lgk_promotion_finish_name_valid:
        jsr     gk_workspace_save_as_latch_reader_validate
        tst.l   %d0
        bne.w   gk_workspace_finish_promotion_restore
        move.l  %d3,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a0
        adda.l  %d0,%a0
        .global gk_workspace_save_publication
gk_workspace_save_publication:
        move.l  __gk_workspace_name,%d0
        move.l  %d0,(%a0)
        move.l  __gk_workspace_name + 4,%d0
        move.l  %d0,4(%a0)
        move.l  %d3,%d0
        lsr.l   #3,%d0
        move.l  %d3,%d1
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        bset    %d1,(%a0,%d0.l)
        cmp.l   %d6,%d3
        beq.s   .Lgk_promotion_finish_kit_identity_done
        move.b  %d3,GK_DESC_KIT(%a2)
        move.b  %d3,GK_PHYS_KIT(%a4)
        move.b  %d3,__gk_current_kit
.Lgk_promotion_finish_kit_identity_done:
        tst.l   40(%sp)
        beq.s   .Lgk_promotion_finish_assignment_done
        move.b  %d3,(%a1)
        move.l  %d4,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  __gk_current_pattern,%d1
        add.l   %d1,%d0
        move.l  %d0,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        bset    %d1,(%a0,%d0.l)
        moveq   #1,%d0
        move.b  %d0,__gk_workspace_bound
.Lgk_promotion_finish_assignment_done:
        clr.l   GK_DESC_CANDIDATE(%a2)
        move.b  #GK_ID_NONE,GK_DESC_SPILL(%a2)
        move.b  #GK_DESC_WORKSPACE_STABLE,GK_DESC_FLAGS(%a2)
        clr.b   __gk_workspace_dirty
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        ori.l   #GK_RUNTIME_STORAGE_DIRTY,%d0
        move.b  %d0,__gk_runtime_flags
        moveq   #0,%d0
        move.b  __gk_undo_pending_owner,%d0
        cmpi.l  #GK_UNDO_PENDING_SAVE,%d0
        bne.s   .Lgk_promotion_finish_no_undo_capture
        move.l  __gk_undo_pending_name,%d0
        move.l  %d0,__gk_undo_kit_name
        move.l  __gk_undo_pending_name + 4,%d0
        move.l  %d0,__gk_undo_kit_name + 4
        move.l  __gk_undo_pending_payload_ptr,%d0
        move.l  %d0,__gk_undo_kit_payload_ptr
        move.b  __gk_undo_pending_kit,%d0
        move.b  %d0,__gk_undo_kit_kit
        move.b  __gk_undo_pending_bound,%d0
        move.b  %d0,__gk_undo_kit_bound
        clr.b   __gk_undo_kit_loading
        moveq   #1,%d0
        move.b  %d0,__gk_undo_kit_valid
        clr.b   __gk_undo_pending_owner
        clr.l   __gk_undo_pending_payload_ptr
        clr.l   __gk_undo_pending_name
        clr.l   __gk_undo_pending_name + 4
        clr.b   __gk_undo_pending_bound
        clr.b   __gk_undo_pending_kit
        clr.b   __gk_undo_pending_reserved
.Lgk_promotion_finish_no_undo_capture:
        move.l  %d3,%d0
        .global gk_workspace_save_v3_kit_dirty_call
gk_workspace_save_v3_kit_dirty_call:
        jsr     gk_persistence_v3_mark_kit_dirty
        tst.l   40(%sp)
        beq.s   .Lgk_promotion_finish_v3_dirty_done
        move.l  %d4,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  __gk_current_pattern,%d1
        add.l   %d1,%d0
        move.l  %d3,%d1
        .global gk_workspace_save_v3_assignment_dirty_call
gk_workspace_save_v3_assignment_dirty_call:
        jsr     gk_persistence_v3_mark_assignment_dirty
.Lgk_promotion_finish_v3_dirty_done:
        clr.b   __gk_promotion_assign
        moveq   #GK_OK,%d0
        bra.s   .Lgk_promotion_finish_restore
        .global gk_workspace_finish_promotion_busy
gk_workspace_finish_promotion_busy:
.Lgk_promotion_finish_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_promotion_finish_restore
        .global gk_workspace_finish_promotion_corrupt
gk_workspace_finish_promotion_corrupt:
.Lgk_promotion_finish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        .global gk_workspace_finish_promotion_restore
gk_workspace_finish_promotion_restore:
.Lgk_promotion_finish_restore:
        move.w  %d7,%sr
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     44(%sp),%sp
        rts
.Lgk_promotion_finish_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_workspace_finish_promotion,.-gk_workspace_finish_promotion
        .global gk_workspace_save_as_named
        .type   gk_workspace_save_as_named,@function
gk_workspace_save_as_named:
        cmpi.l  #0xff,%d0
        bhi.w   .Lgk_workspace_save_as_named_range
        tst.l   %a0
        beq.w   .Lgk_workspace_save_as_named_invalid
        lea     -28(%sp),%sp
        movem.l %d2-%d6,(%sp)
        move.l  %d0,%d4
        move.l  (%a0),%d5
        move.l  4(%a0),%d6
        andi.l  #0xffffff00,%d6
        move.l  __gk_workspace_name,%d2
        move.l  %d2,20(%sp)
        move.l  __gk_workspace_name + 4,%d2
        move.l  %d2,24(%sp)
        moveq   #0,%d3
        move.b  __gk_workspace_descriptor,%d3
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.s   .Lgk_workspace_save_as_named_invalid_restore
        move.l  %d3,%d0
        move.l  %d4,%d1
        moveq   #1,%d2
        bsr.w   gk_descriptor_begin_promotion
        tst.l   %d0
        bne.s   .Lgk_workspace_save_as_named_restore
        move.l  %d5,__gk_workspace_name
        move.l  %d6,__gk_workspace_name + 4
        move.l  %d3,%d0
        jsr     gk_descriptor_copy_payload
        tst.l   %d0
        beq.s   .Lgk_workspace_save_as_named_finish
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_workspace_save_as_named_restore
        bra.s   .Lgk_workspace_save_as_named_rollback
.Lgk_workspace_save_as_named_finish:
        move.l  %d3,%d0
        move.l %d3,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a0
        adda.l %d1,%a0
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a0),%d1
        bsr.w   gk_workspace_finish_promotion
        tst.l   %d0
        beq.s   .Lgk_workspace_save_as_named_restore
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_workspace_save_as_named_restore
.Lgk_workspace_save_as_named_rollback:
        move.l  20(%sp),%d2
        move.l  %d2,__gk_workspace_name
        move.l  24(%sp),%d2
        move.l  %d2,__gk_workspace_name + 4
        bra.s   .Lgk_workspace_save_as_named_restore
.Lgk_workspace_save_as_named_invalid_restore:
        moveq   #GK_ERR_INVALID,%d0
.Lgk_workspace_save_as_named_restore:
        movem.l (%sp),%d2-%d6
        lea     28(%sp),%sp
        rts
.Lgk_workspace_save_as_named_invalid:
        moveq   #GK_ERR_INVALID,%d0
        rts
.Lgk_workspace_save_as_named_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_workspace_save_as_named,.-gk_workspace_save_as_named
        .global gk_workspace_save_as
        .type   gk_workspace_save_as,@function
gk_workspace_save_as:
        cmpi.l  #0xff,%d0
        bhi.s   .Lgk_workspace_save_as_range
        moveq   #1,%d1
.Lgk_workspace_save_mode:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  %d0,%d2
        move.l  %d1,%d4
        moveq   #0,%d3
        move.b  __gk_workspace_descriptor,%d3
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.s   .Lgk_workspace_save_as_invalid
        move.l  %d3,%d0
        move.l  %d2,%d1
        move.l  %d4,%d2
        bsr.w   gk_descriptor_begin_promotion
        tst.l   %d0
        bne.s   .Lgk_workspace_save_as_restore
        move.l  %d3,%d0
        jsr     gk_descriptor_copy_payload
        tst.l   %d0
        bne.s   .Lgk_workspace_save_as_restore
        move.l  %d3,%d0
        move.l %d3,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a0
        adda.l %d1,%a0
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a0),%d1
        bsr.w   gk_workspace_finish_promotion
        bra.s   .Lgk_workspace_save_as_restore
.Lgk_workspace_save_as_invalid:
        moveq   #GK_ERR_INVALID,%d0
.Lgk_workspace_save_as_restore:
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts
.Lgk_workspace_save_as_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_workspace_save_as,.-gk_workspace_save_as
        .global gk_workspace_save
        .type   gk_workspace_save,@function
gk_workspace_save:
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        moveq   #0,%d1
        bra.w   .Lgk_workspace_save_mode
        .size   gk_workspace_save,.-gk_workspace_save
        .global gk_workspace_resume_promotion
        .type   gk_workspace_resume_promotion,@function
gk_workspace_resume_promotion:
        lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
        moveq   #0,%d2
        move.b  __gk_workspace_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.s   .Lgk_workspace_resume_invalid
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        andi.l  #0xef,%d0
        cmpi.l  #GK_DESC_WORKSPACE_PROMOTING,%d0
        bne.s   .Lgk_workspace_resume_invalid
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        moveq   #0,%d1
        move.b  __gk_promotion_assign,%d1
        bsr.w   .Lgk_workspace_save_mode
        bra.s   .Lgk_workspace_resume_restore
.Lgk_workspace_resume_invalid:
        moveq   #GK_ERR_INVALID,%d0
.Lgk_workspace_resume_restore:
        movem.l (%sp),%d2/%a2
        addq.l  #8,%sp
        rts
        .size   gk_workspace_resume_promotion,.-gk_workspace_resume_promotion
        .global gk_workspace_rename
        .type   gk_workspace_rename,@function
gk_workspace_rename:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .global gk_workspace_rename_publication
gk_workspace_rename_publication:
        .size   gk_workspace_rename,.-gk_workspace_rename
