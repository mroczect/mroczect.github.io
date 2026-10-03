+++
title = "Zig Build System: Panduan Lengkap dari Nol Sampai Mahir (LLM VERSION)"
date = 2026-10-03
description = "Belajar Zig Build System dari awal — dari hello world, static library, sampe multi-target release. Lengkap dengan contoh kode."
[taxonomies]
tags = ["zig", "programming", "build-system", "tutorial", "llm"]
+++

## Zig Build System itu apa sih?

oke jadi di blog kali ini aku mau bahas **Zig Build System** nih. ini salah satu fitur Zig yang paling berguna tapi sering diabaikan pemula.

jadi gini, sebenernya kamu bisa build project Zig cuma pakai command dasar kayak:

```sh
zig build-exe hello.zig
zig build-lib hello.zig
zig build-obj hello.zig
zig test hello.zig
```

itu udah cukup buat project kecil. tapi begitu project kamu mulai gede, kamu bakal butuh sesuatu yang lebih.

### Kapan harus pindah ke Build System?

pindah ke build system kalau:

- **Command line-nya udah kepanjangan** dan kamu mau nyimpen di suatu tempat biar nggak nulis ulang tiap kali.
- **Kamu mau build banyak hal** sekaligus.
- **Kamu mau caching dan concurrency** biar build lebih cepet.
- **Kamu mau expose config options** ke user.
- **Build process beda-beda** tergantung target OS.
- **Kamu punya dependencies** ke project lain.
- **Kamu mau avoid dependency** ke cmake, make, shell, msvc, python, dll.
- **Kamu mau bikin package** yang bisa dipakai orang lain.
- **Kamu mau IDE bisa ngerti** cara build project kamu.

kalau salah satu dari itu kena, mending pakai Build System.

---

## 1. Getting Started: Hello World

### Simple Executable

mulai dari yang paling gampang. bikin dua file:

**hello.zig:**

```zig
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});
}
```

**build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("hello.zig"),
            .target = b.graph.host,
        }),
    });

    b.installArtifact(exe);
}
```

terus jalanin:

```sh
$ zig build --summary all
Build Summary: 3/3 steps succeeded
install success
+- install hello success
   +- compile exe hello debug native success 694ms MaxRSS:152M
```

hasilnya di folder `zig-out/bin/hello`.

### Penjelasan struktur folder

setelah build, kamu bakal punya:

```
├── build.zig
├── hello.zig
├── .zig-cache
└── zig-out
    └── bin
        └── hello
```

ada 2 folder yang dibuat otomatis:

- **`.zig-cache`** — isinya file cache yang bikin build berikutnya lebih cepet. **jangan** di-commit ke git. folder ini bisa dihapus kapan aja tanpa efek samping.
- **`zig-out`** — "installation prefix". ini yang nanti isinya hasil build kamu. user bisa ganti lokasinya pakai `--prefix`.

### Installing Build Artifacts

Zig build system itu modelnya **Directed Acyclic Graph (DAG)**. setiap step bisa jalan independen dan concurrent.

default-nya, step utama namanya **Install**. fungsinya copy build artifacts ke tempat final.

di contoh di atas, `b.installArtifact(exe)` nambahin exe ke daftar yang mau di-install.

### Adding a Run Step

biasanya project punya step `run` biar bisa langsung jalanin aplikasinya:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("hello.zig"),
            .target = b.graph.host,
        }),
    });

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
```

sekarang kamu bisa:

```sh
$ zig build run
Hello World!
```

---

## 2. The Basics: User Options

### User-Provided Options

kamu bisa bikin build script kamu configurable pakai `b.option`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const windows = b.option(bool, "windows", "Target Microsoft Windows") orelse false;

    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("example.zig"),
            .target = b.resolveTargetQuery(.{
                .os_tag = if (windows) .windows else null,
            }),
        }),
    });

    b.installArtifact(exe);
}
```

terus kalau kamu jalanin `zig build --help`, bakal muncul:

```
Project-Specific Options:
  -Dwindows=[bool]             Target Microsoft Windows
```

nah user bisa pake `-Dwindows=true` atau `-Dwindows=false`.

### Standard Configuration Options

tapi daripada bikin option sendiri-sendiri, mending pakai helper function bawaan Zig:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("hello.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);
}
```

sekarang user bisa:

```sh
$ zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall
```

dan di `--help` bakal muncul:

```
Project-Specific Options:
  -Dtarget=[string]            The CPU architecture, OS, and ABI to build for
  -Dcpu=[string]               Target CPU features to add or subtract
  -Doptimize=[enum]            Prioritize performance, safety, or binary size
                                 Supported Values:
                                   Debug
                                   ReleaseSafe
                                   ReleaseFast
                                   ReleaseSmall
```

### Options for Conditional Compilation

buat kirim options dari build script ke kode Zig, pakai `Options` step:

**app.zig:**

```zig
const std = @import("std");
const config = @import("config");

const semver = std.SemanticVersion.parse(config.version) catch unreachable;

extern fn foo_bar() void;

pub fn main() !void {
    if (semver.major < 1) {
        @compileError("too old");
    }
    std.debug.print("version: {s}\n", .{config.version});

    if (config.have_libfoo) {
        foo_bar();
    }
}
```

**build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("app.zig"),
            .target = b.graph.host,
        }),
    });

    const version = b.option([]const u8, "version", "application version string") orelse "0.0.0";
    const enable_foo = detectWhetherToEnableLibFoo();

    const options = b.addOptions();
    options.addOption([]const u8, "version", version);
    options.addOption(bool, "have_libfoo", enable_foo);

    exe.root_module.addOptions("config", options);

    b.installArtifact(exe);
}
```

jalanin:

```sh
$ zig build -Dversion=1.2.3
```

karena `@import("config").version` itu comptime-known, `@compileError` nggak akan ke-trigger.

---

## 3. Static Library

bikin static library dari Zig code:

**fizzbuzz.zig:**

```zig
export fn fizzbuzz(n: usize) ?[*:0]const u8 {
    if (n % 5 == 0) {
        if (n % 3 == 0) {
            return "fizzbuzz";
        } else {
            return "fizz";
        }
    } else if (n % 3 == 0) {
        return "buzz";
    }
    return null;
}
```

**demo.zig:**

```zig
const std = @import("std");
const Io = std.Io;

extern fn fizzbuzz(n: usize) ?[*:0]const u8;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buf: [1024]u8 = undefined;
    const file_writer = Io.File.stdout().writer(io, &buf);
    const w = &file_writer.interface;
    for (0..100) |n| {
        if (fizzbuzz(n)) |s| {
            try w.print("{s}\n", .{s});
        } else {
            try w.print("{d}\n", .{n});
        }
    }
    try w.flush();
}
```

**build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libfizzbuzz = b.addLibrary(.{
        .name = "fizzbuzz",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("fizzbuzz.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const exe = b.addExecutable(.{
        .name = "demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("demo.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.linkLibrary(libfizzbuzz);

    b.installArtifact(libfizzbuzz);

    if (b.option(bool, "enable-demo", "install the demo too") orelse false) {
        b.installArtifact(exe);
    }
}
```

default-nya cuma static library yang di-install:

```
zig-out/
└── lib
    └── libfizzbuzz.a
```

kalau pakai `-Denable-demo`, baru exe-nya ikut:

```
zig-out/
├── bin
│   └── demo
└── lib
    └── libfizzbuzz.a
```

**catatan penting:** walaupun `addExecutable` dipanggil tanpa kondisi, build system **nggak akan build** exe-nya kalau nggak diminta. karena DAG-based.

---

## 4. Dynamic Library

tinggal ganti `linkage = .dynamic` dan tambahin versi:

```zig
const libfizzbuzz = b.addLibrary(.{
    .name = "fizzbuzz",
    .linkage = .dynamic,
    .version = .{ .major = 1, .minor = 2, .patch = 3 },
    .root_module = b.createModule(.{
        .root_source_file = b.path("fizzbuzz.zig"),
        .target = target,
        .optimize = optimize,
    }),
});
```

hasilnya:

```
zig-out
└── lib
    ├── libfizzbuzz.so -> libfizzbuzz.so.1
    ├── libfizzbuzz.so.1 -> libfizzbuzz.so.1.2.3
    └── libfizzbuzz.so.1.2.3
```

buat link exe ke dynamic library, sama aja:

```zig
exe.linkLibrary(libfizzbuzz);
```

---

## 5. Testing

test individual file bisa langsung:

```sh
zig test foo.zig
```

tapi kalau pake build system, bisa lebih powerful.

di build system, unit test itu dibagi jadi 2 step: **Compile** dan **Run**. tanpa `addRunArtifact`, test-nya nggak akan dijalanin.

**main.zig:**

```zig
const std = @import("std");

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit();
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
```

**build.zig:**

```zig
const std = @import("std");

const test_targets = [_]std.Target.Query{
    .{}, // native
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
    .{
        .cpu_arch = .aarch64,
        .os_tag = .macos,
    },
};

pub fn build(b: *std.Build) void {
    const test_step = b.step("test", "Run unit tests");

    for (test_targets) |target| {
        const unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("main.zig"),
                .target = b.resolveTargetQuery(target),
            }),
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);
        run_unit_tests.skip_foreign_checks = true;
        test_step.dependOn(&run_unit_tests.step);
    }
}
```

jalanin dengan:

```sh
$ zig build test
```

**catatan:** kalau ngetest buat target yang beda dari host (misal test aarch64-macos dari x86_64-linux), perlu QEMU atau emulator lain. `skip_foreign_checks = true` bikin step-nya di-skip kalau nggak bisa dijalanin.

---

## 6. Linking to System Libraries

ada 2 cara depend ke library:

1. **Via Zig Build System** — pakai package management.
2. **Via system files** — pakai yang udah ada di sistem.

buat upstream maintainer, cara pertama lebih bagus karena hasilnya reproducible dan cross-compilation-nya jalan.

tapi buat packaging (Debian, Homebrew, Nix), wajib pakai system libraries.

contoh:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "zip",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zip.zig"),
            .target = b.graph.host,
            .link_libc = true,
        }),
    });

    exe.root_module.linkSystemLibrary("z", .{});

    b.installArtifact(exe);
}
```

user bisa nambahin search path pakai `--search-prefix`.

---

## 7. Generating Files

### Running System Tools

kadang kamu perlu generate file dari tool sistem. contoh: pakai `jq` buat parse JSON:

**words.json:**

```json
{
	"en": "world",
	"it": "mondo",
	"ja": "世界"
}
```

**build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const lang = b.option([]const u8, "language", "language of the greeting") orelse "en";
    const tool_run = b.addSystemCommand(&.{"jq"});
    tool_run.addArgs(&.{
        b.fmt(
            \\.["{s}"]
        , .{lang}),
        "-r",
    });
    tool_run.addFileArg(b.path("words.json"));

    const output = tool_run.captureStdOut();

    b.getInstallStep().dependOn(&b.addInstallFileWithDir(output, .prefix, "word.txt").step);

    // ... sisanya build exe
}
```

hasilnya:

```
zig-out
├── hello
└── word.txt
```

**tapi hati-hati:** depend ke `jq` bikin project kamu susah di-build. mendingan pakai tool Zig sendiri.

### Running the Project's Tools

ganti `jq` sama tool Zig sendiri. lebih portable.

**tools/word_select.zig:**

```zig
const std = @import("std");
const Io = std.Io;

const usage =
    \\Usage: ./word_select [options]
    \\
    \\Options:
    \\  --input-file INPUT_JSON_FILE
    \\  --output-file OUTPUT_TXT_FILE
    \\  --lang LANG
    \\
;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);

    var opt_input_file_path: ?[]const u8 = null;
    var opt_output_file_path: ?[]const u8 = null;
    var opt_lang: ?[]const u8 = null;

    // parse args...

    // baca JSON, tulis output
}
```

**build.zig:**

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const lang = b.option([]const u8, "language", "language of the greeting") orelse "en";
    const tool = b.addExecutable(.{
        .name = "word_select",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/word_select.zig"),
            .target = b.graph.host,
        }),
    });

    const tool_step = b.addRunArtifact(tool);
    tool_step.addArg("--input-file");
    tool_step.addFileArg(b.path("tools/words.json"));
    tool_step.addArg("--output-file");
    const output = tool_step.addOutputFileArg("word.txt");
    tool_step.addArgs(&.{ "--lang", lang });

    // ... sisanya
}
```

### Producing Assets for @embedFile

kalau kamu mau embed file yang di-generate ke binary:

**main.zig:**

```zig
const std = @import("std");
const word = @embedFile("word");

pub fn main() !void {
    std.log.info("Hello {s}\n", .{word});
}
```

**build.zig:**

```zig
    exe.root_module.addAnonymousImport("word", .{
        .root_source_file = output,
    });
```

### Generating Zig Source Code

bisa juga generate file `.zig` dan expose sebagai module:

**build.zig:**

```zig
    exe.root_module.addAnonymousImport("person", .{
        .root_source_file = output,
    });
```

**main.zig:**

```zig
const std = @import("std");
const Person = @import("person").Person;

pub fn main() !void {
    const p: Person = .{};
    std.log.info("Hello {any}\n", .{p});
}
```

---

## 8. Dealing With Generated Files

### WriteFiles Step

buat generate banyak file yang share parent directory:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
        }),
    });

    const version = b.option([]const u8, "version", "application version string") orelse "0.0.0";

    const wf = b.addWriteFiles();
    const app_exe_name = b.fmt("project/{s}", .{exe.out_filename});
    _ = wf.addCopyFile(exe.getEmittedBin(), app_exe_name);
    _ = wf.add("project/version.txt", version);

    const tar = b.addSystemCommand(&.{ "tar", "czf" });
    tar.setCwd(wf.getDirectory());
    const out_file = tar.addOutputFileArg("project.tar.gz");
    tar.addArgs(&.{"project/"});

    const install_tar = b.addInstallFileWithDir(out_file, .prefix, "project.tar.gz");
    b.getInstallStep().dependOn(&install_tar.step);
}
```

hasilnya: `zig-out/project.tar.gz`.

---

## 9. Mutating Source Files in Place

### UpdateSourceFiles

kadang project commit generated files ke version control. ini berguna kalau file-nya jarang update tapi dependensinya susah.

**build.zig:**

```zig
    const proto_gen = b.addExecutable(.{
        .name = "proto_gen",
        .root_source_file = b.path("tools/proto_gen.zig"),
        .target = target,
    });

    const run = b.addRunArtifact(proto_gen);
    const generated_protocol_file = run.addOutputFileArg("protocol.zig");

    const wf = b.addUpdateSourceFiles();
    wf.addCopyFileToSource(generated_protocol_file, "src/protocol.zig");

    const update_protocol_step = b.step("update-protocol", "update src/protocol.zig to latest");
    update_protocol_step.dependOn(&wf.step);
```

jalanin:

```sh
$ zig build update-protocol
```

nah `src/protocol.zig` bakal ke-update in place.

**hati-hati:** ini **jangan** dipakai di build process normal. cuma buat utility yang dijalanin manual sama developer.

---

## 10. Handy Example: Build for Multiple Targets

bikin release untuk banyak target sekaligus:

```zig
const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
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

satu command, lima target. gila kan?

---

## Kesimpulan

Zig Build System itu powerful banget. yang paling penting:

- **Mulai dari simpel** — `build.zig` dengan `addExecutable` aja udah cukup.
- **Pakai helper bawaan** — `standardTargetOptions` dan `standardOptimizeOption` bikin konsisten.
- **Manfaatkan DAG** — build system cuma build yang perlu aja.
- **Bisa generate file** — dari system tools atau dari tool Zig sendiri.
- **Multi-target** — satu `build.zig` bisa build buat banyak platform.

kalau kamu baru mulai, saran aku:

1. Bikin project `hello world` pakai build system.
2. Tambahin `run` step.
3. Coba `standardTargetOptions`.
4. Coba bikin static library.
5. Coba multi-target release.

udah, itu aja. nanti kamu bakal nemu sendiri fitur-fitur lain yang lebih canggih.

ya udah segitu dulu blog kali ini. kalau ada yang bingung, tanya aja di komentar (eh, gak ada komentar 😅). sampai jumpa di post berikutnya!

---

**Referensi:** Dokumentasi resmi [Zig Build System](https://ziglang.org/learn/build-system/).