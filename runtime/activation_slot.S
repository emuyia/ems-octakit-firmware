        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_stage_canonical_activation_release
        .type   gk_stage_canonical_activation_release,@function
gk_stage_canonical_activation_release:
        move.l  %d3,-(%sp)
        move.l  %a0,-(%sp)
        move.l  __gk_workspace_descriptor,%d3
        cmpi.l  #-1,%d3
        bne.s   .Lgk_activation_slot_stage
        moveq   #0,%d3
        move.b  GK_STOCK_CURRENT_PART_PRIMARY,%d3
        cmpi.l  #3,%d3
        bhi.s   .Lgk_activation_slot_corrupt
        lea     __gk_physical_victim_cursors,%a0
        move.b  %d3,(%a0,%d0.l)
.Lgk_activation_slot_stage:
        movea.l (%sp)+,%a0
        move.l  (%sp)+,%d3
        jmp     gk_stage_canonical
.Lgk_activation_slot_corrupt:
        movea.l (%sp)+,%a0
        move.l  (%sp)+,%d3
        moveq   #GK_ERR_CORRUPT,%d0
        rts
        .size   gk_stage_canonical_activation_release,.-gk_stage_canonical_activation_release
