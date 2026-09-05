        .include "abi.inc"
        .equ    GK_MCP_RELEASE_MODE,1
        .set    GK_MCP_ABORT_FATAL,gk_mcp_abort_fatal
        .set    GK_MCP_RELEASE_ABORT_FATAL,gk_mcp_release_abort_fatal
        .set    GK_MCP_RELEASE_ABORT_D0_FATAL,gk_mcp_release_abort_fatal_d0
        .set    GK_MCP_RELEASE_FATAL,gk_mcp_release_fatal
        .set    GK_MCP_FRAME_STATE_FATAL,gk_mcp_frame_state_fatal
        .set    GK_MCP_COMMIT_STATE_FATAL,gk_mcp_commit_state_fatal
        .equ    GK_MCP_STOCK_HANDLER,0x4000e79c
        .equ    GK_MCP_STOCK_DIRTY_HELPER,0x40027e00
        .equ    GK_MCP_STOCK_DERIVED_REFRESH,0x40002df4
        .equ    GK_MCP_DIRTY_RETURN_PAIR0,0x4000eb34
        .equ    GK_MCP_DIRTY_RETURN_PAIR1,0x4000ec38
        .equ    GK_MCP_DIRTY_RETURN_SCENE_A,0x4000ef04
        .equ    GK_MCP_DIRTY_RETURN_SCENE_B,0x4000ef66
        .equ    GK_MCP_DIRTY_RETURN_BOOL0,0x4000f046
        .equ    GK_MCP_DIRTY_RETURN_BOOL1,0x4000f0e6
        .equ    GK_MCP_DERIVED_RETURN,0x4000ef7e
        .equ    GK_MCP_FRAME_SIZE,200
        .equ    GK_MCP_MAGIC,0x4d435046
        .equ    GK_MCP_TOKEN_ARMED,0x4d410000
        .equ    GK_MCP_TOKEN_WRITTEN,0x4d570000
        .equ    GK_MCP_TOKEN_COMMITTED,0x4d430000
        .equ    GK_MCP_TOKEN_STATE_MASK,0xffff0000
        .equ    GK_MCP_TOKEN_CONTEXT_MASK,0x0000ffff
        .equ    GK_MCP_WORKING_EDITED,0x100b145e
        .equ    GK_MCP_BANK_WORKING_EDITED_OFFSET,0x00095048
        .equ    GK_MCP_INPUT_D0,0
        .equ    GK_MCP_INPUT_A0,32
        .equ    GK_MCP_INPUT_A6,56
        .equ    GK_MCP_INPUT_SR,60
        .equ    GK_MCP_FRAME_MAGIC,64
        .equ    GK_MCP_FRAME_MAGIC_INVERSE,68
        .equ    GK_MCP_BANK,72
        .equ    GK_MCP_PATTERN,76
        .equ    GK_MCP_PART,80
        .equ    GK_MCP_DESCRIPTOR,84
        .equ    GK_MCP_PAYLOAD,88
        .equ    GK_MCP_EVENT,92
        .equ    GK_MCP_ARGUMENT2,96
        .equ    GK_MCP_SELECTOR,100
        .equ    GK_MCP_OUTPUT_D0,104
        .equ    GK_MCP_OUTPUT_A0,136
        .equ    GK_MCP_OUTPUT_SR,164
        .equ    GK_MCP_TOKEN,168
        .equ    GK_MCP_TOKEN_INVERSE,172
        .equ    GK_MCP_BASELINE_ROUTE,176
        .equ    GK_MCP_BASELINE_RESIDENT_EDITED,184
        .equ    GK_MCP_BASELINE_MIRROR_EDITED,188
        .equ    GK_MCP_BASELINE_BANK_DIRTY,192
        .equ    GK_MCP_BASELINE_PROJECT_DIRTY,196
        .equ    GK_MCP_MARKER_SCRATCH,64
        .equ    GK_MCP_MARKER_SR,60
        .equ    GK_MCP_MARKER_KIND,64
        .equ    GK_MCP_MARKER_RETURN,68
        .section .runtime,"ax"
        .align  4
        .type   gk_mcp_abort_fatal,@function
gk_mcp_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_mcp_fatal
        bra.w   gk_mcp_fatal
        .size   gk_mcp_abort_fatal,.-gk_mcp_abort_fatal
        .type   gk_mcp_release_abort_fatal_d0,@function
gk_mcp_release_abort_fatal_d0:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_mcp_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_mcp_fatal
        bra.w   gk_mcp_abort_fatal
        .size   gk_mcp_release_abort_fatal_d0,.-gk_mcp_release_abort_fatal_d0
        .type   gk_mcp_release_abort_fatal,@function
gk_mcp_release_abort_fatal:
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        beq.w   gk_mcp_fatal
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        bra.w   gk_mcp_release_abort_fatal_d0
        .size   gk_mcp_release_abort_fatal,.-gk_mcp_release_abort_fatal
        .type   gk_mcp_release_fatal,@function
gk_mcp_release_fatal:
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_mcp_fatal
        jsr     gk_descriptor_release
        bra.w   gk_mcp_fatal
        .size   gk_mcp_release_fatal,.-gk_mcp_release_fatal
        .type   gk_mcp_frame_state_fatal,@function
gk_mcp_frame_state_fatal:
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   gk_mcp_release_abort_fatal
        bra.w   gk_mcp_release_fatal
        .size   gk_mcp_frame_state_fatal,.-gk_mcp_frame_state_fatal
        .type   gk_mcp_commit_state_fatal,@function
gk_mcp_commit_state_fatal:
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   gk_mcp_release_abort_fatal
        bra.w   gk_mcp_release_fatal
        .size   gk_mcp_commit_state_fatal,.-gk_mcp_commit_state_fatal
        .type   gk_mcp_selector_route,@function
gk_mcp_selector_route:
        cmpi.l  #0x07,%d0
        beq.s   .Lgk_mcp_route_0
        cmpi.l  #0x2e,%d0
        beq.s   .Lgk_mcp_route_1
        cmpi.l  #0x2f,%d0
        beq.s   .Lgk_mcp_route_2
        cmpi.l  #0x37,%d0
        beq.s   .Lgk_mcp_route_3
        cmpi.l  #0x38,%d0
        beq.s   .Lgk_mcp_route_4
        cmpi.l  #0x39,%d0
        beq.s   .Lgk_mcp_route_5
        cmpi.l  #0x3a,%d0
        beq.s   .Lgk_mcp_route_6
        moveq   #-1,%d0
        rts
.Lgk_mcp_route_0:
        moveq   #0,%d0
        rts
.Lgk_mcp_route_1:
        moveq   #1,%d0
        rts
.Lgk_mcp_route_2:
        moveq   #2,%d0
        rts
.Lgk_mcp_route_3:
        moveq   #3,%d0
        rts
.Lgk_mcp_route_4:
        moveq   #4,%d0
        rts
.Lgk_mcp_route_5:
        moveq   #5,%d0
        rts
.Lgk_mcp_route_6:
        moveq   #6,%d0
        rts
        .size   gk_mcp_selector_route,.-gk_mcp_selector_route
        .type   gk_mcp_frame_token,@function
gk_mcp_frame_token:
        move.l  GK_MCP_DESCRIPTOR(%a6),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_mcp_frame_token_corrupt
        move.l  GK_MCP_PART(%a6),%d1
        cmpi.l  #3,%d1
        bhi.w   .Lgk_mcp_frame_token_corrupt
        lsl.l   #7,%d1
        or.l    %d1,%d0
        move.l  GK_MCP_BANK(%a6),%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_mcp_frame_token_corrupt
        lsl.l   #8,%d1
        lsl.l   #1,%d1
        or.l    %d1,%d0
        move.l  GK_MCP_SELECTOR(%a6),%d1
        move.l  %d1,%d2
        move.l  %d2,%d0
        bsr.w   gk_mcp_selector_route
        tst.l   %d0
        bmi.w   .Lgk_mcp_frame_token_corrupt
        lsl.l   #8,%d0
        lsl.l   #5,%d0
        move.l  %d0,%d2
        move.l  GK_MCP_DESCRIPTOR(%a6),%d0
        move.l  GK_MCP_PART(%a6),%d1
        lsl.l   #7,%d1
        or.l    %d1,%d0
        move.l  GK_MCP_BANK(%a6),%d1
        lsl.l   #8,%d1
        lsl.l   #1,%d1
        or.l    %d1,%d0
        or.l    %d2,%d0
        ori.l   #GK_MCP_TOKEN_ARMED,%d0
        rts
.Lgk_mcp_frame_token_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_mcp_frame_token,.-gk_mcp_frame_token
        .type   gk_mcp_validate_frame,@function
gk_mcp_validate_frame:
        move.l  GK_MCP_FRAME_MAGIC(%a6),%d0
        cmpi.l  #GK_MCP_MAGIC,%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        not.l   %d0
        cmp.l   GK_MCP_FRAME_MAGIC_INVERSE(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        move.l  GK_MCP_TOKEN(%a6),%d0
        not.l   %d0
        cmp.l   GK_MCP_TOKEN_INVERSE(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        bsr.w   gk_mcp_frame_token
        tst.l   %d0
        bmi.w   .Lgk_mcp_validate_frame_corrupt
        andi.l  #GK_MCP_TOKEN_CONTEXT_MASK,%d0
        move.l  GK_MCP_TOKEN(%a6),%d1
        andi.l  #GK_MCP_TOKEN_CONTEXT_MASK,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_PRIMARY,%d0
        cmp.l   GK_MCP_BANK(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d0
        cmp.l   GK_MCP_BANK(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_BANK,%d0
        cmp.l   GK_MCP_BANK(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN,%d0
        cmp.l   GK_MCP_PATTERN(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PATTERN_PRIMARY,%d0
        cmp.l   GK_MCP_PATTERN(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmp.l   GK_MCP_PART(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d0
        cmp.l   GK_MCP_PART(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  GK_STOCK_ENGINE_PART,%d0
        cmp.l   GK_MCP_PART(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  __gk_current_bank,%d0
        cmp.l   GK_MCP_BANK(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  __gk_current_pattern,%d0
        cmp.l   GK_MCP_PATTERN(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   GK_MCP_DESCRIPTOR(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        move.l  GK_MCP_BANK(%a6),%d0
        move.l  #GK_STOCK_BANK_STRIDE,%d1
        muls.l  %d1,%d0
        lea     GK_STOCK_RESIDENT_BANK_BASE,%a0
        adda.l  %d0,%a0
        cmpa.l  GK_STOCK_BANK_POINTER,%a0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        move.l  GK_MCP_PATTERN(%a6),%d0
        mulu.w  #GK_STOCK_PATTERN_STRIDE,%d0
        .incbin "stock/0292.bin", 0, 6
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a0
        moveq   #0,%d1
        move.b  (%a0),%d1
        cmp.l   GK_MCP_PART(%a6),%d1
        bne.w   .Lgk_mcp_validate_frame_corrupt
        lea     GK_STOCK_PATTERN_MIRROR_BASE,%a0
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_PATTERN_PART_OFFSET,%a0
        moveq   #0,%d1
        move.b  (%a0),%d1
        cmp.l   GK_MCP_PART(%a6),%d1
        bne.w   .Lgk_mcp_validate_frame_corrupt
        move.l  GK_MCP_BANK(%a6),%d0
        lsl.l   #4,%d0
        add.l   GK_MCP_PATTERN(%a6),%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   %d0,%d1
        bne.w   .Lgk_mcp_validate_frame_corrupt
        movea.l GK_MCP_EVENT(%a6),%a0
        moveq   #0,%d0
        move.b  1(%a0),%d0
        cmp.l   GK_MCP_SELECTOR(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        move.l  GK_MCP_BANK(%a6),%d0
        lsl.l   #2,%d0
        add.l   GK_MCP_PART(%a6),%d0
        jsr     gk_physical_validate
        tst.l   %d0
        bmi.w   .Lgk_mcp_validate_frame_corrupt
        cmp.l   GK_MCP_DESCRIPTOR(%a6),%d0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        cmpa.l  GK_MCP_PAYLOAD(%a6),%a0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        move.l  GK_MCP_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        .incbin "stock/0293.bin", 0, 6
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        adda.l  %d0,%a0
        cmpa.l  GK_MCP_PAYLOAD(%a6),%a0
        bne.w   .Lgk_mcp_validate_frame_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_mcp_validate_frame_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_mcp_validate_frame,.-gk_mcp_validate_frame
        .type   gk_mcp_validate_settled,@function
gk_mcp_validate_settled:
        bsr.w   gk_mcp_validate_frame
        tst.l   %d0
        bmi.w   .Lgk_mcp_validate_settled_corrupt
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   .Lgk_mcp_validate_settled_corrupt
        cmp.l   GK_MCP_BANK(%a6),%d0
        bne.w   .Lgk_mcp_validate_settled_corrupt
        cmp.l   GK_MCP_PATTERN(%a6),%d1
        bne.w   .Lgk_mcp_validate_settled_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_mcp_validate_settled_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_mcp_validate_settled,.-gk_mcp_validate_settled
        .type   gk_mcp_capture_baseline,@function
gk_mcp_capture_baseline:
        moveq   #0,%d0
        move.l  %d0,GK_MCP_BASELINE_ROUTE(%a6)
        move.l  %d0,GK_MCP_BASELINE_ROUTE + 4(%a6)
        movea.l GK_MCP_PAYLOAD(%a6),%a0
        lea     GK_MCP_BASELINE_ROUTE(%a6),%a1
        move.l  GK_MCP_SELECTOR(%a6),%d0
        cmpi.l  #0x07,%d0
        beq.s   .Lgk_mcp_capture_pair0
        cmpi.l  #0x2e,%d0
        beq.s   .Lgk_mcp_capture_pair0
        cmpi.l  #0x2f,%d0
        beq.s   .Lgk_mcp_capture_pair1
        cmpi.l  #0x37,%d0
        beq.s   .Lgk_mcp_capture_scene_a
        cmpi.l  #0x38,%d0
        beq.s   .Lgk_mcp_capture_scene_b
        cmpi.l  #0x39,%d0
        beq.s   .Lgk_mcp_capture_bool0
        cmpi.l  #0x3a,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        adda.l  #0x60d,%a0
        moveq   #12,%d1
        bra.s   .Lgk_mcp_capture_eight
.Lgk_mcp_capture_pair0:
        adda.l  #0x12,%a0
        moveq   #2,%d1
        bra.s   .Lgk_mcp_capture_eight
.Lgk_mcp_capture_pair1:
        adda.l  #0x13,%a0
        moveq   #2,%d1
        bra.s   .Lgk_mcp_capture_eight
.Lgk_mcp_capture_scene_a:
        move.b  0x10(%a0),(%a1)
        bra.s   .Lgk_mcp_capture_dirty
.Lgk_mcp_capture_scene_b:
        move.b  0x11(%a0),(%a1)
        bra.s   .Lgk_mcp_capture_dirty
.Lgk_mcp_capture_bool0:
        adda.l  #0x60a,%a0
        moveq   #12,%d1
.Lgk_mcp_capture_eight:
        moveq   #8,%d0
.Lgk_mcp_capture_next:
        move.b  (%a0),(%a1)+
        adda.l  %d1,%a0
        subq.l  #1,%d0
        bne.s   .Lgk_mcp_capture_next
.Lgk_mcp_capture_dirty:
        .incbin "stock/0294.bin", 0, 6
        adda.l  #GK_MCP_BANK_WORKING_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        move.l  %d0,GK_MCP_BASELINE_RESIDENT_EDITED(%a6)
        moveq   #0,%d0
        move.b  GK_MCP_WORKING_EDITED,%d0
        move.l  %d0,GK_MCP_BASELINE_MIRROR_EDITED(%a6)
        .incbin "stock/0295.bin", 0, 6
        move.l  #GK_STOCK_BANK_DIRTY_OFFSET,%d0
        move.l  (%a0,%d0.l),%d0
        move.l  %d0,GK_MCP_BASELINE_BANK_DIRTY(%a6)
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        move.l  %d0,GK_MCP_BASELINE_PROJECT_DIRTY(%a6)
        rts
        .size   gk_mcp_capture_baseline,.-gk_mcp_capture_baseline
        .type   gk_mcp_validate_no_write,@function
gk_mcp_validate_no_write:
        bsr.w   gk_mcp_validate_frame
        tst.l   %d0
        bmi.w   .Lgk_mcp_no_write_corrupt
        movea.l GK_MCP_PAYLOAD(%a6),%a0
        lea     GK_MCP_BASELINE_ROUTE(%a6),%a1
        move.l  GK_MCP_SELECTOR(%a6),%d0
        cmpi.l  #0x07,%d0
        beq.s   .Lgk_mcp_no_write_pair0
        cmpi.l  #0x2e,%d0
        beq.s   .Lgk_mcp_no_write_pair0
        cmpi.l  #0x2f,%d0
        beq.s   .Lgk_mcp_no_write_pair1
        cmpi.l  #0x37,%d0
        beq.s   .Lgk_mcp_no_write_scene_a
        cmpi.l  #0x38,%d0
        beq.s   .Lgk_mcp_no_write_scene_b
        cmpi.l  #0x39,%d0
        beq.s   .Lgk_mcp_no_write_bool0
        cmpi.l  #0x3a,%d0
        bne.w   .Lgk_mcp_no_write_corrupt
        adda.l  #0x60d,%a0
        moveq   #12,%d1
        bra.s   .Lgk_mcp_no_write_eight
.Lgk_mcp_no_write_pair0:
        adda.l  #0x12,%a0
        moveq   #2,%d1
        bra.s   .Lgk_mcp_no_write_eight
.Lgk_mcp_no_write_pair1:
        adda.l  #0x13,%a0
        moveq   #2,%d1
        bra.s   .Lgk_mcp_no_write_eight
.Lgk_mcp_no_write_scene_a:
        move.b  0x10(%a0),%d0
        cmp.b   (%a1),%d0
        bne.w   .Lgk_mcp_no_write_corrupt
        bra.s   .Lgk_mcp_no_write_dirty
.Lgk_mcp_no_write_scene_b:
        move.b  0x11(%a0),%d0
        cmp.b   (%a1),%d0
        bne.w   .Lgk_mcp_no_write_corrupt
        bra.s   .Lgk_mcp_no_write_dirty
.Lgk_mcp_no_write_bool0:
        adda.l  #0x60a,%a0
        moveq   #12,%d1
.Lgk_mcp_no_write_eight:
        moveq   #8,%d0
.Lgk_mcp_no_write_next:
        move.b  (%a0),%d2
        cmp.b   (%a1)+,%d2
        bne.w   .Lgk_mcp_no_write_corrupt
        adda.l  %d1,%a0
        subq.l  #1,%d0
        bne.s   .Lgk_mcp_no_write_next
.Lgk_mcp_no_write_dirty:
        .incbin "stock/0296.bin", 0, 6
        adda.l  #GK_MCP_BANK_WORKING_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        cmp.l   GK_MCP_BASELINE_RESIDENT_EDITED(%a6),%d0
        bne.s   .Lgk_mcp_no_write_corrupt
        moveq   #0,%d0
        move.b  GK_MCP_WORKING_EDITED,%d0
        cmp.l   GK_MCP_BASELINE_MIRROR_EDITED(%a6),%d0
        bne.s   .Lgk_mcp_no_write_corrupt
        .incbin "stock/0297.bin", 0, 6
        move.l  #GK_STOCK_BANK_DIRTY_OFFSET,%d0
        move.l  (%a0,%d0.l),%d0
        cmp.l   GK_MCP_BASELINE_BANK_DIRTY(%a6),%d0
        bne.s   .Lgk_mcp_no_write_corrupt
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmp.l   GK_MCP_BASELINE_PROJECT_DIRTY(%a6),%d0
        bne.s   .Lgk_mcp_no_write_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_mcp_no_write_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_mcp_validate_no_write,.-gk_mcp_validate_no_write
        .type   gk_mcp_validate_publication,@function
gk_mcp_validate_publication:
        bsr.w   gk_mcp_validate_frame
        tst.l   %d0
        bmi.w   .Lgk_mcp_validate_publication_corrupt
        movea.l GK_MCP_PAYLOAD(%a6),%a0
        move.l  GK_MCP_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a1
        adda.l  %d0,%a1
        move.l  GK_MCP_SELECTOR(%a6),%d0
        cmpi.l  #0x07,%d0
        beq.s   .Lgk_mcp_publication_pair0
        cmpi.l  #0x2e,%d0
        beq.s   .Lgk_mcp_publication_pair0
        cmpi.l  #0x2f,%d0
        beq.s   .Lgk_mcp_publication_pair1
        cmpi.l  #0x37,%d0
        beq.s   .Lgk_mcp_publication_scene_a
        cmpi.l  #0x38,%d0
        beq.s   .Lgk_mcp_publication_scene_b
        cmpi.l  #0x39,%d0
        beq.s   .Lgk_mcp_publication_bool0
        cmpi.l  #0x3a,%d0
        bne.w   .Lgk_mcp_validate_publication_corrupt
        adda.l  #0x60d,%a0
        adda.l  #0x60d,%a1
        moveq   #12,%d1
        bra.s   .Lgk_mcp_publication_eight
.Lgk_mcp_publication_pair0:
        adda.l  #0x12,%a0
        adda.l  #0x12,%a1
        moveq   #2,%d1
        bra.s   .Lgk_mcp_publication_eight
.Lgk_mcp_publication_pair1:
        adda.l  #0x13,%a0
        adda.l  #0x13,%a1
        moveq   #2,%d1
        bra.s   .Lgk_mcp_publication_eight
.Lgk_mcp_publication_scene_a:
        adda.l  #0x10,%a0
        adda.l  #0x10,%a1
        moveq   #1,%d0
        moveq   #1,%d1
        bra.s   .Lgk_mcp_compare_route
.Lgk_mcp_publication_scene_b:
        adda.l  #0x11,%a0
        adda.l  #0x11,%a1
        moveq   #1,%d0
        moveq   #1,%d1
        bra.s   .Lgk_mcp_compare_route
.Lgk_mcp_publication_bool0:
        adda.l  #0x60a,%a0
        adda.l  #0x60a,%a1
        moveq   #12,%d1
.Lgk_mcp_publication_eight:
        moveq   #8,%d0
.Lgk_mcp_compare_route:
        move.b  (%a0),%d2
        cmp.b   (%a1),%d2
        bne.w   .Lgk_mcp_validate_publication_corrupt
        adda.l  %d1,%a0
        adda.l  %d1,%a1
        subq.l  #1,%d0
        bne.s   .Lgk_mcp_compare_route
        moveq   #1,%d1
        move.l  GK_MCP_PART(%a6),%d0
        lsl.l   %d0,%d1
        .incbin "stock/0298.bin", 0, 6
        adda.l  #GK_MCP_BANK_WORKING_EDITED_OFFSET,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        and.l   %d1,%d0
        beq.w   .Lgk_mcp_validate_publication_corrupt
        moveq   #0,%d0
        move.b  GK_MCP_WORKING_EDITED,%d0
        and.l   %d1,%d0
        beq.w   .Lgk_mcp_validate_publication_corrupt
        .incbin "stock/0299.bin", 0, 6
        move.l  #GK_STOCK_BANK_DIRTY_OFFSET,%d0
        move.l  (%a0,%d0.l),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_mcp_validate_publication_corrupt
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_mcp_validate_publication_corrupt
        moveq   #GK_OK,%d0
        rts
.Lgk_mcp_validate_publication_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_mcp_validate_publication,.-gk_mcp_validate_publication
        .type   gk_mcp_authenticate_handler_frame,@function
gk_mcp_authenticate_handler_frame:
        lea     24(%a5),%a6
        move.l  (%a5),%d0
        cmp.l   GK_MCP_INPUT_A6(%a6),%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        move.l  4(%a5),%d0
        cmpi.l  #gk_mcp_stock_return,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        move.l  8(%a5),%d0
        cmp.l   GK_MCP_EVENT(%a6),%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        move.l  12(%a5),%d0
        cmp.l   GK_MCP_ARGUMENT2(%a6),%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        bsr.w   gk_mcp_validate_frame
        tst.l   %d0
        bmi.w   GK_MCP_RELEASE_ABORT_FATAL
        bsr.w   gk_mcp_frame_token
        move.l  16(%a5),%d1
        cmp.l   %d1,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        not.l   %d0
        move.l  20(%a5),%d1
        cmp.l   %d1,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        rts
        .size   gk_mcp_authenticate_handler_frame,.-gk_mcp_authenticate_handler_frame
        .type   gk_mcp_commit_written,@function
gk_mcp_commit_written:
        bsr.w   gk_mcp_validate_publication
        tst.l   %d0
        bmi.w   GK_MCP_RELEASE_ABORT_FATAL
        move.l  GK_MCP_DESCRIPTOR(%a6),%d0
        move.l  GK_MCP_BANK(%a6),%d1
        move.l  GK_MCP_PATTERN(%a6),%d2
        move.l  GK_MCP_PART(%a6),%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        jsr     gk_workspace_commit_update
        tst.l   %d0
        bne.w   GK_MCP_COMMIT_STATE_FATAL
        bsr.w   gk_mcp_validate_settled
        tst.l   %d0
        bmi.w   GK_MCP_RELEASE_FATAL
        rts
        .size   gk_mcp_commit_written,.-gk_mcp_commit_written
        .global gk_stock_midi_control_parameter
        .type   gk_stock_midi_control_parameter,@function
gk_stock_midi_control_parameter:
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0,(%sp)
        move.w  %sr,%d0
        move.w  %d0,12(%sp)
        movea.l 20(%sp),%a0
        moveq   #0,%d0
        move.b  1(%a0),%d0
        bsr.w   gk_mcp_selector_route
        tst.l   %d0
        bmi.s   .Lgk_mcp_passthrough_restore
        move.w  12(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d1/%a0
        lea     16(%sp),%sp
        bra.s   .Lgk_mcp_writer
.Lgk_mcp_passthrough_restore:
        move.w  12(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d1/%a0
        lea     16(%sp),%sp
        .byte 0x4e,0xf9
        .incbin "stock/0300.bin", 0, 4
.Lgk_mcp_writer:
        move.l  %d0,-(%sp)
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_mcp_lifecycle_active_restore
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_mcp_busy_early_restore
        bra.w   gk_mcp_fatal
.Lgk_mcp_lifecycle_active_restore:
        move.l  (%sp)+,%d0
        lea     -GK_MCP_FRAME_SIZE(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.w  %sr,%d0
        move.w  %d0,GK_MCP_INPUT_SR(%sp)
        move.l  #GK_MCP_MAGIC,%d0
        move.l  %d0,GK_MCP_FRAME_MAGIC(%sp)
        not.l   %d0
        move.l  %d0,GK_MCP_FRAME_MAGIC_INVERSE(%sp)
        move.l  GK_MCP_FRAME_SIZE + 4(%sp),%d0
        move.l  %d0,GK_MCP_EVENT(%sp)
        move.l  GK_MCP_FRAME_SIZE + 8(%sp),%d0
        move.l  %d0,GK_MCP_ARGUMENT2(%sp)
        movea.l GK_MCP_EVENT(%sp),%a0
        moveq   #0,%d0
        move.b  1(%a0),%d0
        move.l  %d0,GK_MCP_SELECTOR(%sp)
        bsr.w   gk_mcp_selector_route
        tst.l   %d0
        bmi.w   gk_mcp_fatal
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_mcp_fatal
        move.l  %d0,GK_MCP_PART(%sp)
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   gk_mcp_fatal
        jsr     gk_stock_current_context_validate
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_mcp_busy_saved
        tst.l   %d0
        bmi.w   gk_mcp_fatal
        move.l  %d0,GK_MCP_BANK(%sp)
        move.l  %d1,GK_MCP_PATTERN(%sp)
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_mcp_fatal
        move.l  %d6,GK_MCP_DESCRIPTOR(%sp)
        move.l  GK_MCP_BANK(%sp),%d0
        move.l  GK_MCP_PATTERN(%sp),%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_mcp_busy_saved
        tst.l   %d0
        bmi.w   gk_mcp_fatal
        cmp.l   %d6,%d0
        bne.w   GK_MCP_ABORT_FATAL
        move.l  GK_MCP_PART(%sp),%d2
        cmp.l   %d2,%d1
        bne.w   GK_MCP_ABORT_FATAL
        move.l  %a0,GK_MCP_PAYLOAD(%sp)
        move.l  GK_MCP_BANK(%sp),%d0
        move.l  GK_MCP_PART(%sp),%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   GK_MCP_ABORT_FATAL
        cmp.l   %d6,%d0
        bne.w   GK_MCP_RELEASE_ABORT_D0_FATAL
        cmpa.l  GK_MCP_PAYLOAD(%sp),%a0
        bne.w   GK_MCP_RELEASE_ABORT_D0_FATAL
        movea.l %sp,%a6
        bsr.w   gk_mcp_capture_baseline
        bsr.w   gk_mcp_frame_token
        tst.l   %d0
        bmi.w   GK_MCP_RELEASE_ABORT_FATAL
        move.l  %d0,GK_MCP_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_MCP_TOKEN_INVERSE(%a6)
        move.l  GK_MCP_TOKEN_INVERSE(%a6),-(%sp)
        move.l  GK_MCP_TOKEN(%a6),-(%sp)
        move.l  GK_MCP_ARGUMENT2(%a6),-(%sp)
        move.l  GK_MCP_EVENT(%a6),-(%sp)
        move.w  GK_MCP_INPUT_SR(%a6),%d0
        move.w  %d0,%sr
        movem.l (%a6),%d0-%d7/%a0-%a6
        .byte 0x4e,0xb9
        .incbin "stock/0301.bin", 0, 4
        .global gk_mcp_stock_return
gk_mcp_stock_return:
        movem.l %d0-%d7/%a0-%a6,120(%sp)
        move.w  %sr,%d0
        move.w  %d0,180(%sp)
        lea     16(%sp),%sp
        movea.l %sp,%a6
        bsr.w   gk_mcp_validate_frame
        tst.l   %d0
        bmi.w   GK_MCP_FRAME_STATE_FATAL
        bsr.w   gk_mcp_frame_token
        move.l  %d0,%d1
        move.l  GK_MCP_TOKEN(%a6),%d0
        cmp.l   %d1,%d0
        beq.w   .Lgk_mcp_finish_no_write
        andi.l  #GK_MCP_TOKEN_CONTEXT_MASK,%d1
        move.l  %d1,%d2
        ori.l   #GK_MCP_TOKEN_WRITTEN,%d1
        cmp.l   %d1,%d0
        beq.s   .Lgk_mcp_finish_written
        ori.l   #GK_MCP_TOKEN_COMMITTED,%d2
        cmp.l   %d2,%d0
        bne.w   GK_MCP_FRAME_STATE_FATAL
        move.l  GK_MCP_SELECTOR(%a6),%d0
        cmpi.l  #0x37,%d0
        beq.s   .Lgk_mcp_finish_release
        cmpi.l  #0x38,%d0
        bne.w   GK_MCP_RELEASE_FATAL
        bra.s   .Lgk_mcp_finish_release
.Lgk_mcp_finish_written:
        move.l  GK_MCP_SELECTOR(%a6),%d0
        cmpi.l  #0x37,%d0
        beq.w   GK_MCP_RELEASE_ABORT_FATAL
        cmpi.l  #0x38,%d0
        beq.w   GK_MCP_RELEASE_ABORT_FATAL
        bsr.w   gk_mcp_commit_written
        move.l  GK_MCP_TOKEN(%a6),%d0
        andi.l  #GK_MCP_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_MCP_TOKEN_COMMITTED,%d0
        move.l  %d0,GK_MCP_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_MCP_TOKEN_INVERSE(%a6)
.Lgk_mcp_finish_release:
        bsr.w   gk_mcp_validate_publication
        tst.l   %d0
        bmi.w   GK_MCP_RELEASE_FATAL
        bsr.w   gk_mcp_validate_settled
        tst.l   %d0
        bmi.w   GK_MCP_RELEASE_FATAL
        move.l  GK_MCP_DESCRIPTOR(%a6),%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_mcp_fatal
        bra.s   .Lgk_mcp_restore_outputs
.Lgk_mcp_finish_no_write:
        bsr.w   gk_mcp_validate_no_write
        tst.l   %d0
        bmi.w   GK_MCP_RELEASE_ABORT_FATAL
        move.l  GK_MCP_DESCRIPTOR(%a6),%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_mcp_fatal
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_mcp_fatal
        bsr.w   gk_mcp_validate_settled
        tst.l   %d0
        bmi.w   gk_mcp_fatal
.Lgk_mcp_restore_outputs:
        move.l  GK_MCP_OUTPUT_D0(%a6),%d1
        move.w  GK_MCP_OUTPUT_SR(%a6),%d0
        lea     GK_MCP_FRAME_SIZE(%a6),%sp
        move.l  %d1,-(%sp)
        move.w  %d0,-(%sp)
        movem.l GK_MCP_OUTPUT_D0(%a6),%d0-%d7/%a0-%a6
        move.w  (%sp),%d0
        move.w  %d0,%sr
        movem.l 2(%sp),%d0
        lea     6(%sp),%sp
        rts
.Lgk_mcp_busy_saved:
        move.w  GK_MCP_INPUT_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     GK_MCP_FRAME_SIZE(%sp),%sp
        rts
.Lgk_mcp_busy_early_restore:
        move.l  (%sp)+,%d0
        rts
        .size   gk_stock_midi_control_parameter,.-gk_stock_midi_control_parameter
        .type   gk_mcp_dirty_marker_common,@function
gk_mcp_dirty_marker_common:
        lea     -GK_MCP_MARKER_SCRATCH(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.w  %sr,%d0
        move.w  %d0,GK_MCP_MARKER_SR(%sp)
        movea.l %a6,%a5
        bsr.w   gk_mcp_authenticate_handler_frame
        move.l  GK_MCP_SELECTOR(%a6),%d0
        move.l  GK_MCP_MARKER_RETURN(%sp),%d1
        cmpi.l  #0x07,%d0
        beq.s   .Lgk_mcp_expect_pair0
        cmpi.l  #0x2e,%d0
        beq.s   .Lgk_mcp_expect_pair0
        cmpi.l  #0x2f,%d0
        beq.s   .Lgk_mcp_expect_pair1
        cmpi.l  #0x37,%d0
        beq.s   .Lgk_mcp_expect_scene_a
        cmpi.l  #0x38,%d0
        beq.s   .Lgk_mcp_expect_scene_b
        cmpi.l  #0x39,%d0
        beq.s   .Lgk_mcp_expect_bool0
        cmpi.l  #0x3a,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        cmpi.l  #GK_MCP_DIRTY_RETURN_BOOL1,%d1
        bra.s   .Lgk_mcp_dirty_return_checked
.Lgk_mcp_expect_pair0:
        cmpi.l  #GK_MCP_DIRTY_RETURN_PAIR0,%d1
        bra.s   .Lgk_mcp_dirty_return_checked
.Lgk_mcp_expect_pair1:
        cmpi.l  #GK_MCP_DIRTY_RETURN_PAIR1,%d1
        bra.s   .Lgk_mcp_dirty_return_checked
.Lgk_mcp_expect_scene_a:
        cmpi.l  #GK_MCP_DIRTY_RETURN_SCENE_A,%d1
        bra.s   .Lgk_mcp_dirty_return_checked
.Lgk_mcp_expect_scene_b:
        cmpi.l  #GK_MCP_DIRTY_RETURN_SCENE_B,%d1
        bra.s   .Lgk_mcp_dirty_return_checked
.Lgk_mcp_expect_bool0:
        cmpi.l  #GK_MCP_DIRTY_RETURN_BOOL0,%d1
.Lgk_mcp_dirty_return_checked:
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        bsr.w   gk_mcp_validate_publication
        tst.l   %d0
        bmi.w   GK_MCP_RELEASE_ABORT_FATAL
        bsr.w   gk_mcp_frame_token
        move.l  %d0,%d1
        move.l  GK_MCP_TOKEN(%a6),%d0
        cmp.l   %d1,%d0
        beq.s   .Lgk_mcp_mark_written
        andi.l  #GK_MCP_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_MCP_TOKEN_WRITTEN,%d1
        cmp.l   %d1,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        bra.s   .Lgk_mcp_marker_restore_select
.Lgk_mcp_mark_written:
        andi.l  #GK_MCP_TOKEN_CONTEXT_MASK,%d1
        ori.l   #GK_MCP_TOKEN_WRITTEN,%d1
        move.l  %d1,GK_MCP_TOKEN(%a6)
        not.l   %d1
        move.l  %d1,GK_MCP_TOKEN_INVERSE(%a6)
.Lgk_mcp_marker_restore_select:
        move.l  GK_MCP_MARKER_KIND(%sp),%d0
        cmpi.l  #3,%d0
        beq.s   .Lgk_mcp_marker_restore_a3
        cmpi.l  #5,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        move.w  GK_MCP_MARKER_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     GK_MCP_MARKER_RETURN(%sp),%sp
        .incbin "stock/0302.bin", 0, 6
        jmp     (%a5)
.Lgk_mcp_marker_restore_a3:
        move.w  GK_MCP_MARKER_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     GK_MCP_MARKER_RETURN(%sp),%sp
        .incbin "stock/0303.bin", 0, 6
        jmp     (%a3)
        .size   gk_mcp_dirty_marker_common,.-gk_mcp_dirty_marker_common
        .global gk_mcp_dirty_marker_a3
        .type   gk_mcp_dirty_marker_a3,@function
gk_mcp_dirty_marker_a3:
        pea     3
        bra.w   gk_mcp_dirty_marker_common
        .size   gk_mcp_dirty_marker_a3,.-gk_mcp_dirty_marker_a3
        .global gk_mcp_dirty_marker_a5
        .type   gk_mcp_dirty_marker_a5,@function
gk_mcp_dirty_marker_a5:
        pea     5
        bra.w   gk_mcp_dirty_marker_common
        .size   gk_mcp_dirty_marker_a5,.-gk_mcp_dirty_marker_a5
        .global gk_mcp_pre_derived_refresh
        .type   gk_mcp_pre_derived_refresh,@function
gk_mcp_pre_derived_refresh:
        lea     -GK_MCP_MARKER_SCRATCH(%sp),%sp
        movem.l %d0-%d7/%a0-%a6,(%sp)
        move.w  %sr,%d0
        move.w  %d0,GK_MCP_MARKER_SR(%sp)
        movea.l %a6,%a5
        bsr.w   gk_mcp_authenticate_handler_frame
        move.l  GK_MCP_MARKER_KIND(%sp),%d0
        cmpi.l  #GK_MCP_DERIVED_RETURN,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        move.l  GK_MCP_SELECTOR(%a6),%d0
        cmpi.l  #0x37,%d0
        beq.s   .Lgk_mcp_pre_derived_selector_ok
        cmpi.l  #0x38,%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
.Lgk_mcp_pre_derived_selector_ok:
        bsr.w   gk_mcp_frame_token
        andi.l  #GK_MCP_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_MCP_TOKEN_WRITTEN,%d0
        cmp.l   GK_MCP_TOKEN(%a6),%d0
        bne.w   GK_MCP_RELEASE_ABORT_FATAL
        bsr.w   gk_mcp_commit_written
        move.l  GK_MCP_TOKEN(%a6),%d0
        andi.l  #GK_MCP_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_MCP_TOKEN_COMMITTED,%d0
        move.l  %d0,GK_MCP_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_MCP_TOKEN_INVERSE(%a6)
        move.w  GK_MCP_MARKER_SR(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d7/%a0-%a6
        lea     GK_MCP_MARKER_SCRATCH(%sp),%sp
        .incbin "stock/0304.bin", 0, 6
        jmp     (%a4)
        .size   gk_mcp_pre_derived_refresh,.-gk_mcp_pre_derived_refresh
        .global gk_mcp_fatal
        .type   gk_mcp_fatal,@function
gk_mcp_fatal:
        illegal
        bra.s   gk_mcp_fatal
        .size   gk_mcp_fatal,.-gk_mcp_fatal
