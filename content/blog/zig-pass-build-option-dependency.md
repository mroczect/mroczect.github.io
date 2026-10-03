+++
title = "Pass Build Option ke Dependency di Zig: Jawaban dari Ziggit"
date = 2026-10-03
description = "Bingung cara kirim build option dari build.zig ke dependency? Ini solusinya, diambil dari forum Ziggit."
[taxonomies]
tags = ["zig", "build-system", "tutorial", "ziggit"]
+++

## Masalahnya

jadi ceritanya ada orang di forum **Ziggit** yang lagi bikin library. library-nya butuh `addSystemCommand` buat manggil binary eksternal. tapi path binary-nya harus bisa diganti sama user, karena ada banyak versi.

kira-kira kodenya kayak gini:

```zig
const godot_path = b.option([]const u8, "godot-path", "Path to Godot binary [default: `godot`]") orelse "godot";

const dump_cmd = b.addSystemCommand(&.{
    godot_path, "--dump-extension-api", "--dump-gdextension-interface", "--headless",
});
```

nah masalahnya: ketika library ini dipakai sebagai **dependency** di project lain, option `godot-path`-nya **nggak muncul**. waktu jalanin `zig build --help`, option itu nggak ada di "Project-Specific Options".

jadi user nggak bisa ganti path binary-nya. padahal harusnya bisa.

---

## Jawabannya

ternyata ada cara gampang buat **pass build option dari `build.zig` kamu ke dependency**.

tinggal pakai parameter `args` di `b.dependency()`.

### Di `build.zig` kamu (yang punya project utama)

```zig
const lib_godot = b.dependency("godot", .{
    .godot_path = godot_path,
});
```

perhatiin: `.godot_path = godot_path` — itu namanya harus **match** sama nama option yang dideklarasikan di dependency-nya.

### Di `build.zig` dependency (library godot)

```zig
const godot_path = b.option([]const u8, "godot_path", "Path to Godot binary [default: `godot`]") orelse "godot";
```

ini yang bakal nerima value dari parent-nya.

---

## Kenapa Ini Penting?

kalau kamu bikin library atau project yang bisa dipakai orang lain, kamu mungkin punya **build option** yang perlu di-config dari luar. Misalnya:

- Path ke binary eksternal
- Path ke SDK
- Flag kompilasi tertentu
- Konfigurasi build

Nah, dengan cara ini, orang lain yang pakai library kamu bisa nge-config itu **langsung dari `build.zig` mereka**, tanpa harus edit file di dalam folder dependency.

ini prinsip penting: **dependency harus configurable dari luar**.

---

## Contoh Lengkap

biar lebih jelas, ini contoh lengkapnya.

### Struktur Project

```
my-project/
├── build.zig
├── build.zig.zon
└── src/
    └── main.zig

(dependencies tersimpan di zig-pkg/)
└── godot/ (dependency)
    ├── build.zig
    └── src/
        └── godot.zig
```

### `my-project/build.zig` (parent)

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Tentukan path Godot — bisa di-override user
    const godot_path = b.option(
        []const u8,
        "godot-path",
        "Path to Godot binary [default: `godot`]",
    ) orelse "godot";

    // Pass option ini ke dependency
    const lib_godot = b.dependency("godot", .{
        .godot_path = godot_path,
    });

    // Pakai dependency-nya
    const exe = b.addExecutable(.{
        .name = "my-app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("godot", lib_godot.module("godot"));

    b.installArtifact(exe);
}
```

### `godot/build.zig` (dependency)

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    // Terima option dari parent (atau pakai default)
    const godot_path = b.option(
        []const u8,
        "godot_path",
        "Path to Godot binary [default: `godot`]",
    ) orelse "godot";

    // Pakai path itu buat system command
    const dump_cmd = b.addSystemCommand(&.{
        godot_path,
        "--dump-extension-api",
        "--dump-gdextension-interface",
        "--headless",
    });

    // ... sisanya
}
```

### Cara Pakai

```sh
# Pake default (`godot`)
zig build

# Pake custom path
zig build -Dgodot-path=/usr/local/bin/godot-4.3
```

---

## Yang Perlu Diperhatiin

**1. Nama option harus match.**

kalau di parent kamu nulis `.godot_path`, di dependency juga harus `"godot_path"`. Kalau beda, compile-nya bakal error atau option-nya nggak ke-pass.

**2. Ini bisa berantai.**

kalau kamu punya dependency A, yang punya dependency B, kamu bisa pass option lewat A ke B. tinggal A pass lagi ke B.

**3. Cek `zig build --help` di project kamu.**

kalau option-nya udah ke-declare dengan benar, dia bakal muncul di "Project-Specific Options". kalau nggak muncul, berarti ada yang salah.

---

## Kenapa Ini Bikin Hidup Lebih Gampang

bayangin kamu bikin library image processing yang butuh `libpng`. beberapa user punya `libpng` di `/usr/lib`, beberapa di `/usr/local/lib`, beberapa di path custom.

tanpa fitur ini, user harus:

- fork repo kamu
- edit `build.zig` kamu
- maintain fork-nya

dengan fitur ini, user cuma tulis:

```zig
const lib_png = b.dependency("pnglib", .{
    .libpng_path = "/opt/libpng",
});
```

selesai. nggak perlu fork, nggak perlu edit apapun di dalam dependency.

ini salah satu alasan kenapa Zig build system itu powerful. dependency **beneran bisa dikonfigurasi** dari luar, nggak kayak beberapa build system lain yang maksa kamu ngoprek kodenya.

---

## Kesimpulan

- **Pass build option ke dependency**: pakai `b.dependency(name, .{ .option = value })`
- **Dependency terima option**: pakai `b.option()` seperti biasa
- **Nama harus match** antara parent dan dependency
- **Hasilnya**: user bisa config dependency tanpa fork

ini trik simpel tapi penting banget kalau kamu bikin library yang mau dipakai orang banyak.

---

**Sumber:** Diskusi di [Ziggit — Build System Tricks](https://ziggit.dev/t/build-system-tricks/3531).
