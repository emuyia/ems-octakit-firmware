        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_ui_transition_prepare_entry_release
        .type   gk_ui_transition_prepare_entry_release,@function
gk_ui_transition_prepare_entry_release:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_stock_source_prepare_handoff
        moveq   #0,%d1
        move.b  __gk_workspace_descriptor,%d1
        cmpi.l  #GK_ID_NONE,%d1
        beq.s   .Lgk_stock_source_prepare
.Lgk_stock_source_prepare_handoff:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        jmp     gk_ui_transition_prepare_after_entry_compare
.Lgk_stock_source_prepare:
        .incbin "stock/0339.bin", 0, 4
        .incbin "stock/0339.bin", 4, 4
        move.l  %d0,%d7
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   .Lgk_stock_source_prepare_busy
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        move.l  %d0,%d1
        andi.l  #0xe8,%d1
        bne.w   .Lgk_stock_source_prepare_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_stock_source_prepare_corrupt
        tst.l   __gk_ui_transition_start
        bne.w   .Lgk_stock_source_prepare_corrupt
        tst.l   __gk_ui_transition_start + 4
        bne.w   .Lgk_stock_source_prepare_corrupt
        tst.l   __gk_ui_transition_start + 8
        bne.w   .Lgk_stock_source_prepare_corrupt
        tst.l   __gk_ui_transition_start + 12
        bne.w   .Lgk_stock_source_prepare_corrupt
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d2
        move.b  GK_DESC_FLAGS(%a2),%d2
        move.l  %d2,%d0
        andi.l  #0xe6,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        btst    #0,%d2
        beq.w   .Lgk_stock_source_prepare_corrupt
        movea.l GK_DESC_PAYLOAD(%a2),%a3
        tst.l   %a3
        beq.w   .Lgk_stock_source_prepare_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d5
        move.b  GK_DESC_PHYSICAL(%a2),%d5
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d5
        bhi.w   .Lgk_stock_source_prepare_corrupt
        lea     __gk_physical_payload_table,%a4
        move.l  %d5,%d0
        lsl.l   #2,%d0
        movea.l (%a4,%d0.l),%a5
        cmpa.l  %a3,%a5
        bne.w   .Lgk_stock_source_prepare_corrupt
        move.l  %d5,%d4
        lsr.l   #2,%d4
        move.l  %d5,%d3
        andi.l  #3,%d3
        moveq   #0,%d0
        move.b  __gk_pending_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a5
        adda.l  %d0,%a5
        .incbin "stock/0340.bin", 0, 6
        cmpa.l  %a5,%a0
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d6
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d6
        cmpi.l  #3,%d6
        bhi.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_pattern,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PATTERN,%d1
        cmp.l   %d0,%d1
        bne.w   .Lgk_stock_source_prepare_corrupt
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d1
        cmp.l   %d0,%d1
        bne.w   .Lgk_stock_source_prepare_corrupt
        cmp.l   %d3,%d6
        beq.s   .Lgk_stock_source_prepare_ok
        move.l  %d4,%d0
        lsl.l   #2,%d0
        add.l   %d6,%d0
        lsl.l   #2,%d0
        movea.l (%a4,%d0.l),%a3
        adda.l  #GK_PART_MACHINE_SELECTOR_OFFSET,%a3
        lea     __gk_ui_transition_old_machines,%a5
        moveq   #GK_PART_MACHINE_SELECTOR_COUNT,%d0
.Lgk_stock_source_prepare_copy:
        move.b  (%a3)+,(%a5)+
        subq.l  #1,%d0
        bne.s   .Lgk_stock_source_prepare_copy
        moveq   #-1,%d0
        move.b  %d0,__gk_ui_transition_source_descriptor
        move.b  %d4,__gk_ui_transition_source_bank
        move.b  %d6,__gk_ui_transition_source_part
        move.l  #GK_UI_TRANSITION_STOCK_SOURCE_MAGIC,%d1
        move.l  %d1,__gk_ui_transition_reserved
        moveq   #1,%d0
        move.b  %d0,__gk_pending_ui_capture_created
        move.b  %d0,__gk_ui_transition_pending
.Lgk_stock_source_prepare_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_stock_source_prepare_restore
.Lgk_stock_source_prepare_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_stock_source_prepare_restore
.Lgk_stock_source_prepare_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_stock_source_prepare_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
        .size   gk_ui_transition_prepare_entry_release,.-gk_ui_transition_prepare_entry_release
        .align  4
        .global gk_ui_transition_prepare_pending_snapshot_release
        .type   gk_ui_transition_prepare_pending_snapshot_release,@function
gk_ui_transition_prepare_pending_snapshot_release:
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bls.s   .Lgk_prepare_pending_descriptor_source
        cmpi.l  #GK_ID_NONE,%d0
        bne.s   .Lgk_prepare_pending_corrupt
        move.l  __gk_ui_transition_reserved,%d1
        cmpi.l  #GK_UI_TRANSITION_STOCK_SOURCE_MAGIC,%d1
        bne.s   .Lgk_prepare_pending_corrupt
        bra.s   .Lgk_prepare_pending_common
.Lgk_prepare_pending_descriptor_source:
        tst.l   __gk_ui_transition_reserved
        bne.s   .Lgk_prepare_pending_corrupt
.Lgk_prepare_pending_common:
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_bank,%d0
        cmpi.l  #15,%d0
        bhi.s   .Lgk_prepare_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_part,%d0
        cmpi.l  #3,%d0
        bhi.s   .Lgk_prepare_pending_corrupt
        jmp     gk_ui_transition_prepare_ok
.Lgk_prepare_pending_corrupt:
        jmp     gk_ui_transition_prepare_corrupt
        .size   gk_ui_transition_prepare_pending_snapshot_release,.-gk_ui_transition_prepare_pending_snapshot_release
        .align  4
        .global gk_ui_transition_event_snapshot_release
        .type   gk_ui_transition_event_snapshot_release,@function
gk_ui_transition_event_snapshot_release:
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bls.s   .Lgk_event_snapshot_descriptor_source
        cmpi.l  #GK_ID_NONE,%d0
        bne.s   .Lgk_event_snapshot_corrupt
        move.l  __gk_ui_transition_reserved,%d1
        cmpi.l  #GK_UI_TRANSITION_STOCK_SOURCE_MAGIC,%d1
        bne.s   .Lgk_event_snapshot_corrupt
        bra.s   .Lgk_event_snapshot_common
.Lgk_event_snapshot_descriptor_source:
        tst.l   __gk_ui_transition_reserved
        bne.s   .Lgk_event_snapshot_corrupt
.Lgk_event_snapshot_common:
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_bank,%d0
        cmpi.l  #15,%d0
        bhi.s   .Lgk_event_snapshot_corrupt
        moveq   #0,%d0
        move.b  __gk_ui_transition_source_part,%d0
        cmpi.l  #3,%d0
        bhi.s   .Lgk_event_snapshot_corrupt
        jmp     gk_ui_transition_event_snapshot_copy
.Lgk_event_snapshot_corrupt:
        jmp     gk_ui_transition_event_release_corrupt
        .size   gk_ui_transition_event_snapshot_release,.-gk_ui_transition_event_snapshot_release
