import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/model/model.dart';
import 'package:homeypark_mobile_application/model/reservation.dart';
import 'package:homeypark_mobile_application/screens/reservation_detail_screen.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/reservation_service.dart';
import 'package:homeypark_mobile_application/widgets/widgets.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  var _loading = true;
  var _reservationsList = <Reservation>[];

  var _incomingReservationsList = <Reservation>[];
  var _pastReservationsList = <Reservation>[];
  var _inProgressReservationList = <Reservation>[];

  Future onTapReservation(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReservationDetailScreen(id: id)),
    );

    _loadGuestReservations();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _loading = true;
    });
    _loadGuestReservations();
  }

// Dentro de _loadGuestReservations, agrega estos logs
  void _loadGuestReservations() async {
    setState(() {
      _loading = true;
    });

    final reservations = await ReservationService.getReservationsByGuestId(
        await preferences.getUserId());

    // Depuración para ver el resultado
    debugPrint("⚡️ Total reservaciones obtenidas: ${reservations.length}");

    final incomingReservations = reservations
        .where((reservation) =>
    reservation.status == ReservationStatus.pending ||
        reservation.status == ReservationStatus.approved)
        .toList();
    debugPrint("⚡️ Próximas reservaciones: ${incomingReservations.length}");

    final pastReservations = reservations
        .where((reservation) =>
    reservation.status == ReservationStatus.completed ||
        reservation.status == ReservationStatus.cancelled)
        .toList();
    debugPrint("⚡️ Reservaciones pasadas: ${pastReservations.length}");

    final inProgressReservations = reservations
        .where((reservation) => reservation.status == ReservationStatus.inProgress)
        .toList();
    debugPrint("⚡️ En progreso: ${inProgressReservations.length}");

    setState(() {
      _reservationsList = reservations;
      _incomingReservationsList = incomingReservations;
      _pastReservationsList = pastReservations;
      _inProgressReservationList = inProgressReservations;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            "Mis reservas",
            style: theme.textTheme.titleMedium,
          ),
          backgroundColor: Colors.white,
          bottom: const TabBar(tabs: [
            Tab(text: "En progreso"),
            Tab(text: "Próximas"),
            Tab(text: "Pasadas"),
          ]),
        ),
        body: TabBarView(children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ..._inProgressReservationList.map((reservation) {
                        return FutureBuilder(
                            future: ParkingService.getParkingById(reservation.parkingId),
                            builder: (context, snapshot) {
                              if (snapshot.data == null) {
                                return const SizedBox();
                              }

                              return ReservationCard.fromReservation(
                                reservation: reservation,
                                address: snapshot.data!.location.address,
                                number: snapshot.data!.location.numDirection,
                                onTapReservation: onTapReservation,
                              );
                            });
                      }),
                    ],
                  ),
                ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ..._incomingReservationsList.map((reservation) {
                        return FutureBuilder(
                            future: ParkingService.getParkingById(reservation.parkingId),
                            builder: (context, snapshot) {
                              if (snapshot.data == null) {
                                return const SizedBox();
                              }

                              return ReservationCard.fromReservation(
                                reservation: reservation,
                                address: snapshot.data!.location.address,
                                number: snapshot.data!.location.numDirection,
                                onTapReservation: onTapReservation,
                              );
                            });
                      }),
                    ],
                  ),
                ),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ..._pastReservationsList.map((reservation) {
                        return FutureBuilder(
                            future: ParkingService.getParkingById(reservation.parkingId),
                            builder: (context, snapshot) {
                              if (snapshot.data == null) {
                                return const SizedBox();
                              }

                              return ReservationCard.fromReservation(
                                reservation: reservation,
                                address: snapshot.data!.location.address,
                                number: snapshot.data!.location.numDirection,
                                onTapReservation: onTapReservation,
                              );
                            });
                      }),
                    ],
                  ),
                ),
        ]),
      ),
    );
  }
}
