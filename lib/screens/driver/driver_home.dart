import 'package:flutter/material.dart';

import '../../models/ride.dart';
import '../../models/ride_status.dart';
import '../../repositories/ride_repository.dart';
import '../../repositories/user_profile_repository.dart';
import '../../services/app_error_messages.dart';
import '../../services/auth_service.dart';
import '../auth/role_selection_screen.dart';
import '../shared/ride_detail_screen.dart';

enum DriverAvailability { offline, online, busy }

extension DriverAvailabilityLabel on DriverAvailability {
  String get label {
    switch (this) {
      case DriverAvailability.offline:
        return 'Offline';
      case DriverAvailability.online:
        return 'Online';
      case DriverAvailability.busy:
        return 'Busy';
    }
  }

  Color get color {
    switch (this) {
      case DriverAvailability.offline:
        return Colors.red;
      case DriverAvailability.online:
        return Colors.green;
      case DriverAvailability.busy:
        return Colors.amber;
    }
  }
}

class DriverHome extends StatefulWidget {
  final Ride? ride;

  const DriverHome({super.key, this.ride});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  DriverAvailability availability = DriverAvailability.offline;
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
        SnackBar(
          content: Text('Ride update failed. ${friendlyErrorMessage(error)}'),
        ),
      );
    }
  }

  Future<void> acceptRide(Ride ride) async {
    try {
      final acceptedRide = await RideRepository.instance.acceptRide(ride.id);

      if (!mounted) return;

      setState(() {
        activeRide = acceptedRide;
        availability = DriverAvailability.busy;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ride accepted.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride accept failed. ${friendlyErrorMessage(error)}'),
        ),
      );
    }
  }

  void declineRide(Ride ride) {
    setState(() {
      declinedRideIds.add(ride.id);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ride declined')));
  }

  Future<void> completeTrip(Ride ride) async {
    await updateStatus(ride, RideStatus.completed);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip completed.')));
  }

  void findNextRide() {
    setState(() {
      final activeRideId = activeRide?.id;
      if (activeRideId != null) {
        dismissedCompletedRideIds.add(activeRideId);
      }
      activeRide = null;
      availability = DriverAvailability.online;
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
        foregroundColor: Colors.amber,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: handleLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Ride>>(
          stream: RideRepository.instance.watchAssignedDriverRides(),
          builder: (context, assignedSnapshot) {
            if (assignedSnapshot.hasError) {
              return _streamMessageState(
                icon: Icons.cloud_off,
                message:
                    'Driver rides could not load. ${friendlyErrorMessage(assignedSnapshot.error!)}',
              );
            }

            if (assignedSnapshot.connectionState == ConnectionState.waiting &&
                !assignedSnapshot.hasData) {
              return _loadingState('Loading driver rides...');
            }

            final assignedRides = assignedSnapshot.data ?? const <Ride>[];

            return StreamBuilder<List<Ride>>(
              stream: RideRepository.instance.watchPendingRides(),
              builder: (context, pendingSnapshot) {
                if (pendingSnapshot.hasError) {
                  return _streamMessageState(
                    icon: Icons.cloud_off,
                    message:
                        'Ride requests could not load. ${friendlyErrorMessage(pendingSnapshot.error!)}',
                  );
                }

                if (pendingSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !pendingSnapshot.hasData) {
                  return _loadingState('Loading ride requests...');
                }

                final pendingRides = (pendingSnapshot.data ?? const <Ride>[])
                    .where((ride) => !declinedRideIds.contains(ride.id))
                    .toList();
                final upcomingScheduledRides = _sortScheduledRides(
                  pendingRides.where((ride) => ride.isScheduled).toList(),
                );
                final newRequestRides = pendingRides
                    .where((ride) => !ride.isScheduled)
                    .toList();
                final activeRides = assignedRides
                    .where(
                      (ride) =>
                          ride.status == RideStatus.accepted ||
                          ride.status == RideStatus.arriving ||
                          ride.status == RideStatus.inProgress,
                    )
                    .toList();
                final completedRides = assignedRides
                    .where((ride) => ride.status == RideStatus.completed)
                    .toList();
                final effectiveAvailability = activeRides.isEmpty
                    ? availability
                    : DriverAvailability.busy;
                final canAcceptNewRequests =
                    activeRides.isEmpty &&
                    availability == DriverAvailability.online;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _profileCard(
                            availability: effectiveAvailability,
                            completedRides: completedRides,
                          ),
                          const SizedBox(height: 16),
                          _availabilityControls(activeRides: activeRides),
                          const SizedBox(height: 16),
                          _metricsRow(
                            assignedRides: assignedRides,
                            pendingRides: pendingRides,
                          ),
                          const SizedBox(height: 16),
                          _earningsDashboard(completedRides),
                          const SizedBox(height: 22),
                          _rideSection(
                            title: 'Upcoming Scheduled Rides',
                            subtitle: canAcceptNewRequests
                                ? 'Scheduled rides waiting for driver acceptance'
                                : 'Go online to accept scheduled rides',
                            emptyText: canAcceptNewRequests
                                ? 'No upcoming scheduled rides'
                                : 'Scheduled ride acceptance is paused while offline or busy',
                            rides: canAcceptNewRequests
                                ? upcomingScheduledRides
                                : const <Ride>[],
                            builder: _scheduledRideCard,
                          ),
                          const SizedBox(height: 22),
                          _rideSection(
                            title: 'New Request',
                            subtitle: canAcceptNewRequests
                                ? 'Pending rides available to accept'
                                : 'Go online to accept new requests',
                            emptyText: canAcceptNewRequests
                                ? 'No new ride requests'
                                : 'New requests are paused while offline or busy',
                            rides: canAcceptNewRequests
                                ? newRequestRides
                                : const <Ride>[],
                            builder: _availableRideCard,
                          ),
                          const SizedBox(height: 22),
                          _rideSection(
                            title: 'Active Rides',
                            subtitle:
                                'Accepted, arriving, and in-progress trips',
                            emptyText: 'No active rides',
                            rides: activeRides,
                            builder: _activeRideCard,
                          ),
                          const SizedBox(height: 22),
                          _rideSection(
                            title: 'Completed Rides',
                            subtitle: 'Finished trips assigned to you',
                            emptyText: 'No completed rides yet',
                            rides: completedRides,
                            builder: _completedRideCard,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _profileCard({
    required DriverAvailability availability,
    required List<Ride> completedRides,
  }) {
    final user = AuthService.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'SpeedyTrips Driver';
    final email = user?.email?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Profile',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _rideDetail('Email', email),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _profilePill(
                icon: Icons.star,
                label: 'Rating',
                value: _driverRatingLabel(completedRides),
              ),
              _profilePill(
                icon: Icons.radio_button_checked,
                label: 'Status',
                value: availability.label,
                valueColor: availability.color,
              ),
              _profilePill(
                icon: Icons.route,
                label: 'Total Trips',
                value: completedRides.length.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _availabilityControls({required List<Ride> activeRides}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Availability',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: DriverAvailability.values.map((status) {
              final isSelected = availability == status;

              return ChoiceChip(
                selected: isSelected,
                label: Text(status.label),
                avatar: Icon(
                  _availabilityIcon(status),
                  size: 18,
                  color: isSelected ? Colors.black : status.color,
                ),
                selectedColor: Colors.amber,
                backgroundColor: Colors.black,
                side: BorderSide(
                  color: isSelected ? Colors.amber : Colors.white24,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() {
                    availability = status;
                  });
                },
              );
            }).toList(),
          ),
          if (activeRides.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Active rides keep your operational status busy until the trip is completed.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricsRow({
    required List<Ride> assignedRides,
    required List<Ride> pendingRides,
  }) {
    final today = DateTime.now();
    final todaysRides = assignedRides
        .where((ride) => _isSameDay(ride.createdAt, today))
        .length;
    final completedToday = assignedRides
        .where(
          (ride) =>
              ride.status == RideStatus.completed &&
              _isSameDay(ride.createdAt, today),
        )
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final cards = [
          _metricCard('Today\'s Rides', todaysRides.toString(), Icons.today),
          _metricCard('Completed', completedToday.toString(), Icons.done_all),
          _metricCard(
            'Pending',
            pendingRides.length.toString(),
            Icons.schedule,
          ),
        ];

        if (!isWide) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                if (card != cards.last) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (final card in cards) ...[
              Expanded(child: card),
              if (card != cards.last) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _earningsDashboard(List<Ride> completedRides) {
    final totalEarnings = _sumFares(completedRides);
    final today = DateTime.now();
    final todaysEarnings = _sumFares(
      completedRides
          .where((ride) => _isSameDay(_completedDate(ride), today))
          .toList(),
    );
    final weeklyEarnings = _sumFares(
      completedRides
          .where((ride) => _isInCurrentWeek(_completedDate(ride), today))
          .toList(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Earnings',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Completed trips update these totals automatically.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (completedRides.isEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'No earnings yet. Completed trips will appear here.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final cards = [
                _metricCard(
                  'Total Earnings',
                  _currency(totalEarnings),
                  Icons.account_balance_wallet,
                ),
                _metricCard(
                  'Today\'s Earnings',
                  _currency(todaysEarnings),
                  Icons.today,
                ),
                _metricCard(
                  'Weekly Earnings',
                  _currency(weeklyEarnings),
                  Icons.date_range,
                ),
                _metricCard(
                  'Completed Trips',
                  completedRides.length.toString(),
                  Icons.done_all,
                ),
              ];

              if (!isWide) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _rideSection({
    required String title,
    required String subtitle,
    required String emptyText,
    required List<Ride> rides,
    required Widget Function(Ride ride) builder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (rides.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  emptyText,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              itemCount: rides.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == rides.length - 1 ? 0 : 14,
                  ),
                  child: builder(rides[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _availableRideCard(Ride ride) {
    return _rideCard(
      ride: ride,
      actions: [
        ElevatedButton(
          style: _goldButtonStyle(),
          onPressed: availability == DriverAvailability.online
              ? () => acceptRide(ride)
              : null,
          child: const Text(
            'Accept',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: _outlineButtonStyle(),
          onPressed: () => declineRide(ride),
          child: const Text('Decline', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _scheduledRideCard(Ride ride) {
    return _rideCard(
      ride: ride,
      actions: [
        ElevatedButton.icon(
          style: _goldButtonStyle(),
          onPressed: availability == DriverAvailability.online
              ? () => acceptRide(ride)
              : null,
          icon: const Icon(Icons.event_available),
          label: const Text(
            'Accept Scheduled Ride',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: _outlineButtonStyle(),
          onPressed: () => declineRide(ride),
          child: const Text('Decline', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _activeRideCard(Ride ride) {
    return _rideCard(ride: ride, actions: _activeRideActions(ride));
  }

  Widget _completedRideCard(Ride ride) {
    return _rideCard(
      ride: ride,
      actions: [
        _driverReceipt(ride),
        const SizedBox(height: 10),
        if (ride.riderRating != null)
          _rideDetail('Rider rating', '${ride.riderRating}/5')
        else
          _rideDetail('Rider rating', 'Not rated yet'),
        if (activeRide?.id == ride.id &&
            !dismissedCompletedRideIds.contains(ride.id)) ...[
          const SizedBox(height: 10),
          ElevatedButton(
            style: _goldButtonStyle(),
            onPressed: findNextRide,
            child: const Text(
              'Find Next Ride',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _activeRideActions(Ride ride) {
    switch (ride.status) {
      case RideStatus.accepted:
        return [
          ElevatedButton(
            style: _greenButtonStyle(),
            onPressed: () async {
              await updateStatus(ride, RideStatus.arriving);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver marked as arriving')),
              );
            },
            child: const Text('Mark Arriving', style: TextStyle(fontSize: 16)),
          ),
        ];
      case RideStatus.arriving:
        return [
          ElevatedButton(
            style: _greenButtonStyle(),
            onPressed: () async {
              await updateStatus(ride, RideStatus.inProgress);

              if (!mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Trip started')));
            },
            child: const Text('Start Trip', style: TextStyle(fontSize: 16)),
          ),
        ];
      case RideStatus.inProgress:
        return [
          ElevatedButton(
            style: _goldButtonStyle(),
            onPressed: () => completeTrip(ride),
            child: const Text(
              'Complete Trip',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ];
      case RideStatus.pending:
      case RideStatus.completed:
      case RideStatus.cancelled:
        return const <Widget>[];
    }
  }

  Widget _rideCard({required Ride ride, required List<Widget> actions}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.amber.withAlpha((0.45 * 255).round())),
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
                      ? 'Ride request'
                      : ride.dropoffLocation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(ride.status),
            ],
          ),
          const SizedBox(height: 12),
          _rideDetail('Pickup', ride.pickupLocation),
          _rideDetail('Dropoff', ride.dropoffLocation),
          _rideDetail('Service area', ride.zone),
          _rideDetail('Ride type', ride.rideTypeLabel),
          if (ride.isScheduled)
            _rideDetail('Scheduled time', _scheduledDateLabel(ride)),
          _rideDetail('Fare', ride.priceLabel),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: _outlineButtonStyle(),
            onPressed: () => _openRideDetails(ride),
            icon: const Icon(Icons.receipt_long),
            label: const Text('View Details'),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  Widget _driverReceipt(Ride ride) {
    return FutureBuilder<String>(
      future: UserProfileRepository.instance.displayNameForUser(
        ride.riderId,
        fallback: 'Unknown rider',
      ),
      builder: (context, snapshot) {
        final riderName =
            snapshot.data ??
            (ride.riderId == null ? 'Unknown rider' : 'Loading...');

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF12100B),
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Driver Trip Receipt',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _rideDetail('Ride ID', ride.id),
              _rideDetail('Rider', riderName),
              _rideDetail('Pickup', ride.pickupLocation),
              _rideDetail('Dropoff', ride.dropoffLocation),
              _rideDetail('Fare earned', ride.priceLabel),
              _rideDetail('Completed date', _formatDate(_completedDate(ride))),
            ],
          ),
        );
      },
    );
  }

  Widget _profilePill({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
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
        color: Colors.amber.withAlpha((0.14 * 255).round()),
        border: Border.all(color: Colors.amber.withAlpha((0.5 * 255).round())),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF12100B),
      border: Border.all(color: Colors.amber.withAlpha((0.42 * 255).round())),
      borderRadius: BorderRadius.circular(12),
    );
  }

  void _openRideDetails(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RideDetailScreen(ride: ride, title: 'Driver Ride Details'),
      ),
    );
  }

  Widget _loadingState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _streamMessageState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white54),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _goldButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.amber,
      foregroundColor: Colors.black,
      disabledBackgroundColor: Colors.white24,
      disabledForegroundColor: Colors.white54,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  ButtonStyle _greenButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white54),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  IconData _availabilityIcon(DriverAvailability status) {
    switch (status) {
      case DriverAvailability.offline:
        return Icons.power_settings_new;
      case DriverAvailability.online:
        return Icons.check_circle;
      case DriverAvailability.busy:
        return Icons.do_not_disturb_on;
    }
  }

  String _driverRatingLabel(List<Ride> completedRides) {
    final ratings = completedRides
        .map((ride) => ride.riderRating)
        .whereType<int>()
        .toList();

    if (ratings.isEmpty) {
      return 'No ratings';
    }

    final average =
        ratings.reduce((total, rating) => total + rating) / ratings.length;
    return '${average.toStringAsFixed(1)}/5';
  }

  int _sumFares(List<Ride> rides) {
    return rides.fold(0, (total, ride) => total + ride.fare);
  }

  String _currency(int amount) {
    return '\$$amount';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  DateTime _completedDate(Ride ride) {
    return ride.updatedAt ?? ride.createdAt;
  }

  List<Ride> _sortScheduledRides(List<Ride> rides) {
    return rides..sort((a, b) {
      final first = a.effectiveScheduledDateTime ?? a.createdAt;
      final second = b.effectiveScheduledDateTime ?? b.createdAt;
      return first.compareTo(second);
    });
  }

  String _scheduledDateLabel(Ride ride) {
    final scheduledDateTime = ride.effectiveScheduledDateTime;
    if (scheduledDateTime == null) {
      return 'Not scheduled';
    }

    final hour = scheduledDateTime.hour.toString().padLeft(2, '0');
    final minute = scheduledDateTime.minute.toString().padLeft(2, '0');
    return '${scheduledDateTime.month}/${scheduledDateTime.day}/${scheduledDateTime.year} $hour:$minute';
  }

  bool _isInCurrentWeek(DateTime date, DateTime now) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    final weekStart = startOfToday.subtract(
      Duration(days: startOfToday.weekday - DateTime.monday),
    );
    final nextWeekStart = weekStart.add(const Duration(days: 7));

    return !date.isBefore(weekStart) && date.isBefore(nextWeekStart);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
