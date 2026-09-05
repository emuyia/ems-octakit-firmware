RUNTIME_START = 0x45d0dde0;
RUNTIME_END = 0x46025de0;
RUNTIME_CODE_BUDGET = 1
    ? 0x00025000
    : 1
    ? (1
       ? 0x00024000
       : (1
          ? 0x00023000 : 0x00022000))
    : 1
    ? 0x00021000 : 0x00020000;
BOOTSTRAP_LOAD = 0x4010fdf0;
SDRAM_ALIAS_DELTA = 0x08000000;
STAGE_ADDRESS = 1 ? 0x47fc7410 : 0x47fc8000;
STAGE_UNCACHED_ADDRESS = STAGE_ADDRESS + SDRAM_ALIAS_DELTA;
PART_PAYLOAD_SIZE = 0x000018b2;
KIT_COUNT = 256;
SPILL_COUNT = 128;
DESCRIPTOR_COUNT = 128;
DESCRIPTOR_SIZE = 16;
LEASE_SIDECAR_COUNT = 115;
LEASE_SIDECAR_SIZE = 2;
METADATA_SIZE = 0x000013a4;
UI_SIZE = 0x00001800;
UI_ROW_SIZE = 15;
KIT_LIST_ROW_COUNT = 1 ? KIT_COUNT + 1 : KIT_COUNT;
IO_BUFFER_SIZE = 1
    ? 0x00022620 : 0x00001020;
PROJECT_IO_EXTRA_SIZE = 1
    ? 0x00021600 : 0;
PROJECT_RELOAD_CODE_EXTRA_SIZE =
    1 ? 0x00001000 : 0;
QUEUE_COMMIT_CODE_EXTRA_SIZE =
    1 ? 0x00001000 : 0;
PLAYBACK_HANDOFF_CODE_EXTRA_SIZE =
    1 ? 0x00001000 : 0;
CROSS_BANK_PLAYBACK_CODE_EXTRA_SIZE =
    1 ? 0x00001000 : 0;
PATTERN_KIT_PASTE_CODE_EXTRA_SIZE =
    1 ? 0x00001000 : 0;
GUARD_SIZE = 0x00001000;
KIT_V3_CLIPBOARD_SIZE = 1 ? 0x00003180 : 0;
FIXED_RECORD_V3_SIZE = 1 ? 0x00002840 : 0;

SECTIONS
{
    /*
     * These two sections are empty for the standalone primitive build.  The
     * explicitly experimental firmware builder adds a small early loader and
     * stage anchor, making .early/.stage/.runtime one contiguous append image
     * while preserving the runtime's hardware-proved VMA and exact bytes.
     */
    .early BOOTSTRAP_LOAD :
    {
        __gk_extension_load_start = .;
        KEEP(*(.early))
        __gk_extension_early_end = .;
    }

    .stage STAGE_ADDRESS : AT(LOADADDR(.early) + SIZEOF(.early))
    {
        __gk_stage_start = .;
        KEEP(*(.stage))
        __gk_packed_runtime_start = .;
        KEEP(*(.stage.packed))
        __gk_packed_runtime_end = .;
        __gk_stage_end = .;
    }
    __gk_stage_load_start = LOADADDR(.stage);
    __gk_stage_uncached_start = STAGE_UNCACHED_ADDRESS;
    __gk_packed_runtime_load_start =
        LOADADDR(.stage) + (__gk_packed_runtime_start - ADDR(.stage));
    __gk_packed_runtime_load_end =
        LOADADDR(.stage) + (__gk_packed_runtime_end - ADDR(.stage));
    __gk_packed_runtime_size =
        __gk_packed_runtime_end - __gk_packed_runtime_start;
    __gk_packed_runtime_uncached_start =
        __gk_packed_runtime_start + SDRAM_ALIAS_DELTA;

    .runtime RUNTIME_START : AT(LOADADDR(.stage) + SIZEOF(.stage))
    {
        __gk_runtime_start = .;
        KEEP(*(.runtime))
        KEEP(*(.runtime.*))
        __gk_runtime_end = .;
    }
    __gk_runtime_size = SIZEOF(.runtime);
    __gk_runtime_load_start = LOADADDR(.runtime);
    __gk_runtime_stage_start = ADDR(.stage) + SIZEOF(.stage);
    __gk_runtime_stage_uncached_start =
        STAGE_UNCACHED_ADDRESS + SIZEOF(.stage);
    __gk_runtime_uncached_start = RUNTIME_START + SDRAM_ALIAS_DELTA;
    __gk_stage_load_size = 1
        ? SIZEOF(.stage)
        : SIZEOF(.stage) + SIZEOF(.runtime);
    __gk_extension_load_size = 1
        ? SIZEOF(.early) + SIZEOF(.stage)
        : SIZEOF(.early) + SIZEOF(.stage) + SIZEOF(.runtime);
    __gk_runtime_code_budget_end = RUNTIME_START + RUNTIME_CODE_BUDGET;

    .gk_canonical __gk_runtime_code_budget_end (NOLOAD) :
    {
        __gk_canonical_payloads = .;
        . += KIT_COUNT * PART_PAYLOAD_SIZE;
        __gk_canonical_payloads_end = .;
    }

    .gk_spills (NOLOAD) :
    {
        __gk_spill_payloads = .;
        . += SPILL_COUNT * PART_PAYLOAD_SIZE;
        __gk_spill_payloads_end = .;
    }
    __gk_undo_kit_payload_a =
        __gk_spill_payloads + (SPILL_COUNT - 2) * PART_PAYLOAD_SIZE;
    __gk_undo_kit_payload_b =
        __gk_spill_payloads + (SPILL_COUNT - 1) * PART_PAYLOAD_SIZE;
    /* Compatibility geometry symbol; active payload is selected by the
     * volatile __gk_undo_kit_payload_ptr state word. */
    __gk_undo_kit_payload = __gk_undo_kit_payload_a;
    __gk_pattern_kit_rollback_payload = __gk_spill_payloads +
        (SPILL_COUNT - 4) * PART_PAYLOAD_SIZE;
    __gk_pattern_kit_payload = __gk_spill_payloads +
        (SPILL_COUNT - 3) * PART_PAYLOAD_SIZE;

    .gk_metadata ALIGN(32) (NOLOAD) :
    {
        __gk_metadata_start = .;

        __gk_descriptors = .;
        . += DESCRIPTOR_COUNT * DESCRIPTOR_SIZE;
        __gk_descriptors_end = .;

        /*
         * Each lease sidecar is one atomic big-endian word:
         *   byte 0 = currently published descriptor ID
         *   byte 1 = pending descriptor ID, or 0xff while stable.
         * The eight non-leasing coherence IDs share this 0x100-byte region.
         */
        __gk_lease_sidecars = .;
        . += LEASE_SIDECAR_COUNT * LEASE_SIDECAR_SIZE;
        __gk_lease_sidecars_end = .;
        __gk_coherence_sidecars = .;
        . += 8;
        __gk_coherence_sidecars_end = .;
        . += 0x100 - (LEASE_SIDECAR_COUNT * LEASE_SIDECAR_SIZE) - 8;

        /* Four bytes per stock physical staging record. */
        __gk_physical_cache = .;
        . += 64 * 4;
        __gk_physical_cache_end = .;

        __gk_pattern_assignments = .;
        . += 256;
        __gk_pattern_assignments_end = .;

        __gk_pattern_assignment_valid = .;
        . += 32;
        __gk_pattern_assignment_valid_end = .;

        __gk_initialized_bitmap = .;
        . += 32;
        __gk_initialized_bitmap_end = .;

        __gk_kit_names = .;
        . += KIT_COUNT * 8;
        __gk_kit_names_end = .;

        __gk_descriptor_bitmap = .;
        . += 16;
        __gk_descriptor_bitmap_end = .;

        __gk_spill_bitmap = .;
        . += 16;
        __gk_spill_bitmap_end = .;

        __gk_current_state = .;
        __gk_workspace_descriptor = .;
        . += 1;
        __gk_current_bank = .;
        . += 1;
        __gk_current_pattern = .;
        . += 1;
        __gk_current_kit = .;
        . += 1;
        __gk_workspace_dirty = .;
        . += 1;
        __gk_descriptor_cursor = .;
        . += 1;
        __gk_spill_cursor = .;
        . += 1;
        __gk_runtime_flags = .;
        . += 1;
        __gk_physical_victim_cursors = .;
        . += 16;
        __gk_workspace_name = .;
        . += 8;
        __gk_workspace_name_pad = .;
        . += 1;
        __gk_workspace_bound = .;
        . += 1;
        __gk_pending_workspace_descriptor = .;
        . += 1;
        __gk_pending_bank = .;
        . += 1;
        __gk_pending_pattern = .;
        . += 1;
        __gk_pending_kit = .;
        . += 1;
        __gk_pending_transition_flags = .;
        . += 1;
        __gk_pending_ui_capture_created = .;
        . += 1;
        __gk_pending_workspace_bound = .;
        . += 1;
        __gk_promotion_assign = .;
        . += 1;
        __gk_pending_state_pad = .;
        /*
         * D49 transient ownership marker.  This aliases the first byte of
         * the existing two-byte pending-state pad, so every historical SRAM
         * address and reservation remains unchanged.  Metadata reset clears
         * it together with the rest of the current-state block.
         */
        __gk_sequencer_latch_queue_handoff = .;
        . += 2;
        /*
         * The second historical pad byte authenticates a Kit transaction
         * prepared by the queued-Pattern commit entry.  D49's latch marker
         * remains the first byte; no metadata or persistence geometry grows.
         */
        __gk_pattern_queue_commit_prepared =
            __gk_pending_state_pad + 1;
        __gk_persistence_state = .;
        __gk_persistence_work_slot = .;
        . += 1;
        __gk_persistence_stored_slot = .;
        . += 1;
        __gk_persistence_flags = .;
        . += 1;
        __gk_persistence_reserved = .;
        . += 1;
        __gk_persistence_work_generation = .;
        . += 4;
        __gk_persistence_stored_generation = .;
        . += 4;
        __gk_persistence_last_error = .;
        . += 4;
        __gk_persistence_reserved_tail = .;
        __gk_persistence_snapshot_gate = .;
        . += 4;
        __gk_persistence_snapshot_reserved = .;
        . += 4;
        __gk_persistence_reserved_tail_end = .;
        __gk_persistence_state_end = .;
        __gk_current_state_end = .;

        __gk_metadata_end = .;
    }

    /*
     * Project/bank replacement must be visible to periodic stock-hook
     * wrappers while metadata and UI are being cleared.  Keep this exact
     * longword outside both reset ranges.
     */
    .gk_lifecycle (NOLOAD) :
    {
        __gk_lifecycle_state = .;
        . += 4;
        __gk_lifecycle_state_end = .;
    }

    .gk_ui (NOLOAD) :
    {
        __gk_ui_start = .;

        /*
         * Fixed LOAD KIT / SAVE AS tables:
         *   "001 " + eight-byte name + " " + marker + NUL.
         */
        __gk_ui_rows = .;
        . += KIT_LIST_ROW_COUNT * UI_ROW_SIZE;
        __gk_ui_rows_end = .;
        . = ALIGN(4);

        __gk_ui_label_pointers = .;
        . += KIT_LIST_ROW_COUNT * 4;
        __gk_ui_label_pointers_end = .;

        __gk_ui_callback_pointers = .;
        . += KIT_LIST_ROW_COUNT * 4;
        __gk_ui_callback_pointers_end = .;

        __gk_ui_referenced_bitmap = .;
        . += KIT_COUNT / 8;
        __gk_ui_referenced_bitmap_end = .;

        __gk_ui_selected_kit = .;
        . += 4;
        __gk_ui_selected_row = .;
        . += 1 ? 4 : 0;
        __gk_undo_kit_valid = .;
        . += 1 ? 1 : 0;
        __gk_undo_kit_bound = .;
        . += 1 ? 1 : 0;
        __gk_undo_kit_kit = .;
        . += 1 ? 1 : 0;
        __gk_undo_kit_loading = .;
        . += 1 ? 1 : 0;
        __gk_undo_kit_name = .;
        . += 1 ? 8 : 0;
        __gk_undo_kit_payload_ptr = .;
        . += 1 ? 4 : 0;
        __gk_undo_pending_owner = .;
        . += 1 ? 1 : 0;
        __gk_undo_pending_bound = .;
        . += 1 ? 1 : 0;
        __gk_undo_pending_kit = .;
        . += 1 ? 1 : 0;
        __gk_undo_pending_reserved = .;
        . += 1 ? 1 : 0;
        __gk_undo_pending_name = .;
        . += 1 ? 8 : 0;
        __gk_undo_pending_payload_ptr = .;
        . += 1 ? 4 : 0;
        __gk_ui_context_bank = .;
        . += 1;
        __gk_ui_context_pattern = .;
        . += 1;
        __gk_ui_context_kit = .;
        . += 1;
        __gk_ui_mode = .;
        . += 1;

        /*
         * The stock four-row PART EDIT menu and two-row SAVE AS overwrite
         * confirmation each retain their own 32-bit absolute selection.
         * RENAME edits a private eight-byte scratch name because the stock
         * editor writes through its caller pointer before invoking the
         * completion callback.
         */
        __gk_ui_part_edit_selection = .;
        . += 4;
        __gk_ui_confirm_selection = .;
        . += 4;
        __gk_ui_rename_name = .;
        . += 8;
        __gk_ui_rename_name_pad = .;
        . += 1;
        __gk_ui_state_pad = .;
        . += 3;
        __gk_pattern_kit_state_start = .;
        __gk_pattern_kit_valid = .;
        . += 1 ? 1 : 0;
        __gk_pattern_kit_armed = .;
        . += 1 ? 1 : 0;
        __gk_pattern_kit_bank = .;
        . += 1 ? 1 : 0;
        __gk_pattern_kit_pattern = .;
        . += 1 ? 1 : 0;
        __gk_pattern_kit_name = .;
        . += 1 ? 8 : 0;
        __gk_pattern_kit_rollback_name = .;
        . += 1 ? 8 : 0;
        __gk_pattern_kit_rollback_occupied = .;
        . += 1 ? 1 : 0;
        __gk_pattern_kit_rollback_target = .;
        . += 1 ? 1 : 0;
        . += 1 ? 2 : 0;
        __gk_pattern_kit_state_end = .;
        __gk_ui_state_end = .;

        /*
         * Event 0x14 must compare the latest staged Kit against the actual
         * previously visible Kit, even after event 0x15 changes bank.  Keep
         * that eight-byte machine-selector snapshot outside the rebuilt menu
         * tables.  PENDING is published last by the transition preparer and
         * cleared atomically with current-Part publication by the consumer.
         */
        __gk_ui_transition_start = .;
        __gk_ui_transition_pending = .;
        . += 1;
        __gk_ui_transition_source_descriptor = .;
        . += 1;
        __gk_ui_transition_source_bank = .;
        . += 1;
        __gk_ui_transition_source_part = .;
        . += 1;
        __gk_ui_transition_old_machines = .;
        . += 8;
        __gk_ui_transition_reserved = .;
        . += 4;
        __gk_ui_transition_end = .;

        /*
         * The arranger may encounter the scheduler before or after it changes
         * between immediate and queued mode.  This bounded record owns only
         * two Scene bytes and, while immediate, the already-open workspace
         * transaction.  KIND is published last and cleared first under IPL7.
         */
        __gk_arranger_state_start = .;
        __gk_arranger_kind = .;
        . += 1;
        __gk_arranger_owner = .;
        . += 1;
        __gk_arranger_bank = .;
        . += 1;
        __gk_arranger_pattern = .;
        . += 1;
        __gk_arranger_kit = .;
        . += 1;
        __gk_arranger_descriptor = .;
        . += 1;
        __gk_arranger_scene_mask = .;
        . += 1;
        __gk_arranger_scene_a = .;
        . += 1;
        __gk_arranger_scene_b = .;
        . += 1;
        __gk_arranger_old_scene_a = .;
        . += 1;
        __gk_arranger_old_scene_b = .;
        . += 1;
        __gk_arranger_old_workspace_dirty = .;
        . += 1;
        __gk_arranger_old_descriptor_flags = .;
        . += 1;
        __gk_arranger_epoch = .;
        . += 1;
        __gk_arranger_token_active = .;
        . += 1;
        __gk_arranger_token_epoch = .;
        . += 1;
        __gk_arranger_consume_source = .;
        . += 1;
        __gk_arranger_consume_epoch = .;
        . += 1;
        __gk_arranger_reserved = .;
        . += 2;
        __gk_arranger_generation = .;
        . += 4;
        __gk_arranger_token_generation = .;
        . += 4;
        __gk_arranger_consume_generation = .;
        . += 4;
        __gk_arranger_state_end = .;

        /*
         * A normal task publisher is serialized against the level-two row
         * producer while level-five audio remains enabled.  DEPTH is two
         * only while the playback task's pre-write guard encloses its common
         * publisher guard.
         */
        __gk_arranger_guard_start = .;
        __gk_arranger_guard_depth = .;
        . += 1;
        __gk_arranger_playback_guard_active = .;
        . += 1;
        __gk_arranger_guard_reserved = .;
        . += 2;
        __gk_arranger_guard_saved_sr = .;
        . += 2;
        __gk_arranger_guard_saved_sr_pad = .;
        . += 2;
        __gk_arranger_guard_end = .;

        /*
         * Scene COPY/PASTE/CLEAR callbacks are synchronous task operations.
         * This four-byte record authenticates the sole live wrapper and
         * publishes the physical Part that its complete stock callback owns.
         * It lives in the reset UI arena and does not enlarge that arena.
         */
        __gk_scene_clipboard_state_start = .;
        __gk_scene_clipboard_active = .;
        . += 1;
        __gk_scene_clipboard_part = .;
        . += 1;
        __gk_scene_clipboard_reserved = .;
        __gk_scene_clipboard_descriptor = .;
        . += 1;
        __gk_scene_clipboard_descriptor_inverse = .;
        . += 1;
        __gk_scene_clipboard_state_end = .;

        /*
         * The two command-0x32 RELOAD PAGE records execute synchronously in
         * the UI task.  This reset-arena record prevents nested ownership and
         * authenticates the physical Part/track held by the stack frame.
         */
        __gk_reload_page_state_start = .;
        __gk_reload_page_active = .;
        . += 1;
        __gk_reload_page_part = .;
        . += 1;
        __gk_reload_page_track = .;
        . += 1;
        __gk_reload_page_active_inverse = .;
        . += 1;
        __gk_reload_page_state_end = .;

        /* Exact synchronous Page CLEAR/PASTE operation ownership. */
        __gk_page_clipboard_state_start = .;
        __gk_page_clipboard_active = .;
        . += 1;
        __gk_page_clipboard_part = .;
        . += 1;
        __gk_page_clipboard_track = .;
        . += 1;
        __gk_page_clipboard_active_inverse = .;
        . += 1;
        __gk_page_clipboard_state_end = .;

        /*
         * RANDOMIZE PAGE ownership is introduced after D34.  Its zero-size
         * historical form preserves every prior runtime and SRAM identity;
         * release-candidate builds opt into the four-byte live record.
         */
        __gk_randomize_page_state_start = .;
        __gk_randomize_page_active = .;
        . += 1 ? 1 : 0;
        __gk_randomize_page_part = .;
        . += 1 ? 1 : 0;
        __gk_randomize_page_track = .;
        . += 1 ? 1 : 0;
        __gk_randomize_page_active_inverse = .;
        . += 1 ? 1 : 0;
        __gk_randomize_page_state_end = .;

        /*
         * The machine-transition family is synchronous task code.  One
         * compact record authenticates the sole outer transaction, every
         * nested chooser/helper publication, and the eight-track Part-event
         * loop.  The UI arena is fixed-size, so enabling the record consumes
         * no additional reserved SRAM.
         */
        . = ALIGN(4);
        __gk_machine_transition_state_start = .;
        __gk_machine_transition_active = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_active_inverse = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_stage = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_count = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_part = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_track = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_descriptor = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_bank = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_pattern = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_kit = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_event_index = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_reserved = .;
        . += 1 ? 1 : 0;
        __gk_machine_transition_state_end = .;

        /*
         * CREATE RANDOM/LINEAR LOCKS are synchronous confirmation callbacks.
         * Their compact record authenticates the untouched stock body from
         * its object lookup through its single Part publication and tail.
         * Like D41, this consumes only the pre-reserved fixed-size UI arena.
         */
        . = ALIGN(4);
        __gk_slice_lock_state_start = .;
        __gk_slice_lock_active = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_active_inverse = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_marker_count = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_mode = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_part = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_track = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_descriptor = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_bank = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_pattern = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_kit = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_machine = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_reserved = .;
        . += 1 ? 1 : 0;
        __gk_slice_lock_slot = .;
        . += 1 ? 4 : 0;
        __gk_slice_lock_state_end = .;

        . = __gk_ui_start + UI_SIZE;
        __gk_ui_end = .;
    }

    .gk_io (NOLOAD) :
    {
        __gk_io_buffer = .;
        . += IO_BUFFER_SIZE;
        __gk_io_buffer_end = .;
    }

    /*
     * D33 fixed-record persistence keeps one complete 13-sector record and
     * only bounded A/B selection state.  Historical checkpoints define a
     * zero-length range and therefore retain their exact SRAM addresses.
     */
    .gk_persistence_v3 (NOLOAD) :
    {
        __gk_v3_start = .;
        __gk_v3_record_stage = .;
        . += 1 ? 0x1a00 : 0;
        __gk_v3_record_stage_end = .;

        __gk_v3_work_generations = .;
        . += 1 ? 0x400 : 0;
        __gk_v3_stored_generations = .;
        . += 1 ? 0x400 : 0;
        __gk_v3_work_source_bitmap = .;
        . += 1 ? 0x20 : 0;
        __gk_v3_stored_source_bitmap = .;
        . += 1 ? 0x20 : 0;
        __gk_v3_work_valid_bitmap = .;
        . += 1 ? 0x20 : 0;
        __gk_v3_stored_valid_bitmap = .;
        . += 1 ? 0x20 : 0;
        __gk_v3_work_dirty_bitmap = .;
        . += 1 ? 0x20 : 0;
        __gk_v3_assignment_dependency_bitmap = .;
        . += 1 ? 0x20 : 0;
        __gk_v3_state_header = .;
        . += 1 ? 0x80 : 0;
        __gk_v3_state_header_end = .;
        __gk_v3_peer_summaries = .;
        . += 1 ? 0x500 : 0;
        __gk_v3_peer_summaries_end = .;
        __gk_v3_end = .;
    }

    .gk_guard (NOLOAD) :
    {
        __gk_guard_start = .;
        . += GUARD_SIZE;
        __gk_guard_end = .;
    }

    /*
     * A partial stock bank replacement destroys descriptor ownership but
     * must not erase saved-but-not-yet-card-synced global metadata or the
     * one dirty mutable workspace.  This bounded handoff record is outside
     * every reset range and is valid only while the lifecycle gate is
     * QUIESCED.  MAGIC is published after the complete atomic capture.
     */
    .gk_lifecycle_scratch (NOLOAD) :
    {
        __gk_lifecycle_scratch_start = .;
        __gk_lifecycle_scratch_magic = .;
        . += 4;
        __gk_lifecycle_scratch_flags = .;
        . += 1;
        __gk_lifecycle_scratch_kit = .;
        . += 1;
        __gk_lifecycle_scratch_bank = .;
        . += 1;
        __gk_lifecycle_scratch_pattern = .;
        . += 1;
        __gk_lifecycle_scratch_runtime_flags = .;
        . += 1;
        __gk_lifecycle_scratch_bound = .;
        . += 1;
        __gk_lifecycle_scratch_header_pad = .;
        . += 2;
        __gk_lifecycle_scratch_persistence = .;
        . += 24;
        __gk_lifecycle_scratch_library = .;
        . += 0x940;
        __gk_lifecycle_scratch_workspace_name = .;
        . += 8;
        __gk_lifecycle_scratch_payload = .;
        . += PART_PAYLOAD_SIZE;
        . = __gk_lifecycle_scratch_start + 0x2228;
        __gk_lifecycle_scratch_end = .;
    }

    /* Exact stock-initialized source for an ephemeral unbound workspace. */
    .gk_default_payload (NOLOAD) :
    {
        __gk_default_payload = .;
        . += PART_PAYLOAD_SIZE;
        __gk_default_payload_end = .;
    }

    /* Transient Kit COPY and one-level PASTE/CLEAR undo. */
    .gk_kit_clipboard (NOLOAD) :
    {
        __gk_kit_clipboard_start = .;
        . += 1 ? 2 : 0;
        __gk_kit_clipboard_payload = .;
        . += 1 ? PART_PAYLOAD_SIZE : 0;
        __gk_kit_clipboard_name = .;
        . += 1 ? 8 : 0;
        __gk_kit_clipboard_occupied = .;
        . += 1 ? 1 : 0;
        __gk_kit_clipboard_valid = .;
        . += 1 ? 1 : 0;

        __gk_kit_undo_payload = .;
        . += 1 ? PART_PAYLOAD_SIZE : 0;
        __gk_kit_undo_name = .;
        . += 1 ? 8 : 0;
        __gk_kit_undo_occupied = .;
        . += 1 ? 1 : 0;
        __gk_kit_undo_valid = .;
        . += 1 ? 1 : 0;
        __gk_kit_undo_action = .;
        . += 1 ? 1 : 0;
        __gk_kit_undo_target = .;
        . += 1 ? 1 : 0;

        /* Keep the conditional ledger long-aligned without duplicate locks. */
        . += 1 ? 1 : 0;
        . += 1 ? 3 : 0;
        __gk_kit_clipboard_end = .;
    }

    __gk_planned_end = .;
    __gk_headroom = RUNTIME_END - __gk_planned_end;

    /*
     * A hardware checkpoint keeps a byte-identical recovery source at the
     * top of the same allocator-reserved arena.  The ordinary standalone
     * build defines a zero-length range so its existing memory ledger and
     * semantics remain unchanged.
     */
    __gk_runtime_backup_start = RUNTIME_END -
        (1 ? SIZEOF(.runtime) : 0);
    .gk_runtime_backup __gk_runtime_backup_start (NOLOAD) :
    {
        . += 1 ? SIZEOF(.runtime) : 0;
        __gk_runtime_backup_end = .;
    }
    __gk_runtime_backup_uncached_start =
        __gk_runtime_backup_start + SDRAM_ALIAS_DELTA;
    __gk_extension_ram_end = __gk_runtime_backup_end;

    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
        *(.note*)
    }
}

ASSERT(__gk_runtime_end <= __gk_runtime_code_budget_end,
       "global-Kit runtime code exceeds its 128 KiB allowance")
ASSERT(__gk_canonical_payloads_end - __gk_canonical_payloads == 0x18b200,
       "global-Kit canonical payload geometry changed")
ASSERT(__gk_spill_payloads_end - __gk_spill_payloads == 0x0c5900,
       "global-Kit spill payload geometry changed")
ASSERT(__gk_descriptors_end - __gk_descriptors == 0x800,
       "global-Kit descriptor geometry changed")
ASSERT(__gk_lease_sidecars_end - __gk_lease_sidecars == 230,
       "global-Kit lease sidecar geometry changed")
ASSERT(__gk_persistence_state_end - __gk_persistence_state == 24,
       "global-Kit persistence-state geometry changed")
ASSERT(__gk_metadata_end - __gk_metadata_start == METADATA_SIZE,
       "global-Kit metadata exceeds its explicit budget")
ASSERT(__gk_lifecycle_state_end - __gk_lifecycle_state == 4,
       "global-Kit lifecycle gate geometry changed")
ASSERT(__gk_ui_rows_end - __gk_ui_rows ==
       (1 ? 0x0f0f : 0x0f00),
       "global-Kit UI row geometry changed")
ASSERT(__gk_ui_label_pointers_end - __gk_ui_label_pointers ==
       (1 ? 0x404 : 0x400),
       "global-Kit UI label-pointer geometry changed")
ASSERT(__gk_ui_callback_pointers_end - __gk_ui_callback_pointers ==
       (1 ? 0x404 : 0x400),
       "global-Kit UI callback-pointer geometry changed")
ASSERT(__gk_ui_referenced_bitmap_end - __gk_ui_referenced_bitmap == 0x20,
       "global-Kit UI reference bitmap geometry changed")
ASSERT(__gk_arranger_state_end - __gk_arranger_state_start == 32,
       "global-Kit arranger transaction geometry changed")
ASSERT(__gk_arranger_guard_end - __gk_arranger_guard_start == 8,
       "global-Kit arranger guard geometry changed")
ASSERT(__gk_scene_clipboard_state_end -
       __gk_scene_clipboard_state_start == 4,
       "global-Kit Scene clipboard state geometry changed")
ASSERT(__gk_reload_page_state_end -
       __gk_reload_page_state_start == 4,
       "global-Kit RELOAD PAGE state geometry changed")
ASSERT(__gk_page_clipboard_state_end -
       __gk_page_clipboard_state_start == 4,
       "global-Kit Page clipboard state geometry changed")
ASSERT(__gk_randomize_page_state_end -
       __gk_randomize_page_state_start ==
       (1 ? 4 : 0),
       "global-Kit RANDOMIZE PAGE state geometry changed")
ASSERT(__gk_ui_end - __gk_ui_start == UI_SIZE,
       "global-Kit UI exceeds its explicit budget")
ASSERT(__gk_io_buffer_end - __gk_io_buffer == IO_BUFFER_SIZE,
       "global-Kit persistence I/O arena geometry changed")
ASSERT(__gk_lifecycle_scratch_persistence -
       __gk_lifecycle_scratch_start == 0x0c,
       "global-Kit lifecycle scratch persistence offset changed")
ASSERT(__gk_lifecycle_scratch_library -
       __gk_lifecycle_scratch_start == 0x24,
       "global-Kit lifecycle scratch library offset changed")
ASSERT(__gk_lifecycle_scratch_payload -
       __gk_lifecycle_scratch_start == 0x96c,
       "global-Kit lifecycle scratch payload offset changed")
ASSERT(__gk_lifecycle_scratch_end -
       __gk_lifecycle_scratch_start == 0x2228,
       "global-Kit lifecycle scratch geometry changed")
ASSERT(__gk_default_payload_end - __gk_default_payload == PART_PAYLOAD_SIZE,
       "global-Kit ephemeral default payload geometry changed")
ASSERT(__gk_kit_clipboard_end - __gk_kit_clipboard_start ==
       KIT_V3_CLIPBOARD_SIZE,
       "global-Kit v3 clipboard geometry changed")
ASSERT(__gk_v3_record_stage_end - __gk_v3_record_stage ==
       (1 ? 0x1a00 : 0),
       "global-Kit v3 record stage geometry changed")
ASSERT(__gk_v3_state_header_end - __gk_v3_work_generations ==
       (1 ? 0x940 : 0),
       "global-Kit v3 bounded state geometry changed")
ASSERT(__gk_v3_peer_summaries_end - __gk_v3_peer_summaries ==
       (1 ? 0x500 : 0),
       "global-Kit v3 peer-summary scratch geometry changed")
ASSERT(__gk_v3_end - __gk_v3_start == FIXED_RECORD_V3_SIZE,
       "global-Kit v3 persistence reservation changed")
ASSERT(__gk_planned_end == RUNTIME_START + 0x2791a2 + KIT_V3_CLIPBOARD_SIZE +
       FIXED_RECORD_V3_SIZE + PROJECT_IO_EXTRA_SIZE +
       PROJECT_RELOAD_CODE_EXTRA_SIZE + QUEUE_COMMIT_CODE_EXTRA_SIZE +
       PLAYBACK_HANDOFF_CODE_EXTRA_SIZE +
       CROSS_BANK_PLAYBACK_CODE_EXTRA_SIZE +
       PATTERN_KIT_PASTE_CODE_EXTRA_SIZE,
       "global-Kit runtime ledger changed")
ASSERT(__gk_planned_end <= RUNTIME_END,
       "global-Kit runtime exceeds the reserved recorder pages")
ASSERT(__gk_headroom == 0x0009ee5e - KIT_V3_CLIPBOARD_SIZE -
       FIXED_RECORD_V3_SIZE - PROJECT_IO_EXTRA_SIZE -
       PROJECT_RELOAD_CODE_EXTRA_SIZE - QUEUE_COMMIT_CODE_EXTRA_SIZE -
       PLAYBACK_HANDOFF_CODE_EXTRA_SIZE -
       CROSS_BANK_PLAYBACK_CODE_EXTRA_SIZE -
       PATTERN_KIT_PASTE_CODE_EXTRA_SIZE,
       "global-Kit reserved-page headroom changed")
ASSERT(!1 ||
       __gk_runtime_backup_start >= __gk_planned_end,
       "global-Kit runtime backup overlaps planned persistent state")
ASSERT(__gk_runtime_backup_end <= RUNTIME_END,
       "global-Kit runtime backup exceeds reserved recorder pages")
ASSERT(__gk_stage_start >= 0x47fc7410,
       "global-Kit transient stage overlaps stock mirrored SDRAM clear")
ASSERT(__gk_stage_start + __gk_stage_load_size <= 0x47fe0000,
       "global-Kit transient stage leaves less than 128 KiB below SP")
