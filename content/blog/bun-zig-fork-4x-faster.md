+++
title = "Bun Fork Zig, Dapet Compile 4x Lebih Cepat — Tapi Ada Twist"
date = 2026-10-03
description = "Bun bikin fork Zig dengan parallel semantic analysis + multiple codegen units. Hasilnya 4x lebih cepat. Tapi kenapa nggak di-upstream ke Zig? Ini ceritanya."
[taxonomies]
tags = ["zig", "bun", "compiler", "llvm", "ai"]
+++

## Jadi ceritanya...

beberapa waktu lalu, tim **Bun** (JavaScript runtime yang ditulis pakai Zig) ngumumin sesuatu yang lumayan gede: mereka bikin **fork Zig** sendiri, dan hasilnya **debug build 4x lebih cepat**.

cara mereka:

- **parallel semantic analysis** — analisis kode dijalanin paralel, bukan satu-satu
- **multiple codegen units** di LLVM backend (macOS + Linux)

hasilnya: build internal mereka jadi jauh lebih cepet. buat tim yang iterasi puluhan kali sehari, ini game changer.

tapi... ada twist.

---

## Twist-nya: Kode Nya Dibuat dengan Bantuan AI

ini bagian yang bikin diskusi di forum Ziggit jadi rame.

masalahnya bukan hasilnya. hasilnya bagus. masalahnya: **kode itu dihasilkan dengan bantuan AI (LLM)**.

dan Zig punya **AI policy** yang cukup jelas: **kode yang dihasilkan AI nggak boleh di-upstream ke repo utama Zig**.

jadi walaupun hasilnya bagus, kode itu **nggak akan masuk ke Zig upstream**.

---

## Reaksi Komunitas

reaksi di forum Ziggit campur-campur. ada yang bilang:

> "I don't usually engage with AI posts, but honestly this is awesome results by Bun's team."
> — Karim MK, pembuka thread

ada juga yang lebih skeptis:

> "I actually find it telling that the Bun devs don't feel like putting in whatever extra time it would take to vet/edit their own code so that they could propose it for upstreaming into Zig and stand behind it as their own."
> — theo

dan ada yang tegas:

> "It doesn't matter how much they vetted/edited it. It was produced with the help of AI and per Zig's Code of Conduct it wouldn't be welcomed."
> — wbrian

intinya: **bukan soal kualitas kode**, tapi soal **proses**. Zig memilih untuk nggak menerima kode AI, apapun kualitasnya.

---

## Tapi Tunggu — Kenapa Bun Nggak Pakai Solusi yang Udah Ada?

ini pertanyaan bagus yang muncul di thread. **mlugg** (Matthew Lugg, anggota tim inti Zig) jawab dengan panjang lebar.

### 1. Zig udah punya self-hosted backend yang lebih cepet

sejak Zig 0.15.x, **self-hosted x86_64 backend** udah jadi default. artinya kalau kamu upgrade dari 0.14.x ke 0.15.x, kamu **udah otomatis dapet 4x peningkatan** — sama kayak yang Bun klaim.

jadi... kenapa Bun nggak upgrade aja?

### 2. Incremental compilation

selain backend baru, Zig juga punya **incremental compilation**. ini bisa bikin perbedaan besar, terutama kalau kamu lagi fix banyak error. hasilnya: daftar error yang di-update **hampir instan**.

cara pakainya:

```sh
zig build -fincremental --watch
```

### 3. Build subset aplikasi

kalau kamu cuma mau test satu bagian aplikasi, kamu **nggak perlu build semuanya**. pakai fitur lazy analysis Zig, kamu bisa bikin "feature flag" yang bikin compiler cuma analisis kode yang perlu.

contoh implementasi dari mlugg:

```zig
const enabled_features: std.enums.EnumSet(Feature) = .initMany(&.{
    foo, bar,
});

pub const Feature = enum {
    foo,
    bar,
    qux,

    pub fn check(f: Feature) if (enabled_features.contains(f)) void else noreturn {
        if (enabled_features.contains(f)) return;
        std.debug.panic("feature '{t}' is disabled in this build", .{f});
    }
};

// contoh pakai:
fn doFoo() void {
    Feature.check(.foo);
    // kode di sini cuma dianalisis kalau `Feature.foo` diaktifin
}
```

ini yang dipakai tim Zig sendiri. mereka bisa pass `-Ddev=x86_64-linux` buat build compiler yang cuma support backend x86_64 self-hosted + ELF linker. hasilnya: binary lebih kecil, compile lebih cepet, kadang **5x lebih cepet** di LLVM Emit Object.

---

## Kenapa Pendekatan Bun Nggak Cocok Buat Release Build

ini penjelasan teknis dari mlugg yang penting banget.

### Masalahnya: LLVM module itu independen

waktu kamu split bitcode ke beberapa LLVM module, tiap module **dianalisis, dioptimasi, dan di-codegen secara independen**. artinya: **LLVM nggak bisa optimasi lintas batas module**.

di bahasa yang punya batas natural (kayak Rust crate), ini mungkin nggak masalah. tapi pendekatan Bun: **split function ke N LLVM module berdasarkan hash nama function**. artinya batas optimasinya **pseudo-random**.

> "which makes the optimization boundaries quite literally pseudo-random"
> — mlugg

kalau kamu lagi test optimization, kamu **nggak mau** optimization-nya berubah random tiap build. hasil benchmark-nya jadi nggak konsisten.

### Solusinya: build subset aja

kalau kamu cuma mau test bagian kecil, build bagian itu aja. jangan split-random.

---

## Diskusi Teknis: Thin LTO vs Full LTO

bagian ini melibatkan **matklad** (Alex Kladov, developer Rust analyzer) yang ikut nimbrung.

### Klarifikasi dari matklad

dia bilang:

> "I believe that even with multiple LLVM codegen units, it still can do thin-lto across them."

jadi bukan cuma dua pilihan: "semua dalam satu tumpukan" atau "banyak tumpukan independen". ada **middle ground**: thin-LTO, di mana codegen mostly independen + paralel, tapi unit-summary tetap dihitung buat **cross-unit inlining terbatas**.

### Tentang Rust crate

matklad juga klarifikasi: **"crate" di Rust itu bukan benar-benar satu compilation unit**. waktu compile, crate di-split jadi **multiple codegen-units** untuk LLVM. dan split itu **bukan sesuatu yang user kontrol**.

ini yang akhirnya jadi **map-reduce**: codegen mostly independen, tapi ada unit-summary untuk inlining lintas unit.

### Empat mode LTO di Rust

matklad jelasin ada 4 mode:

1. **No LTO** — default `Debug` build
2. **Thin local LTO** — codegen unit dalam satu crate di-LTO satu sama lain, crate nggak di-LTO. ini default `Release` build.
3. **Thin LTO** — semua di-thin-LTO. ini yang **seharusnya** jadi default `Release` build, karena model kompilasi ini yang "sane" buat bahasa zero-cost abstraction dengan separate compilation.
4. **Full LTO** — compilation step secara moral cuma `cat` semua source jadi satu, compiler "ngumpet" di linker. butuh RAM puluhan GB.

### mlugg setuju... tapi push back dikit

dia jawab:

> "Perhaps I'm underestimating how effective thin LTO is, but to me, full LTO seems like the 'correct' way to do this."

argumen mlugg: **fundamentally, saya nggak mau ngasih optimization opportunities cuma karena module split yang semi-arbitrary**.

solusi kayak thin LTO, menurut dia, terasa kayak **workaround** untuk framework optimasi LLVM yang nggak scale dengan baik.

dia juga bilang: **the component which best knows where those boundaries would be placed is LLVM itself**. LLVM bisa mulai dengan efficient passes full-LTO-style, terus consider call graph, terus tentuin partisi terbaik.

dan lucunya: itu **persis** yang terjadi di Rust backend parallelism (yang di-link matklad).

---

## Pendapat dari Anggota Lain

### Chung Leong

> "I certainly wouldn't mind if an AI would look at a bug report and automatically generate the exact steps to reproduce it."

jadi: AI boleh dipakai buat **hal-hal lain** (kayak deteksi bug, code review, auto-generate reproduction steps), tapi **bukan buat nulis kode yang masuk upstream**.

### IntegratedQuantum

dia setuju soal pentingnya faster LLVM backend, terutama untuk release build:

> "I often need to make release builds when testing an optimization, and waiting two minutes... every time I make a change is kind of annoying."

tapi dia juga sadar build subset nggak selalu feasible. contoh kasusnya: **game**. kalau mau test block updates di client, butuh banyak fitur sekaligus (asset loading, server ticks, networking, mesh generation, world generation, gui). "lebih cepet nunggu 2 menit daripada ngisolasi semua module itu."

dia saran: **`@setRuntimeSafety` → `@optimizeFor`** (issue #978). ini bakal bikin cepet buat ngetes bagian tertentu.

### wbrian

> "Yes, it only affects the scope in which it's set."

jadi `@setRuntimeSafety` cuma ngaruh di scope yang sama, bukan ke function yang dipanggil.

### xydone

dia lebih ke pertanyaan jangka panjang:

> "I wonder, what sort of plan do they have for evolving past 0.15, if any."

maksudnya: Bun fork Zig, terus upstream Zig jalan terus. gimana cara mereka maintain fork ini ke depannya? apalagi kalau mereka nambahin fitur kayak **private fields** yang nggak kompatibel sama Zig upstream.

dia penutup:

> "Best of luck to whoever has to maintain it."

### DigitalGems9000

dan ini quote yang paling puitis:

> "remember that feeling when some cracked out dev submits a PR and it gets merged, and you're like holy sh*t dave, great job! we need to cherish those moments not only from the past, but for the future! why let AI rob an awesome human experience that we get only a few times in life? when our lives are bounded by time which is gold"

jadi: momen ketika developer lain submit PR keren dan di-merge, itu **pengalaman manusia yang berharga**. kenapa mau dirampas sama AI?

---

## Kesimpulan

jadi ceritanya:

1. **Bun fork Zig**, tambahin parallel semantic analysis + multiple codegen units
2. hasilnya: **4x lebih cepet** debug build
3. **tapi** kode-nya dibuat dengan bantuan AI, jadi nggak bisa di-upstream ke Zig
4. **mlugg** jelasin kenapa pendekatan Bun nggak cocok buat release build (bikin optimasi jadi pseudo-random)
5. **matklad** klarifikasi soal thin-LTO vs full LTO di Rust
6. diskusi jadi lebih luas: soal AI policy, maintainability fork, dan "human experience"

poin yang paling penting menurut aku:

- **Zig udah punya solusinya**: self-hosted backend (default sejak 0.15.x) + incremental compilation + build subset
- **AI policy bukan soal kualitas**, tapi soal proses dan trust
- **Fork bukan solusi jangka panjang** kalau upstream-nya terus jalan
- **Optimization boundaries itu masalah kompleks** — dan solusi terbaik mungkin bukan thin LTO atau full LTO, tapi LLVM yang lebih pintar

---

## Sumber

Diskusi lengkapnya di [Ziggit — Bun's Zig fork got 4x faster compilation times](https://ziggit.dev/t/bun-s-zig-fork-got-4x-faster-compilation-times/15183).

Quote dari: mlugg, matklad, theo, wbrian, IntegratedQuantum, Chung Leong, xydone, DigitalGems9000, dan lain-lain.
