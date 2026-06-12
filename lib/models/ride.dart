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
  final DateTime? updatedAt;
  final String? riderId;
  final String? assignedDriver;
  final int? riderRating;
  final DateTime? scheduledDateTime;
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
    this.updatedAt,
    this.riderId,
    this.assignedDriver,
    this.riderRating,
    this.scheduledDateTime,
    this.scheduledDate,
    this.scheduledTime,
  });

  String get priceLabel => '\$$fare';

  bool get isScheduled {
    final normalizedRideType = rideType.toLowerCase();
    return normalizedRideType == 'scheduled' ||
        normalizedRideType.contains('scheduled') ||
        scheduledDateTime != null ||
        scheduledDate != null ||
        scheduledTime != null;
  }

  String get rideTypeLabel {
    final normalizedRideType = rideType.toLowerCase();

    if (normalizedRideType == 'now' || normalizedRideType == 'ride now') {
      return 'Ride Now';
    }

    if (normalizedRideType == 'scheduled' ||
        normalizedRideType.contains('scheduled')) {
      return 'Scheduled Ride';
    }

    return rideType;
  }

  DateTime? get effectiveScheduledDateTime {
    if (scheduledDateTime != null) {
      return scheduledDateTime;
    }

    if (scheduledDate == null) {
      return null;
    }

    final time = scheduledTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      scheduledDate!.year,
      scheduledDate!.month,
      scheduledDate!.day,
      time.hour,
      time.minute,
    );
  }

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
    DateTime? updatedAt,
    String? riderId,
    String? assignedDriver,
    int? riderRating,
    DateTime? scheduledDateTime,
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
      updatedAt: updatedAt ?? this.updatedAt,
      riderId: riderId ?? this.riderId,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      riderRating: riderRating ?? this.riderRating,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }
}
