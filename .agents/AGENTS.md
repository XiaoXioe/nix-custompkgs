# Aturan Pembangunan Modul & Servis NixOS

## Rotasi Log Servis Systemd Kontinu (24/7)
Ketika mendefinisikan pengalihan output log ke file pada servis Systemd yang berjalan terus-menerus (seperti bot trading, daemon, server, dll.):
1. **Hindari Hanya Mengandalkan ExecStartPre:** Jangan mengandalkan `ExecStartPre` sebagai satu-satunya pemicu log rotasi. Servis kontinu jarang mengalami restart, sehingga log akan tumbuh tanpa batas.
2. **Gunakan copytruncate (cp + truncate):** Jangan pernah menggunakan perintah `mv` untuk memutar log servis yang sedang aktif karena Systemd file descriptor akan terus menulis ke berkas hasil rename (inode lama). Gunakan metode duplikasi lalu potong:
   ```bash
   cp "$LOG_FILE" "$BACKUP_FILE"
   truncate -s 0 "$LOG_FILE"
   ```
3. **Definisikan Timer Periodik:** Selalu sediakan *systemd timer* (misal: setiap jam/`hourly`) dan companion *systemd service* yang bertugas memicu skrip rotasi log secara berkala pada seluruh jalur berkas log yang dikonfigurasi.

## Larangan Melacak Folder docs (Git Tracking)
1. **Jangan Melacak docs:** Seluruh berkas di dalam folder `docs/` (termasuk rancangan/desain spec) telah dimasukkan ke dalam `.gitignore` secara sengaja.
2. **Hindari force-add (`git add -f`):** Jangan pernah menggunakan perintah `git add -f` atau memaksa menambahkan berkas apa pun yang berada di bawah direktori `docs/` ke dalam kontrol versi Git. Biarkan berkas-berkas tersebut tetap bersifat lokal/untracked.

