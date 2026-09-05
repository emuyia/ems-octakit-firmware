        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_sequencer_condition_quiesced_pointer,@function
gk_sequencer_condition_quiesced_pointer:
        lea     GK_STOCK_SEQUENCER_TRACK_BANKS,%a0
        mvs.b   (%a0,%d5.l),%d0
        lea     GK_STOCK_SEQUENCER_TRACK_PARTS,%a0
        mvs.b   (%a0,%d5.l),%d1
        move.l  #GK_STOCK_BANK_STRIDE,%d2
        muls.l  %d2,%d0
        move.l  #GK_PART_PAYLOAD_SIZE,%d2
        muls.l  %d2,%d1
        lea     GK_STOCK_PHYSICAL_BASE,%a4
        adda.l  %d0,%a4
        adda.l  %d1,%a4
        adda.l  #GK_STOCK_SEQUENCER_PART_CONDITION_OFFSET,%a4
        rts
        .size   gk_sequencer_condition_quiesced_pointer,.-gk_sequencer_condition_quiesced_pointer
        .global gk_stock_sequencer_condition_enter
        .type   gk_stock_sequencer_condition_enter,@function
gk_stock_sequencer_condition_enter:
        move.l  %d6,-(%sp)
        move.l  %a4,-(%sp)
        .incbin "stock/0168.bin", 0, 4
        .incbin "stock/0168.bin", 4, 4
        move.l  36(%sp),%d5
        cmpi.l  #GK_SIDECAR_SEQUENCER_TRACK_COUNT - 1,%d5
        bhi.w   gk_sequencer_reader_fatal
        moveq   #-1,%d6
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_condition_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_sequencer_reader_fatal
        bsr.w   gk_sequencer_condition_quiesced_pointer
        jmp     GK_STOCK_SEQUENCER_CONDITION_CONTINUE
.Lgk_condition_active:
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        adda.l  %d0,%a0
        jsr     gk_selector_acquire
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_condition_unavailable
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_condition_unavailable
        tst.l   %d0
        bmi.w   gk_sequencer_reader_fatal
        move.l  %d0,%d6
        movea.l %a0,%a4
        adda.l  #GK_STOCK_SEQUENCER_PART_CONDITION_OFFSET,%a4
        jmp     GK_STOCK_SEQUENCER_CONDITION_CONTINUE
.Lgk_condition_unavailable:
        jmp     GK_STOCK_SEQUENCER_CONDITION_UNAVAILABLE
        .size   gk_stock_sequencer_condition_enter,.-gk_stock_sequencer_condition_enter
        .global gk_stock_sequencer_condition_return
        .type   gk_stock_sequencer_condition_return,@function
gk_stock_sequencer_condition_return:
        move.w  %sr,%d5
        lea     -20(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        move.w  %d5,16(%sp)
        move.l  %d6,%d0
        bmi.s   .Lgk_condition_return_restore
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_sequencer_reader_fatal
.Lgk_condition_return_restore:
        movem.l 20(%sp),%d2-%d5/%a2-%a3
        movea.l 44(%sp),%a4
        move.l  48(%sp),%d6
        movem.l (%sp),%d0-%d1/%a0-%a1
        move.w  16(%sp),%d5
        move.w  %d5,%sr
        movem.l 32(%sp),%d5
        tst.l   %d0
        lea     52(%sp),%sp
        rts
        .size   gk_stock_sequencer_condition_return,.-gk_stock_sequencer_condition_return
        .type   gk_sequencer_advance_quiesced_pointer,@function
gk_sequencer_advance_quiesced_pointer:
        lea     GK_STOCK_SEQUENCER_TRACK_BANKS,%a0
        mvs.b   (%a0,%d3.l),%d0
        lea     GK_STOCK_SEQUENCER_TRACK_PARTS,%a0
        mvs.b   (%a0,%d3.l),%d1
        move.l  #GK_STOCK_BANK_STRIDE,%d2
        muls.l  %d2,%d0
        move.l  #GK_PART_PAYLOAD_SIZE,%d2
        muls.l  %d2,%d1
        lea     GK_STOCK_PHYSICAL_BASE,%a5
        adda.l  %d0,%a5
        adda.l  %d1,%a5
        adda.l  #GK_STOCK_SEQUENCER_PART_CONDITION_OFFSET,%a5
        rts
        .size   gk_sequencer_advance_quiesced_pointer,.-gk_sequencer_advance_quiesced_pointer
        .global gk_stock_sequencer_advance_enter
        .type   gk_stock_sequencer_advance_enter,@function
gk_stock_sequencer_advance_enter:
        move.l  %a5,-(%sp)
        move.l  %a6,-(%sp)
        .incbin "stock/0169.bin", 0, 4
        .incbin "stock/0169.bin", 4, 4
        move.l  48(%sp),%d3
        movea.l 52(%sp),%a4
        cmpi.l  #GK_SIDECAR_SEQUENCER_TRACK_COUNT - 1,%d3
        bhi.w   gk_sequencer_reader_fatal
        movea.l #-1,%a6
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_advance_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_sequencer_reader_fatal
        bsr.w   gk_sequencer_advance_quiesced_pointer
        jmp     GK_STOCK_SEQUENCER_ADVANCE_CONTINUE
.Lgk_advance_active:
        move.l  %d3,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        adda.l  %d0,%a0
        jsr     gk_selector_acquire
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_advance_unavailable
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_advance_unavailable
        tst.l   %d0
        bmi.w   gk_sequencer_reader_fatal
        movea.l %d0,%a6
        movea.l %a0,%a5
        adda.l  #GK_STOCK_SEQUENCER_PART_CONDITION_OFFSET,%a5
        jmp     GK_STOCK_SEQUENCER_ADVANCE_CONTINUE
.Lgk_advance_unavailable:
        jmp     GK_STOCK_SEQUENCER_ADVANCE_UNAVAILABLE
        .size   gk_stock_sequencer_advance_enter,.-gk_stock_sequencer_advance_enter
        .global gk_stock_sequencer_advance_return
        .type   gk_stock_sequencer_advance_return,@function
gk_stock_sequencer_advance_return:
        move.w  %sr,%d5
        lea     -20(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        move.w  %d5,16(%sp)
        move.l  %a6,%d0
        bmi.s   .Lgk_advance_return_restore
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.s   gk_sequencer_reader_fatal
.Lgk_advance_return_restore:
        movem.l 20(%sp),%d2-%d7/%a2-%a4
        movea.l 56(%sp),%a6
        movea.l 60(%sp),%a5
        movem.l (%sp),%d0-%d1/%a0-%a1
        move.w  16(%sp),%d5
        move.w  %d5,%sr
        movem.l 32(%sp),%d5
        tst.l   %d0
        lea     64(%sp),%sp
        rts
        .size   gk_stock_sequencer_advance_return,.-gk_stock_sequencer_advance_return
        .global gk_sequencer_reader_fatal
gk_sequencer_reader_fatal:
        illegal
        bra.s   gk_sequencer_reader_fatal
