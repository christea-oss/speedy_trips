import 'package:flutter/material.dart';

import '../../models/ride.dart';
import '../../models/ride_status.dart';
import '../../models/vehicle_type.dart';
import '../../repositories/ride_repository.dart';
import '../rider/trip_complete.dart';

class RideSuccessScreen extends StatelessWidget {
  final Ride ride;

  const RideSuccessScreen({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Ride?>(
      stream: RideRepository.instance.watchRide(ride.id),
      initialData: ride,
      builder: (context, snapshot) {
        final currentRide = snapshot.data ?? ride;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('SpeedyTrips'),
            backgroundColor: Colors.black,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Ride Confirmed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentRide.status.label,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pickup: ${currentRide.pickupLocation}\n'
                    'Dropoff: ${currentRide.dropoffLocation}\n'
                    'Zone: ${currentRide.zone}\n'
                    'Type: ${currentRide.rideType}\n'
                    '${currentRide.scheduledDate != null ? "Date: ${currentRide.scheduledDate!.month}/${currentRide.scheduledDate!.day}/${currentRide.scheduledDate!.year}\n" : ""}'
                    '${currentRide.scheduledTime != null ? "Time: ${currentRide.scheduledTime!.format(context)}\n" : ""}'
                    'Price: ${currentRide.priceLabel}',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (currentRide.status == RideStatus.completed) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TripComplete(
                              zone: currentRide.zone,
                              vehicleType: currentRide.vehicleType.id,
                              price: currentRide.priceLabel,
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);
                    },
                    child: Text(
                      currentRide.status == RideStatus.completed
                          ? 'Rate Trip'
                          : 'Done',
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
