        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_part_clear_abort_fatal,@function
gk_part_clear_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        bra.w   gk_part_save_clear_reload_fatal
        .size   gk_part_clear_abort_fatal,.-gk_part_clear_abort_fatal
        .type   gk_part_clear_release_abort_fatal,@function
gk_part_clear_release_abort_fatal:
        move.l  %d2,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        bra.w   gk_part_clear_abort_fatal
        .size   gk_part_clear_release_abort_fatal,.-gk_part_clear_release_abort_fatal
        .global gk_stock_part_working_to_saved_store
        .type   gk_stock_part_working_to_saved_store,@function
gk_stock_part_working_to_saved_store:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_part_save_active
        bra.w   gk_part_save_clear_reload_fatal
.Lgk_part_save_active:
        move.l  (%sp),%d0
        cmpi.l  #gk_part_clear_stock_return,%d0
        beq.w   .Lgk_part_save_join_clear
        cmpi.l  #GK_STOCK_PART_SAVE_SELECTED_RETURN,%d0
        bne.w   gk_part_save_clear_reload_fatal
        .incbin "stock/0137.bin", 0, 4
        .incbin "stock/0137.bin", 4, 4
        move.l  48(%sp),%d6
        cmpi.l  #3,%d6
        bhi.w   gk_part_save_clear_reload_fatal
        cmp.l   GK_STOCK_SELECTED_PART,%d6
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d6,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d6,%d0
        bne.w   gk_part_save_clear_reload_fatal
        jsr     gk_stock_current_context_validate_or_resume
        tst.l   %d0
        bmi.w   gk_part_save_clear_reload_fatal
        move.l  %d0,%d4
        jsr     gk_workspace_save
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #1,%d0
        lsl.l   %d4,%d0
        jsr     gk_stock_dirty_mark_bank_mask
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        .incbin "stock/0138.bin", 0, 4
        .incbin "stock/0138.bin", 4, 4
        .incbin "stock/0138.bin", 8, 2
.Lgk_part_save_join_clear:
        .incbin "stock/0139.bin", 0, 4
        .incbin "stock/0139.bin", 4, 4
        move.l  48(%sp),%d7
        cmpi.l  #3,%d7
        bhi.w   gk_part_save_clear_reload_fatal
        cmp.l   GK_STOCK_SELECTED_PART,%d7
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d7,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d7,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   gk_part_save_clear_reload_fatal
        andi.l  #0x7e,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        cmpi.l  #GK_TRANSITION_PRESERVE_NAME,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d4
        move.b  __gk_pending_workspace_descriptor,%d4
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d4,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d5
        move.b  __gk_pending_bank,%d5
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d5,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d5,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d6
        move.b  __gk_pending_pattern,%d6
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   %d6,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   %d6,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   %d6,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
        move.b  __gk_pending_kit,%d0
        moveq   #0,%d1
        move.b  __gk_current_kit,%d1
        cmp.l   %d1,%d0
        bne.w   gk_part_save_clear_reload_fatal
        move.l  %d5,%d0
        move.l  %d7,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_part_save_clear_reload_fatal
        move.l  %d0,%d3
        cmp.l   %d4,%d0
        bne.w   .Lgk_part_save_release_fatal
        move.l  %d7,-(%sp)
        jsr     gk_stock_part_working_to_saved_store_trampoline
        addq.l  #4,%sp
        move.l  %d3,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        .incbin "stock/0140.bin", 0, 4
        .incbin "stock/0140.bin", 4, 4
        .incbin "stock/0140.bin", 8, 2
.Lgk_part_save_release_fatal:
        move.l  %d3,%d0
        jsr     gk_descriptor_release
        bra.w   gk_part_save_clear_reload_fatal
        .size   gk_stock_part_working_to_saved_store,.-gk_stock_part_working_to_saved_store
        .global gk_stock_part_clear
        .type   gk_stock_part_clear,@function
gk_stock_part_clear:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_part_clear_active
        bra.w   gk_part_save_clear_reload_fatal
.Lgk_part_clear_active:
        .incbin "stock/0141.bin", 0, 4
        .incbin "stock/0141.bin", 4, 4
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_PART_CLEAR_CALL_RETURN,%d0
        bne.w   gk_part_save_clear_reload_fatal
        move.l  48(%sp),%d6
        cmpi.l  #3,%d6
        bhi.w   gk_part_save_clear_reload_fatal
        cmp.l   GK_STOCK_SELECTED_PART,%d6
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0x11,%d0
        cmp.l   GK_STOCK_UNDO_TAG,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0x24,%d0
        cmp.l   GK_STOCK_UNDO_ACTION,%d0
        bne.w   gk_part_save_clear_reload_fatal
        cmp.l   GK_STOCK_UNDO_PART,%d6
        bne.w   gk_part_save_clear_reload_fatal
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_part_save_clear_reload_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d6,%d0
        bne.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_part_save_clear_reload_fatal
        cmp.l   %d7,%d0
        bne.w   gk_part_clear_abort_fatal
        cmp.l   %d6,%d1
        bne.w   gk_part_clear_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %d6,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_part_clear_abort_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   gk_part_clear_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_part_clear_release_abort_fatal
        move.l  %d6,-(%sp)
        jsr     gk_stock_part_clear_trampoline
        .global gk_part_clear_stock_return
gk_part_clear_stock_return:
        addq.l  #4,%sp
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %d6,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        jsr     gk_stock_engine_context_validate
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_part_save_clear_reload_fatal
        .incbin "stock/0142.bin", 0, 4
        .incbin "stock/0142.bin", 4, 4
        .incbin "stock/0142.bin", 8, 2
        .size   gk_stock_part_clear,.-gk_stock_part_clear
        .global gk_stock_part_saved_to_working_reload
        .type   gk_stock_part_saved_to_working_reload,@function
gk_stock_part_saved_to_working_reload:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_part_reload_active
        bra.w   gk_part_save_clear_reload_fatal
.Lgk_part_reload_active:
        move.l  (%sp),%d0
        cmpi.l  #GK_STOCK_PART_RELOAD_SELECTED_RETURN,%d0
        beq.s   .Lgk_part_reload_caller_valid
        cmpi.l  #GK_STOCK_PART_RELOAD_SHORTCUT_RETURN,%d0
        bne.w   gk_part_save_clear_reload_fatal
.Lgk_part_reload_caller_valid:
        .incbin "stock/0143.bin", 0, 4
        .incbin "stock/0143.bin", 4, 4
        move.l  48(%sp),%d6
        cmpi.l  #3,%d6
        bhi.w   gk_part_save_clear_reload_fatal
        .global gk_part_reload_pattern_interlock_begin
gk_part_reload_pattern_interlock_begin:
        move.w  %sr,%d7
        move.w  #0x2200,%sr
        .global gk_part_reload_pattern_interlock_armed
gk_part_reload_pattern_interlock_armed:
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_PART_RELOAD_SHORTCUT_RETURN,%d0
        beq.s   .Lgk_part_reload_shortcut_selector
        cmp.l   GK_STOCK_SELECTED_PART,%d6
        bne.w   .Lgk_part_reload_failed
        bra.s   .Lgk_part_reload_selector_valid
.Lgk_part_reload_shortcut_selector:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d0,%d6
        bne.w   .Lgk_part_reload_failed
.Lgk_part_reload_selector_valid:
        jsr     gk_stock_current_context_validate_or_resume
        .global gk_part_reload_context_validate_return
gk_part_reload_context_validate_return:
        tst.l   %d0
        bmi.s   .Lgk_part_reload_context_failed
        move.l  %d0,%d4
        move.l  %d1,%d5
        tst.b   __gk_workspace_bound
        beq.s   .Lgk_part_reload_failed
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_part_reload_failed
        move.l  %d4,%d0
        move.l  %d5,%d1
        jsr     gk_stock_load_kit_transaction
        .global gk_part_reload_load_transaction_return
gk_part_reload_load_transaction_return:
        tst.l   %d0
        bne.s   .Lgk_part_reload_transaction_failed
        moveq   #1,%d0
        bra.s   .Lgk_part_reload_restore
.Lgk_part_reload_context_failed:
        cmpi.l  #GK_ERR_CORRUPT,%d0
        beq.w   gk_part_reload_context_corrupt_fatal
        moveq   #0,%d0
        bra.s   .Lgk_part_reload_restore
.Lgk_part_reload_transaction_failed:
        cmpi.l  #GK_ERR_CORRUPT,%d0
        beq.w   gk_part_reload_transaction_corrupt_fatal
        moveq   #0,%d0
        bra.s   .Lgk_part_reload_restore
.Lgk_part_reload_failed:
        cmpi.l  #GK_ERR_CORRUPT,%d0
        beq.w   gk_part_save_clear_reload_fatal
        moveq   #0,%d0
.Lgk_part_reload_restore:
        .global gk_part_reload_pattern_interlock_release
gk_part_reload_pattern_interlock_release:
        move.w  %d7,%sr
        .incbin "stock/0144.bin", 0, 4
        .incbin "stock/0144.bin", 4, 4
        .incbin "stock/0144.bin", 8, 2
        .size   gk_stock_part_saved_to_working_reload,.-gk_stock_part_saved_to_working_reload
        .global gk_stock_part_working_to_saved_store_trampoline
        .type   gk_stock_part_working_to_saved_store_trampoline,@function
gk_stock_part_working_to_saved_store_trampoline:
        .incbin "stock/0145.bin", 0, 4
        .incbin "stock/0145.bin", 4, 4
        .global gk_stock_part_working_to_saved_store_trampoline_jump
gk_stock_part_working_to_saved_store_trampoline_jump:
        jmp     GK_STOCK_PART_WORKING_TO_SAVED_STORE_CONTINUE
        .size   gk_stock_part_working_to_saved_store_trampoline,.-gk_stock_part_working_to_saved_store_trampoline
        .global gk_stock_part_clear_trampoline
        .type   gk_stock_part_clear_trampoline,@function
gk_stock_part_clear_trampoline:
        .incbin "stock/0146.bin", 0, 4
        .incbin "stock/0146.bin", 4, 4
        .global gk_stock_part_clear_trampoline_jump
gk_stock_part_clear_trampoline_jump:
        jmp     GK_STOCK_PART_CLEAR_CONTINUE
        .size   gk_stock_part_clear_trampoline,.-gk_stock_part_clear_trampoline
        .global gk_stock_part_saved_to_working_reload_trampoline
        .type   gk_stock_part_saved_to_working_reload_trampoline,@function
gk_stock_part_saved_to_working_reload_trampoline:
        .incbin "stock/0147.bin", 0, 4
        .incbin "stock/0147.bin", 4, 4
        .global gk_stock_part_saved_to_working_reload_trampoline_jump
gk_stock_part_saved_to_working_reload_trampoline_jump:
        jmp     GK_STOCK_PART_SAVED_TO_WORKING_RELOAD_CONTINUE
        .size   gk_stock_part_saved_to_working_reload_trampoline,.-gk_stock_part_saved_to_working_reload_trampoline
        .global gk_part_save_clear_reload_fatal
gk_part_save_clear_reload_fatal:
        illegal
        bra.s   gk_part_save_clear_reload_fatal
        .align  4
        .global gk_part_reload_context_corrupt_fatal
gk_part_reload_context_corrupt_fatal:
        illegal
        bra.s   gk_part_reload_context_corrupt_fatal
        .align  4
        .global gk_part_reload_transaction_corrupt_fatal
gk_part_reload_transaction_corrupt_fatal:
        illegal
        bra.s   gk_part_reload_transaction_corrupt_fatal
