import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/reward.dart';
import '../model/rewards_progress.dart';
import '../model/available_rewards.dart';
import '../model/dto/redeem_reward_request.dart';
import '../model/dto/redeem_reward_response.dart';
import '../model/dto/apply_discount_request.dart';
import '../model/dto/apply_discount_response.dart';
import 'base_service.dart';

class RewardsService extends BaseService {
  RewardsService() : super();

  // TB10 - Obtener progreso hacia recompensas
  Future<RewardsProgress?> getRewardsProgress(int userId) async {
    try {
      final response = await http.get('/profiles/$userId/rewards/progress' as Uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RewardsProgress.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting rewards progress: $e');
      return null;
    }
  }

  // TB10 - Obtener conteo de reservas del usuario
  Future<Map<String, int>?> getReservationCount(int userId) async {
    try {
      final response = await http.get('/reservations/user/$userId/count' as Uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'totalReservations': data['totalReservations'] as int,
          'completedReservations': data['completedReservations'] as int,
          'pendingReservations': data['pendingReservations'] as int,
          'cancelledReservations': data['cancelledReservations'] as int,
        };
      }
      return null;
    } catch (e) {
      print('Error getting reservation count: $e');
      return null;
    }
  }

  // TB11 - Obtener recompensas disponibles
  Future<AvailableRewards?> getAvailableRewards(int userId) async {
    try {
      final response = await http.get('/profiles/$userId/rewards/available' as Uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AvailableRewards.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting available rewards: $e');
      return null;
    }
  }

  // TB11 - Canjear recompensa
  Future<RedeemRewardResponse?> redeemReward(int userId, RedeemRewardRequest request) async {
    try {
      final response = await http.post(
        '/profiles/$userId/rewards/redeem' as Uri,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RedeemRewardResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error redeeming reward: $e');
      return null;
    }
  }

  // TB11 - Aplicar descuento a reserva
  Future<ApplyDiscountResponse?> applyDiscountToReservation(
      int reservationId,
      ApplyDiscountRequest request
      ) async {
    try {
      final response = await http.post(
        '/reservations/$reservationId/apply-discount' as Uri,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApplyDiscountResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error applying discount: $e');
      return null;
    }
  }

  // Verificar elegibilidad para recompensas
  Future<Map<String, dynamic>?> checkRewardEligibility(int userId) async {
    try {
      final response = await http.get('/profiles/$userId/rewards/eligibility' as Uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'isEligible': data['isEligible'] as bool,
          'completedReservations': data['completedReservations'] as int,
          'requiredReservations': data['requiredReservations'] as int,
          'availableRewardTypes': List<String>.from(data['availableRewardTypes']),
        };
      }
      return null;
    } catch (e) {
      print('Error checking reward eligibility: $e');
      return null;
    }
  }

  // Calcular precio con descuento
  Future<Map<String, dynamic>?> calculatePriceWithDiscount({
    required String parkingId,
    required DateTime startTime,
    required DateTime endTime,
    String? couponCode,
  }) async {
    try {
      final requestBody = {
        'parkingId': parkingId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        if (couponCode != null) 'couponCode': couponCode,
      };

      final response = await http.post(
        '/reservations/calculate-price' as Uri,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'basePrice': (data['basePrice'] as num).toDouble(),
          'discountAmount': (data['discountAmount'] as num).toDouble(),
          'finalPrice': (data['finalPrice'] as num).toDouble(),
          'discountApplied': data['discountApplied'] as bool,
          'appliedCoupon': data['appliedCoupon'] as String?,
        };
      }
      return null;
    } catch (e) {
      print('Error calculating price: $e');
      return null;
    }
  }
}