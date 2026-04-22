import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/quedada.dart';
import '../services/quedadas_service.dart';

class QuedadasPage extends StatefulWidget {
  const QuedadasPage({super.key, QuedadasService? service})
    : _service = service;

  final QuedadasService? _service;

  @override
  State<QuedadasPage> createState() => _QuedadasPageState();
}

class _QuedadasPageState extends State<QuedadasPage> {
  static const List<String> _tematicas = <String>[
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

  static const List<String> _estados = <String>[
    'abierta',
    'cerrada',
    'cancelada',
  ];

  late final QuedadasService _service;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? QuedadasService();
  }

  Future<void> _mostrarFormularioCrearQuedada() async {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final organizadorController = TextEditingController();
    final cupoController = TextEditingController();
    final latitudController = TextEditingController();
    final longitudController = TextEditingController();

    String tematicaSeleccionada = _tematicas.first;
    String estadoSeleccionado = _estados.first;
    bool esVerificado = false;
    DateTime fechaInicio = DateTime.now().add(const Duration(hours: 1));
    DateTime fechaFin = DateTime.now().add(const Duration(hours: 3));

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nuevo evento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: organizadorController,
                      decoration: const InputDecoration(
                        labelText: 'Organizador',
                        hintText:
                            'Si lo dejas vacío se usará tu usuario actual',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tematicaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Temática',
                        border: OutlineInputBorder(),
                      ),
                      items: _tematicas
                          .map(
                            (tematica) => DropdownMenuItem<String>(
                              value: tematica,
                              child: Text(tematica),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setStateDialog(() {
                          tematicaSeleccionada = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: estadoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: _estados
                          .map(
                            (estado) => DropdownMenuItem<String>(
                              value: estado,
                              child: Text(_capitalizar(estado)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setStateDialog(() {
                          estadoSeleccionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cupoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cupo máximo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: latitudController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        hintText: 'Ejemplo: 40.4168',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: longitudController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        hintText: 'Ejemplo: -3.7038',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Evento verificado'),
                      value: esVerificado,
                      onChanged: (value) {
                        setStateDialog(() {
                          esVerificado = value;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha de inicio'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fechaInicio),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await _seleccionarFechaYHora(
                          context,
                          fechaInicio,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            fechaInicio = picked;
                            if (fechaFin.isBefore(fechaInicio)) {
                              fechaFin = fechaInicio.add(
                                const Duration(hours: 2),
                              );
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha de finalización'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fechaFin),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await _seleccionarFechaYHora(
                          context,
                          fechaFin,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            fechaFin = picked;
                          });
                        }
                      },
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
                    final titulo = tituloController.text.trim();
                    final descripcion = descripcionController.text.trim();
                    final organizador = organizadorController.text.trim();
                    final cupoMax = int.tryParse(cupoController.text.trim());
                    final latitud = double.tryParse(
                      latitudController.text.trim().replaceAll(',', '.'),
                    );
                    final longitud = double.tryParse(
                      longitudController.text.trim().replaceAll(',', '.'),
                    );

                    final ubicacionValida =
                        latitud != null &&
                        longitud != null &&
                        latitud >= -90 &&
                        latitud <= 90 &&
                        longitud >= -180 &&
                        longitud <= 180;

                    if (titulo.isEmpty ||
                        descripcion.isEmpty ||
                        cupoMax == null ||
                        cupoMax <= 0 ||
                        !ubicacionValida) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Rellena título, descripción, cupo válido y una ubicación correcta.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await _service.crearQuedada(
                        titulo: titulo,
                        descripcion: descripcion,
                        organizador: organizador,
                        tematica: tematicaSeleccionada,
                        cupoMax: cupoMax,
                        latitud: latitud!,
                        longitud: longitud!,
                        estado: estadoSeleccionado,
                        esVerificado: esVerificado,
                        fechaInicio: fechaInicio,
                        fechaFin: fechaFin,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Evento creado correctamente.'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al crear el evento: $e')),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    tituloController.dispose();
    descripcionController.dispose();
    organizadorController.dispose();
    cupoController.dispose();
    latitudController.dispose();
    longitudController.dispose();
  }

  Future<DateTime?> _seleccionarFechaYHora(
    BuildContext context,
    DateTime inicial,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null) return null;

    if (!context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(inicial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _eliminarQuedada(Quedada quedada) async {
    final confirmar =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar evento'),
            content: Text('¿Seguro que quieres eliminar "${quedada.titulo}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) {
      return;
    }

    try {
      await _service.eliminarQuedada(quedada.id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Evento eliminado.')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el evento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioCrearQuedada,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: StreamBuilder<List<Quedada>>(
        stream: _service.escucharQuedadas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error cargando los eventos: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final quedadas = snapshot.data ?? const <Quedada>[];

          if (quedadas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay eventos creados. Pulsa en "Nuevo" para añadir el primero.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: quedadas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final quedada = quedadas[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    quedada.titulo.isEmpty ? 'Sin título' : quedada.titulo,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(quedada.tematica),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(
                                'Estado: ${_capitalizar(quedada.estado)}',
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text('Cupo: ${quedada.cupoMax}'),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text('Libres: ${quedada.plazasLibres}'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quedada.descripcion.isEmpty
                              ? 'Sin descripción'
                              : quedada.descripcion,
                        ),
                        const SizedBox(height: 8),
                        Text('Organizador: ${quedada.organizador}'),
                        const SizedBox(height: 4),
                        Text(
                          'Verificado: ${quedada.esVerificado ? 'Sí' : 'No'}',
                        ),
                        const SizedBox(height: 4),
                        Text('Reportes: ${quedada.contadorReportes}'),
                        const SizedBox(height: 4),
                        Text('Asistentes: ${quedada.asistentesID.length}'),
                        const SizedBox(height: 4),
                        Text(
                          'Ubicación: ${quedada.ubicacion.latitude.toStringAsFixed(5)}, '
                          '${quedada.ubicacion.longitude.toStringAsFixed(5)}',
                        ),
                        const Divider(),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Inicio: ${DateFormat('dd/MM/yyyy HH:mm').format(quedada.fechaInicio)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Fin: ${DateFormat('dd/MM/yyyy HH:mm').format(quedada.fechaFin)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar evento',
                    onPressed: () => _eliminarQuedada(quedada),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _capitalizar(String valor) {
    if (valor.isEmpty) {
      return valor;
    }

    return valor[0].toUpperCase() + valor.substring(1);
  }
}
