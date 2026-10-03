+++
title = "Teori Himpunan (Versi LLM)"
date = 2026-10-02
description = "Versi alternatif teori himpunan yang ditulis dengan bantuan LLM."
[taxonomies]
tags = ["matematika", "diskrit", "himpunan", "llm"]
+++


# BAGIAN 1: KENAPA BELAJAR INI DULU?

## Matematika Diskrit itu apa?

**Matematika Diskrit** = cabang matematika yang ngurusin benda-benda **yang bisa dihitung satu-satu**, bukan yang mengalir terus kayak air.

Contoh:

- **Diskrit** (bisa dihitung): `1, 2, 3, 4, 5`
- **Kontinu** (nggak bisa dihitung satu-satu): semua angka antara 0 dan 1 (ada 0.1, 0.01, 0.001, ... nggak ada habisnya)

Komputer itu kerjanya **diskrit**. Semua yang disimpan komputer itu berupa potongan-potongan kecil (bit, byte). Nggak ada yang "setengah ada setengah nggak". Makanya belajar matematika diskrit penting banget buat programmer.

## Kenapa harus belajar?

1. **Biar bisa berpikir logis** — nggak asal coding, tapi tahu alasannya.
2. **Landasan buat mata kuliah lain** — database, algoritma, keamanan, semua pakai ini.
3. **Biar ngerti cara komputer kerja** — komputer itu cuma ngerti 0 dan 1. Semua yang kamu lihat di layar sebenarnya hasil dari operasi diskrit.

## Contoh masalah nyata yang butuh ini

- Bikin **database** yang nggak nyimpen data dobel
- Bikin **enkripsi** biar data aman
- Bikin **GPS** yang bisa nyari jalan terpendek
- Bikin **sistem login** yang ngatur siapa boleh akses apa

---

# BAGIAN 2: HIMPUNAN ITU APA?

## Definisi

**Himpunan = kumpulan benda yang batasnya jelas.**

"Batasnya jelas" artinya: kalau ada benda, kita bisa **pastikan** benda itu masuk atau nggak. Jawabannya cuma **iya** atau **tidak**. Nggak ada "kayaknya iya".

## Contoh yang JELAS (ini himpunan)

```
A = {apel, jeruk, mangga}
```

- Apel masuk? **Iya**
- Semangka masuk? **Tidak**

```
B = {1, 2, 3, 4, 5}
```

- Angka 3 masuk? **Iya**
- Angka 7 masuk? **Tidak**

```
C = {GET, POST, PUT, DELETE}
```

- GET masuk? **Iya**
- PATCH masuk? **Tidak**

## Contoh yang NGGAK JELAS (ini bukan himpunan)

```
D = {makanan enak}
```

- Rendang masuk? Tergantung siapa yang ditanya.
- Nanas masuk? Ada yang suka, ada yang nggak.

Jawabannya nggak bisa dipastiin. Jadi **bukan himpunan**.

## Istilah penting

Di dalam himpunan, isinya disebut:

- **Elemen** (istilah Inggris)
- **Unsur** (istilah lama)
- **Anggota** (istilah sehari-hari)

**Tiga-tiganya artinya sama.** Cuma beda bahasa. Aku saranin pakai **anggota** aja, paling gampang.

## Notasi (cara nulis)

Himpunan ditulis pakai **kurung kurawal** `{ }`.

```
A = {apel, jeruk, mangga}
```

- `A` = nama himpunan
- `{ }` = tanda himpunan
- Isi di dalam = anggotanya

## Simbol-simbol dasar

| Simbol | Artinya              | Contoh                                    |
| ------ | -------------------- | ----------------------------------------- |
| `∈`    | "anggota dari"       | `apel ∈ A` = apel anggota A               |
| `∉`    | "bukan anggota dari" | `semangka ∉ A` = semangka bukan anggota A |

## Aturan penting himpunan

### Aturan 1: Nggak boleh ada duplikat

Kalau kamu tulis:

```
{ikan, ikan, sayur, roti}
```

Ini **salah** sebagai himpunan. Karena `ikan` muncul dua kali. Yang bener:

```
{ikan, sayur, roti}
```

**Alasan:** himpunan itu ngurusin "ada atau nggak", bukan "berapa kali ada".

### Aturan 2: Urutan nggak penting

```
{1, 2, 3} = {3, 2, 1} = {2, 1, 3}
```

Semuanya **sama**. Karena himpunan cuma peduli "apa isinya", bukan "urutan nulisnya".

**Bandingkan dengan array di coding:**

```zig
// Array: urutan PENTING
const arr = [_]u8{ 1, 2, 3 };
// arr[0] = 1, arr[1] = 2, arr[2] = 3

// Kalau dibalik jadi {3, 2, 1}, itu array yang BEDA
```

Jadi:

- **Himpunan** = nggak peduli urutan → `{1, 2, 3} = {3, 2, 1}`
- **Array/List** = peduli urutan → `[1, 2, 3] ≠ [3, 2, 1]`

---

# BAGIAN 3: CARA NULIS HIMPUNAN (4 CARA)

Ada 4 cara nulis himpunan. Masing-masing cocok buat situasi beda.

## Cara 1: Enumerasi (tulis semua)

**Enumerasi = tulis semua anggotanya satu-satu.**

Contoh:

```
H = {GET, POST, PUT, DELETE}
```

**Kapan pakai?**

- Kalau anggotanya **sedikit** (misal di bawah 20).
- Kalau kamu mau **eksplisit** — nggak mau ada salah paham.

**Kapan jangan pakai?**

- Kalau anggotanya sejuta. Nggak mungkin ditulis satu-satu.
- Kalau anggotanya nggak terbatas. Kayak `{1, 2, 3, 4, ...}` — kapan berhentinya?

## Cara 2: Simbol Baku

**Simbol baku = simbol yang udah disepakati dunia.**

Ini daftar yang wajib kamu hafal:

| Simbol | Nama                         | Isinya                                                       |
| ------ | ---------------------------- | ------------------------------------------------------------ |
| `N`    | Bilangan Asli (Natural)      | `{1, 2, 3, 4, ...}`                                          |
| `Z`    | Bilangan Bulat (Integer)     | `{..., -3, -2, -1, 0, 1, 2, 3, ...}`                         |
| `Q`    | Bilangan Rasional (Quotient) | Semua angka yang bisa ditulis `a/b`, misal `1/2`, `3/4`, `5` |
| `R`    | Bilangan Riil (Real)         | Semua angka di garis bilangan, termasuk `√2`, `π`, `e`       |
| `C`    | Bilangan Kompleks (Complex)  | Angka yang ada `i`-nya, misal `2 + 3i`                       |

**Kenapa hurufnya begitu?**

- `N` = Natural
- `Z` = Zahlen (bahasa Jerman, artinya "angka")
- `Q` = Quotient (hasil bagi)
- `R` = Real
- `C` = Complex

**Cara baca `{1, 2, 3, ...}`:**

Titik-titiknya (`...`) artinya "terus gitu, nggak berhenti". Jadi kamu nggak perlu tulis semua — cukup awal dan akhirnya (kalau ada).

**Contoh pakai:**

```
N = {1, 2, 3, 4, 5, ...}
Z = {..., -2, -1, 0, 1, 2, ...}
```

## Cara 3: Notasi Pembentuk Himpunan

**Ini cara paling penting.** Kalau kamu cuma mau hafal satu, hafal yang ini.

**Notasi pembentuk = tulis syaratnya, bukan isinya.**

Format:

```
{ x | syarat yang harus dipenuhi x }
```

- `x` = variabel, ibarat "sesuatu"
- `|` = dibaca **"dimana"** atau **"sedemikian sehingga"**
- Setelah `|` = syaratnya
- Tanda `,` = dibaca **"dan"**

**Contoh gampang:**

```
A = {x | x bilangan genap, x < 10}
```

**Cara baca:** "A adalah himpunan semua `x`, **dimana** `x` itu bilangan genap **dan** `x` kurang dari 10."

**Hasilnya:** `A = {2, 4, 6, 8}`

**Contoh dari materi:**

```
P = {x | x adalah nomor port jaringan, x < 1024}
```

**Cara baca:** "P adalah himpunan semua `x`, **dimana** `x` itu nomor port jaringan **dan** `x` kurang dari 1024."

**Contoh lain:**

```
B = {x | x ∈ N, x > 5}
```

**Cara baca:** "B adalah himpunan `x`, dimana `x` anggota N (bilangan asli) **dan** `x` lebih dari 5."

**Hasil:** `B = {6, 7, 8, 9, ...}`

**Kapan pakai?**

- Kalau anggotanya banyak atau nggak terbatas
- Kalau ada pola yang jelas
- Kalau mau ringkas

**Di pemrograman**, ini kayak filter:

```python
genap = {x for x in range(1, 20) if x % 2 == 0}
```

Kamu nggak tulis hasilnya. Kamu tulis aturannya. Komputer yang nanti isi.

## Cara 4: Diagram Venn

**Diagram Venn = gambar.**

Bentuknya lingkaran-lingkaran yang bisa tumpang tindih. Dipakai buat nunjukin **hubungan** antar himpunan.

**Contoh:**

Bayangin ada dua himpunan:

- **Soccer** = `{alex, casey, drew, hunter}`
- **Tennis** = `{casey, drew, jade}`

Kalau digambar:

```
    ┌─────────────────────────────┐
    │           Semesta           │
    │                             │
    │   ┌──────────┐ ┌──────────┐ │
    │   │ Soccer   │ │ Tennis   │ │
    │   │          │ │          │ │
    │   │ alex     │ │       jade│
    │   │ hunter   │ │          │ │
    │   │    ┌─────┴─┴─────┐    │ │
    │   │    │ casey, drew │    │ │
    │   │    └─────────────┘    │ │
    │   └──────────┘ └──────────┘ │
    └─────────────────────────────┘
```

- **Kotak luar** = semesta, semua yang lagi dibicarakan
- **Lingkaran** = himpunan
- **Tumpang tindih** = ada yang anggota dua-duanya (`casey`, `drew`)

**Kapan pakai?**

- Kalau mau nunjukin hubungan antar himpunan
- Kalau mau jelasin ke orang dengan visual
- Kalau mau buktiin sesuatu

**Kapan jangan pakai?**

- Kalau anggotanya banyak. Nggak mungkin gambar 1000 elemen.
- Kalau cuma mau daftar isi. Pakai enumerasi aja.

---

# BAGIAN 4: KARDINALITAS (JUMLAH ANGGOTA)

## Apa itu kardinalitas?

**Kardinalitas = jumlah anggota unik di dalam himpunan.**

**Notasi:** `n(A)` atau `|A|`

**Contoh:**

```
A = {2, 3, 5, 7, 11, 13, 17, 19}
```

Anggotanya ada 8. Jadi:

```
|A| = 8
```

## Kenapa penting?

Bayangin kamu punya data login:

```
{Ani, Budi, Ani, Cici, Budi}
```

Kalau dihitung sebagai **list**, ada 5. Tapi itu **salah** karena Ani dan Budi dihitung dobel.

Kalau dijadikan **himpunan**, yang dobel hilang:

```
{Ani, Budi, Cici}
```

Kardinalitasnya = 3.

## Di dunia nyata

Ini dipakai buat hitung **Unique Active Users (UAU)**.

Misal sebuah aplikasi mau tahu "berapa orang yang benar-benar unik yang buka aplikasi hari ini". Data login:

```
[USR01, USR05, USR02, USR01, USR03, USR05, USR01, USR04, USR02]
```

Kalau dijadikan himpunan:

```
U = {USR01, USR02, USR03, USR04, USR05}
```

Maka:

```
|U| = 5
```

Artinya ada **5 pengguna unik**.

**Dampaknya:**

- Nggak ada data dobel → hemat penyimpanan
- Query database lebih cepat
- Analisis lebih akurat

---

# BAGIAN 5: HIMPUNAN KHUSUS

## 1. Himpunan Kosong (`∅`)

Himpunan yang **nggak punya anggota sama sekali**.

**Notasi:** `∅` atau `{ }`

**Kardinalitasnya:** 0

**Contoh:** himpunan mahasiswa yang tinggal di bulan. Ya nggak ada. Jadi `∅`.

**Catatan:** `{∅}` itu **beda** dengan `∅`.

- `∅` = nggak ada isinya
- `{∅}` = ada isinya satu, yaitu himpunan kosong

Anggap aja:

- `∅` = kotak kosong
- `{∅}` = kotak yang isinya kotak kosong

## 2. Himpunan Semesta (`U`)

Himpunan yang memuat **semua** objek yang lagi dibicarakan.

**Notasi:** `U` (dari kata "Universal")

**Contoh:**

Kalau lagi ngomongin angka 1 sampai 9, maka:

```
U = {1, 2, 3, 4, 5, 6, 7, 8, 9}
```

Kalau ada himpunan:

```
A = {1, 3, 5, 7, 9}
```

Maka yang **bukan** anggota A tapi ada di U adalah:

```
{2, 4, 6, 8}
```

Ini yang disebut **komplemen** (nanti dibahas).

**Penting:** Himpunan semesta itu **relatif**. Tergantung konteks.

- Kalau lagi ngomongin angka, `U` = semua angka.
- Kalau lagi ngomongin mahasiswa, `U` = semua mahasiswa.
- Kalau lagi ngomongin warna, `U` = semua warna.

## 3. Subset (Himpunan Bagian)

**Subset = himpunan yang semua anggotanya ada di himpunan lain.**

**Notasi:** `A ⊆ B` (dibaca "A subset dari B" atau "A himpunan bagian B")

**Contoh:**

```
{1, 2, 3} ⊆ {1, 2, 3, 4, 5}
```

Kenapa? Karena **setiap anggota** `{1, 2, 3}` (yaitu 1, 2, dan 3) ada di `{1, 2, 3, 4, 5}`.

**Contoh yang bukan subset:**

```
{1, 2, 6} ⊄ {1, 2, 3, 4, 5}
```

Karena 6 nggak ada di himpunan kedua.

**Aturan penting:**

- Setiap himpunan adalah subset dari dirinya sendiri: `A ⊆ A`
- Himpunan kosong adalah subset dari semua himpunan: `∅ ⊆ A`

**Istilah lain:**

- Kalau `A ⊆ B` tapi `A ≠ B` → `A` disebut **proper subset** dari B (notasi: `A ⊂ B`)
- Kalau `A ⊆ B`, maka `B` disebut **superset** dari A

**Analogi sehari-hari:**

```
Mahasiswa TI ⊆ Mahasiswa Polibatam
```

Karena semua mahasiswa TI juga mahasiswa Polibatam.

## 4. Himpunan Kuasa (Power Set)

**Power set = himpunan yang berisi SEMUA subset dari suatu himpunan.**

**Notasi:** `P(A)` atau `2^A`

**Contoh:**

```
A = {1, 2}
```

Semua subset dari A adalah:

- `∅` (kosong)
- `{1}`
- `{2}`
- `{1, 2}`

Jadi power setnya:

```
P(A) = {∅, {1}, {2}, {1, 2}}
```

**Jumlah anggotanya:** `2^n`, dengan `n` = jumlah anggota A.

Karena `A` punya 2 anggota, maka `P(A)` punya `2^2 = 4` anggota.

**Contoh lain:**

```
B = {a, b, c}
```

Semua subset dari B:

- `∅`
- `{a}`, `{b}`, `{c}`
- `{a, b}`, `{a, c}`, `{b, c}`
- `{a, b, c}`

Total: 8 = `2^3`.

**Kapan dipakai?**

Di RBAC (Role-Based Access Control) — sistem hak akses.

Contoh:

```
HakAkses = {Input, Edit, Hapus, Lihat}
Admin = {Input, Edit, Hapus, Lihat}
Dosen = {Input, Lihat}
Mahasiswa = {Lihat}
```

Relasinya:

```
Mahasiswa ⊆ Dosen ⊆ Admin
```

Power set dari `{Lihat}` = `{∅, {Lihat}}`.

Artinya: mahasiswa cuma punya 2 kemungkinan hak akses:

- nggak punya apa-apa (`∅`)
- punya hak lihat (`{Lihat}`)

Ini penting biar nggak ada kebocoran hak akses. Mahasiswa nggak mungkin tiba-tiba punya hak Hapus.

## 5. Himpunan Sama (=)

Dua himpunan disebut **sama** kalau anggotanya persis sama.

**Notasi:** `A = B`

**Definisi formal:**

```
A = B ↔ A ⊆ B dan B ⊆ A
```

Artinya: A sama dengan B, kalau A subset B **dan** B subset A. Dua-duanya saling mengandung.

**Contoh:**

```
A = {0, 1}
B = {x | x(x-1) = 0}
```

Hitung B dulu: kalau `x(x-1) = 0`, maka `x = 0` atau `x = 1`. Jadi `B = {0, 1}`.

Karena `A = {0, 1}` dan `B = {0, 1}`, maka `A = B`.

## 6. Himpunan Ekivalen (~)

Dua himpunan disebut **ekivalen** kalau **jumlah anggotanya sama**, tapi isinya boleh beda.

**Notasi:** `A ~ B`

**Contoh:**

```
A = {1, 3, 5, 7}
B = {a, b, c, d}
```

`|A| = 4` dan `|B| = 4`. Jadi `A ~ B`.

**Beda sama "sama":**

- **Sama (`=`)** → isinya persis sama
- **Ekivalen (`~`)** → cuma jumlahnya yang sama

Analogi:

- **Sama** = dua keranjang isinya buah yang persis sama
- **Ekivalen** = dua keranjang isinya beda, tapi jumlahnya sama-sama 4

---

# BAGIAN 6: OPERASI HIMPUNAN (6 OPERASI)

Sekarang kita masuk ke operasi. Ini kayak operasi matematika biasa (`+`, `-`, `×`), tapi buat himpunan.

## 1. Irisan (Intersection) — `∩`

**Irisan = anggota yang ada di KEDUA himpunan.**

**Notasi:** `A ∩ B`

**Definisi:**

```
A ∩ B = {x | x ∈ A dan x ∈ B}
```

**Kata kunci:** "**dan**"

**Contoh:**

```
A = {2, 4, 6, 8, 10, 11}
B = {4, 10, 11, 14, 18}
```

Yang ada di A **dan** B:

- 4 ada di A dan B → masuk
- 10 ada di A dan B → masuk
- 11 ada di A dan B → masuk

```
A ∩ B = {4, 10, 11}
```

**Di SQL:** ini setara dengan `INTERSECT` atau `INNER JOIN`.

**Analogi:** dua lingkaran yang tumpang tindih. Irisan itu bagian tengahnya.

## 2. Gabungan (Union) — `∪`

**Gabungan = semua anggota dari KEDUA himpunan, digabung.**

**Notasi:** `A ∪ B`

**Definisi:**

```
A ∪ B = {x | x ∈ A atau x ∈ B}
```

**Kata kunci:** "**atau**"

**Contoh:**

```
A = {2, 5, 8}
B = {7, 5, 22}
```

Gabungin semua:

- 2, 5, 8 dari A
- 7, 5, 22 dari B
- Yang dobel (5) dihitung sekali

```
A ∪ B = {2, 5, 7, 8, 22}
```

**Di SQL:** setara dengan `UNION`.

## 3. Komplemen — `A̅` atau `A'` atau `A^c`

**Komplemen = anggota semesta yang BUKAN anggota A.**

**Notasi:** `A̅` (dibaca "A bar" atau "A komplemen")

**Definisi:**

```
A̅ = {x | x ∈ U dan x ∉ A}
```

**Contoh:**

```
U = {1, 2, 3, 4, 5, 6, 7, 8, 9}
A = {1, 3, 5, 7, 9}
```

Yang ada di U tapi **bukan** di A:

```
A̅ = {2, 4, 6, 8}
```

**Analogi:** kalau semesta itu seluruh kelas, dan A itu anak yang bawa bekal, maka `A̅` itu anak yang nggak bawa bekal.

## 4. Selisih (Difference) — `-`

**Selisih = anggota A yang BUKAN anggota B.**

**Notasi:** `A - B`

**Definisi:**

```
A - B = {x | x ∈ A dan x ∉ B}
```

**Perhatikan:** urutan penting! `A - B` beda dengan `B - A`.

**Contoh:**

```
A = {User1, User2, User3, User5}  (pengguna aktif bulan ini)
B = {User2, User5}                 (pengguna yang sudah bayar)
```

Yang aktif tapi belum bayar:

```
A - B = {User1, User3}
```

**Di SQL:** setara dengan `EXCEPT` atau `NOT IN`.

**Beda dengan komplemen:**

- **Komplemen** pakai semesta `U`
- **Selisih** pakai dua himpunan biasa

## 5. Beda Simetris (Symmetric Difference) — `⊕`

**Beda simetris = anggota yang ada di A atau B, tapi TIDAK di keduanya.**

**Notasi:** `A ⊕ B` atau `A △ B`

**Definisi:**

```
A ⊕ B = {x | x ∈ A atau x ∈ B, tapi tidak keduanya}
```

**Kata kunci:** "**atau**" tapi "**tidak keduanya**"

**Contoh:**

```
A = {2, 4, 6}
B = {2, 3, 5}
```

- 2 ada di dua-duanya → **buang**
- 4 cuma di A → **masuk**
- 6 cuma di A → **masuk**
- 3 cuma di B → **masuk**
- 5 cuma di B → **masuk**

```
A ⊕ B = {3, 4, 5, 6}
```

**Analogi:** dua lingkaran yang tumpang tindih. Yang diambil itu **yang nggak tumpang tindih**, dari kedua sisi.

**Rumus lain:**

```
A ⊕ B = (A ∪ B) - (A ∩ B)
```

Artinya: gabungan dikurangi irisan.

## 6. Cartesian Product — `×`

**Cartesian product = semua pasangan berurutan dari dua himpunan.**

**Notasi:** `A × B`

**Definisi:**

```
A × B = {(a, b) | a ∈ A dan b ∈ B}
```

**Contoh:**

```
A = {Chrome, Firefox}
B = {Windows, Linux, MacOS}
```

Bikin semua kombinasi:

```
A × B = {
  (Chrome, Windows), (Chrome, Linux), (Chrome, MacOS),
  (Firefox, Windows), (Firefox, Linux), (Firefox, MacOS)
}
```

Total: 6 pasangan (karena `2 × 3 = 6`).

**Kapan dipakai di RPL?**

**1. Software Testing (Combinatorial Test Case Generation)**

Mau nguji aplikasi web yang support 2 browser dan 3 OS. Kamu harus uji semua kombinasi:

- Chrome di Windows
- Chrome di Linux
- Chrome di MacOS
- Firefox di Windows
- Firefox di Linux
- Firefox di MacOS

Total 6 skenario uji. Itu Cartesian product.

**2. Database Query**

Di SQL, ini setara dengan `CROSS JOIN`.

---

# BAGIAN 7: PRINSIP INKLUSI-EKSKLUSI

## Masalahnya dulu

Kalau kamu punya 2 himpunan, dan kamu mau tahu **total anggotanya**, kamu nggak bisa cuma menjumlahkan.

Contoh:

```
A = {1, 2, 3, 4, 5}    → |A| = 5
B = {4, 5, 6, 7}       → |B| = 4
```

Kalau kamu hitung `|A| + |B| = 5 + 4 = 9`, itu **salah**. Kenapa?

Karena 4 dan 5 dihitung dua kali (sekali di A, sekali di B).

Yang bener:

```
A ∪ B = {1, 2, 3, 4, 5, 6, 7}
|A ∪ B| = 7
```

## Rumus untuk 2 himpunan

```
|A ∪ B| = |A| + |B| - |A ∩ B|
```

**Kenapa dikurangi `|A ∩ B|`?**

Karena yang dobel itu ada di irisan. Kita kurangi biar nggak dihitung dua kali.

**Cek dengan contoh di atas:**

```
|A ∪ B| = 5 + 4 - |{4, 5}|
        = 9 - 2
        = 7  ✓
```

## Rumus untuk 3 himpunan

```
|A ∪ B ∪ C| = |A| + |B| + |C| - |A ∩ B| - |A ∩ C| - |B ∩ C| + |A ∩ B ∩ C|
```

**Kenapa ada yang dikurangi, ada yang ditambah?**

Bayangin 3 lingkaran yang tumpang tindih. Yang di tengah (anggota tiga-tiganya) itu kelebihan dikurangi. Makanya harus ditambah lagi.

## Contoh soal (dari materi)

Diketahui:

```
|N| = 120      (Netflix)
|D| = 80       (Disney+)
|V| = 60       (Vidio)

|N ∩ D| = 40
|N ∩ V| = 25
|D ∩ V| = 15

|N ∩ D ∩ V| = 10
```

Pertanyaan: berapa total pelanggan unik `|N ∪ D ∪ V|`?

**Hitung:**

```
|N ∪ D ∪ V| = 120 + 80 + 60 - 40 - 25 - 15 + 10
            = 260 - 80 + 10
            = 190
```

Jadi ada **190 pelanggan unik**.

## Kenapa ini penting?

Kalau kamu cuma jumlahin:

```
120 + 80 + 60 = 260
```

Itu **double counting**. Orang yang langganan Netflix **dan** Disney+ dihitung dua kali. Orang yang langganan tiga-tiganya dihitung tiga kali.

Akibatnya:

- Analisis jadi salah
- Laporan ke manajemen jadi nggak akurat
- Keputusan bisnis jadi keliru

---

# BAGIAN 8: HIMPUNAN FUZZY

## Masalah dengan himpunan biasa

Himpunan biasa (disebut **crisp**) itu kaku. Cuma ada 2 kemungkinan:

- Anggota (1)
- Bukan anggota (0)

Contoh: umur 30 tahun, itu MUDA atau TUA?

Kalau pakai aturan crisp:

- MUDA: umur < 35
- PAROBAYA: 35 ≤ umur ≤ 55
- TUA: umur > 55

Maka:

- Umur 30 → MUDA (100%)
- Umur 36 → PAROBAYA (100%)
- Umur 60 → TUA (100%)

Masalahnya: umur 34 dan 36 itu beda banget nasibnya, padahal cuma beda 2 tahun. Ini yang bikin crisp terasa aneh.

## Solusinya: Fuzzy

**Himpunan fuzzy = himpunan yang keanggotaannya nggak cuma 0 atau 1, tapi bisa di antaranya.**

Nilai keanggotaan ada di rentang **0 sampai 1**.

## Fungsi Keanggotaan

**Notasi:** `μ_A(x)`

- `μ` (baca "mu") = fungsi
- `A` = nama himpunan
- `x` = anggota yang mau dicek

**Bedanya:**

- **Crisp:** `χ_A : X → {0, 1}` (cuma 0 atau 1)
- **Fuzzy:** `μ_A : X → [0, 1]` (bisa 0.5, 0.25, 0.75, dll)

## Contoh dari materi

Umur seseorang = 40 tahun.

Lihat grafik:

- `μ_MUDA(40) = 0.25` → dia 25% "muda"
- `μ_PAROBAYA(40) = 0.5` → dia 50% "parobaya"

Artinya, umur 40 itu:

- Bukan muda banget (cuma 25%)
- Bukan parobaya banget (cuma 50%)
- Ada di antara dua-duanya

Ini lebih realistis daripada crisp yang bilang "40 itu parobaya 100%" atau "40 itu muda 100%".

## Crisp vs Fuzzy

**Crisp (kaku):**

```
MUDA    : umur < 35
PAROBAYA: 35 ≤ umur ≤ 55
TUA     : umur > 55
```

**Fuzzy (halus):**

Ada transisi bertahap. Umur 35 bisa jadi anggota MUDA **dan** PAROBAYA sekaligus, dengan derajat beda.

## Contoh di RPL

**1. Sistem Rekomendasi Film**

Penilaian:

- Suka banget = 1
- Suka = 0.7
- Netral = 0.5
- Tidak suka = 0.2

User kasih rating:

- Film A = Suka (0.7)
- Film B = Netral (0.5)
- Film C = Suka banget (1.0)

Urutan rekomendasi (dari paling disukai):

```
C → A → B
```

Kenapa pakai fuzzy? Karena selera orang nggak hitam-putih. Kadang "suka" itu nggak 100%, cuma 70%.

**2. Deteksi Spam**

- **Crisp:** Spam (1) atau Clean (0)
- **Fuzzy:** `μ_Spam(email) = 0.72` → masuk kategori "Suspicious" (mencurigakan)

Jadi email nggak langsung dibuang, tapi dikarantina dulu.

**3. Kualitas Kode**

Kompleksitas kode diklasifikasikan:

- Low
- Medium
- High

Berdasarkan skor fuzzy (0-1).

## Kenapa Fuzzy lebih cocok?

Karena dunia nyata itu **nggak hitam-putih**.

- Film bagus? Tergantung selera, nggak cuma iya/nggak.
- Email spam? Kadang "setengah spam".
- Kode kompleks? Kadang "agak kompleks".

Fuzzy ngasih ruang buat "**derajat keabuan**" itu.

---

# BAGIAN 9: PENERAPAN DI RPL

## 1. RBAC (Role-Based Access Control)

Sistem hak akses:

```
HakAkses = {Input, Edit, Hapus, Lihat}

Admin     = {Input, Edit, Hapus, Lihat}
Dosen     = {Input, Lihat}
Mahasiswa = {Lihat}
```

Relasi:

```
Mahasiswa ⊆ Dosen ⊆ Admin
```

Power set dari `{Lihat}`:

```
P({Lihat}) = {∅, {Lihat}}
```

Artinya mahasiswa cuma punya 2 kemungkinan hak akses:

- nggak punya apa-apa
- punya hak lihat

## 2. Unique Active Users (UAU)

Data log:

```
[USR01, USR05, USR02, USR01, USR03, USR05, USR01, USR04, USR02]
```

Himpunan unik:

```
U = {USR01, USR02, USR03, USR04, USR05}
```

Kardinalitas:

```
|U| = 5
```

Dipakai buat hitung UAU dan optimasi penyimpanan.

## 3. SQL dan Operasi Himpunan

| Operasi Himpunan        | SQL                 |
| ----------------------- | ------------------- |
| Gabungan (`∪`)          | `UNION`             |
| Irisan (`∩`)            | `INTERSECT`         |
| Selisih (`-`)           | `EXCEPT` / `NOT IN` |
| Cartesian Product (`×`) | `CROSS JOIN`        |

## 4. Test Case Generation

Dengan Cartesian product, kita bisa buat semua kombinasi input.

Contoh:

- Browser: Chrome, Firefox
- OS: Windows, Linux, MacOS

Total 6 skenario pengujian. Ini yang disebut **Combinatorial Test Case Generation**.

---

# BAGIAN 10: CONTOH SOAL DAN JAWABAN

## Soal 1

```
A = {101, 102, 105, 108, 112}
B = {x | 100 ≤ x ≤ 115, x habis dibagi 3}
```

a. Enumerasi B
b. Notasi pembentuk A
c. Kardinalitas A ∪ B

**Jawaban:**

a. Bilangan antara 100-115 yang habis dibagi 3:

```
102, 105, 108, 111, 114
```

Jadi:

```
B = {102, 105, 108, 111, 114}
```

b. Notasi pembentuk A:

```
A = {x | x ∈ {101, 102, 105, 108, 112}}
```

c. Gabungan:

```
A ∪ B = {101, 102, 105, 108, 111, 112, 114}
|A ∪ B| = 7
```

## Soal 2

Data log:

```
[USR01, USR05, USR02, USR01, USR03, USR05, USR01, USR04, USR02]
```

a. Himpunan unik
b. Kardinalitas
c. Kenapa penting?

**Jawaban:**

a.

```
U = {USR01, USR02, USR03, USR04, USR05}
```

b.

```
|U| = 5
```

c. Penting buat hitung Unique Active Users, hindari double counting, hemat penyimpanan, dan percepat query.

## Soal 3

Netflix, Disney+, Vidio:

```
|N| = 120, |D| = 80, |V| = 60
|N ∩ D| = 40, |N ∩ V| = 25, |D ∩ V| = 15
|N ∩ D ∩ V| = 10
```

a. Hitung `|N ∪ D ∪ V|`
b. Kenapa nggak boleh cuma jumlahin?

**Jawaban:**

a.

```
|N ∪ D ∪ V| = 120 + 80 + 60 - 40 - 25 - 15 + 10
            = 190
```

b. Kalau cuma jumlahin:

```
120 + 80 + 60 = 260
```

Itu salah karena pelanggan yang langganan lebih dari satu dihitung berkali-kali. Namanya **double counting**.

## Soal 4

Penilaian film:

- Film A = Suka (0.7)
- Film B = Netral (0.5)
- Film C = Suka banget (1.0)

a. Urutan rekomendasi
b. Kenapa fuzzy lebih cocok?

**Jawaban:**

a. Urutan: `C → A → B` (dari yang paling tinggi nilainya)

b. Karena preferensi orang nggak hitam-putih. Kadang "suka" cuma 70%, nggak full 100%.

---

# RINGKASAN SEMUA

| Konsep                | Inti                                      |
| --------------------- | ----------------------------------------- |
| **Himpunan**          | Kumpulan objek yang batasnya jelas        |
| **Anggota**           | Isi dari himpunan                         |
| **Enumerasi**         | Tulis semua anggota                       |
| **Simbol baku**       | N, Z, Q, R, C                             |
| **Notasi pembentuk**  | `{x \| syarat}`                           |
| **Diagram Venn**      | Gambar lingkaran                          |
| **Kardinalitas**      | Jumlah anggota (`\|A\|`)                  |
| **Himpunan kosong**   | `∅`                                       |
| **Himpunan semesta**  | `U`                                       |
| **Subset**            | `A ⊆ B`                                   |
| **Power set**         | Semua subset, jumlah `2^n`                |
| **Himpunan sama**     | `A = B`                                   |
| **Himpunan ekivalen** | `A ~ B` (jumlah sama)                     |
| **Irisan**            | `A ∩ B` (yang ada di dua-duanya)          |
| **Gabungan**          | `A ∪ B` (semua digabung)                  |
| **Komplemen**         | `A̅` (yang bukan A di semesta)             |
| **Selisih**           | `A - B` (di A tapi bukan di B)            |
| **Beda simetris**     | `A ⊕ B` (di salah satu, bukan dua-duanya) |
| **Cartesian product** | `A × B` (semua pasangan)                  |
| **Inklusi-Eksklusi**  | `\|A ∪ B\| = \|A\| + \|B\| - \|A ∩ B\|`   |
| **Fuzzy**             | Keanggotaan 0 sampai 1                    |