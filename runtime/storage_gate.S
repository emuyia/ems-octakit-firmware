        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_persistence_snapshot_begin
        .type   gk_persistence_snapshot_begin,@function
gk_persistence_snapshot_begin:
        moveq   #0,%d0
        bra.s   .Lgk_snapshot_begin_common
        .global gk_persistence_work_snapshot_begin
        .type   gk_persistence_work_snapshot_begin,@function
gk_persistence_work_snapshot_begin:
        moveq   #1,%d0
.Lgk_snapshot_begin_common:
        .incbin "stock/0189.bin", 0, 4
        .incbin "stock/0189.bin", 4, 4
        move.l  %d0,%d5
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_snapshot_lifecycle_valid
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   .Lgk_snapshot_corrupt
.Lgk_snapshot_lifecycle_valid:
        moveq   #0,%d0
        move.b  __gk_undo_pending_owner,%d0
        cmpi.l  #GK_UNDO_PENDING_SAVE,%d0
        bhi.w   .Lgk_snapshot_corrupt
        tst.l   %d0
        bne.w   .Lgk_snapshot_busy
        tst.l   %d5
        beq.s   .Lgk_snapshot_mode_lifecycle_valid
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_snapshot_busy
.Lgk_snapshot_mode_lifecycle_valid:
        moveq   #0,%d0
        move.b  __gk_persistence_reserved,%d0
        cmpi.l  #GK_PERSIST_RELOAD_MAX,%d0
        bhi.w   .Lgk_snapshot_corrupt
        tst.l   %d0
        bne.w   .Lgk_snapshot_busy
        move.l  __gk_persistence_snapshot_gate,%d0
        tst.l   %d0
        beq.s   .Lgk_snapshot_gate_free
        cmpi.l  #GK_PERSIST_SNAPSHOT_ACTIVE,%d0
        beq.w   .Lgk_snapshot_busy
        bra.w   .Lgk_snapshot_corrupt
.Lgk_snapshot_gate_free:
        tst.l   __gk_persistence_snapshot_reserved
        bne.w   .Lgk_snapshot_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_snapshot_corrupt
        btst    #7,%d0
        bne.w   .Lgk_snapshot_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_snapshot_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_snapshot_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_snapshot_corrupt
        lea     __gk_descriptors,%a2
        move.l  #GK_DESCRIPTOR_COUNT,%d2
.Lgk_snapshot_descriptor_loop:
        moveq   #0,%d3
        move.b  GK_DESC_FLAGS(%a2),%d3
        btst    #7,%d3
        bne.s   .Lgk_snapshot_corrupt
        btst    #6,%d3
        bne.s   .Lgk_snapshot_busy
        lea     GK_DESC_SIZE(%a2),%a2
        subq.l  #1,%d2
        bne.s   .Lgk_snapshot_descriptor_loop
        tst.l   %d5
        beq.s   .Lgk_snapshot_publish_gate
        lea     __gk_pattern_assignments,%a0
        lea     __gk_io_buffer + GK_ASSIGNMENT_BUFFER_OFFSET,%a2
        move.l  #(GK_ASSIGNMENT_BUFFER_SIZE / 4),%d2
.Lgk_work_snapshot_assignment_copy:
        move.l  (%a0)+,(%a2)+
        subq.l  #1,%d2
        bne.s   .Lgk_work_snapshot_assignment_copy
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        andi.l  #0xfe,%d0
        move.b  %d0,__gk_runtime_flags
        move.l  #GK_PERSIST_SNAPSHOT_WORK_ACTIVE,%d0
        .global gk_persistence_work_snapshot_publication
gk_persistence_work_snapshot_publication:
        move.l  %d0,__gk_persistence_snapshot_reserved
.Lgk_snapshot_publish_gate:
        move.l  #GK_PERSIST_SNAPSHOT_ACTIVE,%d0
        .global gk_persistence_snapshot_publication
gk_persistence_snapshot_publication:
        move.l  %d0,__gk_persistence_snapshot_gate
        moveq   #GK_OK,%d0
        bra.s   .Lgk_snapshot_restore
.Lgk_snapshot_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_snapshot_restore
.Lgk_snapshot_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_snapshot_restore:
        move.w  %d4,%sr
        movem.l (%sp),%d2-%d5/%a2
        lea     20(%sp),%sp
        rts
        .size   gk_persistence_work_snapshot_begin,.-gk_persistence_work_snapshot_begin
        .size   gk_persistence_snapshot_begin,.-gk_persistence_snapshot_begin
        .global gk_persistence_snapshot_end
        .type   gk_persistence_snapshot_end,@function
gk_persistence_snapshot_end:
        move.l  %d2,-(%sp)
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        move.l  __gk_persistence_snapshot_gate,%d0
        cmpi.l  #GK_PERSIST_SNAPSHOT_ACTIVE,%d0
        bne.s   .Lgk_snapshot_end_corrupt
        move.l  __gk_persistence_snapshot_reserved,%d0
        tst.l   %d0
        beq.s   .Lgk_snapshot_end_reserved_valid
        cmpi.l  #GK_PERSIST_SNAPSHOT_WORK_ACTIVE,%d0
        bne.s   .Lgk_snapshot_end_corrupt
.Lgk_snapshot_end_reserved_valid:
        clr.l   __gk_persistence_snapshot_reserved
        .global gk_persistence_snapshot_release
gk_persistence_snapshot_release:
        clr.l   __gk_persistence_snapshot_gate
        moveq   #GK_OK,%d0
        bra.s   .Lgk_snapshot_end_restore
.Lgk_snapshot_end_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_snapshot_end_restore:
        move.w  %d2,%sr
        move.l  (%sp)+,%d2
        rts
        .size   gk_persistence_snapshot_end,.-gk_persistence_snapshot_end
