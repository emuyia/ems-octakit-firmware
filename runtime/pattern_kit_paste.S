        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_pattern_copy_capture
        .type   gk_stock_pattern_copy_capture,@function
gk_stock_pattern_copy_capture:
        move.l  4(%sp),-(%sp)
        bsr.w   gk_stock_pattern_copy_capture_trampoline
        addq.l  #4,%sp
        bra.w   gk_pattern_kit_capture_workspace
        .size   gk_stock_pattern_copy_capture,.-gk_stock_pattern_copy_capture
        .global gk_stock_pattern_copy_capture_trampoline
        .type   gk_stock_pattern_copy_capture_trampoline,@function
gk_stock_pattern_copy_capture_trampoline:
        .incbin "stock/0395.bin", 0, 4
        .incbin "stock/0395.bin", 4, 4
        .byte 0x8e,0xd8
        .global gk_stock_pattern_copy_capture_trampoline_jump
gk_stock_pattern_copy_capture_trampoline_jump:
        jmp     GK_STOCK_PATTERN_COPY_CAPTURE_CONTINUE
        .size   gk_stock_pattern_copy_capture_trampoline,.-gk_stock_pattern_copy_capture_trampoline
        .global gk_pattern_kit_capture_workspace
        .type   gk_pattern_kit_capture_workspace,@function
gk_pattern_kit_capture_workspace:
        .incbin "stock/0396.bin", 0, 4
        .incbin "stock/0396.bin", 4, 4
        clr.b   __gk_pattern_kit_valid
        clr.b   __gk_pattern_kit_armed
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_pattern_kit_capture_busy
        tst.l   __gk_persistence_snapshot_gate
        bne.w   .Lgk_pattern_kit_capture_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_pattern_kit_capture_busy
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_pattern_kit_capture_busy
        moveq   #0,%d2
        move.b  __gk_workspace_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_pattern_kit_capture_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0xef,%d1
        cmpi.l  #GK_DESC_WORKSPACE_STABLE,%d1
        bne.w   .Lgk_pattern_kit_capture_busy
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_pattern_kit_capture_corrupt
        lea     __gk_pattern_kit_payload,%a4
        movea.l %a4,%a0
        moveq   #GK_PATTERN_KIT_SPILL_ID,%d1
        move.l  %d2,%d0
        jsr     gk_descriptor_begin_copy
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_capture_restore
        move.l  %d2,%d0
        jsr     gk_descriptor_copy_payload
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_capture_restore
        move.w  %sr,%d5
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0xef,%d1
        cmpi.l  #0x0b,%d1
        bne.s   .Lgk_pattern_kit_capture_finish_corrupt
        cmpa.l  GK_DESC_CANDIDATE(%a2),%a4
        bne.s   .Lgk_pattern_kit_capture_finish_corrupt
        moveq   #0,%d1
        move.b  GK_DESC_SPILL(%a2),%d1
        cmpi.l  #GK_PATTERN_KIT_SPILL_ID,%d1
        bne.s   .Lgk_pattern_kit_capture_finish_corrupt
        clr.l   GK_DESC_CANDIDATE(%a2)
        move.b  #GK_ID_NONE,GK_DESC_SPILL(%a2)
        andi.l  #0xfd,%d0
        move.b  %d0,GK_DESC_FLAGS(%a2)
        move.l  __gk_workspace_name,%d0
        move.l  %d0,__gk_pattern_kit_name
        move.l  __gk_workspace_name + 4,%d0
        move.l  %d0,__gk_pattern_kit_name + 4
        moveq   #1,%d0
        move.b  %d0,__gk_pattern_kit_valid
        move.w  %d5,%sr
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pattern_kit_capture_restore
.Lgk_pattern_kit_capture_finish_corrupt:
        move.w  %d5,%sr
.Lgk_pattern_kit_capture_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_pattern_kit_capture_restore
.Lgk_pattern_kit_capture_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_pattern_kit_capture_restore:
        movem.l (%sp),%d2-%d5/%a2-%a4
        lea     28(%sp),%sp
        rts
        .size   gk_pattern_kit_capture_workspace,.-gk_pattern_kit_capture_workspace
        .global gk_pattern_kit_allocate
        .type   gk_pattern_kit_allocate,@function
gk_pattern_kit_allocate:
        lea     -24(%sp),%sp
        movem.l %d2-%d7,(%sp)
        lea     __gk_ui_referenced_bitmap,%a0
        moveq   #0,%d0
        moveq   #8,%d1
.Lgk_pattern_kit_refs_clear:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_pattern_kit_refs_clear
        moveq   #0,%d7
        move.b  __gk_current_bank,%d7
        lsl.l   #4,%d7
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        add.l   %d0,%d7
        moveq   #0,%d2
.Lgk_pattern_kit_ref_pattern_loop:
        cmp.l   %d7,%d2
        beq.s   .Lgk_pattern_kit_ref_pattern_next
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_pattern_assignment_valid,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_pattern_kit_ref_pattern_next
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d3
        move.b  (%a0,%d2.l),%d3
        move.l  %d3,%d0
        move.l  %d3,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_ui_referenced_bitmap,%a0
        bset    %d1,(%a0,%d0.l)
.Lgk_pattern_kit_ref_pattern_next:
        addq.l  #1,%d2
        cmpi.l  #GK_PATTERN_ASSIGNMENT_COUNT,%d2
        blo.s   .Lgk_pattern_kit_ref_pattern_loop
        moveq   #0,%d4
        move.b  __gk_current_kit,%d4
        addq.l  #1,%d4
        andi.l  #0xff,%d4
        moveq   #0,%d6
.Lgk_pattern_kit_candidate_pass:
        move.l  %d4,%d5
        moveq   #0,%d7
        move.w  #GK_KIT_COUNT - 1,%d7
.Lgk_pattern_kit_candidate_loop:
        move.l  %d5,%d0
        move.l  %d5,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_ui_referenced_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        bne.s   .Lgk_pattern_kit_candidate_next
        tst.l   %d6
        bne.s   .Lgk_pattern_kit_candidate_found
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_pattern_kit_candidate_found
.Lgk_pattern_kit_candidate_next:
        addq.l  #1,%d5
        andi.l  #0xff,%d5
        subq.l  #1,%d7
        bpl.s   .Lgk_pattern_kit_candidate_loop
        addq.l  #1,%d6
        cmpi.l  #2,%d6
        blo.s   .Lgk_pattern_kit_candidate_pass
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_pattern_kit_allocate_restore
.Lgk_pattern_kit_candidate_found:
        move.l  %d5,%d0
.Lgk_pattern_kit_allocate_restore:
        movem.l (%sp),%d2-%d7
        lea     24(%sp),%sp
        rts
        .size   gk_pattern_kit_allocate,.-gk_pattern_kit_allocate
        .type   gk_pattern_kit_rollback_capture,@function
gk_pattern_kit_rollback_capture:
        move.l  %d2,-(%sp)
        move.l  %a2,-(%sp)
        move.l  %d0,%d2
        move.b  %d2,__gk_pattern_kit_rollback_target
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_pattern_kit_rollback_empty
        moveq   #1,%d0
        move.b  %d0,__gk_pattern_kit_rollback_occupied
        move.l  %d2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a0
        adda.l  %d0,%a0
        lea     __gk_pattern_kit_rollback_payload,%a1
        jsr     gk_copy_payload_interruptible
        move.l  %d2,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a2
        adda.l  %d0,%a2
        move.l  (%a2),%d0
        move.l  %d0,__gk_pattern_kit_rollback_name
        move.l  4(%a2),%d0
        move.l  %d0,__gk_pattern_kit_rollback_name + 4
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pattern_kit_rollback_capture_restore
.Lgk_pattern_kit_rollback_empty:
        clr.b   __gk_pattern_kit_rollback_occupied
        clr.l   __gk_pattern_kit_rollback_name
        clr.l   __gk_pattern_kit_rollback_name + 4
        moveq   #GK_OK,%d0
.Lgk_pattern_kit_rollback_capture_restore:
        move.l  (%sp)+,%a2
        move.l  (%sp)+,%d2
        rts
        .size   gk_pattern_kit_rollback_capture,.-gk_pattern_kit_rollback_capture
        .type   gk_pattern_kit_record_apply,@function
gk_pattern_kit_record_apply:
        moveq   #1,%d1
        lea     __gk_pattern_kit_payload,%a0
        lea     __gk_pattern_kit_name,%a1
        jmp     gk_kit_record_apply
        .size   gk_pattern_kit_record_apply,.-gk_pattern_kit_record_apply
        .type   gk_pattern_kit_rollback_apply,@function
gk_pattern_kit_rollback_apply:
        moveq   #0,%d0
        move.b  __gk_pattern_kit_rollback_target,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_rollback_occupied,%d1
        tst.l   %d1
        beq.s   .Lgk_pattern_kit_rollback_apply_empty
        lea     __gk_pattern_kit_rollback_payload,%a0
        lea     __gk_pattern_kit_rollback_name,%a1
        jmp     gk_kit_record_apply
.Lgk_pattern_kit_rollback_apply_empty:
        lea     __gk_default_payload,%a0
        lea     __gk_pattern_kit_rollback_name,%a1
        jmp     gk_kit_record_apply
        .size   gk_pattern_kit_rollback_apply,.-gk_pattern_kit_rollback_apply
        .global gk_pattern_kit_paste_dispatch
        .type   gk_pattern_kit_paste_dispatch,@function
gk_pattern_kit_paste_dispatch:
        moveq   #1,%d0
        cmp.l   12(%sp),%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled
        .incbin "stock/0397.bin", 0, 4
        .incbin "stock/0397.bin", 4, 4
        jsr     gk_function_map_active
        tst.l   %d0
        beq.w   .Lgk_pattern_kit_paste_not_handled_restore
        .incbin "stock/0398.bin", 0, 4
        .incbin "stock/0398.bin", 4, 6
        .incbin "stock/0398.bin", 10, 2
        .incbin "stock/0398.bin", 12, 2
        .incbin "stock/0398.bin", 14, 2
        .byte 0x01,0x92
        pea     GK_STOCK_PASTE_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.w   .Lgk_pattern_kit_paste_not_handled_restore
        moveq   #0,%d0
        move.b  __gk_pattern_kit_valid,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        moveq   #0,%d0
        move.b  __gk_pattern_kit_armed,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        tst.l   __gk_lifecycle_state
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        tst.b   __gk_ui_mode
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        tst.l   GK_STOCK_CALLBACK_MENU_OBJECT
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_bank,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_pattern,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_pattern_kit_paste_not_handled_restore
        bsr.w   gk_pattern_kit_allocate
        tst.l   %d0
        bmi.w   .Lgk_pattern_kit_paste_finish
        move.l  %d0,%d4
        jsr     gk_persistence_snapshot_begin
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_paste_finish
        move.l  %d4,%d0
        bsr.w   gk_pattern_kit_rollback_capture
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_paste_snapshot_abort
        move.l  %d4,%d0
        bsr.w   gk_pattern_kit_record_apply
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_paste_snapshot_abort
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.w   .Lgk_pattern_kit_paste_finish
        moveq   #0,%d2
        move.b  __gk_current_bank,%d2
        moveq   #0,%d3
        move.b  __gk_current_pattern,%d3
        move.l  %d2,%d0
        move.l  %d3,%d1
        move.l  %d4,%d2
        jsr     gk_stock_load_kit_transaction
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_rollback
        moveq   #0,%d1
        move.b  __gk_current_bank,%d1
        moveq   #1,%d0
        lsl.l   %d1,%d0
        jsr     gk_stock_dirty_mark_bank_mask
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_finish
        clr.b   __gk_pattern_kit_armed
        moveq   #GK_OK,%d0
        bra.s   .Lgk_pattern_kit_paste_finish
.Lgk_pattern_kit_paste_rollback:
        move.l  %d0,%d5
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_bank,%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_pattern_kit_paste_rollback_record
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        moveq   #0,%d1
        move.b  __gk_pattern_kit_pattern,%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_pattern_kit_paste_rollback_record
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   %d4,%d0
        beq.s   .Lgk_pattern_kit_paste_late_failure
.Lgk_pattern_kit_paste_rollback_record:
        jsr     gk_persistence_snapshot_begin
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_corrupt
        bsr.w   gk_pattern_kit_rollback_apply
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_snapshot_abort_corrupt
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_corrupt
        move.l  %d5,%d0
        bra.s   .Lgk_pattern_kit_paste_finish
.Lgk_pattern_kit_paste_late_failure:
        move.l  %d5,%d0
        bra.s   .Lgk_pattern_kit_paste_finish
.Lgk_pattern_kit_paste_snapshot_abort_corrupt:
        jsr     gk_persistence_snapshot_end
.Lgk_pattern_kit_paste_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_pattern_kit_paste_finish
.Lgk_pattern_kit_paste_snapshot_abort:
        move.l  %d0,%d5
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_paste_corrupt
        move.l  %d5,%d0
.Lgk_pattern_kit_paste_finish:
        move.l  %d0,%d4
        clr.b   __gk_pattern_kit_armed
        move.l  %d4,%d0
        lea     .Lgk_pattern_kit_paste_message,%a0
        jsr     gk_part_edit_notify_result
        moveq   #0,%d0
        bra.s   .Lgk_pattern_kit_paste_restore
.Lgk_pattern_kit_paste_not_handled_restore:
        moveq   #1,%d0
.Lgk_pattern_kit_paste_restore:
        movem.l (%sp),%d2-%d7/%a2-%a3
        lea     32(%sp),%sp
        rts
.Lgk_pattern_kit_paste_not_handled:
        moveq   #1,%d0
        rts
        .size   gk_pattern_kit_paste_dispatch,.-gk_pattern_kit_paste_dispatch
        .align  4
.Lgk_pattern_kit_paste_message:
        .byte 0x4b,0x49,0x54,0x20
        .incbin "stock/0399.bin", 0, 5
        .byte 0x44,0x00
        .align  4
        .global gk_pattern_kit_mkii_part_dispatch
        .type   gk_pattern_kit_mkii_part_dispatch,@function
gk_pattern_kit_mkii_part_dispatch:
        bsr.w   gk_pattern_kit_paste_dispatch
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_mkii_part_stock
        rts
.Lgk_pattern_kit_mkii_part_stock:
        moveq   #GK_QUICK_SAVE_INITIATOR_PART,%d0
        move.b  %d0,__gk_ui_state_pad + 2
        .byte 0x4e,0xf9
        .incbin "stock/0400.bin", 0, 4
        .size   gk_pattern_kit_mkii_part_dispatch,.-gk_pattern_kit_mkii_part_dispatch
        .align  4
        .global gk_pattern_kit_mki_part_dispatch
        .type   gk_pattern_kit_mki_part_dispatch,@function
gk_pattern_kit_mki_part_dispatch:
        bsr.w   gk_pattern_kit_paste_dispatch
        tst.l   %d0
        bne.s   .Lgk_pattern_kit_mki_part_stock
        rts
.Lgk_pattern_kit_mki_part_stock:
        .byte 0x4e,0xf9
        .incbin "stock/0401.bin", 0, 4
        .size   gk_pattern_kit_mki_part_dispatch,.-gk_pattern_kit_mki_part_dispatch
        .global gk_pattern_kit_mki_part_lifecycle_dispatch
        .type   gk_pattern_kit_mki_part_lifecycle_dispatch,@function
gk_pattern_kit_mki_part_lifecycle_dispatch:
        lea     -12(%sp),%sp
        moveq   #1,%d0
        move.l  %d0,8(%sp)
        bsr.w   gk_pattern_kit_paste_dispatch
        lea     12(%sp),%sp
        rts
        .size   gk_pattern_kit_mki_part_lifecycle_dispatch,.-gk_pattern_kit_mki_part_lifecycle_dispatch
