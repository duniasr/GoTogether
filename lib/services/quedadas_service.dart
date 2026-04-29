import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/quedada.dart';

class QuedadasService {
  QuedadasService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> get _notifRef =>
      _firestore.collection('notificaciones');

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
        .where('fechaFin', isGreaterThanOrEqualTo: Timestamp.now())
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
    bool esVerificadoFinal = esVerificado;

    if (usuario != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(usuario.uid)
            .get();

        if (userDoc.exists) {
          // Si el usuario es verificado, sus eventos se crean como verificados automáticamente
          if (userDoc.data()?['rol'] == 'verificado') {
            esVerificadoFinal = true;
          }

          if (organizadorFinal.isEmpty &&
              userDoc.data()?['nombre'] != null &&
              userDoc.data()!['nombre'].toString().trim().isNotEmpty) {
            organizadorFinal = userDoc.data()!['nombre'];
          }
        }

        if (organizadorFinal.isEmpty) {
          organizadorFinal = usuario.displayName ?? 'Anónimo';
        }
      } catch (e) {
        if (organizadorFinal.isEmpty) {
          organizadorFinal = 'Anónimo';
        }
      }
    } else {
      if (organizadorFinal.isEmpty) {
        organizadorFinal = 'Anónimo';
      }
    }

    final evento = Quedada(
      id: '',
      asistentesID: const <String>[],
      contadorReportes: 0,
      cupoMax: cupoMax,
      descripcion: descripcion.trim(),
      esVerificado: esVerificadoFinal,
      estado: estado,
      organizador: organizadorFinal,
      organizadorId: usuario?.uid ?? '',
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
    final doc = await _eventsRef.doc(eventoId).get();
    if (doc.exists) {
      final quedada = Quedada.fromFirestore(doc);
      if (quedada.asistentesID.isNotEmpty) {
        final fecha = DateFormat('dd/MM/yyyy HH:mm').format(quedada.fechaInicio);
        await _enviarNotificacionAAsistentes(
          quedada,
          'The plan "${quedada.titulo}" ($fecha) has been deleted by the organizer.',
        );
      }
    }
    await _eventsRef.doc(eventoId).delete();
  }

  Future<void> _enviarNotificacionAAsistentes(Quedada quedada, String mensaje) async {
    final batch = _firestore.batch();
    for (final userId in quedada.asistentesID) {
      final newNotifRef = _notifRef.doc();
      batch.set(newNotifRef, {
        'userId': userId,
        'mensaje': mensaje,
        'fecha': FieldValue.serverTimestamp(),
        'leida': false,
        'eventoId': quedada.id,
      });
    }
    await batch.commit();
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
          .then<String>(
            (doc) =>
                doc.data()?['nombre'] as String? ??
                usuario.displayName ??
                'Anónimo',
          )
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
              (a, b) =>
                  a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()),
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
    int? nuevasPlazasLibres;
    final doc = await _eventsRef.doc(eventoId).get();
    
    if (doc.exists) {
      final currentQuedada = Quedada.fromFirestore(doc);
      
      // Calculate new available spots
      nuevasPlazasLibres = cupoMax - currentQuedada.asistentesID.length;
      if (nuevasPlazasLibres < 0) nuevasPlazasLibres = 0;

      // Check if we need to notify about cancellation
      if (estado == 'cancelada' && currentQuedada.estado != 'cancelada' && currentQuedada.asistentesID.isNotEmpty) {
        final fecha = DateFormat('dd/MM/yyyy HH:mm').format(currentQuedada.fechaInicio);
        await _enviarNotificacionAAsistentes(
          currentQuedada,
          'The plan "${currentQuedada.titulo}" ($fecha) has been cancelled.',
        );
      }
    }

    await _eventsRef.doc(eventoId).update({
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'tematica': tematica,
      'cupoMax': cupoMax,
      'estado': estado,
      if (nuevasPlazasLibres != null) 'plazasLibres': nuevasPlazasLibres,
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
        .where('asistentesID', arrayContains: usuario.uid) // ← corregido
        .snapshots()
        .map((snap) {
          final lista = snap.docs
              .map(Quedada.fromFirestore)
              .toList(growable: false);
          lista.sort(
            (a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()),
          );
          return lista;
        });
  }

  Future<void> unirseAQuedada(String eventoId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _eventsRef.doc(eventoId).update({
      'asistentesID': FieldValue.arrayUnion([uid]), // ← corregido
      'plazasLibres': FieldValue.increment(-1),
    });
  }

  Future<void> abandonarQuedada(String eventoId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _eventsRef.doc(eventoId).update({
      'asistentesID': FieldValue.arrayRemove([uid]), // ← ya estaba bien
      'plazasLibres': FieldValue.increment(1),
    });
  }

  Future<void> reportarQuedada(String eventoId, String motivo) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User is not authenticated');

    final reportesRef = _firestore.collection('reportes_quedadas');
    final reporteId = '${eventoId}_$uid';

    final docResult = await reportesRef.doc(reporteId).get();
    if (docResult.exists) {
      throw Exception('You have already reported this event');
    }

    await reportesRef.doc(reporteId).set({
      'eventoId': eventoId,
      'reportadorId': uid,
      'motivo': motivo,
      'fecha': FieldValue.serverTimestamp(),
    });

    await _eventsRef.doc(eventoId).update({
      'contadorReportes': FieldValue.increment(1),
    });

  }
}
