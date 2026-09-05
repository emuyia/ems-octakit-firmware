        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_descriptor_begin_clone
        .type   gk_descriptor_begin_clone,@function
gk_descriptor_begin_clone:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_clone_begin_range
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_clone_begin_range
        lea     -32(%sp),%sp
        movem.l %d2-%d6/%a2-%a4,(%sp)
        move.l  %d0,%d2
        move.l  %d1,%d3
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        move.w  %sr,%d6
        move.w  #0x2700,%sr
        moveq   #0,%d4
        move.b  GK_DESC_FLAGS(%a2),%d4
        btst    #0,%d4
        beq.w   .Lgk_clone_begin_corrupt
        move.l  %d4,%d0
        andi.l  #0xc0,%d0
        bne.w   .Lgk_clone_begin_corrupt
        btst    #1,%d4
        bne.w   .Lgk_clone_begin_busy
        btst    #2,%d4
        bne.w   .Lgk_clone_begin_corrupt
        btst    #5,%d4
        bne.w   .Lgk_clone_begin_corrupt
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_clone_begin_corrupt
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_clone_begin_busy
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_clone_begin_busy
        moveq   #0,%d4
        move.b  GK_DESC_PHYSICAL(%a2),%d4
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d4
        bhi.w   .Lgk_clone_begin_corrupt
        cmp.l   %d3,%d4
        beq.w   .Lgk_clone_begin_range_restore
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_clone_begin_corrupt
        move.l  %d4,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.w   .Lgk_clone_begin_corrupt
        move.l %d4,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a3
        adda.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a3),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_clone_begin_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a3),%d0
        moveq   #0,%d5
        move.b  GK_DESC_KIT(%a2),%d5
        cmp.l   %d5,%d0
        bne.w   .Lgk_clone_begin_corrupt
        tst.b   GK_PHYS_STATE(%a3)
        bne.w   .Lgk_clone_begin_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a3),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_clone_begin_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a4
        adda.l %d0,%a4
        move.l  (%a4),%d0
        cmpi.l  #-1,%d0
        beq.s   .Lgk_clone_begin_target_free
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a4),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.w   .Lgk_clone_begin_corrupt
        bra.w   .Lgk_clone_begin_busy
.Lgk_clone_begin_target_free:
        move.l  %d3,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        move.l  %a0,GK_DESC_CANDIDATE(%a2)
        move.b  %d3,GK_DESC_SPILL(%a2)
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        ori.l   #GK_DESC_CLONE_COPY,%d0
        move.b  %d0,GK_DESC_FLAGS(%a2)
        move.l  %d3,%d1
        moveq   #GK_OK,%d0
        bra.s   .Lgk_clone_begin_restore
.Lgk_clone_begin_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_clone_begin_restore
.Lgk_clone_begin_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_clone_begin_restore
.Lgk_clone_begin_range_restore:
        moveq   #GK_ERR_RANGE,%d0
.Lgk_clone_begin_restore:
        move.w  %d6,%sr
        movem.l (%sp),%d2-%d6/%a2-%a4
        lea     32(%sp),%sp
        rts
.Lgk_clone_begin_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_begin_clone,.-gk_descriptor_begin_clone
        .global gk_descriptor_finish_clone
        .type   gk_descriptor_finish_clone,@function
gk_descriptor_finish_clone:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_clone_finish_range
        .incbin "stock/0054.bin", 0, 4
        .incbin "stock/0054.bin", 4, 4
        move.l  %d0,%d2
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        move.w  %sr,%d7
        move.w  #0x2700,%sr
        moveq   #0,%d5
        move.b  GK_DESC_FLAGS(%a2),%d5
        btst    #0,%d5
        beq.w   .Lgk_clone_finish_corrupt
        move.l  %d5,%d0
        andi.l  #0xc0,%d0
        bne.w   .Lgk_clone_finish_corrupt
        btst    #1,%d5
        beq.w   .Lgk_clone_finish_busy
        btst    #5,%d5
        beq.w   .Lgk_clone_finish_corrupt
        btst    #2,%d5
        bne.w   .Lgk_clone_finish_corrupt
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a2),%d3
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d4
        move.b  GK_DESC_SPILL(%a2),%d4
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d4
        bhi.w   .Lgk_clone_finish_corrupt
        cmp.l   %d3,%d4
        beq.w   .Lgk_clone_finish_corrupt
        move.l  %d3,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.w   .Lgk_clone_finish_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a3
        adda.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a3),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d6
        move.b  GK_DESC_KIT(%a2),%d6
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a3),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_clone_finish_corrupt
        tst.b   GK_PHYS_STATE(%a3)
        bne.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a3),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_clone_finish_corrupt
        move.l  %d4,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_CANDIDATE(%a2),%a0
        bne.w   .Lgk_clone_finish_corrupt
        move.l %d4,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a4
        adda.l %d0,%a4
        move.l  (%a4),%d0
        cmpi.l  #-1,%d0
        beq.w   .Lgk_clone_finish_busy
        moveq   #0,%d1
        move.b  GK_PHYS_OWNER(%a4),%d1
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a4),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_clone_finish_corrupt
        tst.b   GK_PHYS_STATE(%a4)
        bne.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a4),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_clone_finish_corrupt
        move.l %d1,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a5
        adda.l %d0,%a5
        cmpa.l  GK_DESC_PAYLOAD(%a5),%a0
        bne.w   .Lgk_clone_finish_corrupt
        tst.l   GK_DESC_CANDIDATE(%a5)
        bne.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a5),%d0
        cmpi.l  #1,%d0
        beq.s   .Lgk_clone_finish_roots_valid
        cmpi.l  #2,%d0
        bne.w   .Lgk_clone_finish_corrupt
        move.l  %d2,%d0
        lsl.l   #8,%d0
        or.l    %d1,%d0
        moveq   #0,%d3
        move.w  __gk_lease_sidecars,%d3
        cmp.l   %d3,%d0
        bne.w   .Lgk_clone_finish_corrupt
.Lgk_clone_finish_roots_valid:
        tst.w   GK_DESC_READERS(%a5)
        bne.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a5),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a5),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a5),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a5),%d0
        cmpi.l  #GK_DESC_VALID,%d0
        bne.w   .Lgk_clone_finish_corrupt
        move.l  %d1,%d0
        lsr.l   #3,%d0
        move.l  %d1,%d3
        andi.l  #7,%d3
        lea     __gk_descriptor_bitmap,%a3
        btst    %d3,(%a3,%d0.l)
        beq.w   .Lgk_clone_finish_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_READERS(%a2),%d0
        cmpi.l  #0,%d0
        beq.s   .Lgk_clone_finish_readers_valid
        cmpi.l  #1,%d0
        bne.w   .Lgk_clone_finish_busy
        move.l  %d2,%d0
        jsr     gk_pattern_queue_clone_reader_validate
        tst.l   %d0
        bne.w   .Lgk_clone_finish_busy
.Lgk_clone_finish_readers_valid:
        .global gk_descriptor_clone_publication
gk_descriptor_clone_publication:
        clr.l   GK_DESC_CANDIDATE(%a2)
        move.b  #GK_ID_NONE,GK_DESC_SPILL(%a2)
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        andi.l  #0xdd,%d0
        move.b  %d0,GK_DESC_FLAGS(%a2)
        btst    #4,%d5
        beq.s   .Lgk_clone_finish_clean
        move.b  #GK_DESC_VALID_DIRTY,GK_DESC_FLAGS(%a5)
.Lgk_clone_finish_clean:
        move.l  GK_DESC_PAYLOAD(%a5),%a0
        moveq   #GK_OK,%d0
        bra.s   .Lgk_clone_finish_restore
.Lgk_clone_finish_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_clone_finish_restore
.Lgk_clone_finish_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_clone_finish_restore:
        move.w  %d7,%sr
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
.Lgk_clone_finish_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_finish_clone,.-gk_descriptor_finish_clone
        .global gk_descriptor_abort_clone
        .type   gk_descriptor_abort_clone,@function
gk_descriptor_abort_clone:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_clone_abort_range
        .incbin "stock/0055.bin", 0, 4
        .incbin "stock/0055.bin", 4, 4
        move.l  %d0,%d2
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        btst    #0,%d0
        beq.w   .Lgk_clone_abort_corrupt
        btst    #1,%d0
        beq.w   .Lgk_clone_abort_busy
        btst    #5,%d0
        beq.w   .Lgk_clone_abort_corrupt
        move.l  %d0,%d3
        andi.l  #0xc4,%d3
        bne.w   .Lgk_clone_abort_corrupt
        tst.w   GK_DESC_READERS(%a2)
        bne.w   .Lgk_clone_abort_busy
        moveq   #0,%d3
        move.b  GK_DESC_SPILL(%a2),%d3
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w   .Lgk_clone_abort_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a0
        adda.l %d0,%a0
        move.l  (%a0),%d0
        cmpi.l  #-1,%d0
        bne.w   .Lgk_clone_abort_busy
        move.l  %d3,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_CANDIDATE(%a2),%a0
        bne.w   .Lgk_clone_abort_corrupt
        clr.l   GK_DESC_CANDIDATE(%a2)
        move.b  #GK_ID_NONE,GK_DESC_SPILL(%a2)
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        andi.l  #0xdd,%d0
        move.b  %d0,GK_DESC_FLAGS(%a2)
        move.l  %d3,%d1
        moveq   #GK_OK,%d0
        bra.s   .Lgk_clone_abort_restore
.Lgk_clone_abort_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_clone_abort_restore
.Lgk_clone_abort_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_clone_abort_restore:
        move.w  %d4,%sr
        .incbin "stock/0056.bin", 0, 4
        .incbin "stock/0056.bin", 4, 4
        .incbin "stock/0056.bin", 8, 2
.Lgk_clone_abort_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_abort_clone,.-gk_descriptor_abort_clone
