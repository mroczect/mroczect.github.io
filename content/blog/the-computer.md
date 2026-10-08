+++
title = "Cara Kerja Komputer: Dari Mesin Turing hingga Arsitektur von Neumann"
date = 2026-10-08
description = "Perjalanan lengkap memahami cara kerja komputer: mulai dari model abstrak Mesin Turing, rangkaian digital, gerbang logika, memori, arsitektur von Neumann, register, cache, bus, hingga bahasa assembly. Ditulis dalam bahasa Indonesia yang santai namun mendalam."
[taxonomies]
tags = ["komputer", "turing", "von-neumann", "hardware", "arsitektur", "assembly", "cpu", "memori", "logika"]
+++

## Pengantar

Komputer adalah salah satu penemuan paling berpengaruh dalam sejarah manusia. Namun, di balik layar yang menampilkan gambar dan teks, ada serangkaian prinsip yang bekerja secara elegan dan terkoordinasi. Bagaimana sebenarnya komputer bekerja? Dari mana kita harus mulai memahaminya?

Artikel ini akan mengajak Anda menelusuri perjalanan intelektual tentang cara kerja komputer. Kita akan mulai dari model paling abstrak, yaitu Mesin Turing, lalu turun ke rangkaian digital, gerbang logika, memori, arsitektur von Neumann, hingga akhirnya memahami mengapa bahasa assembly masih relevan sampai hari ini.

## Komputer: Kombinasi Eksekusi Fungsi dan Memori

Secara sederhana, komputer adalah kombinasi dari eksekusi fungsi yang berulang dan memori. Pada komputer yang dapat diprogram, fungsi yang dieksekusi dipilih oleh instruksi program. Inilah yang membedakan komputer dari kalkulator biasa. Kalkulator hanya bisa melakukan operasi yang sudah ditentukan, sedangkan komputer dapat menjalankan berbagai macam program yang berbeda, tergantung instruksi yang diberikan.

Konsep ini terdengar sederhana, tetapi implikasinya sangat besar. Dengan memisahkan program dari perangkat keras, satu mesin yang sama dapat digunakan untuk berbagai keperluan, mulai dari menulis dokumen, mengedit foto, hingga mengendalikan pesawat ruang angkasa. Inilah fondasi dari komputer modern.

## Mesin Turing: Model Abstrak dari Komputer Universal

Sebelum komputer elektronik benar-benar dibangun, Alan Turing pada tahun 1936 memperkenalkan sebuah model abstrak yang disebut Mesin Turing. Mesin ini adalah model sederhana dari komputer universal yang mampu mengeksekusi program apa pun yang dapat diimplementasikan pada perangkat keras digital apa pun.

Mesin Turing terdiri dari beberapa komponen. Pertama, terdapat sejumlah keadaan terbatas atau finite state. Kedua, terdapat pita tak terbatas yang terdiri dari sel-sel diskrit, masing-masing ditandai dengan huruf dari alfabet yang terbatas dan tetap. Ketiga, terdapat posisi saat ini pada pita tersebut. Keempat, terdapat fungsi transisi yang menentukan keadaan berikutnya, huruf yang ditulis pada posisi saat ini, dan gerakan pita, apakah ke kiri, ke kanan, atau tetap. Semua ini ditentukan oleh keadaan saat ini dan huruf yang dibaca.

Cara kerja Mesin Turing sangat sederhana. Pertama, mesin membaca simbol pada pita di posisi saat ini. Kedua, mesin menghitung fungsi transisi berdasarkan keadaan saat ini dan simbol yang dibaca. Fungsi transisi ini menghasilkan keadaan berikutnya, simbol baru yang akan ditulis, dan arah gerakan. Ketiga, mesin menulis simbol baru pada posisi saat ini, menggantikan simbol lama. Keempat, mesin memperbarui posisinya sesuai arah gerakan. Kelima, mesin memperbarui keadaan saat ini. Proses ini diulang terus-menerus.

Mesin Turing sepenuhnya didefinisikan oleh fungsi transisinya. Karena input ke fungsi transisi terbatas, fungsi ini dapat ditulis sebagai tabel pencarian. Misalnya, tabel transisi dapat menunjukkan bahwa jika mesin berada dalam keadaan Q dan membaca simbol X, maka mesin akan berpindah ke keadaan Q', menulis simbol Y, dan bergerak ke arah tertentu.

Yang menarik, fungsi transisi dari sebuah Mesin Turing dapat dikodekan sebagai string huruf, bahkan dalam bentuk biner. Ini memungkinkan kita merancang sebuah Mesin Turing universal, yaitu mesin yang dapat membaca encoding dari Mesin Turing lain dan mensimulasikan eksekusinya. Mesin Turing universal inilah yang merupakan komputer yang dapat diprogram. Konsep ini menjadi dasar dari semua komputer modern.

Tesis Church-Turing menyatakan bahwa sesuatu yang dapat dihitung oleh Mesin Turing dianggap sama dengan sesuatu yang dapat dihitung secara umum. Dengan kata lain, jika sebuah masalah dapat diselesaikan oleh komputer digital apa pun, maka masalah itu juga dapat diselesaikan oleh Mesin Turing. Ini adalah salah satu gagasan paling fundamental dalam ilmu komputer.

## Rangkaian Digital dan Bilangan Biner

Komputer elektronik bekerja dengan representasi biner dari data. Bilangan biner adalah bilangan dalam basis dua. Selain bilangan positif, terdapat juga bilangan negatif dan bilangan pecahan dalam representasi biner. Satu digit biner atau bit direpresentasikan oleh ada atau tidaknya arus listrik dalam suatu rangkaian. Delapan bit membentuk satu byte. Bilangan dengan lebar tetap, misalnya 32-bit atau 64-bit, sering disebut sebagai word atau kata.

Rangkaian kombinasional adalah rangkaian yang menghitung keluaran biner sebagai fungsi dari masukan biner. Rangkaian ini dibangun dari primitif yang disebut gerbang atau gate. Gerbang mengimplementasikan fungsi-fungsi dasar. Kabel membawa nilai-nilai biner dari satu gerbang ke gerbang lainnya. Sebuah rangkaian dapat menjadi elemen dari rangkaian yang lebih besar, sehingga tercipta abstraksi berlapis.

## Gerbang Logika Dasar

Ada tiga gerbang logika dasar yang menjadi fondasi dari semua rangkaian digital, yaitu AND, OR, dan NOT. Gerbang AND menghasilkan 1 hanya jika kedua masukannya 1. Gerbang OR menghasilkan 1 jika salah satu atau kedua masukannya 1. Gerbang NOT membalik nilai masukannya, jika masukannya 0 maka keluarannya 1, dan sebaliknya.

Ketiga gerbang ini sangat penting karena setiap fungsi biner dapat ditulis sebagai kombinasi dari AND, OR, dan NOT. Selain itu, terdapat primitif lain yang juga sering digunakan, yaitu XOR, NAND, dan NOR. Gerbang-gerbang ini menawarkan cara yang lebih efisien untuk mengimplementasikan fungsi tertentu.

## Realisasi Rangkaian

Rangkaian digital dapat direalisasikan dengan berbagai teknologi. Pada tahun 1800-an, ide rangkaian mekanik muncul, meskipun hanya digunakan pada mainan. Pada tahun 1930-an, relay elektromekanik dan tabung vakum digunakan. Pada tahun 1950-an, transistor ditemukan, diikuti oleh sirkuit terintegrasi pada tahun 1960-an, dan CMOS pada tahun 1990-an. Setiap teknologi memiliki trade-off dalam hal ukuran, kecepatan, konsumsi daya, panas, dan biaya.

Perkembangan teknologi ini mengikuti sebuah pola yang dikenal sebagai Hukum Moore. Hukum Moore menyatakan bahwa jumlah transistor pada chip sirkuit terintegrasi berlipat ganda kira-kira setiap dua tahun. Pola ini diamati dari tahun 1971 hingga 2018. Kemajuan ini sangat penting karena aspek lain dari kemajuan teknologi, seperti kecepatan pemrosesan atau harga produk elektronik, terkait erat dengan Hukum Moore.

## Rangkaian Memori

Selain rangkaian kombinasional yang menghitung keluaran berdasarkan masukan, terdapat juga rangkaian memori yang dapat menyimpan nilai. Rangkaian memori dibangun menggunakan umpan balik atau feedback. Sebuah rangkaian tertutup dapat mengingat sebuah nilai.

Namun, umpan balik menimbulkan masalah, seperti osilasi dan race condition, yaitu kondisi di mana nilai keluaran tidak stabil karena saling memengaruhi secara cepat. Untuk mengatasi masalah ini, digunakan clock, yaitu sinyal sinkronisasi yang teratur. Clock memastikan bahwa perubahan nilai hanya terjadi pada waktu yang telah ditentukan, sehingga rangkaian memori dapat bekerja dengan stabil.

Memori yang dapat dialamati atau addressable memory, yang juga dikenal sebagai RAM atau random access memory, dapat menyimpan banyak word dengan lebar m bit, tetapi hanya dapat mengakses satu word pada satu waktu. Alamat menentukan word mana yang diakses. RAM bekerja seperti array yang sangat besar dari bilangan bulat dengan lebar tetap. Operasi baca dan tulis dilakukan dengan memberikan alamat dan data yang sesuai.

## Arsitektur von Neumann

Arsitektur von Neumann adalah arsitektur komputer digital modern. Dalam arsitektur ini, CPU mengimplementasikan sejumlah kecil operasi tetap. Program dan data disimpan dalam memori yang sama. CPU secara berulang membaca dan mengeksekusi instruksi dari memori.

Proses ini berlangsung dalam siklus yang berulang. Pertama, CPU membaca instruksi berikutnya dari alamat memori yang diberikan oleh program counter atau PC. Kedua, CPU memahami detail instruksi, yaitu operasi apa yang harus dilakukan, operand apa yang digunakan, dan di mana hasilnya disimpan. Jika instruksi tersebut adalah lompatan bersyarat, CPU mengatur PC ke alamat target. Jika tidak, CPU menambah PC dengan ukuran instruksi. Proses ini diulang terus-menerus.

Arsitektur von Neumann terdiri dari beberapa komponen utama. CPU terdiri dari Arithmetic Logical Unit atau ALU dan Control Unit atau CU. ALU melakukan operasi aritmetika dan logika, sedangkan CU mengendalikan jalannya instruksi. Terdapat address bus dan data bus yang menghubungkan CPU dengan memori utama dan perangkat lainnya. Memori utama menyimpan program dan data yang dapat dieksekusi.

## Register, Memori, dan Cache

CPU memiliki memori kerja yang disebut register. Register berukuran kecil, biasanya seukuran word, dan jumlahnya terbatas, biasanya hanya beberapa puluh. Namun, register sangat cepat karena berjalan pada kecepatan clock CPU. Register digunakan untuk menyimpan data sementara selama operasi berlangsung.

Memori utama memiliki kepadatan yang sangat tinggi, mungkin 10^8 kali lebih besar dari register, tetapi lebih lambat dari CPU, seringkali dengan faktor 10 atau lebih. Untuk menjembatani kesenjangan kecepatan ini, digunakan cache, yaitu memori berkecepatan tinggi yang lebih kecil yang terletak di antara CPU dan memori utama. Caching bersifat transparan bagi program, artinya program tidak perlu mengetahui keberadaan cache.

## Bus

Bus adalah jalur yang mentransfer data antara komponen-komponen komputer, termasuk CPU, FPU, memori, dan periferal seperti hard drive, kartu grafis, dan kartu jaringan. Komponen-komponen ini dapat berjalan pada kecepatan clock yang berbeda. Namun, bus memiliki keterbatasan, yaitu hanya satu komponen yang dapat menulis ke bus pada satu waktu. Ini menjadi bottleneck atau penghambat kinerja.

Untuk mempercepat kinerja, berbagai teknik digunakan. Pertama, jalur langsung antara memori dan periferal dapat dibuat. Kedua, eksekusi out-of-order dan spekulatif memungkinkan CPU mengeksekusi instruksi independen atau instruksi masa depan yang mungkin diperlukan sambil menunggu. Teknik-teknik ini meningkatkan efisiensi pemanfaatan bus dan komponen lainnya.

## Bahasa Assembly

Bahasa pemrograman yang tidak memiliki banyak abstraksi dari cara kerja CPU biasanya disebut assembler atau bahasa assembly. Bahasa assembly menyediakan nama mnemonic untuk instruksi dan operand, label alamat, dan berbagai kemudahan lainnya. Contoh instruksi assembly antara lain xor ax, ax untuk mengosongkan register ax, pop bx untuk mengambil nilai dari stack, mov cx, [bx] untuk memindahkan nilai dari memori ke register, add bx, 4 untuk menambahkan 4 ke register bx, dan jnz @loop untuk melompat ke label loop jika hasil sebelumnya bukan nol.

Meskipun bahasa tingkat tinggi seperti Python, Java, atau C++ lebih banyak digunakan, bahasa assembly masih relevan dalam beberapa situasi. Pertama, dalam kasus tertentu, bahasa assembly dapat memberikan kinerja yang lebih baik. Meskipun mitos bahwa bahasa assembly tulisan tangan selalu cepat, ada efek-efek tertentu seperti cache dan bus yang dalam situasi tertentu sangat memengaruhi kinerja. Kedua, bahasa assembly digunakan untuk berinteraksi langsung dengan perangkat keras, misalnya dalam pemrograman GPU atau perangkat komputasi tertanam. Ketiga, memahami bahasa assembly penting untuk memahami cara kerja kode berbahaya dan bagaimana melindungi diri dari serangan tersebut.

## Mengapa Ini Penting?

Memahami cara kerja komputer dari level paling dasar hingga arsitektur von Neumann memberikan beberapa manfaat. Pertama, kita menjadi programmer yang lebih baik karena memahami apa yang sebenarnya terjadi di balik kode yang kita tulis. Kedua, kita dapat mengoptimalkan kinerja program dengan mempertimbangkan aspek-aspek seperti cache, bus, dan register. Ketiga, kita dapat memahami dan mengatasi masalah keamanan yang muncul dari interaksi antara perangkat keras dan perangkat lunak.

Lebih dari itu, memahami cara kerja komputer adalah bagian dari literasi teknologi modern. Di era di mana komputer ada di mana-mana, dari ponsel hingga mobil hingga peralatan rumah tangga, pemahaman tentang prinsip-prinsip dasar ini membantu kita menjadi pengguna yang lebih cerdas dan pengembang yang lebih kompeten.

## Kesimpulan

Perjalanan dari Mesin Turing hingga arsitektur von Neumann menunjukkan bagaimana serangkaian gagasan sederhana dapat digabungkan menjadi sistem yang sangat kompleks dan kuat. Mesin Turing memberikan model abstrak tentang apa yang dapat dihitung. Rangkaian digital dan gerbang logika memberikan fondasi fisik untuk komputasi. Memori dan clock memungkinkan penyimpanan dan sinkronisasi. Arsitektur von Neumann menyatukan semuanya menjadi komputer yang dapat diprogram.

Dengan memahami lapisan-lapisan ini, kita tidak hanya belajar tentang komputer, tetapi juga tentang bagaimana memecah masalah besar menjadi modul-modul yang lebih kecil, bagaimana merancang abstraksi yang baik, dan bagaimana mengelola kompleksitas. Inilah warisan intelektual dari ilmu komputer, yang terus relevan dan menginspirasi hingga hari ini.
