using System.Net.Http.Json;
using System.Text.Json;

namespace FrontBlazor_AppiGenericaCsharp.Services
{
    public class SpService
    {
        private readonly HttpClient _http;
        private readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public SpService(HttpClient http)
        {
            _http = http;
        }

        public async Task<(bool exito, JsonElement? datos, string mensaje)> EjecutarSpAsync(
            string nombreSP,
            Dictionary<string, object?>? parametros = null)
        {
            var payload = new Dictionary<string, object?>
            {
                ["nombreSP"] = nombreSP
            };

            if (parametros != null)
            {
                foreach (var kvp in parametros)
                {
                    // No sobrescribir el nombreSP
                    if (!string.Equals(kvp.Key, "nombreSP", StringComparison.OrdinalIgnoreCase))
                    {
                        payload[kvp.Key] = kvp.Value;
                    }
                }
            }

            try
            {
                var response = await _http.PostAsJsonAsync("/api/procedimientos/ejecutarsp", payload);
                var contenido = await response.Content.ReadAsStringAsync();

                if (string.IsNullOrWhiteSpace(contenido))
                    return (false, null, "Respuesta vacía del servidor.");

                using var doc = JsonDocument.Parse(contenido);
                var root = doc.RootElement;

                string mensaje = string.Empty;
                if (root.TryGetProperty("mensaje", out var mensajeProp) || root.TryGetProperty("Mensaje", out mensajeProp))
                {
                    mensaje = mensajeProp.GetString() ?? string.Empty;
                }

                if (root.TryGetProperty("resultados", out var resultados) || root.TryGetProperty("Resultados", out resultados))
                {
                    return (response.IsSuccessStatusCode, resultados.ValueKind == JsonValueKind.Null ? null : resultados, mensaje);
                }

                return (response.IsSuccessStatusCode, null, mensaje);
            }
            catch (Exception ex)
            {
                return (false, null, ex.Message);
            }
        }
    }
}
