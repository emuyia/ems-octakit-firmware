        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_dirty_mark_bank_mask
        .type   gk_stock_dirty_mark_bank_mask,@function
gk_stock_dirty_mark_bank_mask:
        lea     -16(%sp),%sp
        movem.l %d2-%d3/%a2,(%sp)
        move.w  %sr,%d1
        move.w  %d1,12(%sp)
        move.w  #0x2700,%sr
        tst.l   %d0
        ble.w   .Lgk_dirty_mask_range
        cmpi.l  #0xffff,%d0
        bhi.w   .Lgk_dirty_mask_range
        move.l  %d0,%d2
        moveq   #0,%d3
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d3
        cmpi.l  #15,%d3
        bhi.s   .Lgk_dirty_mask_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d3,%d0
        bne.s   .Lgk_dirty_mask_corrupt
        move.l  %d3,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a0
        adda.l  %d0,%a0
        movea.l GK_STOCK_BANK_POINTER,%a1
        cmpa.l  %a0,%a1
        bne.s   .Lgk_dirty_mask_corrupt
        movea.l #GK_STOCK_RESIDENT_BANK_BASE + GK_STOCK_BANK_DIRTY_OFFSET,%a2
        moveq   #0,%d1
.Lgk_dirty_mask_loop:
        btst    %d1,%d2
        beq.s   .Lgk_dirty_mask_next
        moveq   #1,%d0
        move.l  %d0,(%a2)
.Lgk_dirty_mask_next:
        adda.l  #GK_STOCK_BANK_STRIDE,%a2
        addq.l  #1,%d1
        cmpi.l  #16,%d1
        blo.s   .Lgk_dirty_mask_loop
        btst    %d3,%d2
        beq.s   .Lgk_dirty_mask_ok
        moveq   #1,%d0
        .incbin "stock/0170.bin", 0, 6
.Lgk_dirty_mask_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_dirty_mask_restore
.Lgk_dirty_mask_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_dirty_mask_restore:
        move.w  12(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d3/%a2
        lea     16(%sp),%sp
        rts
.Lgk_dirty_mask_range:
        moveq   #GK_ERR_RANGE,%d0
        bra.s   .Lgk_dirty_mask_restore
        .size   gk_stock_dirty_mark_bank_mask,.-gk_stock_dirty_mark_bank_mask
        .global gk_stock_dirty_mark_current
        .type   gk_stock_dirty_mark_current,@function
gk_stock_dirty_mark_current:
        subq.l  #4,%sp
        move.w  %sr,%d1
        move.w  %d1,(%sp)
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmpi.l  #15,%d0
        bhi.s   .Lgk_dirty_current_corrupt
        moveq   #1,%d1
        lsl.l   %d0,%d1
        move.l  %d1,%d0
        bsr.w   gk_stock_dirty_mark_bank_mask
        bra.s   .Lgk_dirty_current_restore
.Lgk_dirty_current_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_dirty_current_restore:
        move.w  (%sp),%d1
        move.w  %d1,%sr
        addq.l  #4,%sp
        rts
        .size   gk_stock_dirty_mark_current,.-gk_stock_dirty_mark_current
