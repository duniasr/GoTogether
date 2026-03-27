import 'package:flutter/material.dart';
import '../../../services/quedadas_service.dart';

Future<void> showCreateEventDialog(BuildContext context, QuedadasService service) async {
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final cupoCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lonCtrl = TextEditingController();

  const List<String> tematicas = [
    'Deporte',
    'Naturaleza',
    'Estudio',
    'Ocio',
    'Cultura',
    'Gastronomía',
    'Fiesta',
    'Voluntariado',
    'Viajes',
    'Videojuegos',
    'Música',
    'Networking',
    'Otros',
  ];

  String tematica = tematicas.first;
  bool esVerificado = false;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Nuevo plan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descripcionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tematica,
                    decoration: const InputDecoration(
                      labelText: 'Temática *',
                      border: OutlineInputBorder(),
                    ),
                    items: tematicas
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setStateDialog(() => tematica = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cupoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cupo máximo *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Latitud *',
                      hintText: 'Ej: 28.1248',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lonCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Longitud *',
                      hintText: 'Ej: -15.4300',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Evento verificado'),
                    value: esVerificado,
                    onChanged: (v) => setStateDialog(() => esVerificado = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final titulo = tituloCtrl.text.trim();
                  final descripcion = descripcionCtrl.text.trim();
                  final cupoMax = int.tryParse(cupoCtrl.text.trim());
                  final lat = double.tryParse(
                    latCtrl.text.trim().replaceAll(',', '.'),
                  );
                  final lon = double.tryParse(
                    lonCtrl.text.trim().replaceAll(',', '.'),
                  );

                  final ubicacionValida =
                      lat != null &&
                      lon != null &&
                      lat >= -90 &&
                      lat <= 90 &&
                      lon >= -180 &&
                      lon <= 180;

                  if (titulo.isEmpty ||
                      descripcion.isEmpty ||
                      cupoMax == null ||
                      cupoMax <= 0 ||
                      !ubicacionValida) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, completa todos los campos correctamente.',
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    await service.crearQuedada(
                      titulo: titulo,
                      descripcion: descripcion,
                      organizador: '',
                      tematica: tematica,
                      cupoMax: cupoMax,
                      latitud: lat,
                      longitud: lon,
                      estado: 'abierta',
                      esVerificado: esVerificado,
                    );

                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Plan creado correctamente.'),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear el plan: $e')),
                    );
                  }
                },
                child: const Text('Crear plan'),
              ),
            ],
          );
        },
      );
    },
  );

  tituloCtrl.dispose();
  descripcionCtrl.dispose();
  cupoCtrl.dispose();
  latCtrl.dispose();
  lonCtrl.dispose();
}
