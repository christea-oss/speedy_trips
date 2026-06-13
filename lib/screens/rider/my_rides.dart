import 'package:flutter/material.dart';

import '../../models/ride.dart';
import '../../models/ride_status.dart';
import '../../models/vehicle_type.dart';
import '../../repositories/ride_repository.dart';
import '../../repositories/user_profile_repository.dart';
import '../../services/app_error_messages.dart';
import '../shared/ride_detail_screen.dart';

class MyRides extends StatefulWidget {
  const MyRides({super.key});

  @override
  State<MyRides> createState() => _MyRidesState();
}

class _MyRidesState extends State<MyRides> {
  final Set<String> _ratingRideIds = <String>{};
  final Set<String> _updatingScheduledRideIds = <String>{};

  void returnToBooking() {
    Navigator.of(context).pop();
  }

  void handleRebook(Ride ride) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rebooking ${ride.dropoffLocation} for ${ride.priceLabel}',
        ),
      ),
    );

    // Later, this can navigate directly into RiderHome with data pre-filled.
  }

  Future<void> handleRating(Ride ride, int rating) async {
    if (ride.status != RideStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only completed rides can be rated.'),
        ),
      );
      return;
    }

    setState(() {
      _ratingRideIds.add(ride.id);
    });

    try {
      await RideRepository.instance.rateRide(
        rideId: ride.id,
        rating: rating,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $rating-star driver rating.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rating was not saved. ${friendlyErrorMessage(error)}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _ratingRideIds.remove(ride.id);
        });
      }
    }
  }

  Future<void> handleEditScheduledRide(Ride ride) async {
    if (!_canManageScheduledRide(ride)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled rides can only be edited before accepted.'),
        ),
      );
      return;
    }

    final currentSchedule = ride.effectiveScheduledDateTime ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentSchedule.isAfter(DateTime.now())
          ? currentSchedule
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: ride.scheduledTime ??
          TimeOfDay(
            hour: currentSchedule.hour,
            minute: currentSchedule.minute,
          ),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!scheduledDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a future ride time.')),
      );
      return;
    }

    setState(() {
      _updatingScheduledRideIds.add(ride.id);
    });

    try {
      await RideRepository.instance.updateScheduledRideDateTime(
        rideId: ride.id,
        scheduledDate: pickedDate,
        scheduledTime: pickedTime,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled ride time updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scheduled ride was not updated. ${friendlyErrorMessage(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingScheduledRideIds.remove(ride.id);
        });
      }
    }
  }

  Future<void> handleCancelScheduledRide(Ride ride) async {
    if (!_canManageScheduledRide(ride)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled rides can only be cancelled before accepted.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel scheduled ride?'),
        content: Text(
          'This will cancel your scheduled ride to '
          '${ride.dropoffLocation.isEmpty ? 'your destination' : ride.dropoffLocation}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Ride'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _updatingScheduledRideIds.add(ride.id);
    });

    try {
      await RideRepository.instance.cancelScheduledRide(ride.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled ride cancelled.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scheduled ride was not cancelled. ${friendlyErrorMessage(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingScheduledRideIds.remove(ride.id);
        });
      }
    }
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month}/${date.day}/${date.year} $hour:$minute';
  }

  String scheduledLabel(Ride ride) {
    final scheduledDateTime = ride.effectiveScheduledDateTime;
    if (scheduledDateTime == null) {
      return 'Not scheduled';
    }

    return formatDateTime(scheduledDateTime);
  }

  bool _canManageScheduledRide(Ride ride) {
    return ride.isScheduled &&
        ride.status == RideStatus.pending &&
        ride.assignedDriver == null;
  }

  DateTime receiptDate(Ride ride) {
    if (ride.status == RideStatus.completed) {
      return ride.updatedAt ?? ride.createdAt;
    }

    return ride.createdAt;
  }

  Color statusColor(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.pending:
        return Colors.orange;
      case RideStatus.accepted:
      case RideStatus.arriving:
      case RideStatus.inProgress:
        return Colors.blue;
      case RideStatus.cancelled:
        return Colors.red;
    }
  }

  Widget buildRatingStars(Ride ride) {
    if (ride.status != RideStatus.completed) {
      return const SizedBox.shrink();
    }

    final isSaving = _ratingRideIds.contains(ride.id);
    final selectedRating = ride.riderRating ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Rate driver',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = rating <= selectedRating;

            return IconButton(
              tooltip: '$rating star rating',
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              padding: EdgeInsets.zero,
              onPressed: isSaving ? null : () => handleRating(ride, rating),
              icon: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: isSelected ? Colors.amber : Colors.white54,
                size: 30,
              ),
            );
          }),
        ),
        if (isSaving)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Saving rating...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget buildRideCard(Ride ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ride.dropoffLocation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pickup: ${ride.pickupLocation}',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          Text(
            'Vehicle: ${ride.vehicleType.label}',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          Text(
            'Ride type: ${ride.rideTypeLabel}',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          Text(
            'Zone: ${ride.zone}',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          Text(
            'Fare: ${ride.priceLabel}',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Date: ${formatDate(ride.createdAt)}',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          if (ride.isScheduled)
            Text(
              'Scheduled time: ${scheduledLabel(ride)}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),
          _riderReceipt(ride),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
            ),
            onPressed: () => _openRideDetails(ride),
            icon: const Icon(Icons.receipt_long),
            label: const Text('View Details'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ride.status.label.toUpperCase(),
                style: TextStyle(
                  color: statusColor(ride.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => handleRebook(ride),
                child: const Text('Rebook'),
              ),
            ],
          ),
          if (ride.isScheduled) ...[
            const SizedBox(height: 10),
            _scheduledRideActions(ride),
          ],
          buildRatingStars(ride),
        ],
      ),
    );
  }

  Widget _scheduledRideActions(Ride ride) {
    final canManage = _canManageScheduledRide(ride);
    final isUpdating = _updatingScheduledRideIds.contains(ride.id);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amber,
            side: const BorderSide(color: Colors.amber),
          ),
          onPressed: canManage && !isUpdating
              ? () => handleEditScheduledRide(ride)
              : null,
          icon: const Icon(Icons.edit_calendar),
          label: const Text('Edit Time'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
          ),
          onPressed: canManage && !isUpdating
              ? () => handleCancelScheduledRide(ride)
              : null,
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel Scheduled'),
        ),
      ],
    );
  }

  Widget _riderReceipt(Ride ride) {
    return FutureBuilder<String>(
      future: UserProfileRepository.instance.displayNameForUser(
        ride.assignedDriver,
        fallback: 'Not assigned',
      ),
      builder: (context, snapshot) {
        final driverName = snapshot.data ??
            (ride.assignedDriver == null ? 'Not assigned' : 'Loading...');

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip Receipt',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _receiptDetail('Ride ID', ride.id),
              _receiptDetail('Pickup', ride.pickupLocation),
              _receiptDetail('Dropoff', ride.dropoffLocation),
              _receiptDetail('Driver', driverName),
              _receiptDetail('Ride date', formatDate(receiptDate(ride))),
              _receiptDetail('Ride type', ride.rideTypeLabel),
              if (ride.isScheduled)
                _receiptDetail('Scheduled time', scheduledLabel(ride)),
              _receiptDetail('Fare paid', ride.priceLabel),
              _receiptDetail('Ride status', ride.status.label),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value.isEmpty ? 'Not provided' : value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          tooltip: 'Back to booking',
          onPressed: returnToBooking,
          icon: const Icon(Icons.arrow_back, color: Colors.amber),
        ),
        title: const Text('Ride History'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onPressed: returnToBooking,
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  'Back to Booking',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Ride>>(
                stream: RideRepository.instance.watchRiderRides(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _messageState(
                      icon: Icons.cloud_off,
                      message:
                          'Ride history could not load. ${friendlyErrorMessage(snapshot.error!)}',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }

                  final rides = snapshot.data ?? const <Ride>[];

                  if (rides.isEmpty) {
                    return _messageState(
                      icon: Icons.directions_car,
                      message: 'No rides yet.\nYour trips will appear here.',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Your rides',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rides.length,
                        itemBuilder: (context, index) =>
                            buildRideCard(rides[index]),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRideDetails(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailScreen(
          ride: ride,
          title: 'Rider Ride Details',
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String message,
  }) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 60,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
