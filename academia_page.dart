import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AcademiasPage extends StatefulWidget {
  final bool isLoggedIn;
  final bool isAdmin;
  final String? token;

  const AcademiasPage({
    super.key,
    required this.isLoggedIn,
    this.isAdmin = false,
    this.token,
  });

  @override
  State<AcademiasPage> createState() => _AcademiasPageState();
}

class _AcademiasPageState extends State<AcademiasPage> {
  List<dynamic> academias = [];
  bool cargando = true;

  final etiquetas = [
    {'id': 1, 'nombre': 'Danza'},
    {'id': 2, 'nombre': 'Música'},
    {'id': 3, 'nombre': 'Pintura'},
    {'id': 4, 'nombre': 'Teatro'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarAcademias();
  }

  Future<void> _cargarAcademias() async {
    try {
      final data = await ApiService.getAcademias();
      if (!mounted) return;
      setState(() {
        academias = data;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
      _mostrarError('Error al cargar academias');
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _campo(TextEditingController ctrl, String label,
      {bool numero = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.amberAccent)),
        ),
      ),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? academia}) {
    final nombreCtrl   = TextEditingController(text: academia?['nombre'] ?? '');
    final ubicCtrl     = TextEditingController(text: academia?['ubicacion'] ?? '');
    final contactoCtrl = TextEditingController(text: academia?['numeroContacto']?.toString() ?? '');
    final correoCtrl   = TextEditingController(text: academia?['correo'] ?? '');
    final nitCtrl      = TextEditingController(text: academia?['nit']?.toString() ?? '');
    int? etiquetaSeleccionada = academia?['etiqueta'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (modalContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  academia == null ? 'Nueva Academia' : 'Editar Academia',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent),
                ),
                const SizedBox(height: 16),

                _campo(nombreCtrl,   'Nombre'),
                _campo(ubicCtrl,     'Ubicación'),
                _campo(contactoCtrl, 'Número de Contacto', numero: true),
                _campo(correoCtrl,   'Correo'),
                _campo(nitCtrl,      'NIT (opcional)',      numero: true),

                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: etiquetaSeleccionada,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amberAccent)),
                  ),
                  items: etiquetas
                      .map((e) => DropdownMenuItem<int>(
                            value: e['id'] as int,
                            child: Text(e['nombre'] as String),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => etiquetaSeleccionada = val),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final nombre   = nombreCtrl.text.trim();
                    final ubic     = ubicCtrl.text.trim();
                    final contacto = int.tryParse(contactoCtrl.text.trim());
                    final correo   = correoCtrl.text.trim();
                    final nit      = int.tryParse(nitCtrl.text.trim());
                    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

                    if (nombre.isEmpty)              { _mostrarError('El nombre es obligatorio'); return; }
                    if (ubic.isEmpty)                { _mostrarError('La ubicación es obligatoria'); return; }
                    if (contacto == null)            { _mostrarError('Número de contacto no válido'); return; }
                    if (!emailRegex.hasMatch(correo)){ _mostrarError('Correo no válido'); return; }
                    if (etiquetaSeleccionada == null){ _mostrarError('Selecciona una etiqueta'); return; }

                    final data = {
                      'nombre':          nombre,
                      'ubicacion':       ubic,
                      'numeroContacto':  contacto,
                      'correo':          correo,
                      'nit':             nit,
                      'etiqueta':        etiquetaSeleccionada,
                    };

                    try {
                      if (academia == null) {
                        await ApiService.crearAcademia(data, widget.token!);
                      } else {
                        await ApiService.editarAcademia(academia['id'], data, widget.token!);
                      }
                      if (!mounted) return;
                      Navigator.pop(modalContext);
                      _cargarAcademias();
                    } catch (e) {
                      if (!mounted) return;
                      _mostrarError('Error al guardar academia');
                    }
                  },
                  child: Text(academia == null ? 'Crear' : 'Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarAcademia(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar academia?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.eliminarAcademia(id, widget.token!);
      if (!mounted) return;
      _cargarAcademias();
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error al eliminar academia');
    }
  }

  String _nombreEtiqueta(int? id) {
    final e = etiquetas.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {'nombre': 'Sin etiqueta'},
    );
    return e['nombre'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academias Culturales')),
      body: Stack(
        children: [
          cargando
              ? const Center(child: CircularProgressIndicator())
              : academias.isEmpty
                  ? const Center(child: Text('No hay academias registradas.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: academias.length,
                      itemBuilder: (_, i) {
                        final a = academias[i];
                        return Card(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: ListTile(
                            leading: const Icon(Icons.school_outlined,
                                color: Colors.amberAccent),
                            title: Text(a['nombre'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '📍 ${a['ubicacion'] ?? ''}   📞 ${a['numeroContacto'] ?? ''}\n'
                              '✉️ ${a['correo'] ?? ''}   🏷️ ${_nombreEtiqueta(a['etiqueta'])}',
                            ),
                            isThreeLine: true,
                            trailing: widget.isAdmin
                                ? PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'editar'){
                                        _abrirFormulario(academia: a);
                                      }
                                      if (val == 'eliminar'){
                                        _eliminarAcademia(a['id']);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'editar',
                                          child: Text('✏️ Editar')),
                                      PopupMenuItem(
                                          value: 'eliminar',
                                          child: Text('🗑️ Eliminar')),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
          if (widget.isLoggedIn && widget.isAdmin)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add_business),
                label: const Text('Nueva Academia'),
              ),
            ),
        ],
      ),
    );
  }
}