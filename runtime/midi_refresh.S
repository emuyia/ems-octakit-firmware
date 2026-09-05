        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_selector_begin_physical
        .type   gk_selector_begin_physical,@function
gk_selector_begin_physical:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_begin_physical_range
        cmpi.l  #3,%d1
        bhi.w   .Lgk_begin_physical_range
        cmpi.l  #0xff,%d2
        bhi.w   .Lgk_begin_physical_range
        .incbin "stock/0103.bin", 0, 4
        .incbin "stock/0103.bin", 4, 4
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d2,%d5
        movea.l %a0,%a2
        lsl.l   #2,%d3
        add.l   %d4,%d3
        move.l  %d3,%d0
        bsr.w   gk_physical_validate
        tst.l   %d0
        bmi.s   .Lgk_begin_physical_restore
        cmp.l   %d5,%d1
        bne.s   .Lgk_begin_physical_corrupt
        move.l  %d0,%d4
        move.l %d4,%d3
        andi.l #0xff,%d3
        lsl.l #4,%d3
        lea __gk_descriptors,%a1
        adda.l %d3,%a1
        tst.w   GK_DESC_ROOTS(%a1)
        beq.s   .Lgk_begin_physical_corrupt
        movea.l %a2,%a0
        move.l  %d4,%d0
        bsr.w   gk_selector_begin_update
        bra.s   .Lgk_begin_physical_restore
.Lgk_begin_physical_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_begin_physical_restore:
        movem.l (%sp),%d2-%d5/%a2
        lea     20(%sp),%sp
        rts
.Lgk_begin_physical_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_selector_begin_physical,.-gk_selector_begin_physical
        .global gk_selector_commit_physical_part
        .type   gk_selector_commit_physical_part,@function
gk_selector_commit_physical_part:
        andi.l  #0xff,%d0
        andi.l  #0xff,%d1
        cmpi.l  #3,%d0
        bhi.w   .Lgk_commit_physical_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_commit_physical_range
        .incbin "stock/0104.bin", 0, 4
        .incbin "stock/0104.bin", 4, 4
        move.l  %d0,%d6
        move.l  %d1,%d7
        lsl.l   #2,%d7
        add.l   %d6,%d7
        movea.l %a0,%a2
        movea.l %a1,%a3
        moveq   #0,%d2
        move.w  (%a2),%d2
        move.l  %d2,%d3
        andi.l  #0xff,%d3
        cmpi.l  #GK_ID_NONE,%d3
        beq.w   .Lgk_commit_physical_busy
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w   .Lgk_commit_physical_corrupt
        lsr.l   #8,%d2
        andi.l  #0xff,%d2
        move.l  %d7,%d0
        bsr.w   gk_physical_validate
        tst.l   %d0
        bmi.w   .Lgk_commit_physical_corrupt
        cmp.l   %d3,%d0
        bne.w   .Lgk_commit_physical_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a4
        adda.l %d0,%a4
        tst.w   GK_DESC_ROOTS(%a4)
        beq.w   .Lgk_commit_physical_corrupt
        suba.l  %a1,%a1
        cmpi.l  #GK_ID_NONE,%d2
        beq.s   .Lgk_commit_physical_old_validated
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_commit_physical_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_commit_physical_corrupt
        btst    #2,GK_DESC_FLAGS(%a1)
        bne.w   .Lgk_commit_physical_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.w   .Lgk_commit_physical_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a1),%d0
        tst.l   %d0
        beq.w   .Lgk_commit_physical_corrupt
        cmp.l   %d3,%d2
        bne.s   .Lgk_commit_physical_old_validated
        cmpi.l  #2,%d0
        blo.w   .Lgk_commit_physical_corrupt
.Lgk_commit_physical_old_validated:
        .global gk_selector_physical_commit_pre_mask
gk_selector_physical_commit_pre_mask:
        move.w  %sr,%d5
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.w  (%a2),%d0
        move.l  %d2,%d1
        lsl.l   #8,%d1
        or.l    %d3,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_commit_physical_masked_corrupt
        moveq   #0,%d4
        move.b  GK_DESC_FLAGS(%a4),%d4
        move.l  %d4,%d0
        andi.l  #0x84,%d0
        bne.w   .Lgk_commit_physical_masked_corrupt
        btst    #0,%d4
        beq.w   .Lgk_commit_physical_masked_corrupt
        tst.l   GK_DESC_PAYLOAD(%a4)
        beq.w   .Lgk_commit_physical_masked_corrupt
        tst.w   GK_DESC_ROOTS(%a4)
        beq.w   .Lgk_commit_physical_masked_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a4),%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_commit_physical_masked_corrupt
        move.l  %d7,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_PAYLOAD(%a4),%a0
        bne.w   .Lgk_commit_physical_masked_corrupt
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a0
        adda.l %d0,%a0
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a0),%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_commit_physical_masked_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a0),%d0
        moveq   #0,%d4
        move.b  GK_DESC_KIT(%a4),%d4
        cmp.l   %d4,%d0
        bne.w   .Lgk_commit_physical_masked_corrupt
        tst.b   GK_PHYS_STATE(%a0)
        bne.w   .Lgk_commit_physical_masked_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a0),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_commit_physical_masked_corrupt
        tst.l   %a1
        beq.s   .Lgk_commit_physical_publish
        cmpa.l  %a4,%a1
        bne.s   .Lgk_commit_physical_old_distinct
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a1),%d0
        cmpi.l  #2,%d0
        blo.w   .Lgk_commit_physical_masked_corrupt
        bra.s   .Lgk_commit_physical_publish
.Lgk_commit_physical_old_distinct:
        tst.w   GK_DESC_ROOTS(%a1)
        beq.w   .Lgk_commit_physical_masked_corrupt
        .global gk_selector_physical_part_publication
gk_selector_physical_part_publication:
.Lgk_commit_physical_publish:
        move.b  %d6,(%a3)
        move.l  %d3,%d0
        lsl.l   #8,%d0
        ori.l   #0xff,%d0
        .global gk_selector_physical_sidecar_publication
gk_selector_physical_sidecar_publication:
        move.w  %d0,(%a2)
        tst.l   %a1
        beq.s   .Lgk_commit_physical_success
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a1),%d0
        subq.l  #1,%d0
        move.w  %d0,GK_DESC_ROOTS(%a1)
.Lgk_commit_physical_success:
        move.w  %d5,%sr
        moveq   #GK_OK,%d0
        bra.s   .Lgk_commit_physical_restore
.Lgk_commit_physical_masked_corrupt:
        move.w  %d5,%sr
.Lgk_commit_physical_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_commit_physical_restore
.Lgk_commit_physical_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_commit_physical_restore:
        .incbin "stock/0105.bin", 0, 4
        .incbin "stock/0105.bin", 4, 4
        rts
.Lgk_commit_physical_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_selector_commit_physical_part,.-gk_selector_commit_physical_part
        .global gk_selector_acquire_physical
        .type   gk_selector_acquire_physical,@function
gk_selector_acquire_physical:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_acquire_physical_range
        cmpi.l  #3,%d1
        bhi.w   .Lgk_acquire_physical_range
        .incbin "stock/0106.bin", 0, 4
        .incbin "stock/0106.bin", 4, 4
        move.l  %d0,%d2
        move.l  %d1,%d3
        bsr.w   gk_selector_acquire
        tst.l   %d0
        bmi.s   .Lgk_acquire_physical_restore
        move.l  %d0,%d4
        movea.l %a0,%a2
        lsl.l   #2,%d2
        add.l   %d3,%d2
        move.l  %d2,%d0
        bsr.w   gk_physical_validate
        tst.l   %d0
        bmi.s   .Lgk_acquire_physical_release_corrupt
        cmp.l   %d4,%d0
        bne.s   .Lgk_acquire_physical_release_corrupt
        cmpa.l  %a2,%a0
        bne.s   .Lgk_acquire_physical_release_corrupt
        move.l  %d4,%d0
        movea.l %a2,%a0
        bra.s   .Lgk_acquire_physical_restore
.Lgk_acquire_physical_release_corrupt:
        move.l  %d4,%d0
        bsr.w   gk_descriptor_release
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_acquire_physical_restore:
        movem.l (%sp),%d2-%d5/%a2-%a4
        lea     28(%sp),%sp
        rts
.Lgk_acquire_physical_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_selector_acquire_physical,.-gk_selector_acquire_physical
        .global gk_midi_refresh_begin
        .type   gk_midi_refresh_begin,@function
gk_midi_refresh_begin:
        .incbin "stock/0107.bin", 0, 4
        .incbin "stock/0107.bin", 4, 4
        moveq   #0,%d3
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d3
        cmpi.l  #15,%d3
        bhi.w   .Lgk_midi_begin_corrupt
        moveq   #0,%d4
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_midi_begin_corrupt
        move.l  %d3,%d0
        lsl.l   #4,%d0
        add.l   %d4,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d5
        move.b  (%a0,%d0.l),%d5
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
        move.l  %d3,%d0
        move.l  %d5,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_MIDI_REFRESH_OFFSET,%a0
        bsr.w   gk_selector_begin_physical
        bra.s   .Lgk_midi_begin_restore
.Lgk_midi_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_midi_begin_restore:
        movem.l (%sp),%d2-%d5/%a2-%a4
        lea     28(%sp),%sp
        rts
        .size   gk_midi_refresh_begin,.-gk_midi_refresh_begin
        .global gk_stock_midi_refresh_begin
        .type   gk_stock_midi_refresh_begin,@function
gk_stock_midi_refresh_begin:
        lea     -56(%sp),%sp
        movem.l %d0-%d1/%d3-%d7/%a0-%a6,(%sp)
        tst.b   __gk_sequencer_latch_queue_handoff
        bne.s   .Lgk_stock_midi_begin_publish
        bsr.w   gk_midi_refresh_begin
        tst.l   %d0
        beq.s   .Lgk_stock_midi_begin_publish
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_midi_refresh_fatal
.Lgk_stock_midi_begin_publish:
        movem.l (%sp),%d0-%d1/%d3-%d7/%a0-%a6
        lea     56(%sp),%sp
        .incbin "stock/0108.bin", 0, 2
        .incbin "stock/0108.bin", 2, 6
        jmp     GK_STOCK_MIDI_REFRESH_BEGIN_CONTINUE
        .size   gk_stock_midi_refresh_begin,.-gk_stock_midi_refresh_begin
        .global gk_stock_midi_refresh_commit
        .type   gk_stock_midi_refresh_commit,@function
gk_stock_midi_refresh_commit:
        lea     -60(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        moveq   #0,%d0
        move.b  (%a0),%d0
        tst.b   __gk_sequencer_latch_queue_handoff
        bne.s   .Lgk_stock_midi_commit_stock_only
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_stock_midi_commit_stock_only
        moveq   #0,%d1
        move.b  GK_STOCK_MIDI_REFRESH_BANK,%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_MIDI_REFRESH_OFFSET,%a0
        lea     GK_STOCK_MIDI_REFRESH_PART,%a1
        bsr.w   gk_selector_commit_physical_part
        tst.l   %d0
        bne.w   gk_midi_refresh_fatal
        bra.s   .Lgk_stock_midi_commit_restore
.Lgk_stock_midi_commit_stock_only:
        move.b  %d0,GK_STOCK_MIDI_REFRESH_PART
.Lgk_stock_midi_commit_restore:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        jmp     GK_STOCK_MIDI_REFRESH_COMMIT_CONTINUE
        .size   gk_stock_midi_refresh_commit,.-gk_stock_midi_refresh_commit
        .global gk_stock_midi_refresh_consume
        .type   gk_stock_midi_refresh_consume,@function
gk_stock_midi_refresh_consume:
        tst.b   __gk_sequencer_latch_queue_handoff
        beq.s   .Lgk_midi_consume_not_queue_handoff
        jmp     GK_STOCK_MIDI_REFRESH_CONSUME_CONTINUE
.Lgk_midi_consume_not_queue_handoff:
        move.l  %d4,-(%sp)
        lea     -56(%sp),%sp
        movem.l %d0-%d3/%d5-%d7/%a0-%a6,(%sp)
        moveq   #0,%d0
        move.b  GK_STOCK_MIDI_REFRESH_BANK,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_MIDI_REFRESH_PART,%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_MIDI_REFRESH_OFFSET,%a0
        bsr.w   gk_selector_acquire_physical
        tst.l   %d0
        bmi.s   .Lgk_midi_consume_skip
        move.l  %d0,%d4
        movem.l (%sp),%d0-%d3/%d5-%d7/%a0-%a6
        lea     56(%sp),%sp
        .incbin "stock/0109.bin", 0, 6
        .incbin "stock/0109.bin", 6, 6
        .incbin "stock/0109.bin", 12, 2
        .incbin "stock/0109.bin", 14, 6
        .incbin "stock/0109.bin", 20, 2
        .incbin "stock/0109.bin", 22, 6
        .incbin "stock/0109.bin", 28, 2
        move.l  %d4,%d0
        bsr.w   gk_descriptor_release
        tst.l   %d0
        bne.w   gk_midi_refresh_fatal
        move.l  (%sp)+,%d4
        jmp     GK_STOCK_MIDI_REFRESH_CONSUME_CONTINUE
.Lgk_midi_consume_skip:
        movem.l (%sp),%d0-%d3/%d5-%d7/%a0-%a6
        lea     56(%sp),%sp
        move.l  (%sp)+,%d4
        jmp     GK_STOCK_MIDI_REFRESH_CONSUME_CONTINUE
        .size   gk_stock_midi_refresh_consume,.-gk_stock_midi_refresh_consume
        .global gk_midi_refresh_fatal
gk_midi_refresh_fatal:
        illegal
        bra.s   gk_midi_refresh_fatal
