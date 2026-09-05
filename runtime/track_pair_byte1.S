        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stock_track_pair_byte1
        .type   gk_stock_track_pair_byte1,@function
gk_stock_track_pair_byte1:
        lea     gk_track_pair_byte0_d3_old_pc_guard+0x08000000,%a0
        move.l  (%a0),%d0
        cmpi.l  #0x4e714e71,%d0
        bne.w   gk_track_pair_byte1_fatal_runtime_image
        move.l  4(%sp),%d0
        cmpi.l  #6,%d0
        bne.w   gk_track_pair_byte1_fatal_entry_id
        move.l  8(%sp),%d0
        move.l  %d0,%d1
        andi.l  #0xffffff00,%d1
        btst    #7,%d0
        bne.s   .Lgk_track_pair_byte1_delta_negative
        tst.l   %d1
        bne.w   gk_track_pair_byte1_fatal_entry_delta
        bra.s   .Lgk_track_pair_byte1_delta_ok
.Lgk_track_pair_byte1_delta_negative:
        cmpi.l  #0xffffff00,%d1
        bne.w   gk_track_pair_byte1_fatal_entry_delta
.Lgk_track_pair_byte1_delta_ok:
        move.l  __gk_lifecycle_state,%d0
        tst.l   %d0
        beq.s   .Lgk_track_pair_byte1_lifecycle_active
        cmpi.l  #GK_LIFECYCLE_QUIESCED,%d0
        beq.w   .Lgk_track_pair_byte1_busy_early
        bra.w   gk_track_pair_byte1_fatal_entry_lifecycle
.Lgk_track_pair_byte1_lifecycle_active:
        .incbin "stock/0362.bin", 0, 4
        .incbin "stock/0362.bin", 4, 4
        moveq   #0,%d0
        move.b  GK_STOCK_CURRENT_TRACK_PRIMARY,%d0
        jsr     gk_track_pair_byte0_prepare
        cmpi.l  #GK_ERR_BUSY,%d0
        beq.s   .Lgk_track_pair_byte1_busy_saved
        tst.l   %d0
        bne.w   gk_track_pair_byte1_fatal_entry_lifecycle
        move.l  52(%sp),%d0
        move.l  56(%sp),%d1
        move.l  %d7,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        move.l  #GK_STOCK_TRACK_PAIR_BYTE1,%d0
        moveq   #6,%d1
        lea     GK_STOCK_TRACK_PAIR_BYTE1_REGISTRY,%a0
        movea.l %d0,%a1
        .global gk_track_pair_byte1_stock_call
gk_track_pair_byte1_stock_call:
        jsr     GK_STOCK_TRACK_PAIR_BYTE1
        move.l  %d0,56(%sp)
        move.l  8(%sp),%d0
        lea     12(%sp),%sp
        jsr     gk_track_pair_byte0_finish
        move.l  44(%sp),%d0
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts
.Lgk_track_pair_byte1_busy_saved:
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     48(%sp),%sp
.Lgk_track_pair_byte1_busy_early:
        moveq   #0,%d0
        rts
        .size   gk_stock_track_pair_byte1,.-gk_stock_track_pair_byte1
        .global gk_track_pair_byte1_write_marker
        .type   gk_track_pair_byte1_write_marker,@function
gk_track_pair_byte1_write_marker:
        move.l  %d0,-(%sp)
        cmpi.l  #1,%d1
        bne.w   gk_track_pair_byte1_fatal_marker_dirty
        move.l  4(%sp),%d0
        cmpi.l  #GK_STOCK_TRACK_PAIR_BYTE1_DIRTY_RETURN,%d0
        bne.w   gk_track_pair_byte1_fatal_marker_return
        move.l  36(%sp),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_STATE_MASK,%d0
        cmpi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_ARMED,%d0
        bne.w   gk_track_pair_byte1_fatal_marker_token
        move.l  36(%sp),%d0
        andi.l  #GK_TRACK_PAIR_BYTE0_TOKEN_CONTEXT_MASK,%d0
        ori.l   #GK_TRACK_PAIR_BYTE0_TOKEN_WRITTEN,%d0
        move.l  %d0,36(%sp)
        move.l  (%sp)+,%d0
        .global gk_track_pair_byte1_stock_dirty_store
gk_track_pair_byte1_stock_dirty_store:
        .incbin "stock/0363.bin", 0, 6
        rts
        .size   gk_track_pair_byte1_write_marker,.-gk_track_pair_byte1_write_marker
        .global gk_track_pair_byte1_fatal_runtime_image
        .type gk_track_pair_byte1_fatal_runtime_image,@function
gk_track_pair_byte1_fatal_runtime_image:
        illegal
        bra.s gk_track_pair_byte1_fatal_runtime_image
        .size gk_track_pair_byte1_fatal_runtime_image,.-gk_track_pair_byte1_fatal_runtime_image
        .global gk_track_pair_byte1_fatal_entry_id
        .type gk_track_pair_byte1_fatal_entry_id,@function
gk_track_pair_byte1_fatal_entry_id:
        illegal
        bra.s gk_track_pair_byte1_fatal_entry_id
        .size gk_track_pair_byte1_fatal_entry_id,.-gk_track_pair_byte1_fatal_entry_id
        .global gk_track_pair_byte1_fatal_entry_delta
        .type gk_track_pair_byte1_fatal_entry_delta,@function
gk_track_pair_byte1_fatal_entry_delta:
        illegal
        bra.s gk_track_pair_byte1_fatal_entry_delta
        .size gk_track_pair_byte1_fatal_entry_delta,.-gk_track_pair_byte1_fatal_entry_delta
        .global gk_track_pair_byte1_fatal_entry_lifecycle
        .type gk_track_pair_byte1_fatal_entry_lifecycle,@function
gk_track_pair_byte1_fatal_entry_lifecycle:
        illegal
        bra.s gk_track_pair_byte1_fatal_entry_lifecycle
        .size gk_track_pair_byte1_fatal_entry_lifecycle,.-gk_track_pair_byte1_fatal_entry_lifecycle
        .global gk_track_pair_byte1_fatal_marker_dirty
        .type gk_track_pair_byte1_fatal_marker_dirty,@function
gk_track_pair_byte1_fatal_marker_dirty:
        illegal
        bra.s gk_track_pair_byte1_fatal_marker_dirty
        .size gk_track_pair_byte1_fatal_marker_dirty,.-gk_track_pair_byte1_fatal_marker_dirty
        .global gk_track_pair_byte1_fatal_marker_return
        .type gk_track_pair_byte1_fatal_marker_return,@function
gk_track_pair_byte1_fatal_marker_return:
        illegal
        bra.s gk_track_pair_byte1_fatal_marker_return
        .size gk_track_pair_byte1_fatal_marker_return,.-gk_track_pair_byte1_fatal_marker_return
        .global gk_track_pair_byte1_fatal_marker_token
        .type gk_track_pair_byte1_fatal_marker_token,@function
gk_track_pair_byte1_fatal_marker_token:
        illegal
        bra.s gk_track_pair_byte1_fatal_marker_token
        .size gk_track_pair_byte1_fatal_marker_token,.-gk_track_pair_byte1_fatal_marker_token
