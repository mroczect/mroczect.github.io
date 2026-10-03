+++
title = "Ngintip Isi std.zig: Pintu Masuk ke Standard Library Zig"
date = 2026-10-03
description = "std.zig itu file root dari Standard Library Zig. Ini penjelasan santai tentang isinya — dari ArrayList sampai Options yang bisa kamu override."
[taxonomies]
tags = ["zig", "programming", "stdlib", "systems", "llm"]
+++

## std.zig itu apa sih?

oke jadi kalau kamu nulis kode Zig, pasti sering banget nulis ini:

```zig
const std = @import("std");
```

nah pernah nggak kepikiran, sebenernya `std` itu apa? isinya apa aja? kok bisa manggil `std.ArrayList`, `std.mem`, `std.fs`, dll?

jawabannya: `std` itu **root file dari Standard Library Zig**. file-nya ada di `lib/std/std.zig`. dia yang jadi pintu masuk ke semua module std lib.

di blog ini aku mau bahas isi file itu — santai aja, nggak semua baris. tapi cukup biar kamu paham cara kerja std lib Zig.

---

## 1. Struktur Dasar

kalau kamu buka `lib/std/std.zig`, kamu bakal lihat sesuatu kayak gini:

```zig
pub const AutoHashMap = hash_map.AutoHashMap;
pub const BitStack = @import("BitStack.zig");
pub const Build = @import("Build.zig");
pub const BufMap = @import("buf_map.zig").BufMap;
pub const BufSet = @import("buf_set.zig").BufSet;
// ...
```

jadi simple-nya, `std.zig` itu **daftar export**. setiap baris bilang:

> "Oh, `std.AutoHashMap` itu sebenernya `hash_map.AutoHashMap`."

atau

> "`std.Build` itu ada di file `Build.zig`."

jadi waktu kamu nulis `std.Build`, Zig bakal ngeliat ke `std.zig` dulu, terus diarahin ke `Build.zig`.

---

## 2. Cara Kerja `@import`

ada dua pola yang dipake di `std.zig`:

### Pola 1: Import langsung

```zig
pub const BitStack = @import("BitStack.zig");
pub const Build = @import("Build.zig");
pub const Io = @import("Io.zig");
pub const Progress = @import("Progress.zig");
pub const Random = @import("Random.zig");
pub const Target = @import("Target.zig");
pub const Thread = @import("Thread.zig");
pub const Uri = @import("Uri.zig");
```

ini buat file yang **isinya satu topik**. misal `BitStack.zig` isinya cuma `BitStack`. `Random.zig` isinya random generator.

### Pola 2: Ambil dari namespace

```zig
pub const AutoHashMap = hash_map.AutoHashMap;
pub const ArrayList = array_list.Aligned;
pub const StringHashMap = hash_map.StringHashMap;
pub const Target = @import("Target.zig");
```

ini buat module yang **isinya banyak**. misal `hash_map` punya `AutoHashMap`, `StringHashMap`, `HashMap`, dll. nah `std.zig` cuma ngambil yang penting-penting.

---

## 3. Yang Ada di `std`

kategori besar yang bisa kamu akses dari `std`:

### Data Structures

```zig
std.ArrayList       // list growable
std.AutoHashMap     // hash map otomatis
std.StringHashMap   // hash map dengan key string
std.BufMap          // map string ke string
std.BufSet          // set of string
std.Deque           // double-ended queue
std.DoublyLinkedList
std.SinglyLinkedList
std.PriorityQueue
std.MultiArrayList
std.Treap
std.EnumMap
std.EnumSet
std.StaticStringMap
```

### System / OS

```zig
std.os          // abstraksi OS
std.posix       // POSIX API
std.fs          // filesystem
std.process     // spawn process, dll
std.Thread      // thread
std.DynLib      // dynamic library
std.time        // waktu
std.Tz          // timezone
```

### Encoding / Format

```zig
std.base64
std.json
std.fmt         // formatting
std.leb         // LEB128
std.tar
std.zip
std.compress
std.unicode
std.ascii
```

### Crypto / Security

```zig
std.crypto
std.hash
std.Random
```

### Compiler / Tooling

```zig
std.Build       // build system
std.zig         // Zig AST, dll
std.elf         // ELF format
std.coff        // COFF format
std.macho       // Mach-O format
std.dwarf       // DWARF debug info
std.pdb         // PDB debug info
std.wasm        // WebAssembly
std.spirv       // SPIR-V
```

### Lain-lain

```zig
std.debug       // debugging
std.testing     // unit testing
std.log         // logging
std.math        // matematika
std.mem         // memory utilities
std.meta        // comptime meta
std.simd        // SIMD operations
std.sort        // sorting
std.valgrind    // Valgrind integration
```

banyak banget kan?

---

## 4. `Options`: Setting Compile-Time

ini bagian menarik dari `std.zig`. ada struct namanya `Options` yang bisa kamu **override** dari root source file kamu.

```zig
pub const options: Options = if (@hasDecl(root, "std_options")) root.std_options else .{};
```

jadi gini: kalau file utama kamu (root source) punya deklarasi `std_options`, maka Zig bakal pakai itu. kalau nggak ada, pakai default.

### Contoh pakai

misal kamu mau matiin segfault handler biar binary lebih kecil:

```zig
// main.zig
const std = @import("std");

pub const std_options: std.Options = .{
    .enable_segfault_handler = false,
    .log_level = .warn,
};

pub fn main() void {
    std.debug.print("Hello!\n", .{});
}
```

sekarang Zig bakal pakai setting itu, bukan default.

### Options yang bisa di-override

| Option                         | Default                     | Fungsi                                      |
| ------------------------------ | --------------------------- | ------------------------------------------- |
| `enable_segfault_handler`      | true di debug               | Handle segfault biar bisa print stack trace |
| `signal_stack_size`            | 256 KiB                     | Ukuran signal stack buat stack overflow     |
| `log_level`                    | `.debug`                    | Level log minimum                           |
| `log_scope_levels`             | `&.{}`                      | Level log per scope                         |
| `logFn`                        | `log.defaultLog`            | Fungsi log custom                           |
| `page_size_min`                | null                        | Override page size minimum                  |
| `page_size_max`                | null                        | Override page size maximum                  |
| `queryPageSize`                | `heap.defaultQueryPageSize` | Fungsi custom buat query page size          |
| `fmt_max_depth`                | `fmt.default_max_depth`     | Kedalaman maksimum formatting               |
| `http_disable_tls`             | false                       | Matiin TLS di HTTP client                   |
| `http_enable_ssl_key_log_file` | true di debug               | Log SSL key buat debugging                  |
| `side_channels_mitigations`    | default                     | Mitigasi side-channel attacks               |
| `allow_stack_tracing`          | `!strip_debug_info`         | Izinkan stack tracing                       |
| `networking`                   | true                        | Izinkan networking                          |
| `unexpected_error_tracing`     | true di debug               | Print error.Unexpected                      |

ini berguna banget kalau kamu bikin embedded program yang butuh binary kecil — tinggal matiin fitur yang nggak perlu.

---

## 5. `logFn`: Custom Logging

salah satu option yang paling powerful: **`logFn`**. kamu bisa ganti cara Zig nge-log.

default-nya, log muncul di stderr. tapi kamu bisa ganti, misalnya:

- Kirim ke file
- Kirim ke syslog
- Matiin log di production
- Format log sesuai selera

contoh:

```zig
const std = @import("std");

pub const std_options: std.Options = .{
    .logFn = myLog,
};

fn myLog(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    // format sendiri
    const timestamp = std.time.timestamp();
    std.debug.print("[{d}] {s}: ", .{ timestamp, @tagName(level) });
    std.debug.print(format, args);
    std.debug.print("\n", .{});
}

pub fn main() void {
    std.log.info("Hello, custom log!", .{});
}
```

---

## 6. `start`: Magic di Balik `main`

ada satu baris penting di akhir `std.zig`:

```zig
comptime {
    _ = start;
}
```

ini yang bikin kamu bisa nulis `pub fn main() void` tanpa setup apapun.

file `start.zig` isinya logic yang:

- **Export symbol `_start`** (di Linux) atau `mainCRTStartup` (di Windows).
- **Setup runtime** — argument parsing, allocator, dll.
- **Panggil `main`** kamu.
- **Handle error** kalau `main` return error.
- **Exit** dengan code yang bener.

jadi waktu kamu nulis:

```zig
pub fn main() void {
    std.debug.print("Hello!\n", .{});
}
```

sebenernya Zig nge-generate kode yang manggil `main` kamu lewat `start.zig`. keren kan?

---

## 7. Testing Built-in

di akhir `std.zig` juga ada ini:

```zig
test {
    testing.refAllDecls(@This());
}
```

ini bikin setiap decl di `std.zig` di-test. jadi kalau ada module yang rusak, langsung ketahuan.

ada juga:

```zig
comptime {
    debug.assert(@import("std") == @This()); // std lib tests require --zig-lib-dir
}
```

ini mastiin `std` yang di-import sama dengan `std.zig` yang lagi diproses.

---

## 8. Tips Pakai `std`

### 1. Explore pakai `@typeInfo`

kamu bisa liat isi `std` di compile-time:

```zig
const std = @import("std");

pub fn main() void {
    const info = @typeInfo(std).@"struct";
    inline for (info.decls) |decl| {
        std.debug.print("{s}\n", .{decl.name});
    }
}
```

tapi ini bakal print banyak banget. mending buka source-nya langsung di [github.com/ziglang/zig/blob/master/lib/std/std.zig](https://github.com/ziglang/zig/blob/master/lib/std/std.zig).

### 2. Baca source code `std`

salah satu kelebihan Zig: **std lib-nya readable**. kamu bisa buka file manapun di `lib/std/` dan baca implementasinya. ini cara belajar yang bagus.

contoh: mau tau `ArrayList` gimana kerjanya? buka `lib/std/array_list.zig`.

### 3. Pakai `zig std` di command line

Zig punya subcommand `zig std` buat buka dokumentasi std lib di browser:

```sh
zig std
```

ini bakal generate dokumentasi dari std lib versi kamu dan buka di browser.

---

## 9. Deprecated Stuff

kalau kamu baca `std.zig` dengan teliti, ada beberapa decl yang ditandai **deprecated**:

```zig
/// Deprecated: use `bit_set.DynamicManaged`.
pub const DynamicBitSet = bit_set.DynamicBitSet;

/// Deprecated: use `bit_set.Dynamic`.
pub const DynamicBitSetUnmanaged = bit_set.DynamicBitSetUnmanaged;

/// Deprecated; use `array_hash_map.Custom`.
pub const ArrayHashMapUnmanaged = array_hash_map.Custom;
```

ini penanda kalau API bakal berubah di versi mendatang. kalau kamu pakai API yang deprecated, ada baiknya migrasi ke penggantinya.

contoh: `std.DynamicBitSet` bakal diganti sama `std.bit_set.DynamicManaged`.

---

## 10. `builtin` vs `lang`

ada satu perubahan menarik di Zig 0.17.0:

```zig
/// Deprecated; use `lang`.
pub const builtin = lang;
pub const lang = @import("lang.zig");
```

dulu, kita akses `@import("builtin")` buat dapet info compile-time. sekarang ada `std.lang` yang jadi pengganti.

contoh dulu:

```zig
const builtin = @import("builtin");
const mode = builtin.mode;
```

sekarang bisa:

```zig
const lang = @import("std").lang;
const mode = lang.mode;
```

atau lebih umum, masih:

```zig
const builtin = @import("builtin");
```

tapi `std.builtin` bakal dihapus pelan-pelan.

---

## Kesimpulan

`std.zig` itu file root yang jadi pintu masuk ke seluruh Standard Library Zig. isinya:

- **Daftar export** — nunjukin semua yang bisa diakses lewat `std.X`.
- **`Options` struct** — setting compile-time yang bisa di-override.
- **`start`** — handle startup code, panggil `main` kamu.
- **Testing** — mastiin semua module bener.

yang penting diingat:

- `std` itu bukan file, tapi **namespace**.
- isinya banyak banget — dari data structure sampai crypto.
- kamu bisa **override options** dari root file kamu.
- **source-nya readable** — jangan takut buka dan baca.

kalau kamu lagi belajar Zig, saran aku: sesekali buka `lib/std/std.zig` dan baca. banyak yang bisa dipelajari dari cara tim Zig nulis kode.

ya udah segitu dulu blog kali ini. kalau ada yang bingung, tanya aja di komentar (eh, gak ada komentar 😅).

sampai jumpa di post berikutnya!

---

**Referensi:** Source code [std.zig di GitHub](https://github.com/ziglang/zig/blob/master/lib/std/std.zig).
