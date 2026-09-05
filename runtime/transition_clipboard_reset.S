        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_engine_context_validate_and_reset
        .type   gk_stock_engine_context_validate_and_reset,@function
gk_stock_engine_context_validate_and_reset:
        jsr     gk_stock_engine_context_validate
        tst.l   %d0
        bne.s   .Lgk_transition_clipboard_reset_finish
        jsr     GK_STOCK_CLIPBOARD_RESET
        moveq   #GK_OK,%d0
.Lgk_transition_clipboard_reset_finish:
        addq.l  #4,%sp
        jmp     gk_stock_load_transaction_restore
        .size   gk_stock_engine_context_validate_and_reset,.-gk_stock_engine_context_validate_and_reset
