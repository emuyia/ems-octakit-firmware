        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_sequencer_latch_begin
        .type   gk_sequencer_latch_begin,@function
gk_sequencer_latch_begin:
        .incbin "stock/0161.bin", 0, 4
        .incbin "stock/0161.bin", 4, 4
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        jsr     gk_sequencer_engine_acquire
        tst.l   %d0
        bmi.w   .Lgk_latch_begin_restore
        move.l  %d0,%d7
        movea.l %a0,%a2
        suba.l  %a5,%a5
        bra.s   .Lgk_latch_begin_after_queue_mark
        .global gk_sequencer_latch_queue_mark
gk_sequencer_latch_queue_mark:
        moveq   #1,%d0
        movea.l %d0,%a5
        bra.w   .Lgk_latch_begin_queue_mark_continue
.Lgk_latch_begin_after_queue_mark:
        bra.s   .Lgk_latch_begin_after_current_validator
        .global gk_periodic_queue_handoff_current_validate
        .type   gk_periodic_queue_handoff_current_validate,@function
gk_periodic_queue_handoff_current_validate:
        move.w  GK_STOCK_SEQUENCER_CURRENT_BANK,%d6
        moveq   #0,%d7
        move.b  %d6,%d7
        lsr.l   #8,%d6
        bra.w   gk_audio_periodic_queue_handoff_validate
        .size   gk_periodic_queue_handoff_current_validate,.-gk_periodic_queue_handoff_current_validate
.Lgk_latch_begin_after_current_validator:
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d4
        move.b  __gk_current_bank,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d5
        move.b  __gk_current_pattern,%d5
        cmpi.l  #15,%d5
        bhi.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d6
        move.b  GK_STOCK_ENGINE_PART,%d6
        cmpi.l  #3,%d6
        bhi.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   gk_sequencer_latch_queue_mark
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d0
        cmp.l   %d5,%d0
        bne.w   gk_sequencer_latch_queue_mark
.Lgk_latch_begin_queue_mark_continue:
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        moveq   #0,%d3
        move.b  GK_DESC_FLAGS(%a3),%d3
        move.l  %d3,%d0
        andi.l  #0x80,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        btst    #0,%d3
        beq.w   .Lgk_latch_begin_release_corrupt
        btst    #2,%d3
        bne.w   .Lgk_latch_begin_release_corrupt
        btst    #3,%d3
        beq.w   .Lgk_latch_begin_release_corrupt
        cmpa.l  GK_DESC_PAYLOAD(%a3),%a2
        bne.w   .Lgk_latch_begin_release_corrupt
        tst.w   GK_DESC_ROOTS(%a3)
        beq.w   .Lgk_latch_begin_release_corrupt
        tst.w   GK_DESC_READERS(%a3)
        beq.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d2
        move.b  GK_DESC_PHYSICAL(%a3),%d2
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d2
        bhi.w   .Lgk_latch_begin_release_corrupt
        move.l  %d2,%d0
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        move.l  %d2,%d0
        andi.l  #3,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a3),%d0
        btst    #1,%d3
        bne.s   .Lgk_latch_begin_copy_metadata
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        tst.l   GK_DESC_CANDIDATE(%a3)
        bne.w   .Lgk_latch_begin_release_corrupt
        bra.s   .Lgk_latch_begin_payload_table
.Lgk_latch_begin_copy_metadata:
        tst.l   GK_DESC_CANDIDATE(%a3)
        beq.w   .Lgk_latch_begin_release_corrupt
.Lgk_latch_begin_payload_table:
        move.l  %d2,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  %a2,%a0
        bne.w   .Lgk_latch_begin_release_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a4
        adda.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a4),%d0
        cmp.l   %d7,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a4),%d0
        moveq   #0,%d1
        move.b  GK_DESC_KIT(%a3),%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        tst.b   GK_PHYS_STATE(%a4)
        bne.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a4),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        cmp.l   %d1,%d2
        bne.w   .Lgk_latch_begin_release_corrupt
        move.l  %d4,%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        move.l  %d5,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_latch_begin_release_corrupt
        tst.l   %a5
        bne.w   gk_sequencer_latch_queue_handoff_validate
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%a0
        move.l  %d7,%d0
        jsr     gk_selector_begin_update
        tst.l   %d0
        bne.s   .Lgk_latch_begin_release_status
        moveq   #GK_OK,%d0
        bra.s   .Lgk_latch_begin_restore
        .global gk_sequencer_latch_begin_release_corrupt
gk_sequencer_latch_begin_release_corrupt:
.Lgk_latch_begin_release_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        .global gk_sequencer_latch_begin_release_status
gk_sequencer_latch_begin_release_status:
.Lgk_latch_begin_release_status:
        move.l  %d0,%d6
        move.l  %d7,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_latch_begin_release_failed
        move.l  %d6,%d0
        bra.s   .Lgk_latch_begin_restore
.Lgk_latch_begin_release_failed:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_latch_begin_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
        .size   gk_sequencer_latch_begin,.-gk_sequencer_latch_begin
        .global gk_sequencer_latch_commit_part
        .type   gk_sequencer_latch_commit_part,@function
gk_sequencer_latch_commit_part:
        andi.l  #0xff,%d0
        cmpi.l  #3,%d0
        bhi.w   .Lgk_latch_commit_range
        lea     -28(%sp),%sp
        movem.l %d2-%d6/%a2-%a3,(%sp)
        move.l  %d0,%d6
        lea     __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%a0
        moveq   #0,%d2
        move.w  (%a0),%d2
        move.l  %d2,%d3
        andi.l  #0xff,%d3
        cmpi.l  #GK_ID_NONE,%d3
        beq.w   .Lgk_latch_commit_busy
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w   .Lgk_latch_commit_corrupt
        lsr.l   #8,%d2
        andi.l  #0xff,%d2
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0x84,%d1
        bne.w   .Lgk_latch_commit_corrupt
        btst    #0,%d0
        beq.w   .Lgk_latch_commit_corrupt
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_latch_commit_corrupt
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_latch_commit_corrupt
        tst.w   GK_DESC_READERS(%a2)
        beq.w   .Lgk_latch_commit_corrupt
        moveq   #0,%d4
        move.b  GK_STOCK_SEQUENCER_LATCH_BANK,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_latch_commit_corrupt
        lsl.l   #2,%d4
        add.l   %d6,%d4
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_latch_commit_corrupt
        move.l  %d4,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a1
        move.l  (%a1,%d0.l),%a1
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a1
        bne.w   .Lgk_latch_commit_corrupt
        move.l %d4,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a1
        adda.l %d0,%a1
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a1),%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_latch_commit_corrupt
        suba.l  %a3,%a3
        cmpi.l  #GK_ID_NONE,%d2
        beq.s   .Lgk_latch_commit_old_validated
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_latch_commit_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        btst    #0,GK_DESC_FLAGS(%a3)
        beq.w   .Lgk_latch_commit_corrupt
        btst    #2,GK_DESC_FLAGS(%a3)
        bne.w   .Lgk_latch_commit_corrupt
        tst.l   GK_DESC_PAYLOAD(%a3)
        beq.w   .Lgk_latch_commit_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a3),%d0
        tst.l   %d0
        beq.w   .Lgk_latch_commit_corrupt
        moveq   #0,%d1
        move.w  GK_DESC_READERS(%a3),%d1
        tst.l   %d1
        beq.w   .Lgk_latch_commit_corrupt
        cmp.l   %d3,%d2
        bne.s   .Lgk_latch_commit_old_validated
        cmpi.l  #2,%d0
        blo.w   .Lgk_latch_commit_corrupt
        cmpi.l  #2,%d1
        blo.w   .Lgk_latch_commit_corrupt
.Lgk_latch_commit_old_validated:
        move.w  %sr,%d5
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.w  (%a0),%d0
        move.l  %d2,%d1
        lsl.l   #8,%d1
        or.l    %d3,%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_latch_commit_masked_corrupt
        tst.w   GK_DESC_ROOTS(%a2)
        beq.s   .Lgk_latch_commit_masked_corrupt
        tst.w   GK_DESC_READERS(%a2)
        beq.s   .Lgk_latch_commit_masked_corrupt
        tst.l   %a3
        beq.s   .Lgk_latch_commit_publish
        tst.w   GK_DESC_ROOTS(%a3)
        beq.s   .Lgk_latch_commit_masked_corrupt
        tst.w   GK_DESC_READERS(%a3)
        beq.s   .Lgk_latch_commit_masked_corrupt
        .global gk_sequencer_latch_stock_part_publication
gk_sequencer_latch_stock_part_publication:
.Lgk_latch_commit_publish:
        move.b  %d6,GK_STOCK_SEQUENCER_LATCH_PART
        move.l  %d3,%d0
        lsl.l   #8,%d0
        ori.l   #0xff,%d0
        .global gk_sequencer_latch_sidecar_publication
gk_sequencer_latch_sidecar_publication:
        move.w  %d0,(%a0)
        tst.l   %a3
        beq.s   .Lgk_latch_commit_success
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a3),%d0
        subq.l  #1,%d0
        move.w  %d0,GK_DESC_ROOTS(%a3)
        moveq   #0,%d0
        move.w  GK_DESC_READERS(%a3),%d0
        subq.l  #1,%d0
        move.w  %d0,GK_DESC_READERS(%a3)
.Lgk_latch_commit_success:
        move.w  %d5,%sr
        moveq   #GK_OK,%d0
        bra.s   .Lgk_latch_commit_restore
.Lgk_latch_commit_masked_corrupt:
        move.w  %d5,%sr
.Lgk_latch_commit_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_latch_commit_restore
.Lgk_latch_commit_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_latch_commit_restore:
        movem.l (%sp),%d2-%d6/%a2-%a3
        lea     28(%sp),%sp
        rts
.Lgk_latch_commit_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_sequencer_latch_commit_part,.-gk_sequencer_latch_commit_part
        .global gk_audio_latch_ready
        .type   gk_audio_latch_ready,@function
gk_audio_latch_ready:
        tst.b   __gk_sequencer_latch_queue_handoff
        beq.s   .Lgk_audio_latch_ready_stable
        jmp     gk_pattern_queue_audio_handoff_ready
.Lgk_audio_latch_ready_stable:
        .incbin "stock/0162.bin", 0, 4
        .incbin "stock/0162.bin", 4, 4
        moveq   #0,%d2
        move.w  __gk_lease_sidecars + GK_SIDECAR_SEQUENCER_LATCH_OFFSET,%d2
        move.l  %d2,%d0
        andi.l  #0xff,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_audio_latch_not_ready
        moveq   #0,%d0
        move.w  __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_audio_latch_not_ready
        lsr.l   #8,%d2
        andi.l  #0xff,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_audio_latch_not_ready
        moveq   #0,%d3
        move.b  GK_STOCK_SEQUENCER_LATCH_BANK,%d3
        cmpi.l  #15,%d3
        bhi.w   .Lgk_audio_latch_not_ready
        moveq   #0,%d4
        move.b  GK_STOCK_SEQUENCER_LATCH_PART,%d4
        cmpi.l  #3,%d4
        bhi.w   .Lgk_audio_latch_not_ready
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_audio_latch_not_ready
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_audio_latch_not_ready
        lsl.l   #2,%d3
        add.l   %d4,%d3
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d5
        move.b  GK_DESC_FLAGS(%a2),%d5
        move.l  %d5,%d0
        andi.l  #0x84,%d0
        bne.s   .Lgk_audio_latch_not_ready
        btst    #0,%d5
        beq.s   .Lgk_audio_latch_not_ready
        tst.w   GK_DESC_ROOTS(%a2)
        beq.s   .Lgk_audio_latch_not_ready
        tst.w   GK_DESC_READERS(%a2)
        beq.s   .Lgk_audio_latch_not_ready
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmp.l   %d3,%d0
        bne.s   .Lgk_audio_latch_not_ready
        move.l  %d3,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.s   .Lgk_audio_latch_not_ready
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a0
        adda.l %d0,%a0
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a0),%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_audio_latch_not_ready
        move.l  %d2,%d0
        bra.s   .Lgk_audio_latch_restore
.Lgk_audio_latch_not_ready:
        moveq   #GK_ERR_UPDATING,%d0
.Lgk_audio_latch_restore:
        movem.l (%sp),%d2-%d5/%a2
        lea     20(%sp),%sp
        rts
        .size   gk_audio_latch_ready,.-gk_audio_latch_ready
        .global gk_audio_latch_store_byte
        .type   gk_audio_latch_store_byte,@function
gk_audio_latch_store_byte:
        move.l  %d3,-(%sp)
        move.l  %d1,%d3
        bsr.w   gk_audio_latch_ready
        tst.l   %d0
        bmi.s   .Lgk_audio_latch_store_restore
        move.l  %d3,%d1
        jsr     gk_descriptor_store_byte
.Lgk_audio_latch_store_restore:
        move.l  (%sp)+,%d3
        rts
        .size   gk_audio_latch_store_byte,.-gk_audio_latch_store_byte
        .global gk_stock_sequencer_latch_begin
        .type   gk_stock_sequencer_latch_begin,@function
gk_stock_sequencer_latch_begin:
        lea     -56(%sp),%sp
        movem.l %d0-%d3/%d5-%d7/%a0-%a6,(%sp)
        bsr.w   gk_sequencer_latch_begin
        tst.l   %d0
        bne.s   .Lgk_stock_latch_begin_unavailable
        movem.l (%sp),%d0-%d3/%d5-%d7/%a0-%a6
        lea     56(%sp),%sp
        .incbin "stock/0163.bin", 0, 2
        .incbin "stock/0163.bin", 2, 6
        jmp     GK_STOCK_SEQUENCER_LATCH_BEGIN_CONTINUE
.Lgk_stock_latch_begin_unavailable:
        move.l  __gk_lifecycle_state,%d0
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.s   gk_sequencer_latch_begin_fatal
        movem.l (%sp),%d0-%d3/%d5-%d7/%a0-%a6
        lea     56(%sp),%sp
        .incbin "stock/0164.bin", 0, 2
        .incbin "stock/0164.bin", 2, 6
        jmp     GK_STOCK_SEQUENCER_LATCH_BEGIN_CONTINUE
        .global gk_sequencer_latch_begin_fatal
gk_sequencer_latch_begin_fatal:
        illegal
        bra.s   gk_sequencer_latch_begin_fatal
        .size   gk_stock_sequencer_latch_begin,.-gk_stock_sequencer_latch_begin
        .global gk_stock_sequencer_latch_commit
        .type   gk_stock_sequencer_latch_commit,@function
gk_stock_sequencer_latch_commit:
        .global gk_sequencer_latch_final_store_hook
gk_sequencer_latch_final_store_hook:
        nop
        nop
        lea     -60(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.l  __gk_lifecycle_state,%d1
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d1
        beq.s   .Lgk_stock_latch_commit_quiesced
        bsr.w   gk_sequencer_latch_commit_part
        bne.w   gk_sequencer_latch_queue_commit_deferred
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        jmp     GK_STOCK_SEQUENCER_LATCH_COMMIT_CONTINUE
        .global gk_stock_sequencer_latch_commit_stock_only
gk_stock_sequencer_latch_commit_stock_only:
.Lgk_stock_latch_commit_quiesced:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     60(%sp),%sp
        .incbin "stock/0165.bin", 0, 6
        jmp     GK_STOCK_SEQUENCER_LATCH_COMMIT_CONTINUE
        .global gk_sequencer_latch_commit_fatal
gk_sequencer_latch_commit_fatal:
        illegal
        bra.s   gk_sequencer_latch_commit_fatal
        .size   gk_stock_sequencer_latch_commit,.-gk_stock_sequencer_latch_commit
        .global gk_stock_audio_latch_gate
        .type   gk_stock_audio_latch_gate,@function
gk_stock_audio_latch_gate:
        .incbin "stock/0166.bin", 0, 6
        beq.s   .Lgk_stock_audio_gate_continue
        lea     -12(%sp),%sp
        movem.l %d1/%a0-%a1,(%sp)
        bsr.w   gk_audio_latch_ready
        bmi.s   .Lgk_stock_audio_gate_skip_restore
        movem.l (%sp),%d1/%a0-%a1
        lea     12(%sp),%sp
        .incbin "stock/0167.bin", 0, 6
.Lgk_stock_audio_gate_continue:
        jmp     GK_STOCK_AUDIO_LATCH_GATE_CONTINUE
.Lgk_stock_audio_gate_skip_restore:
        movem.l (%sp),%d1/%a0-%a1
        lea     12(%sp),%sp
.Lgk_stock_audio_gate_skip_direct:
        jmp     GK_STOCK_AUDIO_LATCH_SKIP
        .size   gk_stock_audio_latch_gate,.-gk_stock_audio_latch_gate
        .global gk_stock_audio_scene_a_store
        .type   gk_stock_audio_scene_a_store,@function
gk_stock_audio_scene_a_store:
        moveq   #0,%d2
        move.b  GK_STOCK_AUDIO_SCENE_A_VALUE,%d2
        moveq   #0x10,%d1
        bsr.w   gk_audio_latch_store_byte
        tst.l   %d0
        bne.s   gk_audio_latch_store_fatal
        lea     GK_STOCK_AUDIO_SCENE_A_VALUE,%a1
        jmp     GK_STOCK_AUDIO_SCENE_A_CONTINUE
        .size   gk_stock_audio_scene_a_store,.-gk_stock_audio_scene_a_store
        .global gk_stock_audio_scene_b_store
        .type   gk_stock_audio_scene_b_store,@function
gk_stock_audio_scene_b_store:
        moveq   #0,%d2
        move.b  GK_STOCK_AUDIO_SCENE_B_VALUE,%d2
        moveq   #0x11,%d1
        bsr.w   gk_audio_latch_store_byte
        tst.l   %d0
        bne.s   gk_audio_latch_store_fatal
        lea     GK_STOCK_AUDIO_SCENE_B_VALUE,%a1
        jmp     GK_STOCK_AUDIO_SCENE_B_CONTINUE
        .size   gk_stock_audio_scene_b_store,.-gk_stock_audio_scene_b_store
        .global gk_audio_latch_store_fatal
gk_audio_latch_store_fatal:
        illegal
        bra.s   gk_audio_latch_store_fatal
