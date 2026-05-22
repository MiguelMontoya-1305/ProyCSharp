using System.Text.Json.Serialization;

namespace ApiGenericaCsharp.Modelos
{
    /// <summary>
    /// Modelo simple para solicitar envío de código de verificación
    /// El usuario solo proporciona el email
    /// </summary>
    public class SolicitudCodigoVerificacion
    {
        /// <summary>Email del usuario (funciona como username único)</summary>
        [JsonPropertyName("email")]
        public string Email { get; set; } = string.Empty;
    }

    /// <summary>
    /// Modelo para solicitar la creación de una cuenta (registro)
    /// El usuario proporciona email, contraseña y roles que quiere
    /// </summary>
    public class SolicitudRegistro
    {
        /// <summary>Email del usuario (funciona como username único)</summary>
        [JsonPropertyName("email")]
        public string Email { get; set; } = string.Empty;

        /// <summary>Contraseña en texto plano (se encriptará con BCrypt en la API)</summary>
        [JsonPropertyName("contrasena")]
        public string Contrasena { get; set; } = string.Empty;

        /// <summary>Confirmación de contraseña (validar que coincida)</summary>
        [JsonPropertyName("confirmarContrasena")]
        public string ConfirmarContrasena { get; set; } = string.Empty;

        /// <summary>Código de verificación de 6 dígitos recibido en el email</summary>
        [JsonPropertyName("codigoVerificacion")]
        public string CodigoVerificacion { get; set; } = string.Empty;

        /// <summary>IDs de roles a asignar (ej: [2,3] para Usuario y Vendedor)</summary>
        [JsonPropertyName("idsRoles")]
        public List<int> IdsRoles { get; set; } = new();
    }

    /// <summary>
    /// Modelo para la respuesta después de registrarse
    /// Indica que se envió un código al correo
    /// </summary>
    public class RespuestaRegistro
    {
        public bool Exitoso { get; set; }
        public string Mensaje { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
    }

    /// <summary>
    /// Modelo para solicitar verificación del email con código
    /// El usuario recibe un código de 6 dígitos en su email
    /// </summary>
    public class SolicitudVerificacion
    {
        /// <summary>Email que se está registrando</summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>Código de 6 dígitos recibido en el email</summary>
        public string CodigoVerificacion { get; set; } = string.Empty;
    }

    /// <summary>
    /// Modelo para responder a verificación de email
    /// </summary>
    public class RespuestaVerificacion
    {
        public bool Exitoso { get; set; }
        public string Mensaje { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty; // JWT si verificación fue exitosa
    }

    /// <summary>
    /// Modelo para asignar un rol a un usuario (admin)
    /// </summary>
    public class AsignacionRol
    {
        /// <summary>Email del usuario</summary>
        [JsonPropertyName("email")]
        public string Email { get; set; } = string.Empty;

        /// <summary>ID del rol a asignar</summary>
        [JsonPropertyName("idRol")]
        public int IdRol { get; set; }
    }

    /// <summary>
    /// Modelo para revocar un rol de un usuario
    /// </summary>
    public class RevocacionRol
    {
        /// <summary>Email del usuario</summary>
        [JsonPropertyName("email")]
        public string Email { get; set; } = string.Empty;

        /// <summary>ID del rol a remover</summary>
        [JsonPropertyName("idRol")]
        public int IdRol { get; set; }
    }

    /// <summary>
    /// Modelo para información de un rol con sus rutas asignadas
    /// </summary>
    public class RolConRutas
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public List<RutaInfo> Rutas { get; set; } = new();
    }

    /// <summary>
    /// Modelo para información de una ruta
    /// </summary>
    public class RutaInfo
    {
        public int Id { get; set; }
        public string Ruta { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
    }

    /// <summary>
    /// Información completa de un usuario con roles y rutas
    /// Usada después de login exitoso para el frontend
    /// </summary>
    public class DatosUsuarioAutenticado
    {
        /// <summary>Email del usuario autenticado</summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>Nombres de roles asignados (ej: ["Admin", "Vendedor"])</summary>
        public List<string> Roles { get; set; } = new();

        /// <summary>Rutas/permisos disponibles según los roles</summary>
        public HashSet<string> RutasPermitidas { get; set; } = new();

        /// <summary>Token JWT para autenticación en futuros requests</summary>
        public string Token { get; set; } = string.Empty;
    }
}
