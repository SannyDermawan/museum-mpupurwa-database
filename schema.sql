-- ============================================================================
-- Skema database: Admin Web Museum Mpu Purwa
--
-- Target : MySQL 8.0+ atau MariaDB 10.4+ (versi bawaan XAMPP/Laragon juga bisa).
-- Dipakai: backend (Express) lewat query di queries.sql.
--
-- PERINGATAN: skrip ini menjalankan DROP TABLE, jadi menjalankannya ulang
-- MENGHAPUS data yang sudah ada. Pakai hanya untuk database development.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS museum_mpupurwa
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE museum_mpupurwa;

-- Urutan DROP: tabel yang punya foreign key dihapus lebih dulu.
DROP VIEW  IF EXISTS v_collections;
DROP TABLE IF EXISTS visits;
DROP TABLE IF EXISTS visitor_accounts;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS collections;
DROP TABLE IF EXISTS admins;

-- ----------------------------------------------------------------------------
-- admins: akun pengelola museum yang masuk ke admin web.
-- Dipakai oleh: login, Manajemen Akun > Admin.
-- ----------------------------------------------------------------------------
CREATE TABLE admins (
  id            VARCHAR(10)  NOT NULL,                       -- format API: ADM-001
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,                       -- hash bcrypt, JANGAN simpan sandi asli
  role          ENUM('super_admin', 'admin') NOT NULL DEFAULT 'admin',
  status        ENUM('active', 'inactive')   NOT NULL DEFAULT 'active',
  last_login_at DATETIME     NULL,                           -- NULL = belum pernah masuk
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- visitor_accounts: akun pengunjung yang mendaftar lewat aplikasi mobile.
-- Dipakai oleh: Manajemen Akun > Pengunjung, kartu "Total akun terdaftar".
-- ----------------------------------------------------------------------------
CREATE TABLE visitor_accounts (
  id              VARCHAR(10)  NOT NULL,                     -- format API: ACC-001
  name            VARCHAR(100) NOT NULL,
  phone           VARCHAR(20)  NOT NULL,                     -- disimpan utuh; API yang menyamarkan (0812-xxxx-3421)
  email           VARCHAR(150) NOT NULL,
  domicile        VARCHAR(80)  NOT NULL,                     -- kota asal
  institution     VARCHAR(150) NULL,                         -- sekolah/kampus; NULL untuk "Umum"
  education_level ENUM('Mahasiswa', 'Pelajar', 'Umum') NOT NULL,
  registered_at   DATE         NOT NULL,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- visits: satu baris per check-in pengunjung di museum.
-- Dipakai oleh: Pengunjung Hari Ini, grafik Statistik Pengunjung, "Pengunjung Terbaru".
--
-- visitor_account_id boleh NULL (pengunjung tanpa akun). Nama, domisili, institusi
-- dan jenjang disalin ke baris ini saat check-in (snapshot), sehingga riwayat tidak
-- berubah walaupun akunnya nanti diedit atau dihapus.
-- ----------------------------------------------------------------------------
CREATE TABLE visits (
  id                 VARCHAR(12)  NOT NULL,                  -- format API: VIS-001
  visitor_account_id VARCHAR(10)  NULL,
  visitor_name       VARCHAR(100) NOT NULL,
  domicile           VARCHAR(80)  NOT NULL,
  institution        VARCHAR(150) NULL,
  education_level    ENUM('Mahasiswa', 'Pelajar', 'Umum') NOT NULL,
  visit_date         DATE         NOT NULL,
  check_in_time      TIME         NOT NULL,
  created_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_visits_account FOREIGN KEY (visitor_account_id)
    REFERENCES visitor_accounts (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_visits_date_time ON visits (visit_date, check_in_time);

-- ----------------------------------------------------------------------------
-- bookings: pengajuan kunjungan rombongan (sekolah, kampus, instansi).
-- Dipakai oleh: Booking Rombongan, kartu "Booking menunggu", diagram Status Booking.
-- ----------------------------------------------------------------------------
CREATE TABLE bookings (
  id                VARCHAR(30)  NOT NULL,                   -- mengikuti id yang dipakai API/halaman: sdn1, smpn4, ...
  institution       VARCHAR(150) NOT NULL,
  contact_name      VARCHAR(100) NOT NULL,                   -- penanggung jawab
  phone             VARCHAR(20)  NOT NULL,
  visit_date        DATE         NOT NULL,                   -- tanggal kunjungan
  participant_count INT UNSIGNED NOT NULL,
  notes             TEXT         NULL,
  status            ENUM('pending', 'confirmed', 'completed', 'rejected') NOT NULL DEFAULT 'pending',
  created_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,   -- waktu pengajuan (dasar filter 24 jam / 7 hari / 30 hari)
  updated_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT chk_bookings_participants CHECK (participant_count > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_bookings_status     ON bookings (status);
CREATE INDEX idx_bookings_created_at ON bookings (created_at);
CREATE INDEX idx_bookings_visit_date ON bookings (visit_date);

-- ----------------------------------------------------------------------------
-- collections: koleksi arca dan prasasti yang tampil di aplikasi mobile.
-- Dipakai oleh: Manajemen Koleksi, kartu "Koleksi terdaftar".
--
-- Kolom foto/video/pdf bernilai NULL kalau belum diunggah. Label "Lengkap /
-- Belum ada video / ..." di tabel tidak disimpan, tetapi dihitung di view v_collections.
-- ----------------------------------------------------------------------------
CREATE TABLE collections (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(150) NOT NULL,                         -- nama koleksi
  era         VARCHAR(50)  NOT NULL,                         -- Kanjuruhan, Tumapel, Singosari, Majapahit, Prasasti
  period      VARCHAR(80)  NULL,                             -- mis. "Abad 13"
  origin      VARCHAR(120) NULL,                             -- asal temuan, mis. "Malang Raya"
  material    VARCHAR(100) NULL,                             -- mis. "Batu andesit"
  dimensions  VARCHAR(120) NULL,                             -- mis. "T 90 cm, L 60 cm"
  meaning     TEXT         NULL,                             -- sejarah, fungsi, dan makna (tampil di aplikasi)
  photo_path  VARCHAR(255) NULL,
  video_url   VARCHAR(255) NULL,
  pdf_path    VARCHAR(255) NULL,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_collections_era ON collections (era);

-- Koleksi lengkap dengan label kelengkapan media (sama dengan kolom "Video & PDF" di tabel).
CREATE VIEW v_collections AS
SELECT
  c.*,
  CASE
    WHEN c.video_url IS NOT NULL AND c.pdf_path IS NOT NULL THEN 'Lengkap'
    WHEN c.video_url IS NULL     AND c.pdf_path IS NULL     THEN 'Belum ada video dan PDF'
    WHEN c.video_url IS NULL                                THEN 'Belum ada video'
    ELSE 'Belum ada PDF'
  END AS status_media
FROM collections c;
