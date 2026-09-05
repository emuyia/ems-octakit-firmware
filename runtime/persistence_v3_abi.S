        .include "abi.inc"
        .section .runtime,"ax"
        .align  4
        .global gk_fixed_record_v3_marker
        .set    gk_fixed_record_v3_marker,1
        .global gk_v3_stock_current_project_directory
        .type   gk_v3_stock_current_project_directory,@function
gk_v3_stock_current_project_directory:
        .global gk_persistence_stock_project_directory_call
gk_persistence_stock_project_directory_call:
        jmp     GK_STOCK_CURRENT_PROJECT_DIRECTORY
        .size   gk_v3_stock_current_project_directory,.-gk_v3_stock_current_project_directory
        .global gk_v3_stock_file_open
        .type   gk_v3_stock_file_open,@function
gk_v3_stock_file_open:
        .global gk_persistence_stock_file_open_call
gk_persistence_stock_file_open_call:
        jmp     GK_STOCK_BUFFERED_FILE_OPEN
        .size   gk_v3_stock_file_open,.-gk_v3_stock_file_open
        .global gk_v3_stock_file_read
        .type   gk_v3_stock_file_read,@function
gk_v3_stock_file_read:
        .global gk_persistence_stock_file_read_call
gk_persistence_stock_file_read_call:
        jmp     GK_STOCK_BUFFERED_FILE_READ
        .size   gk_v3_stock_file_read,.-gk_v3_stock_file_read
        .global gk_v3_stock_file_seek
        .type   gk_v3_stock_file_seek,@function
gk_v3_stock_file_seek:
        .global gk_persistence_stock_file_seek_call
gk_persistence_stock_file_seek_call:
        jmp     GK_STOCK_BUFFERED_FILE_SEEK
        .size   gk_v3_stock_file_seek,.-gk_v3_stock_file_seek
        .global gk_v3_stock_file_write
        .type   gk_v3_stock_file_write,@function
gk_v3_stock_file_write:
        .global gk_persistence_stock_file_write_call
gk_persistence_stock_file_write_call:
        jmp     GK_STOCK_BUFFERED_FILE_WRITE
        .size   gk_v3_stock_file_write,.-gk_v3_stock_file_write
        .global gk_v3_stock_file_close
        .type   gk_v3_stock_file_close,@function
gk_v3_stock_file_close:
        .global gk_persistence_stock_file_close_call
gk_persistence_stock_file_close_call:
        jmp     GK_STOCK_BUFFERED_FILE_CLOSE
        .size   gk_v3_stock_file_close,.-gk_v3_stock_file_close
        .global gk_v3_stock_part_payload_initialize
        .type   gk_v3_stock_part_payload_initialize,@function
gk_v3_stock_part_payload_initialize:
        .global gk_persistence_stock_part_payload_initialize_call
gk_persistence_stock_part_payload_initialize_call:
        jmp     GK_STOCK_PART_PAYLOAD_INITIALIZE
        .size   gk_v3_stock_part_payload_initialize,.-gk_v3_stock_part_payload_initialize
        .global gk_v3_stock_bank_deserialize
        .type   gk_v3_stock_bank_deserialize,@function
gk_v3_stock_bank_deserialize:
        .global gk_persistence_stock_bank_deserialize_call
gk_persistence_stock_bank_deserialize_call:
        jmp     GK_STOCK_BANK_DESERIALIZE
        .size   gk_v3_stock_bank_deserialize,.-gk_v3_stock_bank_deserialize
        .global gk_v3_irq_lock
        .type   gk_v3_irq_lock,@function
gk_v3_irq_lock:
        moveq   #0,%d0
        move.w  %sr,%d0
        move.w  #0x2700,%sr
        rts
        .size   gk_v3_irq_lock,.-gk_v3_irq_lock
        .global gk_v3_irq_restore
        .type   gk_v3_irq_restore,@function
gk_v3_irq_restore:
        move.l  4(%sp),%d0
        move.w  %d0,%sr
        rts
        .size   gk_v3_irq_restore,.-gk_v3_irq_restore
        .global gk_persistence_crc32_update
        .type   gk_persistence_crc32_update,@function
gk_persistence_crc32_update:
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        move.l  %a0,-(%sp)
        movea.l #gk_v3_crc32_update_impl,%a0
        jsr     (%a0)
        lea     12(%sp),%sp
        rts
        .size   gk_persistence_crc32_update,.-gk_persistence_crc32_update
        .global gk_persistence_header_validate
        .type   gk_persistence_header_validate,@function
gk_persistence_header_validate:
        subq.l  #8,%sp
        lea     4(%sp),%a1
        move.l  %a1,-(%sp)
        move.l  %sp,%a1
        addq.l  #4,%a1
        move.l  %a1,-(%sp)
        move.l  %a0,-(%sp)
        movea.l #gk_v3_legacy_header_validate_impl,%a0
        jsr     (%a0)
        lea     12(%sp),%sp
        tst.l   %d0
        bmi.s   .Lgk_v3_header_validate_done
        move.l  (%sp),%d1
        movea.l 4(%sp),%a1
.Lgk_v3_header_validate_done:
        addq.l  #8,%sp
        rts
        .size   gk_persistence_header_validate,.-gk_persistence_header_validate
        .global gk_persistence_initialized_validate
        .type   gk_persistence_initialized_validate,@function
gk_persistence_initialized_validate:
        moveq   #GK_OK,%d0
        rts
        .size   gk_persistence_initialized_validate,.-gk_persistence_initialized_validate
        .global gk_persistence_project_path_build
        .type   gk_persistence_project_path_build,@function
gk_persistence_project_path_build:
        move.l  %a1,-(%sp)
        move.l  %a0,-(%sp)
        movea.l #gk_v3_project_path_build_impl,%a0
        jsr     (%a0)
        addq.l  #8,%sp
        rts
        .size   gk_persistence_project_path_build,.-gk_persistence_project_path_build
        .global gk_persistence_close
        .type   gk_persistence_close,@function
gk_persistence_close:
        move.l  %a0,-(%sp)
        movea.l #gk_v3_close_impl,%a0
        jsr     (%a0)
        addq.l  #4,%sp
        rts
        .size   gk_persistence_close,.-gk_persistence_close
        .global gk_persistence_peer_validate
        .type gk_persistence_peer_validate,@function
gk_persistence_peer_validate:
        subq.l #8,%sp
        lea 4(%sp),%a1
        move.l %a1,-(%sp)
        lea 4(%sp),%a1
        move.l %a1,-(%sp)
        move.l %a0,-(%sp)
        move.l #0,-(%sp)
        movea.l #gk_v3_compat_peer_read_impl,%a0
        jsr (%a0)
        lea 16(%sp),%sp
        tst.l %d0
        bmi.s .Lpeer_done_gk_persistence_peer_validate
        move.l (%sp),%d1
        movea.l 4(%sp),%a1
.Lpeer_done_gk_persistence_peer_validate:
        addq.l #8,%sp
        rts
        .size gk_persistence_peer_validate,.-gk_persistence_peer_validate
        .global gk_persistence_peer_load
        .type gk_persistence_peer_load,@function
gk_persistence_peer_load:
        subq.l #8,%sp
        lea 4(%sp),%a1
        move.l %a1,-(%sp)
        lea 4(%sp),%a1
        move.l %a1,-(%sp)
        move.l %a0,-(%sp)
        move.l #1,-(%sp)
        movea.l #gk_v3_compat_peer_read_impl,%a0
        jsr (%a0)
        lea 16(%sp),%sp
        tst.l %d0
        bmi.s .Lpeer_done_gk_persistence_peer_load
        move.l (%sp),%d1
        movea.l 4(%sp),%a1
.Lpeer_done_gk_persistence_peer_load:
        addq.l #8,%sp
        rts
        .size gk_persistence_peer_load,.-gk_persistence_peer_load
        .global gk_persistence_peer_assignments_load
        .type gk_persistence_peer_assignments_load,@function
gk_persistence_peer_assignments_load:
        subq.l #8,%sp
        lea 4(%sp),%a1
        move.l %a1,-(%sp)
        lea 4(%sp),%a1
        move.l %a1,-(%sp)
        move.l %a0,-(%sp)
        move.l #2,-(%sp)
        movea.l #gk_v3_compat_peer_read_impl,%a0
        jsr (%a0)
        lea 16(%sp),%sp
        tst.l %d0
        bmi.s .Lpeer_done_gk_persistence_peer_assignments_load
        move.l (%sp),%d1
        movea.l 4(%sp),%a1
.Lpeer_done_gk_persistence_peer_assignments_load:
        addq.l #8,%sp
        rts
        .size gk_persistence_peer_assignments_load,.-gk_persistence_peer_assignments_load
        .global gk_persistence_pair_select
        .type   gk_persistence_pair_select,@function
gk_persistence_pair_select:
        move.l  %a2,-(%sp)
        subq.l  #8,%sp
        lea     4(%sp),%a2
        move.l  %a2,-(%sp)
        move.l  %sp,%a2
        addq.l  #4,%a2
        move.l  %a2,-(%sp)
        move.l  %a1,-(%sp)
        move.l  %a0,-(%sp)
        movea.l #gk_v3_compat_pair_select_impl,%a0
        jsr     (%a0)
        lea     16(%sp),%sp
        tst.l   %d0
        bmi.s   .Lgk_v3_pair_select_done
        move.l  (%sp),%d1
        movea.l 4(%sp),%a0
.Lgk_v3_pair_select_done:
        addq.l  #8,%sp
        movea.l (%sp)+,%a2
        rts
        .size   gk_persistence_pair_select,.-gk_persistence_pair_select
        .global gk_persistence_peer_write
        .type   gk_persistence_peer_write,@function
gk_persistence_peer_write:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .size   gk_persistence_peer_write,.-gk_persistence_peer_write
        .global gk_persistence_peer_rebase_write
        .type   gk_persistence_peer_rebase_write,@function
gk_persistence_peer_rebase_write:
        moveq   #GK_ERR_INVALID,%d0
        rts
        .size   gk_persistence_peer_rebase_write,.-gk_persistence_peer_rebase_write
        .global gk_persistence_work_load
        .type gk_persistence_work_load,@function
gk_persistence_work_load:
        movea.l #gk_v3_work_load_impl,%a0
        jmp (%a0)
        .size gk_persistence_work_load,.-gk_persistence_work_load
        .global gk_persistence_work_commit
        .type gk_persistence_work_commit,@function
gk_persistence_work_commit:
        movea.l #gk_v3_work_commit_impl,%a0
        jmp (%a0)
        .size gk_persistence_work_commit,.-gk_persistence_work_commit
        .global gk_persistence_work_commit_locked
        .type gk_persistence_work_commit_locked,@function
gk_persistence_work_commit_locked:
        movea.l #gk_v3_work_commit_locked_impl,%a0
        jmp (%a0)
        .size gk_persistence_work_commit_locked,.-gk_persistence_work_commit_locked
        .global gk_persistence_stored_assignments_load
        .type gk_persistence_stored_assignments_load,@function
gk_persistence_stored_assignments_load:
        movea.l #gk_v3_stored_assignments_load_impl,%a0
        jmp (%a0)
        .size gk_persistence_stored_assignments_load,.-gk_persistence_stored_assignments_load
        .global gk_persistence_project_store
        .type gk_persistence_project_store,@function
gk_persistence_project_store:
        movea.l #gk_v3_project_store_impl,%a0
        jmp (%a0)
        .size gk_persistence_project_store,.-gk_persistence_project_store
        .global gk_persistence_project_store_locked
        .type gk_persistence_project_store_locked,@function
gk_persistence_project_store_locked:
        movea.l #gk_v3_project_store_locked_impl,%a0
        jmp (%a0)
        .size gk_persistence_project_store_locked,.-gk_persistence_project_store_locked
        .global gk_persistence_stored_pending_repair
        .type gk_persistence_stored_pending_repair,@function
gk_persistence_stored_pending_repair:
        movea.l #gk_v3_stored_pending_repair_impl,%a0
        jmp (%a0)
        .size gk_persistence_stored_pending_repair,.-gk_persistence_stored_pending_repair
        .global gk_persistence_project_reload
        .type gk_persistence_project_reload,@function
gk_persistence_project_reload:
        movea.l #gk_v3_project_reload_impl,%a0
        jmp (%a0)
        .size gk_persistence_project_reload,.-gk_persistence_project_reload
        .global gk_persistence_library_clear
        .type gk_persistence_library_clear,@function
gk_persistence_library_clear:
        movea.l #gk_v3_library_clear_impl,%a0
        jmp (%a0)
        .size gk_persistence_library_clear,.-gk_persistence_library_clear
        .global gk_persistence_migrate_resident_work
        .type gk_persistence_migrate_resident_work,@function
gk_persistence_migrate_resident_work:
        movea.l #gk_v3_migrate_resident_work_impl,%a0
        jmp (%a0)
        .size gk_persistence_migrate_resident_work,.-gk_persistence_migrate_resident_work
        .global gk_persistence_new_project_initialize
        .type gk_persistence_new_project_initialize,@function
gk_persistence_new_project_initialize:
        movea.l #gk_v3_new_project_initialize_impl,%a0
        jmp (%a0)
        .size gk_persistence_new_project_initialize,.-gk_persistence_new_project_initialize
        .global gk_persistence_migrate_stored_library
        .type gk_persistence_migrate_stored_library,@function
gk_persistence_migrate_stored_library:
        movea.l #gk_v3_migrate_stored_library_impl,%a0
        jmp (%a0)
        .size gk_persistence_migrate_stored_library,.-gk_persistence_migrate_stored_library
        .global gk_persistence_stored_commit
        .type gk_persistence_stored_commit,@function
gk_persistence_stored_commit:
        movea.l #gk_v3_stored_commit_impl,%a0
        jmp (%a0)
        .size gk_persistence_stored_commit,.-gk_persistence_stored_commit
        .global gk_persistence_stored_commit_locked
        .type gk_persistence_stored_commit_locked,@function
gk_persistence_stored_commit_locked:
        movea.l #gk_v3_stored_commit_locked_impl,%a0
        jmp (%a0)
        .size gk_persistence_stored_commit_locked,.-gk_persistence_stored_commit_locked
        .global gk_persistence_first_install_migrate
        .type gk_persistence_first_install_migrate,@function
gk_persistence_first_install_migrate:
        movea.l #gk_v3_first_install_migrate_impl,%a0
        jmp (%a0)
        .size gk_persistence_first_install_migrate,.-gk_persistence_first_install_migrate
        .global gk_persistence_work_load_or_migrate
        .type gk_persistence_work_load_or_migrate,@function
gk_persistence_work_load_or_migrate:
        movea.l #gk_v3_work_load_or_migrate_impl,%a0
        jmp (%a0)
        .size gk_persistence_work_load_or_migrate,.-gk_persistence_work_load_or_migrate
        .global gk_persistence_destination_reset
        .type gk_persistence_destination_reset,@function
gk_persistence_destination_reset:
        movea.l #gk_v3_destination_reset_impl,%a0
        jmp (%a0)
        .size gk_persistence_destination_reset,.-gk_persistence_destination_reset
        .global gk_persistence_destination_create
        .type gk_persistence_destination_create,@function
gk_persistence_destination_create:
        movea.l #gk_v3_destination_create_impl,%a0
        jmp (%a0)
        .size gk_persistence_destination_create,.-gk_persistence_destination_create
        .global gk_persistence_new_project_create
        .type gk_persistence_new_project_create,@function
gk_persistence_new_project_create:
        movea.l #gk_v3_new_project_create_impl,%a0
        jmp (%a0)
        .size gk_persistence_new_project_create,.-gk_persistence_new_project_create
        .global gk_persistence_bank_store
        .type gk_persistence_bank_store,@function
gk_persistence_bank_store:
        move.l %d0,-(%sp)
        movea.l #gk_v3_bank_store_impl,%a0
        jsr (%a0)
        addq.l #4,%sp
        rts
        .size gk_persistence_bank_store,.-gk_persistence_bank_store
        .global gk_persistence_bank_reload
        .type gk_persistence_bank_reload,@function
gk_persistence_bank_reload:
        move.l %d0,-(%sp)
        movea.l #gk_v3_bank_reload_impl,%a0
        jsr (%a0)
        addq.l #4,%sp
        rts
        .size gk_persistence_bank_reload,.-gk_persistence_bank_reload
        .global gk_persistence_migrate_resident_bank
        .type   gk_persistence_migrate_resident_bank,@function
gk_persistence_migrate_resident_bank:
        move.l  %d0,-(%sp)
        move.l  %a0,-(%sp)
        movea.l #gk_v3_migrate_resident_bank_impl,%a0
        jsr     (%a0)
        addq.l  #8,%sp
        rts
        .size   gk_persistence_migrate_resident_bank,.-gk_persistence_migrate_resident_bank
        .global gk_persistence_stock_stored_bank_load
        .type   gk_persistence_stock_stored_bank_load,@function
gk_persistence_stock_stored_bank_load:
        move.l  %d0,-(%sp)
        move.l  %a0,-(%sp)
        movea.l #gk_v3_stock_stored_bank_load_impl,%a0
        jsr     (%a0)
        addq.l  #8,%sp
        rts
        .size   gk_persistence_stock_stored_bank_load,.-gk_persistence_stock_stored_bank_load
        .global gk_persistence_v3_mark_kit_dirty
        .type gk_persistence_v3_mark_kit_dirty,@function
gk_persistence_v3_mark_kit_dirty:
        move.l %d0,-(%sp)
        movea.l #gk_v3_mark_kit_dirty_impl,%a0
        jsr (%a0)
        addq.l #4,%sp
        rts
        .size gk_persistence_v3_mark_kit_dirty,.-gk_persistence_v3_mark_kit_dirty
        .global gk_persistence_v3_mark_assignment_dirty
        .type   gk_persistence_v3_mark_assignment_dirty,@function
gk_persistence_v3_mark_assignment_dirty:
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        movea.l #gk_v3_mark_assignment_dirty_impl,%a0
        jsr     (%a0)
        addq.l  #8,%sp
        rts
        .size   gk_persistence_v3_mark_assignment_dirty,.-gk_persistence_v3_mark_assignment_dirty
