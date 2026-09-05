        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_voice_pending_pattern_begin
        .type   gk_stock_voice_pending_pattern_begin,@function
gk_stock_voice_pending_pattern_begin:
        lea     -60(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        cmpi.l  #7,%d1
        bhi.w   .Lgk_voice_pattern_begin_corrupt
        move.l  0x70(%sp),%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_voice_pattern_begin_corrupt
        movea.l 0x78(%sp),%a2
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        moveq   #0,%d3
.Lgk_voice_pattern_bank_scan:
        cmpa.l  %a2,%a3
        beq.s   .Lgk_voice_pattern_bank_found
        adda.l  #GK_STOCK_BANK_STRIDE,%a3
        addq.l  #1,%d3
        cmpi.l  #16,%d3
        bne.s   .Lgk_voice_pattern_bank_scan
        bra.w   .Lgk_voice_pattern_begin_corrupt
.Lgk_voice_pattern_bank_found:
        move.l  %d4,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET - 1,%a3
        cmpa.l  %a4,%a3
        bne.w   .Lgk_voice_pattern_begin_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_voice_pattern_begin_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_voice_pattern_begin_corrupt
        move.l  %d3,%d0
        lsl.l   #4,%d0
        add.l   %d4,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        move.l  %d1,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_VOICE_PENDING_OFFSET,%a0
        adda.l  %d0,%a0
        moveq   #0,%d1
        move.b  1(%a4),%d1
        move.l  %d3,%d0
        bsr.w   gk_selector_begin_physical
        tst.l   %d0
        beq.s   .Lgk_voice_pattern_begin_stock
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_voice_pending_fatal
.Lgk_voice_pattern_begin_stock:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        .incbin "stock/0201.bin", 0, 2
        .incbin "stock/0201.bin", 2, 4
        .incbin "stock/0201.bin", 6, 2
        jmp     GK_STOCK_VOICE_PENDING_PATTERN_BEGIN_CONTINUE
.Lgk_voice_pattern_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_voice_pattern_begin_stock
        bra.w   gk_voice_pending_fatal
        .size   gk_stock_voice_pending_pattern_begin,.-gk_stock_voice_pending_pattern_begin
        .global gk_stock_voice_pending_pattern_commit
        .type   gk_stock_voice_pending_pattern_commit,@function
gk_stock_voice_pending_pattern_commit:
        lea     -60(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.l  %d1,%d4
        cmpi.l  #7,%d4
        bhi.w   .Lgk_voice_pattern_commit_corrupt
        moveq   #0,%d0
        move.b  (%a0),%d0
        moveq   #0,%d1
        lea     GK_STOCK_VOICE_PENDING_BANKS,%a3
        move.b  (%a3,%d4.l),%d1
        move.l  %d4,%d2
        lsl.l   #1,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_VOICE_PENDING_OFFSET,%a0
        adda.l  %d2,%a0
        lea     (%a2,%d4.l),%a1
        bsr.w   gk_selector_commit_physical_part
        tst.l   %d0
        beq.s   .Lgk_voice_pattern_commit_success
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_voice_pending_fatal
.Lgk_voice_pattern_commit_stock:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        .incbin "stock/0202.bin", 0, 4
        .incbin "stock/0202.bin", 4, 6
        jmp     GK_STOCK_VOICE_PENDING_PATTERN_COMMIT_CONTINUE
.Lgk_voice_pattern_commit_success:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        tst.b   (%a0)
        lea     0x46c77bc2,%a2
        jmp     GK_STOCK_VOICE_PENDING_PATTERN_COMMIT_CONTINUE
.Lgk_voice_pattern_commit_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.w   .Lgk_voice_pattern_commit_stock
        bra.w   gk_voice_pending_fatal
        .size   gk_stock_voice_pending_pattern_commit,.-gk_stock_voice_pending_pattern_commit
        .global gk_stock_voice_pending_periodic_begin
        .type   gk_stock_voice_pending_periodic_begin,@function
gk_stock_voice_pending_periodic_begin:
        lea     -60(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        cmpi.l  #15,%d3
        bhi.w   .Lgk_voice_periodic_begin_corrupt
        cmpi.l  #15,%d4
        bhi.w   .Lgk_voice_periodic_begin_corrupt
        cmpi.l  #2,%d6
        bhi.w   .Lgk_voice_periodic_begin_corrupt
        cmpi.l  #7,%d7
        bhi.w   .Lgk_voice_periodic_begin_corrupt
        move.l  %a3,%d0
        cmp.b   %d3,%d0
        bne.s   .Lgk_voice_periodic_begin_corrupt
        move.l  %d3,%d0
        lsl.l   #4,%d0
        add.l   %d4,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        move.l  %d3,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d4,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a0
        moveq   #0,%d1
        move.b  (%a0),%d1
        move.l  %d6,%d0
        lsl.l   #3,%d0
        add.l   %d7,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_VOICE_PENDING_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d3,%d0
        move.l  %d4,%d7
        bsr.w   gk_audio_periodic_queue_handoff_begin_or_defer
        tst.l   %d0
        beq.s   .Lgk_voice_periodic_begin_stock
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_voice_pending_fatal
.Lgk_voice_periodic_begin_stock:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        .incbin "stock/0203.bin", 0, 2
        .incbin "stock/0203.bin", 2, 2
        .incbin "stock/0203.bin", 4, 2
        .incbin "stock/0203.bin", 6, 2
        jmp     GK_STOCK_VOICE_PENDING_PERIODIC_BEGIN_CONTINUE
.Lgk_voice_periodic_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_voice_periodic_begin_stock
        bra.w   gk_voice_pending_fatal
        .size   gk_stock_voice_pending_periodic_begin,.-gk_stock_voice_pending_periodic_begin
        .global gk_stock_voice_pending_periodic_commit
        .type   gk_stock_voice_pending_periodic_commit,@function
gk_stock_voice_pending_periodic_commit:
        lea     -60(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.l  %a2,%d5
        cmpi.l  #23,%d5
        bhi.w   .Lgk_voice_periodic_commit_corrupt
        lea     1(%a1,%d0.l),%a3
        moveq   #0,%d0
        move.b  (%a3),%d0
        moveq   #0,%d1
        lea     GK_STOCK_VOICE_PENDING_BANKS,%a4
        move.b  (%a4,%d5.l),%d1
        move.l  %d5,%d2
        lsl.l   #1,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_VOICE_PENDING_OFFSET,%a4
        movea.l %a4,%a0
        adda.l  %d2,%a0
        lea     GK_STOCK_VOICE_PENDING_PARTS,%a4
        lea     (%a4,%d5.l),%a1
        bsr.w   gk_audio_periodic_queue_handoff_commit
        tst.l   %d0
        beq.s   .Lgk_voice_periodic_commit_success
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_voice_pending_fatal
.Lgk_voice_periodic_commit_stock:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        .incbin "stock/0204.bin", 0, 4
        .incbin "stock/0204.bin", 4, 4
        jmp     GK_STOCK_VOICE_PENDING_PERIODIC_COMMIT_CONTINUE
.Lgk_voice_periodic_commit_success:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        lea     1(%a1,%d0.l),%a1
        tst.b   (%a1)
        jmp     GK_STOCK_VOICE_PENDING_PERIODIC_COMMIT_CONTINUE
.Lgk_voice_periodic_commit_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.w   .Lgk_voice_periodic_commit_stock
        bra.w   gk_voice_pending_fatal
        .size   gk_stock_voice_pending_periodic_commit,.-gk_stock_voice_pending_periodic_commit
        .global gk_voice_pending_fatal
gk_voice_pending_fatal:
        illegal
        bra.s   gk_voice_pending_fatal
