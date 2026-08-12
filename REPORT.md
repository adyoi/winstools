# Laporan Analisis Proyek — WINSTOOLS (Windows Super Tools)

**Tanggal:** 12 Agustus 2026 · **Versi aktif:** 1.2.0.0 · **Teknologi:** PowerShell 5.1 + Windows Forms (ps2exe)

---

## 1. Ringkasan

Aplikasi utilitas manajemen & perawatan Windows dengan UI desktop (Windows Forms) dan arsitektur **multi-session**: setiap tool berjalan di tab independen (background job) dengan console output sendiri, sehingga beberapa tool dapat berjalan bersamaan. Aplikasi di-distribusikan sebagai **EXE mandiri yang ditandatangani (Authenticode)** beserta folder runtime self-contained per versi.

## 2. Arsitektur

```
winstools/
├── Build/                      # Tooling build + hasil per versi
│   ├── build.ps1               # Pipeline: compile → versi → sign → runtime → verify
│   ├── setup-ca.ps1            # Private CA + sertifikat code signing (OpenSSL)
│   ├── set-versioninfo.ps1     # Patch VERSIONINFO (bahasa Indonesia 0x0421)
│   ├── Package.psd1            # Konfigurasi alternatif (PowerShellProTools)
│   └── <versi>/                # Release self-contained (exe + Modules + Tools + Icons)
├── CA/                         # Private CA & kunci signing (SENSITIF, di-gitignore)
├── Icons/                      # Aset ikon
├── Scripts/                    # Source code (dev)
│   ├── Main.ps1                # Entry point (152 baris)
│   ├── Modules/                # 5 modul inti (1.172 baris)
│   └── Tools/                  # 13 modul tool (1.039 baris)
└── Test/                       # Skrip uji manual
```

### Lapisan modul

| Modul | Baris | Tanggung jawab |
| --- | --- | --- |
| `Main.ps1` | 152 | Resolusi ModuleRoot, elevasi admin otomatis (RunAs), perakitan UI utama |
| `UI.psm1` | 722 | Seluruh komponen WinForms: form, menu, session bar (scroll/arrow), tab, welcome dashboard (HTML) |
| `Session.psm1` | 207 | Manajemen session/tab, eksekusi via `Start-Job`, pembatalan proses (taskkill /T), log thread-safe (Invoke) |
| `App.psm1` | 111 | State aplikasi, global timer (150 ms) memantau job → stream output ke console |
| `Features.psm1` | 68 | Loader dinamis tool dari `Tools\*.psm1` via `Get-ToolConfig` / `Invoke-ToolAction` |
| `Config.psm1` | 64 | Environment (Dev/Prod), level log, logging berwarna `[INFO][WARN][ERROR][SUCCESS]` |

### Arsitektur tool (plugin)

- Registrasi otomatis: setiap `.psm1` di `Tools\` mengekspos `Get-ToolConfig` (menu, kategori, field input) dan `Invoke-ToolAction`.
- UI default digenerate dari `Fields`; tool dapat menyuntikkan **Custom UI** via `Get-CustomUI`.
- Menambah tool baru = menambah satu file `.psm1`, tanpa mengubah inti aplikasi (mudah diperluas).

## 3. Pipeline Build (stable)

Alur `Build\build.ps1` (satu perintah, output di `Build\<major.minor>\`):

1. **Compile** — ps2exe (`-noConsole`, ikon, metadata assembly).
2. **Patch resource versi** — `set-versioninfo.ps1` menulis ulang `VS_VERSIONINFO` via P/Invoke `UpdateResource` (bahasa **Indonesian 0x0421**, Company, Copyright, versi). Dilakukan *sebelum* signing agar tanda tangan tetap valid.
3. **Sign** — `CA\winstools.pfx` (SHA256 + timestamp DigiCert).
4. **Copy runtime** — `Modules\`, `Tools\`, `Icons\` → folder versi (self-contained).
5. **Verify** — status tanda tangan & signer ditampilkan.

**Metadata rilis:** File Description `Windows Super Tools` · Versi 1.x · Product `Winstools` · Company `PT (Perorangan) Adidaya Karya Utama` · Copyright © 2026 · Language `Indonesian (Indonesia)`.

## 4. Keamanan & Signing

| Aspek | Status |
| --- | --- |
| Tanda tangan | Valid (self-signed root, private CA) |
| Identitas signer | `E=adyoix@gmail.com, O=WINSTOOLS, CN=WINSTOOLS CodeSigning` |
| Timestamp | DigiCert (koneksi internet dibutuhkan untuk status Valid tahan-lama) |
| Kunci privat | `CA/` masuk `.gitignore` ✓ · PFX default password dev |
| Elevasi | Otomatis via `RunAs`, tanpa menyimpan credential |

## 5. Rilis (Build\)

| Folder | Versi | Ukuran | Status |
| --- | --- | --- | --- |
| `1.0` | 1.0.0.0 | ~138 KB | ✅ build lama (fixed-info versi lama, bisa di-refresh) |
| `1.1` | 1.1.0.0 | ~138 KB | ✅ valid |
| `1.2` | 1.2.0.0 | ~138 KB | ✅ valid (versi aktif) |

## 6. Kekuatan

- **Modular & extensible** — tool = satu file modul, registrasi otomatis.
- **Pipeline build terdokumentasi & deterministik** — satu perintah, hasil terverifikasi.
- **Thread-safe logging** ke RichTextBox dengan marshaling antar-thread yang benar.
- **Pembatalan proses yang andal** — mematikan pohon proses sebelum `Stop-Job` (mencegah hang pada `cmd.exe`/`ping`).
- **Release self-contained & versioned** per folder.

## 7. Risiko / Catatan

1. **Sertifikat self-signed** — hanya dipercaya di mesin yang meng-install root; distribusi publik memerlukan EV/OV code-signing.
2. **Modul dimuat dari disk** (tidak di-bundle) — release harus selalu menyertakan `Modules/` & `Tools/` (sudah otomatis oleh build.ps1; risiko hanya jika exe dipindah sendirian).
3. **Versi diubah manual** (`$metaVersion`) — rawan lupa; bisa di-parameter-kan (`build.ps1 -Version 1.3.0`).
4. **Data runtime di folder instalasi** — `Tools\CustomCommands.json` & `logs\` ditulis di samping exe; pada instalasi multi-user idealnya pindah ke `%AppData%\Winstools`.
5. **Belum ada git** — belum ada riwayat versi; `CA/` sudah di-ignore, `CONTRIBUTORS.md` & README siap.
6. **Uji otomatis minim** — hanya `Test\*.ps1` manual; disarankan Pester untuk modul tool.
7. **`Invoke-Cmd` memakai `cmd.exe /c`** — sesuai fungsi utilitas, namun waspadai input user pada tool Custom Command (jalankan dengan prinsip least-privilege).

## 8. Rekomendasi

| Prioritas | Aksi |
| --- | --- |
| Tinggi | Inisialisasi `git init`, commit awal (CA/ tetap di-ignore) |
| Tinggi | Parameter-kan versi: `build.ps1 -Version` (tidak edit file) |
| Sedang | Pindahkan data runtime (`CustomCommands.json`, `logs`) ke `%AppData%` |
| Sedang | Tambah uji otomatis (Pester) untuk modul tool |
| Sedang | Otomasi CI (mis. GitHub Actions) build saat tag `v*` |
| Rendah | Pertimbangkan sertifikat OV untuk distribusi eksternal |

## 9. Kesimpulan

Proyek berada dalam kondisi **stabil dan siap rilis** dengan arsitektur modular yang rapi dan pipeline build + signing yang sudah teruji (1.0 → 1.2). Fokus pengembangan berikutnya: manajemen versi yang lebih terotomasi, pemisahan data runtime, dan pengujian otomatis.
