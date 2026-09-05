        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .equ    GK_LDO_FRAME,80
        .equ    GK_LDO_OUT_D0,44
        .equ    GK_LDO_OUT_D1,48
        .equ    GK_LDO_OUT_A0,52
        .equ    GK_LDO_OUT_A1,56
        .equ    GK_LDO_OUT_SR,60
        .equ    GK_LDO_EXPECTED,64
        .equ    GK_LDO_ROUTE,68
        .equ    GK_LDO_STOCK_TARGET,72
        .equ    GK_LDO_CALLBACK_KIND,76
        .equ    GK_LDO_RETURN,80
        .equ    GK_LDO_ARG1,84
        .equ    GK_LDO_ARG2,88
        .equ    GK_LDO_KIND_PRESS,0
        .equ    GK_LDO_KIND_RELEASE,1
        .equ    GK_LDO_KIND_REPEAT,2
        .equ    GK_LDO_OPERATION_STEP,1
        .equ    GK_LDO_OPERATION_RELATIVE,2
        .equ    GK_LDO_OPERATION_TRANSPOSE,3
        .equ    GK_LDO_OPERATION_ROTATE,4
        .equ    GK_LDO_ROUTE_NONE,0
        .equ    GK_LDO_ROUTE_STEP,1
        .equ    GK_LDO_ROUTE_RELATIVE_ID2,2
        .equ    GK_LDO_ROUTE_RELATIVE_ID5,3
        .equ    GK_LDO_ROUTE_RELATIVE_SINGLE,4
        .equ    GK_LDO_ROUTE_RELATIVE_MULTI,5
        .equ    GK_LDO_ROUTE_TRANSPOSE,6
        .equ    GK_LDO_ROUTE_ROTATE_LEFT,7
        .equ    GK_LDO_ROUTE_ROTATE_RIGHT,8
        .global gk_stock_lfo_designer_step_operation
        .type   gk_stock_lfo_designer_step_operation,@function
gk_stock_lfo_designer_step_operation:
        lea -GK_LDO_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_LDO_OUT_D0(%sp)
        move.l %d1,GK_LDO_OUT_D1(%sp)
        move.l %a0,GK_LDO_OUT_A0(%sp)
        move.l %a1,GK_LDO_OUT_A1(%sp)
        move.l  GK_LDO_ARG1(%sp),%d0
        cmpi.l  #15,%d0
        bhi.w   gk_lfo_designer_operations_fatal_entry_id
        movea.l #GK_STOCK_LFO_DESIGNER_STEP_OPERATION,%a4
        movea.l #gk_stock_lfo_designer_step_operation,%a5
        movea.l #GK_LDO_OPERATION_STEP,%a6
        move.l GK_LDO_ARG1(%sp),%d0
        move.l GK_LDO_ARG2(%sp),%d1
        move.l GK_LDO_RETURN(%sp),%d2
        cmpi.l #GK_STOCK_DIRECT_PRESS_RETURN,%d2
        beq.w .Lgk_ldo_direct_press1
        cmpi.l #GK_STOCK_DIRECT_REPEAT_RETURN,%d2
        beq.w .Lgk_ldo_direct_repeat1
        cmpi.l #GK_STOCK_DIRECT_RELEASE_RETURN,%d2
        beq.w .Lgk_ldo_direct_release1
        bra.w gk_lfo_designer_operations_fatal_entry_return
.Lgk_ldo_direct_press1:
        tst.l %d1
        beq.w gk_lfo_designer_operations_fatal_entry_event
        cmp.l (%sp),%d0
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        cmp.l 8(%sp),%d1
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        move.l GK_LDO_OUT_A0(%sp),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        moveq #GK_LDO_KIND_PRESS,%d2
        bra.w .Lgk_ldo_direct_slot1
.Lgk_ldo_direct_repeat1:
        cmpi.l #2,%d1
        bne.w gk_lfo_designer_operations_fatal_entry_event
        move.l GK_LDO_OUT_A0(%sp),%d2
        cmp.l %d0,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        move.l GK_LDO_OUT_A1(%sp),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        moveq #GK_LDO_KIND_REPEAT,%d2
        bra.w .Lgk_ldo_direct_slot1
.Lgk_ldo_direct_release1:
        tst.l %d1
        bne.w gk_lfo_designer_operations_fatal_entry_event
        cmp.l (%sp),%d0
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        cmp.l 8(%sp),%d1
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        move.l GK_LDO_OUT_A0(%sp),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        moveq #GK_LDO_KIND_RELEASE,%d2
.Lgk_ldo_direct_slot1:
        move.l %d2,GK_LDO_CALLBACK_KIND(%sp)
        move.l %d0,%d3
        mulu.w #24,%d3
        lsl.l #2,%d2
        add.l %d2,%d3
        lea GK_STOCK_LFO_DESIGNER_BUTTON_REGISTRY,%a0
        move.l (%a0,%d3.l),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_registry
        bra.w   .Lgk_ldo_execute
        .size   gk_stock_lfo_designer_step_operation,.-gk_stock_lfo_designer_step_operation
        .global gk_stock_lfo_designer_relative_operation
        .type   gk_stock_lfo_designer_relative_operation,@function
gk_stock_lfo_designer_relative_operation:
        lea -GK_LDO_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_LDO_OUT_D0(%sp)
        move.l %d1,GK_LDO_OUT_D1(%sp)
        move.l %a0,GK_LDO_OUT_A0(%sp)
        move.l %a1,GK_LDO_OUT_A1(%sp)
        move.l  GK_LDO_ARG1(%sp),%d0
        cmpi.l  #6,%d0
        bhi.w   gk_lfo_designer_operations_fatal_entry_id
        cmp.l   GK_LDO_OUT_D1(%sp),%d0
        bne.w   gk_lfo_designer_operations_fatal_entry_scratch
        movea.l #gk_stock_lfo_designer_relative_operation,%a5
        move.l  GK_LDO_OUT_D0(%sp),%d1
        cmp.l   %a5,%d1
        bne.w   gk_lfo_designer_operations_fatal_entry_scratch
        move.l  GK_LDO_OUT_A1(%sp),%d1
        cmp.l   %a5,%d1
        bne.w   gk_lfo_designer_operations_fatal_entry_scratch
        move.l  %d0,%d1
        lsl.l   #4,%d0
        lsl.l   #2,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_LFO_DESIGNER_OPERATION_RELATIVE_REGISTRY,%a0
        adda.l  %d0,%a0
        move.l  GK_LDO_OUT_A0(%sp),%d1
        cmp.l   %a0,%d1
        bne.w   gk_lfo_designer_operations_fatal_entry_registry
        move.l  (%a0),%d1
        cmp.l   %a5,%d1
        bne.w   gk_lfo_designer_operations_fatal_entry_registry
        move.l  GK_LDO_ARG2(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_ldo_relative_delta_negative
        tst.l   %d1
        bne.w   gk_lfo_designer_operations_fatal_entry_event
        bra.s   .Lgk_ldo_relative_delta_ok
.Lgk_ldo_relative_delta_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_lfo_designer_operations_fatal_entry_event
.Lgk_ldo_relative_delta_ok:
        movea.l #GK_STOCK_LFO_DESIGNER_RELATIVE_OPERATION,%a4
        movea.l #GK_LDO_OPERATION_RELATIVE,%a6
        moveq   #GK_LDO_KIND_PRESS,%d0
        move.l  %d0,GK_LDO_CALLBACK_KIND(%sp)
        bra.w   .Lgk_ldo_execute
        .size   gk_stock_lfo_designer_relative_operation,.-gk_stock_lfo_designer_relative_operation
        .global gk_stock_lfo_designer_transpose_operation
        .type   gk_stock_lfo_designer_transpose_operation,@function
gk_stock_lfo_designer_transpose_operation:
        lea -GK_LDO_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_LDO_OUT_D0(%sp)
        move.l %d1,GK_LDO_OUT_D1(%sp)
        move.l %a0,GK_LDO_OUT_A0(%sp)
        move.l %a1,GK_LDO_OUT_A1(%sp)
        move.l  GK_LDO_ARG1(%sp),%d0
        cmpi.l  #0x20,%d0
        beq.s   .Lgk_ldo_transpose_id_ok
        cmpi.l  #0x33,%d0
        bne.w   gk_lfo_designer_operations_fatal_entry_id
.Lgk_ldo_transpose_id_ok:
        movea.l #GK_STOCK_LFO_DESIGNER_TRANSPOSE_OPERATION,%a4
        movea.l #gk_stock_lfo_designer_transpose_operation,%a5
        movea.l #GK_LDO_OPERATION_TRANSPOSE,%a6
        move.l GK_LDO_ARG1(%sp),%d0
        move.l GK_LDO_ARG2(%sp),%d1
        move.l GK_LDO_RETURN(%sp),%d2
        cmpi.l #GK_STOCK_DIRECT_PRESS_RETURN,%d2
        beq.w .Lgk_ldo_direct_press4
        cmpi.l #GK_STOCK_DIRECT_REPEAT_RETURN,%d2
        beq.w .Lgk_ldo_direct_repeat4
        bra.w gk_lfo_designer_operations_fatal_entry_return
.Lgk_ldo_direct_press4:
        tst.l %d1
        beq.w gk_lfo_designer_operations_fatal_entry_event
        cmp.l (%sp),%d0
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        cmp.l 8(%sp),%d1
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        move.l GK_LDO_OUT_A0(%sp),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        moveq #GK_LDO_KIND_PRESS,%d2
        bra.w .Lgk_ldo_direct_slot4
.Lgk_ldo_direct_repeat4:
        cmpi.l #2,%d1
        bne.w gk_lfo_designer_operations_fatal_entry_event
        move.l GK_LDO_OUT_A0(%sp),%d2
        cmp.l %d0,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        move.l GK_LDO_OUT_A1(%sp),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        moveq #GK_LDO_KIND_REPEAT,%d2
        bra.w .Lgk_ldo_direct_slot4
.Lgk_ldo_direct_slot4:
        move.l %d2,GK_LDO_CALLBACK_KIND(%sp)
        move.l %d0,%d3
        mulu.w #24,%d3
        lsl.l #2,%d2
        add.l %d2,%d3
        lea GK_STOCK_LFO_DESIGNER_BUTTON_REGISTRY,%a0
        move.l (%a0,%d3.l),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_registry
        bra.w   .Lgk_ldo_execute
        .size   gk_stock_lfo_designer_transpose_operation,.-gk_stock_lfo_designer_transpose_operation
        .global gk_stock_lfo_designer_rotate_operation
        .type   gk_stock_lfo_designer_rotate_operation,@function
gk_stock_lfo_designer_rotate_operation:
        lea -GK_LDO_FRAME(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l %d0,GK_LDO_OUT_D0(%sp)
        move.l %d1,GK_LDO_OUT_D1(%sp)
        move.l %a0,GK_LDO_OUT_A0(%sp)
        move.l %a1,GK_LDO_OUT_A1(%sp)
        move.l  GK_LDO_ARG1(%sp),%d0
        cmpi.l  #0x21,%d0
        beq.s   .Lgk_ldo_rotate_id_ok
        cmpi.l  #0x34,%d0
        bne.w   gk_lfo_designer_operations_fatal_entry_id
.Lgk_ldo_rotate_id_ok:
        movea.l #GK_STOCK_LFO_DESIGNER_ROTATE_OPERATION,%a4
        movea.l #gk_stock_lfo_designer_rotate_operation,%a5
        movea.l #GK_LDO_OPERATION_ROTATE,%a6
        move.l GK_LDO_ARG1(%sp),%d0
        move.l GK_LDO_ARG2(%sp),%d1
        move.l GK_LDO_RETURN(%sp),%d2
        cmpi.l #GK_STOCK_DIRECT_PRESS_RETURN,%d2
        beq.w .Lgk_ldo_direct_press6
        cmpi.l #GK_STOCK_DIRECT_REPEAT_RETURN,%d2
        beq.w .Lgk_ldo_direct_repeat6
        bra.w gk_lfo_designer_operations_fatal_entry_return
.Lgk_ldo_direct_press6:
        tst.l %d1
        beq.w gk_lfo_designer_operations_fatal_entry_event
        cmp.l (%sp),%d0
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        cmp.l 8(%sp),%d1
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        move.l GK_LDO_OUT_A0(%sp),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        moveq #GK_LDO_KIND_PRESS,%d2
        bra.w .Lgk_ldo_direct_slot6
.Lgk_ldo_direct_repeat6:
        cmpi.l #2,%d1
        bne.w gk_lfo_designer_operations_fatal_entry_event
        move.l GK_LDO_OUT_A0(%sp),%d2
        cmp.l %d0,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        move.l GK_LDO_OUT_A1(%sp),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_scratch
        moveq #GK_LDO_KIND_REPEAT,%d2
        bra.w .Lgk_ldo_direct_slot6
.Lgk_ldo_direct_slot6:
        move.l %d2,GK_LDO_CALLBACK_KIND(%sp)
        move.l %d0,%d3
        mulu.w #24,%d3
        lsl.l #2,%d2
        add.l %d2,%d3
        lea GK_STOCK_LFO_DESIGNER_BUTTON_REGISTRY,%a0
        move.l (%a0,%d3.l),%d2
        cmp.l %a5,%d2
        bne.w gk_lfo_designer_operations_fatal_entry_registry
        bra.w   .Lgk_ldo_execute
        .size   gk_stock_lfo_designer_rotate_operation,.-gk_stock_lfo_designer_rotate_operation
.Lgk_ldo_selection_popcount:
        moveq   #0,%d0
        moveq   #0,%d1
        move.w  GK_STOCK_LFO_DESIGNER_OPERATION_SELECTION,%d1
        moveq   #0,%d2
.Lgk_ldo_selection_popcount_loop:
        btst    %d2,%d1
        beq.s   .Lgk_ldo_selection_popcount_next
        addq.l  #1,%d0
.Lgk_ldo_selection_popcount_next:
        addq.l  #1,%d2
        cmpi.l  #16,%d2
        bne.s   .Lgk_ldo_selection_popcount_loop
        rts
.Lgk_ldo_execute:
        lea     gk_track_pair_byte0_d3_old_pc_guard+0x08000000,%a0
        move.l  (%a0),%d0
        cmpi.l  #0x4e714e71,%d0
        bne.w   gk_lfo_designer_operations_fatal_runtime_image
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_ldo_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_ldo_busy
        bra.w   gk_lfo_designer_operations_fatal_entry_lifecycle
.Lgk_ldo_lifecycle_active:
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        jsr     gk_track_pair_byte0_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_ldo_busy
        tst.l   %d0
        bne.w   gk_lfo_designer_operations_fatal_entry_lifecycle
        clr.l   GK_LDO_EXPECTED(%sp)
        clr.l   GK_LDO_ROUTE(%sp)
        move.l  %a6,%d0
        cmpi.l  #GK_LDO_OPERATION_STEP,%d0
        bne.s   .Lgk_ldo_expected_relative
        tst.l   GK_LDO_ARG2(%sp)
        bne.w   .Lgk_ldo_expected_ready
        tst.l   GK_STOCK_LFO_DESIGNER_OPERATION_GATE
        bne.w   .Lgk_ldo_expected_ready
        moveq   #2,%d0
        move.l  %d0,GK_LDO_EXPECTED(%sp)
        moveq   #GK_LDO_ROUTE_STEP,%d0
        move.l  %d0,GK_LDO_ROUTE(%sp)
        bra.w   .Lgk_ldo_expected_ready
.Lgk_ldo_expected_relative:
        cmpi.l  #GK_LDO_OPERATION_RELATIVE,%d0
        bne.w   .Lgk_ldo_expected_transpose
        move.l  GK_LDO_ARG1(%sp),%d0
        cmpi.l  #2,%d0
        bne.s   .Lgk_ldo_expected_relative_id5
        moveq   #1,%d0
        move.l  %d0,GK_LDO_EXPECTED(%sp)
        moveq   #GK_LDO_ROUTE_RELATIVE_ID2,%d0
        move.l  %d0,GK_LDO_ROUTE(%sp)
        bra.w   .Lgk_ldo_expected_ready
.Lgk_ldo_expected_relative_id5:
        cmpi.l  #5,%d0
        bne.s   .Lgk_ldo_expected_relative_id6
        moveq   #1,%d0
        move.l  %d0,GK_LDO_EXPECTED(%sp)
        moveq   #GK_LDO_ROUTE_RELATIVE_ID5,%d0
        move.l  %d0,GK_LDO_ROUTE(%sp)
        bra.w   .Lgk_ldo_expected_ready
.Lgk_ldo_expected_relative_id6:
        cmpi.l  #6,%d0
        bne.w   .Lgk_ldo_expected_ready
        bsr.w   .Lgk_ldo_selection_popcount
        cmpi.l  #1,%d0
        bne.s   .Lgk_ldo_expected_relative_multi
        move.l  GK_STOCK_LFO_DESIGNER_OPERATION_SHIFT_INIT,%d1
        cmpi.l  #1,%d1
        bhi.w   gk_lfo_designer_operations_fatal_expected
        tst.l   %d1
        bne.s   .Lgk_ldo_expected_relative_single_ok
        move.l  GK_STOCK_LFO_DESIGNER_OPERATION_SHIFT_ANCHOR,%d1
        cmpi.l  #3,%d1
        bhi.w   gk_lfo_designer_operations_fatal_expected
.Lgk_ldo_expected_relative_single_ok:
        moveq   #1,%d0
        move.l  %d0,GK_LDO_EXPECTED(%sp)
        moveq   #GK_LDO_ROUTE_RELATIVE_SINGLE,%d0
        move.l  %d0,GK_LDO_ROUTE(%sp)
        bra.w   .Lgk_ldo_expected_ready
.Lgk_ldo_expected_relative_multi:
        move.l  %d0,GK_LDO_EXPECTED(%sp)
        moveq   #GK_LDO_ROUTE_RELATIVE_MULTI,%d0
        move.l  %d0,GK_LDO_ROUTE(%sp)
        bra.w   .Lgk_ldo_expected_ready
.Lgk_ldo_expected_transpose:
        cmpi.l  #GK_LDO_OPERATION_TRANSPOSE,%d0
        bne.s   .Lgk_ldo_expected_rotate
        bsr.w   .Lgk_ldo_selection_popcount
        move.l  %d0,GK_LDO_EXPECTED(%sp)
        moveq   #GK_LDO_ROUTE_TRANSPOSE,%d0
        move.l  %d0,GK_LDO_ROUTE(%sp)
        bra.s   .Lgk_ldo_expected_ready
.Lgk_ldo_expected_rotate:
        cmpi.l  #GK_LDO_OPERATION_ROTATE,%d0
        bne.w   gk_lfo_designer_operations_fatal_expected
        move.l  %a2,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        move.l  %a3,%d1
        mulu.w  #0x24,%d1
        .incbin "stock/0365.bin", 0, 6
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        adda.l  %d0,%a0
        adda.l  %d1,%a0
        moveq   #0,%d0
        move.b  0x4f0(%a0),%d0
        cmpi.l  #15,%d0
        bhi.w   gk_lfo_designer_operations_fatal_expected
        addq.l  #2,%d0
        move.l  %d0,GK_LDO_EXPECTED(%sp)
        move.l  GK_LDO_ARG1(%sp),%d0
        cmpi.l  #0x34,%d0
        bne.s   .Lgk_ldo_expected_rotate_right
        moveq   #GK_LDO_ROUTE_ROTATE_LEFT,%d0
        move.l  %d0,GK_LDO_ROUTE(%sp)
        bra.s   .Lgk_ldo_expected_ready
.Lgk_ldo_expected_rotate_right:
        moveq   #GK_LDO_ROUTE_ROTATE_RIGHT,%d0
        move.l  %d0,GK_LDO_ROUTE(%sp)
.Lgk_ldo_expected_ready:
        move.l  GK_LDO_ARG1(%sp),%d2
        move.l  GK_LDO_ARG2(%sp),%d3
        move.l  GK_LDO_ROUTE(%sp),-(%sp)
        move.l  GK_LDO_EXPECTED+4(%sp),-(%sp)
        clr.l   -(%sp)
        move.l  %d7,%d0
        not.l   %d0
        move.l  %d0,-(%sp)
        move.l  %d7,-(%sp)
        move.l  %d3,-(%sp)
        move.l  %d2,-(%sp)
        move.l  GK_LDO_OUT_D0+28(%sp),%d0
        move.l  GK_LDO_OUT_D1+28(%sp),%d1
        movea.l GK_LDO_OUT_A0+28(%sp),%a0
        movea.l GK_LDO_OUT_A1+28(%sp),%a1
        move.l  %a6,%d2
        cmpi.l  #GK_LDO_OPERATION_RELATIVE,%d2
        bne.s   .Lgk_ldo_stock_direct_entry
        move.l  %a4,%d0
        movea.l %a4,%a1
        bra.s   .Lgk_ldo_stock_entry_ready
.Lgk_ldo_stock_direct_entry:
        move.l  GK_LDO_CALLBACK_KIND+28(%sp),%d2
        cmpi.l  #GK_LDO_KIND_REPEAT,%d2
        beq.s   .Lgk_ldo_stock_repeat_entry
        movea.l %a4,%a0
        bra.s   .Lgk_ldo_stock_entry_ready
.Lgk_ldo_stock_repeat_entry:
        movea.l %a4,%a1
.Lgk_ldo_stock_entry_ready:
        .global gk_lfo_designer_operations_stock_call
gk_lfo_designer_operations_stock_call:
        jsr     (%a4)
        move.w  %sr,%d2
        move.w  %d2,GK_LDO_OUT_SR+28(%sp)
        move.l  %d0,GK_LDO_OUT_D0+28(%sp)
        move.l  %d1,GK_LDO_OUT_D1+28(%sp)
        move.l  %a0,GK_LDO_OUT_A0+28(%sp)
        move.l  %a1,GK_LDO_OUT_A1+28(%sp)
        move.l  16(%sp),%d2
        cmp.l   GK_LDO_EXPECTED+28(%sp),%d2
        bne.w   gk_lfo_designer_operations_fatal_finish_count
        move.l  20(%sp),%d2
        cmp.l   GK_LDO_EXPECTED+28(%sp),%d2
        bne.w   gk_lfo_designer_operations_fatal_finish_expected
        move.l  24(%sp),%d2
        cmp.l   GK_LDO_ROUTE+28(%sp),%d2
        bne.w   gk_lfo_designer_operations_fatal_finish_route
        move.l  8(%sp),GK_LDO_STOCK_TARGET+28(%sp)
        move.l  12(%sp),GK_LDO_CALLBACK_KIND+28(%sp)
        lea     28(%sp),%sp
        move.l  GK_LDO_STOCK_TARGET(%sp),%d0
        move.l  GK_LDO_CALLBACK_KIND(%sp),%d1
        move.l  %a2,-(%sp)
        jsr     gk_lfo_designer_token_validate
        movea.l (%sp)+,%a2
        move.l  GK_LDO_STOCK_TARGET(%sp),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_STATE_MASK,%d0
        tst.l   GK_LDO_EXPECTED(%sp)
        bne.s   .Lgk_ldo_finish_written
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d0
        bne.w   gk_lfo_designer_operations_fatal_finish_state
        bra.s   .Lgk_ldo_finish_token_ok
.Lgk_ldo_finish_written:
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d0
        bne.w   gk_lfo_designer_operations_fatal_finish_state
.Lgk_ldo_finish_token_ok:
        move.l  GK_LDO_STOCK_TARGET(%sp),%d0
        jsr     gk_track_pair_byte0_finish
        movem.l (%sp),%d2-%d7/%a2-%a6
        move.l  GK_LDO_OUT_D0(%sp),%d0
        move.l  GK_LDO_OUT_D1(%sp),%d1
        movea.l GK_LDO_OUT_A0(%sp),%a0
        movea.l GK_LDO_OUT_A1(%sp),%a1
        move.w  GK_LDO_OUT_SR(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d2
        lea     GK_LDO_FRAME(%sp),%sp
        rts
.Lgk_ldo_busy:
        movem.l (%sp),%d2-%d7/%a2-%a6
        move.l  GK_LDO_OUT_D0(%sp),%d0
        move.l  GK_LDO_OUT_D1(%sp),%d1
        movea.l GK_LDO_OUT_A0(%sp),%a0
        movea.l GK_LDO_OUT_A1(%sp),%a1
        lea     GK_LDO_FRAME(%sp),%sp
        rts
        .global gk_lfo_designer_operations_write_marker_d3
        .type   gk_lfo_designer_operations_write_marker_d3,@function
gk_lfo_designer_operations_write_marker_d3:
        lea     -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        moveq   #108,%d6
        moveq   #3,%d7
        bra.w   .Lgk_ldo_marker_common
        .size   gk_lfo_designer_operations_write_marker_d3,.-gk_lfo_designer_operations_write_marker_d3
        .global gk_lfo_designer_operations_write_marker_d1
        .type   gk_lfo_designer_operations_write_marker_d1,@function
gk_lfo_designer_operations_write_marker_d1:
        lea     -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.l  64(%sp),%d0
        cmpi.l  #GK_STOCK_LFO_DESIGNER_STEP_DIRTY_2_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_step_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RELATIVE_ID2_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_relative_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RELATIVE_ID5_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_relative_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RELATIVE_SINGLE_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_relative_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RELATIVE_MULTI_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_relative_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_TRANSPOSE_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_relative_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_LEFT_LOOP_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_rotate_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_RIGHT_LOOP_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_rotate_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_STEP_RETURN,%d0
        beq.s   .Lgk_ldo_marker_d1_rotate_frame
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_MASK_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
.Lgk_ldo_marker_d1_rotate_frame:
        moveq   #124,%d6
        bra.s   .Lgk_ldo_marker_d1_ready
.Lgk_ldo_marker_d1_relative_frame:
        moveq   #116,%d6
        bra.s   .Lgk_ldo_marker_d1_ready
.Lgk_ldo_marker_d1_step_frame:
        moveq   #108,%d6
.Lgk_ldo_marker_d1_ready:
        moveq   #1,%d7
.Lgk_ldo_marker_common:
        cmpi.l  #3,%d7
        bne.s   .Lgk_ldo_marker_source_d1
        move.l  12(%sp),%d0
        bra.s   .Lgk_ldo_marker_source_ready
.Lgk_ldo_marker_source_d1:
        move.l  4(%sp),%d0
.Lgk_ldo_marker_source_ready:
        cmpi.l  #1,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_dirty
        move.l  (%sp,%d6.l),%d0
        move.l  4(%sp,%d6.l),%d1
        bsr.w   gk_lfo_designer_token_validate
        move.l  8(%sp,%d6.l),%d5
        move.l  12(%sp,%d6.l),%d2
        cmp.l   %d2,%d5
        bcc.w   gk_lfo_designer_operations_fatal_marker_count
        move.l  (%sp,%d6.l),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_STATE_MASK,%d0
        tst.l   %d5
        bne.s   .Lgk_ldo_marker_existing_write
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_state
        bra.s   .Lgk_ldo_marker_state_ok
.Lgk_ldo_marker_existing_write:
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_state
.Lgk_ldo_marker_state_ok:
        move.l  16(%sp,%d6.l),%d4
        move.l  64(%sp),%d0
        cmpi.l  #GK_LDO_ROUTE_STEP,%d4
        bne.s   .Lgk_ldo_marker_route_id2
        cmpi.l  #2,%d2
        bne.w   gk_lfo_designer_operations_fatal_marker_route
        tst.l   %d5
        bne.s   .Lgk_ldo_marker_step_second
        cmpi.l  #3,%d7
        bne.w   gk_lfo_designer_operations_fatal_marker_route
        cmpi.l  #GK_STOCK_LFO_DESIGNER_STEP_DIRTY_1_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_sequence_ok
.Lgk_ldo_marker_step_second:
        cmpi.l  #1,%d5
        bne.w   gk_lfo_designer_operations_fatal_marker_count
        cmpi.l  #1,%d7
        bne.w   gk_lfo_designer_operations_fatal_marker_route
        cmpi.l  #GK_STOCK_LFO_DESIGNER_STEP_DIRTY_2_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_sequence_ok
.Lgk_ldo_marker_route_id2:
        cmpi.l  #GK_LDO_ROUTE_RELATIVE_ID2,%d4
        bne.s   .Lgk_ldo_marker_route_id5
        cmpi.l  #1,%d2
        bne.w   gk_lfo_designer_operations_fatal_marker_route
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RELATIVE_ID2_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_single_d1
.Lgk_ldo_marker_route_id5:
        cmpi.l  #GK_LDO_ROUTE_RELATIVE_ID5,%d4
        bne.s   .Lgk_ldo_marker_route_relative_single
        cmpi.l  #1,%d2
        bne.w   gk_lfo_designer_operations_fatal_marker_route
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RELATIVE_ID5_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_single_d1
.Lgk_ldo_marker_route_relative_single:
        cmpi.l  #GK_LDO_ROUTE_RELATIVE_SINGLE,%d4
        bne.s   .Lgk_ldo_marker_route_relative_multi
        cmpi.l  #1,%d2
        bne.w   gk_lfo_designer_operations_fatal_marker_route
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RELATIVE_SINGLE_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_single_d1
.Lgk_ldo_marker_route_relative_multi:
        cmpi.l  #GK_LDO_ROUTE_RELATIVE_MULTI,%d4
        bne.s   .Lgk_ldo_marker_route_transpose
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RELATIVE_MULTI_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_repeated_d1
.Lgk_ldo_marker_route_transpose:
        cmpi.l  #GK_LDO_ROUTE_TRANSPOSE,%d4
        bne.s   .Lgk_ldo_marker_route_rotate_left
        cmpi.l  #GK_STOCK_LFO_DESIGNER_TRANSPOSE_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_repeated_d1
.Lgk_ldo_marker_route_rotate_left:
        cmpi.l  #GK_LDO_ROUTE_ROTATE_LEFT,%d4
        bne.s   .Lgk_ldo_marker_route_rotate_right
        move.l  %d2,%d3
        subq.l  #2,%d3
        cmp.l   %d3,%d5
        bcs.s   .Lgk_ldo_marker_rotate_left_loop
        beq.s   .Lgk_ldo_marker_rotate_step
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_MASK_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_repeated_d1
.Lgk_ldo_marker_rotate_left_loop:
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_LEFT_LOOP_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.w   .Lgk_ldo_marker_repeated_d1
.Lgk_ldo_marker_route_rotate_right:
        cmpi.l  #GK_LDO_ROUTE_ROTATE_RIGHT,%d4
        bne.w   gk_lfo_designer_operations_fatal_marker_route
        move.l  %d2,%d3
        subq.l  #2,%d3
        cmp.l   %d3,%d5
        bcs.s   .Lgk_ldo_marker_rotate_right_loop
        beq.s   .Lgk_ldo_marker_rotate_step
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_MASK_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.s   .Lgk_ldo_marker_repeated_d1
.Lgk_ldo_marker_rotate_right_loop:
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_RIGHT_LOOP_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.s   .Lgk_ldo_marker_repeated_d1
.Lgk_ldo_marker_rotate_step:
        cmpi.l  #GK_STOCK_LFO_DESIGNER_ROTATE_STEP_RETURN,%d0
        bne.w   gk_lfo_designer_operations_fatal_marker_return
        bra.s   .Lgk_ldo_marker_repeated_d1
.Lgk_ldo_marker_single_d1:
        tst.l   %d5
        bne.w   gk_lfo_designer_operations_fatal_marker_count
.Lgk_ldo_marker_repeated_d1:
        cmpi.l  #1,%d7
        bne.w   gk_lfo_designer_operations_fatal_marker_route
.Lgk_ldo_marker_sequence_ok:
        addq.l  #1,%d5
        move.l  %d5,8(%sp,%d6.l)
        move.l  (%sp,%d6.l),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d0
        move.l  %d0,(%sp,%d6.l)
        not.l   %d0
        move.l  %d0,4(%sp,%d6.l)
        cmpi.l  #3,%d7
        beq.s   .Lgk_ldo_marker_restore_d3
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     64(%sp),%sp
        .global gk_lfo_designer_operations_stock_dirty_store_d1
gk_lfo_designer_operations_stock_dirty_store_d1:
        .incbin "stock/0366.bin", 0, 6
        rts
.Lgk_ldo_marker_restore_d3:
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     64(%sp),%sp
        .global gk_lfo_designer_operations_stock_dirty_store_d3
gk_lfo_designer_operations_stock_dirty_store_d3:
        .incbin "stock/0367.bin", 0, 6
        rts
        .size   gk_lfo_designer_operations_write_marker_d1,.-gk_lfo_designer_operations_write_marker_d1
        .global gk_lfo_designer_operations_fatal_runtime_image
        .type gk_lfo_designer_operations_fatal_runtime_image,@function
gk_lfo_designer_operations_fatal_runtime_image:
        illegal
        bra.s gk_lfo_designer_operations_fatal_runtime_image
        .size gk_lfo_designer_operations_fatal_runtime_image,.-gk_lfo_designer_operations_fatal_runtime_image
        .global gk_lfo_designer_operations_fatal_entry_return
        .type gk_lfo_designer_operations_fatal_entry_return,@function
gk_lfo_designer_operations_fatal_entry_return:
        illegal
        bra.s gk_lfo_designer_operations_fatal_entry_return
        .size gk_lfo_designer_operations_fatal_entry_return,.-gk_lfo_designer_operations_fatal_entry_return
        .global gk_lfo_designer_operations_fatal_entry_id
        .type gk_lfo_designer_operations_fatal_entry_id,@function
gk_lfo_designer_operations_fatal_entry_id:
        illegal
        bra.s gk_lfo_designer_operations_fatal_entry_id
        .size gk_lfo_designer_operations_fatal_entry_id,.-gk_lfo_designer_operations_fatal_entry_id
        .global gk_lfo_designer_operations_fatal_entry_event
        .type gk_lfo_designer_operations_fatal_entry_event,@function
gk_lfo_designer_operations_fatal_entry_event:
        illegal
        bra.s gk_lfo_designer_operations_fatal_entry_event
        .size gk_lfo_designer_operations_fatal_entry_event,.-gk_lfo_designer_operations_fatal_entry_event
        .global gk_lfo_designer_operations_fatal_entry_scratch
        .type gk_lfo_designer_operations_fatal_entry_scratch,@function
gk_lfo_designer_operations_fatal_entry_scratch:
        illegal
        bra.s gk_lfo_designer_operations_fatal_entry_scratch
        .size gk_lfo_designer_operations_fatal_entry_scratch,.-gk_lfo_designer_operations_fatal_entry_scratch
        .global gk_lfo_designer_operations_fatal_entry_registry
        .type gk_lfo_designer_operations_fatal_entry_registry,@function
gk_lfo_designer_operations_fatal_entry_registry:
        illegal
        bra.s gk_lfo_designer_operations_fatal_entry_registry
        .size gk_lfo_designer_operations_fatal_entry_registry,.-gk_lfo_designer_operations_fatal_entry_registry
        .global gk_lfo_designer_operations_fatal_entry_lifecycle
        .type gk_lfo_designer_operations_fatal_entry_lifecycle,@function
gk_lfo_designer_operations_fatal_entry_lifecycle:
        illegal
        bra.s gk_lfo_designer_operations_fatal_entry_lifecycle
        .size gk_lfo_designer_operations_fatal_entry_lifecycle,.-gk_lfo_designer_operations_fatal_entry_lifecycle
        .global gk_lfo_designer_operations_fatal_expected
        .type gk_lfo_designer_operations_fatal_expected,@function
gk_lfo_designer_operations_fatal_expected:
        illegal
        bra.s gk_lfo_designer_operations_fatal_expected
        .size gk_lfo_designer_operations_fatal_expected,.-gk_lfo_designer_operations_fatal_expected
        .global gk_lfo_designer_operations_fatal_finish_count
        .type gk_lfo_designer_operations_fatal_finish_count,@function
gk_lfo_designer_operations_fatal_finish_count:
        illegal
        bra.s gk_lfo_designer_operations_fatal_finish_count
        .size gk_lfo_designer_operations_fatal_finish_count,.-gk_lfo_designer_operations_fatal_finish_count
        .global gk_lfo_designer_operations_fatal_finish_expected
        .type gk_lfo_designer_operations_fatal_finish_expected,@function
gk_lfo_designer_operations_fatal_finish_expected:
        illegal
        bra.s gk_lfo_designer_operations_fatal_finish_expected
        .size gk_lfo_designer_operations_fatal_finish_expected,.-gk_lfo_designer_operations_fatal_finish_expected
        .global gk_lfo_designer_operations_fatal_finish_route
        .type gk_lfo_designer_operations_fatal_finish_route,@function
gk_lfo_designer_operations_fatal_finish_route:
        illegal
        bra.s gk_lfo_designer_operations_fatal_finish_route
        .size gk_lfo_designer_operations_fatal_finish_route,.-gk_lfo_designer_operations_fatal_finish_route
        .global gk_lfo_designer_operations_fatal_finish_state
        .type gk_lfo_designer_operations_fatal_finish_state,@function
gk_lfo_designer_operations_fatal_finish_state:
        illegal
        bra.s gk_lfo_designer_operations_fatal_finish_state
        .size gk_lfo_designer_operations_fatal_finish_state,.-gk_lfo_designer_operations_fatal_finish_state
        .global gk_lfo_designer_operations_fatal_marker_return
        .type gk_lfo_designer_operations_fatal_marker_return,@function
gk_lfo_designer_operations_fatal_marker_return:
        illegal
        bra.s gk_lfo_designer_operations_fatal_marker_return
        .size gk_lfo_designer_operations_fatal_marker_return,.-gk_lfo_designer_operations_fatal_marker_return
        .global gk_lfo_designer_operations_fatal_marker_dirty
        .type gk_lfo_designer_operations_fatal_marker_dirty,@function
gk_lfo_designer_operations_fatal_marker_dirty:
        illegal
        bra.s gk_lfo_designer_operations_fatal_marker_dirty
        .size gk_lfo_designer_operations_fatal_marker_dirty,.-gk_lfo_designer_operations_fatal_marker_dirty
        .global gk_lfo_designer_operations_fatal_marker_count
        .type gk_lfo_designer_operations_fatal_marker_count,@function
gk_lfo_designer_operations_fatal_marker_count:
        illegal
        bra.s gk_lfo_designer_operations_fatal_marker_count
        .size gk_lfo_designer_operations_fatal_marker_count,.-gk_lfo_designer_operations_fatal_marker_count
        .global gk_lfo_designer_operations_fatal_marker_state
        .type gk_lfo_designer_operations_fatal_marker_state,@function
gk_lfo_designer_operations_fatal_marker_state:
        illegal
        bra.s gk_lfo_designer_operations_fatal_marker_state
        .size gk_lfo_designer_operations_fatal_marker_state,.-gk_lfo_designer_operations_fatal_marker_state
        .global gk_lfo_designer_operations_fatal_marker_route
        .type gk_lfo_designer_operations_fatal_marker_route,@function
gk_lfo_designer_operations_fatal_marker_route:
        illegal
        bra.s gk_lfo_designer_operations_fatal_marker_route
        .size gk_lfo_designer_operations_fatal_marker_route,.-gk_lfo_designer_operations_fatal_marker_route
