        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_lfo_store_abort_fatal,@function
gk_lfo_store_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_lfo_store_fatal
        bra.w   gk_lfo_store_fatal
        .size   gk_lfo_store_abort_fatal,.-gk_lfo_store_abort_fatal
        .type   gk_lfo_store_release_abort_fatal,@function
gk_lfo_store_release_abort_fatal:
        move.l  %d2,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_lfo_store_fatal
        bra.w   gk_lfo_store_abort_fatal
        .size   gk_lfo_store_release_abort_fatal,.-gk_lfo_store_release_abort_fatal
        .global gk_stock_lfo_store
        .type   gk_stock_lfo_store,@function
gk_stock_lfo_store:
        tst.l   __gk_lifecycle_state
        bne.w   gk_lfo_store_fatal
        .incbin "stock/0246.bin", 0, 4
        .incbin "stock/0246.bin", 4, 4
        movea.l 48(%sp),%a2
        movea.l 52(%sp),%a5
        movea.l 56(%sp),%a4
        movea.l 60(%sp),%a6
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_LFO_PASTE_RETURN,%d0
        beq.s   .Lgk_lfo_store_paste
        cmpi.l  #GK_STOCK_LFO_UNDO_RETURN,%d0
        bne.w   gk_lfo_store_fatal
        cmpa.l  #GK_STOCK_LFO_UNDO_BUFFER,%a2
        bne.w   gk_lfo_store_fatal
        move.l  GK_STOCK_LFO_UNDO_TAG,%d0
        cmpi.l  #0x16,%d0
        bne.w   gk_lfo_store_fatal
        move.l  GK_STOCK_LFO_UNDO_COMMAND,%d0
        cmpi.l  #0x27,%d0
        beq.s   .Lgk_lfo_store_undo_command_ok
        cmpi.l  #0x28,%d0
        bne.w   gk_lfo_store_fatal
.Lgk_lfo_store_undo_command_ok:
        move.l  GK_STOCK_LFO_UNDO_TRACK,%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        move.l  GK_STOCK_LFO_UNDO_PART,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        move.l  GK_STOCK_LFO_UNDO_MODE,%d0
        move.l  %a6,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        moveq   #1,%d6
        bra.s   .Lgk_lfo_store_caller_ok
.Lgk_lfo_store_paste:
        cmpa.l  #GK_STOCK_LFO_PASTE_BUFFER,%a2
        bne.w   gk_lfo_store_fatal
        move.l  GK_STOCK_LFO_PASTE_TAG,%d0
        cmpi.l  #0x16,%d0
        bne.w   gk_lfo_store_fatal
        moveq   #0,%d6
.Lgk_lfo_store_caller_ok:
        move.l  %a5,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_lfo_store_fatal
        move.l  %a4,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_lfo_store_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        move.l  GK_STOCK_TRACK_MODE,%d0
        move.l  %a6,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_lfo_store_fatal
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
        bmi.w   gk_lfo_store_fatal
        cmp.l   %d7,%d0
        bne.w   gk_lfo_store_abort_fatal
        move.l  %a5,%d2
        cmp.l   %d2,%d1
        bne.w   gk_lfo_store_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %a5,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_lfo_store_abort_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   gk_lfo_store_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_lfo_store_release_abort_fatal
        move.l  %d7,%d0
        andi.l  #0xff,%d0
        ori.l   #GK_LFO_STORE_TOKEN_ARMED,%d0
        move.l  %d0,-(%sp)
        move.l  %a6,-(%sp)
        move.l  %a4,-(%sp)
        move.l  %a5,-(%sp)
        move.l  %a2,-(%sp)
        .global gk_lfo_store_stock_call
gk_lfo_store_stock_call:
        bsr.w   gk_stock_lfo_store_trampoline
        lea     20(%sp),%sp
        tst.l   %d6
        bne.s   .Lgk_lfo_store_post_undo
        move.l  GK_STOCK_LFO_PASTE_TAG,%d0
        cmpi.l  #0x16,%d0
        bne.w   gk_lfo_store_fatal
        bra.s   .Lgk_lfo_store_post_source_ok
.Lgk_lfo_store_post_undo:
        move.l  GK_STOCK_LFO_UNDO_TAG,%d0
        cmpi.l  #0x16,%d0
        bne.w   gk_lfo_store_fatal
.Lgk_lfo_store_post_source_ok:
        move.l  GK_STOCK_TRACK_MODE,%d0
        move.l  %a6,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a5,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_lfo_store_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_lfo_store_fatal
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_lfo_store_fatal
        cmp.l   %d4,%d0
        bne.w   gk_lfo_store_fatal
        cmp.l   %d5,%d1
        bne.w   gk_lfo_store_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_store_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_lfo_store_fatal
        .incbin "stock/0247.bin", 0, 4
        .incbin "stock/0247.bin", 4, 4
        .incbin "stock/0247.bin", 8, 2
        .size   gk_stock_lfo_store,.-gk_stock_lfo_store
        .global gk_stock_lfo_store_trampoline
        .type   gk_stock_lfo_store_trampoline,@function
gk_stock_lfo_store_trampoline:
        .incbin "stock/0248.bin", 0, 4
        .incbin "stock/0248.bin", 4, 4
        .global gk_stock_lfo_store_trampoline_jump
gk_stock_lfo_store_trampoline_jump:
        jmp     GK_STOCK_LFO_STORE_CONTINUE
        .size   gk_stock_lfo_store_trampoline,.-gk_stock_lfo_store_trampoline
        .global gk_lfo_store_identity_match
        .type   gk_lfo_store_identity_match,@function
gk_lfo_store_identity_match:
        cmpi.l  #7,%d0
        bhi.w   gk_lfo_store_fatal
        move.l  %d1,%d2
        andi.l  #0xffffff00,%d2
        cmpi.l  #GK_LFO_STORE_TOKEN_ARMED,%d2
        bne.w   gk_lfo_store_fatal
        andi.l  #0xff,%d1
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.w   gk_lfo_store_fatal
        add.l   %d0,%d0
        adda.l  %d0,%a0
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        .global gk_lfo_store_identity_snapshot
gk_lfo_store_identity_snapshot:
        move.w  (%a0),%d0
        move.w  %d2,%sr
        move.l  %d1,%d2
        lsl.l   #8,%d2
        ori.l   #0xff,%d2
        cmp.l   %d2,%d0
        seq     %d0
        andi.l  #1,%d0
        rts
        .size   gk_lfo_store_identity_match,.-gk_lfo_store_identity_match
        .global gk_stock_lfo_midi_block_compare
        .type   gk_stock_lfo_midi_block_compare,@function
gk_stock_lfo_midi_block_compare:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        cmpi.l  #7,%d2
        bhi.w   gk_lfo_store_fatal
        move.l  %d2,%d0
        lea     GK_STOCK_SEQUENCER_TRACK_BANKS,%a0
        adda.l  %d0,%a0
        cmpa.l  %a1,%a0
        bne.w   gk_lfo_store_fatal
        move.l  %d2,%d0
        move.l  92(%sp),%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        bsr.w   gk_lfo_store_identity_match
        tst.l   %d0
        beq.s   .Lgk_lfo_midi_block_miss
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        mvs.b   (%a1),%d0
        cmp.l   %d0,%d7
        bne.w   gk_lfo_store_fatal
        mvs.b   8(%a1),%d0
        cmp.l   %d0,%d5
        bne.w   gk_lfo_store_fatal
        jmp     GK_STOCK_LFO_MIDI_BLOCK_MATCH
.Lgk_lfo_midi_block_miss:
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        jmp     GK_STOCK_LFO_MIDI_BLOCK_MISS
        .size   gk_stock_lfo_midi_block_compare,.-gk_stock_lfo_midi_block_compare
        .global gk_stock_lfo_audio_block_compare
        .type   gk_stock_lfo_audio_block_compare,@function
gk_stock_lfo_audio_block_compare:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        cmpi.l  #7,%d2
        bhi.w   gk_lfo_store_fatal
        move.l  %d2,%d0
        lea     GK_STOCK_ENGINE_TRACK_BANKS,%a0
        adda.l  %d0,%a0
        cmpa.l  %a1,%a0
        bne.w   gk_lfo_store_fatal
        move.l  %d2,%d0
        move.l  92(%sp),%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        bsr.w   gk_lfo_store_identity_match
        tst.l   %d0
        beq.s   .Lgk_lfo_audio_block_miss
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        mvz.b   (%a1),%d0
        cmp.l   %d0,%d7
        bne.w   gk_lfo_store_fatal
        mvz.b   8(%a1),%d0
        cmp.l   %d0,%d5
        bne.w   gk_lfo_store_fatal
        jmp     GK_STOCK_LFO_AUDIO_BLOCK_MATCH
.Lgk_lfo_audio_block_miss:
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        jmp     GK_STOCK_LFO_AUDIO_BLOCK_MISS
        .size   gk_stock_lfo_audio_block_compare,.-gk_stock_lfo_audio_block_compare
        .global gk_stock_lfo_midi_depth_compare
        .type   gk_stock_lfo_midi_depth_compare,@function
gk_stock_lfo_midi_depth_compare:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        cmpi.l  #7,%d2
        bhi.w   gk_lfo_store_fatal
        move.l  %d2,%d0
        lea     GK_STOCK_SEQUENCER_TRACK_BANKS,%a0
        adda.l  %d0,%a0
        cmpa.l  %a3,%a0
        bne.w   gk_lfo_store_fatal
        move.l  %d2,%d0
        move.l  92(%sp),%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        bsr.w   gk_lfo_store_identity_match
        tst.l   %d0
        beq.s   .Lgk_lfo_midi_depth_miss
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        mvs.b   (%a3),%d0
        cmp.l   %d0,%d7
        bne.w   gk_lfo_store_fatal
        mvs.b   8(%a3),%d0
        cmp.l   %d0,%d5
        bne.w   gk_lfo_store_fatal
        jmp     GK_STOCK_LFO_MIDI_DEPTH_MATCH
.Lgk_lfo_midi_depth_miss:
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        jmp     GK_STOCK_LFO_MIDI_DEPTH_MISS
        .size   gk_stock_lfo_midi_depth_compare,.-gk_stock_lfo_midi_depth_compare
        .global gk_stock_lfo_audio_depth_compare
        .type   gk_stock_lfo_audio_depth_compare,@function
gk_stock_lfo_audio_depth_compare:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        cmpi.l  #7,%d2
        bhi.w   gk_lfo_store_fatal
        move.l  %d2,%d0
        lea     GK_STOCK_ENGINE_TRACK_BANKS,%a0
        adda.l  %d0,%a0
        cmpa.l  %a3,%a0
        bne.w   gk_lfo_store_fatal
        move.l  %d2,%d0
        move.l  92(%sp),%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        bsr.w   gk_lfo_store_identity_match
        tst.l   %d0
        beq.s   .Lgk_lfo_audio_depth_miss
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        mvz.b   (%a3),%d0
        cmp.l   %d0,%d6
        bne.w   gk_lfo_store_fatal
        mvz.b   8(%a3),%d0
        cmp.l   %d0,%d5
        bne.w   gk_lfo_store_fatal
        jmp     GK_STOCK_LFO_AUDIO_DEPTH_MATCH
.Lgk_lfo_audio_depth_miss:
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        jmp     GK_STOCK_LFO_AUDIO_DEPTH_MISS
        .size   gk_stock_lfo_audio_depth_compare,.-gk_stock_lfo_audio_depth_compare
        .global gk_lfo_store_fatal
gk_lfo_store_fatal:
        illegal
        bra.s   gk_lfo_store_fatal
