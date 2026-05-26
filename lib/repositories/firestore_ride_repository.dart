import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../models/ride_status.dart';
import '../models/vehicle_type.dart';
import '../services/auth_service.dart';

class FirestoreRideRepository {
  FirestoreRideRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

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

  Stream<List<Ride>> watchRequestedRides() {
    return _rides
        .where('status', isEqualTo: RideStatus.requested.id)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_rideFromSnapshot).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
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
        .where('status', isEqualTo: RideStatus.requested.id)
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
    final ride = Ride(
      id: document.id,
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
    final rideData = _rideToFirestore(
      ride,
      riderId: riderId,
    );

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

  Future<Ride> cancelRide(String rideId) {
    return updateRideStatus(
      rideId: rideId,
      status: RideStatus.declined,
    );
  }

  Ride _rideFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final scheduledTime = data['scheduledTime'];

    return Ride(
      id: snapshot.id,
      pickupLocation: data['pickupLocation'] as String? ?? '',
      dropoffLocation: data['dropoffLocation'] as String? ?? '',
      zone: data['zone'] as String? ?? '',
      vehicleType: vehicleTypeFromId(
        data['vehicleType'] as String? ?? VehicleType.blackSuv.id,
      ),
      rideType: data['rideType'] as String? ?? 'Ride Now',
      fare: (data['fare'] as num?)?.toInt() ?? 0,
      status: rideStatusFromId(
        data['status'] as String? ?? RideStatus.requested.id,
      ),
      createdAt: _dateTimeFromFirestore(data['createdAt']) ?? DateTime.now(),
      scheduledDate: _dateTimeFromFirestore(data['scheduledDate']),
      scheduledTime: scheduledTime is Map<String, dynamic>
          ? TimeOfDay(
              hour: scheduledTime['hour'] as int? ?? 0,
              minute: scheduledTime['minute'] as int? ?? 0,
            )
          : null,
    );
  }

  Map<String, dynamic> _rideToFirestore(
    Ride ride, {
    required String riderId,
  }) {
    return {
      'pickupLocation': ride.pickupLocation,
      'dropoffLocation': ride.dropoffLocation,
      'zone': ride.zone,
      'vehicleType': ride.vehicleType.id,
      'rideType': ride.rideType,
      'fare': ride.fare,
      'status': ride.status.id,
      'createdAt': Timestamp.fromDate(ride.createdAt),
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

  DateTime? _dateTimeFromFirestore(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
