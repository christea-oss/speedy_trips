import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../models/ride_status.dart';
import '../models/vehicle_type.dart';
import '../services/firebase_bootstrap.dart';
import 'firestore_ride_repository.dart';

class RideRepository {
  RideRepository._();

  static final RideRepository instance = RideRepository._();

  FirestoreRideRepository? _firestoreRepository;
  final StreamController<void> _localRideChanges =
      StreamController<void>.broadcast();

  FirestoreRideRepository get _firestore {
    return _firestoreRepository ??= FirestoreRideRepository();
  }

  final List<Ride> _rides = [
    Ride(
      id: 'demo-driver-request',
      pickupLocation: 'BHM Airport',
      dropoffLocation: 'Zone 1 - Central Birmingham',
      zone: 'Zone 1 - Central Birmingham',
      vehicleType: VehicleType.blackSuv,
      rideType: 'Ride Now',
      fare: 25,
      status: RideStatus.requested,
      createdAt: DateTime.now(),
    ),
    Ride(
      id: 'history-1',
      pickupLocation: 'Birmingham Airport (BHM)',
      dropoffLocation: 'Zone 2 - South Metro',
      zone: 'Zone 2 - South Metro',
      vehicleType: VehicleType.blackSuv,
      rideType: 'Ride Now',
      fare: 45,
      status: RideStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Ride(
      id: 'history-2',
      pickupLocation: 'Birmingham Airport (BHM)',
      dropoffLocation: 'Zone 7 - Tuscaloosa Route',
      zone: 'Zone 7 - Tuscaloosa Route',
      vehicleType: VehicleType.blackRide,
      rideType: 'Scheduled Ride',
      fare: 100,
      status: RideStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  Stream<List<Ride>> watchRides() async* {
    if (FirebaseBootstrap.isEnabled) {
      try {
        await for (final rides in _firestore.watchRides()) {
          yield rides;
        }
        return;
      } catch (error) {
        if (!kIsWeb) {
          rethrow;
        }

        FirebaseBootstrap.disable(error);
      }
    }

    yield getLocalRides();
    await for (final _ in _localRideChanges.stream) {
      yield getLocalRides();
    }
  }

  Stream<List<Ride>> watchRequestedRides() async* {
    if (FirebaseBootstrap.isEnabled) {
      try {
        await for (final rides in _firestore.watchRequestedRides()) {
          yield rides;
        }
        return;
      } catch (error) {
        if (!kIsWeb) {
          rethrow;
        }

        FirebaseBootstrap.disable(error);
      }
    }

    yield _requestedLocalRides();
    await for (final _ in _localRideChanges.stream) {
      yield _requestedLocalRides();
    }
  }

  Stream<Ride?> watchRide(String rideId) async* {
    if (FirebaseBootstrap.isEnabled) {
      try {
        await for (final ride in _firestore.watchRide(rideId)) {
          yield ride;
        }
        return;
      } catch (error) {
        if (!kIsWeb) {
          rethrow;
        }

        FirebaseBootstrap.disable(error);
      }
    }

    yield _findLocalRide(rideId);
    await for (final _ in _localRideChanges.stream) {
      yield _findLocalRide(rideId);
    }
  }

  List<Ride> getLocalRides() {
    return List.unmodifiable(_rides.reversed);
  }

  Future<List<Ride>> getRides() async {
    if (FirebaseBootstrap.isEnabled) {
      try {
        return await _firestore.getRides();
      } catch (error) {
        if (!kIsWeb) {
          rethrow;
        }

        FirebaseBootstrap.disable(error);
      }
    }

    return getLocalRides();
  }

  Future<List<Ride>> getRideHistory() {
    return getRides();
  }

  Future<Ride?> getLatestDriverRequest() async {
    if (FirebaseBootstrap.isEnabled) {
      try {
        return await _firestore.getLatestDriverRequest();
      } catch (error) {
        if (!kIsWeb) {
          rethrow;
        }

        FirebaseBootstrap.disable(error);
      }
    }

    final requestedRides = _requestedLocalRides();
    if (requestedRides.isNotEmpty) {
      return requestedRides.first;
    }

    if (_rides.isNotEmpty) {
      return _rides.first;
    }

    return null;
  }

  Future<Ride> createRide({
    required String pickupLocation,
    required String dropoffLocation,
    required String zone,
    required VehicleType vehicleType,
    required String rideType,
    required int fare,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) async {
    if (FirebaseBootstrap.isEnabled) {
      try {
        final ride = await _firestore.createRide(
          pickupLocation: pickupLocation,
          dropoffLocation: dropoffLocation,
          zone: zone,
          vehicleType: vehicleType,
          rideType: rideType,
          fare: fare,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
        );
        _upsertLocalRide(ride);
        return ride;
      } catch (error) {
        if (!kIsWeb) {
          rethrow;
        }

        FirebaseBootstrap.disable(error);
      }
    }

    return _createLocalRide(
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      zone: zone,
      vehicleType: vehicleType,
      rideType: rideType,
      fare: fare,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
  }

  Future<Ride> updateRideStatus({
    required String rideId,
    required RideStatus status,
  }) async {
    if (FirebaseBootstrap.isEnabled) {
      try {
        final ride = await _firestore.updateRideStatus(
          rideId: rideId,
          status: status,
        );
        _upsertLocalRide(ride);
        return ride;
      } catch (error) {
        if (!kIsWeb) {
          rethrow;
        }

        FirebaseBootstrap.disable(error);
      }
    }

    final index = _rides.indexWhere((ride) => ride.id == rideId);

    if (index == -1) {
      throw ArgumentError.value(rideId, 'rideId', 'Ride not found');
    }

    final updatedRide = _rides[index].copyWith(status: status);
    _rides[index] = updatedRide;
    _notifyLocalRides();
    return updatedRide;
  }

  Future<Ride> cancelRide(String rideId) {
    return updateRideStatus(
      rideId: rideId,
      status: RideStatus.declined,
    );
  }

  Future<Ride> updateStatus(Ride ride, RideStatus status) async {
    try {
      return await updateRideStatus(
        rideId: ride.id,
        status: status,
      );
    } on ArgumentError {
      final updatedRide = ride.copyWith(status: status);
      _upsertLocalRide(updatedRide);
      _notifyLocalRides();
      return updatedRide;
    }
  }

  List<Ride> _requestedLocalRides() {
    return getLocalRides()
        .where((ride) => ride.status == RideStatus.requested)
        .toList();
  }

  Ride? _findLocalRide(String rideId) {
    for (final ride in _rides) {
      if (ride.id == rideId) {
        return ride;
      }
    }

    return null;
  }

  Ride _createLocalRide({
    required String pickupLocation,
    required String dropoffLocation,
    required String zone,
    required VehicleType vehicleType,
    required String rideType,
    required int fare,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) {
    final ride = Ride(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      zone: zone,
      vehicleType: vehicleType,
      rideType: rideType,
      fare: fare,
      status: RideStatus.requested,
      createdAt: DateTime.now(),
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );

    _rides.add(ride);
    _notifyLocalRides();
    return ride;
  }

  void _upsertLocalRide(Ride ride) {
    final index = _rides.indexWhere((localRide) => localRide.id == ride.id);

    if (index == -1) {
      _rides.add(ride);
      return;
    }

    _rides[index] = ride;
  }

  void _notifyLocalRides() {
    if (!_localRideChanges.isClosed) {
      _localRideChanges.add(null);
    }
  }
}
