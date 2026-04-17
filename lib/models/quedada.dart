import 'package:cloud_firestore/cloud_firestore.dart';

class Quedada {
  // Constructor de la clase
  const Quedada({
    required this.id,
    required this.asistentesID,
    required this.contadorReportes,
    required this.cupoMax,
    required this.descripcion,
    required this.esVerificado,
    required this.estado,
    required this.organizador,
    required this.plazasLibres,
    required this.tematica,
    required this.titulo,
    required this.ubicacion,
    required this.fechaInicio,
    required this.fechaFin,
  });

  final String id;
  final List<String> asistentesID;
  final int contadorReportes;
  final int cupoMax;
  final String descripcion;
  final bool esVerificado;
  final String estado;
  final String organizador;
  final int plazasLibres;
  final String tematica;
  final String titulo;
  final GeoPoint ubicacion;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  // Método de fábrica para construir una Quedada a partir del JSON de Firestore
  factory Quedada.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final asistentesRaw = data['asistentesID'];
    
    // Control de errores básicos por si la base de datos devuelve valores nulos
    final fechaInicioRaw = data['fechaInicio'];
    final fechaFinRaw = data['fechaFin'];

    return Quedada(
      id: doc.id,
      asistentesID: asistentesRaw is Iterable
          ? asistentesRaw.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      contadorReportes: (data['contadorReportes'] as num?)?.toInt() ?? 0,
      cupoMax: (data['cupoMax'] as num?)?.toInt() ?? 0,
      descripcion: data['descripcion'] as String? ?? '',
      esVerificado: data['esVerificado'] as bool? ?? false,
      estado: data['estado'] as String? ?? 'abierta',
      organizador: data['organizador'] as String? ?? 'anonimo',
      plazasLibres: (data['plazasLibres'] as num?)?.toInt() ?? 0,
      tematica: data['tematica'] as String? ?? 'Otros',
      titulo: data['titulo'] as String? ?? '',
      ubicacion: data['ubicacion'] as GeoPoint? ?? const GeoPoint(0, 0),
      fechaInicio: fechaInicioRaw is Timestamp
          ? fechaInicioRaw.toDate()
          : DateTime.now(),
      fechaFin: fechaFinRaw is Timestamp
          ? fechaFinRaw.toDate()
          : DateTime.now().add(const Duration(hours: 2)),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'asistentesID': asistentesID,
      'contadorReportes': contadorReportes,
      'cupoMax': cupoMax,
      'descripcion': descripcion,
      'esVerificado': esVerificado,
      'estado': estado,
      'organizador': organizador,
      'plazasLibres': plazasLibres,
      'tematica': tematica,
      'titulo': titulo,
      'ubicacion': ubicacion,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
    };
  }
}
