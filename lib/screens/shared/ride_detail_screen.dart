import 'package:flutter/material.dart';

import '../../models/ride.dart';
import '../../models/ride_status.dart';
import '../../models/vehicle_type.dart';

class RideDetailScreen extends StatelessWidget {
  final Ride ride;
  final String title;
  final List<Widget> actions;

  const RideDetailScreen({
    super.key,
    required this.ride,
    this.title = 'Ride Details',
    this.actions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF12100B),
                  border: Border.all(color: Colors.amber.withOpacity(0.42)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            ride.dropoffLocation.isEmpty
                                ? 'Ride ${ride.id}'
                                : ride.dropoffLocation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _statusBadge(ride.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detail('Ride ID', ride.id),
                    _detail('Pickup', ride.pickupLocation),
                    _detail('Dropoff', ride.dropoffLocation),
                    _detail('Fare', ride.priceLabel),
                    _detail('Status', ride.status.label),
                    _detail('Ride type', ride.rideTypeLabel),
                    if (ride.isScheduled)
                      _detail('Scheduled time', _scheduledDateLabel(ride)),
                    _detail('Created date', _formatDateTime(ride.createdAt)),
                    _detail(
                      'Rating',
                      ride.riderRating == null
                          ? 'Not rated'
                          : '${ride.riderRating}/5',
                    ),
                    _detail('Service area', ride.zone),
                    _detail('Vehicle', ride.vehicleType.label),
                    _detail('Rider ID', ride.riderId ?? 'Not assigned'),
                    _detail('Driver ID', ride.assignedDriver ?? 'Not assigned'),
                    if (ride.updatedAt != null)
                      _detail('Last updated', _formatDateTime(ride.updatedAt!)),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value.isEmpty ? 'Not provided' : value),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(RideStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.14),
        border: Border.all(color: _statusColor(status).withOpacity(0.55)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _scheduledDateLabel(Ride ride) {
    final scheduledDateTime = ride.effectiveScheduledDateTime;
    if (scheduledDateTime == null) {
      return 'Not scheduled';
    }

    return _formatDateTime(scheduledDateTime);
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute';
  }

  Color _statusColor(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return Colors.orange;
      case RideStatus.accepted:
      case RideStatus.arriving:
      case RideStatus.inProgress:
        return Colors.lightBlue;
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
    }
  }
}
