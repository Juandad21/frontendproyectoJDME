import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CalendarioPage extends StatefulWidget {
  final bool isLoggedIn;
  final bool isAdmin;
  final String? token;

  const CalendarioPage({
    super.key,
    required this.isLoggedIn,
    this.isAdmin = false,
    this.token,
  });

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  List<dynamic> eventos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    try {
      final data = await ApiService.getEventos();
      if (!mounted) return;                          // ← guard
      setState(() {
        eventos = data;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;                          // ← guard
      setState(() => cargando = false);
      _mostrarError('Error al cargar eventos');
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _campo(TextEditingController ctrl, String label, {bool numero = false, int maxLines = 1}) {
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
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
        ),
      ),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? evento}) {
    final nombreCtrl      = TextEditingController(text: evento?['nombre'] ?? '');
    final lugarCtrl       = TextEditingController(text: evento?['lugar'] ?? '');
    final fechaCtrl       = TextEditingController(text: evento?['fecha'] ?? '');
    final aforoCtrl       = TextEditingController(text: evento?['aforo']?.toString() ?? '');
    final precioCtrl      = TextEditingController(text: evento?['precio']?.toString() ?? '');
    final descripcionCtrl = TextEditingController(text: evento?['descripcion'] ?? '');
    final horaInicioCtrl  = TextEditingController(text: evento?['horaInicio'] ?? '');
    final horaFinCtrl     = TextEditingController(text: evento?['horaFinalizacion'] ?? '');
    final reservaCtrl     = TextEditingController(text: evento?['numeroReserva']?.toString() ?? '');

    bool estado = evento?['estado'] ?? true;
    int? etiquetaSeleccionada = evento?['etiqueta'];

    final etiquetas = [
      {'id': 1, 'nombre': 'Danza'},
      {'id': 2, 'nombre': 'Música'},
      {'id': 3, 'nombre': 'Pintura'},
      {'id': 4, 'nombre': 'Teatro'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (modalContext, setModalState) => Padding(  // ← usa modalContext, no context
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  evento == null ? 'Nuevo Evento' : 'Editar Evento',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                ),
                const SizedBox(height: 16),

                _campo(nombreCtrl,      'Nombre'),
                _campo(lugarCtrl,       'Lugar'),
                _campo(fechaCtrl,       'Fecha (YYYY-MM-DD)'),
                _campo(aforoCtrl,       'Aforo',             numero: true),
                _campo(precioCtrl,      'Precio',            numero: true),
                _campo(reservaCtrl,     'Número de Reserva', numero: true),
                _campo(horaInicioCtrl,  'Hora Inicio (HH:MM)'),
                _campo(horaFinCtrl,     'Hora Finalización (HH:MM)'),
                _campo(descripcionCtrl, 'Descripción (opcional)', maxLines: 3),

                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: etiquetaSeleccionada,
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amberAccent)),
                  ),
                  items: etiquetas.map((e) => DropdownMenuItem<int>(
                    value: e['id'] as int,
                    child: Text(e['nombre'] as String),
                  )).toList(),
                  onChanged: (val) => setModalState(() => etiquetaSeleccionada = val),
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estado (activo)', style: TextStyle(color: Colors.white70)),
                    Switch(
                      value: estado,
                      activeThumbColor: Colors.amberAccent,
                      onChanged: (val) => setModalState(() => estado = val),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final nombre     = nombreCtrl.text.trim();
                    final lugar      = lugarCtrl.text.trim();
                    final fecha      = fechaCtrl.text.trim();
                    final horaInicio = horaInicioCtrl.text.trim();
                    final horaFin    = horaFinCtrl.text.trim();
                    final aforo      = int.tryParse(aforoCtrl.text.trim());
                    final precio     = double.tryParse(precioCtrl.text.trim());
                    final reserva    = int.tryParse(reservaCtrl.text.trim());
                    final horaRegex  = RegExp(r'^\d{2}:\d{2}$');
                    final fechaRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

                    if (nombre.isEmpty)                        { _mostrarError('El nombre es obligatorio'); return; }
                    if (lugar.isEmpty)                         { _mostrarError('El lugar es obligatorio'); return; }
                    if (!fechaRegex.hasMatch(fecha))           { _mostrarError('Fecha: formato YYYY-MM-DD'); return; }
                    if (aforo == null || aforo <= 0)           { _mostrarError('Aforo debe ser mayor a 0'); return; }
                    if (precio == null || precio < 0)          { _mostrarError('Precio no válido'); return; }
                    if (reserva == null || reserva < 0)        { _mostrarError('Número de reserva no válido'); return; }
                    if (!horaRegex.hasMatch(horaInicio))       { _mostrarError('Hora inicio: formato HH:MM'); return; }
                    if (!horaRegex.hasMatch(horaFin))          { _mostrarError('Hora fin: formato HH:MM'); return; }
                    if (horaFin.compareTo(horaInicio) <= 0)    { _mostrarError('La hora fin debe ser mayor a la hora inicio'); return; }
                    if (etiquetaSeleccionada == null)           { _mostrarError('Selecciona una etiqueta'); return; }

                    final data = {
                      'nombre':           nombre,
                      'lugar':            lugar,
                      'fecha':            fecha,
                      'aforo':            aforo,
                      'precio':           precio,
                      'descripcion':      descripcionCtrl.text.trim(),
                      'estado':           estado,
                      'horaInicio':       horaInicio,
                      'horaFinalizacion': horaFin,
                      'numeroReserva':    reserva,
                      'etiqueta':         etiquetaSeleccionada,
                    };

                    try {
                      if (evento == null) {
                        await ApiService.crearEvento(data, widget.token!);
                      } else {
                        await ApiService.editarEvento(evento['id'], data, widget.token!);
                      }
                      if (!mounted) return;                    // ← guard
                      Navigator.pop(modalContext);             // ← usa modalContext
                      _cargarEventos();
                    } catch (e) {
                      if (!mounted) return;                    // ← guard
                      _mostrarError('Error al guardar evento');
                    }
                  },
                  child: Text(evento == null ? 'Crear' : 'Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarEvento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar evento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.eliminarEvento(id, widget.token!);
      if (!mounted) return;                                    // ← guard
      _cargarEventos();
    } catch (e) {
      if (!mounted) return;                                    // ← guard
      _mostrarError('Error al eliminar evento');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calendario de Eventos")),
      body: Stack(
        children: [
          cargando
              ? const Center(child: CircularProgressIndicator())
              : eventos.isEmpty
                  ? const Center(child: Text('No hay eventos registrados.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: eventos.length,
                      itemBuilder: (_, i) {
                        final e = eventos[i];
                        return Card(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: ListTile(
                            title: Text(e['nombre'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '📍 ${e['lugar'] ?? ''}   📅 ${e['fecha'] ?? ''}\n'
                              '🎟 Aforo: ${e['aforo'] ?? '-'}   💲 ${e['precio'] ?? '-'}',
                            ),
                            isThreeLine: true,
                            trailing: widget.isAdmin
                                ? PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'editar')    _abrirFormulario(evento: e);
                                      if (val == 'eliminar')  _eliminarEvento(e['id']);
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'editar',   child: Text('✏️ Editar')),
                                      PopupMenuItem(value: 'eliminar', child: Text('🗑️ Eliminar')),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
          if (widget.isLoggedIn && widget.isAdmin)
            Positioned(
              bottom: 24, right: 24,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add_card),
                label: const Text("Nuevo Evento"),
              ),
            ),
        ],
      ),
    );
  }
}