+++
title = "Teori Matriks (Versi LLM)"
date = 2026-10-03
description = "Penjelasan teori matriks dengan bantuan LLM."
[taxonomies]
tags = ["matematika", "matriks", "linear-algebra", "llm"]
+++

# BAGIAN 1: KENAPA BELAJAR MATRIKS?

## Masalahnya dulu

Bayangin kamu punya data nilai mahasiswa kayak gini:

| Mahasiswa | Matematika | Struktur Data | Pemrograman |
| --------- | ---------- | ------------- | ----------- |
| Andi      | 80         | 75            | 85          |
| Budi      | 70         | 85            | 80          |
| Citra     | 90         | 80            | 75          |

Sistem harus hitung nilai akhir dengan bobot:

- Matematika = 40%
- Struktur Data = 30%
- Pemrograman = 30%

**Pertanyaannya:** gimana caranya komputer nyimpen data ini biar bisa:

1. Disimpan terstruktur
2. Dioperasikan (ditambah, dikali, dll)
3. Dihitung banyak sekaligus

**Jawabannya:** pakai **matriks**.

## Kenapa matriks?

Karena data di atas bentuknya **baris dan kolom**. Persis kayak tabel. Dan di pemrograman, tabel kayak gini disimpan sebagai **array 2 dimensi**.

```zig
// Array 2D di Zig
const nilai = [3][3]u8{
    .{ 80, 75, 85 },  // Andi
    .{ 70, 85, 80 },  // Budi
    .{ 90, 80, 75 },  // Citra
};
```

Nah, matriks di matematika itu **model** dari array 2D ini. Jadi kalau kamu paham matriks, kamu paham cara komputer ngolah data tabel.

---

# BAGIAN 2: MATRIKS ITU APA?

## Definisi

**Matriks = susunan bilangan dalam bentuk baris dan kolom.**

Bentuknya kayak tabel. Tapi tanpa garis, dan angkanya diapit kurung siku.

Contoh:

```
A = [ 80  75  85 ]
    [ 70  85  80 ]
    [ 90  80  75 ]
```

## Istilah penting

- **Baris** = deretan horizontal (kiri ke kanan)
- **Kolom** = deretan vertikal (atas ke bawah)
- **Entri / elemen** = satu angka di dalam matriks
- **Ordo / dimensi** = ukuran matriks, ditulis `m × n`

Keterangan:

- `m` = jumlah baris
- `n` = jumlah kolom

Contoh di atas:

- Jumlah baris = 3
- Jumlah kolom = 3
- Ordo = `3 × 3`

## Cara nulis matriks

Nama matriks biasanya huruf kapital: `A`, `B`, `M`, dll.

Anggotanya ditulis dalam kurung siku `[ ]` atau kurung biasa `( )`.

## Notasi lengkap

Kalau matriksnya besar, nulis satu-satu capek. Jadi ada notasi singkat:

```
A = [a_ij]
```

Keterangan:

- `a` = nama elemen
- `i` = indeks baris (baris ke-i)
- `j` = indeks kolom (kolom ke-j)

**Contoh:**

```
A = [ 80  75  85 ]
    [ 70  85  80 ]
    [ 90  80  75 ]
```

Baca satu-satu:

- `a₁₁ = 80` → baris 1, kolom 1
- `a₁₂ = 75` → baris 1, kolom 2
- `a₁₃ = 85` → baris 1, kolom 3
- `a₂₁ = 70` → baris 2, kolom 1
- `a₂₃ = 80` → baris 2, kolom 3
- `a₃₂ = 80` → baris 3, kolom 2

**Ingat:** indeks pertama itu **baris**, indeks kedua itu **kolom**. Urutannya `a_baris,kolom`.

## Di pemrograman

```zig
const A = [3][3]u8{
    .{ 80, 75, 85 },
    .{ 70, 85, 80 },
    .{ 90, 80, 75 },
};

// Akses elemen: A[baris][kolom]
// A[0][0] = 80   (baris 1, kolom 1)
// A[1][2] = 80   (baris 2, kolom 3)
```

**Catatan:** di pemrograman, indeks mulai dari 0. Di matematika, indeks mulai dari 1.

Jadi:

- `a₁₁` di matematika = `A[0][0]` di kode
- `a₂₃` di matematika = `A[1][2]` di kode

---

# BAGIAN 3: SKALAR, VEKTOR, MATRIKS

Sebelum lanjut, kita bahas tiga istilah yang sering ketuker.

## 1. Skalar

**Skalar = satu angka tunggal.**

Contoh:

```
x = 85
```

Di pemrograman:

```zig
const score: u8 = 85;
```

Itu skalar. Cuma satu nilai.

## 2. Vektor

**Vektor = deretan angka dalam satu baris atau satu kolom.**

Ada 2 jenis:

**Vektor baris** (satu baris, banyak kolom):

```
v = [80  85  90]
```

Ordo: `1 × 3`

**Vektor kolom** (banyak baris, satu kolom):

```
    [80]
w = [85]
    [90]
```

Ordo: `3 × 1`

Di pemrograman, vektor itu **array 1 dimensi**:

```zig
const nilai = [_]u8{ 80, 85, 90 };
```

## 3. Matriks

**Matriks = kumpulan angka dalam banyak baris dan banyak kolom.**

Contoh:

```
A = [80  75  85]
    [70  85  80]
    [90  80  75]
```

Ordo: `3 × 3`

Di pemrograman, matriks itu **array 2 dimensi**:

```zig
const A = [3][3]u8{
    .{ 80, 75, 85 },
    .{ 70, 85, 80 },
    .{ 90, 80, 75 },
};
```

## Ringkasan

| Istilah      | Bentuk               | Ordo    | Di Kode         |
| ------------ | -------------------- | ------- | --------------- |
| Skalar       | satu angka           | `1 × 1` | `var x = 85;`   |
| Vektor baris | satu baris           | `1 × n` | `[_]u8{...}`    |
| Vektor kolom | satu kolom           | `m × 1` | `[_]u8{...}`    |
| Matriks      | banyak baris & kolom | `m × n` | `[m][n]u8{...}` |

---

# BAGIAN 4: PERSAMAAN MATRIKS

## Kapan dua matriks dianggap sama?

Dua matriks dianggap **sama** kalau:

1. Ordo-nya sama
2. Setiap elemen yang seletak (posisi sama) nilainya sama

**Contoh:**

```
A = [x  4]      B = [3  4]
    [7  y]          [7  9]
```

Kalau `A = B`, maka:

- `a₁₁ = b₁₁` → `x = 3`
- `a₁₂ = b₁₂` → `4 = 4` ✓ (udah sama)
- `a₂₁ = b₂₁` → `7 = 7` ✓ (udah sama)
- `a₂₂ = b₂₂` → `y = 9`

Jadi `x = 3` dan `y = 9`.

**Analogi di kode:**

```zig
const A = [2][2]u8{ .{x, 4}, .{7, y} };
const B = [2][2]u8{ .{3, 4}, .{7, 9} };

// A == B kalau x == 3 dan y == 9
```

---

# BAGIAN 5: JENIS-JENIS MATRIKS

Ada beberapa jenis matriks yang penting kamu tahu.

## 1. Matriks Persegi (Square Matrix)

**Matriks yang jumlah baris = jumlah kolom.**

Contoh:

```
A = [4  6]
    [3  8]
```

Ordo: `2 × 2`. Baris = 2, kolom = 2. Persegi.

## 2. Vektor Kolom

**Matriks yang cuma punya 1 kolom.**

Contoh:

```
    [2]
v = [3]
    [5]
```

Ordo: `3 × 1`

## 3. Vektor Baris

**Matriks yang cuma punya 1 baris.**

Contoh:

```
v = [2  3  5]
```

Ordo: `1 × 3`

## 4. Matriks Nol (Null Matrix)

**Matriks yang semua elemennya nol.**

Contoh:

```
O = [0  0]
    [0  0]
```

## 5. Matriks Identitas (Identity Matrix)

**Matriks persegi yang diagonal utamanya 1, sisanya 0.**

Notasi: `I`

Contoh 2×2:

```
I = [1  0]
    [0  1]
```

Contoh 3×3:

```
    [1  0  0]
I = [0  1  0]
    [0  0  1]
```

**Kegunaan:** kayak angka 1 di perkalian biasa. Kalau matriks dikali `I`, hasilnya matriks itu sendiri.

```
A × I = A
I × A = A
```

## 6. Matriks Transpos

**Transpos = tukar baris jadi kolom, kolom jadi baris.**

Notasi: `Aᵀ` atau `A'`

**Contoh:**

```
A = [6   4  24]      Aᵀ = [6   1]
    [1  -9   8]            [4  -9]
                           [24  8]
```

Perhatikan:

- Baris 1 matriks A (`6, 4, 24`) jadi kolom 1 matriks Aᵀ
- Baris 2 matriks A (`1, -9, 8`) jadi kolom 2 matriks Aᵀ

**Rumus:**

```
A = [a_ij]  →  Aᵀ = [a_ji]
```

**Di kode:**

```zig
const A = [2][3]u8{
    .{ 6, 4, 24 },
    .{ 1, -9, 8 },
};

// Transpose jadi [3][2]
var At: [3][2]i32 = undefined;
for (0..2) |i| {
    for (0..3) |j| {
        At[j][i] = A[i][j];
    }
}
```

---

# BAGIAN 6: OPERASI MATRIKS

## 1. Penjumlahan Matriks

**Syarat:** ordo kedua matriks harus sama.

**Aturan:** jumlahkan elemen yang seletak (posisi sama).

**Contoh:**

```
[3  8]   [4   0]   [3+4   8+0]   [7   8]
[4  6] + [1  -9] = [4+1   6-9] = [5  -3]
```

Lihat:

- `3 + 4 = 7` (posisi kiri atas)
- `8 + 0 = 8` (posisi kanan atas)
- `4 + 1 = 5` (posisi kiri bawah)
- `6 + (-9) = -3` (posisi kanan bawah)

**Rumus:**

```
C = A + B  →  c_ij = a_ij + b_ij
```

**Di kode:**

```zig
fn tambah(A: [2][2]i32, B: [2][2]i32) [2][2]i32 {
    var C: [2][2]i32 = undefined;
    for (0..2) |i| {
        for (0..2) |j| {
            C[i][j] = A[i][j] + B[i][j];
        }
    }
    return C;
}
```

## 2. Pengurangan Matriks

**Syarat:** ordo kedua matriks harus sama.

**Aturan:** kurangkan elemen yang seletak.

**Contoh:**

```
[3  8]   [4   0]   [3-4   8-0]   [-1   8]
[4  6] - [1  -9] = [4-1   6-(-9)] = [3  15]
```

**Rumus:**

```
C = A - B  →  c_ij = a_ij - b_ij
```

## 3. Perkalian Skalar

**Perkalian matriks dengan angka biasa (skalar).**

**Aturan:** semua elemen dikali angka itu.

**Contoh:**

```
    [4  6]         [2×4  2×6]   [8  12]
2 × [3  8] = [2×3  2×8] = [6  16]
```

**Rumus:**

```
k × A = [k × a_ij]
```

## 4. Perkalian Matriks dengan Matriks

**Ini yang paling penting dan paling sering salah.**

**Syarat:** jumlah kolom matriks pertama **harus sama** dengan jumlah baris matriks kedua.

Kalau `A` ordo `m × n` dan `B` ordo `n × p`, maka `A × B` bisa dihitung, dan hasilnya ordo `m × p`.

**Cara hitung:** baris dari A × kolom dari B (dot product).

**Contoh:**

```
A = [1  2]      B = [5  6]
    [3  4]          [7  8]
```

Hitung `AB`:

**Elemen (1,1):** baris 1 A × kolom 1 B

```
(1 × 5) + (2 × 7) = 5 + 14 = 19
```

**Elemen (1,2):** baris 1 A × kolom 2 B

```
(1 × 6) + (2 × 8) = 6 + 16 = 22
```

**Elemen (2,1):** baris 2 A × kolom 1 B

```
(3 × 5) + (4 × 7) = 15 + 28 = 43
```

**Elemen (2,2):** baris 2 A × kolom 2 B

```
(3 × 6) + (4 × 8) = 18 + 32 = 50
```

Hasilnya:

```
AB = [19  22]
     [43  50]
```

**Contoh lain (dengan ordo beda):**

```
A = [1  2  3]      B = [7   8]
    [4  5  6]          [9  10]
                       [11 12]
```

A ordo `2 × 3`, B ordo `3 × 2`. Kolom A (3) = baris B (3). Bisa dikali. Hasilnya `2 × 2`.

**Elemen (1,1):**

```
(1 × 7) + (2 × 9) + (3 × 11) = 7 + 18 + 33 = 58
```

**Elemen (1,2):**

```
(1 × 8) + (2 × 10) + (3 × 12) = 8 + 20 + 36 = 64
```

**Elemen (2,1):**

```
(4 × 7) + (5 × 9) + (6 × 11) = 28 + 45 + 66 = 139
```

**Elemen (2,2):**

```
(4 × 8) + (5 × 10) + (6 × 12) = 32 + 50 + 72 = 154
```

Hasilnya:

```
AB = [58   64]
     [139 154]
```

**Rumus:**

```
C = AB  →  c_ij = Σ (a_ik × b_kj)
```

Artinya: elemen ke-(i,j) dari hasil = jumlah dari (elemen baris i dari A dikali elemen kolom j dari B).

**Penting:** `AB ≠ BA`. Urutan penting!

**Di kode:**

```zig
fn kali(A: [2][3]i32, B: [3][2]i32) [2][2]i32 {
    var C: [2][2]i32 = undefined;
    for (0..2) |i| {
        for (0..2) |j| {
            var sum: i32 = 0;
            for (0..3) |k| {
                sum += A[i][k] * B[k][j];
            }
            C[i][j] = sum;
        }
    }
    return C;
}
```

---

# BAGIAN 7: DETERMINAN

## Apa itu determinan?

**Determinan = satu angka spesial yang dihitung dari matriks persegi.**

Notasi: `det(A)` atau `|A|`

**Kegunaan:**

- Cek apakah matriks punya invers
- Kalau `det(A) = 0` → nggak punya invers
- Kalau `det(A) ≠ 0` → punya invers

## Determinan 2×2

**Rumus:**

```
    [a  b]
A = [c  d]

det(A) = (a × d) - (b × c)
```

**Cara gampang:** diagonal utama (kiri atas ke kanan bawah) dikurangi diagonal kedua (kanan atas ke kiri bawah).

**Contoh:**

```
    [4  6]
B = [3  8]

det(B) = (4 × 8) - (6 × 3)
       = 32 - 18
       = 14
```

## Determinan 3×3

**Rumus:**

```
    [a  b  c]
A = [d  e  f]
    [g  h  i]

det(A) = a(ei - fh) - b(di - fg) + c(dh - eg)
```

**Cara baca:**

- `a` dikali determinan submatriks yang tersisa (buang baris 1, kolom 1)
- dikurangi `b` dikali submatriks (buang baris 1, kolom 2)
- ditambah `c` dikali submatriks (buang baris 1, kolom 3)

**Contoh:**

```
    [2  3  1]
A = [1  2  1]
    [3  1  2]
```

```
det(A) = 2(2×2 - 1×1) - 3(1×2 - 1×3) + 1(1×1 - 2×3)
       = 2(4 - 1) - 3(2 - 3) + 1(1 - 6)
       = 2(3) - 3(-1) + 1(-5)
       = 6 + 3 - 5
       = 4
```

## Determinan 4×4 atau lebih

Caranya sama: expand baris pertama. Tapi submatriksnya jadi 3×3. Lebih ribet.

**Rumus:**

```
    [a  b  c  d]
    [e  f  g  h]
A = [i  j  k  l]
    [m  n  o  p]

det(A) = a × det([f g h; j k l; n o p])
       - b × det([e g h; i k l; m o p])
       + c × det([e f h; i j l; m n p])
       - d × det([e f g; i j k; m n o])
```

**Pola tanda:** `+ - + -` bergantian.

---

# BAGIAN 8: INVERS MATRIKS

## Kenapa perlu invers?

Di bilangan biasa, kalau kamu punya:

```
2x = 10
```

Kamu bagi dua sisi dengan 2:

```
x = 10 / 2 = 5
```

Nah, di matriks, "pembagian" itu **perkalian dengan invers**.

Kalau:

```
AX = B
```

Maka:

```
X = A⁻¹ × B
```

Dengan syarat `A⁻¹` ada (matriks A punya invers).

**Analogi:** kayak `1/8` itu kebalikan (reciprocal) dari `8`. Karena `8 × 1/8 = 1`. Nah, `A⁻¹` itu kebalikan dari `A`. Karena `A × A⁻¹ = I` (matriks identitas).

## Syarat punya invers

Matriks persegi punya invers **kalau dan hanya kalau**:

```
det(A) ≠ 0
```

Kalau `det(A) = 0`, matriksnya disebut **singular**, dan nggak punya invers.

## Invers Matriks 2×2

**Rumus:**

```
    [a  b]      1     [ d  -b]
A = [c  d]  →  --- × [-c   a]
             ad-bc
```

Perhatikan:

- `1 / (ad-bc)` = `1 / det(A)`
- Matriks di kanan: tukar `a` dan `d`, negatifkan `b` dan `c`

**Contoh:**

```
    [4  7]
A = [2  6]
```

Langkah 1: hitung determinan

```
det(A) = (4 × 6) - (7 × 2)
       = 24 - 14
       = 10
```

Langkah 2: tukar dan negatifkan

```
[d  -b]   [6  -7]
[-c  a] = [-2  4]
```

Langkah 3: bagi dengan determinan

```
A⁻¹ = 1/10 × [6  -7]
             [-2  4]

    = [0.6  -0.7]
      [-0.2  0.4]
```

## Invers Matriks 3×3 atau lebih

Ada 2 metode:

**Metode 1: Operasi Baris Elementer (OBE)**

Gabung matriks `A` dengan matriks identitas `I`, jadi `[A | I]`. Lalu lakukan operasi baris sampai sisi kiri jadi `I`. Sisi kanan otomatis jadi `A⁻¹`.

```
[A | I]  →  [I | A⁻¹]
```

**Metode 2: Minor, Kofaktor, Adjugate**

Langkah-langkahnya:

**1.** Hitung determinan `det(A)`. Harus ≠ 0.

**2.** Hitung **matriks minor**. Minor `M_ij` = determinan submatriks yang diperoleh dengan menghapus baris ke-i dan kolom ke-j.

**3.** Hitung **matriks kofaktor**. Kofaktor `C_ij = (-1)^(i+j) × M_ij`.

Pola tanda untuk 3×3:

```
[+  -  +]
[-  +  -]
[+  -  +]
```

**4.** Hitung **matriks adjugate** (adjoint). Caranya: **transpose matriks kofaktor**.

```
adj(A) = Cᵀ
```

**5.** Hitung invers:

```
A⁻¹ = (1 / det(A)) × adj(A)
```

**Contoh lengkap (3×3):**

```
    [2  3  1]
A = [1  2  1]
    [3  1  2]
```

**Langkah 1:** hitung determinan

```
det(A) = 2(2×2 - 1×1) - 3(1×2 - 1×3) + 1(1×1 - 2×3)
       = 2(3) - 3(-1) + 1(-5)
       = 6 + 3 - 5
       = 4
```

**Langkah 2:** hitung matriks minor

```
M = [3   -1  -5]
    [5    1  -1]
    [1    1   1]
```

Cara: `M_11` = determinan submatriks dengan buang baris 1, kolom 1.

```
M_11 = det([2  1]) = (2×2) - (1×1) = 4 - 1 = 3
           [1  2]
```

Dan seterusnya untuk semua elemen.

**Langkah 3:** hitung matriks kofaktor

```
C = [+3   +1   -5]
    [-5   +1   +1]
    [+1   +1   +1]
```

Perhatikan tanda:

- `C_11 = (+) × M_11 = +3`
- `C_12 = (-) × M_12 = -(-1) = +1`
- `C_13 = (+) × M_13 = +(-5) = -5`
- dst.

**Langkah 4:** hitung adjugate

Transpose matriks kofaktor:

```
adj(A) = Cᵀ = [3  -5  1]
              [1   1  1]
              [-5  1  1]
```

**Langkah 5:** hitung invers

```
A⁻¹ = (1/4) × [3  -5  1]
              [1   1  1]
              [-5  1  1]

    = [3/4  -5/4  1/4]
      [1/4   1/4  1/4]
      [-5/4  1/4  1/4]
```

## Aplikasi: sistem persamaan linear

**Contoh soal:**

Sebuah grup naik bus. Tarif anak $3, tarif dewasa $3.2. Total $118.4.

Pulang naik train. Tarif anak $3.5, tarif dewasa $3.6. Total $135.2.

Berapa jumlah anak dan dewasa?

**Jawab:**

Misal `x₁ = jumlah anak`, `x₂ = jumlah dewasa`.

```
3x₁ + 3.2x₂ = 118.4
3.5x₁ + 3.6x₂ = 135.2
```

Ubah jadi matriks:

```
[x₁  x₂] × [3    3.5] = [118.4  135.2]
           [3.2  3.6]
```

Atau ditulis:

```
X × A = B
```

Cari `A⁻¹`:

```
A⁻¹ = 1 / (3×3.6 - 3.5×3.2) × [3.6  -3.5]
                                [-3.2   3]

    = 1 / (10.8 - 11.2) × [3.6  -3.5]
                          [-3.2   3]

    = 1 / (-0.4) × [3.6  -3.5]
                    [-3.2   3]

    = [-9    8.75]
      [8    -7.5 ]
```

Maka:

```
X = B × A⁻¹
  = [118.4  135.2] × [-9    8.75]
                     [8    -7.5 ]

  = [118.4×(-9) + 135.2×8,  118.4×8.75 + 135.2×(-7.5)]
  = [-1065.6 + 1081.6,  1036 - 1014]
  = [16,  22]
```

Jadi `x₁ = 16` anak, `x₂ = 22` dewasa.

---

# BAGIAN 9: PENERAPAN DI RPL

## 1. Transformasi Gambar Digital

Gambar 2×2 piksel disimpan sebagai matriks warna RGB.

**Operasi penjumlahan matriks untuk brightness:**

```
    [100  120]      [20  20]      [120  140]
A = [80   150]  B = [20  20]  C = [100  170]
```

Setiap elemen yang seletak dijumlahkan.

**Di kode:** identik dengan nested loop:

```zig
for (0..2) |i| {
    for (0..2) |j| {
        C[i][j] = A[i][j] + B[i][j];
    }
}
```

## 2. Penghitungan Nilai Akhir Otomatis

Matriks nilai (3 mahasiswa × 3 mata kuliah):

```
    [80  85  90]
M = [70  75  80]
    [90  90  95]
```

Vektor bobot:

```
    [0.40]
W = [0.30]
    [0.30]
```

Nilai akhir `N = M × W`:

```
    [80×0.4 + 85×0.3 + 90×0.3]     [86.5]
N = [70×0.4 + 75×0.3 + 80×0.3]   = [74.5]
    [90×0.4 + 90×0.3 + 95×0.3]     [91.5]
```

Jadi nilai akhir:

- Mahasiswa A: 86.5
- Mahasiswa B: 74.5
- Mahasiswa C: 91.5

**Keunggulan matriks:** satu operasi perkalian, semua mahasiswa langsung terhitung.

## 3. Grafika Komputer

Semua transformasi 3D (rotasi, translasi, scaling) pakai matriks. Contoh rotasi 90 derajat:

```
[0  -1]
[1   0]
```

## 4. Machine Learning

Data training disimpan sebagai matriks. Operasi neural network = serangkaian perkalian matriks.

---

# BAGIAN 10: CONTOH SOAL DAN JAWABAN

## Soal 1

Diketahui:

```
    [2  4]      [1  3]
A = [6  8]  B = [5  7]
```

Hitung:
a. `A + B`
b. `A - B`
c. `A × B`

**Jawaban:**

a.

```
A + B = [2+1  4+3] = [3   7]
        [6+5  8+7]   [11  15]
```

b.

```
A - B = [2-1  4-3] = [1  1]
        [6-5  8-7]   [1  1]
```

c.

```
A × B = [2×1+4×5  2×3+4×7] = [22  34]
        [6×1+8×5  6×3+8×7]   [46  74]
```

## Soal 2

Hitung determinan:

```
    [5  3]
A = [2  4]
```

**Jawaban:**

```
det(A) = (5 × 4) - (3 × 2)
       = 20 - 6
       = 14
```

## Soal 3

Cari invers:

```
    [3  1]
A = [5  2]
```

**Jawaban:**

Langkah 1: determinan

```
det(A) = (3 × 2) - (1 × 5)
       = 6 - 5
       = 1
```

Langkah 2: tukar dan negatifkan

```
[d  -b]   [2  -1]
[-c  a] = [-5   3]
```

Langkah 3: bagi determinan

```
A⁻¹ = 1/1 × [2  -1] = [2  -1]
            [-5  3]   [-5  3]
```

## Soal 4

Matriks nilai 3 mahasiswa:

```
    [80  85  90]
M = [70  75  80]
    [90  90  95]
```

Bobot: 40%, 30%, 30%.

Hitung nilai akhir.

**Jawaban:**

```
    [80×0.4 + 85×0.3 + 90×0.3]
N = [70×0.4 + 75×0.3 + 80×0.3]
    [90×0.4 + 90×0.3 + 95×0.3]

    [32 + 25.5 + 27]     [84.5]
  = [28 + 22.5 + 24]   = [74.5]
    [36 + 27 + 28.5]     [91.5]
```

## Soal 5 (dari tugas)

Buat matriks nilai 5 mahasiswa, hitung rata-rata tiap mata kuliah, hitung nilai akhir.

**Jawaban contoh:**

```
    [80  85  90]  Mhs 1
    [70  75  80]  Mhs 2
M = [90  90  95]  Mhs 3
    [85  80  75]  Mhs 4
    [75  85  88]  Mhs 5
```

**Rata-rata tiap mata kuliah:**

- Matematika: `(80+70+90+85+75) / 5 = 400/5 = 80`
- Struktur Data: `(85+75+90+80+85) / 5 = 415/5 = 83`
- RPL: `(90+80+95+75+88) / 5 = 428/5 = 85.6`

**Nilai akhir (bobot 40%, 30%, 30%):**

```
N = M × W

    [80×0.4 + 85×0.3 + 90×0.3]     [84.5]
    [70×0.4 + 75×0.3 + 80×0.3]     [74.5]
N = [90×0.4 + 90×0.3 + 95×0.3]   = [91.5]
    [85×0.4 + 80×0.3 + 75×0.3]     [80.5]
    [75×0.4 + 85×0.3 + 88×0.3]     [81.9]
```

---

# RINGKASAN SEMUA

| Konsep                | Inti                                          |
| --------------------- | --------------------------------------------- |
| **Matriks**           | Susunan angka dalam baris & kolom             |
| **Ordo**              | Ukuran `m × n`                                |
| **Elemen**            | Angka di dalam matriks, `a_ij`                |
| **Skalar**            | Satu angka tunggal                            |
| **Vektor**            | Matriks 1 baris atau 1 kolom                  |
| **Persamaan matriks** | `A = B` kalau ordo sama & elemen seletak sama |
| **Matriks persegi**   | Baris = kolom                                 |
| **Matriks nol**       | Semua elemen 0                                |
| **Matriks identitas** | Diagonal 1, sisanya 0                         |
| **Transpos**          | Tukar baris & kolom                           |
| **Penjumlahan**       | Jumlahkan elemen seletak, ordo harus sama     |
| **Pengurangan**       | Kurangkan elemen seletak, ordo harus sama     |
| **Perkalian skalar**  | Kalikan semua elemen dengan angka             |
| **Perkalian matriks** | Baris × kolom, kolom A = baris B              |
| **Determinan**        | Angka spesial, `det(A) = ad - bc` untuk 2×2   |
| **Invers**            | Kebalikan matriks, `A⁻¹ = (1/det) × adj(A)`   |
| **Syarat invers**     | `det(A) ≠ 0`                                  |

---

Itu dia lengkapnya. Semua yang ada di PDF udah masuk. Kalau ada bagian yang masih bingung, bilang aja bagian mana — nanti aku jelasin lebih dalam.
