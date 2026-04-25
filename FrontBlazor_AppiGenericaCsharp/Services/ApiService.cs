using System.Net.Http.Json;
using System.Net.Security;
using System.Text.Json;

namespace FrontBlazor_AppiGenericaCsharp.Services
{
    // Servicio generico que consume la API REST para cualquier tabla.
    // Se inyecta en las paginas Blazor con @inject ApiService Api
    public class ApiService
    {
        // HttpClient configurado en Program.cs con la URL base de la API
        private readonly HttpClient _http;

        // Servicio de autenticacion para obtener el token JWT
        private readonly AuthService? _auth;

        // Opciones para deserializar JSON sin distinguir mayusculas/minusculas
        // La API devuelve "datos", "estado", etc. en minuscula
        private readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        // El constructor recibe el HttpClient inyectado por DI
        public ApiService(HttpClient http, AuthService? auth = null)
        {
            _http = http;
            _auth = auth;
        }
        /// <summary>
        /// Agrega el token JWT al header Authorization antes de cada request.
        /// Si no hay token (no ha hecho login), no agrega nada y la API
        /// funciona sin autenticacion (endpoints sin [Authorize]).
        /// </summary>
        private void AgregarTokenJwt()
        {
            _http.DefaultRequestHeaders.Remove("Authorization");
            if (_auth?.Token != null)
                _http.DefaultRequestHeaders.Add("Authorization", $"Bearer {_auth.Token}");
        }

// ──────────────────────────────────────────────
        // LISTAR: GET /api/{tabla}
        // ──────────────────────────────────────────────
        public async Task<List<Dictionary<string, object?>>> ListarAsync(
            string tabla, int? limite = null)
        {
            try
            {
                AgregarTokenJwt();
                string url = $"/api/{tabla}";
                if (limite.HasValue)
                    url += $"?limite={limite.Value}";

                using var respuesta = await _http.GetAsync(url);
                if (!respuesta.IsSuccessStatusCode)
                {
                    Console.WriteLine($"Error al listar {tabla}: {respuesta.StatusCode}");
                    return new List<Dictionary<string, object?>>();
                }

                if (respuesta.StatusCode == System.Net.HttpStatusCode.NoContent)
                    return new List<Dictionary<string, object?>>();

                var contenidoTexto = await respuesta.Content.ReadAsStringAsync();
                if (string.IsNullOrWhiteSpace(contenidoTexto))
                    return new List<Dictionary<string, object?>>();

                var respuestaJson = JsonSerializer.Deserialize<JsonElement>(
                    contenidoTexto, _jsonOptions);
                if (respuestaJson.ValueKind == JsonValueKind.Undefined ||
                    !respuestaJson.TryGetProperty("datos", out JsonElement datos))
                {
                    return new List<Dictionary<string, object?>>();
                }

                return ConvertirDatos(datos);
            }
            catch (HttpRequestException ex)
            {
                Console.WriteLine($"Error al listar {tabla}: {ex.Message}");
                return new List<Dictionary<string, object?>>();
            }
            catch (JsonException ex)
            {
                Console.WriteLine($"Error JSON al listar {tabla}: {ex.Message}");
                return new List<Dictionary<string, object?>>();
            }
        }

        // ──────────────────────────────────────────────
        // CREAR: POST /api/{tabla}
        // ──────────────────────────────────────────────
        public async Task<(bool exito, string mensaje)> CrearAsync(
            string tabla, Dictionary<string, object?> datos,
            string? camposEncriptar = null)
        {
            try
            {
                AgregarTokenJwt();
                string url = $"/api/{tabla}";
                if (!string.IsNullOrEmpty(camposEncriptar))
                    url += $"?camposEncriptar={camposEncriptar}";

                var respuesta = await _http.PostAsJsonAsync(url, datos);
                if (respuesta.StatusCode == System.Net.HttpStatusCode.NoContent)
                    return (respuesta.IsSuccessStatusCode, "Operacion completada.");

                var contenido = await respuesta.Content.ReadAsStringAsync();
                if (string.IsNullOrWhiteSpace(contenido))
                    return (respuesta.IsSuccessStatusCode, "Operacion completada.");

                var json = JsonSerializer.Deserialize<JsonElement>(contenido, _jsonOptions);

                string mensaje = json.TryGetProperty("mensaje", out JsonElement msg)
                    ? msg.GetString() ?? "Operacion completada."
                    : "Operacion completada.";

                return (respuesta.IsSuccessStatusCode, mensaje);
            }
            catch (HttpRequestException ex)
            {
                return (false, $"Error de conexion: {ex.Message}");
            }
            catch (JsonException ex)
            {
                return (false, $"Error de parseo JSON: {ex.Message}");
            }
        }

        // ──────────────────────────────────────────────
        // ACTUALIZAR: PUT /api/{tabla}/{clave}/{valor}
        // ──────────────────────────────────────────────
        public async Task<(bool exito, string mensaje)> ActualizarAsync(
            string tabla, string nombreClave, string valorClave,
            Dictionary<string, object?> datos,
            string? camposEncriptar = null)
        {
            try
            {
                AgregarTokenJwt();
                string url = $"/api/{tabla}/{nombreClave}/{valorClave}";
                if (!string.IsNullOrEmpty(camposEncriptar))
                    url += $"?camposEncriptar={camposEncriptar}";

                var respuesta = await _http.PutAsJsonAsync(url, datos);
                if (respuesta.StatusCode == System.Net.HttpStatusCode.NoContent)
                    return (respuesta.IsSuccessStatusCode, "Operacion completada.");

                var contenido = await respuesta.Content.ReadAsStringAsync();
                if (string.IsNullOrWhiteSpace(contenido))
                    return (respuesta.IsSuccessStatusCode, "Operacion completada.");

                var json = JsonSerializer.Deserialize<JsonElement>(contenido, _jsonOptions);

                string mensaje = json.TryGetProperty("mensaje", out JsonElement msg)
                    ? msg.GetString() ?? "Operacion completada."
                    : "Operacion completada.";

                return (respuesta.IsSuccessStatusCode, mensaje);
            }
            catch (HttpRequestException ex)
            {
                return (false, $"Error de conexion: {ex.Message}");
            }
            catch (JsonException ex)
            {
                return (false, $"Error de parseo JSON: {ex.Message}");
            }
        }

        // ──────────────────────────────────────────────
        // ELIMINAR: DELETE /api/{tabla}/{clave}/{valor}
        // ──────────────────────────────────────────────
        public async Task<(bool exito, string mensaje)> EliminarAsync(
            string tabla, string nombreClave, string valorClave)
        {
            try
            {
                AgregarTokenJwt();
                var respuesta = await _http.DeleteAsync(
                    $"/api/{tabla}/{nombreClave}/{valorClave}");
                if (respuesta.StatusCode == System.Net.HttpStatusCode.NoContent)
                    return (respuesta.IsSuccessStatusCode, "Operacion completada.");

                var contenido = await respuesta.Content.ReadAsStringAsync();
                if (string.IsNullOrWhiteSpace(contenido))
                    return (respuesta.IsSuccessStatusCode, "Operacion completada.");

                var json = JsonSerializer.Deserialize<JsonElement>(contenido, _jsonOptions);

                string mensaje = json.TryGetProperty("mensaje", out JsonElement msg)
                    ? msg.GetString() ?? "Operacion completada."
                    : "Operacion completada.";

                return (respuesta.IsSuccessStatusCode, mensaje);
            }
            catch (HttpRequestException ex)
            {
                return (false, $"Error de conexion: {ex.Message}");
            }
            catch (JsonException ex)
            {
                return (false, $"Error de parseo JSON: {ex.Message}");
            }
        }

        // ──────────────────────────────────────────────
        // DIAGNOSTICO: GET /api/diagnostico/conexion
        // ──────────────────────────────────────────────
        public async Task<Dictionary<string, string>?> ObtenerDiagnosticoAsync()
        {
            try
            {
                using var respuesta = await _http.GetAsync("/api/diagnostico/conexion");
                if (!respuesta.IsSuccessStatusCode)
                    return null;

                var contenidoTexto = await respuesta.Content.ReadAsStringAsync();
                if (string.IsNullOrWhiteSpace(contenidoTexto))
                    return null;

                var json = JsonSerializer.Deserialize<JsonElement>(contenidoTexto, _jsonOptions);

                if (json.TryGetProperty("servidor", out JsonElement servidor))
                {
                    var info = new Dictionary<string, string>();
                    foreach (var prop in servidor.EnumerateObject())
                    {
                        info[prop.Name] = prop.Value.ToString();
                    }
                    return info;
                }

                return null;
            }
            catch
            {
                return null;
            }
        }

        // ──────────────────────────────────────────────
        // Convierte JsonElement a lista de diccionarios
        // ──────────────────────────────────────────────
        private List<Dictionary<string, object?>> ConvertirDatos(JsonElement datos)
        {
            var lista = new List<Dictionary<string, object?>>();

            foreach (var fila in datos.EnumerateArray())
            {
                var diccionario = new Dictionary<string, object?>();

                foreach (var propiedad in fila.EnumerateObject())
                {
                    diccionario[propiedad.Name] = propiedad.Value.ValueKind switch
                    {
                        JsonValueKind.String => propiedad.Value.GetString(),
                        JsonValueKind.Number => propiedad.Value.TryGetInt32(out int i)
                            ? i : propiedad.Value.GetDouble(),
                        JsonValueKind.True => true,
                        JsonValueKind.False => false,
                        JsonValueKind.Null => null,
                        _ => propiedad.Value.GetRawText()
                    };
                }

                lista.Add(diccionario);
            }

            return lista;
        }
    }
}