# Contributing

Terima kasih sudah berkontribusi ke WINSTOOLS.

## Struktur proyek

```
Scripts\
  Main.ps1              Entry point (ps2exe compile)
  Modules\
    App.psm1            State & global timer
    UI.psm1             Form, tab, session panel
    Session.psm1        Session lifecycle, logging, run/cancel
    Features.psm1       Dynamic tool loader
    Config.psm1         Winstools.psd1, debug log
  Tools\                Satu modul per tool (.psm1)
    <Tool>.psm1         Get-ToolConfig, Invoke-ToolAction, Get-CustomUI
Build\
  build.ps1             Compile + patch versi + sign + verify
  build-installer.ps1   Installer Inno Setup
  installer.iss         Script Inno Setup
Test\
  Winstools.Tests.ps1   Uji otomatis (Pester 3.4 & 5.x)
Icons\
```

## Menambah tool baru

1. Buat `Scripts\Tools\<NamaTool>.psm1` dengan fungsi wajib:
   - `Get-ToolConfig` → `MenuName`, `ToolName`, `Category`, `Fields`, (opsional `CustomUI`, `RequiresConfirm`).
   - `Invoke-ToolAction` → `param($params)`, membaca input dari `$params`.
   - (opsional) `Get-CustomUI` → kontrol tambahan untuk panel.
2. `ToolName` wajib sama dengan nama file (tanpa `.psm1`).
3. Jika tool berisiko, set `RequiresConfirm = $true`.
4. Jalankan test: `powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Pester -Script .\Test"`.

## Menjalankan build

```
.\Build\build.ps1                     # versi dari file VERSION
.\Build\build.ps1 -Version 1.2.0      # versi eksplisit
.\Build\build-installer.ps1           # butuh Inno Setup 6 (ISCC.exe)
```

Password PFX: set env `WINSTOOLS_PFX_PASSWORD` (tanpa env, fallback password dev hanya untuk `CA\winstools.pfx` lokal).

## Aturan

- Jangan commit file hasil build (`Build\*\*`) — sudah di `.gitignore`.
- Jangan commit `CA\` (PFX privat).
- Tulis perubahan di `CHANGELOG.md` (format Keep a Changelog).
- Pastikan `Invoke-Pester -Script .\Test` hijau sebelum push.
