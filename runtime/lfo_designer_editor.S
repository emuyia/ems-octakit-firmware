        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_lfo_designer_token_validate
        .type   gk_lfo_designer_token_validate,@function
gk_lfo_designer_token_validate:
        move.l  %d0,%d2
        not.l   %d2
        cmp.l   %d1,%d2
        bne.w   gk_lfo_designer_fatal_token_inverse
        move.l  %d0,%d2
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_STATE_MASK,%d2
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d2
        beq.s   .Lgk_lfo_designer_token_state_ok
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d2
        bne.w   gk_lfo_designer_fatal_token_state
.Lgk_lfo_designer_token_state_ok:
        move.l  %d0,%d3
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_CONTEXT_MASK,%d3
        tst.l   __gk_lifecycle_state
        bne.w   gk_lfo_designer_fatal_token_lifecycle
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.w   gk_lfo_designer_fatal_token_transition
        andi.l  #0x7e,%d0
        bne.w   gk_lfo_designer_fatal_token_transition
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        cmpi.l  #GK_TRANSITION_PRESERVE_NAME,%d0
        bne.w   gk_lfo_designer_fatal_token_pending
        tst.b   __gk_pending_ui_capture_created
        bne.w   gk_lfo_designer_fatal_token_pending
        move.l  %d3,%d2
        andi.l  #0x7f,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   gk_lfo_designer_fatal_token_descriptor
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d2,%d0
        bne.w   gk_lfo_designer_fatal_token_descriptor
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d2,%d0
        bne.w   gk_lfo_designer_fatal_token_descriptor
        move.l  %d3,%d0
        lsr.l   #7,%d0
        andi.l  #7,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_track
        move.l  %d3,%d1
        lsr.l   #8,%d1
        lsr.l   #2,%d1
        andi.l  #3,%d1
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   %d1,%d0
        bne.w   gk_lfo_designer_fatal_token_part
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   %d1,%d0
        bne.w   gk_lfo_designer_fatal_token_part
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   %d1,%d0
        bne.w   gk_lfo_designer_fatal_token_part
        move.l  %d3,%d0
        lsr.l   #8,%d0
        lsr.l   #4,%d0
        andi.l  #15,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_bank
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_bank
        moveq   #0,%d1
        move.b  GK_STOCK_ENGINE_BANK,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_bank
        moveq   #0,%d1
        move.b  __gk_current_bank,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_bank
        moveq   #0,%d1
        move.b  __gk_pending_bank,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_bank
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a0
        adda.l  %d0,%a0
        movea.l GK_STOCK_BANK_POINTER,%a1
        cmpa.l  %a0,%a1
        bne.w   gk_lfo_designer_fatal_token_bank_pointer
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmpi.l  #15,%d0
        bhi.w   gk_lfo_designer_fatal_token_pattern
        moveq   #0,%d1
        move.b  __gk_pending_pattern,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_pattern
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PATTERN,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_pattern
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_pattern
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        movea.l %a0,%a1
        adda.l  %d0,%a1
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a1
        moveq   #0,%d1
        move.b  (%a1),%d1
        move.l  %d3,%d0
        lsr.l   #8,%d0
        lsr.l   #2,%d0
        andi.l  #3,%d0
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_assignment
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a1
        moveq   #0,%d1
        move.b  __gk_current_pattern,%d1
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d1
        adda.l  %d1,%a1
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a1
        moveq   #0,%d1
        move.b  (%a1),%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_assignment
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        moveq   #0,%d1
        move.b  __gk_pending_kit,%d1
        cmp.l   %d0,%d1
        bne.w   gk_lfo_designer_fatal_token_kit
        moveq   #0,%d1
        move.b  __gk_workspace_bound,%d1
        moveq   #0,%d0
        move.b  __gk_pending_workspace_bound,%d0
        cmp.l   %d1,%d0
        bne.w   gk_lfo_designer_fatal_token_bound
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.l  %d0,%d1
        andi.l  #0xe6,%d1
        bne.w   gk_lfo_designer_fatal_token_descriptor
        btst    #0,%d0
        beq.w   gk_lfo_designer_fatal_token_descriptor
        btst    #3,%d0
        beq.w   gk_lfo_designer_fatal_token_descriptor
        tst.w   GK_DESC_READERS(%a2)
        beq.w   gk_lfo_designer_fatal_token_reader
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a2),%d0
        moveq   #0,%d1
        move.b  __gk_current_kit,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_designer_fatal_token_kit
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   gk_lfo_designer_fatal_token_physical
        move.l  %d0,%d1
        lsr.l   #2,%d1
        move.l  %d3,%d2
        lsr.l   #8,%d2
        lsr.l   #4,%d2
        andi.l  #15,%d2
        cmp.l   %d2,%d1
        bne.w   gk_lfo_designer_fatal_token_physical
        move.l  %d0,%d1
        andi.l  #3,%d1
        move.l  %d3,%d2
        lsr.l   #8,%d2
        lsr.l   #2,%d2
        andi.l  #3,%d2
        cmp.l   %d2,%d1
        bne.w   gk_lfo_designer_fatal_token_physical
        jsr     gk_physical_validate
        move.l  %d3,%d1
        andi.l  #0x7f,%d1
        cmp.l   %d1,%d0
        bne.w   gk_lfo_designer_fatal_token_physical
        rts
        .size   gk_lfo_designer_token_validate,.-gk_lfo_designer_token_validate
        .global gk_stock_lfo_designer_editor
        .type   gk_stock_lfo_designer_editor,@function
gk_stock_lfo_designer_editor:
        cmpi.l  #gk_stock_lfo_designer_editor,%d0
        bne.w   gk_lfo_designer_fatal_entry_callback
        cmpa.l  %d0,%a1
        bne.w   gk_lfo_designer_fatal_entry_callback
        move.l  4(%sp),%d0
        cmpi.l  #6,%d0
        bhi.w   gk_lfo_designer_fatal_entry_id
        cmp.l   %d1,%d0
        bne.w   gk_lfo_designer_fatal_entry_id
        move.l  %d0,%d1
        lsl.l   #4,%d0
        lsl.l   #2,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_LFO_DESIGNER_REGISTRY,%a1
        adda.l  %d0,%a1
        cmpa.l  %a1,%a0
        bne.w   gk_lfo_designer_fatal_entry_registry
        move.l  (%a0),%d0
        cmpi.l  #gk_stock_lfo_designer_editor,%d0
        bne.w   gk_lfo_designer_fatal_entry_registry
        lea     gk_track_pair_byte0_d3_old_pc_guard+0x08000000,%a1
        move.l  (%a1),%d0
        cmpi.l  #0x4e714e71,%d0
        bne.w   gk_lfo_designer_fatal_runtime_image
        move.l  8(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_lfo_designer_delta_negative
        tst.l   %d1
        bne.w   gk_lfo_designer_fatal_entry_delta
        bra.s   .Lgk_lfo_designer_delta_ok
.Lgk_lfo_designer_delta_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_lfo_designer_fatal_entry_delta
.Lgk_lfo_designer_delta_ok:
        move.l  0x400bc05c,%d0
        cmpi.l  #GK_STOCK_LFO_DESIGNER_RENDERER,%d0
        bne.w   gk_lfo_designer_fatal_renderer
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_lfo_designer_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_lfo_designer_busy_early
        bra.w   gk_lfo_designer_fatal_entry_lifecycle
.Lgk_lfo_designer_lifecycle_active:
        lea     -64(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        jsr     gk_track_pair_byte0_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_lfo_designer_busy_saved
        tst.l   %d0
        bne.w   gk_lfo_designer_fatal_entry_lifecycle
        movea.l %d7,%a6
        move.l  %d7,%d0
        not.l   %d0
        movea.l %d0,%a5
        move.l  72(%sp),%d1
        move.l  68(%sp),%d0
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        move.l  (%sp),%d0
        move.l  %d0,%d1
        lsl.l   #4,%d0
        lsl.l   #2,%d1
        add.l   %d1,%d0
        lea     GK_STOCK_LFO_DESIGNER_REGISTRY,%a0
        adda.l  %d0,%a0
        move.l  (%sp),%d1
        move.l  #GK_STOCK_LFO_DESIGNER_EDITOR,%d0
        movea.l %d0,%a1
        .global gk_lfo_designer_stock_call
gk_lfo_designer_stock_call:
        jsr     GK_STOCK_LFO_DESIGNER_EDITOR
        move.w  %sr,%d2
        move.w  %d2,68(%sp)
        move.l  %d0,52(%sp)
        move.l  %d1,56(%sp)
        move.l  %a0,60(%sp)
        move.l  %a1,64(%sp)
        lea     8(%sp),%sp
        move.l  %a6,%d0
        not.l   %d0
        cmp.l   %a5,%d0
        bne.w   gk_lfo_designer_fatal_finish_inverse
        move.l  %a6,%d0
        jsr     gk_track_pair_byte0_finish
        movem.l (%sp),%d2-%d7/%a2-%a6
        move.l  44(%sp),%d0
        move.l  48(%sp),%d1
        movea.l 52(%sp),%a0
        movea.l 56(%sp),%a1
        move.w  60(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d2
        lea     64(%sp),%sp
        rts
.Lgk_lfo_designer_busy_saved:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     64(%sp),%sp
.Lgk_lfo_designer_busy_early:
        moveq   #0,%d0
        rts
        .size   gk_stock_lfo_designer_editor,.-gk_stock_lfo_designer_editor
        .global gk_lfo_designer_write_marker
        .type   gk_lfo_designer_write_marker,@function
gk_lfo_designer_write_marker:
        lea     -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.l  64(%sp),%d0
        cmpi.l  #GK_STOCK_LFO_DESIGNER_DIRTY_RETURN,%d0
        bne.w   gk_lfo_designer_fatal_marker_return
        move.l  4(%sp),%d0
        cmpi.l  #1,%d0
        bne.w   gk_lfo_designer_fatal_marker_dirty
        move.l  108(%sp),%d0
        move.l  %d0,%d2
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_STATE_MASK,%d2
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d2
        bne.w   gk_lfo_designer_fatal_marker_token
        move.l  104(%sp),%d1
        bsr.w   gk_lfo_designer_token_validate
        move.l  108(%sp),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d0
        move.l  %d0,108(%sp)
        not.l   %d0
        move.l  %d0,104(%sp)
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     64(%sp),%sp
        .global gk_lfo_designer_stock_dirty_store
gk_lfo_designer_stock_dirty_store:
        .incbin "stock/0364.bin", 0, 6
        rts
        .size   gk_lfo_designer_write_marker,.-gk_lfo_designer_write_marker
        .global gk_lfo_designer_nested_block_write
        .type   gk_lfo_designer_nested_block_write,@function
gk_lfo_designer_nested_block_write:
        lea     -64(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.l  64(%sp),%d0
        cmpi.l  #GK_STOCK_LFO_DESIGNER_NESTED_SINGLE_RETURN,%d0
        beq.s   .Lgk_lfo_designer_nested_single
        cmpi.l  #GK_STOCK_LFO_DESIGNER_NESTED_LOOP_RETURN,%d0
        bne.w   gk_lfo_designer_fatal_nested_return
        moveq   #1,%d7
        move.l  68(%sp),%d0
        cmpi.l  #15,%d0
        bhi.w   gk_lfo_designer_fatal_nested_offset
        cmp.l   8(%sp),%d0
        bne.w   gk_lfo_designer_fatal_nested_offset
        move.l  44(%sp),%d1
        cmpi.l  #GK_STOCK_LFO_BLOCK_WRITE,%d1
        bne.w   gk_lfo_designer_fatal_nested_target
        moveq   #0,%d1
        move.w  GK_STOCK_LFO_DESIGNER_SELECTION_MASK,%d1
        btst    %d0,%d1
        beq.w   gk_lfo_designer_fatal_nested_selection
        bra.w   .Lgk_lfo_designer_nested_route_ok
.Lgk_lfo_designer_nested_single:
        moveq   #0,%d7
        move.l  68(%sp),%d0
        cmpi.l  #-3,%d0
        blt.w   gk_lfo_designer_fatal_nested_offset
        cmpi.l  #15,%d0
        bgt.w   gk_lfo_designer_fatal_nested_offset
        cmp.l   36(%sp),%d0
        bne.w   gk_lfo_designer_fatal_nested_offset
        moveq   #0,%d0
        moveq   #0,%d1
        moveq   #-1,%d2
        moveq   #0,%d3
        move.w  GK_STOCK_LFO_DESIGNER_SELECTION_MASK,%d3
.Lgk_lfo_designer_single_selection_loop:
        btst    %d0,%d3
        beq.s   .Lgk_lfo_designer_single_selection_next
        addq.l  #1,%d1
        move.l  %d0,%d2
.Lgk_lfo_designer_single_selection_next:
        addq.l  #1,%d0
        cmpi.l  #16,%d0
        bne.s   .Lgk_lfo_designer_single_selection_loop
        cmpi.l  #1,%d1
        bne.w   gk_lfo_designer_fatal_nested_selection
        move.l  16(%sp),%d4
        cmpi.l  #6,%d4
        beq.s   .Lgk_lfo_designer_single_id_ok
        cmpi.l  #2,%d4
        bhi.w   gk_lfo_designer_fatal_nested_id
.Lgk_lfo_designer_single_id_ok:
        move.l  GK_STOCK_LFO_DESIGNER_SHIFT_ANCHOR,%d1
        cmpi.l  #3,%d1
        bhi.w   gk_lfo_designer_fatal_nested_anchor
        lea     GK_STOCK_LFO_DESIGNER_SHIFT_TABLE,%a0
        mvs.b   (%a0,%d4.l),%d0
        sub.l   %d1,%d0
        add.l   %d2,%d0
        cmp.l   68(%sp),%d0
        bne.w   gk_lfo_designer_fatal_nested_offset
.Lgk_lfo_designer_nested_route_ok:
        move.l  16(%sp),%d0
        cmpi.l  #6,%d0
        beq.s   .Lgk_lfo_designer_nested_id_ok
        cmpi.l  #2,%d0
        bhi.w   gk_lfo_designer_fatal_nested_id
.Lgk_lfo_designer_nested_id_ok:
        move.l  72(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_lfo_designer_nested_value_negative
        tst.l   %d1
        bne.w   gk_lfo_designer_fatal_nested_value
        bra.s   .Lgk_lfo_designer_nested_value_ok
.Lgk_lfo_designer_nested_value_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_lfo_designer_fatal_nested_value
.Lgk_lfo_designer_nested_value_ok:
        move.l  116(%sp),%d0
        move.l  %d0,%d2
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_STATE_MASK,%d2
        tst.l   %d7
        bne.s   .Lgk_lfo_designer_nested_loop_token
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d2
        bne.w   gk_lfo_designer_fatal_nested_token
        bra.s   .Lgk_lfo_designer_nested_token_ok
.Lgk_lfo_designer_nested_loop_token:
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d2
        beq.s   .Lgk_lfo_designer_nested_token_ok
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d2
        bne.w   gk_lfo_designer_fatal_nested_token
.Lgk_lfo_designer_nested_token_ok:
        move.l  112(%sp),%d1
        bsr.w   gk_lfo_designer_token_validate
        move.l  68(%sp),%d5
        move.l  72(%sp),%d4
        move.l  116(%sp),%d6
        andi.l  #0x7f,%d6
        ori.l   #GK_LFO_PARAMETER_TOKEN_ARMED,%d6
        move.l  %d6,-(%sp)
        move.l  %d4,-(%sp)
        move.l  %d5,-(%sp)
        jsr     gk_stock_lfo_block_write_trampoline
        move.w  %sr,%d2
        move.w  %d2,72(%sp)
        move.l  %d0,12(%sp)
        move.l  %d1,16(%sp)
        move.l  %a0,44(%sp)
        move.l  %a1,48(%sp)
        lea     12(%sp),%sp
        move.l  116(%sp),%d0
        move.l  112(%sp),%d1
        bsr.w   gk_lfo_designer_token_validate
        move.l  116(%sp),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d0
        move.l  %d0,116(%sp)
        not.l   %d0
        move.l  %d0,112(%sp)
        move.w  60(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     64(%sp),%sp
        rts
        .size   gk_lfo_designer_nested_block_write,.-gk_lfo_designer_nested_block_write
        .global gk_lfo_designer_fatal_runtime_image
        .type gk_lfo_designer_fatal_runtime_image,@function
gk_lfo_designer_fatal_runtime_image:
        illegal
        bra.s gk_lfo_designer_fatal_runtime_image
        .size gk_lfo_designer_fatal_runtime_image,.-gk_lfo_designer_fatal_runtime_image
        .global gk_lfo_designer_fatal_entry_callback
        .type gk_lfo_designer_fatal_entry_callback,@function
gk_lfo_designer_fatal_entry_callback:
        illegal
        bra.s gk_lfo_designer_fatal_entry_callback
        .size gk_lfo_designer_fatal_entry_callback,.-gk_lfo_designer_fatal_entry_callback
        .global gk_lfo_designer_fatal_entry_id
        .type gk_lfo_designer_fatal_entry_id,@function
gk_lfo_designer_fatal_entry_id:
        illegal
        bra.s gk_lfo_designer_fatal_entry_id
        .size gk_lfo_designer_fatal_entry_id,.-gk_lfo_designer_fatal_entry_id
        .global gk_lfo_designer_fatal_entry_registry
        .type gk_lfo_designer_fatal_entry_registry,@function
gk_lfo_designer_fatal_entry_registry:
        illegal
        bra.s gk_lfo_designer_fatal_entry_registry
        .size gk_lfo_designer_fatal_entry_registry,.-gk_lfo_designer_fatal_entry_registry
        .global gk_lfo_designer_fatal_entry_delta
        .type gk_lfo_designer_fatal_entry_delta,@function
gk_lfo_designer_fatal_entry_delta:
        illegal
        bra.s gk_lfo_designer_fatal_entry_delta
        .size gk_lfo_designer_fatal_entry_delta,.-gk_lfo_designer_fatal_entry_delta
        .global gk_lfo_designer_fatal_renderer
        .type gk_lfo_designer_fatal_renderer,@function
gk_lfo_designer_fatal_renderer:
        illegal
        bra.s gk_lfo_designer_fatal_renderer
        .size gk_lfo_designer_fatal_renderer,.-gk_lfo_designer_fatal_renderer
        .global gk_lfo_designer_fatal_entry_lifecycle
        .type gk_lfo_designer_fatal_entry_lifecycle,@function
gk_lfo_designer_fatal_entry_lifecycle:
        illegal
        bra.s gk_lfo_designer_fatal_entry_lifecycle
        .size gk_lfo_designer_fatal_entry_lifecycle,.-gk_lfo_designer_fatal_entry_lifecycle
        .global gk_lfo_designer_fatal_finish_inverse
        .type gk_lfo_designer_fatal_finish_inverse,@function
gk_lfo_designer_fatal_finish_inverse:
        illegal
        bra.s gk_lfo_designer_fatal_finish_inverse
        .size gk_lfo_designer_fatal_finish_inverse,.-gk_lfo_designer_fatal_finish_inverse
        .global gk_lfo_designer_fatal_marker_return
        .type gk_lfo_designer_fatal_marker_return,@function
gk_lfo_designer_fatal_marker_return:
        illegal
        bra.s gk_lfo_designer_fatal_marker_return
        .size gk_lfo_designer_fatal_marker_return,.-gk_lfo_designer_fatal_marker_return
        .global gk_lfo_designer_fatal_marker_dirty
        .type gk_lfo_designer_fatal_marker_dirty,@function
gk_lfo_designer_fatal_marker_dirty:
        illegal
        bra.s gk_lfo_designer_fatal_marker_dirty
        .size gk_lfo_designer_fatal_marker_dirty,.-gk_lfo_designer_fatal_marker_dirty
        .global gk_lfo_designer_fatal_marker_token
        .type gk_lfo_designer_fatal_marker_token,@function
gk_lfo_designer_fatal_marker_token:
        illegal
        bra.s gk_lfo_designer_fatal_marker_token
        .size gk_lfo_designer_fatal_marker_token,.-gk_lfo_designer_fatal_marker_token
        .global gk_lfo_designer_fatal_nested_return
        .type gk_lfo_designer_fatal_nested_return,@function
gk_lfo_designer_fatal_nested_return:
        illegal
        bra.s gk_lfo_designer_fatal_nested_return
        .size gk_lfo_designer_fatal_nested_return,.-gk_lfo_designer_fatal_nested_return
        .global gk_lfo_designer_fatal_nested_target
        .type gk_lfo_designer_fatal_nested_target,@function
gk_lfo_designer_fatal_nested_target:
        illegal
        bra.s gk_lfo_designer_fatal_nested_target
        .size gk_lfo_designer_fatal_nested_target,.-gk_lfo_designer_fatal_nested_target
        .global gk_lfo_designer_fatal_nested_offset
        .type gk_lfo_designer_fatal_nested_offset,@function
gk_lfo_designer_fatal_nested_offset:
        illegal
        bra.s gk_lfo_designer_fatal_nested_offset
        .size gk_lfo_designer_fatal_nested_offset,.-gk_lfo_designer_fatal_nested_offset
        .global gk_lfo_designer_fatal_nested_selection
        .type gk_lfo_designer_fatal_nested_selection,@function
gk_lfo_designer_fatal_nested_selection:
        illegal
        bra.s gk_lfo_designer_fatal_nested_selection
        .size gk_lfo_designer_fatal_nested_selection,.-gk_lfo_designer_fatal_nested_selection
        .global gk_lfo_designer_fatal_nested_id
        .type gk_lfo_designer_fatal_nested_id,@function
gk_lfo_designer_fatal_nested_id:
        illegal
        bra.s gk_lfo_designer_fatal_nested_id
        .size gk_lfo_designer_fatal_nested_id,.-gk_lfo_designer_fatal_nested_id
        .global gk_lfo_designer_fatal_nested_anchor
        .type gk_lfo_designer_fatal_nested_anchor,@function
gk_lfo_designer_fatal_nested_anchor:
        illegal
        bra.s gk_lfo_designer_fatal_nested_anchor
        .size gk_lfo_designer_fatal_nested_anchor,.-gk_lfo_designer_fatal_nested_anchor
        .global gk_lfo_designer_fatal_nested_value
        .type gk_lfo_designer_fatal_nested_value,@function
gk_lfo_designer_fatal_nested_value:
        illegal
        bra.s gk_lfo_designer_fatal_nested_value
        .size gk_lfo_designer_fatal_nested_value,.-gk_lfo_designer_fatal_nested_value
        .global gk_lfo_designer_fatal_nested_token
        .type gk_lfo_designer_fatal_nested_token,@function
gk_lfo_designer_fatal_nested_token:
        illegal
        bra.s gk_lfo_designer_fatal_nested_token
        .size gk_lfo_designer_fatal_nested_token,.-gk_lfo_designer_fatal_nested_token
        .global gk_lfo_designer_fatal_token_inverse
        .type gk_lfo_designer_fatal_token_inverse,@function
gk_lfo_designer_fatal_token_inverse:
        illegal
        bra.s gk_lfo_designer_fatal_token_inverse
        .size gk_lfo_designer_fatal_token_inverse,.-gk_lfo_designer_fatal_token_inverse
        .global gk_lfo_designer_fatal_token_state
        .type gk_lfo_designer_fatal_token_state,@function
gk_lfo_designer_fatal_token_state:
        illegal
        bra.s gk_lfo_designer_fatal_token_state
        .size gk_lfo_designer_fatal_token_state,.-gk_lfo_designer_fatal_token_state
        .global gk_lfo_designer_fatal_token_lifecycle
        .type gk_lfo_designer_fatal_token_lifecycle,@function
gk_lfo_designer_fatal_token_lifecycle:
        illegal
        bra.s gk_lfo_designer_fatal_token_lifecycle
        .size gk_lfo_designer_fatal_token_lifecycle,.-gk_lfo_designer_fatal_token_lifecycle
        .global gk_lfo_designer_fatal_token_transition
        .type gk_lfo_designer_fatal_token_transition,@function
gk_lfo_designer_fatal_token_transition:
        illegal
        bra.s gk_lfo_designer_fatal_token_transition
        .size gk_lfo_designer_fatal_token_transition,.-gk_lfo_designer_fatal_token_transition
        .global gk_lfo_designer_fatal_token_pending
        .type gk_lfo_designer_fatal_token_pending,@function
gk_lfo_designer_fatal_token_pending:
        illegal
        bra.s gk_lfo_designer_fatal_token_pending
        .size gk_lfo_designer_fatal_token_pending,.-gk_lfo_designer_fatal_token_pending
        .global gk_lfo_designer_fatal_token_descriptor
        .type gk_lfo_designer_fatal_token_descriptor,@function
gk_lfo_designer_fatal_token_descriptor:
        illegal
        bra.s gk_lfo_designer_fatal_token_descriptor
        .size gk_lfo_designer_fatal_token_descriptor,.-gk_lfo_designer_fatal_token_descriptor
        .global gk_lfo_designer_fatal_token_track
        .type gk_lfo_designer_fatal_token_track,@function
gk_lfo_designer_fatal_token_track:
        illegal
        bra.s gk_lfo_designer_fatal_token_track
        .size gk_lfo_designer_fatal_token_track,.-gk_lfo_designer_fatal_token_track
        .global gk_lfo_designer_fatal_token_part
        .type gk_lfo_designer_fatal_token_part,@function
gk_lfo_designer_fatal_token_part:
        illegal
        bra.s gk_lfo_designer_fatal_token_part
        .size gk_lfo_designer_fatal_token_part,.-gk_lfo_designer_fatal_token_part
        .global gk_lfo_designer_fatal_token_bank
        .type gk_lfo_designer_fatal_token_bank,@function
gk_lfo_designer_fatal_token_bank:
        illegal
        bra.s gk_lfo_designer_fatal_token_bank
        .size gk_lfo_designer_fatal_token_bank,.-gk_lfo_designer_fatal_token_bank
        .global gk_lfo_designer_fatal_token_bank_pointer
        .type gk_lfo_designer_fatal_token_bank_pointer,@function
gk_lfo_designer_fatal_token_bank_pointer:
        illegal
        bra.s gk_lfo_designer_fatal_token_bank_pointer
        .size gk_lfo_designer_fatal_token_bank_pointer,.-gk_lfo_designer_fatal_token_bank_pointer
        .global gk_lfo_designer_fatal_token_pattern
        .type gk_lfo_designer_fatal_token_pattern,@function
gk_lfo_designer_fatal_token_pattern:
        illegal
        bra.s gk_lfo_designer_fatal_token_pattern
        .size gk_lfo_designer_fatal_token_pattern,.-gk_lfo_designer_fatal_token_pattern
        .global gk_lfo_designer_fatal_token_assignment
        .type gk_lfo_designer_fatal_token_assignment,@function
gk_lfo_designer_fatal_token_assignment:
        illegal
        bra.s gk_lfo_designer_fatal_token_assignment
        .size gk_lfo_designer_fatal_token_assignment,.-gk_lfo_designer_fatal_token_assignment
        .global gk_lfo_designer_fatal_token_kit
        .type gk_lfo_designer_fatal_token_kit,@function
gk_lfo_designer_fatal_token_kit:
        illegal
        bra.s gk_lfo_designer_fatal_token_kit
        .size gk_lfo_designer_fatal_token_kit,.-gk_lfo_designer_fatal_token_kit
        .global gk_lfo_designer_fatal_token_bound
        .type gk_lfo_designer_fatal_token_bound,@function
gk_lfo_designer_fatal_token_bound:
        illegal
        bra.s gk_lfo_designer_fatal_token_bound
        .size gk_lfo_designer_fatal_token_bound,.-gk_lfo_designer_fatal_token_bound
        .global gk_lfo_designer_fatal_token_reader
        .type gk_lfo_designer_fatal_token_reader,@function
gk_lfo_designer_fatal_token_reader:
        illegal
        bra.s gk_lfo_designer_fatal_token_reader
        .size gk_lfo_designer_fatal_token_reader,.-gk_lfo_designer_fatal_token_reader
        .global gk_lfo_designer_fatal_token_physical
        .type gk_lfo_designer_fatal_token_physical,@function
gk_lfo_designer_fatal_token_physical:
        illegal
        bra.s gk_lfo_designer_fatal_token_physical
        .size gk_lfo_designer_fatal_token_physical,.-gk_lfo_designer_fatal_token_physical
