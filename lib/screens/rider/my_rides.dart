import 'package:flutter/material.dart';

class RideBooking {
  final String id;
  final String pickupLocation;
  final String dropoffLocation;
  final String vehicleType;
  final String fare;
  final String status;
  final DateTime createdDate;

  RideBooking({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vehicleType,
    required this.fare,
    required this.status,
    required this.createdDate,
  });
}

class MyRides extends StatefulWidget {
  const MyRides({super.key});

  @override
  State<MyRides> createState() => _MyRidesState();
}

class _MyRidesState extends State<MyRides> {
  bool isLoading = false;

  final List<RideBooking> bookings = [
    RideBooking(
      id: '1',
      pickupLocation: 'Birmingham Airport (BHM)',
      dropoffLocation: 'Zone 2',
      vehicleType: 'Black SUV',
      fare: '\$45',
      status: 'completed',
      createdDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    RideBooking(
      id: '2',
      pickupLocation: 'Birmingham Airport (BHM)',
      dropoffLocation: 'Zone 5 - Tuscaloosa',
      vehicleType: 'Black Ride',
      fare: '\$100',
      status: 'completed',
      createdDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  void handleRebook(RideBooking booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rebooking ${booking.dropoffLocation} for ${booking.fare}',
        ),
      ),
    );

    // Later, this can navigate directly into RiderHome
    // with data pre-filled.
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'searching':
        return Colors.blue;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Ride History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.amber,
                ),
              )
            : bookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
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
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your past trips',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final booking = bookings[index];

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
                                    booking.dropoffLocation,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pickup: ${booking.pickupLocation}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Vehicle: ${booking.vehicleType}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Fare: ${booking.fare}',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Date: ${formatDate(booking.createdDate)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        booking.status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor(booking.status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          foregroundColor: Colors.black,
                                        ),
                                        onPressed: () => handleRebook(booking),
                                        child: const Text('Rebook'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
