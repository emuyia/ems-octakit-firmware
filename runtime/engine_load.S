        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .type   gk_selector_group_range_validate,@function
gk_selector_group_range_validate:
        tst.l   %d0
        beq.s   .Lgk_group_range_error
        cmpi.l  #GK_LEASE_SIDECAR_COUNT,%d0
        bhi.s   .Lgk_group_range_error
        move.l  %a0,%d1
        subi.l  #__gk_lease_sidecars,%d1
        bmi.s   .Lgk_group_range_error
        btst    #0,%d1
        bne.s   .Lgk_group_range_error
        add.l   %d0,%d0
        add.l   %d1,%d0
        cmpi.l  #GK_LEASE_SIDECAR_BYTES,%d0
        bhi.s   .Lgk_group_range_error
        moveq   #GK_OK,%d0
        rts
.Lgk_group_range_error:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_selector_group_range_validate,.-gk_selector_group_range_validate
        .global gk_selector_group_begin
        .type   gk_selector_group_begin,@function
gk_selector_group_begin:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_group_begin_range
        lea     -32(%sp),%sp
        movem.l %d2-%d6/%a2-%a4,(%sp)
        move.l  %d0,%d4
        move.l  %d1,%d5
        movea.l %a0,%a2
        move.l  %d5,%d0
        bsr.w   gk_selector_group_range_validate
        tst.l   %d0
        bmi.s   .Lgk_group_begin_restore
        moveq   #0,%d6
.Lgk_group_begin_loop:
        movea.l %a2,%a0
        move.l  %d6,%d0
        add.l   %d0,%d0
        adda.l  %d0,%a0
        move.l  %d4,%d0
        bsr.w   gk_selector_begin_update
        tst.l   %d0
        bne.s   .Lgk_group_begin_rollback
        addq.l  #1,%d6
        cmp.l   %d5,%d6
        blo.s   .Lgk_group_begin_loop
        moveq   #GK_OK,%d0
        bra.s   .Lgk_group_begin_restore
.Lgk_group_begin_rollback:
        move.l  %d0,%d4
        tst.l   %d6
        beq.s   .Lgk_group_begin_original_error
        movea.l %a2,%a3
.Lgk_group_begin_abort_loop:
        movea.l %a3,%a0
        bsr.w   gk_selector_abort_update
        tst.l   %d0
        bne.s   .Lgk_group_begin_rollback_corrupt
        addq.l  #2,%a3
        subq.l  #1,%d6
        bne.s   .Lgk_group_begin_abort_loop
.Lgk_group_begin_original_error:
        move.l  %d4,%d0
        bra.s   .Lgk_group_begin_restore
.Lgk_group_begin_rollback_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_group_begin_restore:
        movem.l (%sp),%d2-%d6/%a2-%a4
        lea     32(%sp),%sp
        rts
.Lgk_group_begin_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_selector_group_begin,.-gk_selector_group_begin
        .global gk_selector_group_commit
        .type   gk_selector_group_commit,@function
gk_selector_group_commit:
        lea     -24(%sp),%sp
        movem.l %d2-%d4/%a2-%a4,(%sp)
        move.l  %d0,%d3
        movea.l %a0,%a2
        bsr.w   gk_selector_group_range_validate
        tst.l   %d0
        bmi.s   .Lgk_group_commit_restore
        moveq   #0,%d4
.Lgk_group_commit_loop:
        movea.l %a2,%a0
        move.l  %d4,%d0
        add.l   %d0,%d0
        adda.l  %d0,%a0
        bsr.w   gk_selector_commit_update
        tst.l   %d0
        bne.s   .Lgk_group_commit_corrupt
        addq.l  #1,%d4
        cmp.l   %d3,%d4
        blo.s   .Lgk_group_commit_loop
        moveq   #GK_OK,%d0
        bra.s   .Lgk_group_commit_restore
.Lgk_group_commit_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_group_commit_restore:
        movem.l (%sp),%d2-%d4/%a2-%a4
        lea     24(%sp),%sp
        rts
        .size   gk_selector_group_commit,.-gk_selector_group_commit
        .global gk_selector_group_abort
        .type   gk_selector_group_abort,@function
gk_selector_group_abort:
        lea     -24(%sp),%sp
        movem.l %d2-%d4/%a2-%a4,(%sp)
        move.l  %d0,%d3
        movea.l %a0,%a2
        bsr.w   gk_selector_group_range_validate
        tst.l   %d0
        bmi.s   .Lgk_group_abort_restore
        moveq   #0,%d4
.Lgk_group_abort_loop:
        movea.l %a2,%a0
        move.l  %d4,%d0
        add.l   %d0,%d0
        adda.l  %d0,%a0
        bsr.w   gk_selector_abort_update
        tst.l   %d0
        bne.s   .Lgk_group_abort_corrupt
        addq.l  #1,%d4
        cmp.l   %d3,%d4
        blo.s   .Lgk_group_abort_loop
        moveq   #GK_OK,%d0
        bra.s   .Lgk_group_abort_restore
.Lgk_group_abort_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_group_abort_restore:
        movem.l (%sp),%d2-%d4/%a2-%a4
        lea     24(%sp),%sp
        rts
        .size   gk_selector_group_abort,.-gk_selector_group_abort
        .type   gk_engine_current_selector_begin,@function
gk_engine_current_selector_begin:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_engine_current_begin_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_engine_current_begin_range
        cmpi.l  #3,%d2
        bhi.w   .Lgk_engine_current_begin_range
        .incbin "stock/0074.bin", 0, 4
        .incbin "stock/0074.bin", 4, 4
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d2,%d5
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a0),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_engine_current_begin_owned
        cmp.l   %d3,%d0
        bne.w   .Lgk_engine_current_begin_busy
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   .Lgk_engine_current_begin_corrupt
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_engine_current_begin_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_engine_current_begin_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_bank,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_current_begin_corrupt
        tst.b   __gk_pending_transition_flags
        beq.w   .Lgk_engine_current_begin_corrupt
        move.l  %d4,%d0
        lsl.l   #2,%d0
        add.l   %d5,%d0
        bsr.w   gk_physical_validate
        cmp.l   %d3,%d0
        bne.w   .Lgk_engine_current_begin_corrupt
        moveq   #GK_OK,%d0
        moveq   #0,%d1
        bra.s   .Lgk_engine_current_begin_restore
.Lgk_engine_current_begin_owned:
        move.l  %d3,%d0
        bsr.w   gk_selector_begin_update
        tst.l   %d0
        bne.s   .Lgk_engine_current_begin_restore
        moveq   #1,%d1
        bra.s   .Lgk_engine_current_begin_restore
.Lgk_engine_current_begin_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_engine_current_begin_restore
.Lgk_engine_current_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_engine_current_begin_restore:
        move.w  %d2,%sr
        movem.l (%sp),%d2-%d5/%a2-%a4
        lea     28(%sp),%sp
        rts
.Lgk_engine_current_begin_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_engine_current_selector_begin,.-gk_engine_current_selector_begin
        .type   gk_engine_load_publish,@function
gk_engine_load_publish:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_engine_publish_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_engine_publish_range
        cmpi.l  #3,%d2
        bhi.w   .Lgk_engine_publish_range
        cmpi.l  #1,%d3
        bhi.w   .Lgk_engine_publish_range
        lea     -44(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %d2,%d6
        move.l  %d3,%d7
        move.w  %sr,%d0
        move.w  %d0,40(%sp)
        move.w  #0x2700,%sr
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_engine_publish_corrupt
        move.l  %d5,%d0
        lsl.l   #2,%d0
        add.l   %d6,%d0
        bsr.w   gk_physical_validate
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_publish_corrupt
        move.l %d4,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_engine_publish_corrupt
        tst.w   GK_DESC_READERS(%a2)
        beq.w   .Lgk_engine_publish_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_engine_publish_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_engine_publish_corrupt
        lea     GK_STOCK_ENGINE_TRACK_BANKS,%a2
        lea     GK_STOCK_ENGINE_TRACK_PARTS,%a3
        moveq   #GK_SIDECAR_ENGINE_AUDIO_COUNT,%d2
.Lgk_engine_publish_engine_track_loop:
        moveq   #0,%d0
        move.b  (%a2)+,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_engine_publish_corrupt
        moveq   #0,%d0
        move.b  (%a3)+,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_engine_publish_corrupt
        subq.l  #1,%d2
        bne.s   .Lgk_engine_publish_engine_track_loop
        lea     GK_STOCK_SEQUENCER_TRACK_BANKS,%a2
        lea     GK_STOCK_SEQUENCER_TRACK_PARTS,%a3
        moveq   #GK_SIDECAR_SEQUENCER_TRACK_COUNT,%d2
.Lgk_engine_publish_sequencer_track_loop:
        moveq   #0,%d0
        move.b  (%a2)+,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_engine_publish_corrupt
        moveq   #0,%d0
        move.b  (%a3)+,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_engine_publish_corrupt
        subq.l  #1,%d2
        bne.s   .Lgk_engine_publish_sequencer_track_loop
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_LOAD_DERIVED_OFFSET,%a2
        moveq   #GK_SIDECAR_ENGINE_LOAD_DERIVED_COUNT,%d2
.Lgk_engine_publish_pending_loop:
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a2),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_publish_corrupt
        addq.l  #2,%a2
        subq.l  #1,%d2
        bne.s   .Lgk_engine_publish_pending_loop
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a2
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a2),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_publish_corrupt
        tst.l   %d7
        bne.s   .Lgk_engine_publish_commit_derived
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_publish_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   .Lgk_engine_publish_corrupt
.Lgk_engine_publish_commit_derived:
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_LOAD_DERIVED_OFFSET,%a0
        moveq   #GK_SIDECAR_ENGINE_LOAD_DERIVED_COUNT,%d0
        bsr.w   gk_selector_group_commit
        tst.l   %d0
        bne.w   .Lgk_engine_publish_corrupt
        tst.l   %d7
        beq.s   .Lgk_engine_publish_release
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        bsr.w   gk_selector_commit_update
        tst.l   %d0
        bne.w   .Lgk_engine_publish_corrupt
.Lgk_engine_publish_release:
        move.l  %d4,%d0
        bsr.w   gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_engine_publish_corrupt
        moveq   #GK_OK,%d0
        bra.s   .Lgk_engine_publish_restore
.Lgk_engine_publish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_engine_publish_restore:
        move.w  40(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     44(%sp),%sp
        rts
.Lgk_engine_publish_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_engine_load_publish,.-gk_engine_load_publish
        .type   gk_engine_saved_reload_publish,@function
gk_engine_saved_reload_publish:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_engine_saved_publish_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_engine_saved_publish_range
        cmpi.l  #3,%d2
        bhi.w   .Lgk_engine_saved_publish_range
        cmpi.l  #1,%d3
        bhi.w   .Lgk_engine_saved_publish_range
        lea     -44(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %d2,%d6
        move.l  %d3,%d7
        move.w  %sr,%d0
        move.w  %d0,40(%sp)
        move.w  #0x2700,%sr
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_engine_saved_publish_corrupt
        move.l  %d5,%d0
        lsl.l   #2,%d0
        add.l   %d6,%d0
        bsr.w   gk_physical_validate
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        move.l %d4,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_engine_saved_publish_corrupt
        tst.w   GK_DESC_READERS(%a2)
        beq.w   .Lgk_engine_saved_publish_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        lea     GK_STOCK_ENGINE_TRACK_BANKS,%a2
        lea     GK_STOCK_ENGINE_TRACK_PARTS,%a3
        moveq   #GK_SIDECAR_ENGINE_AUDIO_COUNT,%d2
.Lgk_engine_saved_publish_track_loop:
        moveq   #0,%d0
        move.b  (%a2)+,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        moveq   #0,%d0
        move.b  (%a3)+,%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        subq.l  #1,%d2
        bne.s   .Lgk_engine_saved_publish_track_loop
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_SAVED_DERIVED_OFFSET,%a2
        moveq   #GK_SIDECAR_ENGINE_SAVED_DERIVED_COUNT,%d2
.Lgk_engine_saved_publish_pending_loop:
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a2),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        addq.l  #2,%a2
        subq.l  #1,%d2
        bne.s   .Lgk_engine_saved_publish_pending_loop
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a2
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a2),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        tst.l   %d7
        bne.s   .Lgk_engine_saved_publish_commit_derived
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   .Lgk_engine_saved_publish_corrupt
.Lgk_engine_saved_publish_commit_derived:
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_SAVED_DERIVED_OFFSET,%a0
        moveq   #GK_SIDECAR_ENGINE_SAVED_DERIVED_COUNT,%d0
        bsr.w   gk_selector_group_commit
        tst.l   %d0
        bne.w   .Lgk_engine_saved_publish_corrupt
        tst.l   %d7
        beq.s   .Lgk_engine_saved_publish_release
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        bsr.w   gk_selector_commit_update
        tst.l   %d0
        bne.w   .Lgk_engine_saved_publish_corrupt
.Lgk_engine_saved_publish_release:
        move.l  %d4,%d0
        bsr.w   gk_descriptor_release
        tst.l   %d0
        bne.s   .Lgk_engine_saved_publish_corrupt
        moveq   #GK_OK,%d0
        bra.s   .Lgk_engine_saved_publish_restore
.Lgk_engine_saved_publish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_engine_saved_publish_restore:
        move.w  40(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     44(%sp),%sp
        rts
.Lgk_engine_saved_publish_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_engine_saved_reload_publish,.-gk_engine_saved_reload_publish
        .global gk_stock_engine_part_load_and_publish
        .type   gk_stock_engine_part_load_and_publish,@function
gk_stock_engine_part_load_and_publish:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_stock_engine_load_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        bne.w   gk_engine_part_load_fatal
        move.l  (%sp),%d0
        cmpi.l  #GK_STOCK_ENGINE_LOAD_RETAINED_RETURN,%d0
        beq.w   gk_stock_engine_part_load_trampoline
        cmpi.l  #GK_STOCK_ENGINE_LOAD_STATE_INIT_RETURN,%d0
        beq.w   gk_stock_engine_part_load_trampoline
        cmpi.l  #GK_STOCK_ENGINE_LOAD_STARTUP_RETURN,%d0
        beq.w   gk_stock_engine_part_load_trampoline
        cmpi.l  #GK_STOCK_ENGINE_LOAD_BANKS_RETURN,%d0
        beq.w   gk_stock_engine_part_load_trampoline
        bra.w   gk_engine_part_load_fatal
.Lgk_stock_engine_load_active:
        .incbin "stock/0075.bin", 0, 4
        .incbin "stock/0075.bin", 4, 4
        .incbin "stock/0076.bin", 0, 4
        .incbin "stock/0076.bin", 4, 4
        cmpi.l  #15,%d4
        bhi.w   gk_engine_part_load_fatal
        cmpi.l  #3,%d5
        bhi.w   gk_engine_part_load_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        bsr.w   gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_engine_part_load_fatal
        move.l  %d0,%d6
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        bsr.w   gk_engine_current_selector_begin
        tst.l   %d0
        bne.w   .Lgk_stock_engine_load_release_fatal
        move.l  %d1,%d7
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_LOAD_DERIVED_OFFSET,%a0
        move.l  %d6,%d0
        moveq   #GK_SIDECAR_ENGINE_LOAD_DERIVED_COUNT,%d1
        bsr.w   gk_selector_group_begin
        tst.l   %d0
        bne.w   .Lgk_stock_engine_load_abort_current_fatal
        move.l  52(%sp),-(%sp)
        move.l  52(%sp),-(%sp)
        bsr.w   gk_stock_engine_part_load_trampoline
        addq.l  #8,%sp
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %d7,%d3
        bsr.w   gk_engine_load_publish
        tst.l   %d0
        bne.w   gk_engine_part_load_fatal
        .incbin "stock/0077.bin", 0, 4
        .incbin "stock/0077.bin", 4, 4
        .incbin "stock/0077.bin", 8, 2
.Lgk_stock_engine_load_abort_current_fatal:
        tst.l   %d7
        beq.s   .Lgk_stock_engine_load_release_fatal
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        bsr.w   gk_selector_abort_update
        tst.l   %d0
        bne.w   gk_engine_part_load_fatal
.Lgk_stock_engine_load_release_fatal:
        move.l  %d6,%d0
        bsr.w   gk_descriptor_release
        bra.w   gk_engine_part_load_fatal
        .size   gk_stock_engine_part_load_and_publish,.-gk_stock_engine_part_load_and_publish
        .global gk_stock_engine_part_load_trampoline
        .type   gk_stock_engine_part_load_trampoline,@function
gk_stock_engine_part_load_trampoline:
        .incbin "stock/0078.bin", 0, 4
        .incbin "stock/0078.bin", 4, 4
        .global gk_stock_engine_part_load_trampoline_jump
gk_stock_engine_part_load_trampoline_jump:
        jmp     GK_STOCK_ENGINE_PART_LOAD_CONTINUE
        .size   gk_stock_engine_part_load_trampoline,.-gk_stock_engine_part_load_trampoline
        .global gk_stock_engine_saved_part_reload
        .type   gk_stock_engine_saved_part_reload,@function
gk_stock_engine_saved_part_reload:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_stock_engine_saved_reload_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   gk_stock_engine_saved_part_reload_trampoline
        bra.w   gk_engine_part_load_fatal
.Lgk_stock_engine_saved_reload_active:
        .incbin "stock/0079.bin", 0, 4
        .incbin "stock/0079.bin", 4, 4
        .incbin "stock/0080.bin", 0, 4
        .incbin "stock/0080.bin", 4, 4
        cmpi.l  #15,%d4
        bhi.w   gk_engine_part_load_fatal
        cmpi.l  #3,%d5
        bhi.w   gk_engine_part_load_fatal
        move.l  %d4,%d0
        move.l  %d5,%d1
        bsr.w   gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_engine_part_load_fatal
        move.l  %d0,%d6
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        bsr.w   gk_engine_current_selector_begin
        tst.l   %d0
        bne.w   .Lgk_stock_engine_saved_release_fatal
        move.l  %d1,%d7
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_SAVED_DERIVED_OFFSET,%a0
        move.l  %d6,%d0
        moveq   #GK_SIDECAR_ENGINE_SAVED_DERIVED_COUNT,%d1
        bsr.w   gk_selector_group_begin
        tst.l   %d0
        bne.w   .Lgk_stock_engine_saved_abort_current_fatal
        move.l  52(%sp),-(%sp)
        move.l  52(%sp),-(%sp)
        bsr.w   gk_stock_engine_saved_part_reload_trampoline
        addq.l  #8,%sp
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %d7,%d3
        bsr.w   gk_engine_saved_reload_publish
        tst.l   %d0
        bne.w   gk_engine_part_load_fatal
        .incbin "stock/0081.bin", 0, 4
        .incbin "stock/0081.bin", 4, 4
        .incbin "stock/0081.bin", 8, 2
.Lgk_stock_engine_saved_abort_current_fatal:
        tst.l   %d7
        beq.s   .Lgk_stock_engine_saved_release_fatal
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a0
        bsr.w   gk_selector_abort_update
        tst.l   %d0
        bne.s   gk_engine_part_load_fatal
.Lgk_stock_engine_saved_release_fatal:
        move.l  %d6,%d0
        bsr.w   gk_descriptor_release
        bra.s   gk_engine_part_load_fatal
        .size   gk_stock_engine_saved_part_reload,.-gk_stock_engine_saved_part_reload
        .global gk_stock_engine_saved_part_reload_trampoline
        .type   gk_stock_engine_saved_part_reload_trampoline,@function
gk_stock_engine_saved_part_reload_trampoline:
        .incbin "stock/0082.bin", 0, 4
        .incbin "stock/0082.bin", 4, 4
        .global gk_stock_engine_saved_part_reload_trampoline_jump
gk_stock_engine_saved_part_reload_trampoline_jump:
        jmp     GK_STOCK_ENGINE_SAVED_PART_RELOAD_CONTINUE
        .size   gk_stock_engine_saved_part_reload_trampoline,.-gk_stock_engine_saved_part_reload_trampoline
        .global gk_engine_part_load_fatal
gk_engine_part_load_fatal:
        illegal
        bra.s   gk_engine_part_load_fatal
