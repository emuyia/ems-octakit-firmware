        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .equ    GK_MT_KIND_UI_A,1
        .equ    GK_MT_KIND_UI_B,2
        .equ    GK_MT_KIND_COMMIT_A,3
        .equ    GK_MT_KIND_TEMPORARY,4
        .equ    GK_MT_KIND_COMMIT_B,5
        .equ    GK_MT_KIND_SETUP,6
        .equ    GK_MT_KIND_EVENT,7
        .equ    GK_MT_STAGE_ARMED,0
        .equ    GK_MT_STAGE_DIRECT,1
        .equ    GK_MT_STAGE_DIRECT_HELPER,2
        .equ    GK_MT_STAGE_NESTED_FIRST,3
        .equ    GK_MT_STAGE_NESTED_HELPER,4
        .equ    GK_MT_STAGE_NESTED_DONE,5
        .equ    GK_MT_STAGE_OUTER,6
        .equ    GK_MT_STAGE_OUTER_HELPER,7
        .equ    GK_MT_STAGE_EVENT_ARMED,8
        .equ    GK_MT_STAGE_EVENT_WRITTEN,9
        .equ    GK_MT_FRAME,96
        .equ    GK_MT_OUT_D0,44
        .equ    GK_MT_OUT_D1,48
        .equ    GK_MT_OUT_A0,52
        .equ    GK_MT_OUT_A1,56
        .equ    GK_MT_OUT_SR,60
        .equ    GK_MT_ARG1,64
        .equ    GK_MT_ARG2,68
        .equ    GK_MT_ARG3,72
        .equ    GK_MT_KIND,76
        .equ    GK_MT_TARGET,80
        .equ    GK_MT_ARGC,84
        .equ    GK_MT_ARG4,88
        .equ    GK_MT_ARG5,92
        .equ    GK_MT_RETURN,96
        .equ    GK_MT_INPUT_ARG1,100
        .equ    GK_MT_INPUT_ARG2,104
        .equ    GK_MT_INPUT_ARG3,108
        .equ    GK_MT_INPUT_ARG4,112
        .equ    GK_MT_INPUT_ARG5,116
        .equ    GK_MT_MARKER_SAVE_BYTES,44
        .type   gk_machine_transition_state_clear,@function
gk_machine_transition_state_clear:
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        clr.l   __gk_machine_transition_state_start
        clr.l   __gk_machine_transition_state_start + 4
        clr.l   __gk_machine_transition_state_start + 8
        move.w  %d1,%sr
        rts
        .size   gk_machine_transition_state_clear,.-gk_machine_transition_state_clear
        .type   gk_machine_transition_state_validate,@function
gk_machine_transition_state_validate:
        moveq   #0,%d0
        move.b  __gk_machine_transition_active,%d0
        cmpi.l  #GK_MT_KIND_UI_A,%d0
        blo.w   gk_machine_transition_fatal_state
        cmpi.l  #GK_MT_KIND_EVENT,%d0
        bhi.w   gk_machine_transition_fatal_state
        move.l  %d0,%d1
        not.l   %d1
        andi.l  #0xff,%d1
        cmp.b   __gk_machine_transition_active_inverse,%d1
        bne.w   gk_machine_transition_fatal_state
        tst.l   __gk_lifecycle_state
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_machine_transition_part,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_CURRENT_PART_PRIMARY,%d0
        bne.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_CURRENT_PART_MIRROR,%d0
        bne.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_ENGINE_PART,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_machine_transition_track,%d0
        cmpi.l  #7,%d0
        bhi.w   gk_machine_transition_fatal_state
        moveq   #0,%d1
        move.b  __gk_machine_transition_active,%d1
        cmpi.l  #GK_MT_KIND_UI_B,%d1
        bhi.s   .Lgk_mt_track_current_done
        cmp.b   GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        bne.w   gk_machine_transition_fatal_state
.Lgk_mt_track_current_done:
        moveq   #0,%d0
        move.b  __gk_machine_transition_bank,%d0
        cmpi.l  #15,%d0
        bhi.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        bne.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_CURRENT_BANK_MIRROR,%d0
        bne.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_ENGINE_BANK,%d0
        bne.w   gk_machine_transition_fatal_state
        cmp.b   __gk_current_bank,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_machine_transition_pattern,%d0
        cmpi.l  #15,%d0
        bhi.w   gk_machine_transition_fatal_state
        moveq   #0,%d1
        move.b  __gk_machine_transition_active,%d1
        cmpi.l  #GK_MT_KIND_EVENT,%d1
        bne.s   .Lgk_mt_state_pattern_settled
        moveq   #0,%d1
        move.b  __gk_machine_transition_reserved,%d1
        cmpi.l  #15,%d1
        bhi.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_CURRENT_PATTERN_PRIMARY,%d1
        bne.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_CURRENT_PATTERN,%d1
        bne.w   gk_machine_transition_fatal_state
        bra.s   .Lgk_mt_state_pattern_runtime
.Lgk_mt_state_pattern_settled:
        cmp.b   GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        bne.w   gk_machine_transition_fatal_state
        cmp.b   GK_STOCK_CURRENT_PATTERN,%d0
        bne.w   gk_machine_transition_fatal_state
.Lgk_mt_state_pattern_runtime:
        cmp.b   __gk_current_pattern,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_machine_transition_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_machine_transition_fatal_state
        cmp.b   __gk_workspace_descriptor,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_machine_transition_kit,%d0
        cmp.b   __gk_current_kit,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_machine_transition_count,%d0
        cmpi.l  #8,%d0
        bhi.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_machine_transition_event_index,%d0
        cmpi.l  #8,%d0
        bhi.w   gk_machine_transition_fatal_state
        rts
        .size   gk_machine_transition_state_validate,.-gk_machine_transition_state_validate
        .global gk_machine_transition_current_tuple_validate
        .type   gk_machine_transition_current_tuple_validate,@function
gk_machine_transition_current_tuple_validate:
        cmpi.l  #15,%d0
        bhi.w   gk_machine_transition_fatal_state
        cmpi.l  #3,%d1
        bhi.w   gk_machine_transition_fatal_state
        cmpi.l  #7,%d2
        bhi.w   gk_machine_transition_fatal_state
        .incbin "stock/0368.bin", 0, 4
        .incbin "stock/0368.bin", 4, 4
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d2,%d5
        bsr.w   gk_machine_transition_state_validate
        cmp.b   __gk_machine_transition_bank,%d3
        bne.w   gk_machine_transition_fatal_state
        cmp.b   __gk_machine_transition_part,%d4
        bne.w   gk_machine_transition_fatal_state
        cmp.b   __gk_machine_transition_track,%d5
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d2
        move.b  __gk_machine_transition_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   gk_machine_transition_fatal_state
        cmp.b   __gk_workspace_descriptor,%d2
        bne.w   gk_machine_transition_fatal_state
        cmp.b   __gk_pending_workspace_descriptor,%d2
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   gk_machine_transition_fatal_state
        andi.l  #0x7e,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        cmpi.l  #GK_TRANSITION_PRESERVE_NAME,%d0
        bne.w   gk_machine_transition_fatal_state
        tst.b   __gk_pending_ui_capture_created
        bne.w   gk_machine_transition_fatal_state
        cmp.b   __gk_pending_bank,%d3
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.b   __gk_pending_pattern,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.b   __gk_pending_kit,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  __gk_workspace_bound,%d0
        cmpi.l  #1,%d0
        bhi.w   gk_machine_transition_fatal_state
        cmp.b   __gk_pending_workspace_bound,%d0
        bne.w   gk_machine_transition_fatal_state
        lea     __gk_lease_sidecars + GK_SIDECAR_ENGINE_CURRENT_OFFSET,%a1
        moveq   #0,%d0
        move.b  GK_SIDECAR_CURRENT(%a1),%d0
        cmp.l   %d2,%d0
        bne.w   gk_machine_transition_fatal_state
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING(%a1),%d0
        cmp.l   %d2,%d0
        bne.w   gk_machine_transition_fatal_state
        move.l  %d3,%d0
        lsl.l   #2,%d0
        add.l   %d4,%d0
        jsr     gk_physical_validate
        tst.l   %d0
        bmi.w   gk_machine_transition_fatal_state
        cmp.l   %d2,%d0
        bne.w   gk_machine_transition_fatal_state
        movea.l %a0,%a2
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        tst.w   GK_DESC_ROOTS(%a1)
        beq.w   gk_machine_transition_fatal_state
        tst.w   GK_DESC_READERS(%a1)
        beq.w   gk_machine_transition_fatal_state
        move.l  %d2,%d0
        movea.l %a2,%a0
        movem.l (%sp),%d2-%d5/%a2
        lea     20(%sp),%sp
        rts
        .size   gk_machine_transition_current_tuple_validate,.-gk_machine_transition_current_tuple_validate
        .global gk_machine_transition_prepare
        .type   gk_machine_transition_prepare,@function
gk_machine_transition_prepare:
        cmpi.l  #GK_MT_KIND_UI_A,%d0
        blo.w   gk_machine_transition_fatal_entry
        cmpi.l  #GK_MT_KIND_EVENT,%d0
        bhi.w   gk_machine_transition_fatal_entry
        cmpi.l  #7,%d1
        bhi.w   gk_machine_transition_fatal_entry
        tst.l   __gk_lifecycle_state
        bne.w   gk_machine_transition_fatal_entry
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        tst.b   __gk_machine_transition_active
        bne.w   gk_machine_transition_fatal_claim
        tst.b   __gk_machine_transition_active_inverse
        bne.w   gk_machine_transition_fatal_claim
        move.b  %d0,__gk_machine_transition_active
        not.l   %d0
        move.b  %d0,__gk_machine_transition_active_inverse
        clr.l   __gk_machine_transition_state_start + 2
        clr.l   __gk_machine_transition_state_start + 6
        clr.w   __gk_machine_transition_state_start + 10
        move.b  %d1,__gk_machine_transition_track
        move.w  %d2,%sr
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_machine_transition_fatal_claimed
        movea.l %d0,%a2
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   gk_machine_transition_fatal_claimed
        moveq   #0,%d1
        move.b  GK_STOCK_ENGINE_PART,%d1
        cmp.l   %d1,%d0
        bne.w   gk_machine_transition_fatal_claimed
        move.b  %d0,__gk_machine_transition_part
        moveq   #0,%d1
        move.b  __gk_machine_transition_active,%d1
        cmpi.l  #GK_MT_KIND_EVENT,%d1
        bne.s   .Lgk_mt_prepare_settled_context
        move.l  %d6,%d0
        jsr     gk_stock_latest_engine_context_validate
        tst.l   %d0
        bmi.w   gk_machine_transition_fatal_claimed
        cmpa.l  %a2,%a0
        bne.w   gk_machine_transition_fatal_claimed
        moveq   #0,%d2
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d2
        cmpi.l  #15,%d2
        bhi.w   gk_machine_transition_fatal_claimed
        cmp.b   GK_STOCK_CURRENT_PATTERN,%d2
        bne.w   gk_machine_transition_fatal_claimed
        move.b  %d2,__gk_machine_transition_reserved
        bra.s   .Lgk_mt_prepare_context_ok
.Lgk_mt_prepare_settled_context:
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_machine_transition_fatal_claimed
.Lgk_mt_prepare_context_ok:
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.b  %d4,__gk_machine_transition_bank
        move.b  %d5,__gk_machine_transition_pattern
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_machine_transition_fatal_claimed
        move.b  %d6,__gk_machine_transition_descriptor
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        move.b  %d2,__gk_machine_transition_kit
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_machine_transition_fatal_claimed
        cmp.l   %d6,%d0
        bne.w   gk_machine_transition_fatal_abort
        move.l  %a2,%d2
        cmp.l   %d2,%d1
        bne.w   gk_machine_transition_fatal_abort
        movea.l %a0,%a3
        move.l  %d4,%d0
        move.l  %a2,%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_machine_transition_fatal_abort
        cmp.l   %d6,%d0
        bne.w   gk_machine_transition_fatal_release_abort_d0
        cmpa.l  %a3,%a0
        bne.w   gk_machine_transition_fatal_release_abort
        bsr.w   gk_machine_transition_state_validate
        rts
        .size   gk_machine_transition_prepare,.-gk_machine_transition_prepare
        .type   gk_machine_transition_terminal_validate,@function
gk_machine_transition_terminal_validate:
        moveq   #0,%d0
        move.b  __gk_machine_transition_active,%d0
        moveq   #0,%d1
        move.b  __gk_machine_transition_stage,%d1
        moveq   #0,%d2
        move.b  __gk_machine_transition_count,%d2
        cmpi.l  #GK_MT_KIND_UI_A,%d0
        beq.w   .Lgk_mt_terminal_ui
        cmpi.l  #GK_MT_KIND_UI_B,%d0
        beq.w   .Lgk_mt_terminal_ui
        cmpi.l  #GK_MT_KIND_EVENT,%d0
        beq.w   .Lgk_mt_terminal_event
        cmpi.l  #GK_MT_KIND_TEMPORARY,%d0
        beq.s   .Lgk_mt_terminal_required_simple
        cmpi.l  #GK_MT_KIND_COMMIT_A,%d0
        beq.s   .Lgk_mt_terminal_optional_simple
        cmpi.l  #GK_MT_KIND_COMMIT_B,%d0
        beq.s   .Lgk_mt_terminal_optional_simple
        cmpi.l  #GK_MT_KIND_SETUP,%d0
        bne.w   gk_machine_transition_fatal_terminal
.Lgk_mt_terminal_optional_simple:
        tst.l   %d1
        beq.s   .Lgk_mt_terminal_zero
.Lgk_mt_terminal_required_simple:
        cmpi.l  #GK_MT_STAGE_DIRECT,%d1
        beq.s   .Lgk_mt_terminal_one
        cmpi.l  #GK_MT_STAGE_DIRECT_HELPER,%d1
        beq.s   .Lgk_mt_terminal_two
        bra.w   gk_machine_transition_fatal_terminal
.Lgk_mt_terminal_zero:
        tst.l   %d2
        bne.w   gk_machine_transition_fatal_terminal
        rts
.Lgk_mt_terminal_one:
        cmpi.l  #1,%d2
        bne.w   gk_machine_transition_fatal_terminal
        rts
.Lgk_mt_terminal_two:
        cmpi.l  #2,%d2
        bne.w   gk_machine_transition_fatal_terminal
        rts
.Lgk_mt_terminal_ui:
        tst.l   %d1
        beq.s   .Lgk_mt_terminal_zero
        cmpi.l  #GK_MT_STAGE_DIRECT,%d1
        beq.s   .Lgk_mt_terminal_one
        cmpi.l  #GK_MT_STAGE_DIRECT_HELPER,%d1
        beq.s   .Lgk_mt_terminal_two
        cmpi.l  #GK_MT_STAGE_NESTED_DONE,%d1
        beq.s   .Lgk_mt_terminal_nested
        cmpi.l  #GK_MT_STAGE_OUTER,%d1
        beq.s   .Lgk_mt_terminal_outer
        cmpi.l  #GK_MT_STAGE_OUTER_HELPER,%d1
        beq.s   .Lgk_mt_terminal_outer_helper
        bra.w   gk_machine_transition_fatal_terminal
.Lgk_mt_terminal_nested:
        cmpi.l  #2,%d2
        beq.s   .Lgk_mt_terminal_ok
        cmpi.l  #3,%d2
        bne.w   gk_machine_transition_fatal_terminal
.Lgk_mt_terminal_ok:
        rts
.Lgk_mt_terminal_outer:
        cmpi.l  #1,%d2
        beq.s   .Lgk_mt_terminal_ok
        cmpi.l  #3,%d2
        beq.s   .Lgk_mt_terminal_ok
        cmpi.l  #4,%d2
        bne.w   gk_machine_transition_fatal_terminal
        rts
.Lgk_mt_terminal_outer_helper:
        cmpi.l  #2,%d2
        beq.s   .Lgk_mt_terminal_ok
        cmpi.l  #4,%d2
        beq.s   .Lgk_mt_terminal_ok
        cmpi.l  #5,%d2
        bne.w   gk_machine_transition_fatal_terminal
        rts
.Lgk_mt_terminal_event:
        tst.l   %d1
        bne.w   gk_machine_transition_fatal_terminal
        moveq   #0,%d0
        move.b  __gk_machine_transition_event_index,%d0
        cmpi.l  #8,%d0
        bne.w   gk_machine_transition_fatal_terminal
        cmp.l   %d0,%d2
        bhi.w   gk_machine_transition_fatal_terminal
        rts
        .size   gk_machine_transition_terminal_validate,.-gk_machine_transition_terminal_validate
        .global gk_machine_transition_finish
        .type   gk_machine_transition_finish,@function
gk_machine_transition_finish:
        bsr.w   gk_machine_transition_state_validate
        bsr.w   gk_machine_transition_terminal_validate
        moveq   #0,%d0
        move.b  __gk_machine_transition_bank,%d0
        cmp.l   %d4,%d0
        bne.w   gk_machine_transition_fatal_finish
        moveq   #0,%d0
        move.b  __gk_machine_transition_pattern,%d0
        cmp.l   %d5,%d0
        bne.w   gk_machine_transition_fatal_finish
        moveq   #0,%d0
        move.b  __gk_machine_transition_descriptor,%d0
        cmp.l   %d6,%d0
        bne.w   gk_machine_transition_fatal_finish
        moveq   #0,%d0
        move.b  __gk_machine_transition_part,%d0
        move.l  %a2,%d1
        cmp.l   %d1,%d0
        bne.w   gk_machine_transition_fatal_finish
        tst.b   __gk_machine_transition_count
        beq.s   .Lgk_mt_finish_no_write
        move.l  %d6,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %a2,%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   gk_machine_transition_fatal_release_abort
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   gk_machine_transition_fatal_release_abort
        bra.s   .Lgk_mt_finish_release
.Lgk_mt_finish_no_write:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_machine_transition_fatal_abort_only
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_machine_transition_fatal_claimed
        bra.s   .Lgk_mt_finish_post
.Lgk_mt_finish_release:
        move.l  %d6,%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_machine_transition_fatal_claimed
.Lgk_mt_finish_post:
        bsr.w   gk_machine_transition_state_validate
        bsr.w   gk_machine_transition_state_clear
        rts
        .size   gk_machine_transition_finish,.-gk_machine_transition_finish
        .type   gk_machine_transition_entry_validate,@function
gk_machine_transition_entry_validate:
        move.l  GK_MT_KIND(%a6),%d0
        cmpi.l  #GK_MT_KIND_UI_B,%d0
        bhi.w   .Lgk_mt_entry_direct
        move.l  GK_MT_ARG1(%a6),%d1
        cmpi.l  #GK_STOCK_MACHINE_COMMAND_ID,%d1
        bne.w   gk_machine_transition_fatal_entry
        tst.l   GK_MT_ARG2(%a6)
        beq.w   gk_machine_transition_fatal_entry
        cmp.l   (%a6),%d1
        bne.w   gk_machine_transition_fatal_entry
        move.l  GK_MT_ARG2(%a6),%d1
        cmp.l   8(%a6),%d1
        bne.w   gk_machine_transition_fatal_entry
        move.l  GK_MT_RETURN(%a6),%d1
        cmpi.l  #GK_STOCK_DIRECT_PRESS_RETURN,%d1
        bne.w   gk_machine_transition_fatal_entry
        cmpi.l  #GK_MT_KIND_UI_A,%d0
        bne.s   .Lgk_mt_entry_ui_b_identity
        lea     gk_stock_machine_ui_callback_a,%a0
        bra.s   .Lgk_mt_entry_ui_identity_ready
.Lgk_mt_entry_ui_b_identity:
        lea     gk_stock_machine_ui_callback_b,%a0
.Lgk_mt_entry_ui_identity_ready:
        move.l  %a0,%d2
        move.l  GK_MT_OUT_A0(%a6),%d1
        cmp.l   %d2,%d1
        bne.w   gk_machine_transition_fatal_entry
        move.l  #GK_STOCK_MACHINE_COMMAND_ID * 24,%d1
        lea     GK_STOCK_MACHINE_DIRECT_REGISTRY,%a0
        move.l  (%a0,%d1.l),%d1
        cmp.l   %d2,%d1
        bne.w   gk_machine_transition_fatal_entry
        rts
.Lgk_mt_entry_direct:
        move.l  GK_MT_ARG1(%a6),%d1
        cmpi.l  #7,%d1
        bhi.w   gk_machine_transition_fatal_entry
        move.l  GK_MT_RETURN(%a6),%d1
        cmpi.l  #GK_MT_KIND_COMMIT_A,%d0
        beq.w   .Lgk_mt_entry_commit_a
        cmpi.l  #GK_MT_KIND_TEMPORARY,%d0
        beq.w   .Lgk_mt_entry_temporary
        cmpi.l  #GK_MT_KIND_COMMIT_B,%d0
        beq.w   .Lgk_mt_entry_commit_b
        cmpi.l  #GK_MT_KIND_SETUP,%d0
        bne.w   gk_machine_transition_fatal_entry
        cmpi.l  #0x4006dd12,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40073900,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40073920,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40076858,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x400793ee,%d1
        bne.w   gk_machine_transition_fatal_entry
.Lgk_mt_entry_ok:
        rts
.Lgk_mt_entry_temporary:
        cmpi.l  #0x40062418,%d1
        bne.w   gk_machine_transition_fatal_entry
        rts
.Lgk_mt_entry_commit_a:
        cmpi.l  #0x40022718,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x4006c52e,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x4006dc9a,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x4006fa06,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40071bc6,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x400744ce,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40078a06,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40079402,%d1
        bne.w   gk_machine_transition_fatal_entry
        rts
.Lgk_mt_entry_commit_b:
        cmpi.l  #0x40022726,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x4003d376,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x4004036e,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x4005e454,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x4006fa14,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40071bd4,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x400744dc,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40078a14,%d1
        beq.w   .Lgk_mt_entry_ok
        cmpi.l  #0x40079410,%d1
        bne.w   gk_machine_transition_fatal_entry
        rts
        .size   gk_machine_transition_entry_validate,.-gk_machine_transition_entry_validate
        .type   gk_machine_transition_execute,@function
gk_machine_transition_execute:
        movea.l %sp,%a6
        bsr.w   gk_machine_transition_entry_validate
        move.l  GK_MT_KIND(%a6),%d0
        cmpi.l  #GK_MT_KIND_UI_B,%d0
        bhi.s   .Lgk_mt_execute_explicit_track
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d1
        bra.s   .Lgk_mt_execute_prepare
.Lgk_mt_execute_explicit_track:
        move.l  GK_MT_ARG1(%a6),%d1
.Lgk_mt_execute_prepare:
        bsr.w   gk_machine_transition_prepare
        movea.l GK_MT_TARGET(%a6),%a4
        move.l  GK_MT_ARGC(%a6),%d0
        cmpi.l  #5,%d0
        bne.s   .Lgk_mt_execute_four_args
        move.l  GK_MT_ARG5(%a6),-(%sp)
.Lgk_mt_execute_four_args:
        cmpi.l  #4,%d0
        blo.s   .Lgk_mt_execute_three_args
        move.l  GK_MT_ARG4(%a6),-(%sp)
.Lgk_mt_execute_three_args:
        cmpi.l  #3,%d0
        blo.s   .Lgk_mt_execute_two_args
        move.l  GK_MT_ARG3(%a6),-(%sp)
.Lgk_mt_execute_two_args:
        cmpi.l  #2,%d0
        blo.s   .Lgk_mt_execute_one_arg
        move.l  GK_MT_ARG2(%a6),-(%sp)
.Lgk_mt_execute_one_arg:
        move.l  GK_MT_ARG1(%a6),-(%sp)
        move.l  GK_MT_OUT_D0(%a6),%d0
        move.l  GK_MT_OUT_D1(%a6),%d1
        movea.l GK_MT_OUT_A0(%a6),%a0
        movea.l GK_MT_OUT_A1(%a6),%a1
        moveq   #0,%d2
        move.b  __gk_machine_transition_active,%d2
        cmpi.l  #GK_MT_KIND_UI_B,%d2
        bhi.s   .Lgk_mt_execute_stock
        movea.l %a4,%a0
.Lgk_mt_execute_stock:
        .global gk_machine_transition_stock_call
gk_machine_transition_stock_call:
        jsr     (%a4)
        move.w  %sr,%d2
        move.w  %d2,GK_MT_OUT_SR(%a6)
        move.l  %d0,GK_MT_OUT_D0(%a6)
        move.l  %d1,GK_MT_OUT_D1(%a6)
        move.l  %a0,GK_MT_OUT_A0(%a6)
        move.l  %a1,GK_MT_OUT_A1(%a6)
        move.l  GK_MT_ARGC(%a6),%d0
        lsl.l   #2,%d0
        adda.l  %d0,%sp
        bsr.w   gk_machine_transition_finish
        movem.l (%a6),%d2-%d7/%a2-%a6
        move.l  GK_MT_OUT_D0(%sp),%d0
        move.l  GK_MT_OUT_D1(%sp),%d1
        movea.l GK_MT_OUT_A0(%sp),%a0
        movea.l GK_MT_OUT_A1(%sp),%a1
        move.w  GK_MT_OUT_SR(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d2
        lea     GK_MT_FRAME(%sp),%sp
        rts
        .size   gk_machine_transition_execute,.-gk_machine_transition_execute
        .global gk_stock_machine_ui_callback_a
        .type gk_stock_machine_ui_callback_a,@function
gk_stock_machine_ui_callback_a:
        lea -GK_MT_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_MT_OUT_D0(%sp)
        move.l %d1,GK_MT_OUT_D1(%sp)
        move.l %a0,GK_MT_OUT_A0(%sp)
        move.l %a1,GK_MT_OUT_A1(%sp)
        move.w %sr,%d2
        move.w %d2,GK_MT_OUT_SR(%sp)
        move.l GK_MT_INPUT_ARG1(%sp),GK_MT_ARG1(%sp)
        move.l GK_MT_INPUT_ARG2(%sp),GK_MT_ARG2(%sp)
        moveq #GK_MT_KIND_UI_A,%d2
        move.l %d2,GK_MT_KIND(%sp)
        move.l #GK_STOCK_MACHINE_UI_CALLBACK_A,%d2
        move.l %d2,GK_MT_TARGET(%sp)
        moveq #2,%d2
        move.l %d2,GK_MT_ARGC(%sp)
        bra.w gk_machine_transition_execute
        .size gk_stock_machine_ui_callback_a,.-gk_stock_machine_ui_callback_a
        .global gk_stock_machine_ui_callback_b
        .type gk_stock_machine_ui_callback_b,@function
gk_stock_machine_ui_callback_b:
        lea -GK_MT_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_MT_OUT_D0(%sp)
        move.l %d1,GK_MT_OUT_D1(%sp)
        move.l %a0,GK_MT_OUT_A0(%sp)
        move.l %a1,GK_MT_OUT_A1(%sp)
        move.w %sr,%d2
        move.w %d2,GK_MT_OUT_SR(%sp)
        move.l GK_MT_INPUT_ARG1(%sp),GK_MT_ARG1(%sp)
        move.l GK_MT_INPUT_ARG2(%sp),GK_MT_ARG2(%sp)
        moveq #GK_MT_KIND_UI_B,%d2
        move.l %d2,GK_MT_KIND(%sp)
        move.l #GK_STOCK_MACHINE_UI_CALLBACK_B,%d2
        move.l %d2,GK_MT_TARGET(%sp)
        moveq #2,%d2
        move.l %d2,GK_MT_ARGC(%sp)
        bra.w gk_machine_transition_execute
        .size gk_stock_machine_ui_callback_b,.-gk_stock_machine_ui_callback_b
        .global gk_stock_machine_commit_a
        .type gk_stock_machine_commit_a,@function
gk_stock_machine_commit_a:
        lea -GK_MT_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_MT_OUT_D0(%sp)
        move.l %d1,GK_MT_OUT_D1(%sp)
        move.l %a0,GK_MT_OUT_A0(%sp)
        move.l %a1,GK_MT_OUT_A1(%sp)
        move.w %sr,%d2
        move.w %d2,GK_MT_OUT_SR(%sp)
        move.l GK_MT_INPUT_ARG1(%sp),GK_MT_ARG1(%sp)
        moveq #GK_MT_KIND_COMMIT_A,%d2
        move.l %d2,GK_MT_KIND(%sp)
        move.l #gk_machine_commit_a_trampoline,%d2
        move.l %d2,GK_MT_TARGET(%sp)
        moveq #1,%d2
        move.l %d2,GK_MT_ARGC(%sp)
        bra.w gk_machine_transition_execute
        .size gk_stock_machine_commit_a,.-gk_stock_machine_commit_a
        .global gk_stock_machine_temporary
        .type gk_stock_machine_temporary,@function
gk_stock_machine_temporary:
        lea -GK_MT_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_MT_OUT_D0(%sp)
        move.l %d1,GK_MT_OUT_D1(%sp)
        move.l %a0,GK_MT_OUT_A0(%sp)
        move.l %a1,GK_MT_OUT_A1(%sp)
        move.w %sr,%d2
        move.w %d2,GK_MT_OUT_SR(%sp)
        move.l GK_MT_INPUT_ARG1(%sp),GK_MT_ARG1(%sp)
        move.l GK_MT_INPUT_ARG2(%sp),GK_MT_ARG2(%sp)
        move.l GK_MT_INPUT_ARG3(%sp),GK_MT_ARG3(%sp)
        move.l GK_MT_INPUT_ARG4(%sp),GK_MT_ARG4(%sp)
        move.l GK_MT_INPUT_ARG5(%sp),GK_MT_ARG5(%sp)
        moveq #GK_MT_KIND_TEMPORARY,%d2
        move.l %d2,GK_MT_KIND(%sp)
        move.l #gk_machine_temporary_trampoline,%d2
        move.l %d2,GK_MT_TARGET(%sp)
        moveq #5,%d2
        move.l %d2,GK_MT_ARGC(%sp)
        bra.w gk_machine_transition_execute
        .size gk_stock_machine_temporary,.-gk_stock_machine_temporary
        .global gk_stock_machine_commit_b
        .type gk_stock_machine_commit_b,@function
gk_stock_machine_commit_b:
        lea -GK_MT_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_MT_OUT_D0(%sp)
        move.l %d1,GK_MT_OUT_D1(%sp)
        move.l %a0,GK_MT_OUT_A0(%sp)
        move.l %a1,GK_MT_OUT_A1(%sp)
        move.w %sr,%d2
        move.w %d2,GK_MT_OUT_SR(%sp)
        move.l GK_MT_INPUT_ARG1(%sp),GK_MT_ARG1(%sp)
        moveq #GK_MT_KIND_COMMIT_B,%d2
        move.l %d2,GK_MT_KIND(%sp)
        move.l #gk_machine_commit_b_trampoline,%d2
        move.l %d2,GK_MT_TARGET(%sp)
        moveq #1,%d2
        move.l %d2,GK_MT_ARGC(%sp)
        bra.w gk_machine_transition_execute
        .size gk_stock_machine_commit_b,.-gk_stock_machine_commit_b
        .global gk_stock_machine_setup
        .type gk_stock_machine_setup,@function
gk_stock_machine_setup:
        lea -GK_MT_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_MT_OUT_D0(%sp)
        move.l %d1,GK_MT_OUT_D1(%sp)
        move.l %a0,GK_MT_OUT_A0(%sp)
        move.l %a1,GK_MT_OUT_A1(%sp)
        move.w %sr,%d2
        move.w %d2,GK_MT_OUT_SR(%sp)
        move.l GK_MT_INPUT_ARG1(%sp),GK_MT_ARG1(%sp)
        move.l GK_MT_INPUT_ARG2(%sp),GK_MT_ARG2(%sp)
        move.l GK_MT_INPUT_ARG3(%sp),GK_MT_ARG3(%sp)
        move.l GK_MT_INPUT_ARG4(%sp),GK_MT_ARG4(%sp)
        moveq #GK_MT_KIND_SETUP,%d2
        move.l %d2,GK_MT_KIND(%sp)
        move.l #gk_machine_setup_trampoline,%d2
        move.l %d2,GK_MT_TARGET(%sp)
        moveq #4,%d2
        move.l %d2,GK_MT_ARGC(%sp)
        bra.w gk_machine_transition_execute
        .size gk_stock_machine_setup,.-gk_stock_machine_setup
        .global gk_machine_commit_a_trampoline
gk_machine_commit_a_trampoline:
        .incbin "stock/0369.bin", 0, 4
        .incbin "stock/0369.bin", 4, 4
        jmp     GK_STOCK_MACHINE_COMMIT_A_CONTINUE
        .global gk_machine_temporary_trampoline
gk_machine_temporary_trampoline:
        .incbin "stock/0370.bin", 0, 4
        .incbin "stock/0370.bin", 4, 4
        jmp     GK_STOCK_MACHINE_TEMPORARY_CONTINUE
        .global gk_machine_commit_b_trampoline
gk_machine_commit_b_trampoline:
        .incbin "stock/0371.bin", 0, 4
        .incbin "stock/0371.bin", 4, 4
        jmp     GK_STOCK_MACHINE_COMMIT_B_CONTINUE
        .global gk_machine_setup_trampoline
gk_machine_setup_trampoline:
        .incbin "stock/0372.bin", 0, 4
        .incbin "stock/0372.bin", 4, 4
        jmp     GK_STOCK_MACHINE_SETUP_CONTINUE
        .type   gk_machine_transition_count_increment,@function
gk_machine_transition_count_increment:
        moveq   #0,%d0
        move.b  __gk_machine_transition_count,%d0
        addq.l  #1,%d0
        cmpi.l  #8,%d0
        bhi.w   gk_machine_transition_fatal_marker
        move.b  %d0,__gk_machine_transition_count
        rts
        .size   gk_machine_transition_count_increment,.-gk_machine_transition_count_increment
        .type   gk_machine_transition_primary_marker_validate,@function
gk_machine_transition_primary_marker_validate:
        move.l  %d0,%d3
        bsr.w   gk_machine_transition_state_validate
        moveq   #0,%d1
        move.b  __gk_machine_transition_active,%d1
        moveq   #0,%d2
        move.b  __gk_machine_transition_stage,%d2
        cmpi.l  #GK_STOCK_MACHINE_UI_A_DIRTY_RETURN_0,%d3
        beq.w   .Lgk_mt_marker_ui_a_direct
        cmpi.l  #GK_STOCK_MACHINE_UI_A_DIRTY_RETURN_1,%d3
        beq.w   .Lgk_mt_marker_ui_a_outer
        cmpi.l  #GK_STOCK_MACHINE_CHOOSER_DIRTY_RETURN_0,%d3
        beq.w   .Lgk_mt_marker_nested_first
        cmpi.l  #GK_STOCK_MACHINE_CHOOSER_DIRTY_RETURN_1,%d3
        beq.w   .Lgk_mt_marker_nested_done
        cmpi.l  #GK_STOCK_MACHINE_UI_B_DIRTY_RETURN,%d3
        beq.w   .Lgk_mt_marker_ui_b_outer
        cmpi.l  #GK_STOCK_MACHINE_COMMIT_A_DIRTY_RETURN,%d3
        beq.w   .Lgk_mt_marker_commit_a
        cmpi.l  #GK_STOCK_MACHINE_TEMPORARY_DIRTY_RETURN,%d3
        beq.w   .Lgk_mt_marker_temporary
        cmpi.l  #GK_STOCK_MACHINE_COMMIT_B_DIRTY_RETURN,%d3
        beq.w   .Lgk_mt_marker_commit_b
        cmpi.l  #GK_STOCK_MACHINE_SETUP_DIRTY_RETURN,%d3
        beq.w   .Lgk_mt_marker_setup
        bra.w   gk_machine_transition_fatal_marker
.Lgk_mt_marker_ui_a_direct:
        cmpi.l  #GK_MT_KIND_UI_A,%d1
        bne.w   gk_machine_transition_fatal_marker
        tst.l   %d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_DIRECT,%d2
        bra.w   .Lgk_mt_marker_publish
.Lgk_mt_marker_ui_a_outer:
        cmpi.l  #GK_MT_KIND_UI_A,%d1
        bne.w   gk_machine_transition_fatal_marker
        tst.l   %d2
        beq.s   .Lgk_mt_marker_outer_ready
        cmpi.l  #GK_MT_STAGE_NESTED_DONE,%d2
        bne.w   gk_machine_transition_fatal_marker
.Lgk_mt_marker_outer_ready:
        moveq   #GK_MT_STAGE_OUTER,%d2
        bra.w   .Lgk_mt_marker_publish
.Lgk_mt_marker_nested_first:
        cmpi.l  #GK_MT_KIND_UI_A,%d1
        beq.s   .Lgk_mt_marker_nested_kind_ok
        cmpi.l  #GK_MT_KIND_UI_B,%d1
        bne.w   gk_machine_transition_fatal_marker
.Lgk_mt_marker_nested_kind_ok:
        tst.l   %d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_NESTED_FIRST,%d2
        bra.w   .Lgk_mt_marker_publish
.Lgk_mt_marker_nested_done:
        cmpi.l  #GK_MT_KIND_UI_A,%d1
        beq.s   .Lgk_mt_marker_nested_done_kind
        cmpi.l  #GK_MT_KIND_UI_B,%d1
        bne.w   gk_machine_transition_fatal_marker
.Lgk_mt_marker_nested_done_kind:
        cmpi.l  #GK_MT_STAGE_NESTED_FIRST,%d2
        beq.s   .Lgk_mt_marker_nested_done_ready
        cmpi.l  #GK_MT_STAGE_NESTED_HELPER,%d2
        bne.w   gk_machine_transition_fatal_marker
.Lgk_mt_marker_nested_done_ready:
        moveq   #GK_MT_STAGE_NESTED_DONE,%d2
        bra.s   .Lgk_mt_marker_publish
.Lgk_mt_marker_ui_b_outer:
        cmpi.l  #GK_MT_KIND_UI_B,%d1
        bne.w   gk_machine_transition_fatal_marker
        tst.l   %d2
        beq.s   .Lgk_mt_marker_ui_b_ready
        cmpi.l  #GK_MT_STAGE_NESTED_DONE,%d2
        bne.w   gk_machine_transition_fatal_marker
.Lgk_mt_marker_ui_b_ready:
        moveq   #GK_MT_STAGE_OUTER,%d2
        bra.s   .Lgk_mt_marker_publish
.Lgk_mt_marker_commit_a:
        cmpi.l  #GK_MT_KIND_COMMIT_A,%d1
        bne.w   gk_machine_transition_fatal_marker
        bra.s   .Lgk_mt_marker_simple
.Lgk_mt_marker_temporary:
        cmpi.l  #GK_MT_KIND_TEMPORARY,%d1
        bne.w   gk_machine_transition_fatal_marker
        bra.s   .Lgk_mt_marker_simple
.Lgk_mt_marker_commit_b:
        cmpi.l  #GK_MT_KIND_COMMIT_B,%d1
        bne.w   gk_machine_transition_fatal_marker
        bra.s   .Lgk_mt_marker_simple
.Lgk_mt_marker_setup:
        cmpi.l  #GK_MT_KIND_SETUP,%d1
        bne.w   gk_machine_transition_fatal_marker
.Lgk_mt_marker_simple:
        tst.l   %d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_DIRECT,%d2
.Lgk_mt_marker_publish:
        move.b  %d2,__gk_machine_transition_stage
        bsr.w   gk_machine_transition_count_increment
        rts
        .size   gk_machine_transition_primary_marker_validate,.-gk_machine_transition_primary_marker_validate
        .type   gk_machine_transition_helper_marker_validate,@function
gk_machine_transition_helper_marker_validate:
        move.l  %d0,%d3
        cmpi.l  #3,%d1
        bhi.w   gk_machine_transition_fatal_marker
        cmpi.l  #7,%d2
        bhi.w   gk_machine_transition_fatal_marker
        cmp.b   __gk_machine_transition_part,%d1
        bne.w   gk_machine_transition_fatal_marker
        cmp.b   __gk_machine_transition_track,%d2
        bne.w   gk_machine_transition_fatal_marker
        bsr.w   gk_machine_transition_state_validate
        moveq   #0,%d1
        move.b  __gk_machine_transition_active,%d1
        moveq   #0,%d2
        move.b  __gk_machine_transition_stage,%d2
        cmpi.l  #GK_STOCK_MACHINE_UI_A_HELPER_RETURN_0,%d3
        beq.w   .Lgk_mt_helper_ui_a_direct
        cmpi.l  #GK_STOCK_MACHINE_UI_A_HELPER_RETURN_1,%d3
        beq.w   .Lgk_mt_helper_ui_a_outer
        cmpi.l  #GK_STOCK_MACHINE_CHOOSER_HELPER_RETURN,%d3
        beq.w   .Lgk_mt_helper_nested
        cmpi.l  #GK_STOCK_MACHINE_UI_B_HELPER_RETURN,%d3
        beq.w   .Lgk_mt_helper_ui_b_outer
        cmpi.l  #GK_STOCK_MACHINE_COMMIT_A_HELPER_RETURN,%d3
        beq.w   .Lgk_mt_helper_commit_a
        cmpi.l  #GK_STOCK_MACHINE_TEMPORARY_HELPER_RETURN,%d3
        beq.w   .Lgk_mt_helper_temporary
        cmpi.l  #GK_STOCK_MACHINE_COMMIT_B_HELPER_RETURN,%d3
        beq.w   .Lgk_mt_helper_commit_b
        cmpi.l  #GK_STOCK_MACHINE_SETUP_HELPER_RETURN,%d3
        beq.w   .Lgk_mt_helper_setup
        cmpi.l  #gk_stock_part_event_machine_return,%d3
        beq.w   .Lgk_mt_helper_event
        bra.w   gk_machine_transition_fatal_marker
.Lgk_mt_helper_ui_a_direct:
        cmpi.l  #GK_MT_KIND_UI_A,%d1
        bne.w   gk_machine_transition_fatal_marker
        cmpi.l  #GK_MT_STAGE_DIRECT,%d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_DIRECT_HELPER,%d2
        bra.w   .Lgk_mt_helper_publish
.Lgk_mt_helper_ui_a_outer:
        cmpi.l  #GK_MT_KIND_UI_A,%d1
        bne.w   gk_machine_transition_fatal_marker
        cmpi.l  #GK_MT_STAGE_OUTER,%d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_OUTER_HELPER,%d2
        bra.w   .Lgk_mt_helper_publish
.Lgk_mt_helper_nested:
        cmpi.l  #GK_MT_KIND_UI_A,%d1
        beq.s   .Lgk_mt_helper_nested_kind
        cmpi.l  #GK_MT_KIND_UI_B,%d1
        bne.w   gk_machine_transition_fatal_marker
.Lgk_mt_helper_nested_kind:
        cmpi.l  #GK_MT_STAGE_NESTED_FIRST,%d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_NESTED_HELPER,%d2
        bra.w   .Lgk_mt_helper_publish
.Lgk_mt_helper_ui_b_outer:
        cmpi.l  #GK_MT_KIND_UI_B,%d1
        bne.w   gk_machine_transition_fatal_marker
        cmpi.l  #GK_MT_STAGE_OUTER,%d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_OUTER_HELPER,%d2
        bra.s   .Lgk_mt_helper_publish
.Lgk_mt_helper_commit_a:
        cmpi.l  #GK_MT_KIND_COMMIT_A,%d1
        bne.w   gk_machine_transition_fatal_marker
        bra.s   .Lgk_mt_helper_simple
.Lgk_mt_helper_temporary:
        cmpi.l  #GK_MT_KIND_TEMPORARY,%d1
        bne.w   gk_machine_transition_fatal_marker
        bra.s   .Lgk_mt_helper_simple
.Lgk_mt_helper_commit_b:
        cmpi.l  #GK_MT_KIND_COMMIT_B,%d1
        bne.w   gk_machine_transition_fatal_marker
        bra.s   .Lgk_mt_helper_simple
.Lgk_mt_helper_setup:
        cmpi.l  #GK_MT_KIND_SETUP,%d1
        bne.w   gk_machine_transition_fatal_marker
.Lgk_mt_helper_simple:
        cmpi.l  #GK_MT_STAGE_DIRECT,%d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_DIRECT_HELPER,%d2
        bra.s   .Lgk_mt_helper_publish
.Lgk_mt_helper_event:
        cmpi.l  #GK_MT_KIND_EVENT,%d1
        bne.w   gk_machine_transition_fatal_marker
        cmpi.l  #GK_MT_STAGE_EVENT_ARMED,%d2
        bne.w   gk_machine_transition_fatal_marker
        moveq   #GK_MT_STAGE_EVENT_WRITTEN,%d2
.Lgk_mt_helper_publish:
        move.b  %d2,__gk_machine_transition_stage
        bsr.w   gk_machine_transition_count_increment
        rts
        .size   gk_machine_transition_helper_marker_validate,.-gk_machine_transition_helper_marker_validate
        .global gk_machine_transition_dirty_marker_d1
        .type gk_machine_transition_dirty_marker_d1,@function
gk_machine_transition_dirty_marker_d1:
        cmpi.l #1,%d1
        bne.w gk_machine_transition_fatal_marker
        lea -GK_MT_MARKER_SAVE_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        move.l GK_MT_MARKER_SAVE_BYTES(%sp),%d0
        bsr.w gk_machine_transition_primary_marker_validate
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea GK_MT_MARKER_SAVE_BYTES(%sp),%sp
        .incbin "stock/0373.bin", 0, 6
        rts
        .size gk_machine_transition_dirty_marker_d1,.-gk_machine_transition_dirty_marker_d1
        .global gk_machine_transition_dirty_marker_d2
        .type gk_machine_transition_dirty_marker_d2,@function
gk_machine_transition_dirty_marker_d2:
        cmpi.l #1,%d2
        bne.w gk_machine_transition_fatal_marker
        lea -GK_MT_MARKER_SAVE_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        move.l GK_MT_MARKER_SAVE_BYTES(%sp),%d0
        bsr.w gk_machine_transition_primary_marker_validate
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea GK_MT_MARKER_SAVE_BYTES(%sp),%sp
        .incbin "stock/0374.bin", 0, 6
        rts
        .size gk_machine_transition_dirty_marker_d2,.-gk_machine_transition_dirty_marker_d2
        .global gk_machine_transition_dirty_marker_d3
        .type gk_machine_transition_dirty_marker_d3,@function
gk_machine_transition_dirty_marker_d3:
        cmpi.l #1,%d3
        bne.w gk_machine_transition_fatal_marker
        lea -GK_MT_MARKER_SAVE_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        move.l GK_MT_MARKER_SAVE_BYTES(%sp),%d0
        bsr.w gk_machine_transition_primary_marker_validate
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea GK_MT_MARKER_SAVE_BYTES(%sp),%sp
        .incbin "stock/0375.bin", 0, 6
        rts
        .size gk_machine_transition_dirty_marker_d3,.-gk_machine_transition_dirty_marker_d3
        .global gk_machine_transition_helper_dirty_marker_d1
        .type   gk_machine_transition_helper_dirty_marker_d1,@function
gk_machine_transition_helper_dirty_marker_d1:
        tst.b   __gk_machine_transition_active
        bne.s   .Lgk_mt_helper_marker_owned
        tst.b   __gk_machine_transition_active_inverse
        bne.w   gk_machine_transition_fatal_marker
        jmp     gk_page_clipboard_helper_marker_d1
.Lgk_mt_helper_marker_owned:
        cmpi.l  #1,%d1
        bne.w   gk_machine_transition_fatal_marker
        lea     -GK_MT_MARKER_SAVE_BYTES(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        move.l  GK_MT_MARKER_SAVE_BYTES(%sp),%d0
        cmpi.l  #GK_STOCK_MACHINE_HELPER_DIRTY_RETURN,%d0
        bne.w   gk_machine_transition_fatal_marker
        move.l  GK_MT_MARKER_SAVE_BYTES + 24(%sp),%d0
        move.l  GK_MT_MARKER_SAVE_BYTES + 28(%sp),%d1
        move.l  GK_MT_MARKER_SAVE_BYTES + 32(%sp),%d2
        bsr.w   gk_machine_transition_helper_marker_validate
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea     GK_MT_MARKER_SAVE_BYTES(%sp),%sp
        .incbin "stock/0376.bin", 0, 6
        rts
        .size   gk_machine_transition_helper_dirty_marker_d1,.-gk_machine_transition_helper_dirty_marker_d1
        .global gk_machine_transition_event_arm
        .type   gk_machine_transition_event_arm,@function
gk_machine_transition_event_arm:
        bsr.w   gk_machine_transition_state_validate
        moveq   #0,%d1
        move.b  __gk_machine_transition_active,%d1
        cmpi.l  #GK_MT_KIND_EVENT,%d1
        bne.w   gk_machine_transition_fatal_event
        tst.b   __gk_machine_transition_stage
        bne.w   gk_machine_transition_fatal_event
        moveq   #0,%d1
        move.b  __gk_machine_transition_event_index,%d1
        cmp.l   %d1,%d0
        bne.w   gk_machine_transition_fatal_event
        cmpi.l  #7,%d0
        bhi.w   gk_machine_transition_fatal_event
        move.b  %d0,__gk_machine_transition_track
        moveq   #GK_MT_STAGE_EVENT_ARMED,%d1
        move.b  %d1,__gk_machine_transition_stage
        rts
        .size   gk_machine_transition_event_arm,.-gk_machine_transition_event_arm
        .global gk_machine_transition_event_step_finish
        .type   gk_machine_transition_event_step_finish,@function
gk_machine_transition_event_step_finish:
        bsr.w   gk_machine_transition_state_validate
        moveq   #0,%d1
        move.b  __gk_machine_transition_active,%d1
        cmpi.l  #GK_MT_KIND_EVENT,%d1
        bne.w   gk_machine_transition_fatal_event
        cmp.b   __gk_machine_transition_track,%d0
        bne.w   gk_machine_transition_fatal_event
        moveq   #0,%d1
        move.b  __gk_machine_transition_stage,%d1
        cmpi.l  #GK_MT_STAGE_EVENT_ARMED,%d1
        beq.s   .Lgk_mt_event_step_ok
        cmpi.l  #GK_MT_STAGE_EVENT_WRITTEN,%d1
        bne.w   gk_machine_transition_fatal_event
.Lgk_mt_event_step_ok:
        clr.b   __gk_machine_transition_stage
        moveq   #0,%d1
        move.b  __gk_machine_transition_event_index,%d1
        addq.l  #1,%d1
        move.b  %d1,__gk_machine_transition_event_index
        rts
        .size   gk_machine_transition_event_step_finish,.-gk_machine_transition_event_step_finish
gk_machine_transition_fatal_release_abort_d0:
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_machine_transition_fatal
        bra.s gk_machine_transition_fatal_abort
gk_machine_transition_fatal_release_abort:
        move.l  %d6,%d0
        bra.s gk_machine_transition_fatal_release_abort_d0
gk_machine_transition_fatal_abort:
        jsr     gk_workspace_abort_update
        bsr.w   gk_machine_transition_state_clear
        bra.s gk_machine_transition_fatal
gk_machine_transition_fatal_abort_only:
        jsr     gk_workspace_abort_update
        bsr.w   gk_machine_transition_state_clear
        bra.s gk_machine_transition_fatal
gk_machine_transition_fatal_claimed:
        bsr.w   gk_machine_transition_state_clear
gk_machine_transition_fatal_entry:
gk_machine_transition_fatal_claim:
gk_machine_transition_fatal_state:
gk_machine_transition_fatal_finish:
gk_machine_transition_fatal_terminal:
gk_machine_transition_fatal_marker:
gk_machine_transition_fatal_event:
        .global gk_machine_transition_fatal
gk_machine_transition_fatal:
        illegal
        bra.s gk_machine_transition_fatal
