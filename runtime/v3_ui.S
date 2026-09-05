        .include "abi.inc"
        .section .runtime,"ax"
        .global gk_kit_v4_ui_marker
        .set    gk_kit_v4_ui_marker,1
        .global gk_kit_v5_ui_marker
        .set    gk_kit_v5_ui_marker,1
        .global gk_kit_v6_ui_marker
        .set    gk_kit_v6_ui_marker,1
        .global gk_kit_v7_ui_marker
        .set    gk_kit_v7_ui_marker,1
        .global gk_kit_v8_ui_marker
        .set    gk_kit_v8_ui_marker,1
        .global gk_unnamed_quick_save_marker
        .set    gk_unnamed_quick_save_marker,1
        .align  4
        .global gk_stock_engine_context_validate_and_retry
        .type   gk_stock_engine_context_validate_and_retry,@function
gk_stock_engine_context_validate_and_retry:
        jsr     gk_stock_engine_context_validate
        tst.l   %d0
        bne.s   .Lgk_load_retry_return
        jsr     GK_STOCK_CLIPBOARD_RESET
        jsr     gk_ui_transition_retry_ensure
.Lgk_load_retry_return:
        addq.l  #4,%sp
        jmp     gk_stock_load_transaction_restore
        .size   gk_stock_engine_context_validate_and_retry,.-gk_stock_engine_context_validate_and_retry
        .align  4
        .global gk_stock_part_status_format_v3
        .type   gk_stock_part_status_format_v3,@function
gk_stock_part_status_format_v3:
        lea     12(%sp),%sp
        jmp     gk_stock_part_status_format
        .size   gk_stock_part_status_format_v3,.-gk_stock_part_status_format_v3
        .align  4
        .global gk_kit_list_context_owned
        .type   gk_kit_list_context_owned,@function
gk_kit_list_context_owned:
        tst.l   GK_STOCK_CALLBACK_MENU_OBJECT
        beq.w   .Lgk_kit_list_context_not_owned
        movea.l #GK_STOCK_SCROLLING_CALLBACK_MENU_INPUT_MAP,%a0
        jsr     gk_stock_input_map_registered
        cmpi.l  #1,%d0
        bne.w   .Lgk_kit_list_context_not_owned
        movea.l GK_STOCK_CALLBACK_MENU_CALLBACKS,%a0
        cmpa.l  #__gk_ui_callback_pointers,%a0
        beq.s   .Lgk_kit_list_context_load_candidate
        cmpa.l  #__gk_ui_callback_pointers + 4,%a0
        bne.s   .Lgk_kit_list_context_not_owned
        movea.l GK_STOCK_CALLBACK_MENU_LABELS,%a1
        cmpa.l  #__gk_ui_label_pointers + 4,%a1
        bne.s   .Lgk_kit_list_context_not_owned
        movea.l GK_STOCK_CALLBACK_MENU_SELECTION,%a1
        cmpa.l  #__gk_ui_selected_kit,%a1
        bne.s   .Lgk_kit_list_context_not_owned
        move.l  GK_STOCK_CALLBACK_MENU_COUNT,%d0
        cmpi.l  #GK_KIT_COUNT,%d0
        bne.s   .Lgk_kit_list_context_not_owned
        move.l  (%a0),%d1
        cmpi.l  #gk_save_as_menu_confirm,%d1
        bne.s   .Lgk_kit_list_context_not_owned
        moveq   #GK_UI_MODE_SAVE_AS,%d0
        bra.w   .Lgk_kit_list_context_check_mode
.Lgk_kit_list_context_load_candidate:
        movea.l GK_STOCK_CALLBACK_MENU_LABELS,%a1
        cmpa.l  #__gk_ui_label_pointers,%a1
        bne.s   .Lgk_kit_list_context_not_owned
        movea.l GK_STOCK_CALLBACK_MENU_SELECTION,%a1
        cmpa.l  #__gk_ui_selected_row,%a1
        bne.s   .Lgk_kit_list_context_not_owned
        move.l  GK_STOCK_CALLBACK_MENU_COUNT,%d0
        cmpi.l  #GK_KIT_COUNT + 1,%d0
        bne.s   .Lgk_kit_list_context_not_owned
        move.l  (%a0),%d1
        cmpi.l  #gk_load_kit_menu_confirm,%d1
        bne.s   .Lgk_kit_list_context_not_owned
        moveq   #GK_UI_MODE_LOAD,%d0
        bra.w   .Lgk_kit_list_context_check_mode
.Lgk_kit_list_context_check_mode:
        cmp.b   __gk_ui_mode,%d0
        bne.s   .Lgk_kit_list_context_not_owned
        rts
.Lgk_kit_list_context_not_owned:
        moveq   #0,%d0
        rts
        .size   gk_kit_list_context_owned,.-gk_kit_list_context_owned
        .global gk_kit_list_owned
        .type   gk_kit_list_owned,@function
gk_kit_list_owned:
        bsr.w   gk_kit_list_context_owned
        tst.l   %d0
        beq.s   .Lgk_kit_list_owned_return
        moveq   #1,%d0
        cmp.l   12(%sp),%d0
        beq.s   .Lgk_kit_list_owned_return
        moveq   #0,%d0
.Lgk_kit_list_owned_return:
        rts
        .size   gk_kit_list_owned,.-gk_kit_list_owned
        .type   gk_kit_list_target_validate,@function
gk_kit_list_target_validate:
        jsr     gk_ui_snapshot_context_validate
        tst.l   %d0
        bmi.s   .Lgk_kit_list_target_return
        move.l  GK_STOCK_CALLBACK_MENU_ABSOLUTE_SELECTION,%d0
        moveq   #0,%d1
        move.b  __gk_ui_mode,%d1
        cmpi.l  #GK_UI_MODE_LOAD,%d1
        bne.s   .Lgk_kit_list_target_save
        tst.l   %d0
        beq.s   .Lgk_kit_list_target_invalid
        subq.l  #1,%d0
.Lgk_kit_list_target_save:
        cmpi.l  #GK_KIT_COUNT - 1,%d0
        bhi.s   .Lgk_kit_list_target_range
        rts
.Lgk_kit_list_target_invalid:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_kit_list_target_return
.Lgk_kit_list_target_range:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_kit_list_target_return:
        rts
        .size   gk_kit_list_target_validate,.-gk_kit_list_target_validate
        .type   gk_kit_record_capture,@function
gk_kit_record_capture:
        move.l  %d0,%d2
        movea.l %a2,%a3
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        moveq   #0,%d3
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_kit_record_capture_default
        moveq   #1,%d3
        move.l  %d2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a0
        adda.l  %d0,%a0
        bra.s   .Lgk_kit_record_capture_payload
.Lgk_kit_record_capture_default:
        lea     __gk_default_payload,%a0
.Lgk_kit_record_capture_payload:
        jsr     gk_copy_payload_interruptible
        tst.l   %d3
        beq.s   .Lgk_kit_record_capture_empty_name
        move.l  %d2,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a0
        adda.l  %d0,%a0
        move.l  (%a0),(%a3)
        move.l  4(%a0),4(%a3)
        bra.s   .Lgk_kit_record_capture_done
.Lgk_kit_record_capture_empty_name:
        clr.l   (%a3)
        clr.l   4(%a3)
.Lgk_kit_record_capture_done:
        move.l  %d3,%d0
        rts
        .size   gk_kit_record_capture,.-gk_kit_record_capture
        .global gk_kit_record_apply
        .type   gk_kit_record_apply,@function
gk_kit_record_apply:
        move.l  %d0,%d2
        move.l  %d1,%d3
        movea.l %a1,%a2
        move.l  %d2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a1
        adda.l  %d0,%a1
        jsr     gk_copy_payload_interruptible
        move.l  %d2,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a0
        adda.l  %d0,%a0
        tst.l   %d3
        beq.s   .Lgk_kit_record_apply_empty
        move.l  (%a2),(%a0)
        move.l  4(%a2),4(%a0)
        bra.s   .Lgk_kit_record_apply_bitmap
.Lgk_kit_record_apply_empty:
        clr.l   (%a0)
        clr.l   4(%a0)
.Lgk_kit_record_apply_bitmap:
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        tst.l   %d3
        beq.s   .Lgk_kit_record_apply_clear_bit
        bset    %d1,(%a0,%d0.l)
        bra.s   .Lgk_kit_record_apply_dirty
.Lgk_kit_record_apply_clear_bit:
        bclr    %d1,(%a0,%d0.l)
.Lgk_kit_record_apply_dirty:
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        ori.l   #GK_RUNTIME_STORAGE_DIRTY,%d0
        move.b  %d0,__gk_runtime_flags
        move.l  %d2,%d0
        .global gk_kit_record_v3_dirty_call
gk_kit_record_v3_dirty_call:
        jsr     gk_persistence_v3_mark_kit_dirty
        moveq   #GK_OK,%d0
        rts
        .size   gk_kit_record_apply,.-gk_kit_record_apply
        .type   gk_kit_list_refresh_rows,@function
gk_kit_list_refresh_rows:
        moveq   #0,%d0
        move.b  __gk_ui_mode,%d0
        cmpi.l  #GK_UI_MODE_LOAD,%d0
        bne.s   .Lgk_kit_list_refresh_save_selection
        move.l  __gk_ui_selected_row,%d2
        bra.s   .Lgk_kit_list_refresh_selection_ready
.Lgk_kit_list_refresh_save_selection:
        move.l  __gk_ui_selected_kit,%d2
.Lgk_kit_list_refresh_selection_ready:
        movea.l GK_STOCK_CALLBACK_MENU_CALLBACKS,%a2
        movea.l (%a2),%a0
        jsr     gk_ui_prepare_kit_tables
        moveq   #0,%d0
        move.b  __gk_ui_mode,%d0
        cmpi.l  #GK_UI_MODE_LOAD,%d0
        bne.s   .Lgk_kit_list_refresh_restore_save
        move.l  %d2,__gk_ui_selected_row
        bra.s   .Lgk_kit_list_refresh_selection_restored
.Lgk_kit_list_refresh_restore_save:
        move.l  %d2,__gk_ui_selected_kit
.Lgk_kit_list_refresh_selection_restored:
        .global gk_kit_list_stock_refresh_call
gk_kit_list_stock_refresh_call:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_REFRESH
        moveq   #GK_OK,%d0
        rts
        .size   gk_kit_list_refresh_rows,.-gk_kit_list_refresh_rows
        .align  4
        .global gk_kit_list_copy
        .type   gk_kit_list_copy,@function
gk_kit_list_copy:
        .incbin "stock/0345.bin", 0, 4
        .incbin "stock/0345.bin", 4, 4
        bsr.w   gk_kit_list_target_validate
        tst.l   %d0
        bmi.s   .Lgk_kit_list_copy_restore
        move.l  %d0,%d2
        jsr     gk_persistence_snapshot_begin
        tst.l   %d0
        bne.s   .Lgk_kit_list_copy_restore
        move.l  %d2,%d0
        lea     __gk_kit_clipboard_payload,%a1
        lea     __gk_kit_clipboard_name,%a2
        bsr.w   gk_kit_record_capture
        move.b  %d0,__gk_kit_clipboard_occupied
        clr.b   __gk_kit_undo_valid
        moveq   #1,%d0
        move.b  %d0,__gk_kit_clipboard_valid
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.s   .Lgk_kit_list_copy_restore
        lea     .Lgk_kit_list_message_copy,%a0
        jsr     gk_part_edit_notify_result
.Lgk_kit_list_copy_restore:
        movem.l (%sp),%d2-%d3/%a2-%a3
        lea     16(%sp),%sp
        rts
        .size   gk_kit_list_copy,.-gk_kit_list_copy
        .type   gk_kit_list_mutate,@function
gk_kit_list_mutate:
        lea     -28(%sp),%sp
        movem.l %d2-%d6/%a2-%a3,(%sp)
        move.l  %d0,%d4
        move.l  %d1,%d5
        cmpi.l  #GK_KIT_CLIPBOARD_ACTION_PASTE,%d5
        beq.s   .Lgk_kit_list_mutate_action_valid
        cmpi.l  #GK_KIT_CLIPBOARD_ACTION_CLEAR,%d5
        bne.w   .Lgk_kit_list_mutate_range
.Lgk_kit_list_mutate_action_valid:
        moveq   #0,%d0
        move.b  __gk_kit_undo_valid,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_kit_list_mutate_corrupt
        moveq   #0,%d6
        tst.l   %d0
        beq.s   .Lgk_kit_list_mutate_check_clipboard
        moveq   #0,%d0
        move.b  __gk_kit_undo_action,%d0
        cmp.l   %d5,%d0
        bne.s   .Lgk_kit_list_mutate_check_clipboard
        moveq   #0,%d0
        move.b  __gk_kit_undo_target,%d0
        cmp.l   %d4,%d0
        bne.s   .Lgk_kit_list_mutate_check_clipboard
        moveq   #1,%d6
.Lgk_kit_list_mutate_check_clipboard:
        cmpi.l  #GK_KIT_CLIPBOARD_ACTION_PASTE,%d5
        bne.s   .Lgk_kit_list_mutate_check_occupied
        moveq   #0,%d0
        move.b  __gk_kit_clipboard_valid,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_kit_list_mutate_invalid_or_corrupt
.Lgk_kit_list_mutate_check_occupied:
        tst.l   %d6
        beq.s   .Lgk_kit_list_mutate_check_new_occupied
        moveq   #0,%d0
        move.b  __gk_kit_undo_occupied,%d0
        bra.s   .Lgk_kit_list_mutate_occupied_ready
.Lgk_kit_list_mutate_check_new_occupied:
        cmpi.l  #GK_KIT_CLIPBOARD_ACTION_CLEAR,%d5
        beq.s   .Lgk_kit_list_mutate_begin
        moveq   #0,%d0
        move.b  __gk_kit_clipboard_occupied,%d0
.Lgk_kit_list_mutate_occupied_ready:
        cmpi.l  #1,%d0
        bhi.w   .Lgk_kit_list_mutate_corrupt
.Lgk_kit_list_mutate_begin:
        jsr     gk_persistence_snapshot_begin
        tst.l   %d0
        bne.w   .Lgk_kit_list_mutate_restore
        tst.l   %d6
        bne.s   .Lgk_kit_list_mutate_undo
        move.l  %d4,%d0
        lea     __gk_kit_undo_payload,%a1
        lea     __gk_kit_undo_name,%a2
        bsr.w   gk_kit_record_capture
        move.b  %d0,__gk_kit_undo_occupied
        move.b  %d5,__gk_kit_undo_action
        move.b  %d4,__gk_kit_undo_target
        cmpi.l  #GK_KIT_CLIPBOARD_ACTION_CLEAR,%d5
        beq.s   .Lgk_kit_list_mutate_clear
        moveq   #0,%d3
        move.b  __gk_kit_clipboard_occupied,%d3
        lea     __gk_kit_clipboard_payload,%a0
        lea     __gk_kit_clipboard_name,%a1
        bra.s   .Lgk_kit_list_mutate_apply
.Lgk_kit_list_mutate_clear:
        moveq   #0,%d3
        lea     __gk_default_payload,%a0
        lea     __gk_kit_clipboard_name,%a1
.Lgk_kit_list_mutate_apply:
        move.l  %d4,%d0
        move.l  %d3,%d1
        bsr.w   gk_kit_record_apply
        moveq   #1,%d0
        move.b  %d0,__gk_kit_undo_valid
        bra.s   .Lgk_kit_list_mutate_release
.Lgk_kit_list_mutate_undo:
        moveq   #0,%d3
        move.b  __gk_kit_undo_occupied,%d3
        move.l  %d4,%d0
        move.l  %d3,%d1
        lea     __gk_kit_undo_payload,%a0
        lea     __gk_kit_undo_name,%a1
        bsr.w   gk_kit_record_apply
        clr.b   __gk_kit_undo_valid
.Lgk_kit_list_mutate_release:
        jsr     gk_persistence_snapshot_end
        tst.l   %d0
        bne.s   .Lgk_kit_list_mutate_restore
        jsr     gk_stock_dirty_mark_current
        tst.l   %d0
        bne.s   .Lgk_kit_list_mutate_restore
        bsr.w   gk_kit_list_refresh_rows
        tst.l   %d6
        bne.s   .Lgk_kit_list_mutate_notify_undo
        cmpi.l  #GK_KIT_CLIPBOARD_ACTION_PASTE,%d5
        beq.s   .Lgk_kit_list_mutate_notify_paste
        lea     .Lgk_kit_list_message_clear,%a0
        bra.s   .Lgk_kit_list_mutate_notify
.Lgk_kit_list_mutate_notify_paste:
        lea     .Lgk_kit_list_message_paste,%a0
        bra.s   .Lgk_kit_list_mutate_notify
.Lgk_kit_list_mutate_notify_undo:
        lea     GK_STOCK_UNDO_TEXT,%a0
.Lgk_kit_list_mutate_notify:
        jsr     gk_part_edit_notify_result
        bra.s   .Lgk_kit_list_mutate_restore
.Lgk_kit_list_mutate_invalid_or_corrupt:
        tst.l   %d0
        beq.s   .Lgk_kit_list_mutate_invalid
.Lgk_kit_list_mutate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_kit_list_mutate_restore
.Lgk_kit_list_mutate_invalid:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_kit_list_mutate_restore
.Lgk_kit_list_mutate_range:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_kit_list_mutate_restore:
        movem.l (%sp),%d2-%d6/%a2-%a3
        lea     28(%sp),%sp
        rts
        .size   gk_kit_list_mutate,.-gk_kit_list_mutate
        .align  4
        .global gk_kit_list_paste
        .type   gk_kit_list_paste,@function
gk_kit_list_paste:
        bsr.w   gk_kit_list_target_validate
        tst.l   %d0
        bmi.s   .Lgk_kit_list_paste_return
        moveq   #GK_KIT_CLIPBOARD_ACTION_PASTE,%d1
        bra.w   gk_kit_list_mutate
.Lgk_kit_list_paste_return:
        rts
        .size   gk_kit_list_paste,.-gk_kit_list_paste
        .align  4
        .global gk_kit_list_clear
        .type   gk_kit_list_clear,@function
gk_kit_list_clear:
        bsr.w   gk_kit_list_target_validate
        tst.l   %d0
        bmi.s   .Lgk_kit_list_clear_return
        moveq   #GK_KIT_CLIPBOARD_ACTION_CLEAR,%d1
        bra.w   gk_kit_list_mutate
.Lgk_kit_list_clear_return:
        rts
        .size   gk_kit_list_clear,.-gk_kit_list_clear
        .align 4
        .global gk_kit_list_copy_dispatch
        .type gk_kit_list_copy_dispatch,@function
gk_kit_list_copy_dispatch:
        bsr.w gk_kit_list_owned
        tst.l %d0
        beq.s .Lstock_gk_kit_list_copy_dispatch
        jmp gk_kit_list_copy
.Lstock_gk_kit_list_copy_dispatch:
        jmp gk_stock_global_copy_callback_trampoline
        .size gk_kit_list_copy_dispatch,.-gk_kit_list_copy_dispatch
        .align 4
        .global gk_kit_list_clear_dispatch
        .type gk_kit_list_clear_dispatch,@function
gk_kit_list_clear_dispatch:
        bsr.w gk_kit_list_owned
        tst.l %d0
        beq.s .Lstock_gk_kit_list_clear_dispatch
        jmp gk_kit_list_clear
.Lstock_gk_kit_list_clear_dispatch:
        jmp gk_stock_global_clear_callback_trampoline
        .size gk_kit_list_clear_dispatch,.-gk_kit_list_clear_dispatch
        .align  4
        .global gk_kit_list_paste_dispatch
        .type   gk_kit_list_paste_dispatch,@function
gk_kit_list_paste_dispatch:
        tst.l   8(%sp)
        bne.s   .Lgk_kit_list_pattern_paste_press
        clr.b   __gk_pattern_kit_armed
.Lgk_kit_list_pattern_paste_press:
        bsr.w   gk_kit_list_owned
        tst.l   %d0
        beq.s   .Lgk_kit_list_pattern_paste_stock
        jmp     gk_kit_list_paste
.Lgk_kit_list_pattern_paste_stock:
        jmp     gk_stock_global_paste_callback_trampoline
        .size   gk_kit_list_paste_dispatch,.-gk_kit_list_paste_dispatch
        .align 4
        .global gk_stock_global_copy_callback_trampoline
        .type gk_stock_global_copy_callback_trampoline,@function
gk_stock_global_copy_callback_trampoline:
        .incbin "stock/0346.bin", 0, 2
        .incbin "stock/0346.bin", 2, 2
        .incbin "stock/0346.bin", 4, 4
        jmp GK_STOCK_GLOBAL_COPY_CALLBACK_CONTINUE
        .size gk_stock_global_copy_callback_trampoline,.-gk_stock_global_copy_callback_trampoline
        .align 4
        .global gk_stock_global_clear_callback_trampoline
        .type gk_stock_global_clear_callback_trampoline,@function
gk_stock_global_clear_callback_trampoline:
        .incbin "stock/0347.bin", 0, 2
        .incbin "stock/0347.bin", 2, 2
        .incbin "stock/0347.bin", 4, 4
        jmp GK_STOCK_GLOBAL_CLEAR_CALLBACK_CONTINUE
        .size gk_stock_global_clear_callback_trampoline,.-gk_stock_global_clear_callback_trampoline
        .align 4
        .global gk_stock_global_paste_callback_trampoline
        .type gk_stock_global_paste_callback_trampoline,@function
gk_stock_global_paste_callback_trampoline:
        .incbin "stock/0348.bin", 0, 2
        .incbin "stock/0348.bin", 2, 2
        .incbin "stock/0348.bin", 4, 4
        jmp GK_STOCK_GLOBAL_PASTE_CALLBACK_CONTINUE
        .size gk_stock_global_paste_callback_trampoline,.-gk_stock_global_paste_callback_trampoline
        .global gk_kit_list_render_dispatch
        .type   gk_kit_list_render_dispatch,@function
gk_kit_list_render_dispatch:
        move.l  (%sp),%d0
        cmpi.l  #GK_STOCK_SCROLLING_CALLBACK_MENU_CANCEL_RETURN,%d0
        bne.s   .Lgk_kit_list_render_normal_v7
        addq.l  #4,%sp
        bsr.w   gk_kit_list_context_owned
        tst.l   %d0
        beq.s   .Lgk_kit_list_cancel_stock_v7
        .global gk_kit_list_v7_cancel_stock_menu_close_call
gk_kit_list_v7_cancel_stock_menu_close_call:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE
        clr.b   __gk_ui_mode
        moveq   #GK_OK,%d0
        rts
.Lgk_kit_list_cancel_stock_v7:
        jmp     GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE
.Lgk_kit_list_render_normal_v7:
        bsr.w   gk_kit_list_context_owned
        tst.l   %d0
        bne.s   .Lgk_kit_list_render_owned
        bra.w   gk_stock_scrolling_callback_menu_refresh
.Lgk_kit_list_render_owned:
        move.l  %d2,-(%sp)
        move.l  %a2,-(%sp)
        movea.l GK_STOCK_CALLBACK_MENU_OBJECT,%a2
        moveq   #6,%d0
        cmp.l   GK_STOCK_CALLBACK_MENU_VISIBLE_COUNT,%d0
        beq.s   .Lgk_kit_list_render_rows
        move.l  0x24(%a2),%d2
        .global gk_kit_list_v7_stock_menu_close_call
gk_kit_list_v7_stock_menu_close_call:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE
        pea     GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE
        pea     (3).w
        clr.l   -(%sp)
        clr.l   -(%sp)
        pea     (57).w
        move.l  %d2,-(%sp)
        .global gk_kit_list_v7_stock_popup_create_call
gk_kit_list_v7_stock_popup_create_call:
        .incbin "stock/0349.bin", 0, 6
        lea     24(%sp),%sp
        move.l  %d0,GK_STOCK_CALLBACK_MENU_OBJECT
        movea.l %d0,%a2
        nop
        .global gk_kit_list_v7_stock_popup_frame_call
gk_kit_list_v7_stock_popup_frame_call:
        nop
        nop
        nop
        nop
        pea     GK_STOCK_SCROLLING_CALLBACK_MENU_INPUT_MAP
        .global gk_kit_list_v7_stock_input_register_call
gk_kit_list_v7_stock_input_register_call:
        jsr     GK_STOCK_INPUT_MAP_REGISTER
        addq.l  #4,%sp
        moveq   #6,%d0
        move.l  %d0,GK_STOCK_CALLBACK_MENU_VISIBLE_COUNT
        move.l  GK_STOCK_CALLBACK_MENU_ABSOLUTE_SELECTION,-(%sp)
        pea     GK_STOCK_CALLBACK_MENU_STATE
        jsr     GK_STOCK_SCROLLING_LIST_SELECT
        addq.l  #8,%sp
.Lgk_kit_list_render_rows:
        moveq   #49,%d0
        move.l  %d0,0x28(%a2)
        bsr.w   gk_stock_scrolling_callback_menu_refresh
        moveq   #57,%d0
        move.l  %d0,0x28(%a2)
        moveq   #GK_UI_MODE_LOAD,%d0
        cmp.b   __gk_ui_mode,%d0
        beq.s   .Lgk_kit_list_render_load_title
        lea     gk_kit_list_save_title,%a0
        bra.s   .Lgk_kit_list_render_title
.Lgk_kit_list_render_load_title:
        lea     .Lgk_kit_list_load_title,%a0
.Lgk_kit_list_render_title:
        clr.l   -(%sp)
        move.l  %a0,-(%sp)
        move.l  %a2,-(%sp)
        .global gk_kit_list_title_panel_draw_call
gk_kit_list_title_panel_draw_call:
        jsr     GK_STOCK_COMPACT_TABBED_TITLE_DRAW
        lea     12(%sp),%sp
.Lgk_kit_list_render_return:
        movea.l (%sp)+,%a2
        move.l  (%sp)+,%d2
        rts
        .size   gk_kit_list_render_dispatch,.-gk_kit_list_render_dispatch
        .global gk_stock_scrolling_callback_menu_refresh
        .type   gk_stock_scrolling_callback_menu_refresh,@function
gk_stock_scrolling_callback_menu_refresh:
        .incbin "stock/0350.bin", 0, 4
        .incbin "stock/0350.bin", 4, 4
        jmp     GK_STOCK_SCROLLING_CALLBACK_MENU_REFRESH_CONTINUE
        .size   gk_stock_scrolling_callback_menu_refresh,.-gk_stock_scrolling_callback_menu_refresh
.Lgk_kit_list_load_title:
        .incbin "stock/0351.bin", 0, 4
        .byte 0x20,0x4b,0x49,0x54,0x00
.Lgk_kit_list_message_copy:
        .incbin "stock/0352.bin", 0, 5
.Lgk_kit_list_message_paste:
        .incbin "stock/0353.bin", 0, 6
.Lgk_kit_list_message_clear:
        .incbin "stock/0354.bin", 0, 6
