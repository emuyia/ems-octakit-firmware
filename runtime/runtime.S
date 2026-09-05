        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_runtime_metadata_reset
        .type   gk_runtime_metadata_reset,@function
gk_runtime_metadata_reset:
        clr.l   __gk_lifecycle_state
        .global gk_runtime_metadata_reset_preserve_lifecycle
gk_runtime_metadata_reset_preserve_lifecycle:
        lea     __gk_metadata_start,%a0
        moveq   #0,%d0
        move.l  #(GK_METADATA_SIZE / 4),%d1
.Lgk_reset_zero:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_reset_zero
        lea     __gk_ui_start,%a0
        move.l  #(GK_UI_SIZE / 4),%d1
.Lgk_reset_ui:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_reset_ui
        lea     __gk_lease_sidecars,%a0
        moveq   #-1,%d0
        moveq   #(0x100 / 4),%d1
.Lgk_reset_sidecars:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_reset_sidecars
        lea     __gk_physical_cache,%a0
        moveq   #(0x100 / 4),%d1
.Lgk_reset_physical:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_reset_physical
        move.l  %d0,__gk_workspace_descriptor
        move.l  %d0,__gk_pending_workspace_descriptor
        move.b  %d0,__gk_persistence_work_slot
        move.b  %d0,__gk_persistence_stored_slot
        clr.b   __gk_kit_clipboard_valid
        clr.b   __gk_kit_clipboard_occupied
        clr.b   __gk_kit_undo_valid
        clr.b   __gk_kit_undo_occupied
        clr.b   __gk_kit_undo_action
        clr.b   __gk_kit_undo_target
        moveq   #GK_OK,%d0
        rts
        .size   gk_runtime_metadata_reset,.-gk_runtime_metadata_reset
        .global gk_selector_begin_update
        .type   gk_selector_begin_update,@function
gk_selector_begin_update:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_begin_range
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_begin_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.s   .Lgk_begin_corrupt
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a0),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.s   .Lgk_begin_busy
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a1),%d0
        cmpi.l  #0xffff,%d0
        beq.s   .Lgk_begin_overflow
        addq.l  #1,%d0
        move.w  %d0,GK_DESC_ROOTS(%a1)
        .global gk_selector_begin_publication
gk_selector_begin_publication:
        move.b  %d2,GK_SIDECAR_PENDING(%a0)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_begin_restore
.Lgk_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_begin_restore
.Lgk_begin_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_begin_restore
.Lgk_begin_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
.Lgk_begin_restore:
        move.w  %d1,%sr
        move.l  (%sp)+,%d2
        rts
.Lgk_begin_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_selector_begin_update,.-gk_selector_begin_update
        .global gk_selector_commit_update
        .type   gk_selector_commit_update,@function
gk_selector_commit_update:
        lea     -12(%sp),%sp
        movem.l %d2-%d3/%a2,(%sp)
        move.w  %sr,%d3
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a0),%d0
        cmpi.b  #GK_ID_NONE,%d0
        beq.w   .Lgk_commit_busy
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_commit_corrupt
        move.l %d0,%d2
        andi.l #0xff,%d2
        lsl.l #4,%d2
        lea __gk_descriptors,%a1
        adda.l %d2,%a1
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_commit_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.w   .Lgk_commit_corrupt
        moveq   #0,%d2
        move.w  GK_DESC_ROOTS(%a1),%d2
        tst.l   %d2
        beq.w   .Lgk_commit_underflow
        move.l  %d2,%d1
        moveq   #0,%d2
        move.b  GK_SIDECAR_CURRENT(%a0),%d2
        suba.l  %a2,%a2
        cmpi.b  #GK_ID_NONE,%d2
        beq.w   .Lgk_commit_publish
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_commit_corrupt
        cmp.l   %d0,%d2
        bne.s   .Lgk_commit_distinct_old
        cmpi.l  #2,%d1
        blo.w   .Lgk_commit_underflow
        move.l  %a1,%a2
        bra.s   .Lgk_commit_publish
.Lgk_commit_distinct_old:
        move.l %d2,%d2
        andi.l #0xff,%d2
        lsl.l #4,%d2
        lea __gk_descriptors,%a2
        adda.l %d2,%a2
        btst    #0,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_commit_corrupt
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_commit_corrupt
        moveq   #0,%d2
        move.w  GK_DESC_ROOTS(%a2),%d2
        tst.l   %d2
        beq.w   .Lgk_commit_underflow
.Lgk_commit_publish:
        lsl.l   #8,%d0
        ori.l   #0x00ff,%d0
        .global gk_selector_commit_publication
gk_selector_commit_publication:
        move.w  %d0,(%a0)
        tst.l   %a2
        beq.s   .Lgk_commit_success
        moveq   #0,%d2
        move.w  GK_DESC_ROOTS(%a2),%d2
        subq.l  #1,%d2
        move.w  %d2,GK_DESC_ROOTS(%a2)
.Lgk_commit_success:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_commit_restore
.Lgk_commit_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_commit_restore
.Lgk_commit_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_commit_restore
.Lgk_commit_underflow:
        moveq   #GK_ERR_UNDERFLOW,%d0
.Lgk_commit_restore:
        move.w  %d3,%sr
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        rts
        .size   gk_selector_commit_update,.-gk_selector_commit_update
        .global gk_selector_abort_update
        .type   gk_selector_abort_update,@function
gk_selector_abort_update:
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a0),%d0
        cmpi.b  #GK_ID_NONE,%d0
        beq.s   .Lgk_abort_busy
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_abort_corrupt
        move.l %d0,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_abort_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a1),%d0
        tst.l   %d0
        beq.s   .Lgk_abort_underflow
        .global gk_selector_abort_publication
gk_selector_abort_publication:
        move.b  #GK_ID_NONE,GK_SIDECAR_PENDING(%a0)
        subq.l  #1,%d0
        move.w  %d0,GK_DESC_ROOTS(%a1)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_abort_restore
.Lgk_abort_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_abort_restore
.Lgk_abort_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_abort_restore
.Lgk_abort_underflow:
        moveq   #GK_ERR_UNDERFLOW,%d0
.Lgk_abort_restore:
        move.w  %d1,%sr
        rts
        .size   gk_selector_abort_update,.-gk_selector_abort_update
        .global gk_selector_invalidate
        .type   gk_selector_invalidate,@function
gk_selector_invalidate:
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a0),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.s   .Lgk_invalidate_busy
        moveq   #0,%d0
        move.b  GK_SIDECAR_CURRENT(%a0),%d0
        cmpi.b  #GK_ID_NONE,%d0
        beq.s   .Lgk_invalidate_success
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_invalidate_corrupt
        move.l %d0,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_invalidate_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a1),%d0
        tst.l   %d0
        beq.s   .Lgk_invalidate_underflow
        .global gk_selector_invalidate_publication
gk_selector_invalidate_publication:
        move.w  #0xffff,(%a0)
        subq.l  #1,%d0
        move.w  %d0,GK_DESC_ROOTS(%a1)
.Lgk_invalidate_success:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_invalidate_restore
.Lgk_invalidate_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_invalidate_restore
.Lgk_invalidate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_invalidate_restore
.Lgk_invalidate_underflow:
        moveq   #GK_ERR_UNDERFLOW,%d0
.Lgk_invalidate_restore:
        move.w  %d1,%sr
        rts
        .size   gk_selector_invalidate,.-gk_selector_invalidate
        .global gk_selector_acquire
        .type   gk_selector_acquire,@function
gk_selector_acquire:
        move.l  %d2,-(%sp)
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        .global gk_selector_acquire_snapshot
gk_selector_acquire_snapshot:
        move.w  (%a0),%d0
        cmpi.b  #GK_ID_NONE,%d0
        bne.s   .Lgk_acquire_updating
        lsr.l   #8,%d0
        andi.l  #0xff,%d0
        cmpi.b  #GK_ID_NONE,%d0
        beq.s   .Lgk_acquire_invalid
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_acquire_corrupt
        move.l %d0,%d2
        andi.l #0xff,%d2
        lsl.l #4,%d2
        lea __gk_descriptors,%a1
        adda.l %d2,%a1
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_acquire_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.s   .Lgk_acquire_corrupt
        moveq   #0,%d2
        move.w  GK_DESC_ROOTS(%a1),%d2
        tst.l   %d2
        beq.s   .Lgk_acquire_corrupt
        moveq   #0,%d2
        move.w  GK_DESC_READERS(%a1),%d2
        cmpi.l  #0xffff,%d2
        beq.s   .Lgk_acquire_overflow
        addq.l  #1,%d2
        move.w  %d2,GK_DESC_READERS(%a1)
        move.l  GK_DESC_PAYLOAD(%a1),%a0
        bra.s   .Lgk_acquire_restore
.Lgk_acquire_invalid:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_acquire_restore
.Lgk_acquire_updating:
        moveq   #GK_ERR_UPDATING,%d0
        bra.s   .Lgk_acquire_restore
.Lgk_acquire_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
        bra.s   .Lgk_acquire_restore
.Lgk_acquire_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_acquire_restore:
        move.w  %d1,%sr
        move.l  (%sp)+,%d2
        rts
        .size   gk_selector_acquire,.-gk_selector_acquire
        .global gk_descriptor_release
        .type   gk_descriptor_release,@function
gk_descriptor_release:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_release_range
        move.l %d0,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a1
        adda.l %d1,%a1
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_release_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_READERS(%a1),%d0
        tst.l   %d0
        beq.s   .Lgk_release_underflow
        subq.l  #1,%d0
        move.w  %d0,GK_DESC_READERS(%a1)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_release_restore
.Lgk_release_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_release_restore
.Lgk_release_underflow:
        moveq   #GK_ERR_UNDERFLOW,%d0
.Lgk_release_restore:
        move.w  %d1,%sr
        rts
.Lgk_release_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_release,.-gk_descriptor_release
        .global gk_descriptor_begin_copy
        .type   gk_descriptor_begin_copy,@function
gk_descriptor_begin_copy:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_copy_begin_range
        cmpi.l  #GK_SPILL_COUNT - 1,%d1
        bhi.w   .Lgk_copy_begin_range
        tst.l   %a0
        beq.w   .Lgk_copy_begin_range
        lea     -12(%sp),%sp
        movem.l %d2-%d3/%a2,(%sp)
        move.l  %d1,%d2
        move.l %d0,%d3
        andi.l #0xff,%d3
        lsl.l #4,%d3
        lea __gk_descriptors,%a1
        adda.l %d3,%a1
        move.w  %sr,%d3
        move.w  #0x2700,%sr
        move.l  %d2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_spill_payloads,%a2
        adda.l  %d0,%a2
        cmpa.l  %a2,%a0
        bne.s   .Lgk_copy_begin_argument
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_copy_begin_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a1),%d0
        andi.l  #0xe0,%d0
        bne.s   .Lgk_copy_begin_corrupt
        btst    #2,GK_DESC_FLAGS(%a1)
        bne.s   .Lgk_copy_begin_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.s   .Lgk_copy_begin_corrupt
        tst.w   GK_DESC_ROOTS(%a1)
        beq.s   .Lgk_copy_begin_busy
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a1),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.s   .Lgk_copy_begin_corrupt
        tst.l   GK_DESC_CANDIDATE(%a1)
        bne.s   .Lgk_copy_begin_busy
        btst    #1,GK_DESC_FLAGS(%a1)
        bne.s   .Lgk_copy_begin_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a1),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.s   .Lgk_copy_begin_corrupt
        move.l  %a0,GK_DESC_CANDIDATE(%a1)
        move.b  %d2,GK_DESC_SPILL(%a1)
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a1),%d0
        ori.l   #GK_DESC_COPYING,%d0
        move.b  %d0,GK_DESC_FLAGS(%a1)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_copy_begin_restore
.Lgk_copy_begin_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_copy_begin_restore
.Lgk_copy_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_copy_begin_restore
.Lgk_copy_begin_argument:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_copy_begin_restore:
        move.w  %d3,%sr
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        rts
.Lgk_copy_begin_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_begin_copy,.-gk_descriptor_begin_copy
        .global gk_copy_payload_interruptible
        .type   gk_copy_payload_interruptible,@function
gk_copy_payload_interruptible:
        move.l  #(GK_PART_PAYLOAD_SIZE / 4),%d0
        .global gk_copy_payload_long_loop
gk_copy_payload_long_loop:
        move.l  (%a0)+,(%a1)+
        subq.l  #1,%d0
        bne.s   gk_copy_payload_long_loop
        .global gk_copy_payload_tail
gk_copy_payload_tail:
        move.w  (%a0)+,(%a1)+
        rts
        .size   gk_copy_payload_interruptible,.-gk_copy_payload_interruptible
        .global gk_descriptor_copy_payload
        .type   gk_descriptor_copy_payload,@function
gk_descriptor_copy_payload:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_copy_payload_range
        lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
        move.l %d0,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a2
        adda.l %d1,%a2
        btst    #0,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_copy_payload_corrupt
        btst    #1,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_copy_payload_busy
        moveq   #0,%d1
        move.b  GK_DESC_FLAGS(%a2),%d1
        move.l  %d1,%d2
        andi.l  #0x80,%d2
        bne.w   .Lgk_copy_payload_corrupt
        btst    #2,%d1
        bne.w   .Lgk_copy_payload_corrupt
        move.l  GK_DESC_PAYLOAD(%a2),%a0
        tst.l   %a0
        beq.w   .Lgk_copy_payload_corrupt
        move.l  GK_DESC_CANDIDATE(%a2),%a1
        tst.l   %a1
        beq.w   .Lgk_copy_payload_corrupt
        btst    #6,%d1
        bne.s   .Lgk_copy_payload_promotion
        btst    #5,%d1
        bne.s   .Lgk_copy_payload_clone
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a2),%d1
        cmpi.l  #GK_SPILL_COUNT - 1,%d1
        bhi.w   .Lgk_copy_payload_corrupt
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d1
        move.l  %a1,%d2
        subi.l  #__gk_spill_payloads,%d2
        cmp.l   %d1,%d2
        bne.w   .Lgk_copy_payload_corrupt
        bra.s   .Lgk_copy_payload_validated
.Lgk_copy_payload_promotion:
        btst    #5,%d1
        bne.w   .Lgk_copy_payload_corrupt
        btst    #3,%d1
        beq.w   .Lgk_copy_payload_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a2),%d1
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d1
        lea     __gk_canonical_payloads,%a0
        adda.l  %d1,%a0
        cmpa.l  %a1,%a0
        bne.w   .Lgk_copy_payload_corrupt
        move.l  GK_DESC_PAYLOAD(%a2),%a0
        bra.s   .Lgk_copy_payload_validated
.Lgk_copy_payload_clone:
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a2),%d1
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_copy_payload_corrupt
        moveq   #0,%d2
        move.b  GK_DESC_PHYSICAL(%a2),%d2
        cmp.l   %d2,%d1
        beq.w   .Lgk_copy_payload_corrupt
        lsl.l   #2,%d1
        move.l  %a0,%d2
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d1.l),%a0
        cmpa.l  %a1,%a0
        bne.w   .Lgk_copy_payload_corrupt
        move.l  %d2,%a0
.Lgk_copy_payload_validated:
        bsr.w   gk_copy_payload_interruptible
        moveq   #GK_OK,%d0
        bra.s   .Lgk_copy_payload_restore
.Lgk_copy_payload_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_copy_payload_restore
.Lgk_copy_payload_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_copy_payload_restore:
        movem.l (%sp),%d2/%a2
        lea     8(%sp),%sp
        rts
.Lgk_copy_payload_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_copy_payload,.-gk_descriptor_copy_payload
        .global gk_descriptor_finish_copy
        .type   gk_descriptor_finish_copy,@function
gk_descriptor_finish_copy:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_copy_finish_range
        move.l  %d2,-(%sp)
        move.l %d0,%d2
        andi.l #0xff,%d2
        lsl.l #4,%d2
        lea __gk_descriptors,%a1
        adda.l %d2,%a1
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_copy_finish_corrupt
        btst    #1,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_copy_finish_busy
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a1),%d0
        andi.l  #0xe0,%d0
        bne.w   .Lgk_copy_finish_corrupt
        btst    #2,GK_DESC_FLAGS(%a1)
        bne.w   .Lgk_copy_finish_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.w   .Lgk_copy_finish_corrupt
        tst.l   GK_DESC_CANDIDATE(%a1)
        beq.w   .Lgk_copy_finish_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_PHYSICAL(%a1),%d1
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_copy_finish_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a1),%d0
        cmpi.l  #GK_SPILL_ALLOC_COUNT - 1,%d0
        bhi.w   .Lgk_copy_finish_corrupt
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_spill_payloads,%a0
        adda.l  %d0,%a0
        cmpa.l  GK_DESC_CANDIDATE(%a1),%a0
        bne.w   .Lgk_copy_finish_corrupt
        tst.w   GK_DESC_READERS(%a1)
        bne.s   .Lgk_copy_finish_busy
        .global gk_descriptor_spill_publication
gk_descriptor_spill_publication:
        move.l  GK_DESC_CANDIDATE(%a1),GK_DESC_PAYLOAD(%a1)
        clr.l   GK_DESC_CANDIDATE(%a1)
        move.b  #GK_ID_NONE,GK_DESC_PHYSICAL(%a1)
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a1),%d0
        andi.l  #0xfd,%d0
        ori.l   #GK_DESC_SPILLED,%d0
        move.b  %d0,GK_DESC_FLAGS(%a1)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_copy_finish_restore
.Lgk_copy_finish_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_copy_finish_restore
.Lgk_copy_finish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_copy_finish_restore:
        move.w  %d2,%sr
        move.l  (%sp)+,%d2
        rts
.Lgk_copy_finish_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_finish_copy,.-gk_descriptor_finish_copy
        .global gk_descriptor_store_byte
        .type   gk_descriptor_store_byte,@function
gk_descriptor_store_byte:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_store_range
        cmpi.l  #GK_PART_PAYLOAD_SIZE - 1,%d1
        bhi.w   .Lgk_store_range
        lea     -12(%sp),%sp
        movem.l %d3-%d4/%a2,(%sp)
        move.l  %d0,%d4
        move.l %d0,%d3
        andi.l #0xff,%d3
        lsl.l #4,%d3
        lea __gk_descriptors,%a2
        adda.l %d3,%a2
        btst    #0,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_store_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d3
        andi.l  #0x80,%d3
        bne.w   .Lgk_store_corrupt
        moveq   #0,%d3
        move.b  __gk_workspace_descriptor,%d3
        btst    #3,%d0
        beq.s   .Lgk_store_not_workspace
        cmp.l   %d4,%d3
        bne.w   .Lgk_store_corrupt
        moveq   #0,%d3
        move.b  __gk_workspace_dirty,%d3
        cmpi.l  #1,%d3
        bhi.w   .Lgk_store_corrupt
        tst.l   %d3
        beq.s   .Lgk_store_workspace_expect_clean
        btst    #4,%d0
        beq.w   .Lgk_store_corrupt
        bra.s   .Lgk_store_workspace_valid
.Lgk_store_workspace_expect_clean:
        btst    #4,%d0
        bne.w   .Lgk_store_corrupt
        bra.s   .Lgk_store_workspace_valid
.Lgk_store_not_workspace:
        cmp.l   %d4,%d3
        beq.w   .Lgk_store_corrupt
.Lgk_store_workspace_valid:
        tst.w   GK_DESC_READERS(%a2)
        beq.w   .Lgk_store_unpinned
        move.l  GK_DESC_PAYLOAD(%a2),%a0
        tst.l   %a0
        beq.w   .Lgk_store_corrupt
        move.l  GK_DESC_CANDIDATE(%a2),%a1
        btst    #1,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_store_no_copy
        tst.l   %a1
        beq.w   .Lgk_store_corrupt
        btst    #2,%d0
        bne.w   .Lgk_store_corrupt
        btst    #6,%d0
        bne.s   .Lgk_store_promotion
        btst    #5,%d0
        bne.s   .Lgk_store_clone
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_SPILL_COUNT - 1,%d0
        bhi.w   .Lgk_store_corrupt
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        move.l  %a1,%d3
        subi.l  #__gk_spill_payloads,%d3
        cmp.l   %d0,%d3
        bne.w   .Lgk_store_corrupt
        bra.s   .Lgk_store_validated
.Lgk_store_promotion:
        btst    #5,%d0
        bne.w   .Lgk_store_corrupt
        btst    #3,%d0
        beq.w   .Lgk_store_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        move.l  %a0,%d3
        lea     __gk_canonical_payloads,%a0
        adda.l  %d0,%a0
        cmpa.l  %a1,%a0
        bne.w   .Lgk_store_corrupt
        move.l  %d3,%a0
        bra.s   .Lgk_store_validated
.Lgk_store_clone:
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_store_corrupt
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a2),%d3
        cmp.l   %d3,%d0
        beq.w   .Lgk_store_corrupt
        lsl.l   #2,%d0
        move.l  %a0,%d3
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  %a1,%a0
        bne.w   .Lgk_store_corrupt
        move.l  %d3,%a0
        bra.s   .Lgk_store_validated
.Lgk_store_no_copy:
        tst.l   %a1
        bne.w   .Lgk_store_corrupt
        btst    #5,%d0
        bne.w   .Lgk_store_corrupt
        btst    #6,%d0
        bne.w   .Lgk_store_corrupt
.Lgk_store_validated:
        adda.l  %d1,%a0
        move.b  %d2,(%a0)
        tst.l   %a1
        beq.s   .Lgk_store_mark_dirty
        adda.l  %d1,%a1
        move.b  %d2,(%a1)
.Lgk_store_mark_dirty:
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        ori.l   #GK_DESC_DIRTY,%d0
        move.b  %d0,GK_DESC_FLAGS(%a2)
        btst    #3,%d0
        beq.w   .Lgk_store_dirty_complete
        moveq   #1,%d3
        move.b  %d3,__gk_workspace_dirty
.Lgk_store_dirty_complete:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_store_restore
.Lgk_store_unpinned:
        moveq   #GK_ERR_UNDERFLOW,%d0
        bra.s   .Lgk_store_restore
.Lgk_store_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_store_restore:
        movem.l (%sp),%d3-%d4/%a2
        lea     12(%sp),%sp
        rts
.Lgk_store_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_store_byte,.-gk_descriptor_store_byte
