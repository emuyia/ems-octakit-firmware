        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_audio_source_engine_current
        .type   gk_stock_audio_source_engine_current,@function
gk_stock_audio_source_engine_current:
        .incbin "stock/0026.bin", 0, 6
        .incbin "stock/0026.bin", 6, 4
        .incbin "stock/0026.bin", 10, 6
        .incbin "stock/0026.bin", 16, 4
        .global gk_audio_source_engine_stock_end
gk_audio_source_engine_stock_end:
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        move.b #GK_AUDIO_SOURCE_ENGINE_CURRENT,GK_AUDIO_SOURCE_KIND_SP+4(%sp)
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_SOURCE_ENGINE_CONTINUE
        .size   gk_stock_audio_source_engine_current,.-gk_stock_audio_source_engine_current
        .global gk_stock_audio_source_primary
        .type   gk_stock_audio_source_primary,@function
gk_stock_audio_source_primary:
        .incbin "stock/0027.bin", 0, 6
        .incbin "stock/0027.bin", 6, 4
        .incbin "stock/0027.bin", 10, 4
        .incbin "stock/0027.bin", 14, 4
        .incbin "stock/0027.bin", 18, 6
        .incbin "stock/0027.bin", 24, 4
        .incbin "stock/0027.bin", 28, 4
        .incbin "stock/0027.bin", 32, 4
        .global gk_audio_source_primary_stock_end
gk_audio_source_primary_stock_end:
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        move.b #GK_AUDIO_SOURCE_PRIMARY,GK_AUDIO_SOURCE_KIND_SP+4(%sp)
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_SOURCE_PRIMARY_CONTINUE
        .size   gk_stock_audio_source_primary,.-gk_stock_audio_source_primary
        .global gk_stock_audio_source_snapshot_chain
        .type   gk_stock_audio_source_snapshot_chain,@function
gk_stock_audio_source_snapshot_chain:
        .incbin "stock/0028.bin", 0, 6
        .incbin "stock/0028.bin", 6, 4
        .incbin "stock/0028.bin", 10, 4
        .incbin "stock/0028.bin", 14, 4
        .incbin "stock/0028.bin", 18, 4
        .incbin "stock/0028.bin", 22, 4
        .incbin "stock/0028.bin", 26, 4
        .global gk_audio_source_snapshot_chain_stock_end
gk_audio_source_snapshot_chain_stock_end:
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        move.b #GK_AUDIO_SOURCE_SNAPSHOT,GK_AUDIO_SOURCE_KIND_SP+4(%sp)
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_SOURCE_SNAPSHOT_CHAIN_CONTINUE
        .size   gk_stock_audio_source_snapshot_chain,.-gk_stock_audio_source_snapshot_chain
        .global gk_stock_audio_source_snapshot_consume
        .type   gk_stock_audio_source_snapshot_consume,@function
gk_stock_audio_source_snapshot_consume:
        .incbin "stock/0029.bin", 0, 6
        .incbin "stock/0029.bin", 6, 4
        .incbin "stock/0029.bin", 10, 4
        .incbin "stock/0029.bin", 14, 4
        .incbin "stock/0029.bin", 18, 4
        .incbin "stock/0029.bin", 22, 4
        .incbin "stock/0029.bin", 26, 4
        .global gk_audio_source_snapshot_consume_stock_end
gk_audio_source_snapshot_consume_stock_end:
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        move.b #GK_AUDIO_SOURCE_SNAPSHOT,GK_AUDIO_SOURCE_KIND_SP+4(%sp)
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_SOURCE_SNAPSHOT_CONSUME_CONTINUE
        .size   gk_stock_audio_source_snapshot_consume,.-gk_stock_audio_source_snapshot_consume
        .global gk_stock_audio_source_active
        .type   gk_stock_audio_source_active,@function
gk_stock_audio_source_active:
        .incbin "stock/0030.bin", 0, 6
        .incbin "stock/0030.bin", 6, 4
        .incbin "stock/0030.bin", 10, 4
        .incbin "stock/0030.bin", 14, 6
        .incbin "stock/0030.bin", 20, 4
        .incbin "stock/0030.bin", 24, 4
        .global gk_audio_source_active_stock_end
gk_audio_source_active_stock_end:
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        move.b #GK_AUDIO_SOURCE_ACTIVE,GK_AUDIO_SOURCE_KIND_SP+4(%sp)
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_SOURCE_ACTIVE_CONTINUE
        .size   gk_stock_audio_source_active,.-gk_stock_audio_source_active
        .global gk_stock_audio_selected_pair
        .type   gk_stock_audio_selected_pair,@function
gk_stock_audio_selected_pair:
        .incbin "stock/0031.bin", 0, 4
        .incbin "stock/0031.bin", 4, 4
        .incbin "stock/0031.bin", 8, 2
        .incbin "stock/0031.bin", 10, 2
        .incbin "stock/0031.bin", 12, 2
        .incbin "stock/0031.bin", 14, 2
.Lgk_audio_selected_compare_part:
        .incbin "stock/0031.bin", 16, 4
        .incbin "stock/0031.bin", 20, 4
        .incbin "stock/0031.bin", 24, 4
        .incbin "stock/0031.bin", 28, 2
        .incbin "stock/0031.bin", 30, 2
        .incbin "stock/0031.bin", 32, 2
        .incbin "stock/0031.bin", 34, 2
.Lgk_audio_selected_compare_done:
        .global gk_audio_selected_pair_stock_compare_end
gk_audio_selected_pair_stock_compare_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_audio_selected_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_audio_selected_stock_tail_restore
        bra.w   gk_audio_selected_fatal
.Lgk_audio_selected_active:
        move.b  #GK_ID_NONE,64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp)
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        cmpi.l  #7,%d5
        bhi.w   gk_audio_selected_fatal
        move.l  64 + 0xa4(%sp),%d0
        subi.l  #GK_STOCK_ENGINE_OBJECT_BASE,%d0
        cmp.l   %d5,%d0
        bne.w   gk_audio_selected_fatal
        moveq   #0,%d4
        move.b  64 + GK_AUDIO_SOURCE_KIND_SP(%sp),%d4
        cmpi.l  #GK_AUDIO_SOURCE_ENGINE_CURRENT,%d4
        beq.w   .Lgk_audio_selected_source_engine
        cmpi.l  #GK_AUDIO_SOURCE_PRIMARY,%d4
        beq.w   .Lgk_audio_selected_source_primary
        cmpi.l  #GK_AUDIO_SOURCE_SNAPSHOT,%d4
        beq.w   .Lgk_audio_selected_source_snapshot
        cmpi.l  #GK_AUDIO_SOURCE_ACTIVE,%d4
        beq.w   .Lgk_audio_selected_source_active
        bra.w   gk_audio_selected_fatal
.Lgk_audio_selected_source_engine:
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        lea     GK_STOCK_ENGINE_BANK,%a1
        lea     GK_STOCK_ENGINE_PART,%a2
        bra.w   .Lgk_audio_selected_acquire
.Lgk_audio_selected_source_primary:
        moveq   #0,%d4
        move.l  64 + 0x48(%sp),%d4
        cmpi.l  #GK_SIDECAR_AUDIO_PRIMARY_COUNT - 1,%d4
        bhi.w   gk_audio_selected_fatal
        move.l  %d4,%d0
        andi.l  #7,%d0
        cmp.l   %d5,%d0
        bne.w   gk_audio_selected_fatal
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d0,%a0
        lea     GK_STOCK_AUDIO_PRIMARY_BANKS,%a1
        adda.l  %d4,%a1
        lea     GK_STOCK_AUDIO_PRIMARY_PARTS,%a2
        adda.l  %d4,%a2
        bra.s   .Lgk_audio_selected_acquire
.Lgk_audio_selected_source_snapshot:
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d5,%d0
        lsl.l   #2,%d0
        lea     GK_STOCK_AUDIO_SNAPSHOT_RECORDS,%a1
        adda.l  %d0,%a1
        lea     1(%a1),%a2
        bra.s   .Lgk_audio_selected_acquire
.Lgk_audio_selected_source_active:
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_ACTIVE_OFFSET,%a0
        adda.l  %d0,%a0
        lea     GK_STOCK_AUDIO_ACTIVE_BANKS,%a1
        adda.l  %d5,%a1
        lea     GK_STOCK_AUDIO_ACTIVE_PARTS,%a2
        adda.l  %d5,%a2
.Lgk_audio_selected_acquire:
        jsr     gk_playback_outgoing_engine_acquire_pair
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.w   .Lgk_audio_selected_unavailable_restore
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.w   .Lgk_audio_selected_unavailable_restore
        tst.l   %d0
        bmi.w   gk_audio_selected_fatal
        move.l  %d0,%d6
        move.l  %d1,%d7
        movea.l %a0,%a6
        moveq   #0,%d2
        move.b  64 + 0x76(%sp),%d2
        lsl.l   #8,%d2
        moveq   #0,%d3
        move.b  64 + 0x77(%sp),%d3
        or.l    %d3,%d2
        cmp.l   %d2,%d7
        bne.w   .Lgk_audio_selected_release_fatal
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        adda.l  %d0,%a0
        lea     GK_STOCK_ENGINE_TRACK_BANKS,%a1
        adda.l  %d5,%a1
        lea     GK_STOCK_ENGINE_TRACK_PARTS,%a2
        adda.l  %d5,%a2
        move.l  %d6,%d0
        move.l  %d7,%d1
        jsr     gk_selector_publish_pair_pinned
        tst.l   %d0
        beq.s   .Lgk_audio_selected_published
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_audio_selected_release_unavailable
        bra.s   .Lgk_audio_selected_release_fatal
.Lgk_audio_selected_published:
        move.l  %d7,%d0
        lsr.l   #8,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d7,%d2
        andi.l  #0xff,%d2
        move.l  #GK_PART_PAYLOAD_SIZE,%d1
        muls.l  %d1,%d2
        add.l   %d2,%d0
        lea     GK_STOCK_PHYSICAL_BASE,%a1
        adda.l  %d0,%a1
        suba.l  %a1,%a6
        move.b  %d6,64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp)
        move.l  %a6,60(%sp)
        bra.s   .Lgk_audio_selected_stock_tail_restore
.Lgk_audio_selected_release_unavailable:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_selected_fatal
        bra.s   .Lgk_audio_selected_unavailable_restore
.Lgk_audio_selected_release_fatal:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_selected_fatal
        bra.w   gk_audio_selected_fatal
.Lgk_audio_selected_unavailable_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_SELECTED_UNAVAILABLE
.Lgk_audio_selected_stock_tail_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_selected_pair_stock_tail
gk_audio_selected_pair_stock_tail:
        .incbin "stock/0032.bin", 0, 4
        .incbin "stock/0032.bin", 4, 4
        .incbin "stock/0032.bin", 8, 4
        .incbin "stock/0032.bin", 12, 4
        .incbin "stock/0032.bin", 16, 4
        jmp     GK_STOCK_AUDIO_SELECTED_PAIR_CONTINUE
        .size   gk_stock_audio_selected_pair,.-gk_stock_audio_selected_pair
        .global gk_stock_audio_selected_release
        .type   gk_stock_audio_selected_release,@function
gk_stock_audio_selected_release:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_audio_selected_release_restore
        tst.l   %d0
        bne.w   gk_audio_selected_fatal
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_audio_selected_restore_engine
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_audio_selected_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_audio_selected_fatal
        move.b  #GK_ID_NONE,64 + GK_AUDIO_SELECTED_DESCRIPTOR_SP(%sp)
.Lgk_audio_selected_restore_engine:
        moveq   #0,%d0
        move.b  64 + GK_AUDIO_ENGINE_DESCRIPTOR_SP(%sp),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_audio_selected_release_restore
        jsr     gk_audio_current_resolve_delta
        tst.l   %d0
        bne.w   gk_audio_selected_fatal
        move.l  %a0,60(%sp)
.Lgk_audio_selected_release_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_selected_release_stock
gk_audio_selected_release_stock:
        .incbin "stock/0033.bin", 0, 4
        .incbin "stock/0033.bin", 4, 4
        jmp     GK_STOCK_AUDIO_SELECTED_RELEASE_CONTINUE
        .size   gk_stock_audio_selected_release,.-gk_stock_audio_selected_release
        .global gk_stock_audio_redirect_type
gk_stock_audio_redirect_type:
        .incbin "stock/0034.bin", 0, 6
        adda.l  %a6,%a0
        jmp     GK_STOCK_AUDIO_REDIRECT_TYPE_CONTINUE
        .global gk_stock_audio_redirect_mode
gk_stock_audio_redirect_mode:
        .incbin "stock/0035.bin", 0, 6
        adda.l  %a6,%a0
        jmp     GK_STOCK_AUDIO_REDIRECT_MODE_CONTINUE
        .global gk_stock_audio_redirect_scene_pair
gk_stock_audio_redirect_scene_pair:
        .incbin "stock/0036.bin", 0, 6
        adda.l  %a6,%a1
        adda.l  %a6,%a0
        jmp     GK_STOCK_AUDIO_REDIRECT_SCENE_PAIR_CONTINUE
        .global gk_stock_audio_redirect_full_header
gk_stock_audio_redirect_full_header:
        .incbin "stock/0037.bin", 0, 6
        adda.l  %a6,%a0
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        add.l %a6,%d4
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_REDIRECT_FULL_HEADER_CONTINUE
        .global gk_stock_audio_redirect_full_thirty
gk_stock_audio_redirect_full_thirty:
        .incbin "stock/0038.bin", 0, 6
        adda.l  %a6,%a2
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        add.l %a6,%d3
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_REDIRECT_FULL_THIRTY_CONTINUE
        .global gk_stock_audio_redirect_full_tail
gk_stock_audio_redirect_full_tail:
        .incbin "stock/0039.bin", 0, 6
        adda.l  %a6,%a1
        jmp     GK_STOCK_AUDIO_REDIRECT_FULL_TAIL_CONTINUE
        .global gk_stock_audio_redirect_scene_matrix
gk_stock_audio_redirect_scene_matrix:
        .incbin "stock/0040.bin", 0, 6
        adda.l  %a6,%a0
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        add.l %a6,%d1
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_REDIRECT_SCENE_MATRIX_CONTINUE
        .global gk_stock_audio_redirect_indexed_tail
gk_stock_audio_redirect_indexed_tail:
        .incbin "stock/0041.bin", 0, 6
        .incbin "stock/0041.bin", 6, 4
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        add.l %a6,%d5
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_REDIRECT_INDEXED_TAIL_CONTINUE
        .global gk_stock_audio_redirect_derived_first
gk_stock_audio_redirect_derived_first:
        .incbin "stock/0042.bin", 0, 6
        adda.l  %a6,%a3
        jmp     GK_STOCK_AUDIO_REDIRECT_DERIVED_FIRST_CONTINUE
        .global gk_stock_audio_redirect_derived_rest
gk_stock_audio_redirect_derived_rest:
        .incbin "stock/0043.bin", 0, 6
        adda.l  %a6,%a0
        suba.l  %a6,%a3
        adda.l  %a6,%a1
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        add.l %a6,%d2
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_REDIRECT_DERIVED_REST_CONTINUE
        .global gk_stock_audio_redirect_partial_header
gk_stock_audio_redirect_partial_header:
        .incbin "stock/0044.bin", 0, 6
        adda.l  %a6,%a0
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        add.l %a6,%d4
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_REDIRECT_PARTIAL_HEADER_CONTINUE
        .global gk_stock_audio_redirect_partial_thirty
gk_stock_audio_redirect_partial_thirty:
        .incbin "stock/0045.bin", 0, 6
        adda.l  %a6,%a2
        lea -4(%sp),%sp
        movem.l %d0,(%sp)
        move.w %sr,%d0
        add.l %a6,%d3
        move.w %d0,%ccr
        movem.l (%sp),%d0
        lea 4(%sp),%sp
        jmp     GK_STOCK_AUDIO_REDIRECT_PARTIAL_THIRTY_CONTINUE
        .global gk_stock_audio_redirect_partial_scene
gk_stock_audio_redirect_partial_scene:
        .incbin "stock/0046.bin", 0, 6
        adda.l  %a6,%a0
        jmp     GK_STOCK_AUDIO_REDIRECT_PARTIAL_SCENE_CONTINUE
        .global gk_stock_audio_redirect_late_type
gk_stock_audio_redirect_late_type:
        .incbin "stock/0047.bin", 0, 6
        adda.l  %a6,%a0
        jmp     GK_STOCK_AUDIO_REDIRECT_LATE_TYPE_CONTINUE
        .global gk_audio_selected_fatal
        .type   gk_audio_selected_fatal,@function
gk_audio_selected_fatal:
        illegal
        .size   gk_audio_selected_fatal,.-gk_audio_selected_fatal
