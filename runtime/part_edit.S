        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_ui_snapshot_context_validate
        .type   gk_ui_snapshot_context_validate,@function
gk_ui_snapshot_context_validate:
        move.l  %d2,-(%sp)
        bsr.w   gk_stock_current_context_validate
        tst.l   %d0
        bmi.s   .Lgk_ui_snapshot_restore
        move.l  %d0,%d2
        moveq   #0,%d0
        move.b  __gk_ui_context_bank,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_ui_snapshot_corrupt
        moveq   #0,%d0
        move.b  __gk_ui_context_pattern,%d0
        cmp.l   %d1,%d0
        bne.s   .Lgk_ui_snapshot_corrupt
        moveq   #0,%d0
        move.b  __gk_ui_context_kit,%d0
        moveq   #0,%d1
        move.b  __gk_current_kit,%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_ui_snapshot_corrupt
        moveq   #0,%d1
        move.b  __gk_ui_context_pattern,%d1
        move.l  %d2,%d0
        bra.s   .Lgk_ui_snapshot_restore
.Lgk_ui_snapshot_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_ui_snapshot_restore:
        move.l  (%sp)+,%d2
        rts
        .size   gk_ui_snapshot_context_validate,.-gk_ui_snapshot_context_validate
        .global gk_ui_mode_context_validate
        .type   gk_ui_mode_context_validate,@function
gk_ui_mode_context_validate:
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        moveq   #0,%d0
        move.b  __gk_ui_mode,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_ui_mode_invalid
        bsr.w   gk_ui_snapshot_context_validate
        bra.s   .Lgk_ui_mode_restore
.Lgk_ui_mode_invalid:
        moveq   #GK_ERR_INVALID,%d0
.Lgk_ui_mode_restore:
        move.l  (%sp)+,%d2
        rts
        .size   gk_ui_mode_context_validate,.-gk_ui_mode_context_validate
        .type   gk_part_edit_menu_owned,@function
gk_part_edit_menu_owned:
        tst.l   GK_STOCK_CALLBACK_MENU_OBJECT
        beq.s   .Lgk_part_edit_menu_not_owned_v6
        movea.l GK_STOCK_CALLBACK_MENU_CALLBACKS,%a0
        cmpa.l  #gk_part_edit_callbacks,%a0
        bne.s   .Lgk_part_edit_menu_not_owned_v6
        movea.l GK_STOCK_CALLBACK_MENU_LABELS,%a0
        cmpa.l  #gk_part_edit_labels,%a0
        bne.s   .Lgk_part_edit_menu_not_owned_v6
        movea.l GK_STOCK_CALLBACK_MENU_SELECTION,%a0
        cmpa.l  #__gk_ui_part_edit_selection,%a0
        bne.s   .Lgk_part_edit_menu_not_owned_v6
        move.l  GK_STOCK_CALLBACK_MENU_COUNT,%d0
        cmpi.l  #2,%d0
        bne.s   .Lgk_part_edit_menu_not_owned_v6
        moveq   #GK_UI_MODE_PART_EDIT,%d0
        cmp.b   __gk_ui_mode,%d0
        bne.s   .Lgk_part_edit_menu_not_owned_v6
        moveq   #1,%d0
        rts
.Lgk_part_edit_menu_not_owned_v6:
        moveq   #0,%d0
        rts
        .size   gk_part_edit_menu_owned,.-gk_part_edit_menu_owned
        .type   gk_stock_popup_object_active,@function
gk_stock_popup_object_active:
        movea.l %a0,%a1
        lea     GK_STOCK_POPUP_OBJECTS,%a0
        moveq   #GK_STOCK_POPUP_SLOT_COUNT,%d1
.Lgk_stock_popup_object_scan:
        cmpa.l  %a0,%a1
        bne.s   .Lgk_stock_popup_object_next
        move.l  GK_STOCK_POPUP_OBJECT_FLAGS(%a0),%d0
        btst    #GK_STOCK_POPUP_OBJECT_ACTIVE_BIT,%d0
        beq.s   .Lgk_stock_popup_object_no
        moveq   #1,%d0
        rts
.Lgk_stock_popup_object_next:
        lea     GK_STOCK_POPUP_OBJECT_STRIDE(%a0),%a0
        subq.l  #1,%d1
        bne.s   .Lgk_stock_popup_object_scan
.Lgk_stock_popup_object_no:
        moveq   #0,%d0
        .incbin "stock/0116.bin", 0, 2
        .size   gk_stock_popup_object_active,.-gk_stock_popup_object_active
        .global gk_function_map_active
        .type   gk_function_map_active,@function
gk_function_map_active:
        .incbin "stock/0116.bin", 2, 4
        .incbin "stock/0116.bin", 6, 6
        .incbin "stock/0116.bin", 12, 2
        .incbin "stock/0116.bin", 14, 2
        .incbin "stock/0116.bin", 16, 1
        .byte 0x04
.Lgk_function_map_yes:
        moveq   #1,%d0
        rts
.Lgk_function_map_no:
        moveq   #0,%d0
        rts
        .size   gk_function_map_active,.-gk_function_map_active
        .global gk_func_part_yes_dispatch
        .type   gk_func_part_yes_dispatch,@function
gk_func_part_yes_dispatch:
        bsr.w   gk_function_map_active
        tst.l   %d0
        beq.s   .Lgk_func_part_yes_stock
        moveq   #0,%d0
        move.b  __gk_ui_state_pad + 2,%d0
        cmpi.l  #GK_QUICK_SAVE_INITIATOR_PART,%d0
        beq.s   .Lgk_func_part_yes_check_part
        cmpi.l  #GK_QUICK_SAVE_INITIATOR_BANK,%d0
        bne.s   .Lgk_func_part_yes_stock
        pea     GK_STOCK_BANK_PRESS_INPUT
        bra.s   .Lgk_func_part_yes_check_held
.Lgk_func_part_yes_check_part:
        pea     GK_STOCK_PART_PRESS_INPUT
.Lgk_func_part_yes_check_held:
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        beq.s   .Lgk_func_part_yes_stock
        jsr     gk_kit_list_context_owned
        cmpi.l  #GK_UI_MODE_SAVE_AS,%d0
        bne.s   .Lgk_func_part_yes_stock
        moveq   #1,%d0
        move.b  %d0,__gk_ui_state_pad
        move.b  %d0,__gk_ui_state_pad + 1
        clr.b   __gk_ui_state_pad + 2
        .byte 0x4e,0xf9
        .incbin "stock/0117.bin", 0, 4
.Lgk_func_part_yes_stock:
        clr.b   __gk_ui_state_pad + 2
        .byte 0x4e,0xf9
        .incbin "stock/0118.bin", 0, 4
        .size   gk_func_part_yes_dispatch,.-gk_func_part_yes_dispatch
        .global gk_func_part_yes_function_release
        .type   gk_func_part_yes_function_release,@function
gk_func_part_yes_function_release:
        tst.b   __gk_ui_state_pad + 1
        beq.s   .Lgk_func_part_yes_release_stock
        clr.b   __gk_ui_state_pad + 1
        rts
.Lgk_func_part_yes_release_stock:
        .byte 0x4e,0xf9
        .incbin "stock/0119.bin", 0, 4
        .size   gk_func_part_yes_function_release,.-gk_func_part_yes_function_release
        .global gk_mki_bank_quick_save_dispatch
        .type   gk_mki_bank_quick_save_dispatch,@function
gk_mki_bank_quick_save_dispatch:
        move.l  %d0,-(%sp)
        moveq   #GK_QUICK_SAVE_INITIATOR_BANK,%d0
        move.b  %d0,__gk_ui_state_pad + 2
        move.l  (%sp)+,%d0
        .byte 0x4e,0xf9
        .incbin "stock/0120.bin", 0, 4
        .size   gk_mki_bank_quick_save_dispatch,.-gk_mki_bank_quick_save_dispatch
        .global gk_kit_menu_conflicting_owner_active
        .type   gk_kit_menu_conflicting_owner_active,@function
gk_kit_menu_conflicting_owner_active:
        lea     GK_STOCK_POPUP_PRIORITIES,%a0
        lea     GK_STOCK_POPUP_OBJECTS,%a1
        moveq   #GK_STOCK_POPUP_SLOT_COUNT,%d1
.Lgk_kit_menu_popup_scan:
        move.l  GK_STOCK_POPUP_OBJECT_FLAGS(%a1),%d0
        btst    #GK_STOCK_POPUP_OBJECT_ACTIVE_BIT,%d0
        beq.s   .Lgk_kit_menu_popup_next
        move.l  (%a0),%d0
        tst.l   %d0
        beq.w   .Lgk_kit_menu_owner_yes
        cmpi.l  #GK_STOCK_COUNTDOWN_POPUP_PRIORITY,%d0
        bhi.w   .Lgk_kit_menu_owner_yes
        move.l  GK_STOCK_POPUP_CALLBACKS - GK_STOCK_POPUP_PRIORITIES(%a0),%d0
        beq.s   .Lgk_kit_menu_popup_next
        cmpi.l  #GK_STOCK_OS_IMAGE_START,%d0
        blo.w   .Lgk_kit_menu_owner_yes
        cmpi.l  #GK_STOCK_OS_IMAGE_END,%d0
        bhs.w   .Lgk_kit_menu_owner_yes
        btst    #0,%d0
        bne.w   .Lgk_kit_menu_owner_yes
.Lgk_kit_menu_popup_next:
        addq.l  #4,%a0
        lea     GK_STOCK_POPUP_OBJECT_STRIDE(%a1),%a1
        subq.l  #1,%d1
        bne.s   .Lgk_kit_menu_popup_scan
        movea.l GK_STOCK_TEXT_EDITOR_OBJECT,%a0
        tst.l   %a0
        beq.s   .Lgk_kit_menu_text_map_absent
        bsr.w   gk_stock_popup_object_active
        cmpi.l  #1,%d0
        bne.w   .Lgk_kit_menu_owner_yes
        movea.l #GK_STOCK_TEXT_EDITOR_INPUT_MAP,%a0
        bsr.w   gk_stock_input_map_registered
        cmpi.l  #1,%d0
        bne.w   .Lgk_kit_menu_owner_yes
        bra.s   .Lgk_kit_menu_callback_singleton
.Lgk_kit_menu_text_map_absent:
        movea.l #GK_STOCK_TEXT_EDITOR_INPUT_MAP,%a0
        bsr.w   gk_stock_input_map_registered
        tst.l   %d0
        bne.w   .Lgk_kit_menu_owner_yes
.Lgk_kit_menu_callback_singleton:
        movea.l GK_STOCK_CALLBACK_MENU_OBJECT,%a0
        tst.l   %a0
        beq.s   .Lgk_kit_menu_callback_map_absent
        bsr.w   gk_stock_popup_object_active
        cmpi.l  #1,%d0
        bne.w   .Lgk_kit_menu_owner_yes
        movea.l #GK_STOCK_SCROLLING_CALLBACK_MENU_INPUT_MAP,%a0
        bsr.w   gk_stock_input_map_registered
        cmpi.l  #1,%d0
        bne.w   .Lgk_kit_menu_owner_yes
        bra.s   .Lgk_kit_menu_callback_scan_begin
.Lgk_kit_menu_callback_map_absent:
        movea.l #GK_STOCK_SCROLLING_CALLBACK_MENU_INPUT_MAP,%a0
        bsr.w   gk_stock_input_map_registered
        tst.l   %d0
        bne.w   .Lgk_kit_menu_owner_yes
.Lgk_kit_menu_callback_scan_begin:
        movea.l GK_STOCK_UI_CALLBACK_HEAD,%a0
        moveq   #GK_STOCK_UI_CALLBACK_NODE_COUNT,%d1
.Lgk_kit_menu_callback_scan:
        tst.l   %a0
        beq.w   .Lgk_kit_menu_owner_no
        cmpa.l  #GK_STOCK_RECORDING_SETUP_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_SCENE_OVERLAY_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_FUNCTION_OVERLAY_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_PATTERN_OVERLAY_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_PRIORITY1_SETUP_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_PRIORITY2_EVENT_1A_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_PRIORITY2_EVENT_19_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_PRIORITY2_EVENT_2F_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_PRIORITY2_EVENT_2E_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_MIDI_TRIG_EDIT_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_ARP_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_BANK_OVERLAY_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_MIXER_CALLBACK,%a0
        beq.w   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_UI_ROOT_CALLBACK,%a0
        beq.s   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_MIDI_LEARN_CALLBACK,%a0
        beq.s   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_FILE_MANAGER_CALLBACK,%a0
        beq.s   .Lgk_kit_menu_callback_next
        cmpa.l  #GK_STOCK_CALLBACK_MANAGER_ROOT,%a0
        bne.s   .Lgk_kit_menu_owner_yes
.Lgk_kit_menu_callback_next:
        movea.l (%a0),%a0
        subq.l  #1,%d1
        bne.w   .Lgk_kit_menu_callback_scan
        tst.l   %a0
        bne.s   .Lgk_kit_menu_owner_yes
.Lgk_kit_menu_owner_no:
        moveq   #0,%d0
        rts
.Lgk_kit_menu_owner_yes:
        moveq   #1,%d0
        rts
        .size   gk_kit_menu_conflicting_owner_active,.-gk_kit_menu_conflicting_owner_active
        .global gk_part_edit_dispatch_bridge
        .type   gk_part_edit_dispatch_bridge,@function
gk_part_edit_dispatch_bridge:
        jsr     gk_kit_list_context_owned
        tst.l   %d0
        bne.s   .Lgk_part_edit_dispatch_owned_return
        bsr.w   gk_save_name_editor_owned
        tst.l   %d0
        beq.s   .Lgk_part_edit_dispatch_stock_nav
.Lgk_part_edit_dispatch_owned_return:
        rts
.Lgk_part_edit_dispatch_stock_nav:
        jmp     GK_STOCK_PART_MODAL_ACTIVE
        .global gk_part_edit_quick_save
        .type   gk_part_edit_quick_save,@function
gk_part_edit_quick_save:
        lea     -12(%sp),%sp
        movem.l %d2-%d3/%a2,(%sp)
        bsr.w   gk_stock_current_context_validate_or_resume
        tst.l   %d0
        bmi.w   .Lgk_func_part_save_restore_silent_v4
        move.l  %d0,%d2
        move.l  %d1,%d3
        tst.b   __gk_workspace_bound
        beq.w   .Lgk_func_part_save_ephemeral_v9
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        movea.l %d0,%a2
        move.l  %d0,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_func_part_save_unnamed_v9
        tst.b   __gk_workspace_dirty
        beq.s   .Lgk_func_part_save_success_v4
        bsr.w   gk_workspace_save
        tst.l   %d0
        bne.s   .Lgk_func_part_save_notify_v4
        moveq   #1,%d0
        lsl.l   %d2,%d0
        bsr.w   gk_stock_dirty_mark_bank_mask
.Lgk_func_part_save_success_v4:
        moveq   #GK_OK,%d0
.Lgk_func_part_save_notify_v4:
        lea     .Lgk_part_edit_message_saved,%a0
        bsr.w   gk_part_edit_notify_result
        bra.s   .Lgk_func_part_save_restore_v4
.Lgk_func_part_save_unnamed_v9:
        move.l  %a2,__gk_ui_selected_kit
        move.b  %d2,__gk_ui_context_bank
        move.b  %d3,__gk_ui_context_pattern
        move.l  %a2,%d0
        move.b  %d0,__gk_ui_context_kit
        moveq   #GK_UI_MODE_PART_EDIT,%d0
        move.b  %d0,__gk_ui_mode
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        jmp     gk_save_as_name_open
.Lgk_func_part_save_ephemeral_v9:
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        move.b  %d2,__gk_ui_context_bank
        move.b  %d3,__gk_ui_context_pattern
        move.b  %d0,__gk_ui_context_kit
        moveq   #GK_UI_MODE_PART_EDIT,%d0
        move.b  %d0,__gk_ui_mode
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        jmp     gk_part_edit_save_as_open
.Lgk_func_part_save_restore_v4:
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
.Lgk_func_part_save_return_v4:
        rts
.Lgk_func_part_save_restore_silent_v4:
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        rts
        .size   gk_part_edit_quick_save,.-gk_part_edit_quick_save
        .size   gk_part_edit_dispatch_bridge,.-gk_part_edit_dispatch_bridge
        .global gk_part_edit_notify_result
        .type   gk_part_edit_notify_result,@function
gk_part_edit_notify_result:
        lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
        move.l  %d0,%d2
        movea.l %a0,%a2
        tst.l   %d2
        beq.s   .Lgk_part_edit_notify_show
        cmpi.l  #GK_ERR_INVALID,%d2
        bne.s   .Lgk_part_edit_notify_busy_check
        cmpa.l  #.Lgk_part_edit_message_reloaded,%a2
        bne.s   .Lgk_part_edit_notify_error
        lea     .Lgk_part_edit_message_save_first,%a2
        bra.s   .Lgk_part_edit_notify_show
.Lgk_part_edit_notify_busy_check:
        cmpi.l  #GK_ERR_BUSY,%d2
        bne.s   .Lgk_part_edit_notify_error
        lea     .Lgk_part_edit_message_busy,%a2
        bra.s   .Lgk_part_edit_notify_show
.Lgk_part_edit_notify_error:
        lea     .Lgk_part_edit_message_error,%a2
.Lgk_part_edit_notify_show:
        pea     (0x44).w
        move.l  %a2,-(%sp)
        .global gk_part_edit_stock_notification_call
gk_part_edit_stock_notification_call:
        jsr     GK_STOCK_NOTIFICATION_SHOW
        addq.l  #8,%sp
        move.l  %d2,%d0
        movem.l (%sp),%d2/%a2
        addq.l  #8,%sp
        rts
        .size   gk_part_edit_notify_result,.-gk_part_edit_notify_result
        .global gk_stock_input_map_registered
        .type   gk_stock_input_map_registered,@function
gk_stock_input_map_registered:
        lea     -8(%sp),%sp
        movem.l %d1-%d2,(%sp)
        movea.l GK_STOCK_INPUT_MAP_HEAD,%a1
        moveq   #GK_STOCK_INPUT_MAP_NODE_COUNT,%d1
        moveq   #0,%d2
.Lgk_stock_input_map_scan:
        tst.l   %a1
        beq.w   .Lgk_stock_input_map_not_registered
        cmpa.l  #GK_STOCK_OS_IMAGE_START,%a1
        blo.w   .Lgk_stock_input_map_corrupt
        cmpa.l  #GK_STOCK_OS_IMAGE_END - GK_STOCK_INPUT_MAP_DESCRIPTOR_SIZE,%a1
        bhi.w   .Lgk_stock_input_map_corrupt
        move.l  %a1,%d0
        btst    #0,%d0
        bne.w   .Lgk_stock_input_map_corrupt
        move.l  16(%a1),%d0
        cmpi.l  #GK_STOCK_INPUT_MAP_REGISTERED_MARKER,%d0
        beq.s   .Lgk_stock_input_map_marker_valid
        cmpi.l  #63,%d0
        bhi.w   .Lgk_stock_input_map_corrupt
        cmpi.l  #GK_STOCK_INPUT_MAP_NODE_COUNT,%d1
        beq.w   .Lgk_stock_input_map_corrupt
.Lgk_stock_input_map_marker_valid:
        move.l  4(%a1),%d0
        beq.w   .Lgk_stock_input_map_corrupt
        cmpi.l  #GK_STOCK_OS_IMAGE_START,%d0
        blo.w   .Lgk_stock_input_map_corrupt
        cmpi.l  #GK_STOCK_OS_IMAGE_END,%d0
        bhs.w   .Lgk_stock_input_map_corrupt
        btst    #0,%d0
        bne.w   .Lgk_stock_input_map_corrupt
.Lgk_stock_input_map_primary_valid:
        move.l  8(%a1),%d0
        beq.s   .Lgk_stock_input_map_aux_valid
        cmpi.l  #GK_STOCK_OS_IMAGE_START,%d0
        blo.w   .Lgk_stock_input_map_corrupt
        cmpi.l  #GK_STOCK_OS_IMAGE_END,%d0
        bhs.w   .Lgk_stock_input_map_corrupt
        btst    #0,%d0
        bne.w   .Lgk_stock_input_map_corrupt
.Lgk_stock_input_map_aux_valid:
        move.l  12(%a1),%d0
        beq.s   .Lgk_stock_input_map_child_valid
        cmpi.l  #GK_STOCK_OS_IMAGE_START,%d0
        blo.w   .Lgk_stock_input_map_corrupt
        cmpi.l  #GK_STOCK_OS_IMAGE_END - GK_STOCK_INPUT_MAP_DESCRIPTOR_SIZE,%d0
        bhi.w   .Lgk_stock_input_map_corrupt
        btst    #0,%d0
        bne.w   .Lgk_stock_input_map_corrupt
.Lgk_stock_input_map_child_valid:
        cmpa.l  %a0,%a1
        bne.s   .Lgk_stock_input_map_next
        move.l  16(%a1),%d0
        cmpi.l  #GK_STOCK_INPUT_MAP_REGISTERED_MARKER,%d0
        bne.w   .Lgk_stock_input_map_corrupt
        moveq   #1,%d2
.Lgk_stock_input_map_next:
        movea.l (%a1),%a1
        subq.l  #1,%d1
        bne.w   .Lgk_stock_input_map_scan
        tst.l   %a1
        bne.w   .Lgk_stock_input_map_corrupt
.Lgk_stock_input_map_not_registered:
        move.l  %d2,%d0
        bra.s   .Lgk_stock_input_map_return
.Lgk_stock_input_map_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_stock_input_map_return:
        movem.l (%sp),%d1-%d2
        addq.l  #8,%sp
        rts
        .size   gk_stock_input_map_registered,.-gk_stock_input_map_registered
        .global gk_save_name_editor_owned
        .type   gk_save_name_editor_owned,@function
gk_save_name_editor_owned:
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        beq.s   .Lgk_save_name_editor_not_owned
        movea.l #GK_STOCK_TEXT_EDITOR_INPUT_MAP,%a0
        bsr.w   gk_stock_input_map_registered
        cmpi.l  #1,%d0
        bne.s   .Lgk_save_name_editor_not_owned
        movea.l GK_STOCK_TEXT_EDITOR_COMPLETION,%a0
        cmpa.l  #gk_save_as_name_complete,%a0
        bne.s   .Lgk_save_name_editor_not_owned
        movea.l GK_STOCK_TEXT_EDITOR_CALLER_BUFFER,%a0
        cmpa.l  #__gk_ui_rename_name,%a0
        bne.s   .Lgk_save_name_editor_not_owned
        move.l  GK_STOCK_TEXT_EDITOR_MAX_LENGTH,%d0
        cmpi.l  #GK_KIT_VISIBLE_NAME_SIZE,%d0
        bne.s   .Lgk_save_name_editor_not_owned
        move.l  GK_STOCK_TEXT_EDITOR_LAYOUT_MODE,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_save_name_editor_not_owned
        moveq   #GK_UI_MODE_SAVE_AS_NAME,%d0
        cmp.b   __gk_ui_mode,%d0
        bne.s   .Lgk_save_name_editor_not_owned
        move.l  __gk_ui_selected_kit,%d0
        cmpi.l  #GK_KIT_COUNT - 1,%d0
        bhi.s   .Lgk_save_name_editor_not_owned
        moveq   #GK_UI_MODE_SAVE_AS_NAME,%d0
        bsr.w   gk_ui_mode_context_validate
        tst.l   %d0
        bmi.s   .Lgk_save_name_editor_not_owned
        moveq   #1,%d0
        rts
.Lgk_save_name_editor_not_owned:
        moveq   #0,%d0
        rts
        .size   gk_save_name_editor_owned,.-gk_save_name_editor_owned
        .global gk_kit_scrolling_popup_create_bridge
        .type   gk_kit_scrolling_popup_create_bridge,@function
gk_kit_scrolling_popup_create_bridge:
        move.l  20(%sp),%d0
        cmpi.l  #GK_STOCK_CALLBACK_MENU_PRIORITY,%d0
        bne.w   .Lgk_kit_scrolling_popup_stock
        move.l  24(%sp),%d0
        cmpi.l  #GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE,%d0
        bne.w   .Lgk_kit_scrolling_popup_stock
        moveq   #GK_UI_MODE_LOAD,%d0
        cmp.b   __gk_ui_mode,%d0
        beq.s   .Lgk_kit_scrolling_popup_load
        moveq   #GK_UI_MODE_SAVE_AS,%d0
        cmp.b   __gk_ui_mode,%d0
        bne.w   .Lgk_kit_scrolling_popup_stock
        movea.l GK_STOCK_CALLBACK_MENU_CALLBACKS,%a0
        cmpa.l  #__gk_ui_callback_pointers + 4,%a0
        bne.w   .Lgk_kit_scrolling_popup_stock
        move.l  (%a0),%d0
        cmpi.l  #gk_save_as_menu_confirm,%d0
        bne.w   .Lgk_kit_scrolling_popup_stock
        bra.s   .Lgk_kit_scrolling_popup_common
.Lgk_kit_scrolling_popup_load:
        movea.l GK_STOCK_CALLBACK_MENU_CALLBACKS,%a0
        cmpa.l  #__gk_ui_callback_pointers,%a0
        bne.w   .Lgk_kit_scrolling_popup_stock
        move.l  (%a0),%d0
        cmpi.l  #gk_load_kit_menu_confirm,%d0
        bne.w   .Lgk_kit_scrolling_popup_stock
.Lgk_kit_scrolling_popup_common:
        movea.l GK_STOCK_CALLBACK_MENU_LABELS,%a0
        moveq   #GK_UI_MODE_LOAD,%d0
        cmp.b   __gk_ui_mode,%d0
        bne.s   .Lgk_kit_scrolling_popup_save_tuple
        cmpa.l  #__gk_ui_label_pointers,%a0
        bne.w   .Lgk_kit_scrolling_popup_stock
        movea.l GK_STOCK_CALLBACK_MENU_SELECTION,%a0
        cmpa.l  #__gk_ui_selected_row,%a0
        bne.w   .Lgk_kit_scrolling_popup_stock
        move.l  GK_STOCK_CALLBACK_MENU_COUNT,%d0
        cmpi.l  #GK_KIT_COUNT + 1,%d0
        bne.w   .Lgk_kit_scrolling_popup_stock
        bra.s   .Lgk_kit_scrolling_popup_promote
.Lgk_kit_scrolling_popup_save_tuple:
        cmpa.l  #__gk_ui_label_pointers + 4,%a0
        bne.w   .Lgk_kit_scrolling_popup_stock
        movea.l GK_STOCK_CALLBACK_MENU_SELECTION,%a0
        cmpa.l  #__gk_ui_selected_kit,%a0
        bne.w   .Lgk_kit_scrolling_popup_stock
        move.l  GK_STOCK_CALLBACK_MENU_COUNT,%d0
        cmpi.l  #GK_KIT_COUNT,%d0
        bne.w   .Lgk_kit_scrolling_popup_stock
.Lgk_kit_scrolling_popup_promote:
        moveq   #GK_STOCK_PART_POPUP_PRIORITY,%d0
        move.l  %d0,20(%sp)
.Lgk_kit_scrolling_popup_stock:
        jmp     GK_STOCK_POPUP_CREATE
        .size   gk_kit_scrolling_popup_create_bridge,.-gk_kit_scrolling_popup_create_bridge
        .global gk_kit_owner_navigate
        .type   gk_kit_owner_navigate,@function
gk_kit_owner_navigate:
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        cmpi.l  #GK_UI_MODE_LOAD,%d2
        beq.s   .Lgk_kit_owner_mode_valid
        cmpi.l  #GK_UI_MODE_SAVE_AS,%d2
        bne.w   .Lgk_kit_owner_busy
.Lgk_kit_owner_mode_valid:
        jsr     gk_kit_list_context_owned
        tst.l   %d0
        bne.s   .Lgk_kit_owner_list
        bsr.w   gk_save_name_editor_owned
        tst.l   %d0
        bne.s   .Lgk_kit_owner_editor
        bsr.w   gk_kit_menu_conflicting_owner_active
        tst.l   %d0
        bne.s   .Lgk_kit_owner_busy
        bra.s   .Lgk_kit_owner_open_requested
.Lgk_kit_owner_list:
        cmp.l   %d2,%d0
        blo.s   .Lgk_kit_owner_switch_list
.Lgk_kit_owner_close_list:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE
        clr.b   __gk_ui_mode
        moveq   #GK_OK,%d0
        bra.s   .Lgk_kit_owner_return
.Lgk_kit_owner_switch_list:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE
        clr.b   __gk_ui_mode
        bra.s   .Lgk_kit_owner_open_requested
.Lgk_kit_owner_editor:
        cmpi.l  #GK_UI_MODE_SAVE_AS,%d2
        beq.s   .Lgk_kit_owner_editor_to_save
        clr.b   __gk_ui_mode
        jsr     GK_STOCK_TEXT_EDITOR_CANCEL
        bra.s   .Lgk_kit_owner_open_requested
.Lgk_kit_owner_editor_to_save:
        jsr     GK_STOCK_TEXT_EDITOR_CANCEL
        moveq   #GK_OK,%d0
        bra.s   .Lgk_kit_owner_return
.Lgk_kit_owner_open_requested:
        cmpi.l  #GK_UI_MODE_LOAD,%d2
        bne.s   .Lgk_kit_owner_open_save
        move.l  (%sp)+,%d2
        jmp     gk_load_kit_menu_open
.Lgk_kit_owner_open_save:
        move.l  (%sp)+,%d2
        bra.w   .Lgk_part_edit_open_new_v4
.Lgk_kit_owner_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_kit_owner_return:
        move.l  (%sp)+,%d2
        rts
        .size   gk_kit_owner_navigate,.-gk_kit_owner_navigate
        .global gk_load_kit_shortcut_open
        .type   gk_load_kit_shortcut_open,@function
gk_load_kit_shortcut_open:
        clr.b   __gk_ui_state_pad + 2
        jsr     gk_pattern_kit_mki_part_lifecycle_dispatch
        tst.l   %d0
        bne.s   .Lgk_load_kit_shortcut_continue
        rts
.Lgk_load_kit_shortcut_continue:
        pea     GK_STOCK_PATTERN_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        bne.s   .Lgk_load_kit_shortcut_busy
        bsr.w   gk_kit_menu_conflicting_owner_active
        tst.l   %d0
        bne.s   .Lgk_load_kit_shortcut_busy
        moveq   #GK_UI_MODE_LOAD,%d0
        jmp     gk_kit_owner_navigate
.Lgk_load_kit_shortcut_busy:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_load_kit_shortcut_open,.-gk_load_kit_shortcut_open
        .global gk_part_edit_menu_open
        .type   gk_part_edit_menu_open,@function
gk_part_edit_menu_open:
        pea     GK_STOCK_PATTERN_PRESS_INPUT
        jsr     GK_STOCK_INPUT_RECORD_STATE
        addq.l  #4,%sp
        tst.l   %d0
        bne.w   .Lgk_part_edit_open_busy_fast
        bsr.w   gk_kit_menu_conflicting_owner_active
        tst.l   %d0
        bne.w   .Lgk_part_edit_open_busy_fast
        bsr.w   gk_function_map_active
        tst.l   %d0
        bne.s   .Lgk_part_edit_open_direct_save
        moveq   #GK_UI_MODE_LOAD,%d0
        jmp     gk_kit_owner_navigate
.Lgk_part_edit_open_direct_save:
        moveq   #GK_UI_MODE_SAVE_AS,%d0
        jmp     gk_kit_owner_navigate
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        bne.w   .Lgk_part_edit_open_busy_fast
        tst.l   GK_STOCK_CALLBACK_MENU_OBJECT
        beq.s   .Lgk_part_edit_open_new_v4
        bsr.w   gk_part_edit_menu_owned
        tst.l   %d0
        beq.w   .Lgk_part_edit_open_busy_fast
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_CLOSE
        clr.b   __gk_ui_mode
        moveq   #GK_OK,%d0
        rts
.Lgk_part_edit_open_new_v4:
        .incbin "stock/0121.bin", 0, 4
        .incbin "stock/0121.bin", 4, 4
        bsr.w   gk_stock_current_context_validate_or_resume
        tst.l   %d0
        bmi.s   .Lgk_part_edit_open_restore
        move.l  %d0,%d4
        move.l  %d1,%d5
        moveq   #0,%d6
        move.b  __gk_current_kit,%d6
        move.b  %d4,__gk_ui_context_bank
        move.b  %d5,__gk_ui_context_pattern
        move.b  %d6,__gk_ui_context_kit
        moveq   #GK_UI_MODE_PART_EDIT,%d0
        move.b  %d0,__gk_ui_mode
        movem.l (%sp),%d2-%d7/%a2-%a3
        lea     32(%sp),%sp
        jmp     gk_part_edit_save_as_open
        lea     gk_part_edit_callbacks,%a3
        lea     gk_part_edit_labels,%a2
        move.l  %a3,-(%sp)
        move.l  %a2,-(%sp)
        move.l  __gk_ui_part_edit_selection,%d0
        cmpi.l  #1,%d0
        bls.s   .Lgk_part_edit_selection_ready
        clr.l   __gk_ui_part_edit_selection
.Lgk_part_edit_selection_ready:
        pea     __gk_ui_part_edit_selection
        move.l  __gk_ui_part_edit_selection,-(%sp)
        pea     (2).w
        .global gk_part_edit_stock_menu_call
gk_part_edit_stock_menu_call:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_OPEN
        lea     20(%sp),%sp
        moveq   #GK_OK,%d0
.Lgk_part_edit_open_restore:
        movem.l (%sp),%d2-%d7/%a2-%a3
        lea     32(%sp),%sp
        rts
.Lgk_part_edit_open_busy_fast:
        moveq   #GK_ERR_BUSY,%d0
        rts
        .size   gk_part_edit_menu_open,.-gk_part_edit_menu_open
        .global gk_part_edit_save
        .type   gk_part_edit_save,@function
        .set    gk_part_edit_save,gk_part_edit_save_as_open
        .global gk_part_edit_load
        .global gk_part_edit_reload
        .type   gk_part_edit_load,@function
        .type   gk_part_edit_reload,@function
gk_part_edit_reload:
gk_part_edit_load:
        moveq   #GK_UI_MODE_PART_EDIT,%d0
        bsr.w   gk_ui_mode_context_validate
        tst.l   %d0
        bmi.s   .Lgk_part_edit_load_error_v4
        clr.b   __gk_ui_mode
        jmp     gk_load_kit_menu_open
.Lgk_part_edit_load_error_v4:
        clr.b   __gk_ui_mode
        lea     .Lgk_part_edit_message_saved,%a0
        bsr.w   gk_part_edit_notify_result
        rts
        .size   gk_part_edit_load,.-gk_part_edit_load
        .size   gk_part_edit_reload,.-gk_part_edit_reload
        .global gk_part_edit_rename_open
        .type   gk_part_edit_rename_open,@function
gk_part_edit_rename_open:
        .global gk_part_edit_rename_complete
        .type   gk_part_edit_rename_complete,@function
gk_part_edit_rename_complete:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .size   gk_part_edit_rename_open,.-gk_part_edit_rename_open
        .size   gk_part_edit_rename_complete,.-gk_part_edit_rename_complete
        .global gk_part_edit_save_as_reopen
        .type   gk_part_edit_save_as_reopen,@function
gk_part_edit_save_as_reopen:
        moveq   #1,%d0
        bra.s   .Lgk_part_edit_save_as_open_entry
        .size   gk_part_edit_save_as_reopen,.-gk_part_edit_save_as_reopen
        .global gk_part_edit_save_as_open
        .type   gk_part_edit_save_as_open,@function
gk_part_edit_save_as_open:
        moveq   #0,%d0
.Lgk_part_edit_save_as_open_entry:
        .incbin "stock/0122.bin", 0, 4
        .incbin "stock/0122.bin", 4, 4
        move.l  %d0,%d3
        tst.l   %d3
        beq.s   .Lgk_part_edit_save_as_reopen_selection_ready
        move.l  __gk_ui_selected_kit,%d2
        cmpi.l  #GK_KIT_COUNT - 1,%d2
        bhi.w   .Lgk_part_edit_save_as_error
.Lgk_part_edit_save_as_reopen_selection_ready:
        moveq   #GK_UI_MODE_PART_EDIT,%d0
        bsr.w   gk_ui_mode_context_validate
        tst.l   %d0
        bmi.w   .Lgk_part_edit_save_as_error
        move.l  %d0,%d4
        move.l  %d1,%d5
        lea     gk_save_as_menu_confirm,%a0
        bsr.w   gk_ui_prepare_kit_tables
        tst.l   %d0
        bne.w   .Lgk_part_edit_save_as_error
        movea.l %a0,%a2
        movea.l %a1,%a3
        tst.l   %d3
        beq.s   .Lgk_part_edit_save_as_current_selection
        bra.s   .Lgk_part_edit_save_as_selection_ready
.Lgk_part_edit_save_as_current_selection:
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
.Lgk_part_edit_save_as_selection_ready:
        move.l  %d2,__gk_ui_selected_kit
        move.b  %d4,__gk_ui_context_bank
        move.b  %d5,__gk_ui_context_pattern
        move.b  %d2,__gk_ui_context_kit
        moveq   #GK_UI_MODE_SAVE_AS,%d0
        move.b  %d0,__gk_ui_mode
        move.l  %a3,-(%sp)
        move.l  %a2,-(%sp)
        pea     __gk_ui_selected_kit
        move.l  __gk_ui_selected_kit,-(%sp)
        pea     (GK_KIT_COUNT).w
        .global gk_save_as_stock_menu_call
gk_save_as_stock_menu_call:
        jsr     GK_STOCK_SCROLLING_CALLBACK_MENU_OPEN
        lea     20(%sp),%sp
        moveq   #GK_OK,%d0
        bra.s   .Lgk_part_edit_save_as_restore
.Lgk_part_edit_save_as_busy_fast:
        moveq   #GK_ERR_BUSY,%d0
        rts
.Lgk_part_edit_save_as_error:
        clr.b   __gk_ui_mode
        lea     .Lgk_part_edit_message_saved_as,%a0
        bsr.w   gk_part_edit_notify_result
.Lgk_part_edit_save_as_restore:
        .incbin "stock/0123.bin", 0, 4
        .incbin "stock/0123.bin", 4, 4
        rts
        .size   gk_part_edit_save_as_open,.-gk_part_edit_save_as_open
        .global gk_save_as_menu_confirm
        .type   gk_save_as_menu_confirm,@function
gk_save_as_menu_confirm:
        .incbin "stock/0124.bin", 0, 4
        .incbin "stock/0124.bin", 4, 4
        moveq   #0,%d4
        move.b  __gk_ui_state_pad,%d4
        clr.b   __gk_ui_state_pad
        move.l  __gk_ui_selected_kit,%d2
        cmpi.l  #GK_KIT_COUNT - 1,%d2
        bhi.w   .Lgk_save_as_confirm_range
        moveq   #GK_UI_MODE_SAVE_AS,%d0
        bsr.w   gk_ui_mode_context_validate
        tst.l   %d0
        bmi.w   .Lgk_save_as_confirm_finish
        tst.l   %d4
        beq.s   .Lgk_save_as_confirm_named
        move.l  %d0,%d3
        tst.b   __gk_workspace_bound
        beq.s   .Lgk_save_as_confirm_named
        tst.b   __gk_workspace_name
        beq.s   .Lgk_save_as_confirm_named
        move.l  %d2,%d0
        lea     __gk_workspace_name,%a0
        bsr.w   gk_workspace_save_as_named
        tst.l   %d0
        bne.s   .Lgk_save_as_confirm_finish
        moveq   #1,%d0
        lsl.l   %d3,%d0
        bsr.w   gk_stock_dirty_mark_bank_mask
        bra.s   .Lgk_save_as_confirm_finish
.Lgk_save_as_confirm_named:
        bsr.w   gk_save_as_name_open
        tst.l   %d0
        beq.s   .Lgk_save_as_confirm_restore
        bra.s   .Lgk_save_as_confirm_finish
.Lgk_save_as_confirm_range:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_save_as_confirm_finish:
        move.l  %d0,%d2
        clr.b   __gk_ui_mode
        move.l  %d2,%d0
        lea     .Lgk_part_edit_message_saved_as,%a0
        bsr.w   gk_part_edit_notify_result
.Lgk_save_as_confirm_restore:
        .incbin "stock/0125.bin", 0, 4
        .incbin "stock/0125.bin", 4, 4
        .incbin "stock/0125.bin", 8, 2
        .size   gk_save_as_menu_confirm,.-gk_save_as_menu_confirm
        .global gk_save_as_overwrite_confirm
        .type   gk_save_as_overwrite_confirm,@function
        .set    gk_save_as_overwrite_confirm,gk_part_edit_rename_open
        .global gk_save_as_overwrite_cancel
        .type   gk_save_as_overwrite_cancel,@function
        .set    gk_save_as_overwrite_cancel,gk_part_edit_rename_open
        .type   gk_save_as_name_open,@function
gk_save_as_name_open:
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        bne.w   .Lgk_save_name_open_busy_v3
        moveq   #0,%d1
        move.b  __gk_ui_mode,%d1
        cmpi.l  #GK_UI_MODE_PART_EDIT,%d1
        bne.s   .Lgk_save_name_open_save_as_v3
        moveq   #GK_UI_MODE_SAVE_NAME,%d1
        lea     .Lgk_part_edit_save_name_title,%a1
        bra.s   .Lgk_save_name_mode_ready_v3
.Lgk_save_name_open_save_as_v3:
        cmpi.l  #GK_UI_MODE_SAVE_AS,%d1
        beq.s   .Lgk_save_name_open_save_as_valid_v3
        cmpi.l  #GK_UI_MODE_SAVE_AS_CONFIRM,%d1
        bne.s   .Lgk_save_name_open_invalid_v3
.Lgk_save_name_open_save_as_valid_v3:
        moveq   #GK_UI_MODE_SAVE_AS_NAME,%d1
        lea     .Lgk_save_as_name_title,%a1
.Lgk_save_name_mode_ready_v3:
        move.l  __gk_workspace_name,%d0
        move.l  %d0,__gk_ui_rename_name
        move.l  __gk_workspace_name + 4,%d0
        move.l  %d0,__gk_ui_rename_name + 4
        tst.b   __gk_ui_rename_name
        bne.s   .Lgk_save_name_value_ready_v3
        move.l  .Lgk_part_edit_default_name,%d0
        move.l  %d0,__gk_ui_rename_name
        move.l  .Lgk_part_edit_default_name + 4,%d0
        move.l  %d0,__gk_ui_rename_name + 4
.Lgk_save_name_value_ready_v3:
        clr.b   __gk_ui_rename_name + GK_KIT_VISIBLE_NAME_SIZE
        clr.b   __gk_ui_rename_name_pad
        move.b  %d1,__gk_ui_mode
        pea     gk_save_as_name_complete
        pea     (1).w
        pea     __gk_ui_rename_name
        move.l  %a1,-(%sp)
        pea     (GK_KIT_VISIBLE_NAME_SIZE).w
        .global gk_save_as_stock_text_editor_call
gk_save_as_stock_text_editor_call:
        jsr     GK_STOCK_TEXT_EDITOR_OPEN
        lea     20(%sp),%sp
        tst.l   GK_STOCK_TEXT_EDITOR_OBJECT
        beq.s   .Lgk_save_name_open_busy_v3
        moveq   #GK_OK,%d0
        rts
.Lgk_save_name_open_busy_v3:
        moveq   #GK_ERR_BUSY,%d0
        rts
.Lgk_save_name_open_invalid_v3:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .size   gk_save_as_name_open,.-gk_save_as_name_open
        .global gk_part_edit_stock_text_editor_call
        .set    gk_part_edit_stock_text_editor_call,gk_save_as_stock_text_editor_call
        .global gk_save_as_name_complete
        .type   gk_save_as_name_complete,@function
gk_save_as_name_complete:
        tst.l   4(%sp)
        bne.s   .Lgk_save_name_confirmed_v3
        moveq   #GK_UI_MODE_SAVE_AS_NAME,%d0
        cmp.b   __gk_ui_mode,%d0
        bne.s   .Lgk_save_name_cancel_close_v3
        move.l  __gk_ui_selected_kit,%d0
        cmpi.l  #GK_KIT_COUNT - 1,%d0
        bhi.s   .Lgk_save_name_cancel_close_v3
        moveq   #GK_UI_MODE_SAVE_AS_NAME,%d0
        bsr.w   gk_ui_mode_context_validate
        tst.l   %d0
        bmi.s   .Lgk_save_name_cancel_close_v3
        moveq   #GK_UI_MODE_PART_EDIT,%d0
        move.b  %d0,__gk_ui_mode
        jmp     gk_part_edit_save_as_reopen
.Lgk_save_name_cancel_close_v3:
        clr.b   __gk_ui_mode
        moveq   #GK_OK,%d0
        rts
.Lgk_save_name_confirmed_v3:
        .incbin "stock/0126.bin", 0, 4
        .incbin "stock/0126.bin", 4, 4
        moveq   #0,%d4
        move.b  __gk_ui_mode,%d4
        cmpi.l  #GK_UI_MODE_SAVE_NAME,%d4
        beq.s   .Lgk_save_name_mode_valid_v3
        cmpi.l  #GK_UI_MODE_SAVE_AS_NAME,%d4
        bne.s   .Lgk_save_name_invalid_v3
.Lgk_save_name_mode_valid_v3:
        move.l  __gk_ui_selected_kit,%d2
        cmpi.l  #GK_KIT_COUNT - 1,%d2
        bhi.s   .Lgk_save_name_range_v3
        move.l  %d4,%d0
        bsr.w   gk_ui_mode_context_validate
        tst.l   %d0
        bmi.s   .Lgk_save_name_finish_v3
        move.l  %d0,%d3
        cmpi.l  #GK_UI_MODE_SAVE_NAME,%d4
        bne.s   .Lgk_save_name_check_complete_v3
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_save_name_corrupt_v3
.Lgk_save_name_check_complete_v3:
        tst.b   __gk_ui_rename_name
        bne.s   .Lgk_save_name_normalized_v3
        move.l  .Lgk_part_edit_default_name,%d0
        move.l  %d0,__gk_ui_rename_name
        move.l  .Lgk_part_edit_default_name + 4,%d0
        move.l  %d0,__gk_ui_rename_name + 4
.Lgk_save_name_normalized_v3:
        clr.b   __gk_ui_rename_name + GK_KIT_VISIBLE_NAME_SIZE
        move.l  %d2,%d0
        lea     __gk_ui_rename_name,%a0
        bsr.w   gk_workspace_save_as_named
        tst.l   %d0
        bne.s   .Lgk_save_name_finish_v3
        moveq   #1,%d0
        lsl.l   %d3,%d0
        bsr.w   gk_stock_dirty_mark_bank_mask
        bra.s   .Lgk_save_name_finish_v3
.Lgk_save_name_corrupt_v3:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_save_name_finish_v3
.Lgk_save_name_invalid_v3:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_save_name_finish_v3
.Lgk_save_name_range_v3:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_save_name_finish_v3:
        move.l  %d0,%d2
        clr.b   __gk_ui_mode
        move.l  %d2,%d0
        cmpi.l  #GK_UI_MODE_SAVE_NAME,%d4
        beq.s   .Lgk_save_name_message_v3
        lea     .Lgk_part_edit_message_saved_as,%a0
        bra.s   .Lgk_save_name_notify_v3
.Lgk_save_name_message_v3:
        lea     .Lgk_part_edit_message_saved,%a0
.Lgk_save_name_notify_v3:
        bsr.w   gk_part_edit_notify_result
        .incbin "stock/0127.bin", 0, 4
        .incbin "stock/0127.bin", 4, 4
        .incbin "stock/0127.bin", 8, 2
        .size   gk_save_as_name_complete,.-gk_save_as_name_complete
        .align  4
        .global gk_part_edit_callbacks
gk_part_edit_callbacks:
        .long   gk_part_edit_load
        .long   gk_part_edit_save_as_open
        .global gk_part_edit_labels
gk_part_edit_labels:
        .long   .Lgk_part_edit_label_load
        .long   .Lgk_part_edit_label_save
        .global gk_save_as_confirmation_callbacks
        .type   gk_save_as_confirmation_callbacks,@object
        .set    gk_save_as_confirmation_callbacks,gk_part_edit_callbacks
        .global gk_save_as_confirmation_labels
        .type   gk_save_as_confirmation_labels,@object
        .set    gk_save_as_confirmation_labels,gk_part_edit_labels
.Lgk_part_edit_label_load:
        .incbin "stock/0128.bin", 0, 5
.Lgk_part_edit_label_save:
        .incbin "stock/0129.bin", 0, 5
.Lgk_part_edit_save_name_title:
        .incbin "stock/0130.bin", 0, 4
        .byte 0x20,0x4b,0x49,0x54,0x00
.Lgk_save_as_name_title:
        .global gk_kit_list_save_title
gk_kit_list_save_title:
        .incbin "stock/0131.bin", 0, 4
        .byte 0x20,0x4b,0x49,0x54,0x00
        .align  4
.Lgk_part_edit_default_name:
        .ascii  "NEW KIT "
.Lgk_part_edit_message_saved:
        .byte 0x4b,0x49,0x54
        .incbin "stock/0132.bin", 0, 7
.Lgk_part_edit_message_reloaded:
        .byte 0x4b,0x49,0x54
        .incbin "stock/0133.bin", 0, 10
.Lgk_part_edit_message_save_first:
        .incbin "stock/0134.bin", 0, 4
        .byte 0x20,0x4b,0x49,0x54
        .incbin "stock/0135.bin", 0, 8
.Lgk_part_edit_message_saved_as:
        .byte 0x4b,0x49,0x54
        .incbin "stock/0136.bin", 0, 7
.Lgk_part_edit_message_busy:
        .asciz  "KIT BUSY - RETRY"
.Lgk_part_edit_message_error:
        .asciz  "KIT ERROR"
