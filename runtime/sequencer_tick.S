        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_selector_acquire_pair
        .type   gk_selector_acquire_pair,@function
gk_selector_acquire_pair:
        .incbin "stock/0221.bin", 0, 4
        .incbin "stock/0221.bin", 4, 4
        movea.l %a1,%a3
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        .global gk_selector_acquire_pair_snapshot
gk_selector_acquire_pair_snapshot:
        move.w  (%a0),%d0
        cmpi.b  #GK_ID_NONE,%d0
        bne.w   .Lgk_pair_acquire_updating
        lsr.l   #8,%d0
        andi.l  #0xff,%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.w   .Lgk_pair_acquire_invalid
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_pair_acquire_corrupt
        move.l %d0,%d2
        andi.l #0xff,%d2
        lsl.l #4,%d2
        lea __gk_descriptors,%a1
        adda.l %d2,%a1
        moveq   #0,%d2
        move.b  GK_DESC_FLAGS(%a1),%d2
        andi.l  #0x80,%d2
        bne.w   .Lgk_pair_acquire_corrupt
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_pair_acquire_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.w   .Lgk_pair_acquire_corrupt
        tst.w   GK_DESC_ROOTS(%a1)
        beq.w   .Lgk_pair_acquire_corrupt
        moveq   #0,%d2
        move.w  GK_DESC_READERS(%a1),%d2
        cmpi.l  #0xffff,%d2
        beq.w   .Lgk_pair_acquire_overflow
        moveq   #0,%d1
        .global gk_selector_acquire_pair_bank_snapshot
gk_selector_acquire_pair_bank_snapshot:
        move.b  (%a3),%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_pair_acquire_corrupt
        lsl.l   #8,%d1
        moveq   #0,%d3
        .global gk_selector_acquire_pair_part_snapshot
gk_selector_acquire_pair_part_snapshot:
        move.b  (%a2),%d3
        cmpi.l  #3,%d3
        bhi.w   .Lgk_pair_acquire_corrupt
        or.l    %d3,%d1
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a1),%d3
        cmpi.l  #GK_ID_NONE,%d3
        beq.s   .Lgk_pair_acquire_tuple_valid
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w   .Lgk_pair_acquire_corrupt
        move.l  %d1,%d2
        lsr.l   #8,%d2
        lsl.l   #2,%d2
        move.l  %d1,%d3
        andi.l  #0xff,%d3
        add.l   %d3,%d2
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a1),%d3
        cmp.l   %d2,%d3
        bne.w   .Lgk_pair_acquire_corrupt
.Lgk_pair_acquire_tuple_valid:
        moveq   #0,%d2
        move.w  GK_DESC_READERS(%a1),%d2
        addq.l  #1,%d2
        .global gk_selector_acquire_pair_reader_publication
gk_selector_acquire_pair_reader_publication:
        move.w  %d2,GK_DESC_READERS(%a1)
        movea.l GK_DESC_PAYLOAD(%a1),%a0
        bra.s   .Lgk_pair_acquire_restore
.Lgk_pair_acquire_invalid:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_pair_acquire_restore
.Lgk_pair_acquire_updating:
        moveq   #GK_ERR_UPDATING,%d0
        bra.s   .Lgk_pair_acquire_restore
.Lgk_pair_acquire_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
        bra.s   .Lgk_pair_acquire_restore
.Lgk_pair_acquire_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_pair_acquire_restore:
        move.w  %d4,%sr
        movem.l (%sp),%d2-%d4/%a2-%a3
        lea     20(%sp),%sp
        rts
        .size   gk_selector_acquire_pair,.-gk_selector_acquire_pair
        .global gk_selector_publish_pair_pinned
        .type   gk_selector_publish_pair_pinned,@function
gk_selector_publish_pair_pinned:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_pair_publish_range
        move.l  %d1,-(%sp)
        .incbin "stock/0222.bin", 0, 4
        .incbin "stock/0222.bin", 4, 4
        move.l  %d0,%d6
        move.l  36(%sp),%d7
        movea.l %a1,%a3
        movea.l %a2,%a4
        move.w  %sr,%d5
        move.w  #0x2700,%sr
        move.l  %d7,%d0
        lsr.l   #8,%d0
        andi.l  #0xff,%d0
        cmpi.l  #15,%d0
        bhi.w   .Lgk_pair_publish_range_masked
        move.l  %d7,%d1
        andi.l  #0xff,%d1
        cmpi.l  #3,%d1
        bhi.w   .Lgk_pair_publish_range_masked
        move.l %d6,%d2
        andi.l #0xff,%d2
        lsl.l #4,%d2
        lea __gk_descriptors,%a1
        adda.l %d2,%a1
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.w   .Lgk_pair_publish_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.w   .Lgk_pair_publish_corrupt
        tst.w   GK_DESC_ROOTS(%a1)
        beq.w   .Lgk_pair_publish_corrupt
        tst.w   GK_DESC_READERS(%a1)
        beq.w   .Lgk_pair_publish_corrupt
        moveq   #0,%d2
        move.b  GK_DESC_PHYSICAL(%a1),%d2
        cmpi.l  #GK_ID_NONE,%d2
        beq.s   .Lgk_pair_publish_new_valid
        move.l  %d0,%d3
        lsl.l   #2,%d3
        add.l   %d1,%d3
        cmp.l   %d2,%d3
        bne.w   .Lgk_pair_publish_corrupt
.Lgk_pair_publish_new_valid:
        moveq   #0,%d2
        move.b  GK_SIDECAR_PENDING(%a0),%d2
        cmpi.l  #GK_ID_NONE,%d2
        bne.w   .Lgk_pair_publish_busy
        moveq   #0,%d4
        move.b  GK_SIDECAR_CURRENT(%a0),%d4
        suba.l  %a2,%a2
        cmpi.l  #GK_ID_NONE,%d4
        beq.s   .Lgk_pair_publish_old_valid
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d4
        bhi.w   .Lgk_pair_publish_corrupt
        move.l %d4,%d2
        andi.l #0xff,%d2
        lsl.l #4,%d2
        lea __gk_descriptors,%a2
        adda.l %d2,%a2
        btst    #0,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_pair_publish_corrupt
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_pair_publish_corrupt
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_pair_publish_underflow
.Lgk_pair_publish_old_valid:
        moveq   #0,%d2
        cmp.l   %d6,%d4
        bne.s   .Lgk_pair_publish_generation_changed
        moveq   #0,%d3
        move.b  (%a3),%d3
        cmp.l   %d0,%d3
        bne.s   .Lgk_pair_publish_generation_changed
        moveq   #0,%d3
        move.b  (%a4),%d3
        cmp.l   %d1,%d3
        beq.s   .Lgk_pair_publish_change_known
.Lgk_pair_publish_generation_changed:
        moveq   #1,%d2
.Lgk_pair_publish_change_known:
        cmp.l   %d6,%d4
        beq.s   .Lgk_pair_publish_store
        moveq   #0,%d3
        move.w  GK_DESC_ROOTS(%a1),%d3
        cmpi.l  #0xffff,%d3
        beq.w   .Lgk_pair_publish_overflow
        addq.l  #1,%d3
        move.w  %d3,GK_DESC_ROOTS(%a1)
.Lgk_pair_publish_store:
        .global gk_selector_pair_bank_publication
gk_selector_pair_bank_publication:
        move.b  %d0,(%a3)
        .global gk_selector_pair_part_publication
gk_selector_pair_part_publication:
        move.b  %d1,(%a4)
        move.l  %d6,%d3
        lsl.l   #8,%d3
        ori.l   #0x00ff,%d3
        .global gk_selector_pair_stable_publication
gk_selector_pair_stable_publication:
        move.w  %d3,(%a0)
        cmpi.l  #GK_ID_NONE,%d4
        beq.s   .Lgk_pair_publish_success
        cmp.l   %d6,%d4
        beq.s   .Lgk_pair_publish_success
        moveq   #0,%d3
        move.w  GK_DESC_ROOTS(%a2),%d3
        subq.l  #1,%d3
        move.w  %d3,GK_DESC_ROOTS(%a2)
.Lgk_pair_publish_success:
        movea.l GK_DESC_PAYLOAD(%a1),%a0
        move.l  %d2,36(%sp)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pair_publish_restore
.Lgk_pair_publish_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_pair_publish_restore
.Lgk_pair_publish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_pair_publish_restore
.Lgk_pair_publish_underflow:
        moveq   #GK_ERR_UNDERFLOW,%d0
        bra.s   .Lgk_pair_publish_restore
.Lgk_pair_publish_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
        bra.s   .Lgk_pair_publish_restore
.Lgk_pair_publish_range_masked:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_pair_publish_restore:
        move.w  %d5,%sr
        .incbin "stock/0223.bin", 0, 4
        .incbin "stock/0223.bin", 4, 4
        move.l  (%sp)+,%d1
        rts
.Lgk_pair_publish_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_selector_publish_pair_pinned,.-gk_selector_publish_pair_pinned
        .global gk_stock_sequencer_tick_engine_snapshot
        .type   gk_stock_sequencer_tick_engine_snapshot,@function
gk_stock_sequencer_tick_engine_snapshot:
        move.w  #GK_ID_NONE,GK_TICK_RETURN_DESCRIPTOR_SP(%sp)
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_tick_engine_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_sequencer_tick_fatal
        .incbin "stock/0224.bin", 0, 6
        .incbin "stock/0224.bin", 6, 4
        .incbin "stock/0224.bin", 10, 6
        .incbin "stock/0224.bin", 16, 4
        jmp     GK_STOCK_SEQUENCER_TICK_ENGINE_CONTINUE
.Lgk_tick_engine_active:
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        lea     GK_STOCK_ENGINE_BANK,%a1
        lea     GK_STOCK_ENGINE_PART,%a2
        jsr     gk_selector_acquire_pair
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_tick_engine_unavailable
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_tick_engine_unavailable
        tst.l   %d0
        bmi.w   gk_sequencer_tick_fatal
        move.b  %d0,GK_TICK_ENGINE_DESCRIPTOR_SP(%sp)
        move.b  %d1,%d7
        move.b  %d7,129(%sp)
        lsr.l   #8,%d1
        move.b  %d1,%d6
        move.b  %d6,128(%sp)
        jmp     GK_STOCK_SEQUENCER_TICK_ENGINE_CONTINUE
.Lgk_tick_engine_unavailable:
        jmp     GK_STOCK_SEQUENCER_TICK_EPILOGUE
        .size   gk_stock_sequencer_tick_engine_snapshot,.-gk_stock_sequencer_tick_engine_snapshot
        .global gk_stock_sequencer_tick_track_source
        .type   gk_stock_sequencer_tick_track_source,@function
gk_stock_sequencer_tick_track_source:
        move.b  GK_TICK_ENGINE_DESCRIPTOR_SP(%sp),%d0
        move.b  %d0,GK_TICK_SELECTED_DESCRIPTOR_SP(%sp)
        cmpi.b  #GK_ID_NONE,%d0
        beq.s   .Lgk_tick_track_raw
        move.l  %d5,%d1
        lsl.l   #1,%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        adda.l  %d1,%a0
        moveq   #0,%d1
        move.b  GK_SIDECAR_PENDING(%a0),%d1
        cmpi.l  #GK_ID_NONE,%d1
        bne.w   .Lgk_tick_track_destination_busy
        move.b  #GK_TICK_SOURCE_ENGINE,GK_TICK_SOURCE_KIND_SP(%sp)
        bra.s   .Lgk_tick_track_continue
.Lgk_tick_track_raw:
        move.b  #GK_TICK_SOURCE_RAW,GK_TICK_SOURCE_KIND_SP(%sp)
.Lgk_tick_track_continue:
        .incbin "stock/0225.bin", 0, 6
        jmp     GK_STOCK_SEQUENCER_TICK_TRACK_CONTINUE
.Lgk_tick_track_destination_busy:
        jmp     GK_STOCK_SEQUENCER_TICK_TRACK_SKIP
        .size   gk_stock_sequencer_tick_track_source,.-gk_stock_sequencer_tick_track_source
        .global gk_stock_sequencer_tick_pending_snapshot
        .type   gk_stock_sequencer_tick_pending_snapshot,@function
gk_stock_sequencer_tick_pending_snapshot:
        move.b  GK_TICK_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.b  #GK_ID_NONE,%d0
        beq.w   .Lgk_tick_pending_raw
        move.l  %d3,%d0
        add.l   %d5,%d0
        move.l  %d0,%d1
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_VOICE_PENDING_OFFSET,%a0
        adda.l  %d0,%a0
        movea.l 66(%sp),%a1
        adda.l  %d3,%a1
        movea.l 62(%sp),%a2
        adda.l  %d3,%a2
        jsr     gk_selector_acquire_pair
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_tick_pending_unavailable
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_tick_pending_unavailable
        tst.l   %d0
        bmi.w   gk_sequencer_tick_fatal
        move.b  %d0,GK_TICK_SELECTED_DESCRIPTOR_SP(%sp)
        movea.l %d5,%a0
        adda.l  %a0,%a0
        lea     __gk_lease_sidecars + GK_SIDECAR_VOICE_REPEAT_OFFSET,%a1
        adda.l  %a0,%a1
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a1),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_tick_pending_repeat_busy
        move.b  #GK_TICK_SOURCE_PENDING,GK_TICK_SOURCE_KIND_SP(%sp)
        move.l  %d1,%d0
        lsr.l   #8,%d0
        andi.l  #0xff,%d0
        movea.w %d0,%a6
        andi.l  #0xff,%d1
        movea.w %d1,%a3
        jmp     GK_STOCK_SEQUENCER_TICK_PENDING_CONTINUE
.Lgk_tick_pending_unavailable:
        jmp     GK_STOCK_SEQUENCER_TICK_TRACK_SKIP
.Lgk_tick_pending_repeat_busy:
        moveq   #0,%d0
        move.b  GK_TICK_SELECTED_DESCRIPTOR_SP(%sp),%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_sequencer_tick_fatal
        move.b  #GK_ID_NONE,GK_TICK_SELECTED_DESCRIPTOR_SP(%sp)
        move.b  #GK_TICK_SOURCE_RAW,GK_TICK_SOURCE_KIND_SP(%sp)
        jmp     GK_STOCK_SEQUENCER_TICK_TRACK_SKIP
.Lgk_tick_pending_raw:
        .incbin "stock/0226.bin", 0, 4
        .incbin "stock/0226.bin", 4, 4
        .incbin "stock/0226.bin", 8, 2
        .incbin "stock/0226.bin", 10, 4
        .incbin "stock/0226.bin", 14, 4
        .incbin "stock/0226.bin", 18, 2
        move.b  #GK_ID_NONE,GK_TICK_SELECTED_DESCRIPTOR_SP(%sp)
        move.b  #GK_TICK_SOURCE_RAW,GK_TICK_SOURCE_KIND_SP(%sp)
        jmp     GK_STOCK_SEQUENCER_TICK_PENDING_CONTINUE
        .size   gk_stock_sequencer_tick_pending_snapshot,.-gk_stock_sequencer_tick_pending_snapshot
        .global gk_stock_sequencer_tick_repeat_publish
        .type   gk_stock_sequencer_tick_repeat_publish,@function
gk_stock_sequencer_tick_repeat_publish:
        lea     GK_STOCK_VOICE_REPEAT_STATE,%a0
        move.l  %d2,(%a0,%d4.l)
        move.b  GK_TICK_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.b  #GK_ID_NONE,%d0
        beq.s   .Lgk_tick_repeat_publish_raw
        moveq   #0,%d1
        move.b  GK_TICK_SOURCE_KIND_SP(%sp),%d1
        cmpi.l  #GK_TICK_SOURCE_PENDING,%d1
        bne.w   gk_sequencer_tick_fatal
        move.l  %d5,%d1
        lsl.l   #1,%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_VOICE_REPEAT_OFFSET,%a0
        adda.l  %d1,%a0
        lea     GK_STOCK_VOICE_REPEAT_BANKS,%a1
        adda.l  %d5,%a1
        lea     GK_STOCK_VOICE_REPEAT_PARTS,%a2
        adda.l  %d5,%a2
        mvs.b   %a6,%d1
        lsl.l   #8,%d1
        moveq   #0,%d0
        move.b  GK_TICK_SELECTED_DESCRIPTOR_SP(%sp),%d0
        moveq   #0,%d2
        move.w  %a3,%d2
        andi.l  #0xff,%d2
        or.l    %d2,%d1
        jsr     gk_selector_publish_pair_pinned
        tst.l   %d0
        bne.w   gk_sequencer_tick_fatal
        jmp     GK_STOCK_SEQUENCER_TICK_REPEAT_PUBLISH_CONTINUE
.Lgk_tick_repeat_publish_raw:
        .incbin "stock/0227.bin", 0, 2
        .incbin "stock/0227.bin", 2, 6
        .incbin "stock/0227.bin", 8, 4
        .incbin "stock/0227.bin", 12, 6
        .incbin "stock/0227.bin", 18, 2
        .incbin "stock/0227.bin", 20, 4
        jmp     GK_STOCK_SEQUENCER_TICK_REPEAT_PUBLISH_CONTINUE
        .size   gk_stock_sequencer_tick_repeat_publish,.-gk_stock_sequencer_tick_repeat_publish
        .global gk_stock_sequencer_tick_repeat_snapshot
        .type   gk_stock_sequencer_tick_repeat_snapshot,@function
gk_stock_sequencer_tick_repeat_snapshot:
        move.b  GK_TICK_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.b  #GK_ID_NONE,%d0
        beq.s   .Lgk_tick_repeat_raw
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_VOICE_REPEAT_OFFSET,%a0
        adda.l  %d0,%a0
        lea     GK_STOCK_VOICE_REPEAT_BANKS,%a1
        adda.l  %d5,%a1
        lea     GK_STOCK_VOICE_REPEAT_PARTS,%a2
        adda.l  %d5,%a2
        jsr     gk_selector_acquire_pair
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_tick_repeat_unavailable
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_tick_repeat_unavailable
        tst.l   %d0
        bmi.w   gk_sequencer_tick_fatal
        move.b  %d0,GK_TICK_SELECTED_DESCRIPTOR_SP(%sp)
        move.b  #GK_TICK_SOURCE_REPEAT,GK_TICK_SOURCE_KIND_SP(%sp)
        move.l  %d1,%d0
        lsr.l   #8,%d0
        andi.l  #0xff,%d0
        movea.w %d0,%a6
        andi.l  #0xff,%d1
        movea.w %d1,%a3
        jmp     GK_STOCK_SEQUENCER_TICK_REPEAT_CONTINUE
.Lgk_tick_repeat_unavailable:
        jmp     GK_STOCK_SEQUENCER_TICK_TRACK_SKIP
.Lgk_tick_repeat_raw:
        .incbin "stock/0228.bin", 0, 6
        .incbin "stock/0228.bin", 6, 4
        .incbin "stock/0228.bin", 10, 2
        .incbin "stock/0228.bin", 12, 6
        .incbin "stock/0228.bin", 18, 4
        .incbin "stock/0228.bin", 22, 2
        move.b  #GK_ID_NONE,GK_TICK_SELECTED_DESCRIPTOR_SP(%sp)
        move.b  #GK_TICK_SOURCE_RAW,GK_TICK_SOURCE_KIND_SP(%sp)
        jmp     GK_STOCK_SEQUENCER_TICK_REPEAT_CONTINUE
        .size   gk_stock_sequencer_tick_repeat_snapshot,.-gk_stock_sequencer_tick_repeat_snapshot
        .global gk_stock_sequencer_tick_selected_publish
        .type   gk_stock_sequencer_tick_selected_publish,@function
gk_stock_sequencer_tick_selected_publish:
        move.b  GK_TICK_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.b  #GK_ID_NONE,%d0
        beq.w   .Lgk_tick_selected_raw
        moveq   #0,%d1
        move.b  GK_TICK_SOURCE_KIND_SP(%sp),%d1
        cmpi.l  #GK_TICK_SOURCE_RAW,%d1
        beq.w   gk_sequencer_tick_fatal
        move.l  %d5,%d1
        lsl.l   #1,%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        adda.l  %d1,%a0
        lea     GK_STOCK_SEQUENCER_TRACK_BANKS,%a1
        adda.l  %d5,%a1
        move.l  %a2,-(%sp)
        lea     GK_STOCK_SEQUENCER_TRACK_PARTS,%a2
        adda.l  %d5,%a2
        mvs.b   %a6,%d1
        lsl.l   #8,%d1
        moveq   #0,%d0
        move.b  4 + GK_TICK_SELECTED_DESCRIPTOR_SP(%sp),%d0
        moveq   #0,%d2
        move.w  %a3,%d2
        andi.l  #0xff,%d2
        or.l    %d2,%d1
        jsr     gk_selector_publish_pair_pinned
        movea.l (%sp)+,%a2
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_tick_selected_busy
        tst.l   %d0
        bne.w   gk_sequencer_tick_fatal
        move.l  %d1,%d0
        mvs.b   %a6,%d7
        mvs.b   %a3,%d6
        movea.l %a0,%a6
        jmp     GK_STOCK_SEQUENCER_TICK_SELECTED_CONTINUE
.Lgk_tick_selected_raw:
        moveq   #0,%d1
        move.b  GK_TICK_SOURCE_KIND_SP(%sp),%d1
        cmpi.l  #GK_TICK_SOURCE_RAW,%d1
        bne.w   gk_sequencer_tick_fatal
        .incbin "stock/0229.bin", 0, 2
        .incbin "stock/0229.bin", 2, 6
        .incbin "stock/0229.bin", 8, 4
        .incbin "stock/0229.bin", 12, 2
        .incbin "stock/0229.bin", 14, 2
        .incbin "stock/0229.bin", 16, 2
        .incbin "stock/0229.bin", 18, 2
        .incbin "stock/0229.bin", 20, 2
.Lgk_tick_raw_bank_same:
        .incbin "stock/0229.bin", 22, 4
        .incbin "stock/0229.bin", 26, 2
        .incbin "stock/0229.bin", 28, 2
        .incbin "stock/0229.bin", 30, 2
        .incbin "stock/0229.bin", 32, 2
        .incbin "stock/0229.bin", 34, 2
.Lgk_tick_raw_change_known:
        .incbin "stock/0229.bin", 36, 2
        .incbin "stock/0229.bin", 38, 4
        .incbin "stock/0229.bin", 42, 2
        .incbin "stock/0229.bin", 44, 4
        .incbin "stock/0229.bin", 48, 2
        .incbin "stock/0229.bin", 50, 2
        move.l  %d0,-(%sp)
        move.l  %d7,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d6,%d1
        move.l  #GK_PART_PAYLOAD_SIZE,%d2
        muls.l  %d2,%d1
        lea     GK_STOCK_PHYSICAL_BASE,%a6
        adda.l  %d0,%a6
        adda.l  %d1,%a6
        move.l  (%sp)+,%d0
        jmp     GK_STOCK_SEQUENCER_TICK_SELECTED_CONTINUE
.Lgk_tick_selected_busy:
        moveq   #0,%d1
        move.b  GK_TICK_SOURCE_KIND_SP(%sp),%d1
        cmpi.l  #GK_TICK_SOURCE_PENDING,%d1
        beq.s   .Lgk_tick_selected_busy_release
        cmpi.l  #GK_TICK_SOURCE_REPEAT,%d1
        beq.s   .Lgk_tick_selected_busy_release
        cmpi.l  #GK_TICK_SOURCE_ENGINE,%d1
        bne.w   gk_sequencer_tick_fatal
        bra.s   .Lgk_tick_selected_busy_skip
.Lgk_tick_selected_busy_release:
        moveq   #0,%d0
        move.b  GK_TICK_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.w   gk_sequencer_tick_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_sequencer_tick_fatal
.Lgk_tick_selected_busy_skip:
        move.b  #GK_ID_NONE,GK_TICK_SELECTED_DESCRIPTOR_SP(%sp)
        move.b  #GK_TICK_SOURCE_RAW,GK_TICK_SOURCE_KIND_SP(%sp)
        jmp     GK_STOCK_SEQUENCER_TICK_TRACK_SKIP
        .size   gk_stock_sequencer_tick_selected_publish,.-gk_stock_sequencer_tick_selected_publish
        .global gk_stock_sequencer_tick_selected_release
        .type   gk_stock_sequencer_tick_selected_release,@function
gk_stock_sequencer_tick_selected_release:
        moveq   #0,%d0
        move.b  GK_TICK_SOURCE_KIND_SP(%sp),%d0
        cmpi.l  #GK_TICK_SOURCE_PENDING,%d0
        beq.s   .Lgk_tick_release_selected
        cmpi.l  #GK_TICK_SOURCE_REPEAT,%d0
        bne.s   .Lgk_tick_release_stock
.Lgk_tick_release_selected:
        moveq   #0,%d0
        move.b  GK_TICK_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.w   gk_sequencer_tick_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_sequencer_tick_fatal
        move.b  #GK_ID_NONE,GK_TICK_SELECTED_DESCRIPTOR_SP(%sp)
.Lgk_tick_release_stock:
        .incbin "stock/0230.bin", 0, 4
        .incbin "stock/0230.bin", 4, 4
        jmp     GK_STOCK_SEQUENCER_TICK_RELEASE_CONTINUE
        .size   gk_stock_sequencer_tick_selected_release,.-gk_stock_sequencer_tick_selected_release
        .global gk_stock_sequencer_tick_return
        .type   gk_stock_sequencer_tick_return,@function
gk_stock_sequencer_tick_return:
        movea.w GK_TICK_RETURN_DESCRIPTOR_SP(%sp),%a2
        adda.l  %a2,%a2
        adda.l  %a2,%a2
        lea     gk_sequencer_tick_return_table,%a3
        movea.l (%a3,%a2.l),%a2
        jmp     (%a2)
        .global gk_sequencer_tick_return_active
gk_sequencer_tick_return_active:
        lea     -20(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        suba.l  %a0,%a0
        bcc.s   .Lgk_tick_return_c_known
        lea     1(%a0),%a0
.Lgk_tick_return_c_known:
        bvc.s   .Lgk_tick_return_v_known
        lea     2(%a0),%a0
.Lgk_tick_return_v_known:
        bne.s   .Lgk_tick_return_z_known
        lea     4(%a0),%a0
.Lgk_tick_return_z_known:
        bpl.s   .Lgk_tick_return_n_known
        lea     8(%a0),%a0
.Lgk_tick_return_n_known:
        move.w  %sr,%d2
        andi.l  #0x0000fff0,%d2
        move.l  %a0,%d4
        or.l    %d4,%d2
        move.w  %d2,16(%sp)
        moveq   #0,%d0
        move.b  20 + GK_TICK_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_tick_return_restore
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_sequencer_tick_fatal
.Lgk_tick_return_restore:
        movem.l (%sp),%d0-%d1/%a0-%a1
        move.w  16(%sp),%d2
        move.w  %d2,%sr
        btst    #4,%d2
        beq.s   .Lgk_tick_return_x_clear
        moveq   #-1,%d3
        addq.l  #1,%d3
        bra.s   .Lgk_tick_return_x_known
.Lgk_tick_return_x_clear:
        moveq   #0,%d3
        add.l   %d3,%d3
.Lgk_tick_return_x_known:
        move.l  %d2,%d4
        andi.l  #0x0f,%d4
        beq.s   .Lgk_tick_return_ccr_0
        cmpi.l  #1,%d4
        beq.s   .Lgk_tick_return_ccr_1
        cmpi.l  #2,%d4
        beq.s   .Lgk_tick_return_ccr_2
        cmpi.l  #4,%d4
        beq.s   .Lgk_tick_return_ccr_4
        cmpi.l  #8,%d4
        beq.s   .Lgk_tick_return_ccr_8
        cmpi.l  #9,%d4
        beq.s   .Lgk_tick_return_ccr_9
        cmpi.l  #11,%d4
        beq.s   .Lgk_tick_return_ccr_11
        move.w  %d2,%ccr
        bra.s   .Lgk_tick_return_stock
.Lgk_tick_return_ccr_0:
        moveq   #1,%d3
        cmpi.b  #0,%d3
        bra.s   .Lgk_tick_return_stock
.Lgk_tick_return_ccr_1:
        moveq   #0,%d3
        cmpi.b  #-127,%d3
        bra.s   .Lgk_tick_return_stock
.Lgk_tick_return_ccr_2:
        moveq   #0,%d3
        move.b  #-128,%d3
        cmpi.b  #1,%d3
        bra.s   .Lgk_tick_return_stock
.Lgk_tick_return_ccr_4:
        moveq   #0,%d3
        cmpi.b  #0,%d3
        bra.s   .Lgk_tick_return_stock
.Lgk_tick_return_ccr_8:
        moveq   #0,%d3
        move.b  #-128,%d3
        cmpi.b  #0,%d3
        bra.s   .Lgk_tick_return_stock
.Lgk_tick_return_ccr_9:
        moveq   #0,%d3
        cmpi.b  #1,%d3
        bra.s   .Lgk_tick_return_stock
.Lgk_tick_return_ccr_11:
        moveq   #0,%d3
        cmpi.b  #-128,%d3
.Lgk_tick_return_stock:
        lea     20(%sp),%sp
        .global gk_sequencer_tick_return_stock_exact
gk_sequencer_tick_return_stock_exact:
        .incbin "stock/0231.bin", 0, 4
        .incbin "stock/0231.bin", 4, 4
        .incbin "stock/0231.bin", 8, 2
        .balign 4
        .global gk_sequencer_tick_return_table
gk_sequencer_tick_return_table:
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_return_active
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long gk_sequencer_tick_fatal
        .long   gk_sequencer_tick_return_stock_exact
        .global gk_sequencer_tick_return_table_end
gk_sequencer_tick_return_table_end:
        .size   gk_stock_sequencer_tick_return,.-gk_stock_sequencer_tick_return
        .global gk_sequencer_tick_fatal
gk_sequencer_tick_fatal:
        illegal
        bra.s   gk_sequencer_tick_fatal
