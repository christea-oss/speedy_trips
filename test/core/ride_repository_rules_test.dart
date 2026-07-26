import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_trips/models/ride_status.dart';
import 'package:speedy_trips/models/vehicle_type.dart';
import 'package:speedy_trips/repositories/ride_repository.dart';

void main() {
  group('RideRepository local rules', () {
    test('creates a scheduled ride with a combined date-time', () async {
      final ride = await RideRepository.instance.createRide(
        pickupLocation: 'Pickup',
        dropoffLocation: 'Dropoff',
        zone: 'Zone 1 - Central Birmingham',
        vehicleType: VehicleType.blackSuv,
        rideType: 'Scheduled Ride',
        fare: 52,
        scheduledDate: DateTime(2026, 5, 26),
        scheduledTime: const TimeOfDay(hour: 14, minute: 30),
        requireFirestore: false,
      );

      expect(ride.status, RideStatus.pending);
      expect(ride.isScheduled, isTrue);
      expect(ride.effectiveScheduledDateTime, DateTime(2026, 5, 26, 14, 30));
    });

    test(
      'rejects canceling a non-scheduled ride in the local fallback',
      () async {
        final ride = await RideRepository.instance.createRide(
          pickupLocation: 'Pickup',
          dropoffLocation: 'Dropoff',
          zone: 'Zone 1 - Central Birmingham',
          vehicleType: VehicleType.blackSuv,
          rideType: 'Ride Now',
          fare: 25,
          requireFirestore: false,
        );

        await expectLater(
          RideRepository.instance.cancelScheduledRide(ride.id),
          throwsStateError,
        );
      },
    );

    test('allows status transitions through the local fallback', () async {
      final ride = await RideRepository.instance.createRide(
        pickupLocation: 'Pickup',
        dropoffLocation: 'Dropoff',
        zone: 'Zone 2 - South Metro',
        vehicleType: VehicleType.blackRide,
        rideType: 'Ride Now',
        fare: 35,
        requireFirestore: false,
      );

      final accepted = await RideRepository.instance.acceptRide(ride.id);
      expect(accepted.status, RideStatus.accepted);

      final arriving = await RideRepository.instance.updateRideStatus(
        rideId: ride.id,
        status: RideStatus.arriving,
      );
      expect(arriving.status, RideStatus.arriving);

      final completed = await RideRepository.instance.updateRideStatus(
        rideId: ride.id,
        status: RideStatus.completed,
      );
      expect(completed.status, RideStatus.completed);
    });
  });
}
