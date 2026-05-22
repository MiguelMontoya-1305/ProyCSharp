# 📋 GUÍA COMPLETA DE USO - Sistema de Roles, Verificación y Rediseño

## 🎯 RESUMEN DE CAMBIOS

Se implementaron 3 mejoras principales:

1. **✅ Sistema de Roles y Rutas para Administradores**
2. **✅ Sistema de Verificación por Email para Registro**  
3. **✅ Rediseño Frontend Empresarial y Moderno**

---

## 📁 ARCHIVOS CREADOS/MODIFICADOS

### Backend (API C#)

| Archivo | Descripción |
|---------|------------|
| `script_bd/nuevas_tablas_para_verificacion.sql` | Script para crear tablas de verificación y relaciones de roles |
| `Modelos/ModelsRegistroYRoles.cs` | Modelos para registro, verificación y asignación de roles |
| `Servicios/ServicioRegistroYRoles.cs` | Servicio con lógica de registro, verificación y roles |
| `Servicios/Abstracciones/IServicioRegistroYRoles.cs` | Interfaz del servicio |
| `Controllers/RegistroYRolesController.cs` | Endpoints API para registro, verificación y admin |
| `Program.cs` | ✏️ Registrado el nuevo servicio |
| `appsettings.json` | ✏️ Agregada configuración de email |

### Frontend (Blazor)

| Archivo | Descripción |
|---------|------------|
| `Components/Pages/Registro.razor` | Nueva página de registro con verificación |
| `Components/Pages/GestionUsuarios.razor` | Panel de administración de usuarios y roles |
| `Components/Pages/Login.razor` | ✏️ Mejorado con nuevo diseño empresarial |
| `wwwroot/estilos-empresariales.css` | Estilos modernos y profesionales |
| `Components/App.razor` | ✏️ Agregados Font Awesome y CSS empresarial |

---

## 🚀 CÓMO USAR

### 1️⃣ REGISTRO DE NUEVOS USUARIOS

#### Flujo:
1. El usuario visita `/registro`
2. Ingresa email, contraseña y selecciona roles (excepto Admin)
3. Se envía un email con código de 6 dígitos
4. El usuario verifica el código
5. Cuenta activada y puede hacer login

#### Código de API:
```bash
# Paso 1: Solicitar código
POST /api/registro/solicitar-codigo
{
  "email": "juan@example.com"
}

# Respuesta:
{
  "exitoso": true,
  "mensaje": "Se envió un código de verificación a juan@example.com. Expira en 10 minutos.",
  "email": "juan@example.com"
}
```

```bash
# Paso 2: Verificar y crear cuenta
POST /api/registro/verificar
{
  "email": "juan@example.com",
  "codigoVerificacion": "123456",
  "contrasena": "MiPassword123",
  "confirmarContrasena": "MiPassword123",
  "idsRoles": [2, 3]  // Usuario y Vendedor
}

# Respuesta:
{
  "exitoso": true,
  "mensaje": "Cuenta creada exitosamente.",
  "email": "juan@example.com",
  "roles": ["Usuario", "Vendedor"],
  "rutasPermitidas": ["/dashboard", "/facturacion"],
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

---

### 2️⃣ ADMINISTRACIÓN DE ROLES

#### Panel Admin:
- URL: `/admin/usuarios`
- ⚠️ **REQUIERE**: Autenticación + Rol Admin

#### Funcionalidades:
- **Tab Usuarios**: Ver usuarios y asignarles roles
- **Tab Roles**: Ver roles disponibles y rutas asignadas
- **Tab Rutas**: Ver todas las rutas del sistema

#### Código de API:

```bash
# Asignar rol a usuario (solo admin)
POST /api/admin/asignar-rol
Authorization: Bearer {token_jwt}
{
  "email": "juan@example.com",
  "idRol": 3  // Vendedor
}

# Respuesta:
{
  "exitoso": true,
  "mensaje": "Rol asignado exitosamente."
}
```

```bash
# Revocar rol de usuario (solo admin)
DELETE /api/admin/revocar-rol
Authorization: Bearer {token_jwt}
{
  "email": "juan@example.com",
  "idRol": 3  // Vendedor
}

# Respuesta:
{
  "exitoso": true,
  "mensaje": "Rol revocado exitosamente."
}
```

```bash
# Obtener datos del usuario autenticado (roles y rutas)
GET /api/usuario/datos
Authorization: Bearer {token_jwt}

# Respuesta:
{
  "email": "juan@example.com",
  "roles": ["Usuario", "Vendedor"],
  "rutasPermitidas": ["/dashboard", "/facturacion", "/reportes"]
}
```

---

### 3️⃣ CONFIGURACIÓN DE EMAIL

Edita `appsettings.json`:

```json
{
  "Email": {
    "Servidor": "smtp.gmail.com",
    "Puerto": 587,
    "Usuario": "tu_email@gmail.com",
    "Contrasena": "tu_contrasena_app",
    "DesdeDireccion": "tu_email@gmail.com"
  }
}
```

**Para Gmail**:
1. Habilita "Contraseñas de aplicación" en tu cuenta Google
2. Copia la contraseña de aplicación en `appsettings.json`

---

### 4️⃣ ROLES Y RUTAS PREDEFINIDAS

#### Roles:
| ID | Nombre | Descripción |
|----|--------|------------|
| 1 | Admin | Acceso total (no se puede asignar al registrarse) |
| 2 | Usuario | Acceso básico |
| 3 | Vendedor | Acceso a facturación |
| 4 | Gerente | Acceso a reportes e inventario |

#### Rutas:
| ID | Ruta | Descripción | Roles |
|----|------|------------|-------|
| 1 | /dashboard | Panel principal | Admin, Gerente |
| 2 | /usuarios | Gestión de usuarios | Admin |
| 3 | /roles | Gestión de roles | Admin |
| 4 | /reportes | Reportes | Admin, Gerente |
| 5 | /facturacion | Módulo de facturación | Vendedor |
| 6 | /inventario | Gestión de inventario | Vendedor, Gerente |

---

## 🎨 DISEÑO EMPRESARIAL

### Características:
✅ Colores profesionales (gradientes azul-púrpura)
✅ Tipografía moderna y limpia
✅ Responsive (funciona en móvil, tablet, desktop)
✅ Animaciones suaves
✅ Iconos Font Awesome
✅ Componentes Bootstrap mejorados
✅ Sombras y espaciado profesional
✅ Modo oscuro (opcional)

### Colores Principales:
- **Primario**: #667eea (Azul)
- **Primario Oscuro**: #764ba2 (Púrpura)
- **Éxito**: #48bb78 (Verde)
- **Peligro**: #f56565 (Rojo)

---

## 📊 BASE DE DATOS

### Nuevas Tablas:

**verificacion_cuenta**
```sql
- id (PK)
- email (UNIQUE)
- codigo_verificacion (6 dígitos)
- fecha_creacion
- fecha_expiracion
- verificado (boolean)
- intentos_fallidos
```

**rol_usuario** (relación muchos-a-muchos)
```sql
- id (PK)
- email (FK a usuario)
- id_rol (FK a rol)
- fecha_asignacion
```

**ruta_rol** (relación muchos-a-muchos)
```sql
- id (PK)
- id_rol (FK a rol)
- id_ruta (FK a ruta)
- fecha_asignacion
```

### Modificaciones Existentes:

**usuario** - Columnas agregadas:
- `cuenta_verificada` (boolean)
- `fecha_creacion` (timestamp)
- `fecha_ultimo_cambio_contrasena` (timestamp)

---

## 🔐 SEGURIDAD

✅ Contraseñas encriptadas con BCrypt
✅ Códigos de verificación de 6 dígitos con expiración de 10 minutos
✅ Autenticación JWT para endpoints admin
✅ Validación de roles en backend
✅ Protección contra inyección SQL (parámetros validados)
✅ CORS configurado
✅ HTTPS recomendado en producción

---

## 🛠️ INSTALACIÓN/CONFIGURACIÓN

### Paso 1: Base de Datos
```bash
# Ejecuta el script SQL en tu BD
-- PostgreSQL:
psql -U postgres -d tu_bd -f nuevas_tablas_para_verificacion.sql

-- SQL Server:
sqlcmd -S servidor -U usuario -P contraseña -i nuevas_tablas_para_verificacion.sql

-- MySQL:
mysql -u usuario -p tu_bd < nuevas_tablas_para_verificacion.sql
```

### Paso 2: Configurar Email
Edita `appsettings.json` con tus credenciales SMTP

### Paso 3: Ejecutar la Aplicación
```bash
cd ApiGenericaCsharp
dotnet run

# En otra terminal:
cd FrontBlazor_AppiGenericaCsharp
dotnet run
```

### Paso 4: Acceder
- Frontend: http://localhost:7073
- API: http://localhost:5035
- Swagger: http://localhost:5035/swagger

---

## 📋 CHECKLIST DE FUNCIONALIDADES

- ✅ Usuarios pueden registrarse con verificación por email
- ✅ Código de verificación de 6 dígitos válido 10 minutos
- ✅ Selección de roles durante el registro (excepto Admin)
- ✅ Admin puede asignar roles a usuarios existentes
- ✅ Admin puede revocar roles
- ✅ Roles tienen rutas asignadas
- ✅ Frontend responsive y empresarial
- ✅ Página de login mejorada
- ✅ Panel de administración de usuarios
- ✅ Seguridad con JWT y encriptación

---

## 🐛 TROUBLESHOOTING

### "Error enviando email"
1. Verifica credenciales SMTP en `appsettings.json`
2. Comprueba que SMTP esté habilitado
3. Para Gmail, usa contraseña de aplicación, no la contraseña de cuenta

### "Código de verificación expirado"
1. Los códigos expiran en 10 minutos
2. El usuario puede solicitar uno nuevo

### "Usuario no encontrado después de login"
1. Verifica que se guardó en tabla `usuario`
2. Comprueba que `cuenta_verificada = true`

### "Rol no se asigna"
1. Verifica que el rol exista (ID válido)
2. Comprueba que el usuario tenga rol Admin para asignar
3. Verifica Token JWT válido

---

## 📞 SOPORTE

Para reportar problemas o sugerencias, contacta al equipo de desarrollo.

**Última actualización**: Mayo 2026
**Versión**: 2.0 (Con Sistema de Roles y Verificación)
