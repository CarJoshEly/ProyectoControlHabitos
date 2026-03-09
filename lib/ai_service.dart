import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyD3cwu0dJPC4bvSXelKk1zO1D6bZ5eqSUI';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const String _systemContext = '''
Eres un asistente de productividad universitaria para estudiantes de la UNICAH 
(Universidad Católica de Honduras). Tu objetivo es ayudar a los estudiantes a 
mejorar sus hábitos de estudio, salud y bienestar. 
Siempre responde en español, de forma amigable, motivadora y concisa.
Adapta tus respuestas al contexto universitario hondureño.
''';

  Future<String> _callGemini(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': '$_systemContext\n\n$prompt'}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? 
               'No se pudo obtener respuesta.';
      } else {
        return 'Error al conectar con la IA. Intenta de nuevo.';
      }
    } catch (e) {
      return 'Error de conexión. Verifica tu internet.';
    }
  }

  // 1. SUGERIDOR DE HÁBITOS
  Future<String> sugerirHabitos({
    required String carrera,
    required String situacion,
  }) async {
    final prompt = '''
Un estudiante de $carrera en la UNICAH tiene esta situación: "$situacion".
Sugiere 5 hábitos específicos y prácticos que le ayuden. 
Para cada hábito incluye:
- Nombre corto del hábito
- Por qué es útil para su situación
- Frecuencia recomendada (diario/semanal)
Formato con emojis para hacerlo visual.
''';
    return await _callGemini(prompt);
  }

  // 2. ANÁLISIS DE PRODUCTIVIDAD
  Future<String> analizarProductividad({
    required List<Map<String, dynamic>> habitos,
  }) async {
    if (habitos.isEmpty) {
      return '¡Aún no tienes hábitos registrados! Crea algunos hábitos para que pueda analizar tu productividad. 💪';
    }

    final habitosTexto = habitos.map((h) => '''
- Hábito: ${h['name']}
  Completados: ${h['progress']} veces
  Racha actual: ${h['streak']} días
  Mejor racha: ${h['bestStreak']} días
  Frecuencia: ${h['frequency']}
''').join('\n');

    final prompt = '''
Analiza los siguientes hábitos de un estudiante universitario de la UNICAH:

$habitosTexto

Proporciona:
1. 📊 Un análisis general de su productividad
2. 💪 Sus fortalezas (hábitos que va bien)
3. ⚠️ Áreas de mejora (hábitos con bajo rendimiento)
4. 🎯 3 recomendaciones concretas y personalizadas
5. 🏆 Una frase motivadora final

Sé específico con los datos, menciona los hábitos por nombre.
''';
    return await _callGemini(prompt);
  }

  // 3. CHAT MOTIVACIONAL
  Future<String> chatMotivacional({
    required String mensaje,
    required List<Map<String, String>> historial,
  }) async {
    String historialTexto = historial
        .map((m) => '${m['role'] == 'user' ? 'Estudiante' : 'Asistente'}: ${m['content']}')
        .join('\n');

    final prompt = '''
Contexto: Eres un coach motivacional para estudiantes universitarios de la UNICAH.
Historial de conversación:
$historialTexto

Estudiante dice: "$mensaje"

Responde de forma empática, motivadora y con consejos prácticos para universitarios.
Máximo 3 párrafos cortos.
''';
    return await _callGemini(prompt);
  }

  // 4. GENERADOR DE RUTINAS
  Future<String> generarRutina({
    required String carrera,
    required String semestre,
    required List<String> diasLibres,
    required String objetivos,
  }) async {
    final dias = diasLibres.isEmpty ? 'No especificados' : diasLibres.join(', ');
    final prompt = '''
Crea una rutina semanal detallada para un estudiante de $carrera, 
en $semestre semestre de la UNICAH.
Días con más tiempo libre: $dias
Objetivos del estudiante: "$objetivos"

La rutina debe incluir:
1. 📅 Horario día por día (Lunes a Domingo)
2. Bloques de: estudio, ejercicio, descanso, vida social
3. Hábitos específicos para cada día
4. Consejos para mantener la rutina

Hazlo práctico y realista para un universitario hondureño.
Usa emojis y formato claro.
''';
    return await _callGemini(prompt);
  }
}