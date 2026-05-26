import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

// ── Modelos locales ───────────────────────────────
class PuntoMapa {
  final String nombre;
  final String descripcion;
  final LatLng posicion;
  final TipoPunto tipo;

  const PuntoMapa({
    required this.nombre,
    required this.descripcion,
    required this.posicion,
    required this.tipo,
  });
}

enum TipoPunto { academia, historico, evento }

// ── Datos fijos ───────────────────────────────────
const LatLng _centroGirardot = LatLng(4.3041, -74.8017);

const List<PuntoMapa> _puntosHistoricos = [
  PuntoMapa(
    nombre: 'Puente de Hierro',
    descripcion: 'Ícono histórico de Girardot, construido en 1895.',
    posicion: LatLng(4.3025, -74.8045),
    tipo: TipoPunto.historico,
  ),
  PuntoMapa(
    nombre: 'Plaza de Bolívar',
    descripcion: 'Centro histórico y político de la ciudad.',
    posicion: LatLng(4.3041, -74.8017),
    tipo: TipoPunto.historico,
  ),
  PuntoMapa(
    nombre: 'Malecón del Río Magdalena',
    descripcion: 'Paseo ribereño con vista al río Magdalena.',
    posicion: LatLng(4.3010, -74.7995),
    tipo: TipoPunto.historico,
  ),
  PuntoMapa(
    nombre: 'Catedral Nuestra Señora del Carmen',
    descripcion: 'Principal iglesia católica de Girardot.',
    posicion: LatLng(4.3048, -74.8020),
    tipo: TipoPunto.historico,
  ),
];

const List<PuntoMapa> _academiasFijas = [
  PuntoMapa(
    nombre: 'Academia de Danza Girardot',
    descripcion: 'Formación en danzas folclóricas y contemporáneas.',
    posicion: LatLng(4.3060, -74.8010),
    tipo: TipoPunto.academia,
  ),
  PuntoMapa(
    nombre: 'Escuela de Música del Magdalena',
    descripcion: 'Clases de guitarra, piano, voz y percusión.',
    posicion: LatLng(4.3035, -74.8035),
    tipo: TipoPunto.academia,
  ),
  PuntoMapa(
    nombre: 'Taller de Artes Plásticas',
    descripcion: 'Pintura, escultura y artes visuales.',
    posicion: LatLng(4.3070, -74.8050),
    tipo: TipoPunto.academia,
  ),
];

// ── Colores por tipo ──────────────────────────────
extension TipoPuntoExt on TipoPunto {
  Color get color {
    switch (this) {
      case TipoPunto.academia:  return Colors.amberAccent;
      case TipoPunto.historico: return Colors.lightBlueAccent;
      case TipoPunto.evento:    return Colors.greenAccent;
    }
  }

  IconData get icono {
    switch (this) {
      case TipoPunto.academia:  return Icons.school_outlined;
      case TipoPunto.historico: return Icons.account_balance_outlined;
      case TipoPunto.evento:    return Icons.event_outlined;
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoPunto.academia:  return 'Academia';
      case TipoPunto.historico: return 'Punto histórico';
      case TipoPunto.evento:    return 'Evento';
    }
  }
}

// ── Página ────────────────────────────────────────
class MapaPage extends StatefulWidget {
  final bool isLoggedIn;
  final bool isAdmin;

  const MapaPage({
    super.key,
    required this.isLoggedIn,
    this.isAdmin = false,
  });

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final MapController _mapController = MapController();
  List<PuntoMapa> _eventosEnMapa = [];
  PuntoMapa? _seleccionado;
  bool _cargando = true;

  // Filtros
  bool _mostrarAcademias  = true;
  bool _mostrarHistoricos = true;
  bool _mostrarEventos    = true;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    try {
      final data = await ApiService.getEventos();
      if (!mounted) return;
      // Distribuimos los eventos alrededor del centro con offset pequeño
      // para no apilarlos (hasta tener coords reales en la BD)
      final List<PuntoMapa> puntos = [];
      for (int i = 0; i < data.length; i++) {
        final e = data[i];
        final double offsetLat = (i % 5) * 0.0015;
        final double offsetLng = (i ~/ 5) * 0.0015;
        puntos.add(PuntoMapa(
          nombre: e['nombre'] ?? 'Evento',
          descripcion:
              '📅 ${e['fecha'] ?? ''}  🕐 ${e['horaInicio'] ?? ''}\n'
              '📍 ${e['lugar'] ?? ''}  💲 ${e['precio'] ?? ''}',
          posicion: LatLng(
            _centroGirardot.latitude + 0.002 + offsetLat,
            _centroGirardot.longitude + 0.002 + offsetLng,
          ),
          tipo: TipoPunto.evento,
        ));
      }
      setState(() {
        _eventosEnMapa = puntos;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  List<PuntoMapa> get _puntosFiltrados {
    return [
      if (_mostrarAcademias)  ..._academiasFijas,
      if (_mostrarHistoricos) ..._puntosHistoricos,
      if (_mostrarEventos)    ..._eventosEnMapa,
    ];
  }

  void _seleccionar(PuntoMapa punto) {
    setState(() => _seleccionado = punto);
    _mapController.move(punto.posicion, 16);
  }

  void _cerrarPopup() => setState(() => _seleccionado = null);

  // ── Build ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Cultural')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : isWide
              ? Row(children: [
                  SizedBox(width: 280, child: _buildSidebar()),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildMapa()),
                ])
              : Stack(children: [
                  _buildMapa(),
                  Positioned(
                    top: 12, left: 12,
                    child: _buildFiltrosChips(),
                  ),
                  if (_seleccionado != null)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: _buildInfoCard(_seleccionado!),
                    ),
                ]),
    );
  }

  // ── Sidebar (pantallas anchas) ─────────────────
  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Puntos de interés',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        _buildFiltrosChips(),
        const Divider(),
        Expanded(
          child: ListView(
            children: _puntosFiltrados.map((p) {
              final selec = _seleccionado == p;
              return ListTile(
                selected: selec,
                selectedTileColor: Colors.white10,
                leading: Icon(p.tipo.icono, color: p.tipo.color),
                title: Text(p.nombre,
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text(p.tipo.etiqueta,
                    style: TextStyle(fontSize: 11, color: p.tipo.color)),
                onTap: () => _seleccionar(p),
              );
            }).toList(),
          ),
        ),
        if (_seleccionado != null) _buildInfoCard(_seleccionado!),
      ],
    );
  }

  // ── Chips de filtro ───────────────────────────
  Widget _buildFiltrosChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _chip('Academias',  TipoPunto.academia,  _mostrarAcademias,
              (v) => setState(() => _mostrarAcademias = v)),
          _chip('Históricos', TipoPunto.historico, _mostrarHistoricos,
              (v) => setState(() => _mostrarHistoricos = v)),
          _chip('Eventos',    TipoPunto.evento,    _mostrarEventos,
              (v) => setState(() => _mostrarEventos = v)),
        ],
      ),
    );
  }

  Widget _chip(String label, TipoPunto tipo, bool activo,
      ValueChanged<bool> onChange) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(tipo.icono, size: 14,
          color: activo ? tipo.color : Colors.grey),
      selected: activo,
      selectedColor: tipo.color.withValues(alpha: 0.2),
      checkmarkColor: tipo.color,
      onSelected: onChange,
    );
  }

  // ── Mapa ──────────────────────────────────────
  Widget _buildMapa() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _centroGirardot,
        initialZoom: 15,
        onTap: (_, _) => _cerrarPopup(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.girardot_arte',
        ),
        MarkerLayer(
          markers: _puntosFiltrados.map((p) {
            final selec = _seleccionado == p;
            return Marker(
              point: p.posicion,
              width: selec ? 52 : 42,
              height: selec ? 52 : 42,
              child: GestureDetector(
                onTap: () => _seleccionar(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selec
                        ? p.tipo.color
                        : p.tipo.color.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white,
                        width: selec ? 3 : 1.5),
                    boxShadow: selec
                        ? [BoxShadow(
                            color: p.tipo.color.withValues(alpha: 0.6),
                            blurRadius: 12,
                            spreadRadius: 2)]
                        : [],
                  ),
                  child: Icon(p.tipo.icono,
                      color: Colors.black87,
                      size: selec ? 26 : 20),
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.isAdmin && widget.isLoggedIn)
          MarkerLayer(markers: []), // placeholder para futuros puntos admin
      ],
    );
  }

  // ── Info card del punto seleccionado ──────────
  Widget _buildInfoCard(PuntoMapa p) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.tipo.color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: p.tipo.color.withValues(alpha: 0.2),
            child: Icon(p.tipo.icono, color: p.tipo.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(p.descripcion,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.tipo.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(p.tipo.etiqueta,
                      style: TextStyle(
                          fontSize: 11, color: p.tipo.color)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _cerrarPopup,
          ),
        ],
      ),
    );
  }
}