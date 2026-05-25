import 'package:flutter/material.dart';

import 'ride_status.dart';
import 'vehicle_type.dart';

class Ride {
  final String id;
  final String pickupLocation;
  final String dropoffLocation;
  final String zone;
  final VehicleType vehicleType;
  final String rideType;
  final int fare;
  final RideStatus status;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;

  const Ride({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.zone,
    required this.vehicleType,
    required this.rideType,
    required this.fare,
    required this.status,
    required this.createdAt,
    this.scheduledDate,
    this.scheduledTime,
  });

  String get priceLabel => '\$$fare';

  Ride copyWith({
    String? id,
    String? pickupLocation,
    String? dropoffLocation,
    String? zone,
    VehicleType? vehicleType,
    String? rideType,
    int? fare,
    RideStatus? status,
    DateTime? createdAt,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) {
    return Ride(
      id: id ?? this.id,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      zone: zone ?? this.zone,
      vehicleType: vehicleType ?? this.vehicleType,
      rideType: rideType ?? this.rideType,
      fare: fare ?? this.fare,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }
}
