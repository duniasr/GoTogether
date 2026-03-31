import 'package:flutter/material.dart';
import '../app_theme.dart';

class DateTimePicker extends StatefulWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback onCleared;

  const DateTimePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
    required this.onCleared,
  });

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _pick() async {
    // Evitar el crash _viewInsets.isNonNegative de Flutter Web escondiendo el teclado primero
    FocusScope.of(context).unfocus();

    final hoy = DateTime.now();
    // Normalizamos 'hoy' para que el firstDate funcione bien si hoy es medianoche
    final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
    
    // Si ya existe un valor previo anterior a 'hoy' (ej: evento antiguo), lo permitimos
    // para no bloquear la edición, sino usamos hoyNormalizado.
    final inicial = widget.value != null && widget.value!.isBefore(hoyNormalizado)
        ? widget.value!
        : hoyNormalizado;

    final fecha = await showDatePicker(
      context: context,
      initialDate: widget.value ?? hoy,
      firstDate: inicial,
      lastDate: DateTime(hoy.year + 5),
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: widget.value != null
          ? TimeOfDay.fromDateTime(widget.value!)
          : TimeOfDay.now(),
    );
    if (hora == null || !mounted) return;

    widget.onPicked(DateTime(
        fecha.year, fecha.month, fecha.day, hora.hour, hora.minute));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: _pick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '${widget.label} Date',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: widget.value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: widget.onCleared,
                )
              : null,
        ),
        child: Text(
          widget.value != null ? _fmt(widget.value!) : 'No date',
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.value != null ? null : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
