import 'package:flutter/material.dart';
import 'package:homeypark_mobile_application/model/model.dart';
import 'package:homeypark_mobile_application/widgets/widgets.dart';
import '../model/reservation.dart';

class ReservationCard extends StatelessWidget {
  final int id;
  final String address;
  final String number;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ReservationStatus status;
  final Reservation? reservation;
  final Function(int)? onTapReservation;
  final bool? hasAction;
  final Function(int)? onCancel;
  final Function(int)? onAccept;
  final List<Widget>? actions;

  const ReservationCard({
    super.key,
    required this.id,
    required this.address,
    required this.number,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reservation,
    this.hasAction = false,
    this.onTapReservation,
    this.onCancel,
    this.onAccept,
    this.actions,
  });

  factory ReservationCard.fromReservation({
    required Reservation reservation,
    required String address,
    required String number,
    bool? hasAction,
    Function(int)? onTapReservation,
    Function(int)? onCancel,
    Function(int)? onAccept,
    List<Widget>? actions,
  }) {
    return ReservationCard(
      id: reservation.id,
      address: address,
      number: number,
      date: reservation.reservationDate,
      startTime: TimeOfDay.fromDateTime(reservation.startTime.toDateTime()),
      endTime: TimeOfDay.fromDateTime(reservation.endTime.toDateTime()),
      status: reservation.status,
      reservation: reservation,
      hasAction: hasAction,
      onTapReservation: onTapReservation,
      onCancel: onCancel,
      onAccept: onAccept,
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final dateStr = "$day/$month/${date.year}";

    return GestureDetector(
      onTap: () {
        onTapReservation?.call(id);
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        shadowColor: theme.colorScheme.primary.withAlpha(153) ?? Colors.grey.withAlpha(153),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$address $number",
                            style: theme.textTheme.bodyLarge
                                ?.apply(color: theme.colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis),
                        Text("#${id.toString().padLeft(7, "0")}",
                            style: theme.textTheme.bodyMedium?.apply(
                                color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis),
                        if (reservation != null) ...[
                          Text(
                            "${reservation!.hoursRegistered} hora${reservation!.hoursRegistered > 1 ? 's' : ''} • S/ ${reservation!.totalFare.toStringAsFixed(2)}",
                            style: theme.textTheme.bodySmall?.apply(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  ReservationBadgeStatus(status: status),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(248, 249, 250, 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text("Desde:",
                          style: theme.textTheme.bodySmall
                              ?.apply(color: theme.colorScheme.onSurface)),
                      const SizedBox(width: 12),
                      Text("${startTime.format(context).toString()} - $dateStr",
                          style: theme.textTheme.bodySmall
                              ?.apply(color: theme.colorScheme.onSurface)),
                    ],
                  )),
              const SizedBox(height: 4),
              Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(248, 249, 250, 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Text("Hasta:",
                          style: theme.textTheme.bodySmall
                              ?.apply(color: theme.colorScheme.onSurface)),
                      const SizedBox(width: 12),
                      Text("${endTime.format(context).toString()} - $dateStr",
                          style: theme.textTheme.bodySmall
                              ?.apply(color: theme.colorScheme.onSurface)),
                    ],
                  )),
              if (hasAction ?? false) ...[
                const SizedBox(height: 8),
                Row(children: actions ?? [])
              ]
            ],
          ),
        ),
      ),
    );
  }
}