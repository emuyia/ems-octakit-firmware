        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_derived_cache_refresh
        .type   gk_stock_derived_cache_refresh,@function
gk_stock_derived_cache_refresh:
        move.l  (%sp),%d0
        cmpi.l  #GK_STOCK_DERIVED_REFRESH_RETURN_0,%d0
        beq.s   .Lgk_derived_caller_ok
        cmpi.l  #GK_STOCK_DERIVED_REFRESH_RETURN_1,%d0
        beq.s   .Lgk_derived_caller_ok
        cmpi.l  #GK_STOCK_DERIVED_REFRESH_RETURN_2,%d0
        beq.s   .Lgk_derived_caller_ok
        cmpi.l  #GK_STOCK_DERIVED_REFRESH_RETURN_3,%d0
        bne.w   gk_derived_cache_refresh_fatal
.Lgk_derived_caller_ok:
        .global gk_stock_derived_cache_refresh_authenticated
gk_stock_derived_cache_refresh_authenticated:
        lea     -64(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l  68(%sp),%d4
        move.l  72(%sp),%d5
        move.l  76(%sp),%d6
        movea.l 80(%sp),%a6
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_derived_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #-1,%d7
        bra.w   .Lgk_derived_invoke_stock_quiesced
.Lgk_derived_active:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bpl.w   .Lgk_derived_context_available
        cmpi.l  #GK_ERR_BUSY,%d0
        bne.w   gk_derived_cache_refresh_fatal
        move.l  64(%sp),%d0
        cmpi.l  #GK_STOCK_DERIVED_REFRESH_RETURN_1,%d0
        beq.s   .Lgk_derived_scene_caller_ok
        cmpi.l  #GK_STOCK_DERIVED_REFRESH_RETURN_2,%d0
        bne.w   gk_derived_cache_refresh_fatal
.Lgk_derived_scene_caller_ok:
        moveq   #0,%d0
        move.b  __gk_scene_clipboard_active,%d0
        cmpi.l  #GK_SCENE_CLIPBOARD_PASTE,%d0
        beq.s   .Lgk_derived_scene_kind_ok
        cmpi.l  #GK_SCENE_CLIPBOARD_CLEAR,%d0
        bne.w   gk_derived_cache_refresh_fatal
.Lgk_derived_scene_kind_ok:
        moveq   #0,%d0
        move.b  __gk_scene_clipboard_part,%d0
        cmp.l   %d5,%d0
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d0
        move.b  __gk_scene_clipboard_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d1
        move.b  __gk_scene_clipboard_descriptor_inverse,%d1
        eor.l   %d0,%d1
        cmpi.l  #0xff,%d1
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d1
        move.b  __gk_pending_workspace_descriptor,%d1
        cmp.l   %d1,%d0
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d1
        move.b  __gk_workspace_descriptor,%d1
        cmp.l   %d1,%d0
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d5,%d0
        bne.w   gk_derived_cache_refresh_fatal
        move.l  %d4,%d0
.Lgk_derived_context_available:
        cmp.l   %d4,%d0
        bne.w   gk_derived_cache_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w   gk_derived_cache_refresh_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_derived_cache_refresh_fatal
        move.l  %d0,%d7
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_derived_release_fatal
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_derived_release_fatal
.Lgk_derived_invoke_stock_active:
        move.l  %d7,%d0
        andi.l  #0xff,%d0
        ori.l   #GK_DERIVED_REFRESH_TOKEN_ARMED,%d0
        move.l  %d0,-(%sp)
        move.l  %a6,-(%sp)
        move.l  %d6,-(%sp)
        move.l  %d5,-(%sp)
        move.l  %d4,-(%sp)
        bsr.w   gk_stock_derived_cache_refresh_trampoline
        move.w  %sr,%d2
        move.w  %d2,80(%sp)
        move.l  %d0,64(%sp)
        move.l  %d1,68(%sp)
        move.l  %a0,72(%sp)
        move.l  %a1,76(%sp)
        move.l  %d7,%d1
        andi.l  #0xff,%d1
        ori.l   #GK_DERIVED_REFRESH_TOKEN_ARMED,%d1
        cmp.l   16(%sp),%d1
        bne.s   .Lgk_derived_post_fatal
        lea     20(%sp),%sp
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.s   .Lgk_derived_release_fatal
        tst.l   __gk_lifecycle_state
        bne.s   .Lgk_derived_release_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_derived_cache_refresh_fatal
.Lgk_derived_restore:
        movem.l (%sp),%d2-%d7/%a2-%a6
        move.l  44(%sp),%d0
        move.l  48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        move.w  60(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d2
        lea     64(%sp),%sp
        rts
.Lgk_derived_invoke_stock_quiesced:
        move.l  %d7,%d0
        andi.l  #0xff,%d0
        ori.l   #GK_DERIVED_REFRESH_TOKEN_ARMED,%d0
        move.l  %d0,-(%sp)
        move.l  %a6,-(%sp)
        move.l  %d6,-(%sp)
        move.l  %d5,-(%sp)
        move.l  %d4,-(%sp)
        bsr.w   gk_stock_derived_cache_refresh_trampoline
        lea     20(%sp),%sp
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     64(%sp),%sp
        rts
.Lgk_derived_post_fatal:
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        bra.w   gk_derived_cache_refresh_fatal
.Lgk_derived_release_fatal:
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        bra.w   gk_derived_cache_refresh_fatal
        .size   gk_stock_derived_cache_refresh,.-gk_stock_derived_cache_refresh
        .global gk_stock_derived_cache_refresh_trampoline
        .type   gk_stock_derived_cache_refresh_trampoline,@function
gk_stock_derived_cache_refresh_trampoline:
        .incbin "stock/0239.bin", 0, 4
        .incbin "stock/0239.bin", 4, 4
        .global gk_stock_derived_cache_refresh_trampoline_jump
gk_stock_derived_cache_refresh_trampoline_jump:
        jmp     GK_STOCK_DERIVED_REFRESH_CONTINUE
        .size   gk_stock_derived_cache_refresh_trampoline,.-gk_stock_derived_cache_refresh_trampoline
        .global gk_derived_cache_identity_match
        .type   gk_derived_cache_identity_match,@function
gk_derived_cache_identity_match:
        cmpi.l  #7,%d0
        bhi.w   gk_derived_cache_refresh_fatal
        move.l  %d1,%d2
        andi.l  #0xffffff00,%d2
        cmpi.l  #GK_DERIVED_REFRESH_TOKEN_ARMED,%d2
        bne.w   gk_derived_cache_refresh_fatal
        andi.l  #0xff,%d1
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.w   gk_derived_cache_refresh_fatal
        add.l   %d0,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        adda.l  %d0,%a0
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        .global gk_derived_cache_identity_snapshot
gk_derived_cache_identity_snapshot:
        move.w  (%a0),%d0
        move.w  %d2,%sr
        move.l  %d1,%d2
        lsl.l   #8,%d2
        ori.l   #0xff,%d2
        cmp.l   %d2,%d0
        seq     %d0
        andi.l  #1,%d0
        rts
        .size   gk_derived_cache_identity_match,.-gk_derived_cache_identity_match
        .global gk_stock_derived_cache_first_compare
        .type   gk_stock_derived_cache_first_compare,@function
gk_stock_derived_cache_first_compare:
        lea     -16(%sp),%sp
        movem.l %d1-%d2/%a0-%a1,(%sp)
        move.l  88(%sp),%d0
        move.l  %d0,%d2
        andi.l  #0xffffff00,%d2
        cmpi.l  #GK_DERIVED_REFRESH_TOKEN_ARMED,%d2
        bne.w   gk_derived_cache_refresh_fatal
        andi.l  #0xff,%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_derived_first_quiesced
        cmpi.l  #7,%d1
        bhi.w   gk_derived_cache_refresh_fatal
        lea     GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l  %d1,%a0
        cmpa.l  %a0,%a2
        bne.w   gk_derived_cache_refresh_fatal
        move.l  %d1,%d0
        move.l  88(%sp),%d1
        bsr.w   gk_derived_cache_identity_match
        tst.l   %d0
        beq.s   .Lgk_derived_first_miss
        mvz.b   (%a2),%d0
        cmpa.l  %d0,%a6
        bne.w   gk_derived_cache_refresh_fatal
        mvz.b   -8(%a2),%d0
        cmpa.l  %d0,%a5
        bne.w   gk_derived_cache_refresh_fatal
        movem.l (%sp),%d1-%d2/%a0-%a1
        lea     16(%sp),%sp
        jmp     GK_STOCK_DERIVED_REFRESH_FIRST_MATCH
.Lgk_derived_first_miss:
        movem.l (%sp),%d1-%d2/%a0-%a1
        lea     16(%sp),%sp
        jmp     GK_STOCK_DERIVED_REFRESH_FIRST_MISS
.Lgk_derived_first_quiesced:
        movem.l (%sp),%d1-%d2/%a0-%a1
        lea     16(%sp),%sp
        mvz.b  (%a2),%d0
        cmpa.l %d0,%a6
        bne.s   .Lgk_derived_first_stock_miss
        mvz.b  -8(%a2),%d0
        cmpa.l %d0,%a5
        bne.s   .Lgk_derived_first_stock_miss
        jmp     GK_STOCK_DERIVED_REFRESH_FIRST_MATCH
.Lgk_derived_first_stock_miss:
        jmp     GK_STOCK_DERIVED_REFRESH_FIRST_MISS
        .size   gk_stock_derived_cache_first_compare,.-gk_stock_derived_cache_first_compare
        .global gk_stock_derived_cache_second_compare
        .type   gk_stock_derived_cache_second_compare,@function
gk_stock_derived_cache_second_compare:
        lea     -16(%sp),%sp
        movem.l %d1-%d2/%a0-%a1,(%sp)
        move.l  88(%sp),%d0
        move.l  %d0,%d2
        andi.l  #0xffffff00,%d2
        cmpi.l  #GK_DERIVED_REFRESH_TOKEN_ARMED,%d2
        bne.w   gk_derived_cache_refresh_fatal
        andi.l  #0xff,%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_derived_second_quiesced
        move.l  %a3,%d0
        subi.l  #GK_STOCK_ENGINE_TRACK_PARTS,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_derived_cache_refresh_fatal
        move.l  88(%sp),%d1
        bsr.w   gk_derived_cache_identity_match
        tst.l   %d0
        beq.s   .Lgk_derived_second_miss
        mvz.b   (%a3),%d0
        cmp.l   %d0,%d5
        bne.w   gk_derived_cache_refresh_fatal
        mvz.b   -8(%a3),%d0
        cmp.l   (%sp),%d0
        bne.w   gk_derived_cache_refresh_fatal
        movem.l (%sp),%d1-%d2/%a0-%a1
        lea     16(%sp),%sp
        jmp     GK_STOCK_DERIVED_REFRESH_SECOND_MATCH
.Lgk_derived_second_miss:
        movem.l (%sp),%d1-%d2/%a0-%a1
        lea     16(%sp),%sp
        jmp     GK_STOCK_DERIVED_REFRESH_SECOND_MISS
.Lgk_derived_second_quiesced:
        movem.l (%sp),%d1-%d2/%a0-%a1
        lea     16(%sp),%sp
        mvz.b  (%a3),%d0
        cmp.l  %d0,%d5
        bne.s   .Lgk_derived_second_stock_miss
        mvz.b  -8(%a3),%d0
        cmp.l  %d0,%d1
        bne.s   .Lgk_derived_second_stock_miss
        jmp     GK_STOCK_DERIVED_REFRESH_SECOND_MATCH
.Lgk_derived_second_stock_miss:
        jmp     GK_STOCK_DERIVED_REFRESH_SECOND_MISS
        .size   gk_stock_derived_cache_second_compare,.-gk_stock_derived_cache_second_compare
        .global gk_derived_cache_refresh_fatal
gk_derived_cache_refresh_fatal:
        illegal
        bra.s   gk_derived_cache_refresh_fatal
