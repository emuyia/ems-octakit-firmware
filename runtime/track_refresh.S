        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .equ    GK_REFRESH_TOKEN_MACHINE_ARMED,0x474b5400
        .global gk_stock_current_tuple_refresh
        .type   gk_stock_current_tuple_refresh,@function
gk_stock_current_tuple_refresh:
        move.l  (%sp),%d0
        cmpi.l  #GK_STOCK_CURRENT_TUPLE_REFRESH_RETURN_0,%d0
        beq.s   .Lgk_refresh_caller_ok
        cmpi.l  #GK_STOCK_CURRENT_TUPLE_REFRESH_RETURN_1,%d0
        beq.s   .Lgk_refresh_caller_ok
        cmpi.l  #GK_STOCK_CURRENT_TUPLE_REFRESH_RETURN_2,%d0
        beq.s   .Lgk_refresh_caller_ok
        cmpi.l  #GK_STOCK_CURRENT_TUPLE_REFRESH_RETURN_3,%d0
        beq.s   .Lgk_refresh_caller_ok
        cmpi.l  #GK_STOCK_CURRENT_TUPLE_REFRESH_RETURN_4,%d0
        beq.s   .Lgk_refresh_caller_ok
        cmpi.l  #GK_STOCK_CURRENT_TUPLE_REFRESH_RETURN_5,%d0
        bne.w   gk_current_tuple_refresh_fatal
.Lgk_refresh_caller_ok:
        lea     -64(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l  68(%sp),%d4
        move.l  72(%sp),%d5
        move.l  76(%sp),%d6
        cmpi.l  #15,%d4
        bhi.w   gk_current_tuple_refresh_fatal
        cmpi.l  #3,%d5
        bhi.w   gk_current_tuple_refresh_fatal
        cmpi.l  #7,%d6
        bhi.w   gk_current_tuple_refresh_fatal
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_refresh_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #-1,%d7
        move.l  #GK_REFRESH_TOKEN_ARMED,%d3
        bra.w   .Lgk_refresh_invoke_stock
.Lgk_refresh_active:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d5,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d5,%d0
        bne.w   gk_current_tuple_refresh_fatal
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        jsr     gk_selector_acquire
        tst.l   %d0
        bpl.s   .Lgk_refresh_source_acquired
        cmpi.l  #GK_ERR_UPDATING,%d0
        bne.w   gk_current_tuple_refresh_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        jsr     gk_machine_transition_current_tuple_validate
        move.l  %d0,%d7
        movea.l %a0,%a5
        move.l  %d4,%d0
        move.l  %d5,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_current_tuple_refresh_fatal
        cmp.l   %d7,%d0
        bne.w   .Lgk_refresh_transition_release_fatal
        cmpa.l  %a5,%a0
        bne.w   .Lgk_refresh_transition_release_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        jsr     gk_machine_transition_current_tuple_validate
        cmp.l   %d7,%d0
        bne.w   .Lgk_refresh_transition_release_d7_fatal
        cmpa.l  %a5,%a0
        bne.w   .Lgk_refresh_transition_release_d7_fatal
        move.l  #GK_REFRESH_TOKEN_MACHINE_ARMED,%d3
        bra.s   .Lgk_refresh_acquired_common
.Lgk_refresh_source_acquired:
        move.l  %d0,%d7
        movea.l %a0,%a5
        move.l  #GK_REFRESH_TOKEN_ARMED,%d3
.Lgk_refresh_acquired_common:
        move.l  %d4,%d0
        lsl.l   #2,%d0
        add.l   %d5,%d0
        jsr     gk_physical_validate
        tst.l   %d0
        bmi.w   .Lgk_refresh_release_fatal
        cmp.l   %d7,%d0
        bne.w   .Lgk_refresh_release_fatal
        cmpa.l  %a5,%a0
        bne.w   .Lgk_refresh_release_fatal
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_refresh_release_fatal
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_refresh_release_fatal
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_refresh_release_fatal
        move.l  %d6,%d0
        add.l   %d0,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        adda.l  %d0,%a0
        jsr     gk_selector_acquire
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.s   .Lgk_refresh_invoke_stock
        tst.l   %d0
        bmi.w   .Lgk_refresh_release_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   .Lgk_refresh_release_fatal
.Lgk_refresh_invoke_stock:
        move.l  %d7,%d0
        andi.l  #0xff,%d0
        or.l    %d3,%d0
        move.l  %d0,-(%sp)
        move.l  %d6,-(%sp)
        move.l  %d5,-(%sp)
        move.l  %d4,-(%sp)
        bsr.w   gk_stock_current_tuple_refresh_trampoline
        move.l  %d0,60(%sp)
        move.l  %d1,64(%sp)
        move.l  %a0,68(%sp)
        move.l  %a1,72(%sp)
        move.w  %sr,%d0
        move.w  %d0,76(%sp)
        move.l  %d7,%d1
        andi.l  #0xff,%d1
        ori.l   #GK_REFRESH_TOKEN_COMMITTED,%d1
        cmp.l   12(%sp),%d1
        bne.s   .Lgk_refresh_post_fatal
        lea     16(%sp),%sp
        cmpi.l  #-1,%d7
        beq.s   .Lgk_refresh_restore
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_current_tuple_refresh_fatal
.Lgk_refresh_restore:
        move.w  60(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d2-%d7/%a2-%a6
        move.l  44(%sp),%d0
        move.l  48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        lea     64(%sp),%sp
        rts
.Lgk_refresh_post_fatal:
        cmpi.l  #-1,%d7
        beq.w   gk_current_tuple_refresh_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        bra.w   gk_current_tuple_refresh_fatal
.Lgk_refresh_release_fatal:
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        bra.w   gk_current_tuple_refresh_fatal
.Lgk_refresh_transition_release_d7_fatal:
        move.l  %d7,%d0
.Lgk_refresh_transition_release_fatal:
        jsr     gk_descriptor_release
        bra.w   gk_current_tuple_refresh_fatal
        .size   gk_stock_current_tuple_refresh,.-gk_stock_current_tuple_refresh
        .global gk_stock_current_tuple_refresh_trampoline
        .type   gk_stock_current_tuple_refresh_trampoline,@function
gk_stock_current_tuple_refresh_trampoline:
        .incbin "stock/0190.bin", 0, 4
        .incbin "stock/0190.bin", 4, 4
        .global gk_stock_current_tuple_refresh_trampoline_jump
gk_stock_current_tuple_refresh_trampoline_jump:
        jmp     GK_STOCK_CURRENT_TUPLE_REFRESH_CONTINUE
        .size   gk_stock_current_tuple_refresh_trampoline,.-gk_stock_current_tuple_refresh_trampoline
        .global gk_stock_current_tuple_track_publish
        .type   gk_stock_current_tuple_track_publish,@function
gk_stock_current_tuple_track_publish:
        lea     -56(%sp),%sp
        movem.l %d0-%d7/%a2-%a6,(%sp)
        move.l  108(%sp),%d4
        move.l  112(%sp),%d5
        move.l  116(%sp),%d6
        move.l  120(%sp),%d7
        cmpi.l  #15,%d4
        bhi.w   gk_current_tuple_refresh_fatal
        cmpi.l  #3,%d5
        bhi.w   gk_current_tuple_refresh_fatal
        cmpi.l  #7,%d6
        bhi.w   gk_current_tuple_refresh_fatal
        cmp.l   24(%sp),%d6
        bne.w   gk_current_tuple_refresh_fatal
        move.l  %d7,%d0
        andi.l  #0xffffff00,%d0
        cmpi.l  #GK_REFRESH_TOKEN_ARMED,%d0
        beq.s   .Lgk_refresh_pair_stable_token
        cmpi.l  #GK_REFRESH_TOKEN_MACHINE_ARMED,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #1,%d3
        bra.s   .Lgk_refresh_pair_token_valid
.Lgk_refresh_pair_stable_token:
        moveq   #0,%d3
.Lgk_refresh_pair_token_valid:
        andi.l  #0xff,%d7
        move.w  %sr,%d0
        move.w  %d0,52(%sp)
        .global gk_current_tuple_refresh_atomic_begin
gk_current_tuple_refresh_atomic_begin:
        move.w  #0x2700,%sr
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_refresh_pair_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_current_tuple_refresh_fatal
        cmpi.l  #GK_ID_NONE,%d7
        bne.w   gk_current_tuple_refresh_fatal
        bra.w   .Lgk_refresh_pair_stock_writes
.Lgk_refresh_pair_active:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d7
        bhi.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   %d4,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   %d4,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d5,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d5,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d5,%d0
        bne.w   gk_current_tuple_refresh_fatal
        tst.l   %d3
        bne.s   .Lgk_refresh_pair_machine_source
        moveq   #0,%d0
        move.w  __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.w   %d1,%d0
        bne.w   gk_current_tuple_refresh_fatal
        bra.s   .Lgk_refresh_pair_source_valid
.Lgk_refresh_pair_machine_source:
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        jsr     gk_machine_transition_current_tuple_validate
        tst.l   %d0
        bmi.w   gk_current_tuple_refresh_fatal
        cmp.l   %d7,%d0
        bne.w   gk_current_tuple_refresh_fatal
.Lgk_refresh_pair_source_valid:
        move.l  %d4,%d0
        lsl.l   #2,%d0
        add.l   %d5,%d0
        jsr     gk_physical_validate
        tst.l   %d0
        bmi.w   gk_current_tuple_refresh_fatal
        cmp.l   %d7,%d0
        bne.w   gk_current_tuple_refresh_fatal
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        tst.w   GK_DESC_ROOTS(%a3)
        beq.w   gk_current_tuple_refresh_fatal
        tst.w   GK_DESC_READERS(%a3)
        beq.w   gk_current_tuple_refresh_fatal
        move.l  %d6,%d0
        add.l   %d0,%d0
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a2
        adda.l  %d0,%a2
        movea.l %a2,%a0
        move.l  %d7,%d0
        jsr     gk_selector_begin_update
        tst.l   %d0
        bne.w   gk_current_tuple_refresh_fatal
.Lgk_refresh_pair_stock_writes:
        .incbin "stock/0191.bin", 0, 6
        .incbin "stock/0191.bin", 6, 6
        .global gk_current_tuple_refresh_stock_bank_publication
gk_current_tuple_refresh_stock_bank_publication:
        .incbin "stock/0191.bin", 12, 4
        .incbin "stock/0191.bin", 16, 6
        .incbin "stock/0191.bin", 22, 6
        .global gk_current_tuple_refresh_stock_part_publication
gk_current_tuple_refresh_stock_part_publication:
        .incbin "stock/0191.bin", 28, 4
        cmpi.l  #GK_ID_NONE,%d7
        beq.s   .Lgk_refresh_pair_token_commit
        movea.l %a2,%a0
        jsr     gk_selector_commit_update
        tst.l   %d0
        bne.w   gk_current_tuple_refresh_fatal
        moveq   #0,%d0
        move.w  (%a2),%d0
        move.l  %d7,%d1
        lsl.l   #8,%d1
        ori.l   #0xff,%d1
        cmp.w   %d1,%d0
        bne.w   gk_current_tuple_refresh_fatal
.Lgk_refresh_pair_token_commit:
        move.l  %d7,%d0
        ori.l   #GK_REFRESH_TOKEN_COMMITTED,%d0
        .global gk_current_tuple_refresh_token_publication
gk_current_tuple_refresh_token_publication:
        move.l  %d0,120(%sp)
        move.w  52(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d7/%a2-%a6
        lea     56(%sp),%sp
        lea     GK_STOCK_ENGINE_TRACK_PARTS,%a0
        lea     GK_STOCK_ENGINE_PART,%a1
        .global gk_stock_current_tuple_track_publish_jump
gk_stock_current_tuple_track_publish_jump:
        jmp     GK_STOCK_CURRENT_TUPLE_REFRESH_PAIR_CONTINUE
        .size   gk_stock_current_tuple_track_publish,.-gk_stock_current_tuple_track_publish
        .global gk_current_tuple_refresh_fatal
gk_current_tuple_refresh_fatal:
        illegal
        bra.s   gk_current_tuple_refresh_fatal
