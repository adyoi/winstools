# Changelog

Semua perubahan penting pada proyek dicatat di sini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.1] - belum dirilis

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
- **Tombol Options** (merah + separator) di menu utama: dialog dengan tab **Gui Config** (Environment Development/Production, Debug, LogLevel), **Gui Builder** (jalankan `build-exe.ps1`), **Gui Tester** (Pester / form test), **Check Update** (cek rilis GitHub `adyoi/winstools` + download), **Changelog**, dan **About**.

## [1.0.0] - 2026-08

Rilis pertama: Windows Super Tools lengkap dengan 10 tool, multi-session, welcome dashboard, auto-elevasi, signing Authenticode SHA256 + timestamp, dan CI build + test.
