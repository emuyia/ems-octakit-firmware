        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_lfo_parameter_abort_fatal,@function
gk_lfo_parameter_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_lfo_parameter_fatal
        bra.w   gk_lfo_parameter_fatal
        .size   gk_lfo_parameter_abort_fatal,.-gk_lfo_parameter_abort_fatal
        .type   gk_lfo_parameter_release_abort_fatal,@function
gk_lfo_parameter_release_abort_fatal:
        move.l  %d2,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_lfo_parameter_fatal
        bra.w   gk_lfo_parameter_abort_fatal
        .size   gk_lfo_parameter_release_abort_fatal,.-gk_lfo_parameter_release_abort_fatal
        .global gk_stock_lfo_depth_write
        .type   gk_stock_lfo_depth_write,@function
gk_stock_lfo_depth_write:
        tst.l   __gk_lifecycle_state
        bne.w   gk_lfo_parameter_fatal
        .incbin "stock/0240.bin", 0, 4
        .incbin "stock/0240.bin", 4, 4
        movea.l 48(%sp),%a6
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_LFO_DEPTH_RETURN_TOGGLE,%d0
        beq.s   .Lgk_lfo_depth_caller_ok
        cmpi.l  #GK_STOCK_LFO_DEPTH_RETURN_SHIFT,%d0
        beq.s   .Lgk_lfo_depth_caller_ok
        cmpi.l  #GK_STOCK_LFO_DEPTH_RETURN_RANDOM,%d0
        beq.s   .Lgk_lfo_depth_caller_ok
        cmpi.l  #GK_STOCK_LFO_DEPTH_RETURN_MASK_CLEAR,%d0
        beq.s   .Lgk_lfo_depth_caller_ok
        cmpi.l  #GK_STOCK_LFO_DEPTH_RETURN_FULL_CLEAR,%d0
        bne.w   gk_lfo_parameter_fatal
.Lgk_lfo_depth_caller_ok:
        move.l  %a6,%d0
        andi.l  #0xffff0000,%d0
        bne.w   gk_lfo_parameter_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_lfo_parameter_fatal
        movea.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_lfo_parameter_fatal
        movea.l %d0,%a5
        move.l  GK_STOCK_TRACK_MODE,%d6
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_lfo_parameter_fatal
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
        bmi.w   gk_lfo_parameter_fatal
        cmp.l   %d7,%d0
        bne.w   gk_lfo_parameter_abort_fatal
        move.l  %a5,%d2
        cmp.l   %d2,%d1
        bne.w   gk_lfo_parameter_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %a5,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_lfo_parameter_abort_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   gk_lfo_parameter_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_lfo_parameter_release_abort_fatal
        move.l  %d7,%d0
        andi.l  #0xff,%d0
        ori.l   #GK_LFO_PARAMETER_TOKEN_ARMED,%d0
        move.l  %d0,-(%sp)
        move.l  %a6,-(%sp)
        .global gk_lfo_depth_stock_call
gk_lfo_depth_stock_call:
        bsr.w   gk_stock_lfo_depth_write_trampoline
        lea     8(%sp),%sp
        move.l  GK_STOCK_TRACK_MODE,%d0
        cmp.l   %d6,%d0
        bne.w   gk_lfo_parameter_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_parameter_fatal
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a5,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_lfo_parameter_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_lfo_parameter_fatal
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_lfo_parameter_fatal
        cmp.l   %d4,%d0
        bne.w   gk_lfo_parameter_fatal
        cmp.l   %d5,%d1
        bne.w   gk_lfo_parameter_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_parameter_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_lfo_parameter_fatal
        .incbin "stock/0241.bin", 0, 4
        .incbin "stock/0241.bin", 4, 4
        .incbin "stock/0241.bin", 8, 2
        .size   gk_stock_lfo_depth_write,.-gk_stock_lfo_depth_write
        .global gk_stock_lfo_depth_write_trampoline
        .type   gk_stock_lfo_depth_write_trampoline,@function
gk_stock_lfo_depth_write_trampoline:
        .incbin "stock/0242.bin", 0, 4
        .incbin "stock/0242.bin", 4, 4
        .global gk_stock_lfo_depth_write_trampoline_jump
gk_stock_lfo_depth_write_trampoline_jump:
        jmp     GK_STOCK_LFO_DEPTH_WRITE_CONTINUE
        .size   gk_stock_lfo_depth_write_trampoline,.-gk_stock_lfo_depth_write_trampoline
        .global gk_stock_lfo_block_write
        .type   gk_stock_lfo_block_write,@function
gk_stock_lfo_block_write:
        move.l  %d0,-(%sp)
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_LFO_DESIGNER_NESTED_SINGLE_RETURN,%d0
        beq.s   .Lgk_lfo_block_designer_nested
        cmpi.l  #GK_STOCK_LFO_DESIGNER_NESTED_LOOP_RETURN,%d0
        beq.s   .Lgk_lfo_block_designer_nested
        move.l  (%sp)+,%d0
        bra.s   .Lgk_lfo_block_designer_checked
.Lgk_lfo_block_designer_nested:
        move.l  (%sp)+,%d0
        jmp     gk_lfo_designer_nested_block_write
.Lgk_lfo_block_designer_checked:
        tst.l   __gk_lifecycle_state
        bne.w   gk_lfo_parameter_fatal
        .incbin "stock/0243.bin", 0, 4
        .incbin "stock/0243.bin", 4, 4
        movea.l 48(%sp),%a6
        movea.l 52(%sp),%a2
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_LFO_BLOCK_RETURN_SHIFT_LEFT,%d0
        beq.s   .Lgk_lfo_block_caller_ok
        cmpi.l  #GK_STOCK_LFO_BLOCK_RETURN_SHIFT_RIGHT,%d0
        beq.s   .Lgk_lfo_block_caller_ok
        cmpi.l  #GK_STOCK_LFO_BLOCK_RETURN_SHIFT_EDGE,%d0
        beq.s   .Lgk_lfo_block_caller_ok
        cmpi.l  #GK_STOCK_LFO_BLOCK_RETURN_INVERT,%d0
        beq.s   .Lgk_lfo_block_caller_ok
        cmpi.l  #GK_STOCK_LFO_BLOCK_RETURN_RANDOM,%d0
        beq.s   .Lgk_lfo_block_caller_ok
        cmpi.l  #GK_STOCK_LFO_BLOCK_RETURN_MASK_CLEAR,%d0
        beq.s   .Lgk_lfo_block_caller_ok
        cmpi.l  #GK_STOCK_LFO_BLOCK_RETURN_FULL_CLEAR,%d0
        bne.w   gk_lfo_parameter_fatal
.Lgk_lfo_block_caller_ok:
        move.l  %a6,%d0
        cmpi.l  #15,%d0
        bhi.w   gk_lfo_parameter_fatal
        move.l  %a2,%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_lfo_block_negative
        tst.l   %d1
        bne.w   gk_lfo_parameter_fatal
        bra.s   .Lgk_lfo_block_value_ok
.Lgk_lfo_block_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_lfo_parameter_fatal
.Lgk_lfo_block_value_ok:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_lfo_parameter_fatal
        movea.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_lfo_parameter_fatal
        movea.l %d0,%a5
        move.l  GK_STOCK_TRACK_MODE,%d6
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_lfo_parameter_fatal
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
        bmi.w   gk_lfo_parameter_fatal
        cmp.l   %d7,%d0
        bne.w   gk_lfo_parameter_abort_fatal
        move.l  %a5,%d2
        cmp.l   %d2,%d1
        bne.w   gk_lfo_parameter_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %a5,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_lfo_parameter_abort_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   gk_lfo_parameter_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_lfo_parameter_release_abort_fatal
        move.l  %d7,%d0
        andi.l  #0xff,%d0
        ori.l   #GK_LFO_PARAMETER_TOKEN_ARMED,%d0
        move.l  %d0,-(%sp)
        move.l  %a2,-(%sp)
        move.l  %a6,-(%sp)
        .global gk_lfo_block_stock_call
gk_lfo_block_stock_call:
        bsr.w   gk_stock_lfo_block_write_trampoline
        lea     12(%sp),%sp
        move.l  GK_STOCK_TRACK_MODE,%d0
        cmp.l   %d6,%d0
        bne.w   gk_lfo_parameter_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        move.l  %a4,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_parameter_fatal
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a5,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_lfo_parameter_fatal
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_lfo_parameter_fatal
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_lfo_parameter_fatal
        cmp.l   %d4,%d0
        bne.w   gk_lfo_parameter_fatal
        cmp.l   %d5,%d1
        bne.w   gk_lfo_parameter_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        move.l  %a5,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_parameter_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_lfo_parameter_fatal
        .incbin "stock/0244.bin", 0, 4
        .incbin "stock/0244.bin", 4, 4
        .incbin "stock/0244.bin", 8, 2
        .size   gk_stock_lfo_block_write,.-gk_stock_lfo_block_write
        .global gk_stock_lfo_block_write_trampoline
        .type   gk_stock_lfo_block_write_trampoline,@function
gk_stock_lfo_block_write_trampoline:
        .incbin "stock/0245.bin", 0, 4
        .incbin "stock/0245.bin", 4, 4
        .global gk_stock_lfo_block_write_trampoline_jump
gk_stock_lfo_block_write_trampoline_jump:
        jmp     GK_STOCK_LFO_BLOCK_WRITE_CONTINUE
        .size   gk_stock_lfo_block_write_trampoline,.-gk_stock_lfo_block_write_trampoline
        .global gk_lfo_parameter_identity_match
        .type   gk_lfo_parameter_identity_match,@function
gk_lfo_parameter_identity_match:
        cmpi.l  #7,%d0
        bhi.w   gk_lfo_parameter_fatal
        move.l  %d1,%d2
        andi.l  #0xffffff00,%d2
        cmpi.l  #GK_LFO_PARAMETER_TOKEN_ARMED,%d2
        bne.w   gk_lfo_parameter_fatal
        andi.l  #0xff,%d1
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.w   gk_lfo_parameter_fatal
        add.l   %d0,%d0
        adda.l  %d0,%a0
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d0
        .global gk_lfo_parameter_identity_snapshot
gk_lfo_parameter_identity_snapshot:
        move.w  (%a0),%d0
        move.w  %d2,%sr
        move.l  %d1,%d2
        lsl.l   #8,%d2
        ori.l   #0xff,%d2
        cmp.l   %d2,%d0
        seq     %d0
        andi.l  #1,%d0
        rts
        .size   gk_lfo_parameter_identity_match,.-gk_lfo_parameter_identity_match
        .global gk_stock_lfo_depth_midi_compare
        .type   gk_stock_lfo_depth_midi_compare,@function
gk_stock_lfo_depth_midi_compare:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        cmpi.l  #7,%d2
        bhi.w   gk_lfo_parameter_fatal
        move.l  %d2,%d0
        lea     GK_STOCK_SEQUENCER_TRACK_BANKS,%a0
        adda.l  %d0,%a0
        cmpa.l  %a1,%a0
        bne.w   gk_lfo_parameter_fatal
        move.l  %d2,%d0
        move.l  64(%sp),%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        bsr.w   gk_lfo_parameter_identity_match
        tst.l   %d0
        beq.s   .Lgk_lfo_depth_midi_miss
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        mvs.b   (%a1),%d0
        cmpa.l  %d0,%a2
        bne.w   gk_lfo_parameter_fatal
        mvs.b   8(%a1),%d0
        cmp.l   %d0,%d5
        bne.w   gk_lfo_parameter_fatal
        jmp     GK_STOCK_LFO_DEPTH_MIDI_MATCH
.Lgk_lfo_depth_midi_miss:
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        jmp     GK_STOCK_LFO_DEPTH_MIDI_MISS
        .size   gk_stock_lfo_depth_midi_compare,.-gk_stock_lfo_depth_midi_compare
        .global gk_stock_lfo_depth_audio_compare
        .type   gk_stock_lfo_depth_audio_compare,@function
gk_stock_lfo_depth_audio_compare:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        cmpi.l  #7,%d2
        bhi.w   gk_lfo_parameter_fatal
        move.l  %d2,%d0
        lea     GK_STOCK_ENGINE_TRACK_BANKS,%a0
        adda.l  %d0,%a0
        cmpa.l  %a1,%a0
        bne.w   gk_lfo_parameter_fatal
        move.l  %d2,%d0
        move.l  64(%sp),%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        bsr.w   gk_lfo_parameter_identity_match
        tst.l   %d0
        beq.s   .Lgk_lfo_depth_audio_miss
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        mvz.b   (%a1),%d0
        cmp.l   %d0,%d6
        bne.w   gk_lfo_parameter_fatal
        mvz.b   8(%a1),%d0
        cmp.l   %d0,%d4
        bne.w   gk_lfo_parameter_fatal
        jmp     GK_STOCK_LFO_DEPTH_AUDIO_MATCH
.Lgk_lfo_depth_audio_miss:
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        jmp     GK_STOCK_LFO_DEPTH_AUDIO_MISS
        .size   gk_stock_lfo_depth_audio_compare,.-gk_stock_lfo_depth_audio_compare
        .global gk_stock_lfo_block_midi_compare
        .type   gk_stock_lfo_block_midi_compare,@function
gk_stock_lfo_block_midi_compare:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        cmpi.l  #7,%d1
        bhi.w   gk_lfo_parameter_fatal
        move.l  %d1,%d0
        lea     GK_STOCK_SEQUENCER_TRACK_BANKS,%a0
        adda.l  %d0,%a0
        cmpa.l  %a2,%a0
        bne.w   gk_lfo_parameter_fatal
        move.l  %d1,%d0
        move.l  68(%sp),%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_TRACK_OFFSET,%a0
        bsr.w   gk_lfo_parameter_identity_match
        tst.l   %d0
        beq.s   .Lgk_lfo_block_midi_miss
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        mvs.b   (%a2),%d0
        cmp.l   %d0,%d7
        bne.w   gk_lfo_parameter_fatal
        mvs.b   8(%a2),%d0
        cmp.l   %d0,%d4
        bne.w   gk_lfo_parameter_fatal
        jmp     GK_STOCK_LFO_BLOCK_MIDI_MATCH
.Lgk_lfo_block_midi_miss:
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        jmp     GK_STOCK_LFO_BLOCK_MIDI_MISS
        .size   gk_stock_lfo_block_midi_compare,.-gk_stock_lfo_block_midi_compare
        .global gk_stock_lfo_block_audio_compare
        .type   gk_stock_lfo_block_audio_compare,@function
gk_stock_lfo_block_audio_compare:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        cmpi.l  #7,%d2
        bhi.w   gk_lfo_parameter_fatal
        move.l  %d2,%d0
        lea     GK_STOCK_ENGINE_TRACK_BANKS,%a0
        adda.l  %d0,%a0
        cmpa.l  %a1,%a0
        bne.w   gk_lfo_parameter_fatal
        move.l  %d2,%d0
        move.l  68(%sp),%d1
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_AUDIO_OFFSET,%a0
        bsr.w   gk_lfo_parameter_identity_match
        tst.l   %d0
        beq.s   .Lgk_lfo_block_audio_miss
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        mvz.b   (%a1),%d0
        cmp.l   %d0,%d6
        bne.w   gk_lfo_parameter_fatal
        mvz.b   8(%a1),%d0
        cmp.l   %d0,%d4
        bne.w   gk_lfo_parameter_fatal
        jmp     GK_STOCK_LFO_BLOCK_AUDIO_MATCH
.Lgk_lfo_block_audio_miss:
        movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        jmp     GK_STOCK_LFO_BLOCK_AUDIO_MISS
        .size   gk_stock_lfo_block_audio_compare,.-gk_stock_lfo_block_audio_compare
        .global gk_lfo_parameter_fatal
gk_lfo_parameter_fatal:
        illegal
        bra.s   gk_lfo_parameter_fatal
