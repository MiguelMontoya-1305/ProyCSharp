using System.Collections.Generic;
using System.Threading.Tasks;
using ApiGenericaCsharp.Modelos;

namespace ApiGenericaCsharp.Servicios.Abstracciones
{
    /// <summary>
    /// Define el contrato para servicios de registro de usuarios, verificación
    /// de email, asignación de roles y gestión de permisos.
    /// 
    /// Implementar esta interfaz permite:
    /// - Separar responsabilidades (SRP)
    /// - Inyectar dependencias (DIP)
    /// - Crear mocks para testing
    /// - Cambiar implementaciones sin afectar clientes
    /// </summary>
    public interface IServicioRegistroYRoles
    {
        /// <summary>
        /// Envía un código de verificación de 6 dígitos al email especificado.
        /// El código expira después de 10 minutos.
        /// </summary>
        /// <param name="email">Email del usuario que se registra</param>
        /// <returns>(exitoso, mensaje)</returns>
        Task<(bool exitoso, string mensaje)> EnviarCodigoVerificacionAsync(string email);

        /// <summary>
        /// Verifica el código enviado, crea la cuenta y asigna roles iniciales.
        /// </summary>
        /// <param name="email">Email a verificar</param>
        /// <param name="codigoVerificacion">Código de 6 dígitos recibido en email</param>
        /// <param name="contrasena">Contraseña en texto plano</param>
        /// <param name="idsRoles">IDs de roles a asignar (excluyendo Admin)</param>
        /// <returns>(exitoso, mensaje, datosUsuario con roles y rutas)</returns>
        Task<(bool exitoso, string mensaje, DatosUsuarioAutenticado? usuario)> VerificarCuentaAsync(
            string email, string codigoVerificacion, string contrasena, List<int> idsRoles);

        /// <summary>
        /// Asigna un rol existente a un usuario existente.
        /// Solo administradores pueden hacer esto.
        /// </summary>
        /// <param name="email">Email del usuario</param>
        /// <param name="idRol">ID del rol a asignar</param>
        /// <returns>(exitoso, mensaje)</returns>
        Task<(bool exitoso, string mensaje)> AsignarRolAsync(string email, int idRol);

        /// <summary>
        /// Revoca (elimina) un rol de un usuario.
        /// </summary>
        /// <param name="email">Email del usuario</param>
        /// <param name="idRol">ID del rol a remover</param>
        /// <returns>(exitoso, mensaje)</returns>
        Task<(bool exitoso, string mensaje)> RevocarRolAsync(string email, int idRol);

        /// <summary>
        /// Obtiene toda la información de un usuario autenticado:
        /// - Lista de roles asignados
        /// - Rutas permitidas según roles
        /// - Datos para generar el token JWT
        /// </summary>
        /// <param name="email">Email del usuario</param>
        /// <returns>DatosUsuarioAutenticado con roles y rutas</returns>
        Task<DatosUsuarioAutenticado> ObtenerDatosUsuarioAsync(string email);
    }
}
