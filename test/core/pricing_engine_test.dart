import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_trips/services/pricing_engine.dart';

void main() {
  group('PricingEngine', () {
    test('estimates base fare with airport and scheduled ride fees', () {
      final estimate = PricingEngine.estimate(
        zone: 'Zone 1 - Central Birmingham',
        pickupLocation: 'BHM Airport Door 4L',
        rideType: 'Scheduled Ride',
      );

      expect(estimate.baseFare, 25);
      expect(estimate.airportPickupFee, PricingEngine.airportPickupFee);
      expect(estimate.scheduledRideFee, PricingEngine.scheduledRideFee);
      expect(estimate.total, 40);
      expect(estimate.hasAirportPickupFee, isTrue);
      expect(estimate.hasScheduledRideFee, isTrue);
    });

    test('returns zero fees when the ride does not match fee rules', () {
      final estimate = PricingEngine.estimate(
        zone: 'Unknown Zone',
        pickupLocation: 'Downtown Birmingham',
        rideType: 'Ride Now',
      );

      expect(estimate.baseFare, 0);
      expect(estimate.airportPickupFee, 0);
      expect(estimate.scheduledRideFee, 0);
      expect(estimate.total, 0);
    });

    test('formats currency with a leading dollar sign', () {
      expect(PricingEngine.formatCurrency(125), r'$125');
    });
  });
}
