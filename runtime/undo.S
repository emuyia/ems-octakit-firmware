        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_undo_kit_active_payload
        .type   gk_undo_kit_active_payload,@function
gk_undo_kit_active_payload:
        tst.b   __gk_undo_kit_valid
        beq.s   .Lgk_undo_active_invalid
        moveq   #0,%d0
        move.b  __gk_undo_kit_bound,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_undo_active_corrupt
        moveq   #0,%d0
        move.b  __gk_undo_kit_loading,%d0
        cmpi.l  #1,%d0
        bhi.s   .Lgk_undo_active_corrupt
        tst.b   __gk_undo_pending_owner
        bne.s   .Lgk_undo_active_busy
        movea.l __gk_undo_kit_payload_ptr,%a0
        cmpa.l  #__gk_undo_kit_payload_a,%a0
        beq.s   .Lgk_undo_active_ok
        cmpa.l  #__gk_undo_kit_payload_b,%a0
        bne.s   .Lgk_undo_active_corrupt
.Lgk_undo_active_ok:
        moveq   #GK_OK,%d0
        rts
.Lgk_undo_active_invalid:
        moveq   #GK_ERR_INVALID,%d0
        rts
.Lgk_undo_active_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
.Lgk_undo_active_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_undo_kit_active_payload,.-gk_undo_kit_active_payload
        .global gk_undo_kit_capture_workspace
        .type   gk_undo_kit_capture_workspace,@function
gk_undo_kit_capture_workspace:
        .incbin "stock/0199.bin", 0, 4
        .incbin "stock/0199.bin", 4, 4
        tst.b   __gk_workspace_bound
        beq.w   .Lgk_undo_workspace_ok
        tst.b   __gk_undo_kit_loading
        bne.w   .Lgk_undo_workspace_busy
        tst.b   __gk_undo_pending_owner
        bne.w   .Lgk_undo_workspace_busy
        moveq   #0,%d2
        move.b  __gk_workspace_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_undo_workspace_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0xef,%d1
        cmpi.l  #GK_DESC_WORKSPACE_STABLE,%d1
        bne.w   .Lgk_undo_workspace_corrupt
        moveq   #0,%d3
        move.b  __gk_current_kit,%d3
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a2),%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_undo_workspace_corrupt
        lea     __gk_undo_kit_payload_a,%a4
        moveq   #GK_UNDO_SPILL_A_ID,%d4
        tst.b   __gk_undo_kit_valid
        beq.s   .Lgk_undo_workspace_inactive_ready
        movea.l __gk_undo_kit_payload_ptr,%a3
        cmpa.l  #__gk_undo_kit_payload_a,%a3
        bne.s   .Lgk_undo_workspace_active_b
        lea     __gk_undo_kit_payload_b,%a4
        moveq   #GK_UNDO_SPILL_B_ID,%d4
        bra.s   .Lgk_undo_workspace_inactive_ready
.Lgk_undo_workspace_active_b:
        cmpa.l  #__gk_undo_kit_payload_b,%a3
        bne.w   .Lgk_undo_workspace_corrupt
.Lgk_undo_workspace_inactive_ready:
        movea.l %a4,%a0
        move.l  %d4,%d1
        move.l  %d2,%d0
        jsr     gk_descriptor_begin_copy
        tst.l   %d0
        bne.w   .Lgk_undo_workspace_restore
        move.l  %d2,%d0
        jsr     gk_descriptor_copy_payload
        tst.l   %d0
        bne.w   .Lgk_undo_workspace_restore
        move.w  %sr,%d5
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0xef,%d1
        cmpi.l  #0x0b,%d1
        bne.s   .Lgk_undo_workspace_finish_corrupt
        cmpa.l  GK_DESC_CANDIDATE(%a2),%a4
        bne.s   .Lgk_undo_workspace_finish_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a2),%d1
        cmp.l   %d4,%d1
        bne.s   .Lgk_undo_workspace_finish_corrupt
        tst.b   __gk_undo_pending_owner
        bne.s   .Lgk_undo_workspace_finish_corrupt
        tst.b   __gk_undo_kit_loading
        bne.s   .Lgk_undo_workspace_finish_corrupt
        clr.l   GK_DESC_CANDIDATE(%a2)
        move.b  #GK_ID_NONE,GK_DESC_SPILL(%a2)
        andi.l  #0xfd,%d0
        move.b  %d0,GK_DESC_FLAGS(%a2)
        move.l  __gk_workspace_name,%d0
        move.l  %d0,__gk_undo_pending_name
        move.l  __gk_workspace_name + 4,%d0
        move.l  %d0,__gk_undo_pending_name + 4
        move.l  %a4,__gk_undo_pending_payload_ptr
        move.b  %d3,__gk_undo_pending_kit
        moveq   #1,%d0
        move.b  %d0,__gk_undo_pending_bound
        clr.b   __gk_undo_pending_reserved
        moveq   #GK_UNDO_PENDING_WORKSPACE,%d0
        move.b  %d0,__gk_undo_pending_owner
        move.w  %d5,%sr
.Lgk_undo_workspace_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_undo_workspace_restore
.Lgk_undo_workspace_finish_corrupt:
        move.w  %d5,%sr
.Lgk_undo_workspace_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_undo_workspace_restore
.Lgk_undo_workspace_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_undo_workspace_restore:
        movem.l (%sp),%d2-%d5/%a2-%a4
        lea     28(%sp),%sp
        rts
        .size   gk_undo_kit_capture_workspace,.-gk_undo_kit_capture_workspace
        .global gk_undo_kit_capture_save_target
        .type   gk_undo_kit_capture_save_target,@function
gk_undo_kit_capture_save_target:
        cmpi.l  #GK_KIT_COUNT - 1,%d0
        bhi.w   .Lgk_undo_save_range
        .incbin "stock/0200.bin", 0, 4
        .incbin "stock/0200.bin", 4, 4
        move.l  %d0,%d2
        move.l  %d1,%d5
        tst.b   __gk_undo_kit_loading
        bne.w   .Lgk_undo_save_busy
        tst.b   __gk_undo_pending_owner
        bne.w   .Lgk_undo_save_busy
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.w   .Lgk_undo_save_ok
        lea     __gk_undo_kit_payload_a,%a4
        tst.b   __gk_undo_kit_valid
        beq.s   .Lgk_undo_save_inactive_ready
        movea.l __gk_undo_kit_payload_ptr,%a3
        cmpa.l  #__gk_undo_kit_payload_a,%a3
        bne.s   .Lgk_undo_save_active_b
        lea     __gk_undo_kit_payload_b,%a4
        bra.s   .Lgk_undo_save_inactive_ready
.Lgk_undo_save_active_b:
        cmpa.l  #__gk_undo_kit_payload_b,%a3
        bne.w   .Lgk_undo_save_corrupt
.Lgk_undo_save_inactive_ready:
        move.l  %d2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a3
        adda.l  %d0,%a3
        move.l  %d2,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a2
        adda.l  %d0,%a2
        move.l  (%a2),%d0
        move.l  %d0,__gk_undo_pending_name
        move.l  4(%a2),%d0
        move.l  %d0,__gk_undo_pending_name + 4
        move.l  %a4,__gk_undo_pending_payload_ptr
        move.b  %d2,__gk_undo_pending_kit
        moveq   #1,%d0
        move.b  %d0,__gk_undo_pending_bound
        clr.b   __gk_undo_pending_reserved
        moveq   #GK_UNDO_PENDING_SAVE,%d0
        move.b  %d0,__gk_undo_pending_owner
        move.w  %d5,%sr
        movea.l %a3,%a0
        movea.l %a4,%a1
        jsr     gk_copy_payload_interruptible
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_undo_pending_owner,%d0
        cmpi.l  #GK_UNDO_PENDING_SAVE,%d0
        bne.s   .Lgk_undo_save_discard_corrupt
        cmp.b   __gk_undo_pending_kit,%d2
        bne.s   .Lgk_undo_save_discard_corrupt
        cmpa.l  __gk_undo_pending_payload_ptr,%a4
        bne.s   .Lgk_undo_save_discard_corrupt
        move.l  (%a2),%d0
        cmp.l   __gk_undo_pending_name,%d0
        bne.s   .Lgk_undo_save_discard_corrupt
        move.l  4(%a2),%d0
        cmp.l   __gk_undo_pending_name + 4,%d0
        bne.s   .Lgk_undo_save_discard_corrupt
.Lgk_undo_save_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_undo_save_restore
.Lgk_undo_save_discard_corrupt:
        clr.b   __gk_undo_pending_owner
        clr.l   __gk_undo_pending_payload_ptr
        clr.l   __gk_undo_pending_name
        clr.l   __gk_undo_pending_name + 4
        clr.b   __gk_undo_pending_bound
        clr.b   __gk_undo_pending_kit
        clr.b   __gk_undo_pending_reserved
.Lgk_undo_save_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_undo_save_restore
.Lgk_undo_save_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_undo_save_restore:
        movem.l (%sp),%d2-%d5/%a2-%a4
        lea     28(%sp),%sp
        rts
.Lgk_undo_save_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_undo_kit_capture_save_target,.-gk_undo_kit_capture_save_target
        .global gk_undo_kit_validate_pending_save
        .type   gk_undo_kit_validate_pending_save,@function
gk_undo_kit_validate_pending_save:
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        cmpi.l  #GK_KIT_COUNT - 1,%d2
        bhi.w   .Lgk_undo_pending_save_corrupt
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_undo_pending_save_empty
        moveq   #0,%d0
        move.b  __gk_undo_pending_owner,%d0
        cmpi.l  #GK_UNDO_PENDING_SAVE,%d0
        bne.w   .Lgk_undo_pending_save_corrupt
        moveq   #0,%d0
        move.b  __gk_undo_pending_kit,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_undo_pending_save_corrupt
        moveq   #0,%d0
        move.b  __gk_undo_pending_bound,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_undo_pending_save_corrupt
        tst.b   __gk_undo_pending_reserved
        bne.w   .Lgk_undo_pending_save_corrupt
        movea.l __gk_undo_pending_payload_ptr,%a0
        cmpa.l  #__gk_undo_kit_payload_a,%a0
        beq.s   .Lgk_undo_pending_save_pointer_valid
        cmpa.l  #__gk_undo_kit_payload_b,%a0
        bne.s   .Lgk_undo_pending_save_corrupt
.Lgk_undo_pending_save_pointer_valid:
        tst.b   __gk_undo_kit_valid
        beq.s   .Lgk_undo_pending_save_ok
        cmpa.l  __gk_undo_kit_payload_ptr,%a0
        beq.s   .Lgk_undo_pending_save_corrupt
        bra.s   .Lgk_undo_pending_save_ok
.Lgk_undo_pending_save_empty:
        tst.b   __gk_undo_pending_owner
        bne.s   .Lgk_undo_pending_save_corrupt
.Lgk_undo_pending_save_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_undo_pending_save_restore
.Lgk_undo_pending_save_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_undo_pending_save_restore:
        move.l  (%sp)+,%d2
        rts
        .size   gk_undo_kit_validate_pending_save,.-gk_undo_kit_validate_pending_save
        .global gk_undo_kit_discard_pending_save
        .type   gk_undo_kit_discard_pending_save,@function
gk_undo_kit_discard_pending_save:
        tst.b   __gk_undo_pending_owner
        beq.s   .Lgk_undo_discard_save_ok
        moveq   #0,%d0
        move.b  __gk_undo_pending_owner,%d0
        cmpi.l  #GK_UNDO_PENDING_SAVE,%d0
        bne.s   .Lgk_undo_discard_save_corrupt
        clr.b   __gk_undo_pending_owner
        clr.l   __gk_undo_pending_payload_ptr
        clr.l   __gk_undo_pending_name
        clr.l   __gk_undo_pending_name + 4
        clr.b   __gk_undo_pending_bound
        clr.b   __gk_undo_pending_kit
        clr.b   __gk_undo_pending_reserved
.Lgk_undo_discard_save_ok:
        moveq   #GK_OK,%d0
        rts
.Lgk_undo_discard_save_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_undo_kit_discard_pending_save,.-gk_undo_kit_discard_pending_save
        .global gk_undo_kit_mark_pending_dirty
        .type   gk_undo_kit_mark_pending_dirty,@function
gk_undo_kit_mark_pending_dirty:
        move.l  %d2,-(%sp)
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        tst.b   __gk_undo_kit_valid
        beq.w   .Lgk_undo_pending_invalid
        tst.b   __gk_undo_pending_owner
        bne.w   .Lgk_undo_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   .Lgk_undo_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_undo_pending_corrupt
        move.l %d0,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a0
        adda.l %d1,%a0
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a0),%d0
        moveq   #0,%d1
        move.b  __gk_pending_transition_flags,%d1
        cmpi.l  #0x06,%d1
        bne.s   .Lgk_undo_pending_already_marked
        cmpi.l  #GK_DESC_VALID,%d0
        beq.s   .Lgk_undo_pending_mark_descriptor
        cmpi.l  #0x11,%d0
        bne.s   .Lgk_undo_pending_corrupt
        bra.s   .Lgk_undo_pending_mark_flags
.Lgk_undo_pending_mark_descriptor:
        ori.l   #GK_DESC_DIRTY,%d0
        move.b  %d0,GK_DESC_FLAGS(%a0)
.Lgk_undo_pending_mark_flags:
        moveq   #GK_TRANSITION_UNDO_PENDING_FLAGS,%d1
        move.b  %d1,__gk_pending_transition_flags
        bra.s   .Lgk_undo_pending_publish_loading
.Lgk_undo_pending_already_marked:
        cmpi.l  #GK_TRANSITION_UNDO_PENDING_FLAGS,%d1
        bne.s   .Lgk_undo_pending_corrupt
        cmpi.l  #0x11,%d0
        bne.s   .Lgk_undo_pending_corrupt
.Lgk_undo_pending_publish_loading:
        moveq   #0,%d0
        move.b  __gk_undo_kit_loading,%d0
        cmpi.l  #1,%d0
        bhi.s   .Lgk_undo_pending_corrupt
        moveq   #1,%d0
        move.b  %d0,__gk_undo_kit_loading
        moveq   #GK_OK,%d0
        bra.s   .Lgk_undo_pending_restore
.Lgk_undo_pending_invalid:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_undo_pending_restore
.Lgk_undo_pending_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_undo_pending_restore:
        move.w  %d2,%sr
        move.l  (%sp)+,%d2
        rts
        .size   gk_undo_kit_mark_pending_dirty,.-gk_undo_kit_mark_pending_dirty
