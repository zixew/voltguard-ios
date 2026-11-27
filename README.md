# VoltGuard iOS (Companion & Battery Monitor)

Versi iPhone dari **VoltGuard** yang berfungsi sebagai **Remote Mac Monitor & Companion App** sekaligus **Local iPhone Battery Diagnostics**.

## Fitur Utama
1. **Remote Mac Telemetry & Control (LAN)**:
   - Pantau persentase, sisa waktu pengecasan (ETA), suhu, daya (watt), dan kondisi kesehatan baterai MacBook secara real-time.
   - Atur batas pengisian daya Mac (60%, 80%, 90%, 100%) dan picu kalibrasi manual (Discharge).
2. **Local iPhone Battery Insights**:
   - Tampilan visual cairan baterai animasi (*Fluid Battery Wave*).
   - Pengingat pintar saat baterai mencapai 80% (Smart 80% Reminder).
3. **Multi-Theme VoltGuard**:
   - Obsidian Slate, Cyber Lime, Hyper Neon, Crimson Forge, dan Clean Frost.

## Cara Menjalankan
```bash
# Jalankan test
swift test

# Build untuk iOS Simulator
bash scripts/build_sim.sh
```
