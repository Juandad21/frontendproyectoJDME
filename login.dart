import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginDialog extends StatefulWidget {
  final void Function(String token, Map<String, dynamic> usuario) onLoginSuccess;
  const LoginDialog({super.key, required this.onLoginSuccess});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}


class _LoginDialogState extends State<LoginDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login
  final TextEditingController _correoCtrl    = TextEditingController();
  final TextEditingController _passwordCtrl  = TextEditingController();

  // Registro
  final TextEditingController _regUsernameCtrl   = TextEditingController();
  final TextEditingController _regCorreoCtrl     = TextEditingController();
  final TextEditingController _regPasswordCtrl   = TextEditingController();
  final TextEditingController _regNombreCtrl     = TextEditingController();
  final TextEditingController _regApellidoCtrl   = TextEditingController();
  final TextEditingController _regEdadCtrl       = TextEditingController();
  final TextEditingController _regCedulaCtrl     = TextEditingController();
  final TextEditingController _regTelefonoCtrl   = TextEditingController();

  bool _obscureLogin    = true;
  bool _obscureReg      = true;
  bool _isLoading       = false;
  String? _errorMsg;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMsg = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _correoCtrl.dispose();   _passwordCtrl.dispose();
    _regUsernameCtrl.dispose(); _regCorreoCtrl.dispose();
    _regPasswordCtrl.dispose(); _regNombreCtrl.dispose();
    _regApellidoCtrl.dispose(); _regEdadCtrl.dispose();
    _regCedulaCtrl.dispose();   _regTelefonoCtrl.dispose();
    super.dispose();
  }

  String? _validarLogin() {
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_correoCtrl.text.trim())) return 'Correo inválido';
    if (_passwordCtrl.text.isEmpty) return 'La contraseña es obligatoria';
    return null;
  }

  String? _validarRegistro() {
    if (_regNombreCtrl.text.trim().isEmpty) return 'El nombre es obligatorio';
    if (_regApellidoCtrl.text.trim().isEmpty) return 'El apellido es obligatorio';
    if (_regUsernameCtrl.text.trim().isEmpty) return 'El username es obligatorio';

    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(_regCorreoCtrl.text.trim())) return 'Correo inválido';

    final edad = int.tryParse(_regEdadCtrl.text);
    if (edad == null || edad < 1 || edad > 120) return 'Edad inválida';

    final cedula = int.tryParse(_regCedulaCtrl.text);
    if (cedula == null || _regCedulaCtrl.text.length < 6) return 'Cédula inválida';

    if (_regTelefonoCtrl.text.length < 10) return 'Teléfono inválido';
    if (_regPasswordCtrl.text.length < 8) return 'La contraseña debe tener mínimo 8 caracteres';

    return null;
  }


  // ── LOGIN ──────────────────────────────────────────
  Future<void> _handleLogin() async {
    final String? loginError = _validarLogin();
    if (loginError != null) {
      setState(() => _errorMsg = loginError);
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final data = await ApiService.login(
        _correoCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      widget.onLoginSuccess(data['access'], data['usuario']);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMsg = 'Correo o contraseña incorrectos');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── REGISTRO ───────────────────────────────────────
  Future<void> _handleRegistro() async {
    final String? registroError = _validarRegistro();
    if (registroError != null) {
      setState(() => _errorMsg = registroError);
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await ApiService.registrar({
        'username':   _regUsernameCtrl.text.trim(),
        'email':      _regCorreoCtrl.text.trim(),
        'password':   _regPasswordCtrl.text,
        'first_name': _regNombreCtrl.text.trim(),
        'last_name':  _regApellidoCtrl.text.trim(),
        'edad':       int.tryParse(_regEdadCtrl.text) ?? 0,
        'cedula':     int.tryParse(_regCedulaCtrl.text) ?? 0,
        'telefono':   _regTelefonoCtrl.text.trim(),
      });
      if (!mounted) return;
      // Después de registrar, ir al tab de login
      _tabController.animateTo(0);
      setState(() => _errorMsg = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso, inicia sesión'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _errorMsg = 'Error al registrarse, verifica los datos');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.amberAccent,
                labelColor: Colors.amberAccent,
                unselectedLabelColor: Colors.white60,
                tabs: const [Tab(text: "Iniciar Sesión"), Tab(text: "Registrarse")],
              ),
              const SizedBox(height: 16),

              // Error
              if (_errorMsg != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                    ],
                  ),
                ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── TAB LOGIN ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("¡Bienvenido!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        _buildField(controller: _correoCtrl, label: "Correo", icon: Icons.email_outlined),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _passwordCtrl,
                          label: "Contraseña",
                          icon: Icons.lock_outline,
                          obscure: _obscureLogin,
                          toggleObscure: () => setState(() => _obscureLogin = !_obscureLogin),
                        ),
                        const SizedBox(height: 24),
                        _buildButton("INGRESAR", _isLoading ? null : _handleLogin),
                      ],
                    ),

                    // ── TAB REGISTRO ──
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text("Crear cuenta", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildField(controller: _regNombreCtrl,   label: "Nombre",    icon: Icons.person_outline),
                          const SizedBox(height: 12),
                          _buildField(controller: _regApellidoCtrl, label: "Apellido",  icon: Icons.person_outline),
                          const SizedBox(height: 12),
                          _buildField(controller: _regUsernameCtrl, label: "Username",  icon: Icons.alternate_email),
                          const SizedBox(height: 12),
                          _buildField(controller: _regCorreoCtrl,   label: "Correo",    icon: Icons.email_outlined),
                          const SizedBox(height: 12),
                          _buildField(controller: _regEdadCtrl,     label: "Edad",      icon: Icons.cake_outlined,    keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildField(controller: _regCedulaCtrl,   label: "Cédula",    icon: Icons.badge_outlined,   keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildField(controller: _regTelefonoCtrl, label: "Teléfono",  icon: Icons.phone_outlined,   keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _buildField(
                            controller: _regPasswordCtrl,
                            label: "Contraseña",
                            icon: Icons.lock_outline,
                            obscure: _obscureReg,
                            toggleObscure: () => setState(() => _obscureReg = !_obscureReg),
                          ),
                          const SizedBox(height: 24),
                          _buildButton("REGISTRARSE", _isLoading ? null : _handleRegistro),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback? onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amberAccent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: onPressed,
      child: _isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}