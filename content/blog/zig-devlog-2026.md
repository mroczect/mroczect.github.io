+++
title = "Zig Devlog 2026: Build System Dirombak, Incremental Compilation, dan @bitCast Baru"
date = 2026-10-03
description = "Rangkuman devlog Zig 2026 — dari pointer stability ArrayList sampai io_uring, dari @bitCast baru sampai bypass kernel32."
[taxonomies]
tags = ["zig", "programming", "systems", "devlog", "llm"]
+++

## Zig devlog 2026: apa aja yang berubah?

oke jadi kali ini aku mau bahas **devlog Zig** sepanjang 2026. ini bukan rilis resmi, tapi catatan perubahan di branch `main` yang lagi dikerjain.

banyak banget yang berubah. dari ArrayList, Build System, `@bitCast`, io_uring, sampe cara Zig ngobrol sama Windows kernel. aku rangkum satu-satu, pelan-pelan.

---

## 1. Pointer Stability untuk ArrayList (27 Agustus 2026)

jadi ceritanya Zig nambahin fitur **Pointer Stability Lock** ke `std.ArrayList`. konsepnya sebenernya udah ada di HashMap sejak 2024, sekarang dibawa ke ArrayList.

kenapa ini penting? karena ArrayList itu kalau tumbuh, dia bisa **pindahin memory-nya**. Jadi kalau kamu punya pointer ke elemen di dalam ArrayList, terus ArrayList-nya grow, pointer kamu jadi **dangling**.

contoh bug-nya kayak gini:

```zig
const Context = struct {
    history: std.ArrayList(u8),
    lines: std.ArrayList([]const u8),

    fn parse(ctx: *Context, allocator: std.mem.Allocator, input: []const u8) !void {
        const slice = try ctx.history.addManyAsSlice(allocator, input.len);
        @memcpy(slice, input);
        var it = std.mem.tokenizeScalar(u8, slice, '\n');
        while (it.next()) |line| {
            try ctx.lines.append(allocator, line);
        }
    }
};
```

bug-nya: `ctx.lines` nyimpen pointer ke dalam `ctx.history`. tapi kalau `ctx.history` grow, memory-nya pindah, jadi pointer di `ctx.lines` jadi **invalid**.

solusinya:

```zig
try ctx.parse(gpa, input);
ctx.history.lockPointers();
defer ctx.history.unlockPointers();
try ctx.parse(gpa, input_two);
```

kalau kamu lupa unlock, atau kalau ArrayList mau resize sementara pointer-nya masih di-lock, dia **panic** dengan stack trace yang jelas. jadi kamu langsung tau di mana masalahnya.

ini bikin debugging jauh lebih gampang.

---

## 2. Package Management Pindah dari Compiler ke Build System (30 Juni 2026)

jadi dulu, package management itu bagian dari compiler Zig. sekarang dipindah ke **maker process** di Build System.

subcommand yang pindah:

- `zig build`
- `zig fetch`
- `zig init`
- `zig libc`

efeknya:

- **Ukuran binary Zig mengecil** — dari 14.1 MiB jadi 13.5 MiB.
- **Fungsi networking Zig sekarang pake safety checks** — karena maker executable di-compile di ReleaseSafe mode.
- **Crypto-nya bisa pake instruksi CPU khusus** — jadi lebih cepet.
- **Bisa di-patch tanpa rebuild compiler.**

struktur proses-nya juga berubah:

dulu:

```
zig build (compiler + package manager)
└─ builder (user's build.zig + build system)
```

sekarang:

```
zig build (compiler)
└─ maker (build system + package manager)
   └─ configurer (user's build.zig)
```

kenapa ini penting? karena kalau pake `--watch`, proses maker nggak perlu mati kalau `build.zig` berubah. jadi build server-nya lebih stabil.

---

## 3. SPIR-V Backend Progress (26 Juni 2026)

Zig lagi serius ngerjain **SPIR-V backend**. ini buat bikin shader sama compute kernel pakai Zig.

yang baru:

### @SpirvType

builtin baru buat bikin tipe SPIR-V yang nggak ada di sistem tipe Zig:

```zig
const Sampler = @SpirvType(.sampler);
const Image = @SpirvType(.{ .image = .{
    .usage = .{ .sampled = u32 },
    .format = .unknown,
    .dim = .@"2d",
    .depth = .unknown,
    .arrayed = false,
    .multisampled = false,
    .access = .unknown,
} });
const SampledImage = @SpirvType(.{ .sampled_image = Image });
```

### Execution Mode pindah ke calling convention

dulu, execution mode (workgroup size, fragment origin, dll) di-emit lewat inline assembly. sekarang jadi bagian dari calling convention:

```zig
export fn vert() callconv(.spirv_vertex) void {}
export fn frag() callconv(.{ .spirv_fragment = .{ .depth_assumption = .greater } }) void {}
export fn comp() callconv(.{ .spirv_kernel = .{ .x = 8, .y = 8, .z = 1 } }) void {}
```

### Multi-Threaded Codegen

SPIR-V backend sekarang **multi-threaded** kayak backend lain. jadi lebih cepet.

### Object File Linking

`.spv` files sekarang dikenali sebagai object files. jadi kamu bisa compile banyak `.zig` file, terus di-link jadi satu module.

### Hasilnya

**49% behavior tests passing** di `spirv64-vulkan`. masih jauh dari sempurna, tapi lumayan lah.

`std.gpu` juga di-rename jadi `std.spirv`.

---

## 4. @bitCast Baru + LLVM Backend Improvements (25 Juni 2026)

ini yang paling teknis tapi menarik.

### Masalah lama dengan @bitCast

dulu, `@bitCast` itu didefinisiin sebagai "reinterpret bytes di memory". tapi definisi ini bikin masalah karena:

- ukuran tipe di memory beda-beda tergantung target
- LLVM sering salah optimasi
- kadang hasilnya beda antara little-endian dan big-endian

### Definisi baru

sekarang `@bitCast` didefinisiin ulang: **reinterpret logical bit representation**.

artinya: setiap tipe punya **logical bit layout** — urutan bit yang "logis". nah `@bitCast` cuma nge-reinterpret bit itu.

efeknya:

- **Endian-agnostic** — sama aja di little atau big endian.
- **Lebih konsisten** — nggak tergantung layout memory.
- **Lebih predictable**.

contoh menarik:

```zig
test "bitcast [2]u3 to @Vector(3, u2)" {
    const arr: [2]u3 = .{ 0b001, 0b011 };
    const vec: @Vector(3, u2) = @bitCast(arr);

    // arr[0] = 0b001 → bit: 1, 0, 0
    // arr[1] = 0b011 → bit: 1, 1, 0
    // Gabungin: 1 0 0 1 1 0
    // Bagi 2-bit: 01, 10, 01
    // vec[0] = 0b01
    // vec[1] = 0b10
    // vec[2] = 0b01
}
```

### Yang di-drop

`@bitCast` sekarang **nggak boleh** dari `extern struct` atau `extern union`. kalau butuh type punning, pakai `@ptrCast`.

### Bonus: LLVM performance

perubahan cara LLVM lower integer tipe arbitrary bikin **compiler Zig 5% lebih cepet**. jadi ada bonus performa juga.

---

## 5. ELF Linker Improvements (30 Mei 2026)

ELF linker baru Zig udah makin matang.

yang baru:

- bisa **build Zig compiler sendiri** dengan LLVM dan LLD enabled.
- **Incremental compilation** jalan di x86_64 Linux, bahkan dengan external libraries.
- Rebuild cuma butuh **~250ms** buat compiler Zig (vs 36 detik build pertama).

contoh:

```
[mlugg@nebula master]$ zig build -Dno-lib -Denable-llvm -fincremental --watch
Build Summary: 4/4 steps succeeded
install success
└─ install zig success
   └─ compile exe zig Debug native success 36s

Build Summary: 4/4 steps succeeded
└─ compile exe zig Debug native success 244ms

Build Summary: 4/4 steps succeeded
└─ compile exe zig Debug native success 228ms
```

dari **36 detik** jadi **228 milidetik**. itu luar biasa cepet.

yang belum: **DWARF debug info** buat kode Zig. ini prioritas selanjutnya.

---

## 6. Build System Reworked (26 Mei 2026)

ini perubahan gede yang aku udah bahas di atas. tapi ada detail tambahan.

### Performa

perbandingan `zig build --help`:

|              | Sebelum | Sesudah | Delta    |
| ------------ | ------- | ------- | -------- |
| wall_time    | 150ms   | 14.3ms  | **-90%** |
| peak_rss     | 84.8MB  | 78.5MB  | -7%      |
| cpu_cycles   | 593M    | 24.1M   | **-96%** |
| instructions | 995M    | 43.7M   | **-96%** |

kenapa bisa secepet itu? karena `build.zig` logic **nggak dijalanin lagi** tiap `zig build`. build system pakai cached configuration.

### Breaking change

yang paling sering ketemu:

```zig
// Dulu
if (b.args) |args| {
    run_cmd.addArgs(args);
}

// Sekarang
run_cmd.addPassthruArgs();
```

### Argumen CLI yang berubah

- `--maker-opt` → ganti pakai env `ZIG_DEBUG_MAKER`
- `--zig-lib-dir` → ganti pakai env `ZIG_LIB_DIR`

---

## 7. Incremental Compilation dengan LLVM (8 April 2026)

selain ELF linker, LLVM backend juga udah support incremental compilation.

ini bantu banget kalau kamu lagi **print debugging**. soalnya kalau ada compile error, LLVM emit object di-skip, jadi errornya muncul cepet.

cara pakainya:

```sh
zig build -fincremental --watch
```

tim Zig core udah pakai ini setahun terakhir. katanya mereka suka banget.

---

## 8. Type Resolution Redesign (10 Maret 2026)

ini PR 30.000 baris yang dikerjain 2-3 bulan sama Matthew Lugg.

### Yang berubah

- **Lazy field analysis** — kalau tipe nggak pernah diinisialisasi, Zig nggak perlu tau isinya. jadi kalau kamu punya struct yang cuma dipakai sebagai namespace, nggak akan pull code yang nggak perlu.
- **Dependency loop error message** — dulu pesannya nggak jelas. sekarang detail banget:

```
error: dependency loop with length 2
    repro.zig:1:29: note: type 'repro.Foo' depends on type 'repro.Bar' for field declared here
    const Foo = struct { inner: Bar };
                                ^~~
    repro.zig:2:44: note: type 'repro.Bar' depends on type 'repro.Foo' for alignment query here
    const Bar = struct { x: u32 align(@alignOf(Foo)) };
                                               ^~~
    note: eliminate any one of these dependencies to break the loop
```

- **Incremental compilation improvement** — bug-bug fixed, over-analysis dihilangin.

---

## 9. io_uring dan Grand Central Dispatch (13 Februari 2026)

Zig sekarang punya implementasi `std.Io.Evented` yang pake:

- **io_uring** (Linux)
- **Grand Central Dispatch** (macOS)

keduanya pake **userspace stack switching** — kadang disebut "fibers", "stackful coroutines", atau "green threads".

konsepnya: kamu bisa **ganti I/O implementation** tanpa ngubah kode aplikasi.

contoh:

```zig
fn app(io: std.Io) !void {
    try std.Io.File.stdout().writeStreamingAll(io, "Hello, World!\n");
}
```

terus tinggal ganti `io`-nya:

```zig
// Pakai Threaded
var threaded: std.Io.Threaded = .init(gpa, .{...});
const io = threaded.io();

// Atau pakai Evented (io_uring / GCD)
var evented: std.Io.Evented = undefined;
try evented.init(gpa, .{...});
const io = evented.io();
```

`app()`-nya **identik**. cuma `main()`-nya yang beda.

masih eksperimental, tapi arahnya ke arah yang bagus.

---

## 10. Package Management Workflow (6 Februari 2026)

dua perubahan penting buat kamu yang punya Zig project dengan dependencies.

### Fetched packages disimpan lokal

sekarang, package yang di-fetch disimpan di folder `zig-pkg/` di root project. jadi:

```sh
zig-pkg/
├── freetype-2.14.1-.../
├── opus-0.0.2-.../
├── pulseaudio-16.1.1-.../
└── vaxis-0.5.1-.../
```

kamu harus masukin `zig-pkg/` ke `.gitignore`. tapi keuntungannya: bisa bikin **self-contained source tarball** yang bisa di-build offline.

### --fork flag

ada flag baru buat `zig build`:

```sh
zig build --fork=/path/to/fork
```

ini buat override package dengan source checkout lokal. gunanya kalau kamu lagi nge-fix package yang upstream-nya rusak.

contoh:

```sh
$ zig build --fork=/home/andy/dev/dvui
info: fork /home/andy/dev/dvui matched 1 (dvui) packages
```

kalau nggak match:

```sh
$ zig build --fork=/home/andy/dev/mime
error: fork /home/andy/dev/mime matched no mime packages
```

flag ini **ephemeral** — begitu kamu drop flag-nya, kamu balik pakai package aslinya. enak buat testing.

---

## 11. Bypassing Kernel32.dll untuk Fun dan Nonprofit (3 Februari 2026)

ini cerita teknis soal Windows.

### Masalahnya

di Windows, `kernel32.dll` itu **wrapper** dari `ntdll.dll`. kalau kamu panggil `ReadFile`, sebenernya yang jalan itu `NtReadFile`.

masalahnya: `kernel32.dll` introduces:

- heap allocations yang nggak perlu
- failure modes tambahan
- CPU usage yang nggak sengaja
- bloat

### Solusinya

Zig sekarang **prefer native API** di mana bisa.

contoh 1: **entropy** (random bytes)

dulu, project kayak Chromium, Firefox, Rust panggil `SystemFunction036` dari `advapi32.dll`. yang mana ini load `bcryptprimitives.dll`, yang mana ini heap allocate, yang mana bisa **gagal dengan cara aneh**.

Zig sekarang panggil `NtOpenFile("\\Device\\CNG")` langsung, baca 48 bytes, terus init CSPRNG. **nggak perlu DLL tambahan**.

contoh 2: **NtReadFile vs ReadFile**

`ReadFile`:

```zig
pub extern "kernel32" fn ReadFile(
    hFile: HANDLE,
    lpBuffer: LPVOID,
    nNumberOfBytesToRead: DWORD,
    lpNumberOfBytesRead: ?*DWORD,
    lpOverlapped: ?*OVERLAPPED,
) callconv(.winapi) BOOL;
```

`NtReadFile`:

```zig
pub extern "ntdll" fn NtReadFile(
    FileHandle: HANDLE,
    Event: ?HANDLE,
    ApcRoutine: ?*const IO_APC_ROUTINE,
    ApcContext: ?*anyopaque,
    IoStatusBlock: *IO_STATUS_BLOCK,
    Buffer: *anyopaque,
    Length: ULONG,
    ByteOffset: ?*const LARGE_INTEGER,
    Key: ?*const ULONG,
) callconv(.winapi) NTSTATUS;
```

`ReadFile` return `BOOL` (iya/nggak), terus kamu harus panggil `GetLastError` buat tau errornya.

`NtReadFile` return `NTSTATUS` — langsung dapet error code-nya. **nggak perlu GetLastError**.

selain itu, `OVERLAPPED` itu **tipe palsu** — Windows kernel nggak tau itu apa. yang beneran primitif itu: events, APCs, dan `IO_STATUS_BLOCK`.

Zig sekarang pake APC routine, jadi I/O-nya bisa di-cancel sambil jalan.

---

## 12. zig libc (31 Januari 2026)

ini proyek jangka panjang: **ganti fungsi-fungsi libc dari C source jadi wrapper Zig**.

contoh:

```zig
fn strnlen(str: [*:0]const c_char, max: usize) callconv(.c) usize {
    return std.mem.findScalar(u8, @ptrCast(str[0..max]), 0) orelse max;
}
```

simpel kan? cuma wrap fungsi Zig biasa.

### Progress

- **250 file C dihapus** dari repo Zig.
- **2032 file C tersisa**.

### Keuntungan

- independen dari third-party projects
- compile lebih cepet
- instalasi Zig lebih kecil
- binary user yang statically link libc jadi lebih kecil

### Bonus

`zig libc` sekarang **share Zig Compilation Unit** dengan kode Zig lain. jadi bisa dioptimize bareng. efeknya kayak LTO, tapi lebih bagus karena dilakukan di frontend, bukan di linker.

---

## Kesimpulan

Zig 2026 devlog-nya banyak banget. yang paling impactful menurut aku:

1. **Build System dirombak** — `zig build` jadi 90% lebih cepet.
2. **Incremental compilation** — rebuild 228ms, bukan 36 detik.
3. **@bitCast baru** — lebih konsisten dan endian-agnostic.
4. **io_uring support** — networking Linux jadi lebih cepet.
5. **Bypass kernel32** — Windows code jadi lebih efisien.

buat kamu yang lagi belajar Zig, momen ini bagus banget. banyak fitur baru yang lagi stabil, banyak diskusi yang lagi jalan.

tapi inget: **Zig belum 1.0**. jadi masih banyak breaking changes ke depan.

ya udah segitu dulu. kalau kamu mau baca devlog lengkapnya, langsung aja ke [ziglang.org/devlog](https://ziglang.org/devlog/).

sampai jumpa di post berikutnya!