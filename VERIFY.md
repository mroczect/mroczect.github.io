# Cara Verifikasi Paper

Semua paper di repositori ini ditandatangani secara kriptografis dengan GnuPG. Tujuannya agar pembaca dapat memastikan bahwa:

1. File PDF yang diunduh **benar-benar** berasal dari penulis.
2. File PDF **tidak diubah** sejak ditandatangani.
3. Tanggal tanda tangan dapat diverifikasi.

---

## Bagian A — Untuk Pembaca

### Prasyarat

Pasang GnuPG:

- Debian/Ubuntu: `sudo apt install gnupg`
- Arch: `sudo pacman -S gnupg`
- macOS: `brew install gnupg`

### Langkah Verifikasi

#### 1. Impor kunci publik penulis

```bash
gpg --import public.asc
```

#### 2. Unduh file PDF dan file `.asc` yang bersangkutan

Misalnya `Artikel-Variable-Rust.pdf` dan `Artikel-Variable-Rust.pdf.asc`.

#### 3. Verifikasi tanda tangan

```bash
gpg --verify Artikel-Variable-Rust.pdf.asc Artikel-Variable-Rust.pdf
```

Jika valid, GnuPG akan menampilkan:

```
gpg: Good signature from "Muhammad Riduwan Khafidi <mroczect@proton.me>"
```

#### 4. Verifikasi hash SHA-256 (opsional, lapisan kedua)

```bash
sha256sum Artikel-Variable-Rust.pdf
```

Bandingkan hasilnya dengan entri di [`paper/SHA256SUMS`](paper/SHA256SUMS) atau dengan 16 karakter pertama yang tercantum di tabel verifikasi.

### Jika Muncul "BAD signature"

Berarti file PDF **telah diubah** setelah ditandatangani, atau file yang diunduh rusak. Dalam kondisi ini, jangan percaya isi file tersebut. Hubungi penulis untuk mendapatkan file yang sah.

### Jika Muncul "Can't check signature: No public key"

Berarti kunci publik belum diimpor. Ulangi langkah 1.