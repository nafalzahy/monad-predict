# 🟣 MonadPredict

**Prediction market di Monad Testnet.** Tebak masa depan dengan MON: beli saham **Ya** atau **Tidak**, harga otomatis menunjukkan peluangnya, dan pemenang menarik hadiah langsung dari smart contract.

🔗 **Coba langsung:** https://monad-predict.vercel.app
📜 **Smart contract:** `0x9696028adE0493F06eD004F320447BeF58b1883e` ([lihat di explorer](https://testnet.monadvision.com/address/0x9696028adE0493F06eD004F320447BeF58b1883e))
🌐 **Jaringan:** Monad Testnet (hanya testnet, tanpa uang asli)

---

## Isi README

1. [Apa itu MonadPredict](#apa-itu-monadpredict)
2. [Fitur](#fitur)
3. [Cara memakai (untuk pengguna)](#cara-memakai-untuk-pengguna)
4. [Cara kerja harga dan hadiah](#cara-kerja-harga-dan-hadiah)
5. [Cara menjalankan sendiri (untuk developer)](#cara-menjalankan-sendiri-untuk-developer)
6. [Struktur project](#struktur-project)
7. [Fungsi smart contract](#fungsi-smart-contract)
8. [Batasan dan keamanan](#batasan-dan-keamanan)
9. [Masalah umum](#masalah-umum)

---

## Apa itu MonadPredict

Prediction market adalah pasar tempat orang "bertaruh" pada hasil sebuah peristiwa, misalnya *"Apakah BTC tembus 150 ribu USD sebelum 2027?"*.

- Kalau kamu yakin jawabannya **Ya**, beli saham Ya.
- Kalau kamu yakin **Tidak**, beli saham Tidak.
- Harga saham Ya sama dengan peluang yang dipercaya pasar. Harga 62¢ berarti peluang 62%.
- Setelah pasar selesai, saham yang benar bernilai **1 MON**, yang salah bernilai **0**.

Semuanya berjalan di smart contract Solidity di Monad, jadi transparan dan tidak butuh perantara.

## Fitur

| Fitur | Keterangan |
|---|---|
| Buat pasar sendiri | Isi pertanyaan, deskripsi aturan, kategori, emoji, waktu tutup, dan likuiditas awal |
| Beli dan jual kapan saja | Ambil untung atau batasi rugi sebelum pasar tutup |
| Harga = probabilitas | Persentase besar di tiap kartu dan grafik pergerakan peluang |
| Estimasi sebelum transaksi | Jumlah saham dan potensi untung terlihat sebelum konfirmasi |
| Perlindungan slippage | Transaksi dibatalkan bila harga bergeser lebih dari sekitar 3% |
| Portofolio | Semua posisi, nilai perkiraan, dan pasar buatanmu dalam satu halaman |
| Klaim hadiah | Pemenang menarik MON langsung dari contract |
| Pencarian dan kategori | Crypto, Politik, Olahraga, Teknologi, Hiburan, Lainnya |
| Fee 1% untuk pembuat pasar | Insentif untuk membuat pasar yang ramai |
| Tanpa server | Data dibaca langsung dari blockchain |

## Cara memakai (untuk pengguna)

Kamu hanya butuh browser Chrome (atau Brave/Edge) dengan ekstensi **MetaMask**.

### 1. Siapkan wallet
1. Pasang MetaMask dari https://metamask.io/download lalu buat wallet.
2. **Gunakan wallet khusus testnet.** Jangan pakai wallet berisi uang asli.

### 2. Ambil MON testnet gratis
1. Buka https://faucet.monad.xyz.
2. Tempel alamat wallet-mu lalu klaim MON.
3. Tunggu sebentar sampai saldo masuk.

### 3. Buka aplikasi dan hubungkan wallet
1. Buka https://monad-predict.vercel.app.
2. Klik **Connect Wallet** di pojok kanan atas dan setujui di MetaMask.
3. Jika diminta, setujui penambahan jaringan **Monad Testnet**. Kalau perlu menambahkan manual:

| Pengaturan | Nilai |
|---|---|
| Network name | Monad Testnet |
| RPC URL | `https://testnet-rpc.monad.xyz` |
| Chain ID | `10143` |
| Currency symbol | `MON` |
| Block explorer | `https://testnet.monadvision.com` |

### 4. Beli saham
1. Pilih sebuah pasar dari halaman utama.
2. Di panel kanan, pilih **Ya** atau **Tidak**.
3. Isi jumlah MON (minimal 0.001 MON) atau pakai tombol cepat `+0.1`, `+0.5`, `+1`.
4. Lihat estimasi saham dan potensi untung, lalu klik **Beli**.
5. Konfirmasi di MetaMask dan tunggu pesan **Berhasil ✅**.

### 5. Jual saham (opsional)
1. Di pasar yang sama, buka tab **Jual**.
2. Pilih sisi (Ya/Tidak), isi jumlah saham atau klik **Maks**.
3. Klik **Jual** dan konfirmasi. MON kembali ke walletmu setelah dipotong fee 1%.

### 6. Pantau posisi
Buka menu **Portofolio** untuk melihat semua saham yang kamu pegang dan pasar yang kamu buat.

### 7. Klaim hadiah
1. Setelah pasar ditutup dan hasilnya diputuskan, buka pasar tersebut.
2. Jika sisi yang kamu beli menang, muncul tombol **Klaim ... MON**.
3. Klik dan konfirmasi. 1 saham pemenang = 1 MON.

### 8. Buat pasar sendiri
1. Klik **+ Buat pasar** di halaman utama.
2. Isi:
   - **Pertanyaan** yang jawabannya Ya atau Tidak.
   - **Deskripsi dan aturan**: tulis sumber data dan kriteria menang dengan jelas.
   - **Kategori** dan **emoji**.
   - **Waktu tutup** (minimal 2 menit dari sekarang).
   - **Likuiditas awal** (minimal 0.01 MON). Dana ini kembali kepadamu setelah pasar diputuskan.
3. Klik **Buat pasar** dan konfirmasi.

### 9. Putuskan hasil pasar buatanmu
1. Setelah waktu tutup lewat, buka pasarmu dengan akun pembuat.
2. Klik **Hasil: YA** atau **Hasil: TIDAK**.
3. Klik **Tarik fee & likuiditas** untuk mengambil fee 1% dan sisa likuiditas.

> **Penting:** hasil diputuskan oleh pembuat pasar, jadi tulis aturan resolusi yang jelas dan jujur dalam keputusan.

## Cara kerja harga dan hadiah

MonadPredict memakai **AMM (Automated Market Maker)** dengan rumus `x · y = k`.

- Tiap pasar punya dua kolam saham: Ya dan Tidak, diisi likuiditas awal pembuat pasar. Awalnya seimbang, jadi harga **50% / 50%**.
- Saat seseorang membeli **Ya**, kolam Ya berkurang dan harga Ya naik. Makin banyak yang beli, makin mahal.
- Harga Ya = `kolam Tidak / (kolam Ya + kolam Tidak)`.
- **Fee 1%** dipotong dari setiap pembelian dan penjualan, diberikan ke pembuat pasar.
- Setelah pasar diputuskan: 1 saham pemenang = **1 MON**, saham yang kalah = 0.
- Sisa likuiditas di kolam pemenang kembali ke pembuat pasar.

Contoh: harga Ya 40¢. Kamu beli saham Ya senilai 1 MON dan mendapat sekitar 2,4 saham (harga rata-rata sedikit di atas 40¢ karena harga ikut naik saat kamu membeli). Jika hasilnya **Ya**, kamu menarik sekitar 2,4 MON. Jika **Tidak**, sahammu bernilai 0.

## Cara menjalankan sendiri (untuk developer)

### Prasyarat
- Git dan Node.js
- [Foundry](https://book.getfoundry.sh) versi Monad
- Windows: gunakan **WSL (Ubuntu)**
- MetaMask dan MON testnet

### 1. Clone dan install
```bash
git clone https://github.com/nafalzahy/monad-predict.git
cd monad-predict
curl -L https://foundry.category.xyz | bash
foundryup --network monad
```

### 2. Compile dan tes
```bash
forge build
forge test -vv
```
Semua tes harus `[PASS]`.

### 3. Siapkan wallet deploy
```bash
cast wallet import monad-deployer --interactive
```
Tempel private key wallet **testnet** dan buat password. Jangan pernah commit private key ke GitHub.

### 4. Deploy contract
```bash
forge create src/MonadPredict.sol:MonadPredict \
  --rpc-url https://testnet-rpc.monad.xyz \
  --account monad-deployer \
  --broadcast
```
Simpan alamat dari baris `Deployed to: 0x...`.

### 5. Hubungkan tampilan
Buka `index.html` (atau `web/index.html`) dan ganti:
```js
const CONTRACT_ADDRESS = "0xALAMAT_CONTRACT_KAMU";
```

### 6. (Opsional) Isi pasar contoh
```bash
cast send 0xALAMAT_CONTRACT "createMarket(string,string,string,string,uint64)" \
  "Apakah BTC tembus 150 ribu USD sebelum 2027?" "Sumber: harga BTC/USD di Coinbase." "Crypto" "₿" \
  $(( $(date +%s) + 2592000 )) \
  --value 0.05ether --rpc-url https://testnet-rpc.monad.xyz --account monad-deployer
```

### 7. Jalankan tampilan lokal
Tampilan hanya satu file statis, jadi cukup server sederhana:
```bash
python3 -m http.server 3000
```
Buka `http://localhost:3000`. Jalankan perintah dari folder yang berisi `index.html`.

### 8. Deploy ke Vercel
1. Push project ke GitHub.
2. Buka https://vercel.com/new dan import repository.
3. Pastikan `index.html` ada di folder yang dipakai Vercel (taruh di root, atau atur **Root Directory**).
4. Klik **Deploy**. Tidak ada environment variable yang dibutuhkan.

## Struktur project

```
monad-predict/
├── src/
│   └── MonadPredict.sol        # smart contract (Solidity)
├── test/
│   └── MonadPredict.t.sol      # tes Foundry
├── index.html                  # tampilan web (HTML + JS + ethers.js)
├── foundry.toml                # konfigurasi Foundry
└── README.md
```

## Fungsi smart contract

| Fungsi | Siapa | Keterangan |
|---|---|---|
| `createMarket(...)` | Siapa saja | Buat pasar baru, kirim likuiditas awal (min 0.01 MON) |
| `buy(id, isYes, minShares)` | Siapa saja | Beli saham Ya/Tidak selama pasar terbuka (min 0.001 MON) |
| `sell(id, isYes, shares, minReturn)` | Pemegang saham | Jual saham sebelum pasar tutup |
| `resolve(id, yesWon)` | Pembuat pasar atau owner | Putuskan hasil setelah waktu tutup |
| `redeem(id)` | Pemegang saham pemenang | Tarik hadiah 1 saham = 1 MON |
| `claimCreator(id)` | Pembuat pasar | Tarik fee dan sisa likuiditas |
| `getMarkets`, `getTrades`, `quoteBuy`, `quoteSell` | Siapa saja | Fungsi baca untuk tampilan |

Data transaksi disimpan di contract dan dibaca lewat fungsi `view`, sehingga tampilan tidak bergantung pada `eth_getLogs` yang dibatasi RPC publik.

## Batasan dan keamanan

- **Hanya testnet.** MON testnet tidak bernilai uang.
- **Belum diaudit.** Jangan dipakai dengan uang asli.
- **Resolusi terpusat:** hasil diputuskan oleh pembuat pasar (atau deployer). Rencana ke depan: oracle otomatis atau voting.
- **Belum ada pembatalan pasar.** Jika hasil tidak pernah diputuskan, dana di pasar itu tertahan.
- Jaringan testnet bisa direset sewaktu-waktu. Jika itu terjadi, deploy ulang contract dan perbarui alamat di `index.html`.

## Masalah umum

| Masalah | Solusi |
|---|---|
| Halaman bertuliskan "Isi CONTRACT_ADDRESS" | Alamat contract di `index.html` belum diisi |
| MetaMask tidak muncul | Buka lewat Chrome biasa dan pastikan ekstensi MetaMask aktif |
| `insufficient funds` | Klaim MON lagi di https://faucet.monad.xyz |
| Transaksi gagal "Slippage" | Harga bergeser, kurangi jumlah atau coba lagi |
| "Pasar tidak terbuka" | Pasar sudah lewat waktu tutup atau sudah diputuskan |
| Data tidak termuat | Ganti RPC di `index.html` ke `https://rpc.ankr.com/monad_testnet` |
| Vercel menampilkan 404 | Pastikan `index.html` ada di root atau Root Directory sudah benar, lalu Redeploy |
| Jaringan salah | Tambahkan manual Monad Testnet (Chain ID `10143`) seperti di bagian pengguna |

## Tim

Dibuat untuk Hackathon Monad Yogyakarta oleh **[nafalzahy]**.

## Lisensi

MIT