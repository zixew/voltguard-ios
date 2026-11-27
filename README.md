# VoltGuard iOS

**VoltGuard iOS** membawa tampilan, sistem tema, animasi baterai cair (`LiquidBatteryCellView`), dwi bahasa (`EN` / `ID`), pengawasan suhu, jadwal pengingat, serta **Auto-Cek Kompatibilitas 1-kali** yang identik dengan aplikasi desktop **VoltGuard macOS**, dirancang khusus sesuai batasan sandbox iPhone.

## Fitur Utama
1. **Ringkasan & Target Pengingat Pengisian (`50% - 100%`)**:
   - Sel baterai animasi cair dengan 3 gaya warna (`Spektrum Adaptif`, `Reaktif Thermal`, `Aksen Tema`) dan garis batas interaktif yang bisa digeser.
   - Rekomendasi profil harian (`Seimbang`, `Mobilitas`, `Awet Maksimal`) dan estimasi waktu (`BatteryETACalculator`).
2. **Smart Alerts & Batas Pengisian (`UNUserNotificationCenter`)**:
   - Notifikasi lokal native iOS ketika baterai mencapai batas target (misal `80%`), penuh `100%` (Top Up), turun `<= 20%`, atau status thermal sistem meningkat ke `Serious` / `Critical`.
   - Panduan 1-ketuk untuk mengaktifkan batas hardware `80%` bawaan Apple pada iPhone 15+.
3. **Jadwal & Log Aktivitas**:
   - Jadwalkan pengingat `Set 80%` maupun `Top Up 100%` dan pantau log notifikasi sesi.
4. **Appearance Studio Identik Desktop**:
   - 4 preset tema (`Obsidian`, `Paper Light`, `Nordic Mist`, `Midnight`), swatch aksen + custom hex, corner radius, surface opacity, serta wallpaper galeri (`PhotosPicker`) dengan scrim & blur.
5. **Auto-Cek Kompatibilitas iPhone (Cek 1x Tersimpan)**:
   - Mengecek model perangkat, versi iOS, izin notifikasi, dan dukungan Apple Hardware 80% Limit satu kali saja lalu menyimpannya ke `ios_settings.json`.

## Kompatibilitas iPhone, iPad & Versi iOS

Minimum deployment target: **iOS 16.0 / iPadOS 16.0**.

| Seri Perangkat / Versi OS | Telemetri & Sel Cair | Smart Alerts & Thermal | Jadwal Kalender (`UNCalendar`) | Batas Hardware 80% Apple | SMC / Force Discharge |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **iPhone 8, 8 Plus, X (iOS 16.x)** | Ya (`UIDevice`) | Ya | Ya | Tidak (Optimized Charging) | Tidak (Sandbox iOS) |
| **iPhone XR - iPhone 14 Pro Max (iOS 16 - 26+)** | Ya (`UIDevice`) | Ya | Ya | Tidak (Optimized Charging) | Tidak (Sandbox iOS) |
| **iPhone 15, 16, 17, 17e & Air (iOS 17 - 26+)** | Ya (`UIDevice`) | Ya | Ya | **Ya** (di Settings iOS) | Tidak (Sandbox iOS) |
| **iPad Air M2-M4, iPad Pro M4-M5, iPad mini A17 Pro (iPadOS 17.5+)** | Ya (`UIDevice`) | Ya | Ya | **Ya** (di Settings iPadOS) | Tidak (Sandbox iOS) |
| **iPad Generasi Sebelumnya (iPadOS 16 - 26+)** | Ya (`UIDevice`) | Ya | Ya | Tidak (Optimized Charging) | Tidak (Sandbox iOS) |

## Fitur Mac yang Sengaja Tidak Ada di iPhone
Sesuai batasan kernel & sandbox iOS, VoltGuard iOS tidak menyertakan kontrol hardware khusus Mac: penulisan register `AppleSMC` (`CHIE`/`CH0B`/`BCLM`), `Force Discharge`, `Clamshell Discharge`, lampu `MagSafe 3 LED`, dan daftar proses energi (`PID`).

## Cara Build & Test
```bash
# Jalankan SwiftPM unit test
swift test

# Build & verifikasi untuk iOS Simulator dan iOS Device
bash scripts/build_sim.sh
```
