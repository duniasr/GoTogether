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
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final usuario = _auth.currentUser;
    String organizadorFinal = organizador.trim();

    // --- LA MAGIA: Si el campo de la pantalla viene vacío, buscamos su NOMBRE real ---
    if (organizadorFinal.isEmpty) {
      if (usuario != null) {
        try {
          // Buscamos en la colección 'users' a ver si tiene el nombre configurado
          final userDoc = await _firestore.collection('users').doc(usuario.uid).get();
          
          if (userDoc.exists && userDoc.data()?['nombre'] != null && userDoc.data()!['nombre'].toString().trim().isNotEmpty) {
            organizadorFinal = userDoc.data()!['nombre']; // Encontramos "kiko"
          } else {
            // Si no tiene nombre en la base de datos, usamos su displayName de Google o "Anónimo"
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

  Future<void> eliminarQuedada(String eventoId) async {
    await _eventsRef.doc(eventoId).delete();
  }

  /// Stream con los eventos cuyo campo [organizador] coincide con el
  /// nombre guardado en Firestore para el usuario actual.
  Stream<List<Quedada>> escucharMisQuedadas() {
    final usuario = _auth.currentUser;
    if (usuario == null) return Stream.value([]);

    // Primero obtenemos el nombre con un Future, luego abrimos el stream de Firestore.
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

  /// Actualiza los campos editables de un evento existente.
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

  /// Eventos en los que el usuario actual figura como asistente.
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
  /// Elimina al usuario actual de la lista de asistentes y devuelve una plaza.
  Future<void> abandonarQuedada(String eventoId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _eventsRef.doc(eventoId).update({
      'asistentesID': FieldValue.arrayRemove([uid]),
      'plazasLibres': FieldValue.increment(1),
    });
  }
}
