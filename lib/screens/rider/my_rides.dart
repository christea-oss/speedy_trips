import 'package:flutter/material.dart';

import '../../models/ride.dart';
import '../../models/ride_status.dart';
import '../../models/vehicle_type.dart';
import '../../repositories/ride_repository.dart';
import '../../repositories/user_profile_repository.dart';

class MyRides extends StatefulWidget {
  const MyRides({super.key});

  @override
  State<MyRides> createState() => _MyRidesState();
}

class _MyRidesState extends State<MyRides> {
  final Set<String> _ratingRideIds = <String>{};

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
          content: Text('Rating was not saved: $error'),
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

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
            'Ride type: ${ride.rideType}',
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
          const SizedBox(height: 12),
          _riderReceipt(ride),
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
          buildRatingStars(ride),
        ],
      ),
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
              _receiptDetail('Ride type', ride.rideType),
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
                    return SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.6,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_car,
                              size: 60,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No rides yet.\nYour trips will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
