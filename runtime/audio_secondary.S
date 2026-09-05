        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_audio_secondary_resolve_delta
        .type   gk_audio_secondary_resolve_delta,@function
gk_audio_secondary_resolve_delta:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_audio_secondary_delta_range
        move.l  %d4,-(%sp)
        move.l  %d0,%d3
        move.l  %d1,%d2
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        move.l %d3,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a1
        adda.l %d1,%a1
        moveq   #0,%d1
        move.b  GK_DESC_FLAGS(%a1),%d1
        andi.l  #0x80,%d1
        bne.w   .Lgk_audio_secondary_delta_corrupt
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_audio_secondary_delta_corrupt
        cmpa.l  GK_DESC_PAYLOAD(%a1),%a0
        bne.w   .Lgk_audio_secondary_delta_corrupt
        tst.l   %a0
        beq.w   .Lgk_audio_secondary_delta_corrupt
        tst.w   GK_DESC_ROOTS(%a1)
        beq.w   .Lgk_audio_secondary_delta_corrupt
        tst.w   GK_DESC_READERS(%a1)
        beq.w   .Lgk_audio_secondary_delta_corrupt
        move.l  %d2,%d0
        lsr.l   #8,%d0
        andi.l  #0xff,%d0
        cmpi.l  #GK_BANK_COUNT - 1,%d0
        bhi.w   .Lgk_audio_secondary_delta_corrupt
        move.l  %d2,%d3
        andi.l  #0xff,%d3
        cmpi.l  #GK_PARTS_PER_BANK - 1,%d3
        bhi.w   .Lgk_audio_secondary_delta_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_PHYSICAL(%a1),%d1
        cmpi.l  #GK_ID_NONE,%d1
        beq.s   .Lgk_audio_secondary_delta_spilled
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_audio_secondary_delta_corrupt
        btst    #2,GK_DESC_FLAGS(%a1)
        bne.w   .Lgk_audio_secondary_delta_corrupt
        move.l  %d0,%d2
        lsl.l   #2,%d2
        add.l   %d3,%d2
        cmp.l   %d2,%d1
        bne.w   .Lgk_audio_secondary_delta_corrupt
        bra.s   .Lgk_audio_secondary_delta_address
.Lgk_audio_secondary_delta_spilled:
        btst    #2,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_audio_secondary_delta_corrupt
.Lgk_audio_secondary_delta_address:
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  #GK_PART_PAYLOAD_SIZE,%d1
        muls.l  %d1,%d3
        add.l   %d3,%d0
        lea     GK_STOCK_PHYSICAL_BASE,%a1
        adda.l  %d0,%a1
        suba.l  %a1,%a0
        moveq   #GK_OK,%d0
        bra.s   .Lgk_audio_secondary_delta_restore
.Lgk_audio_secondary_delta_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_audio_secondary_delta_restore:
        move.w  %d4,%sr
        move.l  (%sp)+,%d4
        rts
.Lgk_audio_secondary_delta_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_audio_secondary_resolve_delta,.-gk_audio_secondary_resolve_delta
        .global gk_audio_secondary_publish_coherence
        .type   gk_audio_secondary_publish_coherence,@function
gk_audio_secondary_publish_coherence:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_audio_secondary_coherence_range
        cmpi.l  #GK_COHERENCE_COUNT - 1,%d1
        bhi.w   .Lgk_audio_secondary_coherence_range
        lea     -16(%sp),%sp
        movem.l %d2-%d4/%a1,(%sp)
        move.l  %d0,%d3
        move.l  %d1,%d2
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a1),%d0
        andi.l  #0x80,%d0
        bne.s   .Lgk_audio_secondary_coherence_corrupt
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_audio_secondary_coherence_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.s   .Lgk_audio_secondary_coherence_corrupt
        tst.w   GK_DESC_ROOTS(%a1)
        beq.s   .Lgk_audio_secondary_coherence_corrupt
        tst.w   GK_DESC_READERS(%a1)
        beq.s   .Lgk_audio_secondary_coherence_corrupt
        lea     __gk_coherence_sidecars,%a1
        .global gk_audio_secondary_coherence_publication
gk_audio_secondary_coherence_publication:
        move.b  %d3,(%a1,%d2.l)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_audio_secondary_coherence_restore
.Lgk_audio_secondary_coherence_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_audio_secondary_coherence_restore:
        move.w  %d4,%sr
        movem.l (%sp),%d2-%d4/%a1
        lea     16(%sp),%sp
        rts
.Lgk_audio_secondary_coherence_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_audio_secondary_publish_coherence,.-gk_audio_secondary_publish_coherence
        .global gk_stock_audio_secondary_begin
        .type   gk_stock_audio_secondary_begin,@function
gk_stock_audio_secondary_begin:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_secondary_begin_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_secondary_begin_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_begin_active:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_audio_secondary_fatal
        move.b  #GK_ID_NONE,64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp)
        clr.b   64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
.Lgk_audio_secondary_begin_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_secondary_begin_stock
gk_audio_secondary_begin_stock:
        .incbin "stock/0209.bin", 0, 6
        .global gk_audio_secondary_begin_stock_end
gk_audio_secondary_begin_stock_end:
        jmp     GK_STOCK_AUDIO_SECONDARY_BEGIN_CONTINUE
        .size   gk_stock_audio_secondary_begin,.-gk_stock_audio_secondary_begin
        .global gk_stock_audio_secondary_acquire
        .type   gk_stock_audio_secondary_acquire,@function
gk_stock_audio_secondary_acquire:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_secondary_acquire_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_audio_secondary_acquire_stock_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_acquire_active:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_audio_secondary_fatal
        tst.b   64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
        bne.w   gk_audio_secondary_fatal
        cmpi.l  #GK_COHERENCE_COUNT - 1,%d4
        bhi.w   gk_audio_secondary_fatal
        move.l  %d6,%d3
        tst.l   %d3
        beq.s   .Lgk_audio_secondary_acquire_queue
        cmpi.l  #1,%d3
        bne.w   gk_audio_secondary_fatal
        moveq   #0,%d7
        move.w  %a2,%d7
        andi.l  #0xff,%d7
        lsl.l   #8,%d7
        moveq   #0,%d0
        move.b  %d2,%d0
        or.l    %d0,%d7
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        lea     GK_STOCK_ENGINE_BANK,%a1
        lea     GK_STOCK_ENGINE_PART,%a2
        bra.s   .Lgk_audio_secondary_acquire_call
.Lgk_audio_secondary_acquire_queue:
        cmpi.l  #2,%d5
        bhi.w   gk_audio_secondary_fatal
        moveq   #0,%d7
        move.w  %a2,%d7
        andi.l  #0xff,%d7
        lsl.l   #8,%d7
        moveq   #0,%d0
        move.b  %d2,%d0
        or.l    %d0,%d7
        move.l  %d5,%d0
        lsl.l   #3,%d0
        add.l   %d4,%d0
        cmpi.l  #GK_SIDECAR_AUDIO_SECONDARY_COUNT - 1,%d0
        bhi.w   gk_audio_secondary_fatal
        move.l  %d0,%d1
        lsl.l   #1,%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SECONDARY_OFFSET,%a0
        adda.l  %d1,%a0
        lea     GK_STOCK_AUDIO_SECONDARY_BANKS,%a1
        adda.l  %d0,%a1
        lea     GK_STOCK_AUDIO_SECONDARY_PARTS,%a2
        adda.l  %d0,%a2
.Lgk_audio_secondary_acquire_call:
        jsr     gk_selector_acquire_pair
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.w   .Lgk_audio_secondary_acquire_stock_restore
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.w   .Lgk_audio_secondary_acquire_stock_restore
        tst.l   %d0
        bmi.w   gk_audio_secondary_fatal
        move.l  %d0,%d6
        cmp.l   %d1,%d7
        bne.s   .Lgk_audio_secondary_acquire_pair_mismatch
        move.l  %d6,%d0
        jsr     gk_audio_secondary_resolve_delta
        tst.l   %d0
        bne.s   .Lgk_audio_secondary_acquire_release_fatal
        move.b  %d6,64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp)
        move.l  %a0,60(%sp)
        bra.s   .Lgk_audio_secondary_acquire_stock_restore
.Lgk_audio_secondary_acquire_pair_mismatch:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_secondary_fatal
        tst.l   %d3
        bne.s   .Lgk_audio_secondary_acquire_stock_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_acquire_release_fatal:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_secondary_fatal
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_acquire_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_secondary_acquire_stock
gk_audio_secondary_acquire_stock:
        .incbin "stock/0210.bin", 0, 2
        .incbin "stock/0210.bin", 2, 6
        .global gk_audio_secondary_acquire_stock_end
gk_audio_secondary_acquire_stock_end:
        jmp     GK_STOCK_AUDIO_SECONDARY_ACQUIRE_CONTINUE
        .size   gk_stock_audio_secondary_acquire,.-gk_stock_audio_secondary_acquire
        .global gk_stock_audio_secondary_cache_compare
        .type   gk_stock_audio_secondary_cache_compare,@function
gk_stock_audio_secondary_cache_compare:
        .global gk_audio_secondary_cache_compare_stock
gk_audio_secondary_cache_compare_stock:
        .incbin "stock/0211.bin", 0, 8
        .incbin "stock/0211.bin", 8, 8
        .global gk_audio_secondary_cache_compare_stock_end
gk_audio_secondary_cache_compare_stock_end:
.Lgk_audio_secondary_cache_mismatch_stub:
        bra.s   .Lgk_audio_secondary_cache_mismatch
        .global gk_sequencer_latch_queue_handoff_validate
        .type   gk_sequencer_latch_queue_handoff_validate,@function
gk_sequencer_latch_queue_handoff_validate:
        move.w  GK_STOCK_SEQUENCER_CURRENT_BANK,%d2
        move.l  %d2,%d0
        andi.l  #0xf0f0,%d0
        bne.s   .Lgk_latch_queue_handoff_corrupt
        moveq   #1,%d0
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.s   .Lgk_latch_queue_handoff_corrupt
        tst.b   __gk_sequencer_latch_queue_handoff
        bne.s   .Lgk_latch_queue_handoff_repeat
        lsl.l   #8,%d5
        or.l    %d4,%d5
        cmp.w   GK_STOCK_SEQUENCER_PREVIOUS_PATTERN,%d5
        bne.s   .Lgk_latch_queue_handoff_corrupt
        jsr     gk_pattern_queue_handoff_marker_publish
.Lgk_latch_queue_handoff_ok:
        moveq   #GK_OK,%d0
        bra.w   gk_sequencer_latch_begin_release_status
.Lgk_latch_queue_handoff_repeat:
        bsr.w   gk_sequencer_latch_queue_handoff_repeat_validate
        beq.s   .Lgk_latch_queue_handoff_ok
.Lgk_latch_queue_handoff_corrupt:
        bra.w   gk_sequencer_latch_begin_release_corrupt
        .size   gk_sequencer_latch_queue_handoff_validate,.-gk_sequencer_latch_queue_handoff_validate
        .global gk_audio_secondary_cache_equal_stub
gk_audio_secondary_cache_equal_stub:
.Lgk_audio_secondary_cache_equal_stub:
        bra.s   .Lgk_audio_secondary_cache_equal
.Lgk_audio_secondary_cache_mismatch:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_secondary_cache_mismatch_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_audio_secondary_cache_copy_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_cache_mismatch_active:
        tst.b   64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
        bne.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.w   .Lgk_audio_secondary_cache_unavailable_restore
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_secondary_fatal
        move.b  #GK_AUDIO_SECONDARY_COPY_MARKER,64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
.Lgk_audio_secondary_cache_copy_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_SECONDARY_COPY_PATH
.Lgk_audio_secondary_cache_equal:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_secondary_cache_equal_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_audio_secondary_cache_skip_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_cache_equal_active:
        tst.b   64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
        bne.w   gk_audio_secondary_fatal
        cmpi.l  #GK_COHERENCE_COUNT - 1,%d4
        bhi.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_audio_secondary_cache_skip_restore
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_secondary_fatal
        lea     __gk_coherence_sidecars,%a0
        moveq   #0,%d1
        move.b  (%a0,%d4.l),%d1
        cmp.l   %d0,%d1
        beq.s   .Lgk_audio_secondary_cache_skip_restore
        move.b  #GK_AUDIO_SECONDARY_COPY_MARKER,64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
        bra.s   .Lgk_audio_secondary_cache_copy_restore
.Lgk_audio_secondary_cache_skip_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_SECONDARY_NO_COPY
.Lgk_audio_secondary_cache_unavailable_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_SECONDARY_RELEASE
        .size   gk_stock_audio_secondary_cache_compare,.-gk_stock_audio_secondary_cache_compare
        .global gk_stock_audio_secondary_source
        .type   gk_stock_audio_secondary_source,@function
gk_stock_audio_secondary_source:
        .global gk_audio_secondary_source_stock
gk_audio_secondary_source_stock:
        .incbin "stock/0212.bin", 0, 6
        .global gk_audio_secondary_source_stock_end
gk_audio_secondary_source_stock_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_secondary_source_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_secondary_source_stock_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_source_active:
        cmpi.l  #GK_COHERENCE_COUNT - 1,%d4
        bhi.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + 4 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + 4 + GK_AUDIO_SOURCE_KIND_SP(%sp),%d0
        cmpi.l  #GK_AUDIO_SECONDARY_COPY_MARKER,%d0
        bne.w   gk_audio_secondary_fatal
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        lea -4(%sp),%sp
        movem.l %d1,(%sp)
        move.w %sr,%d1
        add.l %a6,%d0
        move.w %d1,%ccr
        movem.l (%sp),%d1
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_SECONDARY_SOURCE_CONTINUE
.Lgk_audio_secondary_source_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_SECONDARY_SOURCE_CONTINUE
        .size   gk_stock_audio_secondary_source,.-gk_stock_audio_secondary_source
        .global gk_stock_audio_secondary_copy
        .type   gk_stock_audio_secondary_copy,@function
gk_stock_audio_secondary_copy:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_secondary_copy_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_secondary_copy_stock_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_copy_active:
        cmpi.l  #GK_COHERENCE_COUNT - 1,%d4
        bhi.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + 12 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + 12 + GK_AUDIO_SOURCE_KIND_SP(%sp),%d0
        cmpi.l  #GK_AUDIO_SECONDARY_COPY_MARKER,%d0
        bne.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_copy_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_secondary_copy_stock
gk_audio_secondary_copy_stock:
        .incbin "stock/0213.bin", 0, 6
        .global gk_audio_secondary_copy_stock_end
gk_audio_secondary_copy_stock_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_secondary_copy_publish
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_secondary_copy_return_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_copy_publish:
        cmpi.l  #GK_COHERENCE_COUNT - 1,%d4
        bhi.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + 12 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_secondary_fatal
        moveq   #0,%d1
        move.b  64 + 12 + GK_AUDIO_SOURCE_KIND_SP(%sp),%d1
        cmpi.l  #GK_AUDIO_SECONDARY_COPY_MARKER,%d1
        bne.w   gk_audio_secondary_fatal
        move.l  %d4,%d1
        jsr     gk_audio_secondary_publish_coherence
        tst.l   %d0
        bne.w   gk_audio_secondary_fatal
        clr.b   64 + 12 + GK_AUDIO_SOURCE_KIND_SP(%sp)
.Lgk_audio_secondary_copy_return_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_SECONDARY_COPY_RETURN
        .size   gk_stock_audio_secondary_copy,.-gk_stock_audio_secondary_copy
        .global gk_stock_audio_secondary_release
        .type   gk_stock_audio_secondary_release,@function
gk_stock_audio_secondary_release:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_secondary_release_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_secondary_release_restore
        bra.w   gk_audio_secondary_fatal
.Lgk_audio_secondary_release_active:
        tst.b   64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
        bne.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_audio_secondary_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_audio_secondary_release_restore
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_secondary_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_secondary_fatal
        move.b  #GK_ID_NONE,64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp)
.Lgk_audio_secondary_release_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_secondary_release_stock
gk_audio_secondary_release_stock:
        .incbin "stock/0214.bin", 0, 2
        .incbin "stock/0214.bin", 2, 4
        .global gk_audio_secondary_release_stock_end
gk_audio_secondary_release_stock_end:
        jmp     GK_STOCK_AUDIO_SECONDARY_RELEASE_CONTINUE
        .size   gk_stock_audio_secondary_release,.-gk_stock_audio_secondary_release
        .global gk_audio_secondary_fatal
        .type   gk_audio_secondary_fatal,@function
gk_audio_secondary_fatal:
        illegal
        .size   gk_audio_secondary_fatal,.-gk_audio_secondary_fatal
