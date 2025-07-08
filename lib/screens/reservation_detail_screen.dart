import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homeypark_mobile_application/model/model.dart';
import 'package:homeypark_mobile_application/model/vehicle.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/reservation_service.dart';
import 'package:homeypark_mobile_application/services/vehicle_service.dart';
import 'package:homeypark_mobile_application/widgets/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/rewards_provider.dart'; // NUEVO
import '../model/dto/apply_discount_response.dart'; // NUEVO

class ReservationDetailScreen extends StatefulWidget {
  final int id;

  const ReservationDetailScreen({super.key, required this.id});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _loading = true;

  late ReservationStatus _status;
  late DateTime _createdDate;
  late TimeOfDay _startTime;
  late DateTime _startDateTime;
  late TimeOfDay _endTime;
  late DateTime _endDateTime;
  late int _parkingId;
  late int _vehicleId;
  Vehicle? _vehicle;

  // NUEVO: Variables para información de descuentos
  bool _loadingDiscountInfo = false;
  ApplyDiscountResponse? _appliedDiscount;
  double? _originalPrice;
  double? _finalPrice;

  @override
  void initState() {
    super.initState();
    _fetchReservation();
  }

  void _fetchReservation() async {
    final reservation = await ReservationService.getReservationById(widget.id);

    setState(() {
      _loading = false;
      _status = reservation.status;
      _createdDate = reservation.createdAt;
      _startDateTime = reservation.startDateTime;
      _startTime = TimeOfDay(
          hour: reservation.startDateTime.hour,
          minute: reservation.startDateTime.minute);
      _endDateTime = reservation.endDateTime;
      _endTime = TimeOfDay(
          hour: reservation.endDateTime.hour,
          minute: reservation.endDateTime.minute);
      _parkingId = reservation.parkingId;
      _vehicleId = reservation.vehicleId;
      // NUEVO: Capturar precios si están disponibles
      _finalPrice = reservation.totalFare;
    });

    // Cargar datos del vehículo
    _loadVehicleData();

    // NUEVO: Cargar información de descuentos
    _loadDiscountInformation();
  }

  void _loadVehicleData() async {
    // 1. Obtiene la instancia del servicio usando Provider.
    //    Usamos `context.read` porque estamos fuera del método `build` y solo
    //    necesitamos llamar a una acción, no escuchar cambios.
    final vehicleService = context.read<VehicleService>();

    // 2. Llama al método de instancia en el objeto `vehicleService`.
    final vehicle = await vehicleService.getVehicleById(_vehicleId);

    // 3. Verificamos si el widget sigue "montado" antes de llamar a setState.
    //    Esta es una buena práctica obligatoria para evitar errores si el
    //    usuario navega fuera de la pantalla mientras se cargan los datos.
    if (mounted && vehicle != null) {
      setState(() {
        _vehicle = vehicle;
      });
    }
  }

  // NUEVO: Cargar información de descuentos aplicados
  void _loadDiscountInformation() async {
    setState(() {
      _loadingDiscountInfo = true;
    });

    try {
      final rewardsProvider = context.read<RewardsProvider>();

      // Verificar si esta reserva tiene descuentos aplicados
      // Esto se puede hacer de varias maneras dependiendo de como se almacene la información
      // Por ahora, verificaremos si hay descuentos recientes aplicados
      final lastDiscount = rewardsProvider.lastDiscountApplied;

      // También podríamos verificar a través del servicio si se necesita
      // final discountInfo = await RewardsService.getReservationDiscountInfo(widget.id);

      if (mounted) {
        setState(() {
          _appliedDiscount = lastDiscount;
          _loadingDiscountInfo = false;
        });
      }
    } catch (e) {
      print('Error loading discount information: $e');
      if (mounted) {
        setState(() {
          _loadingDiscountInfo = false;
        });
      }
    }
  }

  void _cancelReservation() async {
    Navigator.pop(context, "Ok");

    await ReservationService.cancelReservation(widget.id);

    setState(() {
      _status = ReservationStatus.cancelled;
    });
  }

  void _showCancelAlertDialog() {
    final theme = Theme.of(context);

    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          title:
          Text("Cancelar reserva", style: theme.textTheme.titleMedium),
          content: Text(
            "¿Estas seguro de cancelar esta reserva? Esta acción es irreversible y no se mostrara tu publicación.",
            style: theme.textTheme.bodyMedium
                ?.apply(color: theme.colorScheme.onSurfaceVariant),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context, 'Close');
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.tertiary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Cerrar",
                  style: TextStyle(color: theme.colorScheme.tertiary)),
            ),
            FilledButton(
                onPressed: _cancelReservation,
                style: FilledButton.styleFrom(
                  overlayColor: theme.colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  backgroundColor: theme.colorScheme.error,
                ),
                child: const Text("Cancelar")),
          ],
        ));
  }

  // NUEVO: Widget para mostrar información de descuentos aplicados
  Widget _buildDiscountInformation() {
    if (_loadingDiscountInfo) {
      return CardWithHeader(
        headerTextStr: "Información de pago",
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Calcular precio original basado en las horas y parking
    return FutureBuilder(
      future: ParkingService.getParkingById(_parkingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CardWithHeader(
            headerTextStr: "Información de pago",
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final parking = snapshot.data!;
        final duration = _endDateTime.difference(_startDateTime);
        final hours = duration.inMinutes / 60.0;
        final calculatedOriginalPrice = hours * parking.price;

        final hasDiscount = _appliedDiscount != null &&
            _appliedDiscount!.success &&
            _finalPrice != null &&
            _finalPrice! < calculatedOriginalPrice;

        return CardWithHeader(
          headerTextStr: "Información de pago",
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duración
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Duración:",
                    style: Theme.of(context).textTheme.labelMedium?.apply(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "${hours.toStringAsFixed(1)} horas",
                    style: Theme.of(context).textTheme.bodySmall?.apply(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tarifa por hora
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tarifa:",
                    style: Theme.of(context).textTheme.labelMedium?.apply(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    "S/ ${parking.price.toStringAsFixed(2)}/hora",
                    style: Theme.of(context).textTheme.bodySmall?.apply(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),

              // NUEVO: Mostrar información de descuento si aplica
              if (hasDiscount) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Precio original
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Precio original:",
                      style: Theme.of(context).textTheme.labelMedium?.apply(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      "S/ ${calculatedOriginalPrice.toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.bodySmall?.apply(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Descuento aplicado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 16,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Descuento:",
                          style: Theme.of(context).textTheme.labelMedium?.apply(
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "-S/ ${(calculatedOriginalPrice - _finalPrice!).toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Información del cupón
                if (_appliedDiscount?.appliedCoupon != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Cupón usado:",
                        style: Theme.of(context).textTheme.labelSmall?.apply(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          _appliedDiscount!.appliedCoupon,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
              ],

              // Total final
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total pagado:",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "S/ ${(_finalPrice ?? calculatedOriginalPrice).toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // NUEVO: Mensaje de ahorro si hay descuento
              if (hasDiscount) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.savings,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "¡Ahorraste S/ ${(calculatedOriginalPrice - _finalPrice!).toStringAsFixed(2)} con tus recompensas!",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _status);
          },
        ),
        title: Text(
          "Detalles de reserva",
          style: theme.textTheme.titleMedium,
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _loading
                ? Container()
                : ReservationBadgeStatus(status: _status),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder(
                  future: ParkingService.getParkingById(_parkingId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
                    final location = snapshot.data!.location;
                    final latitude = location.latitude;
                    final longitude = location.longitude;

                    return Stack(
                      children: [
                        Image.network(
                          "https://maps.googleapis.com/maps/api/streetview?size=600x400&location=$latitude,$longitude&key=$apiKey",
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        ),
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color.fromRGBO(0, 0, 0, 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          bottom: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${location.address} ${location.numDirection}",
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${location.district}, ${location.street}, ${location.city}",
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
            ),
            const SizedBox(height: 16),
            CardWithHeader(
                headerTextStr: "Horario",
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Creado:",
                        style: theme.textTheme.labelMedium
                            ?.apply(color: theme.colorScheme.onSurface)),
                    Text(
                        "${_createdDate.day}/${_createdDate.month}/${_createdDate.year} ${_createdDate.hour.toString().padLeft(2, "0")}:${_createdDate.minute.toString().padLeft(2, "0")}:${_createdDate.second.toString().padLeft(2, "0")}",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 20),
                    Text("Horario de reserva:",
                        style: theme.textTheme.labelMedium
                            ?.apply(color: theme.colorScheme.onSurface)),
                    Text(
                        "Desde: ${_startTime.format(context).toString()} - ${_startDateTime.day}/${_startDateTime.month}/${_startDateTime.year}",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                    Text(
                        "Hasta: ${_endTime.format(context).toString()} - ${_endDateTime.day}/${_endDateTime.month}/${_endDateTime.year}",
                        style: theme.textTheme.bodySmall
                            ?.apply(color: theme.colorScheme.onSurface)),
                  ],
                )),
            const SizedBox(height: 16),

            // NUEVO: Información de pago y descuentos
            _buildDiscountInformation(),
            const SizedBox(height: 16),

            CardWithHeader(
                headerTextStr: "Información adicional",
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car_outlined),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_vehicle?.licensePlate ?? "Cargando...",
                                style: theme.textTheme.labelMedium?.apply(
                                  color: theme.colorScheme.onSurface,
                                )),
                            Text(
                                _vehicle != null
                                    ? "${_vehicle!.brand} ${_vehicle!.model}"
                                    : "Cargando...",
                                style: theme.textTheme.labelSmall?.apply(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        )
                      ],
                    ),
                  ],
                )),
            const SizedBox(height: 16),
            if (_status == ReservationStatus.pending)
              CardWithHeader(
                headerTextStr: "Cancelar reserva",
                body: Column(children: [
                  Text(
                    "Puedes cancelar tu reserva hasta 6 horas antes de la hora programada para recibir un reembolso completo del pago realizado.",
                    style: theme.textTheme.bodySmall?.apply(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error),
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _showCancelAlertDialog,
                      child: Text(
                        "Cancelar reserva",
                        style: TextStyle(color: theme.colorScheme.error),
                      )),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}