        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_track_store_abort_fatal,@function
gk_track_store_abort_fatal:
        bsr.w   gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_track_store_fatal
        bra.w   gk_track_store_fatal
        .size   gk_track_store_abort_fatal,.-gk_track_store_abort_fatal
        .type   gk_track_store_release_abort_fatal,@function
gk_track_store_release_abort_fatal:
        move.l  %d2,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_store_fatal
        bra.w   gk_track_store_abort_fatal
        .size   gk_track_store_release_abort_fatal,.-gk_track_store_release_abort_fatal
        .global gk_stock_midi_track_part_store
        .type   gk_stock_midi_track_part_store,@function
gk_stock_midi_track_part_store:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_midi_track_store_active
        bra.w   gk_track_store_fatal
.Lgk_midi_track_store_active:
        .incbin "stock/0192.bin", 0, 4
        .incbin "stock/0192.bin", 4, 4
        movea.l 48(%sp),%a2
        move.l  52(%sp),%d5
        move.l  56(%sp),%d6
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_MIDI_TRACK_UNDO_RETURN,%d0
        beq.s   .Lgk_midi_track_store_undo
        cmpi.l  #GK_STOCK_MIDI_TRACK_PASTE_RETURN,%d0
        bne.w   gk_track_store_fatal
        cmpa.l  #GK_STOCK_TRACK_PASTE_BUFFER,%a2
        bne.w   gk_track_store_fatal
        bra.s   .Lgk_midi_track_store_caller_ok
.Lgk_midi_track_store_undo:
        cmpa.l  #GK_STOCK_TRACK_UNDO_BUFFER,%a2
        bne.w   gk_track_store_fatal
.Lgk_midi_track_store_caller_ok:
        tst.l   GK_STOCK_TRACK_MODE
        beq.w   gk_track_store_fatal
        cmpi.l  #15,%d5
        bhi.w   gk_track_store_fatal
        cmpi.l  #7,%d6
        bhi.w   gk_track_store_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmp.l   %d6,%d0
        bne.w   gk_track_store_fatal
        bsr.w   gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_track_store_fatal
        move.l  %d0,%d4
        cmp.l   %d5,%d1
        bne.w   gk_track_store_fatal
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        moveq   #0,%d3
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d3
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        bsr.w   gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_track_store_fatal
        cmp.l   %d7,%d0
        bne.w   gk_track_store_abort_fatal
        moveq   #0,%d3
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d3
        cmp.l   %d3,%d1
        bne.w   gk_track_store_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %d3,%d1
        bsr.w   gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_track_store_abort_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   gk_track_store_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_track_store_release_abort_fatal
        move.l  %d6,-(%sp)
        move.l  %d5,-(%sp)
        move.l  %a2,-(%sp)
        .global gk_midi_track_store_stock_call
gk_midi_track_store_stock_call:
        bsr.w   gk_stock_midi_track_part_store_trampoline
        lea     12(%sp),%sp
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        bsr.w   gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_track_store_fatal
        bsr.w   gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_track_store_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d3,%d2
        bsr.w   gk_stock_engine_context_validate
        tst.l   %d0
        bne.w   gk_track_store_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_store_fatal
        .incbin "stock/0193.bin", 0, 4
        .incbin "stock/0193.bin", 4, 4
        .incbin "stock/0193.bin", 8, 2
        .size   gk_stock_midi_track_part_store,.-gk_stock_midi_track_part_store
        .global gk_stock_midi_track_part_store_trampoline
        .type   gk_stock_midi_track_part_store_trampoline,@function
gk_stock_midi_track_part_store_trampoline:
        .incbin "stock/0194.bin", 0, 4
        .incbin "stock/0194.bin", 4, 4
        .global gk_stock_midi_track_part_store_trampoline_jump
gk_stock_midi_track_part_store_trampoline_jump:
        jmp     GK_STOCK_MIDI_TRACK_PART_STORE_CONTINUE
        .size   gk_stock_midi_track_part_store_trampoline,.-gk_stock_midi_track_part_store_trampoline
        .global gk_stock_audio_track_part_store
        .type   gk_stock_audio_track_part_store,@function
gk_stock_audio_track_part_store:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_audio_track_store_active
        bra.w   gk_track_store_fatal
.Lgk_audio_track_store_active:
        .incbin "stock/0195.bin", 0, 4
        .incbin "stock/0195.bin", 4, 4
        movea.l 48(%sp),%a2
        move.l  52(%sp),%d5
        move.l  56(%sp),%d6
        move.l  44(%sp),%d0
        cmpi.l  #GK_STOCK_AUDIO_TRACK_UNDO_RETURN,%d0
        beq.s   .Lgk_audio_track_store_undo
        cmpi.l  #GK_STOCK_AUDIO_TRACK_PASTE_RETURN,%d0
        bne.w   gk_track_store_fatal
        cmpa.l  #GK_STOCK_TRACK_PASTE_BUFFER,%a2
        bne.w   gk_track_store_fatal
        bra.s   .Lgk_audio_track_store_caller_ok
.Lgk_audio_track_store_undo:
        cmpa.l  #GK_STOCK_TRACK_UNDO_BUFFER,%a2
        bne.w   gk_track_store_fatal
.Lgk_audio_track_store_caller_ok:
        tst.l   GK_STOCK_TRACK_MODE
        bne.w   gk_track_store_fatal
        cmpi.l  #15,%d5
        bhi.w   gk_track_store_fatal
        cmpi.l  #7,%d6
        bhi.w   gk_track_store_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        cmp.l   %d6,%d0
        bne.w   gk_track_store_fatal
        bsr.w   gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_track_store_fatal
        move.l  %d0,%d4
        cmp.l   %d5,%d1
        bne.w   gk_track_store_fatal
        moveq   #0,%d7
        move.b  __gk_workspace_descriptor,%d7
        moveq   #0,%d3
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d3
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        bsr.w   gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_track_store_fatal
        cmp.l   %d7,%d0
        bne.w   gk_track_store_abort_fatal
        moveq   #0,%d3
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d3
        cmp.l   %d3,%d1
        bne.w   gk_track_store_abort_fatal
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %d3,%d1
        bsr.w   gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_track_store_abort_fatal
        move.l  %d0,%d2
        cmp.l   %d7,%d0
        bne.w   gk_track_store_release_abort_fatal
        cmpa.l  %a3,%a0
        bne.w   gk_track_store_release_abort_fatal
        move.l  %d6,-(%sp)
        move.l  %d5,-(%sp)
        move.l  %a2,-(%sp)
        .global gk_audio_track_store_stock_call
gk_audio_track_store_stock_call:
        bsr.w   gk_stock_audio_track_part_store_trampoline
        lea     12(%sp),%sp
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        bsr.w   gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_track_store_fatal
        bsr.w   gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_track_store_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d3,%d2
        bsr.w   gk_stock_engine_context_validate
        tst.l   %d0
        bne.w   gk_track_store_fatal
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_track_store_fatal
        .incbin "stock/0196.bin", 0, 4
        .incbin "stock/0196.bin", 4, 4
        .incbin "stock/0196.bin", 8, 2
        .size   gk_stock_audio_track_part_store,.-gk_stock_audio_track_part_store
        .global gk_stock_audio_track_part_store_trampoline
        .type   gk_stock_audio_track_part_store_trampoline,@function
gk_stock_audio_track_part_store_trampoline:
        .incbin "stock/0197.bin", 0, 4
        .incbin "stock/0197.bin", 4, 4
        .global gk_stock_audio_track_part_store_trampoline_jump
gk_stock_audio_track_part_store_trampoline_jump:
        jmp     GK_STOCK_AUDIO_TRACK_PART_STORE_CONTINUE
        .size   gk_stock_audio_track_part_store_trampoline,.-gk_stock_audio_track_part_store_trampoline
        .global gk_track_store_fatal
gk_track_store_fatal:
        illegal
        bra.s   gk_track_store_fatal
