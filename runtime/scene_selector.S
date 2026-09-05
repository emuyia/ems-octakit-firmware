        .include "abi.inc"
        .equ    GK_SCENE_SELECTOR_RELEASE_MODE,1
        .set    GK_SS_ACQUIRE_MISMATCH_FATAL,gk_scene_selector_release_abort_fatal_d0
        .set    GK_SS_PENDING_RELEASE_ABORT_FATAL,gk_scene_selector_release_abort_fatal
        .set    GK_SS_FRAME_PENDING_FATAL,gk_scene_selector_release_abort_fatal
        .set    GK_SS_COMMIT_STATE_FATAL,gk_scene_selector_commit_state_fatal
        .set    GK_SS_FRAME_RELEASE_FATAL,gk_scene_selector_release_fatal
        .equ    GK_SCENE_SELECTOR_CONTINUE,0x4005294c
        .equ    GK_SCENE_SELECTOR_REFRESH_CONTINUE,0x400529ba
        .equ    GK_SCENE_SELECTOR_TAIL_CONTINUE,0x400529d6
        .equ    GK_SCENE_SELECTOR_FRAME_SIZE,128
        .equ    GK_SCENE_SELECTOR_FAKE_RETURN,0x53534658
        .equ    GK_SCENE_SELECTOR_TOKEN_ARMED,0x53530000
        .equ    GK_SCENE_SELECTOR_TOKEN_COMMITTED,0x53430000
        .equ    GK_SCENE_SELECTOR_TOKEN_STATE_MASK,0xffff0000
        .equ    GK_SCENE_SELECTOR_WORKING_EDITED,0x100b145e
        .equ    GK_SS_SAVED_D2,0
        .equ    GK_SS_SAVED_D3,4
        .equ    GK_SS_SAVED_D4,8
        .equ    GK_SS_SAVED_A6,40
        .equ    GK_SS_INPUT_D0,44
        .equ    GK_SS_INPUT_D1,48
        .equ    GK_SS_INPUT_A0,52
        .equ    GK_SS_INPUT_A1,56
        .equ    GK_SS_INPUT_SR,60
        .equ    GK_SS_BANK,64
        .equ    GK_SS_PATTERN,68
        .equ    GK_SS_PART,72
        .equ    GK_SS_DESCRIPTOR,76
        .equ    GK_SS_OUTPUT_D0,80
        .equ    GK_SS_OUTPUT_D1,84
        .equ    GK_SS_OUTPUT_D2,88
        .equ    GK_SS_OUTPUT_D3,92
        .equ    GK_SS_OUTPUT_A0,96
        .equ    GK_SS_OUTPUT_A1,100
        .equ    GK_SS_OUTPUT_SR,104
        .equ    GK_SS_SCENE,108
        .equ    GK_SS_TOKEN,112
        .equ    GK_SS_TOKEN_INVERSE,116
        .equ    GK_SS_PAYLOAD,120
        .section .runtime,"ax"
        .align  4
        .type   gk_scene_selector_abort_fatal,@function
gk_scene_selector_abort_fatal:
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_scene_selector_fatal
        bra.w   gk_scene_selector_fatal
        .size   gk_scene_selector_abort_fatal,.-gk_scene_selector_abort_fatal
        .type   gk_scene_selector_release_abort_fatal_d0,@function
gk_scene_selector_release_abort_fatal_d0:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_scene_selector_fatal
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_selector_fatal
        bra.w   gk_scene_selector_abort_fatal
        .size   gk_scene_selector_release_abort_fatal_d0,.-gk_scene_selector_release_abort_fatal_d0
        .type   gk_scene_selector_release_abort_fatal,@function
gk_scene_selector_release_abort_fatal:
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        beq.w   gk_scene_selector_fatal
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        bra.w   gk_scene_selector_release_abort_fatal_d0
        .size   gk_scene_selector_release_abort_fatal,.-gk_scene_selector_release_abort_fatal
        .type   gk_scene_selector_release_fatal,@function
gk_scene_selector_release_fatal:
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   gk_scene_selector_fatal
        jsr     gk_descriptor_release
        bra.w   gk_scene_selector_fatal
        .size   gk_scene_selector_release_fatal,.-gk_scene_selector_release_fatal
        .type   gk_scene_selector_commit_state_fatal,@function
gk_scene_selector_commit_state_fatal:
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   gk_scene_selector_release_abort_fatal
        bra.w   gk_scene_selector_release_fatal
        .size   gk_scene_selector_commit_state_fatal,.-gk_scene_selector_commit_state_fatal
        .type   gk_scene_selector_frame_token,@function
gk_scene_selector_frame_token:
        move.l  GK_SS_DESCRIPTOR(%a6),%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_scene_selector_frame_token_corrupt
        move.l  GK_SS_PART(%a6),%d1
        cmpi.l  #3,%d1
        bhi.s   .Lgk_scene_selector_frame_token_corrupt
        lsl.l   #8,%d1
        lsl.l   #2,%d1
        or.l    %d1,%d0
        move.l  GK_SS_BANK(%a6),%d1
        cmpi.l  #15,%d1
        bhi.s   .Lgk_scene_selector_frame_token_corrupt
        lsl.l   #8,%d1
        lsl.l   #4,%d1
        or.l    %d1,%d0
        ori.l   #GK_SCENE_SELECTOR_TOKEN_ARMED,%d0
        rts
.Lgk_scene_selector_frame_token_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_scene_selector_frame_token,.-gk_scene_selector_frame_token
        .global gk_stock_scene_selector
        .type   gk_stock_scene_selector,@function
gk_stock_scene_selector:
        tst.l   __gk_lifecycle_state
        bne.w   gk_scene_selector_fatal
        lea     -GK_SCENE_SELECTOR_FRAME_SIZE(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l  %d0,GK_SS_INPUT_D0(%sp)
        move.l  %d1,GK_SS_INPUT_D1(%sp)
        move.l  %a0,GK_SS_INPUT_A0(%sp)
        move.l  %a1,GK_SS_INPUT_A1(%sp)
        move.w  %sr,%d0
        move.w  %d0,GK_SS_INPUT_SR(%sp)
        move.l  GK_SCENE_SELECTOR_FRAME_SIZE + 4(%sp),%d0
        cmpi.l  #15,%d0
        bhi.w   gk_scene_selector_fatal
        move.l  %d0,GK_SS_SCENE(%sp)
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d0
        cmpi.l  #3,%d0
        bhi.w   gk_scene_selector_fatal
        move.l  %d0,GK_SS_PART(%sp)
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.w   gk_scene_selector_fatal
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   gk_scene_selector_fatal
        move.l  %d0,GK_SS_BANK(%sp)
        move.l  %d1,GK_SS_PATTERN(%sp)
        moveq   #0,%d6
        move.b  __gk_workspace_descriptor,%d6
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d6
        bhi.w   gk_scene_selector_fatal
        move.l  %d6,GK_SS_DESCRIPTOR(%sp)
        move.l  GK_SS_BANK(%sp),%d0
        move.l  GK_SS_PATTERN(%sp),%d1
        moveq   #0,%d2
        move.b  __gk_current_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   gk_scene_selector_fatal
        cmp.l   %d6,%d0
        bne.w   gk_scene_selector_abort_fatal
        move.l  GK_SS_PART(%sp),%d2
        cmp.l   %d2,%d1
        bne.w   gk_scene_selector_abort_fatal
        move.l  %a0,GK_SS_PAYLOAD(%sp)
        move.l  GK_SS_BANK(%sp),%d0
        move.l  GK_SS_PART(%sp),%d1
        jsr     gk_physical_acquire
        tst.l   %d0
        bmi.w   gk_scene_selector_abort_fatal
        cmp.l   %d6,%d0
        bne.w   GK_SS_ACQUIRE_MISMATCH_FATAL
        movea.l GK_SS_PAYLOAD(%sp),%a1
        cmpa.l  %a1,%a0
        bne.w   GK_SS_ACQUIRE_MISMATCH_FATAL
        move.l  GK_SS_PART(%sp),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        .incbin "stock/0305.bin", 0, 6
        adda.l  %d0,%a0
        adda.l  #GK_STOCK_BANK_WORKING_OFFSET,%a0
        cmpa.l  %a1,%a0
        bne.w   GK_SS_PENDING_RELEASE_ABORT_FATAL
        movea.l %sp,%a6
        bsr.w   gk_scene_selector_frame_token
        tst.l   %d0
        bmi.w   GK_SS_FRAME_PENDING_FATAL
        move.l  %d0,GK_SS_TOKEN(%sp)
        not.l   %d0
        move.l  %d0,GK_SS_TOKEN_INVERSE(%sp)
        move.l  GK_SS_SCENE(%sp),-(%sp)
        move.l  #GK_SCENE_SELECTOR_FAKE_RETURN,-(%sp)
        movem.l 8(%sp),%d2-%d7/%a2-%a6
        move.l  GK_SS_INPUT_D0 + 8(%sp),%d0
        move.l  GK_SS_INPUT_D1 + 8(%sp),%d1
        movea.l GK_SS_INPUT_A0 + 8(%sp),%a0
        movea.l GK_SS_INPUT_A1 + 8(%sp),%a1
        move.w  GK_SS_INPUT_SR + 8(%sp),%d0
        move.w  %d0,%sr
        move.l  GK_SS_INPUT_D0 + 8(%sp),%d0
        jmp     gk_stock_scene_selector_trampoline
        .size   gk_stock_scene_selector,.-gk_stock_scene_selector
        .global gk_stock_scene_selector_trampoline
        .type   gk_stock_scene_selector_trampoline,@function
gk_stock_scene_selector_trampoline:
        .incbin "stock/0306.bin", 0, 2
        .incbin "stock/0306.bin", 2, 2
        .incbin "stock/0306.bin", 4, 4
        jmp     GK_SCENE_SELECTOR_CONTINUE
        .size   gk_stock_scene_selector_trampoline,.-gk_stock_scene_selector_trampoline
        .type   gk_scene_selector_validate_stock_publication,@function
gk_scene_selector_validate_stock_publication:
        move.l  GK_SS_BANK(%a6),%d0
        lsl.l   #2,%d0
        add.l   GK_SS_PART(%a6),%d0
        jsr     gk_physical_validate
        tst.l   %d0
        bmi.w   .Lgk_scene_selector_publication_invalid
        cmp.l   GK_SS_DESCRIPTOR(%a6),%d0
        bne.w   .Lgk_scene_selector_publication_invalid
        cmpa.l  GK_SS_PAYLOAD(%a6),%a0
        bne.w   .Lgk_scene_selector_publication_invalid
        movea.l GK_SS_PAYLOAD(%a6),%a0
        moveq   #0,%d0
        move.b  0x11(%a0),%d0
        cmp.l   GK_SS_SCENE(%a6),%d0
        bne.w   .Lgk_scene_selector_publication_invalid
        move.l  GK_SS_PART(%a6),%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a0
        adda.l  %d0,%a0
        moveq   #0,%d0
        move.b  0x11(%a0),%d0
        cmp.l   GK_SS_SCENE(%a6),%d0
        bne.w   .Lgk_scene_selector_publication_invalid
        moveq   #1,%d1
        move.l  GK_SS_PART(%a6),%d0
        lsl.l   %d0,%d1
        .incbin "stock/0307.bin", 0, 6
        adda.l  #0x95048,%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        and.l   %d1,%d0
        beq.w   .Lgk_scene_selector_publication_invalid
        moveq   #0,%d0
        move.b  GK_SCENE_SELECTOR_WORKING_EDITED,%d0
        and.l   %d1,%d0
        beq.w   .Lgk_scene_selector_publication_invalid
        .incbin "stock/0308.bin", 0, 6
        move.l  #0x9b332,%d0
        move.l  (%a0,%d0.l),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_scene_selector_publication_invalid
        move.l  GK_STOCK_CURRENT_BANK_DIRTY,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_scene_selector_publication_invalid
        moveq   #GK_OK,%d0
        rts
.Lgk_scene_selector_publication_invalid:
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_scene_selector_validate_stock_publication,.-gk_scene_selector_validate_stock_publication
        .global gk_stock_scene_selector_pre_refresh
        .type   gk_stock_scene_selector_pre_refresh,@function
gk_stock_scene_selector_pre_refresh:
        lea     -28(%sp),%sp
        movem.l %d0-%d3/%a0-%a1,(%sp)
        move.w  %sr,%d0
        move.w  %d0,24(%sp)
        lea     44(%sp),%a6
        bsr.w   gk_scene_selector_frame_token
        tst.l   %d0
        bmi.w   GK_SS_FRAME_PENDING_FATAL
        cmp.l   GK_SS_TOKEN(%a6),%d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        not.l   %d0
        cmp.l   GK_SS_TOKEN_INVERSE(%a6),%d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        move.l  36(%sp),%d0
        cmpi.l  #GK_SCENE_SELECTOR_FAKE_RETURN,%d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        move.l  GK_SS_SCENE(%a6),%d0
        cmp.l   40(%sp),%d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        cmp.l   12(%sp),%d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        move.l  GK_SS_SAVED_D2(%a6),%d0
        cmp.l   28(%sp),%d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        move.l  GK_SS_SAVED_D3(%a6),%d0
        cmp.l   32(%sp),%d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        bsr.w   gk_scene_selector_validate_stock_publication
        tst.l   %d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        move.l  GK_SS_DESCRIPTOR(%a6),%d0
        move.l  GK_SS_BANK(%a6),%d1
        move.l  GK_SS_PATTERN(%a6),%d2
        move.l  GK_SS_PART(%a6),%d3
        jsr     gk_workspace_mark_dirty_pending
        tst.l   %d0
        bne.w   GK_SS_FRAME_PENDING_FATAL
        jsr     gk_workspace_commit_update
        .global gk_scene_selector_post_commit_check
gk_scene_selector_post_commit_check:
        tst.l   %d0
        bne.w   GK_SS_COMMIT_STATE_FATAL
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   GK_SS_FRAME_RELEASE_FATAL
        cmp.l   GK_SS_BANK(%a6),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        cmp.l   GK_SS_PATTERN(%a6),%d1
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   GK_SS_DESCRIPTOR(%a6),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  GK_SS_TOKEN(%a6),%d0
        andi.l  #0x0000ffff,%d0
        ori.l   #GK_SCENE_SELECTOR_TOKEN_COMMITTED,%d0
        move.l  %d0,GK_SS_TOKEN(%a6)
        not.l   %d0
        move.l  %d0,GK_SS_TOKEN_INVERSE(%a6)
        move.w  24(%sp),%d0
        move.w  %d0,%sr
        movem.l (%sp),%d0-%d3/%a0-%a1
        lea     28(%sp),%sp
        movea.l GK_SS_SAVED_A6(%a6),%a6
        .incbin "stock/0309.bin", 0, 4
        .incbin "stock/0309.bin", 4, 2
        jmp     GK_SCENE_SELECTOR_REFRESH_CONTINUE
        .size   gk_stock_scene_selector_pre_refresh,.-gk_stock_scene_selector_pre_refresh
        .type   gk_scene_selector_release_committed,@function
gk_scene_selector_release_committed:
        bsr.w   gk_scene_selector_frame_token
        tst.l   %d0
        bmi.w   GK_SS_FRAME_RELEASE_FATAL
        andi.l  #0x0000ffff,%d0
        ori.l   #GK_SCENE_SELECTOR_TOKEN_COMMITTED,%d0
        cmp.l   GK_SS_TOKEN(%a6),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        not.l   %d0
        cmp.l   GK_SS_TOKEN_INVERSE(%a6),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        bsr.w   gk_scene_selector_validate_stock_publication
        tst.l   %d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        jsr     gk_stock_current_context_validate
        tst.l   %d0
        bmi.w   GK_SS_FRAME_RELEASE_FATAL
        cmp.l   GK_SS_BANK(%a6),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        cmp.l   GK_SS_PATTERN(%a6),%d1
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   GK_SS_DESCRIPTOR(%a6),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  GK_SS_DESCRIPTOR(%a6),%d0
        jsr     gk_descriptor_release
        tst.l   %d0
        bne.w   gk_scene_selector_fatal
        rts
        .size   gk_scene_selector_release_committed,.-gk_scene_selector_release_committed
        .global gk_stock_scene_selector_finish
        .type   gk_stock_scene_selector_finish,@function
gk_stock_scene_selector_finish:
        lea     32(%sp),%a6
        movem.l %d0-%d3/%a0-%a1,GK_SS_OUTPUT_D0(%a6)
        move.w  %sr,%d0
        move.w  %d0,GK_SS_OUTPUT_SR(%a6)
        move.l  24(%sp),%d0
        cmpi.l  #GK_SCENE_SELECTOR_FAKE_RETURN,%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  GK_SS_SCENE(%a6),%d0
        cmp.l   8(%sp),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        cmp.l   28(%sp),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        cmp.l   GK_SS_OUTPUT_D3(%a6),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  GK_SS_BANK(%a6),%d0
        cmp.l   (%sp),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  GK_SS_PART(%a6),%d0
        cmp.l   4(%sp),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  12(%sp),%d0
        cmpi.l  #1,%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  GK_SS_SAVED_D2(%a6),%d0
        cmp.l   16(%sp),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  GK_SS_SAVED_D3(%a6),%d0
        cmp.l   20(%sp),%d0
        bne.w   GK_SS_FRAME_RELEASE_FATAL
        move.l  %a6,%sp
        bsr.w   gk_scene_selector_release_committed
        move.w  GK_SS_OUTPUT_SR(%a6),%d4
        lea     GK_SCENE_SELECTOR_FRAME_SIZE(%a6),%sp
        move.l  GK_SS_SAVED_D3(%a6),-(%sp)
        move.l  GK_SS_SAVED_D2(%a6),-(%sp)
        move.l  #1,-(%sp)
        move.l  GK_SS_SCENE(%a6),-(%sp)
        move.l  GK_SS_PART(%a6),-(%sp)
        move.l  GK_SS_BANK(%a6),-(%sp)
        movem.l GK_SS_OUTPUT_D0(%a6),%d0-%d3/%a0-%a1
        move.w  %d4,%sr
        movem.l GK_SS_SAVED_D4(%a6),%d4-%d7/%a2-%a6
        .incbin "stock/0310.bin", 0, 2
        .incbin "stock/0310.bin", 2, 4
        jmp     GK_SCENE_SELECTOR_TAIL_CONTINUE
        .size   gk_stock_scene_selector_finish,.-gk_stock_scene_selector_finish
        .global gk_scene_selector_fatal
        .type   gk_scene_selector_fatal,@function
gk_scene_selector_fatal:
        illegal
        bra.s   gk_scene_selector_fatal
        .size   gk_scene_selector_fatal,.-gk_scene_selector_fatal
