        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_part_buffer_store_abort_fatal,@function
gk_part_buffer_store_abort_fatal:
        bsr.w   gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_part_buffer_store_fatal
        bra.w   gk_part_buffer_store_fatal
        .size   gk_part_buffer_store_abort_fatal,.-gk_part_buffer_store_abort_fatal
        .type   gk_part_buffer_store_release_abort_fatal,@function
gk_part_buffer_store_release_abort_fatal:
        move.l  %d2,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_part_buffer_store_fatal
        bra.w   gk_part_buffer_store_abort_fatal
        .size   gk_part_buffer_store_release_abort_fatal,.-gk_part_buffer_store_release_abort_fatal
        .global gk_stock_part_buffer_store
        .type   gk_stock_part_buffer_store,@function
gk_stock_part_buffer_store:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_part_buffer_store_active
        bra.w   gk_part_buffer_store_fatal
.Lgk_part_buffer_store_active:
        .incbin "stock/0113.bin", 0, 4
        .incbin "stock/0113.bin", 4, 4
        movea.l 48(%sp),%a2
        move.l  52(%sp),%d6
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_PART_BUFFER_UNDO_RETURN,%d0
        beq.s   .Lgk_part_buffer_store_undo
        cmpi.l  #GK_STOCK_PART_BUFFER_PASTE_RETURN,%d0
        bne.w   gk_part_buffer_store_fatal
        cmpa.l  #GK_STOCK_PASTE_BUFFER,%a2
        bne.w   gk_part_buffer_store_fatal
        moveq   #0x11,%d0
        cmp.l   GK_STOCK_PASTE_TAG,%d0
        bne.w   gk_part_buffer_store_fatal
        bra.s   .Lgk_part_buffer_store_caller_ok
.Lgk_part_buffer_store_undo:
        cmpa.l  #GK_STOCK_UNDO_BUFFER,%a2
        bne.w   gk_part_buffer_store_fatal
        moveq   #0x11,%d0
        cmp.l   GK_STOCK_UNDO_TAG,%d0
        bne.w   gk_part_buffer_store_fatal
.Lgk_part_buffer_store_caller_ok:
        cmpi.l  #3,%d6
        bhi.w   gk_part_buffer_store_fatal
        cmp.l   GK_STOCK_SELECTED_PART,%d6
        bne.w   gk_part_buffer_store_fatal
        bsr.w   gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_part_buffer_store_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d3
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d3
        cmp.l   %d6,%d3
        bne.w   gk_part_buffer_store_fatal
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        bsr.w   gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_part_buffer_store_fatal
        cmp.l   %d7,%d0
        bne.w   gk_part_buffer_store_abort_fatal
        cmp.l   %d6,%d1
        bne.w   gk_part_buffer_store_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %d6,%d1
        bsr.w   gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_part_buffer_store_abort_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   gk_part_buffer_store_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_part_buffer_store_release_abort_fatal
        move.l  %d6,-(%sp)
        move.l  %a2,-(%sp)
        .global gk_part_buffer_store_stock_call
gk_part_buffer_store_stock_call:
        bsr.w   gk_stock_part_buffer_store_trampoline
        addq.l  #8,%sp
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %d6,%d3
        bsr.w   gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_part_buffer_store_fatal
        bsr.w   gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_part_buffer_store_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        bsr.w   gk_stock_engine_context_validate
        tst.l   %d0
        bne.w   gk_part_buffer_store_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_part_buffer_store_fatal
        .incbin "stock/0114.bin", 0, 4
        .incbin "stock/0114.bin", 4, 4
        .incbin "stock/0114.bin", 8, 2
        .size   gk_stock_part_buffer_store,.-gk_stock_part_buffer_store
        .global gk_stock_part_buffer_store_trampoline
        .type   gk_stock_part_buffer_store_trampoline,@function
gk_stock_part_buffer_store_trampoline:
        .incbin "stock/0115.bin", 0, 4
        .incbin "stock/0115.bin", 4, 4
        .global gk_stock_part_buffer_store_trampoline_jump
gk_stock_part_buffer_store_trampoline_jump:
        jmp     GK_STOCK_PART_BUFFER_STORE_CONTINUE
        .size   gk_stock_part_buffer_store_trampoline,.-gk_stock_part_buffer_store_trampoline
        .global gk_part_buffer_store_fatal
gk_part_buffer_store_fatal:
        illegal
        bra.s   gk_part_buffer_store_fatal
