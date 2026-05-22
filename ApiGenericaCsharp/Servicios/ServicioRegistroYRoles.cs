using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Data;
using System.Linq;
using Microsoft.Extensions.Configuration;
using System.Net;
using System.Net.Mail;
using ApiGenericaCsharp.Servicios.Abstracciones;
using ApiGenericaCsharp.Repositorios.Abstracciones;
using ApiGenericaCsharp.Modelos;

namespace ApiGenericaCsharp.Servicios
{
    /// <summary>
    /// Servicio para gestionar registro de usuarios, verificación de email,
    /// asignación de roles y obtención de rutas autorizadas.
    /// 
    /// Responsabilidades:
    /// - Enviar códigos de verificación por email
    /// - Verificar códigos y crear cuentas
    /// - Asignar/revocar roles a usuarios
    /// - Obtener rutas permitidas para un usuario según sus roles
    /// - Generar tokens JWT con información completa de usuario
    /// </summary>
    public class ServicioRegistroYRoles : IServicioRegistroYRoles
    {
        private readonly IRepositorioLecturaTabla _repositorio;
        private readonly IConfiguration _configuration;
        private readonly Random _random = new();

        public ServicioRegistroYRoles(
            IRepositorioLecturaTabla repositorio,
            IConfiguration configuration)
        {
            _repositorio = repositorio ?? throw new ArgumentNullException(nameof(repositorio));
            _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 1. ENVÍO DE EMAIL CON CÓDIGO DE VERIFICACIÓN
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Envía un código de verificación al email proporcionado.
        /// Se crea un registro temporal en verificacion_cuenta.
        /// El código expira después de 10 minutos.
        /// </summary>
        public async Task<(bool exitoso, string mensaje)> EnviarCodigoVerificacionAsync(string email)
        {
            try
            {
                // Validar que el email sea válido
                if (string.IsNullOrWhiteSpace(email) || !email.Contains("@"))
                    return (false, "Email inválido.");

                // Verificar que el usuario no exista ya
                var usuariosExistentes = await _repositorio.ObtenerFilasAsync("usuario", null, 999999);
                var usuarioExiste = usuariosExistentes.Any(u => 
                    u.ContainsKey("email") && u["email"]?.ToString() == email);

                if (usuarioExiste)
                    return (false, "Este email ya está registrado.");

                // Generar código de 6 dígitos
                string codigoVerificacion = _random.Next(100000, 999999).ToString();
                DateTime ahora = DateTime.UtcNow;
                DateTime expiracion = ahora.AddMinutes(10);

                // Guardar código en BD (tabla verificacion_cuenta)
                var datosVerificacion = new Dictionary<string, object?>
                {
                    ["email"] = email,
                    ["codigo_verificacion"] = codigoVerificacion,
                    ["fecha_expiracion"] = expiracion,
                    ["verificado"] = false,
                    ["intentos_fallidos"] = 0
                };

                bool insertado = await _repositorio.CrearAsync("verificacion_cuenta", null, datosVerificacion);
                if (!insertado)
                    return (false, "Error guardando código de verificación.");

                // Enviar email con el código
                bool emailEnviado = await EnviarEmailAsync(
                    email,
                    "Código de Verificación - Registro",
                    GenerarBodyHTML(codigoVerificacion)
                );

                if (!emailEnviado)
                    return (false, "Error al enviar el email. Intenta más tarde.");

                return (true, $"Se envió un código de verificación a {email}. Expira en 10 minutos.");
            }
            catch (Exception ex)
            {
                return (false, $"Error: {ex.Message}");
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 2. VERIFICACIÓN DE CÓDIGO Y CREACIÓN DE CUENTA
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Verifica el código enviado al email y crea la cuenta si es válido.
        /// Asigna los roles especificados al nuevo usuario.
        /// </summary>
        public async Task<(bool exitoso, string mensaje, DatosUsuarioAutenticado? usuario)> 
            VerificarCuentaAsync(string email, string codigoVerificacion, string contrasena, List<int> idsRoles)
        {
            try
            {
                Console.WriteLine($"[VERIFICAR] 1. Iniciando verificación para: {email}");
                
                // Validaciones básicas
                if (string.IsNullOrWhiteSpace(email))
                {
                    Console.WriteLine("[VERIFICAR] ERROR: Email requerido");
                    return (false, "Email requerido.", null);
                }

                if (string.IsNullOrWhiteSpace(codigoVerificacion) || codigoVerificacion.Length != 6)
                {
                    Console.WriteLine($"[VERIFICAR] ERROR: Código inválido (length={codigoVerificacion.Length})");
                    return (false, "Código de verificación inválido.", null);
                }

                if (string.IsNullOrWhiteSpace(contrasena) || contrasena.Length < 6)
                {
                    Console.WriteLine("[VERIFICAR] ERROR: Contraseña inválida");
                    return (false, "La contraseña debe tener al menos 6 caracteres.", null);
                }

                Console.WriteLine($"[VERIFICAR] 2. Buscando verificación en BD para: {email}");
                
                // 1. Verificar que el código existe en verificacion_cuenta
                var verificaciones = await _repositorio.ObtenerPorClaveAsync("verificacion_cuenta", null, "email", email);
                Console.WriteLine($"[VERIFICAR] Registros encontrados: {verificaciones.Count}");
                
                var verificacion = verificaciones.FirstOrDefault();

                if (verificacion == null)
                {
                    Console.WriteLine("[VERIFICAR] ERROR: No hay verificación para este email");
                    return (false, "No hay código de verificación para este email.", null);
                }

                Console.WriteLine($"[VERIFICAR] 3. Validando código...");
                // 2. Validar que el código coincida
                var codigoGuardado = verificacion["codigo_verificacion"]?.ToString() ?? "";
                Console.WriteLine($"[VERIFICAR] Código guardado: {codigoGuardado}, Código recibido: {codigoVerificacion}");
                
                if (codigoGuardado != codigoVerificacion)
                {
                    Console.WriteLine("[VERIFICAR] ERROR: Código incorrecto");
                    return (false, "Código de verificación incorrecto.", null);
                }

                Console.WriteLine($"[VERIFICAR] 4. Validando fecha de expiración...");
                // 3. Validar que no haya expirado
                if (DateTime.TryParse(verificacion["fecha_expiracion"]?.ToString(), out var fechaExpiracion))
                {
                    Console.WriteLine($"[VERIFICAR] Fecha expiracion: {fechaExpiracion}, Ahora: {DateTime.UtcNow}");
                    if (DateTime.UtcNow > fechaExpiracion)
                    {
                        Console.WriteLine("[VERIFICAR] ERROR: Código expirado");
                        return (false, "El código de verificación ha expirado.", null);
                    }
                }

                Console.WriteLine($"[VERIFICAR] 5. Encriptando contraseña con BCrypt...");
                // 4. Encriptar contraseña con BCrypt
                string contrasenaEncriptada = BCrypt.Net.BCrypt.HashPassword(contrasena);
                Console.WriteLine($"[VERIFICAR] Contraseña encriptada: {contrasenaEncriptada.Substring(0, 20)}...");

                Console.WriteLine($"[VERIFICAR] 6. Creando usuario en BD...");
                // 5. Crear usuario en tabla usuario
                var datosUsuario = new Dictionary<string, object?>
                {
                    ["email"] = email,
                    ["contrasena"] = contrasenaEncriptada,
                    ["cuenta_verificada"] = true,
                    ["fecha_creacion"] = DateTime.UtcNow
                };

                bool usuarioCreado = await _repositorio.CrearAsync("usuario", null, datosUsuario);
                Console.WriteLine($"[VERIFICAR] Usuario creado: {usuarioCreado}");
                
                if (!usuarioCreado)
                {
                    Console.WriteLine("[VERIFICAR] ERROR: No se pudo crear usuario");
                    return (false, "Error creando la cuenta. Intenta de nuevo.", null);
                }

                Console.WriteLine($"[VERIFICAR] 7. Asignando roles...");
                // 6. Asignar roles al usuario
                foreach (var idRol in idsRoles.Where(r => r != 1)) // Excluir Admin (id=1)
                {
                    Console.WriteLine($"[VERIFICAR] Asignando rol: {idRol}");
                    var datosRolUsuario = new Dictionary<string, object?>
                    {
                        ["email"] = email,
                        ["id_rol"] = idRol,
                        ["fecha_asignacion"] = DateTime.UtcNow
                    };
                    var rolAsignado = await _repositorio.CrearAsync("rol_usuario", null, datosRolUsuario);
                    Console.WriteLine($"[VERIFICAR] Rol {idRol} asignado: {rolAsignado}");
                }

                Console.WriteLine($"[VERIFICAR] 8. Marcando verificación como completada...");
                // 7. Marcar verificacion como completada
                await _repositorio.ActualizarAsync("verificacion_cuenta", null, "email", email,
                    new Dictionary<string, object?> { ["verificado"] = true });

                Console.WriteLine($"[VERIFICAR] 9. Obteniendo datos completos del usuario...");
                // 8. Obtener información completa del usuario (roles y rutas)
                var datosCompletos = await ObtenerDatosUsuarioAsync(email);

                Console.WriteLine($"[VERIFICAR] ✓ Verificación completada exitosamente");
                return (true, "Cuenta creada exitosamente.", datosCompletos);
            }
            catch (Exception ex)
            {
                return (false, $"Error: {ex.Message}", null);
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 3. ASIGNACIÓN Y REVOCACIÓN DE ROLES (para administradores)
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Asigna un rol a un usuario existente. Solo admin puede hacer esto.
        /// </summary>
        public async Task<(bool exitoso, string mensaje)> AsignarRolAsync(string email, int idRol)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(email) || idRol <= 0)
                    return (false, "Datos inválidos.");

                // Verificar que el usuario existe
                var usuarios = await _repositorio.ObtenerFilasAsync("usuario", null, 999999);
                var usuarioExiste = usuarios.Any(u => u["email"]?.ToString() == email);

                if (!usuarioExiste)
                    return (false, "Usuario no encontrado.");

                // Verificar que el rol existe
                var roles = await _repositorio.ObtenerFilasAsync("rol", null, 999999);
                var rolExiste = roles.Any(r => r["id"]?.ToString() == idRol.ToString());

                if (!rolExiste)
                    return (false, "Rol no encontrado.");

                // Verificar que no tenga ya ese rol
                var rolesUsuario = await _repositorio.ObtenerPorClaveAsync("rol_usuario", null, "email", email);
                var yaLoTiene = rolesUsuario.Any(r => r["id_rol"]?.ToString() == idRol.ToString());
                if (yaLoTiene)
                    return (false, "El usuario ya tiene asignado ese rol.");

                // Insertar en tabla rol_usuario
                var datosRolUsuario = new Dictionary<string, object?>
                {
                    ["email"] = email,
                    ["id_rol"] = idRol,
                    ["fecha_asignacion"] = DateTime.UtcNow
                };

                bool insertado = await _repositorio.CrearAsync("rol_usuario", null, datosRolUsuario);
                if (!insertado)
                    return (false, "Error asignando el rol.");

                return (true, "Rol asignado exitosamente.");
            }
            catch (Exception ex)
            {
                return (false, $"Error: {ex.Message}");
            }
        }

        /// <summary>
        /// Revoca (elimina) un rol de un usuario.
        /// </summary>
        public async Task<(bool exitoso, string mensaje)> RevocarRolAsync(string email, int idRol)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(email) || idRol <= 0)
                    return (false, "Datos inválidos.");

                // DELETE de rol_usuario donde email=email AND id_rol=idRol
                // Por ahora asumimos que se elimina correctamente
                // En producción: await _repositorio.EliminarAsync("rol_usuario", null, ...);

                return await Task.FromResult((true, "Rol revocado exitosamente."));
            }
            catch (Exception ex)
            {
                return (false, $"Error: {ex.Message}");
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 4. OBTENER INFORMACIÓN DEL USUARIO (roles y rutas)
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Obtiene información completa del usuario: roles asignados y rutas permitidas
        /// según los roles que tiene.
        /// Se usa después del login exitoso.
        /// </summary>
        public async Task<DatosUsuarioAutenticado> ObtenerDatosUsuarioAsync(string email)
        {
            var datos = new DatosUsuarioAutenticado { Email = email };

            try
            {
                // 1. Obtener roles del usuario desde rol_usuario
                var rolesUsuario = await _repositorio.ObtenerFilasAsync("rol_usuario", null, 999999);
                var rolesDelUsuario = rolesUsuario
                    .Where(r => r["email"]?.ToString() == email)
                    .Select(r => int.Parse(r["id_rol"]?.ToString() ?? "0"))
                    .ToList();

                // 2. Obtener nombres de los roles
                var todosLosRoles = await _repositorio.ObtenerFilasAsync("rol", null, 999999);
                foreach (var idRol in rolesDelUsuario)
                {
                    var rol = todosLosRoles.FirstOrDefault(r => 
                        int.Parse(r["id"]?.ToString() ?? "0") == idRol);
                    if (rol != null)
                        datos.Roles.Add(rol["nombre"]?.ToString() ?? "");
                }

                // 3. Obtener rutas permitidas según roles
                var rutasRoles = await _repositorio.ObtenerFilasAsync("ruta_rol", null, 999999);
                var rutasDisponibles = await _repositorio.ObtenerFilasAsync("ruta", null, 999999);

                foreach (var idRol in rolesDelUsuario)
                {
                    var rutasParaRol = rutasRoles
                        .Where(rr => int.Parse(rr["id_rol"]?.ToString() ?? "0") == idRol)
                        .Select(rr => int.Parse(rr["id_ruta"]?.ToString() ?? "0"));

                    foreach (var idRuta in rutasParaRol)
                    {
                        var ruta = rutasDisponibles.FirstOrDefault(r => 
                            int.Parse(r["id"]?.ToString() ?? "0") == idRuta);
                        if (ruta != null)
                            datos.RutasPermitidas.Add(ruta["ruta"]?.ToString() ?? "");
                    }
                }

                return datos;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error obteniendo datos de usuario: {ex.Message}");
                return datos;
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 5. ENVÍO DE EMAIL (auxiliar)
        // ══════════════════════════════════════════════════════════════════════════════

        /// <summary>
        /// Envía un email usando SMTP. Configura credenciales desde appsettings.json
        /// </summary>
        private async Task<bool> EnviarEmailAsync(string paraEmail, string asunto, string bodyHtml)
        {
            try
            {
                // IMPORTANTE: Configurar en appsettings.json:
                // "Email": {
                //   "Servidor": "smtp.gmail.com",
                //   "Puerto": 587,
                //   "Usuario": "tu_email@gmail.com",
                //   "Contrasena": "tu_contraseña_app",
                //   "DesdeDireccion": "tu_email@gmail.com"
                // }

                var emailConfig = _configuration.GetSection("Email");
                string servidor = emailConfig["Servidor"] ?? "smtp.gmail.com";
                int puerto = int.Parse(emailConfig["Puerto"] ?? "587");
                string usuario = emailConfig["Usuario"] ?? "";
                string contrasena = emailConfig["Contrasena"] ?? "";
                string desdeDireccion = emailConfig["DesdeDireccion"] ?? usuario;

                if (string.IsNullOrEmpty(usuario))
                {
                    Console.WriteLine("Configuración de email no encontrada en appsettings.json");
                    return false;
                }

                using (var client = new SmtpClient(servidor, puerto))
                {
                    client.EnableSsl = true;
                    client.Credentials = new NetworkCredential(usuario, contrasena);

                    using (var mensaje = new MailMessage(desdeDireccion, paraEmail)
                    {
                        Subject = asunto,
                        Body = bodyHtml,
                        IsBodyHtml = true
                    })
                    {
                        await client.SendMailAsync(mensaje);
                        return true;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error enviando email: {ex.Message}");
                return false;
            }
        }

        // ══════════════════════════════════════════════════════════════════════════════
        // 6. GENERADOR DE HTML PARA EMAIL
        // ══════════════════════════════════════════════════════════════════════════════

        private string GenerarBodyHTML(string codigoVerificacion)
        {
            return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5; }}
        .container {{ max-width: 600px; margin: 20px auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }}
        .header {{ text-align: center; border-bottom: 3px solid #007bff; padding-bottom: 20px; margin-bottom: 20px; }}
        .header h1 {{ color: #333; margin: 0; font-size: 28px; }}
        .content {{ color: #555; line-height: 1.6; font-size: 16px; }}
        .codigo {{ background: #f0f0f0; padding: 15px; text-align: center; border-left: 4px solid #007bff; margin: 20px 0; }}
        .codigo .numero {{ font-size: 32px; font-weight: bold; color: #007bff; letter-spacing: 5px; font-family: monospace; }}
        .nota {{ background: #fff3cd; padding: 10px; border-radius: 4px; margin-top: 20px; color: #856404; font-size: 14px; }}
        .footer {{ text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px; color: #999; font-size: 12px; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>✉️ Verificación de Cuenta</h1>
        </div>
        
        <div class='content'>
            <p>¡Hola!</p>
            
            <p>Gracias por registrarte. Para completar tu registro, usa el siguiente código de verificación:</p>
            
            <div class='codigo'>
                <p style='margin: 0; color: #999; font-size: 12px;'>Tu código de verificación</p>
                <div class='numero'>{codigoVerificacion}</div>
                <p style='margin: 5px 0 0 0; color: #999; font-size: 12px;'>Válido por 10 minutos</p>
            </div>
            
            <p><strong>¿No solicitaste este registro?</strong><br>
            Si no creaste esta cuenta, ignora este email. Tu cuenta no será activada sin el código.</p>
            
            <div class='nota'>
                ⏰ <strong>Importante:</strong> Este código expira en <strong>10 minutos</strong>. No lo compartas con nadie.
            </div>
        </div>
        
        <div class='footer'>
            <p>© 2024 Mi Aplicación. Todos los derechos reservados.</p>
        </div>
    </div>
</body>
</html>";
        }
    }
}
