        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_playback_outgoing_engine_validate
        .type   gk_playback_outgoing_engine_validate,@function
gk_playback_outgoing_engine_validate:
        lea     -20(%sp),%sp
        movem.l %d1-%d3/%a0-%a1,(%sp)
        move.l  %d0,%d3
        tst.l   __gk_lifecycle_state
        bne.s   .Lgk_outgoing_engine_unavailable
        moveq   #0,%d1
        move.b  __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%d1
        cmp.l   %d3,%d1
        bne.s   .Lgk_outgoing_engine_unavailable
        move.b  __gk_workspace_descriptor,%d1
        cmp.l   %d3,%d1
        bne.s   .Lgk_outgoing_engine_unavailable
        moveq   #1,%d1
        cmp.b   __gk_sequencer_latch_queue_handoff,%d1
        bne.s   .Lgk_outgoing_engine_unavailable
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d1
        bne.s   .Lgk_outgoing_engine_unavailable
        moveq   #GK_PATTERN_QUEUE_PREPARED_BASE + 1,%d1
        cmp.b   __gk_pattern_queue_commit_prepared,%d1
        bne.s   .Lgk_outgoing_engine_unavailable
        moveq   #0,%d1
        move.b  __gk_pending_workspace_descriptor,%d1
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.s   .Lgk_outgoing_engine_unavailable
        cmp.b   __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET + 1,%d1
        bne.s   .Lgk_outgoing_engine_unavailable
        cmp.b   __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET + GK_SIDECAR_PENDING,%d1
        bne.s   .Lgk_outgoing_engine_unavailable
        moveq   #GK_OK,%d0
        bra.s   .Lgk_outgoing_engine_validate_restore
.Lgk_outgoing_engine_unavailable:
        moveq   #GK_ERR_UPDATING,%d0
.Lgk_outgoing_engine_validate_restore:
        movem.l (%sp),%d1-%d3/%a0-%a1
        lea     20(%sp),%sp
        rts
        .size   gk_playback_outgoing_engine_validate,.-gk_playback_outgoing_engine_validate
        .global gk_playback_outgoing_engine_acquire_pair
        .type   gk_playback_outgoing_engine_acquire_pair,@function
gk_playback_outgoing_engine_acquire_pair:
        jsr     gk_selector_acquire_pair
        cmpi.l  #GK_ERR_UPDATING,%d0
        bne.w   .Lgk_outgoing_engine_acquire_return
        cmpa.l  #__gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        bne.w   .Lgk_outgoing_engine_acquire_return
        lea     -20(%sp),%sp
        movem.l %d2-%d4/%a2,(%sp)
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        moveq   #0,%d2
        move.b  __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%d2
        move.l  %d2,%d0
        bsr.w   gk_playback_outgoing_engine_validate
        tst.l   %d0
        bne.s   .Lgk_outgoing_engine_acquire_restore
        jsr     gk_pattern_queue_audio_handoff_ready
        tst.l   %d0
        bmi.s   .Lgk_outgoing_engine_acquire_restore
        move.l  %d2,%d0
        lsl.l   #8,%d0
        ori.l   #GK_ID_NONE,%d0
        move.w  %d0,16(%sp)
        lea     16(%sp),%a0
        lea     GK_STOCK_ENGINE_BANK,%a1
        lea     GK_STOCK_ENGINE_PART,%a2
        jsr     gk_selector_acquire_pair
.Lgk_outgoing_engine_acquire_restore:
        move.w  %d4,%sr
        movem.l (%sp),%d2-%d4/%a2
        lea     20(%sp),%sp
.Lgk_outgoing_engine_acquire_return:
        rts
        .size   gk_playback_outgoing_engine_acquire_pair,.-gk_playback_outgoing_engine_acquire_pair
        .global gk_audio_current_resolve_delta
        .type   gk_audio_current_resolve_delta,@function
gk_audio_current_resolve_delta:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_audio_current_delta_range
        move.l  %d4,-(%sp)
        move.l  %d0,%d3
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        move.w  __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%d1
        cmpi.b  #GK_ID_NONE,%d1
        beq.s   .Lgk_audio_current_delta_selector_ready
        move.l  %d3,%d0
        bsr.w   gk_playback_outgoing_engine_validate
        tst.l   %d0
        bne.w   .Lgk_audio_current_delta_corrupt
.Lgk_audio_current_delta_selector_ready:
        lsr.l   #8,%d1
        andi.l  #0xff,%d1
        cmp.l   %d3,%d1
        bne.w   .Lgk_audio_current_delta_corrupt
        move.l %d3,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a1
        adda.l %d1,%a1
        moveq   #0,%d1
        move.b  GK_DESC_FLAGS(%a1),%d1
        andi.l  #0x80,%d1
        bne.w   .Lgk_audio_current_delta_corrupt
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_audio_current_delta_corrupt
        movea.l GK_DESC_PAYLOAD(%a1),%a0
        tst.l   %a0
        beq.w   .Lgk_audio_current_delta_corrupt
        tst.w   GK_DESC_ROOTS(%a1)
        beq.w   .Lgk_audio_current_delta_corrupt
        tst.w   GK_DESC_READERS(%a1)
        beq.w   .Lgk_audio_current_delta_corrupt
        moveq   #0,%d2
        move.b  GK_STOCK_ENGINE_BANK,%d2
        cmpi.l  #GK_BANK_COUNT - 1,%d2
        bhi.w   .Lgk_audio_current_delta_corrupt
        moveq   #0,%d3
        move.b  GK_STOCK_ENGINE_PART,%d3
        cmpi.l  #GK_PARTS_PER_BANK - 1,%d3
        bhi.w   .Lgk_audio_current_delta_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_PHYSICAL(%a1),%d1
        cmpi.l  #GK_ID_NONE,%d1
        beq.s   .Lgk_audio_current_delta_spilled
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_audio_current_delta_corrupt
        btst    #2,GK_DESC_FLAGS(%a1)
        bne.w   .Lgk_audio_current_delta_corrupt
        move.l  %d2,%d0
        lsl.l   #2,%d0
        add.l   %d3,%d0
        cmp.l   %d0,%d1
        bne.w   .Lgk_audio_current_delta_corrupt
        bra.s   .Lgk_audio_current_delta_address
.Lgk_audio_current_delta_spilled:
        btst    #2,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_audio_current_delta_corrupt
.Lgk_audio_current_delta_address:
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d2
        move.l  #GK_PART_PAYLOAD_SIZE,%d1
        muls.l  %d1,%d3
        add.l   %d3,%d2
        lea     GK_STOCK_PHYSICAL_BASE,%a1
        adda.l  %d2,%a1
        suba.l  %a1,%a0
        moveq   #GK_OK,%d0
        bra.s   .Lgk_audio_current_delta_restore
.Lgk_audio_current_delta_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_audio_current_delta_restore:
        move.w  %d4,%sr
        move.l  (%sp)+,%d4
        rts
.Lgk_audio_current_delta_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_audio_current_resolve_delta,.-gk_audio_current_resolve_delta
        .global gk_stock_audio_current_begin
        .type   gk_stock_audio_current_begin,@function
gk_stock_audio_current_begin:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_current_begin_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_audio_current_begin_stock_restore
        bra.w   gk_audio_current_fatal
.Lgk_audio_current_begin_active:
        move.b  #GK_ID_NONE,64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp)
        move.b  #GK_ID_NONE,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        lea     GK_STOCK_ENGINE_BANK,%a1
        lea     GK_STOCK_ENGINE_PART,%a2
        jsr     gk_playback_outgoing_engine_acquire_pair
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.w   .Lgk_audio_current_begin_unavailable
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.w   .Lgk_audio_current_begin_unavailable
        tst.l   %d0
        bmi.w   gk_audio_current_fatal
        move.l  %d0,%d6
        jsr     gk_audio_current_resolve_delta
        tst.l   %d0
        bne.s   .Lgk_audio_current_begin_release_fatal
        move.b  %d6,64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp)
        clr.b   64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
        move.l  %a0,60(%sp)
.Lgk_audio_current_begin_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_current_begin_stock
gk_audio_current_begin_stock:
        .incbin "stock/0232.bin", 0, 6
        .global gk_audio_current_begin_stock_end
gk_audio_current_begin_stock_end:
        jmp     GK_STOCK_AUDIO_CURRENT_BEGIN_CONTINUE
.Lgk_audio_current_begin_release_fatal:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_current_fatal
        bra.w   gk_audio_current_fatal
.Lgk_audio_current_begin_unavailable:
        move.b  #GK_AUDIO_CURRENT_SKIP_MARKER,64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_CURRENT_UNAVAILABLE
        .size   gk_stock_audio_current_begin,.-gk_stock_audio_current_begin
        .global gk_stock_audio_current_redirect_first
        .type   gk_stock_audio_current_redirect_first,@function
gk_stock_audio_current_redirect_first:
        .global gk_audio_current_redirect_first_stock
gk_audio_current_redirect_first_stock:
        .incbin "stock/0233.bin", 0, 6
        .global gk_audio_current_redirect_first_stock_end
gk_audio_current_redirect_first_stock_end:
        adda.l  %a6,%a0
        jmp     GK_STOCK_AUDIO_CURRENT_REDIRECT_FIRST_CONTINUE
        .size   gk_stock_audio_current_redirect_first,.-gk_stock_audio_current_redirect_first
        .global gk_stock_audio_current_redirect_second
        .type   gk_stock_audio_current_redirect_second,@function
gk_stock_audio_current_redirect_second:
        .global gk_audio_current_redirect_second_stock
gk_audio_current_redirect_second_stock:
        .incbin "stock/0234.bin", 0, 6
        .global gk_audio_current_redirect_second_stock_end
gk_audio_current_redirect_second_stock_end:
        adda.l  %a6,%a0
        jmp     GK_STOCK_AUDIO_CURRENT_REDIRECT_SECOND_CONTINUE
        .size   gk_stock_audio_current_redirect_second,.-gk_stock_audio_current_redirect_second
        .global gk_stock_audio_current_gate
        .type   gk_stock_audio_current_gate,@function
gk_stock_audio_current_gate:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_current_gate_stock_restore
        tst.l   %d0
        bne.w   gk_audio_current_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.s   .Lgk_audio_current_gate_stock_restore
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SOURCE_KIND_SP(%sp),%d0
        cmpi.l  #GK_AUDIO_CURRENT_SKIP_MARKER,%d0
        bne.w   gk_audio_current_fatal
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_CURRENT_SKIP_TAIL
.Lgk_audio_current_gate_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_current_gate_stock
gk_audio_current_gate_stock:
        .incbin "stock/0235.bin", 0, 6
        .global gk_audio_current_gate_stock_end
gk_audio_current_gate_stock_end:
        jmp     GK_STOCK_AUDIO_CURRENT_GATE_CONTINUE
        .size   gk_stock_audio_current_gate,.-gk_stock_audio_current_gate
        .global gk_stock_audio_current_redirect_track
        .type   gk_stock_audio_current_redirect_track,@function
gk_stock_audio_current_redirect_track:
        .global gk_audio_current_redirect_track_stock
gk_audio_current_redirect_track_stock:
        .incbin "stock/0236.bin", 0, 6
        .global gk_audio_current_redirect_track_stock_end
gk_audio_current_redirect_track_stock_end:
        adda.l  %a6,%a0
        jmp     GK_STOCK_AUDIO_CURRENT_REDIRECT_TRACK_CONTINUE
        .size   gk_stock_audio_current_redirect_track,.-gk_stock_audio_current_redirect_track
        .global gk_stock_audio_current_release
        .type   gk_stock_audio_current_release,@function
gk_stock_audio_current_release:
        .global gk_audio_current_release_stock_compare
gk_audio_current_release_stock_compare:
        cmp.l   0x72(%sp),%d5
        .global gk_audio_current_release_stock_compare_end
gk_audio_current_release_stock_compare_end:
        beq.s   .Lgk_audio_current_release_final
        jmp     GK_STOCK_AUDIO_CURRENT_TRACK_LOOP
.Lgk_audio_current_release_final:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_current_release_restore
        tst.l   %d0
        bne.w   gk_audio_current_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.s   .Lgk_audio_current_release_descriptor
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SOURCE_KIND_SP(%sp),%d0
        cmpi.l  #GK_AUDIO_CURRENT_SKIP_MARKER,%d0
        bne.w   gk_audio_current_fatal
        clr.b   64 + GK_AUDIO_SOURCE_KIND_SP(%sp)
        bra.s   .Lgk_audio_current_release_restore
.Lgk_audio_current_release_descriptor:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_current_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_current_fatal
        move.b  #GK_ID_NONE,64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp)
.Lgk_audio_current_release_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_CURRENT_RELEASE_CONTINUE
        .size   gk_stock_audio_current_release,.-gk_stock_audio_current_release
        .global gk_audio_current_fatal
        .type   gk_audio_current_fatal,@function
gk_audio_current_fatal:
        illegal
        .size   gk_audio_current_fatal,.-gk_audio_current_fatal
