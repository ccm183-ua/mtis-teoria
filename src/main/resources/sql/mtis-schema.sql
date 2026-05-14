-- Base de datos MTIS - Plataforma E-Learning (Grupo 20)
-- Ejecutar como usuario con privilegios: CREATE DATABASE IF NOT EXISTS mtis;
-- mysql -u root -p < mtis-schema.sql

CREATE DATABASE IF NOT EXISTS mtis CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mtis;

CREATE TABLE IF NOT EXISTS restkey (
    id INT AUTO_INCREMENT NOT NULL,
    rest_key VARCHAR(255) NOT NULL,
    description VARCHAR(255) NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_rest_key (rest_key)
);

-- Si restkey se creó antes sin 'description', añadirla (evita ERROR 1054 al INSERT)
SET @col_exists := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'restkey' AND COLUMN_NAME = 'description'
);
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE restkey ADD COLUMN description VARCHAR(255) NULL',
    'SELECT 1');
PREPARE stmt_restkey_desc FROM @ddl;
EXECUTE stmt_restkey_desc;
DEALLOCATE PREPARE stmt_restkey_desc;

CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('student', 'instructor', 'admin') NOT NULL DEFAULT 'student',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_users_email (email)
);

CREATE TABLE IF NOT EXISTS courses (
    id CHAR(36) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructor_id CHAR(36) NOT NULL,
    instructor_name VARCHAR(100),
    category VARCHAR(100),
    duration_hours INT,
    price DECIMAL(10,2),
    currency CHAR(3) DEFAULT 'EUR',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    external_content_id VARCHAR(255),
    external_last_modified TIMESTAMP NULL,
    external_checksum VARCHAR(255),
    PRIMARY KEY (id),
    CONSTRAINT fk_course_instructor
        FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS enrollments (
    id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    course_id CHAR(36) NOT NULL,
    enrollment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('ACTIVE', 'CANCELLED', 'COMPLETED') NOT NULL DEFAULT 'ACTIVE',
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_course (user_id, course_id),
    CONSTRAINT fk_enrollment_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS evaluation_results (
    id CHAR(36) NOT NULL,
    enrollment_id CHAR(36) NOT NULL,
    course_id CHAR(36) NOT NULL,
    grade DECIMAL(5,2) NULL,
    passed BOOLEAN NULL,
    answers_json JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_eval_enrollment (enrollment_id),
    CONSTRAINT fk_eval_enrollment
        FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE,
    CONSTRAINT fk_eval_course
        FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS payments (
    id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    course_id CHAR(36) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'EUR',
    status ENUM('PENDING', 'CONFIRMED', 'CANCELLED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    external_ref VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_payment_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS certificates (
    id CHAR(36) NOT NULL,
    enrollment_id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    course_id CHAR(36) NOT NULL,
    grade DECIMAL(5,2) NOT NULL,
    issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    certificate_payload TEXT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_cert_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE,
    CONSTRAINT fk_cert_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_cert_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS email_log (
    id CHAR(36) NOT NULL,
    recipient_email VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body TEXT,
    notification_type ENUM('WELCOME', 'ENROLLMENT', 'CERTIFICATE', 'ERROR', 'OTHER') NOT NULL DEFAULT 'OTHER',
    status ENUM('SENT', 'FAILED', 'PENDING') NOT NULL DEFAULT 'PENDING',
    related_user_id CHAR(36) NULL,
    sent_at TIMESTAMP NULL DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    error_message TEXT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_email_log_user
        FOREIGN KEY (related_user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS legacy_sync_log (
    id CHAR(36) NOT NULL,
    operation VARCHAR(100) NOT NULL,
    status ENUM('OK', 'ERROR') NOT NULL,
    detail TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

INSERT INTO restkey (rest_key, description) VALUES ('elearning-key-2025', 'API pública plataforma e-learning')
ON DUPLICATE KEY UPDATE rest_key = VALUES(rest_key);

-- Datos demo (contraseña para ambos: password123)
INSERT INTO users (id, name, email, password, role, active)
SELECT '00000000-0000-0000-0000-000000000001', 'Administrador MTIS', 'admin@mtis.local',
       '$2a$10$UoajRJtZKu8lV2GT.9YfX.wVJVxzxwAi.M9Ng35prnuL4x0qT3o8y', 'admin', TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@mtis.local');

INSERT INTO users (id, name, email, password, role, active)
SELECT '00000000-0000-0000-0000-000000000002', 'Profesor Demo', 'instructor@mtis.local',
       '$2a$10$UoajRJtZKu8lV2GT.9YfX.wVJVxzxwAi.M9Ng35prnuL4x0qT3o8y', 'instructor', TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'instructor@mtis.local');

INSERT INTO courses (id, title, description, instructor_id, instructor_name, category, duration_hours, price, currency, active)
SELECT '10000000-0000-0000-0000-000000000001', 'Integración SOA con Mule 4', 'Curso introductorio MTIS',
       '00000000-0000-0000-0000-000000000002', 'Profesor Demo', 'Integración', 40, 0.00, 'EUR', TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses WHERE id = '10000000-0000-0000-0000-000000000001');

INSERT INTO users (id, name, email, password, role, active)
SELECT '00000000-0000-0000-0000-000000000003', 'Estudiante Demo', 'student@mtis.local',
       '$2a$10$UoajRJtZKu8lV2GT.9YfX.wVJVxzxwAi.M9Ng35prnuL4x0qT3o8y', 'student', TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'student@mtis.local');

INSERT INTO enrollments (id, user_id, course_id, status)
SELECT '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003',
       '10000000-0000-0000-0000-000000000001', 'ACTIVE'
WHERE NOT EXISTS (SELECT 1 FROM enrollments WHERE id = '20000000-0000-0000-0000-000000000001');
