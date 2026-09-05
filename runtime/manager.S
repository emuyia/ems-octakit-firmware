        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_physical_validate
        .type   gk_physical_validate,@function
gk_physical_validate:
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_physical_validate_range
        .incbin "stock/0092.bin", 0, 4
        .incbin "stock/0092.bin", 4, 4
        move.l  %d0,%d2
        move.l  %d2,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #2,%d0
        lea __gk_physical_cache,%a2
        adda.l %d0,%a2
        move.l  (%a2),%d0
        cmpi.l  #-1,%d0
        beq.w   .Lgk_physical_validate_free
        moveq   #0,%d3
        move.b  GK_PHYS_OWNER(%a2),%d3
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d3
        bhi.w   .Lgk_physical_validate_corrupt
        moveq   #0,%d4
        move.b  GK_PHYS_KIT(%a2),%d4
        tst.b   GK_PHYS_STATE(%a2)
        bne.w   .Lgk_physical_validate_corrupt
        moveq   #0,%d0
        move.b  GK_PHYS_RESERVED(%a2),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_physical_validate_corrupt
        move.l %d3,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        move.l  %d3,%d0
        lsr.l   #3,%d0
        move.l  %d3,%d1
        andi.l  #7,%d1
        lea     __gk_descriptor_bitmap,%a4
        btst    %d1,(%a4,%d0.l)
        beq.w   .Lgk_physical_validate_corrupt
        moveq   #0,%d5
        move.b  GK_DESC_FLAGS(%a3),%d5
        btst    #0,%d5
        beq.w   .Lgk_physical_validate_corrupt
        move.l  %d5,%d0
        andi.l  #0x80,%d0
        bne.w   .Lgk_physical_validate_corrupt
        btst    #2,%d5
        bne.w   .Lgk_physical_validate_corrupt
        cmpa.l  GK_DESC_PAYLOAD(%a3),%a0
        bne.w   .Lgk_physical_validate_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_KIT(%a3),%d0
        cmp.l   %d4,%d0
        bne.w   .Lgk_physical_validate_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a3),%d0
        cmp.l   %d2,%d0
        bne.w   .Lgk_physical_validate_corrupt
        btst    #1,%d5
        bne.w   .Lgk_physical_validate_copying
        btst    #5,%d5
        bne.w   .Lgk_physical_validate_corrupt
        btst    #6,%d5
        bne.w   .Lgk_physical_validate_corrupt
        tst.l   GK_DESC_CANDIDATE(%a3)
        bne.w   .Lgk_physical_validate_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a3),%d0
        cmpi.l  #GK_ID_NONE,%d0
        bne.w   .Lgk_physical_validate_corrupt
        bra.w   .Lgk_physical_validate_occupied
.Lgk_physical_validate_copying:
        tst.l   GK_DESC_CANDIDATE(%a3)
        beq.w   .Lgk_physical_validate_corrupt
        moveq   #0,%d0
        move.b  GK_DESC_SPILL(%a3),%d0
        btst    #6,%d5
        bne.w   .Lgk_physical_validate_promotion
        btst    #5,%d5
        bne.w   .Lgk_physical_validate_clone
        cmpi.l  #GK_SPILL_COUNT - 1,%d0
        bhi.w   .Lgk_physical_validate_corrupt
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_spill_payloads,%a1
        adda.l  %d0,%a1
        cmpa.l  GK_DESC_CANDIDATE(%a3),%a1
        bne.w   .Lgk_physical_validate_corrupt
        bra.w   .Lgk_physical_validate_occupied
.Lgk_physical_validate_promotion:
        btst    #5,%d5
        bne.w   .Lgk_physical_validate_corrupt
        btst    #3,%d5
        beq.w   .Lgk_physical_validate_corrupt
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a1
        adda.l  %d0,%a1
        cmpa.l  GK_DESC_CANDIDATE(%a3),%a1
        bne.w   .Lgk_physical_validate_corrupt
        bra.w   .Lgk_physical_validate_occupied
.Lgk_physical_validate_clone:
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_physical_validate_corrupt
        cmp.l   %d2,%d0
        beq.w   .Lgk_physical_validate_corrupt
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a1
        move.l  (%a1,%d0.l),%a1
        cmpa.l  GK_DESC_CANDIDATE(%a3),%a1
        bne.w   .Lgk_physical_validate_corrupt
.Lgk_physical_validate_occupied:
        move.l  %d4,%d1
        move.l  %d3,%d0
        bra.s   .Lgk_physical_validate_restore
.Lgk_physical_validate_free:
        moveq   #GK_ERR_INVALID,%d0
        bra.s   .Lgk_physical_validate_restore
.Lgk_physical_validate_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_physical_validate_restore:
        movem.l (%sp),%d2-%d5/%a2-%a4
        lea     28(%sp),%sp
        rts
.Lgk_physical_validate_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_physical_validate,.-gk_physical_validate
        .global gk_physical_acquire
        .type   gk_physical_acquire,@function
gk_physical_acquire:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_physical_acquire_range
        cmpi.l  #3,%d1
        bhi.w   .Lgk_physical_acquire_range
        .incbin "stock/0093.bin", 0, 4
        .incbin "stock/0093.bin", 4, 4
        move.l  %d0,%d2
        lsl.l   #2,%d2
        add.l   %d1,%d2
        move.w  %sr,%d4
        move.w  #0x2700,%sr
        move.l  %d2,%d0
        bsr.w   gk_physical_validate
        tst.l   %d0
        bmi.s   .Lgk_physical_acquire_restore
        move.l  %d0,%d2
        movea.l %a0,%a2
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a1
        adda.l %d0,%a1
        tst.w   GK_DESC_ROOTS(%a1)
        beq.s   .Lgk_physical_acquire_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_READERS(%a1),%d0
        cmpi.l  #0xffff,%d0
        beq.s   .Lgk_physical_acquire_overflow
        addq.l  #1,%d0
        .global gk_physical_acquire_reader_publication
gk_physical_acquire_reader_publication:
        move.w  %d0,GK_DESC_READERS(%a1)
        move.l  %d2,%d0
        movea.l %a2,%a0
        bra.s   .Lgk_physical_acquire_restore
.Lgk_physical_acquire_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_physical_acquire_restore
.Lgk_physical_acquire_overflow:
        moveq   #GK_ERR_OVERFLOW,%d0
.Lgk_physical_acquire_restore:
        move.w  %d4,%sr
        .incbin "stock/0094.bin", 0, 4
        .incbin "stock/0094.bin", 4, 4
        .incbin "stock/0094.bin", 8, 2
.Lgk_physical_acquire_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_physical_acquire,.-gk_physical_acquire
        .global gk_physical_reserve
        .type   gk_physical_reserve,@function
gk_physical_reserve:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_reserve_range
        cmpi.l  #GK_ID_NONE,%d1
        beq.s   .Lgk_reserve_arguments_ok
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d1
        bhi.w   .Lgk_reserve_range
.Lgk_reserve_arguments_ok:
        .incbin "stock/0095.bin", 0, 4
        .incbin "stock/0095.bin", 4, 4
        move.l  %d0,%d2
        lsl.l   #2,%d2
        move.l  %d1,%d3
        lea     __gk_physical_victim_cursors,%a2
        adda.l  %d0,%a2
        moveq   #0,%d4
        move.b  (%a2),%d4
        andi.l  #3,%d4
        moveq   #0,%d5
.Lgk_reserve_free_loop:
        move.l  %d4,%d6
        add.l   %d5,%d6
        andi.l  #3,%d6
        add.l   %d2,%d6
        move.l  %d6,%d0
        bsr.w   gk_physical_validate
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.w   .Lgk_reserve_success
        tst.l   %d0
        bmi.w   .Lgk_reserve_restore
        addq.l  #1,%d5
        cmpi.l  #4,%d5
        blo.s   .Lgk_reserve_free_loop
        moveq   #0,%d5
.Lgk_reserve_reap_loop:
        move.l  %d4,%d6
        add.l   %d5,%d6
        andi.l  #3,%d6
        add.l   %d2,%d6
        move.l  %d6,%d0
        bsr.w   gk_physical_validate
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.w   .Lgk_reserve_success
        tst.l   %d0
        bmi.w   .Lgk_reserve_restore
        move.l  %d0,%d7
        cmp.l   %d3,%d7
        beq.s   .Lgk_reserve_reap_next
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        tst.w   GK_DESC_ROOTS(%a3)
        bne.s   .Lgk_reserve_reap_next
        tst.w   GK_DESC_READERS(%a3)
        bne.s   .Lgk_reserve_reap_next
        btst    #1,GK_DESC_FLAGS(%a3)
        bne.s   .Lgk_reserve_reap_next
        btst    #3,GK_DESC_FLAGS(%a3)
        bne.s   .Lgk_reserve_reap_next
        move.l  %d7,%d0
        bsr.w   gk_descriptor_reap
        tst.l   %d0
        beq.s   .Lgk_reserve_reaped
        cmpi.l  #GK_ERR_BUSY,%d0
        bne.w   .Lgk_reserve_restore
        bra.s   .Lgk_reserve_reap_next
.Lgk_reserve_reaped:
        cmp.l   %d6,%d1
        bne.w   .Lgk_reserve_internal_corrupt
        bra.w   .Lgk_reserve_success
.Lgk_reserve_reap_next:
        addq.l  #1,%d5
        cmpi.l  #4,%d5
        blo.s   .Lgk_reserve_reap_loop
        moveq   #0,%d5
.Lgk_reserve_finish_loop:
        move.l  %d4,%d6
        add.l   %d5,%d6
        andi.l  #3,%d6
        add.l   %d2,%d6
        move.l  %d6,%d0
        bsr.w   gk_physical_validate
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.w   .Lgk_reserve_success
        tst.l   %d0
        bmi.w   .Lgk_reserve_restore
        move.l  %d0,%d7
        cmp.l   %d3,%d7
        beq.s   .Lgk_reserve_finish_next
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        btst    #3,GK_DESC_FLAGS(%a3)
        bne.s   .Lgk_reserve_finish_next
        btst    #1,GK_DESC_FLAGS(%a3)
        beq.s   .Lgk_reserve_finish_next
        btst    #5,GK_DESC_FLAGS(%a3)
        bne.s   .Lgk_reserve_finish_next
        move.l  %d7,%d0
        bsr.w   gk_descriptor_finish_spill
        tst.l   %d0
        beq.s   .Lgk_reserve_finished
        cmpi.l  #GK_ERR_BUSY,%d0
        bne.w   .Lgk_reserve_restore
        bra.s   .Lgk_reserve_finish_next
.Lgk_reserve_finished:
        cmp.l   %d6,%d1
        bne.w   .Lgk_reserve_internal_corrupt
        bra.w   .Lgk_reserve_success
.Lgk_reserve_finish_next:
        addq.l  #1,%d5
        cmpi.l  #4,%d5
        blo.s   .Lgk_reserve_finish_loop
        moveq   #0,%d5
.Lgk_reserve_spill_loop:
        move.l  %d4,%d6
        add.l   %d5,%d6
        andi.l  #3,%d6
        add.l   %d2,%d6
        move.l  %d6,%d0
        bsr.w   gk_physical_validate
        cmpi.l  #GK_ERR_INVALID,%d0
        beq.w   .Lgk_reserve_success
        tst.l   %d0
        bmi.w   .Lgk_reserve_restore
        move.l  %d0,%d7
        cmp.l   %d3,%d7
        beq.s   .Lgk_reserve_spill_next
        move.l %d7,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        btst    #3,GK_DESC_FLAGS(%a3)
        bne.s   .Lgk_reserve_spill_next
        btst    #1,GK_DESC_FLAGS(%a3)
        bne.s   .Lgk_reserve_spill_next
        tst.w   GK_DESC_ROOTS(%a3)
        beq.s   .Lgk_reserve_spill_next
        tst.w   GK_DESC_READERS(%a3)
        bne.s   .Lgk_reserve_spill_next
        move.l  %d7,%d0
        bsr.w   gk_descriptor_begin_spill
        tst.l   %d0
        bne.w   .Lgk_reserve_restore
        move.l  %d7,%d0
        bsr.w   gk_descriptor_copy_payload
        tst.l   %d0
        bne.w   .Lgk_reserve_restore
        move.l  %d7,%d0
        bsr.w   gk_descriptor_finish_spill
        tst.l   %d0
        bne.w   .Lgk_reserve_restore
        cmp.l   %d6,%d1
        bne.w   .Lgk_reserve_internal_corrupt
        bra.s   .Lgk_reserve_success
.Lgk_reserve_spill_next:
        addq.l  #1,%d5
        cmpi.l  #4,%d5
        blo.w   .Lgk_reserve_spill_loop
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_reserve_restore
.Lgk_reserve_internal_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
        bra.s   .Lgk_reserve_restore
.Lgk_reserve_success:
        move.l  %d6,%d0
        andi.l  #3,%d0
        addq.l  #1,%d0
        andi.l  #3,%d0
        move.b  %d0,(%a2)
        move.l  %d6,%d0
        lsl.l   #2,%d0
        lea     __gk_physical_payload_table,%a0
        move.l  (%a0,%d0.l),%a0
        move.l  %d6,%d0
.Lgk_reserve_restore:
        .incbin "stock/0096.bin", 0, 4
        .incbin "stock/0096.bin", 4, 4
        rts
.Lgk_reserve_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_physical_reserve,.-gk_physical_reserve
        .global gk_stage_canonical
        .type   gk_stage_canonical,@function
gk_stage_canonical:
        cmpi.l  #15,%d0
        bhi.w   .Lgk_stage_range
        cmpi.l  #0xff,%d1
        bhi.w   .Lgk_stage_range
        cmpi.l  #GK_ID_NONE,%d2
        beq.s   .Lgk_stage_arguments_ok
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d2
        bhi.w   .Lgk_stage_range
.Lgk_stage_arguments_ok:
        .incbin "stock/0097.bin", 0, 4
        .incbin "stock/0097.bin", 4, 4
        move.l  %d0,%d3
        move.l  %d1,%d4
        move.l  %d3,%d0
        move.l  %d2,%d1
        bsr.w   gk_physical_reserve
        tst.l   %d0
        bmi.s   .Lgk_stage_restore
        move.l  %d0,%d5
        move.l  %a0,%a3
        move.l  %d4,%d0
        mulu.w  #GK_PART_PAYLOAD_SIZE,%d0
        lea     __gk_canonical_payloads,%a0
        adda.l  %d0,%a0
        move.l  %a3,%a1
        bsr.w   gk_copy_payload_interruptible
        move.l  %d4,%d0
        move.l  %d5,%d1
        bsr.w   gk_descriptor_allocate_physical
        tst.l   %d0
        bmi.s   .Lgk_stage_restore
        move.l  %d5,%d1
        move.l  %a3,%a0
.Lgk_stage_restore:
        .incbin "stock/0098.bin", 0, 4
        .incbin "stock/0098.bin", 4, 4
        rts
.Lgk_stage_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_stage_canonical,.-gk_stage_canonical
        .global gk_clone_stage_to_bank
        .type   gk_clone_stage_to_bank,@function
gk_clone_stage_to_bank:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_clone_stage_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_clone_stage_range
        .incbin "stock/0099.bin", 0, 4
        .incbin "stock/0099.bin", 4, 4
        move.l  %d0,%d2
        move.l  %d1,%d3
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        btst    #0,%d0
        beq.w   .Lgk_clone_stage_corrupt
        move.l  %d0,%d7
        andi.l  #0xc4,%d7
        bne.w   .Lgk_clone_stage_corrupt
        moveq   #0,%d5
        move.b  GK_DESC_KIT(%a2),%d5
        btst    #1,%d0
        bne.w   .Lgk_clone_stage_retry
        btst    #5,%d0
        bne.w   .Lgk_clone_stage_corrupt
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_clone_stage_busy
        move.l  %d3,%d0
        move.l  %d2,%d1
        bsr.w   gk_physical_reserve
        tst.l   %d0
        bmi.w   .Lgk_clone_stage_restore
        move.l  %d0,%d4
        move.l  %d2,%d0
        move.l  %d4,%d1
        bsr.w   gk_descriptor_begin_clone
        tst.l   %d0
        bne.w   .Lgk_clone_stage_restore
        move.l  %d2,%d0
        bsr.w   gk_descriptor_copy_payload
        tst.l   %d0
        bne.w   .Lgk_clone_stage_abort_error
        move.l  %d5,%d0
        move.l  %d4,%d1
        bsr.w   gk_descriptor_allocate_physical
        tst.l   %d0
        bmi.w   .Lgk_clone_stage_abort_error
        move.l  %d0,%d6
        move.l  %d6,%d0
        move.l  %d4,%d1
        bra.w   .Lgk_clone_stage_restore
.Lgk_clone_stage_retry:
        btst    #5,%d0
        beq.w   .Lgk_clone_stage_busy
        moveq   #0,%d4
        move.b  GK_DESC_SPILL(%a2),%d4
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d4
        bhi.w   .Lgk_clone_stage_corrupt
        move.l  %d4,%d0
        lsr.l   #2,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_clone_stage_busy
        moveq   #0,%d0
        move.b  GK_DESC_PHYSICAL(%a2),%d0
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d0
        bhi.w   .Lgk_clone_stage_corrupt
        bsr.w   gk_physical_validate
        cmp.l   %d2,%d0
        bne.w   .Lgk_clone_stage_corrupt
        move.l  %d4,%d0
        bsr.w   gk_physical_validate
        tst.l   %d0
        bmi.w   .Lgk_clone_stage_corrupt
        move.l  %d0,%d6
        cmp.l   %d5,%d1
        bne.w   .Lgk_clone_stage_corrupt
        move.l %d6,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a3
        adda.l %d0,%a3
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a3),%d0
        cmpi.l  #GK_DESC_VALID,%d0
        bne.w   .Lgk_clone_stage_corrupt
        moveq   #0,%d0
        move.w  GK_DESC_ROOTS(%a3),%d0
        cmpi.l  #1,%d0
        bne.w   .Lgk_clone_stage_corrupt
        tst.w   GK_DESC_READERS(%a3)
        bne.w   .Lgk_clone_stage_corrupt
        move.l  %d6,%d0
        move.l  %d4,%d1
        bra.s   .Lgk_clone_stage_restore
.Lgk_clone_stage_abort_error:
        move.l  %d0,%d7
        move.l  %d2,%d0
        bsr.w   gk_descriptor_abort_clone
        tst.l   %d0
        bne.s   .Lgk_clone_stage_corrupt
        move.l  %d7,%d0
        bra.s   .Lgk_clone_stage_restore
.Lgk_clone_stage_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_clone_stage_restore
.Lgk_clone_stage_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_clone_stage_restore:
        .incbin "stock/0100.bin", 0, 4
        .incbin "stock/0100.bin", 4, 4
        rts
.Lgk_clone_stage_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_clone_stage_to_bank,.-gk_clone_stage_to_bank
        .global gk_clone_to_bank
        .type   gk_clone_to_bank,@function
gk_clone_to_bank:
        cmpi.l  #GK_DESCRIPTOR_COUNT - 1,%d0
        bhi.w   .Lgk_clone_to_bank_range
        cmpi.l  #15,%d1
        bhi.w   .Lgk_clone_to_bank_range
        .incbin "stock/0101.bin", 0, 4
        .incbin "stock/0101.bin", 4, 4
        move.l  %d0,%d2
        move.l  %d1,%d3
        move.l %d2,%d0
        andi.l #0xff,%d0
        lsl.l #4,%d0
        lea __gk_descriptors,%a2
        adda.l %d0,%a2
        moveq   #0,%d0
        move.b  GK_DESC_FLAGS(%a2),%d0
        btst    #0,%d0
        beq.w   .Lgk_clone_to_bank_corrupt
        move.l  %d0,%d7
        andi.l  #0xc4,%d7
        bne.w   .Lgk_clone_to_bank_corrupt
        btst    #1,%d0
        bne.w   .Lgk_clone_to_bank_retry
        btst    #5,%d0
        bne.w   .Lgk_clone_to_bank_corrupt
        tst.w   GK_DESC_ROOTS(%a2)
        beq.w   .Lgk_clone_to_bank_busy
        moveq   #0,%d5
        move.b  GK_DESC_KIT(%a2),%d5
        move.l  %d3,%d0
        move.l  %d2,%d1
        bsr.w   gk_physical_reserve
        tst.l   %d0
        bmi.w   .Lgk_clone_to_bank_restore
        move.l  %d0,%d4
        move.l  %d2,%d0
        move.l  %d4,%d1
        bsr.w   gk_descriptor_begin_clone
        tst.l   %d0
        bne.w   .Lgk_clone_to_bank_restore
        move.l  %d2,%d0
        bsr.w   gk_descriptor_copy_payload
        tst.l   %d0
        bne.w   .Lgk_clone_to_bank_abort_error
        move.l  %d5,%d0
        move.l  %d4,%d1
        bsr.w   gk_descriptor_allocate_physical
        tst.l   %d0
        bmi.w   .Lgk_clone_to_bank_abort_error
        move.l  %d0,%d6
        move.l  %d2,%d0
        bsr.w   gk_descriptor_finish_clone
        tst.l   %d0
        bne.w   .Lgk_clone_to_bank_restore
        cmp.l   %d6,%d1
        bne.w   .Lgk_clone_to_bank_corrupt
        move.l  %d6,%d0
        move.l  %d4,%d1
        bra.s   .Lgk_clone_to_bank_restore
.Lgk_clone_to_bank_retry:
        btst    #5,%d0
        beq.w   .Lgk_clone_to_bank_busy
        moveq   #0,%d4
        move.b  GK_DESC_SPILL(%a2),%d4
        cmpi.l  #GK_PHYSICAL_COUNT - 1,%d4
        bhi.w   .Lgk_clone_to_bank_corrupt
        move.l  %d4,%d0
        lsr.l   #2,%d0
        cmp.l   %d3,%d0
        bne.w   .Lgk_clone_to_bank_busy
        move.l  %d2,%d0
        bsr.w   gk_descriptor_finish_clone
        tst.l   %d0
        bne.s   .Lgk_clone_to_bank_restore
        move.l  %d1,%d0
        move.l  %d4,%d1
        bra.s   .Lgk_clone_to_bank_restore
.Lgk_clone_to_bank_abort_error:
        move.l  %d0,%d7
        move.l  %d2,%d0
        bsr.w   gk_descriptor_abort_clone
        tst.l   %d0
        bne.s   .Lgk_clone_to_bank_corrupt
        move.l  %d7,%d0
        bra.s   .Lgk_clone_to_bank_restore
.Lgk_clone_to_bank_busy:
        moveq   #GK_ERR_BUSY,%d0
        bra.s   .Lgk_clone_to_bank_restore
.Lgk_clone_to_bank_corrupt:
        moveq   #GK_ERR_CORRUPT,%d0
.Lgk_clone_to_bank_restore:
        .incbin "stock/0102.bin", 0, 4
        .incbin "stock/0102.bin", 4, 4
        rts
.Lgk_clone_to_bank_range:
        moveq   #GK_ERR_RANGE,%d0
        rts
        .size   gk_clone_to_bank,.-gk_clone_to_bank
