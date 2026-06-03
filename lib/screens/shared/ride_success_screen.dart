import 'package:flutter/material.dart';

import '../../models/ride.dart';
import '../../models/ride_status.dart';
import '../../models/vehicle_type.dart';
import '../../repositories/ride_repository.dart';
import '../../services/pricing_engine.dart';
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
        final fareEstimate = PricingEngine.estimate(
          zone: currentRide.zone,
          pickupLocation: currentRide.pickupLocation,
          rideType: currentRide.rideType,
        );

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('SpeedyTrips'),
            backgroundColor: Colors.black,
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
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
                          '\n${_fareSummary(currentRide, fareEstimate)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (currentRide.status == RideStatus.completed) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TripComplete(
                                      rideId: currentRide.id,
                                      zone: currentRide.zone,
                                      vehicleType: currentRide.vehicleType.id,
                                      price: currentRide.priceLabel,
                                      riderRating: currentRide.riderRating,
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _fareSummary(Ride ride, FareEstimate estimate) {
    final lines = [
      'Fare Summary',
      'Zone base fare: ${PricingEngine.formatCurrency(estimate.baseFare)}',
    ];

    if (estimate.hasAirportPickupFee) {
      lines.add(
        'Airport pickup fee: ${PricingEngine.formatCurrency(estimate.airportPickupFee)}',
      );
    }

    if (estimate.hasScheduledRideFee) {
      lines.add(
        'Scheduled ride fee: ${PricingEngine.formatCurrency(estimate.scheduledRideFee)}',
      );
    }

    lines.add('Total fare: ${ride.priceLabel}');
    return lines.join('\n');
  }
}
