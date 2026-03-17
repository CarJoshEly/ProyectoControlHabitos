import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'register.dart';

// Colores UNICAH
const _azulOscuro = Color(0xFF003087);
const _azulMedio = Color(0xFF0057B8);
const _dorado = Color(0xFFC8A84B);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _setLoading(bool v) async {
    if (!mounted) return;
    setState(() => _loading = v);
  }

  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'theme': 'light',
        'notificationsEnabled': true,
      });
    } else {
      await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }

  Future<void> loginWithEmail() async {
    if (emailController.text.trim().isEmpty) {
      _showError('Por favor ingresa tu correo electrónico');
      return;
    }
    if (!emailController.text.trim().endsWith('@unicah.edu')) {
      _showError('Solo se permite el correo institucional @unicah.edu');
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      _showError('Por favor ingresa tu contraseña');
      return;
    }

    await _setLoading(true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (credential.user != null) {
        await _createUserDocument(credential.user!);

        // Verificar si el correo está verificado
        if (!credential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          _showError(
              'Debes verificar tu correo @unicah.edu antes de ingresar.');

          // Opción de reenviar el correo
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_unread, color: Color(0xFF003087)),
                  SizedBox(width: 8),
                  Text('Correo no verificado'),
                ],
              ),
              content: const Text(
                '📧 Revisa tu correo institucional @unicah.edu\n\n'
                'Si no lo encuentras en tu bandeja principal:\n'
                '1. Ve a "Correo no deseado" o "Spam"\n'
                '3. Busca el correo de Control Hábitos UNICAH\n'
                '4. Ábrelo y clic en "No es correo no deseado"\n'
                '5. Verifica tu cuenta desde ese correo\n\n'
                '¿Deseas que te reenviemos el correo de verificación?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await credential.user!.sendEmailVerification();
                    if (mounted) {
                      Navigator.pop(context);
                      _showSuccess(
                          'Correo de verificación reenviado a ${credential.user!.email}');
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Reenviar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003087),
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      _showSuccess('¡Bienvenido de vuelta!');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HabitsPage()));
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _showError('Error inesperado: $e');
    } finally {
      await _setLoading(false);
    }
  }

  Future<void> loginWithGoogle() async {
    await _setLoading(true);
    try {
      const webClientID =
          "1058689194132-76at03bp255ipm7d17eh78vrjg2iuvti.apps.googleusercontent.com";
      final GoogleSignIn googleSignIn = GoogleSignIn(clientId: webClientID);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        await _setLoading(false);
        return;
      }
      if (!googleUser.email.endsWith('@unicah.edu')) {
        await googleSignIn.signOut();
        _showError('Solo se permite el correo institucional @unicah.edu');
        await _setLoading(false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null)
        await _createUserDocument(userCredential.user!);
      if (!mounted) return;
      _showSuccess('¡Login con Google exitoso!');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HabitsPage()));
    } catch (e) {
      _showError('Error con Google: $e');
    } finally {
      await _setLoading(false);
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación: $code';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(message))
      ]),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white),
        const SizedBox(width: 8),
        Text(message)
      ]),
      backgroundColor: Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo UNICAH
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_azulOscuro, _azulMedio],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: _azulOscuro.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/profile.jpg',
                        fit: BoxFit.cover,
                        width: 110,
                        height: 110,
                        errorBuilder: (_, __, ___) => const Icon(Icons.school,
                            size: 60, color: _azulOscuro),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Badge UNICAH
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _dorado.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _dorado, width: 1),
                  ),
                  child: const Text(
                    '🎓 UNICAH',
                    style: TextStyle(
                        color: _azulOscuro,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Bienvenido',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _azulOscuro),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 36),

                // Campo Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: _azulMedio),
                    labelText: 'Correo institucional',
                    hintText: 'ejemplo@unicah.edu',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            const BorderSide(color: _azulMedio, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Contraseña
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => loginWithEmail(),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: _azulMedio),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: _azulMedio),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    labelText: 'Contraseña',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            const BorderSide(color: _azulMedio, width: 2)),
                  ),
                ),
                const SizedBox(height: 28),

                // Botón Iniciar Sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _azulOscuro,
                      disabledBackgroundColor: _azulOscuro.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 3,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Iniciar sesión',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),

                // Divisor
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            thickness: 1,
                            endIndent: 10,
                            color: Colors.grey[400])),
                    Text('O continúa con',
                        style: TextStyle(color: Colors.grey[600])),
                    Expanded(
                        child: Divider(
                            thickness: 1, indent: 10, color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 20),

                // Botón Google
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : loginWithGoogle,
                    icon: Image.network(
                      'https://www.gstatic.com/marketing-cms/assets/images/d5/dc/cfe9ce8b4425b410b49b7f2dd3f3/g.webp=s96-fcrop64=1,00000000ffffffff-rw',
                      height: 24,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.g_mobiledata, size: 24),
                    ),
                    label: const Text('Iniciar sesión con Google',
                        style: TextStyle(fontSize: 16, color: _azulOscuro)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      side: const BorderSide(color: _azulOscuro),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Enlace a registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tienes una cuenta? ',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 15)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage())),
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(
                            color: _azulMedio,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
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
}
