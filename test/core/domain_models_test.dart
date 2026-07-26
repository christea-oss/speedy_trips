import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_trips/models/ride.dart';
import 'package:speedy_trips/models/ride_status.dart';
import 'package:speedy_trips/models/user_role.dart';
import 'package:speedy_trips/models/vehicle_type.dart';

void main() {
  group('UserRole', () {
    test('maps rider, driver, and admin ids', () {
      expect(userRoleFromId('rider'), UserRole.rider);
      expect(userRoleFromId('driver'), UserRole.driver);
      expect(userRoleFromId('admin'), UserRole.admin);
    });

    test('rejects unknown ids', () {
      expect(() => userRoleFromId('guest'), throwsArgumentError);
    });
  });

  group('RideStatus', () {
    test('maps supported status ids including legacy aliases', () {
      expect(rideStatusFromId('pending'), RideStatus.pending);
      expect(rideStatusFromId('requested'), RideStatus.pending);
      expect(rideStatusFromId('accepted'), RideStatus.accepted);
      expect(rideStatusFromId('arriving'), RideStatus.arriving);
      expect(rideStatusFromId('in_progress'), RideStatus.inProgress);
      expect(rideStatusFromId('completed'), RideStatus.completed);
      expect(rideStatusFromId('cancelled'), RideStatus.cancelled);
      expect(rideStatusFromId('canceled'), RideStatus.cancelled);
      expect(rideStatusFromId('declined'), RideStatus.cancelled);
    });

    test('rejects unknown status ids', () {
      expect(() => rideStatusFromId('on_hold'), throwsArgumentError);
    });
  });

  group('VehicleType', () {
    test('maps supported vehicle ids', () {
      expect(vehicleTypeFromId('black_ride'), VehicleType.blackRide);
      expect(vehicleTypeFromId('black_suv'), VehicleType.blackSuv);
    });

    test('rejects unknown vehicle ids', () {
      expect(() => vehicleTypeFromId('sedan'), throwsArgumentError);
    });
  });

  group('Ride', () {
    test('derives labels and scheduled date-time from fields', () {
      final ride = Ride(
        id: 'ride-1',
        pickupLocation: 'Pickup',
        dropoffLocation: 'Dropoff',
        zone: 'Zone 1 - Central Birmingham',
        vehicleType: VehicleType.blackSuv,
        rideType: 'Scheduled Ride',
        fare: 52,
        status: RideStatus.pending,
        createdAt: DateTime(2026, 1, 1),
        scheduledDate: DateTime(2026, 1, 2),
        scheduledTime: const TimeOfDay(hour: 14, minute: 30),
      );

      expect(ride.priceLabel, r'$52');
      expect(ride.rideTypeLabel, 'Scheduled Ride');
      expect(ride.isScheduled, isTrue);
      expect(ride.effectiveScheduledDateTime, DateTime(2026, 1, 2, 14, 30));
    });

    test('copyWith preserves existing data unless overridden', () {
      final ride = Ride(
        id: 'ride-2',
        pickupLocation: 'Pickup',
        dropoffLocation: 'Dropoff',
        zone: 'Zone 2 - South Metro',
        vehicleType: VehicleType.blackRide,
        rideType: 'Ride Now',
        fare: 35,
        status: RideStatus.accepted,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = ride.copyWith(
        status: RideStatus.completed,
        riderRating: 5,
      );

      expect(updated.id, 'ride-2');
      expect(updated.status, RideStatus.completed);
      expect(updated.riderRating, 5);
      expect(updated.pickupLocation, 'Pickup');
    });
  });
}
