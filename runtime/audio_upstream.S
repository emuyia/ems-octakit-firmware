        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_audio_upstream_acquire_source
        .type   gk_audio_upstream_acquire_source,@function
gk_audio_upstream_acquire_source:
        jsr     gk_selector_acquire_pair
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_audio_upstream_acquire_return
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_audio_upstream_acquire_return
        tst.l   %d0
        bmi.s   .Lgk_audio_upstream_acquire_return
        move.l  %d0,%d6
        cmp.l   %d1,%d7
        bne.s   .Lgk_audio_upstream_acquire_mismatch
        move.l  %d6,%d0
.Lgk_audio_upstream_acquire_return:
        rts
.Lgk_audio_upstream_acquire_mismatch:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_audio_upstream_acquire_return
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_audio_upstream_acquire_source,.-gk_audio_upstream_acquire_source
        .global gk_audio_upstream_validate_pinned
        .type   gk_audio_upstream_validate_pinned,@function
gk_audio_upstream_validate_pinned:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_audio_upstream_validate_range
        lea     -16(%sp),%sp
        movem.l %d2-%d4/%a1,(%sp)
        move.l  %d0,%d3
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        move.l %d3,%d2
        andi.l #0xff,%d2
        lsl.l #4,%d2
        lea __gk_descriptors,%a1
        adda.l %d2,%a1
        moveq   #0,%d2
        move.b  GK_DESC_FLAGS(%a1),%d2
        andi.l  #0x80,%d2
        bne.s   .Lgk_audio_upstream_validate_corrupt
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_audio_upstream_validate_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.s   .Lgk_audio_upstream_validate_corrupt
        tst.w   GK_DESC_READERS(%a1)
        beq.s   .Lgk_audio_upstream_validate_corrupt
        moveq   #0,%d2
        move.b  GK_DESC_PHYSICAL(%a1),%d2
        cmpi.l  #GK_ID_NONE,%d2
        beq.s   .Lgk_audio_upstream_validate_spilled
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d2
        bhi.s   .Lgk_audio_upstream_validate_corrupt
        btst    #2,GK_DESC_FLAGS(%a1)
        bne.s   .Lgk_audio_upstream_validate_corrupt
        move.l  %d1,%d0
        lsr.l   #8,%d0
        andi.l  #0xff,%d0
        cmpi.l  #GK_BANK_COUNT - 1,%d0
        bhi.s   .Lgk_audio_upstream_validate_corrupt
        lsl.l   #2,%d0
        move.l  %d1,%d3
        andi.l  #0xff,%d3
        cmpi.l  #GK_PARTS_PER_BANK - 1,%d3
        bhi.s   .Lgk_audio_upstream_validate_corrupt
        add.l   %d3,%d0
        cmp.l   %d0,%d2
        bne.s   .Lgk_audio_upstream_validate_corrupt
        bra.s   .Lgk_audio_upstream_validate_ok
.Lgk_audio_upstream_validate_spilled:
        btst    #2,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_audio_upstream_validate_corrupt
.Lgk_audio_upstream_validate_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_audio_upstream_validate_restore
.Lgk_audio_upstream_validate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_audio_upstream_validate_restore:
        move.w  %d4,%sr
        movem.l (%sp),%d2-%d4/%a1
        lea     16(%sp),%sp
        rts
.Lgk_audio_upstream_validate_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_audio_upstream_validate_pinned,.-gk_audio_upstream_validate_pinned
        .global gk_stock_audio_primary_type_read
        .type   gk_stock_audio_primary_type_read,@function
gk_stock_audio_primary_type_read:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_primary_type_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_audio_primary_type_stock_restore
        bra.w   gk_audio_upstream_fatal
.Lgk_audio_primary_type_active:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_audio_upstream_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SOURCE_KIND_SP(%sp),%d0
        cmpi.l  #GK_AUDIO_SOURCE_PRIMARY,%d0
        bne.w   gk_audio_upstream_fatal
        moveq   #0,%d3
        move.l  64 + 0x72(%sp),%d3
        cmpi.l  #6,%d3
        bhi.w   gk_audio_upstream_fatal
        cmpi.l  #3,%d3
        beq.w   gk_audio_upstream_fatal
        moveq   #0,%d2
        move.l  64 + 0x98(%sp),%d2
        cmpi.l  #7,%d2
        bhi.w   gk_audio_upstream_fatal
        move.l  %d3,%d0
        addq.l  #1,%d0
        cmp.l   %d0,%d2
        bne.w   gk_audio_upstream_fatal
        cmp.l   16(%sp),%d2
        bne.w   gk_audio_upstream_fatal
        moveq   #0,%d4
        move.l  64 + 0x78(%sp),%d4
        cmpi.l  #2,%d4
        bhi.w   gk_audio_upstream_fatal
        move.l  %d4,%d5
        lsl.l   #3,%d5
        add.l   %d3,%d5
        cmp.l   64 + 0x48(%sp),%d5
        bne.w   gk_audio_upstream_fatal
        cmpi.l  #GK_SIDECAR_AUDIO_PRIMARY_COUNT - 1,%d5
        bhi.w   gk_audio_upstream_fatal
        moveq #0,%d7
        move.b 64+0x76(%sp),%d7
        lsl.l #8,%d7
        moveq #0,%d0
        move.b 64+0x77(%sp),%d0
        or.l %d0,%d7
        move.l  %d7,%d0
        lsr.l   #8,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d7,%d1
        andi.l  #0xff,%d1
        move.l  #GK_PART_PAYLOAD_SIZE,%d6
        muls.l  %d6,%d1
        add.l   %d1,%d0
        cmp.l   36(%sp),%d0
        bne.w   gk_audio_upstream_fatal
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d0,%a0
        lea     GK_STOCK_AUDIO_PRIMARY_BANKS,%a1
        adda.l  %d5,%a1
        lea     GK_STOCK_AUDIO_PRIMARY_PARTS,%a2
        adda.l  %d5,%a2
        jsr     gk_audio_upstream_acquire_source
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_audio_primary_type_unavailable
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_audio_primary_type_unavailable
        tst.l   %d0
        bmi.w   gk_audio_upstream_fatal
        move.b  %d0,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        move.l  %a0,%d6
        move.l  36(%sp),%d1
        addi.l  #GK_STOCK_PHYSICAL_BASE,%d1
        sub.l   %d1,%d6
        move.l  %d6,28(%sp)
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_primary_type_read_active_stock
gk_audio_primary_type_read_active_stock:
        .incbin "stock/0215.bin", 0, 6
        adda.l  %d6,%a0
        mvs.b   (%a0,%d3.l),%d0
        suba.l  %d6,%a0
        jmp     GK_STOCK_AUDIO_PRIMARY_TYPE_READ_CONTINUE
.Lgk_audio_primary_type_unavailable:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .incbin "stock/0216.bin", 0, 6
        jmp     GK_STOCK_AUDIO_PRIMARY_TYPE_SKIP
.Lgk_audio_primary_type_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_primary_type_read_stock
gk_audio_primary_type_read_stock:
        .incbin "stock/0217.bin", 0, 6
        .incbin "stock/0217.bin", 6, 4
        .global gk_audio_primary_type_read_stock_end
gk_audio_primary_type_read_stock_end:
        jmp     GK_STOCK_AUDIO_PRIMARY_TYPE_READ_CONTINUE
        .size   gk_stock_audio_primary_type_read,.-gk_stock_audio_primary_type_read
        .align  2
        .global gk_stock_audio_primary_type_decision
        .type   gk_stock_audio_primary_type_decision,@function
gk_stock_audio_primary_type_decision:
        .global gk_audio_primary_type_decision_stock
gk_audio_primary_type_decision_stock:
        .incbin "stock/0218.bin", 0, 6
        .incbin "stock/0218.bin", 6, 6
        .global gk_audio_primary_type_decision_stock_end
gk_audio_primary_type_decision_stock_end:
        bra.w   .Lgk_audio_primary_type_equal
        .global gk_sequencer_latch_queue_handoff_refresh
        .type   gk_sequencer_latch_queue_handoff_refresh,@function
gk_sequencer_latch_queue_handoff_refresh:
        tst.b   __gk_sequencer_latch_queue_handoff
        beq.s   .Lgk_latch_queue_refresh_return
        tst.l   GK_STOCK_AUDIO_LATCH_TRIGGER
        bne.s   .Lgk_latch_queue_refresh_trigger_trampoline
        bsr.w   gk_sequencer_latch_begin
        bne.s   .Lgk_latch_queue_refresh_begin_trampoline
        move.b  GK_STOCK_ENGINE_PART,%d0
        bsr.w   gk_sequencer_latch_commit_part
        bne.s   .Lgk_latch_queue_refresh_commit_trampoline
        jsr     gk_pattern_queue_handoff_marker_retire
.Lgk_latch_queue_refresh_return:
        rts
.Lgk_latch_queue_refresh_trigger_trampoline:
        bra.s   gk_arranger_fatal_latch_trigger_pending
.Lgk_latch_queue_refresh_begin_trampoline:
        bra.s   gk_arranger_fatal_latch_begin
.Lgk_latch_queue_refresh_commit_trampoline:
        bra.s   gk_arranger_fatal_latch_commit
        .size   gk_sequencer_latch_queue_handoff_refresh,.-gk_sequencer_latch_queue_handoff_refresh
        .global gk_audio_primary_type_mismatch_stub
gk_audio_primary_type_mismatch_stub:
.Lgk_audio_primary_type_mismatch_stub:
        bra.w   .Lgk_audio_primary_type_mismatch
        .global gk_arranger_fatal_latch_trigger_pending
gk_arranger_fatal_latch_trigger_pending:
        illegal
        bra.s   gk_arranger_fatal_latch_trigger_pending
        .global gk_arranger_fatal_latch_begin
gk_arranger_fatal_latch_begin:
        illegal
        bra.s   gk_arranger_fatal_latch_begin
        .global gk_arranger_fatal_latch_commit
gk_arranger_fatal_latch_commit:
        illegal
        bra.s   gk_arranger_fatal_latch_commit
.Lgk_audio_primary_type_equal:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_primary_type_equal_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_primary_type_equal_restore
        bra.w   gk_audio_upstream_fatal
.Lgk_audio_primary_type_equal_active:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_upstream_fatal
.Lgk_audio_primary_type_equal_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_PRIMARY_TYPE_TRANSFER
.Lgk_audio_primary_type_mismatch:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_primary_type_mismatch_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_primary_type_mismatch_restore
        bra.w   gk_audio_upstream_fatal
.Lgk_audio_primary_type_mismatch_active:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_audio_primary_type_mismatch_restore
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_upstream_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_upstream_fatal
        move.b  #GK_ID_NONE,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_audio_primary_type_mismatch_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_PRIMARY_TYPE_SKIP
        .size   gk_stock_audio_primary_type_decision,.-gk_stock_audio_primary_type_decision
        .global gk_stock_audio_snapshot_type_read
        .type   gk_stock_audio_snapshot_type_read,@function
gk_stock_audio_snapshot_type_read:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_snapshot_type_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_audio_snapshot_type_stock_restore
        bra.w   gk_audio_upstream_fatal
.Lgk_audio_snapshot_type_active:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_audio_upstream_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SOURCE_KIND_SP(%sp),%d0
        cmpi.l  #GK_AUDIO_SOURCE_SNAPSHOT,%d0
        bne.w   gk_audio_upstream_fatal
        moveq   #0,%d3
        move.l  64 + 0x72(%sp),%d3
        cmpi.l  #6,%d3
        bhi.w   gk_audio_upstream_fatal
        cmpi.l  #3,%d3
        beq.w   gk_audio_upstream_fatal
        moveq   #0,%d2
        move.l  64 + 0x98(%sp),%d2
        cmpi.l  #7,%d2
        bhi.w   gk_audio_upstream_fatal
        move.l  %d3,%d0
        addq.l  #1,%d0
        cmp.l   %d0,%d2
        bne.w   gk_audio_upstream_fatal
        move.l  %d3,%d0
        lsl.l   #2,%d0
        cmp.l   64 + 0xb4(%sp),%d0
        bne.w   gk_audio_upstream_fatal
        moveq #0,%d7
        move.b 64+0x76(%sp),%d7
        lsl.l #8,%d7
        moveq #0,%d0
        move.b 64+0x77(%sp),%d0
        or.l %d0,%d7
        move.l  %d7,%d0
        lsr.l   #8,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d7,%d1
        andi.l  #0xff,%d1
        move.l  #GK_PART_PAYLOAD_SIZE,%d5
        muls.l  %d5,%d1
        add.l   %d1,%d0
        addi.l  #GK_STOCK_PHYSICAL_PART_BASE,%d0
        cmp.l   36(%sp),%d0
        bne.w   gk_audio_upstream_fatal
        move.l  %d3,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d3,%d0
        lsl.l   #2,%d0
        lea     GK_STOCK_AUDIO_SNAPSHOT_RECORDS,%a1
        adda.l  %d0,%a1
        lea     1(%a1),%a2
        jsr     gk_audio_upstream_acquire_source
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_audio_snapshot_type_unavailable
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_audio_snapshot_type_unavailable
        tst.l   %d0
        bmi.w   gk_audio_upstream_fatal
        move.b  %d0,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        lea     GK_PART_MACHINE_SELECTOR_OFFSET(%a0),%a0
        suba.l  36(%sp),%a0
        move.l  %a0,8(%sp)
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_snapshot_type_read_active_stock
gk_audio_snapshot_type_read_active_stock:
        movea.l 0x98(%sp),%a1
        adda.l  %d1,%a0
        mvs.b   (%a0,%a1.l),%d0
        suba.l  %d1,%a0
        jmp     GK_STOCK_AUDIO_SNAPSHOT_TYPE_READ_CONTINUE
.Lgk_audio_snapshot_type_unavailable:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        movea.l 0x98(%sp),%a1
        jmp     GK_STOCK_AUDIO_SNAPSHOT_TYPE_SKIP
.Lgk_audio_snapshot_type_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_snapshot_type_read_stock
gk_audio_snapshot_type_read_stock:
        .incbin "stock/0219.bin", 0, 4
        .incbin "stock/0219.bin", 4, 4
        .global gk_audio_snapshot_type_read_stock_end
gk_audio_snapshot_type_read_stock_end:
        jmp     GK_STOCK_AUDIO_SNAPSHOT_TYPE_READ_CONTINUE
        .size   gk_stock_audio_snapshot_type_read,.-gk_stock_audio_snapshot_type_read
        .align  2
        .global gk_stock_audio_snapshot_type_decision
        .type   gk_stock_audio_snapshot_type_decision,@function
gk_stock_audio_snapshot_type_decision:
        .global gk_audio_snapshot_type_decision_stock
gk_audio_snapshot_type_decision_stock:
        .incbin "stock/0220.bin", 0, 8
        .incbin "stock/0220.bin", 8, 6
        .global gk_audio_snapshot_type_decision_stock_end
gk_audio_snapshot_type_decision_stock_end:
        bra.w   .Lgk_audio_snapshot_type_equal
        .global gk_sequencer_latch_queue_commit_deferred
        .type   gk_sequencer_latch_queue_commit_deferred,@function
gk_sequencer_latch_queue_commit_deferred:
        cmpi.l  #GK_ERR_BUSY,%d0
        bne.w   gk_sequencer_latch_commit_fatal
        tst.b   __gk_sequencer_latch_queue_handoff
        beq.w   gk_sequencer_latch_commit_fatal
        bra.w   gk_stock_sequencer_latch_commit_stock_only
        .size   gk_sequencer_latch_queue_commit_deferred,.-gk_sequencer_latch_queue_commit_deferred
        nop
        nop
        nop
        nop
        nop
        nop
        .global gk_audio_snapshot_type_mismatch_stub
gk_audio_snapshot_type_mismatch_stub:
.Lgk_audio_snapshot_type_mismatch_stub:
        bra.w   .Lgk_audio_snapshot_type_mismatch
.Lgk_audio_snapshot_type_equal:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_snapshot_type_equal_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_snapshot_type_equal_restore
        bra.w   gk_audio_upstream_fatal
.Lgk_audio_snapshot_type_equal_active:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_upstream_fatal
.Lgk_audio_snapshot_type_equal_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_SNAPSHOT_TYPE_TRANSFER
.Lgk_audio_snapshot_type_mismatch:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_snapshot_type_mismatch_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_snapshot_type_mismatch_restore
        bra.w   gk_audio_upstream_fatal
.Lgk_audio_snapshot_type_mismatch_active:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_audio_snapshot_type_mismatch_restore
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_upstream_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_upstream_fatal
        move.b  #GK_ID_NONE,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_audio_snapshot_type_mismatch_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_SNAPSHOT_TYPE_SKIP
        .size   gk_stock_audio_snapshot_type_decision,.-gk_stock_audio_snapshot_type_decision
        .global gk_audio_upstream_fatal
        .type   gk_audio_upstream_fatal,@function
gk_audio_upstream_fatal:
        illegal
        .size   gk_audio_upstream_fatal,.-gk_audio_upstream_fatal
