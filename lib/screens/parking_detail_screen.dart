import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart'; // 1. Importa Provider
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/profile_service.dart';
import 'package:homeypark_mobile_application/model/profile.dart';
import 'package:homeypark_mobile_application/screens/reservation_form_screen.dart';

// 2. Convertimos el widget a un StatefulWidget para usar initState
class ParkingDetailScreen extends StatefulWidget {
  final int parkingId;

  const ParkingDetailScreen({super.key, required this.parkingId});

  @override
  State<ParkingDetailScreen> createState() => _ParkingDetailScreenState();
}

class _ParkingDetailScreenState extends State<ParkingDetailScreen> {
  // 3. Creamos variables Future en el estado para almacenar los resultados de la API
  late Future<Parking?> _parkingFuture;
  late Future<Profile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    // 4. Realizamos las llamadas a la API UNA SOLA VEZ, al iniciar la pantalla
    _parkingFuture = ParkingService.getParkingById(widget.parkingId);

    // Obtenemos la instancia de ProfileService usando Provider
    final profileService = Provider.of<ProfileService>(context, listen: false);

    // Inicializamos el Future del perfil como nulo, lo cargaremos después
    _profileFuture = Future.value(null);

    // Encadenamos la segunda llamada a la API para que se ejecute después de la primera
    _parkingFuture.then((parking) {
      if (parking != null) {
        // Una vez que tenemos el parking, usamos su `profileId` para buscar el perfil
        setState(() {
          _profileFuture = profileService.getProfileById(parking.profileId);
        });
      }
    });
  }

  String _getMonthName(int month) {
    const months = ["", "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalles del garaje", style: theme.textTheme.titleMedium),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      // 5. El cuerpo ahora usa el `_parkingFuture` que definimos en el estado
      body: FutureBuilder<Parking?>(
        future: _parkingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No se pudo cargar la información del garaje."));
          }

          final parking = snapshot.data!;
          final latitude = parking.location.latitude;
          final longitude = parking.location.longitude;
          final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Image.network(
                            "https://maps.googleapis.com/maps/api/streetview?size=600x400&location=$latitude,$longitude&key=$apiKey",
                            fit: BoxFit.cover, height: 240, width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(height: 240, width: double.infinity, color: Colors.grey[300], child: const Center(child: Icon(Icons.error_outline, color: Colors.grey, size: 40))),
                          ),
                          Container(width: double.infinity, height: 240, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color.fromRGBO(0, 0, 0, 0.6), Colors.transparent]))),
                          Positioned(
                            left: 16, bottom: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${parking.location.address} ${parking.location.numDirection}", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text("${parking.location.district}, ${parking.location.street}, ${parking.location.city}", style: theme.textTheme.labelMedium?.copyWith(color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoColumn(theme, Icons.money, "S/ ${parking.price.toStringAsFixed(2)}", "Precio/hora"),
                                _buildInfoColumn(theme, Icons.garage, "${parking.space} libres", "Espacios"),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text("Propietario", style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const CircleAvatar(radius: 20, backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/1.jpg")),
                                const SizedBox(width: 16),
                                // 6. El FutureBuilder anidado ahora usa `_profileFuture`
                                Expanded(
                                  child: FutureBuilder<Profile?>(
                                    future: _profileFuture,
                                    builder: (context, profileSnapshot) {
                                      if (profileSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Text("Cargando datos del propietario...");
                                      }
                                      if (!profileSnapshot.hasData || profileSnapshot.data == null) {
                                        return const Text("Información no disponible");
                                      }
                                      final profile = profileSnapshot.data!;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("${profile.firstName} ${profile.lastName}", style: theme.textTheme.labelLarge),
                                          Text("Se unió desde ${_getMonthName(profile.createdAt.month)}, ${profile.createdAt.year}", style: theme.textTheme.bodySmall),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text("Descripción", style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(parking.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // El bottomSheet ahora está fuera del SingleChildScrollView
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 16)],
                ),
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReservationFormScreen(parking: parking))),
                  style: ButtonStyle(shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                  child: const Text("Reservar"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget helper para no repetir código
  Widget _buildInfoColumn(ThemeData theme, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor),
        Text(value, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}