+++
title = "Monumentum: Membangun Database Engine di Rust dari Nol"
date = 2026-10-03
description = "Cerita lengkap di balik Monumentum: page, pager, buffer pool, B-tree, WAL, catalog, recovery, dan keputusan desainnya. Kenapa dan bagaimana semua bekerja."
[taxonomies]
tags = ["rust", "database", "systems", "storage-engine", "monumentum", "llm"]
+++

# Monumentum: Membangun Database Engine di Rust dari Nol

Oke, jadi aku lagi bikin **database engine** sendiri. Dari nol. Pakai **Rust**. Namanya **Monumentum**.

Ini bukan database yang punya SQL parser segala macam — itu level aplikasi. Ini level **storage engine**: yang ngurusin gimana data disimpan di disk, gimana dibaca, gimana di-recover kalau crash, dan seterusnya.

Workspace-nya terbagi jadi beberapa crate:

- **`monumentum_handler`** — kontrak, tipe dasar, schema, value, trait, error.
- **`monumentum_core`** — implementasi storage engine: pager, buffer pool, B-tree, WAL, catalog, table storage.
- **`monumentum_dsl`** — query builder Rust-native, opsional, buat yang pengin nulis query tanpa SQL string.

Fokus cerita ini adalah `monumentum_handler` dan `monumentum_core`, karena di situlah jantungnya.

---

## Daftar Isi

- [1. Halaman (Page): Unit Terkecil Data](#1-halaman-page-unit-terkecil-data)
- [2. Pager: Jembatan ke Disk](#2-pager-jembatan-ke-disk)
- [3. Buffer Pool: Cache di Memori](#3-buffer-pool-cache-di-memori)
- [4. B-Tree On-Disk: Index yang Persisten](#4-b-tree-on-disk-index-yang-persisten)
- [5. WAL: Write-Ahead Log](#5-wal-write-ahead-log)
- [6. Catalog: Metadata Tabel](#6-catalog-metadata-tabel)
- [7. Table Storage: Menyimpan Baris](#7-table-storage-menyimpan-baris)
- [8. Serde: Encode/Decode Data](#8-serde-encode-decode-data)
- [9. Recovery dan Checkpoint](#9-recovery-dan-checkpoint)
- [10. Tipe Data dan Schema](#10-tipe-data-dan-schema)
- [11. Error Handling: Nggak Ada Panic](#11-error-handling-nggak-ada-panic)
- [12. Trait-Trait Utama](#12-trait-trait-utama)
- [13. Konstanta Penting](#13-konstanta-penting)
- [14. Testing: Serius Banget](#14-testing-serius-banget)
- [15. Keputusan Desain yang Menarik](#15-keputusan-desain-yang-menarik)
- [16. Roadmap](#16-roadmap)
- [17. Contoh Penggunaan](#17-contoh-penggunaan)
- [18. Pelajaran yang Aku Dapat](#18-pelajaran-yang-aku-dapat)
- [Penutup](#penutup)

---

## 1. Halaman (Page): Unit Terkecil Data

Di database, data nggak disimpan per baris. Tapi disimpan per **halaman** (page). Halaman itu blok memori ukuran fixed — di Monumentum **4096 byte**.

```rust
pub const PAGE_SIZE: usize = 4096;
pub const PAGE_HEADER_SIZE: usize = 16;
pub const PAGE_BODY_SIZE: usize = PAGE_SIZE - PAGE_HEADER_SIZE;
```

Jadi tiap halaman punya:

- **header 16 byte** — metadata.
- **body 4080 byte** — isi data.

### Header halaman isinya apa?

```rust
pub struct PageHeader {
    pub page_id: u32,           // ID halaman
    pub page_type: PageType,    // tipe halaman
    pub free_space_offset: u16, // offset ruang bebas
    pub cell_count: u16,        // jumlah cell
    pub checksum: u32,          // CRC32 buat deteksi korupsi
    pub flags: u32,             // flag
}
```

Kenapa 16 byte? Biar rapi. 4 + 1 + 2 + 2 + 4 + 3 = 16. Pas.

### Tipe halaman

```rust
pub enum PageType {
    Meta = 0,        // halaman metadata (halaman 0)
    Freelist = 1,    // halaman yang udah di-free
    TableMeta = 2,   // metadata tabel
    Data = 3,        // data baris
    Index = 4,       // index B-tree
    Overflow = 5,    // kalau data kegedean
}
```

Setiap halaman punya tipe. Kenapa? Karena tiap tipe punya struktur internal yang beda.

### Checksum: Deteksi Korupsi

Ini salah satu keputusan desain paling penting. Setiap halaman punya **checksum CRC32** yang dihitung dari header + body.

```rust
pub fn compute_checksum(&self) -> u32 {
    let mut header = self.header;
    header.checksum = 0;  // nol-in dulu
    let header_bytes = header.to_bytes();
    let mut crc = 0xFFFF_FFFFu32;
    for &byte in header_bytes.iter().chain(self.data.iter()) {
        crc ^= u32::from(byte);
        for _ in 0..8 {
            let mask = (crc & 1).wrapping_neg();
            crc = (crc >> 1) ^ (0xEDB8_8320 & mask);
        }
    }
    !crc
}
```

**Kenapa penting?** Karena kalau ada bit yang korup di disk — bisa karena disk rusak, cosmic ray, atau apa pun — kita bisa deteksi. Bukan diam-diam ngasih data salah ke user.

Waktu baca halaman, checksum diverifikasi:

```rust
let expected = page.header.checksum;
let actual = page.compute_checksum();
if expected != actual {
    return Err(DbError::corruption(...));
}
```

Kalau mismatch? Error. Bukan panic, bukan silent corruption. **Error yang bisa di-handle.**

---

## 2. Pager: Jembatan ke Disk

**Pager** itu komponen yang ngurusin I/O ke file. Dia yang tahu halaman berapa ada di offset berapa.

```rust
pub struct Pager {
    file: File,
    page_count: u32,
}
```

Simple banget. Cuma file handle + jumlah halaman.

### Cara hitung offset

```rust
let offset = u64::from(page_id) * PAGE_SIZE as u64;
```

Mudah. Halaman ke-5? Offset-nya `5 * 4096 = 20480`.

### Operasi utama

- **`read_page`** — baca halaman dari disk, verify checksum.
- **`write_page`** — tulis halaman ke disk, sync, biar bener-bener sampai disk.
- **`allocate_page`** — tambah halaman baru. Cuma extend file dan increment counter.
- **`free_page`** — tandai halaman sebagai freelist. Bukan dihapus.

### File Locking

Ini detail yang sering dilupain. Waktu buka file, Monumentum **mengunci file** pakai `flock` (lewat crate `fs2`):

```rust
file.try_lock_exclusive().map_err(DbError::from_io)?;
```

Artinya: cuma **satu proses** yang bisa buka database. Kalau ada proses lain nyoba buka? Langsung error.

Ini mencegah **konkurensi yang berbahaya**. Dua proses nulis di file yang sama = resep bencana.

### Deteksi File Size yang Nggak Valid

Kalau file size bukan kelipatan 4096? Itu tandanya file rusak atau bukan database Monumentum:

```rust
if remainder != 0 {
    return Err(DbError::corruption(...));
}
```

---

## 3. Buffer Pool: Cache di Memori

Baca dari disk itu **mahal**. Jadi kita cache halaman yang sering dipakai di memori. Itu tugas **BufferPool**.

```rust
pub struct BufferPool {
    pager: Pager,
    capacity: usize,                      // maksimal halaman di cache
    entries: HashMap<u32, PageEntry>,     // map page_id -> entry
    clock: u64,                           // counter buat LRU
}
```

### Struktur Entry

```rust
struct PageEntry {
    page: Page,
    dirty: bool,       // udah diubah belum?
    pin_count: u32,    // berapa yang lagi pake
    last_used: u64,    // kapan terakhir diakses (buat LRU)
}
```

### Konsep "Pin"

**Pin** itu kayak "aku lagi pake halaman ini, jangan di-evict dulu". Setiap kali `get_page`, `pin_count` naik. Setiap `unpin_page`, turun.

Kenapa penting? Karena kalau halaman di-evict sementara ada yang lagi pegang referensi ke situ = **use-after-free**.

```rust
pub fn unpin_page(&mut self, page_id: u32, dirty: bool) -> Result<(), DbError> {
    // ...
    entry.pin_count = entry.pin_count.checked_sub(1)
        .ok_or_else(|| DbError::invalid_operation("cannot unpin a page with zero pin count"))?;
    // ...
}
```

Kalau unpin yang `pin_count`-nya udah 0? Error. **Bukan** diam-diam jadi underflow.

### Eviction: LRU Sederhana

Kalau cache penuh dan mau masuk halaman baru, harus evict salah satu. Monumentum pilih halaman dengan `last_used` terkecil (LRU — Least Recently Used):

```rust
pub fn evict_one(&mut self) -> Result<(), DbError> {
    let mut candidate: Option<(u32, u64)> = None;
    for (&page_id, entry) in &self.entries {
        if entry.pin_count == 0 {  // cuma yang nggak di-pin
            if let Some((_, min_used)) = candidate {
                if entry.last_used < min_used {
                    candidate = Some((page_id, entry.last_used));
                }
            } else {
                candidate = Some((page_id, entry.last_used));
            }
        }
    }

    let page_id = candidate.map(|(id, _)| id)
        .ok_or_else(|| DbError::invalid_operation("no unpinned page to evict"))?;

    // kalau dirty, flush dulu
    if self.entries.get(&page_id).unwrap().dirty {
        self.flush_page(page_id)?;
    }

    self.entries.remove(&page_id);
    Ok(())
}
```

Perhatiin: **halaman yang lagi di-pin nggak boleh di-evict**. Kalau semua halaman di-pin, error. Ini bikin bug keliatan langsung, bukan bikin silent corruption.

### Dirty Flag

Kalau halaman diubah, kita set `dirty = true`. Waktu evict atau flush, baru ditulis ke disk. Ini **write-back cache** — hemat I/O.

```rust
pub fn mark_dirty(&mut self, page_id: u32) -> Result<(), DbError> {
    // ...
    entry.dirty = true;
    // ...
}
```

---

## 4. B-Tree On-Disk: Index yang Persisten

Salah satu komponen paling ribet. Buat lookup cepat pakai primary key, kita butuh **index**. Monumentum pakai **B-Tree**.

Yang beda dari B-Tree biasa: ini **on-disk**. Tiap node disimpan di satu halaman.

```rust
pub struct BTreeOnDisk {
    root_page_id: u32,
}
```

Cuma tahu root-nya di halaman berapa.

### Struktur Node

```rust
struct Node {
    page_id: u32,
    is_leaf: bool,
    parent_page_id: u32,
    keys: Vec<IndexKey>,
    values: Vec<u64>,      // cuma leaf
    children: Vec<u32>,    // cuma internal node
}
```

### Format on-disk

Setiap node punya header 7 byte:

```
[0]      : is_leaf (1 byte)
[1..3]   : num_keys (2 byte LE)
[3..7]   : parent_page_id (4 byte LE)
```

Terus diikuti key-value pairs:

```
[key_len u16][key_bytes][value u64]  (leaf)
[key_len u16][key_bytes][child u32]  (internal)
```

Dan child terakhir disimpan terpisah (karena internal node punya `n+1` child untuk `n` key).

### Operasi Insert

Ini yang paling ribet. B-Tree insert harus handle **split** kalau node penuh.

`MAX_KEYS_PER_NODE = 100` — kalau udah 100 key, split jadi 2.

```rust
pub fn insert_static(
    buffer_pool: &mut BufferPool,
    root_page_id: &mut u32,
    key: IndexKey,
    value: u64,
) -> Result<(), DbError> {
    let root = Self::load_node(buffer_pool, *root_page_id)?;
    if root.keys.len() >= MAX_KEYS_PER_NODE {
        Self::split_root(buffer_pool, root_page_id)?;
    }
    Self::insert_non_full(buffer_pool, *root_page_id, key, value)
}
```

**Split root** — bikin root baru, anaknya adalah root lama, terus split anaknya:

```rust
fn split_root(buffer_pool: &mut BufferPool, root_page_id: &mut u32) -> Result<(), DbError> {
    let new_root_page_id = Self::allocate_node(buffer_pool, false)?;
    let old_root_page_id = *root_page_id;

    {
        let mut new_root = Self::load_node(buffer_pool, new_root_page_id)?;
        new_root.children.push(old_root_page_id);
        Self::save_node(buffer_pool, &new_root)?;
    }

    Self::split_child(buffer_pool, new_root_page_id, 0)?;
    *root_page_id = new_root_page_id;
    Ok(())
}
```

### IndexKey: Tipe Data untuk Key

Key bisa berbagai tipe. Jadi kita punya enum:

```rust
pub enum IndexKey {
    Integer(i64),
    Float(u64),      // disimpan sebagai bits biar total ordered
    Text(String),
    Blob(Vec<u8>),
    Boolean(bool),
}
```

**Kenapa Float disimpan sebagai bits?** Karena `f64` nggak bisa langsung dipakai buat ordering kalau ada `-0.0` vs `0.0` atau NaN. Dengan bits, kita bisa total order.

### Serialisasi Key

Tiap key punya tag byte di depan:

```
0 = Integer, diikuti 8 byte LE
1 = Float, diikuti 8 byte LE
2 = Text, diikuti len u32 + bytes
3 = Blob, diikuti len u32 + bytes
4 = Boolean, diikuti 1 byte
```

Jadi waktu deserialize, tinggal lihat tag-nya.

---

## 5. WAL: Write-Ahead Log

Ini yang bikin database **crash-safe**. Sebelum ngubah halaman di disk, kita catat dulu perubahannya di **log**. Kalau crash, log-nya dibaca ulang.

```rust
pub struct Wal {
    file: Option<File>,
}
```

### Record Format

Setiap record punya header 20 byte:

```
[0..4]   : MAGIC = 0x4D4F4E55 ("MONU")
[4..8]   : VERSION = 1
[8..16]  : length (u64 LE)
[16..20] : checksum CRC32
```

Terus diikuti payload.

### Tipe Record

```rust
pub enum WalRecordType {
    Snapshot = 0,         // snapshot full catalog
    PageWrite = 1,        // tulis halaman
    TableMetaUpdate = 2,  // update metadata tabel
}
```

Payload dari `PageWrite`:

```
[0..4] : page_id
[4..]  : page_bytes (4096 byte)
```

Payload dari `TableMetaUpdate`:

```
[table_name][next_row_id][index_root_page_id (Option<u32>)]
```

### Safety Limits

Nggak boleh unlimited. WAL punya batas:

```rust
const MAX_TOTAL_WAL_BYTES: usize = 256 * 1024 * 1024;   // 256 MB
const MAX_WAL_RECORDS: usize = 1_000_000;                // 1 juta record
```

Kalau lebih? **Error**. Bukan OOM.

### Truncate Setelah Checkpoint

Setelah checkpoint (semua dirty page di-flush), WAL di-truncate:

```rust
pub fn truncate(&mut self) -> Result<(), DbError> {
    let file = self.file.as_mut().ok_or_else(...)?;
    file.set_len(0)?;
    file.sync_all()?;
    file.seek(SeekFrom::Start(0))?;
    Ok(())
}
```

Jadi WAL nggak tumbuh selamanya.

### Baca WAL dengan Verifikasi

Waktu recovery, baca WAL record demi record. Kalau checksum mismatch? Error. Kalau file berhenti di tengah? Error (incomplete record).

```rust
pub fn read_records(file: &mut File) -> Result<Vec<Vec<u8>>, DbError> {
    // ...
    loop {
        let mut header_buf = [0_u8; HEADER_SIZE];
        let bytes_read = file.read(&mut header_buf[..])?;
        if bytes_read == 0 {
            return Ok(records);  // EOF = selesai
        }
        if bytes_read != HEADER_SIZE {
            return Err(DbError::corruption(...));  // partial header
        }

        let magic = u32::from_le_bytes(...);
        if magic != MAGIC {
            return Err(DbError::corruption(...));
        }
        // ...
    }
}
```

---

## 6. Catalog: Metadata Tabel

**Catalog** itu daftar semua tabel di database, plus schema-nya.

```rust
pub struct Catalog {
    tables: BTreeMap<String, Table>,
}
```

Pakai `BTreeMap` biar deterministic ordering — penting buat serialisasi.

### Operasi

- `create_table(schema)` — bikin tabel baru.
- `drop_table(name)` — hapus.
- `rename_table(old, new)` — ganti nama.
- `replace_table(name, table)` — replace (buat recovery).

Semua operasi **validasi dulu**. Contoh:

```rust
pub fn create_table(&mut self, schema: TableSchema) -> Result<(), DbError> {
    let name = schema.name().to_string();
    if name.is_empty() {
        return Err(DbError::invalid_operation("table name cannot be empty"));
    }
    if self.tables.contains_key(&name) {
        return Err(DbError::invalid_operation(format!(
            "table '{name}' already exists"
        )));
    }
    self.tables.insert(name, Table::new(schema));
    Ok(())
}
```

### Catalog Disimpan di Halaman

Catalog bisa gede. Jadi disimpan di **linked list halaman**:

```
[page 1: header 8 byte + chunk 1] -> next_page_id ->
[page 2: header 8 byte + chunk 2] -> next_page_id ->
...
```

Header chunk:

```
[0..4] : next_page_id (0 = terakhir)
[4..8] : used_len
```

Kalau catalog lebih gede dari satu halaman, otomatis nambah halaman.

---

## 7. Table Storage: Menyimpan Baris

Data baris disimpan di halaman **Data**, juga linked list:

```rust
pub struct TableStorage {
    first_data_page_id: u32,
}
```

### Format Halaman Data

```
[0..4] : next_page_id
[4..8] : used_len
[8..]  : rows (masing-masing: [len u32][encoded_row])
```

### Insert Row

Kalau row muat di halaman sekarang? Tulis. Kalau nggak? Lanjut ke halaman berikutnya. Kalau udah halaman terakhir? Bikin halaman baru.

```rust
pub fn insert_row_static(
    buffer_pool: &mut BufferPool,
    first_data_page_id: u32,
    row: &Row,
) -> Result<(), DbError> {
    let encoded = encode_row(row)?;
    let mut current_page_id = first_data_page_id;

    loop {
        let current_page = buffer_pool.get_page(current_page_id)?;
        let used_len = Self::get_used_len(current_page)?;
        let free_space = PAGE_BODY_SIZE - DATA_PAGE_HEADER_SIZE - used_len;

        if free_space >= encoded.len() {
            // tulis di sini
            // ...
            return Ok(());
        }

        let next_page_id = Self::get_next_page_id(current_page)?;
        buffer_pool.unpin_page(current_page_id, false)?;

        if next_page_id == 0 {
            // bikin halaman baru
            let new_page_id = buffer_pool.allocate_page(PageType::Data)?;
            // link dari halaman lama ke halaman baru
            // ...
        } else {
            current_page_id = next_page_id;
        }
    }
}
```

### Get Row by Index

Linear scan dari halaman pertama sampai halaman ke-N, terus hitung row ke-`idx`:

```rust
pub fn get_row_static(
    buffer_pool: &mut BufferPool,
    first_data_page_id: u32,
    row_idx: usize,
) -> Result<Option<Row>, DbError> {
    let mut current_page_id = first_data_page_id;
    let mut current_row_idx = 0_usize;

    loop {
        let page = buffer_pool.get_page(current_page_id)?;
        // iterasi row di halaman ini
        while offset < end {
            if current_row_idx == row_idx {
                // ketemu!
                return Ok(Some(row));
            }
            offset = row_end;
            current_row_idx += 1;
        }

        // lanjut ke halaman berikutnya
        let next = Self::get_next_page_id(page)?;
        if next == 0 {
            return Ok(None);
        }
        current_page_id = next;
    }
}
```

---

## 8. Serde: Encode/Decode Data

Semua data harus bisa di-serialize ke bytes dan di-deserialize balik. Monumentum punya modul **serde** sendiri.

### Trait

```rust
pub(crate) trait Encode {
    fn encode(&self, buf: &mut Vec<u8>) -> Result<(), DbError>;
}

pub(crate) trait Decode: Sized {
    fn decode(cursor: &mut Cursor<&[u8]>) -> Result<Self, DbError>;
}
```

### Tag System

Setiap `Value` punya tag byte:

```rust
const TAG_NULL: u8 = 0;
const TAG_INTEGER: u8 = 1;
const TAG_FLOAT: u8 = 2;
const TAG_TEXT: u8 = 3;
const TAG_BLOB: u8 = 4;
const TAG_BOOLEAN: u8 = 5;
```

### Format Row

Row disimpan sebagai:

```
[len u32][value_1][value_2]...[value_n]
```

Di mana tiap value punya tag-nya sendiri.

### Safety: Batas Ukuran

Waktu decode, ada batas:

```rust
const MAX_READ_BYTES: usize = 64 * 1024 * 1024;  // 64 MB
const MAX_VEC_ELEMENTS: usize = 1_000_000;
```

Kalau data yang di-decode ngeklaim lebih dari itu? **Error**. Ini mencegah serangan "decompression bomb" atau data corrupt yang bikin OOM.

```rust
if len > MAX_READ_BYTES {
    return Err(DbError::corruption(...));
}
```

Juga ada check: **jangan baca lebih banyak dari yang ada di buffer**.

```rust
let remaining = cursor.get_ref().len() - cursor.position() as usize;
if len > remaining {
    return Err(DbError::corruption(...));
}
```

---

## 9. Recovery dan Checkpoint

Ini yang paling keren. Kalau proses mati tiba-tiba, data harus bisa di-recover.

### Cara Kerja Recovery

1. Buka pager + WAL.
2. Baca meta page (halaman 0) — dapet `last_checkpoint_lsn`.
3. Baca catalog dari disk (halaman catalog).
4. **Apply WAL records** yang LSN-nya > last checkpoint.
5. Checkpoint (flush semua ke disk, truncate WAL).

```rust
fn apply_wal_records(&mut self) -> Result<(), DbError> {
    let wal_records = self.wal.read_wal_records()?;
    for record in wal_records {
        if record.lsn <= self.last_checkpoint_lsn {
            continue;  // udah ada di disk
        }
        match record.record_type {
            WalRecordType::PageWrite => self.apply_page_write(&record)?,
            WalRecordType::Snapshot => {
                let (lsn, catalog) = decode_snapshot(&record.data)?;
                self.catalog = catalog;
                self.current_lsn = lsn;
            }
            WalRecordType::TableMetaUpdate => {
                let (name, next_row_id, index_root) =
                    Self::decode_table_meta_update(&record.data)?;
                // update metadata tabel
            }
        }
    }
    Ok(())
}
```

### Idempotent

WAL record cuma di-apply kalau LSN-nya > last checkpoint. Jadi kalau crash berkali-kali, recovery tetep konsisten. **Idempotent**.

### Checkpoint

Checkpoint = "simpen semua perubahan ke disk, biar WAL bisa dipotong".

```rust
pub fn checkpoint(&mut self) -> Result<(), DbError> {
    // 1. Tulis catalog ke halaman
    let catalog = self.catalog.clone();
    self.write_catalog_to_pages(&catalog)?;

    // 2. Flush semua halaman dirty
    self.buffer_pool.flush_all()?;
    self.buffer_pool.flush_all()?;  // sengaja dua kali

    // 3. Update meta page
    {
        let meta_page = self.buffer_pool.get_page(META_PAGE_ID)?;
        meta_page.data[META_LSN_OFFSET..META_LSN_OFFSET + 8]
            .copy_from_slice(&self.current_lsn.to_le_bytes());
        // ... update catalog_page_id, last_checkpoint_lsn
    }
    self.buffer_pool.unpin_page(META_PAGE_ID, true)?;
    self.buffer_pool.flush_page(META_PAGE_ID)?;
    self.buffer_pool.flush_all()?;

    // 4. Truncate WAL
    self.wal.truncate()?;
    self.last_checkpoint_lsn = self.current_lsn;
    Ok(())
}
```

**Kenapa `flush_all` dua kali?** Karena `flush_all` cuma flush halaman yang ada di buffer pool. Tapi `write_catalog_to_pages` bisa bikin halaman baru. Jadi flush kedua buat mastiin halaman baru itu juga ke disk.

---

## 10. Tipe Data dan Schema

### Integer — wrapper i64

```rust
pub struct Integer(i64);
```

Punya operasi checked (nggak akan overflow diam-diam):

```rust
pub const fn checked_add(self, rhs: Self) -> Option<Self> {
    match self.0.checked_add(rhs.0) {
        Some(v) => Some(Self(v)),
        None => None,
    }
}
```

### Float — wrapper f64 yang anti NaN

```rust
pub struct Float(f64);

impl Float {
    pub fn try_new(value: f64) -> Result<Self, DbError> {
        if value.is_finite() {
            Ok(Self(value))
        } else {
            Err(DbError::type_mismatch("float must be finite (no NaN or infinity)"))
        }
    }
}
```

**Kenapa tolak NaN dan Infinity?** Karena mereka bikin comparison jadi aneh. `NaN != NaN`. `infinity - infinity = NaN`. Jadi kita larang aja.

### Text — wrapper String dengan batas ukuran

```rust
pub struct Text(String);

impl Text {
    pub fn try_new(value: String) -> Result<Self, DbError> {
        if value.len() > MAX_TEXT_SIZE {
            return Err(DbError::invalid_operation(...));
        }
        Ok(Self(value))
    }
}
```

`MAX_TEXT_SIZE = 16 MB`. Kenapa dibatasin? Biar nggak ada satu row yang bikin database OOM.

### Blob — wrapper Vec<u8> dengan batas 64 MB

Sama kayak Text, tapi buat binary data.

### ColumnDef

```rust
pub struct ColumnDef {
    name: String,
    data_type: DataType,
    nullable: bool,
    primary_key: bool,
    unique: bool,
    default_value: Option<Value>,
    check_constraint: Option<CheckConstraint>,
    foreign_key: Option<ForeignKey>,
    allowed_values: Option<Vec<Value>>,
}
```

Lengkap banget. Ini mirip SQL column definition.

### TableSchema

```rust
pub struct TableSchema {
    name: String,
    columns: Vec<ColumnDef>,
}
```

### Validasi Schema

Waktu bikin schema, ada validasi ketat:

```rust
pub fn try_new(name: impl Into<String>, columns: Vec<ColumnDef>) -> Result<Self, DbError> {
    // - nama nggak boleh kosong
    // - nama nggak boleh > 255 byte
    // - nama nggak boleh ada control character
    // - minimal 1 kolom
    // - maksimal 1024 kolom
    // - nama kolom unik (case-insensitive)
    // ...
}
```

Setiap kolom juga divalidasi:

```rust
if col_name.is_empty() { ... }
if col_name.len() > MAX_NAME_LENGTH { ... }
if col_name.chars().any(char::is_control) { ... }
if !seen.insert(col_name.to_lowercase()) { /* duplicate */ }
```

---

## 11. Error Handling: Nggak Ada Panic

Ini filosofi utama Monumentum: **error itu harus di-handle, bukan panic**.

```rust
pub enum DbError {
    Io(Arc<std::io::Error>),
    Corruption(Arc<dyn Error + Send + Sync>),
    TableNotFound(String),
    ColumnNotFound(String),
    TypeMismatch(String),
    InvalidOperation(String),
    InvalidQuery(String),
    Transaction(Arc<dyn Error + Send + Sync>),
    Unsupported(String),
    ConstraintViolation {
        kind: ErrorKind,
        message: String,
        constraint: Option<String>,
        table: Option<String>,
    },
}
```

### Kenapa Arc?

`Arc` biar bisa di-clone tanpa copy. `DbError` sering di-propagate dari berbagai layer. Kalau pakai `Box`, clone jadi mahal. `Arc` cuma increment counter.

### Trait MonumentumError

Selain `DbError`, ada trait generik:

```rust
pub trait MonumentumError: Error + Send + Sync {
    fn kind(&self) -> ErrorKind;
    fn message(&self) -> &str;
    fn constraint(&self) -> Option<&str> { None }
    fn table(&self) -> Option<&str> { None }

    fn is_unique_violation(&self) -> bool { ... }
    fn is_foreign_key_violation(&self) -> bool { ... }
    // ...
}
```

Tujuannya: kode yang pakai Monumentum bisa ngecek tipe error tanpa tergantung tipe error spesifik. Jadi bisa ganti implementasi error tanpa breaking API.

---

## 12. Trait-Trait Utama

### StorageEngine

```rust
pub trait StorageEngine {
    fn create_table(&mut self, schema: TableSchema) -> Result<(), DbError>;
    fn drop_table(&mut self, name: &str) -> Result<(), DbError>;
    fn rename_table(&mut self, old_name: &str, new_name: &str) -> Result<(), DbError>;
    fn insert_row(&mut self, table: &str, row: &Row) -> Result<(), DbError>;
    fn get_row(&mut self, table: &str, row_idx: usize) -> Result<Option<Row>, DbError>;
    fn set_cell(&mut self, table: &str, row_idx: usize, col_idx: usize, value: Value) -> Result<(), DbError>;
    fn replace_rows(&mut self, table: &str, rows: Vec<Row>) -> Result<(), DbError>;
    fn checkpoint(&mut self) -> Result<(), DbError>;
    fn get_row_by_key(&mut self, table: &str, key: &Value) -> Result<Option<Row>, DbError>;
    fn get_all_rows(&mut self, table: &str) -> Result<Vec<Row>, DbError>;
}
```

Ada 2 implementasi:

- **`FileStorage`** — nyimpan beneran ke disk.
- **`InMemoryStorage`** — cuma di memori (buat testing).

### CatalogStore

```rust
pub trait CatalogStore {
    fn create_table(&mut self, schema: TableSchema) -> Result<(), DbError>;
    fn drop_table(&mut self, name: &str) -> Result<(), DbError>;
    fn rename_table(&mut self, old_name: &str, new_name: &str) -> Result<(), DbError>;
}
```

### Index

```rust
pub trait Index {
    fn insert(&mut self, key: &Value, row_idx: usize);
    fn remove(&mut self, key: &Value, row_idx: usize);
    fn lookup(&self, key: &Value) -> Option<&[usize]>;
}
```

Ada 2 implementasi:

- **`BTreeIndex`** — pakai `BTreeMap` (in-memory).
- **`HashIndex`** — pakai `HashMap` (in-memory).

### TableStore

```rust
pub trait TableStore {
    fn insert(&mut self, row: &Row) -> Result<(), DbError>;
    fn set_cell(&mut self, row_idx: usize, col_idx: usize, value: Value) -> Result<(), DbError>;
    fn replace_rows(&mut self, rows: Vec<Row>) -> Result<(), DbError>;
}
```

---

## 13. Konstanta Penting

```rust
pub const HASH_LENGTH: usize = 64;
pub const MAX_NAME_LENGTH: usize = 255;
pub const MAX_COLUMNS: usize = 1024;
pub const MAX_TEXT_SIZE: usize = 16 * 1024 * 1024;    // 16 MB
pub const MAX_BLOB_SIZE: usize = 64 * 1024 * 1024;    // 64 MB
pub const MAX_ROWS_PER_TABLE: usize = 10_000_000;     // 10 juta
pub const MAX_TABLES: usize = 1024;
pub const MAX_RECORD_SIZE: usize = 64 * 1024 * 1024;  // 64 MB
pub const MAX_SNAPSHOT_SIZE: u64 = 256 * 1024 * 1024; // 256 MB
pub const MAX_VEC_ELEMENTS: usize = 1_000_000;        // 1 juta
```

Semua batas ini ada **alasannya**:

- **MAX_NAME_LENGTH = 255** — biar muat di satu byte length (u8).
- **MAX_COLUMNS = 1024** — biar schema nggak bikin OOM.
- **MAX_TEXT_SIZE = 16 MB** — biar satu row nggak ngabisin semua halaman.
- **MAX_BLOB_SIZE = 64 MB** — sama, plus kasih ruang buat blob.
- **MAX_ROWS_PER_TABLE = 10 juta** — biar linear scan masih feasible.
- **MAX_TABLES = 1024** — biar catalog nggak nggak berujung.
- **MAX_RECORD_SIZE = 64 MB** — batas WAL record.
- **MAX_SNAPSHOT_SIZE = 256 MB** — batas snapshot.
- **MAX_VEC_ELEMENTS = 1 juta** — batas array/vector dalam value.

---

## 14. Testing: Serius Banget

Ini bagian yang mungkin paling banyak kodenya. Monumentum punya **beberapa jenis test**.

### Unit Test

Tiap modul punya `#[cfg(test)]`. Contoh di `buffer_pool.rs`:

```rust
#[test]
fn test_buffer_pool_basic() -> Result<(), DbError> {
    let path = temp_db_path();
    let pager = Pager::open(&path)?;
    let mut pool = BufferPool::new(pager, 2)?;

    let page_id = pool.allocate_page(PageType::Data)?;
    {
        let page = pool.get_page(page_id)?;
        page.header.cell_count = 42;
    }
    pool.unpin_page(page_id, true)?;
    pool.flush_page(page_id)?;

    // ...
}
```

### Integration Test

Ada 10 file test di folder `tests/`:

- `buff_tests.rs` — buffer pool.
- `catalog_tests.rs` — catalog.
- `index_tests.rs` — B-tree + hash index.
- `integration_tests.rs` — full workflow.
- `pager_tests.rs` — pager.
- `property_tests.rs` — property-based test.
- `serde_testing.rs` — encode/decode.
- `store_tests.rs` — WAL + file.
- `table_storage_tests.rs` — table storage.
- `table_tests.rs` — table metadata.

### Property-Based Test

Ini yang paling seru. Pakai crate **`proptest`**. Kita generate random input, terus verify invariant:

```rust
proptest! {
    #[test]
    fn prop_value_roundtrip(val in valid_value()) {
        let row = Row::new(vec![val.clone()]);
        let encoded = encode_row(&row)?;
        let decoded_row = decode_row(&encoded)?;
        prop_assert_eq!(decoded_row.len(), 1);
        // ...
    }

    #[test]
    fn prop_catalog_roundtrip(
        tables in proptest::collection::btree_set(valid_table_name(), 0..5)
    ) {
        let mut catalog = Catalog::new();
        for name in tables {
            // ...
        }
        let encoded = encode_catalog(&catalog)?;
        let decoded_catalog = decode_catalog(&encoded)?;
        prop_assert_eq!(catalog, decoded_catalog);
    }
}
```

Property test itu kayak: **"untuk SEMUA input yang valid, output-nya harus memenuhi sifat X"**. Ini nemu bug yang unit test nggak nemu.

### Test Crash Recovery

Ini test paling penting. Kita simulasikan crash dengan:

1. Buka storage.
2. Insert data.
3. **JANGAN checkpoint** (simulasi crash).
4. Drop storage (tanpa close).
5. Buka lagi.
6. Verify data masih ada.

```rust
#[test]
fn test_crash_recovery_without_checkpoint() {
    let path = temp_db_path();
    let schema = make_schema();
    let row = Row::new(vec![Value::from(1i64), Value::from(text)]);

    {
        // buka, insert, JANGAN checkpoint
        let mut storage = FileStorage::open(&path, 10).unwrap();
        storage.create_table(schema).unwrap();
        storage.insert_row("users", &row).unwrap();
        // storage di-drop tanpa close = crash
    }

    {
        // buka lagi, harus recover dari WAL
        let mut storage = FileStorage::open(&path, 10).unwrap();
        let retrieved = storage.get_row("users", 0).unwrap();
        assert_eq!(retrieved, Some(row));  // data masih ada!
    }
}
```

### Test File Locking

```rust
#[test]
fn test_file_locking_prevents_concurrent_writer() {
    let path = temp_db_path();
    let first = FileStorage::open(&path, 10);
    assert!(first.is_ok());

    let second = FileStorage::open(&path, 10);
    assert!(second.is_err());  // harus error!
}
```

---

## 15. Keputusan Desain yang Menarik

Beberapa keputusan yang aku ambil, plus alasannya:

### 1. Nggak pakai `unsafe`

```rust
#![forbid(unsafe_code)]
```

Di `lib.rs`. Ini **sangat ketat**. Artinya kode Monumentum harus 100% safe Rust. Nggak boleh `unsafe` sama sekali.

**Kenapa?** Karena storage engine itu rawan bug. Kalau ada `unsafe`, bug-nya jadi silent memory corruption. Dengan `forbid(unsafe_code)`, bug-nya jadi panic atau error yang jelas.

**Konsekuensinya:** harus pakai `Arc`, `Rc`, atau struktur data yang udah ada. Nggak bisa bikin custom allocator pakai `unsafe`.

### 2. `Arc` buat Error, bukan `Box`

```rust
Io(Arc<std::io::Error>)
```

**Kenapa `Arc`?** Karena `DbError` sering di-clone (buat logging, buat propagate). Kalau pakai `Box`, clone = deep copy. Kalau pakai `Arc`, clone = increment counter.

**Konsekuensinya:** `Arc` itu thread-safe. Jadi `DbError` bisa di-send antar thread.

### 3. Checksum di Setiap Halaman

Setiap halaman punya CRC32. **Overhead-nya kecil** (cuma 1 pass), tapi **manfaatnya gede**: deteksi korupsi.

**Trade-off:** kalau CPU-nya lambat, checksum bisa jadi bottleneck. Tapi untuk correctness, worth it.

### 4. WAL dengan CRC32 juga

Setiap WAL record punya checksum. Jadi kalau WAL corrupt di tengah, kita tahu.

**Konsekuensinya:** WAL write jadi 2x lebih lambat (karena harus hitung CRC). Tapi recovery jadi aman.

### 5. LRU Eviction, bukan Clock

Sebenarnya Clock (yang lebih efisien) juga bisa. Tapi LRU lebih gampang di-implementasi dan di-test. Buat sekarang, LRU cukup.

### 6. `BTreeMap` buat Catalog

Kenapa `BTreeMap` bukan `HashMap`? Karena `BTreeMap` punya **deterministic iteration order**. Ini penting buat:

- Serialisasi (bytes-nya konsisten).
- Testing (hasilnya predictable).

### 7. Linear Scan buat Data

Buat sekarang, get row ke-N itu linear scan. O(N). Ini **lambat** buat data gede.

**Kenapa?** Karena prioritas sekarang adalah correctness, bukan performance. Optimasi bisa nanti.

**Rencananya:** bikin "page directory" yang nyimpen offset tiap row. Jadi get row ke-N tinggal lihat directory, bukan scan.

### 8. B-Tree Cuma buat Primary Key

Sekarang, cuma primary key yang punya index B-tree. Kolom lain? Linear scan.

**Kenapa?** Karena implementasi index yang general (multi-column, secondary index) itu **jauh lebih ribet**. Buat MVP, fokus ke primary key dulu.

---

## 16. Roadmap

Jujur aja, ini project yang belum kelar. Yang masih kurang:

1. **Multi-column index** — sekarang cuma single column.
2. **Secondary index** — selain primary key.
3. **Page directory** — biar get row ke-N O(1), bukan O(N).
4. **Concurrent access** — sekarang cuma 1 writer.
5. **Query planner** — sekarang cuma get/set row.
6. **Transaction** — sekarang cuma single operation.
7. **Vacuum** — reclaim space dari row yang dihapus.
8. **Compression** — buat text/blob gede.
9. **Encryption** — at-rest encryption.
10. **Replication** — master-slave.

Tapi foundation-nya udah ada. Tinggal bangun di atasnya.

---

## 17. Contoh Penggunaan

Biar keliatan gimana pakainya:

```rust
use monumentum_core::store::storage::FileStorage;
use monumentum_handler::core::row::Row;
use monumentum_handler::core::schema::column::{ColumnDef, DataType};
use monumentum_handler::core::schema::table_schema::TableSchema;
use monumentum_handler::core::value::Value;
use monumentum_handler::traits::StorageEngine;
use monumentum_handler::types::Text;
use std::path::Path;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 1. Buka database
    let mut storage = FileStorage::open(Path::new("my.db"), 100)?;

    // 2. Bikin schema
    let schema = TableSchema::try_new(
        "users",
        vec![
            ColumnDef::new("id", DataType::Integer),
            ColumnDef::new("name", DataType::Text),
        ],
    )?;

    // 3. Bikin tabel
    storage.create_table(schema)?;

    // 4. Insert row
    let row = Row::new(vec![
        Value::from(1i64),
        Value::from(Text::try_new("Alice".to_string())?),
    ]);
    storage.insert_row("users", &row)?;

    // 5. Baca row
    if let Some(retrieved) = storage.get_row("users", 0)? {
        println!("Row: {:?}", retrieved);
    }

    // 6. Update cell
    storage.set_cell(
        "users",
        0,
        1,
        Value::from(Text::try_new("Bobby".to_string())?),
    )?;

    // 7. Checkpoint
    storage.checkpoint()?;

    // 8. Close
    storage.close()?;

    Ok(())
}
```

---

## 18. Pelajaran yang Aku Dapat

Beberapa hal yang aku pelajari bikin database:

### 1. Error handling itu 80% dari kerjaan

Bikin operasi sukses itu gampang. Bikin operasi yang **gagal dengan benar** itu susah. Setiap `?` yang aku tulis, aku harus mikir: "kalau ini error, state-nya konsisten nggak?"

### 2. WAL itu fondasi crash safety

Sebelum nulis WAL, aku nggak bisa bikin database yang crash-safe. Setelah nulis WAL, tiba-tiba aja crash recovery jadi masalah yang solved.

### 3. Checksum itu murah, tapi nyawa

CRC32 itu cuma beberapa instruksi per byte. Tapi bisa ngedeteksi korupsi disk. **Worth it.**

### 4. Testing crash itu susah

Simulasi crash dalam test itu tricky. Aku pakai trik: drop storage tanpa `close()`. Tapi kadang OS-nya masih flush, jadi nggak 100% kayak crash beneran.

### 5. Batas ukuran itu penting

Tanpa `MAX_TEXT_SIZE`, satu user bisa upload 1 GB text dan bikin database OOM. Batas ukuran itu **bukan** fitur, tapi **syarat** biar database bisa jalan.

### 6. Idempotent recovery itu kunci

Kalau recovery nggak idempotent, crash kedua bisa bikin state makin rusak. Jadi WAL record harus bisa di-apply berkali-kali tanpa efek samping.

---

## Penutup

Monumentum itu:

- **Database engine** ditulis 100% di Rust safe code.
- **Arsitektur:** page → pager → buffer pool → storage engine → catalog → WAL.
- **Fitur:** crash recovery, checksum, B-tree index, WAL, file locking.
- **Testing:** unit, integration, property-based, crash recovery.
- **Roadmap:** banyak yang masih belum, tapi foundation-nya kuat.

Kalau kamu tertarik bikin database sendiri, saran aku:

1. **Mulai dari page.** Itu unit terkecil.
2. **Bikin pager.** Jembatan ke disk.
3. **Bikin buffer pool.** Cache di memori.
4. **Bikin WAL.** Crash safety.
5. **Bikin B-tree.** Index.
6. **Bikin catalog.** Metadata.
7. **Testing crash.** Yang paling penting.

Jangan skip WAL. Jangan skip checksum. Jangan skip testing.

Dan yang paling penting: **nikmatin prosesnya**. Bikin database itu susah, tapi **memuaskan**.

---

**Referensi:**

- Kode: `monumentum_handler`, `monumentum_core`, `monumentum_dsl`.
- Buku: _Database Internals_ by Alex Petrov.
- Buku: _Designing Data-Intensive Applications_ by Martin Kleppmann.
- Paper: _The Design and Implementation of a Log-Structured File System_ by Rosenblum & Ousterhout.
