import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../models/ride_status.dart';
import '../models/vehicle_type.dart';
import '../services/auth_service.dart';

class FirestoreRideRepository {
  FirestoreRideRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rides {
    return _firestore.collection('rides');
  }

  Stream<List<Ride>> watchRides() {
    return _rides
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_rideFromSnapshot).toList());
  }

  Stream<List<Ride>> watchRiderRides() {
    final riderId = AuthService.instance.currentUser?.uid;

    if (riderId == null) {
      return Stream.value(const <Ride>[]);
    }

    return _rides
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_rideFromSnapshot).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Stream<List<Ride>> watchRequestedRides() {
    return watchPendingRides();
  }

  Stream<List<Ride>> watchPendingRides() {
    return _rides
        .where('status', isEqualTo: RideStatus.pending.id)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_rideFromSnapshot).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Stream<List<Ride>> watchAssignedDriverRides() {
    final driverId = AuthService.instance.currentUser?.uid;

    if (driverId == null) {
      return Stream.value(const <Ride>[]);
    }

    return _rides
        .where('assignedDriver', isEqualTo: driverId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_rideFromSnapshot).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Stream<Ride?> watchRide(String rideId) {
    return _rides.doc(rideId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return _rideFromSnapshot(snapshot);
    });
  }

  Future<List<Ride>> getRides() async {
    final snapshot = await _rides.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(_rideFromSnapshot).toList();
  }

  Future<Ride?> getLatestDriverRequest() async {
    final snapshot = await _rides
        .where('status', isEqualTo: RideStatus.pending.id)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final rides = snapshot.docs.map(_rideFromSnapshot).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rides.first;
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
    final riderId = AuthService.instance.currentUser?.uid;

    if (riderId == null) {
      throw StateError('A signed-in rider is required to book a ride.');
    }

    final document = _rides.doc();
    final scheduledDateTime = _combineScheduledDateTime(
      scheduledDate,
      scheduledTime,
    );
    final ride = Ride(
      id: document.id,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      zone: zone,
      vehicleType: vehicleType,
      rideType: rideType,
      fare: fare,
      status: RideStatus.pending,
      createdAt: DateTime.now(),
      riderId: riderId,
      scheduledDateTime: scheduledDateTime,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
    final rideData = _rideToFirestore(ride, riderId: riderId);

    debugPrint(
      'FirestoreRideRepository.createRide writing ride data: $rideData',
    );

    await document.set(rideData);

    debugPrint(
      'FirestoreRideRepository.createRide wrote ride document ID: ${document.id}',
    );

    return ride;
  }

  Future<Ride> updateRideStatus({
    required String rideId,
    required RideStatus status,
  }) async {
    final document = _rides.doc(rideId);

    await document.update({
      'status': status.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await document.get();
    return _rideFromSnapshot(snapshot);
  }

  Future<Ride> acceptRide(String rideId) async {
    final driverId = AuthService.instance.currentUser?.uid;

    if (driverId == null) {
      throw StateError('A signed-in driver is required to accept a ride.');
    }

    final document = _rides.doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        throw StateError('Ride is no longer available.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final status = rideStatusFromId(
        data['status'] as String? ?? RideStatus.pending.id,
      );
      final assignedDriver = data['assignedDriver'] as String?;

      if (status != RideStatus.pending || assignedDriver != null) {
        throw StateError('Ride was already accepted.');
      }

      transaction.update(document, {
        'assignedDriver': driverId,
        'driverId': driverId,
        'status': RideStatus.accepted.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final snapshot = await document.get();
    return _rideFromSnapshot(snapshot);
  }

  Future<Ride> cancelRide(String rideId) {
    return updateRideStatus(rideId: rideId, status: RideStatus.cancelled);
  }

  Future<Ride> cancelScheduledRide(String rideId) async {
    final riderId = AuthService.instance.currentUser?.uid;
    if (riderId == null) {
      throw StateError('A signed-in rider is required to cancel a ride.');
    }

    final document = _rides.doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        throw StateError('Ride was not found.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final status = rideStatusFromId(
        data['status'] as String? ?? RideStatus.pending.id,
      );
      final rideRiderId =
          _stringFromFirestore(data['riderId']) ??
          _stringFromFirestore(data['riderUid']);
      final assignedDriver =
          _stringFromFirestore(data['assignedDriver']) ??
          _stringFromFirestore(data['driverId']);

      if (rideRiderId != null && rideRiderId != riderId) {
        throw StateError('Only the rider who booked this trip can cancel it.');
      }

      if (!_firestoreDataIsScheduled(data)) {
        throw StateError('Only scheduled rides can be cancelled here.');
      }

      if (status != RideStatus.pending || assignedDriver != null) {
        throw StateError(
          'Scheduled rides can only be cancelled before accepted.',
        );
      }

      transaction.update(document, {
        'status': RideStatus.cancelled.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final snapshot = await document.get();
    return _rideFromSnapshot(snapshot);
  }

  Future<Ride> updateScheduledRideDateTime({
    required String rideId,
    required DateTime scheduledDate,
    required TimeOfDay scheduledTime,
  }) async {
    final riderId = AuthService.instance.currentUser?.uid;
    if (riderId == null) {
      throw StateError('A signed-in rider is required to edit a ride.');
    }

    final scheduledDateTime = _combineScheduledDateTime(
      scheduledDate,
      scheduledTime,
    );
    if (scheduledDateTime == null) {
      throw StateError('Scheduled ride date and time are required.');
    }

    final document = _rides.doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        throw StateError('Ride was not found.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final status = rideStatusFromId(
        data['status'] as String? ?? RideStatus.pending.id,
      );
      final rideRiderId =
          _stringFromFirestore(data['riderId']) ??
          _stringFromFirestore(data['riderUid']);
      final assignedDriver =
          _stringFromFirestore(data['assignedDriver']) ??
          _stringFromFirestore(data['driverId']);

      if (rideRiderId != null && rideRiderId != riderId) {
        throw StateError('Only the rider who booked this trip can edit it.');
      }

      if (!_firestoreDataIsScheduled(data)) {
        throw StateError('Only scheduled rides can be edited.');
      }

      if (status != RideStatus.pending || assignedDriver != null) {
        throw StateError('Scheduled rides can only be edited before accepted.');
      }

      transaction.update(document, {
        'rideType': 'scheduled',
        'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
        'ScheduledDateTime': Timestamp.fromDate(scheduledDateTime),
        'scheduledDate': Timestamp.fromDate(
          DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day),
        ),
        'scheduledTime': {
          'hour': scheduledTime.hour,
          'minute': scheduledTime.minute,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final snapshot = await document.get();
    return _rideFromSnapshot(snapshot);
  }

  Future<Ride> rateRide({required String rideId, required int rating}) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be 1-5.');
    }

    final riderId = AuthService.instance.currentUser?.uid;
    if (riderId == null) {
      throw StateError('A signed-in rider is required to rate a ride.');
    }

    final document = _rides.doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        throw StateError('Ride was not found.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final status = rideStatusFromId(
        data['status'] as String? ?? RideStatus.pending.id,
      );
      final rideRiderId =
          _stringFromFirestore(data['riderId']) ??
          _stringFromFirestore(data['riderUid']);

      if (status != RideStatus.completed) {
        throw StateError('Only completed rides can be rated.');
      }

      if (rideRiderId != null && rideRiderId != riderId) {
        throw StateError('Only the rider who booked this trip can rate it.');
      }

      transaction.update(document, {
        'riderRating': rating,
        'riderRatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final snapshot = await document.get();
    return _rideFromSnapshot(snapshot);
  }

  Ride _rideFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final scheduledTime = data['scheduledTime'];
    final scheduledDateTime =
        _dateTimeFromFirestore(data['scheduledDateTime']) ??
        _dateTimeFromFirestore(data['ScheduledDateTime']);
    final scheduledDate = _dateTimeFromFirestore(data['scheduledDate']);
    final parsedScheduledTime = scheduledTime is Map<String, dynamic>
        ? TimeOfDay(
            hour: scheduledTime['hour'] as int? ?? 0,
            minute: scheduledTime['minute'] as int? ?? 0,
          )
        : null;

    return Ride(
      id: snapshot.id,
      pickupLocation: data['pickupLocation'] as String? ?? '',
      dropoffLocation: data['dropoffLocation'] as String? ?? '',
      zone: data['zone'] as String? ?? '',
      vehicleType: vehicleTypeFromId(
        data['vehicleType'] as String? ?? VehicleType.blackSuv.id,
      ),
      rideType: data['rideType'] as String? ?? 'now',
      fare: (data['fare'] as num?)?.toInt() ?? 0,
      status: rideStatusFromId(
        data['status'] as String? ?? RideStatus.pending.id,
      ),
      createdAt: _dateTimeFromFirestore(data['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTimeFromFirestore(data['updatedAt']),
      riderId:
          _stringFromFirestore(data['riderId']) ??
          _stringFromFirestore(data['riderUid']),
      assignedDriver:
          _stringFromFirestore(data['assignedDriver']) ??
          _stringFromFirestore(data['driverId']),
      riderRating: (data['riderRating'] as num?)?.toInt(),
      scheduledDateTime:
          scheduledDateTime ??
          _combineScheduledDateTime(scheduledDate, parsedScheduledTime),
      scheduledDate: scheduledDate,
      scheduledTime: parsedScheduledTime,
    );
  }

  Map<String, dynamic> _rideToFirestore(Ride ride, {required String riderId}) {
    final scheduledDateTime = ride.effectiveScheduledDateTime;

    return {
      'pickupLocation': ride.pickupLocation,
      'dropoffLocation': ride.dropoffLocation,
      'zone': ride.zone,
      'vehicleType': ride.vehicleType.id,
      'rideType': ride.rideType,
      'fare': ride.fare,
      'status': ride.status.id,
      'assignedDriver': ride.assignedDriver,
      'driverId': ride.assignedDriver,
      'createdAt': Timestamp.fromDate(ride.createdAt),
      'scheduledDateTime': scheduledDateTime == null
          ? null
          : Timestamp.fromDate(scheduledDateTime),
      'ScheduledDateTime': scheduledDateTime == null
          ? null
          : Timestamp.fromDate(scheduledDateTime),
      'scheduledDate': ride.scheduledDate == null
          ? null
          : Timestamp.fromDate(ride.scheduledDate!),
      'scheduledTime': ride.scheduledTime == null
          ? null
          : {
              'hour': ride.scheduledTime!.hour,
              'minute': ride.scheduledTime!.minute,
            },
      'riderId': riderId,
      'riderUid': riderId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool _firestoreDataIsScheduled(Map<String, dynamic> data) {
    final rideType = data['rideType'] as String? ?? '';
    final normalizedRideType = rideType.toLowerCase();

    return data['scheduledDateTime'] != null ||
        data['ScheduledDateTime'] != null ||
        data['scheduledDate'] != null ||
        data['scheduledTime'] != null ||
        normalizedRideType == 'scheduled' ||
        normalizedRideType.contains('scheduled');
  }

  DateTime? _combineScheduledDateTime(
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  ) {
    if (scheduledDate == null || scheduledTime == null) {
      return null;
    }

    return DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
  }

  DateTime? _dateTimeFromFirestore(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  String? _stringFromFirestore(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }
}
