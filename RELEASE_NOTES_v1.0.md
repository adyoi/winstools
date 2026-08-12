# Winstools v1.0 — Release Notes

**Tanggal:** 12 Agustus 2026
**Build:** `1.0.0.0` · **Bahasa:** Indonesian · **Platform:** Windows 10/11 (x64)

## Tentang

**Winstools (Windows Super Tools)** adalah utilitas manajemen & perawatan Windows berbasis PowerShell + Windows Forms. Setiap tool berjalan pada tab independen (multi-session), sehingga beberapa tool dapat berjalan bersamaan tanpa saling menunggu.

## Fitur Utama

- **Multi-session** — setiap tool berjalan di tab sendiri, dapat dibuka bersamaan.
- **Welcome Dashboard** — ringkasan spesifikasi sistem: OS, CPU, RAM, GPU, penyimpanan, jaringan, status aktivasi Windows, BIOS.
- **Console output berwarna** per session dengan log terstruktur `[INFO] [WARNING] [ERROR] [SUCCESS]`.
- **Custom UI per tool** — antarmuka setiap tool didefinisikan modular.
- **Elevasi otomatis** — meminta izin Administrator saat dijalankan.
- **Data runtime aman** — konfigurasi tersimpan di `%LOCALAPPDATA%\Winstools`, tidak tertimpa saat update.

## Daftar Tools

| Kategori | Tool |
| --- | --- |
| Network | Clear DNS, Proxy Manager |
| Maintenance | Clear Logs, Disk Repair, Event Log, Win Update Reset |
| Advanced | Custom Command (save/load JSON) |
| Customization | God Mode, Set OEM |
| Security | Virus Scan (ClamAV) |

## Cara Menjalankan

1. Unduh `winstools.exe`.
2. Pastikan folder berisi `Modules\`, `Tools\`, dan `Icons\` (hasil build self-contained).
3. Double-click `winstools.exe` — aplikasi akan meminta hak Administrator secara otomatis.

> **Catatan keamanan:** File ini ditandatangani dengan sertifikat code signing *WINSTOOLS CodeSigning* (SHA256 + timestamp DigiCert). Jika Windows menampilkan *"Unknown Publisher"*, itu karena Root CA internal belum di-trust di mesin Anda — instal `CA\rootCA.cer` ke *Trusted Root Certification Authorities* (opsional, untuk menghilangkan peringatan).

## Verifikasi Build

- **Tanda tangan:** Valid (Authenticode SHA256 + timestamp DigiCert)
- **Signer:** `WINSTOOLS CodeSigning <adyoix@gmail.com>`
- **MD5:** `839412C743750A5948F8F99080684331`
- **SHA-256:** `1EFF1FBBC80895002F5855626E0E7A9775E3FDD07B8F23D068E0FEC1E1F8FF50`

## Riwayat

- **v1.0.0.0** — rilis perdana: seluruh tool inti, multi-session, welcome dashboard, build pipeline (compile + versi + sign + verify), suite uji otomatis (48 test), CI GitHub Actions.

---

Copyright © 2026 PT (Perorangan) Adidaya Karya Utama. All rights reserved.
Dilisensikan di bawah **MIT License** — lihat `LICENSE`.
