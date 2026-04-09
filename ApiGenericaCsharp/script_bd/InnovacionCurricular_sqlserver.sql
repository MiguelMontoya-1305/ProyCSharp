-- ============================================================
-- Script de creación de base de datos: InnovacionCurricular_sqlserver
-- Compatible con SQL Server 2016+
-- Incluye: tablas de Innovación Curricular y procedimientos maestro-detalle
-- ============================================================

USE knowledge_map_db;
GO

-- ============================================================
-- LIMPIEZA: eliminar objetos existentes
-- ============================================================

IF OBJECT_ID('sp_borrar_programa_y_actividades', 'P') IS NOT NULL DROP PROCEDURE sp_borrar_programa_y_actividades;
IF OBJECT_ID('sp_actualizar_programa_y_actividades', 'P') IS NOT NULL DROP PROCEDURE sp_actualizar_programa_y_actividades;
IF OBJECT_ID('sp_listar_programas_y_actividades', 'P') IS NOT NULL DROP PROCEDURE sp_listar_programas_y_actividades;
IF OBJECT_ID('sp_consultar_programa_y_actividades', 'P') IS NOT NULL DROP PROCEDURE sp_consultar_programa_y_actividades;
IF OBJECT_ID('sp_insertar_programa_y_actividades', 'P') IS NOT NULL DROP PROCEDURE sp_insertar_programa_y_actividades;

IF OBJECT_ID('aa_rc', 'U') IS NOT NULL DROP TABLE aa_rc;
IF OBJECT_ID('programa_ac', 'U') IS NOT NULL DROP TABLE programa_ac;
IF OBJECT_ID('programa_ci', 'U') IS NOT NULL DROP TABLE programa_ci;
IF OBJECT_ID('enfoque_rc', 'U') IS NOT NULL DROP TABLE enfoque_rc;
IF OBJECT_ID('programa_pe', 'U') IS NOT NULL DROP TABLE programa_pe;
IF OBJECT_ID('an_programa', 'U') IS NOT NULL DROP TABLE an_programa;
IF OBJECT_ID('alianza', 'U') IS NOT NULL DROP TABLE alianza;
IF OBJECT_ID('docente_departamento', 'U') IS NOT NULL DROP TABLE docente_departamento;
IF OBJECT_ID('pasantia', 'U') IS NOT NULL DROP TABLE pasantia;
IF OBJECT_ID('premio', 'U') IS NOT NULL DROP TABLE premio;
IF OBJECT_ID('registro_calificado', 'U') IS NOT NULL DROP TABLE registro_calificado;
IF OBJECT_ID('acreditacion', 'U') IS NOT NULL DROP TABLE acreditacion;
IF OBJECT_ID('activ_academica', 'U') IS NOT NULL DROP TABLE activ_academica;
IF OBJECT_ID('programa', 'U') IS NOT NULL DROP TABLE programa;
IF OBJECT_ID('departamento', 'U') IS NOT NULL DROP TABLE departamento;
IF OBJECT_ID('facultad', 'U') IS NOT NULL DROP TABLE facultad;
IF OBJECT_ID('universidad', 'U') IS NOT NULL DROP TABLE universidad;
IF OBJECT_ID('practica_estrategia', 'U') IS NOT NULL DROP TABLE practica_estrategia;
IF OBJECT_ID('enfoque', 'U') IS NOT NULL DROP TABLE enfoque;
IF OBJECT_ID('car_innovacion', 'U') IS NOT NULL DROP TABLE car_innovacion;
IF OBJECT_ID('aspecto_normativo', 'U') IS NOT NULL DROP TABLE aspecto_normativo;
GO

-- ============================================================
-- TABLAS INDEPENDIENTES DEL MODULO INNOVACION CURRICULAR
-- ============================================================

CREATE TABLE aspecto_normativo (
    id INT IDENTITY(1,1) NOT NULL,
    tipo NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(500) NOT NULL,
    fuente NVARCHAR(200) NOT NULL,
    CONSTRAINT pk_aspecto_normativo PRIMARY KEY (id)
);

CREATE TABLE car_innovacion (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    descripcion NVARCHAR(500) NOT NULL,
    tipo NVARCHAR(100) NOT NULL,
    CONSTRAINT pk_car_innovacion PRIMARY KEY (id)
);

CREATE TABLE enfoque (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    descripcion NVARCHAR(500) NOT NULL,
    CONSTRAINT pk_enfoque PRIMARY KEY (id)
);

CREATE TABLE practica_estrategia (
    id INT IDENTITY(1,1) NOT NULL,
    tipo NVARCHAR(100) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    descripcion NVARCHAR(500) NOT NULL,
    CONSTRAINT pk_practica_estrategia PRIMARY KEY (id)
);

CREATE TABLE universidad (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    tipo NVARCHAR(100) NOT NULL,
    ciudad NVARCHAR(100) NOT NULL,
    CONSTRAINT pk_universidad PRIMARY KEY (id)
);

-- Tabla de facultades, cada una vinculada a una universidad
CREATE TABLE facultad (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    tipo NVARCHAR(100) NOT NULL,
    fecha_fun DATE NOT NULL,
    universidad INT NOT NULL,
    CONSTRAINT pk_facultad PRIMARY KEY (id),
    CONSTRAINT fk_facultad_universidad FOREIGN KEY (universidad) REFERENCES universidad(id)
);

-- Tabla de departamentos, asociados a una facultad
CREATE TABLE departamento (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    facultad INT NOT NULL,
    CONSTRAINT pk_departamento PRIMARY KEY (id),
    CONSTRAINT fk_departamento_facultad FOREIGN KEY (facultad) REFERENCES facultad(id)
);

-- Tabla de programas académicos, con datos generales y relación a facultad
CREATE TABLE programa (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(250) NOT NULL,
    tipo NVARCHAR(100) NOT NULL,
    nivel NVARCHAR(100) NOT NULL,
    fecha_creacion DATE NOT NULL,
    fecha_cierre DATE NULL,
    numero_cohortes INT NOT NULL DEFAULT 0,
    cant_graduados INT NOT NULL DEFAULT 0,
    fecha_actualizacion DATE NULL,
    ciudad NVARCHAR(100) NOT NULL,
    facultad INT NOT NULL,
    CONSTRAINT pk_programa PRIMARY KEY (id),
    CONSTRAINT fk_programa_facultad FOREIGN KEY (facultad) REFERENCES facultad(id)
);

-- Tabla de acreditaciones asociadas a cada programa
CREATE TABLE acreditacion (
    resolucion NVARCHAR(50) NOT NULL,
    tipo NVARCHAR(100) NOT NULL,
    calificacion NVARCHAR(100) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    programa INT NOT NULL,
    CONSTRAINT pk_acreditacion PRIMARY KEY (resolucion),
    CONSTRAINT fk_acreditacion_programa FOREIGN KEY (programa) REFERENCES programa(id)
);

-- Tabla de registros calificados que documentan el estado académico de un programa
CREATE TABLE registro_calificado (
    codigo NVARCHAR(50) NOT NULL,
    cant_creditos INT NOT NULL,
    hora_acom INT NOT NULL,
    hora_ind INT NOT NULL,
    metodologia NVARCHAR(200) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    duracion_anios INT NOT NULL,
    duracion_semestres INT NOT NULL,
    tipo_titulacion NVARCHAR(100) NOT NULL,
    programa INT NOT NULL,
    CONSTRAINT pk_registro_calificado PRIMARY KEY (codigo),
    CONSTRAINT fk_registro_calificado_programa FOREIGN KEY (programa) REFERENCES programa(id)
);

-- Tabla intermedia para el enfoque de un registro calificado
CREATE TABLE enfoque_rc (
    enfoque INT NOT NULL,
    registro_calificado_codigo NVARCHAR(50) NOT NULL,
    CONSTRAINT pk_enfoque_rc PRIMARY KEY (enfoque, registro_calificado_codigo),
    CONSTRAINT fk_enfoque_rc_enfoque FOREIGN KEY (enfoque) REFERENCES enfoque(id),
    CONSTRAINT fk_enfoque_rc_registro FOREIGN KEY (registro_calificado_codigo) REFERENCES registro_calificado(codigo)
);

-- Tabla de actividades académicas que forman parte del diseño curricular de un programa
CREATE TABLE activ_academica (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(250) NOT NULL,
    num_creditos INT NOT NULL,
    tipo NVARCHAR(100) NOT NULL,
    area_formacion NVARCHAR(150) NOT NULL,
    h_acom INT NOT NULL,
    h_indep INT NOT NULL,
    idioma NVARCHAR(100) NOT NULL,
    espejo BIT NOT NULL DEFAULT 0,
    entidad_espejo NVARCHAR(200) NULL,
    pais_espejo NVARCHAR(100) NULL,
    disenio INT NOT NULL,
    CONSTRAINT pk_activ_academica PRIMARY KEY (id),
    CONSTRAINT fk_activ_academica_programa FOREIGN KEY (disenio) REFERENCES programa(id) ON DELETE CASCADE
);

CREATE TABLE pasantia (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    pais NVARCHAR(100) NOT NULL,
    empresa NVARCHAR(200) NOT NULL,
    descripcion NVARCHAR(500) NOT NULL,
    programa INT NOT NULL,
    CONSTRAINT pk_pasantia PRIMARY KEY (id),
    CONSTRAINT fk_pasantia_programa FOREIGN KEY (programa) REFERENCES programa(id)
);

CREATE TABLE premio (
    id INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    descripcion NVARCHAR(500) NOT NULL,
    fecha DATE NOT NULL,
    entidad_otorgante NVARCHAR(200) NOT NULL,
    pais NVARCHAR(100) NOT NULL,
    programa INT NOT NULL,
    CONSTRAINT pk_premio PRIMARY KEY (id),
    CONSTRAINT fk_premio_programa FOREIGN KEY (programa) REFERENCES programa(id)
);

CREATE TABLE an_programa (
    aspecto_normativo INT NOT NULL,
    programa INT NOT NULL,
    CONSTRAINT pk_an_programa PRIMARY KEY (aspecto_normativo, programa),
    CONSTRAINT fk_an_programa_aspecto FOREIGN KEY (aspecto_normativo) REFERENCES aspecto_normativo(id),
    CONSTRAINT fk_an_programa_programa FOREIGN KEY (programa) REFERENCES programa(id)
);

CREATE TABLE programa_ac (
    programa INT NOT NULL,
    area_conocimiento INT NOT NULL,
    CONSTRAINT pk_programa_ac PRIMARY KEY (programa, area_conocimiento),
    CONSTRAINT fk_programa_ac_programa FOREIGN KEY (programa) REFERENCES programa(id),
    CONSTRAINT fk_programa_ac_area FOREIGN KEY (area_conocimiento) REFERENCES area_conocimiento(id)
);

CREATE TABLE programa_ci (
    programa INT NOT NULL,
    car_innovacion INT NOT NULL,
    CONSTRAINT pk_programa_ci PRIMARY KEY (programa, car_innovacion),
    CONSTRAINT fk_programa_ci_programa FOREIGN KEY (programa) REFERENCES programa(id),
    CONSTRAINT fk_programa_ci_car_innovacion FOREIGN KEY (car_innovacion) REFERENCES car_innovacion(id)
);

CREATE TABLE programa_pe (
    programa INT NOT NULL,
    practica_estrategia INT NOT NULL,
    CONSTRAINT pk_programa_pe PRIMARY KEY (programa, practica_estrategia),
    CONSTRAINT fk_programa_pe_programa FOREIGN KEY (programa) REFERENCES programa(id),
    CONSTRAINT fk_programa_pe_practica FOREIGN KEY (practica_estrategia) REFERENCES practica_estrategia(id)
);

CREATE TABLE aa_rc (
    activ_academicas_idcurso INT NOT NULL,
    registro_calificado_codigo NVARCHAR(50) NOT NULL,
    componente NVARCHAR(200) NOT NULL,
    semestre INT NOT NULL,
    CONSTRAINT pk_aa_rc PRIMARY KEY (activ_academicas_idcurso, registro_calificado_codigo),
    CONSTRAINT fk_aa_rc_activ_academica FOREIGN KEY (activ_academicas_idcurso) REFERENCES activ_academica(id) ON DELETE CASCADE,
    CONSTRAINT fk_aa_rc_registro FOREIGN KEY (registro_calificado_codigo) REFERENCES registro_calificado(codigo) ON DELETE CASCADE
);

CREATE TABLE docente_departamento (
    docente NVARCHAR(50) NOT NULL,
    departamento INT NOT NULL,
    dedicacion NVARCHAR(100) NOT NULL,
    modalidad NVARCHAR(100) NOT NULL,
    fecha_ingreso DATE NOT NULL,
    fecha_salida DATE NULL,
    CONSTRAINT pk_docente_departamento PRIMARY KEY (docente, departamento),
    CONSTRAINT fk_docente_departamento_docente FOREIGN KEY (docente) REFERENCES docente(cedula),
    CONSTRAINT fk_docente_departamento_departamento FOREIGN KEY (departamento) REFERENCES departamento(id)
);

CREATE TABLE alianza (
    aliado NVARCHAR(50) NOT NULL,
    departamento INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    docente NVARCHAR(50) NOT NULL,
    CONSTRAINT pk_alianza PRIMARY KEY (aliado, departamento, docente),
    CONSTRAINT fk_alianza_aliado FOREIGN KEY (aliado) REFERENCES aliado(nit),
    CONSTRAINT fk_alianza_departamento FOREIGN KEY (departamento) REFERENCES departamento(id),
    CONSTRAINT fk_alianza_docente FOREIGN KEY (docente) REFERENCES docente(cedula)
);

-- ============================================================
-- DATOS DE EJEMPLO
-- ============================================================

INSERT INTO universidad (nombre, tipo, ciudad)
VALUES
    (N'Universidad Central', N'Pública', N'Bogotá'),
    (N'Universidad Metropolitana', N'Privada', N'Medellín');

INSERT INTO facultad (nombre, tipo, fecha_fun, universidad)
VALUES
    (N'Facultad de Ingeniería', N'Tecnológica', '2001-03-15', 1),
    (N'Facultad de Ciencias Sociales', N'Académica', '1998-07-01', 2);

INSERT INTO departamento (nombre, facultad)
VALUES
    (N'Departamento de Ingeniería de Sistemas', 1),
    (N'Departamento de Ciencias Sociales', 2);

INSERT INTO aspecto_normativo (tipo, descripcion, fuente)
VALUES
    (N'Estatuto', N'Regula los requisitos de los programas académicos', N'MinEducación'),
    (N'Norma interna', N'Documento de actualización curricular', N'Vedado institucional');

INSERT INTO car_innovacion (nombre, descripcion, tipo)
VALUES
    (N'Aprendizaje Basado en Proyectos', N'Trabajo colaborativo con enfoque por proyectos', N'Pedagógica'),
    (N'Currículo Flexible', N'Programas con rutas de formación personalizadas', N'Curricular');

INSERT INTO enfoque (nombre, descripcion)
VALUES
    (N'Aprendizaje activo', N'Modelo centrado en el estudiante y la práctica'),
    (N'Competencias', N'Currículo orientado a resultados de aprendizaje');

INSERT INTO practica_estrategia (tipo, nombre, descripcion)
VALUES
    (N'Pedagógica', N'Aprendizaje Basado en Problemas', N'Actividades orientadas a la resolución de retos reales'),
    (N'Pedagógica', N'Gamificación', N'Uso de dinámicas lúdicas para el aprendizaje');

INSERT INTO programa (nombre, tipo, nivel, fecha_creacion, fecha_cierre, numero_cohortes, cant_graduados, fecha_actualizacion, ciudad, facultad)
VALUES
    (N'Ingeniería de Sistemas', N'Técnico', N'Pregrado', '2015-02-01', NULL, 12, 450, '2024-08-05', N'Bogotá', 1),
    (N'Comunicación Social', N'Académico', N'Pregrado', '2012-09-15', NULL, 10, 380, '2024-09-01', N'Medellín', 2);

INSERT INTO activ_academica (nombre, num_creditos, tipo, area_formacion, h_acom, h_indep, idioma, espejo, entidad_espejo, pais_espejo, disenio)
VALUES
    (N'Matemáticas Discretas', 3, N'Obligatoria', N'Ciencias Básicas', 48, 96, N'Español', 0, NULL, NULL, 1),
    (N'Algoritmos y Estructuras', 4, N'Obligatoria', N'Ingeniería', 64, 96, N'Español', 0, NULL, NULL, 1),
    (N'Comunicación Escrita', 2, N'Obligatoria', N'Formación Humanística', 32, 64, N'Español', 0, NULL, NULL, 2);

INSERT INTO acreditacion (resolucion, tipo, calificacion, fecha_inicio, fecha_fin, programa)
VALUES
    (N'ACR-2024-001', N'Nacional', N'Alta', '2024-01-01', '2029-01-01', 1);

INSERT INTO registro_calificado (codigo, cant_creditos, hora_acom, hora_ind, metodologia, fecha_inicio, fecha_fin, duracion_anios, duracion_semestres, tipo_titulacion, programa)
VALUES
    (N'RC-2024-01', 160, 40, 80, N'Presencial', '2024-01-10', '2024-12-20', 4, 8, N'Título Profesional', 1);

INSERT INTO enfoque_rc (enfoque, registro_calificado_codigo)
VALUES
    (1, N'RC-2024-01');

INSERT INTO aa_rc (activ_academicas_idcurso, registro_calificado_codigo, componente, semestre)
VALUES
    (1, N'RC-2024-01', N'Fundamentos', 1),
    (2, N'RC-2024-01', N'Disminución', 2);

INSERT INTO pasantia (nombre, pais, empresa, descripcion, programa)
VALUES
    (N'Pasantía en Desarrollo de Software', N'Colombia', N'Empresa Tech', N'Práctica profesional en desarrollo de aplicaciones', 1);

INSERT INTO premio (nombre, descripcion, fecha, entidad_otorgante, pais, programa)
VALUES
    (N'Premio a la Innovación Educativa', N'Reconocimiento por buenas prácticas pedagógicas', '2023-11-30', N'Agencia Nacional', N'Colombia', 1);

INSERT INTO an_programa (aspecto_normativo, programa)
VALUES
    (1, 1);

INSERT INTO programa_ac (programa, area_conocimiento)
VALUES
    (1, 1);

INSERT INTO programa_ci (programa, car_innovacion)
VALUES
    (1, 1);

INSERT INTO programa_pe (programa, practica_estrategia)
VALUES
    (1, 1);

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS PARA MAESTRO-DETALLE
-- ============================================================
-- sp_listar_programas_y_actividades: devuelve todos los programas con sus actividades
-- sp_consultar_programa_y_actividades: obtiene un programa y sus actividades por id
-- sp_insertar_programa_y_actividades: inserta programa y sus actividades en transacción
-- sp_actualizar_programa_y_actividades: actualiza programa y vuelve a insertar actividades
-- sp_borrar_programa_y_actividades: elimina un programa y devuelve el resumen

CREATE PROCEDURE sp_listar_programas_y_actividades
    @p_resultado NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Construye un arreglo JSON con todos los programas y sus actividades
    SET NOCOUNT ON;

    DECLARE @v_result NVARCHAR(MAX) = N'[';
    DECLARE @v_first BIT = 1;
    DECLARE @v_id INT;
    DECLARE @v_programa_json NVARCHAR(MAX);
    DECLARE @v_actividades_json NVARCHAR(MAX);

    DECLARE programa_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT id FROM programa ORDER BY id;

    OPEN programa_cursor;
    FETCH NEXT FROM programa_cursor INTO @v_id;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @v_first = 0
            SET @v_result = @v_result + N',';

        SET @v_first = 0;

        SELECT @v_programa_json = (
            SELECT p.id, p.nombre, p.tipo, p.nivel, p.fecha_creacion, p.fecha_cierre,
                   p.numero_cohortes, p.cant_graduados, p.fecha_actualizacion, p.ciudad,
                   p.facultad, f.nombre AS nombre_facultad
            FROM programa p
            JOIN facultad f ON f.id = p.facultad
            WHERE p.id = @v_id
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        SELECT @v_actividades_json = (
            SELECT a.id, a.nombre, a.num_creditos, a.tipo, a.area_formacion,
                   a.h_acom, a.h_indep, a.idioma, a.espejo, a.entidad_espejo,
                   a.pais_espejo
            FROM activ_academica a
            WHERE a.disenio = @v_id
            ORDER BY a.id
            FOR JSON PATH
        );

        SET @v_result = @v_result + N'{"programa":' + ISNULL(@v_programa_json, N'{}') + N',"actividades":' + ISNULL(@v_actividades_json, N'[]') + N'}';

        FETCH NEXT FROM programa_cursor INTO @v_id;
    END;

    CLOSE programa_cursor;
    DEALLOCATE programa_cursor;

    SET @v_result = @v_result + N']';
    SET @p_resultado = @v_result;
END;
GO

CREATE PROCEDURE sp_consultar_programa_y_actividades
    @p_id INT,
    @p_resultado NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM programa WHERE id = @p_id)
    BEGIN
        THROW 50010, N'Programa no existe.', 1;
    END

    DECLARE @v_programa_json NVARCHAR(MAX);
    DECLARE @v_actividades_json NVARCHAR(MAX);

    SELECT @v_programa_json = (
        SELECT p.id, p.nombre, p.tipo, p.nivel, p.fecha_creacion, p.fecha_cierre,
               p.numero_cohortes, p.cant_graduados, p.fecha_actualizacion, p.ciudad,
               p.facultad, f.nombre AS nombre_facultad
        FROM programa p
        JOIN facultad f ON f.id = p.facultad
        WHERE p.id = @p_id
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    SELECT @v_actividades_json = (
        SELECT a.id, a.nombre, a.num_creditos, a.tipo, a.area_formacion,
               a.h_acom, a.h_indep, a.idioma, a.espejo, a.entidad_espejo,
               a.pais_espejo
        FROM activ_academica a
        WHERE a.disenio = @p_id
        ORDER BY a.id
        FOR JSON PATH
    );

    SET @p_resultado = N'{"programa":' + ISNULL(@v_programa_json, N'{}') + N',"actividades":' + ISNULL(@v_actividades_json, N'[]') + N'}';
END;
GO

CREATE PROCEDURE sp_insertar_programa_y_actividades
    @p_nombre NVARCHAR(250),
    @p_tipo NVARCHAR(100),
    @p_nivel NVARCHAR(100),
    @p_fecha_creacion DATE,
    @p_fecha_cierre DATE = NULL,
    @p_numero_cohortes INT = 0,
    @p_cant_graduados INT = 0,
    @p_fecha_actualizacion DATE = NULL,
    @p_ciudad NVARCHAR(100),
    @p_facultad INT,
    @p_actividades NVARCHAR(MAX),
    @p_resultado NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO programa (nombre, tipo, nivel, fecha_creacion, fecha_cierre, numero_cohortes, cant_graduados, fecha_actualizacion, ciudad, facultad)
        VALUES (@p_nombre, @p_tipo, @p_nivel, @p_fecha_creacion, @p_fecha_cierre, @p_numero_cohortes, @p_cant_graduados, @p_fecha_actualizacion, @p_ciudad, @p_facultad);

        DECLARE @v_id INT = SCOPE_IDENTITY();
        DECLARE @v_nombre NVARCHAR(250);
        DECLARE @v_num_creditos INT;
        DECLARE @v_tipo NVARCHAR(100);
        DECLARE @v_area_formacion NVARCHAR(150);
        DECLARE @v_h_acom INT;
        DECLARE @v_h_indep INT;
        DECLARE @v_idioma NVARCHAR(100);
        DECLARE @v_espejo BIT;
        DECLARE @v_entidad_espejo NVARCHAR(200);
        DECLARE @v_pais_espejo NVARCHAR(100);

        DECLARE actividad_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT
                JSON_VALUE(value, '$.nombre'),
                CAST(JSON_VALUE(value, '$.num_creditos') AS INT),
                JSON_VALUE(value, '$.tipo'),
                JSON_VALUE(value, '$.area_formacion'),
                CAST(JSON_VALUE(value, '$.h_acom') AS INT),
                CAST(JSON_VALUE(value, '$.h_indep') AS INT),
                JSON_VALUE(value, '$.idioma'),
                CAST(JSON_VALUE(value, '$.espejo') AS BIT),
                JSON_VALUE(value, '$.entidad_espejo'),
                JSON_VALUE(value, '$.pais_espejo')
            FROM OPENJSON(@p_actividades);

        OPEN actividad_cursor;
        FETCH NEXT FROM actividad_cursor INTO @v_nombre, @v_num_creditos, @v_tipo, @v_area_formacion, @v_h_acom, @v_h_indep, @v_idioma, @v_espejo, @v_entidad_espejo, @v_pais_espejo;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO activ_academica (nombre, num_creditos, tipo, area_formacion, h_acom, h_indep, idioma, espejo, entidad_espejo, pais_espejo, disenio)
            VALUES (@v_nombre, @v_num_creditos, @v_tipo, @v_area_formacion, @v_h_acom, @v_h_indep, @v_idioma, @v_espejo, @v_entidad_espejo, @v_pais_espejo, @v_id);

            FETCH NEXT FROM actividad_cursor INTO @v_nombre, @v_num_creditos, @v_tipo, @v_area_formacion, @v_h_acom, @v_h_indep, @v_idioma, @v_espejo, @v_entidad_espejo, @v_pais_espejo;
        END;

        CLOSE actividad_cursor;
        DEALLOCATE actividad_cursor;

        DECLARE @v_programa_json NVARCHAR(MAX) = (
            SELECT p.id, p.nombre, p.tipo, p.nivel, p.fecha_creacion, p.fecha_cierre,
                   p.numero_cohortes, p.cant_graduados, p.fecha_actualizacion, p.ciudad,
                   p.facultad, f.nombre AS nombre_facultad
            FROM programa p
            JOIN facultad f ON f.id = p.facultad
            WHERE p.id = @v_id
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        DECLARE @v_actividades_json NVARCHAR(MAX) = (
            SELECT a.id, a.nombre, a.num_creditos, a.tipo, a.area_formacion,
                   a.h_acom, a.h_indep, a.idioma, a.espejo, a.entidad_espejo,
                   a.pais_espejo
            FROM activ_academica a
            WHERE a.disenio = @v_id
            ORDER BY a.id
            FOR JSON PATH
        );

        SET @p_resultado = N'{"programa":' + ISNULL(@v_programa_json, N'{}') + N',"actividades":' + ISNULL(@v_actividades_json, N'[]') + N'}';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE sp_actualizar_programa_y_actividades
    @p_id INT,
    @p_nombre NVARCHAR(250),
    @p_tipo NVARCHAR(100),
    @p_nivel NVARCHAR(100),
    @p_fecha_creacion DATE,
    @p_fecha_cierre DATE = NULL,
    @p_numero_cohortes INT = 0,
    @p_cant_graduados INT = 0,
    @p_fecha_actualizacion DATE = NULL,
    @p_ciudad NVARCHAR(100),
    @p_facultad INT,
    @p_actividades NVARCHAR(MAX),
    @p_resultado NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM programa WHERE id = @p_id)
    BEGIN
        THROW 50011, N'Programa no existe para actualizar.', 1;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE programa
        SET nombre = @p_nombre,
            tipo = @p_tipo,
            nivel = @p_nivel,
            fecha_creacion = @p_fecha_creacion,
            fecha_cierre = @p_fecha_cierre,
            numero_cohortes = @p_numero_cohortes,
            cant_graduados = @p_cant_graduados,
            fecha_actualizacion = @p_fecha_actualizacion,
            ciudad = @p_ciudad,
            facultad = @p_facultad
        WHERE id = @p_id;

        DELETE FROM activ_academica WHERE disenio = @p_id;

        DECLARE @v_nombre NVARCHAR(250);
        DECLARE @v_num_creditos INT;
        DECLARE @v_tipo NVARCHAR(100);
        DECLARE @v_area_formacion NVARCHAR(150);
        DECLARE @v_h_acom INT;
        DECLARE @v_h_indep INT;
        DECLARE @v_idioma NVARCHAR(100);
        DECLARE @v_espejo BIT;
        DECLARE @v_entidad_espejo NVARCHAR(200);
        DECLARE @v_pais_espejo NVARCHAR(100);

        DECLARE actividad_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT
                JSON_VALUE(value, '$.nombre'),
                CAST(JSON_VALUE(value, '$.num_creditos') AS INT),
                JSON_VALUE(value, '$.tipo'),
                JSON_VALUE(value, '$.area_formacion'),
                CAST(JSON_VALUE(value, '$.h_acom') AS INT),
                CAST(JSON_VALUE(value, '$.h_indep') AS INT),
                JSON_VALUE(value, '$.idioma'),
                CAST(JSON_VALUE(value, '$.espejo') AS BIT),
                JSON_VALUE(value, '$.entidad_espejo'),
                JSON_VALUE(value, '$.pais_espejo')
            FROM OPENJSON(@p_actividades);

        OPEN actividad_cursor;
        FETCH NEXT FROM actividad_cursor INTO @v_nombre, @v_num_creditos, @v_tipo, @v_area_formacion, @v_h_acom, @v_h_indep, @v_idioma, @v_espejo, @v_entidad_espejo, @v_pais_espejo;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO activ_academica (nombre, num_creditos, tipo, area_formacion, h_acom, h_indep, idioma, espejo, entidad_espejo, pais_espejo, disenio)
            VALUES (@v_nombre, @v_num_creditos, @v_tipo, @v_area_formacion, @v_h_acom, @v_h_indep, @v_idioma, @v_espejo, @v_entidad_espejo, @v_pais_espejo, @p_id);

            FETCH NEXT FROM actividad_cursor INTO @v_nombre, @v_num_creditos, @v_tipo, @v_area_formacion, @v_h_acom, @v_h_indep, @v_idioma, @v_espejo, @v_entidad_espejo, @v_pais_espejo;
        END;

        CLOSE actividad_cursor;
        DEALLOCATE actividad_cursor;

        DECLARE @v_programa_json NVARCHAR(MAX) = (
            SELECT p.id, p.nombre, p.tipo, p.nivel, p.fecha_creacion, p.fecha_cierre,
                   p.numero_cohortes, p.cant_graduados, p.fecha_actualizacion, p.ciudad,
                   p.facultad, f.nombre AS nombre_facultad
            FROM programa p
            JOIN facultad f ON f.id = p.facultad
            WHERE p.id = @p_id
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        DECLARE @v_actividades_json NVARCHAR(MAX) = (
            SELECT a.id, a.nombre, a.num_creditos, a.tipo, a.area_formacion,
                   a.h_acom, a.h_indep, a.idioma, a.espejo, a.entidad_espejo,
                   a.pais_espejo
            FROM activ_academica a
            WHERE a.disenio = @p_id
            ORDER BY a.id
            FOR JSON PATH
        );

        SET @p_resultado = N'{"programa":' + ISNULL(@v_programa_json, N'{}') + N',"actividades":' + ISNULL(@v_actividades_json, N'[]') + N'}';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE sp_borrar_programa_y_actividades
    @p_id INT,
    @p_resultado NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM programa WHERE id = @p_id)
    BEGIN
        THROW 50012, N'Programa no existe para eliminar.', 1;
    END

    DECLARE @v_nombre NVARCHAR(250);
    DECLARE @v_cantidad_actividades INT;

    SELECT @v_nombre = nombre FROM programa WHERE id = @p_id;
    SELECT @v_cantidad_actividades = COUNT(*) FROM activ_academica WHERE disenio = @p_id;

    DELETE FROM programa WHERE id = @p_id;

    SET @p_resultado = N'{"mensaje":"Programa eliminado exitosamente.","id_eliminado":' + CAST(@p_id AS NVARCHAR) + N',"nombre_eliminado":"' + @v_nombre + N'","actividades_eliminadas":' + CAST(ISNULL(@v_cantidad_actividades,0) AS NVARCHAR) + N'}';
END;
GO
