        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_kit_reference_count
        .type   gk_kit_reference_count,@function
gk_kit_reference_count:
        cmpi.l  #GK_KIT_COUNT - 1,%d0
        bhi.s   .Lgk_kit_reference_count_range
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  %d0,%d1
        moveq   #0,%d0
        moveq   #0,%d2
        lea     __gk_pattern_assignments,%a0
        lea     __gk_pattern_assignment_valid,%a1
.Lgk_kit_reference_count_loop:
        move.l  %d2,%d3
        lsr.l   #3,%d3
        btst    %d2,(%a1,%d3.l)
        beq.s   .Lgk_kit_reference_count_next
        cmp.b   (%a0),%d1
        bne.s   .Lgk_kit_reference_count_next
        addq.l  #1,%d0
.Lgk_kit_reference_count_next:
        addq.l  #1,%a0
        addq.l  #1,%d2
        cmpi.l  #GK_PATTERN_ASSIGNMENT_COUNT,%d2
        blo.s   .Lgk_kit_reference_count_loop
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts
.Lgk_kit_reference_count_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_kit_reference_count,.-gk_kit_reference_count
        .global gk_ui_prepare_kit_tables
        .type   gk_ui_prepare_kit_tables,@function
gk_ui_prepare_kit_tables:
        tst.l   %a0
        beq.w   .Lgk_ui_prepare_invalid
        .incbin "stock/0198.bin", 0, 4
        .incbin "stock/0198.bin", 4, 4
        move.l  %a0,%a5
        lea     __gk_ui_referenced_bitmap,%a0
        moveq   #0,%d0
        moveq   #(GK_KIT_COUNT / 8 / 4),%d1
.Lgk_ui_reference_clear:
        move.l  %d0,(%a0)+
        subq.l  #1,%d1
        bne.s   .Lgk_ui_reference_clear
        lea     __gk_pattern_assignments,%a2
        lea     __gk_pattern_assignments_end,%a3
        lea     __gk_ui_referenced_bitmap,%a4
        lea     __gk_pattern_assignment_valid,%a1
        moveq   #0,%d6
.Lgk_ui_reference_scan:
        move.l  %d6,%d0
        lsr.l   #3,%d0
        btst    %d6,(%a1,%d0.l)
        beq.s   .Lgk_ui_reference_next
        moveq   #0,%d0
        move.b  (%a2),%d0
        move.l  %d0,%d1
        lsr.l   #3,%d1
        andi.l  #7,%d0
        bset    %d0,(%a4,%d1.l)
.Lgk_ui_reference_next:
        addq.l  #1,%a2
        addq.l  #1,%d6
        cmpa.l  %a3,%a2
        bne.s   .Lgk_ui_reference_scan
        moveq   #0,%d2
        lea     __gk_ui_rows,%a2
        lea     __gk_ui_label_pointers,%a3
        lea     __gk_ui_callback_pointers,%a4
        move.l  %a2,(%a3)+
        move.l  %a5,(%a4)+
        move.l  #0x554e444f,(%a2)+
        move.l  #0x204b4954,(%a2)+
        move.l  #0x00000000,(%a2)+
        clr.b   (%a2)+
        clr.b   (%a2)+
        clr.b   (%a2)+
.Lgk_ui_row_loop:
        move.l  %a2,(%a3)+
        move.l  %a5,(%a4)+
        move.l  %d2,%d0
        addq.l  #1,%d0
        moveq   #0,%d3
.Lgk_ui_hundreds_loop:
        cmpi.l  #100,%d0
        blo.s   .Lgk_ui_hundreds_done
        subi.l  #100,%d0
        addq.l  #1,%d3
        bra.s   .Lgk_ui_hundreds_loop
.Lgk_ui_hundreds_done:
        moveq   #0,%d4
.Lgk_ui_tens_loop:
        cmpi.l  #10,%d0
        blo.s   .Lgk_ui_tens_done
        subi.l  #10,%d0
        addq.l  #1,%d4
        bra.s   .Lgk_ui_tens_loop
.Lgk_ui_tens_done:
        addi.l  #0x30,%d3
        move.b  %d3,(%a2)+
        addi.l  #0x30,%d4
        move.b  %d4,(%a2)+
        addi.l  #0x30,%d0
        move.b  %d0,(%a2)+
        move.b  #0x20,(%a2)+
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_ui_empty_kit_name
        move.l  %d2,%d0
        lsl.l   #3,%d0
        lea     __gk_kit_names,%a0
        adda.l  %d0,%a0
        tst.b   (%a0)
        beq.s   .Lgk_ui_new_kit_name
        moveq   #0,%d5
        moveq   #GK_KIT_VISIBLE_NAME_SIZE,%d6
.Lgk_ui_saved_name_loop:
        tst.l   %d5
        bne.s   .Lgk_ui_saved_name_space
        moveq   #0,%d0
        move.b  (%a0)+,%d0
        tst.b   %d0
        bne.s   .Lgk_ui_saved_name_store
        moveq   #1,%d5
.Lgk_ui_saved_name_space:
        moveq   #0x01,%d0
.Lgk_ui_saved_name_store:
        move.b  %d0,(%a2)+
        subq.l  #1,%d6
        bne.s   .Lgk_ui_saved_name_loop
        bra.s   .Lgk_ui_name_done
.Lgk_ui_new_kit_name:
        lea     .Lgk_ui_new_kit,%a0
        moveq   #GK_KIT_VISIBLE_NAME_SIZE,%d6
.Lgk_ui_new_kit_name_loop:
        move.b  (%a0)+,(%a2)+
        subq.l  #1,%d6
        bne.s   .Lgk_ui_new_kit_name_loop
        bra.s   .Lgk_ui_name_done
.Lgk_ui_empty_kit_name:
        lea     .Lgk_ui_empty_kit,%a0
        moveq   #GK_KIT_VISIBLE_NAME_SIZE,%d6
.Lgk_ui_empty_kit_name_loop:
        move.b  (%a0)+,(%a2)+
        subq.l  #1,%d6
        bne.s   .Lgk_ui_empty_kit_name_loop
.Lgk_ui_name_done:
        move.b  #0x20,(%a2)+
        move.b  #0x20,(%a2)+
        move.l  %d2,%d0
        move.l  %d2,%d1
        lsr.l   #3,%d0
        andi.l  #7,%d1
        lea     __gk_initialized_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_ui_marker_space_v9
        lea     __gk_ui_referenced_bitmap,%a0
        btst    %d1,(%a0,%d0.l)
        beq.s   .Lgk_ui_unreferenced
.Lgk_ui_marker_space_v9:
        moveq   #0x20,%d0
        bra.s   .Lgk_ui_marker_store
.Lgk_ui_unreferenced:
        moveq   #0x2a,%d0
.Lgk_ui_marker_store:
        move.b  %d0,(%a2)+
        clr.b   (%a2)+
        addq.l  #1,%d2
        cmpi.l  #GK_KIT_COUNT,%d2
        blo.w   .Lgk_ui_row_loop
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_ui_selection_zero
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_ui_selection_zero
        tst.b   __gk_workspace_bound
        beq.s   .Lgk_ui_selection_zero
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
.Lgk_ui_selection_store:
        move.l  %d0,__gk_ui_selected_kit
        addq.l  #1,%d0
        move.l  %d0,__gk_ui_selected_row
        bra.s   .Lgk_ui_selection_done
.Lgk_ui_selection_zero:
        moveq   #0,%d0
        move.l  %d0,__gk_ui_selected_kit
        addq.l  #1,%d0
        move.l  %d0,__gk_ui_selected_row
.Lgk_ui_selection_done:
        moveq   #GK_OK,%d0
        lea     __gk_ui_label_pointers,%a0
        lea     __gk_ui_callback_pointers,%a1
        cmpa.l  #gk_load_kit_menu_confirm,%a5
        beq.s   .Lgk_ui_table_return_ready
        addq.l  #4,%a0
        addq.l  #4,%a1
.Lgk_ui_table_return_ready:
        movem.l (%sp),%d2-%d6/%a2-%a5
        lea     36(%sp),%sp
        rts
.Lgk_ui_prepare_invalid:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .size   gk_ui_prepare_kit_tables,.-gk_ui_prepare_kit_tables
        .align  2
.Lgk_ui_new_kit:
        .byte   'N','E','W',0x01,'K','I','T',0x01
.Lgk_ui_empty_kit:
        .byte   '-','-',0x01,0x01,0x01,0x01,0x01,0x01
