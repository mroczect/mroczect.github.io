+++
title = "The Elements of Computing Systems: Membangun Komputer Modern dari Nand ke Sistem Operasi"
date = 2026-10-08
description = "Rangkuman lengkap buku The Elements of Computing Systems—dari gerbang logika, ALU, CPU Hack, assembler, VM, compiler Jack, hingga sistem operasi. Panduan memahami komputer dari prinsip pertama."
[taxonomies]
tags = ["computer-science", "hardware", "software", "compiler", "operating-system", "buku", "resensi", "nand2tetris"]
+++

# The Elements of Computing Systems: Membangun Komputer Modern dari Prinsip Pertama

## Pengantar dan Filosofi Buku

Buku _The Elements of Computing Systems: Building a Modern Computer from First Principles_ yang ditulis oleh Noam Nisan dan Shimon Schocken adalah sebuah karya yang mengajak pembaca untuk memahami cara kerja komputer secara utuh, mulai dari gerbang logika paling dasar hingga sistem operasi yang mampu menjalankan program berorientasi objek. Buku ini diterbitkan oleh MIT Press dan pertama kali muncul pada tahun 2005. Gagasan utamanya sederhana namun ambisius, yaitu membangun sebuah komputer modern dari nol. Pembaca tidak hanya membaca teori, tetapi juga benar-benar merancang, membangun, dan menguji setiap lapisan sistem, baik perangkat keras maupun perangkat lunak.

Filosofi yang mendasari buku ini adalah bahwa cara terbaik untuk memahami sesuatu adalah dengan membangunnya sendiri. Buku ini tidak menyajikan komputer sebagai kotak hitam yang ajaib, melainkan membongkar setiap lapisan abstraksi dan menunjukkan bagaimana lapisan yang lebih rendah mendukung lapisan yang lebih tinggi. Pembaca diajak untuk melihat bahwa sistem komputasi yang kompleks sebenarnya tersusun dari sejumlah kecil prinsip dasar yang saling terkait. Prinsip-prinsip itu kemudian diulang dan dikembangkan secara rekursif hingga membentuk sistem yang utuh.

Buku ini menggunakan paradigma abstraksi dan implementasi. Setiap bab dimulai dengan penjelasan tentang apa yang harus dilakukan oleh suatu modul, yang disebut abstraksi atau antarmuka. Setelah itu, bab tersebut menjelaskan bagaimana modul tersebut dapat diimplementasikan menggunakan modul-modul yang sudah dibangun sebelumnya. Dengan cara ini, pembaca selalu melihat dua sisi dari setiap komponen, yaitu sisi luar yang menjelaskan layanan yang diberikan, dan sisi dalam yang menjelaskan bagaimana layanan itu diwujudkan.

Perjalanan dalam buku ini terbagi menjadi dua bagian besar. Bagian pertama, yang terdiri dari lima bab, berfokus pada pembangunan platform perangkat keras komputer. Bagian kedua, yang terdiri dari tujuh bab, berfokus pada hierarki perangkat lunak, yang berpuncak pada pembangunan compiler dan sistem operasi sederhana. Seluruh proyek dalam buku ini dapat dikerjakan di komputer pribadi dengan bantuan simulator perangkat keras dan perangkat lunak yang disediakan.

## Paradigma Abstraksi dan Implementasi

Inti dari buku ini adalah gagasan bahwa sistem komputasi yang rumit dapat dipahami jika kita memecahnya menjadi modul-modul yang lebih kecil. Setiap modul memiliki antarmuka yang jelas, yaitu deskripsi tentang apa yang dilakukannya, dan implementasi yang menjelaskan bagaimana hal itu dilakukan. Antarmuka bersifat publik dan digunakan oleh modul lain, sedangkan implementasi bersifat internal dan dapat diubah tanpa memengaruhi modul lain selama antarmukanya tetap sama.

Dengan pendekatan ini, pembaca dapat mempelajari setiap lapisan secara terpisah. Misalnya, ketika mempelajari gerbang logika, pembaca tidak perlu mengetahui bagaimana transistor di dalamnya bekerja. Cukup mengetahui bahwa gerbang Nand, misalnya, menghasilkan keluaran tertentu berdasarkan masukannya. Setelah gerbang dasar dikuasai, gerbang yang lebih kompleks dapat dibangun dari gerbang dasar tersebut. Demikian seterusnya hingga terbentuk komputer lengkap.

Buku ini juga menekankan pentingnya pengujian. Setiap modul, baik perangkat keras maupun perangkat lunak, harus diuji secara terpisah sebelum digabungkan dengan modul lain. Pengujian dilakukan dengan skrip uji dan file pembanding yang telah disediakan. Dengan cara ini, kesalahan dapat dilokalisasi dengan cepat dan pembangunan sistem besar menjadi lebih terkendali.

## Bab 1: Logika Boolean

Bab pertama memperkenalkan dasar dari segala dasar dalam sistem digital, yaitu logika Boolean. Logika Boolean bekerja dengan nilai biner, biasanya dilambangkan dengan 0 dan 1, atau salah dan benar. Semua perangkat digital, mulai dari telepon seluler hingga router jaringan, dibangun dari gerbang logika yang mengimplementasikan fungsi Boolean. Fungsi Boolean dapat dinyatakan dalam beberapa cara, antara lain tabel kebenaran, ekspresi Boolean, dan representasi kanonik.

Gerbang logika adalah perangkat fisik yang mengimplementasikan fungsi Boolean. Gerbang paling dasar yang digunakan dalam buku ini adalah Nand. Dari gerbang Nand, semua gerbang lain dapat dibangun, termasuk Not, And, Or, Xor, Multiplexor, dan Demultiplexor. Not adalah gerbang dengan satu masukan yang membalik nilai masukan. And menghasilkan 1 hanya jika kedua masukannya 1. Or menghasilkan 1 jika salah satu atau kedua masukannya 1. Xor menghasilkan 1 jika kedua masukannya berbeda. Multiplexor memilih salah satu dari dua masukan berdasarkan bit selektor. Demultiplexor melakukan kebalikannya, yaitu menyalurkan satu masukan ke salah satu dari dua keluaran berdasarkan bit selektor.

Selain gerbang dasar, bab ini juga memperkenalkan versi multi-bit dari gerbang-gerbang tersebut. Misalnya, Not16 adalah gerbang Not yang bekerja pada bus 16 bit. And16, Or16, dan Mux16 juga memiliki perilaku yang sama dengan versi satu bitnya, tetapi bekerja pada banyak bit sekaligus. Ada pula gerbang multi-way seperti Or8Way, Mux4Way16, Mux8Way16, DMux4Way, dan DMux8Way. Semua gerbang ini nantinya akan digunakan untuk membangun chip yang lebih kompleks.

Bab ini juga memperkenalkan Hardware Description Language atau HDL. HDL adalah bahasa formal untuk mendeskripsikan chip. Dengan HDL, perancang dapat menulis program yang mendefinisikan antarmuka chip dan menghubungkan chip-chip yang lebih rendah di dalamnya. HDL memungkinkan simulasi dan pengujian chip sebelum benar-benar dibuat dalam silikon. Buku ini menggunakan simulator perangkat keras yang dapat membaca HDL dan menjalankan skrip uji.

## Bab 2: Aritmetika Boolean

Bab kedua membahas bagaimana bilangan direpresentasikan dan dioperasikan dalam sistem digital. Bilangan biner adalah dasar dari semua operasi aritmetika di komputer. Bilangan biner dapat diubah menjadi bilangan desimal dengan menjumlahkan pangkat dua dari setiap bit yang bernilai 1. Penjumlahan biner dilakukan dari bit paling kanan ke kiri, dengan membawa carry ke bit berikutnya. Jika carry terakhir masih 1, maka terjadi overflow.

Untuk merepresentasikan bilangan bertanda, buku ini menggunakan metode komplemen dua. Dalam metode ini, bilangan positif dimulai dengan bit 0, sedangkan bilangan negatif dimulai dengan bit 1. Komplemen dua dari suatu bilangan x diperoleh dengan membalik semua bit x lalu menambahkan 1. Keunggulan metode ini adalah penjumlahan bilangan bertanda dapat dilakukan dengan cara yang sama seperti penjumlahan bilangan positif biasa. Pengurangan juga dapat dilakukan dengan menambahkan komplemen dua dari bilangan yang dikurangkan.

Bab ini kemudian memperkenalkan rangkaian adder. Half-adder adalah chip yang menjumlahkan dua bit dan menghasilkan sum serta carry. Full-adder adalah chip yang menjumlahkan tiga bit, yaitu dua bit masukan dan satu bit carry. Adder 16-bit adalah chip yang menjumlahkan dua bilangan 16-bit. Incrementer adalah chip khusus yang menambahkan 1 pada suatu bilangan. Semua chip ini dibangun dari gerbang logika yang telah dipelajari di bab sebelumnya.

Puncak dari bab ini adalah Arithmetic Logic Unit atau ALU. ALU adalah chip yang mampu melakukan berbagai operasi aritmetika dan logika berdasarkan enam bit kontrol. Operasi yang didukung antara lain penjumlahan, pengurangan, And, Or, negasi, dan perbandingan. ALU menerima dua masukan 16-bit, yaitu x dan y, serta menghasilkan keluaran 16-bit, sinyal zr yang menandakan apakah keluaran bernilai nol, dan sinyal ng yang menandakan apakah keluaran bernilai negatif. ALU ini nantinya akan menjadi jantung dari Central Processing Unit atau CPU.

## Bab 3: Logika Sekuensial

Bab ketiga memperkenalkan logika sekuensial, yaitu jenis rangkaian digital yang dapat menyimpan keadaan atau state. Berbeda dengan rangkaian kombinasional yang keluarannya hanya bergantung pada masukan saat itu, rangkaian sekuensial keluarannya juga bergantung pada keadaan sebelumnya. Untuk itu, diperlukan elemen memori yang dapat mempertahankan nilai sepanjang waktu.

Elemen paling dasar dalam logika sekuensial adalah data flip-flop atau DFF. DFF memiliki satu masukan data dan satu keluaran data. DFF bekerja berdasarkan clock, yaitu sinyal yang berubah secara periodik. Keluaran DFF pada waktu t adalah masukan DFF pada waktu t-1. Dengan kata lain, DFF menunda sinyal masukan selama satu siklus clock. DFF dianggap sebagai primitif dan tidak perlu diimplementasikan dari gerbang yang lebih dasar.

Dari DFF, dapat dibangun register satu bit yang disebut Bit. Bit memiliki masukan data, pin load, dan keluaran. Jika load bernilai 1, maka Bit akan menyimpan nilai masukan pada siklus berikutnya. Jika load bernilai 0, maka Bit akan mempertahankan nilai sebelumnya. Register 16-bit dibangun dari kumpulan Bit. Register ini dapat menyimpan satu word 16-bit.

Selanjutnya, dibangun memori akses acak atau RAM. RAM adalah kumpulan register yang dapat diakses berdasarkan alamat. RAM8 memiliki delapan register, RAM64 memiliki 64 register, RAM512 memiliki 512 register, RAM4K memiliki 4096 register, dan RAM16K memiliki 16384 register. Setiap RAM memiliki masukan data 16-bit, masukan alamat, pin load, dan keluaran 16-bit. Operasi baca dilakukan dengan memberikan alamat dan membaca keluaran. Operasi tulis dilakukan dengan memberikan alamat, data, dan mengaktifkan pin load.

Bab ini juga memperkenalkan counter atau pencacah. Counter adalah chip yang menyimpan bilangan bulat dan menambahkannya setiap siklus clock. Counter memiliki pin reset, load, dan inc. Counter biasanya digunakan sebagai program counter dalam CPU, yaitu register yang menyimpan alamat instruksi berikutnya yang akan dieksekusi.

## Bab 4: Bahasa Mesin

Bab keempat membahas bahasa mesin, yaitu antarmuka paling dasar antara perangkat lunak dan perangkat keras. Bahasa mesin adalah formalism yang telah disepakati untuk menulis program tingkat rendah sebagai rangkaian instruksi mesin. Setiap instruksi mesin dapat memerintahkan prosesor untuk melakukan operasi aritmetika, logika, akses memori, dan lompatan bersyarat.

Bahasa mesin biasanya dispesifikasikan dalam dua bentuk, yaitu kode biner dan notasi simbolik yang disebut assembly. Kode biner adalah representasi sebenarnya yang dipahami perangkat keras. Assembly adalah notasi yang lebih mudah dibaca manusia, yang nantinya diterjemahkan oleh assembler menjadi kode biner. Bahasa mesin memiliki beberapa kategori perintah, yaitu operasi aritmetika dan logika, akses memori, dan aliran kontrol.

Bab ini kemudian memperkenalkan bahasa mesin Hack secara rinci. Hack adalah komputer 16-bit dengan dua ruang alamat terpisah, yaitu memori instruksi dan memori data. CPU Hack hanya dapat mengeksekusi program yang berada di memori instruksi. Program dimuat ke memori instruksi melalui cara eksternal, misalnya dengan mengganti chip ROM. Hack memiliki dua register 16-bit, yaitu D dan A. Register D digunakan untuk menyimpan data, sedangkan register A dapat digunakan sebagai data, alamat memori data, atau alamat memori instruksi.

Bahasa mesin Hack terdiri dari dua jenis instruksi, yaitu A-instruction dan C-instruction. A-instruction digunakan untuk memasukkan nilai 15-bit ke register A. C-instruction adalah instruksi yang melakukan komputasi, menyimpan hasil, dan menentukan instruksi berikutnya. C-instruction memiliki field comp yang menentukan operasi ALU, field dest yang menentukan tujuan penyimpanan, dan field jump yang menentukan kondisi lompatan. Hack juga mendukung simbol-simbol yang telah ditentukan sebelumnya, seperti R0 sampai R15, SP, LCL, ARG, THIS, THAT, SCREEN, dan KBD. Simbol-simbol ini memudahkan penulisan program assembly.

Bab ini juga membahas penanganan input/output pada Hack. Layar Hack adalah layar hitam-putih berukuran 256 baris kali 512 kolom. Layar dipetakan ke memori mulai alamat 16384. Setiap baris layar diwakili oleh 32 word 16-bit. Keyboard dipetakan ke alamat memori 24576. Ketika sebuah tombol ditekan, kode ASCII tombol tersebut muncul di alamat itu. Jika tidak ada tombol yang ditekan, nilai yang muncul adalah 0.

## Bab 5: Arsitektur Komputer

Bab kelima adalah puncak dari bagian perangkat keras. Bab ini menggabungkan semua chip yang telah dibangun sebelumnya menjadi sebuah komputer lengkap yang disebut Hack. Hack adalah komputer von Neumann 16-bit yang terdiri dari CPU, memori instruksi, memori data, layar, dan keyboard. Konsep stored program menjadi dasar arsitektur ini, yaitu program disimpan di memori dan dapat dieksekusi oleh CPU.

CPU Hack terdiri dari ALU, register D, register A, dan program counter. CPU menerima instruksi dari memori instruksi, mengeksekusinya, dan menentukan alamat instruksi berikutnya. CPU juga berinteraksi dengan memori data melalui sinyal inM, outM, writeM, addressM, dan pc. Program counter bertanggung jawab untuk melacak alamat instruksi berikutnya. Jika terjadi lompatan, program counter akan dimuat dengan nilai dari register A. Jika tidak, program counter akan bertambah satu.

Memori data Hack terdiri dari RAM16K, layar, dan keyboard. RAM16K menempati alamat 0 sampai 16383. Layar menempati alamat 16384 sampai 24575. Keyboard menempati alamat 24576. Semua perangkat ini disatukan dalam chip Memory yang menyediakan satu ruang alamat logis. Dengan cara ini, program dapat mengakses layar dan keyboard seolah-olah mereka adalah memori biasa.

Chip teratas dalam hierarki perangkat keras adalah Computer. Chip ini berisi CPU, ROM32K, Memory, Screen, dan Keyboard. Untuk menjalankan program, program harus dimuat ke ROM32K. Ketika sinyal reset diberikan, program akan mulai dieksekusi dari alamat 0. Bab ini juga memberikan panduan implementasi CPU, Memory, dan Computer, serta menekankan pentingnya pengujian setiap komponen sebelum digabungkan.

## Bab 6: Assembler

Bab keenam memulai bagian perangkat lunak. Bab ini membahas assembler, yaitu program yang menerjemahkan program assembly menjadi kode biner. Assembler adalah modul pertama dalam hierarki perangkat lunak dan merupakan contoh sederhana dari proses translasi yang lebih kompleks. Assembler membaca file `.asm` dan menghasilkan file `.hack`.

Tugas utama assembler adalah memparsing setiap perintah assembly menjadi field-fieldnya, menerjemahkan setiap field menjadi kode biner yang sesuai, mengganti semua referensi simbolik dengan alamat numerik, dan merakit kode biner menjadi instruksi mesin lengkap. Tiga tugas pertama relatif mudah, sedangkan tugas keempat, yaitu penanganan simbol, lebih menantang.

Simbol dalam program assembly berasal dari tiga sumber. Pertama, simbol yang telah ditentukan sebelumnya seperti SP, LCL, ARG, THIS, THAT, R0 sampai R15, SCREEN, dan KBD. Kedua, label yang dideklarasikan dengan pseudo-command `(xxx)`. Ketiga, variabel yang muncul pertama kali sebagai simbol dan belum didefinisikan. Assembler menggunakan tabel simbol untuk memetakan simbol ke alamat memori. Tabel simbol biasanya diimplementasikan sebagai hash table.

Untuk menangani label yang mungkin didefinisikan setelah digunakan, assembler bekerja dalam dua pass. Pass pertama membaca seluruh program dan membangun tabel simbol untuk label. Pass kedua membaca ulang program dan menghasilkan kode biner, sambil menangani variabel yang belum dikenal dengan mengalokasikan alamat RAM mulai dari 16. Dengan cara ini, assembler dapat menghasilkan kode biner yang benar untuk program assembly Hack.

## Bab 7: Mesin Virtual I: Aritmetika Stack

Bab ketujuh memperkenalkan mesin virtual atau VM. VM adalah komputer abstrak yang tidak ada secara fisik, tetapi dapat diimplementasikan pada platform lain. Pendekatan ini memisahkan compiler menjadi dua bagian, yaitu front-end yang menerjemahkan bahasa tingkat tinggi ke kode VM, dan back-end yang menerjemahkan kode VM ke bahasa mesin target. Model ini digunakan oleh Java dan C#.

VM yang digunakan dalam buku ini adalah VM berbasis stack. Semua operasi dilakukan pada stack. Perintah aritmetika seperti add, sub, neg, eq, gt, lt, and, or, dan not mengambil operand dari stack, melakukan operasi, dan menaruh hasilnya kembali ke stack. VM juga memiliki perintah akses memori seperti push dan pop untuk delapan segmen memori virtual, yaitu argument, local, static, constant, this, that, pointer, dan temp.

Segmen argument menyimpan argumen fungsi. Segmen local menyimpan variabel lokal. Segmen static menyimpan variabel statis yang dibagi oleh semua fungsi dalam file `.vm` yang sama. Segmen constant adalah pseudo-segmen yang menyimpan konstanta. Segmen this dan that adalah segmen umum yang dapat menunjuk ke area berbeda di heap. Segmen pointer menyimpan alamat dasar segmen this dan that. Segmen temp menyimpan delapan variabel sementara.

Bab ini juga membahas pemetaan standar VM ke platform Hack. Stack global ditempatkan mulai alamat RAM 256. Segmen local, argument, this, dan that dipetakan ke RAM dan alamat dasarnya disimpan di register LCL, ARG, THIS, dan THAT. Segmen pointer dipetakan ke RAM 3-4, dan segmen temp dipetakan ke RAM 5-12. Segmen static dipetakan ke simbol assembly `xxx.j` untuk setiap variabel statis j dalam file `xxx.vm`. Segmen constant ditangani dengan memasukkan nilai konstanta langsung ke stack.

Implementasi VM translator melibatkan dua modul, yaitu Parser dan CodeWriter. Parser membaca file `.vm` dan memecah perintah menjadi komponen-komponennya. CodeWriter menerjemahkan setiap perintah VM menjadi kode assembly Hack. Bab ini berfokus pada perintah aritmetika dan akses memori. Perintah program flow dan function calling akan dibahas di bab berikutnya.

## Bab 8: Mesin Virtual II: Kontrol Program

Bab kedelapan melanjutkan pengembangan VM dengan menambahkan perintah aliran program dan pemanggilan fungsi. Perintah aliran program meliputi label, goto, dan if-goto. Perintah ini memungkinkan pembuatan struktur kontrol seperti if, else, while, dan for. Label digunakan untuk menandai lokasi dalam kode. Goto melakukan lompatan tanpa syarat. If-goto melakukan lompatan bersyarat berdasarkan nilai teratas di stack.

Perintah pemanggilan fungsi meliputi function, call, dan return. Function mendeklarasikan fungsi dengan sejumlah variabel lokal. Call memanggil fungsi dengan sejumlah argumen yang telah didorong ke stack. Return mengembalikan kontrol ke fungsi pemanggil. Untuk mendukung pemanggilan fungsi bersarang dan rekursif, VM menggunakan stack global. Setiap kali fungsi dipanggil, sebuah frame baru ditambahkan ke stack. Frame berisi argumen, alamat kembali, penyimpanan register pemanggil, variabel lokal, dan working stack.

Protokol pemanggilan fungsi diimplementasikan dengan serangkaian operasi. Sebelum memanggil fungsi, pemanggil mendorong argumen ke stack. Perintah call kemudian mendorong alamat kembali, menyimpan LCL, ARG, THIS, dan THAT, mengatur ulang ARG dan LCL, lalu melompat ke fungsi. Di dalam fungsi, perintah function menginisialisasi variabel lokal dengan 0. Perintah return menyimpan nilai kembali, mengembalikan SP, THAT, THIS, ARG, dan LCL, lalu melompat ke alamat kembali.

Bab ini juga memperkenalkan bootstrap code. Ketika komputer dinyalakan, program mulai dari alamat ROM 0. Bootstrap code menginisialisasi stack pointer ke 256 dan memanggil Sys.init. Fungsi Sys.init kemudian memanggil Main.main. Dengan cara ini, program VM dapat mulai berjalan. Bab ini juga memberikan contoh dinamis dari pemanggilan fungsi, termasuk bagaimana stack berubah selama pemanggilan dan pengembalian fungsi.

## Bab 9: Bahasa Tingkat Tinggi Jack

Bab kesembilan memperkenalkan Jack, sebuah bahasa pemrograman tingkat tinggi berbasis objek yang dirancang sederhana namun cukup umum. Jack memiliki kemiripan dengan Java dan C#, tetapi tanpa pewarisan. Jack digunakan sebagai bahasa target compiler yang akan dibangun di bab berikutnya. Program Jack terdiri dari satu atau lebih kelas. Setiap kelas berada dalam file terpisah dan dapat dikompilasi secara terpisah.

Setiap kelas Jack dapat berisi deklarasi variabel field dan static, serta deklarasi subroutine. Subroutine dapat berupa constructor, method, atau function. Method terkait dengan objek dan memiliki akses ke field objek. Function tidak terkait dengan objek tertentu, mirip dengan static method di Java. Constructor digunakan untuk membuat objek baru. Jack mendukung tipe primitif int, char, dan boolean, serta tipe objek yang merupakan nama kelas.

Jack memiliki pernyataan let, if, else, while, do, dan return. Ekspresi Jack dibangun dari konstanta, variabel, this, elemen array, pemanggilan subroutine, operator unary, dan operator biner. Jack tidak mendefinisikan prioritas operator, sehingga ekspresi seperti `2+3*4` dapat menghasilkan 20 atau 14 tergantung implementasi. Tanda kurung digunakan untuk memperjelas urutan evaluasi. Jack juga memiliki pustaka standar yang mencakup kelas Math, String, Array, Output, Screen, Keyboard, Memory, dan Sys.

Bab ini juga memberikan contoh aplikasi Jack, termasuk Hello World, pemrosesan array, tipe data abstrak Fraction, dan implementasi linked list. Jack dapat digunakan untuk membuat aplikasi interaktif seperti game Pong. Pengembangan aplikasi Jack melibatkan perancangan kelas, field, dan subroutine, serta pengujian menggunakan compiler Jack dan VM emulator. Sistem operasi Jack, yang ditulis dalam Jack, harus disertakan bersama program agar dapat berjalan.

## Bab 10: Compiler I: Analisis Sintaks

Bab kesepuluh memulai pembangunan compiler untuk bahasa Jack. Compiler adalah program yang menerjemahkan program dari bahasa sumber ke bahasa target. Proses kompilasi dibagi menjadi dua tugas utama, yaitu analisis sintaks dan generasi kode. Bab ini fokus pada analisis sintaks, yaitu proses memahami struktur program sumber.

Analisis sintaks dimulai dengan analisis leksikal atau tokenizing. Program sumber yang berupa rangkaian karakter dipecah menjadi token-token, seperti keyword, symbol, identifier, integer constant, dan string constant. Setelah token diperoleh, proses parsing dilakukan untuk mencocokkan aliran token dengan aturan tata bahasa. Tata bahasa Jack didefinisikan menggunakan context-free grammar. Parser yang digunakan adalah recursive descent parser, yang bekerja dengan memanggil routine secara rekursif sesuai aturan grammar.

Bab ini mendefinisikan grammar lengkap bahasa Jack, termasuk struktur kelas, deklarasi variabel, subroutine, pernyataan, dan ekspresi. Syntax analyzer yang dibangun akan menghasilkan output XML yang mencerminkan struktur sintaksis program. XML ini dapat dilihat di browser web dan digunakan untuk memverifikasi bahwa analyzer bekerja dengan benar. Bab ini juga memberikan API untuk modul JackTokenizer dan CompilationEngine.

Implementasi syntax analyzer melibatkan tiga modul, yaitu JackAnalyzer sebagai driver, JackTokenizer untuk tokenizing, dan CompilationEngine untuk parsing. CompilationEngine memiliki routine compileClass, compileClassVarDec, compileSubroutine, compileParameterList, compileVarDec, compileStatements, compileDo, compileLet, compileWhile, compileReturn, compileIf, compileExpression, compileTerm, dan compileExpressionList. Setiap routine membaca elemen sintaksis tertentu dari input, memajukan tokenizer, dan menghasilkan output XML.

## Bab 11: Compiler II: Generasi Kode

Bab kesebelas melanjutkan compiler dengan menambahkan generasi kode. Compiler yang lengkap akan menerjemahkan program Jack menjadi kode VM. Proses ini melibatkan dua isu utama, yaitu translasi data dan translasi perintah. Translasi data mencakup pengelolaan variabel, array, dan objek. Translasi perintah mencakup evaluasi ekspresi dan aliran kontrol.

Untuk mengelola variabel, compiler menggunakan tabel simbol. Tabel simbol mencatat nama, tipe, jenis, dan indeks setiap identifier. Variabel dapat berupa static, field, argument, atau local. Variabel static dialokasikan ke segmen static VM. Variabel field dialokasikan ke segmen this. Variabel argument dialokasikan ke segmen argument. Variabel local dialokasikan ke segmen local. Array dan objek dialokasikan di heap menggunakan fungsi Memory.alloc.

Generasi kode untuk ekspresi dilakukan dengan traversal pohon parse secara post-order. Untuk target berbasis stack, ekspresi diterjemahkan menjadi urutan perintah push dan operasi. Misalnya, ekspresi `x + g(2, y, -z) * 5` diterjemahkan menjadi push x, push 2, push y, push z, neg, call g, push 5, call multiply, add. Aliran kontrol seperti if dan while diterjemahkan menggunakan label dan goto. Compiler harus menghasilkan label unik untuk setiap struktur kontrol.

Bab ini juga memberikan contoh kompilasi lengkap dari kelas BankAccount, yang menunjukkan bagaimana statement `let balance = (balance + sum) - commission(sum * 5)` diterjemahkan menjadi kode VM. Compiler Jack menghasilkan satu file `.vm` untuk setiap file `.jack`. Setiap subroutine Jack menjadi satu fungsi VM. Method Jack menjadi fungsi VM dengan argumen pertama adalah referensi ke objek this. Constructor Jack mengalokasikan memori untuk objek baru dan mengatur segmen this.

## Bab 12: Sistem Operasi

Bab kedua belas membahas sistem operasi Jack. Sistem operasi ini adalah kumpulan kelas Jack yang menyediakan layanan dasar bagi program Jack. Layanan ini mencakup operasi matematika, manipulasi string, alokasi memori, output teks dan grafik, input keyboard, dan layanan eksekusi. Sistem operasi ini ditulis dalam Jack dan dikompilasi menjadi file `.vm` yang harus disertakan bersama program aplikasi.

Kelas Math menyediakan fungsi absolut, perkalian, pembagian, minimum, maksimum, dan akar kuadrat. Perkalian dan pembagian diimplementasikan dengan algoritma efisien yang berjalan dalam waktu O(n) operasi penjumlahan, bukan O(x) atau O(y) yang eksponensial. Kelas String menyediakan konstruktor string, metode length, charAt, setCharAt, appendChar, eraseLastChar, intValue, dan setInt. Kelas Array menyediakan konstruktor array dan metode dispose.

Kelas Output menangani output teks ke layar. Kelas Screen menangani output grafik, termasuk menggambar pixel, garis, persegi panjang, dan lingkaran. Kelas Keyboard menangani input dari keyboard, termasuk keyPressed, readChar, readLine, dan readInt. Kelas Memory menyediakan akses langsung ke memori utama, termasuk peek, poke, alloc, dan deAlloc. Kelas Sys menyediakan init, halt, error, dan wait. Sys.init dipanggil saat boot dan bertanggung jawab menginisialisasi semua kelas OS lalu memanggil Main.main.

Implementasi OS ini melibatkan algoritma klasik seperti perkalian, pembagian, akar kuadrat, konversi string-number, alokasi memori dinamis, dan penggambaran grafik. Bab ini juga memberikan tips implementasi, misalnya penggunaan array statis untuk mempercepat fungsi bit, penanganan overflow, dan trik untuk mengakses memori langsung dari Jack. Pengujian OS dilakukan secara bertahap untuk setiap kelas, dan akhirnya diuji dengan game Pong.

## Bab 13: Postscript: More Fun to Go

Bab terakhir memberikan semangat untuk melanjutkan eksplorasi. Setelah menyelesaikan seluruh proyek, pembaca diundang untuk memodifikasi dan memperluas sistem yang telah dibangun. Berbagai ide pengembangan disajikan, seperti realisasi perangkat keras nyata, peningkatan arsitektur Hack, penambahan kemampuan memuat program, pengembangan bahasa tingkat tinggi baru, optimasi, dan komunikasi melalui Internet.

Buku ini menekankan bahwa desain adalah bagian yang paling menyenangkan dari setiap proyek. Pembaca didorong untuk bereksperimen dengan spesifikasi bahasa assembly, bahasa Jack, sistem operasi, VM, dan perangkat keras. Semua kode sumber software yang menyertai buku tersedia secara publik dan dapat dimodifikasi. Pembaca juga dapat menambahkan chip built-in baru pada simulator perangkat keras untuk memperluas platform.

## Lampiran A: Hardware Description Language

Lampiran ini memberikan referensi teknis untuk HDL yang digunakan dalam buku. HDL adalah bahasa formal untuk mendefinisikan dan menguji chip. Setiap chip didefinisikan dalam file terpisah dengan ekstensi `.hdl`. Struktur chip terdiri dari header dan body. Header menentukan antarmuka chip, yaitu nama chip dan pin masukan serta keluaran. Body menentukan implementasi chip, yaitu chip-chip yang lebih rendah yang saling terhubung.

HDL mendukung pin tunggal dan bus multi-bit. Koneksi antar pin dinyatakan dengan sintaks `pin_tujuan = pin_sumber`. Pin internal dapat dibuat sesuai kebutuhan. HDL juga mendukung chip built-in yang diimplementasikan dalam Java. Chip built-in dapat memiliki GUI untuk visualisasi. Chip sekuensial dideklarasikan dengan kata kunci CLOCKED. Feedback loop diperbolehkan hanya jika melewati pin yang clocked.

## Lampiran B: Test Scripting Language

Lampiran ini menjelaskan bahasa skrip untuk menguji chip dan program. Setiap simulator, baik hardware simulator, CPU emulator, maupun VM emulator, mendukung bahasa skrip yang serupa. File skrip uji memiliki ekstensi `.tst`. File output memiliki ekstensi `.out`, dan file pembanding memiliki ekstensi `.cmp`.

Perintah dalam skrip uji mencakup load, output-file, output-list, compare-to, set, eval, output, tick, tock, repeat, while, echo, breakpoint, dan clear-breakpoints. Untuk CPU emulator, perintah ticktock digunakan sebagai ganti tick dan tock. Untuk VM emulator, perintah vmstep digunakan untuk menjalankan satu perintah VM. Skrip uji memungkinkan pengujian yang sistematis, dapat diulang, dan terdokumentasi.

## Penutup

Buku _The Elements of Computing Systems_ adalah perjalanan yang luar biasa dari gerbang Nand hingga sistem operasi. Pembaca tidak hanya belajar tentang komputer, tetapi juga tentang bagaimana memecah masalah besar menjadi modul-modul kecil, bagaimana merancang antarmuka yang baik, dan bagaimana menguji setiap komponen secara menyeluruh. Dengan menyelesaikan semua proyek, pembaca akan memiliki pemahaman yang mendalam tentang cara kerja komputer modern, mulai dari transistor hingga aplikasi berorientasi objek. Buku ini membuktikan bahwa dengan prinsip yang tepat, hal yang tampak rumit dapat dipahami dan dibangun dari awal.
