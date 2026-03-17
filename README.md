# Control Hábitos UNICAH 🎓

Aplicación móvil desarrollada en Flutter para estudiantes de la **Universidad Católica de Honduras (UNICAH)**, orientada al control de hábitos académicos y personales con apoyo de Inteligencia Artificial.

## Características
- Registro y control de hábitos diarios, semanales y mensuales
- Calendario de cumplimiento con rachas
- Estadísticas y progreso por hábito
- Notificaciones de recordatorio
- Perfil de usuario con foto
- Modo oscuro/claro
- **Apartado de IA Universitaria:**
  - Sugeridor de hábitos personalizados
  - Análisis de productividad
  - Chat motivacional
  - Generador de rutinas semanales
- Acceso exclusivo con correo institucional `@unicah.edu`
- Verificación de correo al registrarse

---

## Tecnologías
- Flutter / Dart
- Firebase (Auth, Firestore, Storage, Cloud Messaging)
- Gemini API (Google AI)

---

## Configuración para correr el proyecto

Este proyecto requiere archivos de credenciales que **no están incluidos** en el repositorio por seguridad. Debes crearlos manualmente:

### 1. Firebase
Crea tu propio proyecto en [Firebase Console](https://console.firebase.google.com) y ejecuta:
```bash
flutterfire configure
```
Esto generará automáticamente:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 2. firebase_config.dart
Crea el archivo `lib/firebase_config.dart` con tus credenciales de Firebase:
```dart
import 'package:firebase_core/firebase_core.dart';

const firebaseConfig = FirebaseOptions(
  apiKey: "TU_API_KEY",
  authDomain: "TU_PROJECT.firebaseapp.com",
  projectId: "TU_PROJECT_ID",
  storageBucket: "TU_PROJECT.firebasestorage.app",
  messagingSenderId: "TU_SENDER_ID",
  appId: "TU_APP_ID"
);
```

### 3. ai_service.dart
Crea el archivo `lib/ai_service.dart` con tu API key de [Google AI Studio](https://aistudio.google.com):
```dart
static const String _apiKey = 'TU_GEMINI_API_KEY';
```

### 4. Instalar dependencias
```bash
flutter pub get
flutter run
```

---

## Requisitos
- Flutter SDK >= 3.0.0
- Android SDK >= 21
- Cuenta de correo institucional `@unicah.edu` para usar la app

---

## Licencia
Proyecto académico — UNICAH 2026.