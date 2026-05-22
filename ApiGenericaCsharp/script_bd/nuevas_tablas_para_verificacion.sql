-- ============================================================
-- Script de actualización para sistema de roles, rutas y verificación
-- Compatibles con PostgreSQL, MySQL/MariaDB y SQL Server
-- ============================================================

-- ============================================================
-- 1. TABLA: verificacion_cuenta
-- Propósito: Almacenar códigos de verificación temporales para registros
-- ============================================================

-- Nota: Esta tabla es común para PostgreSQL, MySQL y SQL Server
-- Solo cambian los tipos de datos y sintaxis de auto-incremento

-- Para PostgreSQL:
CREATE TABLE IF NOT EXISTS verificacion_cuenta (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE,
    codigo_verificacion VARCHAR(6) NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP NOT NULL,
    verificado BOOLEAN DEFAULT FALSE,
    intentos_fallidos INTEGER DEFAULT 0,
    CONSTRAINT chk_codigo_length CHECK (length(codigo_verificacion) = 6)
);

CREATE INDEX IF NOT EXISTS idx_verificacion_email ON verificacion_cuenta(email);
CREATE INDEX IF NOT EXISTS idx_verificacion_codigo ON verificacion_cuenta(codigo_verificacion);

-- ============================================================
-- 2. ACTUALIZAR TABLA: usuario
-- Agregamos campos para control de cuenta
-- ============================================================

-- Para PostgreSQL (agregar columnas si no existen):
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS cuenta_verificada BOOLEAN DEFAULT FALSE;
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE usuario ADD COLUMN IF NOT EXISTS fecha_ultimo_cambio_contrasena TIMESTAMP;

-- ============================================================
-- 3. TABLA: rol_usuario (relación muchos a muchos)
-- Propósito: Asignar múltiples roles a un usuario
-- ============================================================

CREATE TABLE IF NOT EXISTS rol_usuario (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) NOT NULL REFERENCES usuario(email) ON DELETE CASCADE,
    id_rol INTEGER NOT NULL REFERENCES rol(id) ON DELETE CASCADE,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_rol_usuario UNIQUE(email, id_rol)
);

CREATE INDEX IF NOT EXISTS idx_rol_usuario_email ON rol_usuario(email);
CREATE INDEX IF NOT EXISTS idx_rol_usuario_rol ON rol_usuario(id_rol);

-- ============================================================
-- 4. TABLA: ruta_rol (relación muchos a muchos)
-- Propósito: Asignar rutas/permisos a roles
-- ============================================================

CREATE TABLE IF NOT EXISTS ruta_rol (
    id SERIAL PRIMARY KEY,
    id_rol INTEGER NOT NULL REFERENCES rol(id) ON DELETE CASCADE,
    id_ruta INTEGER NOT NULL REFERENCES ruta(id) ON DELETE CASCADE,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_ruta_rol UNIQUE(id_rol, id_ruta)
);

CREATE INDEX IF NOT EXISTS idx_ruta_rol_rol ON ruta_rol(id_rol);
CREATE INDEX IF NOT EXISTS idx_ruta_rol_ruta ON ruta_rol(id_ruta);

-- ============================================================
-- 5. DATOS DE EJEMPLO
-- ============================================================

-- Insertar roles si no existen (para PostgreSQL, usar SERIAL):
INSERT INTO rol (nombre) VALUES ('Admin') ON CONFLICT DO NOTHING;
INSERT INTO rol (nombre) VALUES ('Usuario') ON CONFLICT DO NOTHING;
INSERT INTO rol (nombre) VALUES ('Vendedor') ON CONFLICT DO NOTHING;
INSERT INTO rol (nombre) VALUES ('Gerente') ON CONFLICT DO NOTHING;

-- Insertar rutas de ejemplo si no existen:
-- Insertar rutas reales del frontend si no existen:
INSERT INTO ruta (ruta, descripcion) VALUES ('/', 'Página principal / Home') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/login', 'Pantalla de inicio de sesión') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/error', 'Página de error') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/sin-acceso', 'Página de acceso denegado') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/admin/usuarios', 'Administración de usuarios (panel admin)') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/acreditacion', 'Acreditación') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/activ_academica', 'Actividad académica') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/aspecto_normativo', 'Aspecto normativo') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/aliado', 'Aliados / Colaboradores') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/enfoque', 'Enfoque institucional') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/car_innovacion', 'Características de innovación') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/departamento', 'Gestión de departamentos') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/facultad', 'Gestión de facultades') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/pasantia', 'Pasantías') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/premio', 'Premios y reconocimientos') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/programa', 'Programas académicos') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/practica_estrategia', 'Prácticas y estrategias') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/registro', 'Página de registro de usuarios') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/registro_calificado', 'Registro calificado') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/recuperar-contrasena', 'Recuperar contraseña') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/rol', 'Gestión de roles') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/ruta', 'Gestión de rutas/permisos') ON CONFLICT DO NOTHING;
INSERT INTO ruta (ruta, descripcion) VALUES ('/universidad', 'Información de la universidad') ON CONFLICT DO NOTHING;

-- ============================================================
-- NOTAS IMPORTANTES
-- ============================================================
-- 1. Para SQL Server, cambiar:
--    - SERIAL por IDENTITY(1,1)
--    - TIMESTAMP por DATETIME2
--    - ON CONFLICT por IF NOT EXISTS
--    
-- 2. Para MySQL/MariaDB:
--    - SERIAL por AUTO_INCREMENT INT
--    - TIMESTAMP igual funciona
--    - ON CONFLICT DO NOTHING por ON DUPLICATE KEY UPDATE (si es necesario)
--
-- 3. Los índices mejoran la performance de búsquedas frecuentes
--
-- 4. Los constraints UNIQUE previenen duplicados
--
-- 5. ON DELETE CASCADE elimina datos relacionados automáticamente
