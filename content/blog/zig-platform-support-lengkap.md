+++
title = "Zig Platform Support: Tier System dan Target Lengkap yang Di-support"
date = 2026-10-03
description = "Zig support banyak arsitektur dan OS. Ini penjelasan lengkap Tier System, Support Table, dan platform tambahan yang didukung Zig."
[taxonomies]
tags = ["zig", "programming", "systems", "platform", "llm"]
+++

## Zig support platform apa aja sih?

oke jadi di blog kali ini aku mau bahas **platform support Zig** nih. soalnya sering banget ada yang nanya "Zig bisa build buat OS apa aja?" atau "Zig support ARM nggak?" atau "kalau mau cross-compile ke Windows gimana?"

jawabannya: **Zig support banyak banget platform**. mungkin salah satu yang paling luas di antara bahasa sistem modern.

tapi nggak semua platform sama level support-nya. ada yang **full support**, ada yang **partial**, ada yang cuma bisa **generate kode doang**.

di blog ini aku bakal jelasin lengkap:

- **Tier System** — level support Zig
- **Support Table** — daftar lengkap target
- **Version Requirements** — versi OS minimal
- **Additional Platforms** — target tambahan di luar tier

langsung aja ya.

---

## 1. Tier System: Level Support Zig

Zig bagi level support target jadi **4 tier**. Tier 1 paling tinggi, Tier 4 paling rendah.

tujuannya: tier 1 target harus punya **zero disabled tests**. ini bakal jadi requirement sebelum Zig rilis 1.0.0.

### Tier 1

target di tier ini harus:

- **semua fitur bahasa non-experimental jalan** dengan benar.
- **compiler bisa generate machine code tanpa LLVM** (self-hosted backend).
- **fuzzer** jalan di target ini (kalau applicable).

yang masuk tier 1 sekarang: **cuma `x86_64-linux`**.

iya, cuma satu. itu sebabnya Zig belum 1.0 — karena baru satu target yang benar-benar "matang".

### Tier 2

target di tier ini harus:

- **std lib cross-platform abstractions** ada implementasinya.
- **failed assertions dan crashes** produce stack traces.
- **libc tersedia** walau lagi cross-compile.
- **CI machine** build module tests tiap push.

contoh target tier 2: `aarch64-macos`, `x86_64-windows`, `riscv64-linux`, `s390x-linux`, dll. banyak.

### Tier 3

target di tier ini:

- **compiler bisa generate machine code** — tapi harus pakai external backend kayak LLVM.
- **linker bisa produce** object files, libraries, executables.

contoh: `aarch64-ios`, `aarch64-tvos`, `x86_64-haiku`, `x86_64-illumos`, dll.

### Tier 4

target di tier ini:

- **compiler cuma bisa generate assembly atau C source code**.

contoh: `alpha-linux`, `hppa-linux`, `m68k-linux`, `sparc-linux`, dll. ini target-target eksotis yang udah jarang dipake.

---

## 2. Support Table: Daftar Lengkap

di tabel ini ada beberapa simbol yang dipake:

| Simbol | Arti                        |
| ------ | --------------------------- |
| ✅     | Full support                |
| ❌     | No support                  |
| ⚠️     | Partial support             |
| ❔     | Status largely unknown      |
| 🪦     | Obsolescent (bakal dihapus) |

kolom-kolomnya:

- **Tier** — 1 sampai 4
- **Target** — nama target (contoh `aarch64-linux`)
- **Code Gen.** — 🖥️ machine code, 📄 C code, ⚡ self-hosted, 🛠️ self-hosted in development
- **Linker** — bisa link apa nggak
- **Lang. Feat.** — fitur bahasa jalan apa nggak
- **Std. Lib.** — std library jalan apa nggak
- **Stack Traces** — bisa produce stack trace apa nggak
- **Fuzzer** — fuzzer jalan apa nggak
- **libc** — libc tersedia apa nggak
- **CI** — masuk CI Zig apa nggak

### Tier 1

| Target         | Status   |
| -------------- | -------- |
| `x86_64-linux` | ✅ semua |

itu aja. cuma satu.

### Tier 2 (yang populer)

| Target              | Code Gen | Linker | Lang | Std Lib | Stack | Fuzzer | libc | CI    |
| ------------------- | -------- | ------ | ---- | ------- | ----- | ------ | ---- | ----- |
| `aarch64-macos`     | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `aarch64-linux`     | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `aarch64-windows`   | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ❌     | ✅   | ⚠️    |
| `x86_64-windows`    | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ❌     | ✅   | ✅    |
| `x86_64-macos`      | 🖥️⚡     | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ⚠️ 🪦 |
| `x86_64-freebsd`    | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `x86_64-netbsd`     | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `x86_64-openbsd`    | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ❌     | ✅   | ✅    |
| `riscv64-linux`     | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `s390x-linux`       | 🖥️       | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `sparc64-linux`     | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `powerpc64le-linux` | 🖥️       | ✅     | ✅   | ✅      | ✅    | ❌     | ✅   | ✅    |
| `mips64-linux`      | 🖥️       | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `loongarch64-linux` | 🖥️🛠️     | ✅     | ✅   | ✅      | ✅    | ✅     | ✅   | ✅    |
| `wasm32-wasi`       | 🖥️🛠️     | ✅     | ✅   | ✅      | ⚠️    | ❌     | ✅   | ✅    |
| `x86-linux`         | 🖥️       | ✅     | ✅   | ✅      | ✅    | ❌     | ✅   | ✅    |
| `arm-linux`         | 🖥️       | ✅     | ✅   | ✅      | ✅    | ❌     | ✅   | ✅    |
| `thumb-linux`       | 🖥️       | ✅     | ✅   | ✅      | ✅    | ❌     | ✅   | ✅    |
| `hexagon-linux`     | 🖥️       | ✅     | ✅   | ✅      | ✅    | ❌     | ✅   | ✅    |

**catatan:** `x86_64-macos` dan `x86_64-maccatalyst` ditandai 🪦 — artinya **obsolescent**. Apple udah transisi ke ARM (Apple Silicon), jadi target x86_64 macOS bakal dihapus di masa depan.

### Tier 2 yang lagi dikembangin

| Target              | Code Gen | Catatan                    |
| ------------------- | -------- | -------------------------- |
| `aarch64-freebsd`   | 🖥️🛠️     | Self-hosted in development |
| `aarch64-netbsd`    | 🖥️🛠️     | Self-hosted in development |
| `aarch64-openbsd`   | 🖥️🛠️     | Self-hosted in development |
| `loongarch32-linux` | 🖥️🛠️     | Self-hosted in development |
| `riscv64-freebsd`   | 🖥️🛠️     | Self-hosted in development |
| `riscv64-netbsd`    | 🖥️🛠️     | Self-hosted in development |
| `riscv64-openbsd`   | 🖥️🛠️     | Self-hosted in development |
| `x86_64-openbsd`    | 🖥️🛠️     | Self-hosted in development |

### Tier 3

target tier 3 butuh LLVM buat generate machine code. tapi linkernya udah jalan.

| Target             | Catatan    |
| ------------------ | ---------- |
| `aarch64-haiku`    | Haiku OS   |
| `aarch64-ios`      | iOS        |
| `aarch64-serenity` | SerenityOS |
| `aarch64-tvos`     | tvOS       |
| `aarch64-visionos` | visionOS   |
| `aarch64-watchos`  | watchOS    |
| `arm-haiku`        |            |
| `mips64-netbsd`    |            |
| `riscv64-haiku`    |            |
| `riscv64-serenity` |            |
| `thumb-windows`    | 🪦         |
| `wasm64-wasi`      |            |
| `x86-freebsd`      | 🪦         |
| `x86-haiku`        |            |
| `x86-illumos`      | 🪦         |
| `x86_64-dragonfly` |            |
| `x86_64-haiku`     |            |
| `x86_64-illumos`   |            |
| `x86_64-serenity`  |            |

### Tier 4

target tier 4 cuma bisa generate assembly atau C source code.

contoh: `alpha-linux`, `arc-linux`, `csky-linux`, `hppa-linux`, `m68k-linux`, `m88k-openbsd`, `microblaze-linux`, `or1k-linux`, `sh-linux`, `sparc-linux`, `xtensa-linux`, dan masih banyak lagi.

ini target-target **eksotis** yang udah jarang dipake. support-nya best-effort doang.

---

## 3. Version Requirements: Versi OS Minimal

std lib Zig punya minimum version requirement buat beberapa OS. ini affect compiler Zig juga.

| OS                     | Versi Minimal |
| ---------------------- | ------------- |
| **Darwin** (macOS/iOS) | 15.0+         |
| **DragonFly BSD**      | 6.4+          |
| **FreeBSD**            | 14.0+         |
| **Linux**              | 5.10+         |
| **NetBSD**             | 10.1+         |
| **OpenBSD**            | 7.8+          |
| **Windows**            | 10+           |

jadi kalau kamu pake Linux kernel di bawah 5.10, Zig mungkin nggak jalan dengan baik.

kenapa minimum-nya gitu? karena Zig std lib pake syscall atau API yang baru ada di versi itu. jadi nggak bisa di-backport ke versi lama.

---

## 4. Additional Platforms: Di Luar Tier System

selain target-target di atas, Zig juga punya varying level support buat target-target ini. tapi tier system nggak sepenuhnya berlaku.

### Freestanding (tanpa OS)

ini target-target yang nggak punya OS. biasanya buat embedded atau bare-metal:
```

aarch64-freestanding
alpha-freestanding
arc-freestanding
arm-freestanding
avr-freestanding
bpf-freestanding
csky-freestanding
ez80-freestanding
hexagon-freestanding
hppa-freestanding
hppa64-freestanding
kalimba-freestanding
kvx-freestanding
lanai-freestanding
loongarch32-freestanding
loongarch64-freestanding
m68k-freestanding
m88k-freestanding
microblaze-freestanding
mips-freestanding
mips64-freestanding
msp430-freestanding
or1k-freestanding
powerpc-freestanding
powerpc64-freestanding
propeller-freestanding
riscv32-freestanding
riscv64-freestanding
s390x-freestanding
sh-freestanding
sparc-freestanding
sparc64-freestanding
spork8-freestanding
thumb-freestanding
ve-freestanding
wasm32-freestanding
wasm64-freestanding
x86-freestanding
x86_64-freestanding
xcore-freestanding
xtensa-freestanding

```

### UEFI

buat bootloader atau firmware:

```

aarch64-uefi
arm-uefi
loongarch32-uefi
loongarch64-uefi
riscv32-uefi
riscv64-uefi
x86-uefi
x86_64-uefi

```

### Game Consoles

Zig support beberapa console:

```

aarch64-switch — Nintendo Switch
arm-3ds — Nintendo 3DS
arm-gba — Game Boy Advance
arm-vita — PlayStation Vita
mipsel-psx — PlayStation 1
mipsel-psp — PlayStation Portable
powerpc-wiiu — Nintendo Wii U
powerpc64-ps3 — PlayStation 3
thumb-gba — Game Boy Advance (Thumb)
thumb-vita — PlayStation Vita (Thumb)
x86_64-ps4 — PlayStation 4
x86_64-ps5 — PlayStation 5

```

keren kan? bisa bikin homebrew game console pakai Zig.

### GPU / Accelerator

```

amdgcn-amdhsa — AMD GPU (HSA)
amdgcn-amdpal — AMD GPU (PAL)
amdgcn-mesa3d — AMD GPU (Mesa3D)
nvptx-cuda — NVIDIA CUDA
nvptx64-cuda — NVIDIA CUDA (64-bit)
nvptx-nvcl — NVIDIA OpenCL
nvptx64-nvcl — NVIDIA OpenCL (64-bit)
spirv32-opencl — SPIR-V buat OpenCL
spirv64-opencl — SPIR-V buat OpenCL (64-bit)
spirv32-opengl — SPIR-V buat OpenGL
spirv64-opengl — SPIR-V buat OpenGL (64-bit)
spirv32-vulkan — SPIR-V buat Vulkan
spirv64-vulkan — SPIR-V buat Vulkan (64-bit)

```

jadi kamu bisa compile shader atau compute kernel pakai Zig.

### Sistem Operasi lain

```

aarch64-driverkit
aarch64-fuchsia
aarch64-hurd
arm-fuchsia
riscv64-fuchsia
riscv64-hurd
thumb-fuchsia
x86-hurd
x86_64-driverkit
x86_64-fuchsia
x86_64-plan9

```

### Platform lain

```

ez80-tios — TI Calculator

````

---

## 5. Yang Perlu Kamu Tahu

### 1. Zig belum 1.0

masih banyak target yang belum tier 1. jadi kalau kamu build buat target tier 2 atau 3, ada kemungkinan nemu bug.

### 2. Cross-compilation itu gampang

salah satu kelebihan Zig: **cross-compilation gampang banget**. kamu bisa build buat Windows di Linux tanpa setup apapun:

```sh
zig build-exe hello.zig -target x86_64-windows
````

atau build buat macOS ARM di Linux:

```sh
zig build-exe hello.zig -target aarch64-macos
```

tinggal ganti `-target` aja.

### 3. Target naming convention

format target query Zig itu:

```
<cpu_arch>-<os>-<abi>
```

contoh:

- `x86_64-linux-gnu` — x86_64, Linux, GNU libc
- `aarch64-macos` — ARM64, macOS
- `x86_64-windows-gnu` — x86_64, Windows, GNU ABI

kamu bisa query target pakai `zig targets`:

```sh
zig targets
```

ini bakal nampilin daftar lengkap target yang Zig support.

### 4. Tier 1 cuma x86_64-linux

jujur aja, ini yang bikin Zig belum 1.0. tim Zig mau **semua target tier 1 punya zero disabled tests**. ini butuh kerja keras karena banyak backend yang belum selesai.

tapi sekarang arahnya bagus. **self-hosted backend** lagi dikembangin buat aarch64, riscv64, dan lainnya. jadi nanti target tier 1 bakal nambah.

### 5. Obsolescent targets

target yang ditandai 🪦 artinya **bakal dihapus** di masa depan. contoh:

- `x86_64-macos` dan `x86_64-maccatalyst` — Apple udah transisi ke ARM.
- `x86-windows` — Windows 32-bit udah jarang dipake.
- `thumb-windows` — juga jarang.
- `x86-freebsd` — FreeBSD 32-bit udah jarang.
- `x86-illumos` — Illumos 32-bit jarang.

kalau kamu masih pake target-target ini, siap-siap migrasi.

---

## 6. Contoh Praktis

### Build buat Linux, macOS, Windows sekaligus

```zig
// build.zig
const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
};

pub fn build(b: *std.Build) !void {
    for (targets) |t| {
        const exe = b.addExecutable(.{
            .name = "hello",
            .root_module = b.createModule(.{
                .root_source_file = b.path("hello.zig"),
                .target = b.resolveTargetQuery(t),
                .optimize = .ReleaseSafe,
            }),
        });

        const target_output = b.addInstallArtifact(exe, .{
            .dest_dir = .{
                .override = .{
                    .custom = try t.zigTriple(b.allocator),
                },
            },
        });

        b.getInstallStep().dependOn(&target_output.step);
    }
}
```

hasilnya:

```
zig-out
├── aarch64-linux
│   └── hello
├── aarch64-macos
│   └── hello
├── x86_64-linux-gnu
│   └── hello
├── x86_64-linux-musl
│   └── hello
└── x86_64-windows
    ├── hello.exe
    └── hello.pdb
```

satu command, lima platform.

### Cross-compile langsung

kalau cuma butuh 1 target:

```sh
# Build buat Windows
zig build-exe hello.zig -target x86_64-windows

# Build buat macOS ARM
zig build-exe hello.zig -target aarch64-macos

# Build buat RISC-V Linux
zig build-exe hello.zig -target riscv64-linux
```

gampang kan?

---

## Kesimpulan

Zig platform support-nya luas banget. dari yang mainstream kayak Linux, Windows, macOS, sampai yang eksotis kayak SPARC, MIPS, LoongArch.

tapi:

- **Tier 1 cuma x86_64-linux** — ini yang bikin Zig belum 1.0.
- **Banyak target tier 2** — udah jalan dengan baik tapi belum sempurna.
- **Target tier 3-4** — buat yang eksotis atau niche.
- **Cross-compilation gampang** — salah satu kelebihan Zig.

buat kamu yang lagi belajar Zig:

1. **Mulai dari target native kamu** — misal `x86_64-linux` kalau di Linux.
2. **Coba cross-compile** ke Windows atau macOS — rasain gampangnya.
3. **Explore `zig targets`** — liat daftar lengkap target.
4. **Kalau bikin project buat platform lain**, cek dulu tier support-nya.

ya udah segitu dulu blog kali ini. semoga membantu yang lagi bingung soal platform support Zig.

sampai jumpa di post berikutnya!

---

**Referensi:** Dokumentasi resmi [Zig Platform Support](https://ziglang.org/learn/platform-support/).