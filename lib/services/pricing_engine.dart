class FareEstimate {
  final int baseFare;
  final int airportPickupFee;
  final int scheduledRideFee;

  const FareEstimate({
    required this.baseFare,
    required this.airportPickupFee,
    required this.scheduledRideFee,
  });

  int get total => baseFare + airportPickupFee + scheduledRideFee;

  bool get hasAirportPickupFee => airportPickupFee > 0;

  bool get hasScheduledRideFee => scheduledRideFee > 0;
}

class PricingEngine {
  const PricingEngine._();

  static const int airportPickupFee = 10;
  static const int scheduledRideFee = 5;

  static const Map<String, int> zoneBaseFares = {
    'Zone 1 - Central Birmingham': 25,
    'Zone 2 - South Metro': 35,
    'Zone 3 - Hoover Corridor': 45,
    'Zone 4 - North Corridor': 50,
    'Zone 5 - East Corridor': 50,
    'Zone 6 - West Corridor': 55,
    'Zone 7 - Tuscaloosa Route': 90,
    'Zone 8 - Alabama Statewide': 125,
  };

  static FareEstimate estimate({
    required String? zone,
    required String pickupLocation,
    required String rideType,
  }) {
    final isScheduledRide = rideType.toLowerCase().contains('scheduled');

    return FareEstimate(
      baseFare: zone == null ? 0 : zoneBaseFares[zone] ?? 0,
      airportPickupFee:
          isAirportPickup(pickupLocation) ? airportPickupFee : 0,
      scheduledRideFee: isScheduledRide ? scheduledRideFee : 0,
    );
  }

  static bool isAirportPickup(String value) {
    final normalizedValue = _normalizeLocation(value);
    return normalizedValue.contains('bhm') ||
        normalizedValue.contains('birmingham airport') ||
        normalizedValue.contains('airport') ||
        normalizedValue.contains('door 4l') ||
        normalizedValue.contains('dl door 4l');
  }

  static String formatCurrency(int value) => '\$$value';

  static String _normalizeLocation(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}
