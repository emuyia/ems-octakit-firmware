        .include "abi.inc"
        .equ    GK_STOCK_BOOT_CONTINUE, 0x40001e50
        .equ    GK_STOCK_APLIB_DEPACK, 0x400e0aca
        .equ    GK_RUNTIME_HASH_HELPER, 0x40014418
        .equ    GK_PACKED_HASH_COMMON, 0x40014424
        .section .early,"ax",@progbits
        .align  4
        .global gk_experimental_bootstrap
        .type   gk_experimental_bootstrap,@function
gk_experimental_bootstrap:
        jsr     GK_STOCK_BOOT_CONTINUE
        lea     -48(%sp),%sp
        movem.l %d0-%d7/%a0-%a2,(%sp)
        lea     __gk_stage_load_start,%a0
        lea     __gk_stage_uncached_start,%a1
        move.l  #__gk_stage_load_size,%d0
.Lgk_packed_stage_copy:
        move.b  (%a0)+,(%a1)+
        subq.l  #1,%d0
        bne.s   .Lgk_packed_stage_copy
        lea     __gk_packed_runtime_uncached_start,%a0
        move.l  #__gk_packed_runtime_size,%d0
        jsr     GK_PACKED_HASH_COMMON
        cmpi.l  #GK_PACKED_RUNTIME_HASH,%d1
        bne.s   .Lgk_packed_fatal
        lea     __gk_packed_runtime_uncached_start,%a0
        move.l  (%a0)+,%d0
        cmpi.l  #0x474b4133,%d0
        bne.s   .Lgk_packed_fatal
        move.l  (%a0)+,%d0
        cmpi.l  #__gk_runtime_size,%d0
        bne.s   .Lgk_packed_fatal
        pea     __gk_runtime_uncached_start
        pea     __gk_packed_runtime_uncached_start
        jsr     GK_STOCK_APLIB_DEPACK
        lea     8(%sp),%sp
        tst.l   %d0
        bne.s   .Lgk_packed_fatal
        jsr     GK_RUNTIME_HASH_HELPER
        bne.s   .Lgk_packed_fatal
        lea     __gk_runtime_uncached_start,%a0
        lea     __gk_runtime_backup_uncached_start,%a1
        move.l  #__gk_runtime_size,%d0
.Lgk_packed_backup_copy:
        move.b  (%a0)+,(%a1)+
        subq.l  #1,%d0
        bne.s   .Lgk_packed_backup_copy
        movem.l (%sp),%d0-%d7/%a0-%a2
        lea     48(%sp),%sp
        rts
.Lgk_packed_fatal:
        bra.s   .Lgk_packed_fatal
        .size   gk_experimental_bootstrap,.-gk_experimental_bootstrap
        .section .stage,"a",@progbits
        .align  4
        .global gk_experimental_stage_signature
gk_experimental_stage_signature:
        .long   0x474b5832
