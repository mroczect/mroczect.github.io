+++
title = "Mengenal Zig: Bahasa Sistem yang Simpel Tapi Kuat (VERSI LLM)"
date = 2026-10-03
description = "Perkenalan santai tentang Zig — bahasa sistem modern yang katanya pengganti C. Apa sih istimewanya?"
[taxonomies]
tags = ["zig", "programming", "systems", "bahasa", "llm"]
+++

## Zig itu apa sih?

oke jadi di blog kali ini aku mau bahas **Zig** nih. akhir-akhir ini kan lumayan sering muncul di timeline aku, sekilas denger namanya tuh kayak bahasa baru yang aneh gitu. tapi ternyata Zig ini bukan bahasa iseng loh, dia serius. sekarang udah versi **0.17.0**.

jadi singkatnya gini, Zig itu:

> bahasa pemrograman _general-purpose_ dan _toolchain_ buat bikin software yang **robust**, **optimal**, dan **reusable**.

nah kata kuncinya di situ. **robust** (gak gampang crash), **optimal** (cepet sama hemat resource), sama **reusable** (gampang dipake ulang di mana-mana).

Zig ini sering disebut-sebut sebagai _"pengganti C"_ di era modern. kenapa emang? ya karena dia emang dirancang buat bisa ngobrol sama kode C/C++ lama, tanpa harus buang semuanya dari awal.

---

## Nah kenapa Zig menarik?

ada beberapa alasan kenapa orang mulai ngelirik Zig. aku rangkum dari website resminya.

### 1. Bahasanya Simpel

filosofi utamanya tuh gini:

> _"Focus on debugging your application rather than debugging your programming language knowledge."_

artinya apa? artinya kamu gak perlu ngabisin waktu buat belajar "keajaiban" bahasa. di Zig tuh:

- **No hidden control flow** — apa yang kamu baca, itu yang jalan. gak ada magic.
- **No hidden memory allocations** — kamu tau persis kapan memory dialokasi.
- **No preprocessor, no macros** — gak ada `#define` yang bikin kepala pusing.

coba bandingin sama C++ yang penuh template sama macro tersembunyi. Zig tuh jujur. apa yang kamu tulis, itu yang terjadi. gitu.

### 2. Comptime (Compile-Time)

nah ini nih fitur andalan Zig. **Comptime** itu metaprogramming yang jalan di _compile-time_, bukan runtime.

maksudnya:

- kamu bisa panggil **fungsi apa aja** di compile-time.
- kamu bisa **manipulasi type** kayak nilai biasa, tanpa overhead runtime.
- comptime bisa **niru target architecture** — misal kamu mau compile buat ARM tapi lagi di x86, comptime bisa handle.

analoginya kayak gini: bayangin kamu bisa ngejalanin kode kamu di _dalam compiler_ sebelum program-nya beneran jalan. keren kan?

### 3. Bisa Dipake Buat Maintain C/C++

oke ini yang paling gila menurut aku. **Zig bisa jadi compiler C/C++ drop-in**.

jadi kalau kamu punya project C/C++ lama, kamu gak harus nulis ulang semuanya loh. tinggal:

- pake Zig sebagai compiler C/C++ **zero-dependency**, mendukung cross-compilation langsung.
- pake `zig build` buat bikin environment development yang konsisten di semua platform.
- tambahin unit Zig ke project C/C++ kamu, langsung dapet akses ke standard library Zig yang kaya.

jadi Zig itu bukan cuma bahasa baru ya, dia juga **toolchain** yang bisa hidup berdampingan sama C/C++.

---

## Contoh kode Zig

biar ada gambaran, ini snippet kecil dari website Zig. parsing integer pake `std.fmt.parseInt`:

```zig
const std = @import("std");
const parseInt = std.fmt.parseInt;

test "parse integers" {
    const input = "123 67 89,99";
    const gpa = std.testing.allocator;

    var list: std.ArrayList(u32) = .empty;
    // Pastikan list dibebaskan saat scope keluar.
    // Coba comment baris ini!
    defer list.deinit(gpa);

    var it = std.mem.tokenizeAny(u8, input, " ,");
    while (it.next()) |num| {
        const n = try parseInt(u32, num, 10);
        try list.append(gpa, n);
    }

    const expected = [_]u32{ 123, 67, 89, 99 };

    for (expected, list.items) |exp, actual| {
        try std.testing.expectEqual(exp, actual);
    }
}
```

jalanin test-nya:

```sh
$ zig test index.zig
1/1 index.test.parse integers...OK
All 1 tests passed.
```

perhatiin beberapa hal menarik:

- `defer list.deinit(gpa);` — ini kayak RAII tapi eksplisit. pastiin kamu free memory-nya.
- `try` — error handling-nya jelas, gak ada exception tersembunyi.
- `@import`, `@` prefix — builtin function di Zig pake `@`.

---

## Komunitas Zig

nah kalau soal komunitas, Zig itu **desentralisasi**. gak ada yang namanya "official" atau "unofficial" — tiap tempat kumpul punya moderator sama aturannya masing-masing.

- **Repo utama:** [codeberg.org/ziglang/zig](https://codeberg.org/ziglang/zig) — di sini juga ada issue tracker sama diskusi proposal.
- kontributor diharapkan ngikutin **Zig's Code of Conduct**.

---

## Zig Software Foundation (ZSF)

Zig punya yayasan sendiri nih, namanya **Zig Software Foundation**. didirikan tahun 2020 sama **Andrew Kelley** (pencipta Zig). statusnya 501(c)(3) non-profit.

tujuan ZSF:

- support pengembangan bahasa Zig.
- bisa bayar core contributor dengan rate kompetitif.
- ke depannya, semoga bisa bayar lebih banyak contributor.

ZSF hidup dari **donasi**. jadi kalau kamu ngerasa Zig berguna, bisa pertimbangin buat dukung.

---

## Belajar Zig dari mana?

kalau kamu tertarik, ini resource yang bisa dipake:

**Dokumentasi:**

- **Unstable (master)** — Language Reference, std lib, platform support
- **Latest Stable (0.17.0)** — sama, tapi versi stabil

**Guides:**

- [Zig Build System](https://ziglang.org/learn/build-system/) — intro ke build system Zig

**Pengantar:**

- **In-depth Overview** — fitur-fitur Zig dari perspektif systems programming
- **Why Zig When There is Already C++, D, and Rust?** — buat kamu yang udah kenal bahasa lain
- **Code Examples** — kumpulan snippet
- **Tools** — daftar tool bantu nulis Zig

**Getting started:**

- panduan setup environment

**Online learning:**

- [Introduction to Zig](https://pedropark99.github.io/zig-book/) — buku project-based, open & technical
- [zig.guide](https://zig.guide/) — intro terstruktur oleh Sobeston
- [Ziglings](https://codeberg.org/ziglings/exercises/) — belajar Zig dengan fix program kecil yang rusak
- [Zig on Exercism](https://exercism.org/tracks/zig) — coding exercise + mentoring

**Video & blog:**

- [Road to Zig 1.0](https://www.youtube.com/watch?v=Gv2I7qTux7g) — Andrew Kelley sendiri yang jelasin filosofi Zig

---

## Kesimpulan

jadi intinya Zig itu bahasa sistem yang:

- **Simpel** — gak ada magic, semua eksplisit
- **Kuat** — comptime, cross-compilation, C/C++ interop
- **Jujur** — apa yang kamu tulis, itu yang jalan

buat kamu yang suka ngoprek low-level tapi males sama kompleksitas C++ atau Rust yang kadang bikin pusing, Zig ini kandidat serius buat dicoba.

aku sendiri baru mulai baca-baca sih, belum sampai beneran nulis project. tapi dari dokumentasinya aja, vibe-nya udah beda — kayak ngobrol sama programmer yang gak sok pinter, tapi jelas sama to-the-point.

ya udah segitu dulu blog kali ini. kalau kamu udah pernah coba Zig, share dong di komentar (eh, gak ada komentar sih ini blog 😅). mungkin next time aku bakal nulis tentang build system-nya atau comptime lebih dalam.

sampai jumpa di post berikutnya!