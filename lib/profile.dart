import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'login.dart';
import 'theme_provider.dart';
import 'notification_service.dart';

// Colores UNICAH
const _azulOscuro = Color(0xFF003087);
const _azulMedio  = Color(0xFF0057B8);
const _dorado     = Color(0xFFC8A84B);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingProfile = true;
  String? _photoUrl;
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _fs.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _nameCtrl.text = data['displayName'] ?? user.displayName ?? '';
          _photoUrl = data['photoUrl'] ?? user.photoURL;
        });
      }
    } catch (e) {
      // Error silencioso
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 75);
      if (image == null) return;
      setState(() { _loading = true; _localImage = File(image.path); });
      final user = _auth.currentUser;
      if (user == null) { setState(() => _loading = false); return; }
      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();
      await _fs.collection('users').doc(user.uid).update({'photoUrl': downloadUrl});
      await user.updatePhotoURL(downloadUrl);
      if (mounted) {
        setState(() { _photoUrl = downloadUrl; _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Foto de perfil actualizada'), backgroundColor: _azulMedio));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _localImage = null; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar foto'), backgroundColor: Colors.red));
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: const CircleAvatar(backgroundColor: _azulOscuro, child: Icon(Icons.photo_camera, color: Colors.white)),
                title: const Text('Tomar foto'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: _azulMedio, child: Icon(Icons.photo_library, color: Colors.white)),
                title: const Text('Elegir de galería'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _nameCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.edit, color: _azulOscuro), SizedBox(width: 8), Text('Editar nombre')]),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ingresa tu nombre',
            prefixIcon: const Icon(Icons.person, color: _azulMedio),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _azulMedio, width: 2)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: _azulMedio))),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre no puede estar vacío')));
                return;
              }
              Navigator.pop(ctx);
              await _updateName(name);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _azulOscuro, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await _fs.collection('users').doc(user.uid).set({'displayName': name, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      try { await user.updateDisplayName(name); } catch (_) {}
      if (!mounted) return;
      setState(() { _nameCtrl.text = name; _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Nombre actualizado'), backgroundColor: _azulMedio));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar nombre'), backgroundColor: Colors.red));
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
    }
  }

  Future<void> _showPendingNotifications() async {
    try {
      final pendingList = await NotificationService().getPendingNotifications();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(children: [const Icon(Icons.schedule, color: _azulOscuro), const SizedBox(width: 8), Text('Recordatorios (${pendingList.length})')]),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: pendingList.isEmpty
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.notifications_off, size: 48, color: Colors.grey), SizedBox(height: 8), Text('No hay recordatorios programados')]))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: pendingList.length,
                    itemBuilder: (_, i) {
                      final item = pendingList[i];
                      return Card(child: ListTile(leading: const Icon(Icons.alarm, color: _azulMedio), title: Text(item.title ?? 'Sin título'), subtitle: Text(item.body ?? '')));
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await NotificationService().cancelAllNotifications();
                if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todas canceladas'))); }
              },
              child: const Text('Cancelar Todas', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: _azulOscuro),
              child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar recordatorios'), backgroundColor: Colors.red));
    }
  }

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.description, color: _azulOscuro, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Términos y Condiciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('Control Hábitos UNICAH', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _azulOscuro))),
                    const SizedBox(height: 8),
                    Center(child: Text('Última actualización: 2026', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                    const SizedBox(height: 24),
                    _buildSection('1. Aceptación de los términos', 'Al crear una cuenta y utilizar la aplicación Control Hábitos UNICAH, aceptas cumplir estos Términos y Condiciones, así como nuestras políticas de privacidad y uso de datos.'),
                    _buildSection('2. Uso de la aplicación', 'La aplicación está diseñada exclusivamente para estudiantes activos de la UNICAH. Te comprometes a utilizarla de forma responsable para mejorar tus hábitos académicos y personales.'),
                    _buildSection('3. Registro y seguridad de la cuenta', 'Solo se permite el acceso con correo institucional @unicah.edu. Eres responsable de mantener la confidencialidad de tus datos y contraseñas.'),
                    _buildSection('4. Datos y privacidad', 'Los datos que registras sobre tus hábitos se utilizan únicamente para mostrarte estadísticas, rachas y recordatorios dentro de la aplicación. No compartimos tu información personal con nadie más, sin tu consentimiento.'),
                    _buildSection('5. Inteligencia Artificial', 'El apartado de IA procesa texto ingresado por el usuario para generar respuestas personalizadas mediante la API de Gemini de Google. No almacenamos las conversaciones con la IA en nuestra base de datos.'),
                    _buildSection('6. Licencia de uso', 'Se te concede una licencia personal para utilizar la aplicación. No puedes modificar, ni distribuir partes del sistema sin autorización escrita del equipo de desarrollo.'),
                    _buildSection('7. Modificaciones', 'Podemos actualizar estos términos cuando consideremos sea necesario. Se te notificará mediante tu correo institucional.'),
                    _buildSection('8. Contacto', 'Si tienes dudas sobre estos Términos y Condiciones, puedes comunicarte con el equipo de soporte.'),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_azulOscuro, _azulMedio]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🎓 ¡Bienvenido a la comunidad UNICAH!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _azulOscuro)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(ThemeProvider themeProvider, bool value) async {
    final user = _auth.currentUser;
    themeProvider.toggleNotifications(value);
    if (!value) await NotificationService().cancelAllNotifications();
    if (user != null) await _fs.collection('users').doc(user.uid).set({'notificationsEnabled': value}, SetOptions(merge: true));
  }

  Widget _buildPreferencesCard(ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              themeProvider.darkMode ? Icons.dark_mode : Icons.light_mode,
              color: themeProvider.darkMode ? _dorado : _azulMedio,
            ),
            title: const Text('Tema oscuro'),
            subtitle: Text(themeProvider.darkMode ? 'Activado' : 'Desactivado', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            value: themeProvider.darkMode,
            activeColor: _azulOscuro,
            onChanged: (v) => themeProvider.toggleTheme(v),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description, color: _azulOscuro),
            title: const Text('Términos y Condiciones'),
            subtitle: const Text('Políticas de uso y privacidad'),
            trailing: const Icon(Icons.chevron_right, color: _azulMedio),
            onTap: _showTermsAndConditions,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.schedule, color: _dorado),
            title: const Text('Ver Recordatorios'),
            subtitle: const Text('Notificaciones programadas'),
            trailing: const Icon(Icons.chevron_right, color: _azulMedio),
            onTap: _showPendingNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool editable = false, VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _azulOscuro, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          if (editable && onEdit != null)
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, size: 20, color: _azulMedio)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _azulOscuro)));
    }

    final user = _auth.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Foto de perfil
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_azulOscuro, _dorado]),
                    boxShadow: [BoxShadow(color: _azulOscuro.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _localImage != null
                        ? FileImage(_localImage!)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty ? NetworkImage(_photoUrl!) as ImageProvider : null),
                    child: (_localImage == null && (_photoUrl == null || _photoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 70, color: Colors.white)
                        : null,
                  ),
                ),
                if (_loading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _loading ? null : _showImageOptions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _dorado,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: _dorado.withOpacity(0.4), blurRadius: 6)],
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nombre
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _nameCtrl.text.isEmpty ? 'Sin nombre' : _nameCtrl.text,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(onPressed: _showEditNameDialog, icon: const Icon(Icons.edit, color: _azulMedio)),
              ],
            ),

            // Badge correo institucional
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _azulOscuro.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _azulOscuro.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 14, color: _azulOscuro),
                  const SizedBox(width: 4),
                  Text(
                    user?.email ?? 'correo@unicah.edu',
                    style: const TextStyle(fontSize: 14, color: _azulOscuro),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Información de la cuenta
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: _azulOscuro),
                        SizedBox(width: 8),
                        Text('Información de la cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.person, 'Nombre', _nameCtrl.text.isEmpty ? 'No establecido' : _nameCtrl.text, editable: true, onEdit: _showEditNameDialog),
                    const Divider(),
                    _buildInfoRow(Icons.email, 'Correo institucional', user?.email ?? 'No disponible'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Preferencias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            _buildPreferencesCard(themeProvider),
            const SizedBox(height: 32),

            // Botón cerrar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}