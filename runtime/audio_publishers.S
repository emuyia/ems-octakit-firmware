        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_audio_pattern_primary_begin
        .type   gk_stock_audio_pattern_primary_begin,@function
gk_stock_audio_pattern_primary_begin:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        cmpi.l  #7,%d4
        bhi.w   .Lgk_audio_pattern_primary_begin_corrupt
        move.l  0x74(%sp),%d5
        cmpi.l  #15,%d5
        bhi.w   .Lgk_audio_pattern_primary_begin_corrupt
        movea.l 0x7c(%sp),%a2
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        moveq   #0,%d6
.Lgk_audio_pattern_primary_bank_scan:
        cmpa.l  %a2,%a3
        beq.s   .Lgk_audio_pattern_primary_bank_found
        adda.l  #GK_STOCK_BANK_STRIDE,%a3
        addq.l  #1,%d6
        cmpi.l  #16,%d6
        bne.s   .Lgk_audio_pattern_primary_bank_scan
        bra.w   .Lgk_audio_pattern_primary_begin_corrupt
.Lgk_audio_pattern_primary_bank_found:
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        lea     -1(%a3),%a0
        cmpa.l  %a4,%a0
        bne.w   .Lgk_audio_pattern_primary_begin_corrupt
        moveq   #0,%d7
        move.b  %d2,%d7
        cmp.l   %d6,%d7
        bne.w   .Lgk_audio_pattern_primary_begin_corrupt
        move.l  %d6,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        moveq   #0,%d1
        move.b  (%a3),%d1
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d6,%d0
        bsr.w   gk_selector_begin_physical
        tst.l   %d0
        beq.s   .Lgk_audio_pattern_primary_begin_stock
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_pattern_primary_begin_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0013.bin", 0, 6
        jmp     GK_STOCK_AUDIO_PATTERN_PRIMARY_BEGIN_CONTINUE
.Lgk_audio_pattern_primary_begin_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_audio_pattern_primary_begin_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_pattern_primary_begin,.-gk_stock_audio_pattern_primary_begin
        .global gk_stock_audio_pattern_primary_commit
        .type   gk_stock_audio_pattern_primary_commit,@function
gk_stock_audio_pattern_primary_commit:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  %d4,%d5
        cmpi.l  #7,%d5
        bhi.w   .Lgk_audio_pattern_primary_commit_corrupt
        moveq   #0,%d0
        move.b  %d3,%d0
        moveq   #0,%d1
        .incbin "stock/0014.bin", 0, 6
        move.b  (%a2,%d5.l),%d1
        lea     (%a3,%d5.l),%a1
        move.l  %d5,%d2
        lsl.l   #1,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d2,%a0
        bsr.w   gk_selector_commit_physical_part
        tst.l   %d0
        beq.s   .Lgk_audio_pattern_primary_commit_success
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_pattern_primary_commit_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0015.bin", 0, 4
        .incbin "stock/0015.bin", 4, 6
        jmp     GK_STOCK_AUDIO_PATTERN_PRIMARY_COMMIT_CONTINUE
.Lgk_audio_pattern_primary_commit_success:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_pattern_primary_ccr_replay
gk_audio_pattern_primary_ccr_replay:
        tst.b   %d3
        lea     0x46c7a852,%a0
        jmp     GK_STOCK_AUDIO_PATTERN_PRIMARY_COMMIT_CONTINUE
.Lgk_audio_pattern_primary_commit_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_audio_pattern_primary_commit_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_pattern_primary_commit,.-gk_stock_audio_pattern_primary_commit
        .global gk_stock_audio_pattern_secondary_begin
        .type   gk_stock_audio_pattern_secondary_begin,@function
gk_stock_audio_pattern_secondary_begin:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        cmpi.l  #7,%d4
        bhi.w   .Lgk_audio_pattern_secondary_begin_corrupt
        move.l  0x74(%sp),%d5
        cmpi.l  #15,%d5
        bhi.w   .Lgk_audio_pattern_secondary_begin_corrupt
        movea.l 0x7c(%sp),%a2
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        moveq   #0,%d6
.Lgk_audio_pattern_secondary_bank_scan:
        cmpa.l  %a2,%a3
        beq.s   .Lgk_audio_pattern_secondary_bank_found
        adda.l  #GK_STOCK_BANK_STRIDE,%a3
        addq.l  #1,%d6
        cmpi.l  #16,%d6
        bne.s   .Lgk_audio_pattern_secondary_bank_scan
        bra.w   .Lgk_audio_pattern_secondary_begin_corrupt
.Lgk_audio_pattern_secondary_bank_found:
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        lea     -1(%a3),%a0
        cmpa.l  %a4,%a0
        bne.w   .Lgk_audio_pattern_secondary_begin_corrupt
        moveq   #0,%d7
        move.b  %d2,%d7
        cmp.l   %d6,%d7
        bne.w   .Lgk_audio_pattern_secondary_begin_corrupt
        moveq   #0,%d0
        move.b  %d3,%d0
        moveq   #0,%d1
        move.b  (%a3),%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_audio_pattern_secondary_begin_corrupt
        move.l  %d6,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SECONDARY_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d6,%d0
        bsr.w   gk_selector_begin_physical
        tst.l   %d0
        beq.s   .Lgk_audio_pattern_secondary_begin_stock
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_pattern_secondary_begin_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0016.bin", 0, 6
        jmp     GK_STOCK_AUDIO_PATTERN_SECONDARY_BEGIN_CONTINUE
.Lgk_audio_pattern_secondary_begin_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_audio_pattern_secondary_begin_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_pattern_secondary_begin,.-gk_stock_audio_pattern_secondary_begin
        .global gk_stock_audio_pattern_secondary_commit
        .type   gk_stock_audio_pattern_secondary_commit,@function
gk_stock_audio_pattern_secondary_commit:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  %d4,%d5
        cmpi.l  #7,%d5
        bhi.w   .Lgk_audio_pattern_secondary_commit_corrupt
        moveq   #0,%d0
        move.b  %d3,%d0
        moveq   #0,%d1
        lea     GK_STOCK_AUDIO_SECONDARY_BANKS,%a2
        move.b  (%a2,%d5.l),%d1
        lea     (%a0,%d5.l),%a1
        move.l  %d5,%d2
        lsl.l   #1,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SECONDARY_OFFSET,%a0
        adda.l  %d2,%a0
        bsr.w   gk_selector_commit_physical_part
        tst.l   %d0
        beq.s   .Lgk_audio_pattern_secondary_commit_success
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_pattern_secondary_commit_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0017.bin", 0, 4
        .incbin "stock/0017.bin", 4, 2
        jmp     GK_STOCK_AUDIO_PATTERN_SECONDARY_COMMIT_CONTINUE
.Lgk_audio_pattern_secondary_commit_success:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_pattern_secondary_ccr_replay
gk_audio_pattern_secondary_ccr_replay:
        move.l  %d4,%d0
        jmp     GK_STOCK_AUDIO_PATTERN_SECONDARY_COMMIT_CONTINUE
.Lgk_audio_pattern_secondary_commit_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_audio_pattern_secondary_commit_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_pattern_secondary_commit,.-gk_stock_audio_pattern_secondary_commit
        .global gk_stock_audio_pattern_special_begin
        .type   gk_stock_audio_pattern_special_begin,@function
gk_stock_audio_pattern_special_begin:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  %d0,%d4
        cmpi.l  #7,%d4
        bhi.w   .Lgk_audio_pattern_special_begin_corrupt
        move.l  0x74(%sp),%d5
        cmpi.l  #15,%d5
        bhi.w   .Lgk_audio_pattern_special_begin_corrupt
        movea.l 0x7c(%sp),%a2
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        moveq   #0,%d6
.Lgk_audio_pattern_special_bank_scan:
        cmpa.l  %a2,%a3
        beq.s   .Lgk_audio_pattern_special_bank_found
        adda.l  #GK_STOCK_BANK_STRIDE,%a3
        addq.l  #1,%d6
        cmpi.l  #16,%d6
        bne.s   .Lgk_audio_pattern_special_bank_scan
        bra.w   .Lgk_audio_pattern_special_begin_corrupt
.Lgk_audio_pattern_special_bank_found:
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_audio_pattern_special_begin_corrupt
        move.l  %d5,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a2,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        move.l  %d6,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        moveq   #0,%d1
        move.b  (%a3),%d1
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d6,%d0
        bsr.w   gk_selector_begin_physical
        tst.l   %d0
        beq.s   .Lgk_audio_pattern_special_begin_stock
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_pattern_special_begin_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0018.bin", 0, 6
        jmp     GK_STOCK_AUDIO_PATTERN_SPECIAL_BEGIN_CONTINUE
.Lgk_audio_pattern_special_begin_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_audio_pattern_special_begin_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_pattern_special_begin,.-gk_stock_audio_pattern_special_begin
        .global gk_stock_audio_pattern_special_commit
        .type   gk_stock_audio_pattern_special_commit,@function
gk_stock_audio_pattern_special_commit:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  %d0,%d5
        cmpi.l  #7,%d5
        bhi.w   .Lgk_audio_pattern_special_commit_corrupt
        move.l  0x74(%sp),%d7
        cmpi.l  #15,%d7
        bhi.w   .Lgk_audio_pattern_special_commit_corrupt
        movea.l 0x7c(%sp),%a2
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        moveq   #0,%d6
.Lgk_audio_pattern_special_commit_bank_scan:
        cmpa.l  %a2,%a3
        beq.s   .Lgk_audio_pattern_special_commit_bank_found
        adda.l  #GK_STOCK_BANK_STRIDE,%a3
        addq.l  #1,%d6
        cmpi.l  #16,%d6
        bne.s   .Lgk_audio_pattern_special_commit_bank_scan
        bra.w   .Lgk_audio_pattern_special_commit_corrupt
.Lgk_audio_pattern_special_commit_bank_found:
        moveq   #0,%d0
        .incbin "stock/0019.bin", 0, 6
        move.b  (%a2,%d5.l),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_audio_pattern_special_commit_corrupt
        move.l  %d7,%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        move.l  %d6,%d2
        move.l  #GK_STOCK_BANK_STRIDE,%d3
        muls.l  %d3,%d2
        add.l   %d2,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d2
        move.b  (%a3),%d2
        moveq   #0,%d0
        move.b  %d1,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_audio_pattern_special_commit_corrupt
        lea     (%a0,%d5.l),%a1
        move.l  %d5,%d2
        lsl.l   #1,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d2,%a0
        move.l  %d6,%d1
        bsr.w   gk_selector_commit_physical_part
        tst.l   %d0
        beq.s   .Lgk_audio_pattern_special_commit_success
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_pattern_special_commit_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0020.bin", 0, 4
        .incbin "stock/0020.bin", 4, 6
        jmp     GK_STOCK_AUDIO_PATTERN_SPECIAL_COMMIT_CONTINUE
.Lgk_audio_pattern_special_commit_success:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_pattern_special_ccr_replay
gk_audio_pattern_special_ccr_replay:
        tst.b   %d1
        lea     0x46c7fa20,%a0
        jmp     GK_STOCK_AUDIO_PATTERN_SPECIAL_COMMIT_CONTINUE
.Lgk_audio_pattern_special_commit_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.w   .Lgk_audio_pattern_special_commit_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_pattern_special_commit,.-gk_stock_audio_pattern_special_commit
        .global gk_stock_audio_periodic_primary_begin
        .type   gk_stock_audio_periodic_primary_begin,@function
gk_stock_audio_periodic_primary_begin:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  %a1,%d4
        cmpi.l  #23,%d4
        bhi.w   .Lgk_audio_periodic_primary_begin_corrupt
        cmp.l   0x82(%sp),%d4
        bne.w   .Lgk_audio_periodic_primary_begin_corrupt
        move.l  %a6,%d3
        cmpi.l  #2,%d3
        bhi.w   .Lgk_audio_periodic_primary_begin_corrupt
        cmpi.l  #7,%d5
        bhi.w   .Lgk_audio_periodic_primary_begin_corrupt
        move.l  %d3,%d0
        lsl.l   #3,%d0
        add.l   %d5,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_audio_periodic_primary_begin_corrupt
        move.l  0x8a(%sp),%d6
        cmpi.l  #15,%d6
        bhi.w   .Lgk_audio_periodic_primary_begin_corrupt
        move.l  0x8e(%sp),%d7
        cmpi.l  #15,%d7
        bhi.w   .Lgk_audio_periodic_primary_begin_corrupt
        moveq   #0,%d0
        move.b  0x93(%sp),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_audio_periodic_primary_begin_corrupt
        move.l  %d6,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d7,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        move.l  %d6,%d0
        lsl.l   #4,%d0
        add.l   %d7,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d6,%d0
        bsr.w   gk_audio_periodic_queue_handoff_begin_or_defer
        tst.l   %d0
        beq.s   .Lgk_audio_periodic_primary_begin_stock
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_periodic_primary_begin_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0021.bin", 0, 6
        jmp     GK_STOCK_AUDIO_PERIODIC_PRIMARY_BEGIN_CONTINUE
.Lgk_audio_periodic_primary_begin_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_audio_periodic_primary_begin_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_periodic_primary_begin,.-gk_stock_audio_periodic_primary_begin
        .global gk_stock_audio_periodic_primary_commit
        .type   gk_stock_audio_periodic_primary_commit,@function
gk_stock_audio_periodic_primary_commit:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  %d4,%d3
        cmpi.l  #23,%d3
        bhi.w   .Lgk_audio_periodic_primary_commit_corrupt
        cmp.l   0x82(%sp),%d3
        bne.w   .Lgk_audio_periodic_primary_commit_corrupt
        moveq   #0,%d4
        move.b  %d0,%d4
        lea     (%a0,%d3.l),%a4
        move.l  %a6,%d2
        cmpi.l  #2,%d2
        bhi.w   .Lgk_audio_periodic_primary_commit_corrupt
        cmpi.l  #7,%d5
        bhi.w   .Lgk_audio_periodic_primary_commit_corrupt
        move.l  %d2,%d0
        lsl.l   #3,%d0
        add.l   %d5,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_audio_periodic_primary_commit_corrupt
        move.l  0x8a(%sp),%d6
        cmpi.l  #15,%d6
        bhi.w   .Lgk_audio_periodic_primary_commit_corrupt
        move.l  0x8e(%sp),%d7
        cmpi.l  #15,%d7
        bhi.w   .Lgk_audio_periodic_primary_commit_corrupt
        moveq   #0,%d0
        move.b  0x93(%sp),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_audio_periodic_primary_commit_corrupt
        moveq   #0,%d1
        .incbin "stock/0022.bin", 0, 6
        move.b  (%a2,%d3.l),%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_audio_periodic_primary_commit_corrupt
        move.l  %d6,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d7,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d0
        move.b  (%a3),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_audio_periodic_primary_commit_corrupt
        move.l  %d3,%d2
        lsl.l   #1,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d2,%a0
        movea.l %a4,%a1
        move.l  %d4,%d0
        move.l  %d6,%d1
        bsr.w   gk_audio_periodic_queue_handoff_commit
        tst.l   %d0
        beq.s   .Lgk_audio_periodic_primary_commit_success
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_periodic_primary_commit_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0023.bin", 0, 4
        .incbin "stock/0023.bin", 4, 6
        jmp     GK_STOCK_AUDIO_PERIODIC_PRIMARY_COMMIT_CONTINUE
.Lgk_audio_periodic_primary_commit_success:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_periodic_primary_ccr_replay
gk_audio_periodic_primary_ccr_replay:
        mvs.b   GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d1
        jmp     GK_STOCK_AUDIO_PERIODIC_PRIMARY_COMMIT_CONTINUE
.Lgk_audio_periodic_primary_commit_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.w   .Lgk_audio_periodic_primary_commit_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_periodic_primary_commit,.-gk_stock_audio_periodic_primary_commit
        .global gk_stock_audio_periodic_secondary_begin
        .type   gk_stock_audio_periodic_secondary_begin,@function
gk_stock_audio_periodic_secondary_begin:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  %a1,%d4
        cmpi.l  #23,%d4
        bhi.w   .Lgk_audio_periodic_secondary_begin_corrupt
        move.l  %d6,%d3
        cmpi.l  #2,%d3
        bhi.w   .Lgk_audio_periodic_secondary_begin_corrupt
        cmpi.l  #7,%d5
        bhi.w   .Lgk_audio_periodic_secondary_begin_corrupt
        move.l  %d3,%d0
        lsl.l   #3,%d0
        add.l   %d5,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_audio_periodic_secondary_begin_corrupt
        move.l  0x8a(%sp),%d6
        cmpi.l  #15,%d6
        bhi.w   .Lgk_audio_periodic_secondary_begin_corrupt
        move.l  0x8e(%sp),%d7
        cmpi.l  #15,%d7
        bhi.w   .Lgk_audio_periodic_secondary_begin_corrupt
        moveq   #0,%d0
        move.b  0x93(%sp),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_audio_periodic_secondary_begin_corrupt
        move.l  %d6,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d7,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d1
        move.b  (%a3),%d1
        move.l  %d6,%d0
        lsl.l   #4,%d0
        add.l   %d7,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SECONDARY_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d6,%d0
        bsr.w   gk_audio_periodic_queue_handoff_begin_or_defer
        tst.l   %d0
        beq.s   .Lgk_audio_periodic_secondary_begin_stock
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_periodic_secondary_begin_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0024.bin", 0, 6
        jmp     GK_STOCK_AUDIO_PERIODIC_SECONDARY_BEGIN_CONTINUE
.Lgk_audio_periodic_secondary_begin_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_audio_periodic_secondary_begin_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_periodic_secondary_begin,.-gk_stock_audio_periodic_secondary_begin
        .global gk_stock_audio_periodic_secondary_commit
        .type   gk_stock_audio_periodic_secondary_commit,@function
gk_stock_audio_periodic_secondary_commit:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  %a1,%d3
        cmpi.l  #23,%d3
        bhi.w   .Lgk_audio_periodic_secondary_commit_corrupt
        moveq   #0,%d4
        move.b  %d0,%d4
        lea     (%a0,%d3.l),%a4
        move.l  %d6,%d2
        cmpi.l  #2,%d2
        bhi.w   .Lgk_audio_periodic_secondary_commit_corrupt
        cmpi.l  #7,%d5
        bhi.w   .Lgk_audio_periodic_secondary_commit_corrupt
        move.l  %d2,%d0
        lsl.l   #3,%d0
        add.l   %d5,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_audio_periodic_secondary_commit_corrupt
        move.l  0x8a(%sp),%d6
        cmpi.l  #15,%d6
        bhi.w   .Lgk_audio_periodic_secondary_commit_corrupt
        move.l  0x8e(%sp),%d7
        cmpi.l  #15,%d7
        bhi.w   .Lgk_audio_periodic_secondary_commit_corrupt
        moveq   #0,%d0
        move.b  0x93(%sp),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_audio_periodic_secondary_commit_corrupt
        moveq   #0,%d1
        lea     GK_STOCK_AUDIO_SECONDARY_BANKS,%a2
        move.b  (%a2,%d3.l),%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_audio_periodic_secondary_commit_corrupt
        move.l  %d6,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d7,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a3
        adda.l  %d0,%a3
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a3
        moveq   #0,%d0
        move.b  (%a3),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_audio_periodic_secondary_commit_corrupt
        move.l  %d3,%d2
        lsl.l   #1,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SECONDARY_OFFSET,%a0
        adda.l  %d2,%a0
        movea.l %a4,%a1
        move.l  %d4,%d0
        move.l  %d6,%d1
        bsr.w   gk_audio_periodic_queue_handoff_commit
        tst.l   %d0
        beq.s   .Lgk_audio_periodic_secondary_commit_success
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        bne.w   gk_audio_publisher_fatal
.Lgk_audio_periodic_secondary_commit_stock:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0025.bin", 0, 4
        .incbin "stock/0025.bin", 4, 6
        jmp     GK_STOCK_AUDIO_PERIODIC_SECONDARY_COMMIT_CONTINUE
.Lgk_audio_periodic_secondary_commit_success:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_periodic_secondary_ccr_replay
gk_audio_periodic_secondary_ccr_replay:
        mvs.b   GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d1
        jmp     GK_STOCK_AUDIO_PERIODIC_SECONDARY_COMMIT_CONTINUE
.Lgk_audio_periodic_secondary_commit_corrupt:
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.w   .Lgk_audio_periodic_secondary_commit_stock
        bra.w   gk_audio_publisher_fatal
        .size   gk_stock_audio_periodic_secondary_commit,.-gk_stock_audio_periodic_secondary_commit
        .global gk_audio_publisher_fatal
gk_audio_publisher_fatal:
        illegal
        bra.s   gk_audio_publisher_fatal
