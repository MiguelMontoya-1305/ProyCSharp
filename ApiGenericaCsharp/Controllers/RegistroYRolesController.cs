using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using ApiGenericaCsharp.Modelos;
using ApiGenericaCsharp.Servicios.Abstracciones;

namespace ApiGenericaCsharp.Controllers
{
    /// <summary>
    /// Controlador que maneja:
    /// - Registro de nuevos usuarios con verificación de email
    /// - Asignación y revocación de roles (para administradores)
    /// - Obtención de datos de usuario con roles y rutas permitidas
    /// 
    /// Endpoints:
    /// POST   /api/registro/solicitar-codigo     - Enviar código de verificación
    /// POST   /api/registro/verificar             - Verificar email y crear cuenta
    /// POST   /api/admin/asignar-rol              - Asignar rol a usuario (Admin)
    /// DELETE /api/admin/revocar-rol              - Remover rol de usuario (Admin)
    /// GET    /api/usuario/datos                  - Obtener datos del usuario autenticado
    /// </summary>
    [ApiController]
    [Route("api")]
    public class RegistroYRolesController : ControllerBase
    {
        private readonly IServicioRegistroYRoles _servicioRegistro;
        private readonly ILogger<RegistroYRolesController> _logger;

        public RegistroYRolesController(
            IServicioRegistroYRoles servicioRegistro,
            ILogger<RegistroYRolesController> logger)
        {
            _servicioRegistro = servicioRegistro ?? throw new ArgumentNullException(nameof(servicioRegistro));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 1. SOLICITAR CÓDIGO DE VERIFICACIÓN
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Envía un código de verificación (6 dígitos) al email especificado.
        /// El código es válido por 10 minutos.
        /// 
        /// Endpoint: POST /api/registro/solicitar-codigo
        /// 
        /// Ejemplo de solicitud:
        /// {
        ///   "email": "juan@example.com"
        /// }
        /// 
        /// Respuesta exitosa (200):
        /// {
        ///   "exitoso": true,
        ///   "mensaje": "Se envió un código de verificación a juan@example.com. Expira en 10 minutos.",
        ///   "email": "juan@example.com"
        /// }
        /// 
        /// Errores posibles:
        /// - 400: Email inválido o formato incorrecto
        /// - 409: Email ya registrado en el sistema
        /// - 500: Error al enviar email (problema SMTP)
        /// </summary>
        [HttpPost("registro/solicitar-codigo")]
        [AllowAnonymous]
        public async Task<IActionResult> SolicitarCodigoAsync([FromBody] SolicitudCodigoVerificacion solicitud)
        {
            try
            {
                if (solicitud == null || string.IsNullOrWhiteSpace(solicitud.Email))
                    return BadRequest(new { exitoso = false, mensaje = "Email requerido." });

                string email = solicitud.Email.Trim();

                _logger.LogInformation("Solicitud de código para: {Email}", email);

                var (exitoso, mensaje) = await _servicioRegistro.EnviarCodigoVerificacionAsync(email);

                if (!exitoso)
                    return BadRequest(new { exitoso = false, mensaje });

                return Ok(new { exitoso = true, mensaje, email });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error solicitando código de verificación");
                return StatusCode(500, new { exitoso = false, mensaje = "Error interno del servidor" });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 2. VERIFICAR EMAIL Y CREAR CUENTA
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Verifica el código enviado al email y crea la nueva cuenta.
        /// Asigna los roles seleccionados al usuario (excepto Admin).
        /// 
        /// Endpoint: POST /api/registro/verificar
        /// 
        /// Ejemplo de solicitud:
        /// {
        ///   "email": "juan@example.com",
        ///   "codigoVerificacion": "123456",
        ///   "contrasena": "miPassword123",
        ///   "confirmarContrasena": "miPassword123",
        ///   "idsRoles": [2, 3]
        /// }
        /// 
        /// Respuesta exitosa (200):
        /// {
        ///   "exitoso": true,
        ///   "mensaje": "Cuenta creada exitosamente.",
        ///   "email": "juan@example.com",
        ///   "roles": ["Usuario", "Vendedor"],
        ///   "rutasPermitidas": ["/dashboard", "/facturacion"],
        ///   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        /// }
        /// 
        /// Errores posibles:
        /// - 400: Código expirado, inválido, o contraseña no cumple requisitos
        /// - 401: Código incorrecto
        /// - 500: Error interno
        /// </summary>
        [HttpPost("registro/verificar")]
        [AllowAnonymous]
        public async Task<IActionResult> VerificarCuentaAsync([FromBody] SolicitudRegistro solicitud)
        {
            try
            {
                // Validaciones básicas
                if (solicitud == null || string.IsNullOrWhiteSpace(solicitud.Email))
                    return BadRequest(new { exitoso = false, mensaje = "Email requerido." });

                if (solicitud.Contrasena != solicitud.ConfirmarContrasena)
                    return BadRequest(new { exitoso = false, mensaje = "Las contraseñas no coinciden." });

                if (string.IsNullOrWhiteSpace(solicitud.CodigoVerificacion))
                    return BadRequest(new { exitoso = false, mensaje = "Código de verificación requerido." });

                _logger.LogInformation("Verificando cuenta para: {Email}", solicitud.Email);
                _logger.LogInformation("Código recibido: {Codigo}, Contraseña longitud: {PasswordLen}, Roles: {Roles}", 
                    solicitud.CodigoVerificacion, solicitud.Contrasena.Length, string.Join(",", solicitud.IdsRoles));

                var (exitoso, mensaje, usuario) = await _servicioRegistro.VerificarCuentaAsync(
                    solicitud.Email,
                    solicitud.CodigoVerificacion,
                    solicitud.Contrasena,
                    solicitud.IdsRoles
                );

                if (!exitoso)
                {
                    _logger.LogWarning("Verificación fallida: {Mensaje}", mensaje);
                    return BadRequest(new { exitoso = false, mensaje });
                }

                return Ok(new
                {
                    exitoso = true,
                    mensaje = "Cuenta creada exitosamente.",
                    email = usuario?.Email,
                    roles = usuario?.Roles,
                    rutasPermitidas = usuario?.RutasPermitidas,
                    token = usuario?.Token
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verificando cuenta");
                return StatusCode(500, new { exitoso = false, mensaje = "Error interno del servidor" });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 3. ASIGNAR ROL A USUARIO (ADMIN ONLY)
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Asigna un rol a un usuario existente.
        /// **REQUIERE AUTENTICACIÓN Y ROL ADMIN**
        /// 
        /// Endpoint: POST /api/admin/asignar-rol
        /// Header requerido: Authorization: Bearer {token_jwt}
        /// 
        /// Ejemplo de solicitud:
        /// {
        ///   "email": "juan@example.com",
        ///   "idRol": 3
        /// }
        /// 
        /// Respuesta exitosa (200):
        /// {
        ///   "exitoso": true,
        ///   "mensaje": "Rol asignado exitosamente."
        /// }
        /// 
        /// Errores posibles:
        /// - 401: No autenticado
        /// - 403: No tiene rol Admin
        /// - 404: Usuario o rol no encontrado
        /// - 409: Usuario ya tiene ese rol
        /// </summary>
        [HttpPost("admin/asignar-rol")]
        [Authorize]  // Requiere token JWT válido
        public async Task<IActionResult> AsignarRolAsync([FromBody] AsignacionRol solicitud)
        {
            try
            {
                // Validaciones
                if (solicitud == null || string.IsNullOrWhiteSpace(solicitud.Email) || solicitud.IdRol <= 0)
                    return BadRequest(new { exitoso = false, mensaje = "Datos inválidos." });

                _logger.LogInformation(
                    "Admin {Admin} asignando rol {IdRol} a {Email}",
                    User.Identity?.Name ?? "desconocido",
                    solicitud.IdRol,
                    solicitud.Email
                );

                var (exitoso, mensaje) = await _servicioRegistro.AsignarRolAsync(solicitud.Email, solicitud.IdRol);

                if (!exitoso)
                    return BadRequest(new { exitoso = false, mensaje });

                return Ok(new { exitoso = true, mensaje });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error asignando rol");
                return StatusCode(500, new { exitoso = false, mensaje = "Error interno del servidor" });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 4. REVOCAR ROL DE USUARIO (ADMIN ONLY)
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Revoca (elimina) un rol de un usuario.
        /// **REQUIERE AUTENTICACIÓN Y ROL ADMIN**
        /// 
        /// Endpoint: DELETE /api/admin/revocar-rol
        /// Header requerido: Authorization: Bearer {token_jwt}
        /// 
        /// Ejemplo de solicitud:
        /// {
        ///   "email": "juan@example.com",
        ///   "idRol": 3
        /// }
        /// 
        /// Respuesta exitosa (200):
        /// {
        ///   "exitoso": true,
        ///   "mensaje": "Rol revocado exitosamente."
        /// }
        /// </summary>
        [HttpDelete("admin/revocar-rol")]
        [Authorize]  // Requiere token JWT válido
        public async Task<IActionResult> RevocarRolAsync([FromBody] RevocacionRol solicitud)
        {
            try
            {
                if (solicitud == null || string.IsNullOrWhiteSpace(solicitud.Email) || solicitud.IdRol <= 0)
                    return BadRequest(new { exitoso = false, mensaje = "Datos inválidos." });

                _logger.LogInformation(
                    "Admin {Admin} revocando rol {IdRol} de {Email}",
                    User.Identity?.Name ?? "desconocido",
                    solicitud.IdRol,
                    solicitud.Email
                );

                var (exitoso, mensaje) = await _servicioRegistro.RevocarRolAsync(solicitud.Email, solicitud.IdRol);

                if (!exitoso)
                    return BadRequest(new { exitoso = false, mensaje });

                return Ok(new { exitoso = true, mensaje });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error revocando rol");
                return StatusCode(500, new { exitoso = false, mensaje = "Error interno del servidor" });
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 5. OBTENER DATOS DEL USUARIO AUTENTICADO
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Obtiene los datos del usuario autenticado actual:
        /// - Email
        /// - Lista de roles
        /// - Rutas permitidas según roles
        /// 
        /// **REQUIERE AUTENTICACIÓN**
        /// 
        /// Endpoint: GET /api/usuario/datos
        /// Header requerido: Authorization: Bearer {token_jwt}
        /// 
        /// Respuesta (200):
        /// {
        ///   "email": "juan@example.com",
        ///   "roles": ["Usuario", "Vendedor"],
        ///   "rutasPermitidas": ["/dashboard", "/facturacion", "/reportes"]
        /// }
        /// </summary>
        [HttpGet("usuario/datos")]
        [Authorize]  // Requiere token JWT válido
        public async Task<IActionResult> ObtenerDatosUsuarioAsync()
        {
            try
            {
                string emailActual = User.Identity?.Name ?? "";

                if (string.IsNullOrEmpty(emailActual))
                    return Unauthorized(new { mensaje = "Usuario no identificado." });

                var datos = await _servicioRegistro.ObtenerDatosUsuarioAsync(emailActual);

                return Ok(new
                {
                    email = datos.Email,
                    roles = datos.Roles,
                    rutasPermitidas = datos.RutasPermitidas
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error obteniendo datos de usuario");
                return StatusCode(500, new { mensaje = "Error interno del servidor" });
            }
        }
    }
}
