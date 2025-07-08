import 'package:flutter/material.dart';
import '../model/reward.dart';
import '../model/rewards_progress.dart';
import '../model/available_rewards.dart';
import '../model/dto/redeem_reward_request.dart';
import '../model/dto/redeem_reward_response.dart';
import '../model/dto/apply_discount_request.dart';
import '../model/dto/apply_discount_response.dart';
import '../services/rewards_service.dart';

class RewardsProvider extends ChangeNotifier {
  final RewardsService _rewardsService = RewardsService();

  // Estado para TB10 - Progreso de recompensas
  RewardsProgress? _rewardsProgress;
  Map<String, int>? _reservationCount;
  bool _isLoadingProgress = false;

  // Estado para TB11 - Recompensas disponibles y canje
  AvailableRewards? _availableRewards;
  List<RedeemRewardResponse> _redeemedRewards = [];
  bool _isLoadingRewards = false;
  bool _isRedeeming = false;

  // Estado para descuentos
  ApplyDiscountResponse? _lastDiscountApplied;
  Map<String, dynamic>? _priceCalculation;
  bool _isApplyingDiscount = false;

  // Getters para TB10
  RewardsProgress? get rewardsProgress => _rewardsProgress;
  Map<String, int>? get reservationCount => _reservationCount;
  bool get isLoadingProgress => _isLoadingProgress;

  // Getters para TB11
  AvailableRewards? get availableRewards => _availableRewards;
  List<RedeemRewardResponse> get redeemedRewards => _redeemedRewards;
  bool get isLoadingRewards => _isLoadingRewards;
  bool get isRedeeming => _isRedeeming;

  // Getters para descuentos
  ApplyDiscountResponse? get lastDiscountApplied => _lastDiscountApplied;
  Map<String, dynamic>? get priceCalculation => _priceCalculation;
  bool get isApplyingDiscount => _isApplyingDiscount;

  // Computed properties
  bool get hasAvailableRewards =>
      _availableRewards?.hasActiveRewards ?? false;

  int get completedReservations =>
      _rewardsProgress?.completedReservations ?? 0;

  double get progressPercentage =>
      _rewardsProgress?.progressPercentage ?? 0.0;

  bool get isEligibleForReward =>
      _rewardsProgress?.isEligibleForReward ?? false;

  // TB10 - Métodos para progreso de recompensas
  Future<void> loadRewardsProgress(int userId) async {
    _isLoadingProgress = true;
    notifyListeners();

    try {
      _rewardsProgress = await _rewardsService.getRewardsProgress(userId);
      _reservationCount = await _rewardsService.getReservationCount(userId);
    } catch (e) {
      print('Error loading rewards progress: $e');
    } finally {
      _isLoadingProgress = false;
      notifyListeners();
    }
  }

  // TB11 - Métodos para recompensas disponibles
  Future<void> loadAvailableRewards(int userId) async {
    _isLoadingRewards = true;
    notifyListeners();

    try {
      _availableRewards = await _rewardsService.getAvailableRewards(userId);
    } catch (e) {
      print('Error loading available rewards: $e');
    } finally {
      _isLoadingRewards = false;
      notifyListeners();
    }
  }

  // TB11 - Canjear recompensa
  Future<bool> redeemReward(int userId, String rewardId, String rewardType) async {
    _isRedeeming = true;
    notifyListeners();

    try {
      final request = RedeemRewardRequest(
        rewardId: rewardId,
        rewardType: rewardType,
      );

      final response = await _rewardsService.redeemReward(userId, request);

      if (response != null && response.success) {
        _redeemedRewards.add(response);
        // Recargar recompensas disponibles y progreso
        await loadAvailableRewards(userId);
        await loadRewardsProgress(userId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error redeeming reward: $e');
      return false;
    } finally {
      _isRedeeming = false;
      notifyListeners();
    }
  }

  // TB11 - Aplicar descuento a reserva
  Future<bool> applyDiscountToReservation(
      int reservationId,
      String couponCode,
      String discountType,
      ) async {
    _isApplyingDiscount = true;
    notifyListeners();

    try {
      final request = ApplyDiscountRequest(
        couponCode: couponCode,
        discountType: discountType,
      );

      final response = await _rewardsService.applyDiscountToReservation(
        reservationId,
        request,
      );

      if (response != null && response.success) {
        _lastDiscountApplied = response;
        return true;
      }
      return false;
    } catch (e) {
      print('Error applying discount: $e');
      return false;
    } finally {
      _isApplyingDiscount = false;
      notifyListeners();
    }
  }

  // Calcular precio con descuento
  Future<void> calculatePriceWithDiscount({
    required String parkingId,
    required DateTime startTime,
    required DateTime endTime,
    String? couponCode,
  }) async {
    try {
      _priceCalculation = await _rewardsService.calculatePriceWithDiscount(
        parkingId: parkingId,
        startTime: startTime,
        endTime: endTime,
        couponCode: couponCode,
      );
      notifyListeners();
    } catch (e) {
      print('Error calculating price: $e');
    }
  }

  // Verificar elegibilidad para recompensas
  Future<Map<String, dynamic>?> checkRewardEligibility(int userId) async {
    try {
      return await _rewardsService.checkRewardEligibility(userId);
    } catch (e) {
      print('Error checking eligibility: $e');
      return null;
    }
  }

  // Métodos utilitarios
  void clearDiscountApplication() {
    _lastDiscountApplied = null;
    notifyListeners();
  }

  void clearPriceCalculation() {
    _priceCalculation = null;
    notifyListeners();
  }

  // Obtener recompensa específica por ID
  Reward? getRewardById(String id) {
    return _availableRewards?.availableRewards
        .firstWhere((reward) => reward.id == id);
  }

  // Verificar si tiene cupones activos
  bool hasActiveCoupons() {
    return _redeemedRewards.any((reward) =>
        reward.expirationDate.isAfter(DateTime.now()));
  }

  // Obtener cupones activos
  List<RedeemRewardResponse> getActiveCoupons() {
    return _redeemedRewards.where((reward) =>
        reward.expirationDate.isAfter(DateTime.now())).toList();
  }

  // Limpiar todo el estado
  void clearAll() {
    _rewardsProgress = null;
    _reservationCount = null;
    _availableRewards = null;
    _redeemedRewards.clear();
    _lastDiscountApplied = null;
    _priceCalculation = null;
    _isLoadingProgress = false;
    _isLoadingRewards = false;
    _isRedeeming = false;
    _isApplyingDiscount = false;
    notifyListeners();
  }
}