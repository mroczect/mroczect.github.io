+++
title = "LLVM: Compiler Backend yang Diam-Diam Kamu Pakai Setiap Hari"
date = 2026-10-03
description = "Penjelasan lengkap LLVM — dari sejarah, arsitektur, komponen, sampai kenapa dia jadi tulang punggung banyak bahasa pemrograman modern."
[taxonomies]
tags = ["llvm", "compiler", "programming", "systems", "llm"]
+++

## LLVM itu apa sih?

oke jadi kalau kamu pernah denger nama **LLVM** tapi bingung itu apa, ini penjelasan lengkapnya.

singkatnya: **LLVM itu kumpulan teknologi compiler dan toolchain.** Dia bisa dipakai buat bikin **frontend** untuk bahasa pemrograman apapun, dan **backend** untuk arsitektur CPU apapun.

maksudnya gimana?

bayangin kamu mau bikin bahasa pemrograman baru. kamu perlu:

1. **Frontend** — yang baca kode kamu, terus ngubahnya jadi bentuk perantara.
2. **Backend** — yang ngubah bentuk perantara itu jadi kode mesin yang bisa jalan di CPU.

Nah, LLVM nyediain **backend**-nya. Kamu tinggal bikin frontend-nya aja.

atau sebaliknya: kamu punya backend sendiri, tapi mau support banyak bahasa? LLVM bisa jadi frontend-nya.

**LLVM itu jembatan universal antara bahasa pemrograman dan CPU.**

---

## Kenapa Namanya LLVM?

dulu, LLVM itu singkatan dari **Low Level Virtual Machine**. dibikin tahun 2000-an.

tapi makin lama, proyek ini berkembang jadi jauh lebih dari sekadar virtual machine. jadi tahun 2011, secara resmi LLVM **bukan lagi singkatan**. sekarang cuma nama brand aja.

kata Chris Lattner (pendirinya): _"The acronym it once expanded to was confusing, and inappropriate almost from day 1."_

jadi ya, sekarang LLVM ya LLVM. nggak ada kepanjangannya.

---

## Sejarah Singkat

### 2000: Dimulai

LLVM dimulai di **University of Illinois Urbana-Champaign**, dipimpin sama **Vikram Adve** dan **Chris Lattner**.

tujuannya waktu itu: bikin riset infrastructure buat neliti teknik **dynamic compilation** — buat bahasa statis dan dinamis.

### 2003: Rilis Publik

LLVM dirilis di bawah lisensi **University of Illinois/NCSA Open Source License** — lisensi permissive.

### 2005: Apple Rekrut Lattner

ini titik baliknya. **Apple** ngerekrut Chris Lattner dan bikin tim buat ngerjain LLVM buat kepentingan internal Apple.

hasilnya: LLVM jadi bagian integral dari **Xcode** — IDE-nya Apple — sejak Xcode 4 (2011).

### 2006: Clang Dimulai

Lattner mulai project baru namanya **Clang** — frontend buat C, C++, dan Objective-C.

kombinasi Clang + LLVM disebut **Clang/LLVM**, atau cuma **Clang**.

tujuannya: ganti compiler C/Objective-C di GCC dengan sistem yang lebih gampang diintegrasiin sama IDE, dan support multithreading lebih baik.

### 2012: Dapet ACM Award

**Association for Computing Machinery (ACM)** ngasih **ACM Software System Award** ke Vikram Adve, Chris Lattner, dan Evan Cheng buat "designing and implementing LLVM".

### 2019: Rilis 9.0.0, Ganti Lisensi

setelah versi 9.0.0, LLVM **relicense** dari UIUC license ke **Apache License 2.0 with LLVM Exceptions**.

### 2026: Versi 23.1.2

versi stabil terakhir yang aku tau: **23.1.2**, rilis 22 September 2026.

---

## Arsitektur: Gimana LLVM Bekerja?

ini bagian paling penting buat kamu paham. LLVM itu dibangun di atas konsep **intermediate representation (IR)**.

### Konsep: IR

**IR itu bahasa assembly portabel tingkat tinggi.**

bayangin gini:

```

Kode Python ──[frontend]──> IR ──[backend]──> Kode Mesin
Kode C++ ──[frontend]──> IR ──[backend]──> Kode Mesin
Kode Rust ──[frontend]──> IR ──[backend]──> Kode Mesin

```

IR itu **language-independent**. Artinya: IR yang dihasilin dari Python, C++, atau Rust itu formatnya sama. LLVM nggak peduli kamu nulis pakai bahasa apa.

### Kenapa IR Penting?

karena ada **banyak frontend** dan **banyak backend**, tapi semua nyambung ke **satu IR**.

- Frontend N × Backend M = N × M kombinasi tanpa IR
- Frontend N + Backend M = N + M kombinasi dengan IR

ini yang bikin LLVM sangat powerful.

### Bentuk IR

LLVM support 3 bentuk IR yang ekuivalen:

1. **Assembly format** — human-readable, bisa dibaca manusia
2. **In-memory format** — buat frontend
3. **Dense bitcode format** — buat serialisasi

contoh "Hello, World!" dalam IR:

```llvm
@.str = internal constant [14 x i8] c"Hello, world\0A\00"

declare i32 @printf(ptr, ...)

define i32 @main(i32 %argc, ptr %argv) nounwind {
entry:
    %tmp1 = getelementptr [14 x i8], ptr @.str, i32 0, i32 0
    %tmp2 = call i32 (ptr, ...) @printf( ptr %tmp1 ) nounwind
    ret i32 0
}
```

lihat? mirip assembly, tapi lebih terstruktur.

### Fitur IR

- **Strongly typed** — setiap nilai punya tipe yang jelas
- **SSA (Static Single Assignment)** — setiap variabel cuma di-assign sekali
- **Infinite temporaries** — nggak ada batas register, IR pakai `%0`, `%1`, dll
- **Calling convention** diabstraksi lewat `call` dan `ret`

**SSA form** itu penting. Artinya: setiap nilai cuma ditulis sekali. Ini bikin analisis dependency antar variabel jadi jauh lebih gampang.

### MLIR: IR Baru

selain IR biasa, LLVM juga punya **MLIR (Multi-Level IR)**.

MLIR itu IR yang bisa punya **banyak level abstraksi** sekaligus. dia pakai sistem **Dialect** — plugin architecture yang bikin MLIR bisa di-extend.

keuntungannya: bisa pakai informasi level tinggi dalam proses optimasi, termasuk **polyhedral compilation**.

---

## Fitur LLVM

### Compile-Time, Link-Time, Runtime Optimization

LLVM bisa optimize di tiga waktu berbeda:

1. **Compile-time** — waktu kode di-compile
2. **Link-time** — waktu object files di-link jadi binary
3. **Runtime** — waktu program udah jalan

yang paling menarik: **runtime optimization (JIT)**. LLVM bisa compile IR jadi machine code **waktu program jalan**.

### JIT Compilation

**Just-in-Time (JIT) compilation** itu kemampuan buat ngubah IR jadi kode mesin **saat runtime**.

ini berguna banget buat:

- **Partial evaluation** — LLVM JIT bisa optimize static branches yang nggak perlu, cuma berdasarkan kondisi runtime
- **Graphics pipeline** — Apple pakai LLVM di OpenGL pipeline macOS untuk support hardware features yang hilang
- **Database queries** — PostgreSQL pakai JIT buat compile query jadi machine code

contoh: waktu kamu jalanin query database, LLVM bisa compile query-nya jadi machine code yang optimal buat data spesifik kamu.

### Multi-Bahasa

ini daftar bahasa yang pakai LLVM (atau bisa generate LLVM IR):

**Bahasa mainstream:**

- C (via Clang)
- C++ (via Clang)
- Objective-C (via Clang)
- Rust
- Swift
- Julia
- Kotlin
- Crystal
- Zig
- Odin
- Fortran (via Flang)

**Bahasa niche:**

- Ada
- Common Lisp (via Clasp)
- D (via LDC)
- Delphi
- Dylan
- Forth
- FreeBASIC
- Free Pascal
- Halide
- Haskell
- Idris
- Jai (release builds only)
- LabVIEW (G language)
- PicoLisp
- PostgreSQL (SQL, PL/pgSQL)
- Ruby (via RubyMotion)
- Scala
- Standard ML (via MLton)
- Wolfram Language
- Xojo

**Bahasa bytecode:**

- C# (di .NET via LLILC)
- Java bytecode
- CUDA

banyak banget kan?

### Performa vs GCC

dulu, program yang di-compile GCC lebih cepat 10% rata-rata dibanding LLVM (2011).

tapi tahun 2013, Phoronix report bahwa **LLVM udah nyusul GCC**. binary yang dihasilkan udah sebanding performanya.

sekarang, LLVM dan GCC dua-duanya top-tier.

---

## Komponen LLVM

LLVM itu **umbrella project**. Artinya: banyak komponen yang tergabung di dalamnya. ini daftarnya:

### 1. Frontends

- **Clang** — frontend C, C++, Objective-C. ini yang paling populer dan paling mature.
- **Flang** — frontend Fortran
- **LLVM-GCC** — fork GCC yang dimodif biar pakai LLVM backend. udah discontinued.
- **Utrecht Haskell** — compiler Haskell yang bisa generate LLVM IR
- **GHC** — Glasgow Haskell Compiler, pakai LLVM backend. report-nya: **30% lebih cepat** dibanding native code generator.

### 2. Intermediate Representation (IR)

inti dari LLVM. bahasa low-level yang strongly typed, SSA, dan target-independent.

### 3. Backends

LLVM versi 16 udah support banyak arsitektur:

- **IA-32** (x86 32-bit)
- **x86-64** (x86 64-bit)
- **ARM**
- **Qualcomm Hexagon**
- **LoongArch**
- **M68K** (Motorola 68000)
- **MIPS**
- **NVPTX** (Nvidia Parallel Thread Execution / PTX)
- **PowerPC**
- **AMD TeraScale**
- **AMDGPU** (AMD GPU modern)
- **SPARC**
- **SystemZ** (z/Architecture)
- **XCore**
- **RISC-V** (sejak versi 7)
- **WebAssembly**

yang udah dihapus:

- C backend
- Cell SPU
- mblaze (MicroBlaze)
- AMD R600
- DEC Alpha
- Nios2

yang masih beta: **MIPS assembler** integrated support.

### 4. Linker (lld)

**lld** itu linker platform-independent buat LLVM.

tujuannya: **hilangin dependency ke linker pihak ketiga**.

per Mei 2017, lld support:

- **ELF** (Linux, BSD, dll)
- **PE/COFF** (Windows)
- **Mach-O** (macOS)
- **WebAssembly**

dengan urutan kelengkapan dari yang paling lengkap.

lld lebih cepat dari dua varian GNU ld. dan punya **built-in support** buat **link-time optimization (LTO)**, yang artinya:

- code generation lebih cepat (nggak lewat plugin linker)
- tapi nggak interoperable dengan LTO flavor lain

### 5. C++ Standard Library (libc++)

LLVM punya implementasi sendiri buat **C++ Standard Library** namanya **libc++**.

dual-licensed: **MIT License** + **UIUC license**. sejak v9.0.0, relicense ke **Apache License 2.0 with LLVM Exceptions**.

### 6. Polly

Polly itu suite optimasi buat **cache locality**, **auto-parallelism**, dan **vectorization**.

pakai **polyhedral model** — representasi matematis buat loop optimization.

### 7. Debugger (LLDB)

**LLDB** itu debugger buat LLVM. dia standalone, bisa dipakai buat debug program yang di-compile pakai Clang atau LLVM.

### 8. C Standard Library (LLVM-libc)

ini project yang **masih in development**. tujuannya: bikin **C standard library** yang ABI-independent, designed by dan untuk LLVM project.

statusnya: **incomplete, upcoming**.

---

## Derivatif: Fork-Fork LLVM

karena lisensinya permissive, **banyak vendor** rilis fork LLVM mereka sendiri, yang udah di-tuning.

LLVM dokumentasi punya official recommendation: **jangan pakai version number** buat feature check, karena tiap vendor bisa beda numbering.

vendor-vendor yang punya fork:

### Apple

Apple maintain **open-source fork** LLVM buat Xcode.

### AMD

**AMD Optimizing C/C++ Compiler (AOCC)** — based on LLVM, Clang, dan Flang.

### ARM

ARM nyediain beberapa toolchain berbasis LLVM:

- **Arm Compiler for Embedded** — buat bare-metal development
- **Arm Compiler for Linux** — buat High Performance Computing (HPC)

### IBM

IBM adopt LLVM di compiler **C/C++** dan **Fortran** mereka.

### Intel

Intel pakai LLVM buat **Intel C++ Compiler** generasi berikutnya.

### Nvidia

Nvidia pakai LLVM di implementasi **NVVM CUDA Compiler**.

catatan: NVVM beda dengan backend "NVPTX". keduanya generate PTX code buat GPU Nvidia, tapi NVVM itu compiler, NVPTX itu backend.

### Sony

sejak 2013, Sony pakai **Clang** di SDK **PlayStation 4**.

### Los Alamos National Laboratory

punya fork LLVM 8 buat parallel computing, namanya **"Kitsune"**.

---

## Kenapa LLVM Begitu Penting?

beberapa alasan kenapa LLVM jadi tulang punggung dunia compiler modern:

### 1. Modular Design

kamu bisa pakai komponen tertentu aja. mau cuma pakai IR? bisa. mau cuma pakai backend? bisa. mau semuanya? juga bisa.

### 2. Language-Agnostic

banyak bahasa bisa pakai LLVM. jadi satu investasi, dipakai buat banyak bahasa.

### 3. Target-Agnostic

banyak arsitektur CPU bisa pakai LLVM. dari x86 sampai RISC-V sampai WebAssembly.

### 4. Lisensi Permissive

Apache 2.0 + LLVM Exceptions. artinya vendor bisa fork dan modif tanpa harus share balik source codenya.

### 5. Optimasi Canggih

dari compile-time, link-time, sampai runtime (JIT). semua di-support.

### 6. Industri Support

dari Apple, Google, AMD, Intel, Nvidia, ARM, IBM, Sony — semua investasi di LLVM.

### 7. Ekosistem

karena banyak yang pakai, makin banyak yang kontribusi balik. jadi siklus positif.

---

## LLVM di 2026

update terkini:

- **Versi stabil:** 23.1.2 (22 September 2026)
- **Presiden LLVM Foundation:** Tanya Lattner (Executive Director juga), sejak 2014, masih 2026
- **Repo:** github.com/llvm
- **Website:** llvm.org

proyeknya masih aktif banget. setiap tahun ada rilis baru.

---

## Kesimpulan

LLVM itu:

- **Kumpulan teknologi compiler & toolchain**
- **Bukan cuma backend** — juga IR, linker, debugger, C++ standard library, dll
- **Dipake banyak bahasa** — dari C sampai Zig
- **Support banyak target** — dari x86 sampai WebAssembly
- **Lisensi permissive** — Apache 2.0 + LLVM Exceptions
- **Umbrella project** — banyak komponen di dalamnya
- **Aktif dan industri-backed** — dari Apple sampai IBM

kalau kamu programmer, kamu udah pakai LLVM — mungkin tanpa sadar. entah itu waktu nulis Rust, Swift, Zig, atau bahkan C++ pakai Clang.

dan kalau kamu mau bikin bahasa pemrograman sendiri? LLVM itu pilihan yang sangat masuk akal. kamu tinggal fokus ke frontend, urusan backend serahin ke LLVM.

---

## Referensi

- [LLVM Official Website](https://llvm.org)
- [LLVM Wikipedia](https://en.wikipedia.org/wiki/LLVM)
- Chris Lattner, _The Architecture of Open Source Applications_, Chapter 11 (LLVM)
- Lattner & Adve, _LLVM: A Compilation Framework for Lifelong Program Analysis & Transformation_
