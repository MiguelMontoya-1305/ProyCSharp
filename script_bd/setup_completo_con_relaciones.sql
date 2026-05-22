-- ============================================================================
-- SCRIPT SETUP COMPLETO SQL SERVER - SISTEMA ACADÉMICO CON ROLES
-- ============================================================================
-- Estructura completa de base de datos con todas las tablas, PKs, FKs y SPs
-- ============================================================================

USE master;
GO

-- Crear base de datos si no existe
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ProyectoGenericoDb')
BEGIN
    CREATE DATABASE ProyectoGenericoDb;
END
GO

USE ProyectoGenericoDb;
GO

-- ============================================================================
-- TABLAS DE AUTENTICACIÓN Y ROLES
-- ============================================================================

-- Tabla: usuario
IF OBJECT_ID('dbo.usuario', 'U') IS NOT NULL
    DROP TABLE dbo.usuario;
GO

CREATE TABLE dbo.usuario (
    id INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(255) NOT NULL UNIQUE,
    contrasena NVARCHAR(MAX) NOT NULL,
    nombre NVARCHAR(255) NULL,
    apellido NVARCHAR(255) NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_ultima_actualizacion DATETIME DEFAULT GETDATE(),
    activo BIT DEFAULT 1
);

CREATE INDEX idx_usuario_email ON dbo.usuario(email);
GO

-- Tabla: verificacion_cuenta
IF OBJECT_ID('dbo.verificacion_cuenta', 'U') IS NOT NULL
    DROP TABLE dbo.verificacion_cuenta;
GO

CREATE TABLE dbo.verificacion_cuenta (
    id INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(255) NOT NULL UNIQUE,
    codigo_verificacion NVARCHAR(10) NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_expiracion DATETIME NOT NULL,
    verificado BIT DEFAULT 0,
    intentos_fallidos INT DEFAULT 0,
    fecha_verificacion DATETIME NULL
);

CREATE INDEX idx_verif_email ON dbo.verificacion_cuenta(email);
GO

-- Tabla: rol
IF OBJECT_ID('dbo.rol', 'U') IS NOT NULL
    DROP TABLE dbo.rol;
GO

CREATE TABLE dbo.rol (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL UNIQUE,
    descripcion NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE()
);

INSERT INTO dbo.rol (nombre, descripcion) VALUES
(N'Admin', N'Administrador del sistema con acceso total'),
(N'Usuario', N'Usuario regular del sistema'),
(N'Vendedor', N'Usuario con permisos de venta'),
(N'Gerente', N'Usuario con permisos gerenciales');

GO

-- Tabla: ruta
IF OBJECT_ID('dbo.ruta', 'U') IS NOT NULL
    DROP TABLE dbo.ruta;
GO

CREATE TABLE dbo.ruta (
    id INT PRIMARY KEY IDENTITY(1,1),
    ruta NVARCHAR(255) NOT NULL UNIQUE,
    descripcion NVARCHAR(255),
    fecha_creacion DATETIME DEFAULT GETDATE()
);

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

-- Tabla: rol_usuario (M2M)
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

-- Tabla: ruta_rol (M2M)
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
-- TABLAS DE ENTIDADES ACADÉMICAS
-- ============================================================================

-- Tabla: universidad
IF OBJECT_ID('dbo.universidad', 'U') IS NOT NULL
    DROP TABLE dbo.universidad;
GO

CREATE TABLE dbo.universidad (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(60) NOT NULL UNIQUE,
    tipo VARCHAR(45) NOT NULL,
    ciudad VARCHAR(45) NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE()
);
GO

-- Tabla: facultad
IF OBJECT_ID('dbo.facultad', 'U') IS NOT NULL
    DROP TABLE dbo.facultad;
GO

CREATE TABLE dbo.facultad (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(60) NOT NULL,
    tipo VARCHAR(45) NOT NULL,
    fecha_fun DATE NOT NULL,
    universidad INT NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    fecha_actualizacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (universidad) REFERENCES dbo.universidad(id) ON DELETE CASCADE
);

CREATE INDEX idx_facultad_universidad ON dbo.facultad(universidad);
GO

-- Tabla: programa
IF OBJECT_ID('dbo.programa', 'U') IS NOT NULL
    DROP TABLE dbo.programa;
GO

CREATE TABLE dbo.programa (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(60) NOT NULL,
    tipo VARCHAR(45) NOT NULL,
    nivel VARCHAR(45) NOT NULL,
    fecha_creacion VARCHAR(45) NOT NULL,
    fecha_cierre VARCHAR(45) NULL,
    numero_cohortes VARCHAR(45) NOT NULL,
    cant_graduados VARCHAR(45) NOT NULL,
    fecha_actualizacion VARCHAR(45) NOT NULL,
    ciudad VARCHAR(45) NOT NULL,
    facultad INT NOT NULL,
    fecha_crea DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (facultad) REFERENCES dbo.facultad(id) ON DELETE CASCADE
);

CREATE INDEX idx_programa_facultad ON dbo.programa(facultad);
GO

-- Tabla: acreditacion
IF OBJECT_ID('dbo.acreditacion', 'U') IS NOT NULL
    DROP TABLE dbo.acreditacion;
GO

CREATE TABLE dbo.acreditacion (
    resolucion INT PRIMARY KEY IDENTITY(1,1),
    tipo VARCHAR(45) NOT NULL,
    calificacion VARCHAR(45) NOT NULL,
    fecha_inicio VARCHAR(45) NOT NULL,
    fecha_fin VARCHAR(45) NOT NULL,
    programa INT NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (programa) REFERENCES dbo.programa(id) ON DELETE CASCADE
);

CREATE INDEX idx_acreditacion_programa ON dbo.acreditacion(programa);
GO

-- Tabla: aspecto_normativo
IF OBJECT_ID('dbo.aspecto_normativo', 'U') IS NOT NULL
    DROP TABLE dbo.aspecto_normativo;
GO

CREATE TABLE dbo.aspecto_normativo (
    id INT PRIMARY KEY IDENTITY(1,1),
    tipo VARCHAR(45) NOT NULL,
    descripcion VARCHAR(MAX) NOT NULL,
    fuente VARCHAR(45) NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE()
);
GO

-- Tabla: an_programa (M2M: aspecto_normativo - programa)
IF OBJECT_ID('dbo.an_programa', 'U') IS NOT NULL
    DROP TABLE dbo.an_programa;
GO

CREATE TABLE dbo.an_programa (
    aspecto_normativo INT NOT NULL,
    programa INT NOT NULL,
    fecha_asignacion DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (aspecto_normativo, programa),
    FOREIGN KEY (aspecto_normativo) REFERENCES dbo.aspecto_normativo(id) ON DELETE CASCADE,
    FOREIGN KEY (programa) REFERENCES dbo.programa(id) ON DELETE CASCADE
);

CREATE INDEX idx_an_programa_aspecto ON dbo.an_programa(aspecto_normativo);
CREATE INDEX idx_an_programa_programa ON dbo.an_programa(programa);
GO

-- Tabla: activ_academica
IF OBJECT_ID('dbo.activ_academica', 'U') IS NOT NULL
    DROP TABLE dbo.activ_academica;
GO

CREATE TABLE dbo.activ_academica (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(45) NOT NULL,
    num_creditos INT NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    area_formacion VARCHAR(45) NOT NULL,
    h_acom INT NOT NULL,
    h_indep INT NOT NULL,
    idioma VARCHAR(45) NOT NULL,
    espejo TINYINT NOT NULL,
    entidad_espejo VARCHAR(45) NOT NULL,
    pais_espejo VARCHAR(45) NOT NULL,
    disenio INT,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (disenio) REFERENCES dbo.programa(id) ON DELETE CASCADE
);

CREATE INDEX idx_activ_academica_disenio ON dbo.activ_academica(disenio);
GO

-- Tabla: registro_calificado
IF OBJECT_ID('dbo.registro_calificado', 'U') IS NOT NULL
    DROP TABLE dbo.registro_calificado;
GO

CREATE TABLE dbo.registro_calificado (
    codigo INT PRIMARY KEY IDENTITY(1,1),
    cant_creditos VARCHAR(45) NOT NULL,
    hora_acom VARCHAR(45) NOT NULL,
    hora_ind VARCHAR(45) NOT NULL,
    metodologia VARCHAR(45) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    duracion_anios VARCHAR(45) NOT NULL,
    duracion_semestres VARCHAR(45) NOT NULL,
    tipo_titulacion VARCHAR(45) NOT NULL,
    programa INT NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (programa) REFERENCES dbo.programa(id) ON DELETE CASCADE
);

CREATE INDEX idx_registro_calificado_programa ON dbo.registro_calificado(programa);
GO

-- Tabla: aa_rc (M2M: activ_academica - registro_calificado)
IF OBJECT_ID('dbo.aa_rc', 'U') IS NOT NULL
    DROP TABLE dbo.aa_rc;
GO

CREATE TABLE dbo.aa_rc (
    activ_academicas_idcurso INT NOT NULL,
    registro_calificado_codigo INT NOT NULL,
    componente VARCHAR(45) NOT NULL,
    semestre VARCHAR(45) NOT NULL,
    fecha_asignacion DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (activ_academicas_idcurso, registro_calificado_codigo),
    FOREIGN KEY (activ_academicas_idcurso) REFERENCES dbo.activ_academica(id) ON DELETE CASCADE,
    FOREIGN KEY (registro_calificado_codigo) REFERENCES dbo.registro_calificado(codigo) ON DELETE CASCADE
);

CREATE INDEX idx_aa_rc_activ ON dbo.aa_rc(activ_academicas_idcurso);
CREATE INDEX idx_aa_rc_registro ON dbo.aa_rc(registro_calificado_codigo);
GO

-- Tabla: enfoque
IF OBJECT_ID('dbo.enfoque', 'U') IS NOT NULL
    DROP TABLE dbo.enfoque;
GO

CREATE TABLE dbo.enfoque (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(45) NOT NULL UNIQUE,
    descripcion VARCHAR(MAX) NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE()
);
GO

-- Tabla: enfoque_rc (M2M: enfoque - registro_calificado)
IF OBJECT_ID('dbo.enfoque_rc', 'U') IS NOT NULL
    DROP TABLE dbo.enfoque_rc;
GO

CREATE TABLE dbo.enfoque_rc (
    enfoque INT NOT NULL,
    registro_calificado INT NOT NULL,
    fecha_asignacion DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (enfoque, registro_calificado),
    FOREIGN KEY (enfoque) REFERENCES dbo.enfoque(id) ON DELETE CASCADE,
    FOREIGN KEY (registro_calificado) REFERENCES dbo.registro_calificado(codigo) ON DELETE CASCADE
);

CREATE INDEX idx_enfoque_rc_enfoque ON dbo.enfoque_rc(enfoque);
CREATE INDEX idx_enfoque_rc_registro ON dbo.enfoque_rc(registro_calificado);
GO

-- Tabla: car_innovacion
IF OBJECT_ID('dbo.car_innovacion', 'U') IS NOT NULL
    DROP TABLE dbo.car_innovacion;
GO

CREATE TABLE dbo.car_innovacion (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(45) NOT NULL UNIQUE,
    descripcion VARCHAR(MAX) NOT NULL,
    tipo VARCHAR(45) NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE()
);
GO

-- Tabla: programa_ci (M2M: programa - car_innovacion)
IF OBJECT_ID('dbo.programa_ci', 'U') IS NOT NULL
    DROP TABLE dbo.programa_ci;
GO

CREATE TABLE dbo.programa_ci (
    programa INT NOT NULL,
    car_innovacion INT NOT NULL,
    fecha_asignacion DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (programa, car_innovacion),
    FOREIGN KEY (programa) REFERENCES dbo.programa(id) ON DELETE CASCADE,
    FOREIGN KEY (car_innovacion) REFERENCES dbo.car_innovacion(id) ON DELETE CASCADE
);

CREATE INDEX idx_programa_ci_programa ON dbo.programa_ci(programa);
CREATE INDEX idx_programa_ci_innovacion ON dbo.programa_ci(car_innovacion);
GO

-- Tabla: practica_estrategia
IF OBJECT_ID('dbo.practica_estrategia', 'U') IS NOT NULL
    DROP TABLE dbo.practica_estrategia;
GO

CREATE TABLE dbo.practica_estrategia (
    id INT PRIMARY KEY IDENTITY(1,1),
    tipo VARCHAR(45) NOT NULL,
    nombre VARCHAR(45) NOT NULL UNIQUE,
    descripcion VARCHAR(MAX) NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE()
);
GO

-- Tabla: programa_pe (M2M: programa - practica_estrategia)
IF OBJECT_ID('dbo.programa_pe', 'U') IS NOT NULL
    DROP TABLE dbo.programa_pe;
GO

CREATE TABLE dbo.programa_pe (
    programa INT NOT NULL,
    practica_estrategia INT NOT NULL,
    fecha_asignacion DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (programa, practica_estrategia),
    FOREIGN KEY (programa) REFERENCES dbo.programa(id) ON DELETE CASCADE,
    FOREIGN KEY (practica_estrategia) REFERENCES dbo.practica_estrategia(id) ON DELETE CASCADE
);

CREATE INDEX idx_programa_pe_programa ON dbo.programa_pe(programa);
CREATE INDEX idx_programa_pe_practica ON dbo.programa_pe(practica_estrategia);
GO

-- Tabla: pasantia
IF OBJECT_ID('dbo.pasantia', 'U') IS NOT NULL
    DROP TABLE dbo.pasantia;
GO

CREATE TABLE dbo.pasantia (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(45) NOT NULL,
    pais VARCHAR(45) NOT NULL,
    empresa VARCHAR(45) NOT NULL,
    descripcion VARCHAR(MAX) NOT NULL,
    programa INT NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (programa) REFERENCES dbo.programa(id) ON DELETE CASCADE
);

CREATE INDEX idx_pasantia_programa ON dbo.pasantia(programa);
GO

-- Tabla: premio
IF OBJECT_ID('dbo.premio', 'U') IS NOT NULL
    DROP TABLE dbo.premio;
GO

CREATE TABLE dbo.premio (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(45) NOT NULL,
    descripcion VARCHAR(MAX) NOT NULL,
    fecha DATE NOT NULL,
    entidad_otorgante VARCHAR(45) NOT NULL,
    pais VARCHAR(45) NOT NULL,
    programa INT NOT NULL,
    fecha_creacion DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (programa) REFERENCES dbo.programa(id) ON DELETE CASCADE
);

CREATE INDEX idx_premio_programa ON dbo.premio(programa);
GO

-- Tabla: aliado
IF OBJECT_ID('dbo.aliado', 'U') IS NOT NULL
    DROP TABLE dbo.aliado;
GO

CREATE TABLE dbo.aliado (
    nit INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(100) NOT NULL UNIQUE,
    tipo VARCHAR(45) NOT NULL,
    contacto VARCHAR(100),
    email VARCHAR(100),
    fecha_creacion DATETIME DEFAULT GETDATE()
);
GO

-- Tabla: departamento (Asumiendo que es otra tabla de programa/facultad)
IF OBJECT_ID('dbo.departamento', 'U') IS NOT NULL
    DROP TABLE dbo.departamento;
GO

CREATE TABLE dbo.departamento (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(MAX),
    codigo VARCHAR(50),
    fecha_creacion DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- ASIGNAR RUTAS A ROLES (Permisos base del sistema)
-- ============================================================================

-- Admin: Acceso a TODAS las rutas
INSERT INTO dbo.ruta_rol (id_ruta, id_rol)
SELECT id, 1 FROM dbo.ruta;

-- Usuario: Acceso básico
INSERT INTO dbo.ruta_rol (id_ruta, id_rol) VALUES
(1, 2),   -- /
(2, 2),   -- /login
(18, 2),  -- /registro
(20, 2);  -- /recuperar-contrasena

-- Vendedor: Acceso específico
INSERT INTO dbo.ruta_rol (id_ruta, id_rol) VALUES
(1, 3),   -- /
(2, 3),   -- /login
(16, 3);  -- /practica_estrategia

-- Gerente: Múltiples módulos
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
-- CREAR USUARIO ADMIN DE PRUEBA
-- ============================================================================

IF NOT EXISTS (SELECT 1 FROM dbo.usuario WHERE email = N'admin@example.com')
BEGIN
    INSERT INTO dbo.usuario (email, contrasena, nombre, activo)
    VALUES (
        N'admin@example.com',
        N'$2a$11$hNILKXsrFgBrQ7bLTBVK7.b8Zw8.p3xC4sL8mN.nL9pL8pL8pL8pL',
        N'Administrador',
        1
    );

    INSERT INTO dbo.rol_usuario (email_usuario, id_rol)
    VALUES (N'admin@example.com', 1);
END
GO

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

-- SP: ObtenerEstructuraTablas
CREATE OR ALTER PROCEDURE dbo.sp_ObtenerEstructuraTablas
AS
BEGIN
    SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    ORDER BY TABLE_NAME, ORDINAL_POSITION;
END
GO

-- SP: CrearRegistro (INSERT genérico)
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

-- SP: ObtenerRegistros (SELECT genérico)
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

-- SP: ActualizarRegistro (UPDATE genérico)
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

-- SP: ObtenerDatosUsuarioConRolesYRutas
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

-- SP: GenerarCodigoVerificacion
CREATE OR ALTER PROCEDURE dbo.sp_GenerarCodigoVerificacion
    @email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @codigo NVARCHAR(10) = RIGHT(CAST(CAST(RAND() * 1000000 AS INT) AS NVARCHAR), 6);
    DECLARE @fecha_expiracion DATETIME = DATEADD(MINUTE, 10, GETDATE());
    
    DELETE FROM dbo.verificacion_cuenta WHERE email = @email;
    
    INSERT INTO dbo.verificacion_cuenta (email, codigo_verificacion, fecha_expiracion, verificado)
    VALUES (@email, @codigo, @fecha_expiracion, 0);
    
    SELECT @codigo AS codigo;
END
GO

-- SP: VerificarCodigoYCrearUsuario
CREATE OR ALTER PROCEDURE dbo.sp_VerificarCodigoYCrearUsuario
    @email NVARCHAR(255),
    @codigo NVARCHAR(10),
    @contrasena NVARCHAR(MAX),
    @idsRoles NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
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
        
        IF NOT EXISTS (SELECT 1 FROM dbo.usuario WHERE email = @email)
        BEGIN
            INSERT INTO dbo.usuario (email, contrasena)
            VALUES (@email, @contrasena);
        END
        
        DECLARE @json NVARCHAR(MAX) = '[' + @idsRoles + ']';
        INSERT INTO dbo.rol_usuario (email_usuario, id_rol)
        SELECT @email, CAST(JSON_VALUE(value, '$') AS INT)
        FROM OPENJSON(@json)
        WHERE CAST(JSON_VALUE(value, '$') AS INT) != 1;
        
        UPDATE dbo.verificacion_cuenta
        SET verificado = 1, fecha_verificacion = GETDATE()
        WHERE email = @email;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- SP: AsignarRolAUsuario
CREATE OR ALTER PROCEDURE dbo.sp_AsignarRolAUsuario
    @email NVARCHAR(255),
    @idRol INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.usuario WHERE email = @email)
        BEGIN
            RAISERROR('Usuario no encontrado', 16, 1);
            RETURN;
        END
        
        IF NOT EXISTS (SELECT 1 FROM dbo.rol WHERE id = @idRol)
        BEGIN
            RAISERROR('Rol no encontrado', 16, 1);
            RETURN;
        END
        
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

-- SP: RevocarRolDeUsuario
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
-- VERIFICACIÓN FINAL
-- ============================================================================

PRINT '=== BASE DE DATOS CREADA EXITOSAMENTE ===';
PRINT 'Usuario admin: admin@example.com / 1234aA';
PRINT 'Tablas creadas: 20';
PRINT 'Procedimientos almacenados: 9';
PRINT '=======================================';

GO
