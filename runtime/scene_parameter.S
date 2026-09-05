        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_scene_parameter_abort_fatal,@function
gk_scene_parameter_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_scene_parameter_fatal
        bra.w   gk_scene_parameter_fatal
        .size   gk_scene_parameter_abort_fatal,.-gk_scene_parameter_abort_fatal
        .type   gk_scene_parameter_release_abort_fatal,@function
gk_scene_parameter_release_abort_fatal:
        move.l  %d2,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_parameter_fatal
        bra.w   gk_scene_parameter_abort_fatal
        .size   gk_scene_parameter_release_abort_fatal,.-gk_scene_parameter_release_abort_fatal
        .global gk_stock_scene_parameter_write
        .type   gk_stock_scene_parameter_write,@function
gk_stock_scene_parameter_write:
        tst.l   __gk_lifecycle_state
        bne.w   gk_scene_parameter_fatal
        .incbin "stock/0275.bin", 0, 4
        .incbin "stock/0275.bin", 4, 4
        movea.l 48(%sp),%a6
        movea.l 52(%sp),%a4
        movea.l 56(%sp),%a2
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_SCENE_PARAMETER_RETURN,%d0
        bne.w   gk_scene_parameter_fatal
        move.l  %a6,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_scene_parameter_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_scene_parameter_fatal
        movea.l %d0,%a5
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_scene_parameter_fatal
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_scene_parameter_fatal
        cmp.l   %d7,%d0
        bne.w   gk_scene_parameter_abort_fatal
        move.l  %a5,%d2
        cmp.l   %d2,%d1
        bne.w   gk_scene_parameter_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %a5,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_scene_parameter_abort_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   gk_scene_parameter_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_scene_parameter_release_abort_fatal
        move.l  %d7,%d0
        andi.l  #0xff,%d0
        ori.l   #GK_SCENE_PARAMETER_TOKEN_ARMED,%d0
        move.l  %d0,-(%sp)
        move.l  %a2,-(%sp)
        move.l  %a4,-(%sp)
        move.l  %a6,-(%sp)
        .global gk_scene_parameter_stock_call
gk_scene_parameter_stock_call:
        bsr.w   gk_stock_scene_parameter_write_trampoline
        move.l  12(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        cmpi.l  #GK_SCENE_PARAMETER_TOKEN_WRITTEN,%d1
        beq.s   .Lgk_scene_parameter_written
        cmpi.l  #GK_SCENE_PARAMETER_TOKEN_ARMED,%d1
        bne.w   gk_scene_parameter_fatal
        andi.l  #0xff,%d0
        cmp.l   %d7,%d0
        bne.w   gk_scene_parameter_fatal
        lea     16(%sp),%sp
        moveq   #0,%d6
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_parameter_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_scene_parameter_fatal
        bra.s   .Lgk_scene_parameter_post_validate
.Lgk_scene_parameter_written:
        andi.l  #0xff,%d0
        cmp.l   %d7,%d0
        bne.w   gk_scene_parameter_fatal
        lea     16(%sp),%sp
        moveq   #1,%d6
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a5,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_scene_parameter_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_scene_parameter_fatal
.Lgk_scene_parameter_post_validate:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_scene_parameter_fatal
        cmp.l   %d4,%d0
        bne.w   gk_scene_parameter_fatal
        cmp.l   %d5,%d1
        bne.w   gk_scene_parameter_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   gk_scene_parameter_fatal
        tst.l   %d6
        beq.s   .Lgk_scene_parameter_return
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_parameter_fatal
.Lgk_scene_parameter_return:
        .incbin "stock/0276.bin", 0, 4
        .incbin "stock/0276.bin", 4, 4
        .incbin "stock/0276.bin", 8, 2
        .size   gk_stock_scene_parameter_write,.-gk_stock_scene_parameter_write
        .global gk_stock_scene_parameter_write_trampoline
        .type   gk_stock_scene_parameter_write_trampoline,@function
gk_stock_scene_parameter_write_trampoline:
        .incbin "stock/0277.bin", 0, 4
        .incbin "stock/0277.bin", 4, 4
        .global gk_stock_scene_parameter_write_trampoline_jump
gk_stock_scene_parameter_write_trampoline_jump:
        jmp     GK_STOCK_SCENE_PARAMETER_CONTINUE
        .size   gk_stock_scene_parameter_write_trampoline,.-gk_stock_scene_parameter_write_trampoline
        .type   gk_scene_parameter_identity_match,@function
gk_scene_parameter_identity_match:
        cmpi.l  #7,%d0
        bhi.w   gk_scene_parameter_fatal
        move.l  %d1,%d2
        andi.l  #0xffffff00,%d2
        cmpi.l  #GK_SCENE_PARAMETER_TOKEN_ARMED,%d2
        bne.w   gk_scene_parameter_fatal
        andi.l  #0xff,%d1
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.w   gk_scene_parameter_fatal
        add.l   %d0,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        adda.l  %d0,%a0
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        .global gk_scene_parameter_identity_snapshot
gk_scene_parameter_identity_snapshot:
        move.w  (%a0),%d0
        move.w  %d2,%sr
        move.l  %d1,%d2
        lsl.l   #8,%d2
        ori.l   #0xff,%d2
        cmp.l   %d2,%d0
        seq     %d0
        andi.l  #1,%d0
        rts
        .size   gk_scene_parameter_identity_match,.-gk_scene_parameter_identity_match
        .global gk_stock_scene_parameter_a_compare
        .type gk_stock_scene_parameter_a_compare,@function
gk_stock_scene_parameter_a_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d4,%d0
        cmpi.l #7,%d0
        bhi.w gk_scene_parameter_fatal
        move.l 64(%sp),%d1
        bsr.w gk_scene_parameter_identity_match
        move.l %d0,%d2
        move.l 64(%sp),%d1
        andi.l #0xff,%d1
        ori.l #GK_SCENE_PARAMETER_TOKEN_WRITTEN,%d1
        move.l %d1,64(%sp)
        tst.l %d2
        beq.s .Lscene_parameter_miss_0
        move.l %d4,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        moveq #0,%d1
        move.b GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l %d1,%d0
        bne.w gk_scene_parameter_fatal
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        moveq #0,%d1
        move.b GK_STOCK_CURRENT_BANK_MIRROR,%d1
        cmp.l %d1,%d0
        bne.w gk_scene_parameter_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_PARAMETER_A_MATCH
.Lscene_parameter_miss_0:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_PARAMETER_A_MISS
        .size gk_stock_scene_parameter_a_compare,.-gk_stock_scene_parameter_a_compare
        .global gk_stock_scene_parameter_b_compare
        .type gk_stock_scene_parameter_b_compare,@function
gk_stock_scene_parameter_b_compare:
        lea -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l %d4,%d0
        cmpi.l #7,%d0
        bhi.w gk_scene_parameter_fatal
        move.l 64(%sp),%d1
        bsr.w gk_scene_parameter_identity_match
        move.l %d0,%d2
        move.l 64(%sp),%d1
        andi.l #0xff,%d1
        ori.l #GK_SCENE_PARAMETER_TOKEN_WRITTEN,%d1
        move.l %d1,64(%sp)
        tst.l %d2
        beq.s .Lscene_parameter_miss_1
        move.l %d4,%d0
        lea GK_STOCK_ENGINE_TRACK_PARTS,%a0
        adda.l %d0,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        moveq #0,%d1
        move.b GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l %d1,%d0
        bne.w gk_scene_parameter_fatal
        suba.l #8,%a0
        moveq #0,%d0
        move.b (%a0),%d0
        moveq #0,%d1
        move.b GK_STOCK_CURRENT_BANK_MIRROR,%d1
        cmp.l %d1,%d0
        bne.w gk_scene_parameter_fatal
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_PARAMETER_B_MATCH
.Lscene_parameter_miss_1:
        movem.l (%sp),%d0-%d2/%a0
        lea 16(%sp),%sp
        jmp GK_STOCK_SCENE_PARAMETER_B_MISS
        .size gk_stock_scene_parameter_b_compare,.-gk_stock_scene_parameter_b_compare
        .global gk_scene_parameter_fatal
gk_scene_parameter_fatal:
        illegal
        bra.s   gk_scene_parameter_fatal
