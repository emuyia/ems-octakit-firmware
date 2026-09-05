        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
.Lgk_audio_transfer_begin:
        jsr     gk_selector_acquire_pair
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_audio_transfer_begin_return
        cmpi.l  #GK_ERR_UPDATING,%d0
        beq.s   .Lgk_audio_transfer_begin_return
        tst.l   %d0
        bmi.s   .Lgk_audio_transfer_begin_return
        move.l  %d0,%d6
        cmp.l   %d1,%d7
        bne.s   .Lgk_audio_transfer_begin_mismatch
        movea.l %a3,%a0
        move.l  %d6,%d0
        jsr     gk_selector_begin_update
        tst.l   %d0
        beq.s   .Lgk_audio_transfer_begin_return
        move.l  %d0,%d5
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_audio_transfer_begin_return
        cmpi.l  #GK_ERR_BUSY,%d5
        bne.s   .Lgk_audio_transfer_begin_status
        moveq   #GK_ERR_UPDATING,%d0
        rts
.Lgk_audio_transfer_begin_status:
        move.l  %d5,%d0
.Lgk_audio_transfer_begin_return:
        rts
.Lgk_audio_transfer_begin_mismatch:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_audio_transfer_begin_return
        moveq   #GK_ERR_CORRUPT,%d0
        rts
.Lgk_audio_transfer_begin_pinned:
        move.l  %d6,%d0
        move.l  %d7,%d1
        jsr     gk_audio_upstream_validate_pinned
        tst.l   %d0
        bne.s   .Lgk_audio_transfer_begin_pinned_return
        movea.l %a3,%a0
        move.l  %d6,%d0
        jsr     gk_selector_begin_update
        tst.l   %d0
        beq.s   .Lgk_audio_transfer_begin_pinned_return
        move.l  %d0,%d5
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_audio_transfer_begin_pinned_return
        cmpi.l  #GK_ERR_BUSY,%d5
        bne.s   .Lgk_audio_transfer_begin_pinned_status
        moveq   #GK_ERR_UPDATING,%d0
        rts
.Lgk_audio_transfer_begin_pinned_status:
        move.l  %d5,%d0
.Lgk_audio_transfer_begin_pinned_return:
        rts
.Lgk_audio_transfer_finish:
        jsr     gk_selector_commit_update
        tst.l   %d0
        bne.s   .Lgk_audio_transfer_finish_return
        move.l  %d6,%d0
        jsr     gk_descriptor_release
.Lgk_audio_transfer_finish_return:
        rts
        .global gk_stock_audio_transfer_current_adjacent
        .type   gk_stock_audio_transfer_current_adjacent,@function
gk_stock_audio_transfer_current_adjacent:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_current_adjacent_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_current_adjacent_stock_restore
        bra.w   gk_audio_transfer_fatal
.Lgk_current_adjacent_active:
        move.b  #GK_ID_NONE,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        cmpi.l  #6,%d5
        bhi.w   gk_audio_transfer_fatal
        move.l  %d5,%d4
        addq.l  #1,%d4
        cmp.l   64 + 0x98(%sp),%d4
        bne.w   gk_audio_transfer_fatal
        move.l  %d5,%d0
        lsl.l   #2,%d0
        lea     GK_STOCK_AUDIO_SNAPSHOT_RECORDS,%a1
        adda.l  %d0,%a1
        cmpa.l  64 + 0xbc(%sp),%a1
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d2
        move.b  GK_STOCK_AUDIO_SNAPSHOT_VALIDITY,%d2
        bset    %d4,%d2
        moveq   #0,%d0
        move.b  7(%sp),%d0
        cmp.b   %d2,%d0
        bne.w   gk_audio_transfer_fatal
        moveq #0,%d7
        move.b 64+0x76(%sp),%d7
        lsl.l #8,%d7
        moveq #0,%d0
        move.b 64+0x77(%sp),%d0
        or.l %d0,%d7
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        lea     GK_STOCK_ENGINE_BANK,%a1
        lea     GK_STOCK_ENGINE_PART,%a2
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a3
        adda.l  %d0,%a3
        jsr .Lgk_audio_transfer_begin
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_ERR_INVALID,%d0
        beq.w .Lgk_current_adjacent_skip
        cmpi.l #GK_ERR_UPDATING,%d0
        beq.w .Lgk_current_adjacent_skip
        bra.w gk_audio_transfer_fatal
1:
        move.b %d6,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_current_adjacent_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_transfer_current_adjacent_stock
gk_audio_transfer_current_adjacent_stock:
        .incbin "stock/0048.bin", 0, 10
        .incbin "stock/0048.bin", 10, 10
        .incbin "stock/0048.bin", 20, 10
        .incbin "stock/0048.bin", 30, 10
        .incbin "stock/0048.bin", 40, 10
        .incbin "stock/0048.bin", 50, 8
        .global gk_audio_transfer_current_adjacent_stock_end
gk_audio_transfer_current_adjacent_stock_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_current_adjacent_continue_restore
        tst.l   %d0
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        addq.l  #1,%d5
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a0
        adda.l  %d0,%a0
        moveq #0,%d6
        move.b 64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d6
        cmpi.l #GK_DESCRIPTOR_COUNT-1,%d6
        bhi.w gk_audio_transfer_fatal
        jsr .Lgk_audio_transfer_finish
        tst.l %d0
        bne.w gk_audio_transfer_fatal
        move.b #GK_ID_NONE,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_current_adjacent_continue_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_CURRENT_ADJACENT_CONTINUE
.Lgk_current_adjacent_skip:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_CURRENT_ADJACENT_CONTINUE
        .size   gk_stock_audio_transfer_current_adjacent,.-gk_stock_audio_transfer_current_adjacent
        .global gk_stock_audio_transfer_current_special
        .type   gk_stock_audio_transfer_current_special,@function
gk_stock_audio_transfer_current_special:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_current_special_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_current_special_stock_restore
        bra.w   gk_audio_transfer_fatal
.Lgk_current_special_active:
        move.b  #GK_ID_NONE,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        cmpi.l  #7,%d5
        bhi.w   gk_audio_transfer_fatal
        moveq   #0,%d2
        move.b  GK_STOCK_AUDIO_SNAPSHOT_VALIDITY,%d2
        ori.l   #0x80,%d2
        moveq   #0,%d0
        move.b  7(%sp),%d0
        cmp.b   %d2,%d0
        bne.w   gk_audio_transfer_fatal
        moveq #0,%d7
        move.b 64+0x76(%sp),%d7
        lsl.l #8,%d7
        moveq #0,%d0
        move.b 64+0x77(%sp),%d0
        or.l %d0,%d7
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        lea     GK_STOCK_ENGINE_BANK,%a1
        lea     GK_STOCK_ENGINE_PART,%a2
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET + 14,%a3
        jsr .Lgk_audio_transfer_begin
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_ERR_INVALID,%d0
        beq.w .Lgk_current_special_skip
        cmpi.l #GK_ERR_UPDATING,%d0
        beq.w .Lgk_current_special_skip
        bra.w gk_audio_transfer_fatal
1:
        move.b %d6,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_current_special_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_transfer_current_special_stock
gk_audio_transfer_current_special_stock:
        .incbin "stock/0049.bin", 0, 10
        .incbin "stock/0049.bin", 10, 10
        .incbin "stock/0049.bin", 20, 10
        .incbin "stock/0049.bin", 30, 10
        .incbin "stock/0049.bin", 40, 10
        .incbin "stock/0049.bin", 50, 8
        .global gk_audio_transfer_current_special_stock_end
gk_audio_transfer_current_special_stock_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_current_special_continue_restore
        tst.l   %d0
        bne.w   gk_audio_transfer_fatal
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET + 14,%a0
        moveq #0,%d6
        move.b 64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d6
        cmpi.l #GK_DESCRIPTOR_COUNT-1,%d6
        bhi.w gk_audio_transfer_fatal
        jsr .Lgk_audio_transfer_finish
        tst.l %d0
        bne.w gk_audio_transfer_fatal
        move.b #GK_ID_NONE,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_current_special_continue_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_CURRENT_SPECIAL_CONTINUE
.Lgk_current_special_skip:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_CURRENT_SPECIAL_CONTINUE
        .size   gk_stock_audio_transfer_current_special,.-gk_stock_audio_transfer_current_special
        .global gk_stock_audio_transfer_active_primary
        .type   gk_stock_audio_transfer_active_primary,@function
gk_stock_audio_transfer_active_primary:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_active_primary_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_active_primary_stock_restore
        bra.w   gk_audio_transfer_fatal
.Lgk_active_primary_active:
        move.b  #GK_ID_NONE,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        moveq   #0,%d4
        move.l  64 + 0x48(%sp),%d4
        cmpi.l  #GK_SIDECAR_AUDIO_PRIMARY_COUNT - 1,%d4
        bhi.w   gk_audio_transfer_fatal
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        cmpi.l  #7,%d5
        bhi.w   gk_audio_transfer_fatal
        cmp.l   20(%sp),%d4
        bne.w   gk_audio_transfer_fatal
        cmp.l   16(%sp),%d5
        bne.w   gk_audio_transfer_fatal
        move.l  52(%sp),%d0
        cmpi.l  #GK_STOCK_AUDIO_ACTIVE_STATE,%d0
        bne.w   gk_audio_transfer_fatal
        move.l  %d4,%d0
        andi.l  #7,%d0
        cmp.l   %d5,%d0
        bne.w   gk_audio_transfer_fatal
        moveq #0,%d7
        move.b 64+0x76(%sp),%d7
        lsl.l #8,%d7
        moveq #0,%d0
        move.b 64+0x77(%sp),%d0
        or.l %d0,%d7
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d0,%a0
        lea     GK_STOCK_AUDIO_PRIMARY_BANKS,%a1
        adda.l  %d4,%a1
        lea     GK_STOCK_AUDIO_PRIMARY_PARTS,%a2
        adda.l  %d4,%a2
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_ACTIVE_OFFSET,%a3
        adda.l  %d0,%a3
        jsr .Lgk_audio_transfer_begin
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_ERR_INVALID,%d0
        beq.w .Lgk_active_primary_skip
        cmpi.l #GK_ERR_UPDATING,%d0
        beq.w .Lgk_active_primary_skip
        bra.w gk_audio_transfer_fatal
1:
        move.b %d6,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_active_primary_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_transfer_active_primary_stock
gk_audio_transfer_active_primary_stock:
        .incbin "stock/0050.bin", 0, 10
        .incbin "stock/0050.bin", 10, 10
        .incbin "stock/0050.bin", 20, 10
        .incbin "stock/0050.bin", 30, 10
        .incbin "stock/0050.bin", 40, 10
        .incbin "stock/0050.bin", 50, 10
        .global gk_audio_transfer_active_primary_stock_end
gk_audio_transfer_active_primary_stock_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_active_primary_continue_restore
        tst.l   %d0
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_ACTIVE_OFFSET,%a0
        adda.l  %d0,%a0
        moveq #0,%d6
        move.b 64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d6
        cmpi.l #GK_DESCRIPTOR_COUNT-1,%d6
        bhi.w gk_audio_transfer_fatal
        jsr .Lgk_audio_transfer_finish
        tst.l %d0
        bne.w gk_audio_transfer_fatal
        move.b #GK_ID_NONE,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_active_primary_continue_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_ACTIVE_PRIMARY_CONTINUE
.Lgk_active_primary_skip:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_ACTIVE_PRIMARY_CONTINUE
        .size   gk_stock_audio_transfer_active_primary,.-gk_stock_audio_transfer_active_primary
        .global gk_stock_audio_transfer_primary_adjacent
        .type   gk_stock_audio_transfer_primary_adjacent,@function
gk_stock_audio_transfer_primary_adjacent:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_primary_adjacent_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_primary_adjacent_stock_restore
        bra.w   gk_audio_transfer_fatal
.Lgk_primary_adjacent_active:
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        cmpi.l  #6,%d5
        bhi.w   gk_audio_transfer_fatal
        move.l  %d5,%d4
        addq.l  #1,%d4
        cmp.l   64 + 0x98(%sp),%d4
        bne.w   gk_audio_transfer_fatal
        move.l  %d5,%d0
        lsl.l   #2,%d0
        lea     GK_STOCK_AUDIO_SNAPSHOT_RECORDS,%a1
        adda.l  %d0,%a1
        cmpa.l  64 + 0xbc(%sp),%a1
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d2
        move.b  GK_STOCK_AUDIO_SNAPSHOT_VALIDITY,%d2
        bset    %d4,%d2
        moveq   #0,%d0
        move.b  7(%sp),%d0
        cmp.b   %d2,%d0
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d3
        move.l  64 + 0x48(%sp),%d3
        cmpi.l  #GK_SIDECAR_AUDIO_PRIMARY_COUNT - 1,%d3
        bhi.w   gk_audio_transfer_fatal
        move.l  %d3,%d0
        andi.l  #7,%d0
        cmp.l   %d5,%d0
        bne.w   gk_audio_transfer_fatal
        moveq #0,%d7
        move.b 64+0x76(%sp),%d7
        lsl.l #8,%d7
        moveq #0,%d0
        move.b 64+0x77(%sp),%d0
        or.l %d0,%d7
        move.l  %d3,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d0,%a0
        lea     GK_STOCK_AUDIO_PRIMARY_BANKS,%a1
        adda.l  %d3,%a1
        lea     GK_STOCK_AUDIO_PRIMARY_PARTS,%a2
        adda.l  %d3,%a2
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a3
        adda.l  %d0,%a3
        moveq   #0,%d6
        move.b  64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d6
        cmpi.l  #GK_ID_NONE,%d6
        beq.s   .Lgk_primary_adjacent_fallback
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_audio_transfer_fatal
        jsr .Lgk_audio_transfer_begin_pinned
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_ERR_UPDATING,%d0
        bne.w gk_audio_transfer_fatal
        move.b #GK_ID_NONE,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        bra.w .Lgk_primary_adjacent_skip
1:
        bra.s   .Lgk_primary_adjacent_stock_restore
.Lgk_primary_adjacent_fallback:
        jsr .Lgk_audio_transfer_begin
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_ERR_INVALID,%d0
        beq.w .Lgk_primary_adjacent_skip
        cmpi.l #GK_ERR_UPDATING,%d0
        beq.w .Lgk_primary_adjacent_skip
        bra.w gk_audio_transfer_fatal
1:
        move.b %d6,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_primary_adjacent_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_transfer_primary_adjacent_stock
gk_audio_transfer_primary_adjacent_stock:
        .incbin "stock/0051.bin", 0, 10
        .incbin "stock/0051.bin", 10, 10
        .incbin "stock/0051.bin", 20, 10
        .incbin "stock/0051.bin", 30, 10
        .incbin "stock/0051.bin", 40, 10
        .incbin "stock/0051.bin", 50, 2
        .global gk_audio_transfer_primary_adjacent_stock_end
gk_audio_transfer_primary_adjacent_stock_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_primary_adjacent_continue_restore
        tst.l   %d0
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        addq.l  #1,%d5
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a0
        adda.l  %d0,%a0
        moveq #0,%d6
        move.b 64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d6
        cmpi.l #GK_DESCRIPTOR_COUNT-1,%d6
        bhi.w gk_audio_transfer_fatal
        jsr .Lgk_audio_transfer_finish
        tst.l %d0
        bne.w gk_audio_transfer_fatal
        move.b #GK_ID_NONE,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_primary_adjacent_continue_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_PRIMARY_ADJACENT_CONTINUE
.Lgk_primary_adjacent_skip:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_PRIMARY_ADJACENT_CONTINUE
        .size   gk_stock_audio_transfer_primary_adjacent,.-gk_stock_audio_transfer_primary_adjacent
        .global gk_stock_audio_transfer_primary_special
        .type   gk_stock_audio_transfer_primary_special,@function
gk_stock_audio_transfer_primary_special:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_primary_special_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_primary_special_stock_restore
        bra.w   gk_audio_transfer_fatal
.Lgk_primary_special_active:
        move.b  #GK_ID_NONE,64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        cmpi.l  #7,%d5
        bhi.w   gk_audio_transfer_fatal
        moveq   #0,%d2
        move.b  GK_STOCK_AUDIO_SNAPSHOT_VALIDITY,%d2
        ori.l   #0x80,%d2
        moveq   #0,%d0
        move.b  7(%sp),%d0
        cmp.b   %d2,%d0
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d4
        move.l  64 + 0x48(%sp),%d4
        cmpi.l  #GK_SIDECAR_AUDIO_PRIMARY_COUNT - 1,%d4
        bhi.w   gk_audio_transfer_fatal
        move.l  %d4,%d0
        andi.l  #7,%d0
        cmp.l   %d5,%d0
        bne.w   gk_audio_transfer_fatal
        moveq #0,%d7
        move.b 64+0x76(%sp),%d7
        lsl.l #8,%d7
        moveq #0,%d0
        move.b 64+0x77(%sp),%d0
        or.l %d0,%d7
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_PRIMARY_OFFSET,%a0
        adda.l  %d0,%a0
        lea     GK_STOCK_AUDIO_PRIMARY_BANKS,%a1
        adda.l  %d4,%a1
        lea     GK_STOCK_AUDIO_PRIMARY_PARTS,%a2
        adda.l  %d4,%a2
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET + 14,%a3
        jsr .Lgk_audio_transfer_begin
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_ERR_INVALID,%d0
        beq.w .Lgk_primary_special_skip
        cmpi.l #GK_ERR_UPDATING,%d0
        beq.w .Lgk_primary_special_skip
        bra.w gk_audio_transfer_fatal
1:
        move.b %d6,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_primary_special_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_transfer_primary_special_stock
gk_audio_transfer_primary_special_stock:
        .incbin "stock/0052.bin", 0, 10
        .incbin "stock/0052.bin", 10, 10
        .incbin "stock/0052.bin", 20, 10
        .incbin "stock/0052.bin", 30, 10
        .incbin "stock/0052.bin", 40, 10
        .incbin "stock/0052.bin", 50, 2
        .global gk_audio_transfer_primary_special_stock_end
gk_audio_transfer_primary_special_stock_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_primary_special_continue_restore
        tst.l   %d0
        bne.w   gk_audio_transfer_fatal
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET + 14,%a0
        moveq #0,%d6
        move.b 64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d6
        cmpi.l #GK_DESCRIPTOR_COUNT-1,%d6
        bhi.w gk_audio_transfer_fatal
        jsr .Lgk_audio_transfer_finish
        tst.l %d0
        bne.w gk_audio_transfer_fatal
        move.b #GK_ID_NONE,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_primary_special_continue_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_PRIMARY_SPECIAL_CONTINUE
.Lgk_primary_special_skip:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_PRIMARY_SPECIAL_CONTINUE
        .size   gk_stock_audio_transfer_primary_special,.-gk_stock_audio_transfer_primary_special
        .global gk_stock_audio_transfer_snapshot_chain
        .type   gk_stock_audio_transfer_snapshot_chain,@function
gk_stock_audio_transfer_snapshot_chain:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        beq.s   .Lgk_snapshot_chain_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_snapshot_chain_stock_restore
        bra.w   gk_audio_transfer_fatal
.Lgk_snapshot_chain_active:
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        cmpi.l  #6,%d5
        bhi.w   gk_audio_transfer_fatal
        move.l  %d5,%d4
        addq.l  #1,%d4
        cmp.l   64 + 0x98(%sp),%d4
        bne.w   gk_audio_transfer_fatal
        move.l  %d5,%d0
        lsl.l   #2,%d0
        lea     GK_STOCK_AUDIO_SNAPSHOT_RECORDS,%a1
        adda.l  %d0,%a1
        cmpa.l  64 + 0xbc(%sp),%a1
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d2
        move.b  GK_STOCK_AUDIO_SNAPSHOT_VALIDITY,%d2
        bset    %d4,%d2
        moveq   #0,%d0
        move.b  7(%sp),%d0
        cmp.b   %d2,%d0
        bne.w   gk_audio_transfer_fatal
        moveq #0,%d7
        move.b 64+0x76(%sp),%d7
        lsl.l #8,%d7
        moveq #0,%d0
        move.b 64+0x77(%sp),%d0
        or.l %d0,%d7
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a0
        adda.l  %d0,%a0
        move.l  %d5,%d0
        lsl.l   #2,%d0
        lea     GK_STOCK_AUDIO_SNAPSHOT_RECORDS,%a1
        adda.l  %d0,%a1
        lea     1(%a1),%a2
        move.l  %d4,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a3
        adda.l  %d0,%a3
        moveq   #0,%d6
        move.b  64 + GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d6
        cmpi.l  #GK_ID_NONE,%d6
        beq.s   .Lgk_snapshot_chain_fallback
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_audio_transfer_fatal
        jsr .Lgk_audio_transfer_begin_pinned
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_ERR_UPDATING,%d0
        bne.w gk_audio_transfer_fatal
        move.b #GK_ID_NONE,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
        bra.w .Lgk_snapshot_chain_skip
1:
        bra.s   .Lgk_snapshot_chain_stock_restore
.Lgk_snapshot_chain_fallback:
        jsr .Lgk_audio_transfer_begin
        tst.l %d0
        beq.s 1f
        cmpi.l #GK_ERR_INVALID,%d0
        beq.w .Lgk_snapshot_chain_skip
        cmpi.l #GK_ERR_UPDATING,%d0
        beq.w .Lgk_snapshot_chain_skip
        bra.w gk_audio_transfer_fatal
1:
        move.b %d6,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_snapshot_chain_stock_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        .global gk_audio_transfer_snapshot_chain_stock
gk_audio_transfer_snapshot_chain_stock:
        .incbin "stock/0053.bin", 0, 10
        .incbin "stock/0053.bin", 10, 10
        .incbin "stock/0053.bin", 20, 10
        .incbin "stock/0053.bin", 30, 10
        .global gk_audio_transfer_snapshot_chain_stock_end
gk_audio_transfer_snapshot_chain_stock_end:
        lea -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,4(%sp)
        move.w %sr,%d0
        move.w %d0,(%sp)
        move.l 4(%sp),%d0
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.s   .Lgk_snapshot_chain_continue_restore
        tst.l   %d0
        bne.w   gk_audio_transfer_fatal
        moveq   #0,%d5
        move.l  64 + 0x72(%sp),%d5
        addq.l  #1,%d5
        move.l  %d5,%d0
        lsl.l   #1,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_AUDIO_SNAPSHOT_OFFSET,%a0
        adda.l  %d0,%a0
        moveq #0,%d6
        move.b 64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp),%d6
        cmpi.l #GK_DESCRIPTOR_COUNT-1,%d6
        bhi.w gk_audio_transfer_fatal
        jsr .Lgk_audio_transfer_finish
        tst.l %d0
        bne.w gk_audio_transfer_fatal
        move.b #GK_ID_NONE,64+GK_AUDIO_TRANSFER_DESCRIPTOR_SP(%sp)
.Lgk_snapshot_chain_continue_restore:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_SNAPSHOT_CHAIN_CONTINUE
.Lgk_snapshot_chain_skip:
        move.w (%sp),%d0
        move.w %d0,%sr
        movem.l 4(%sp),%d0-%d7/%a0-%a6
        lea 64(%sp),%sp
        jmp     GK_STOCK_AUDIO_TRANSFER_SNAPSHOT_CHAIN_CONTINUE
        .size   gk_stock_audio_transfer_snapshot_chain,.-gk_stock_audio_transfer_snapshot_chain
        .global gk_audio_transfer_fatal
        .type   gk_audio_transfer_fatal,@function
gk_audio_transfer_fatal:
        illegal
        .size   gk_audio_transfer_fatal,.-gk_audio_transfer_fatal
