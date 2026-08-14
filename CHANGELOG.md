# Changelog

Semua perubahan penting pada proyek dicatat di sini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.1] - 2026-08-14

### Ditambahkan
- Proxy Manager: dropdown pilihan proxy dari [iplocate/free-proxy-list](https://github.com/iplocate/free-proxy-list) (`all-proxies.txt`), tombol **Refresh**, dan label sumber daftar.
- Konfirmasi (Yes/No) sebelum menjalankan tool berisiko: Clear DNS, Disk Repair, Disable Services, Win Update Reset, Set OEM, Proxy Manager.
- Auto-release di GitHub Actions saat tag `v*` (termasuk installer).
- Build installer Inno Setup: `Build\build-installer.ps1` → `winstools-installer.exe`.
- File `VERSION` sebagai sumber tunggal versi; `build.ps1` membaca versi dari sana secara default.
- Dukungan env `WINSTOOLS_PFX_PASSWORD` untuk password PFX di CI/produksi (fallback: password dev untuk CA lokal).
- Test Pester: skema Fields tool, roundtrip CustomCommands (dengan backup/restore), integritas build exe, flag `RequiresConfirm`.
- `CHANGELOG.md`, `CONTRIBUTING.md`, badge status CI di README.

### Diubah
- Rename tool **Event Log** → **Clear Event Logs**.
- Rename tool **Virus Scan** → **Virus Scan (ClamAV)**.
- Rename modul tool agar konsisten dengan nama file (toolName = nama file): `CustomCommand` → `CommandManagement`, `DiskRepair` → `DiskManagement`, `NetworkDiagnostics` → `NetworkManagement`, `ProxyManager` → `ProxyManagement`, `DisableServices` → `ServiceManagement`, `GodMode` → `WinGodMode`, `SetOEM` → `WinOEM`.
- Rename skrip build: `build.ps1` → `build-exe.ps1`, `set-versioninfo.ps1` → `setup-vi.ps1`, `installer.iss` → `config-installer.iss`.
- CI build untuk push ke `main` memakai versi dari file `VERSION` (bukan hardcoded).
- README: dokumentasi installer, VERSION default, env password, proxy list, tombol Options.

### Ditambahkan (1.0.1)
- **Tombol Options** (merah + separator) di menu utama: dialog dengan tab **Gui Config** (Environment Development/Production, Debug, LogLevel), **Gui Builder** (jalankan `build-exe.ps1`), **Gui Tester** (Pester / form test), **Update** (cek rilis GitHub `adyoi/winstools` + download), **Changelog**, dan **About**.

### Diperbaiki
- Options: output log tidak lagi tertimpa tombol (layout panel atas + `Dock=Fill` di tab Builder/Tester/Update).
- Options Gui Config: "Muat Nilai Aktif" kini benar menampilkan nilai (`SelectedIndex`, tanpa menimpa oleh handler Environment).
- Options Gui Tester: runner kompatibel Pester 5 (`-Path`) dan 3.x (`-Script`); output `Write-Host` tertangkap via `*>&1`.
- Capture test: path root tidak lagi di-hardcode (dipakai `$PSScriptRoot`).- Versi aplikasi (judul form, header menu, welcome) dibaca dinamis dari file `VERSION`.
- Options: dialog kini tidak lagi memunculkan error "Cannot bind parameter 'Path'..." saat dibuka dari EXE terinstal (fallback `Get-ProjectRoot`/`Get-AppVersion` + guard di semua pemakai).
- Proxy Management: tombol **Load** tidak lagi stuck pada "Loading..." bila unduhan gagal/crash (try/finally + deteksi error), dan kini menampilkan pesan berhasil/gagal yang jelas.
- Command Management: field Name kini dropdown terisi command tersimpan; tombol **Refresh**, **Load**, dan **Load ALL** untuk melihat seluruh daftar command.
- Virus Scanner: tambah tombol **Update Databases** (menjalankan `freshclam.exe`) di samping **Cek ClamAV**.
- Win OEM: logo OEM default memakai `Icons\winstools.bmp` (bukan `D:\logo.bmp`), resolve otomatis dari source maupun EXE terinstal; `build-exe.ps1` ikut menyalin bmp tersebut.
- UI: tombol **RUN** dan **CLEAR** kini sama ukurannya; variabel teks/ukuran/perilaku (bahasa & layout) dideklarasikan di awal `UI.psm1` agar mudah di-custom.
- Start-RedirectProcess: hapus parameter yang tidak valid di PowerShell 5.1 (`UseShellExecute`/`CreateNoWindow`) → pakai `NoNewWindow` (untuk pembacaan output build/test/update di Gui Options).

### Diubah (uji)
- Rename file test mengikuti standard Pester: suite utama → **`Pester.Tests.ps1`** (ter-discover otomatis), skrip GUI → **`form_test.ps1`**, **`close_test.ps1`**, **`capture_test.ps1`**, **`button_test.ps1`**, **`config_test.ps1`** (tidak ikut ter-discover Pester karena butuh sesi interaktif). Referensi di CI, README, dan Gui Tester ikut diperbarui.
- Options Gui Config: dialog kini memuat & menampilkan nilai aktif `Get-Config` saat dibuka (tidak lagi menampilkan default), sehingga perubahan config tetap terlihat setelah dialog ditutup dan dibuka lagi.

### Ditambahkan (lanjutan)
- **Gui Builder** kini mencakup 4 skrip build: `build-exe.ps1`, `build-installer.ps1`, `setup-ca.ps1`, `setup-vi.ps1` — dengan field **Versi** (ditampilkan hanya untuk skrip yang membutuhkannya), **Argumen tambahan**, dan hint berubah sesuai skrip.
- **Gui Tester** kini 6 jenis test: Pester, form smoke, close regression (`-Scenario stuck`), capture screenshot, button/Options dialog, dan config GUI.

### Diubah (lanjutan)
- Default konfigurasi aplikasi: `Environment=Production`, `Debug=false`, `LogLevel=ERROR`.
- Tab Options: label "Check Update - Self Update" disingkat menjadi "Update".
- Gui Config: layout output memakai TextArea berbasis posisi kursor sehingga tidak menimpa teks.
- Gui Builder "Buka Folder": normalisasi versi ke `major.minor`; jika versi kosong, folder `Build` dibuka.
- Screenshot `capture_test` kini disimpan ke `%TEMP%\winstools_capture.png` (bukan di root repo).

## [1.0.0] - 2026-08

Rilis pertama: Windows Super Tools lengkap dengan 10 tool, multi-session, welcome dashboard, auto-elevasi, signing Authenticode SHA256 + timestamp, dan CI build + test.
