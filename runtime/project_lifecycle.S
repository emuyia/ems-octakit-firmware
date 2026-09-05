        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_background_save_request_decision
        .type   gk_stock_background_save_request_decision,@function
gk_stock_background_save_request_decision:
        move.l  %d0,-(%sp)
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_BACKGROUND_SAVE_REQUEST_CONTINUE,%d0
        bne.w   gk_project_lifecycle_fatal
        move.l  (%sp)+,%d0
        and.l   %d1,%d0
        bne.s   .Lgk_background_request_true
        tst.l   __gk_lifecycle_state
        bne.s   .Lgk_background_request_false
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        cmpi.l  #GK_RUNTIME_STORAGE_DIRTY,%d0
        beq.s   .Lgk_background_request_true
.Lgk_background_request_false:
        move.l  #GK_STOCK_BACKGROUND_SAVE_REQUEST_SKIP,(%sp)
        moveq   #0,%d0
        rts
.Lgk_background_request_true:
        moveq   #1,%d0
        rts
        .size   gk_stock_background_save_request_decision,.-gk_stock_background_save_request_decision
        .global gk_stock_background_work_gate
        .type   gk_stock_background_work_gate,@function
gk_stock_background_work_gate:
        tst.w   %d2
        bne.s   .Lgk_background_work_nonzero
        jsr     gk_persistence_work_sync
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_background_work_deferred
        tst.l   %d0
        bmi.s   .Lgk_background_work_complete
.Lgk_background_work_deferred:
        moveq   #1,%d0
.Lgk_background_work_complete:
        jmp     GK_STOCK_BACKGROUND_WORK_COMPLETE
.Lgk_background_work_nonzero:
        pea     -90(%a6)
        jmp     GK_STOCK_BACKGROUND_WORK_NONZERO_CONTINUE
        .size   gk_stock_background_work_gate,.-gk_stock_background_work_gate
        .global gk_stock_background_banks_save_work
        .type   gk_stock_background_banks_save_work,@function
gk_stock_background_banks_save_work:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  24(%sp),-(%sp)
        move.l  24(%sp),-(%sp)
        move.l  24(%sp),-(%sp)
        move.l  24(%sp),-(%sp)
        .global gk_background_stock_banks_save_call
gk_background_stock_banks_save_call:
        .incbin "stock/0149.bin", 0, 6
        lea     16(%sp),%sp
        move.l  %d0,%d2
        tst.l   %d2
        bmi.s   .Lgk_background_banks_save_result
        jsr     gk_persistence_work_sync
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_background_banks_save_result
        tst.l   %d0
        bmi.s   .Lgk_background_banks_save_restore
.Lgk_background_banks_save_result:
        move.l  %d2,%d0
.Lgk_background_banks_save_restore:
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts
        .size   gk_stock_background_banks_save_work,.-gk_stock_background_banks_save_work
        .global gk_persistence_work_sync
        .type   gk_persistence_work_sync,@function
gk_persistence_work_sync:
        move.l  %d2,-(%sp)
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_work_sync_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_work_sync_busy
        bra.w   .Lgk_work_sync_corrupt
.Lgk_work_sync_lifecycle_active:
        moveq   #0,%d0
        move.b  __gk_persistence_reserved,%d0
        cmpi.l  #GK_PERSIST_RELOAD_MAX,%d0
        bhi.w   .Lgk_work_sync_corrupt
        tst.l   %d0
        bne.w   .Lgk_work_sync_busy
        moveq   #0,%d0
        move.b  __gk_persistence_flags,%d0
        move.l  %d0,%d1
        andi.l  #~GK_PERSIST_KNOWN_FLAGS,%d1
        bne.w   .Lgk_work_sync_corrupt
        moveq   #0,%d2
        move.b  __gk_runtime_flags,%d2
        move.l  %d2,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_work_sync_corrupt
        btst    #0,%d0
        beq.s   .Lgk_work_sync_prepare_commit
        btst    #0,%d2
        beq.s   .Lgk_work_sync_repair
.Lgk_work_sync_prepare_commit:
        move.l  #258,%d2
.Lgk_work_sync_commit:
        jsr     gk_persistence_work_commit
        tst.l   %d0
        bmi.s   .Lgk_work_sync_restore
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #0,%d0
        beq.s   .Lgk_work_sync_repair
        subq.l  #1,%d2
        bne.s   .Lgk_work_sync_commit
        bra.s   .Lgk_work_sync_busy
.Lgk_work_sync_repair:
        moveq   #0,%d0
        move.b  __gk_persistence_flags,%d0
        move.l  %d0,%d1
        andi.l  #~GK_PERSIST_KNOWN_FLAGS,%d1
        bne.s   .Lgk_work_sync_corrupt
        btst    #2,%d0
        beq.s   .Lgk_work_sync_ok
        jsr     gk_persistence_stored_pending_repair
        bra.s   .Lgk_work_sync_restore
.Lgk_work_sync_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_work_sync_restore
.Lgk_work_sync_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_work_sync_restore
.Lgk_work_sync_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_work_sync_restore:
        move.l  (%sp)+,%d2
        rts
        .size   gk_persistence_work_sync,.-gk_persistence_work_sync
        .global gk_stock_current_project_card_sync
        .type   gk_stock_current_project_card_sync,@function
gk_stock_current_project_card_sync:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  20(%sp),-(%sp)
        move.l  20(%sp),-(%sp)
        move.l  20(%sp),-(%sp)
        .global gk_lifecycle_stock_card_sync_call
gk_lifecycle_stock_card_sync_call:
        .incbin "stock/0150.bin", 0, 6
        lea     12(%sp),%sp
        move.l  %d0,%d2
        tst.l   %d2
        bmi.s   .Lgk_card_sync_stock_result
        jsr     gk_persistence_work_sync
        tst.l   %d0
        bpl.s   .Lgk_card_sync_stock_result
        move.l  %d0,%d3
        jsr     gk_stock_dirty_mark_current
        move.l  %d3,%d0
        bra.s   .Lgk_card_sync_restore
.Lgk_card_sync_stock_result:
        move.l  %d2,%d0
.Lgk_card_sync_restore:
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts
        .size   gk_stock_current_project_card_sync,.-gk_stock_current_project_card_sync
        .global gk_stock_project_store_work_to_strd
        .type   gk_stock_project_store_work_to_strd,@function
gk_stock_project_store_work_to_strd:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        jsr     gk_persistence_work_sync
        tst.l   %d0
        bmi.s   .Lgk_project_store_restore
        move.l  20(%sp),-(%sp)
        move.l  20(%sp),-(%sp)
        move.l  20(%sp),-(%sp)
        .global gk_lifecycle_stock_project_store_call
gk_lifecycle_stock_project_store_call:
        .incbin "stock/0151.bin", 0, 6
        lea     12(%sp),%sp
        move.l  %d0,%d2
        tst.l   %d2
        bmi.s   .Lgk_project_store_stock_result
        jsr     gk_persistence_project_store
        tst.l   %d0
        bmi.s   .Lgk_project_store_restore
.Lgk_project_store_stock_result:
        move.l  %d2,%d0
.Lgk_project_store_restore:
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts
        .size   gk_stock_project_store_work_to_strd,.-gk_stock_project_store_work_to_strd
        .global gk_stock_banks_store_work_to_strd
        .type   gk_stock_banks_store_work_to_strd,@function
gk_stock_banks_store_work_to_strd:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  20(%sp),%d3
        jsr     gk_persistence_work_sync
        tst.l   %d0
        bmi.s   .Lgk_bank_store_restore
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        .global gk_lifecycle_stock_bank_store_call
gk_lifecycle_stock_bank_store_call:
        .incbin "stock/0152.bin", 0, 6
        lea     16(%sp),%sp
        move.l  %d0,%d2
        tst.l   %d2
        bmi.s   .Lgk_bank_store_stock_result
        move.l  %d3,%d0
        jsr     gk_persistence_bank_store
        tst.l   %d0
        bmi.s   .Lgk_bank_store_restore
.Lgk_bank_store_stock_result:
        move.l  %d2,%d0
.Lgk_bank_store_restore:
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts
        .size   gk_stock_banks_store_work_to_strd,.-gk_stock_banks_store_work_to_strd
        .global gk_stock_project_restore_strd_to_work
        .type   gk_stock_project_restore_strd_to_work,@function
gk_stock_project_restore_strd_to_work:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  20(%sp),-(%sp)
        move.l  20(%sp),-(%sp)
        move.l  20(%sp),-(%sp)
        .global gk_lifecycle_stock_project_reload_call
gk_lifecycle_stock_project_reload_call:
        .incbin "stock/0153.bin", 0, 6
        lea     12(%sp),%sp
        move.l  %d0,%d2
        tst.l   %d2
        bmi.s   .Lgk_project_reload_stock_result
        jsr     gk_persistence_project_reload
        tst.l   %d0
        bmi.s   .Lgk_project_reload_restore
.Lgk_project_reload_stock_result:
        move.l  %d2,%d0
.Lgk_project_reload_restore:
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts
        .size   gk_stock_project_restore_strd_to_work,.-gk_stock_project_restore_strd_to_work
        .global gk_stock_banks_restore_strd_to_work
        .type   gk_stock_banks_restore_strd_to_work,@function
gk_stock_banks_restore_strd_to_work:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  20(%sp),%d3
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        .global gk_lifecycle_stock_bank_reload_call
gk_lifecycle_stock_bank_reload_call:
        .incbin "stock/0154.bin", 0, 6
        lea     16(%sp),%sp
        move.l  %d0,%d2
        tst.l   %d2
        bmi.s   .Lgk_bank_reload_stock_result
        move.l  %d3,%d0
        jsr     gk_persistence_bank_reload
        tst.l   %d0
        bmi.s   .Lgk_bank_reload_restore
.Lgk_bank_reload_stock_result:
        move.l  %d2,%d0
.Lgk_bank_reload_restore:
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts
        .size   gk_stock_banks_restore_strd_to_work,.-gk_stock_banks_restore_strd_to_work
        .global gk_stock_boot_resident_banks_initialize_all
        .type   gk_stock_boot_resident_banks_initialize_all,@function
gk_stock_boot_resident_banks_initialize_all:
        bsr.w   gk_lifecycle_boot_quiesce_reset
        tst.l   %d0
        bne.w   gk_project_lifecycle_fatal
        move.l  4(%sp),%d0
        move.l  %d0,-(%sp)
        .global gk_lifecycle_stock_boot_banks_init_call
gk_lifecycle_stock_boot_banks_init_call:
        .incbin "stock/0155.bin", 0, 6
        addq.l  #4,%sp
        rts
        .size   gk_stock_boot_resident_banks_initialize_all,.-gk_stock_boot_resident_banks_initialize_all
        .global gk_stock_empty_project_runtime_initialize
        .type   gk_stock_empty_project_runtime_initialize,@function
gk_stock_empty_project_runtime_initialize:
        bsr.w   gk_lifecycle_quiesce_reset
        tst.l   %d0
        bne.w   gk_project_lifecycle_fatal
        .incbin "stock/0156.bin", 0, 2
        .incbin "stock/0156.bin", 2, 2
        .global gk_lifecycle_stock_empty_banks_init_call
gk_lifecycle_stock_empty_banks_init_call:
        .incbin "stock/0156.bin", 4, 6
        jmp     GK_STOCK_EMPTY_PROJECT_RUNTIME_INITIALIZE_CONTINUE
        .size   gk_stock_empty_project_runtime_initialize,.-gk_stock_empty_project_runtime_initialize
        .global gk_stock_banks_load_work_trampoline
        .type   gk_stock_banks_load_work_trampoline,@function
gk_stock_banks_load_work_trampoline:
        .incbin "stock/0157.bin", 0, 4
        .incbin "stock/0157.bin", 4, 4
        .global gk_lifecycle_stock_banks_load_trampoline_jump
gk_lifecycle_stock_banks_load_trampoline_jump:
        jmp     GK_STOCK_BANKS_LOAD_WORK_CONTINUE
        .size   gk_stock_banks_load_work_trampoline,.-gk_stock_banks_load_work_trampoline
        .type   gk_lifecycle_partial_load_restore,@function
gk_lifecycle_partial_load_restore:
        move.l  __gk_lifecycle_scratch_magic,%d0
        beq.s   .Lgk_partial_restore_from_work
        cmpi.l  #GK_LIFECYCLE_SCRATCH_MAGIC,%d0
        bne.w   .Lgk_partial_restore_corrupt
        bsr.w   gk_lifecycle_capture_validate
        tst.l   %d0
        bmi.s   .Lgk_partial_restore_return
        lea     __gk_lifecycle_scratch_persistence,%a0
        moveq   #0,%d0
        move.b  GK_PERSIST_RESERVED(%a0),%d0
        tst.l   %d0
        beq.s   .Lgk_partial_restore_library
        cmpi.l  #GK_PERSIST_RELOAD_BANK,%d0
        bne.s   .Lgk_partial_restore_corrupt
        bsr.w   gk_lifecycle_restore_persistence
        tst.l   %d0
        bmi.s   .Lgk_partial_restore_return
        bsr.w   gk_persistence_work_load
        bra.s   .Lgk_partial_restore_return
.Lgk_partial_restore_library:
        bsr.w   gk_lifecycle_restore_library
        bra.s   .Lgk_partial_restore_return
.Lgk_partial_restore_from_work:
        bsr.w   gk_persistence_work_load_or_migrate
        bra.s   .Lgk_partial_restore_return
.Lgk_partial_restore_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_partial_restore_return:
        rts
        .size   gk_lifecycle_partial_load_restore,.-gk_lifecycle_partial_load_restore
        .global gk_lifecycle_activate_current
        .type   gk_lifecycle_activate_current,@function
gk_lifecycle_activate_current:
        .incbin "stock/0158.bin", 0, 4
        .incbin "stock/0158.bin", 4, 4
        move.w  %sr,%d0
        move.w  %d0,44(%sp)
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   .Lgk_activate_busy
        tst.l   __gk_persistence_snapshot_gate
        bne.w   .Lgk_activate_corrupt
        moveq   #0,%d0
        move.b  __gk_persistence_reserved,%d0
        cmpi.l  #GK_PERSIST_RELOAD_MAX,%d0
        bhi.w   .Lgk_activate_corrupt
        tst.l   %d0
        bne.w   .Lgk_activate_busy
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        andi.l  #~GK_RUNTIME_STORAGE_DIRTY,%d0
        bne.w   .Lgk_activate_corrupt
        move.l  __gk_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_activate_corrupt
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_activate_corrupt
        tst.b   __gk_workspace_dirty
        bne.w   .Lgk_activate_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_activate_corrupt
        tst.b   __gk_workspace_bound
        bne.w   .Lgk_activate_corrupt
        tst.b   __gk_pending_workspace_bound
        bne.w   .Lgk_activate_corrupt
        tst.b   __gk_promotion_assign
        bne.w   .Lgk_activate_corrupt
        moveq   #0,%d0
        move.w  __gk_lease_sidecars,%d0
        cmpi.l  #0xffff,%d0
        bne.w   .Lgk_activate_corrupt
        move.l  __gk_descriptor_bitmap,%d0
        or.l    __gk_descriptor_bitmap + 4,%d0
        or.l    __gk_descriptor_bitmap + 8,%d0
        or.l    __gk_descriptor_bitmap + 12,%d0
        bne.w   .Lgk_activate_corrupt
        move.l  __gk_spill_bitmap,%d0
        or.l    __gk_spill_bitmap + 4,%d0
        or.l    __gk_spill_bitmap + 8,%d0
        or.l    __gk_spill_bitmap + 12,%d0
        bne.w   .Lgk_activate_corrupt
        moveq   #0,%d7
        move.l  __gk_lifecycle_scratch_magic,%d0
        beq.s   .Lgk_activate_capture_ready
        cmpi.l  #GK_LIFECYCLE_SCRATCH_MAGIC,%d0
        bne.w   .Lgk_activate_corrupt
        bsr.w   gk_lifecycle_capture_validate
        tst.l   %d0
        bmi.w   .Lgk_activate_restore
        move.l  %d0,%d7
.Lgk_activate_capture_ready:
        moveq   #0,%d4
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_activate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_activate_corrupt
        moveq   #0,%d5
        move.b  GK_STOCK_CURRENT_PATTERN,%d5
        cmpi.l  #15,%d5
        bhi.w   .Lgk_activate_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_activate_corrupt
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d6
        move.b  (%a0,%d0.l),%d6
        move.l  %d0,%d1
        lsr.l   #3,%d1
        andi.l  #7,%d0
        lea     __gk_pattern_assignment_valid,%a0
        btst    %d0,(%a0,%d1.l)
        beq.s   .Lgk_activate_unassigned
        move.l  #(GK_TRANSITION_FORCE_RELOAD + GK_TRANSITION_BIND),%a6
        bra.s   .Lgk_activate_capture_workspace
.Lgk_activate_unassigned:
        suba.l  %a6,%a6
.Lgk_activate_capture_workspace:
        btst    #1,%d7
        beq.s   .Lgk_activate_selection_ready
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_bank,%d0
        cmp.l   %d4,%d0
        bne.s   .Lgk_activate_selection_ready
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_pattern,%d0
        cmp.l   %d5,%d0
        bne.s   .Lgk_activate_selection_ready
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_kit,%d0
        tst.l   %a6
        beq.s   .Lgk_activate_capture_kit_valid
        cmp.l   %d6,%d0
        bne.s   .Lgk_activate_selection_ready
.Lgk_activate_capture_kit_valid:
        move.l  %d0,%d6
        move.l  #(GK_TRANSITION_PRESERVE_NAME + GK_TRANSITION_FORCE_RELOAD),%a6
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_bound,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_activate_corrupt
        tst.l   %d0
        beq.s   .Lgk_activate_capture_name
        move.l  %a6,%d0
        ori.l   #GK_TRANSITION_BIND,%d0
        move.l  %d0,%a6
.Lgk_activate_capture_name:
        move.l  __gk_lifecycle_scratch_workspace_name,%d0
        move.l  %d0,__gk_workspace_name
        move.l  __gk_lifecycle_scratch_workspace_name + 4,%d0
        move.l  %d0,__gk_workspace_name + 4
.Lgk_activate_selection_ready:
        lea     __gk_default_payload,%a0
        move.l  %a0,-(%sp)
        jsr     GK_STOCK_PART_PAYLOAD_INITIALIZE
        addq.l  #4,%sp
        move.w  #0x2700,%sr
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_project_lifecycle_fatal
        .global gk_lifecycle_activation_publication
gk_lifecycle_activation_publication:
        clr.l   __gk_lifecycle_state
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        move.l  %a6,%d3
        bsr.w   gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_project_lifecycle_fatal
        move.l  %d0,%d2
        move.l  %d1,%d3
        movea.l %a0,%a2
        move.l  %d2,%d0
        bsr.w   gk_ui_transition_prepare
        tst.l   %d0
        bmi.w   gk_project_lifecycle_fatal
        btst    #2,%d7
        beq.w   .Lgk_activate_setter
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_activate_setter
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_activate_setter
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_kit,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_activate_setter
        moveq   #0,%d0
        move.b  __gk_lifecycle_scratch_bound,%d0
        moveq   #0,%d1
        move.b  __gk_pending_workspace_bound,%d1
        cmp.l   %d1,%d0
        bne.w   gk_project_lifecycle_fatal
        lea     __gk_lifecycle_scratch_payload,%a0
        movea.l %a2,%a1
        move.l  #(GK_PART_PAYLOAD_SIZE / 4),%d0
.Lgk_activate_dirty_copy:
        move.l  (%a0)+,(%a1)+
        subq.l  #1,%d0
        bne.s   .Lgk_activate_dirty_copy
        move.w  (%a0)+,(%a1)+
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        cmpa.l  GK_DESC_PAYLOAD(%a3),%a2
        bne.w   gk_project_lifecycle_fatal
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a3),%d0
        btst    #0,%d0
        beq.w   gk_project_lifecycle_fatal
        btst    #3,%d0
        bne.w   gk_project_lifecycle_fatal
        btst    #4,%d0
        bne.w   gk_project_lifecycle_fatal
        ori.l   #GK_DESC_DIRTY,%d0
        move.b  %d0,GK_DESC_FLAGS(%a3)
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        cmpi.l  #(GK_TRANSITION_NEW_DESCRIPTOR + GK_TRANSITION_PRESERVE_NAME),%d0
        bne.w   gk_project_lifecycle_fatal
        ori.l   #GK_TRANSITION_PENDING_DIRTY,%d0
        move.b  %d0,__gk_pending_transition_flags
.Lgk_activate_setter:
        move.w  44(%sp),%d0
        move.w  %d0,%sr
        move.l  %d3,-(%sp)
        .global gk_lifecycle_stock_setter_call
gk_lifecycle_stock_setter_call:
        jsr     GK_STOCK_CURRENT_PATTERN_PART_SET
        .global gk_lifecycle_stock_setter_return
gk_lifecycle_stock_setter_return:
        addq.l  #4,%sp
        bsr.w   gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_project_lifecycle_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d3,%d2
        bsr.w   gk_stock_engine_context_validate
        tst.l   %d0
        bne.w   gk_project_lifecycle_fatal
        bsr.w   gk_lifecycle_scratch_clear
        .global gk_lifecycle_activation_scratch_return
gk_lifecycle_activation_scratch_return:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_activate_restore
.Lgk_activate_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_activate_restore
.Lgk_activate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_activate_restore:
        move.w  44(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
        .size   gk_lifecycle_activate_current,.-gk_lifecycle_activate_current
        .global gk_stock_banks_load_work
        .type   gk_stock_banks_load_work,@function
gk_stock_banks_load_work:
        move.l  (%sp),%d0
        cmpi.l  #GK_STOCK_BANKS_LOAD_PROJECT_RETURN,%d0
        beq.s   .Lgk_banks_load_full_pre
        cmpi.l  #GK_STOCK_BANKS_LOAD_BACKGROUND_RETURN,%d0
        beq.s   .Lgk_banks_load_partial_pre
        cmpi.l  #GK_STOCK_BANKS_LOAD_PARTIAL_RETURN,%d0
        bne.w   gk_project_lifecycle_fatal
.Lgk_banks_load_partial_pre:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        bne.s   .Lgk_banks_load_partial_quiesced
        bsr.w   gk_lifecycle_quiesce_capture_reset
        tst.l   %d0
        bmi.w   .Lgk_banks_load_return
        bra.s   .Lgk_banks_load_call_stock
.Lgk_banks_load_partial_quiesced:
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   .Lgk_banks_load_corrupt
        bra.s   .Lgk_banks_load_call_stock
.Lgk_banks_load_full_pre:
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_banks_load_call_stock
        tst.l   %d0
        bne.w   .Lgk_banks_load_corrupt
        bsr.w   gk_lifecycle_quiesce_reset
        tst.l   %d0
        bmi.w   .Lgk_banks_load_return
.Lgk_banks_load_call_stock:
        .incbin "stock/0159.bin", 0, 4
        .incbin "stock/0159.bin", 4, 4
        .incbin "stock/0159.bin", 8, 4
        .incbin "stock/0159.bin", 12, 4
        bsr.w   gk_stock_banks_load_work_trampoline
        lea     16(%sp),%sp
        tst.l   %d0
        bmi.s   .Lgk_banks_load_return
        move.l  %d0,-(%sp)
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_BANKS_LOAD_PROJECT_RETURN,%d0
        beq.s   .Lgk_banks_load_full_post
        bsr.w   gk_lifecycle_partial_load_restore
        bra.s   .Lgk_banks_load_post_loaded
.Lgk_banks_load_full_post:
        bsr.w   gk_persistence_work_load_or_migrate
.Lgk_banks_load_post_loaded:
        tst.l   %d0
        bmi.s   .Lgk_banks_load_post_error
        bsr.w   gk_lifecycle_activate_current
        tst.l   %d0
        bmi.s   .Lgk_banks_load_post_error
        move.l  (%sp)+,%d0
        rts
.Lgk_banks_load_post_error:
        addq.l  #4,%sp
        rts
.Lgk_banks_load_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_banks_load_return:
        rts
        .size   gk_stock_banks_load_work,.-gk_stock_banks_load_work
        .global gk_stock_save_as_new_banks_save_work
        .type   gk_stock_save_as_new_banks_save_work,@function
gk_stock_save_as_new_banks_save_work:
        moveq   #0,%d0
        bra.s   .Lgk_destination_banks_save_common
        .global gk_stock_create_empty_banks_save_work
        .type   gk_stock_create_empty_banks_save_work,@function
gk_stock_create_empty_banks_save_work:
        moveq   #1,%d0
.Lgk_destination_banks_save_common:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  %d0,%d4
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        move.l  28(%sp),-(%sp)
        .global gk_lifecycle_stock_destination_banks_save_call
gk_lifecycle_stock_destination_banks_save_call:
        .incbin "stock/0160.bin", 0, 6
        lea     16(%sp),%sp
        move.l  %d0,%d2
        tst.l   %d2
        bmi.s   .Lgk_destination_banks_save_stock_result
        tst.l   %d4
        bne.s   .Lgk_destination_banks_save_empty
        bsr.w   gk_persistence_destination_create
        bra.s   .Lgk_destination_banks_save_extension_result
.Lgk_destination_banks_save_empty:
        bsr.w   gk_persistence_new_project_create
        tst.l   %d0
        bmi.s   .Lgk_destination_banks_save_extension_result
        bsr.w   gk_lifecycle_activate_current
.Lgk_destination_banks_save_extension_result:
        tst.l   %d0
        bmi.s   .Lgk_destination_banks_save_restore
.Lgk_destination_banks_save_stock_result:
        move.l  %d2,%d0
.Lgk_destination_banks_save_restore:
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts
        .size   gk_stock_save_as_new_banks_save_work,.-gk_stock_save_as_new_banks_save_work
        .size   gk_stock_create_empty_banks_save_work,.-gk_stock_create_empty_banks_save_work
        .global gk_project_lifecycle_fatal
gk_project_lifecycle_fatal:
        illegal
        bra.s   gk_project_lifecycle_fatal
