import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

const _darkPanel = Color(0xFF16212B);
const _darkField = Color(0xFF1E2C38);
const _accent = Color(0xFFCBFF3D);

/// Pantalla de inicio de sesión.
///
/// Solo los usuarios con rol 'admin' tienen email y contraseña en el
/// backend, por lo que esta pantalla es exclusiva para administradores.
///
/// Al autenticarse exitosamente, el AuthProvider almacena el JWT y
/// main.dart redirige automáticamente al AppShell de la aplicación.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.limpiarError();

    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al iniciar sesión'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B26),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: isWide ? _buildWideLayout(auth) : _buildNarrowLayout(auth),
        ),
      ),
    );
  }

  /// Layout para pantallas anchas: panel izquierdo decorativo + formulario derecho.
  Widget _buildWideLayout(AuthProvider auth) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 520),
      child: Row(
        children: [
          // Panel decorativo izquierdo
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(-5, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Agua\nEl Montecito',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sistema de gestión de flotilla de pipas de agua',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Panel del formulario
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: _darkPanel,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: _buildForm(auth),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout para pantallas angostas: formulario centrado.
  Widget _buildNarrowLayout(AuthProvider auth) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(
          color: _darkPanel,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo compacto
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Agua El Montecito',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
            _buildForm(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Iniciar sesión',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa tus credenciales de administrador',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),

          // Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              label: 'Correo electrónico',
              icon: Icons.email_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@')) return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _ocultarPassword,
            style: const TextStyle(color: Colors.white),
            decoration:
                _inputDecoration(
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarPassword = !_ocultarPassword),
                  ),
                ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              return null;
            },
            onFieldSubmitted: (_) => _iniciarSesion(),
          ),
          const SizedBox(height: 28),

          // Botón de login
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              onPressed: auth.cargando ? null : _iniciarSesion,
              child: auth.cargando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : const Text('Entrar'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: _darkField,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
      errorStyle: const TextStyle(color: AppColors.danger),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
