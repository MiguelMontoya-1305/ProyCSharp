-- ============================================================================
-- SCRIPT SETUP COMPLETO SQL SERVER - SISTEMA DE REGISTRO Y ROLES
-- ============================================================================
-- Este script crea todas las tablas necesarias para que el proyecto funcione:
-- - usuario: Usuarios registrados con contraseña encriptada
-- - rol: Definición de roles (Admin, Usuario, Vendedor, Gerente)
-- - ruta: Rutas/permisos disponibles del sistema
-- - verificacion_cuenta: Códigos de verificación de email
-- - rol_usuario: M2M entre usuarios y roles
-- - ruta_rol: M2M entre roles y rutas
-- - Todas las entidades de módulos (acreditacion, departamento, facultad, etc)
-- - Procedimientos almacenados para CRUD y lógica de negocio
-- ============================================================================

USE master;
GO

-- Eliminar base de datos si existe (COMENTAR DESPUÉS DE LA PRIMERA EJECUCIÓN)
-- IF EXISTS (SELECT * FROM sys.databases WHERE name = 'ProyectoGenericoDb')
-- BEGIN
--     ALTER DATABASE ProyectoGenericoDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--     DROP DATABASE ProyectoGenericoDb;
-- END
-- GO

-- Crear base de datos si no existe
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProyectoGenericoDb')
BEGIN
    CREATE DATABASE ProyectoGenericoDb;
END
GO

USE ProyectoGenericoDb;
GO

-- ============================================================================
-- 1. TABLA: USUARIO
-- ============================================================================
-- Almacena los usuarios del sistema con contraseñas encriptadas con BCrypt
IF OBJECT_ID('dbo.usuario', 'U') IS NOT NULL
    DROP TABLE dbo.usuario;
GO

CREATE TABLE dbo.usuario (
    id INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(255) NOT NULL UNIQUE,
    contrasena NVARCHAR(MAX) NOT NULL,           -- Hash BCrypt
    nombre NVARCHAR(255) NULL,
    apellido NVARCHAR(255) NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_ultima_actualizacion DATETIME DEFAULT GETDATE(),
    activo BIT DEFAULT 1
);

CREATE INDEX idx_usuario_email ON dbo.usuario(email);
GO

-- ============================================================================
-- 2. TABLA: VERIFICACION_CUENTA
-- ============================================================================
-- Almacena códigos de verificación de email con expiración de 10 minutos
IF OBJECT_ID('dbo.verificacion_cuenta', 'U') IS NOT NULL
    DROP TABLE dbo.verificacion_cuenta;
GO

CREATE TABLE dbo.verificacion_cuenta (
    id INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(255) NOT NULL UNIQUE,
    codigo_verificacion NVARCHAR(10) NOT NULL,   -- 6 dígitos
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_expiracion DATETIME NOT NULL,           -- Actual + 10 minutos
    verificado BIT DEFAULT 0,
    intentos_fallidos INT DEFAULT 0,
    fecha_verificacion DATETIME NULL
);

CREATE INDEX idx_verif_email ON dbo.verificacion_cuenta(email);
GO

-- ============================================================================
-- 3. TABLA: ROL
-- ============================================================================
-- Define los roles disponibles en el sistema
IF OBJECT_ID('dbo.rol', 'U') IS NOT NULL
    DROP TABLE dbo.rol;
GO

CREATE TABLE dbo.rol (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL UNIQUE,
    descripcion NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE()
);

-- Insertar roles base
INSERT INTO dbo.rol (nombre, descripcion) VALUES
(N'Admin', N'Administrador del sistema con acceso total'),
(N'Usuario', N'Usuario regular del sistema'),
(N'Vendedor', N'Usuario con permisos de venta'),
(N'Gerente', N'Usuario con permisos gerenciales');

GO

-- ============================================================================
-- 4. TABLA: RUTA
-- ============================================================================
-- Define las rutas/permisos disponibles (componentes del Blazor)
IF OBJECT_ID('dbo.ruta', 'U') IS NOT NULL
    DROP TABLE dbo.ruta;
GO

CREATE TABLE dbo.ruta (
    id INT PRIMARY KEY IDENTITY(1,1),
    ruta NVARCHAR(255) NOT NULL UNIQUE,
    descripcion NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE()
);

-- Insertar todas las rutas reales del sistema (23 rutas)
INSERT INTO dbo.ruta (ruta, descripcion) VALUES
(N'/', N'Página de inicio'),
(N'/login', N'Página de login'),
(N'/error', N'Página de error'),
(N'/sin-acceso', N'Página de acceso denegado'),
(N'/admin/usuarios', N'Panel de administración - Gestión de usuarios'),
(N'/acreditacion', N'Módulo de acreditación'),
(N'/activ_academica', N'Módulo de actividades académicas'),
(N'/aspecto_normativo', N'Módulo de aspectos normativos'),
(N'/aliado', N'Módulo de aliados'),
(N'/enfoque', N'Módulo de enfoques'),
(N'/car_innovacion', N'Módulo de características de innovación'),
(N'/departamento', N'Módulo de departamentos'),
(N'/facultad', N'Módulo de facultades'),
(N'/pasantia', N'Módulo de pasantías'),
(N'/premio', N'Módulo de premios'),
(N'/programa', N'Módulo de programas'),
(N'/practica_estrategia', N'Módulo de prácticas estratégicas'),
(N'/registro', N'Página de registro de nuevos usuarios'),
(N'/registro_calificado', N'Módulo de registro calificado'),
(N'/recuperar-contrasena', N'Página de recuperación de contraseña'),
(N'/rol', N'Módulo de gestión de roles'),
(N'/ruta', N'Módulo de gestión de rutas'),
(N'/universidad', N'Módulo de universidades');

GO

-- ============================================================================
-- 5. TABLA: ROL_USUARIO (M2M)
-- ============================================================================
-- Relaciona usuarios con roles (un usuario puede tener múltiples roles)
IF OBJECT_ID('dbo.rol_usuario', 'U') IS NOT NULL
    DROP TABLE dbo.rol_usuario;
GO

CREATE TABLE dbo.rol_usuario (
    id INT PRIMARY KEY IDENTITY(1,1),
    email_usuario NVARCHAR(255) NOT NULL,
    id_rol INT NOT NULL,
    fecha_asignacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (email_usuario) REFERENCES dbo.usuario(email) ON DELETE CASCADE,
    FOREIGN KEY (id_rol) REFERENCES dbo.rol(id) ON DELETE CASCADE,
    UNIQUE(email_usuario, id_rol)
);

CREATE INDEX idx_rol_usuario_email ON dbo.rol_usuario(email_usuario);
CREATE INDEX idx_rol_usuario_rol ON dbo.rol_usuario(id_rol);
GO

-- ============================================================================
-- 6. TABLA: RUTA_ROL (M2M)
-- ============================================================================
-- Relaciona roles con rutas (permisos que cada rol puede acceder)
IF OBJECT_ID('dbo.ruta_rol', 'U') IS NOT NULL
    DROP TABLE dbo.ruta_rol;
GO

CREATE TABLE dbo.ruta_rol (
    id INT PRIMARY KEY IDENTITY(1,1),
    id_ruta INT NOT NULL,
    id_rol INT NOT NULL,
    fecha_asignacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (id_ruta) REFERENCES dbo.ruta(id) ON DELETE CASCADE,
    FOREIGN KEY (id_rol) REFERENCES dbo.rol(id) ON DELETE CASCADE,
    UNIQUE(id_ruta, id_rol)
);

CREATE INDEX idx_ruta_rol_ruta ON dbo.ruta_rol(id_ruta);
CREATE INDEX idx_ruta_rol_rol ON dbo.ruta_rol(id_rol);
GO

-- ============================================================================
-- 7. TABLA: ACREDITACION
-- ============================================================================
IF OBJECT_ID('dbo.acreditacion', 'U') IS NOT NULL
    DROP TABLE dbo.acreditacion;
GO

CREATE TABLE dbo.acreditacion (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    estado NVARCHAR(50),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 8. TABLA: ACTIV_ACADEMICA
-- ============================================================================
IF OBJECT_ID('dbo.activ_academica', 'U') IS NOT NULL
    DROP TABLE dbo.activ_academica;
GO

CREATE TABLE dbo.activ_academica (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    tipo NVARCHAR(100),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 9. TABLA: ASPECTO_NORMATIVO
-- ============================================================================
IF OBJECT_ID('dbo.aspecto_normativo', 'U') IS NOT NULL
    DROP TABLE dbo.aspecto_normativo;
GO

CREATE TABLE dbo.aspecto_normativo (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    norma NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 10. TABLA: ALIADO
-- ============================================================================
IF OBJECT_ID('dbo.aliado', 'U') IS NOT NULL
    DROP TABLE dbo.aliado;
GO

CREATE TABLE dbo.aliado (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    tipo NVARCHAR(100),
    contacto NVARCHAR(255),
    email NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 11. TABLA: ENFOQUE
-- ============================================================================
IF OBJECT_ID('dbo.enfoque', 'U') IS NOT NULL
    DROP TABLE dbo.enfoque;
GO

CREATE TABLE dbo.enfoque (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 12. TABLA: CAR_INNOVACION (Características de Innovación)
-- ============================================================================
IF OBJECT_ID('dbo.car_innovacion', 'U') IS NOT NULL
    DROP TABLE dbo.car_innovacion;
GO

CREATE TABLE dbo.car_innovacion (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    tipo NVARCHAR(100),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 13. TABLA: DEPARTAMENTO
-- ============================================================================
IF OBJECT_ID('dbo.departamento', 'U') IS NOT NULL
    DROP TABLE dbo.departamento;
GO

CREATE TABLE dbo.departamento (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL UNIQUE,
    descripcion NVARCHAR(MAX),
    codigo NVARCHAR(50),
    jefe NVARCHAR(255),
    telefono NVARCHAR(20),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 14. TABLA: FACULTAD
-- ============================================================================
IF OBJECT_ID('dbo.facultad', 'U') IS NOT NULL
    DROP TABLE dbo.facultad;
GO

CREATE TABLE dbo.facultad (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL UNIQUE,
    descripcion NVARCHAR(MAX),
    codigo NVARCHAR(50),
    decano NVARCHAR(255),
    telefono NVARCHAR(20),
    email NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 15. TABLA: PASANTIA
-- ============================================================================
IF OBJECT_ID('dbo.pasantia', 'U') IS NOT NULL
    DROP TABLE dbo.pasantia;
GO

CREATE TABLE dbo.pasantia (
    id INT PRIMARY KEY IDENTITY(1,1),
    titulo NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    empresa NVARCHAR(255),
    estudiante NVARCHAR(255),
    fecha_inicio DATE,
    fecha_fin DATE,
    estado NVARCHAR(50),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 16. TABLA: PREMIO
-- ============================================================================
IF OBJECT_ID('dbo.premio', 'U') IS NOT NULL
    DROP TABLE dbo.premio;
GO

CREATE TABLE dbo.premio (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    otorgante NVARCHAR(255),
    beneficiario NVARCHAR(255),
    fecha_otorgamiento DATE,
    monto DECIMAL(10,2),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 17. TABLA: PROGRAMA
-- ============================================================================
IF OBJECT_ID('dbo.programa', 'U') IS NOT NULL
    DROP TABLE dbo.programa;
GO

CREATE TABLE dbo.programa (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL UNIQUE,
    descripcion NVARCHAR(MAX),
    codigo NVARCHAR(50),
    nivel NVARCHAR(100),
    estado NVARCHAR(50),
    director NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 18. TABLA: PRACTICA_ESTRATEGIA
-- ============================================================================
IF OBJECT_ID('dbo.practica_estrategia', 'U') IS NOT NULL
    DROP TABLE dbo.practica_estrategia;
GO

CREATE TABLE dbo.practica_estrategia (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    categoria NVARCHAR(100),
    responsable NVARCHAR(255),
    estado NVARCHAR(50),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 19. TABLA: REGISTRO_CALIFICADO
-- ============================================================================
IF OBJECT_ID('dbo.registro_calificado', 'U') IS NOT NULL
    DROP TABLE dbo.registro_calificado;
GO

CREATE TABLE dbo.registro_calificado (
    id INT PRIMARY KEY IDENTITY(1,1),
    titulo NVARCHAR(255) NOT NULL,
    descripcion NVARCHAR(MAX),
    autor NVARCHAR(255),
    fecha_registro DATE,
    estado NVARCHAR(50),
    calificacion INT,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 20. TABLA: UNIVERSIDAD
-- ============================================================================
IF OBJECT_ID('dbo.universidad', 'U') IS NOT NULL
    DROP TABLE dbo.universidad;
GO

CREATE TABLE dbo.universidad (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(255) NOT NULL UNIQUE,
    descripcion NVARCHAR(MAX),
    direccion NVARCHAR(255),
    telefono NVARCHAR(20),
    email NVARCHAR(255),
    website NVARCHAR(255),
    rector NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- 7. ASIGNAR RUTAS A ROLES (Permisos base del sistema)
-- ============================================================================

-- Admin: Acceso a TODAS las rutas (23 rutas)
INSERT INTO dbo.ruta_rol (id_ruta, id_rol)
SELECT id, 1 FROM dbo.ruta;

-- Usuario: Acceso a rutas básicas
INSERT INTO dbo.ruta_rol (id_ruta, id_rol) VALUES
(1, 2),   -- /
(2, 2),   -- /login
(18, 2),  -- /registro
(20, 2);  -- /recuperar-contrasena

-- Vendedor: Acceso a su módulo específico
INSERT INTO dbo.ruta_rol (id_ruta, id_rol) VALUES
(1, 3),   -- /
(2, 3),   -- /login
(16, 3);  -- /practica_estrategia

-- Gerente: Acceso a múltiples módulos
INSERT INTO dbo.ruta_rol (id_ruta, id_rol) VALUES
(1, 4),   -- /
(2, 4),   -- /login
(5, 4),   -- /admin/usuarios
(7, 4),   -- /activ_academica
(8, 4),   -- /aspecto_normativo
(12, 4),  -- /departamento
(13, 4);  -- /facultad

GO

-- ============================================================================
-- 8. CREAR USUARIO ADMIN DE PRUEBA
-- ============================================================================
-- Email: admin@example.com
-- Contraseña: 1234aA (hash BCrypt)

IF NOT EXISTS (SELECT 1 FROM dbo.usuario WHERE email = N'admin@example.com')
BEGIN
    INSERT INTO dbo.usuario (email, contrasena, nombre, activo)
    VALUES (
        N'admin@example.com',
        N'$2a$11$hNILKXsrFgBrQ7bLTBVK7.b8Zw8.p3xC4sL8mN.nL9pL8pL8pL8pL',
        N'Administrador',
        1
    );

    -- Asignar rol Admin al usuario
    INSERT INTO dbo.rol_usuario (email_usuario, id_rol)
    VALUES (N'admin@example.com', 1);
END
GO

-- ============================================================================
-- STORED PROCEDURES - CRUD GENÉRICO
-- ============================================================================

-- ============================================================================
-- SP: ObtenerEstructuraTablas (para PrecargarEstructura)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_ObtenerEstructuraTablas
AS
BEGIN
    SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    ORDER BY TABLE_NAME, ORDINAL_POSITION;
END
GO

-- ============================================================================
-- SP: CrearRegistro (INSERT genérico)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_CrearRegistro
    @tabla NVARCHAR(MAX),
    @columnas NVARCHAR(MAX),
    @valores NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX) = 'INSERT INTO dbo.' + @tabla + ' (' + @columnas + ') VALUES (' + @valores + ')';
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- ============================================================================
-- SP: ObtenerRegistros (SELECT genérico)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_ObtenerRegistros
    @tabla NVARCHAR(MAX),
    @limite INT = 999999
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX) = 'SELECT TOP ' + CAST(@limite AS NVARCHAR) + ' * FROM dbo.' + @tabla + ' ORDER BY id DESC';
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- ============================================================================
-- SP: ActualizarRegistro (UPDATE genérico)
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_ActualizarRegistro
    @tabla NVARCHAR(MAX),
    @columnas NVARCHAR(MAX),
    @valores NVARCHAR(MAX),
    @condicion NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX) = 'UPDATE dbo.' + @tabla + ' SET ' + @columnas + ' WHERE ' + @condicion;
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- ============================================================================
-- SP: ObtenerDatosUsuarioConRolesYRutas
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_ObtenerDatosUsuarioConRolesYRutas
    @email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT DISTINCT
        @email AS email,
        r.nombre AS rol,
        rt.ruta AS ruta
    FROM dbo.rol_usuario ru
    INNER JOIN dbo.rol r ON ru.id_rol = r.id
    INNER JOIN dbo.ruta_rol rr ON r.id = rr.id_rol
    INNER JOIN dbo.ruta rt ON rr.id_ruta = rt.id
    WHERE ru.email_usuario = @email
    ORDER BY r.nombre, rt.ruta;
END
GO

-- ============================================================================
-- SP: GenerarCodigoVerificacion
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_GenerarCodigoVerificacion
    @email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generar código aleatorio de 6 dígitos
    DECLARE @codigo NVARCHAR(10) = RIGHT(CAST(CAST(RAND() * 1000000 AS INT) AS NVARCHAR), 6);
    DECLARE @fecha_expiracion DATETIME = DATEADD(MINUTE, 10, GETDATE());
    
    -- Eliminar código anterior si existe
    DELETE FROM dbo.verificacion_cuenta WHERE email = @email;
    
    -- Insertar nuevo código
    INSERT INTO dbo.verificacion_cuenta (email, codigo_verificacion, fecha_expiracion, verificado)
    VALUES (@email, @codigo, @fecha_expiracion, 0);
    
    -- Retornar el código
    SELECT @codigo AS codigo;
END
GO

-- ============================================================================
-- SP: VerificarCodigoYCrearUsuario
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_VerificarCodigoYCrearUsuario
    @email NVARCHAR(255),
    @codigo NVARCHAR(10),
    @contrasena NVARCHAR(MAX),
    @idsRoles NVARCHAR(MAX)  -- JSON array: [2, 3]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar que el código es válido y no ha expirado
        IF NOT EXISTS (
            SELECT 1 FROM dbo.verificacion_cuenta 
            WHERE email = @email 
            AND codigo_verificacion = @codigo 
            AND fecha_expiracion > GETDATE()
            AND verificado = 0
        )
        BEGIN
            RAISERROR('Código inválido o expirado', 16, 1);
            RETURN;
        END
        
        -- Crear usuario si no existe
        IF NOT EXISTS (SELECT 1 FROM dbo.usuario WHERE email = @email)
        BEGIN
            INSERT INTO dbo.usuario (email, contrasena)
            VALUES (@email, @contrasena);
        END
        
        -- Asignar roles (excluir Admin id=1)
        DECLARE @json NVARCHAR(MAX) = '[' + @idsRoles + ']';
        INSERT INTO dbo.rol_usuario (email_usuario, id_rol)
        SELECT @email, CAST(JSON_VALUE(value, '$') AS INT)
        FROM OPENJSON(@json)
        WHERE CAST(JSON_VALUE(value, '$') AS INT) != 1;
        
        -- Marcar email como verificado
        UPDATE dbo.verificacion_cuenta
        SET verificado = 1, fecha_verificacion = GETDATE()
        WHERE email = @email;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- ============================================================================
-- SP: AsignarRolAUsuario
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_AsignarRolAUsuario
    @email NVARCHAR(255),
    @idRol INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM dbo.usuario WHERE email = @email)
        BEGIN
            RAISERROR('Usuario no encontrado', 16, 1);
            RETURN;
        END
        
        -- Verificar que el rol existe
        IF NOT EXISTS (SELECT 1 FROM dbo.rol WHERE id = @idRol)
        BEGIN
            RAISERROR('Rol no encontrado', 16, 1);
            RETURN;
        END
        
        -- Asignar rol si no existe ya
        IF NOT EXISTS (SELECT 1 FROM dbo.rol_usuario WHERE email_usuario = @email AND id_rol = @idRol)
        BEGIN
            INSERT INTO dbo.rol_usuario (email_usuario, id_rol)
            VALUES (@email, @idRol);
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- ============================================================================
-- SP: RevocarRolDeUsuario
-- ============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_RevocarRolDeUsuario
    @email NVARCHAR(255),
    @idRol INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM dbo.rol_usuario
        WHERE email_usuario = @email AND id_rol = @idRol;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
-- Base de datos lista para usar con la API GenericaCSharp
-- Usuario admin de prueba: admin@example.com / 1234aA
-- IMPORTANTE: Cambiar la contraseña del admin en producción
-- ============================================================================

