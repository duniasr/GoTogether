import 'package:cloud_firestore/cloud_firestore.dart';

class AvisoModificacion {
  const AvisoModificacion({
    required this.id,
    required this.eventoId,
    required this.tituloEvento,
    required this.userId,
    required this.campos,
    required this.fecha,
    required this.leido,
  });

  final String id;
  final String eventoId;
  final String tituloEvento;
  final String userId;
  final List<String> campos;
  final DateTime fecha;
  final bool leido;

  factory AvisoModificacion.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final camposRaw = data['campos'];
    final fechaRaw = data['fecha'];

    return AvisoModificacion(
      id: doc.id,
      eventoId: data['eventoId'] as String? ?? '',
      tituloEvento: data['tituloEvento'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      campos: camposRaw is Iterable
          ? camposRaw.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      fecha: fechaRaw is Timestamp ? fechaRaw.toDate() : DateTime.now(),
      leido: data['leido'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventoId': eventoId,
      'tituloEvento': tituloEvento,
      'userId': userId,
      'campos': campos,
      'fecha': Timestamp.fromDate(fecha),
      'leido': leido,
    };
  }
}
