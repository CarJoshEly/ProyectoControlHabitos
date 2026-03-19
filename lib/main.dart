import 'ai_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_config.dart';
import 'firestone_service.dart';
import 'login.dart';
import 'profile.dart';
import 'habit_progress_page.dart';
import 'habit_history_page.dart';
import 'theme_provider.dart';
import 'notification_service.dart';
import 'fcm_service.dart';

// ============================================================
// COLORES INSTITUCIONALES UNICAH
// ============================================================
class UnicahColors {
  static const Color azulOscuro = Color(0xFF003087);
  static const Color azulMedio = Color(0xFF0057B8);
  static const Color azulClaro = Color(0xFF4A90D9);
  static const Color dorado = Color(0xFFC8A84B);
  static const Color doradoClaro = Color(0xFFE8C96A);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisClaro = Color(0xFFF5F5F5);
  static const Color grisMedio = Color(0xFFE0E0E0);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // El permiso de batería se pide con delay para evitar que
  // el reinicio que provoca en algunos dispositivos cierre la sesión de Firebase
  Future.delayed(const Duration(seconds: 3), () {
    notificationService.requestBatteryOptimizationPermission();
  });

  final fcmService = FCMService();
  await fcmService.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Control de Hábitos UNICAH',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: UnicahColors.azulOscuro,
              primary: UnicahColors.azulOscuro,
              secondary: UnicahColors.dorado,
              tertiary: UnicahColors.azulMedio,
              background: UnicahColors.grisClaro,
              surface: UnicahColors.blanco,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: UnicahColors.azulOscuro,
              foregroundColor: UnicahColors.blanco,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: UnicahColors.blanco,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: UnicahColors.blanco),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: UnicahColors.dorado,
              foregroundColor: UnicahColors.blanco,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: UnicahColors.azulOscuro,
                foregroundColor: UnicahColors.blanco,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: UnicahColors.azulMedio,
              ),
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return UnicahColors.azulMedio;
                }
                return null;
              }),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: UnicahColors.blanco,
              indicatorColor: UnicahColors.azulOscuro.withOpacity(0.15),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(color: UnicahColors.azulOscuro);
                }
                return const IconThemeData(color: Colors.grey);
              }),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const TextStyle(
                    color: UnicahColors.azulOscuro,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                }
                return const TextStyle(color: Colors.grey, fontSize: 12);
              }),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: UnicahColors.azulMedio, width: 2),
              ),
              labelStyle: const TextStyle(color: UnicahColors.azulOscuro),
            ),
            chipTheme: ChipThemeData(
              selectedColor: UnicahColors.azulOscuro.withOpacity(0.2),
              checkmarkColor: UnicahColors.azulOscuro,
            ),
            cardTheme: CardThemeData(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: UnicahColors.azulMedio,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: UnicahColors.azulMedio,
              primary: UnicahColors.azulMedio,
              secondary: UnicahColors.dorado,
              brightness: Brightness.dark,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900],
              foregroundColor: UnicahColors.blanco,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: const TextStyle(
                color: UnicahColors.blanco,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: UnicahColors.dorado,
              foregroundColor: UnicahColors.blanco,
            ),
            navigationBarTheme: NavigationBarThemeData(
              indicatorColor: UnicahColors.azulMedio.withOpacity(0.3),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const IconThemeData(color: UnicahColors.dorado);
                }
                return const IconThemeData(color: Colors.grey);
              }),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const TextStyle(
                    color: UnicahColors.dorado,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                }
                return const TextStyle(color: Colors.grey, fontSize: 12);
              }),
            ),
          ),
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: UnicahColors.azulOscuro),
                  SizedBox(height: 16),
                  Text('Cargando...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HabitsPage();
        }

        return const LoginPage();
      },
    );
  }
}

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final FirestoneService _service = FirestoneService();
  int _selectedTab = 0;
  DateTime _selectedDate = DateTime.now();

  Future<void> _addHabit() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddHabitDialog(),
    );

    if (result != null) {
      await _service.addHabito(
        result['name'] ?? '',
        result['description'] ?? '',
        result['frequency'] ?? 'daily',
        reminderTime: result['reminderTime'],
        reminderType: result['reminderType'] ?? 'notification',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Hábito creado exitosamente'),
            backgroundColor: UnicahColors.azulMedio,
          ),
        );
      }
    }
  }

  Future<void> _editHabit(String id, Map<String, dynamic> habitData) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EditHabitDialog(habit: habitData),
    );

    if (result != null) {
      await _service.updateHabito(
        id,
        result['name'] ?? '',
        result['description'] ?? '',
        result['frequency'] ?? 'daily',
        reminderTime: result['reminderTime'],
        reminderType: result['reminderType'] ?? 'notification',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Hábito actualizado'),
            backgroundColor: UnicahColors.azulOscuro,
          ),
        );
      }
    }
  }

  Future<void> _deleteHabit(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Hábito'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de eliminar este hábito?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await _service.deleteHabit(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hábito eliminado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewProgress(String habitId, Map<String, dynamic> habitData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HabitProgressPage(habitId: habitId, habitData: habitData),
      ),
    );
  }

  void _viewHistory(String habitId, Map<String, dynamic> habitData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HabitHistoryPage(habitId: habitId, habitData: habitData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hábitos'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: UnicahColors.dorado,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Cambiar tema',
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: _addHabit,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Hábito'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 0:
        return _buildHabitsTab();
      case 1:
        return const StatsPage();
      case 2:
        return const AIPage();
      case 3:
        return const ProfilePage();
      default:
        return _buildHabitsTab();
    }
  }

  Widget _buildHabitsTab() {
    return Column(
      children: [
        _buildCalendar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _service.getHabitsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: UnicahColors.azulOscuro));
              }

              final habits = snapshot.data!.docs;
              if (habits.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_nature,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        '¡Bienvenido!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primer hábito para comenzar',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addHabit,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Hábito'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: habits.length,
                itemBuilder: (context, i) {
                  final doc = habits[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildHabitCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [UnicahColors.azulOscuro, UnicahColors.azulMedio],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: UnicahColors.blanco,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedDate = DateTime.now());
                },
                icon: const Icon(Icons.today,
                    size: 18, color: UnicahColors.dorado),
                label: const Text('Hoy',
                    style: TextStyle(color: UnicahColors.dorado)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = _selectedDate.subtract(Duration(days: 7 - index));
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                final isFuture = date.isAfter(DateTime.now());

                return GestureDetector(
                  onTap: isFuture
                      ? null
                      : () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? UnicahColors.dorado
                          : (isToday
                              ? UnicahColors.blanco.withOpacity(0.2)
                              : null),
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: UnicahColors.dorado, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDayName(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? UnicahColors.azulOscuro
                                : (isFuture
                                    ? UnicahColors.blanco.withOpacity(0.4)
                                    : UnicahColors.blanco.withOpacity(0.8)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? UnicahColors.azulOscuro
                                : (isFuture
                                    ? UnicahColors.blanco.withOpacity(0.4)
                                    : UnicahColors.blanco),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? '';
    final description = data['description'] ?? '';
    final frequency = data['frequency'] ?? 'daily';
    final progress = data['progress'] ?? 0;
    final streak = data['streak'] ?? 0;
    final history = List<dynamic>.from(data['completionHistory'] ?? []);
    final reminderHour = data['reminderHour'];
    final reminderMinute = data['reminderMinute'];

    final isCompletedForSelectedDate =
        _service.isCompletedForDate(history, _selectedDate);
    final hasReminder = reminderHour != null && reminderMinute != null;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('¿Eliminar hábito?'),
            content: Text('¿Deseas eliminar "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _service.deleteHabit(id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isCompletedForSelectedDate ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isCompletedForSelectedDate
              ? const BorderSide(color: UnicahColors.azulMedio, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _viewProgress(id, data),
          onLongPress: () => _editHabit(id, data),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: isCompletedForSelectedDate,
                        onChanged: (v) async {
                          await _service.toggleHabitCompletedForDate(
                            id,
                            v ?? false,
                            _selectedDate,
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        activeColor: UnicahColors.azulMedio,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    decoration: isCompletedForSelectedDate
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: isCompletedForSelectedDate
                                        ? Colors.grey
                                        : null,
                                  ),
                                ),
                              ),
                              if (hasReminder)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: UnicahColors.azulOscuro
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.notifications_active,
                                          size: 14,
                                          color: UnicahColors.azulMedio),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: UnicahColors.azulMedio),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                description,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editHabit(id, data);
                            break;
                          case 'progress':
                            _viewProgress(id, data);
                            break;
                          case 'history':
                            _viewHistory(id, data);
                            break;
                          case 'delete':
                            _deleteHabit(id);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Editar')
                            ])),
                        const PopupMenuItem(
                            value: 'progress',
                            child: Row(children: [
                              Icon(Icons.show_chart, size: 20),
                              SizedBox(width: 12),
                              Text('Ver Progreso')
                            ])),
                        const PopupMenuItem(
                            value: 'history',
                            child: Row(children: [
                              Icon(Icons.history, size: 20),
                              SizedBox(width: 12),
                              Text('Ver Historial')
                            ])),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Eliminar',
                                  style: TextStyle(color: Colors.red))
                            ])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(Icons.local_fire_department, '$streak días',
                        Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatChip(Icons.check_circle, '$progress total',
                        UnicahColors.azulMedio),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: UnicahColors.dorado.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getFrequencyLabel(frequency),
                        style: const TextStyle(
                            fontSize: 12,
                            color: UnicahColors.azulOscuro,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day} de ${_getMonthName(date.month)} ${date.year}';

  String _getDayName(DateTime date) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _getFrequencyLabel(String freq) {
    switch (freq) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      default:
        return freq;
    }
  }
}

// ============================================================
// DIÁLOGO AGREGAR HÁBITO
// ============================================================
class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  String selectedFrequency = 'daily';
  String _reminderType = 'notification';
  TimeOfDay? reminderTime;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.add_circle, color: UnicahColors.azulOscuro),
          SizedBox(width: 8),
          Text('Nuevo Hábito'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre del Hábito *',
                hintText: 'Ej. Estudiar para parciales',
                prefixIcon: const Icon(Icons.edit),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Ej. Repasar apuntes 1 hora',
                prefixIcon: const Icon(Icons.description),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedFrequency,
              decoration: InputDecoration(
                labelText: 'Frecuencia',
                prefixIcon: const Icon(Icons.repeat),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('📅 Diario')),
                DropdownMenuItem(value: 'weekly', child: Text('📆 Semanal')),
                DropdownMenuItem(value: 'monthly', child: Text('🗓️ Mensual')),
              ],
              onChanged: (v) =>
                  setState(() => selectedFrequency = v ?? 'daily'),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  reminderTime != null
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: reminderTime != null
                      ? UnicahColors.azulOscuro
                      : Colors.grey,
                ),
                title: Text(
                  reminderTime != null
                      ? 'Recordatorio: ${reminderTime!.format(context)}'
                      : 'Agregar recordatorio',
                  style: TextStyle(
                      color: reminderTime != null
                          ? UnicahColors.azulOscuro
                          : Colors.grey[700]),
                ),
                trailing: reminderTime != null
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => reminderTime = null))
                    : const Icon(Icons.chevron_right),
                onTap: _selectTime,
              ),
            ),
            if (reminderTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _reminderType = 'notification'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _reminderType == 'notification'
                              ? const Color(0xFF003087)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF003087)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.notifications,
                                color: _reminderType == 'notification'
                                    ? Colors.white
                                    : const Color(0xFF003087)),
                            Text('Notificación',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _reminderType == 'notification'
                                      ? Colors.white
                                      : const Color(0xFF003087),
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _reminderType = 'alarm'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _reminderType == 'alarm'
                              ? const Color(0xFFC8A84B)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC8A84B)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.alarm,
                                color: _reminderType == 'alarm'
                                    ? Colors.white
                                    : const Color(0xFFC8A84B)),
                            Text('Alarma',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _reminderType == 'alarm'
                                      ? Colors.white
                                      : const Color(0xFFC8A84B),
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton.icon(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('El nombre es requerido'),
                  backgroundColor: Colors.orange));
              return;
            }
            Navigator.pop(context, {
              'name': nameCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'frequency': selectedFrequency,
              'reminderTime': reminderTime,
              'reminderType': _reminderType,
            });
          },
          icon: const Icon(Icons.check),
          label: const Text('Crear'),
        ),
      ],
    );
  }
}

// ============================================================
// DIÁLOGO EDITAR HÁBITO
// ============================================================
class EditHabitDialog extends StatefulWidget {
  final Map<String, dynamic> habit;
  const EditHabitDialog({super.key, required this.habit});

  @override
  State<EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<EditHabitDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late String selectedFrequency;
  String _reminderType = 'notification';
  TimeOfDay? reminderTime;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.habit['name']);
    descCtrl = TextEditingController(text: widget.habit['description']);
    selectedFrequency = widget.habit['frequency'] ?? 'daily';
    _reminderType = widget.habit['reminderType'] ?? 'notification';
    final hour = widget.habit['reminderHour'];
    final minute = widget.habit['reminderMinute'];
    if (hour != null && minute != null) {
      reminderTime = TimeOfDay(hour: hour, minute: minute);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.edit, color: UnicahColors.azulMedio),
          SizedBox(width: 8),
          Text('Editar Hábito'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre del Hábito',
                prefixIcon: const Icon(Icons.edit),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Descripción',
                prefixIcon: const Icon(Icons.description),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedFrequency,
              decoration: InputDecoration(
                labelText: 'Frecuencia',
                prefixIcon: const Icon(Icons.repeat),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('📅 Diario')),
                DropdownMenuItem(value: 'weekly', child: Text('📆 Semanal')),
                DropdownMenuItem(value: 'monthly', child: Text('🗓️ Mensual')),
              ],
              onChanged: (v) =>
                  setState(() => selectedFrequency = v ?? 'daily'),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  reminderTime != null
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: reminderTime != null
                      ? UnicahColors.azulOscuro
                      : Colors.grey,
                ),
                title: Text(reminderTime != null
                    ? 'Recordatorio: ${reminderTime!.format(context)}'
                    : 'Sin recordatorio'),
                trailing: reminderTime != null
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => reminderTime = null))
                    : const Icon(Icons.chevron_right),
                onTap: _selectTime,
              ),
            ),
            if (reminderTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _reminderType = 'notification'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _reminderType == 'notification'
                              ? const Color(0xFF003087)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF003087)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.notifications,
                                color: _reminderType == 'notification'
                                    ? Colors.white
                                    : const Color(0xFF003087)),
                            Text('Notificación',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _reminderType == 'notification'
                                      ? Colors.white
                                      : const Color(0xFF003087),
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _reminderType = 'alarm'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _reminderType == 'alarm'
                              ? const Color(0xFFC8A84B)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC8A84B)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.alarm,
                                color: _reminderType == 'alarm'
                                    ? Colors.white
                                    : const Color(0xFFC8A84B)),
                            Text('Alarma',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _reminderType == 'alarm'
                                      ? Colors.white
                                      : const Color(0xFFC8A84B),
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton.icon(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El nombre es requerido')),
              );
              return;
            }
            Navigator.pop(context, {
              'name': nameCtrl.text.trim(),
              'description': descCtrl.text.trim(),
              'frequency': selectedFrequency,
              'reminderTime': reminderTime,
              'reminderType': _reminderType,
            });
          },
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text('Guardar',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: UnicahColors.azulOscuro,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PÁGINA DE ESTADÍSTICAS
// ============================================================
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoneService();

    return StreamBuilder<QuerySnapshot>(
      stream: service.getHabitsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: UnicahColors.azulOscuro));
        }

        final habits = snapshot.data!.docs;
        int totalHabits = habits.length;
        int totalCompleted = 0;
        int totalStreak = 0;
        int bestStreak = 0;

        for (var doc in habits) {
          final data = doc.data() as Map<String, dynamic>;
          totalCompleted += (data['progress'] ?? 0) as int;
          totalStreak += (data['streak'] ?? 0) as int;
          final habitBest = (data['bestStreak'] ?? 0) as int;
          if (habitBest > bestStreak) bestStreak = habitBest;
        }

        if (totalHabits == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('Sin estadísticas',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Crea hábitos para ver tus estadísticas',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [UnicahColors.azulOscuro, UnicahColors.azulMedio],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.school, color: UnicahColors.dorado, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Tu Progreso UNICAH',
                      style: TextStyle(
                          color: UnicahColors.blanco,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Resumen General',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard('Hábitos Activos', '$totalHabits',
                          Icons.favorite, UnicahColors.azulOscuro)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatCard(
                          'Total Completados',
                          '$totalCompleted',
                          Icons.check_circle,
                          UnicahColors.azulMedio)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                          'Racha Combinada',
                          '$totalStreak días',
                          Icons.local_fire_department,
                          Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildStatCard('Mejor Racha', '$bestStreak días',
                          Icons.emoji_events, UnicahColors.dorado)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Progreso por Hábito',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...habits.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? '';
                final progress = data['progress'] ?? 0;
                final streak = data['streak'] ?? 0;
                final bestHabitStreak = data['bestStreak'] ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                        color: UnicahColors.grisMedio, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat(Icons.check, '$progress', 'Total',
                                UnicahColors.azulMedio),
                            _buildMiniStat(Icons.local_fire_department,
                                '$streak', 'Racha', Colors.orange),
                            _buildMiniStat(
                                Icons.emoji_events,
                                '$bestHabitStreak',
                                'Mejor',
                                UnicahColors.dorado),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}