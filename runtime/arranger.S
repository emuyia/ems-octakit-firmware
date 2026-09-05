        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_arranger_state_claim
        .type   gk_arranger_state_claim,@function
gk_arranger_state_claim:
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d0
        beq.s   .Lgk_arranger_claim_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d0
        bne.w   .Lgk_arranger_claim_range
.Lgk_arranger_claim_owner_ok:
        cmpi.l  #15,%d1
        bhi.w   .Lgk_arranger_claim_range
        cmpi.l  #15,%d2
        bhi.w   .Lgk_arranger_claim_range
        cmpi.l  #0xff,%d3
        bhi.w   .Lgk_arranger_claim_range
        tst.l   %d4
        beq.w   .Lgk_arranger_claim_range
        cmpi.l  #3,%d4
        bhi.w   .Lgk_arranger_claim_range
        btst    #0,%d4
        beq.s   .Lgk_arranger_claim_scene_b
        cmpi.l  #15,%d5
        bhi.w   .Lgk_arranger_claim_range
.Lgk_arranger_claim_scene_b:
        btst    #1,%d4
        beq.s   .Lgk_arranger_claim_arguments_ok
        cmpi.l  #15,%d6
        bhi.w   .Lgk_arranger_claim_range
.Lgk_arranger_claim_arguments_ok:
        lea     -32(%sp),%sp
        movem.l %d2-%d7/%a2,(%sp)
        move.w  %sr,%d7
        move.w  %d7,28(%sp)
        move.w  #0x2700,%sr
        moveq   #0,%d7
        move.b  __gk_arranger_kind,%d7
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d7
        bhi.w   .Lgk_arranger_claim_corrupt
        tst.l   %d7
        beq.s   .Lgk_arranger_claim_available
        cmpi.l  #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d7
        bne.w   .Lgk_arranger_claim_busy
        tst.b   __gk_arranger_token_active
        bne.w   .Lgk_arranger_claim_busy
.Lgk_arranger_claim_available:
        tst.b   __gk_arranger_token_active
        bne.w   .Lgk_arranger_claim_corrupt
        tst.b   __gk_arranger_token_epoch
        bne.w   .Lgk_arranger_claim_corrupt
        tst.l   __gk_arranger_token_generation
        bne.w   .Lgk_arranger_claim_corrupt
        tst.b   __gk_arranger_consume_source
        bne.w   .Lgk_arranger_claim_corrupt
        tst.b   __gk_arranger_consume_epoch
        bne.w   .Lgk_arranger_claim_corrupt
        tst.l   __gk_arranger_consume_generation
        bne.w   .Lgk_arranger_claim_corrupt
        move.l  __gk_arranger_generation,%d7
        tst.l   %d7
        bmi.w   .Lgk_arranger_claim_corrupt
        .global gk_arranger_state_invalidation
gk_arranger_state_invalidation:
        clr.b   __gk_arranger_kind
        cmpi.l  #0x7fffffff,%d7
        beq.s   .Lgk_arranger_claim_generation_wrap
        addq.l  #1,%d7
        bra.s   .Lgk_arranger_claim_generation_ready
.Lgk_arranger_claim_generation_wrap:
        moveq   #1,%d7
.Lgk_arranger_claim_generation_ready:
        move.l  %d7,__gk_arranger_generation
        move.b  %d7,__gk_arranger_epoch
        move.b  %d0,__gk_arranger_owner
        move.b  %d1,__gk_arranger_bank
        move.b  %d2,__gk_arranger_pattern
        move.b  %d3,__gk_arranger_kit
        move.b  %d4,__gk_arranger_scene_mask
        move.b  %d5,__gk_arranger_scene_a
        move.b  %d6,__gk_arranger_scene_b
        moveq   #-1,%d7
        move.b  %d7,__gk_arranger_descriptor
        clr.b   __gk_arranger_old_scene_a
        clr.b   __gk_arranger_old_scene_b
        clr.b   __gk_arranger_old_workspace_dirty
        move.b  %d7,__gk_arranger_old_descriptor_flags
        clr.b   __gk_arranger_token_active
        clr.b   __gk_arranger_token_epoch
        clr.b   __gk_arranger_consume_source
        clr.b   __gk_arranger_consume_epoch
        clr.w   __gk_arranger_reserved
        clr.l   __gk_arranger_token_generation
        clr.l   __gk_arranger_consume_generation
        moveq   #GK_ARRANGER_STATE_PREPARING,%d7
        .global gk_arranger_state_claim_publication
gk_arranger_state_claim_publication:
        move.b  %d7,__gk_arranger_kind
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_claim_restore
.Lgk_arranger_claim_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_claim_restore
.Lgk_arranger_claim_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_claim_restore:
        move.w  28(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d7/%a2
        lea     32(%sp),%sp
        rts
.Lgk_arranger_claim_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_state_claim,.-gk_arranger_state_claim
        .global gk_arranger_state_publish
        .type   gk_arranger_state_publish,@function
gk_arranger_state_publish:
        cmpi.l  #GK_ARRANGER_STATE_ARMED_DEFERRED,%d0
        beq.s   .Lgk_arranger_publish_value_ok
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d0
        bne.s   .Lgk_arranger_publish_range
.Lgk_arranger_publish_value_ok:
        move.l  %d2,-(%sp)
        move.w  %sr,%d2
        move.w  #0x2700,%sr
        moveq   #0,%d1
        move.b  __gk_arranger_kind,%d1
        cmpi.l  #GK_ARRANGER_STATE_PREPARING,%d1
        bne.s   .Lgk_arranger_publish_busy
        tst.b   __gk_arranger_token_active
        bne.s   .Lgk_arranger_publish_corrupt
        tst.b   __gk_arranger_token_epoch
        bne.s   .Lgk_arranger_publish_corrupt
        tst.l   __gk_arranger_token_generation
        bne.s   .Lgk_arranger_publish_corrupt
        tst.b   __gk_arranger_consume_source
        bne.s   .Lgk_arranger_publish_corrupt
        tst.b   __gk_arranger_consume_epoch
        bne.s   .Lgk_arranger_publish_corrupt
        tst.l   __gk_arranger_consume_generation
        bne.s   .Lgk_arranger_publish_corrupt
        tst.l   __gk_arranger_generation
        beq.s   .Lgk_arranger_publish_corrupt
        .global gk_arranger_state_ready_publication
gk_arranger_state_ready_publication:
        move.b  %d0,__gk_arranger_kind
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_publish_restore
.Lgk_arranger_publish_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_publish_restore
.Lgk_arranger_publish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_publish_restore:
        move.w  %d2,%sr
        move.l  (%sp)+,%d2
        rts
.Lgk_arranger_publish_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_state_publish,.-gk_arranger_state_publish
        .global gk_arranger_state_clear
        .type   gk_arranger_state_clear,@function
gk_arranger_state_clear:
        move.l  %d2,-(%sp)
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_arranger_kind,%d0
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d0
        bhi.s   .Lgk_arranger_clear_corrupt
        beq.s   .Lgk_arranger_clear_busy
        tst.b   __gk_arranger_token_active
        bne.s   .Lgk_arranger_clear_busy
        tst.b   __gk_arranger_token_epoch
        bne.s   .Lgk_arranger_clear_corrupt
        tst.l   __gk_arranger_token_generation
        bne.s   .Lgk_arranger_clear_corrupt
        tst.b   __gk_arranger_consume_source
        bne.s   .Lgk_arranger_clear_corrupt
        tst.b   __gk_arranger_consume_epoch
        bne.s   .Lgk_arranger_clear_corrupt
        tst.l   __gk_arranger_consume_generation
        bne.s   .Lgk_arranger_clear_corrupt
        .global gk_arranger_state_clear_publication
gk_arranger_state_clear_publication:
        clr.b   __gk_arranger_kind
        lea     __gk_arranger_owner,%a0
        moveq   #0,%d0
        moveq   #12,%d2
.Lgk_arranger_clear_prefix:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_clear_prefix
        addq.l  #1,%a0
        moveq   #(GK_ARRANGER_GENERATION - GK_ARRANGER_TOKEN_ACTIVE),%d2
.Lgk_arranger_clear_suffix:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_clear_suffix
        addq.l  #4,%a0
        moveq   #(GK_ARRANGER_STATE_SIZE - GK_ARRANGER_TOKEN_GENERATION),%d2
.Lgk_arranger_clear_token_generations:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_clear_token_generations
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_clear_restore
.Lgk_arranger_clear_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_arranger_clear_restore
.Lgk_arranger_clear_busy:
        moveq   #GK_ERR_BUSY,%d0
.Lgk_arranger_clear_restore:
        move.w  %d1,%sr
        move.l  (%sp)+,%d2
        rts
        .size   gk_arranger_state_clear,.-gk_arranger_state_clear
        .global gk_arranger_publisher_owner_from_return
        .type   gk_arranger_publisher_owner_from_return,@function
gk_arranger_publisher_owner_from_return:
        cmpi.l  #GK_STOCK_PATTERN_PUBLISH_ROW_RETURN,%d0
        beq.s   .Lgk_arranger_publisher_owner_row
        cmpi.l  #GK_STOCK_PATTERN_PUBLISH_PLAYBACK_RETURN,%d0
        beq.s   .Lgk_arranger_publisher_owner_playback
        cmpi.l  #GK_STOCK_PATTERN_PUBLISH_REPEAT_RETURN,%d0
        beq.s   .Lgk_arranger_publisher_owner_none
        cmpi.l  #GK_STOCK_PATTERN_PUBLISH_REQUEST_RETURN,%d0
        beq.s   .Lgk_arranger_publisher_owner_token
        bra.s   .Lgk_arranger_publisher_owner_invalid
.Lgk_arranger_publisher_owner_none:
        moveq   #GK_ARRANGER_OWNER_NONE,%d0
        rts
.Lgk_arranger_publisher_owner_row:
        moveq   #GK_ARRANGER_OWNER_ROW,%d0
        rts
.Lgk_arranger_publisher_owner_playback:
        moveq   #GK_ARRANGER_OWNER_PLAYBACK,%d0
        rts
.Lgk_arranger_publisher_owner_token:
        moveq   #GK_ARRANGER_OWNER_TOKEN,%d0
        rts
.Lgk_arranger_publisher_owner_invalid:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .size   gk_arranger_publisher_owner_from_return,.-gk_arranger_publisher_owner_from_return
        .global gk_arranger_guard_enter
        .type   gk_arranger_guard_enter,@function
gk_arranger_guard_enter:
        move.l  %d2,-(%sp)
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        tst.w   __gk_arranger_guard_reserved
        bne.w   .Lgk_arranger_guard_enter_corrupt
        tst.w   __gk_arranger_guard_saved_sr_pad
        bne.w   .Lgk_arranger_guard_enter_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_guard_depth,%d0
        cmpi.l  #GK_ARRANGER_GUARD_MAX_DEPTH,%d0
        bhi.w   .Lgk_arranger_guard_enter_corrupt
        tst.l   %d0
        bne.s   .Lgk_arranger_guard_enter_nested
        tst.b   __gk_arranger_playback_guard_active
        bne.w   .Lgk_arranger_guard_enter_corrupt
        tst.w   __gk_arranger_guard_saved_sr
        bne.w   .Lgk_arranger_guard_enter_corrupt
        move.w  %d1,__gk_arranger_guard_saved_sr
        moveq   #1,%d0
        .global gk_arranger_guard_first_publication
gk_arranger_guard_first_publication:
        move.b  %d0,__gk_arranger_guard_depth
        moveq   #0,%d2
        move.w  %d1,%d2
        move.l  %d2,%d0
        andi.l  #0x00000700,%d0
        cmpi.l  #0x00000200,%d0
        bcc.s   .Lgk_arranger_guard_enter_first_mask_ready
        andi.l  #0x0000f8ff,%d2
        ori.l   #0x00000200,%d2
.Lgk_arranger_guard_enter_first_mask_ready:
        move.w  %d2,%sr
        moveq   #GK_OK,%d0
        bra.w   .Lgk_arranger_guard_enter_restore
.Lgk_arranger_guard_enter_nested:
        cmpi.l  #GK_ARRANGER_GUARD_MAX_DEPTH,%d0
        beq.w   .Lgk_arranger_guard_enter_busy
        moveq   #0,%d2
        move.w  __gk_arranger_guard_saved_sr,%d2
        move.l  %d2,%d0
        andi.l  #0x00000700,%d0
        cmpi.l  #0x00000200,%d0
        bcc.s   .Lgk_arranger_guard_enter_expected_ready
        move.l  #0x00000200,%d0
.Lgk_arranger_guard_enter_expected_ready:
        moveq   #0,%d2
        move.w  %d1,%d2
        andi.l  #0x00000700,%d2
        cmp.l   %d0,%d2
        bne.w   .Lgk_arranger_guard_enter_busy
        moveq   #0,%d0
        move.b  __gk_arranger_guard_depth,%d0
        addq.l  #1,%d0
        .global gk_arranger_guard_nested_publication
gk_arranger_guard_nested_publication:
        move.b  %d0,__gk_arranger_guard_depth
        move.w  %d1,%sr
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_guard_enter_restore
.Lgk_arranger_guard_enter_busy:
        move.w  %d1,%sr
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_guard_enter_restore
.Lgk_arranger_guard_enter_corrupt:
        move.w  %d1,%sr
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_guard_enter_restore:
        move.l  (%sp)+,%d2
        rts
        .size   gk_arranger_guard_enter,.-gk_arranger_guard_enter
        .global gk_arranger_guard_exit
        .type   gk_arranger_guard_exit,@function
gk_arranger_guard_exit:
        move.l  %d2,-(%sp)
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        tst.w   __gk_arranger_guard_reserved
        bne.w   .Lgk_arranger_guard_exit_corrupt
        tst.w   __gk_arranger_guard_saved_sr_pad
        bne.w   .Lgk_arranger_guard_exit_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_guard_depth,%d0
        tst.l   %d0
        beq.w   .Lgk_arranger_guard_exit_corrupt
        cmpi.l  #GK_ARRANGER_GUARD_MAX_DEPTH,%d0
        bhi.w   .Lgk_arranger_guard_exit_corrupt
        subq.l  #1,%d0
        beq.s   .Lgk_arranger_guard_exit_final
        .global gk_arranger_guard_nested_release
gk_arranger_guard_nested_release:
        move.b  %d0,__gk_arranger_guard_depth
        move.w  %d1,%sr
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_guard_exit_restore
.Lgk_arranger_guard_exit_final:
        tst.b   __gk_arranger_playback_guard_active
        bne.w   .Lgk_arranger_guard_exit_corrupt
        moveq   #0,%d2
        move.w  __gk_arranger_guard_saved_sr,%d2
        .global gk_arranger_guard_final_invalidation
gk_arranger_guard_final_invalidation:
        clr.b   __gk_arranger_guard_depth
        clr.w   __gk_arranger_guard_saved_sr
        andi.l  #0x0000ff00,%d2
        moveq   #0,%d0
        move.w  %d1,%d0
        andi.l  #0x000000ff,%d0
        or.l    %d0,%d2
        move.w  %d2,%sr
        moveq   #GK_OK,%d0
        move.l  (%sp)+,%d2
        jsr     gk_pattern_queue_retry_event_ensure
        tst.l   %d0
        beq.s   .Lgk_arranger_guard_exit_final_return
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        bne.s   .Lgk_arranger_guard_exit_retry_corrupt
        jmp     gk_pattern_queue_retry_overflow_fatal
.Lgk_arranger_guard_exit_retry_corrupt:
        jmp     gk_pattern_queue_commit_defer_fatal
.Lgk_arranger_guard_exit_final_return:
        rts
.Lgk_arranger_guard_exit_corrupt:
        move.w  %d1,%sr
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_guard_exit_restore:
        move.l  (%sp)+,%d2
        rts
        .size   gk_arranger_guard_exit,.-gk_arranger_guard_exit
        .global gk_arranger_playback_guard_enter
        .type   gk_arranger_playback_guard_enter,@function
gk_arranger_playback_guard_enter:
        bsr.w   gk_arranger_guard_enter
        tst.l   %d0
        bne.s   .Lgk_arranger_playback_guard_enter_return
        move.l  %d2,-(%sp)
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_arranger_guard_depth,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_arranger_playback_guard_enter_fail
        tst.b   __gk_arranger_playback_guard_active
        bne.s   .Lgk_arranger_playback_guard_enter_fail
        tst.w   __gk_arranger_guard_reserved
        bne.s   .Lgk_arranger_playback_guard_enter_fail
        tst.w   __gk_arranger_guard_saved_sr_pad
        bne.s   .Lgk_arranger_playback_guard_enter_fail
        moveq   #1,%d0
        .global gk_arranger_playback_guard_publication
gk_arranger_playback_guard_publication:
        move.b  %d0,__gk_arranger_playback_guard_active
        move.w  %d1,%sr
        move.l  (%sp)+,%d2
        moveq   #GK_OK,%d0
.Lgk_arranger_playback_guard_enter_return:
        rts
.Lgk_arranger_playback_guard_enter_fail:
        move.w  %d1,%sr
        move.l  (%sp)+,%d2
        bsr.w   gk_arranger_guard_exit
        tst.l   %d0
        bne.w   gk_arranger_fatal_playback_guard_enter_cleanup
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_arranger_playback_guard_enter,.-gk_arranger_playback_guard_enter
        .global gk_arranger_playback_guard_exit
        .type   gk_arranger_playback_guard_exit,@function
gk_arranger_playback_guard_exit:
        move.l  %d2,-(%sp)
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  __gk_arranger_playback_guard_active,%d0
        tst.l   %d0
        beq.s   .Lgk_arranger_playback_guard_exit_none
        cmpi.l  #1,%d0
        bne.s   .Lgk_arranger_playback_guard_exit_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_guard_depth,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_arranger_playback_guard_exit_corrupt
        .global gk_arranger_playback_guard_invalidation
gk_arranger_playback_guard_invalidation:
        clr.b   __gk_arranger_playback_guard_active
        move.w  %d1,%sr
        move.l  (%sp)+,%d2
        bra.w   gk_arranger_guard_exit
.Lgk_arranger_playback_guard_exit_none:
        move.w  %d1,%sr
        move.l  (%sp)+,%d2
        moveq   #GK_ARRANGER_NOT_HANDLED,%d0
        rts
.Lgk_arranger_playback_guard_exit_corrupt:
        move.w  %d1,%sr
        move.l  (%sp)+,%d2
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_arranger_playback_guard_exit,.-gk_arranger_playback_guard_exit
        .global gk_arranger_consume_begin
        .type   gk_arranger_consume_begin,@function
gk_arranger_consume_begin:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_arranger_consume_begin_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_arranger_consume_begin_range
        cmpi.l  #0xff,%d2
        bhi.w   .Lgk_arranger_consume_begin_range
        cmpi.l  #GK_ARRANGER_CONSUME_ARMED_ONLY,%d3
        bhi.w   .Lgk_arranger_consume_begin_range
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d4
        beq.s   .Lgk_arranger_consume_begin_expected_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d4
        beq.s   .Lgk_arranger_consume_begin_expected_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_TOKEN,%d4
        bne.w   .Lgk_arranger_consume_begin_range
.Lgk_arranger_consume_begin_expected_owner_ok:
        lea     -28(%sp),%sp
        movem.l %d2-%d7,(%sp)
        move.l  %d4,%d7
        move.l  %d3,%d6
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d2,%d5
        move.w  %sr,%d2
        move.w  %d2,24(%sp)
        move.w  #0x2700,%sr
        moveq   #0,%d2
        move.b  __gk_arranger_kind,%d2
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d2
        bhi.w   .Lgk_arranger_consume_begin_corrupt
        tst.l   %d2
        beq.w   .Lgk_arranger_consume_begin_none
        cmpi.l  #GK_ARRANGER_STATE_PREPARING,%d2
        beq.w   .Lgk_arranger_consume_begin_busy
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d2
        beq.w   .Lgk_arranger_consume_begin_busy
        cmpi.l  #GK_ARRANGER_OWNER_TOKEN,%d7
        bne.s   .Lgk_arranger_consume_begin_direct_kind
        tst.l   %d6
        bne.w   .Lgk_arranger_consume_begin_corrupt
        cmpi.l  #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d2
        beq.s   .Lgk_arranger_consume_begin_kind_ok
        cmpi.l  #GK_ARRANGER_STATE_ARMED_DEFERRED,%d2
        beq.w   .Lgk_arranger_consume_begin_none
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d2
        beq.w   .Lgk_arranger_consume_begin_none
        bra.w   .Lgk_arranger_consume_begin_corrupt
.Lgk_arranger_consume_begin_direct_kind:
        tst.l   %d6
        beq.s   .Lgk_arranger_consume_begin_kind_any
        cmpi.l  #GK_ARRANGER_STATE_ARMED_DEFERRED,%d2
        beq.s   .Lgk_arranger_consume_begin_kind_ok
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d2
        beq.s   .Lgk_arranger_consume_begin_kind_ok
        bra.w   .Lgk_arranger_consume_begin_busy
.Lgk_arranger_consume_begin_kind_any:
        cmpi.l  #GK_ARRANGER_STATE_ARMED_DEFERRED,%d2
        beq.s   .Lgk_arranger_consume_begin_kind_ok
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d2
        beq.s   .Lgk_arranger_consume_begin_kind_ok
        cmpi.l  #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d2
        bne.w   .Lgk_arranger_consume_begin_corrupt
.Lgk_arranger_consume_begin_kind_ok:
        moveq   #0,%d0
        move.b  __gk_arranger_bank,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_arranger_consume_begin_busy
        moveq   #0,%d0
        move.b  __gk_arranger_pattern,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_arranger_consume_begin_busy
        moveq   #0,%d0
        move.b  __gk_arranger_kit,%d0
        cmp.l   %d5,%d0
        bne.w   .Lgk_arranger_consume_begin_busy
        moveq   #0,%d0
        move.b  __gk_arranger_owner,%d0
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d0
        beq.s   .Lgk_arranger_consume_begin_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d0
        bne.w   .Lgk_arranger_consume_begin_corrupt
.Lgk_arranger_consume_begin_owner_ok:
        cmpi.l  #GK_ARRANGER_OWNER_TOKEN,%d7
        beq.s   .Lgk_arranger_consume_begin_owner_matches
        cmp.l   %d7,%d0
        bne.w   .Lgk_arranger_consume_begin_busy
.Lgk_arranger_consume_begin_owner_matches:
        moveq   #0,%d0
        move.b  __gk_arranger_scene_mask,%d0
        tst.l   %d0
        beq.w   .Lgk_arranger_consume_begin_corrupt
        cmpi.l  #3,%d0
        bhi.w   .Lgk_arranger_consume_begin_corrupt
        btst    #0,%d0
        beq.s   .Lgk_arranger_consume_begin_scene_b
        moveq   #0,%d1
        move.b  __gk_arranger_scene_a,%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_arranger_consume_begin_corrupt
.Lgk_arranger_consume_begin_scene_b:
        btst    #1,%d0
        beq.s   .Lgk_arranger_consume_begin_fields
        moveq   #0,%d1
        move.b  __gk_arranger_scene_b,%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_arranger_consume_begin_corrupt
.Lgk_arranger_consume_begin_fields:
        tst.b   __gk_arranger_consume_source
        bne.w   .Lgk_arranger_consume_begin_corrupt
        tst.b   __gk_arranger_consume_epoch
        bne.w   .Lgk_arranger_consume_begin_corrupt
        tst.l   __gk_arranger_consume_generation
        bne.w   .Lgk_arranger_consume_begin_corrupt
        tst.l   __gk_arranger_generation
        beq.w   .Lgk_arranger_consume_begin_corrupt
        move.b  __gk_arranger_generation + 3,%d0
        cmp.b   __gk_arranger_epoch,%d0
        bne.w   .Lgk_arranger_consume_begin_corrupt
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d2
        beq.s   .Lgk_arranger_consume_begin_prepared
        moveq   #0,%d0
        move.b  __gk_arranger_descriptor,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_arranger_consume_begin_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_old_descriptor_flags,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_arranger_consume_begin_corrupt
        bra.s   .Lgk_arranger_consume_begin_token
.Lgk_arranger_consume_begin_prepared:
        moveq   #0,%d0
        move.b  __gk_arranger_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_arranger_consume_begin_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_old_descriptor_flags,%d0
        cmpi.l  #GK_DESC_VALID,%d0
        bne.w   .Lgk_arranger_consume_begin_corrupt
.Lgk_arranger_consume_begin_token:
        cmpi.l  #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d2
        beq.s   .Lgk_arranger_consume_begin_queued_token
        tst.b   __gk_arranger_token_active
        bne.w   .Lgk_arranger_consume_begin_corrupt
        tst.b   __gk_arranger_token_epoch
        bne.w   .Lgk_arranger_consume_begin_corrupt
        tst.l   __gk_arranger_token_generation
        bne.w   .Lgk_arranger_consume_begin_corrupt
        bra.s   .Lgk_arranger_consume_begin_publish
.Lgk_arranger_consume_begin_queued_token:
        moveq   #0,%d0
        move.b  __gk_arranger_token_active,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_arranger_consume_begin_busy
        moveq   #0,%d0
        move.b  __gk_arranger_token_epoch,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_epoch,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_consume_begin_corrupt
        move.l  __gk_arranger_token_generation,%d0
        cmp.l   __gk_arranger_generation,%d0
        bne.w   .Lgk_arranger_consume_begin_corrupt
.Lgk_arranger_consume_begin_publish:
        move.b  %d2,__gk_arranger_consume_source
        move.b  __gk_arranger_epoch,%d0
        move.b  %d0,__gk_arranger_consume_epoch
        move.l  __gk_arranger_generation,%d0
        move.l  %d0,__gk_arranger_consume_generation
        moveq   #GK_ARRANGER_STATE_CONSUMING,%d0
        .global gk_arranger_consume_publication
gk_arranger_consume_publication:
        move.b  %d0,__gk_arranger_kind
        move.l  %d2,%d1
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_consume_begin_restore
.Lgk_arranger_consume_begin_none:
        tst.b   __gk_arranger_token_active
        bne.s   .Lgk_arranger_consume_begin_corrupt
        tst.b   __gk_arranger_token_epoch
        bne.s   .Lgk_arranger_consume_begin_corrupt
        tst.l   __gk_arranger_token_generation
        bne.s   .Lgk_arranger_consume_begin_corrupt
        tst.l   __gk_arranger_consume_generation
        bne.s   .Lgk_arranger_consume_begin_corrupt
        moveq   #GK_ARRANGER_NOT_HANDLED,%d0
        bra.s   .Lgk_arranger_consume_begin_restore
.Lgk_arranger_consume_begin_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_consume_begin_restore
.Lgk_arranger_consume_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_consume_begin_restore:
        move.w  24(%sp),%d2
        move.w  %d2,%sr
        movem.l (%sp),%d2-%d7
        lea     28(%sp),%sp
        rts
.Lgk_arranger_consume_begin_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_consume_begin,.-gk_arranger_consume_begin
        .global gk_arranger_consume_finish
        .type   gk_arranger_consume_finish,@function
gk_arranger_consume_finish:
        lea     -12(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.w  %sr,%d3
        move.w  %d3,8(%sp)
        move.w  #0x2700,%sr
        moveq   #0,%d2
        move.b  __gk_arranger_kind,%d2
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d2
        bne.w   .Lgk_arranger_consume_finish_busy
        moveq   #0,%d2
        move.b  __gk_arranger_consume_source,%d2
        cmpi.l  #GK_ARRANGER_STATE_ARMED_DEFERRED,%d2
        beq.s   .Lgk_arranger_consume_finish_source_ok
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d2
        beq.s   .Lgk_arranger_consume_finish_source_ok
        cmpi.l  #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d2
        bne.w   .Lgk_arranger_consume_finish_corrupt
.Lgk_arranger_consume_finish_source_ok:
        moveq   #0,%d0
        move.b  __gk_arranger_consume_epoch,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_epoch,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_consume_finish_corrupt
        move.l  __gk_arranger_generation,%d0
        beq.w   .Lgk_arranger_consume_finish_corrupt
        cmp.l   __gk_arranger_consume_generation,%d0
        bne.w   .Lgk_arranger_consume_finish_corrupt
        move.b  __gk_arranger_generation + 3,%d0
        cmp.b   __gk_arranger_epoch,%d0
        bne.w   .Lgk_arranger_consume_finish_corrupt
        cmpi.l  #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d2
        beq.s   .Lgk_arranger_consume_finish_queued
        tst.b   __gk_arranger_token_active
        bne.w   .Lgk_arranger_consume_finish_corrupt
        tst.b   __gk_arranger_token_epoch
        bne.w   .Lgk_arranger_consume_finish_corrupt
        tst.l   __gk_arranger_token_generation
        bne.w   .Lgk_arranger_consume_finish_corrupt
        bra.s   .Lgk_arranger_consume_finish_transaction
.Lgk_arranger_consume_finish_queued:
        moveq   #0,%d0
        move.b  __gk_arranger_token_active,%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_arranger_consume_finish_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_token_epoch,%d0
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_consume_finish_corrupt
        move.l  __gk_arranger_token_generation,%d0
        cmp.l   __gk_arranger_generation,%d0
        bne.w   .Lgk_arranger_consume_finish_corrupt
.Lgk_arranger_consume_finish_transaction:
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        bne.w   .Lgk_arranger_consume_finish_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_arranger_consume_finish_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_arranger_consume_finish_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_arranger_consume_finish_corrupt
        .global gk_arranger_consume_clear_publication
gk_arranger_consume_clear_publication:
        clr.b   __gk_arranger_kind
        lea     __gk_arranger_owner,%a0
        moveq   #0,%d0
        moveq   #12,%d2
.Lgk_arranger_consume_finish_prefix:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_consume_finish_prefix
        addq.l  #1,%a0
        moveq   #(GK_ARRANGER_GENERATION - GK_ARRANGER_TOKEN_ACTIVE),%d2
.Lgk_arranger_consume_finish_suffix:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_consume_finish_suffix
        addq.l  #4,%a0
        moveq   #(GK_ARRANGER_STATE_SIZE - GK_ARRANGER_TOKEN_GENERATION),%d2
.Lgk_arranger_consume_finish_generations:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_consume_finish_generations
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_consume_finish_restore
.Lgk_arranger_consume_finish_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_consume_finish_restore
.Lgk_arranger_consume_finish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_consume_finish_restore:
        move.w  8(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d3
        lea     12(%sp),%sp
        rts
        .size   gk_arranger_consume_finish,.-gk_arranger_consume_finish
        .global gk_arranger_consume_abort
        .type   gk_arranger_consume_abort,@function
gk_arranger_consume_abort:
        move.l  %d2,-(%sp)
        moveq   #0,%d2
        move.b  __gk_arranger_kind,%d2
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d2
        bne.s   .Lgk_arranger_consume_abort_busy
        moveq   #0,%d0
        move.b  __gk_arranger_old_descriptor_flags,%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.s   .Lgk_arranger_consume_abort_workspace
        bsr.w   gk_arranger_pending_scene_rollback
        tst.l   %d0
        bne.s   .Lgk_arranger_consume_abort_restore
.Lgk_arranger_consume_abort_workspace:
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        beq.s   .Lgk_arranger_consume_abort_no_workspace
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.s   .Lgk_arranger_consume_abort_restore
        bra.s   .Lgk_arranger_consume_abort_finish
.Lgk_arranger_consume_abort_no_workspace:
        moveq   #0,%d0
        move.b  __gk_arranger_descriptor,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.s   .Lgk_arranger_consume_abort_corrupt
.Lgk_arranger_consume_abort_finish:
        bsr.w   gk_arranger_consume_finish
        bra.s   .Lgk_arranger_consume_abort_restore
.Lgk_arranger_consume_abort_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_consume_abort_restore
.Lgk_arranger_consume_abort_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_consume_abort_restore:
        move.l  (%sp)+,%d2
        rts
        .size   gk_arranger_consume_abort,.-gk_arranger_consume_abort
        .global gk_arranger_scene_engine_publish
        .type   gk_arranger_scene_engine_publish,@function
gk_arranger_scene_engine_publish:
        tst.l   %a0
        beq.w   .Lgk_arranger_engine_invalid
        tst.l   %d0
        beq.w   .Lgk_arranger_engine_range
        cmpi.l  #3,%d0
        bhi.w   .Lgk_arranger_engine_range
        lea     -24(%sp),%sp
        movem.l %d3-%d7/%a2,(%sp)
        movea.l %a0,%a2
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d2,%d5
        moveq   #0,%d6
        btst    #0,%d3
        beq.s   .Lgk_arranger_engine_payload_a
        move.l  %d4,%d6
        bra.s   .Lgk_arranger_engine_a_ready
.Lgk_arranger_engine_payload_a:
        move.b  0x10(%a2),%d6
.Lgk_arranger_engine_a_ready:
        andi.l  #0xff,%d6
        cmpi.l  #15,%d6
        bhi.w   .Lgk_arranger_engine_range_restore
        moveq   #0,%d7
        btst    #1,%d3
        beq.s   .Lgk_arranger_engine_payload_b
        move.l  %d5,%d7
        bra.s   .Lgk_arranger_engine_b_ready
.Lgk_arranger_engine_payload_b:
        move.b  0x11(%a2),%d7
.Lgk_arranger_engine_b_ready:
        andi.l  #0xff,%d7
        cmpi.l  #15,%d7
        bhi.w   .Lgk_arranger_engine_range_restore
        lea     GK_STOCK_ENGINE_SCENE_CLEAR,%a0
        moveq   #-1,%d0
        move.l  %d0,(%a0)
        move.l  %d0,4(%a0)
        move.l  %d0,8(%a0)
        move.l  %d0,12(%a0)
        move.l  %d6,%d0
        mulu.w  #10,%d0
        move.l  %d7,%d1
        mulu.w  #10,%d1
        lea     GK_STOCK_ENGINE_SCENE_TABLE,%a0
        lea     0x166a(%a2),%a1
        moveq   #0,%d3
        move.b  (%a1,%d0.l),%d3
        move.b  %d3,(%a0)
        move.b  (%a1,%d1.l),%d3
        move.b  %d3,1(%a0)
        addq.l  #1,%a1
        move.b  (%a1,%d0.l),%d3
        move.b  %d3,2(%a0)
        move.b  (%a1,%d1.l),%d3
        .global gk_arranger_scene_engine_publication
gk_arranger_scene_engine_publication:
        move.b  %d3,3(%a0)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_engine_restore
.Lgk_arranger_engine_range_restore:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_arranger_engine_restore:
        movem.l (%sp),%d3-%d7/%a2
        lea     24(%sp),%sp
        rts
.Lgk_arranger_engine_invalid:
        moveq   #GK_ERR_INVALID,%d0
        rts
.Lgk_arranger_engine_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_scene_engine_publish,.-gk_arranger_scene_engine_publish
        .global gk_arranger_active_scene_apply
        .type   gk_arranger_active_scene_apply,@function
gk_arranger_active_scene_apply:
        cmpi.l  #0xff,%d0
        bhi.w   .Lgk_arranger_active_range
        tst.l   %d1
        beq.w   .Lgk_arranger_active_range
        cmpi.l  #3,%d1
        bhi.w   .Lgk_arranger_active_range
        btst    #0,%d1
        beq.s   .Lgk_arranger_active_scene_b
        cmpi.l  #15,%d2
        bhi.w   .Lgk_arranger_active_range
.Lgk_arranger_active_scene_b:
        btst    #1,%d1
        beq.s   .Lgk_arranger_active_arguments_ok
        cmpi.l  #15,%d3
        bhi.w   .Lgk_arranger_active_range
.Lgk_arranger_active_arguments_ok:
        lea     -48(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %d2,%d6
        move.l  %d3,%d7
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        bne.w   .Lgk_arranger_active_busy
        move.l  %d0,%d1
        andi.l  #0x7e,%d1
        bne.w   .Lgk_arranger_active_corrupt
        moveq   #0,%d2
        move.b  __gk_workspace_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_arranger_active_busy
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_arranger_active_busy
        lea     __gk_lease_sidecars,%a0
        bsr.w   gk_selector_acquire
        tst.l   %d0
        bmi.w   .Lgk_arranger_active_restore
        move.l  %d0,%d3
        movea.l %a0,%a3
        cmp.l   %d2,%d3
        bne.w   .Lgk_arranger_active_release_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        move.b  %d0,42(%sp)
        moveq   #0,%d1
        move.b  __gk_workspace_dirty,%d1
        move.b  %d1,43(%sp)
        move.b  0x10(%a3),40(%sp)
        move.b  0x11(%a3),41(%sp)
        move.w  %sr,%d0
        move.w  %d0,44(%sp)
        move.w  #0x2700,%sr
        btst    #0,%d5
        beq.s   .Lgk_arranger_active_apply_b
        move.l  %d3,%d0
        moveq   #0x10,%d1
        move.l  %d6,%d2
        bsr.w   gk_descriptor_store_byte
        tst.l   %d0
        bne.s   .Lgk_arranger_active_rollback
.Lgk_arranger_active_apply_b:
        btst    #1,%d5
        beq.s   .Lgk_arranger_active_applied
        move.l  %d3,%d0
        moveq   #0x11,%d1
        move.l  %d7,%d2
        bsr.w   gk_descriptor_store_byte
        tst.l   %d0
        bne.s   .Lgk_arranger_active_rollback
.Lgk_arranger_active_applied:
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_arranger_active_masked_release_corrupt
        move.l  %d0,%d1
        lsr.l   #2,%d1
        moveq   #0,%d2
        .global gk_arranger_visible_mirror_check
gk_arranger_visible_mirror_check:
        move.b  GK_STOCK_CURRENT_BANK_MIRROR,%d2
        cmp.l   %d2,%d1
        bne.s   .Lgk_arranger_active_release_success
        andi.l  #3,%d0
        moveq   #0,%d1
        move.b  GK_STOCK_CURRENT_PART_MIRROR,%d1
        cmp.l   %d1,%d0
        bne.s   .Lgk_arranger_active_release_success
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     GK_STOCK_WORKING_PART_MIRROR_BASE,%a4
        adda.l  %d0,%a4
        btst    #0,%d5
        beq.s   .Lgk_arranger_active_mirror_b
        .global gk_arranger_visible_mirror_scene_a_publication
gk_arranger_visible_mirror_scene_a_publication:
        move.b  %d6,0x10(%a4)
.Lgk_arranger_active_mirror_b:
        btst    #1,%d5
        beq.s   .Lgk_arranger_active_release_success
        .global gk_arranger_visible_mirror_scene_b_publication
gk_arranger_visible_mirror_scene_b_publication:
        move.b  %d7,0x11(%a4)
.Lgk_arranger_active_release_success:
        .global gk_arranger_visible_mirror_restore
gk_arranger_visible_mirror_restore:
        move.w  44(%sp),%d0
        move.w  %d0,%sr
        move.l  %d3,%d0
        bsr.w   gk_descriptor_release
        tst.l   %d0
        bne.w   gk_arranger_fatal_active_scene_release
        movea.l %a3,%a0
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_active_restore
.Lgk_arranger_active_rollback:
        btst    #0,%d5
        beq.s   .Lgk_arranger_active_rollback_b
        move.l  %d3,%d0
        moveq   #0x10,%d1
        moveq   #0,%d2
        move.b  40(%sp),%d2
        bsr.w   gk_descriptor_store_byte
        tst.l   %d0
        bne.w   gk_arranger_fatal_active_scene_rollback_a
.Lgk_arranger_active_rollback_b:
        btst    #1,%d5
        beq.s   .Lgk_arranger_active_rollback_flags
        move.l  %d3,%d0
        moveq   #0x11,%d1
        moveq   #0,%d2
        move.b  41(%sp),%d2
        bsr.w   gk_descriptor_store_byte
        tst.l   %d0
        bne.w   gk_arranger_fatal_active_scene_rollback_b
.Lgk_arranger_active_rollback_flags:
        move.b  42(%sp),GK_DESC_FLAGS(%a2)
        moveq   #0,%d0
        move.b  43(%sp),%d0
        move.b  %d0,__gk_workspace_dirty
        move.w  44(%sp),%d0
        move.w  %d0,%sr
        bra.w   gk_arranger_fatal_active_scene_rollback_terminal
.Lgk_arranger_active_masked_release_corrupt:
        move.w  44(%sp),%d0
        move.w  %d0,%sr
.Lgk_arranger_active_release_corrupt:
        move.l  %d3,%d0
        bsr.w   gk_descriptor_release
        tst.l   %d0
        bne.w   gk_arranger_fatal_active_scene_corrupt_release
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_arranger_active_restore
.Lgk_arranger_active_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_active_restore
.Lgk_arranger_active_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_active_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     48(%sp),%sp
        rts
.Lgk_arranger_active_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_active_scene_apply,.-gk_arranger_active_scene_apply
        .global gk_arranger_pending_scene_apply
        .type   gk_arranger_pending_scene_apply,@function
gk_arranger_pending_scene_apply:
        lea     -28(%sp),%sp
        movem.l %d2-%d6/%a2-%a3,(%sp)
        moveq   #0,%d6
        move.b  __gk_arranger_kind,%d6
        cmpi.l  #GK_ARRANGER_STATE_PREPARING,%d6
        beq.s   .Lgk_arranger_pending_kind_ok
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d6
        bne.w   .Lgk_arranger_pending_busy
.Lgk_arranger_pending_kind_ok:
        moveq   #0,%d2
        move.b  __gk_arranger_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_bank,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_bank,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_pattern,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_pattern,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_kit,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_kit,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        move.l  %d0,%d1
        andi.l  #0xe8,%d1
        bne.w   .Lgk_arranger_pending_corrupt
        btst    #2,%d0
        beq.w   .Lgk_arranger_pending_corrupt
        btst    #0,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d6
        move.b  __gk_arranger_old_descriptor_flags,%d6
        cmpi.l  #GK_ID_NONE,%d6
        beq.s   .Lgk_arranger_pending_first_apply
        cmpi.l  #GK_DESC_VALID,%d6
        bne.w   .Lgk_arranger_pending_corrupt
        btst    #4,%d0
        beq.w   .Lgk_arranger_pending_corrupt
        moveq   #1,%d6
        bra.s   .Lgk_arranger_pending_apply_mode_ready
.Lgk_arranger_pending_first_apply:
        btst    #4,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d6
.Lgk_arranger_pending_apply_mode_ready:
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d3
        move.b  GK_DESC_FLAGS(%a2),%d3
        tst.l   %d6
        bne.s   .Lgk_arranger_pending_expect_applied
        cmpi.l  #GK_DESC_VALID,%d3
        bne.w   .Lgk_arranger_pending_corrupt
        bra.s   .Lgk_arranger_pending_flags_ok
.Lgk_arranger_pending_expect_applied:
        cmpi.l  #0x11,%d3
        bne.w   .Lgk_arranger_pending_corrupt
.Lgk_arranger_pending_flags_ok:
        movea.l GK_DESC_PAYLOAD(%a2),%a3
        tst.l   %a3
        beq.w   .Lgk_arranger_pending_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a2),%d0
        moveq   #0,%d1
        move.b  __gk_arranger_kit,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a2),%d0
        cmpi.l  #2,%d0
        blo.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_arranger_pending_corrupt
        bsr.w   gk_physical_validate
        cmp.l   %d2,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d4
        move.b  __gk_arranger_scene_mask,%d4
        tst.l   %d4
        beq.w   .Lgk_arranger_pending_corrupt
        cmpi.l  #3,%d4
        bhi.w   .Lgk_arranger_pending_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_dirty,%d0
        cmpi.l  #1,%d0
        bhi.w   .Lgk_arranger_pending_corrupt
        tst.l   %d6
        beq.s   .Lgk_arranger_pending_write
        moveq   #0,%d1
        move.b  __gk_arranger_old_workspace_dirty,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_pending_corrupt
        btst    #0,%d4
        beq.s   .Lgk_arranger_pending_validate_b
        moveq   #0,%d0
        move.b  __gk_arranger_scene_a,%d0
        cmp.b   0x10(%a3),%d0
        bne.w   .Lgk_arranger_pending_corrupt
.Lgk_arranger_pending_validate_b:
        btst    #1,%d4
        beq.s   .Lgk_arranger_pending_validated
        moveq   #0,%d0
        move.b  __gk_arranger_scene_b,%d0
        cmp.b   0x11(%a3),%d0
        bne.w   .Lgk_arranger_pending_corrupt
.Lgk_arranger_pending_validated:
        movea.l %a3,%a0
        moveq   #GK_OK,%d0
        bra.w   .Lgk_arranger_pending_restore
.Lgk_arranger_pending_write:
        move.w  %sr,%d5
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  0x10(%a3),%d0
        move.b  %d0,__gk_arranger_old_scene_a
        move.b  0x11(%a3),%d0
        move.b  %d0,__gk_arranger_old_scene_b
        move.b  __gk_workspace_dirty,%d0
        move.b  %d0,__gk_arranger_old_workspace_dirty
        move.b  %d3,__gk_arranger_old_descriptor_flags
        btst    #0,%d4
        beq.w   .Lgk_arranger_pending_apply_b
        move.b  __gk_arranger_scene_a,%d0
        move.b  %d0,0x10(%a3)
.Lgk_arranger_pending_apply_b:
        btst    #1,%d4
        beq.w   .Lgk_arranger_pending_mark_dirty
        move.b  __gk_arranger_scene_b,%d0
        move.b  %d0,0x11(%a3)
.Lgk_arranger_pending_mark_dirty:
        ori.l   #GK_DESC_DIRTY,%d3
        move.b  %d3,GK_DESC_FLAGS(%a2)
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        ori.l   #GK_TRANSITION_PENDING_DIRTY,%d0
        move.b  %d0,__gk_pending_transition_flags
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmp.l   %d2,%d0
        bne.s   .Lgk_arranger_pending_applied
        moveq   #1,%d0
        move.b  %d0,__gk_workspace_dirty
.Lgk_arranger_pending_applied:
        move.w  %d5,%sr
        movea.l %a3,%a0
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_pending_restore
.Lgk_arranger_pending_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_pending_restore
.Lgk_arranger_pending_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_pending_restore:
        movem.l (%sp),%d2-%d6/%a2-%a3
        lea     28(%sp),%sp
        rts
        .size   gk_arranger_pending_scene_apply,.-gk_arranger_pending_scene_apply
        .global gk_arranger_pending_scene_rollback
        .type   gk_arranger_pending_scene_rollback,@function
gk_arranger_pending_scene_rollback:
        .incbin "stock/0005.bin", 0, 4
        .incbin "stock/0005.bin", 4, 4
        moveq   #0,%d0
        move.b  __gk_arranger_kind,%d0
        cmpi.l  #GK_ARRANGER_STATE_PREPARING,%d0
        beq.s   .Lgk_arranger_rollback_kind_ok
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d0
        beq.s   .Lgk_arranger_rollback_kind_ok
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d0
        bne.w   .Lgk_arranger_rollback_busy
.Lgk_arranger_rollback_kind_ok:
        moveq   #0,%d2
        move.b  __gk_arranger_old_descriptor_flags,%d2
        cmpi.l  #GK_ID_NONE,%d2
        beq.w   .Lgk_arranger_rollback_ok
        cmpi.l  #GK_DESC_VALID,%d2
        bne.w   .Lgk_arranger_rollback_corrupt
        moveq   #0,%d3
        move.b  __gk_arranger_descriptor,%d3
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w   .Lgk_arranger_rollback_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_arranger_rollback_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        move.l  %d0,%d1
        andi.l  #0xe8,%d1
        bne.w   .Lgk_arranger_rollback_corrupt
        btst    #2,%d0
        beq.w   .Lgk_arranger_rollback_corrupt
        btst    #0,%d0
        bne.w   .Lgk_arranger_rollback_corrupt
        btst    #4,%d0
        beq.w   .Lgk_arranger_rollback_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        cmpi.l  #0x11,%d0
        bne.w   .Lgk_arranger_rollback_corrupt
        movea.l GK_DESC_PAYLOAD(%a2),%a3
        tst.l   %a3
        beq.w   .Lgk_arranger_rollback_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_arranger_rollback_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a2),%d0
        cmpi.l  #2,%d0
        blo.w   .Lgk_arranger_rollback_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_arranger_rollback_corrupt
        bsr.w   gk_physical_validate
        cmp.l   %d3,%d0
        bne.w   .Lgk_arranger_rollback_corrupt
        moveq   #0,%d4
        move.b  __gk_arranger_scene_mask,%d4
        tst.l   %d4
        beq.w   .Lgk_arranger_rollback_corrupt
        cmpi.l  #3,%d4
        bhi.w   .Lgk_arranger_rollback_corrupt
        moveq   #0,%d0
        move.b  __gk_workspace_dirty,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_old_workspace_dirty,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_rollback_corrupt
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        btst    #0,%d4
        beq.w   .Lgk_arranger_rollback_b
        move.b  __gk_arranger_old_scene_a,%d0
        move.b  %d0,0x10(%a3)
.Lgk_arranger_rollback_b:
        btst    #1,%d4
        beq.w   .Lgk_arranger_rollback_metadata
        move.b  __gk_arranger_old_scene_b,%d0
        move.b  %d0,0x11(%a3)
.Lgk_arranger_rollback_metadata:
        move.b  %d2,GK_DESC_FLAGS(%a2)
        move.b  __gk_arranger_old_workspace_dirty,%d0
        move.b  %d0,__gk_workspace_dirty
        moveq   #0,%d0
        move.b  __gk_pending_transition_flags,%d0
        andi.l  #0xef,%d0
        move.b  %d0,__gk_pending_transition_flags
        moveq   #-1,%d0
        move.b  %d0,__gk_arranger_old_descriptor_flags
        move.w  %d1,%sr
.Lgk_arranger_rollback_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_rollback_restore
.Lgk_arranger_rollback_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_rollback_restore
.Lgk_arranger_rollback_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_rollback_restore:
        movem.l (%sp),%d2-%d4/%a2-%a3
        lea     20(%sp),%sp
        rts
        .size   gk_arranger_pending_scene_rollback,.-gk_arranger_pending_scene_rollback
        .global gk_arranger_transition_adopt
        .type   gk_arranger_transition_adopt,@function
gk_arranger_transition_adopt:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_arranger_adopt_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_arranger_adopt_range
        cmpi.l  #0xff,%d2
        bhi.w   .Lgk_arranger_adopt_range
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d3
        beq.s   .Lgk_arranger_adopt_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d3
        beq.s   .Lgk_arranger_adopt_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_TOKEN,%d3
        bne.w   .Lgk_arranger_adopt_range
.Lgk_arranger_adopt_owner_ok:
        .incbin "stock/0006.bin", 0, 4
        .incbin "stock/0006.bin", 4, 4
        movea.l %d0,%a4
        move.l  %d0,%d4
        move.l  %d1,%d5
        move.l  %d2,%d6
        move.l  %d3,%d7
        moveq   #GK_ARRANGER_CONSUME_ANY,%d3
        move.l  %d7,%d4
        bsr.w   gk_arranger_consume_begin
        move.l  %a4,%d4
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        beq.w   .Lgk_arranger_adopt_restore
        tst.l   %d0
        bmi.w   .Lgk_arranger_adopt_restore
        move.l  %d1,%d7
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d7
        beq.s   .Lgk_arranger_adopt_validate_write
        tst.b   __gk_pattern_queue_commit_prepared
        beq.s   .Lgk_arranger_adopt_prepare_workspace
        move.l  %d4,%d0
        move.l  %d5,%d1
        jsr     gk_pattern_queue_commit_prepared_take
        tst.l   %d0
        bpl.s   .Lgk_arranger_adopt_prepared_taken
        jmp     gk_arranger_queue_commit_prepared_fatal
.Lgk_arranger_adopt_prepared_taken:
        move.b  %d0,__gk_arranger_descriptor
        bra.s   .Lgk_arranger_adopt_validate_write
.Lgk_arranger_adopt_prepare_workspace:
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   .Lgk_arranger_adopt_fail
        move.b  %d0,__gk_arranger_descriptor
        bsr.w   gk_ui_transition_prepare
        tst.l   %d0
        bmi.w   .Lgk_arranger_adopt_fail
.Lgk_arranger_adopt_validate_write:
        bsr.w   gk_arranger_pending_scene_apply
        tst.l   %d0
        beq.s   .Lgk_arranger_adopt_scene_applied
        tst.b   __gk_pattern_queue_commit_prepared
        beq.s   .Lgk_arranger_adopt_scene_unprepared_fail
        jmp     gk_arranger_queue_commit_prepared_fatal
.Lgk_arranger_adopt_scene_unprepared_fail:
        bra.w   .Lgk_arranger_adopt_fail
.Lgk_arranger_adopt_scene_applied:
        movea.l %a0,%a3
        moveq   #0,%d2
        move.b  __gk_arranger_descriptor,%d2
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_arranger_adopt_corrupt
        moveq   #0,%d0
        move.b  __gk_pending_workspace_descriptor,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_arranger_adopt_corrupt
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        cmpi.l  #0x11,%d0
        bne.w   .Lgk_arranger_adopt_corrupt
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a3
        bne.w   .Lgk_arranger_adopt_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_arranger_adopt_corrupt
        tst.w   GK_DESC_READERS(%a2)
        beq.s   .Lgk_arranger_adopt_readers_ready
        tst.b   __gk_pattern_queue_commit_prepared
        beq.s   .Lgk_arranger_adopt_readers_unprepared_busy
        jmp     gk_arranger_queue_commit_prepared_fatal
.Lgk_arranger_adopt_readers_unprepared_busy:
        bra.w   .Lgk_arranger_adopt_busy
.Lgk_arranger_adopt_readers_ready:
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a2),%d0
        cmpi.l  #2,%d0
        blo.w   .Lgk_arranger_adopt_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a2),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_arranger_adopt_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_arranger_adopt_corrupt
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a2),%d3
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w   .Lgk_arranger_adopt_corrupt
        move.l  %d3,%d0
        lsr.l   #2,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_arranger_adopt_corrupt
        move.l  %d3,%d0
        bsr.w   gk_physical_validate
        cmp.l   %d2,%d0
        bne.w   .Lgk_arranger_adopt_corrupt
        moveq   #0,%d0
        move.b  GK_SIDECAR_PENDING + __gk_lease_sidecars,%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_arranger_adopt_corrupt
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d1
        move.b  (%a0,%d0.l),%d1
        cmp.l   %d6,%d1
        bne.w   .Lgk_arranger_adopt_busy
        andi.l  #3,%d3
        move.l  %d2,%d1
        movea.l %d3,%a0
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_adopt_restore
.Lgk_arranger_adopt_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_adopt_fail
.Lgk_arranger_adopt_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_adopt_fail:
        movea.l %d0,%a5
        bsr.w   gk_arranger_consume_abort
        tst.l   %d0
        bne.w   gk_arranger_fatal_transition_adopt_abort
        move.l  %a5,%d0
.Lgk_arranger_adopt_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
.Lgk_arranger_adopt_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_transition_adopt,.-gk_arranger_transition_adopt
        .global gk_arranger_consume_requeue
        .type   gk_arranger_consume_requeue,@function
gk_arranger_consume_requeue:
        lea     -12(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.w  %sr,%d3
        move.w  %d3,8(%sp)
        move.w  #0x2700,%sr
        moveq   #0,%d2
        move.b  __gk_arranger_kind,%d2
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d2
        bne.w   .Lgk_arranger_requeue_busy
        moveq   #0,%d2
        move.b  __gk_arranger_consume_source,%d2
        cmpi.l  #GK_ARRANGER_STATE_ARMED_DEFERRED,%d2
        beq.s   .Lgk_arranger_requeue_source_ok
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d2
        bne.w   .Lgk_arranger_requeue_corrupt
.Lgk_arranger_requeue_source_ok:
        moveq   #0,%d0
        move.b  __gk_arranger_consume_epoch,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_epoch,%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_arranger_requeue_corrupt
        move.l  __gk_arranger_generation,%d0
        beq.w   .Lgk_arranger_requeue_corrupt
        cmp.l   __gk_arranger_consume_generation,%d0
        bne.w   .Lgk_arranger_requeue_corrupt
        tst.b   __gk_arranger_token_active
        bne.w   .Lgk_arranger_requeue_corrupt
        tst.b   __gk_arranger_token_epoch
        bne.w   .Lgk_arranger_requeue_corrupt
        tst.l   __gk_arranger_token_generation
        bne.w   .Lgk_arranger_requeue_corrupt
        moveq   #0,%d0
        move.b  __gk_runtime_flags,%d0
        btst    #7,%d0
        bne.w   .Lgk_arranger_requeue_busy
        move.l  __gk_pending_workspace_descriptor,%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_arranger_requeue_corrupt
        tst.b   __gk_pending_transition_flags
        bne.w   .Lgk_arranger_requeue_corrupt
        tst.b   __gk_pending_ui_capture_created
        bne.w   .Lgk_arranger_requeue_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_old_descriptor_flags,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_arranger_requeue_corrupt
        cmpi.l  #GK_ARRANGER_STATE_ARMED_DEFERRED,%d2
        bne.s   .Lgk_arranger_requeue_reset
        moveq   #0,%d0
        move.b  __gk_arranger_descriptor,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_arranger_requeue_corrupt
.Lgk_arranger_requeue_reset:
        moveq   #-1,%d0
        move.b  %d0,__gk_arranger_descriptor
        clr.b   __gk_arranger_old_scene_a
        clr.b   __gk_arranger_old_scene_b
        clr.b   __gk_arranger_old_workspace_dirty
        move.b  %d0,__gk_arranger_old_descriptor_flags
        clr.b   __gk_arranger_consume_source
        clr.b   __gk_arranger_consume_epoch
        clr.l   __gk_arranger_consume_generation
        moveq   #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d0
        .global gk_arranger_requeue_publication
gk_arranger_requeue_publication:
        move.b  %d0,__gk_arranger_kind
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_requeue_restore
.Lgk_arranger_requeue_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_requeue_restore
.Lgk_arranger_requeue_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_requeue_restore:
        move.w  8(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d3
        lea     12(%sp),%sp
        rts
        .size   gk_arranger_consume_requeue,.-gk_arranger_consume_requeue
        .global gk_arranger_queue_publish_handoff
        .type   gk_arranger_queue_publish_handoff,@function
gk_arranger_queue_publish_handoff:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_arranger_queue_handoff_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_arranger_queue_handoff_range
        cmpi.l  #0xff,%d2
        bhi.w   .Lgk_arranger_queue_handoff_range
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d3
        beq.s   .Lgk_arranger_queue_handoff_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d3
        bne.w   .Lgk_arranger_queue_handoff_range
.Lgk_arranger_queue_handoff_owner_ok:
        lea     -28(%sp),%sp
        movem.l %d2-%d7/%a2,(%sp)
        move.l  %d3,%d6
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d2,%d5
        move.l  %d3,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        moveq   #GK_ARRANGER_CONSUME_ARMED_ONLY,%d3
        move.l  %d6,%d4
        bsr.w   gk_arranger_consume_begin
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        beq.w   .Lgk_arranger_queue_handoff_ok
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_arranger_queue_handoff_ok
        tst.l   %d0
        bmi.w   .Lgk_arranger_queue_handoff_restore
        move.l  %d1,%d7
        cmpi.l  #GK_ARRANGER_STATE_ARMED_PREPARED,%d7
        bne.s   .Lgk_arranger_queue_handoff_requeue
        bsr.w   gk_arranger_pending_scene_rollback
        tst.l   %d0
        bne.w   .Lgk_arranger_queue_handoff_restore
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   .Lgk_arranger_queue_handoff_restore
.Lgk_arranger_queue_handoff_requeue:
        bsr.w   gk_arranger_consume_requeue
        bra.s   .Lgk_arranger_queue_handoff_restore
.Lgk_arranger_queue_handoff_ok:
        moveq   #GK_OK,%d0
.Lgk_arranger_queue_handoff_restore:
        movem.l (%sp),%d2-%d7/%a2
        lea     28(%sp),%sp
        rts
.Lgk_arranger_queue_handoff_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_queue_publish_handoff,.-gk_arranger_queue_publish_handoff
        .global gk_arranger_abort_matching
        .type   gk_arranger_abort_matching,@function
gk_arranger_abort_matching:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_arranger_abort_matching_ok_direct
        cmpi.l  #15,%d1
        bhi.w   .Lgk_arranger_abort_matching_ok_direct
        cmpi.l  #0xff,%d2
        bhi.w   .Lgk_arranger_abort_matching_ok_direct
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d3
        beq.s   .Lgk_arranger_abort_matching_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d3
        bne.w   .Lgk_arranger_abort_matching_ok_direct
.Lgk_arranger_abort_matching_owner_ok:
        lea     -28(%sp),%sp
        movem.l %d2-%d7/%a2,(%sp)
        move.l  %d3,%d6
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d2,%d5
        move.l  %d3,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        moveq   #GK_ARRANGER_CONSUME_ANY,%d3
        move.l  %d6,%d4
        bsr.w   gk_arranger_consume_begin
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        beq.w   .Lgk_arranger_abort_matching_ok
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_arranger_abort_matching_ok
        tst.l   %d0
        bmi.w   .Lgk_arranger_abort_matching_restore
        bsr.w   gk_arranger_consume_abort
        bra.s   .Lgk_arranger_abort_matching_restore
.Lgk_arranger_abort_matching_ok:
        moveq   #GK_OK,%d0
.Lgk_arranger_abort_matching_restore:
        movem.l (%sp),%d2-%d7/%a2
        lea     28(%sp),%sp
        rts
.Lgk_arranger_abort_matching_ok_direct:
        moveq   #GK_OK,%d0
        rts
        .size   gk_arranger_abort_matching,.-gk_arranger_abort_matching
        .global gk_arranger_queue_token_issue
        .type   gk_arranger_queue_token_issue,@function
gk_arranger_queue_token_issue:
        lea     -24(%sp),%sp
        movem.l %d2-%d5/%a2,(%sp)
        move.w  %sr,%d5
        move.w  %d5,20(%sp)
        move.w  #0x2700,%sr
        moveq   #0,%d2
        move.b  __gk_arranger_kind,%d2
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d2
        bhi.w   .Lgk_arranger_token_issue_corrupt
        tst.l   %d2
        beq.w   .Lgk_arranger_token_issue_none
        cmpi.l  #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d2
        bne.w   .Lgk_arranger_token_issue_no_token
        tst.b   __gk_arranger_consume_source
        bne.w   .Lgk_arranger_token_issue_corrupt
        tst.b   __gk_arranger_consume_epoch
        bne.w   .Lgk_arranger_token_issue_corrupt
        tst.l   __gk_arranger_consume_generation
        bne.w   .Lgk_arranger_token_issue_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_descriptor,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_arranger_token_issue_corrupt
        moveq   #0,%d0
        move.b  __gk_arranger_old_descriptor_flags,%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_arranger_token_issue_corrupt
        tst.b   __gk_arranger_token_active
        bne.w   .Lgk_arranger_token_issue_busy
        tst.b   __gk_arranger_token_epoch
        bne.w   .Lgk_arranger_token_issue_corrupt
        tst.l   __gk_arranger_token_generation
        bne.w   .Lgk_arranger_token_issue_corrupt
        tst.l   __gk_arranger_generation
        beq.w   .Lgk_arranger_token_issue_corrupt
        move.b  __gk_arranger_generation + 3,%d0
        cmp.b   __gk_arranger_epoch,%d0
        bne.w   .Lgk_arranger_token_issue_corrupt
        moveq   #0,%d0
        move.b  __gk_sequencer_latch_queue_handoff,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_arranger_token_issue_stock_state
        moveq   #1,%d0
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.w   .Lgk_arranger_token_issue_stale
        bra.s   .Lgk_arranger_token_issue_state_ready
.Lgk_arranger_token_issue_stock_state:
        move.l  GK_STOCK_SCHEDULER_STATE,%d0
        cmpi.l  #1,%d0
        beq.s   .Lgk_arranger_token_issue_state_ready
        cmpi.l  #2,%d0
        bne.w   .Lgk_arranger_token_issue_stale
.Lgk_arranger_token_issue_state_ready:
        tst.l   GK_STOCK_SCHEDULER_CHAINED
        bne.w   .Lgk_arranger_token_issue_stale
        moveq   #0,%d3
        move.b  __gk_arranger_bank,%d3
        cmpi.l  #15,%d3
        bhi.w   .Lgk_arranger_token_issue_corrupt
        moveq   #0,%d4
        move.b  __gk_arranger_pattern,%d4
        cmpi.l  #15,%d4
        bhi.w   .Lgk_arranger_token_issue_corrupt
        moveq   #0,%d0
        move.b  __gk_sequencer_latch_queue_handoff,%d0
        cmpi.l  #1,%d0
        bne.s   .Lgk_arranger_token_issue_stock_tuple
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_BANK,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_arranger_token_issue_stale
        moveq   #0,%d0
        move.b  GK_STOCK_SEQUENCER_CURRENT_PATTERN,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_arranger_token_issue_stale
        bra.s   .Lgk_arranger_token_issue_tuple_ready
.Lgk_arranger_token_issue_stock_tuple:
        moveq   #0,%d0
        move.b  GK_STOCK_QUEUED_BANK,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_arranger_token_issue_stale
        moveq   #0,%d0
        move.b  GK_STOCK_QUEUED_PATTERN,%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_arranger_token_issue_stale
.Lgk_arranger_token_issue_tuple_ready:
        move.l  __gk_arranger_generation,%d5
        move.l  %d5,__gk_arranger_token_generation
        move.b  __gk_arranger_epoch,%d0
        move.b  %d0,__gk_arranger_token_epoch
        moveq   #1,%d0
        .global gk_arranger_token_publication
gk_arranger_token_publication:
        move.b  %d0,__gk_arranger_token_active
        move.l  %d5,%d0
        bra.s   .Lgk_arranger_token_issue_restore
.Lgk_arranger_token_issue_stale:
        bsr.w   .Lgk_arranger_clear_locked
        moveq   #GK_ARRANGER_NO_TOKEN,%d0
        bra.s   .Lgk_arranger_token_issue_restore
.Lgk_arranger_token_issue_none:
        tst.b   __gk_arranger_token_active
        bne.s   .Lgk_arranger_token_issue_corrupt
        tst.b   __gk_arranger_token_epoch
        bne.s   .Lgk_arranger_token_issue_corrupt
        tst.l   __gk_arranger_token_generation
        bne.s   .Lgk_arranger_token_issue_corrupt
        tst.b   __gk_arranger_consume_source
        bne.s   .Lgk_arranger_token_issue_corrupt
        tst.b   __gk_arranger_consume_epoch
        bne.s   .Lgk_arranger_token_issue_corrupt
        tst.l   __gk_arranger_consume_generation
        bne.s   .Lgk_arranger_token_issue_corrupt
.Lgk_arranger_token_issue_no_token:
        moveq   #GK_ARRANGER_NO_TOKEN,%d0
        bra.s   .Lgk_arranger_token_issue_restore
.Lgk_arranger_token_issue_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_arranger_token_issue_restore
.Lgk_arranger_token_issue_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_token_issue_restore:
        move.w  20(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d5/%a2
        lea     24(%sp),%sp
        rts
        .size   gk_arranger_queue_token_issue,.-gk_arranger_queue_token_issue
        .global gk_arranger_queue_token_cleanup
        .type   gk_arranger_queue_token_cleanup,@function
gk_arranger_queue_token_cleanup:
        cmpi.l  #GK_ARRANGER_NO_TOKEN,%d0
        beq.w   .Lgk_arranger_token_cleanup_ok_direct
        tst.l   %d0
        ble.w   .Lgk_arranger_token_cleanup_range
        lea     -20(%sp),%sp
        movem.l %d2-%d4/%a2,(%sp)
        move.l  %d0,%d4
        move.w  %sr,%d3
        move.w  %d3,16(%sp)
        move.w  #0x2700,%sr
        move.l  __gk_arranger_generation,%d0
        cmp.l   %d4,%d0
        bne.s   .Lgk_arranger_token_cleanup_ok
        tst.b   __gk_arranger_token_active
        beq.s   .Lgk_arranger_token_cleanup_ok
        move.l  __gk_arranger_token_generation,%d0
        cmp.l   %d4,%d0
        bne.s   .Lgk_arranger_token_cleanup_corrupt
        move.b  __gk_arranger_generation + 3,%d0
        cmp.b   __gk_arranger_epoch,%d0
        bne.s   .Lgk_arranger_token_cleanup_corrupt
        move.b  __gk_arranger_epoch,%d0
        cmp.b   __gk_arranger_token_epoch,%d0
        bne.s   .Lgk_arranger_token_cleanup_corrupt
        moveq   #0,%d2
        move.b  __gk_arranger_kind,%d2
        cmpi.l  #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d2
        beq.s   .Lgk_arranger_token_cleanup_clear
        cmpi.l  #GK_ARRANGER_STATE_CONSUMING,%d2
        bne.s   .Lgk_arranger_token_cleanup_corrupt
        move.w  16(%sp),%d0
        move.w  %d0,%sr
        bsr.w   gk_arranger_consume_abort
        bra.s   .Lgk_arranger_token_cleanup_restore_no_sr
.Lgk_arranger_token_cleanup_clear:
        bsr.w   .Lgk_arranger_clear_locked
.Lgk_arranger_token_cleanup_ok:
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_token_cleanup_restore
.Lgk_arranger_token_cleanup_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_token_cleanup_restore:
        move.w  16(%sp),%d1
        move.w  %d1,%sr
.Lgk_arranger_token_cleanup_restore_no_sr:
        movem.l (%sp),%d2-%d4/%a2
        lea     20(%sp),%sp
        rts
.Lgk_arranger_token_cleanup_ok_direct:
        moveq   #GK_OK,%d0
        rts
.Lgk_arranger_token_cleanup_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_queue_token_cleanup,.-gk_arranger_queue_token_cleanup
        .global gk_arranger_queue_token_defer
        .type   gk_arranger_queue_token_defer,@function
gk_arranger_queue_token_defer:
        cmpi.l  #GK_ARRANGER_NO_TOKEN,%d0
        beq.w   .Lgk_arranger_token_defer_ok_direct
        tst.l   %d0
        ble.w   .Lgk_arranger_token_defer_range
        lea     -12(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  %d0,%d3
        move.w  %sr,%d2
        move.w  %d2,8(%sp)
        move.w  #0x2700,%sr
        move.l  __gk_arranger_generation,%d0
        cmp.l   %d3,%d0
        bne.s   .Lgk_arranger_token_defer_corrupt
        cmp.l   __gk_arranger_token_generation,%d0
        bne.s   .Lgk_arranger_token_defer_corrupt
        tst.b   __gk_arranger_token_active
        beq.s   .Lgk_arranger_token_defer_corrupt
        move.b  __gk_arranger_generation + 3,%d0
        cmp.b   __gk_arranger_epoch,%d0
        bne.s   .Lgk_arranger_token_defer_corrupt
        move.b  __gk_arranger_epoch,%d0
        cmp.b   __gk_arranger_token_epoch,%d0
        bne.s   .Lgk_arranger_token_defer_corrupt
        moveq   #GK_ARRANGER_STATE_QUEUED_DEFERRED,%d0
        cmp.b   __gk_arranger_kind,%d0
        bne.s   .Lgk_arranger_token_defer_corrupt
        tst.b   __gk_arranger_consume_source
        bne.s   .Lgk_arranger_token_defer_corrupt
        tst.b   __gk_arranger_consume_epoch
        bne.s   .Lgk_arranger_token_defer_corrupt
        tst.l   __gk_arranger_consume_generation
        bne.s   .Lgk_arranger_token_defer_corrupt
        clr.b   __gk_arranger_token_active
        clr.b   __gk_arranger_token_epoch
        clr.l   __gk_arranger_token_generation
        moveq   #GK_OK,%d0
        bra.s   .Lgk_arranger_token_defer_restore
.Lgk_arranger_token_defer_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_arranger_token_defer_restore:
        move.w  8(%sp),%d1
        move.w  %d1,%sr
        movem.l (%sp),%d2-%d3
        lea     12(%sp),%sp
        rts
.Lgk_arranger_token_defer_ok_direct:
        moveq   #GK_OK,%d0
        rts
.Lgk_arranger_token_defer_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_queue_token_defer,.-gk_arranger_queue_token_defer
.Lgk_arranger_clear_locked:
        clr.b   __gk_arranger_kind
        lea     __gk_arranger_owner,%a0
        moveq   #0,%d0
        moveq   #12,%d2
.Lgk_arranger_clear_locked_prefix:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_clear_locked_prefix
        addq.l  #1,%a0
        moveq   #(GK_ARRANGER_GENERATION - GK_ARRANGER_TOKEN_ACTIVE),%d2
.Lgk_arranger_clear_locked_suffix:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_clear_locked_suffix
        addq.l  #4,%a0
        moveq   #(GK_ARRANGER_STATE_SIZE - GK_ARRANGER_TOKEN_GENERATION),%d2
.Lgk_arranger_clear_locked_generations:
        move.b  %d0,(%a0)+
        subq.l  #1,%d2
        bne.s   .Lgk_arranger_clear_locked_generations
        rts
        .global gk_arranger_post_scene_events
        .type   gk_arranger_post_scene_events,@function
gk_arranger_post_scene_events:
        tst.l   %a0
        beq.s   .Lgk_arranger_events_invalid
        tst.l   %a1
        beq.s   .Lgk_arranger_events_invalid
        tst.l   %d0
        beq.s   .Lgk_arranger_events_range
        cmpi.l  #3,%d0
        bhi.s   .Lgk_arranger_events_range
        lea     -12(%sp),%sp
        movem.l %d2/%a2-%a3,(%sp)
        move.l  %d0,%d2
        movea.l %a0,%a2
        movea.l %a1,%a3
        btst    #0,%d2
        beq.s   .Lgk_arranger_events_b
        .global gk_arranger_scene_event_prepare_a_call
gk_arranger_scene_event_prepare_a_call:
        .incbin "stock/0007.bin", 0, 6
        pea     (%a2)
        pea     GK_STOCK_EVENT_OBJECT
        .global gk_arranger_scene_event_a_call
gk_arranger_scene_event_a_call:
        jsr     GK_STOCK_EVENT_POINTER_PUSH
        addq.l  #8,%sp
.Lgk_arranger_events_b:
        btst    #1,%d2
        beq.s   .Lgk_arranger_events_done
        .global gk_arranger_scene_event_prepare_b_call
gk_arranger_scene_event_prepare_b_call:
        .incbin "stock/0008.bin", 0, 6
        pea     (%a3)
        pea     GK_STOCK_EVENT_OBJECT
        .global gk_arranger_scene_event_b_call
gk_arranger_scene_event_b_call:
        jsr     GK_STOCK_EVENT_POINTER_PUSH
        addq.l  #8,%sp
.Lgk_arranger_events_done:
        moveq   #GK_OK,%d0
        movem.l (%sp),%d2/%a2-%a3
        lea     12(%sp),%sp
        rts
.Lgk_arranger_events_invalid:
        moveq   #GK_ERR_INVALID,%d0
        rts
.Lgk_arranger_events_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_post_scene_events,.-gk_arranger_post_scene_events
        .global gk_arranger_producer_prepare
        .type   gk_arranger_producer_prepare,@function
gk_arranger_producer_prepare:
        tst.l   %a0
        beq.w   .Lgk_arranger_producer_invalid
        tst.l   %a1
        beq.w   .Lgk_arranger_producer_invalid
        tst.l   %a2
        beq.w   .Lgk_arranger_producer_invalid
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d0
        beq.s   .Lgk_arranger_producer_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d0
        bne.w   .Lgk_arranger_producer_range
.Lgk_arranger_producer_owner_ok:
        .incbin "stock/0009.bin", 0, 4
        .incbin "stock/0009.bin", 4, 4
        move.l  %d0,%d7
        movea.l %a0,%a5
        movea.l %a1,%a3
        movea.l %a2,%a4
        moveq   #0,%d0
        move.b  1(%a5),%d0
        move.l  %d0,%d4
        lsr.l   #4,%d4
        andi.l  #15,%d0
        move.l  %d0,%d5
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d6
        move.b  (%a0,%d0.l),%d6
        moveq   #0,%d2
        moveq   #0,%d3
        move.b  8(%a5),%d3
        bmi.s   .Lgk_arranger_producer_scene_b
        andi.l  #0xff,%d3
        cmpi.l  #15,%d3
        bhi.w   .Lgk_arranger_producer_range_restore
        ori.l   #GK_ARRANGER_SCENE_A,%d2
.Lgk_arranger_producer_scene_b:
        moveq   #0,%d1
        move.b  9(%a5),%d1
        bmi.s   .Lgk_arranger_producer_scenes_ready
        andi.l  #0xff,%d1
        cmpi.l  #15,%d1
        bhi.w   .Lgk_arranger_producer_range_restore
        ori.l   #GK_ARRANGER_SCENE_B,%d2
.Lgk_arranger_producer_scenes_ready:
        tst.l   %d2
        beq.w   .Lgk_arranger_producer_ok
        moveq   #0,%d0
        move.b  __gk_workspace_descriptor,%d0
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_arranger_producer_different
        moveq   #0,%d0
        move.b  __gk_current_kit,%d0
        cmp.l   %d6,%d0
        bne.s   .Lgk_arranger_producer_different
        move.l  %d2,%a2
        move.l  %d6,%d0
        move.l  %d2,%d1
        move.l  %d3,%d2
        moveq   #0,%d3
        move.b  9(%a5),%d3
        andi.l  #0xff,%d3
        bsr.w   gk_arranger_active_scene_apply
        tst.l   %d0
        bmi.w   .Lgk_arranger_producer_restore
        move.l  %a2,%d0
        move.l  %d2,%d1
        move.l  %d3,%d2
        bsr.w   gk_arranger_scene_engine_publish
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_restore
        movea.l %a3,%a0
        movea.l %a4,%a1
        move.l  %a2,%d0
        bsr.w   gk_arranger_post_scene_events
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_restore
        bra.w   .Lgk_arranger_producer_ok
.Lgk_arranger_producer_different:
        move.l  %d2,%a0
        move.l  %d3,%a1
        move.l  %d1,%a2
        move.l  %d7,%d0
        move.l  %d4,%d1
        move.l  %d5,%d2
        move.l  %d6,%d3
        move.l  %a0,%d4
        move.l  %a1,%d5
        move.l  %a2,%d6
        bsr.w   gk_arranger_state_claim
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_restore
        moveq   #1,%d0
        cmp.l   GK_STOCK_SCHEDULER_STATE,%d0
        bne.s   .Lgk_arranger_producer_immediate
        move.l  %d3,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a0
        adda.l  %d0,%a0
        move.l  %d4,%d0
        move.l  %d5,%d1
        move.l  %d6,%d2
        bsr.w   gk_arranger_scene_engine_publish
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_state_fail
        movea.l %a3,%a0
        movea.l %a4,%a1
        move.l  %d4,%d0
        bsr.w   gk_arranger_post_scene_events
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_state_fail
        moveq   #GK_ARRANGER_STATE_ARMED_DEFERRED,%d0
        bsr.w   gk_arranger_state_publish
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_state_fail
        bra.w   .Lgk_arranger_producer_ok
.Lgk_arranger_producer_immediate:
        moveq   #0,%d0
        move.b  __gk_arranger_bank,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_pattern,%d1
        moveq   #0,%d2
        move.b  __gk_arranger_kit,%d2
        moveq   #0,%d3
        jsr     gk_workspace_prepare
        tst.l   %d0
        bmi.w   .Lgk_arranger_producer_state_fail
        move.b  %d0,__gk_arranger_descriptor
        move.l  %d0,%d7
        bsr.w   gk_ui_transition_prepare
        tst.l   %d0
        bmi.w   .Lgk_arranger_producer_transaction_fail
        bsr.w   gk_arranger_pending_scene_apply
        tst.l   %d0
        bmi.w   .Lgk_arranger_producer_transaction_fail
        movea.l %a0,%a5
        moveq   #0,%d0
        move.b  __gk_arranger_scene_mask,%d0
        moveq   #0,%d1
        move.b  __gk_arranger_scene_a,%d1
        moveq   #0,%d2
        move.b  __gk_arranger_scene_b,%d2
        movea.l %a5,%a0
        bsr.w   gk_arranger_scene_engine_publish
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_transaction_fail
        movea.l %a3,%a0
        movea.l %a4,%a1
        moveq   #0,%d0
        move.b  __gk_arranger_scene_mask,%d0
        bsr.w   gk_arranger_post_scene_events
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_transaction_fail
        moveq   #GK_ARRANGER_STATE_ARMED_PREPARED,%d0
        bsr.w   gk_arranger_state_publish
        tst.l   %d0
        bne.w   .Lgk_arranger_producer_transaction_fail
        bra.s   .Lgk_arranger_producer_ok
.Lgk_arranger_producer_transaction_fail:
        move.l  %d0,%d7
        bsr.w   gk_arranger_pending_scene_rollback
        tst.l   %d0
        bne.w   gk_arranger_fatal_producer_scene_rollback
        jsr     gk_workspace_abort_update
        tst.l   %d0
        bne.w   gk_arranger_fatal_producer_workspace_abort
        move.l  %d7,%d0
.Lgk_arranger_producer_state_fail:
        move.l  %d0,%d7
        bsr.w   gk_arranger_state_clear
        tst.l   %d0
        bne.w   gk_arranger_fatal_producer_state_clear
        move.l  %d7,%d0
        bra.s   .Lgk_arranger_producer_restore
.Lgk_arranger_producer_ok:
        moveq   #GK_OK,%d0
.Lgk_arranger_producer_restore:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
.Lgk_arranger_producer_range_restore:
        moveq   #GK_ERR_RANGE,%d0
        bra.s   .Lgk_arranger_producer_restore
.Lgk_arranger_producer_invalid:
        moveq   #GK_ERR_INVALID,%d0
        rts
.Lgk_arranger_producer_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_arranger_producer_prepare,.-gk_arranger_producer_prepare
        .global gk_stock_arranger_row_scene_prepare
        .type   gk_stock_arranger_row_scene_prepare,@function
gk_stock_arranger_row_scene_prepare:
        move.l  #GK_STOCK_ARRANGER_ROW_SCENE_CONTINUE,(%sp)
        lea     -48(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        moveq   #GK_ARRANGER_OWNER_ROW,%d0
        movea.l %a1,%a0
        lea     GK_STOCK_ROW_SCENE_A_EVENT,%a1
        lea     GK_STOCK_ROW_SCENE_B_EVENT,%a2
        bsr.w   gk_arranger_producer_prepare
        tst.l   %d0
        bpl.s   .Lgk_arranger_row_restore
        move.l  #GK_STOCK_ARRANGER_ROW_RETURN,%d1
        move.l  %d1,48(%sp)
        moveq   #-1,%d0
        move.l  %d0,(%sp)
.Lgk_arranger_row_restore:
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea     48(%sp),%sp
.Lgk_arranger_row_return:
        rts
        .size   gk_stock_arranger_row_scene_prepare,.-gk_stock_arranger_row_scene_prepare
        .global gk_stock_arranger_playback_scene_prepare
        .type   gk_stock_arranger_playback_scene_prepare,@function
gk_stock_arranger_playback_scene_prepare:
        move.l  #GK_STOCK_ARRANGER_PLAYBACK_SCENE_CONTINUE,(%sp)
        lea     -48(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        bsr.w   gk_arranger_playback_guard_enter
        tst.l   %d0
        bne.w   gk_arranger_fatal_playback_prepare_guard_enter
        moveq   #GK_ARRANGER_OWNER_PLAYBACK,%d0
        movea.l %a1,%a0
        lea     GK_STOCK_PLAYBACK_SCENE_A_EVENT,%a1
        lea     GK_STOCK_PLAYBACK_SCENE_B_EVENT,%a2
        bsr.w   gk_arranger_producer_prepare
        tst.l   %d0
        bpl.s   .Lgk_arranger_playback_restore
        move.l  #GK_STOCK_ARRANGER_PLAYBACK_RETURN,%d1
        move.l  %d1,48(%sp)
        moveq   #-1,%d0
        move.l  %d0,(%sp)
.Lgk_arranger_playback_restore:
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea     48(%sp),%sp
.Lgk_arranger_playback_return:
        rts
        .size   gk_stock_arranger_playback_scene_prepare,.-gk_stock_arranger_playback_scene_prepare
        .global gk_stock_arranger_playback_exit
        .type   gk_stock_arranger_playback_exit,@function
gk_stock_arranger_playback_exit:
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        bsr.w   gk_arranger_playback_guard_exit
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        beq.s   .Lgk_arranger_playback_exit_restore
        tst.l   %d0
        bne.w   gk_arranger_fatal_playback_exit_guard
.Lgk_arranger_playback_exit_restore:
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
        .incbin "stock/0010.bin", 0, 4
        .incbin "stock/0010.bin", 4, 4
        .incbin "stock/0010.bin", 8, 2
        .size   gk_stock_arranger_playback_exit,.-gk_stock_arranger_playback_exit
        .global gk_stock_pattern_schedule_enter
        .type   gk_stock_pattern_schedule_enter,@function
gk_stock_pattern_schedule_enter:
        bsr.w   gk_arranger_guard_enter
        tst.l   %d0
        bne.w   gk_arranger_fatal_pattern_schedule_guard_enter
        .incbin "stock/0011.bin", 0, 4
        .incbin "stock/0011.bin", 4, 4
        jmp     GK_STOCK_PATTERN_SCHEDULE_ENTER_CONTINUE
        .size   gk_stock_pattern_schedule_enter,.-gk_stock_pattern_schedule_enter
        .global gk_stock_pattern_schedule_queued_handoff
        .type   gk_stock_pattern_schedule_queued_handoff,@function
gk_stock_pattern_schedule_queued_handoff:
        lea     -24(%sp),%sp
        movem.l %d0-%d3/%a0-%a1,(%sp)
        move.l  44(%sp),%d0
        bsr.w   gk_arranger_publisher_owner_from_return
        tst.l   %d0
        bmi.w   gk_arranger_fatal_queued_owner
        move.l  %d0,%d3
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d0
        beq.s   .Lgk_arranger_stock_queued_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d0
        bne.s   .Lgk_arranger_stock_queued_restore
.Lgk_arranger_stock_queued_owner_ok:
        cmpi.l  #15,%d4
        bhi.w   gk_arranger_fatal_queued_bank_range
        cmpi.l  #15,%d5
        bhi.w   gk_arranger_fatal_queued_pattern_range
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        move.l  %d4,%d0
        move.l  %d5,%d1
        bsr.w   gk_arranger_queue_publish_handoff
        tst.l   %d0
        bne.w   gk_arranger_fatal_queued_publish
.Lgk_arranger_stock_queued_restore:
        movem.l (%sp),%d0-%d3/%a0-%a1
        lea     24(%sp),%sp
        .global gk_arranger_stock_queued_bank_publication
gk_arranger_stock_queued_bank_publication:
        .incbin "stock/0012.bin", 0, 6
        jmp     GK_STOCK_PATTERN_SCHEDULE_QUEUED_CONTINUE
        .size   gk_stock_pattern_schedule_queued_handoff,.-gk_stock_pattern_schedule_queued_handoff
        .global gk_stock_pattern_schedule_tail_exit
        .type   gk_stock_pattern_schedule_tail_exit,@function
gk_stock_pattern_schedule_tail_exit:
        move.l  8(%sp),-(%sp)
        move.l  8(%sp),-(%sp)
        .global gk_stock_pattern_schedule_tail_event_call
gk_stock_pattern_schedule_tail_event_call:
        jsr     GK_STOCK_EVENT_POINTER_PUSH
        .global gk_stock_pattern_schedule_tail_event_return
gk_stock_pattern_schedule_tail_event_return:
        addq.l  #8,%sp
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        bsr.w   gk_arranger_guard_exit
        tst.l   %d0
        bne.w   gk_arranger_fatal_schedule_tail_guard_exit
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
        rts
        .size   gk_stock_pattern_schedule_tail_exit,.-gk_stock_pattern_schedule_tail_exit
        .global gk_stock_pattern_notify_exit
        .type   gk_stock_pattern_notify_exit,@function
gk_stock_pattern_notify_exit:
        movem.l (%sp),%d2-%d4/%a2
        lea     16(%sp),%sp
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        move.l  16(%sp),%d0
        bsr.w   gk_arranger_publisher_owner_from_return
        tst.l   %d0
        bmi.s   .Lgk_arranger_notify_exit_restore
        bsr.w   gk_arranger_guard_exit
        tst.l   %d0
        bne.w   gk_arranger_fatal_notify_guard_exit
.Lgk_arranger_notify_exit_restore:
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
        rts
        .size   gk_stock_pattern_notify_exit,.-gk_stock_pattern_notify_exit
        .global gk_stock_pattern_schedule_abort_cleanup
        .type   gk_stock_pattern_schedule_abort_cleanup,@function
gk_stock_pattern_schedule_abort_cleanup:
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        move.l  36(%sp),%d0
        bsr.w   gk_arranger_publisher_owner_from_return
        tst.l   %d0
        bmi.w   gk_arranger_fatal_abort_owner
        move.l  %d0,%d3
        cmpi.l  #GK_ARRANGER_OWNER_ROW,%d0
        beq.s   .Lgk_arranger_stock_abort_owner_ok
        cmpi.l  #GK_ARRANGER_OWNER_PLAYBACK,%d0
        bne.s   .Lgk_arranger_stock_abort_restore_volatile
.Lgk_arranger_stock_abort_owner_ok:
        cmpi.l  #15,%d4
        bhi.s   .Lgk_arranger_stock_abort_restore_volatile
        cmpi.l  #15,%d5
        bhi.s   .Lgk_arranger_stock_abort_restore_volatile
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   %d5,%d0
        lea     __gk_pattern_assignments,%a0
        moveq   #0,%d2
        move.b  (%a0,%d0.l),%d2
        move.l  %d4,%d0
        move.l  %d5,%d1
        bsr.w   gk_arranger_abort_matching
        tst.l   %d0
        bne.w   gk_arranger_fatal_abort_matching
.Lgk_arranger_stock_abort_restore_volatile:
        bsr.w   gk_arranger_guard_exit
        tst.l   %d0
        bne.w   gk_arranger_fatal_abort_guard_exit
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
        movem.l (%sp),%d2-%d6
        lea     20(%sp),%sp
        rts
        .size   gk_stock_pattern_schedule_abort_cleanup,.-gk_stock_pattern_schedule_abort_cleanup
        .global gk_stock_pattern_queue_commit_enter
        .type   gk_stock_pattern_queue_commit_enter,@function
gk_stock_pattern_queue_commit_enter:
        lea     -40(%sp),%sp
        movem.l %d2-%d5/%a2-%fp,4(%sp)
        clr.l   (%sp)
        jsr     gk_pattern_queue_commit_guard_enter
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_arranger_queue_entry_guard_busy
        tst.l   %d0
        bpl.s   .Lgk_arranger_queue_entry_guard_status_ok
        jmp     gk_pattern_queue_commit_guard_enter_fatal
.Lgk_arranger_queue_entry_guard_status_ok:
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_entry_guard_ready
        move.l  #GK_QUEUE_COMMIT_GUARD_OWNED,(%sp)
.Lgk_arranger_queue_entry_guard_ready:
.Lgk_arranger_queue_entry_issue_token:
        bsr.w   gk_arranger_queue_token_issue
        cmpi.l  #GK_ARRANGER_NO_TOKEN,%d0
        beq.s   .Lgk_arranger_queue_entry_continue
        tst.l   %d0
        bmi.w   gk_arranger_fatal_queue_token_issue
        or.l    %d0,(%sp)
.Lgk_arranger_queue_entry_continue:
        move.l  GK_STOCK_SCHEDULER_STATE,%d0
        cmpi.l  #2,%d0
        bls.s   .Lgk_arranger_queue_entry_state_valid
        jmp     gk_pattern_queue_commit_prepare_fatal
.Lgk_arranger_queue_entry_state_valid:
        tst.l   %d0
        bne.s   .Lgk_arranger_queue_entry_prepare
.Lgk_arranger_queue_entry_state_zero:
        tst.b   __gk_sequencer_latch_queue_handoff
        bne.w   .Lgk_arranger_queue_entry_busy
.Lgk_arranger_queue_entry_marker_clear:
        move.l  GK_STOCK_SCHEDULER_CHAINED,%d0
        beq.w   .Lgk_arranger_queue_entry_unqueued
        cmpi.l  #1,%d0
        beq.s   .Lgk_arranger_queue_entry_state_zero_chain
        jmp     gk_pattern_queue_commit_prepare_fatal
.Lgk_arranger_queue_entry_state_zero_chain:
        tst.l   GK_STOCK_PATTERN_QUEUE_GATE
        bne.w   .Lgk_arranger_queue_entry_unqueued
.Lgk_arranger_queue_entry_prepare:
        jsr     gk_pattern_queue_commit_prepare
        tst.l   %d0
        beq.w   .Lgk_arranger_queue_entry_prepared
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_arranger_queue_entry_busy
        cmpi.l  #GK_ERR_OVERFLOW,%d0
        beq.s   .Lgk_arranger_queue_entry_busy
        cmpi.l  #GK_ERR_EXHAUSTED,%d0
        beq.s   .Lgk_arranger_queue_entry_busy
        jmp     gk_pattern_queue_commit_prepare_fatal
.Lgk_arranger_queue_entry_busy:
        jsr     gk_pattern_queue_commit_defer_publish
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_entry_defer_arranger
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        beq.s   .Lgk_arranger_queue_entry_cancel_vanished
        jmp     gk_pattern_queue_commit_defer_fatal
.Lgk_arranger_queue_entry_defer_arranger:
        move.l  (%sp),%d0
        andi.l  #GK_QUEUE_COMMIT_TOKEN_MASK,%d0
        bne.s   .Lgk_arranger_queue_entry_defer_token_ready
        moveq   #GK_ARRANGER_NO_TOKEN,%d0
.Lgk_arranger_queue_entry_defer_token_ready:
        bsr.w   gk_arranger_queue_token_defer
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_entry_release_guard
        jmp     gk_pattern_queue_commit_defer_fatal
.Lgk_arranger_queue_entry_cancel_vanished:
        jsr     gk_pattern_queue_commit_cancel_deferred
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_entry_cancel_arranger
        cmpi.l  #GK_ERR_BUSY,%d0
        bne.s   .Lgk_arranger_queue_entry_cancel_vanished_fatal
.Lgk_arranger_queue_entry_cancel_arranger:
        move.l  (%sp),%d0
        andi.l  #GK_QUEUE_COMMIT_TOKEN_MASK,%d0
        bne.s   .Lgk_arranger_queue_entry_cancel_token_ready
        moveq   #GK_ARRANGER_NO_TOKEN,%d0
.Lgk_arranger_queue_entry_cancel_token_ready:
        bsr.w   gk_arranger_queue_token_cleanup
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_entry_release_guard
.Lgk_arranger_queue_entry_cancel_vanished_fatal:
        jmp     gk_pattern_queue_commit_defer_fatal
.Lgk_arranger_queue_entry_release_guard:
        move.l  (%sp),%d0
        btst    #31,%d0
        beq.s   .Lgk_arranger_queue_entry_return
        bsr.w   gk_arranger_guard_exit
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_entry_return
        jmp     gk_pattern_queue_commit_guard_exit_fatal
.Lgk_arranger_queue_entry_guard_busy:
        jsr     gk_pattern_queue_commit_defer_publish
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_entry_return
        cmpi.l  #GK_ARRANGER_NOT_HANDLED,%d0
        beq.s   .Lgk_arranger_queue_entry_return
        jmp     gk_pattern_queue_commit_defer_fatal
.Lgk_arranger_queue_entry_return:
        movem.l 4(%sp),%d2-%d5/%a2-%fp
        lea     40(%sp),%sp
        rts
.Lgk_arranger_queue_entry_unqueued:
        jsr     gk_pattern_queue_commit_cancel_deferred
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_entry_prepared
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.w   .Lgk_arranger_queue_entry_release_guard
        jmp     gk_pattern_queue_commit_defer_fatal
.Lgk_arranger_queue_entry_prepared:
        jmp     GK_STOCK_PATTERN_QUEUE_COMMIT_CONTINUE
        .size   gk_stock_pattern_queue_commit_enter,.-gk_stock_pattern_queue_commit_enter
        .global gk_stock_pattern_queue_commit_exit
        .type   gk_stock_pattern_queue_commit_exit,@function
gk_stock_pattern_queue_commit_exit:
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        jsr     gk_pattern_queue_commit_prepared_finish
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_exit_prepared_finished
        jmp     gk_pattern_queue_commit_finish_fatal
.Lgk_arranger_queue_exit_prepared_finished:
        move.l  16(%sp),%d0
        andi.l  #GK_QUEUE_COMMIT_TOKEN_MASK,%d0
        bne.s   .Lgk_arranger_queue_exit_token_ready
        moveq   #GK_ARRANGER_NO_TOKEN,%d0
.Lgk_arranger_queue_exit_token_ready:
        bsr.w   gk_arranger_queue_token_cleanup
        tst.l   %d0
        bne.s   gk_arranger_fatal_queue_token_cleanup
        tst.b   __gk_sequencer_latch_queue_handoff
        beq.s   .Lgk_arranger_queue_exit_marker_clear
        moveq   #GK_PATTERN_QUEUE_PREPARED_BASE + 1,%d0
        cmp.b   __gk_pattern_queue_commit_prepared,%d0
        beq.s   .Lgk_arranger_queue_exit_prepared_clear
        jmp     gk_pattern_queue_commit_exit_fatal
.Lgk_arranger_queue_exit_marker_clear:
        tst.b   __gk_pattern_queue_commit_prepared
        beq.s   .Lgk_arranger_queue_exit_prepared_clear
        jmp     gk_pattern_queue_commit_exit_fatal
.Lgk_arranger_queue_exit_prepared_clear:
        jsr     gk_sequencer_latch_queue_handoff_refresh
        tst.b   __gk_pattern_queue_commit_prepared
        bne.s   .Lgk_arranger_queue_exit_state_fatal
        tst.b   __gk_sequencer_latch_queue_handoff
        beq.s   .Lgk_arranger_queue_exit_state_clear
.Lgk_arranger_queue_exit_state_fatal:
        jmp     gk_pattern_queue_commit_exit_fatal
.Lgk_arranger_queue_exit_state_clear:
        move.l  16(%sp),%d0
        btst    #31,%d0
        beq.s   .Lgk_arranger_queue_exit_guard_released
        jsr     gk_arranger_guard_exit
        tst.l   %d0
        beq.s   .Lgk_arranger_queue_exit_guard_released
        jmp     gk_pattern_queue_commit_guard_exit_fatal
.Lgk_arranger_queue_exit_guard_released:
        movem.l 20(%sp),%d2-%d5/%a2-%fp
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     56(%sp),%sp
        rts
        .size   gk_stock_pattern_queue_commit_exit,.-gk_stock_pattern_queue_commit_exit
        .global gk_arranger_transition_fatal
gk_arranger_transition_fatal:
        illegal
        bra.w   gk_arranger_transition_fatal
        .global gk_arranger_fatal_queue_token_cleanup
gk_arranger_fatal_queue_token_cleanup:
        illegal
        bra.s gk_arranger_fatal_queue_token_cleanup
        .global gk_arranger_fatal_playback_guard_enter_cleanup
gk_arranger_fatal_playback_guard_enter_cleanup:
        illegal
        bra.s gk_arranger_fatal_playback_guard_enter_cleanup
        .global gk_arranger_fatal_active_scene_release
gk_arranger_fatal_active_scene_release:
        illegal
        bra.s gk_arranger_fatal_active_scene_release
        .global gk_arranger_fatal_active_scene_rollback_a
gk_arranger_fatal_active_scene_rollback_a:
        illegal
        bra.s gk_arranger_fatal_active_scene_rollback_a
        .global gk_arranger_fatal_active_scene_rollback_b
gk_arranger_fatal_active_scene_rollback_b:
        illegal
        bra.s gk_arranger_fatal_active_scene_rollback_b
        .global gk_arranger_fatal_active_scene_rollback_terminal
gk_arranger_fatal_active_scene_rollback_terminal:
        illegal
        bra.s gk_arranger_fatal_active_scene_rollback_terminal
        .global gk_arranger_fatal_active_scene_corrupt_release
gk_arranger_fatal_active_scene_corrupt_release:
        illegal
        bra.s gk_arranger_fatal_active_scene_corrupt_release
        .global gk_arranger_fatal_transition_adopt_abort
gk_arranger_fatal_transition_adopt_abort:
        illegal
        bra.s gk_arranger_fatal_transition_adopt_abort
        .global gk_arranger_fatal_producer_scene_rollback
gk_arranger_fatal_producer_scene_rollback:
        illegal
        bra.s gk_arranger_fatal_producer_scene_rollback
        .global gk_arranger_fatal_producer_workspace_abort
gk_arranger_fatal_producer_workspace_abort:
        illegal
        bra.s gk_arranger_fatal_producer_workspace_abort
        .global gk_arranger_fatal_producer_state_clear
gk_arranger_fatal_producer_state_clear:
        illegal
        bra.s gk_arranger_fatal_producer_state_clear
        .global gk_arranger_fatal_playback_prepare_guard_enter
gk_arranger_fatal_playback_prepare_guard_enter:
        illegal
        bra.s gk_arranger_fatal_playback_prepare_guard_enter
        .global gk_arranger_fatal_playback_exit_guard
gk_arranger_fatal_playback_exit_guard:
        illegal
        bra.s gk_arranger_fatal_playback_exit_guard
        .global gk_arranger_fatal_pattern_schedule_guard_enter
gk_arranger_fatal_pattern_schedule_guard_enter:
        illegal
        bra.s gk_arranger_fatal_pattern_schedule_guard_enter
        .global gk_arranger_fatal_queued_owner
gk_arranger_fatal_queued_owner:
        illegal
        bra.s gk_arranger_fatal_queued_owner
        .global gk_arranger_fatal_queued_bank_range
gk_arranger_fatal_queued_bank_range:
        illegal
        bra.s gk_arranger_fatal_queued_bank_range
        .global gk_arranger_fatal_queued_pattern_range
gk_arranger_fatal_queued_pattern_range:
        illegal
        bra.s gk_arranger_fatal_queued_pattern_range
        .global gk_arranger_fatal_queued_publish
gk_arranger_fatal_queued_publish:
        illegal
        bra.s gk_arranger_fatal_queued_publish
        .global gk_arranger_fatal_schedule_tail_guard_exit
gk_arranger_fatal_schedule_tail_guard_exit:
        illegal
        bra.s gk_arranger_fatal_schedule_tail_guard_exit
        .global gk_arranger_fatal_notify_guard_exit
gk_arranger_fatal_notify_guard_exit:
        illegal
        bra.s gk_arranger_fatal_notify_guard_exit
        .global gk_arranger_fatal_abort_owner
gk_arranger_fatal_abort_owner:
        illegal
        bra.s gk_arranger_fatal_abort_owner
        .global gk_arranger_fatal_abort_matching
gk_arranger_fatal_abort_matching:
        illegal
        bra.s gk_arranger_fatal_abort_matching
        .global gk_arranger_fatal_abort_guard_exit
gk_arranger_fatal_abort_guard_exit:
        illegal
        bra.s gk_arranger_fatal_abort_guard_exit
        .global gk_arranger_fatal_queue_token_issue
gk_arranger_fatal_queue_token_issue:
        illegal
        bra.s gk_arranger_fatal_queue_token_issue
        .global gk_arranger_fatal_pattern_publish_owner
gk_arranger_fatal_pattern_publish_owner:
        illegal
        bra.s gk_arranger_fatal_pattern_publish_owner
