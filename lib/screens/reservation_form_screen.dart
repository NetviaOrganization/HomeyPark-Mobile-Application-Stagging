import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/services/reservation_service.dart';

import '../model/reservation_status.dart';

class ReservationFormScreen extends StatefulWidget {
  final Parking parking;
  
  const ReservationFormScreen({super.key, required this.parking});
  
  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  
  final _carModelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  
  double get _totalPrice {
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      return 0.0;
    }
    
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    
    final end = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
    
    if (end.isBefore(start)) return 0.0;
    
    final duration = end.difference(start);
    final hours = duration.inMinutes / 60.0;
    
    return hours * widget.parking.price;
  }
  
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }
  
  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }
  
  bool _isValidDateTime() {
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      return false;
    }
    
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    
    final end = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
    
    return end.isAfter(start) && start.isAfter(DateTime.now());
  }
  
  Future<void> _createReservation() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isValidDateTime()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fechas y horas válidas'),
        ),
      );
      return;
    }
    
    setState(() {
      _loading = true;
    });
    
    try {
      final userId = await preferences.getUserId();
      
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      
      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );
      
      // Llamada CORRECTA al servicio actualizado
      final reservation = await ReservationService.createReservation(
        userId: userId,
        parkingId: widget.parking.id,
        startTime: startDateTime,
        endTime: endDateTime,
        carModel: _carModelController.text,
        licensePlate: _licensePlateController.text,
        totalPrice: _totalPrice,
        // paymentProof: _selectedPaymentProof, // Opcional
      );
      
      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          title: const Text('¡Reserva creada exitosamente!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID de reserva: ${reservation.id}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total: S/ ${_totalPrice.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    Text('Estacionamiento: ${widget.parking.location.address}'),
                    const SizedBox(height: 4),
                    Text('Desde: ${_formatDateTime(startDateTime)}'),
                    Text('Hasta: ${_formatDateTime(endDateTime)}'),
                    const SizedBox(height: 4),
                    Text('Estado: ${statusText(reservation.status)}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a la pantalla anterior
              },
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear reserva: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nueva Reserva',
          style: theme.textTheme.titleMedium,
        ),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del estacionamiento
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estacionamiento seleccionado',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.parking.location.address),
                    Text('Precio: S/ ${widget.parking.price.toStringAsFixed(2)} por hora'),
                    Text('Espacios disponibles: ${widget.parking.space}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Información del vehículo
              Text('Información del vehículo', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _carModelController,
                decoration: const InputDecoration(
                  labelText: 'Modelo del vehículo',
                  hintText: 'Ej: Toyota Corolla',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El modelo del vehículo es requerido';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  labelText: 'Placa del vehículo',
                  hintText: 'Ej: ABC-123',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La placa del vehículo es requerida';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Fechas y horas
              Text('Horario de reserva', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              
              // Fecha y hora de inicio
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectStartDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate != null
                            ? 'Inicio: ${_formatDate(_startDate!)}'
                            : 'Fecha de inicio',
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectStartTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _startTime != null
                            ? _formatTime(_startTime!)
                            : 'Hora inicio',
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Fecha y hora de fin
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectEndDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _endDate != null
                            ? 'Fin: ${_formatDate(_endDate!)}'
                            : 'Fecha de fin',
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectEndTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _endTime != null
                            ? _formatTime(_endTime!)
                            : 'Hora fin',
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Resumen de precio
              if (_totalPrice > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total a pagar:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'S/ ${_totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Botón de reservar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _createReservation,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirmar Reserva'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _carModelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }
}