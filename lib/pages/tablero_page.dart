import 'academia_page.dart'; // arriba del archivo
import 'dart:ui';
import 'package:flutter/material.dart';
import 'mapa_page.dart';
import 'calendario_page.dart';
import '../widgets/login.dart';


class TableroInteractivoPage extends StatelessWidget {
  final bool isAdmin;
  final bool isLoggedIn;
  final String? token;
  final void Function(bool, {String? token, bool? isAdmin}) onLoginChanged;

  const TableroInteractivoPage({
    super.key,
    required this.isLoggedIn,
    required this.onLoginChanged,
    this.isAdmin = false,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondo.jpeg'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
          ),
          // Desenfoque
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          // Contenido
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "GIRARDOT SUENA A ARTE",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoggedIn
                        ? "Modo Administrador / Gestor Cultural Activo 🛠️"
                        : "Gestionando y promoviendo nuestra riqueza cultural",
                    style: TextStyle(fontSize: 16, color: isLoggedIn ? Colors.amberAccent : Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                      children: [
                        _buildMenuCard(
                          icon: Icons.map_outlined,
                          title: "Mapa",
                          description: "Explora los puntos clave, rutas históricas y ubicación de los centros culturales.",
                          onTap: () => Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (_) => MapaPage(
                                isLoggedIn: isLoggedIn,
                                isAdmin: isAdmin,
                              )
                            ),
                        )),

                        _buildMenuCard(
                          icon: Icons.calendar_month_outlined,
                          title: "Calendario",
                          description: "Mantente al día con los eventos, talleres y festividades locales.",
                          onTap: () => Navigator.push(context,
                           MaterialPageRoute(
                            builder: (_) => CalendarioPage(
                              isLoggedIn: isLoggedIn,
                              isAdmin: isAdmin,
                              token: token,
                            )
                          )),
                        ),
                        _buildMenuCard(
                          icon: Icons.history_edu_outlined,
                          title: "Historia",
                          description: "Viaja en el tiempo y descubre la evolución, el legado del río y nuestra identidad.",
                          onTap: () {},
                        ),
                        _buildMenuCard(
                          icon: Icons.school_outlined,
                          title: "Academias",
                          description: "Conoce los espacios de formación artística disponibles.",
                          onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AcademiasPage(
                                      isLoggedIn: isLoggedIn,
                                      isAdmin: isAdmin,
                                      token: token,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón Login / Logout
          Positioned(
            left: 24,
            bottom: 24,
            child: OutlinedButton.icon(
              onPressed: () {
                if (isLoggedIn) {
                  onLoginChanged(false,token: null, isAdmin: false);
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => LoginDialog(
                      onLoginSuccess: (token, usuario) {
                        onLoginChanged(true, token: token, isAdmin: usuario['is_staff'] ?? false);
                        // Guarda el token si lo necesitas después
                      },
                    ),
                  );
                }
              },
              icon: Icon(isLoggedIn ? Icons.logout : Icons.account_circle_outlined, color: Colors.white),
              label: Text(
                isLoggedIn ? "Cerrar Sesión" : "Iniciar Sesión / Registro",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isLoggedIn ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white30, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 14, color: Colors.white70), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}