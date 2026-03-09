import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_service.dart';

class AIPage extends StatelessWidget {
  const AIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Universitaria'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header UNICAH
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003087), Color(0xFF0057B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎓 Asistente UNICAH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tu compañero inteligente para el éxito universitario',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Qué necesitas hoy?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Tarjetas de módulos
            _buildModuleCard(
              context,
              icon: '🎯',
              title: 'Sugeridor de Hábitos',
              description: 'Recibe hábitos personalizados según tu carrera y situación actual',
              color: const Color(0xFF4CAF50),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HabitSuggesterPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildModuleCard(
              context,
              icon: '📊',
              title: 'Análisis de Productividad',
              description: 'La IA analiza tus hábitos y te da consejos personalizados',
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductivityAnalysisPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildModuleCard(
              context,
              icon: '💬',
              title: 'Chat Motivacional',
              description: 'Habla con tu coach universitario cuando necesites motivación',
              color: const Color(0xFF9C27B0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MotivationalChatPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildModuleCard(
              context,
              icon: '📅',
              title: 'Generador de Rutinas',
              description: 'Crea una rutina semanal personalizada para tu carrera',
              color: const Color(0xFFFF9800),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoutineGeneratorPage()),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// MÓDULO 1: SUGERIDOR DE HÁBITOS
class HabitSuggesterPage extends StatefulWidget {
  const HabitSuggesterPage({super.key});

  @override
  State<HabitSuggesterPage> createState() => _HabitSuggesterPageState();
}

class _HabitSuggesterPageState extends State<HabitSuggesterPage> {
  final _carreraCtrl = TextEditingController();
  final _situacionCtrl = TextEditingController();
  final _service = GeminiService();
  String _resultado = '';
  bool _loading = false;

  final List<String> _carreras = [
    'Ingeniería en Sistemas',
    'Medicina',
    'Derecho',
    'Administración de Empresas',
    'Psicología',
    'Ingeniería Civil',
    'Enfermería',
    'Contaduría',
    'Arquitectura',
    'Otra',
  ];

  @override
  void dispose() {
    _carreraCtrl.dispose();
    _situacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _sugerir() async {
    if (_carreraCtrl.text.isEmpty || _situacionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() { _loading = true; _resultado = ''; });
    final resultado = await _service.sugerirHabitos(
      carrera: _carreraCtrl.text,
      situacion: _situacionCtrl.text,
    );
    setState(() { _resultado = resultado; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Sugeridor de Hábitos'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuéntame sobre ti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tu carrera en UNICAH',
                prefixIcon: const Icon(Icons.school),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _carreras.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => _carreraCtrl.text = v ?? '',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _situacionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe tu situación actual',
                hintText: 'Ej: Tengo parciales la próxima semana, me cuesta concentrarme...',
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _sugerir,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Generando...' : 'Sugerir Hábitos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_resultado.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF4CAF50)),
                        SizedBox(width: 8),
                        Text('Hábitos Sugeridos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_resultado, style: const TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// MÓDULO 2: ANÁLISIS DE PRODUCTIVIDAD
class ProductivityAnalysisPage extends StatefulWidget {
  const ProductivityAnalysisPage({super.key});

  @override
  State<ProductivityAnalysisPage> createState() => _ProductivityAnalysisPageState();
}

class _ProductivityAnalysisPageState extends State<ProductivityAnalysisPage> {
  final _service = GeminiService();
  String _resultado = '';
  bool _loading = false;

  Future<void> _analizar() async {
    setState(() { _loading = true; _resultado = ''; });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();

      final habitos = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? '',
          'progress': data['progress'] ?? 0,
          'streak': data['streak'] ?? 0,
          'bestStreak': data['bestStreak'] ?? 0,
          'frequency': data['frequency'] ?? 'daily',
        };
      }).toList();

      final resultado = await _service.analizarProductividad(habitos: habitos);
      setState(() { _resultado = resultado; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _resultado = 'Error al obtener datos. Intenta de nuevo.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Análisis de Productividad'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Text('📊', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'Análisis Inteligente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'La IA analizará todos tus hábitos registrados y te dará recomendaciones personalizadas',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _analizar,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.analytics),
                label: Text(_loading ? 'Analizando...' : 'Analizar mis Hábitos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_resultado.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights, color: Color(0xFF2196F3)),
                        SizedBox(width: 8),
                        Text('Tu Análisis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_resultado, style: const TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// MÓDULO 3: CHAT MOTIVACIONAL
class MotivationalChatPage extends StatefulWidget {
  const MotivationalChatPage({super.key});

  @override
  State<MotivationalChatPage> createState() => _MotivationalChatPageState();
}

class _MotivationalChatPageState extends State<MotivationalChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _service = GeminiService();
  bool _loading = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': '¡Hola! 👋 Soy tu coach universitario de la UNICAH. Estoy aquí para motivarte y ayudarte. ¿Cómo te sientes hoy? 😊'
    }
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    final historial = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : List<Map<String, String>>.from(_messages);

    final respuesta = await _service.chatMotivacional(
      mensaje: text,
      historial: historial,
    );

    setState(() {
      _messages.add({'role': 'assistant', 'content': respuesta});
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Chat Motivacional'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _loading) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content']!, isUser);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.15),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF9C27B0),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _loading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF9C27B0),
              child: const Text('🤖', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF9C27B0) : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : null,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF9C27B0),
            child: const Text('🤖', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: Color(0xFF9C27B0),
                  ),
                ),
                SizedBox(width: 8),
                Text('Escribiendo...', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MÓDULO 4: GENERADOR DE RUTINAS
class RoutineGeneratorPage extends StatefulWidget {
  const RoutineGeneratorPage({super.key});

  @override
  State<RoutineGeneratorPage> createState() => _RoutineGeneratorPageState();
}

class _RoutineGeneratorPageState extends State<RoutineGeneratorPage> {
  final _carreraCtrl = TextEditingController();
  final _objetivosCtrl = TextEditingController();
  String _semestre = '1er';
  final _service = GeminiService();
  String _resultado = '';
  bool _loading = false;

  final List<String> _semestres = ['1er', '2do', '3er', '4to', '5to', '6to', '7mo', '8vo', '9no', '10mo'];
  final List<String> _carreras = [
    'Ingeniería en Sistemas',
    'Medicina',
    'Derecho',
    'Administración de Empresas',
    'Psicología',
    'Ingeniería Civil',
    'Enfermería',
    'Contaduría',
    'Arquitectura',
    'Otra',
  ];

  final Map<String, bool> _diasLibres = {
    'Lunes': false,
    'Martes': false,
    'Miércoles': false,
    'Jueves': false,
    'Viernes': false,
    'Sábado': true,
    'Domingo': true,
  };

  @override
  void dispose() {
    _carreraCtrl.dispose();
    _objetivosCtrl.dispose();
    super.dispose();
  }

  Future<void> _generar() async {
    if (_carreraCtrl.text.isEmpty || _objetivosCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _loading = true; _resultado = ''; });

    final diasSeleccionados = _diasLibres.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final resultado = await _service.generarRutina(
      carrera: _carreraCtrl.text,
      semestre: _semestre,
      diasLibres: diasSeleccionados,
      objetivos: _objetivosCtrl.text,
    );

    setState(() { _resultado = resultado; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Generador de Rutinas'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tu carrera',
                prefixIcon: const Icon(Icons.school),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _carreras.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => _carreraCtrl.text = v ?? '',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _semestre,
              decoration: InputDecoration(
                labelText: 'Semestre actual',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _semestres.map((s) => DropdownMenuItem(value: s, child: Text('$s semestre'))).toList(),
              onChanged: (v) => setState(() => _semestre = v ?? '1er'),
            ),
            const SizedBox(height: 16),
            const Text('Días con más tiempo libre:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _diasLibres.entries.map((e) {
                return FilterChip(
                  label: Text(e.key),
                  selected: e.value,
                  onSelected: (v) => setState(() => _diasLibres[e.key] = v),
                  selectedColor: const Color(0xFFFF9800).withOpacity(0.3),
                  checkmarkColor: const Color(0xFFFF9800),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _objetivosCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Tus objetivos este semestre',
                hintText: 'Ej: Mejorar mis notas, hacer ejercicio, reducir el estrés...',
                prefixIcon: const Icon(Icons.flag),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generar,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'Generando rutina...' : 'Generar mi Rutina'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_resultado.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month, color: Color(0xFFFF9800)),
                        SizedBox(width: 8),
                        Text('Tu Rutina Semanal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_resultado, style: const TextStyle(fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}