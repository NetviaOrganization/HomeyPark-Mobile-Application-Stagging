import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/model/review.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/services/profile_service.dart';
import 'package:homeypark_mobile_application/services/review_service.dart';
import 'package:homeypark_mobile_application/model/profile.dart';
import 'package:homeypark_mobile_application/screens/reservation_form_screen.dart';
import 'package:homeypark_mobile_application/config/pref/preferences.dart';
import 'package:homeypark_mobile_application/widgets/verification_badge.dart';


class ParkingDetailScreen extends StatefulWidget {
  final int parkingId;

  const ParkingDetailScreen({super.key, required this.parkingId});

  @override
  State<ParkingDetailScreen> createState() => _ParkingDetailScreenState();
}

class _ParkingDetailScreenState extends State<ParkingDetailScreen> {
  late Future<Parking?> _parkingFuture;
  late Future<Profile?> _profileFuture;
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _parkingFuture = ParkingService.getParkingById(widget.parkingId);
    _reviewsFuture = ReviewService.getReviewsByParkingId(widget.parkingId);

    final profileService = Provider.of<ProfileService>(context, listen: false);
    _profileFuture = Future.value(null);

    _parkingFuture.then((parking) {
      if (parking != null) {
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

  void _showReviewDialog(Parking parking) {
    showDialog(
      context: context,
      builder: (context) => _ReviewDialog(
        parkingId: parking.id,
        onReviewSubmitted: () {
          setState(() {
            _reviewsFuture = ReviewService.getReviewsByParkingId(widget.parkingId);
            _parkingFuture = ParkingService.getParkingById(widget.parkingId);
          });
        },
      ),
    );
  }

  Future<String> _getUserFullName(int userId) async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final profile = await profileService.getProfileById(userId);
    if (profile != null) {
      return "${profile.firstName} ${profile.lastName}";
    }
    return "Usuario $userId";
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
                            // Rating Section
                            _buildRatingSection(theme, parking),
                            const SizedBox(height: 24),
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
                                          VerificationBadgeInline(
                                            isVerified: profile.verifiedEmail,
                                            userName: "${profile.firstName} ${profile.lastName}",
                                          ),
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
                            const SizedBox(height: 32),
                            // Reviews Section
                            _buildReviewsSection(theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

  Widget _buildRatingSection(ThemeData theme, Parking parking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 24),
          const SizedBox(width: 8),
          Text(
            parking.averageRating.toStringAsFixed(1),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            "(${parking.reviewCount} ${parking.reviewCount == 1 ? 'reseña' : 'reseñas'})",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          _buildStarRating(parking.averageRating),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star :
          index < rating ? Icons.star_half : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildReviewsSection(ThemeData theme) {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar comentarios'));
        }

        final reviews = snapshot.data ?? [];
        reviews.sort((a, b) => b.id.compareTo(a.id));
        final recentReviews = reviews.take(10).toList();

        if (recentReviews.isEmpty) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header con título y botón
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comentarios recientes',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FutureBuilder<Parking?>(
                        future: _parkingFuture,
                        builder: (context, parkingSnapshot) {
                          if (parkingSnapshot.hasData) {
                            return IconButton(
                              onPressed: () => _showReviewDialog(parkingSnapshot.data!),
                              icon: const Icon(Icons.rate_review),
                              tooltip: 'Escribir reseña',
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay comentarios aún. ¡Sé el primero en comentar!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título y botón
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comentarios recientes',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FutureBuilder<Parking?>(
                      future: _parkingFuture,
                      builder: (context, parkingSnapshot) {
                        if (parkingSnapshot.hasData) {
                          return IconButton(
                            onPressed: () => _showReviewDialog(parkingSnapshot.data!),
                            icon: const Icon(Icons.rate_review),
                            tooltip: 'Escribir reseña',
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Lista de comentarios
                ...recentReviews.map((review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReviewCard(theme, review),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(ThemeData theme, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.primaryColor,
                child: FutureBuilder<String>(
                  future: _getUserFullName(review.userId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final name = snapshot.data!;
                      return Text(
                        name.split(' ').map((word) => word.substring(0, 1).toUpperCase()).join(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }
                    return Text(
                      "U",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getUserFullName(review.userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text(
                            "Cargando...",
                            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                          );
                        }
                        return Text(
                          snapshot.data ?? "Usuario ${review.userId}",
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                    Row(
                      children: [
                        _buildStarRating(review.rating.toDouble()),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return "${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'} atrás";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'} atrás";
    } else {
      return "Hace un momento";
    }
  }

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

// Dialog para crear reseñas
class _ReviewDialog extends StatefulWidget {
  final int parkingId;
  final VoidCallback onReviewSubmitted;

  const _ReviewDialog({
    required this.parkingId,
    required this.onReviewSubmitted,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, agrega un comentario")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = await preferences.getUserId();

      await ReviewService.createReview(
        rating: _rating,
        comment: _commentController.text.trim(),
        parkingId: widget.parkingId,
        userId: userId,
      );

      widget.onReviewSubmitted();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reseña enviada exitosamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar la reseña: $e")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Calificar parking"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Calificación:"),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Text("Comentario:"),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Comparte tu experiencia...",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitReview,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Enviar"),
        ),
      ],
    );
  }
}