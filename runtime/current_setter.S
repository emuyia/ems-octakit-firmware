        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_current_setter_stable_resolve,@function
gk_current_setter_stable_resolve:
        .incbin "stock/0057.bin", 0, 4
        .incbin "stock/0057.bin", 4, 4
        tst.l   __gk_lifecycle_state
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        andi.l  #0xfe,%d0
        bne.w .Lgk_setter_stable_busy
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w .Lgk_setter_stable_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d4
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d4
        cmpi.l  #15,%d4
        bhi.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d5
        move.b  GK_STOCK_CURRENT_PATTERN,%d5
        cmpi.l  #15,%d5
        bhi.w .Lgk_setter_stable_corrupt
        moveq   #0,%d6
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d6
        cmpi.l  #3,%d6
        bhi.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d6,%d0
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w .Lgk_setter_stable_corrupt
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        .incbin "stock/0058.bin", 0, 6
        cmpa.l  %a2,%a0
        bne.w .Lgk_setter_stable_corrupt
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmpi.l  #3,%d1
        bhi.w .Lgk_setter_stable_corrupt
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmpi.l  #3,%d1
        bhi.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d5,%d0
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d3
        move.b  __gk_current_kit,%d3
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        cmp.l   %d3,%d1
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bhi.w .Lgk_setter_stable_busy
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a4
        adda.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a4),%d0
        move.l  %d0,%d1
        andi.l  #0xe6,%d1
        bne.w .Lgk_setter_stable_busy
        btst    #0,%d0
        beq.w .Lgk_setter_stable_corrupt
        btst    #3,%d0
        beq.w .Lgk_setter_stable_corrupt
        moveq   #0,%d1
        move.b  __gk_workspace_dirty,%d1
        cmpi.l  #1,%d1
        bhi.w .Lgk_setter_stable_corrupt
        tst.l   %d1
        beq.s   .Lgk_setter_stable_clean
        btst    #4,%d0
        beq.w .Lgk_setter_stable_corrupt
        bra.s   .Lgk_setter_stable_dirty_checked
.Lgk_setter_stable_clean:
        btst    #4,%d0
        bne.w .Lgk_setter_stable_corrupt
.Lgk_setter_stable_dirty_checked:
        tst.l   GK_DESC_PAYLOAD(%a4)
        beq.w .Lgk_setter_stable_corrupt
        tst.l   GK_DESC_CANDIDATE(%a4)
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a4),%d0
        cmpi.l  #2,%d0
        blo.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a4),%d0
        cmp.l   %d3,%d0
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a4),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d2
        move.b  GK_DESC_PHYSICAL(%a4),%d2
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d2
        bhi.w .Lgk_setter_stable_corrupt
        move.l  %d2,%d0
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_stable_corrupt
        andi.l  #3,%d2
        cmp.l   %d6,%d2
        bne.w .Lgk_setter_stable_corrupt
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.l   %d1,%d0
        bne.w .Lgk_setter_stable_busy
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a4),%d0
        bsr.w   gk_physical_validate
        cmp.l   %d7,%d0
        bne.w .Lgk_setter_stable_corrupt
        move.l  %d4,%d0
        move.l  %d5,%d1
        movea.l %d7,%a0
        movea.l %d6,%a1
        bra.s   .Lgk_setter_stable_restore
.Lgk_setter_stable_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_setter_stable_restore
.Lgk_setter_stable_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_setter_stable_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
        .size   gk_current_setter_stable_resolve,.-gk_current_setter_stable_resolve
        .type   gk_current_setter_pending_resolve,@function
gk_current_setter_pending_resolve:
        cmpi.l  #3,%d0
        bhi.w .Lgk_setter_pending_range
        .incbin "stock/0059.bin", 0, 4
        .incbin "stock/0059.bin", 4, 4
        move.l  %d0,%d4
        tst.l   __gk_lifecycle_state
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w .Lgk_setter_pending_busy
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d5
        move.b  __gk_pending_bank,%d5
        cmpi.l  #15,%d5
        bhi.w .Lgk_setter_pending_corrupt
        moveq   #0,%d6
        move.b  __gk_pending_pattern,%d6
        cmpi.l  #15,%d6
        bhi.w .Lgk_setter_pending_corrupt
        moveq   #0,%d7
        move.b  __gk_pending_workspace_descriptor,%d7
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bhi.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        tst.l   %d0
        beq.w .Lgk_setter_pending_corrupt
        move.l  %d0,%d1
        andi.l  #0xe0,%d1
        bne.w .Lgk_setter_pending_corrupt
        btst    #1,%d0
        beq.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d5,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d5,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d6,%d0
        bne.w .Lgk_setter_pending_corrupt
        move.l  %d5,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        .incbin "stock/0060.bin", 0, 6
        cmpa.l  %a2,%a0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d2
        move.b  __gk_workspace_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d5,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d6,%d0
        bne.w .Lgk_setter_pending_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a3),%d0
        move.l  %d0,%d1
        andi.l  #0xe6,%d1
        bne.w .Lgk_setter_pending_corrupt
        btst    #0,%d0
        beq.w .Lgk_setter_pending_corrupt
        btst    #3,%d0
        beq.w .Lgk_setter_pending_corrupt
        tst.l   GK_DESC_PAYLOAD(%a3)
        beq.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a3),%d0
        cmpi.l  #2,%d0
        blo.w .Lgk_setter_pending_corrupt
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a3),%d3
        move.l  %d3,%d0
        lsr.l   #2,%d0
        cmp.l   %d5,%d0
        bne.w .Lgk_setter_pending_corrupt
        andi.l  #3,%d3
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d3,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d3,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d3,%d0
        bne.w .Lgk_setter_pending_corrupt
        move.l  %d6,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a4
        adda.l  %d0,%a4
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a4
        moveq   #0,%d1
        move.b  (%a4),%d1
        cmp.l   %d3,%d1
        bne.w .Lgk_setter_pending_corrupt
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a4
        adda.l  %d0,%a4
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a4
        moveq   #0,%d1
        move.b  (%a4),%d1
        cmp.l   %d3,%d1
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        move.l  %d2,%d1
        lsl.l   #8,%d1
        or.l    %d7,%d1
        cmp.l   %d1,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a3),%d0
        bsr.w   gk_physical_validate
        cmp.l   %d2,%d0
        bne.w .Lgk_setter_pending_corrupt
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a5
        adda.l %d0,%a5
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a5),%d0
        cmpi.l  #GK_DESC_VALID,%d0
        bne.w .Lgk_setter_pending_corrupt
        tst.l   GK_DESC_PAYLOAD(%a5)
        beq.w .Lgk_setter_pending_corrupt
        tst.l   GK_DESC_CANDIDATE(%a5)
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a5),%d0
        cmpi.l  #2,%d0
        blo.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a5),%d0
        moveq   #0,%d1
        move.b  __gk_pending_kit,%d1
        cmp.l   %d1,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a5),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a5),%d0
        move.l  %d0,%d1
        lsr.l   #2,%d1
        cmp.l   %d5,%d1
        bne.w .Lgk_setter_pending_corrupt
        andi.l  #3,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_pending_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a5),%d0
        bsr.w   gk_physical_validate
        cmp.l   %d7,%d0
        bne.w .Lgk_setter_pending_corrupt
        move.l  %d5,%d0
        move.l  %d6,%d1
        movea.l %d7,%a0
        movea.l %d4,%a1
        bra.s   .Lgk_setter_pending_restore
.Lgk_setter_pending_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_setter_pending_restore
.Lgk_setter_pending_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_setter_pending_restore:
        .incbin "stock/0061.bin", 0, 4
        .incbin "stock/0061.bin", 4, 4
        .incbin "stock/0061.bin", 8, 2
.Lgk_setter_pending_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_current_setter_pending_resolve,.-gk_current_setter_pending_resolve
        .type   gk_current_setter_lifecycle_pending_resolve,@function
gk_current_setter_lifecycle_pending_resolve:
        cmpi.l  #3,%d0
        bhi.w .Lgk_setter_lifecycle_range
        .incbin "stock/0062.bin", 0, 4
        .incbin "stock/0062.bin", 4, 4
        move.l  %d0,%d4
        tst.l   __gk_lifecycle_state
        beq.s .Lgk_project_load_diag_pass_78
        .global gk_project_load_diag_lifecycle_state
gk_project_load_diag_lifecycle_state:
        illegal
.Lgk_project_load_diag_pass_78:
        tst.l   __gk_persistence_snapshot_gate
        beq.s .Lgk_project_load_diag_pass_79
        .global gk_project_load_diag_snapshot_gate
gk_project_load_diag_snapshot_gate:
        illegal
.Lgk_project_load_diag_pass_79:
        tst.b   __gk_persistence_reserved
        beq.s .Lgk_project_load_diag_pass_80
        .global gk_project_load_diag_persistence_marker
gk_project_load_diag_persistence_marker:
        illegal
.Lgk_project_load_diag_pass_80:
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        bne.s .Lgk_project_load_diag_pass_81
        .global gk_project_load_diag_transition_missing
gk_project_load_diag_transition_missing:
        illegal
.Lgk_project_load_diag_pass_81:
        andi.l  #0x7e,%d0
        beq.s .Lgk_project_load_diag_pass_82
        .global gk_project_load_diag_runtime_flags
gk_project_load_diag_runtime_flags:
        illegal
.Lgk_project_load_diag_pass_82:
        move.l  __gk_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        beq.s .Lgk_project_load_diag_pass_83
        .global gk_project_load_diag_old_workspace_present
gk_project_load_diag_old_workspace_present:
        illegal
.Lgk_project_load_diag_pass_83:
        tst.b   __gk_workspace_dirty
        beq.s .Lgk_project_load_diag_pass_84
        .global gk_project_load_diag_old_workspace_dirty
gk_project_load_diag_old_workspace_dirty:
        illegal
.Lgk_project_load_diag_pass_84:
        moveq   #0,%d5
        move.b  __gk_pending_bank,%d5
        cmpi.l  #15,%d5
        bls.s .Lgk_project_load_diag_pass_85
        .global gk_project_load_diag_pending_bank_range
gk_project_load_diag_pending_bank_range:
        illegal
.Lgk_project_load_diag_pass_85:
        moveq   #0,%d6
        move.b  __gk_pending_pattern,%d6
        cmpi.l  #15,%d6
        bls.s .Lgk_project_load_diag_pass_86
        .global gk_project_load_diag_pending_pattern_range
gk_project_load_diag_pending_pattern_range:
        illegal
.Lgk_project_load_diag_pass_86:
        moveq   #0,%d7
        move.b  __gk_pending_workspace_descriptor,%d7
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bls.s .Lgk_project_load_diag_pass_87
        .global gk_project_load_diag_pending_descriptor_range
gk_project_load_diag_pending_descriptor_range:
        illegal
.Lgk_project_load_diag_pass_87:
        move.b  __gk_pending_transition_flags,%d0
        cmpi.b  #GK_TRANSITION_NEW_DESCRIPTOR,%d0
        beq.s   .Lgk_setter_lifecycle_pending_flags_valid
        cmpi.b  #(GK_TRANSITION_NEW_DESCRIPTOR + GK_TRANSITION_PRESERVE_NAME),%d0
        beq.s   .Lgk_setter_lifecycle_pending_flags_valid
        cmpi.b  #(GK_TRANSITION_NEW_DESCRIPTOR + GK_TRANSITION_PRESERVE_NAME + GK_TRANSITION_PENDING_DIRTY),%d0
        beq.s .Lgk_project_load_diag_pass_88
        .global gk_project_load_diag_pending_flags
gk_project_load_diag_pending_flags:
        illegal
.Lgk_project_load_diag_pass_88:
.Lgk_setter_lifecycle_pending_flags_valid:
        moveq   #0,%d3
        move.b  __gk_pending_kit,%d3
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d5,%d0
        beq.s .Lgk_project_load_diag_pass_89
        .global gk_project_load_diag_stock_bank_primary
gk_project_load_diag_stock_bank_primary:
        illegal
.Lgk_project_load_diag_pass_89:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d5,%d0
        beq.s .Lgk_project_load_diag_pass_90
        .global gk_project_load_diag_stock_bank_mirror
gk_project_load_diag_stock_bank_mirror:
        illegal
.Lgk_project_load_diag_pass_90:
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d5,%d0
        beq.s .Lgk_project_load_diag_pass_91
        .global gk_project_load_diag_engine_bank
gk_project_load_diag_engine_bank:
        illegal
.Lgk_project_load_diag_pass_91:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d6,%d0
        beq.s .Lgk_project_load_diag_pass_92
        .global gk_project_load_diag_pattern_mirror
gk_project_load_diag_pattern_mirror:
        illegal
.Lgk_project_load_diag_pass_92:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   %d6,%d0
        beq.s .Lgk_project_load_diag_pass_93
        .global gk_project_load_diag_pattern_primary
gk_project_load_diag_pattern_primary:
        illegal
.Lgk_project_load_diag_pass_93:
        move.l  %d5,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        .incbin "stock/0063.bin", 0, 6
        cmpa.l  %a2,%a0
        beq.s .Lgk_project_load_diag_pass_94
        .global gk_project_load_diag_bank_pointer
gk_project_load_diag_bank_pointer:
        illegal
.Lgk_project_load_diag_pass_94:
        moveq   #0,%d2
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d2
        cmpi.l  #3,%d2
        bls.s .Lgk_project_load_diag_pass_95
        .global gk_project_load_diag_current_part_range
gk_project_load_diag_current_part_range:
        illegal
.Lgk_project_load_diag_pass_95:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d2,%d0
        beq.s .Lgk_project_load_diag_pass_96
        .global gk_project_load_diag_current_part_mirror
gk_project_load_diag_current_part_mirror:
        illegal
.Lgk_project_load_diag_pass_96:
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d2,%d0
        beq.s .Lgk_project_load_diag_pass_97
        .global gk_project_load_diag_engine_part
gk_project_load_diag_engine_part:
        illegal
.Lgk_project_load_diag_pass_97:
        move.l  %d6,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        .global gk_project_load_resident_assignment_repair_gate
gk_project_load_resident_assignment_repair_gate:
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        .global gk_project_load_mirror_assignment_repair_gate
gk_project_load_mirror_assignment_repair_gate:
        move.l  %d5,%d0
        lsl.l   #4,%d0
        add.l   %d6,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        cmp.l   %d3,%d1
        beq.s .Lgk_project_load_diag_pass_98
        .global gk_project_load_diag_global_assignment
gk_project_load_diag_global_assignment:
        illegal
.Lgk_project_load_diag_pass_98:
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a4
        adda.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a4),%d0
        move.l  %d0,%d1
        andi.l  #0xee,%d1
        beq.s .Lgk_project_load_diag_pass_100
        .global gk_project_load_diag_descriptor_flags
gk_project_load_diag_descriptor_flags:
        illegal
.Lgk_project_load_diag_pass_100:
        btst    #0,%d0
        bne.s .Lgk_project_load_diag_pass_101
        .global gk_project_load_diag_descriptor_invalid
gk_project_load_diag_descriptor_invalid:
        illegal
.Lgk_project_load_diag_pass_101:
        moveq   #0,%d1
        move.b  __gk_pending_transition_flags,%d1
        btst    #4,%d1
        beq.s   .Lgk_setter_lifecycle_target_clean
        btst    #4,%d0
        bne.s .Lgk_project_load_diag_pass_102
        .global gk_project_load_diag_dirty_descriptor_clean
gk_project_load_diag_dirty_descriptor_clean:
        illegal
.Lgk_project_load_diag_pass_102:
        bra.s   .Lgk_setter_lifecycle_dirty_valid
.Lgk_setter_lifecycle_target_clean:
        btst    #4,%d0
        beq.s .Lgk_project_load_diag_pass_103
        .global gk_project_load_diag_clean_descriptor_dirty
gk_project_load_diag_clean_descriptor_dirty:
        illegal
.Lgk_project_load_diag_pass_103:
.Lgk_setter_lifecycle_dirty_valid:
        tst.l   GK_DESC_PAYLOAD(%a4)
        bne.s .Lgk_project_load_diag_pass_104
        .global gk_project_load_diag_descriptor_payload
gk_project_load_diag_descriptor_payload:
        illegal
.Lgk_project_load_diag_pass_104:
        tst.l   GK_DESC_CANDIDATE(%a4)
        beq.s .Lgk_project_load_diag_pass_105
        .global gk_project_load_diag_descriptor_candidate
gk_project_load_diag_descriptor_candidate:
        illegal
.Lgk_project_load_diag_pass_105:
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a4),%d0
        cmpi.l  #2,%d0
        beq.s .Lgk_project_load_diag_pass_106
        .global gk_project_load_diag_descriptor_roots
gk_project_load_diag_descriptor_roots:
        illegal
.Lgk_project_load_diag_pass_106:
        tst.w   GK_DESC_READERS(%a4)
        beq.s .Lgk_project_load_diag_pass_107
        .global gk_project_load_diag_descriptor_readers
gk_project_load_diag_descriptor_readers:
        illegal
.Lgk_project_load_diag_pass_107:
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a4),%d0
        cmp.l   %d3,%d0
        beq.s .Lgk_project_load_diag_pass_108
        .global gk_project_load_diag_descriptor_kit
gk_project_load_diag_descriptor_kit:
        illegal
.Lgk_project_load_diag_pass_108:
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a4),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s .Lgk_project_load_diag_pass_109
        .global gk_project_load_diag_descriptor_spill
gk_project_load_diag_descriptor_spill:
        illegal
.Lgk_project_load_diag_pass_109:
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a4),%d0
        move.l  %d0,%d1
        lsr.l   #2,%d1
        cmp.l   %d5,%d1
        beq.s .Lgk_project_load_diag_pass_110
        .global gk_project_load_diag_physical_bank
gk_project_load_diag_physical_bank:
        illegal
.Lgk_project_load_diag_pass_110:
        andi.l  #3,%d0
        cmp.l   %d4,%d0
        beq.s .Lgk_project_load_diag_pass_111
        .global gk_project_load_diag_physical_part
gk_project_load_diag_physical_part:
        illegal
.Lgk_project_load_diag_pass_111:
        move.l  %d5,%d0
        lsl.l   #2,%d0
        add.l   %d4,%d0
        bsr.w   gk_physical_validate
        cmp.l   %d7,%d0
        beq.s .Lgk_project_load_diag_pass_112
        .global gk_project_load_diag_physical_reverse_map
gk_project_load_diag_physical_reverse_map:
        illegal
.Lgk_project_load_diag_pass_112:
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        move.l  %d7,%d1
        ori.l   #0xff00,%d1
        cmp.l   %d1,%d0
        beq.s .Lgk_project_load_diag_pass_113
        .global gk_project_load_diag_lease_sidecars
gk_project_load_diag_lease_sidecars:
        illegal
.Lgk_project_load_diag_pass_113:
        move.l  %d5,%d0
        move.l  %d6,%d1
        movea.l %d7,%a0
        movea.l %d4,%a1
        bra.s   .Lgk_setter_lifecycle_restore
.Lgk_setter_lifecycle_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_setter_lifecycle_restore:
        .incbin "stock/0064.bin", 0, 4
        .incbin "stock/0064.bin", 4, 4
        .incbin "stock/0064.bin", 8, 2
.Lgk_setter_lifecycle_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_current_setter_lifecycle_pending_resolve,.-gk_current_setter_lifecycle_pending_resolve
        .type   gk_current_setter_refresh_pending_resolve,@function
gk_current_setter_refresh_pending_resolve:
        cmpi.l  #3,%d0
        bhi.w .Lgk_setter_refresh_range
        .incbin "stock/0065.bin", 0, 4
        .incbin "stock/0065.bin", 4, 4
        tst.l   __gk_lifecycle_state
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w .Lgk_setter_refresh_busy
        andi.l  #0x7e,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        cmpi.l  #GK_TRANSITION_PRESERVE_NAME,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d4
        move.b  __gk_current_bank,%d4
        cmpi.l  #15,%d4
        bhi.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_bank,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d5
        move.b  __gk_current_pattern,%d5
        cmpi.l  #15,%d5
        bhi.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_pattern,%d0
        cmp.l   %d5,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d3
        move.b  __gk_current_kit,%d3
        moveq   #0,%d0
        move.b  __gk_pending_kit,%d0
        cmp.l   %d3,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bhi.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d5,%d0
        bne.w .Lgk_setter_refresh_corrupt
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        .incbin "stock/0066.bin", 0, 6
        cmpa.l  %a2,%a0
        bne.w .Lgk_setter_refresh_corrupt
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        cmp.l   %d3,%d1
        bne.w .Lgk_setter_refresh_corrupt
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a3),%d0
        move.l  %d0,%d1
        andi.l  #0xe6,%d1
        bne.w .Lgk_setter_refresh_corrupt
        btst    #0,%d0
        beq.w .Lgk_setter_refresh_corrupt
        btst    #3,%d0
        beq.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d1
        move.b  __gk_workspace_dirty,%d1
        cmpi.l  #1,%d1
        bhi.w .Lgk_setter_refresh_corrupt
        tst.l   %d1
        beq.s   .Lgk_setter_refresh_clean
        btst    #4,%d0
        beq.w .Lgk_setter_refresh_corrupt
        bra.s   .Lgk_setter_refresh_dirty_checked
.Lgk_setter_refresh_clean:
        btst    #4,%d0
        bne.w .Lgk_setter_refresh_corrupt
.Lgk_setter_refresh_dirty_checked:
        tst.l   GK_DESC_PAYLOAD(%a3)
        beq.w .Lgk_setter_refresh_corrupt
        tst.l   GK_DESC_CANDIDATE(%a3)
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a3),%d0
        cmpi.l  #3,%d0
        blo.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a3),%d0
        cmp.l   %d3,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a3),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d6
        move.b  GK_DESC_PHYSICAL(%a3),%d6
        move.l  %d6,%d0
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        bne.w .Lgk_setter_refresh_corrupt
        andi.l  #3,%d6
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d6,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d6,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w .Lgk_setter_refresh_corrupt
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a4
        adda.l  %d0,%a4
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a4
        moveq   #0,%d1
        move.b  (%a4),%d1
        cmpi.l  #3,%d1
        bhi.w .Lgk_setter_refresh_corrupt
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a4
        adda.l  %d0,%a4
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a4
        moveq   #0,%d1
        move.b  (%a4),%d1
        cmpi.l  #3,%d1
        bhi.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        or.l    %d7,%d1
        cmp.l   %d1,%d0
        bne.w .Lgk_setter_refresh_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a3),%d0
        bsr.w   gk_physical_validate
        cmp.l   %d7,%d0
        bne.w .Lgk_setter_refresh_corrupt
        move.l  %d4,%d0
        move.l  %d5,%d1
        movea.l %d7,%a0
        movea.l %d6,%a1
        bra.s   .Lgk_setter_refresh_restore
.Lgk_setter_refresh_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_setter_refresh_restore
.Lgk_setter_refresh_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_setter_refresh_restore:
        .incbin "stock/0067.bin", 0, 4
        .incbin "stock/0067.bin", 4, 4
        .incbin "stock/0067.bin", 8, 2
.Lgk_setter_refresh_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_current_setter_refresh_pending_resolve,.-gk_current_setter_refresh_pending_resolve
        .type   gk_current_setter_pending_post_validate,@function
gk_current_setter_pending_post_validate:
        cmpi.l  #15,%d0
        bhi.w .Lgk_setter_post_range
        cmpi.l  #15,%d1
        bhi.w .Lgk_setter_post_range
        cmpi.l  #3,%d2
        bhi.w .Lgk_setter_post_range
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w .Lgk_setter_post_range
        lea     -32(%sp),%sp
        movem.l %d2-%d6/%a2-%a4,(%sp)
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %d2,%d6
        tst.l   __gk_lifecycle_state
        beq.s .Lgk_project_load_diag_pass_156
        .global gk_project_load_post_diag_lifecycle_state
gk_project_load_post_diag_lifecycle_state:
        illegal
.Lgk_project_load_diag_pass_156:
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        bne.s .Lgk_project_load_diag_pass_157
        .global gk_project_load_post_diag_transition_missing
gk_project_load_post_diag_transition_missing:
        illegal
.Lgk_project_load_diag_pass_157:
        andi.l  #0x7e,%d0
        beq.s .Lgk_project_load_diag_pass_158
        .global gk_project_load_post_diag_runtime_flags
gk_project_load_post_diag_runtime_flags:
        illegal
.Lgk_project_load_diag_pass_158:
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d3,%d0
        beq.s .Lgk_project_load_diag_pass_159
        .global gk_project_load_post_diag_pending_descriptor
gk_project_load_post_diag_pending_descriptor:
        illegal
.Lgk_project_load_diag_pass_159:
        moveq   #0,%d0
        move.b  __gk_pending_bank,%d0
        cmp.l   %d4,%d0
        beq.s .Lgk_project_load_diag_pass_160
        .global gk_project_load_post_diag_pending_bank
gk_project_load_post_diag_pending_bank:
        illegal
.Lgk_project_load_diag_pass_160:
        moveq   #0,%d0
        move.b  __gk_pending_pattern,%d0
        cmp.l   %d5,%d0
        beq.s .Lgk_project_load_diag_pass_161
        .global gk_project_load_post_diag_pending_pattern
gk_project_load_post_diag_pending_pattern:
        illegal
.Lgk_project_load_diag_pass_161:
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        beq.s .Lgk_project_load_diag_pass_162
        .global gk_project_load_post_diag_engine_bank
gk_project_load_post_diag_engine_bank:
        illegal
.Lgk_project_load_diag_pass_162:
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        beq.s .Lgk_project_load_diag_pass_163
        .global gk_project_load_post_diag_engine_part
gk_project_load_post_diag_engine_part:
        illegal
.Lgk_project_load_diag_pass_163:
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a2
        adda.l  %d0,%a2
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d6,%d1
        beq.s .Lgk_project_load_diag_pass_164
        .global gk_project_load_post_diag_resident_assignment
gk_project_load_post_diag_resident_assignment:
        illegal
.Lgk_project_load_diag_pass_164:
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d6,%d1
        beq.s .Lgk_project_load_diag_pass_165
        .global gk_project_load_post_diag_mirror_assignment
gk_project_load_post_diag_mirror_assignment:
        illegal
.Lgk_project_load_diag_pass_165:
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        andi.l  #0xff,%d0
        cmp.l   %d3,%d0
        beq.s .Lgk_project_load_diag_pass_166
        .global gk_project_load_post_diag_lease_sidecar
gk_project_load_post_diag_lease_sidecar:
        illegal
.Lgk_project_load_diag_pass_166:
        move.l  %d4,%d0
        lsl.l   #2,%d0
        add.l   %d6,%d0
        bsr.w   gk_physical_validate
        cmp.l   %d3,%d0
        beq.s .Lgk_project_load_diag_pass_167
        .global gk_project_load_post_diag_physical_reverse_map
gk_project_load_post_diag_physical_reverse_map:
        illegal
.Lgk_project_load_diag_pass_167:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_setter_post_restore
.Lgk_setter_post_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_setter_post_restore:
        movem.l (%sp),%d2-%d6/%a2-%a4
        lea     32(%sp),%sp
        rts
.Lgk_setter_post_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_current_setter_pending_post_validate,.-gk_current_setter_pending_post_validate
        .global gk_stock_current_pattern_part_set
        .type   gk_stock_current_pattern_part_set,@function
gk_stock_current_pattern_part_set:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_stock_setter_active
        bra.w gk_current_pattern_part_set_fatal
.Lgk_stock_setter_active:
        .incbin "stock/0068.bin", 0, 4
        .incbin "stock/0068.bin", 4, 4
        move.l  48(%sp),%d4
        cmpi.l  #3,%d4
        bhi.w gk_current_pattern_part_set_fatal
        move.l  44(%sp),%d0
        cmpi.l  #gk_load_kit_stock_setter_return,%d0
        beq.w   .Lgk_stock_setter_outer
        cmpi.l  #gk_lifecycle_stock_setter_return,%d0
        beq.w   .Lgk_stock_setter_outer_lifecycle
        cmpi.l  #GK_STOCK_PATTERN_PAYLOAD_STORE_SETTER_RETURN,%d0
        beq.w   .Lgk_stock_setter_outer_refresh
        bsr.w   gk_current_setter_stable_resolve
        tst.l   %d0
        bmi.w gk_current_pattern_part_set_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %a0,%d7
        move.l  %a1,%d6
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmp.l   %d7,%d0
        bne.w gk_current_pattern_part_set_fatal
        cmp.l   %d6,%d1
        bne.w gk_current_pattern_part_set_fatal
        move.l  %d6,-(%sp)
        bsr.w   gk_stock_current_pattern_part_set_trampoline
        addq.l  #4,%sp
        bsr.w   gk_workspace_commit_update
        tst.l   %d0
        bne.w gk_current_pattern_part_set_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        bsr.w   gk_stock_engine_context_validate
        tst.l   %d0
        bne.w gk_current_pattern_part_set_fatal
        bra.s   .Lgk_stock_setter_success
.Lgk_stock_setter_outer:
        move.l  %d4,%d0
        bsr.w   gk_current_setter_pending_resolve
        bra.s   .Lgk_stock_setter_outer_resolved
.Lgk_stock_setter_outer_lifecycle:
        move.l  %d4,%d0
        bsr.w   gk_current_setter_lifecycle_pending_resolve
        bra.s   .Lgk_stock_setter_outer_resolved
.Lgk_stock_setter_outer_refresh:
        move.l  %d4,%d0
        bsr.w   gk_current_setter_refresh_pending_resolve
.Lgk_stock_setter_outer_resolved:
        tst.l   %d0
        bmi.w gk_current_pattern_part_set_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %a0,%d7
        move.l  %a1,%d6
        move.l  %d6,-(%sp)
        bsr.w   gk_stock_current_pattern_part_set_trampoline
        addq.l  #4,%sp
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        move.l  %d7,%d3
        bsr.w   gk_current_setter_pending_post_validate
        tst.l   %d0
        bne.w gk_current_pattern_part_set_fatal
.Lgk_stock_setter_success:
        .incbin "stock/0069.bin", 0, 4
        .incbin "stock/0069.bin", 4, 4
        .incbin "stock/0069.bin", 8, 2
        .size   gk_stock_current_pattern_part_set,.-gk_stock_current_pattern_part_set
        .global gk_stock_current_pattern_part_set_trampoline
        .type   gk_stock_current_pattern_part_set_trampoline,@function
gk_stock_current_pattern_part_set_trampoline:
        .incbin "stock/0070.bin", 0, 2
        .incbin "stock/0070.bin", 2, 4
        .global gk_stock_current_pattern_part_set_trampoline_jump
gk_stock_current_pattern_part_set_trampoline_jump:
        jmp     GK_STOCK_CURRENT_PATTERN_PART_SET + 6
        .size   gk_stock_current_pattern_part_set_trampoline,.-gk_stock_current_pattern_part_set_trampoline
        .global gk_stock_pattern_payload_store
        .type   gk_stock_pattern_payload_store,@function
gk_stock_pattern_payload_store:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_stock_pattern_store_active
        bra.w gk_current_pattern_part_set_fatal
.Lgk_stock_pattern_store_active:
        .incbin "stock/0071.bin", 0, 4
        .incbin "stock/0071.bin", 4, 4
        move.l  48(%sp),%a6
        move.l  52(%sp),%d7
        tst.l   %a6
        beq.w gk_current_pattern_part_set_fatal
        cmpi.l  #15,%d7
        bhi.w gk_current_pattern_part_set_fatal
        bsr.w   gk_current_setter_stable_resolve
        tst.l   %d0
        bmi.w gk_current_pattern_part_set_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        cmp.l   %d5,%d7
        bne.w gk_current_pattern_part_set_fatal
        move.l  %a0,%d7
        move.l  %a1,%d6
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmp.l   %d7,%d0
        bne.w gk_current_pattern_part_set_fatal
        cmp.l   %d6,%d1
        bne.w gk_current_pattern_part_set_fatal
        move.l  52(%sp),-(%sp)
        move.l  52(%sp),-(%sp)
        bsr.w   gk_stock_pattern_payload_store_trampoline
        addq.l  #8,%sp
        bsr.w   gk_workspace_commit_update
        tst.l   %d0
        bne.w gk_current_pattern_part_set_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        bsr.w   gk_stock_engine_context_validate
        tst.l   %d0
        bne.w gk_current_pattern_part_set_fatal
        clr.b   __gk_pattern_kit_armed
        cmpa.l  #GK_STOCK_PASTE_BUFFER,%a6
        bne.s   .Lgk_stock_pattern_store_pattern_kit_done
        moveq   #0,%d0
        move.b  __gk_pattern_kit_valid,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_stock_pattern_store_pattern_kit_done
        move.b  %d4,__gk_pattern_kit_bank
        move.b  %d5,__gk_pattern_kit_pattern
        moveq   #1,%d0
        move.b  %d0,__gk_pattern_kit_armed
.Lgk_stock_pattern_store_pattern_kit_done:
        .incbin "stock/0072.bin", 0, 4
        .incbin "stock/0072.bin", 4, 4
        .incbin "stock/0072.bin", 8, 2
        .size   gk_stock_pattern_payload_store,.-gk_stock_pattern_payload_store
        .global gk_stock_pattern_payload_store_trampoline
        .type   gk_stock_pattern_payload_store_trampoline,@function
gk_stock_pattern_payload_store_trampoline:
        .incbin "stock/0073.bin", 0, 4
        .incbin "stock/0073.bin", 4, 4
        .global gk_stock_pattern_payload_store_trampoline_jump
gk_stock_pattern_payload_store_trampoline_jump:
        jmp     GK_STOCK_PATTERN_PAYLOAD_STORE_CONTINUE
        .size   gk_stock_pattern_payload_store_trampoline,.-gk_stock_pattern_payload_store_trampoline
        .global gk_current_pattern_part_set_fatal
gk_current_pattern_part_set_fatal:
        illegal
        bra.s   gk_current_pattern_part_set_fatal
