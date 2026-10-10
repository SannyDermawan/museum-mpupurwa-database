-- ============================================================================
-- Kumpulan query yang dibutuhkan backend, dikelompokkan per endpoint.
-- Ini referensi untuk menggantikan data dummy di backend (backend/src/data/*).
-- Tanda ? adalah parameter yang diisi dari kode (jangan digabung ke string SQL).
-- Jalankan di database museum_mpupurwa.
-- ============================================================================

USE museum_mpupurwa;

-- ============================================================================
-- AUTH  (POST /api/auth/login)
-- Ambil admin lewat email, lalu bandingkan sandi dengan password_hash memakai
-- bcrypt.compare() di backend. Admin nonaktif tidak boleh masuk.
-- ============================================================================
SELECT id, name, email, role, password_hash
FROM admins
WHERE email = ? AND status = 'active';

-- Setelah login berhasil:
UPDATE admins SET last_login_at = NOW() WHERE id = ?;

-- ============================================================================
-- DASHBOARD  (GET /api/dashboard)
-- ============================================================================

-- Kartu "Pengunjung hari ini"
SELECT COUNT(*) AS today_visitors FROM visits WHERE visit_date = CURDATE();

-- Persentase perubahan dibanding kemarin (NULL kalau kemarin 0)
SELECT ROUND(
         (SUM(visit_date = CURDATE()) - SUM(visit_date = CURDATE() - INTERVAL 1 DAY))
         / NULLIF(SUM(visit_date = CURDATE() - INTERVAL 1 DAY), 0) * 100
       ) AS change_percent
FROM visits
WHERE visit_date >= CURDATE() - INTERVAL 1 DAY;

-- Kartu "Booking menunggu konfirmasi" (angka yang sama dipakai badge sidebar)
SELECT COUNT(*) AS pending_bookings FROM bookings WHERE status = 'pending';

-- Kartu "Total akun terdaftar" dan penanda "+48" (akun baru 30 hari terakhir)
SELECT COUNT(*) AS total_accounts,
       SUM(registered_at >= CURDATE() - INTERVAL 30 DAY) AS new_accounts
FROM visitor_accounts;

-- Kartu "Koleksi terdaftar"
SELECT COUNT(*) AS total_collections FROM collections;

-- "Pengunjung Terbaru": 4 check-in terakhir hari ini
SELECT id, visitor_name AS name, domicile, institution, education_level, DATE_FORMAT(check_in_time, '%H:%i') AS check_in_time
FROM visits
WHERE visit_date = CURDATE()
ORDER BY check_in_time DESC
LIMIT 4;

-- "Booking Menunggu": urut dari tanggal kunjungan terdekat
SELECT id, institution AS institution_name, participant_count, visit_date, created_at
FROM bookings
WHERE status = 'pending'
ORDER BY visit_date ASC;

-- ============================================================================
-- DASHBOARD  (GET /api/dashboard/booking-status?range=24h|7d|30d)
-- Jumlah booking per status yang DIAJUKAN dalam rentang. Isi interval sesuai range:
-- 24 HOUR, 7 DAY, atau 30 DAY. Status yang tidak muncul berarti 0 (isi 0 di backend).
-- ============================================================================
SELECT status, COUNT(*) AS total
FROM bookings
WHERE created_at >= NOW() - INTERVAL 24 HOUR   -- ganti: INTERVAL 7 DAY / INTERVAL 30 DAY
GROUP BY status;

-- ============================================================================
-- DASHBOARD  (GET /api/dashboard/visitor-trend?range=...)
-- Hanya hari yang punya check-in yang muncul; hari tanpa pengunjung (mis. akhir
-- pekan saat museum tutup) diisi 0 oleh backend.
-- ============================================================================

-- range=24h: pola per jam pada hari buka terakhir (grafik 08.00 - 16.00)
SELECT HOUR(check_in_time) AS hour, COUNT(*) AS total
FROM visits
WHERE visit_date = (SELECT MAX(visit_date) FROM visits)
GROUP BY HOUR(check_in_time)
ORDER BY hour;

-- range=7d: jumlah pengunjung per hari
SELECT visit_date, COUNT(*) AS total
FROM visits
WHERE visit_date > CURDATE() - INTERVAL 7 DAY
GROUP BY visit_date
ORDER BY visit_date;

-- range=30d: sama, 30 hari ke belakang
SELECT visit_date, COUNT(*) AS total
FROM visits
WHERE visit_date > CURDATE() - INTERVAL 30 DAY
GROUP BY visit_date
ORDER BY visit_date;

-- ============================================================================
-- PENGUNJUNG HARI INI  (GET /api/visitors/today?q=)
-- ? diisi kata kunci pencarian (kosongkan filter dengan memakai query tanpa LIKE).
-- ============================================================================
SELECT id, visitor_name AS name, domicile, institution, education_level, DATE_FORMAT(check_in_time, '%H:%i') AS check_in_time
FROM visits
WHERE visit_date = CURDATE()
  AND CONCAT_WS(' ', visitor_name, domicile, institution, education_level) LIKE CONCAT('%', ?, '%')
ORDER BY check_in_time;

-- ============================================================================
-- MANAJEMEN AKUN > PENGUNJUNG  (/api/accounts/visitors)
-- ============================================================================
SELECT id, name, phone, email, domicile, institution, education_level, registered_at
FROM visitor_accounts
WHERE CONCAT_WS(' ', name, phone, email, domicile, institution, education_level) LIKE CONCAT('%', ?, '%')
ORDER BY registered_at, id;

UPDATE visitor_accounts
SET name = ?, domicile = ?, institution = ?, education_level = ?
WHERE id = ?;

DELETE FROM visitor_accounts WHERE id = ?;   -- riwayat check-in tetap ada (visitor_account_id jadi NULL)

-- ============================================================================
-- MANAJEMEN AKUN > ADMIN  (/api/accounts/admins)
-- ============================================================================
SELECT id, name, email, role, status, last_login_at
FROM admins
WHERE CONCAT_WS(' ', name, email, role) LIKE CONCAT('%', ?, '%')
ORDER BY id;

-- Tambah admin: password_hash dihasilkan backend dari sandi sementara (bcrypt).
-- Email yang sudah dipakai akan ditolak oleh UNIQUE (error 1062 -> balas 409).
INSERT INTO admins (id, name, email, password_hash, role, status) VALUES (?, ?, ?, ?, ?, 'active');

UPDATE admins SET name = ?, role = ?, status = ? WHERE id = ?;

DELETE FROM admins WHERE id = ?;

-- ============================================================================
-- BOOKING ROMBONGAN  (GET /api/bookings, PATCH /api/bookings/:id/status)
-- ============================================================================
SELECT id, institution, contact_name AS contact, phone, visit_date AS date, participant_count AS participants,
       notes, status, created_at
FROM bookings
ORDER BY created_at DESC;

-- Status hanya boleh: pending, confirmed, completed, rejected (nilai lain ditolak oleh ENUM).
UPDATE bookings SET status = ? WHERE id = ?;

-- ============================================================================
-- MANAJEMEN KOLEKSI  (/api/collections)
-- Tabel koleksi memakai view v_collections supaya kolom "Video & PDF" ikut terhitung.
-- ============================================================================
SELECT id, name, era, material, status_media
FROM v_collections
WHERE CONCAT_WS(' ', name, era, material) LIKE CONCAT('%', ?, '%')
ORDER BY id;

INSERT INTO collections (name, era, period, origin, material, dimensions, meaning, photo_path, video_url, pdf_path)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);   -- simpan NULL (bukan teks kosong) untuk media yang belum ada

UPDATE collections
SET name = ?, era = ?, period = ?, origin = ?, material = ?, dimensions = ?, meaning = ?,
    photo_path = ?, video_url = ?, pdf_path = ?
WHERE id = ?;

DELETE FROM collections WHERE id = ?;

-- ============================================================================
-- NOTIFIKASI (lonceng di navbar)
-- Tidak punya tabel sendiri: dibentuk dari dua query yang sudah ada di atas, yaitu
-- booking berstatus pending dan 2 akun pengunjung terbaru.
-- ============================================================================
SELECT id, name, registered_at
FROM visitor_accounts
ORDER BY registered_at DESC
LIMIT 2;
