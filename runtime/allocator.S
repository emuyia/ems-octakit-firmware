        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_descriptor_retain_root
        .type   gk_descriptor_retain_root,@function
gk_descriptor_retain_root:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_retain_root_range
        move.l %d0,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a1
        adda.l %d1,%a1
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_retain_root_corrupt
        tst.l   GK_DESC_PAYLOAD(%a1)
        beq.s   .Lgk_retain_root_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a1),%d0
        cmpi.l  #0xffff,%d0
        beq.s   .Lgk_retain_root_overflow
        addq.l  #1,%d0
        move.w  %d0,GK_DESC_ROOTS(%a1)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_retain_root_restore
.Lgk_retain_root_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_retain_root_restore
.Lgk_retain_root_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
.Lgk_retain_root_restore:
        move.w  %d1,%sr
        rts
.Lgk_retain_root_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_retain_root,.-gk_descriptor_retain_root
        .global gk_descriptor_release_root
        .type   gk_descriptor_release_root,@function
gk_descriptor_release_root:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.s   .Lgk_release_root_range
        move.l %d0,%d1
        andi.l #0xff,%d1
        lsl.l #4,%d1
        lea __gk_descriptors,%a1
        adda.l %d1,%a1
        move.w  %sr,%d1
        move.w  #0x2700,%sr
        btst    #0,GK_DESC_FLAGS(%a1)
        beq.s   .Lgk_release_root_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a1),%d0
        tst.l   %d0
        beq.s   .Lgk_release_root_underflow
        subq.l  #1,%d0
        move.w  %d0,GK_DESC_ROOTS(%a1)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_release_root_restore
.Lgk_release_root_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_release_root_restore
.Lgk_release_root_underflow:
        moveq   #GK_ERR_UNDERFLOW,%d0
.Lgk_release_root_restore:
        move.w  %d1,%sr
        rts
.Lgk_release_root_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_release_root,.-gk_descriptor_release_root
        .global gk_descriptor_allocate_physical
        .type   gk_descriptor_allocate_physical,@function
gk_descriptor_allocate_physical:
        cmpi.l  #0xff,%d0
        bhi.w   .Lgk_alloc_physical_range
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_alloc_physical_range
        .incbin "stock/0000.bin", 0, 4
        .incbin "stock/0000.bin", 4, 4
        move.l  %d0,%d2
        move.l  %d1,%d3
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a2
        adda.l %d0,%a2
        move.l  (%a2),%d0
        cmpi.l  #-1,%d0
        beq.s   .Lgk_alloc_scan
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        beq.w   .Lgk_alloc_physical_corrupt
        moveq   #GK_ERR_BUSY,%d0
        bra.w   .Lgk_alloc_physical_restore
.Lgk_alloc_scan:
        lea     __gk_descriptor_bitmap,%a3
        moveq   #0,%d4
.Lgk_alloc_scan_loop:
        move.l  %d4,%d5
        lsr.l   #3,%d5
        moveq   #0,%d6
        move.b  (%a3,%d5.l),%d6
        move.l  %d4,%d5
        andi.l  #7,%d5
        btst    %d5,%d6
        beq.s   .Lgk_alloc_found
        addq.l  #1,%d4
        cmpi.l  #GK_DESCRIPTOR_COUNT,%d4
        blo.s   .Lgk_alloc_scan_loop
        moveq   #GK_ERR_EXHAUSTED,%d0
        bra.w   .Lgk_alloc_physical_restore
.Lgk_alloc_found:
        move.l %d4,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a4
        adda.l %d0,%a4
        move.l  (%a4),%d0
        or.l    4(%a4),%d0
        or.l    8(%a4),%d0
        or.l    12(%a4),%d0
        bne.w   .Lgk_alloc_physical_corrupt
        lea     __gk_lease_sidecars,%a0
        move.l  #GK_LEASE_SIDECAR_BYTES + GK_COHERENCE_COUNT,%d5
.Lgk_alloc_reference_scan:
        moveq   #0,%d6
        move.b  (%a0)+,%d6
        cmp.l   %d4,%d6
        beq.w   .Lgk_alloc_physical_corrupt
        subq.l  #1,%d5
        bne.s   .Lgk_alloc_reference_scan
        move.l  %d4,%d5
        lsr.l   #3,%d5
        move.l  %d4,%d6
        andi.l  #7,%d6
        bset    %d6,(%a3,%d5.l)
        move.l  %d3,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        move.l  %a0,GK_DESC_PAYLOAD(%a4)
        clr.l   GK_DESC_CANDIDATE(%a4)
        move.l  #0x00010000,%d0
        move.l  %d0,GK_DESC_ROOTS(%a4)
        move.b  %d2,GK_DESC_KIT(%a4)
        move.b  %d3,GK_DESC_PHYSICAL(%a4)
        move.b  #GK_ID_NONE,GK_DESC_SPILL(%a4)
        move.b  #GK_DESC_VALID,GK_DESC_FLAGS(%a4)
        move.b  %d4,GK_PHYS_OWNER(%a2)
        move.b  %d2,GK_PHYS_KIT(%a2)
        clr.b   GK_PHYS_STATE(%a2)
        move.b  #GK_ID_NONE,GK_PHYS_RESERVED(%a2)
        move.l  %d4,%d0
        bra.s   .Lgk_alloc_physical_restore
.Lgk_alloc_physical_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_alloc_physical_restore:
        .incbin "stock/0001.bin", 0, 4
        .incbin "stock/0001.bin", 4, 4
        rts
.Lgk_alloc_physical_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_allocate_physical,.-gk_descriptor_allocate_physical
        .global gk_descriptor_reap
        .type   gk_descriptor_reap,@function
gk_descriptor_reap:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_reap_range
        .incbin "stock/0002.bin", 0, 4
        .incbin "stock/0002.bin", 4, 4
        move.l  %d0,%d2
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d6
        lea     __gk_lease_sidecars,%a0
        move.l  #GK_LEASE_SIDECAR_BYTES,%d0
.Lgk_reap_lease_prescan:
        moveq   #0,%d5
        move.b  (%a0)+,%d5
        cmp.l   %d2,%d5
        beq.s   .Lgk_reap_lease_seen
        subq.l  #1,%d0
        bne.s   .Lgk_reap_lease_prescan
        bra.s   .Lgk_reap_lease_prescan_done
.Lgk_reap_lease_seen:
        moveq   #1,%d6
.Lgk_reap_lease_prescan_done:
        .global gk_descriptor_reap_prescan_complete
gk_descriptor_reap_prescan_complete:
        move.w  %sr,%d7
        move.w  #0x2700,%sr
        move.l  %d2,%d3
        lsr.l   #3,%d3
        move.l  %d2,%d4
        andi.l  #7,%d4
        lea     __gk_descriptor_bitmap,%a3
        btst    %d4,(%a3,%d3.l)
        beq.w   .Lgk_reap_corrupt
        moveq   #0,%d5
        move.b  GK_DESC_FLAGS(%a2),%d5
        btst    #0,%d5
        beq.w   .Lgk_reap_corrupt
        move.l  %d5,%d0
        andi.l  #0x80,%d0
        bne.w   .Lgk_reap_corrupt
        btst    #1,%d5
        bne.w   .Lgk_reap_busy
        btst    #5,%d5
        bne.w   .Lgk_reap_corrupt
        btst    #6,%d5
        bne.w   .Lgk_reap_corrupt
        btst    #3,%d5
        bne.w   .Lgk_reap_busy
        tst.w   GK_DESC_ROOTS(%a2)
        bne.w   .Lgk_reap_busy
        tst.l   %d6
        beq.s   .Lgk_reap_lease_clear
        lea     __gk_lease_sidecars,%a0
        move.l  #GK_LEASE_SIDECAR_BYTES,%d0
.Lgk_reap_lease_rescan:
        moveq   #0,%d1
        move.b  (%a0)+,%d1
        cmp.l   %d2,%d1
        beq.w   .Lgk_reap_corrupt
        subq.l  #1,%d0
        bne.s   .Lgk_reap_lease_rescan
.Lgk_reap_lease_clear:
        tst.w   GK_DESC_READERS(%a2)
        bne.w   .Lgk_reap_busy
        tst.l   GK_DESC_CANDIDATE(%a2)
        bne.w   .Lgk_reap_corrupt
        tst.l   GK_DESC_PAYLOAD(%a2)
        beq.w   .Lgk_reap_corrupt
        moveq   #0,%d6
        move.b  GK_DESC_KIT(%a2),%d6
        moveq   #-1,%d1
        andi.l  #0xff,%d1
        btst    #2,%d5
        bne.w   .Lgk_reap_validate_spill
        moveq   #0,%d1
        move.b  GK_DESC_PHYSICAL(%a2),%d1
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d1
        bhi.w   .Lgk_reap_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_reap_corrupt
        move.l  %d1,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.w   .Lgk_reap_corrupt
        move.l %d1,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a4
        adda.l %d0,%a4
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a4),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_reap_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a4),%d0
        cmp.l   %d6,%d0
        bne.w   .Lgk_reap_corrupt
        tst.b   GK_PHYS_STATE(%a4)
        bne.w   .Lgk_reap_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a4),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_reap_corrupt
        bra.w   .Lgk_reap_validated
.Lgk_reap_validate_spill:
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_reap_corrupt
        moveq   #0,%d3
        move.b  GK_DESC_SPILL(%a2),%d3
        cmpi.l  #GK_SPILL_ALLOC_COUNT - 1,%d3
        bhi.w   .Lgk_reap_corrupt
        move.l  %d3,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_spill_payloads,%a0
        adda.l  %d0,%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.w   .Lgk_reap_corrupt
        move.l  %d3,%d4
        andi.l  #7,%d4
        lsr.l   #3,%d3
        lea     __gk_spill_bitmap,%a4
        btst    %d4,(%a4,%d3.l)
        beq.w   .Lgk_reap_corrupt
.Lgk_reap_validated:
        lea     __gk_coherence_sidecars,%a0
        moveq   #GK_COHERENCE_COUNT,%d0
.Lgk_reap_coherence_loop:
        moveq   #0,%d5
        move.b  (%a0),%d5
        cmp.l   %d2,%d5
        bne.s   .Lgk_reap_coherence_next
        move.b  #GK_ID_NONE,(%a0)
.Lgk_reap_coherence_next:
        addq.l  #1,%a0
        subq.l  #1,%d0
        bne.s   .Lgk_reap_coherence_loop
        cmpi.l  #GK_ID_NONE,%d1
        beq.s   .Lgk_reap_release_spill
        moveq   #-1,%d0
        move.l  %d0,(%a4)
        bra.s   .Lgk_reap_release_descriptor
.Lgk_reap_release_spill:
        bclr    %d4,(%a4,%d3.l)
.Lgk_reap_release_descriptor:
        move.l  %d2,%d3
        lsr.l   #3,%d3
        move.l  %d2,%d4
        andi.l  #7,%d4
        lea     __gk_descriptor_bitmap,%a3
        bclr    %d4,(%a3,%d3.l)
        clr.l   (%a2)
        clr.l   4(%a2)
        clr.l   8(%a2)
        clr.l   12(%a2)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_reap_restore
.Lgk_reap_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_reap_restore
.Lgk_reap_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_reap_restore:
        move.w  %d7,%sr
        .incbin "stock/0003.bin", 0, 4
        .incbin "stock/0003.bin", 4, 4
        rts
.Lgk_reap_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_reap,.-gk_descriptor_reap
        .global gk_descriptor_begin_spill
        .type   gk_descriptor_begin_spill,@function
gk_descriptor_begin_spill:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_begin_spill_range
        lea     -28(%sp),%sp
        movem.l %d2-%d6/%a2-%a3,(%sp)
        move.l  %d0,%d2
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        btst    #0,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_begin_spill_corrupt
        btst    #1,GK_DESC_FLAGS(%a2)
        bne.w   .Lgk_begin_spill_busy
        btst    #2,GK_DESC_FLAGS(%a2)
        bne.w   .Lgk_begin_spill_corrupt
        btst    #5,GK_DESC_FLAGS(%a2)
        bne.w   .Lgk_begin_spill_corrupt
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_begin_spill_busy
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a2),%d3
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w   .Lgk_begin_spill_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a3
        adda.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a3),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_begin_spill_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a3),%d0
        moveq   #0,%d1
        move.b  GK_DESC_KIT(%a2),%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_begin_spill_corrupt
        tst.b   GK_PHYS_STATE(%a3)
        bne.w   .Lgk_begin_spill_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a3),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_begin_spill_corrupt
        move.l  %d3,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.w   .Lgk_begin_spill_corrupt
        lea     __gk_spill_bitmap,%a3
        moveq   #0,%d4
.Lgk_begin_spill_scan:
        move.l  %d4,%d5
        lsr.l   #3,%d5
        moveq   #0,%d6
        move.b  (%a3,%d5.l),%d6
        move.l  %d4,%d5
        andi.l  #7,%d5
        btst    %d5,%d6
        beq.s   .Lgk_begin_spill_found
        addq.l  #1,%d4
        cmpi.l  #GK_SPILL_ALLOC_COUNT,%d4
        blo.s   .Lgk_begin_spill_scan
        moveq   #GK_ERR_EXHAUSTED,%d0
        bra.w   .Lgk_begin_spill_restore
.Lgk_begin_spill_found:
        move.l  %d4,%d5
        lsr.l   #3,%d5
        move.l  %d4,%d6
        andi.l  #7,%d6
        bset    %d6,(%a3,%d5.l)
        move.l  %d4,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_spill_payloads,%a0
        adda.l  %d0,%a0
        move.l  %d4,%d1
        move.l  %d2,%d0
        bsr.w   gk_descriptor_begin_copy
        tst.l   %d0
        bne.s   .Lgk_begin_spill_rollback
        move.l  %d4,%d1
        move.l  %d4,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_spill_payloads,%a0
        adda.l  %d0,%a0
        moveq   #GK_OK,%d0
        bra.s   .Lgk_begin_spill_restore
.Lgk_begin_spill_rollback:
        move.l  %d4,%d5
        lsr.l   #3,%d5
        move.l  %d4,%d6
        andi.l  #7,%d6
        bclr    %d6,(%a3,%d5.l)
        bra.s   .Lgk_begin_spill_restore
.Lgk_begin_spill_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_begin_spill_restore
.Lgk_begin_spill_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_begin_spill_restore:
        movem.l (%sp),%d2-%d6/%a2-%a3
        lea     28(%sp),%sp
        rts
.Lgk_begin_spill_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_begin_spill,.-gk_descriptor_begin_spill
        .global gk_descriptor_finish_spill
        .type   gk_descriptor_finish_spill,@function
gk_descriptor_finish_spill:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_finish_spill_range
        .incbin "stock/0004.bin", 0, 4
        .incbin "stock/0004.bin", 4, 4
        move.l  %d0,%d2
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        btst    #0,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_finish_spill_corrupt
        btst    #1,GK_DESC_FLAGS(%a2)
        beq.w   .Lgk_finish_spill_busy
        moveq   #0,%d3
        move.b  GK_DESC_PHYSICAL(%a2),%d3
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d3
        bhi.w   .Lgk_finish_spill_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a3
        adda.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_PHYS_OWNER(%a3),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_finish_spill_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_KIT(%a3),%d0
        moveq   #0,%d1
        move.b  GK_DESC_KIT(%a2),%d1
        cmp.l   %d1,%d0
        bne.w   .Lgk_finish_spill_corrupt
        tst.b   GK_PHYS_STATE(%a3)
        bne.w   .Lgk_finish_spill_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a3),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_finish_spill_corrupt
        move.l  %d3,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        cmpa.l  GK_DESC_PAYLOAD(%a2),%a0
        bne.w   .Lgk_finish_spill_corrupt
        moveq   #0,%d4
        move.b  GK_DESC_SPILL(%a2),%d4
        cmpi.l  #GK_SPILL_ALLOC_COUNT - 1,%d4
        bhi.w   .Lgk_finish_spill_corrupt
        move.l  %d4,%d0
        andi.l  #7,%d0
        lsr.l   #3,%d4
        lea     __gk_spill_bitmap,%a0
        btst    %d0,(%a0,%d4.l)
        beq.w   .Lgk_finish_spill_corrupt
        move.l  %d2,%d0
        bsr.w   gk_descriptor_finish_copy
        tst.l   %d0
        bne.s   .Lgk_finish_spill_restore
        cmp.l   %d3,%d1
        bne.s   .Lgk_finish_spill_post_corrupt
        moveq   #-1,%d0
        move.l  %d0,(%a3)
        moveq   #GK_OK,%d0
        bra.s   .Lgk_finish_spill_restore
.Lgk_finish_spill_post_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_finish_spill_restore
.Lgk_finish_spill_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_finish_spill_restore
.Lgk_finish_spill_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_finish_spill_restore:
        movem.l (%sp),%d2-%d4/%a2-%a3
        lea     20(%sp),%sp
        rts
.Lgk_finish_spill_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_descriptor_finish_spill,.-gk_descriptor_finish_spill
        .align  4
        .global __gk_physical_payload_table
__gk_physical_payload_table:
        .set    .Lgk_table_bank,0
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .set .Lgk_table_slot,0
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .long GK_STOCK_PHYSICAL_BASE+.Lgk_table_bank*GK_STOCK_BANK_STRIDE+.Lgk_table_slot*GK_PART_PAYLOAD_SIZE
        .set .Lgk_table_slot,.Lgk_table_slot+1
        .set .Lgk_table_bank,.Lgk_table_bank+1
        .global __gk_physical_payload_table_end
__gk_physical_payload_table_end:
