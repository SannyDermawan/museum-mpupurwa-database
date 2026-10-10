-- ============================================================================
-- Data awal (development / UTS): Admin Web Museum Mpu Purwa
--
-- Isinya sama dengan data dummy yang dipakai backend dan halaman koleksi, supaya
-- tampilan admin web tidak berubah saat backend nanti dihubungkan ke database.
--
-- Jalankan SETELAH schema.sql. HANYA untuk development: akun di bawah memakai
-- kata sandi yang sudah diketahui umum.
-- ============================================================================

SET NAMES utf8mb4;
USE museum_mpupurwa;

-- ----------------------------------------------------------------------------
-- admins
-- Kata sandi ketiga akun: admin123 (hash bcrypt). Akun untuk login:
--   admin@mpupurwa.test / admin123  (Super Admin)
-- ----------------------------------------------------------------------------
INSERT INTO admins (id, name, email, password_hash, role, status, last_login_at) VALUES
  ('ADM-001', 'Rizal Pradana',   'admin@mpupurwa.test', '$2b$10$TP4gzYxJeAyDaqwgJ724cORAIx2wxakPAVPf5W4eXm7biBTexPqay', 'super_admin', 'active',   TIMESTAMP(CURDATE(), '08:02:00')),
  ('ADM-002', 'Dewi Anggraini',  'dewi@mpupurwa.id',    '$2b$10$TP4gzYxJeAyDaqwgJ724cORAIx2wxakPAVPf5W4eXm7biBTexPqay', 'admin',       'active',   TIMESTAMP(CURDATE() - INTERVAL 1 DAY, '15:40:00')),
  ('ADM-003', 'Hadi Kurniawan',  'hadi@mpupurwa.id',    '$2b$10$TP4gzYxJeAyDaqwgJ724cORAIx2wxakPAVPf5W4eXm7biBTexPqay', 'admin',       'inactive', '2026-09-12 10:15:00');

-- ----------------------------------------------------------------------------
-- visitor_accounts
-- Nomor telepon di data dummy sudah tersamarkan (0812-xxxx-3421). Di database
-- sungguhan simpan nomor utuh, lalu samarkan di API.
-- ----------------------------------------------------------------------------
INSERT INTO visitor_accounts (id, name, phone, email, domicile, institution, education_level, registered_at) VALUES
  ('ACC-001', 'Amanda Putri',      '0812-xxxx-3421', 'amanda@gmail.com', 'Surabaya', 'Univ. Airlangga',  'Mahasiswa', '2026-08-12'),
  ('ACC-002', 'Bagas Pratama',     '0813-xxxx-1092', 'bagas@gmail.com',  'Malang',   'SMAN 3 Malang',    'Pelajar',   '2026-08-20'),
  ('ACC-003', 'Citra Ayu Lestari', '0857-xxxx-4433', 'citra@gmail.com',  'Malang',   'Univ. Brawijaya',  'Mahasiswa', '2026-09-01'),
  ('ACC-004', 'Dimas Setiawan',    '0895-xxxx-7765', 'dimas@gmail.com',  'Blitar',   NULL,               'Umum',      '2026-09-15'),
  ('ACC-005', 'Eka Nur Fadila',    '0821-xxxx-9012', 'eka@gmail.com',    'Malang',   'SDN Merjosari 1',  'Pelajar',   '2026-09-18'),
  ('ACC-006', 'Fajar Ramadhan',    '0812-xxxx-5541', 'fajar@gmail.com',  'Kediri',   'Univ. Brawijaya',  'Mahasiswa', '2026-09-22');

-- ----------------------------------------------------------------------------
-- visits: check-in HARI INI (tanggalnya selalu hari saat seed dijalankan).
-- Enam pengunjung pertama punya akun; empat terakhir tidak (visitor_account_id NULL).
-- Seed hanya berisi hari ini. Riwayat harian untuk grafik 7 dan 30 hari akan
-- terisi sendiri seiring check-in nyata.
-- ----------------------------------------------------------------------------
INSERT INTO visits (id, visitor_account_id, visitor_name, domicile, institution, education_level, visit_date, check_in_time) VALUES
  ('VIS-001', 'ACC-001', 'Amanda Putri',      'Surabaya', 'Univ. Airlangga',   'Mahasiswa', CURDATE(), '09:14:00'),
  ('VIS-002', 'ACC-002', 'Bagas Pratama',     'Malang',   'SMAN 3 Malang',     'Pelajar',   CURDATE(), '09:42:00'),
  ('VIS-003', 'ACC-003', 'Citra Ayu Lestari', 'Malang',   'Univ. Brawijaya',   'Mahasiswa', CURDATE(), '10:05:00'),
  ('VIS-004', 'ACC-004', 'Dimas Setiawan',    'Blitar',   NULL,                'Umum',      CURDATE(), '10:20:00'),
  ('VIS-005', 'ACC-005', 'Eka Nur Fadila',    'Malang',   'SDN Merjosari 1',   'Pelajar',   CURDATE(), '10:35:00'),
  ('VIS-006', 'ACC-006', 'Fajar Ramadhan',    'Kediri',   'Univ. Brawijaya',   'Mahasiswa', CURDATE(), '11:02:00'),
  ('VIS-007', NULL,      'Gita Anjani',       'Surabaya', NULL,                'Umum',      CURDATE(), '11:15:00'),
  ('VIS-008', NULL,      'Hendra Wijaya',     'Malang',   'SMPN 1 Malang',     'Pelajar',   CURDATE(), '11:40:00'),
  ('VIS-009', NULL,      'Intan Permatasari', 'Batu',     'Univ. Negeri Malang', 'Mahasiswa', CURDATE(), '12:10:00'),
  ('VIS-010', NULL,      'Joko Susilo',       'Malang',   NULL,                'Umum',      CURDATE(), '13:05:00');

-- ----------------------------------------------------------------------------
-- bookings
-- Waktu pengajuan (created_at) dihitung mundur dari saat seed dijalankan, sama
-- seperti data dummy backend, sehingga filter 24 jam / 7 hari / 30 hari terisi:
--   tk 5 jam lalu | smpn4 3 hari lalu | sdn1 6 hari lalu | ub 12 hari lalu | sman1 25 hari lalu
-- ----------------------------------------------------------------------------
INSERT INTO bookings (id, institution, contact_name, phone, visit_date, participant_count, notes, status, created_at) VALUES
  ('sdn1',  'SDN Merjosari 1 Malang',                'Dewi Saraswati', '0813-2456-7890', '2026-09-29', 65, 'Butuh pemandu untuk siswa SD',  'pending',   NOW() - INTERVAL 6 DAY),
  ('smpn4', 'SMPN 4 Malang',                         'Budi Hartono',   '0812-3456-7891', '2026-10-02', 48, 'Kunjungan edukasi sejarah',     'pending',   NOW() - INTERVAL 3 DAY),
  ('tk',    'TK Tunas Bangsa',                       'Sri Wahyuni',    '0815-6789-0123', '2026-10-05', 20, 'Siswa PAUD dan pendamping',     'pending',   NOW() - INTERVAL 5 HOUR),
  ('ub',    'Universitas Brawijaya — Prodi Sejarah', 'Anisa Rahma',    '0821-9876-5432', '2026-09-25', 30, 'Penelitian lapangan',           'confirmed', NOW() - INTERVAL 12 DAY),
  ('sman1', 'SMAN 1 Batu',                           'Rudi Setiawan',  '0857-1234-5678', '2026-09-20', 55, NULL,                            'rejected',  NOW() - INTERVAL 25 DAY);

-- ----------------------------------------------------------------------------
-- collections
-- Data dummy hanya punya nama, era, material, dan status media. Kolom lain
-- dibiarkan NULL. Alamat video dan berkas PDF di bawah hanyalah PENGISI
-- (placeholder) agar status "Lengkap / Belum ada ..." sama dengan tampilan sekarang.
-- ----------------------------------------------------------------------------
INSERT INTO collections (name, era, material, video_url, pdf_path) VALUES
  ('Arca Ganesya Tikus',  'Singosari', 'Batu andesit', 'https://example.com/video/arca-ganesya-tikus', '/uploads/pdf/arca-ganesya-tikus.pdf'),
  ('Arca Brahma',         'Kanjuruhan','Batu andesit', 'https://example.com/video/arca-brahma',        '/uploads/pdf/arca-brahma.pdf'),
  ('Siwa Catur Muka',     'Tumapel',   'Batu andesit', NULL,                                          '/uploads/pdf/siwa-catur-muka.pdf'),
  ('Makara Gapura',       'Singosari', 'Batu andesit', 'https://example.com/video/makara-gapura',     '/uploads/pdf/makara-gapura.pdf'),
  ('Prasasti Kanjuruhan', 'Prasasti',  'Batu andesit', 'https://example.com/video/prasasti-kanjuruhan', NULL),
  ('Arca Nandi',          'Tumapel',   'Batu andesit', NULL,                                          NULL);
