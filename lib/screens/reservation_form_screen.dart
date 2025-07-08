import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/services/reservation_service.dart';

import 'package:provider/provider.dart';
import '../providers/rewards_provider.dart'; // NUEVO
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

  // NUEVO: Variables para manejo de descuentos
  Map<String, dynamic>? _priceCalculation;
  bool _isCalculatingPrice = false;

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

  // NUEVO: Precio con descuento aplicado
  double get _finalPrice {
    return _priceCalculation?['finalPrice']?.toDouble() ?? _totalPrice;
  }

  // NUEVO: Verificar y calcular descuentos automáticamente
  Future<void> _calculatePriceWithDiscount() async {
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      return;
    }

    setState(() {
      _isCalculatingPrice = true;
    });

    try {
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

      final rewardsProvider = context.read<RewardsProvider>();

      // Obtener cupones activos del usuario
      final activeCoupons = rewardsProvider.getActiveCoupons();
      String? bestCouponCode;

      if (activeCoupons.isNotEmpty) {
        // Usar el cupón con mayor descuento
        activeCoupons.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        bestCouponCode = activeCoupons.first.couponCode;
      }

      // Calcular precio con descuento automático
      await rewardsProvider.calculatePriceWithDiscount(
        parkingId: widget.parking.id.toString(),
        startTime: startDateTime,
        endTime: endDateTime,
        couponCode: bestCouponCode,
      );

      setState(() {
        _priceCalculation = rewardsProvider.priceCalculation;
      });

    } catch (e) {
      print('Error calculating price with discount: $e');
    } finally {
      setState(() {
        _isCalculatingPrice = false;
      });
    }
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
      // NUEVO: Recalcular precio con descuento cuando cambia la fecha
      _calculatePriceWithDiscount();
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
      // NUEVO: Recalcular precio con descuento cuando cambia la hora
      _calculatePriceWithDiscount();
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
      // NUEVO: Recalcular precio con descuento cuando cambia la fecha
      _calculatePriceWithDiscount();
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
      // NUEVO: Recalcular precio con descuento cuando cambia la hora
      _calculatePriceWithDiscount();
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

      // MODIFICADO: Usar precio final (con descuento si aplica)
      final reservation = await ReservationService.createReservation(
        userId: userId,
        parkingId: widget.parking.id,
        startTime: startDateTime,
        endTime: endDateTime,
        carModel: _carModelController.text,
        licensePlate: _licensePlateController.text,
        totalPrice: _finalPrice, // NUEVO: Usar precio con descuento
      );

      // NUEVO: Si hay descuento aplicado, aplicarlo a la reserva
      if (_priceCalculation != null &&
          _priceCalculation!['discountApplied'] == true &&
          _priceCalculation!['appliedCoupon'] != null) {

        final rewardsProvider = context.read<RewardsProvider>();
        await rewardsProvider.applyDiscountToReservation(
          reservation.id,
          _priceCalculation!['appliedCoupon'] as String,
          'COUPON',
        );
      }

      // MODIFICADO: Mostrar diálogo de éxito con información de descuento
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
                    // NUEVO: Mostrar información de descuento si aplica
                    if (_priceCalculation != null && _priceCalculation!['discountApplied'] == true) ...[
                      Text(
                        'Precio original: S/ ${_priceCalculation!['basePrice'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Descuento: -S/ ${_priceCalculation!['discountAmount'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Total: S/ ${_finalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Estacionamiento: ${widget.parking.location.address}'),
                    const SizedBox(height: 4),
                    Text('Desde: ${_formatDateTime(startDateTime)}'),
                    Text('Hasta: ${_formatDateTime(endDateTime)}'),
                    const SizedBox(height: 4),
                    Text('Estado: ${statusText(reservation.status)}'),
                    // NUEVO: Mostrar cupón utilizado
                    if (_priceCalculation != null && _priceCalculation!['appliedCoupon'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Cupón utilizado: ${_priceCalculation!['appliedCoupon']}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
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

  // NUEVO: Widget para mostrar información de descuento
  Widget _buildDiscountInfo() {
    if (_priceCalculation == null || _isCalculatingPrice) {
      return const SizedBox.shrink();
    }

    final bool hasDiscount = _priceCalculation!['discountApplied'] == true;

    if (!hasDiscount) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                '¡Descuento aplicado automáticamente!',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cupón: ${_priceCalculation!['appliedCoupon']}',
            style: TextStyle(color: Colors.green[600]),
          ),
          Text(
            'Ahorro: S/ ${_priceCalculation!['discountAmount'].toStringAsFixed(2)}',
            style: TextStyle(color: Colors.green[600]),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // NUEVO: Cargar recompensas del usuario al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserRewards();
    });
  }

  // NUEVO: Cargar recompensas del usuario
  Future<void> _loadUserRewards() async {
    try {
      final userId = await preferences.getUserId();
      final rewardsProvider = context.read<RewardsProvider>();
      await rewardsProvider.loadAvailableRewards(userId);
    } catch (e) {
      print('Error loading user rewards: $e');
    }
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

              // NUEVO: Información de descuento
              _buildDiscountInfo(),

              // Resumen de precio (MODIFICADO para mostrar descuento)
              if (_totalPrice > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      // NUEVO: Mostrar precio original si hay descuento
                      if (_priceCalculation != null && _priceCalculation!['discountApplied'] == true) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Precio original:'),
                            Text(
                              'S/ ${_priceCalculation!['basePrice'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Descuento:',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                            Text(
                              '-S/ ${_priceCalculation!['discountAmount'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total a pagar:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // NUEVO: Mostrar indicador de carga o precio final
                          _isCalculatingPrice
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(
                            'S/ ${_finalPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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