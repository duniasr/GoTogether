import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/quedada.dart';

class QuedadasService {
  QuedadasService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  Stream<List<Quedada>> escucharQuedadas() {
    return _eventsRef.snapshots().map((snapshot) {
      final eventos = snapshot.docs
          .map(Quedada.fromFirestore)
          .toList(growable: false);

      eventos.sort(
        (a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()),
      );

      return eventos;
    });
  }

  Future<void> crearQuedada({
    required String titulo,
    required String descripcion,
    required String organizador,
    required String tematica,
    required int cupoMax,
    required double latitud,
    required double longitud,
    required String estado,
    required bool esVerificado,
  }) async {
    final usuario = _auth.currentUser;
    final organizadorFinal = organizador.trim().isNotEmpty
        ? organizador.trim()
        : usuario?.email ?? usuario?.uid ?? 'anonimo';

    final evento = Quedada(
      id: '',
      asistentesId: const <String>[],
      contadorReportes: 0,
      cupoMax: cupoMax,
      descripcion: descripcion.trim(),
      esVerificado: esVerificado,
      estado: estado,
      organizador: organizadorFinal,
      plazasLibres: cupoMax,
      tematica: tematica,
      titulo: titulo.trim(),
      ubicacion: GeoPoint(latitud, longitud),
    );

    await _eventsRef.add(evento.toFirestore());
  }

  Future<void> eliminarQuedada(String eventoId) async {
    await _eventsRef.doc(eventoId).delete();
  }
}
