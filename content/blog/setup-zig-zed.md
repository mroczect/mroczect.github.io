+++
title = "Setup Zig di Zed: ZLS, ZVM, dan Alias Update Sekali Jalan"
date = 2026-10-03
description = "Ini setup Zig aku di Zed editor — dari konfigurasi ZLS, manajemen versi pakai ZVM, sampe alias buat update Zig + ZLS sekali jalan."
[taxonomies]
tags = ["zig", "zed", "zls", "setup", "dotfiles", "llm"]
+++

## Setup Zig aku di Zed

oke jadi di blog kali ini aku mau share **setup Zig aku di Zed**. ini bukan tutorial lengkap dari nol ya, tapi lebih ke "ini loh yang aku pakai sehari-hari". mungkin ada yang bisa kamu contek, mungkin ada yang bisa kamu improve.

singkatnya setup aku:

- **Editor:** Zed
- **Zig:** master branch, dikelola pakai ZVM
- **ZLS:** build sendiri dari source, di-update manual
- **Shell:** zsh + oh-my-zsh
- **OS:** Fedora Linux 44

langsung aja.

---

## 1. Lingkungan Kerja

buat konteks, ini spec laptop aku:

```

OS: Fedora Linux 44 (Workstation Edition) x86_64
Kernel: Linux 7.2.7-200.fc44.x86_64
Shell: zsh 5.9
Desktop Environment: GNOME 50.5
Window Manager: Mutter (Wayland)
Terminal: zed-editor
CPU: Intel Core i7-9750H (12) @ 4.50 GHz
GPU 1: NVIDIA Quadro T2000 Mobile / Max-Q [Discrete]
GPU 2: Intel UHD Graphics 630 @ 1.15 GHz [Integrated]
Memory: 15.62 GiB / 30.98 GiB (50%)
Disk: 129.32 GiB / 474.35 GiB (27%) - btrfs
Locale: en_US.UTF-8

```

ThinkPad P53, i7-9750H, RAM 32GB, Fedora Workstation. terminalnya pake Zed editor langsung — enak buat aku karena bisa coding + shell dalam satu window.

---

## 2. Manajemen Versi Zig: ZVM

aku pakai **ZVM** (Zig Version Manager) buat manage versi Zig. ini mirip `nvm` buat Node.js atau `rustup` buat Rust.

kenapa pakai ZVM?

- **gampang ganti versi** — bisa pindah antara master, stable, atau versi tertentu.
- **nggak perlu install manual** — tinggal `zvm install`.
- **bisa punya beberapa versi** — project lama pake versi lama, project baru pake master.

path ZVM aku:

```sh
# Binary zvm
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$ZVM_INSTALL:$PATH"

# Symlink zig versi aktif
export PATH="$HOME/.local/share/zvm/bin:$PATH"
```

jadi binary `zig` yang aktif itu symlink ke `~/.local/share/zvm/master/zig`.

kalau mau install versi baru:

```sh
zvm install --force master
```

---

## 3. ZLS: Zig Language Server

**ZLS** itu Language Server buat Zig. fungsinya buat autocomplete, go-to-definition, diagnostics, inlay hints, dll. tanpa ZLS, Zed cuma jadi text editor biasa buat Zig.

aku build ZLS sendiri dari source, bukan pakai binary release. kenapa? karena:

- **cocok sama versi Zig master** — binary release kadang nggak sinkron sama Zig master.
- **bisa update kapan aja** — tinggal `git pull` terus build ulang.
- **dapet fitur terbaru** — termasuk yang belum masuk release.

lokasi ZLS aku:

```sh
# Arahkan ke ZLS master yang cocok dengan Zig 0.17.0-dev
export PATH="$HOME/.zls/master:$PATH"
```

jadi binary ZLS ada di `~/.zls/master/zls`.

---

## 4. Konfigurasi ZLS

ini config ZLS aku. taruh di `~/.config/zls.json`:

```json
{
	"$schema": "https://raw.githubusercontent.com/zigtools/zls/refs/heads/master/schema.json",
	"zig_exe_path": "/home/mroczect/.local/share/zvm/master/zig",
	"semantic_tokens": "full",
	"enable_snippets": true,
	"enable_argument_placeholders": true,
	"completion_label_details": true,
	"enable_build_on_save": true,
	"build_on_save_args": ["check"],
	"inlay_hints_show_variable_type_hints": true,
	"inlay_hints_show_struct_literal_field_type": true,
	"inlay_hints_show_parameter_name": true,
	"inlay_hints_show_builtin": false,
	"inlay_hints_exclude_single_argument": true,
	"inlay_hints_hide_redundant_param_names": true,
	"inlay_hints_hide_redundant_param_names_last_token": true,
	"warn_style": true,
	"highlight_global_var_declarations": true,
	"prefer_ast_check_as_child_process": true,
	"force_autofix": false
}
```

### Penjelasan tiap option

**`$schema`** — JSON schema buat validasi. bikin editor bisa autocomplete option ZLS.

**`zig_exe_path`** — path ke binary Zig. aku arahin ke master ZVM.

**`semantic_tokens: "full"`** — aktifin semantic highlighting. jadi kode kamu warnanya lebih kaya (keyword, function, type, dll dibedain).

**`enable_snippets: true`** — aktifin snippets. ketik `fn` terus Tab, langsung jadi `fn name() void {}`.

**`enable_argument_placeholders: true`** — waktu autocomplete function, argumennya langsung muncul placeholder. jadi kamu tinggal Tab buat isi.

**`completion_label_details: true`** — label autocomplete nampilin detail (tipe, signature, dll).

**`enable_build_on_save: true`** — setiap save file, ZLS bakal jalanin `zig build check`. jadi kamu tau langsung kalau ada error.

**`build_on_save_args: ["check"]`** — argumen yang dipake buat build-on-save. di sini aku pake `check` biar cuma compile-check, bukan full build.

**`inlay_hints_show_variable_type_hints: true`** — nampilin tipe variabel sebagai hint di samping kode.

contoh:

```zig
const x = 42;  // : i32  ← ini hint
```

**`inlay_hints_show_struct_literal_field_type: true`** — nampilin tipe field waktu nulis struct literal.

**`inlay_hints_show_parameter_name: true`** — nampilin nama parameter di pemanggilan function.

**`inlay_hints_show_builtin: false`** — aku matiin hint buat builtin function, karena bikin rame.

**`inlay_hints_exclude_single_argument: true`** — kalau function cuma punya 1 argumen, hint-nya nggak muncul.

**`inlay_hints_hide_redundant_param_names: true`** — kalau nama parameter sama kayak nama variabel yang dikirim, hint-nya disembunyiin.

**`warn_style: true`** — aktifin warning buat style issue (kayak `var` yang harusnya `const`).

**`highlight_global_var_declarations: true`** — highlight global variable declarations biar gampang keliatan.

**`prefer_ast_check_as_child_process: true`** — pakai AST check sebagai child process. ini bikin ZLS lebih cepet dan nggak blocking.

**`force_autofix: false`** — aku matiin ini biar nggak ada autofix yang gak sengaja ngubah kode.

---

## 5. Konfigurasi Zed buat Zig

selain ZLS config, aku juga set config Zed buat Zig. di `~/.config/zed/settings.json`:

```json
"lsp": {
  "zls": {
    "binary": {
      "path": "/home/mroczect/.zls/master/zls"
    },
    "settings": {
      "zls": {
        "enable_snippets": true,
        "enable_argument_placeholders": true,
        "completion_label_details": true,
        "enable_build_on_save": true,
        "build_on_save_args": [],
        "semantic_tokens": "combined",
        "inlay_hints_show_variable_type_hints": true,
        "inlay_hints_show_struct_literal_field_type": true,
        "inlay_hints_show_parameter_name": true,
        "inlay_hints_show_builtin": true,
        "inlay_hints_exclude_single_argument": true,
        "inlay_hints_hide_redundant_param_names": false,
        "inlay_hints_hide_redundant_param_names_last_token": false,
        "force_autofix": false,
        "warn_style": true,
        "highlight_global_var_declarations": true,
        "prefer_ast_check_as_child_process": true,
        "zig_exe_path": "/home/mroczect/.local/share/zvm/master/zig"
      }
    }
  }
}
```

perhatiin: **binary path** ZLS aku arahin ke `~/.zls/master/zls`. ini karena aku build sendiri.

### Language-specific settings buat Zig

```json
"languages": {
  "Zig": {
    "language_servers": ["zls"],
    "code_actions_on_format": {
      "source.fixAll": true,
      "source.organizeImports": true
    },
    "semantic_tokens": "combined",
    "format_on_save": "on",
    "tab_size": 4,
    "hard_tabs": false
  }
}
```

yang penting:

- **`format_on_save: "on"`** — setiap save, langsung diformat. rapi otomatis.
- **`tab_size: 4`** — indentasi 4 spasi.
- **`hard_tabs: false`** — pakai spasi, bukan tab.
- **`code_actions_on_format`** — jalanin `source.fixAll` dan `source.organizeImports` waktu format.

---

## 6. Alias Update Zig + ZLS

ini yang paling aku suka. daripada update Zig sama ZLS satu-satu, aku bikin alias:

```sh
alias zig-update='zvm install --force master && cd ~/zls && git pull && zig build -Doptimize=ReleaseSafe && cp zig-out/bin/zls ~/.zls/master/zls && cd - && echo "✅ Zig & ZLS updated to latest master"'
```

cara pakainya tinggal:

```sh
zig-update
```

apa aja yang dilakuin:

1. **`zvm install --force master`** — download Zig master terbaru, timpa yang lama.
2. **`cd ~/zls`** — masuk ke folder source ZLS.
3. **`git pull`** — tarik update terbaru dari repo ZLS.
4. **`zig build -Doptimize=ReleaseSafe`** — build ZLS dengan optimasi.
5. **`cp zig-out/bin/zls ~/.zls/master/zls`** — copy binary hasil build ke lokasi yang dipake Zed.
6. **`cd -`** — balik ke folder awal.
7. **echo** — print pesan sukses.

sekali jalan, Zig dan ZLS langsung update. hemat waktu banget.

---

## 7. Workflow Sehari-hari

kalau lagi ngoding Zig, workflow aku kayak gini:

### Mulai project baru

```sh
mkdir project-baru && cd project-baru
zig init
```

`zig init` bakal bikin struktur project Zig standar:

```
.
├── build.zig
├── build.zig.zon
└── src/
    ├── main.zig
    └── root.zig
```

### Buka di Zed

```sh
zed .
```

Zed bakal otomatis nyalain ZLS. tunggu beberapa detik, terus kamu udah bisa:

- **Autocomplete** — ketik `std.` bakal muncul daftar function.
- **Go to definition** — Ctrl+Click atau F12.
- **Find references** — Shift+F12.
- **Rename** — F2.
- **Inline hints** — tipe variabel muncul di samping.
- **Diagnostics** — error muncul langsung di bawah kode.

### Build dan test

```sh
zig build          # build
zig build run      # build + run
zig build test     # jalanin test
```

### Update Zig dan ZLS

sekali seminggu atau kalau ada fitur baru:

```sh
zig-update
```

---

## 8. Kenapa Setup Ini?

beberapa alasan kenapa aku pilih setup ini:

### 1. Zed itu cepet

Zed ditulis pakai Rust, dan performa-nya jauh lebih cepet dari VS Code. buat project Zig yang gede, ini kerasa banget.

### 2. ZVM gampang

pindah versi Zig tinggal `zvm use` — nggak perlu mikir.

### 3. Build ZLS sendiri lebih fleksibel

binary release ZLS kadang nggak cocok sama Zig master. dengan build sendiri, aku bisa mastiin kompatibel.

### 4. Alias update itu game changer

bayangin harus update Zig, terus build ZLS, terus copy binary — satu-satu. ribet kan? dengan alias, tinggal 1 command.

---

## 9. Kalau Kamu Mau Coba

kalau kamu tertarik sama setup ini, ini langkah-langkahnya:

### 1. Install Zed

kunjungi [zed.dev](https://zed.dev) dan download sesuai OS kamu.

### 2. Install ZVM

```sh
# Clone repo ZVM
git clone https://github.com/lispking/zvm ~/.zvm/self
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$ZVM_INSTALL:$PATH"
```

### 3. Install Zig master

```sh
zvm install --force master
```

### 4. Clone ZLS

```sh
git clone https://github.com/zigtools/zls ~/zls
cd ~/zls
zig build -Doptimize=ReleaseSafe
mkdir -p ~/.zls/master
cp zig-out/bin/zls ~/.zls/master/zls
```

### 5. Setup ZLS config

bikin `~/.config/zls.json` dengan config di atas.

### 6. Setup Zed config

tambahin konfigurasi Zig di `~/.config/zed/settings.json`.

### 7. Tambahin alias

tambahin `zig-update` di `~/.zshrc` kamu.

### 8. Selesai

buka project Zig di Zed, dan mulai coding.

---

## Kesimpulan

setup Zig aku di Zed itu:

- **Zig master** via ZVM
- **ZLS** build sendiri dari source
- **Zed** sebagai editor
- **Alias `zig-update`** buat update sekali jalan
- **Inlay hints + semantic tokens** bikin coding lebih enak

kalau kamu lagi cari setup Zig yang nyaman, coba contek sebagian. nggak harus sama persis — sesuaikan sama kebutuhan kamu.

ya udah segitu dulu blog kali ini. kalau kamu punya setup Zig yang beda atau lebih bagus, share aja di komentar (eh, gak ada komentar 😅).

sampai jumpa di post berikutnya!
