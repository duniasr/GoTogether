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

  // Escucha todos los eventos de Firestore en tiempo real para mantener la lista actualizada
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

  
  Stream<List<Quedada>> escucharQuedadasFuturas() {
    return _eventsRef
        .where('fechaInicio', isGreaterThanOrEqualTo: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(Quedada.fromFirestore)
          .toList(growable: false);
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
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final usuario = _auth.currentUser;
    String organizadorFinal = organizador.trim();

    if (organizadorFinal.isEmpty) {
      if (usuario != null) {
        try {
          // Si no se pasó un nombre, buscamos si el usuario tiene un nombre guardado en la BD
          final userDoc = await _firestore.collection('users').doc(usuario.uid).get();
          
          if (userDoc.exists && userDoc.data()?['nombre'] != null && userDoc.data()!['nombre'].toString().trim().isNotEmpty) {
            organizadorFinal = userDoc.data()!['nombre'];
          } else {
            organizadorFinal = usuario.displayName ?? 'Anónimo';
          }
        } catch (e) {
          organizadorFinal = 'Anónimo';
        }
      } else {
        organizadorFinal = 'Anónimo';
      }
    }

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
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );

    await _eventsRef.add(evento.toFirestore());
  }

  // Borra un evento específico de la base de datos
  Future<void> eliminarQuedada(String eventoId) async {
    await _eventsRef.doc(eventoId).delete();
  }

  // Retorna únicamente los eventos creados por el usuario activo
  Stream<List<Quedada>> escucharMisQuedadas() {
    final usuario = _auth.currentUser;
    if (usuario == null) return Stream.value([]);

    return Stream.fromFuture(
      _firestore
          .collection('users')
          .doc(usuario.uid)
          .get()
          .then<String>((doc) =>
              doc.data()?['nombre'] as String? ??
              usuario.displayName ??
              'Anónimo')
          .catchError((_) => usuario.displayName ?? 'Anónimo'),
    ).asyncExpand(
      (nombre) => _eventsRef
          .where('organizador', isEqualTo: nombre)
          .snapshots()
          .map((snapshot) {
        final eventos = snapshot.docs
            .map(Quedada.fromFirestore)
            .toList(growable: false);
        eventos.sort(
          (a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()),
        );
        return eventos;
      }),
    );
  }

  Future<void> actualizarQuedada({
    required String eventoId,
    required String titulo,
    required String descripcion,
    required String tematica,
    required int cupoMax,
    required String estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    await _eventsRef.doc(eventoId).update({
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'tematica': tematica,
      'cupoMax': cupoMax,
      'estado': estado,
      'fechaInicio': fechaInicio != null
          ? Timestamp.fromDate(fechaInicio)
          : FieldValue.delete(),
      'fechaFin': fechaFin != null
          ? Timestamp.fromDate(fechaFin)
          : FieldValue.delete(),
    });
  }

  Stream<List<Quedada>> escucharQuedadasUnidas() {
    final usuario = _auth.currentUser;
    if (usuario == null) return Stream.value([]);

    return _eventsRef
        .where('asistentesID', arrayContains: usuario.uid)
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map(Quedada.fromFirestore).toList(growable: false);
      lista.sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
      return lista;
    });
  }
  Future<void> abandonarQuedada(String eventoId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _eventsRef.doc(eventoId).update({
      'asistentesID': FieldValue.arrayRemove([uid]),
      'plazasLibres': FieldValue.increment(1),
    });
  }
}
