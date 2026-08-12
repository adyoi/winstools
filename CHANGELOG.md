# Changelog

Semua perubahan penting pada proyek dicatat di sini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.1] - belum dirilis

### Ditambahkan
- Konfirmasi (Yes/No) sebelum menjalankan tool berisiko: Clear DNS, Disk Repair, Disable Services, Win Update Reset, Set OEM, Proxy Manager.
- Auto-release di GitHub Actions saat tag `v*` (termasuk installer).
- Build installer Inno Setup: `Build\build-installer.ps1` → `winstools-installer.exe`.
- File `VERSION` sebagai sumber tunggal versi; `build.ps1` membaca versi dari sana secara default.
- Dukungan env `WINSTOOLS_PFX_PASSWORD` untuk password PFX di CI/produksi (fallback: password dev untuk CA lokal).
- Test Pester: skema Fields tool, roundtrip CustomCommands (dengan backup/restore), integritas build exe, flag `RequiresConfirm`.
- `CHANGELOG.md`, `CONTRIBUTING.md`, badge status CI di README.

### Diubah
- CI build untuk push ke `main` memakai versi dari file `VERSION` (bukan hardcoded).

## [1.0.0] - 2026-08

Rilis pertama: Windows Super Tools lengkap dengan 10 tool, multi-session, welcome dashboard, auto-elevasi, signing Authenticode SHA256 + timestamp, dan CI build + test.
