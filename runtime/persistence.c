/*
 * Sector-aligned project-global Kit persistence format v3.
 *
 * This is freestanding target code: no libc, allocator, division helper, or
 * writable static storage is permitted.  All mutable storage is explicitly
 * reserved by link.ld inside the recorder-page arena.  The assembly veneer
 * preserves the existing register ABI and pins every stock call instruction.
 */

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef GK_V3_HOST_TEST
#define CODE __attribute__((noinline))
#define DATA
#else
#define CODE __attribute__((section(".runtime.v3.c"), used, noinline))
#define DATA __attribute__((section(".runtime.v3.data"), used))
#endif
#define INLINE static inline __attribute__((always_inline))

enum {
    GK_OK = 0,
    GK_ERR_INVALID = -1,
    GK_ERR_BUSY = -3,
    GK_ERR_CORRUPT = -6,
    GK_ERR_RANGE = -7,
    GK_ERR_CONFLICT = -8,
    GK_ERR_IO = -9,
    GK_ERR_NOT_FOUND = -10,

    KIT_COUNT = 256,
    PATTERN_COUNT = 256,
    PART_PAYLOAD_SIZE = 0x18B2,
    KIT_NAME_SIZE = 8,
    KIT_VISIBLE_NAME_SIZE = 7,
    FILE_BUFFER_SIZE = 0x200,
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    STREAM_BUFFER_SIZE = 0x10000,
    IO_READ_BUFFER_OFFSET = 0,
    IO_WRITE_BUFFER_OFFSET = 0x10000,
    IO_FIXED_BUFFER_OFFSET = 0x20000,
    IO_ASSIGNMENT_BUFFER_OFFSET = 0x21A00,
    IO_COMPARE_BUFFER_OFFSET = 0x21B20,
    IO_COMPARE_BUFFER_SIZE = 0xB00,
    IO_BUFFER_SIZE = 0x22620,
#else
    IO_ASSIGNMENT_BUFFER_OFFSET = 0x400,
    IO_COMPARE_BUFFER_OFFSET = 0x520,
    IO_COMPARE_BUFFER_SIZE = 0xB00,
    IO_BUFFER_SIZE = 0x1020,
#endif
    FILE_OBJECT_BUFFERED_COUNT_WORD = 3,
    FILE_OBJECT_LOGICAL_LENGTH_WORD = 4,
    PROJECT_PATH_SIZE = 260,

    V3_VERSION = 3,
    V3_SECTOR_SIZE = 0x200,
    V3_SUPERBLOCK_SIZE = 0x200,
    V3_MANIFEST_SIZE = 0x200,
    V3_ROOT_OFFSET = 0x200,
    V3_OVERLAY_OFFSET = 0x400,
    V3_RECORDS_OFFSET = 0x600,
    V3_RECORD_SIZE = 0x1A00,
    V3_PEER_SIZE = 0x1A0600,
    V3_RECORD_CRC_OFFSET = 0x19FC,
    V3_RECORD_NAME_OFFSET = 0x20,
    V3_RECORD_PAYLOAD_OFFSET = 0x28,
    V3_RECORD_PADDING_OFFSET = 0x18DA,
    V3_BLOCK_CRC_OFFSET = 0x1FC,
    V3_MANIFEST_ASSIGNMENTS_OFFSET = 0x20,
    V3_MANIFEST_VALID_OFFSET = 0x120,
    V3_MANIFEST_PADDING_OFFSET = 0x140,

    V3_KIND_WORK = 0,
    V3_KIND_STORED = 1,
    V3_ROLE_ROOT = 0,
    V3_ROLE_OVERLAY = 1,
    V3_FLAG_STORED_PENDING = 0x01,
    V3_KIT_FLAG_OCCUPIED = 0x01,

    V3_STATE_MAGIC = 0x4F544B33,
    V3_STATE_WORK_READY = 0x00000001,
    V3_STATE_STORED_READY = 0x00000002,
    V3_STATE_WORK_OVERLAY_DIRTY = 0x00000004,
    V3_STATE_WORK_FULL_DIRTY = 0x00000008,
    V3_STATE_WORK_OVERLAY_UNKNOWN = 0x00000010,

    RUNTIME_STORAGE_DIRTY = 0x01,
    PERSIST_WORK_KNOWN = 0x01,
    PERSIST_STORED_KNOWN = 0x02,
    PERSIST_STORED_PENDING = 0x04,
    PERSIST_KNOWN_FLAGS = 0x07,
    PERSIST_SLOT_NONE = 0xFF,
    PERSIST_SNAPSHOT_ACTIVE = 0x4B495450,
    PERSIST_RELOAD_BANK = 1,
    PERSIST_RELOAD_PROJECT = 2,
    PERSIST_RELOAD_MAX = 2,

    LEGACY_VERSION_V1 = 1,
    LEGACY_VERSION_V2 = 2,
    LEGACY_HEADER_SIZE = 26,
    LEGACY_META_SIZE_V1 = 0x820,
    LEGACY_META_SIZE_V2 = 0x940,
    LEGACY_PAYLOAD_SIZE = 0x18B200,
    LEGACY_SIZE_V1 = 0x18BA3E,
    LEGACY_SIZE_V2 = 0x18BB5E,

    STOCK_RESIDENT_BANK_BASE = 0x400E21E0,
    STOCK_BANK_STRIDE = 0x9B340,
    STOCK_PATTERN_STRIDE = 0x8ED8,
    STOCK_PATTERN_PART_OFFSET = 0x8E57,
    STOCK_BANK_WORKING_OFFSET = 0x8ED80,
    STOCK_BANK_NAMES_OFFSET = 0x9B316,
    STOCK_BANK_SIZE = 0x9B4D1,
    STOCK_FILE_SIZE_VECTOR = 0x46C8241E,
};

typedef struct {
    uint32_t words[6];
} FileObject;

typedef struct {
    bool valid;
    uint8_t flags;
    uint32_t container_epoch;
    uint32_t image_epoch;
    uint32_t generation;
    uint8_t assignments[PATTERN_COUNT];
    uint8_t assignment_valid[PATTERN_COUNT / 8];
} ManifestSummary;

typedef struct {
    bool transport_error;
    bool superblock_valid;
    uint32_t container_epoch;
    ManifestSummary root;
    ManifestSummary overlay;
} PeerSummary;

typedef struct {
    uint32_t magic;
    uint32_t flags;
    uint32_t work_container_epoch[2];
    uint32_t stored_container_epoch[2];
    uint32_t work_image_epoch;
    uint32_t stored_image_epoch;
    uint32_t work_root_generation;
    uint32_t stored_root_generation;
    uint32_t work_manifest_generation;
    uint32_t stored_manifest_generation;
    uint8_t work_root_peer;
    uint8_t stored_root_peer;
    uint8_t work_manifest_peer;
    uint8_t stored_manifest_peer;
    uint8_t work_flags;
    uint8_t stored_flags;
    uint8_t reserved[74];
} V3StateHeader;

typedef char assert_file_object_size[(sizeof(FileObject) == 24) ? 1 : -1];
typedef char assert_state_header_fits[(sizeof(V3StateHeader) <= 0x80) ? 1 : -1];
typedef char assert_peer_summary_scratch_fits[
    (sizeof(PeerSummary) * 2U <= 0x500U) ? 1 : -1
];
typedef char assert_io_buffer_layout[
    (IO_COMPARE_BUFFER_OFFSET + IO_COMPARE_BUFFER_SIZE == IO_BUFFER_SIZE)
        ? 1 : -1
];
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
typedef char assert_stream_buffer_sector_aligned[
    ((STREAM_BUFFER_SIZE % V3_SECTOR_SIZE) == 0U &&
      (IO_WRITE_BUFFER_OFFSET % V3_SECTOR_SIZE) == 0U &&
      (IO_FIXED_BUFFER_OFFSET % V3_SECTOR_SIZE) == 0U)
        ? 1 : -1
];
#endif

extern uint8_t __gk_pattern_assignments[];
extern uint8_t __gk_pattern_assignment_valid[];
extern uint8_t __gk_initialized_bitmap[];
extern uint8_t __gk_kit_names[];
extern uint8_t __gk_canonical_payloads[];
extern uint8_t __gk_default_payload[];
extern uint8_t __gk_spill_payloads[];
extern uint8_t __gk_io_buffer[];
extern uint8_t __gk_v3_record_stage[];
extern uint32_t __gk_v3_work_generations[];
extern uint32_t __gk_v3_stored_generations[];
extern uint8_t __gk_v3_work_source_bitmap[];
extern uint8_t __gk_v3_stored_source_bitmap[];
extern uint8_t __gk_v3_work_valid_bitmap[];
extern uint8_t __gk_v3_stored_valid_bitmap[];
extern uint8_t __gk_v3_work_dirty_bitmap[];
extern uint8_t __gk_v3_assignment_dependency_bitmap[];
extern V3StateHeader __gk_v3_state_header;
extern PeerSummary __gk_v3_peer_summaries[2];

extern uint8_t __gk_runtime_flags;
extern uint8_t __gk_persistence_work_slot;
extern uint8_t __gk_persistence_stored_slot;
extern uint8_t __gk_persistence_flags;
extern uint8_t __gk_persistence_reserved;
extern uint32_t __gk_persistence_work_generation;
extern uint32_t __gk_persistence_stored_generation;
extern int32_t __gk_persistence_last_error;
extern uint32_t __gk_persistence_snapshot_gate;

extern char *gk_v3_stock_current_project_directory(uint32_t, uint32_t);
extern int32_t gk_v3_stock_file_open(
    FileObject *, const char *, const char *, uint8_t *, uint32_t
);
extern int32_t gk_v3_stock_file_read(FileObject *, void *, uint32_t);
extern int32_t gk_v3_stock_file_seek(FileObject *, uint32_t);
extern int32_t gk_v3_stock_file_write(FileObject *, const void *, uint32_t);
extern int32_t gk_v3_stock_file_close(FileObject *);
extern int32_t gk_v3_stock_part_payload_initialize(void *);
extern int32_t gk_v3_stock_bank_deserialize(FileObject *, void *, uint32_t);
extern uint32_t gk_v3_irq_lock(void);
extern void gk_v3_irq_restore(uint32_t);
extern int32_t gk_persistence_snapshot_begin(void);
extern int32_t gk_persistence_snapshot_end(void);

#ifdef GK_V3_HOST_TEST
extern void gk_v3_host_event(uint32_t event, uint32_t value);
#define HOST_EVENT(event, value) gk_v3_host_event((event), (value))
#else
#define HOST_EVENT(event, value) ((void)0)
#endif

static const char mode_read[] DATA = "r";
static const char mode_write[] DATA = "w";
static const char work_a_suffix[] DATA = "/kits3a.work";
static const char work_b_suffix[] DATA = "/kits3b.work";
static const char stored_a_suffix[] DATA = "/kits3a.strd";
static const char stored_b_suffix[] DATA = "/kits3b.strd";
#ifndef GK_V3_PROJECT_IO_OPTIMIZED
static const char legacy_work_a_suffix[] DATA = "/kitsa.work";
static const char legacy_work_b_suffix[] DATA = "/kitsb.work";
static const char legacy_stored_a_suffix[] DATA = "/kitsa.strd";
static const char legacy_stored_b_suffix[] DATA = "/kitsb.strd";
#endif
static const char stock_bank_suffix[] DATA = "/bank01.strd";

static const uint8_t magic_superblock[8] DATA = {
    'O', 'T', 'K', '3', 'F', 'I', 'L', 'E'
};
static const uint8_t magic_root[8] DATA = {
    'O', 'T', 'K', '3', 'R', 'O', 'O', 'T'
};
static const uint8_t magic_overlay[8] DATA = {
    'O', 'T', 'K', '3', 'L', 'I', 'N', 'K'
};
static const uint8_t magic_record[8] DATA = {
    'O', 'T', 'K', '3', 'K', 'I', 'T', 'S'
};
#ifndef GK_V3_PROJECT_IO_OPTIMIZED
static const uint8_t magic_legacy[8] DATA = {
    'O', 'T', 'K', 'I', 'T', '2', '5', '6'
};
#endif

INLINE uint16_t load_u16(const uint8_t *data) {
    return (uint16_t)(((uint16_t)data[0] << 8) | data[1]);
}

INLINE uint32_t load_u32(const uint8_t *data) {
    return ((uint32_t)data[0] << 24) | ((uint32_t)data[1] << 16) |
           ((uint32_t)data[2] << 8) | data[3];
}

INLINE void store_u16(uint8_t *data, uint16_t value) {
    data[0] = (uint8_t)(value >> 8);
    data[1] = (uint8_t)value;
}

INLINE void store_u32(uint8_t *data, uint32_t value) {
    data[0] = (uint8_t)(value >> 24);
    data[1] = (uint8_t)(value >> 16);
    data[2] = (uint8_t)(value >> 8);
    data[3] = (uint8_t)value;
}

INLINE void bytes_clear(uint8_t *destination, uint32_t length) {
    while (length != 0U) {
        *destination++ = 0;
        --length;
    }
}

INLINE void bytes_fill(uint8_t *destination, uint8_t value, uint32_t length) {
    while (length != 0U) {
        *destination++ = value;
        --length;
    }
}

INLINE void bytes_copy(uint8_t *destination, const uint8_t *source,
                       uint32_t length) {
    while (length != 0U) {
        *destination++ = *source++;
        --length;
    }
}

INLINE bool bytes_equal(const uint8_t *left, const uint8_t *right,
                        uint32_t length) {
    while (length != 0U) {
        if (*left++ != *right++) {
            return false;
        }
        --length;
    }
    return true;
}

INLINE bool bytes_zero(const uint8_t *data, uint32_t length) {
    while (length != 0U) {
        if (*data++ != 0U) {
            return false;
        }
        --length;
    }
    return true;
}

#ifndef GK_V3_PROJECT_IO_OPTIMIZED
INLINE bool bytes_value(const uint8_t *data, uint8_t value,
                        uint32_t length) {
    while (length != 0U) {
        if (*data++ != value) {
            return false;
        }
        --length;
    }
    return true;
}
#endif

INLINE bool bitmap_test(const uint8_t *bitmap, uint32_t index) {
    return (bitmap[index >> 3] & (uint8_t)(1U << (index & 7U))) != 0U;
}

INLINE void bitmap_set(uint8_t *bitmap, uint32_t index) {
    bitmap[index >> 3] |= (uint8_t)(1U << (index & 7U));
}

INLINE void bitmap_clear(uint8_t *bitmap, uint32_t index) {
    bitmap[index >> 3] &= (uint8_t)~(uint8_t)(1U << (index & 7U));
}

INLINE bool bitmap_full(const uint8_t *bitmap) {
    uint32_t index = 0;
    while (index != KIT_COUNT / 8U) {
        if (bitmap[index] != 0xFFU) {
            return false;
        }
        ++index;
    }
    return true;
}

INLINE bool bitmap_empty(const uint8_t *bitmap) {
    uint32_t index = 0;
    while (index != KIT_COUNT / 8U) {
        if (bitmap[index] != 0U) {
            return false;
        }
        ++index;
    }
    return true;
}

INLINE uint32_t next_generation(uint32_t generation) {
    return generation + 1U;
}

INLINE int generation_compare(uint32_t left, uint32_t right) {
    uint32_t delta;
    if (left == right) {
        return 0;
    }
    delta = left - right;
    if (delta == 0x80000000U) {
        return 2;
    }
    return delta < 0x80000000U ? 1 : -1;
}

CODE uint32_t gk_v3_crc32_update_impl(const uint8_t *data, uint32_t length,
                                      uint32_t state) {
    uint32_t byte_index;
    if (data == NULL && length != 0U) {
        return (uint32_t)GK_ERR_RANGE;
    }
    while (length != 0U) {
        state ^= *data++;
        byte_index = 8U;
        while (byte_index != 0U) {
            state = (state >> 1) ^
                    ((state & 1U) != 0U ? 0xEDB88320U : 0U);
            --byte_index;
        }
        --length;
    }
    return state;
}

INLINE uint32_t block_crc(const uint8_t *data, uint32_t length) {
    return ~gk_v3_crc32_update_impl(data, length, 0xFFFFFFFFU);
}

INLINE bool block_crc_valid(const uint8_t *data, uint32_t crc_offset) {
    return load_u32(data + crc_offset) == block_crc(data, crc_offset);
}

CODE int32_t gk_v3_project_path_build_impl(char *destination,
                                           const char *suffix) {
    const char *base;
    uint32_t length = 0;
    if (destination == NULL || suffix == NULL) {
        return GK_ERR_RANGE;
    }
    base = gk_v3_stock_current_project_directory(0, 0);
    if (base == NULL) {
        destination[0] = 0;
        return GK_ERR_RANGE;
    }
    while (*base != 0) {
        if (length >= PROJECT_PATH_SIZE - 1U) {
            destination[0] = 0;
            return GK_ERR_RANGE;
        }
        destination[length++] = *base++;
    }
    while (*suffix != 0) {
        if (length >= PROJECT_PATH_SIZE - 1U) {
            destination[0] = 0;
            return GK_ERR_RANGE;
        }
        destination[length++] = *suffix++;
    }
    destination[length] = 0;
    return GK_OK;
}

INLINE const char *image_suffix(uint8_t kind, uint8_t peer) {
    if (kind == V3_KIND_WORK) {
        return peer == 0U ? work_a_suffix : work_b_suffix;
    }
    return peer == 0U ? stored_a_suffix : stored_b_suffix;
}

#ifndef GK_V3_PROJECT_IO_OPTIMIZED
INLINE const char *legacy_suffix(uint8_t kind, uint8_t peer) {
    if (kind == V3_KIND_WORK) {
        return peer == 0U ? legacy_work_a_suffix : legacy_work_b_suffix;
    }
    return peer == 0U ? legacy_stored_a_suffix : legacy_stored_b_suffix;
}
#endif

INLINE int32_t normalize_open_error(int32_t status) {
    if (status == -10 || status == -12) {
        return GK_ERR_NOT_FOUND;
    }
    return GK_ERR_IO;
}

INLINE int32_t file_size(FileObject *object) {
#ifdef GK_V3_HOST_TEST
    extern int32_t gk_v3_host_file_size(FileObject *);
    return gk_v3_host_file_size(object);
#else
    typedef int32_t (*SizeFunction)(uint32_t);
    SizeFunction function = *(SizeFunction *)(uintptr_t)STOCK_FILE_SIZE_VECTOR;
    return function(object->words[0]);
#endif
}

INLINE int32_t read_exact(FileObject *object, void *destination,
                          uint32_t length) {
    int32_t status = gk_v3_stock_file_read(object, destination, length);
    if (status == 1) {
        return GK_OK;
    }
    return status == 0 ? GK_ERR_CORRUPT : GK_ERR_IO;
}

INLINE int32_t write_exact(FileObject *object, const void *source,
                           uint32_t length) {
    return gk_v3_stock_file_write(object, source, length) == 1
               ? GK_OK
               : GK_ERR_IO;
}

CODE int32_t gk_v3_close_impl(FileObject *object) {
    return gk_v3_stock_file_close(object) < 0 ? GK_ERR_IO : GK_OK;
}

INLINE int32_t close_preserve(FileObject *object, int32_t status) {
    int32_t close_status = gk_v3_close_impl(object);
    return status < 0 ? status : close_status;
}

INLINE int32_t open_path(FileObject *object, const char *path,
                         const char *mode, uint8_t *buffer) {
    int32_t status = gk_v3_stock_file_open(
        object, path, mode, buffer, FILE_BUFFER_SIZE
    );
    return status < 0 ? normalize_open_error(status) : GK_OK;
}

#ifdef GK_V3_PROJECT_IO_OPTIMIZED
INLINE int32_t open_path_sized(FileObject *object, const char *path,
                               const char *mode, uint8_t *buffer,
                               uint32_t buffer_size) {
    int32_t status = gk_v3_stock_file_open(
        object, path, mode, buffer, buffer_size
    );
    return status < 0 ? normalize_open_error(status) : GK_OK;
}

INLINE uint8_t *read_stream_buffer(void) {
    return __gk_io_buffer + IO_READ_BUFFER_OFFSET;
}

INLINE uint8_t *write_stream_buffer(void) {
    return __gk_io_buffer + IO_WRITE_BUFFER_OFFSET;
}

INLINE uint8_t *fixed_file_buffer(void) {
    return __gk_io_buffer + IO_FIXED_BUFFER_OFFSET;
}
#endif

INLINE uint8_t *assignment_buffer(void) {
    return __gk_io_buffer + IO_ASSIGNMENT_BUFFER_OFFSET;
}

INLINE uint8_t *compare_buffer(void) {
    return __gk_io_buffer + IO_COMPARE_BUFFER_OFFSET;
}

INLINE uint32_t record_offset(uint32_t kit) {
    return V3_RECORDS_OFFSET + kit * V3_RECORD_SIZE;
}

INLINE uint32_t content_crc(const uint8_t *record) {
    uint32_t state = 0xFFFFFFFFU;
    state = gk_v3_crc32_update_impl(record + 9, 1, state);
    state = gk_v3_crc32_update_impl(
        record + V3_RECORD_NAME_OFFSET,
        KIT_NAME_SIZE + PART_PAYLOAD_SIZE,
        state
    );
    return ~state;
}

INLINE bool record_valid(const uint8_t *record, uint32_t container_epoch,
                         uint32_t kit) {
    uint8_t flags;
    if (!block_crc_valid(record, V3_RECORD_CRC_OFFSET) ||
        !bytes_equal(record, magic_record, 8) || record[8] != V3_VERSION) {
        return false;
    }
    flags = record[9];
    if ((flags & (uint8_t)~V3_KIT_FLAG_OCCUPIED) != 0U ||
        record[10] != KIT_NAME_SIZE ||
        record[11] != KIT_VISIBLE_NAME_SIZE ||
        load_u32(record + 12) != container_epoch ||
        load_u16(record + 24) != kit ||
        load_u16(record + 26) != PART_PAYLOAD_SIZE ||
        record[V3_RECORD_NAME_OFFSET + KIT_VISIBLE_NAME_SIZE] != 0U ||
        !bytes_zero(record + V3_RECORD_PADDING_OFFSET,
                    V3_RECORD_CRC_OFFSET - V3_RECORD_PADDING_OFFSET) ||
        load_u32(record + 28) != content_crc(record)) {
        return false;
    }
    if ((flags & V3_KIT_FLAG_OCCUPIED) == 0U &&
        !bytes_zero(record + V3_RECORD_NAME_OFFSET, KIT_NAME_SIZE)) {
        return false;
    }
    return true;
}

INLINE void canonical_publish_record(uint32_t kit, const uint8_t *record) {
    uint8_t *name = __gk_kit_names + kit * KIT_NAME_SIZE;
    uint8_t *payload = __gk_canonical_payloads + kit * PART_PAYLOAD_SIZE;
    if ((record[9] & V3_KIT_FLAG_OCCUPIED) != 0U) {
        bitmap_set(__gk_initialized_bitmap, kit);
        bytes_copy(name, record + V3_RECORD_NAME_OFFSET, KIT_NAME_SIZE);
    } else {
        bitmap_clear(__gk_initialized_bitmap, kit);
        bytes_clear(name, KIT_NAME_SIZE);
    }
    bytes_copy(payload, record + V3_RECORD_PAYLOAD_OFFSET, PART_PAYLOAD_SIZE);
}

INLINE bool canonical_record_equal(uint32_t kit, const uint8_t *record) {
    bool occupied = bitmap_test(__gk_initialized_bitmap, kit);
    if (occupied != ((record[9] & V3_KIT_FLAG_OCCUPIED) != 0U)) {
        return false;
    }
    return bytes_equal(__gk_kit_names + kit * KIT_NAME_SIZE,
                       record + V3_RECORD_NAME_OFFSET, KIT_NAME_SIZE) &&
           bytes_equal(__gk_canonical_payloads + kit * PART_PAYLOAD_SIZE,
                       record + V3_RECORD_PAYLOAD_OFFSET,
                       PART_PAYLOAD_SIZE);
}

INLINE bool superblock_parse(const uint8_t *block, uint8_t kind,
                             uint8_t peer, uint32_t *container_epoch) {
    if (!block_crc_valid(block, V3_BLOCK_CRC_OFFSET) ||
        !bytes_equal(block, magic_superblock, 8) ||
        block[8] != V3_VERSION || block[9] != kind || block[10] != peer ||
        block[11] != 0U || load_u16(block + 12) != 0x20U ||
        load_u16(block + 14) != V3_SECTOR_SIZE ||
        load_u32(block + 16) != V3_PEER_SIZE ||
        load_u16(block + 20) != KIT_COUNT ||
        load_u16(block + 22) != V3_RECORD_SIZE ||
        load_u16(block + 24) != V3_ROOT_OFFSET / V3_SECTOR_SIZE ||
        load_u16(block + 26) != V3_RECORDS_OFFSET / V3_SECTOR_SIZE ||
        !bytes_zero(block + 0x20, V3_BLOCK_CRC_OFFSET - 0x20)) {
        return false;
    }
    *container_epoch = load_u32(block + 28);
    return true;
}

INLINE bool manifest_parse(const uint8_t *block, uint8_t kind, uint8_t role,
                           uint32_t container_epoch,
                           ManifestSummary *manifest) {
    const uint8_t *magic = role == V3_ROLE_ROOT ? magic_root : magic_overlay;
    bytes_clear((uint8_t *)manifest, (uint32_t)sizeof(*manifest));
    if (!block_crc_valid(block, V3_BLOCK_CRC_OFFSET) ||
        !bytes_equal(block, magic, 8) || block[8] != V3_VERSION ||
        block[9] != kind ||
        (block[10] & (uint8_t)~V3_FLAG_STORED_PENDING) != 0U ||
        block[11] != 0x20U || load_u32(block + 12) != container_epoch ||
        load_u16(block + 24) != PATTERN_COUNT ||
        load_u16(block + 26) != PATTERN_COUNT / 8U ||
        load_u32(block + 28) != 0U ||
        !bytes_zero(block + V3_MANIFEST_PADDING_OFFSET,
                    V3_BLOCK_CRC_OFFSET - V3_MANIFEST_PADDING_OFFSET)) {
        return false;
    }
    manifest->valid = true;
    manifest->flags = block[10];
    manifest->container_epoch = container_epoch;
    manifest->image_epoch = load_u32(block + 16);
    manifest->generation = load_u32(block + 20);
    bytes_copy(manifest->assignments,
               block + V3_MANIFEST_ASSIGNMENTS_OFFSET, PATTERN_COUNT);
    bytes_copy(manifest->assignment_valid,
               block + V3_MANIFEST_VALID_OFFSET, PATTERN_COUNT / 8U);
    return true;
}

static CODE int32_t peer_probe(uint8_t kind, uint8_t peer,
                               PeerSummary *summary) {
    char path[PROJECT_PATH_SIZE];
    FileObject object;
    uint8_t *block = __gk_v3_record_stage;
    int32_t status;
    bytes_clear((uint8_t *)summary, (uint32_t)sizeof(*summary));
    status = gk_v3_project_path_build_impl(path, image_suffix(kind, peer));
    if (status < 0) {
        return status;
    }
    status = open_path(&object, path, mode_read, __gk_io_buffer);
    if (status < 0) {
        summary->transport_error = status == GK_ERR_IO;
        return status;
    }
    if (file_size(&object) != V3_PEER_SIZE) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    status = read_exact(&object, block, V3_SUPERBLOCK_SIZE);
    if (status < 0 || !superblock_parse(block, kind, peer,
                                        &summary->container_epoch)) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    summary->superblock_valid = true;
    status = read_exact(&object, block, V3_MANIFEST_SIZE);
    if (status < 0) {
        return close_preserve(&object, status);
    }
    (void)manifest_parse(block, kind, V3_ROLE_ROOT,
                         summary->container_epoch, &summary->root);
    status = read_exact(&object, block, V3_MANIFEST_SIZE);
    if (status < 0) {
        return close_preserve(&object, status);
    }
    (void)manifest_parse(block, kind, V3_ROLE_OVERLAY,
                         summary->container_epoch, &summary->overlay);
    return close_preserve(&object, GK_OK);
}

INLINE uint32_t *kind_generations(uint8_t kind) {
    return kind == V3_KIND_WORK ? __gk_v3_work_generations
                                : __gk_v3_stored_generations;
}

INLINE uint8_t *kind_sources(uint8_t kind) {
    return kind == V3_KIND_WORK ? __gk_v3_work_source_bitmap
                                : __gk_v3_stored_source_bitmap;
}

INLINE uint8_t *kind_valid(uint8_t kind) {
    return kind == V3_KIND_WORK ? __gk_v3_work_valid_bitmap
                                : __gk_v3_stored_valid_bitmap;
}

INLINE uint32_t *kind_container_epochs(uint8_t kind) {
    return kind == V3_KIND_WORK
               ? __gk_v3_state_header.work_container_epoch
               : __gk_v3_state_header.stored_container_epoch;
}

INLINE uint32_t kind_image_epoch(uint8_t kind) {
    return kind == V3_KIND_WORK ? __gk_v3_state_header.work_image_epoch
                                : __gk_v3_state_header.stored_image_epoch;
}

INLINE uint32_t kind_root_generation(uint8_t kind) {
    return kind == V3_KIND_WORK
               ? __gk_v3_state_header.work_root_generation
               : __gk_v3_state_header.stored_root_generation;
}

INLINE uint32_t kind_manifest_generation(uint8_t kind) {
    return kind == V3_KIND_WORK
               ? __gk_v3_state_header.work_manifest_generation
               : __gk_v3_state_header.stored_manifest_generation;
}

INLINE uint8_t kind_root_peer(uint8_t kind) {
    return kind == V3_KIND_WORK ? __gk_v3_state_header.work_root_peer
                                : __gk_v3_state_header.stored_root_peer;
}

INLINE uint8_t kind_manifest_peer(uint8_t kind) {
    return kind == V3_KIND_WORK ? __gk_v3_state_header.work_manifest_peer
                                : __gk_v3_state_header.stored_manifest_peer;
}

INLINE uint8_t kind_flags(uint8_t kind) {
    return kind == V3_KIND_WORK ? __gk_v3_state_header.work_flags
                                : __gk_v3_state_header.stored_flags;
}

INLINE bool kind_ready(uint8_t kind) {
    uint32_t flag = kind == V3_KIND_WORK ? V3_STATE_WORK_READY
                                         : V3_STATE_STORED_READY;
    return __gk_v3_state_header.magic == V3_STATE_MAGIC &&
           (__gk_v3_state_header.flags & flag) != 0U;
}

INLINE void set_kind_ready(uint8_t kind, bool ready) {
    uint32_t flag = kind == V3_KIND_WORK ? V3_STATE_WORK_READY
                                         : V3_STATE_STORED_READY;
    if (ready) {
        __gk_v3_state_header.flags |= flag;
    } else {
        __gk_v3_state_header.flags &= ~flag;
    }
}

INLINE void set_kind_image_state(uint8_t kind, uint32_t image_epoch,
                                 uint32_t root_generation, uint8_t root_peer,
                                 uint32_t manifest_generation,
                                 uint8_t manifest_peer, uint8_t flags) {
    if (kind == V3_KIND_WORK) {
        __gk_v3_state_header.work_image_epoch = image_epoch;
        __gk_v3_state_header.work_root_generation = root_generation;
        __gk_v3_state_header.work_root_peer = root_peer;
        __gk_v3_state_header.work_manifest_generation = manifest_generation;
        __gk_v3_state_header.work_manifest_peer = manifest_peer;
        __gk_v3_state_header.work_flags = flags;
    } else {
        __gk_v3_state_header.stored_image_epoch = image_epoch;
        __gk_v3_state_header.stored_root_generation = root_generation;
        __gk_v3_state_header.stored_root_peer = root_peer;
        __gk_v3_state_header.stored_manifest_generation = manifest_generation;
        __gk_v3_state_header.stored_manifest_peer = manifest_peer;
        __gk_v3_state_header.stored_flags = flags;
    }
}

INLINE void state_initialize(void) {
    bytes_clear((uint8_t *)&__gk_v3_state_header, 0x80U);
    bytes_clear((uint8_t *)__gk_v3_work_generations, 0x400U);
    bytes_clear((uint8_t *)__gk_v3_stored_generations, 0x400U);
    bytes_clear(__gk_v3_work_source_bitmap, 0x20U);
    bytes_clear(__gk_v3_stored_source_bitmap, 0x20U);
    bytes_clear(__gk_v3_work_valid_bitmap, 0x20U);
    bytes_clear(__gk_v3_stored_valid_bitmap, 0x20U);
    bytes_clear(__gk_v3_work_dirty_bitmap, 0x20U);
    bytes_clear(__gk_v3_assignment_dependency_bitmap, 0x20U);
    __gk_v3_state_header.magic = V3_STATE_MAGIC;
}

INLINE bool manifest_logically_equal(const ManifestSummary *left,
                                     const ManifestSummary *right) {
    return left->image_epoch == right->image_epoch &&
           left->flags == right->flags &&
           bytes_equal(left->assignments, right->assignments,
                       PATTERN_COUNT) &&
           bytes_equal(left->assignment_valid, right->assignment_valid,
                       PATTERN_COUNT / 8U);
}

INLINE void superblock_encode(uint8_t *block, uint8_t kind, uint8_t peer,
                              uint32_t container_epoch) {
    bytes_clear(block, V3_SUPERBLOCK_SIZE);
    bytes_copy(block, magic_superblock, 8);
    block[8] = V3_VERSION;
    block[9] = kind;
    block[10] = peer;
    store_u16(block + 12, 0x20U);
    store_u16(block + 14, V3_SECTOR_SIZE);
    store_u32(block + 16, V3_PEER_SIZE);
    store_u16(block + 20, KIT_COUNT);
    store_u16(block + 22, V3_RECORD_SIZE);
    store_u16(block + 24, V3_ROOT_OFFSET / V3_SECTOR_SIZE);
    store_u16(block + 26, V3_RECORDS_OFFSET / V3_SECTOR_SIZE);
    store_u32(block + 28, container_epoch);
    store_u32(block + V3_BLOCK_CRC_OFFSET,
              block_crc(block, V3_BLOCK_CRC_OFFSET));
}

INLINE void manifest_encode(uint8_t *block, uint8_t kind, uint8_t role,
                            uint32_t container_epoch, uint32_t image_epoch,
                            uint32_t generation, const uint8_t *assignments,
                            const uint8_t *assignment_valid, uint8_t flags) {
    bytes_clear(block, V3_MANIFEST_SIZE);
    bytes_copy(block, role == V3_ROLE_ROOT ? magic_root : magic_overlay, 8);
    block[8] = V3_VERSION;
    block[9] = kind;
    block[10] = flags;
    block[11] = 0x20U;
    store_u32(block + 12, container_epoch);
    store_u32(block + 16, image_epoch);
    store_u32(block + 20, generation);
    store_u16(block + 24, PATTERN_COUNT);
    store_u16(block + 26, PATTERN_COUNT / 8U);
    bytes_copy(block + V3_MANIFEST_ASSIGNMENTS_OFFSET, assignments,
               PATTERN_COUNT);
    bytes_copy(block + V3_MANIFEST_VALID_OFFSET, assignment_valid,
               PATTERN_COUNT / 8U);
    store_u32(block + V3_BLOCK_CRC_OFFSET,
              block_crc(block, V3_BLOCK_CRC_OFFSET));
}

INLINE void record_finish_encode(uint8_t *record, uint8_t kind,
                                 uint8_t peer, uint32_t kit,
                                 uint32_t image_epoch,
                                 uint32_t generation) {
    uint32_t container_epoch = kind_container_epochs(kind)[peer];
    uint8_t occupied = record[9] & V3_KIT_FLAG_OCCUPIED;
    bytes_clear(record, V3_RECORD_NAME_OFFSET);
    bytes_copy(record, magic_record, 8);
    record[8] = V3_VERSION;
    record[9] = occupied;
    record[10] = KIT_NAME_SIZE;
    record[11] = KIT_VISIBLE_NAME_SIZE;
    store_u32(record + 12, container_epoch);
    store_u32(record + 16, image_epoch);
    store_u32(record + 20, generation);
    store_u16(record + 24, (uint16_t)kit);
    store_u16(record + 26, PART_PAYLOAD_SIZE);
    record[V3_RECORD_NAME_OFFSET + KIT_VISIBLE_NAME_SIZE] = 0U;
    bytes_clear(record + V3_RECORD_PADDING_OFFSET,
                V3_RECORD_CRC_OFFSET - V3_RECORD_PADDING_OFFSET);
    store_u32(record + 28, content_crc(record));
    store_u32(record + V3_RECORD_CRC_OFFSET,
              block_crc(record, V3_RECORD_CRC_OFFSET));
}

static CODE int32_t fixed_write(uint8_t kind, uint8_t peer,
                                uint32_t offset, const uint8_t *source,
                                uint32_t length) {
    char path[PROJECT_PATH_SIZE];
    FileObject object;
    int32_t status;
    status = gk_v3_project_path_build_impl(path, image_suffix(kind, peer));
    if (status < 0) {
        return status;
    }
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = open_path_sized(&object, path, mode_write,
                             fixed_file_buffer(), length);
#else
    status = open_path(&object, path, mode_write,
                       __gk_io_buffer + FILE_BUFFER_SIZE);
#endif
    if (status < 0) {
        return status;
    }
    if (file_size(&object) != V3_PEER_SIZE) {
        status = GK_ERR_CORRUPT;
    } else if (gk_v3_stock_file_seek(&object, offset) < 0) {
        status = GK_ERR_IO;
    } else {
        status = write_exact(&object, source, length);
    }
    /*
     * The authenticated 24-byte stock buffered object stores its pending
     * byte count in word 3 and its close-time logical length in word 4.
     * Every v3 offset and write unit is exactly sector aligned, so the
     * pending count must be zero after either a complete write or a backend
     * sector failure (stock buffered_file_write clears it on that failure).
     *
     * Publishing the fixed logical length directly removes the expensive
     * second FAT seek while preserving the essential invariant: write-mode
     * close must never truncate this preallocated peer after any success or
     * failure.  Close itself authenticates and applies this length through
     * the selected filesystem set-length vector.
     */
    if (object.words[FILE_OBJECT_BUFFERED_COUNT_WORD] != 0U && status >= 0) {
        status = GK_ERR_CORRUPT;
    }
    object.words[FILE_OBJECT_LOGICAL_LENGTH_WORD] = V3_PEER_SIZE;
    return close_preserve(&object, status);
}

static CODE int32_t read_record(uint8_t kind, uint8_t peer, uint32_t kit,
                                uint8_t *destination, uint8_t *file_buffer) {
    char path[PROJECT_PATH_SIZE];
    FileObject object;
    int32_t status;
    status = gk_v3_project_path_build_impl(path, image_suffix(kind, peer));
    if (status < 0) {
        return status;
    }
    status = open_path(&object, path, mode_read, file_buffer);
    if (status < 0) {
        return status;
    }
    if (file_size(&object) != V3_PEER_SIZE ||
        gk_v3_stock_file_seek(&object, record_offset(kit)) < 0) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    status = read_exact(&object, destination, V3_RECORD_SIZE);
    return close_preserve(&object, status);
}

static CODE int32_t stage_logically_equals_record(uint8_t kind, uint8_t peer,
                                                  uint32_t kit) {
    char path[PROJECT_PATH_SIZE];
    FileObject object;
    uint8_t *chunk = compare_buffer();
    const uint8_t *expected = __gk_v3_record_stage;
    uint32_t remaining = V3_RECORD_SIZE;
    int32_t status;
    status = gk_v3_project_path_build_impl(path, image_suffix(kind, peer));
    if (status < 0) {
        return status;
    }
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = open_path_sized(&object, path, mode_read,
                             fixed_file_buffer(), FILE_BUFFER_SIZE);
#else
    status = open_path(&object, path, mode_read,
                       __gk_io_buffer + FILE_BUFFER_SIZE);
#endif
    if (status < 0) {
        return status;
    }
    if (file_size(&object) != V3_PEER_SIZE ||
        gk_v3_stock_file_seek(&object, record_offset(kit)) < 0) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    while (remaining != 0U) {
        uint32_t count = remaining > IO_COMPARE_BUFFER_SIZE
                             ? IO_COMPARE_BUFFER_SIZE
                             : remaining;
        uint32_t chunk_offset = V3_RECORD_SIZE - remaining;
        uint32_t index;
        status = read_exact(&object, chunk, count);
        if (status < 0) {
            return close_preserve(&object, status);
        }
        for (index = 0; index != count; ++index) {
            uint32_t record_index = chunk_offset + index;
            /* Container epoch and the dependent block CRC are peer-local. */
            if ((record_index < 12U || record_index >= 16U) &&
                record_index < V3_RECORD_CRC_OFFSET &&
                chunk[index] != expected[index]) {
                return close_preserve(&object, GK_ERR_CORRUPT);
            }
        }
        expected += count;
        remaining -= count;
    }
    return close_preserve(&object, GK_OK);
}

static CODE int32_t scan_peer_records(uint8_t kind, uint8_t peer,
                                      uint32_t container_epoch,
                                      uint32_t image_epoch, bool publish) {
    char path[PROJECT_PATH_SIZE];
    FileObject object;
    uint32_t *generations = kind_generations(kind);
    uint8_t *sources = kind_sources(kind);
    uint8_t *valid = kind_valid(kind);
    uint8_t *record = __gk_v3_record_stage;
    uint32_t kit;
    int32_t status;
    status = gk_v3_project_path_build_impl(path, image_suffix(kind, peer));
    if (status < 0) {
        return status;
    }
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = open_path_sized(&object, path, mode_read,
                             read_stream_buffer(), STREAM_BUFFER_SIZE);
#else
    status = open_path(&object, path, mode_read, __gk_io_buffer);
#endif
    if (status < 0) {
        return status;
    }
    if (file_size(&object) != V3_PEER_SIZE ||
        gk_v3_stock_file_seek(&object, V3_RECORDS_OFFSET) < 0) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    for (kit = 0; kit != KIT_COUNT; ++kit) {
        uint32_t generation;
        int comparison;
        status = read_exact(&object, record, V3_RECORD_SIZE);
        if (status < 0) {
            return close_preserve(&object, status);
        }
        if (!record_valid(record, container_epoch, kit) ||
            load_u32(record + 16) != image_epoch) {
            continue;
        }
        generation = load_u32(record + 20);
        if (!bitmap_test(valid, kit)) {
            generations[kit] = generation;
            if (peer != 0U) {
                bitmap_set(sources, kit);
            } else {
                bitmap_clear(sources, kit);
            }
            bitmap_set(valid, kit);
            if (publish) {
                canonical_publish_record(kit, record);
            }
            continue;
        }
        comparison = generation_compare(generation, generations[kit]);
        if (comparison == 2) {
            return close_preserve(&object, GK_ERR_CONFLICT);
        }
        if (comparison == 0) {
            if (publish) {
                if (!canonical_record_equal(kit, record)) {
                    return close_preserve(&object, GK_ERR_CONFLICT);
                }
            } else {
                uint8_t selected_peer = bitmap_test(sources, kit) ? 1U : 0U;
                status = stage_logically_equals_record(kind, selected_peer,
                                                       kit);
                if (status < 0) {
                    return close_preserve(
                        &object,
                        status == GK_ERR_CORRUPT ? GK_ERR_CONFLICT : status
                    );
                }
            }
            continue;
        }
        if (comparison > 0) {
            generations[kit] = generation;
            if (peer != 0U) {
                bitmap_set(sources, kit);
            } else {
                bitmap_clear(sources, kit);
            }
            if (publish) {
                canonical_publish_record(kit, record);
            }
        }
    }
    return close_preserve(&object, GK_OK);
}

static CODE int32_t scan_epoch(uint8_t kind, const PeerSummary *summaries,
                               uint32_t image_epoch, bool publish) {
    uint8_t *valid = kind_valid(kind);
    uint8_t *sources = kind_sources(kind);
    uint32_t *generations = kind_generations(kind);
    uint8_t peer;
    int32_t first_error = GK_ERR_CORRUPT;
    bytes_clear(valid, KIT_COUNT / 8U);
    bytes_clear(sources, KIT_COUNT / 8U);
    bytes_clear((uint8_t *)generations, KIT_COUNT * sizeof(uint32_t));
    for (peer = 0; peer != 2U; ++peer) {
        int32_t status;
        if (!summaries[peer].superblock_valid) {
            continue;
        }
        status = scan_peer_records(kind, peer,
                                   summaries[peer].container_epoch,
                                   image_epoch, publish);
        if (status == GK_ERR_CONFLICT) {
            return GK_ERR_CORRUPT;
        }
        if (status == GK_ERR_IO) {
            first_error = GK_ERR_IO;
        } else if (status < 0 && first_error != GK_ERR_IO) {
            first_error = status;
        }
    }
    return bitmap_full(valid) ? GK_OK : first_error;
}

INLINE void publish_assignments(uint8_t kind,
                                const ManifestSummary *manifest) {
    if (kind == V3_KIND_WORK) {
        bytes_copy(__gk_pattern_assignments, manifest->assignments,
                   PATTERN_COUNT);
        bytes_copy(__gk_pattern_assignment_valid,
                   manifest->assignment_valid, PATTERN_COUNT / 8U);
    } else {
        uint8_t *destination = assignment_buffer();
        bytes_copy(destination, manifest->assignments, PATTERN_COUNT);
        bytes_copy(destination + PATTERN_COUNT,
                   manifest->assignment_valid, PATTERN_COUNT / 8U);
    }
}

INLINE void publish_compatibility_state(uint8_t kind) {
    if (kind == V3_KIND_WORK) {
        __gk_persistence_work_slot = kind_root_peer(kind);
        __gk_persistence_work_generation = kind_root_generation(kind);
        __gk_persistence_flags |= PERSIST_WORK_KNOWN;
        if ((kind_flags(kind) & V3_FLAG_STORED_PENDING) != 0U) {
            __gk_persistence_flags |= PERSIST_STORED_PENDING;
        } else {
            __gk_persistence_flags &= (uint8_t)~PERSIST_STORED_PENDING;
        }
    } else {
        __gk_persistence_stored_slot = kind_root_peer(kind);
        __gk_persistence_stored_generation = kind_root_generation(kind);
        __gk_persistence_flags |= PERSIST_STORED_KNOWN;
    }
    __gk_persistence_last_error = GK_OK;
}

INLINE void invalidate_compatibility_state(uint8_t kind, int32_t error) {
    __gk_persistence_last_error = error;
    if (kind == V3_KIND_WORK) {
        __gk_persistence_work_slot = PERSIST_SLOT_NONE;
        __gk_persistence_flags &= (uint8_t)~PERSIST_WORK_KNOWN;
    } else {
        __gk_persistence_stored_slot = PERSIST_SLOT_NONE;
        __gk_persistence_flags &= (uint8_t)~PERSIST_STORED_KNOWN;
    }
    set_kind_ready(kind, false);
}

static CODE int32_t choose_effective_manifest(
    const PeerSummary *summaries, const ManifestSummary *root,
    uint8_t root_peer, const ManifestSummary **effective,
    uint8_t *effective_peer
) {
    const ManifestSummary *candidates[2];
    uint8_t peers[2];
    uint8_t count = 0;
    uint8_t peer;
    for (peer = 0; peer != 2U; ++peer) {
        if (summaries[peer].overlay.valid &&
            summaries[peer].overlay.image_epoch == root->image_epoch) {
            candidates[count] = &summaries[peer].overlay;
            peers[count] = peer;
            ++count;
        }
    }
    if (count == 0U) {
        *effective = root;
        *effective_peer = root_peer;
        return GK_OK;
    }
    if (count == 1U) {
        *effective = candidates[0];
        *effective_peer = peers[0];
        return GK_OK;
    }
    {
        int comparison = generation_compare(candidates[0]->generation,
                                            candidates[1]->generation);
        if (comparison == 2) {
            return GK_ERR_CORRUPT;
        }
        if (comparison == 0 &&
            !manifest_logically_equal(candidates[0], candidates[1])) {
            return GK_ERR_CORRUPT;
        }
        if (comparison < 0) {
            *effective = candidates[1];
            *effective_peer = peers[1];
        } else {
            *effective = candidates[0];
            *effective_peer = peers[0];
        }
    }
    return GK_OK;
}

static CODE int32_t select_kind(uint8_t kind, bool publish) {
    PeerSummary *summaries = __gk_v3_peer_summaries;
    const ManifestSummary *roots[2];
    uint8_t root_peers[2];
    uint8_t root_count = 0;
    uint8_t root_index;
    bool transport_error = false;
    int32_t fallback_error = GK_ERR_CORRUPT;
    uint8_t peer;
    if (kind > V3_KIND_STORED) {
        return GK_ERR_RANGE;
    }
    for (peer = 0; peer != 2U; ++peer) {
        int32_t status = peer_probe(kind, peer, &summaries[peer]);
        if (status == GK_ERR_IO || summaries[peer].transport_error) {
            transport_error = true;
        }
        if (summaries[peer].root.valid) {
            roots[root_count] = &summaries[peer].root;
            root_peers[root_count] = peer;
            ++root_count;
        }
    }
    if (root_count == 0U) {
        return transport_error ? GK_ERR_IO : GK_ERR_INVALID;
    }
    if (root_count == 2U) {
        int comparison = generation_compare(roots[0]->generation,
                                            roots[1]->generation);
        if (comparison == 2 ||
            (comparison == 0 &&
             !manifest_logically_equal(roots[0], roots[1]))) {
            return GK_ERR_CORRUPT;
        }
        if (comparison < 0) {
            const ManifestSummary *root_swap = roots[0];
            uint8_t peer_swap = root_peers[0];
            roots[0] = roots[1];
            roots[1] = root_swap;
            root_peers[0] = root_peers[1];
            root_peers[1] = peer_swap;
        }
    }
    for (root_index = 0; root_index != root_count; ++root_index) {
        const ManifestSummary *effective;
        uint8_t effective_peer;
        int32_t status = scan_epoch(kind, summaries,
                                    roots[root_index]->image_epoch, publish);
        if (status < 0) {
            if (status == GK_ERR_IO) {
                fallback_error = GK_ERR_IO;
            }
            continue;
        }
        status = choose_effective_manifest(
            summaries, roots[root_index], root_peers[root_index],
            &effective, &effective_peer
        );
        if (status < 0) {
            return status;
        }
        kind_container_epochs(kind)[0] = summaries[0].superblock_valid
                                                 ? summaries[0].container_epoch
                                                 : 0U;
        kind_container_epochs(kind)[1] = summaries[1].superblock_valid
                                                 ? summaries[1].container_epoch
                                                 : 0U;
        set_kind_image_state(kind, roots[root_index]->image_epoch,
                             roots[root_index]->generation,
                             root_peers[root_index], effective->generation,
                             effective_peer, effective->flags);
        publish_assignments(kind, effective);
        set_kind_ready(kind, true);
        publish_compatibility_state(kind);
        return GK_OK;
    }
    return fallback_error;
}

#ifdef GK_V3_PROJECT_IO_OPTIMIZED
/*
 * Ordinary project opening needs to know whether the Stored v3 conversion
 * completed, but it does not consume Stored Kit payloads.  Authenticate both
 * peer headers and roots here and defer the 3.25 MiB record scan until a
 * Store/Reload operation actually needs the Stored image.
 */
static CODE int32_t probe_kind_root(uint8_t kind) {
    PeerSummary *summaries = __gk_v3_peer_summaries;
    const ManifestSummary *first_root = NULL;
    bool transport_error = false;
    uint8_t peer;
    if (kind > V3_KIND_STORED) {
        return GK_ERR_RANGE;
    }
    for (peer = 0; peer != 2U; ++peer) {
        int32_t status = peer_probe(kind, peer, &summaries[peer]);
        if (status == GK_ERR_IO || summaries[peer].transport_error) {
            transport_error = true;
        }
        if (!summaries[peer].root.valid) {
            continue;
        }
        if (kind == V3_KIND_STORED &&
            (summaries[peer].root.flags & V3_FLAG_STORED_PENDING) != 0U) {
            return GK_ERR_CORRUPT;
        }
        if (first_root == NULL) {
            first_root = &summaries[peer].root;
        } else {
            int comparison = generation_compare(
                first_root->generation, summaries[peer].root.generation
            );
            if (comparison == 2 ||
                (comparison == 0 &&
                 !manifest_logically_equal(first_root,
                                           &summaries[peer].root))) {
                return GK_ERR_CORRUPT;
            }
        }
    }
    if (first_root != NULL) {
        return GK_OK;
    }
    return transport_error ? GK_ERR_IO : GK_ERR_INVALID;
}

#ifdef GK_V3_HOST_TEST
CODE int32_t gk_v3_host_probe_kind_root(uint32_t kind) {
    return probe_kind_root((uint8_t)kind);
}
#endif
#endif

static CODE int32_t selected_record_read(uint8_t kind, uint32_t kit,
                                         uint8_t *destination) {
    uint8_t peer;
    int32_t status;
    if (!kind_ready(kind) || kit >= KIT_COUNT ||
        !bitmap_test(kind_valid(kind), kit)) {
        return GK_ERR_CORRUPT;
    }
    peer = bitmap_test(kind_sources(kind), kit) ? 1U : 0U;
    status = read_record(kind, peer, kit, destination, __gk_io_buffer);
    if (status < 0 ||
        !record_valid(destination, kind_container_epochs(kind)[peer], kit) ||
        load_u32(destination + 16) != kind_image_epoch(kind) ||
        load_u32(destination + 20) != kind_generations(kind)[kit]) {
        return status < 0 ? status : GK_ERR_CORRUPT;
    }
    return GK_OK;
}

INLINE void stage_from_canonical(uint32_t kit) {
    uint8_t *record = __gk_v3_record_stage;
    bytes_clear(record, V3_RECORD_SIZE);
    if (bitmap_test(__gk_initialized_bitmap, kit)) {
        record[9] = V3_KIT_FLAG_OCCUPIED;
        bytes_copy(record + V3_RECORD_NAME_OFFSET,
                   __gk_kit_names + kit * KIT_NAME_SIZE, KIT_NAME_SIZE);
    }
    bytes_copy(record + V3_RECORD_PAYLOAD_OFFSET,
               __gk_canonical_payloads + kit * PART_PAYLOAD_SIZE,
               PART_PAYLOAD_SIZE);
}

static CODE int32_t write_new_peer(uint8_t kind, uint8_t peer,
                                   uint32_t container_epoch,
                                   uint32_t image_epoch,
                                   uint32_t generation,
                                   const uint8_t *assignments,
                                   const uint8_t *assignment_valid,
                                   uint8_t flags, int32_t source_kind) {
    char path[PROJECT_PATH_SIZE];
    FileObject object;
    uint8_t *stage = __gk_v3_record_stage;
    uint32_t kit;
    int32_t status;
    status = gk_v3_project_path_build_impl(path, image_suffix(kind, peer));
    if (status < 0) {
        return status;
    }
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = open_path_sized(&object, path, mode_write,
                             write_stream_buffer(), STREAM_BUFFER_SIZE);
#else
    status = open_path(&object, path, mode_write,
                       __gk_io_buffer + FILE_BUFFER_SIZE);
#endif
    if (status < 0) {
        return status;
    }
    superblock_encode(stage, kind, peer, container_epoch);
    status = write_exact(&object, stage, V3_SUPERBLOCK_SIZE);
    if (status < 0) {
        return close_preserve(&object, status);
    }
    bytes_clear(stage, V3_MANIFEST_SIZE);
    status = write_exact(&object, stage, V3_MANIFEST_SIZE);
    if (status >= 0) {
        status = write_exact(&object, stage, V3_MANIFEST_SIZE);
    }
    if (status < 0) {
        return close_preserve(&object, status);
    }
    for (kit = 0; kit != KIT_COUNT; ++kit) {
        uint32_t record_generation = generation;
        if (source_kind < 0) {
            stage_from_canonical(kit);
        } else {
            status = selected_record_read((uint8_t)source_kind, kit, stage);
            if (status < 0) {
                return close_preserve(&object, status);
            }
            if ((uint8_t)source_kind == kind &&
                image_epoch == kind_image_epoch(kind)) {
                record_generation = kind_generations(kind)[kit] - 1U;
            }
        }
        kind_container_epochs(kind)[peer] = container_epoch;
        record_finish_encode(stage, kind, peer, kit, image_epoch,
                             record_generation);
        status = write_exact(&object, stage, V3_RECORD_SIZE);
        if (status < 0) {
            return close_preserve(&object, status);
        }
    }
    status = close_preserve(&object, GK_OK);
    if (status < 0) {
        return status;
    }
    manifest_encode(stage, kind, V3_ROLE_ROOT, container_epoch, image_epoch,
                    generation, assignments, assignment_valid, flags);
    return fixed_write(kind, peer, V3_ROOT_OFFSET, stage,
                       V3_MANIFEST_SIZE);
}

static CODE int32_t fresh_container_epochs(uint8_t kind,
                                           uint32_t *epoch_a,
                                           uint32_t *epoch_b) {
    PeerSummary *summaries = __gk_v3_peer_summaries;
    bool valid_a;
    bool valid_b;
    uint32_t newest;
    int comparison;
    (void)peer_probe(kind, 0, &summaries[0]);
    (void)peer_probe(kind, 1, &summaries[1]);
    valid_a = summaries[0].superblock_valid;
    valid_b = summaries[1].superblock_valid;
    if (!valid_a && !valid_b) {
        *epoch_a = 1U;
        *epoch_b = 2U;
        return GK_OK;
    }
    if (valid_a && !valid_b) {
        newest = summaries[0].container_epoch;
    } else if (!valid_a && valid_b) {
        newest = summaries[1].container_epoch;
    } else {
        comparison = generation_compare(summaries[0].container_epoch,
                                        summaries[1].container_epoch);
        if (comparison == 2) {
            return GK_ERR_CORRUPT;
        }
        newest = comparison < 0 ? summaries[1].container_epoch
                                : summaries[0].container_epoch;
    }
    *epoch_a = next_generation(newest);
    *epoch_b = next_generation(*epoch_a);
    return GK_OK;
}

static CODE int32_t create_pair_from_canonical(uint8_t kind, uint8_t flags) {
    uint32_t epoch_a;
    uint32_t epoch_b;
    uint32_t kit;
    int32_t status = fresh_container_epochs(kind, &epoch_a, &epoch_b);
    if (status < 0) {
        return status;
    }
    kind_container_epochs(kind)[0] = epoch_a;
    kind_container_epochs(kind)[1] = epoch_b;
    status = write_new_peer(kind, 1, epoch_b, 1U, 0U,
                            __gk_pattern_assignments,
                            __gk_pattern_assignment_valid, flags, -1);
    if (status < 0) {
        return status;
    }
    status = write_new_peer(kind, 0, epoch_a, 1U, 1U,
                            __gk_pattern_assignments,
                            __gk_pattern_assignment_valid, flags, -1);
    if (status < 0) {
        return status;
    }
    for (kit = 0; kit != KIT_COUNT; ++kit) {
        kind_generations(kind)[kit] = 1U;
    }
    bytes_clear(kind_sources(kind), KIT_COUNT / 8U);
    bytes_fill(kind_valid(kind), 0xFFU, KIT_COUNT / 8U);
    set_kind_image_state(kind, 1U, 1U, 0U, 1U, 0U, flags);
    set_kind_ready(kind, true);
    if (kind == V3_KIND_STORED) {
        bytes_copy(assignment_buffer(), __gk_pattern_assignments,
                   PATTERN_COUNT);
        bytes_copy(assignment_buffer() + PATTERN_COUNT,
                   __gk_pattern_assignment_valid, PATTERN_COUNT / 8U);
    }
    publish_compatibility_state(kind);
    return GK_OK;
}

INLINE const uint8_t *kind_assignments(uint8_t kind) {
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    return kind == V3_KIND_WORK ? __gk_pattern_assignments
                                : assignment_buffer();
#else
    return kind == V3_KIND_WORK ? __gk_pattern_assignments
                                : __gk_io_buffer + 0x400U;
#endif
}

INLINE const uint8_t *kind_assignment_valid(uint8_t kind) {
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    return kind == V3_KIND_WORK ? __gk_pattern_assignment_valid
                                : assignment_buffer() + PATTERN_COUNT;
#else
    return kind == V3_KIND_WORK ? __gk_pattern_assignment_valid
                                : __gk_io_buffer + 0x500U;
#endif
}

static CODE int32_t repair_missing_peer(uint8_t kind, uint8_t peer) {
    uint32_t epoch_a;
    uint32_t epoch_b;
    uint32_t fresh_epoch;
    int32_t status;
    if (!kind_ready(kind) || peer > 1U) {
        return GK_ERR_CORRUPT;
    }
    if (kind_container_epochs(kind)[peer] != 0U) {
        return GK_OK;
    }
    status = fresh_container_epochs(kind, &epoch_a, &epoch_b);
    if (status < 0) {
        return status;
    }
    fresh_epoch = peer == 0U ? epoch_a : epoch_b;
    kind_container_epochs(kind)[peer] = fresh_epoch;
    status = write_new_peer(
        kind, peer, fresh_epoch, kind_image_epoch(kind),
        kind_root_generation(kind) - 1U, kind_assignments(kind),
        kind_assignment_valid(kind), kind_flags(kind), kind
    );
    if (status < 0) {
        kind_container_epochs(kind)[peer] = 0U;
    }
    return status;
}

static CODE int32_t ensure_target_peer(uint8_t kind, uint8_t peer) {
    if (peer > 1U) {
        return GK_ERR_RANGE;
    }
    return kind_container_epochs(kind)[peer] == 0U
               ? repair_missing_peer(kind, peer)
               : GK_OK;
}

static CODE int32_t create_pair_from_kind(uint8_t destination_kind,
                                          uint8_t source_kind,
                                          uint8_t flags) {
    uint32_t epoch_a;
    uint32_t epoch_b;
    uint32_t kit;
    int32_t status;
    if (!kind_ready(source_kind)) {
        return GK_ERR_CORRUPT;
    }
    status = fresh_container_epochs(destination_kind, &epoch_a, &epoch_b);
    if (status < 0) {
        return status;
    }
    kind_container_epochs(destination_kind)[0] = epoch_a;
    kind_container_epochs(destination_kind)[1] = epoch_b;
    status = write_new_peer(
        destination_kind, 1, epoch_b, 1U, 0U,
        kind_assignments(source_kind), kind_assignment_valid(source_kind),
        flags, source_kind
    );
    if (status < 0) {
        return status;
    }
    status = write_new_peer(
        destination_kind, 0, epoch_a, 1U, 1U,
        kind_assignments(source_kind), kind_assignment_valid(source_kind),
        flags, source_kind
    );
    if (status < 0) {
        return status;
    }
    for (kit = 0; kit != KIT_COUNT; ++kit) {
        kind_generations(destination_kind)[kit] = 1U;
    }
    bytes_clear(kind_sources(destination_kind), KIT_COUNT / 8U);
    bytes_fill(kind_valid(destination_kind), 0xFFU, KIT_COUNT / 8U);
    set_kind_image_state(destination_kind, 1U, 1U, 0U, 1U, 0U, flags);
    set_kind_ready(destination_kind, true);
    if (destination_kind == V3_KIND_STORED) {
        bytes_copy(assignment_buffer(), kind_assignments(source_kind),
                   PATTERN_COUNT);
        bytes_copy(assignment_buffer() + PATTERN_COUNT,
                   kind_assignment_valid(source_kind),
                   PATTERN_COUNT / 8U);
    }
    publish_compatibility_state(destination_kind);
    return GK_OK;
}

#ifdef GK_V3_PROJECT_IO_OPTIMIZED
/*
 * Publish a complete canonical image without reopening the same peer for
 * every Kit.  Records still go only to their inactive peer, and the caller
 * publishes the root only after both peer sessions have closed successfully.
 */
static CODE int32_t canonical_records_write(uint8_t kind,
                                            uint32_t image_epoch) {
    char path[PROJECT_PATH_SIZE];
    FileObject object;
    uint8_t peer;
    for (peer = 0; peer != 2U; ++peer) {
        bool peer_needed = false;
        uint32_t kit;
        int32_t status;
        for (kit = 0; kit != KIT_COUNT; ++kit) {
            uint8_t target = bitmap_test(kind_sources(kind), kit) ? 0U : 1U;
            if (target == peer) {
                peer_needed = true;
                break;
            }
        }
        if (!peer_needed) {
            continue;
        }
        status = gk_v3_project_path_build_impl(path, image_suffix(kind, peer));
        if (status < 0) {
            return status;
        }
        status = open_path_sized(&object, path, mode_write,
                                 fixed_file_buffer(), V3_RECORD_SIZE);
        if (status < 0) {
            return status;
        }
        if (file_size(&object) != V3_PEER_SIZE) {
            status = GK_ERR_CORRUPT;
        }
        for (kit = 0; status >= 0 && kit != KIT_COUNT; ++kit) {
            uint8_t target = bitmap_test(kind_sources(kind), kit) ? 0U : 1U;
            if (target != peer) {
                continue;
            }
            if (object.words[FILE_OBJECT_BUFFERED_COUNT_WORD] != 0U) {
                status = GK_ERR_CORRUPT;
                break;
            }
            if (object.words[FILE_OBJECT_LOGICAL_LENGTH_WORD] !=
                    record_offset(kit) &&
                gk_v3_stock_file_seek(&object, record_offset(kit)) < 0) {
                status = GK_ERR_IO;
                break;
            }
            stage_from_canonical(kit);
            record_finish_encode(__gk_v3_record_stage, kind, peer, kit,
                                 image_epoch, 1U);
            status = write_exact(&object, __gk_v3_record_stage,
                                 V3_RECORD_SIZE);
            if (status >= 0 &&
                object.words[FILE_OBJECT_BUFFERED_COUNT_WORD] != 0U) {
                status = GK_ERR_CORRUPT;
            }
        }
        object.words[FILE_OBJECT_LOGICAL_LENGTH_WORD] = V3_PEER_SIZE;
        status = close_preserve(&object, status);
        if (status < 0) {
            return status;
        }
    }
    return GK_OK;
}

#ifdef GK_V3_PROJECT_RELOAD_IO_OPTIMIZED
/*
 * Copy a selected source image into the inactive destination records while
 * keeping each participating peer open.  Project Reload cannot borrow the
 * canonical Work library: playback may still consume it until the later
 * stock full-project load quiesces and publishes the restored Work image.
 * Two stock-sized read streams therefore authenticate the selected Stored
 * records directly, while one record-sized destination stream preserves the
 * same inactive-record/root-last transaction as the historical writer.
 */
static CODE int32_t selected_records_write(uint8_t destination_kind,
                                           uint8_t source_kind,
                                           uint32_t image_epoch) {
    char path[PROJECT_PATH_SIZE];
    FileObject sources[2];
    FileObject destination;
    uint32_t source_offsets[2];
    uint8_t target_peer;
    for (target_peer = 0; target_peer != 2U; ++target_peer) {
        uint8_t source_open_mask = 0U;
        bool destination_open = false;
        bool target_needed = false;
        uint32_t kit;
        int32_t status = GK_OK;
        for (kit = 0; kit != KIT_COUNT; ++kit) {
            uint8_t target = bitmap_test(
                kind_sources(destination_kind), kit
            ) ? 0U : 1U;
            if (target == target_peer) {
                target_needed = true;
                break;
            }
        }
        if (!target_needed) {
            continue;
        }
        status = gk_v3_project_path_build_impl(
            path, image_suffix(destination_kind, target_peer)
        );
        if (status >= 0) {
            status = open_path_sized(
                &destination, path, mode_write,
                fixed_file_buffer(), V3_RECORD_SIZE
            );
        }
        if (status >= 0) {
            destination_open = true;
            if (file_size(&destination) != V3_PEER_SIZE) {
                status = GK_ERR_CORRUPT;
            }
        }
        for (kit = 0; status >= 0 && kit != KIT_COUNT; ++kit) {
            uint8_t target = bitmap_test(
                kind_sources(destination_kind), kit
            ) ? 0U : 1U;
            uint8_t source_peer;
            FileObject *source;
            if (target != target_peer) {
                continue;
            }
            source_peer = bitmap_test(kind_sources(source_kind), kit)
                              ? 1U : 0U;
            source = &sources[source_peer];
            if ((source_open_mask & (uint8_t)(1U << source_peer)) == 0U) {
                status = gk_v3_project_path_build_impl(
                    path, image_suffix(source_kind, source_peer)
                );
                if (status >= 0) {
                    status = open_path_sized(
                        source, path, mode_read,
                        source_peer == 0U ? read_stream_buffer()
                                          : write_stream_buffer(),
                        STREAM_BUFFER_SIZE
                    );
                }
                if (status < 0) {
                    break;
                }
                source_open_mask |= (uint8_t)(1U << source_peer);
                source_offsets[source_peer] = 0U;
                if (file_size(source) != V3_PEER_SIZE) {
                    status = GK_ERR_CORRUPT;
                    break;
                }
            }
            if (source_offsets[source_peer] != record_offset(kit)) {
#ifdef GK_V3_PROJECT_RELOAD_READ_SEEK_FIXED
                /*
                 * Stock buffered_file_seek moves the backend handle but
                 * deliberately leaves FileObject word 3 unchanged.  That
                 * word is the read-buffer cursor, so a later read would
                 * consume stale bytes whenever this 64 KiB stream seeks
                 * after a partial buffer.  Project Reload visits sparse
                 * records whenever either selected A/B image is mixed.
                 * Discard the read cache before the sector-aligned seek;
                 * the next read then refills from the new backend position.
                 */
                source->words[FILE_OBJECT_BUFFERED_COUNT_WORD] = 0U;
#endif
                if (gk_v3_stock_file_seek(source, record_offset(kit)) < 0) {
                    status = GK_ERR_IO;
                    break;
                }
            }
            source_offsets[source_peer] = record_offset(kit);
            status = read_exact(source, __gk_v3_record_stage,
                                V3_RECORD_SIZE);
            if (status < 0 ||
                !record_valid(
                    __gk_v3_record_stage,
                    kind_container_epochs(source_kind)[source_peer], kit
                ) ||
                load_u32(__gk_v3_record_stage + 16) !=
                    kind_image_epoch(source_kind) ||
                load_u32(__gk_v3_record_stage + 20) !=
                    kind_generations(source_kind)[kit]) {
                status = status < 0 ? status : GK_ERR_CORRUPT;
                break;
            }
            source_offsets[source_peer] += V3_RECORD_SIZE;
            record_finish_encode(__gk_v3_record_stage, destination_kind,
                                 target_peer, kit, image_epoch, 1U);
            if (destination.words[FILE_OBJECT_LOGICAL_LENGTH_WORD] !=
                    record_offset(kit) &&
                gk_v3_stock_file_seek(&destination,
                                      record_offset(kit)) < 0) {
                status = GK_ERR_IO;
                break;
            }
            status = write_exact(&destination, __gk_v3_record_stage,
                                 V3_RECORD_SIZE);
            if (status >= 0 &&
                destination.words[FILE_OBJECT_BUFFERED_COUNT_WORD] != 0U) {
                status = GK_ERR_CORRUPT;
            }
        }
        if (destination_open) {
            destination.words[FILE_OBJECT_LOGICAL_LENGTH_WORD] = V3_PEER_SIZE;
            status = close_preserve(&destination, status);
        }
        for (kit = 0; kit != 2U; ++kit) {
            if ((source_open_mask & (uint8_t)(1U << kit)) != 0U) {
                status = close_preserve(&sources[kit], status);
            }
        }
        if (status < 0) {
            return status;
        }
    }
    return GK_OK;
}
#endif
#endif

static CODE int32_t replace_kind_from_source(
    uint8_t destination_kind, int32_t source_kind,
    const uint8_t *assignments, const uint8_t *assignment_valid,
    uint8_t flags
) {
    uint32_t candidate_epoch;
    uint32_t candidate_root_generation;
    uint32_t kit;
    uint8_t root_target;
    uint8_t *stage = __gk_v3_record_stage;
    int32_t status;
    if (!kind_ready(destination_kind)) {
        if (source_kind < 0) {
            return create_pair_from_canonical(destination_kind, flags);
        }
        return create_pair_from_kind(destination_kind,
                                     (uint8_t)source_kind, flags);
    }
    status = ensure_target_peer(destination_kind, 0);
    if (status < 0) {
        return status;
    }
    status = ensure_target_peer(destination_kind, 1);
    if (status < 0) {
        return status;
    }
    candidate_epoch = next_generation(kind_image_epoch(destination_kind));
    candidate_root_generation =
        next_generation(kind_root_generation(destination_kind));
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    if (source_kind < 0) {
        status = canonical_records_write(destination_kind, candidate_epoch);
        if (status < 0) {
            return status;
        }
    }
#ifdef GK_V3_PROJECT_RELOAD_IO_OPTIMIZED
    else {
        status = selected_records_write(
            destination_kind, (uint8_t)source_kind, candidate_epoch
        );
        if (status < 0) {
            return status;
        }
    }
#else
    else
#endif
#endif
#ifndef GK_V3_PROJECT_RELOAD_IO_OPTIMIZED
    for (kit = 0; kit != KIT_COUNT; ++kit) {
        uint8_t target = bitmap_test(kind_sources(destination_kind), kit)
                             ? 0U
                             : 1U;
        if (source_kind < 0) {
            stage_from_canonical(kit);
        } else {
            status = selected_record_read((uint8_t)source_kind, kit, stage);
            if (status < 0) {
                return status;
            }
        }
        record_finish_encode(stage, destination_kind, target, kit,
                             candidate_epoch, 1U);
        status = fixed_write(destination_kind, target, record_offset(kit),
                             stage, V3_RECORD_SIZE);
        if (status < 0) {
            return status;
        }
    }
#endif
    root_target = kind_root_peer(destination_kind) ^ 1U;
    manifest_encode(stage, destination_kind, V3_ROLE_ROOT,
                    kind_container_epochs(destination_kind)[root_target],
                    candidate_epoch, candidate_root_generation, assignments,
                    assignment_valid, flags);
    status = fixed_write(destination_kind, root_target, V3_ROOT_OFFSET,
                         stage, V3_MANIFEST_SIZE);
    if (status < 0) {
        return status;
    }
    for (kit = 0; kit != KIT_COUNT; ++kit) {
        if (bitmap_test(kind_sources(destination_kind), kit)) {
            bitmap_clear(kind_sources(destination_kind), kit);
        } else {
            bitmap_set(kind_sources(destination_kind), kit);
        }
        kind_generations(destination_kind)[kit] = 1U;
    }
    bytes_fill(kind_valid(destination_kind), 0xFFU, KIT_COUNT / 8U);
    set_kind_image_state(destination_kind, candidate_epoch,
                         candidate_root_generation, root_target,
                         candidate_root_generation, root_target, flags);
    if (destination_kind == V3_KIND_STORED) {
        bytes_copy(assignment_buffer(), assignments, PATTERN_COUNT);
        bytes_copy(assignment_buffer() + PATTERN_COUNT, assignment_valid,
                   PATTERN_COUNT / 8U);
    }
    publish_compatibility_state(destination_kind);
    return GK_OK;
}

static CODE int32_t overlay_commit(uint8_t kind,
                                   const uint8_t *assignments,
                                   const uint8_t *assignment_valid,
                                   uint8_t flags) {
    uint8_t target;
    uint32_t generation;
    uint8_t *stage = __gk_v3_record_stage;
    int32_t status;
    if (!kind_ready(kind)) {
        return GK_ERR_CORRUPT;
    }
    target = kind_manifest_peer(kind) ^ 1U;
    status = ensure_target_peer(kind, target);
    if (status < 0) {
        return status;
    }
    generation = next_generation(kind_manifest_generation(kind));
    manifest_encode(stage, kind, V3_ROLE_OVERLAY,
                    kind_container_epochs(kind)[target],
                    kind_image_epoch(kind), generation, assignments,
                    assignment_valid, flags);
    status = fixed_write(kind, target, V3_OVERLAY_OFFSET, stage,
                         V3_MANIFEST_SIZE);
    if (status < 0) {
        return status;
    }
    if (kind == V3_KIND_WORK) {
        __gk_v3_state_header.work_manifest_generation = generation;
        __gk_v3_state_header.work_manifest_peer = target;
        __gk_v3_state_header.work_flags = flags;
    } else {
        __gk_v3_state_header.stored_manifest_generation = generation;
        __gk_v3_state_header.stored_manifest_peer = target;
        __gk_v3_state_header.stored_flags = flags;
        bytes_copy(assignment_buffer(), assignments, PATTERN_COUNT);
        bytes_copy(assignment_buffer() + PATTERN_COUNT, assignment_valid,
                   PATTERN_COUNT / 8U);
    }
    publish_compatibility_state(kind);
    return GK_OK;
}

static CODE int32_t staged_work_record_commit(uint32_t kit) {
    uint8_t target;
    uint32_t generation;
    bool repaired;
    int32_t status;
    if (!kind_ready(V3_KIND_WORK) || kit >= KIT_COUNT) {
        return GK_ERR_CORRUPT;
    }
    target = bitmap_test(__gk_v3_work_source_bitmap, kit) ? 0U : 1U;
    repaired = kind_container_epochs(V3_KIND_WORK)[target] == 0U;
    status = ensure_target_peer(V3_KIND_WORK, target);
    if (status < 0) {
        return status;
    }
    if (repaired) {
        /* Peer recreation uses the shared record stage; snapshot it again. */
        status = gk_persistence_snapshot_begin();
        if (status < 0) {
            return status;
        }
        stage_from_canonical(kit);
        status = gk_persistence_snapshot_end();
        if (status < 0) {
            return status;
        }
    }
    generation = next_generation(__gk_v3_work_generations[kit]);
    record_finish_encode(__gk_v3_record_stage, V3_KIND_WORK, target, kit,
                         __gk_v3_state_header.work_image_epoch, generation);
    status = fixed_write(V3_KIND_WORK, target, record_offset(kit),
                         __gk_v3_record_stage, V3_RECORD_SIZE);
    if (status < 0) {
        return status;
    }
    __gk_v3_work_generations[kit] = generation;
    if (target != 0U) {
        bitmap_set(__gk_v3_work_source_bitmap, kit);
    } else {
        bitmap_clear(__gk_v3_work_source_bitmap, kit);
    }
    bitmap_set(__gk_v3_work_valid_bitmap, kit);
    return GK_OK;
}

INLINE int32_t first_set_bit(const uint8_t *bitmap) {
    uint32_t index;
    for (index = 0; index != KIT_COUNT; ++index) {
        if (bitmap_test(bitmap, index)) {
            return (int32_t)index;
        }
    }
    return -1;
}

static CODE int32_t claim_dirty_record(uint32_t *kit,
                                       bool *was_dependency) {
    uint32_t index;
    int32_t selected = -1;
    int32_t status = gk_persistence_snapshot_begin();
    if (status < 0) {
        return status;
    }
    for (index = 0; index != KIT_COUNT; ++index) {
        if (bitmap_test(__gk_v3_work_dirty_bitmap, index) &&
            bitmap_test(__gk_v3_assignment_dependency_bitmap, index)) {
            selected = (int32_t)index;
            break;
        }
    }
    if (selected < 0) {
        selected = first_set_bit(__gk_v3_work_dirty_bitmap);
    }
    if (selected < 0) {
        (void)gk_persistence_snapshot_end();
        return GK_ERR_NOT_FOUND;
    }
    *kit = (uint32_t)selected;
    *was_dependency = bitmap_test(__gk_v3_assignment_dependency_bitmap,
                                  *kit);
    stage_from_canonical(*kit);
    bitmap_clear(__gk_v3_work_dirty_bitmap, *kit);
    status = gk_persistence_snapshot_end();
    if (status < 0) {
        bitmap_set(__gk_v3_work_dirty_bitmap, *kit);
    }
    return status;
}

static CODE int32_t claim_overlay(void) {
    int32_t status;
    status = gk_persistence_snapshot_begin();
    if (status < 0) {
        return status;
    }
    /* A SAVE AS dependency may appear before the gate is acquired. */
    if (!bitmap_empty(__gk_v3_assignment_dependency_bitmap)) {
        status = gk_persistence_snapshot_end();
        return status < 0 ? status : GK_ERR_BUSY;
    }
    if ((__gk_v3_state_header.flags & V3_STATE_WORK_OVERLAY_DIRTY) == 0U) {
        (void)gk_persistence_snapshot_end();
        return GK_ERR_NOT_FOUND;
    }
    manifest_encode(__gk_v3_record_stage, V3_KIND_WORK, V3_ROLE_OVERLAY,
                    0U, kind_image_epoch(V3_KIND_WORK), 0U,
                    __gk_pattern_assignments,
                    __gk_pattern_assignment_valid,
                    kind_flags(V3_KIND_WORK));
    __gk_v3_state_header.flags &= ~V3_STATE_WORK_OVERLAY_DIRTY;
    status = gk_persistence_snapshot_end();
    if (status < 0) {
        __gk_v3_state_header.flags |= V3_STATE_WORK_OVERLAY_DIRTY;
    }
    return status;
}

static CODE int32_t claimed_overlay_commit(void) {
    uint8_t target = kind_manifest_peer(V3_KIND_WORK) ^ 1U;
    uint32_t generation =
        next_generation(kind_manifest_generation(V3_KIND_WORK));
    int32_t status;
    if (kind_container_epochs(V3_KIND_WORK)[target] == 0U) {
        return GK_ERR_CORRUPT;
    }
    store_u32(__gk_v3_record_stage + 12,
              kind_container_epochs(V3_KIND_WORK)[target]);
    store_u32(__gk_v3_record_stage + 20, generation);
    store_u32(__gk_v3_record_stage + V3_BLOCK_CRC_OFFSET,
              block_crc(__gk_v3_record_stage, V3_BLOCK_CRC_OFFSET));
    status = fixed_write(V3_KIND_WORK, target, V3_OVERLAY_OFFSET,
                         __gk_v3_record_stage, V3_MANIFEST_SIZE);
    if (status < 0) {
        return status;
    }
    __gk_v3_state_header.work_manifest_generation = generation;
    __gk_v3_state_header.work_manifest_peer = target;
    publish_compatibility_state(V3_KIND_WORK);
    return GK_OK;
}

static CODE int32_t ensure_work_overlay_target(void) {
    uint8_t target = kind_manifest_peer(V3_KIND_WORK) ^ 1U;
    return ensure_target_peer(V3_KIND_WORK, target);
}

INLINE void restore_dirty_record(uint32_t kit) {
    uint32_t status = gk_v3_irq_lock();
    bitmap_set(__gk_v3_work_dirty_bitmap, kit);
    __gk_runtime_flags |= RUNTIME_STORAGE_DIRTY;
    gk_v3_irq_restore(status);
}

INLINE void restore_dirty_overlay(void) {
    uint32_t status = gk_v3_irq_lock();
    __gk_v3_state_header.flags |= V3_STATE_WORK_OVERLAY_DIRTY;
    __gk_runtime_flags |= RUNTIME_STORAGE_DIRTY;
    gk_v3_irq_restore(status);
}

INLINE void settle_runtime_dirty(void) {
    uint32_t status = gk_v3_irq_lock();
    if (bitmap_empty(__gk_v3_work_dirty_bitmap) &&
        bitmap_empty(__gk_v3_assignment_dependency_bitmap) &&
        (__gk_v3_state_header.flags & V3_STATE_WORK_OVERLAY_DIRTY) == 0U) {
        __gk_runtime_flags &= (uint8_t)~RUNTIME_STORAGE_DIRTY;
    } else {
        __gk_runtime_flags |= RUNTIME_STORAGE_DIRTY;
    }
    gk_v3_irq_restore(status);
}

CODE int32_t gk_v3_mark_kit_dirty_impl(uint32_t kit) {
    uint32_t status;
    if (kit >= KIT_COUNT) {
        return GK_ERR_RANGE;
    }
    status = gk_v3_irq_lock();
    bitmap_set(__gk_v3_work_dirty_bitmap, kit);
    __gk_runtime_flags |= RUNTIME_STORAGE_DIRTY;
    gk_v3_irq_restore(status);
    return GK_OK;
}

CODE int32_t gk_v3_mark_assignment_dirty_impl(uint32_t pattern,
                                              uint32_t kit) {
    uint32_t status;
    if (pattern >= PATTERN_COUNT || kit >= KIT_COUNT) {
        return GK_ERR_RANGE;
    }
    status = gk_v3_irq_lock();
    __gk_v3_state_header.flags |= V3_STATE_WORK_OVERLAY_DIRTY;
    if (bitmap_test(__gk_v3_work_dirty_bitmap, kit)) {
        bitmap_set(__gk_v3_assignment_dependency_bitmap, kit);
    }
    __gk_runtime_flags |= RUNTIME_STORAGE_DIRTY;
    gk_v3_irq_restore(status);
    return GK_OK;
}

CODE int32_t gk_v3_work_commit_impl(void) {
    uint32_t kit;
    bool was_dependency;
    int32_t status;
    if (!kind_ready(V3_KIND_WORK)) {
        status = select_kind(V3_KIND_WORK, true);
        if (status < 0) {
            invalidate_compatibility_state(V3_KIND_WORK, status);
            return status;
        }
    }
    if (bitmap_empty(__gk_v3_work_dirty_bitmap) &&
        (__gk_v3_state_header.flags & V3_STATE_WORK_OVERLAY_DIRTY) == 0U &&
        (__gk_runtime_flags & RUNTIME_STORAGE_DIRTY) != 0U) {
        bytes_fill(__gk_v3_work_dirty_bitmap, 0xFFU, KIT_COUNT / 8U);
        __gk_v3_state_header.flags |= V3_STATE_WORK_OVERLAY_DIRTY |
                                      V3_STATE_WORK_OVERLAY_UNKNOWN;
    }
    status = claim_dirty_record(&kit, &was_dependency);
    if (status == GK_OK) {
        HOST_EVENT(1U, kit);
        status = staged_work_record_commit(kit);
        if (status < 0) {
            restore_dirty_record(kit);
            __gk_persistence_last_error = status;
            return status;
        }
        {
            uint32_t irq_status = gk_v3_irq_lock();
            if (!bitmap_test(__gk_v3_work_dirty_bitmap, kit)) {
                bitmap_clear(__gk_v3_assignment_dependency_bitmap, kit);
            }
            gk_v3_irq_restore(irq_status);
        }
        if (was_dependency &&
            bitmap_empty(__gk_v3_assignment_dependency_bitmap) &&
            (__gk_v3_state_header.flags &
             V3_STATE_WORK_OVERLAY_DIRTY) != 0U) {
            status = ensure_work_overlay_target();
            if (status < 0) {
                __gk_persistence_last_error = status;
                return status;
            }
            status = claim_overlay();
            if (status == GK_OK) {
                HOST_EVENT(2U, 0U);
                status = claimed_overlay_commit();
                if (status < 0) {
                    restore_dirty_overlay();
                    __gk_persistence_last_error = status;
                    return status;
                }
            }
        }
        settle_runtime_dirty();
        __gk_persistence_last_error = GK_OK;
        return GK_OK;
    }
    if (status != GK_ERR_NOT_FOUND) {
        return status;
    }
    status = ensure_work_overlay_target();
    if (status >= 0) {
        status = claim_overlay();
    }
    if (status == GK_OK) {
        HOST_EVENT(2U, 0U);
        status = claimed_overlay_commit();
        if (status < 0) {
            restore_dirty_overlay();
            __gk_persistence_last_error = status;
            return status;
        }
    } else if (status != GK_ERR_NOT_FOUND) {
        return status;
    }
    settle_runtime_dirty();
    __gk_persistence_last_error = GK_OK;
    return GK_OK;
}

CODE int32_t gk_v3_work_commit_locked_impl(void) {
    if (__gk_persistence_snapshot_gate != PERSIST_SNAPSHOT_ACTIVE) {
        return GK_ERR_CORRUPT;
    }
    if (!kind_ready(V3_KIND_WORK)) {
        return create_pair_from_canonical(V3_KIND_WORK,
                                          V3_FLAG_STORED_PENDING);
    }
    return replace_kind_from_source(
        V3_KIND_WORK, -1, __gk_pattern_assignments,
        __gk_pattern_assignment_valid, kind_flags(V3_KIND_WORK)
    );
}

#ifndef GK_V3_PROJECT_IO_OPTIMIZED
CODE int32_t gk_v3_legacy_header_validate_impl(const uint8_t *header,
                                               uint32_t *generation,
                                               uint32_t *version) {
    uint32_t candidate_version;
    if (header == NULL || generation == NULL || version == NULL ||
        !bytes_equal(header, magic_legacy, 8)) {
        return GK_ERR_CORRUPT;
    }
    candidate_version = header[8];
    if ((candidate_version != LEGACY_VERSION_V1 &&
         candidate_version != LEGACY_VERSION_V2) ||
        (header[9] & (uint8_t)~V3_FLAG_STORED_PENDING) != 0U ||
        load_u16(header + 10) != LEGACY_HEADER_SIZE ||
        load_u16(header + 16) != KIT_COUNT ||
        load_u16(header + 18) != PART_PAYLOAD_SIZE ||
        load_u16(header + 22) != PATTERN_COUNT || header[24] != 1U) {
        return GK_ERR_CORRUPT;
    }
    if (candidate_version == LEGACY_VERSION_V1) {
        if (load_u16(header + 20) != 7U || header[25] != 0U) {
            return GK_ERR_CORRUPT;
        }
    } else if (load_u16(header + 20) != KIT_NAME_SIZE ||
               header[25] != 2U) {
        return GK_ERR_CORRUPT;
    }
    *generation = load_u32(header + 12);
    *version = candidate_version;
    return GK_OK;
}

static CODE int32_t legacy_stream(const char *path, int32_t mode,
                                  uint32_t *generation,
                                  uint32_t *version) {
    FileObject object;
    uint8_t *header = __gk_v3_record_stage;
    uint8_t *buffer = __gk_io_buffer + 0x520U;
    uint32_t expected_size;
    uint32_t metadata_size;
    uint32_t remaining;
    uint32_t crc;
    uint32_t stored_crc;
    uint32_t local_generation;
    uint32_t local_version;
    uint8_t local_flags;
    int32_t status;
    if (path == NULL || mode < 0 || mode > 2) {
        return GK_ERR_RANGE;
    }
    status = open_path(&object, path, mode_read, __gk_io_buffer);
    if (status < 0) {
        return status;
    }
    status = read_exact(&object, header, LEGACY_HEADER_SIZE);
    if (status < 0) {
        return close_preserve(&object, status);
    }
    status = gk_v3_legacy_header_validate_impl(
        header, &local_generation, &local_version
    );
    if (status < 0) {
        return close_preserve(&object, status);
    }
    expected_size = local_version == LEGACY_VERSION_V1
                        ? LEGACY_SIZE_V1
                        : LEGACY_SIZE_V2;
    metadata_size = local_version == LEGACY_VERSION_V1
                        ? LEGACY_META_SIZE_V1
                        : LEGACY_META_SIZE_V2;
    local_flags = header[9];
    if (file_size(&object) != (int32_t)expected_size) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    crc = gk_v3_crc32_update_impl(header, LEGACY_HEADER_SIZE, 0xFFFFFFFFU);
    status = read_exact(&object, buffer, metadata_size);
    if (status < 0) {
        return close_preserve(&object, status);
    }
    crc = gk_v3_crc32_update_impl(buffer, metadata_size, crc);
    if (local_version == LEGACY_VERSION_V1 &&
        !bytes_value(buffer + PATTERN_COUNT, 0xFFU, 32U)) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    if (mode == 1) {
        uint32_t kit;
        bytes_copy(__gk_pattern_assignments, buffer, PATTERN_COUNT);
        if (local_version == LEGACY_VERSION_V1) {
            bytes_fill(__gk_pattern_assignment_valid, 0xFFU, 32U);
            bytes_fill(__gk_initialized_bitmap, 0xFFU, 32U);
            for (kit = 0; kit != KIT_COUNT; ++kit) {
                bytes_copy(__gk_kit_names + kit * KIT_NAME_SIZE,
                           buffer + 0x120U + kit * 7U, 7U);
                __gk_kit_names[kit * KIT_NAME_SIZE + 7U] = 0U;
            }
        } else {
            bytes_copy(__gk_pattern_assignment_valid,
                       buffer + PATTERN_COUNT, 32U);
            bytes_copy(__gk_initialized_bitmap,
                       buffer + PATTERN_COUNT + 32U, 32U);
            bytes_copy(__gk_kit_names,
                       buffer + PATTERN_COUNT + 64U,
                       KIT_COUNT * KIT_NAME_SIZE);
            for (kit = 0; kit != KIT_COUNT; ++kit) {
                __gk_kit_names[kit * KIT_NAME_SIZE + 7U] = 0U;
            }
        }
    } else if (mode == 2) {
        uint8_t *assignment_buffer = __gk_io_buffer + 0x400U;
        bytes_copy(assignment_buffer, buffer, PATTERN_COUNT);
        if (local_version == LEGACY_VERSION_V1) {
            bytes_fill(assignment_buffer + PATTERN_COUNT, 0xFFU, 32U);
        } else {
            bytes_copy(assignment_buffer + PATTERN_COUNT,
                       buffer + PATTERN_COUNT, 32U);
        }
    }
    remaining = LEGACY_PAYLOAD_SIZE;
    {
        uint8_t *payload_destination = __gk_canonical_payloads;
        while (remaining != 0U) {
            uint32_t count = remaining > 0xB00U ? 0xB00U : remaining;
            uint8_t *destination = mode == 1 ? payload_destination : buffer;
            status = read_exact(&object, destination, count);
            if (status < 0) {
                return close_preserve(&object, status);
            }
            crc = gk_v3_crc32_update_impl(destination, count, crc);
            if (mode == 1) {
                payload_destination += count;
            }
            remaining -= count;
        }
    }
    status = read_exact(&object, header, 4U);
    if (status < 0) {
        return close_preserve(&object, status);
    }
    stored_crc = load_u32(header);
    if ((~crc) != stored_crc) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    status = close_preserve(&object, GK_OK);
    if (status < 0) {
        return status;
    }
    *generation = local_generation;
    *version = local_version;
    return local_flags;
}

CODE int32_t gk_v3_compat_peer_read_impl(int32_t mode, const char *path,
                                         uint32_t *generation,
                                         uint32_t *version) {
    return legacy_stream(path, mode, generation, version);
}

CODE int32_t gk_v3_compat_pair_select_impl(const char *path_a,
                                           const char *path_b,
                                           uint32_t *generation,
                                           uint32_t *flags) {
    uint32_t generations[2];
    uint32_t versions[2];
    int32_t results[2];
    int comparison;
    uint8_t selected;
    results[0] = legacy_stream(path_a, 0, &generations[0], &versions[0]);
    results[1] = legacy_stream(path_b, 0, &generations[1], &versions[1]);
    if (results[0] < 0 && results[1] < 0) {
        if (results[0] == GK_ERR_IO || results[1] == GK_ERR_IO) {
            return GK_ERR_IO;
        }
        return GK_ERR_INVALID;
    }
    if (results[0] >= 0 && results[1] < 0) {
        selected = 0U;
    } else if (results[0] < 0) {
        selected = 1U;
    } else {
        comparison = generation_compare(generations[0], generations[1]);
        if (comparison == 2) {
            selected = 0U;
        } else if (comparison < 0) {
            selected = 1U;
        } else {
            selected = 0U;
        }
        if (comparison == 0 && results[0] != results[1]) {
            return GK_ERR_CORRUPT;
        }
    }
    *generation = generations[selected];
    *flags = (uint32_t)results[selected];
    return selected;
}

static CODE int32_t legacy_kind_select(uint8_t kind, int32_t mode,
                                       uint32_t *selected_generation,
                                       uint32_t *selected_version,
                                       uint8_t *selected_flags) {
    char path_a[PROJECT_PATH_SIZE];
    char path_b[PROJECT_PATH_SIZE];
    uint32_t generation;
    uint32_t flags;
    uint32_t version;
    int32_t selected;
    int32_t status = gk_v3_project_path_build_impl(
        path_a, legacy_suffix(kind, 0)
    );
    if (status < 0) {
        return status;
    }
    status = gk_v3_project_path_build_impl(path_b, legacy_suffix(kind, 1));
    if (status < 0) {
        return status;
    }
    selected = gk_v3_compat_pair_select_impl(path_a, path_b,
                                              &generation, &flags);
    if (selected < 0) {
        return selected;
    }
    status = legacy_stream(selected == 0 ? path_a : path_b, mode,
                           &generation, &version);
    if (status < 0 || (uint32_t)status != flags) {
        return status < 0 ? status : GK_ERR_CORRUPT;
    }
    *selected_generation = generation;
    *selected_version = version;
    *selected_flags = (uint8_t)flags;
    return GK_OK;
}
#else
CODE int32_t gk_v3_legacy_header_validate_impl(const uint8_t *header,
                                               uint32_t *generation,
                                               uint32_t *version) {
    (void)header;
    (void)generation;
    (void)version;
    return GK_ERR_INVALID;
}

CODE int32_t gk_v3_compat_peer_read_impl(int32_t mode, const char *path,
                                         uint32_t *generation,
                                         uint32_t *version) {
    (void)mode;
    (void)path;
    (void)generation;
    (void)version;
    return GK_ERR_INVALID;
}

CODE int32_t gk_v3_compat_pair_select_impl(const char *path_a,
                                           const char *path_b,
                                           uint32_t *generation,
                                           uint32_t *flags) {
    (void)path_a;
    (void)path_b;
    (void)generation;
    (void)flags;
    return GK_ERR_INVALID;
}
#endif

CODE int32_t gk_v3_work_load_impl(void) {
    int32_t status;
    state_initialize();
    __gk_persistence_work_slot = PERSIST_SLOT_NONE;
    __gk_persistence_stored_slot = PERSIST_SLOT_NONE;
    __gk_persistence_flags &= (uint8_t)~PERSIST_KNOWN_FLAGS;
    __gk_persistence_reserved = 0U;
    status = select_kind(V3_KIND_WORK, true);
    if (status < 0) {
        invalidate_compatibility_state(V3_KIND_WORK, status);
        return status;
    }
    bytes_clear(__gk_v3_work_dirty_bitmap, KIT_COUNT / 8U);
    bytes_clear(__gk_v3_assignment_dependency_bitmap, KIT_COUNT / 8U);
    __gk_v3_state_header.flags &=
        ~(V3_STATE_WORK_OVERLAY_DIRTY | V3_STATE_WORK_FULL_DIRTY |
          V3_STATE_WORK_OVERLAY_UNKNOWN);
    __gk_runtime_flags &= (uint8_t)~RUNTIME_STORAGE_DIRTY;
    return GK_OK;
}

CODE int32_t gk_v3_stored_assignments_load_impl(void) {
    int32_t status;
    if ((__gk_persistence_flags & PERSIST_STORED_PENDING) != 0U) {
        return GK_ERR_BUSY;
    }
    status = select_kind(V3_KIND_STORED, false);
    if (status < 0) {
        invalidate_compatibility_state(V3_KIND_STORED, status);
    }
    return status;
}

CODE int32_t gk_v3_library_clear_impl(void) {
    uint32_t kit;
    int32_t status;
    bytes_clear(__gk_pattern_assignments, PATTERN_COUNT);
    bytes_clear(__gk_pattern_assignment_valid, PATTERN_COUNT / 8U);
    bytes_clear(__gk_initialized_bitmap, KIT_COUNT / 8U);
    bytes_clear(__gk_kit_names, KIT_COUNT * KIT_NAME_SIZE);
    bytes_clear(__gk_canonical_payloads, PART_PAYLOAD_SIZE);
    status = gk_v3_stock_part_payload_initialize(__gk_canonical_payloads);
    if (status < 0) {
        return GK_ERR_CORRUPT;
    }
    bytes_copy(__gk_default_payload, __gk_canonical_payloads,
               PART_PAYLOAD_SIZE);
    for (kit = 1; kit != KIT_COUNT; ++kit) {
        bytes_copy(__gk_canonical_payloads + kit * PART_PAYLOAD_SIZE,
                   __gk_default_payload, PART_PAYLOAD_SIZE);
    }
    if (kind_ready(V3_KIND_WORK)) {
        bytes_fill(__gk_v3_work_dirty_bitmap, 0xFFU, KIT_COUNT / 8U);
        __gk_v3_state_header.flags |= V3_STATE_WORK_OVERLAY_DIRTY |
                                      V3_STATE_WORK_FULL_DIRTY;
    }
    __gk_runtime_flags |= RUNTIME_STORAGE_DIRTY;
    return GK_OK;
}

#ifdef GK_BUILD_EMPTY_PATTERN_ASSIGNMENT_LIFECYCLE_FIX
/* Byte-exact semantic clone of stock 1.40C's Pattern-presence predicate at
 * 0x4009a464, generalized to a caller-supplied resident bank image.  Stock
 * checks 14 audio longwords (offsets 0x00..0x0f and 0x18..0x37) plus four
 * MIDI longwords (offsets 0x00..0x0f) for each of eight tracks.  The default
 * and bookkeeping planes between those ranges are deliberately ignored. */
static CODE bool stock_resident_pattern_has_content(const uint8_t *bank,
                                                     uint32_t pattern) {
    const uint8_t *audio = bank + pattern * STOCK_PATTERN_STRIDE;
    const uint8_t *midi = audio + 0x48D0U;
    uint32_t track;
    for (track = 0; track != 8U; ++track) {
        if (!bytes_zero(audio, 0x10U) ||
            !bytes_zero(audio + 0x18U, 0x20U) ||
            !bytes_zero(midi, 0x10U)) {
            return true;
        }
        audio += 0x91AU;
        midi += 0x8B0U;
    }
    return false;
}
#endif

CODE int32_t gk_v3_migrate_resident_bank_impl(const uint8_t *bank,
                                              uint32_t bank_number) {
    uint32_t base_kit;
    uint32_t pattern;
    uint32_t part;
    if (bank == NULL || bank_number >= 16U) {
        return GK_ERR_RANGE;
    }
    base_kit = bank_number * 4U;
    for (pattern = 0; pattern != 16U; ++pattern) {
        uint32_t physical =
            bank[STOCK_PATTERN_PART_OFFSET + pattern * STOCK_PATTERN_STRIDE];
        uint32_t project_pattern = bank_number * 16U + pattern;
        if (physical >= 4U) {
            return GK_ERR_CORRUPT;
        }
        __gk_pattern_assignments[project_pattern] =
            (uint8_t)(base_kit + physical);
#ifdef GK_BUILD_EMPTY_PATTERN_ASSIGNMENT_LIFECYCLE_FIX
        if (stock_resident_pattern_has_content(bank, pattern)) {
            bitmap_set(__gk_pattern_assignment_valid, project_pattern);
        } else {
            bitmap_clear(__gk_pattern_assignment_valid, project_pattern);
        }
#else
        bitmap_set(__gk_pattern_assignment_valid, project_pattern);
#endif
    }
    for (part = 0; part != 4U; ++part) {
        uint32_t kit = base_kit + part;
        bytes_copy(__gk_canonical_payloads + kit * PART_PAYLOAD_SIZE,
                   bank + STOCK_BANK_WORKING_OFFSET + part * PART_PAYLOAD_SIZE,
                   PART_PAYLOAD_SIZE);
        bytes_copy(__gk_kit_names + kit * KIT_NAME_SIZE,
                   bank + STOCK_BANK_NAMES_OFFSET + part * 7U, 7U);
        __gk_kit_names[kit * KIT_NAME_SIZE + 7U] = 0U;
        bitmap_set(__gk_initialized_bitmap, kit);
    }
    return GK_OK;
}

CODE int32_t gk_v3_migrate_resident_work_impl(void) {
    uint32_t bank;
    int32_t status = gk_v3_library_clear_impl();
    if (status < 0) {
        return status;
    }
    for (bank = 0; bank != 16U; ++bank) {
        status = gk_v3_migrate_resident_bank_impl(
            (const uint8_t *)(uintptr_t)(STOCK_RESIDENT_BANK_BASE +
                                         bank * STOCK_BANK_STRIDE),
            bank
        );
        if (status < 0) {
            (void)gk_v3_library_clear_impl();
            return status;
        }
    }
    return GK_OK;
}

CODE int32_t gk_v3_new_project_initialize_impl(void) {
    return gk_v3_library_clear_impl();
}

static CODE int32_t stock_stored_bank_path(char *path, uint32_t bank) {
    uint32_t length = 0;
    uint32_t number;
    int32_t status;
    if (bank >= 16U) {
        return GK_ERR_RANGE;
    }
    status = gk_v3_project_path_build_impl(path, stock_bank_suffix);
    if (status < 0) {
        return status;
    }
    while (length != PROJECT_PATH_SIZE && path[length] != 0) {
        ++length;
    }
    if (length < 7U || length == PROJECT_PATH_SIZE) {
        return GK_ERR_RANGE;
    }
    number = bank + 1U;
    path[length - 7U] = number >= 10U ? '1' : '0';
    if (number >= 10U) {
        number -= 10U;
    }
    path[length - 6U] = (char)('0' + number);
    return GK_OK;
}

CODE int32_t gk_v3_stock_stored_bank_load_impl(uint8_t *scratch,
                                               uint32_t bank) {
    char path[PROJECT_PATH_SIZE];
    FileObject object;
    int32_t status;
    int32_t deserialize_status;
    if (scratch == NULL || bank >= 16U) {
        return GK_ERR_RANGE;
    }
    status = stock_stored_bank_path(path, bank);
    if (status < 0) {
        return status;
    }
    status = open_path(&object, path, mode_read, __gk_io_buffer);
    if (status < 0) {
        return status;
    }
    if (file_size(&object) != STOCK_BANK_SIZE) {
        return close_preserve(&object, GK_ERR_CORRUPT);
    }
    deserialize_status = gk_v3_stock_bank_deserialize(&object, scratch, 0U);
    if (deserialize_status != 1) {
        if (deserialize_status == -0x1d || deserialize_status == -0x33 ||
            deserialize_status == -0x34 || deserialize_status == -0x36) {
            status = GK_ERR_CORRUPT;
        } else {
            status = GK_ERR_IO;
        }
        return close_preserve(&object, status);
    }
    return close_preserve(&object, GK_OK);
}

CODE int32_t gk_v3_migrate_stored_library_impl(void) {
    uint32_t bank;
    uint8_t *scratch = __gk_spill_payloads;
    int32_t status = gk_v3_library_clear_impl();
    if (status < 0) {
        return status;
    }
    for (bank = 0; bank != 16U; ++bank) {
        const uint8_t *source = scratch;
        status = gk_v3_stock_stored_bank_load_impl(scratch, bank);
        if (status == GK_ERR_NOT_FOUND || status == GK_ERR_CORRUPT) {
            source = (const uint8_t *)(uintptr_t)(
                STOCK_RESIDENT_BANK_BASE + bank * STOCK_BANK_STRIDE
            );
        } else if (status < 0) {
            (void)gk_v3_library_clear_impl();
            return status;
        }
        status = gk_v3_migrate_resident_bank_impl(source, bank);
        if (status < 0) {
            (void)gk_v3_library_clear_impl();
            return status;
        }
    }
    return GK_OK;
}

CODE int32_t gk_v3_stored_commit_locked_impl(void) {
    if (__gk_persistence_snapshot_gate != PERSIST_SNAPSHOT_ACTIVE) {
        return GK_ERR_CORRUPT;
    }
    if (!kind_ready(V3_KIND_STORED)) {
        return create_pair_from_canonical(V3_KIND_STORED, 0U);
    }
    return replace_kind_from_source(
        V3_KIND_STORED, -1, __gk_pattern_assignments,
        __gk_pattern_assignment_valid, 0U
    );
}

CODE int32_t gk_v3_stored_commit_impl(void) {
    int32_t status = gk_persistence_snapshot_begin();
    int32_t result;
    if (status < 0) {
        return status;
    }
    result = gk_v3_stored_commit_locked_impl();
    status = gk_persistence_snapshot_end();
    return result < 0 ? result : status;
}

CODE int32_t gk_v3_project_store_locked_impl(void) {
    int32_t status;
    if (__gk_persistence_snapshot_gate != PERSIST_SNAPSHOT_ACTIVE) {
        return GK_ERR_CORRUPT;
    }
    if (!kind_ready(V3_KIND_WORK)) {
        status = select_kind(V3_KIND_WORK, true);
        if (status < 0) {
            return status;
        }
    }
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    if (!bitmap_empty(__gk_v3_work_dirty_bitmap) ||
        !bitmap_empty(__gk_v3_assignment_dependency_bitmap) ||
        (__gk_v3_state_header.flags & V3_STATE_WORK_OVERLAY_DIRTY) != 0U ||
        (__gk_runtime_flags & RUNTIME_STORAGE_DIRTY) != 0U) {
        return GK_ERR_BUSY;
    }
#endif
    if (!kind_ready(V3_KIND_STORED)) {
        status = select_kind(V3_KIND_STORED, false);
        if (status < 0 && status != GK_ERR_INVALID &&
            status != GK_ERR_CORRUPT) {
            return status;
        }
    }
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = replace_kind_from_source(
        V3_KIND_STORED, -1, __gk_pattern_assignments,
        __gk_pattern_assignment_valid, 0U
    );
#else
    status = replace_kind_from_source(
        V3_KIND_STORED, V3_KIND_WORK, kind_assignments(V3_KIND_WORK),
        kind_assignment_valid(V3_KIND_WORK), 0U
    );
#endif
    if (status < 0) {
        return status;
    }
    if ((kind_flags(V3_KIND_WORK) & V3_FLAG_STORED_PENDING) != 0U) {
        status = overlay_commit(V3_KIND_WORK,
                                kind_assignments(V3_KIND_WORK),
                                kind_assignment_valid(V3_KIND_WORK), 0U);
        if (status < 0) {
            return status;
        }
    }
    __gk_persistence_flags &= (uint8_t)~PERSIST_STORED_PENDING;
    __gk_persistence_last_error = GK_OK;
    return GK_OK;
}

CODE int32_t gk_v3_project_store_impl(void) {
    int32_t status = gk_persistence_snapshot_begin();
    int32_t result;
    if (status < 0) {
        return status;
    }
    result = gk_v3_project_store_locked_impl();
    status = gk_persistence_snapshot_end();
    if (result < 0) {
        __gk_persistence_last_error = result;
        return result;
    }
    return status;
}

CODE int32_t gk_v3_stored_pending_repair_impl(void) {
    if ((__gk_persistence_flags & (uint8_t)~PERSIST_KNOWN_FLAGS) != 0U) {
        return GK_ERR_CORRUPT;
    }
    return (__gk_persistence_flags & PERSIST_STORED_PENDING) != 0U
               ? gk_v3_project_store_impl()
               : GK_OK;
}

CODE int32_t gk_v3_project_reload_impl(void) {
    int32_t status;
    if ((__gk_persistence_flags & PERSIST_STORED_PENDING) != 0U ||
        __gk_persistence_reserved != 0U) {
        return GK_ERR_BUSY;
    }
    status = select_kind(V3_KIND_STORED, false);
    if (status < 0) {
        return status;
    }
    if (!kind_ready(V3_KIND_WORK)) {
        status = select_kind(V3_KIND_WORK, false);
        if (status < 0 && status != GK_ERR_INVALID &&
            status != GK_ERR_CORRUPT) {
            return status;
        }
    }
    status = replace_kind_from_source(
        V3_KIND_WORK, V3_KIND_STORED, kind_assignments(V3_KIND_STORED),
        kind_assignment_valid(V3_KIND_STORED), 0U
    );
    if (status < 0) {
        __gk_persistence_last_error = status;
        return status;
    }
    __gk_persistence_reserved = PERSIST_RELOAD_PROJECT;
    return GK_OK;
}

CODE int32_t gk_v3_bank_store_impl(uint32_t bank_mask) {
    uint32_t bank;
    uint8_t *stored_assignments = assignment_buffer();
    uint8_t *stored_valid = stored_assignments + PATTERN_COUNT;
    int32_t status;
    if (bank_mask == 0U || bank_mask > 0xFFFFU) {
        return GK_ERR_RANGE;
    }
    if ((__gk_persistence_flags & PERSIST_STORED_PENDING) != 0U) {
        return GK_ERR_BUSY;
    }
    status = select_kind(V3_KIND_STORED, false);
    if (status < 0) {
        return status;
    }
    status = gk_persistence_snapshot_begin();
    if (status < 0) {
        return status;
    }
    for (bank = 0; bank != 16U; ++bank) {
        if ((bank_mask & (1U << bank)) != 0U) {
            bytes_copy(stored_assignments + bank * 16U,
                       __gk_pattern_assignments + bank * 16U, 16U);
            bytes_copy(stored_valid + bank * 2U,
                       __gk_pattern_assignment_valid + bank * 2U, 2U);
        }
    }
    status = gk_persistence_snapshot_end();
    if (status < 0) {
        return status;
    }
    status = overlay_commit(V3_KIND_STORED, stored_assignments,
                            stored_valid, 0U);
    __gk_persistence_last_error = status;
    return status;
}

CODE int32_t gk_v3_bank_reload_impl(uint32_t bank_mask) {
    uint32_t bank;
    uint8_t *merged_assignments = assignment_buffer();
    uint8_t *merged_valid = merged_assignments + PATTERN_COUNT;
    int32_t status;
    if (bank_mask == 0U || bank_mask > 0xFFFFU) {
        return GK_ERR_RANGE;
    }
    if (__gk_persistence_reserved != 0U) {
        return GK_ERR_BUSY;
    }
    status = select_kind(V3_KIND_STORED, false);
    if (status < 0) {
        return status;
    }
    status = gk_persistence_snapshot_begin();
    if (status < 0) {
        return status;
    }
    for (bank = 0; bank != 16U; ++bank) {
        if ((bank_mask & (1U << bank)) == 0U) {
            bytes_copy(merged_assignments + bank * 16U,
                       __gk_pattern_assignments + bank * 16U, 16U);
            bytes_copy(merged_valid + bank * 2U,
                       __gk_pattern_assignment_valid + bank * 2U, 2U);
        }
    }
    status = gk_persistence_snapshot_end();
    if (status < 0) {
        return status;
    }
    status = overlay_commit(V3_KIND_WORK, merged_assignments, merged_valid,
                            kind_flags(V3_KIND_WORK));
    if (status < 0) {
        __gk_persistence_last_error = status;
        return status;
    }
    __gk_persistence_reserved = PERSIST_RELOAD_BANK;
    return GK_OK;
}

static CODE int32_t finish_install_restore_work(void) {
    int32_t status = select_kind(V3_KIND_WORK, true);
    if (status < 0) {
        return status;
    }
    bytes_clear(__gk_v3_work_dirty_bitmap, KIT_COUNT / 8U);
    bytes_clear(__gk_v3_assignment_dependency_bitmap, KIT_COUNT / 8U);
    __gk_v3_state_header.flags &=
        ~(V3_STATE_WORK_OVERLAY_DIRTY | V3_STATE_WORK_FULL_DIRTY |
          V3_STATE_WORK_OVERLAY_UNKNOWN);
    __gk_runtime_flags &= (uint8_t)~RUNTIME_STORAGE_DIRTY;
    __gk_persistence_reserved = 0U;
    __gk_persistence_last_error = GK_OK;
    return GK_OK;
}

CODE int32_t gk_v3_first_install_migrate_impl(void) {
#ifndef GK_V3_PROJECT_IO_OPTIMIZED
    uint32_t generation;
    uint32_t version;
    uint8_t flags;
#endif
    int32_t status;
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = gk_v3_migrate_resident_work_impl();
    if (status >= 0) {
        status = create_pair_from_canonical(V3_KIND_WORK, 0U);
    }
#else
    status = legacy_kind_select(V3_KIND_WORK, 1, &generation, &version,
                                &flags);
    if (status == GK_OK) {
        status = create_pair_from_canonical(V3_KIND_WORK, flags);
    } else if (status == GK_ERR_IO) {
        return status;
    } else {
        status = gk_v3_migrate_resident_work_impl();
        if (status >= 0) {
            status = create_pair_from_canonical(V3_KIND_WORK, 0U);
        }
    }
#endif
    if (status < 0) {
        return status;
    }

#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = probe_kind_root(V3_KIND_STORED);
    if (status != GK_OK) {
        if (status == GK_ERR_IO) {
            return status;
        }
        status = gk_v3_migrate_stored_library_impl();
        if (status >= 0) {
            status = create_pair_from_canonical(V3_KIND_STORED, 0U);
        }
    }
#else
    status = select_kind(V3_KIND_STORED, false);
    if (status != GK_OK) {
        if (status == GK_ERR_IO) {
            return status;
        }
        status = legacy_kind_select(V3_KIND_STORED, 1, &generation, &version,
                                    &flags);
        if (status == GK_OK) {
            status = create_pair_from_canonical(V3_KIND_STORED, 0U);
        } else if (status == GK_ERR_IO) {
            return status;
        } else {
            status = gk_v3_migrate_stored_library_impl();
            if (status >= 0) {
                status = create_pair_from_canonical(V3_KIND_STORED, 0U);
            }
        }
    }
#endif
    if (status < 0) {
        return status;
    }
    return finish_install_restore_work();
}

CODE int32_t gk_v3_work_load_or_migrate_impl(void) {
#ifndef GK_V3_PROJECT_IO_OPTIMIZED
    uint32_t generation;
    uint32_t version;
    uint8_t flags;
#endif
    int32_t restore_status;
    int32_t status = gk_v3_work_load_impl();
    if (status == GK_ERR_IO) {
        return status;
    }
    if (status != GK_OK) {
        return gk_v3_first_install_migrate_impl();
    }

    /*
     * A reset between publishing the v3 work pair and converting the stored
     * pair must resume the stored migration.  Do not treat a valid work pair
     * as proof that the four-file conversion finished.
     */
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = probe_kind_root(V3_KIND_STORED);
#else
    status = select_kind(V3_KIND_STORED, false);
#endif
    if (status == GK_OK || status == GK_ERR_IO) {
        return status;
    }
#ifdef GK_V3_PROJECT_IO_OPTIMIZED
    status = gk_v3_migrate_stored_library_impl();
    if (status >= 0) {
        status = create_pair_from_canonical(V3_KIND_STORED, 0U);
    }
#else
    status = legacy_kind_select(V3_KIND_STORED, 1, &generation, &version,
                                &flags);
    if (status == GK_OK) {
        status = create_pair_from_canonical(V3_KIND_STORED, 0U);
    } else if (status != GK_ERR_IO) {
        status = gk_v3_migrate_stored_library_impl();
        if (status >= 0) {
            status = create_pair_from_canonical(V3_KIND_STORED, 0U);
        }
    }
#endif
    if (status < 0) {
        restore_status = finish_install_restore_work();
        return restore_status < 0 ? restore_status : status;
    }
    return finish_install_restore_work();
}

CODE int32_t gk_v3_destination_reset_impl(void) {
    state_initialize();
    __gk_persistence_work_slot = PERSIST_SLOT_NONE;
    __gk_persistence_stored_slot = PERSIST_SLOT_NONE;
    __gk_persistence_work_generation = 0U;
    __gk_persistence_stored_generation = 0U;
    __gk_persistence_flags = PERSIST_STORED_PENDING;
    __gk_persistence_reserved = 0U;
    __gk_persistence_last_error = GK_OK;
    __gk_runtime_flags |= RUNTIME_STORAGE_DIRTY;
    return GK_OK;
}

CODE int32_t gk_v3_destination_create_impl(void) {
    int32_t status = gk_persistence_snapshot_begin();
    int32_t result;
    if (status < 0) {
        return status;
    }
    result = gk_v3_destination_reset_impl();
    if (result >= 0) {
        result = create_pair_from_canonical(V3_KIND_WORK,
                                            V3_FLAG_STORED_PENDING);
    }
    if (result >= 0) {
        result = create_pair_from_canonical(V3_KIND_STORED, 0U);
    }
    if (result >= 0) {
        result = overlay_commit(V3_KIND_WORK,
                                __gk_pattern_assignments,
                                __gk_pattern_assignment_valid, 0U);
    }
    if (result >= 0) {
        bytes_clear(__gk_v3_work_dirty_bitmap, KIT_COUNT / 8U);
        bytes_clear(__gk_v3_assignment_dependency_bitmap, KIT_COUNT / 8U);
        __gk_v3_state_header.flags &=
            ~(V3_STATE_WORK_OVERLAY_DIRTY | V3_STATE_WORK_FULL_DIRTY |
              V3_STATE_WORK_OVERLAY_UNKNOWN);
        __gk_runtime_flags &= (uint8_t)~RUNTIME_STORAGE_DIRTY;
        __gk_persistence_flags &= (uint8_t)~PERSIST_STORED_PENDING;
        __gk_persistence_last_error = GK_OK;
    } else {
        __gk_persistence_last_error = result;
    }
    status = gk_persistence_snapshot_end();
    return result < 0 ? result : status;
}

CODE int32_t gk_v3_new_project_create_impl(void) {
    int32_t status = gk_v3_new_project_initialize_impl();
    return status < 0 ? status : gk_v3_destination_create_impl();
}
