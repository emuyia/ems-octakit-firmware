        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .equ    GK_RESET_FRAME_SIZE,36
        .equ    GK_RESET_FRAME_SR,32
        .global gk_stock_engine_track_reset_pair
        .type   gk_stock_engine_track_reset_pair,@function
gk_stock_engine_track_reset_pair:
        lea     -GK_RESET_FRAME_SIZE(%sp),%sp
        movem.l %d0-%d3/%a0-%a3,(%sp)
        move.w  %sr,%d0
        move.w  %d0,GK_RESET_FRAME_SR(%sp)
        move.l  %a0,%d2
        subi.l  #GK_STOCK_ENGINE_TRACK_BANKS,%d2
        cmpi.l  #GK_SIDECAR_ENGINE_AUDIO_COUNT - 1,%d2
        bhi.w   gk_pair_invalidate_fatal
        move.l  %d2,%d0
        lsl.l   #2,%d0
        cmp.l   (%sp),%d0
        bne.w   gk_pair_invalidate_fatal
        move.l  %d2,%d0
        add.l   %d0,%d0
        lea     0x80001850,%a2
        adda.l  %d0,%a2
        cmpa.l  20(%sp),%a2
        bne.w   gk_pair_invalidate_fatal
        movea.l 24(%sp),%a2
        cmpa.l  #0x400d61f0,%a2
        bne.w   gk_pair_invalidate_fatal
        movea.l 28(%sp),%a3
        cmpa.l  #0x400d61d0,%a3
        bne.w   gk_pair_invalidate_fatal
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_engine_reset_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_pair_invalidate_fatal
        move.l  #GK_ID_NONE,%d3
        bra.w   .Lgk_engine_reset_stock
.Lgk_engine_reset_active:
        add.l   %d2,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a2
        adda.l  %d2,%a2
        .global gk_engine_track_reset_atomic_begin
gk_engine_track_reset_atomic_begin:
        move.w  #0x2700,%sr
        tst.l   __gk_lifecycle_state
        bne.w   gk_pair_invalidate_fatal
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_pair_invalidate_fatal
        moveq   #0,%d3
        move.b  GK_SIDECAR_CURRENT(%a2),%d3
        cmpi.l  #GK_ID_NONE,%d3
        beq.s   .Lgk_engine_reset_stock
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w   gk_pair_invalidate_fatal
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        btst    #0,GK_DESC_FLAGS(%a3)
        beq.w   gk_pair_invalidate_fatal
        moveq   #0,%d2
        move.w  GK_DESC_ROOTS(%a3),%d2
        tst.l   %d2
        beq.w   gk_pair_invalidate_fatal
.Lgk_engine_reset_stock:
        .global gk_engine_track_reset_stock_bank
gk_engine_track_reset_stock_bank:
        .incbin "stock/0110.bin", 0, 4
        .incbin "stock/0110.bin", 4, 2
        .global gk_engine_track_reset_stock_part
gk_engine_track_reset_stock_part:
        .incbin "stock/0110.bin", 6, 4
        cmpi.l  #GK_ID_NONE,%d3
        beq.s   .Lgk_engine_reset_restore
        movea.l %a2,%a0
        .global gk_engine_track_reset_sidecar_publication
gk_engine_track_reset_sidecar_publication:
        move.w  #0xffff,(%a0)
        subq.l  #1,%d2
        move.w  %d2,GK_DESC_ROOTS(%a3)
.Lgk_engine_reset_restore:
        move.w  GK_RESET_FRAME_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d3/%a0-%a3
        lea     GK_RESET_FRAME_SIZE(%sp),%sp
        st      %d1
        tst.b   %d1
        .global gk_stock_engine_track_reset_pair_jump
gk_stock_engine_track_reset_pair_jump:
        jmp     GK_STOCK_ENGINE_TRACK_RESET_PAIR_CONTINUE
        .size   gk_stock_engine_track_reset_pair,.-gk_stock_engine_track_reset_pair
        .global gk_stock_audio_command_track_reset_pair
        .type   gk_stock_audio_command_track_reset_pair,@function
gk_stock_audio_command_track_reset_pair:
        lea     -GK_RESET_FRAME_SIZE(%sp),%sp
        movem.l %d0-%d3/%a0-%a3,(%sp)
        move.w  %sr,%d0
        move.w  %d0,GK_RESET_FRAME_SR(%sp)
        move.l  %a0,%d2
        subi.l  #GK_STOCK_ENGINE_TRACK_BANKS,%d2
        cmpi.l  #GK_SIDECAR_ENGINE_AUDIO_COUNT - 1,%d2
        bhi.w   gk_pair_invalidate_fatal
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_audio_command_reset_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_pair_invalidate_fatal
        move.l  #GK_ID_NONE,%d3
        bra.w   .Lgk_audio_command_reset_stock
.Lgk_audio_command_reset_active:
        add.l   %d2,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a2
        adda.l  %d2,%a2
        .global gk_audio_command_track_reset_atomic_begin
gk_audio_command_track_reset_atomic_begin:
        move.w  #0x2700,%sr
        tst.l   __gk_lifecycle_state
        bne.w   gk_pair_invalidate_fatal
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_pair_invalidate_fatal
        moveq   #0,%d3
        move.b  GK_SIDECAR_CURRENT(%a2),%d3
        cmpi.l  #GK_ID_NONE,%d3
        beq.s   .Lgk_audio_command_reset_stock
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w   gk_pair_invalidate_fatal
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        btst    #0,GK_DESC_FLAGS(%a3)
        beq.w   gk_pair_invalidate_fatal
        moveq   #0,%d1
        move.w  GK_DESC_ROOTS(%a3),%d1
        tst.l   %d1
        beq.w   gk_pair_invalidate_fatal
.Lgk_audio_command_reset_stock:
        .global gk_audio_command_track_reset_stock_bank
gk_audio_command_track_reset_stock_bank:
        .incbin "stock/0111.bin", 0, 4
        .incbin "stock/0111.bin", 4, 2
        .global gk_audio_command_track_reset_stock_part
gk_audio_command_track_reset_stock_part:
        .incbin "stock/0111.bin", 6, 4
        cmpi.l  #GK_ID_NONE,%d3
        beq.s   .Lgk_audio_command_reset_restore
        movea.l %a2,%a0
        .global gk_audio_command_track_reset_sidecar_publication
gk_audio_command_track_reset_sidecar_publication:
        move.w  #0xffff,(%a0)
        subq.l  #1,%d1
        move.w  %d1,GK_DESC_ROOTS(%a3)
.Lgk_audio_command_reset_restore:
        move.w  GK_RESET_FRAME_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d3/%a0-%a3
        lea     GK_RESET_FRAME_SIZE(%sp),%sp
        st      %d2
        .global gk_stock_audio_command_track_reset_pair_jump
gk_stock_audio_command_track_reset_pair_jump:
        jmp     GK_STOCK_AUDIO_COMMAND_TRACK_RESET_PAIR_CONTINUE
        .size   gk_stock_audio_command_track_reset_pair,.-gk_stock_audio_command_track_reset_pair
        .global gk_stock_sequencer_track_reset_pair
        .type   gk_stock_sequencer_track_reset_pair,@function
gk_stock_sequencer_track_reset_pair:
        lea     -GK_RESET_FRAME_SIZE(%sp),%sp
        movem.l %d0-%d3/%a0-%a3,(%sp)
        move.w  %sr,%d0
        move.w  %d0,GK_RESET_FRAME_SR(%sp)
        move.l  (%sp),%d3
        cmpi.b  #0xff,%d3
        bne.w   gk_pair_invalidate_fatal
        cmpi.l  #32,%d2
        bne.w   gk_pair_invalidate_fatal
        move.l  %a1,%d2
        subi.l  #GK_STOCK_SEQUENCER_TRACK_STATE_BASE,%d2
        cmpi.l  #GK_SIDECAR_SEQUENCER_TRACK_COUNT - 1,%d2
        bhi.w   gk_pair_invalidate_fatal
        cmp.l   %d1,%d2
        bne.w   gk_pair_invalidate_fatal
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_sequencer_reset_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_pair_invalidate_fatal
        move.l  #GK_ID_NONE,%d3
        bra.w   .Lgk_sequencer_reset_stock
.Lgk_sequencer_reset_active:
        add.l   %d2,%d2
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a2
        adda.l  %d2,%a2
        .global gk_sequencer_track_reset_atomic_begin
gk_sequencer_track_reset_atomic_begin:
        move.w  #0x2700,%sr
        tst.l   __gk_lifecycle_state
        bne.w   gk_pair_invalidate_fatal
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   gk_pair_invalidate_fatal
        moveq   #0,%d3
        move.b  GK_SIDECAR_CURRENT(%a2),%d3
        cmpi.l  #GK_ID_NONE,%d3
        beq.s   .Lgk_sequencer_reset_stock
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w   gk_pair_invalidate_fatal
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        btst    #0,GK_DESC_FLAGS(%a3)
        beq.w   gk_pair_invalidate_fatal
        moveq   #0,%d2
        move.w  GK_DESC_ROOTS(%a3),%d2
        tst.l   %d2
        beq.w   gk_pair_invalidate_fatal
.Lgk_sequencer_reset_stock:
        move.l  (%sp),%d0
        .global gk_sequencer_track_reset_stock_bank
gk_sequencer_track_reset_stock_bank:
        .incbin "stock/0112.bin", 0, 4
        .global gk_sequencer_track_reset_stock_part
gk_sequencer_track_reset_stock_part:
        .incbin "stock/0112.bin", 4, 4
        cmpi.l  #GK_ID_NONE,%d3
        beq.s   .Lgk_sequencer_reset_restore
        movea.l %a2,%a0
        .global gk_sequencer_track_reset_sidecar_publication
gk_sequencer_track_reset_sidecar_publication:
        move.w  #0xffff,(%a0)
        subq.l  #1,%d2
        move.w  %d2,GK_DESC_ROOTS(%a3)
.Lgk_sequencer_reset_restore:
        move.w  GK_RESET_FRAME_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d3/%a0-%a3
        lea     GK_RESET_FRAME_SIZE(%sp),%sp
        tst.b   %d0
        .global gk_stock_sequencer_track_reset_pair_jump
gk_stock_sequencer_track_reset_pair_jump:
        jmp     GK_STOCK_SEQUENCER_TRACK_RESET_PAIR_CONTINUE
        .size   gk_stock_sequencer_track_reset_pair,.-gk_stock_sequencer_track_reset_pair
        .global gk_pair_invalidate_fatal
gk_pair_invalidate_fatal:
        illegal
        bra.s   gk_pair_invalidate_fatal
