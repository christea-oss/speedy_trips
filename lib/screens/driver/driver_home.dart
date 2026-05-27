import 'package:flutter/material.dart';

import '../../models/ride.dart';
import '../../models/ride_status.dart';
import '../../repositories/ride_repository.dart';
import '../../services/auth_service.dart';
import '../auth/role_selection_screen.dart';

class DriverHome extends StatefulWidget {
  final Ride? ride;

  const DriverHome({
    super.key,
    this.ride,
  });

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool isOnline = false;
  Ride? activeRide;
  final Set<String> declinedRideIds = <String>{};
  final Set<String> dismissedCompletedRideIds = <String>{};

  @override
  void initState() {
    super.initState();
    activeRide = widget.ride;
  }

  Future<void> updateStatus(Ride ride, RideStatus status) async {
    try {
      final updatedRide = await RideRepository.instance.updateStatus(
        ride,
        status,
      );

      if (!mounted) return;

      setState(() {
        activeRide = updatedRide;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride update failed. ${error.toString()}')),
      );
    }
  }

  Future<void> acceptRide(Ride ride) async {
    try {
      final acceptedRide = await RideRepository.instance.acceptRide(ride.id);

      if (!mounted) return;

      setState(() {
        activeRide = acceptedRide;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride accept failed. ${error.toString()}')),
      );
    }
  }

  void declineRide(Ride ride) {
    setState(() {
      declinedRideIds.add(ride.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride declined'),
      ),
    );
  }

  Future<void> completeTrip(Ride ride) async {
    await updateStatus(ride, RideStatus.completed);
  }

  void findNextRide() {
    setState(() {
      final activeRideId = activeRide?.id;
      if (activeRideId != null) {
        dismissedCompletedRideIds.add(activeRideId);
      }
      activeRide = null;
    });
  }

  Future<void> handleLogout() async {
    await AuthService.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: handleLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            child: StreamBuilder<List<Ride>>(
              stream: RideRepository.instance.watchAssignedDriverRides(),
              builder: (context, snapshot) {
                final assignedRides = snapshot.data ?? const <Ride>[];
                final currentRide = _currentAssignedRide(assignedRides);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      isOnline ? 'Status: Online' : 'Status: Offline',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isOnline = !isOnline;
                          });
                        },
                        child: Text(isOnline ? 'Go Offline' : 'Go Online'),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (currentRide != null)
                      _ridePanel(currentRide)
                    else if (!isOnline)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Text(
                          'Go online to view available rides',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      StreamBuilder<List<Ride>>(
                        stream: RideRepository.instance.watchPendingRides(),
                        builder: (context, pendingSnapshot) {
                          final requestedRides =
                              (pendingSnapshot.data ?? const <Ride>[])
                                  .where((ride) =>
                                      !declinedRideIds.contains(ride.id))
                                  .toList();

                          return _availableRidesSection(
                            rides: requestedRides,
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Ride? _currentAssignedRide(List<Ride> assignedRides) {
    final activeRideId = activeRide?.id;

    if (activeRideId != null) {
      for (final ride in assignedRides) {
        if (ride.id == activeRideId &&
            ride.status != RideStatus.cancelled &&
            !dismissedCompletedRideIds.contains(ride.id)) {
          return ride;
        }
      }
    }

    for (final ride in assignedRides) {
      if (ride.status == RideStatus.accepted ||
          ride.status == RideStatus.arriving ||
          ride.status == RideStatus.inProgress) {
        return ride;
      }
    }

    for (final ride in assignedRides) {
      if (ride.status == RideStatus.completed &&
          !dismissedCompletedRideIds.contains(ride.id)) {
        return ride;
      }
    }

    return null;
  }

  Widget _availableRidesSection({required List<Ride> rides}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Rides',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pending ride requests',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 18),
        if (rides.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Text(
                'No available rides right now',
                style: TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...rides.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _availableRideCard(ride),
            ),
          ),
      ],
    );
  }

  Widget _availableRideCard(Ride ride) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        border: Border.all(color: Colors.amber.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ride.dropoffLocation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _rideDetail('Service area', ride.zone),
          _rideDetail('Ride type', ride.rideType),
          _rideDetail('Pickup', ride.pickupLocation),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => acceptRide(ride),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => declineRide(ride),
                child: const Text(
                  'Decline',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rideDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _ridePanel(Ride ride) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _panelTitle(ride.status),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pickup: ${ride.pickupLocation}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Dropoff: ${ride.dropoffLocation}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Zone: ${ride.zone}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Type: ${ride.rideType}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Status: ${ride.status.label}',
                style: const TextStyle(color: Colors.amber, fontSize: 16),
              ),
              Text(
                'Price: ${ride.priceLabel}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        if (ride.status == RideStatus.pending) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isOnline ? () => acceptRide(ride) : null,
                child: const Text(
                  'Accept Ride',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isOnline ? () => declineRide(ride) : null,
                child: const Text(
                  'Decline Ride',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ] else if (ride.status == RideStatus.accepted) ...[
          const Text(
            'Ride Accepted',
            style: TextStyle(
              color: Colors.green,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await updateStatus(ride, RideStatus.arriving);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Driver marked as arriving'),
                  ),
                );
              },
              child: const Text(
                'Mark Arriving',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ] else if (ride.status == RideStatus.arriving) ...[
          const Text(
            'Driver Arriving',
            style: TextStyle(
              color: Colors.green,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                await updateStatus(ride, RideStatus.inProgress);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trip started'),
                  ),
                );
              },
              child: const Text(
                'Start Trip',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ] else if (ride.status == RideStatus.inProgress) ...[
          const Text(
            'Trip In Progress',
            style: TextStyle(
              color: Colors.green,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => completeTrip(ride),
              child: const Text(
                'Complete Trip',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ] else if (ride.status == RideStatus.completed) ...[
          const Text(
            'Trip Completed',
            style: TextStyle(
              color: Colors.green,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You are still online.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: findNextRide,
              child: const Text(
                'Find Next Ride',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _panelTitle(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return 'Available Ride Request';
      case RideStatus.accepted:
        return 'Accepted Ride';
      case RideStatus.arriving:
        return 'Driver Arriving';
      case RideStatus.inProgress:
        return 'Active Trip';
      case RideStatus.completed:
        return 'Completed Trip';
      case RideStatus.cancelled:
        return 'Cancelled Ride';
    }
  }
}
