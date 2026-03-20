import 'package:cloud_firestore/cloud_firestore.dart';

class Quedada {
  const Quedada({
    required this.id,
    required this.asistentesId,
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
  });

  final String id;
  final List<String> asistentesId;
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

  factory Quedada.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final asistentesRaw = data['asistentesID'];

    return Quedada(
      id: doc.id,
      asistentesId: asistentesRaw is Iterable
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'asistentesID': asistentesId,
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
    };
  }
}
