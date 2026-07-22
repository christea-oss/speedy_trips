import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/ride.dart';
import '../../models/ride_status.dart';
import '../../models/user_role.dart';
import '../../models/vehicle_type.dart';
import '../../repositories/admin_repository.dart';
import '../../services/app_error_messages.dart';
import '../../services/auth_service.dart';
import '../auth/role_selection_screen.dart';
import '../shared/ride_detail_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final searchController = TextEditingController();
  RideStatus? selectedStatus;
  RideStatus? selectedScheduledStatus;
  DateTime? selectedScheduledDate;
  String? selectedRideType;
  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
        title: const Text('Admin Dashboard'),
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
          stream: AdminRepository.instance.watchAllRides(),
          builder: (context, ridesSnapshot) {
            if (ridesSnapshot.hasError) {
              return _streamMessageState(
                icon: Icons.cloud_off,
                message:
                    'Admin rides could not load. ${friendlyErrorMessage(ridesSnapshot.error!)}',
              );
            }

            if (ridesSnapshot.connectionState == ConnectionState.waiting &&
                !ridesSnapshot.hasData) {
              return _loadingState('Loading admin ride data...');
            }

            final rides = ridesSnapshot.data ?? const <Ride>[];

            return StreamBuilder<List<AppUser>>(
              stream: AdminRepository.instance.watchDrivers(),
              builder: (context, driversSnapshot) {
                if (driversSnapshot.hasError) {
                  return _streamMessageState(
                    icon: Icons.cloud_off,
                    message:
                        'Driver profiles could not load. ${friendlyErrorMessage(driversSnapshot.error!)}',
                  );
                }

                if (driversSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !driversSnapshot.hasData) {
                  return _loadingState('Loading driver profiles...');
                }

                final drivers = driversSnapshot.data ?? const <AppUser>[];
                final filteredRides = _filteredRides(rides);
                final scheduledRides = _filteredScheduledRides(rides);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 46),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _adminHeader(),
                          const SizedBox(height: 16),
                          _summaryGrid(rides, drivers),
                          const SizedBox(height: 16),
                          _filtersCard(),
                          const SizedBox(height: 18),
                          _rideStatusOverview(rides),
                          const SizedBox(height: 18),
                          _earningsVisibility(rides),
                          const SizedBox(height: 18),
                          _scheduledRideManagement(scheduledRides),
                          const SizedBox(height: 18),
                          _ridesSection(filteredRides),
                          const SizedBox(height: 18),
                          _driversSection(drivers, rides),
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

  Widget _summaryGrid(List<Ride> rides, List<AppUser> drivers) {
    final completed = rides
        .where((ride) => ride.status == RideStatus.completed)
        .length;
    final pending = rides
        .where((ride) => ride.status == RideStatus.pending)
        .length;
    final active = rides
        .where(
          (ride) =>
              ride.status == RideStatus.accepted ||
              ride.status == RideStatus.arriving ||
              ride.status == RideStatus.inProgress,
        )
        .length;
    final completedRevenue = _sumFares(
      rides.where((ride) => ride.status == RideStatus.completed).toList(),
    );
    final scheduled = rides.where((ride) => ride.isScheduled).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 760;
        final cards = [
          _metricCard('All Rides', rides.length.toString(), Icons.route),
          _metricCard('Drivers', drivers.length.toString(), Icons.local_taxi),
          _metricCard('Active', active.toString(), Icons.play_circle),
          _metricCard('Pending', pending.toString(), Icons.schedule),
          _metricCard('Completed', completed.toString(), Icons.done_all),
          _metricCard('Scheduled', scheduled.toString(), Icons.event),
          _metricCard(
            'Revenue Est.',
            _currency(completedRevenue),
            Icons.attach_money,
          ),
        ];

        if (!useGrid) {
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
                  width: (constraints.maxWidth - 24) / 3,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _filtersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search and Filter',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.amber,
            decoration: InputDecoration(
              labelText: 'Search rides',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Pickup, dropoff, zone, driver, rider, ride ID',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.amber),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchText = '';
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.amber),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchText = value.trim();
              });
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statusChip(null),
              for (final status in RideStatus.values) _statusChip(status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _rideTypeChip(null, 'All ride types'),
              _rideTypeChip('now', 'Ride Now'),
              _rideTypeChip('scheduled', 'Scheduled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rideStatusOverview(List<Ride> rides) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride Statuses',
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
            children: RideStatus.values.map((status) {
              final count = rides.where((ride) => ride.status == status).length;
              return _statusCountPill(status, count);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _earningsVisibility(List<Ride> rides) {
    final completedRides = rides
        .where((ride) => ride.status == RideStatus.completed)
        .toList();
    final totalRevenue = _sumFares(completedRides);
    final visibleFareCount = rides.where((ride) => ride.fare > 0).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings Visibility',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revenue estimate is based on completed ride fares.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (completedRides.isEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'No completed ride revenue yet.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final cards = [
                _metricCard(
                  'Platform Revenue Est.',
                  _currency(totalRevenue),
                  Icons.account_balance,
                ),
                _metricCard(
                  'Completed Rides',
                  completedRides.length.toString(),
                  Icons.done_all,
                ),
                _metricCard(
                  'Ride Fares Visible',
                  visibleFareCount.toString(),
                  Icons.receipt_long,
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
          ),
        ],
      ),
    );
  }

  Widget _ridesSection(List<Ride> rides) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'All Rides',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${rides.length} shown',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (rides.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No rides match the current filters',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
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
                    bottom: index == rides.length - 1 ? 0 : 12,
                  ),
                  child: _rideCard(rides[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _scheduledRideManagement(List<Ride> rides) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Scheduled Ride Management',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${rides.length} shown',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _scheduledStatusChip(null),
              for (final status in RideStatus.values)
                _scheduledStatusChip(status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                ),
                onPressed: _pickScheduledDateFilter,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  selectedScheduledDate == null
                      ? 'Filter by date'
                      : _formatDate(selectedScheduledDate!),
                ),
              ),
              if (selectedScheduledDate != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedScheduledDate = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Clear date'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (rides.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No scheduled rides match the current filters',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
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
                    bottom: index == rides.length - 1 ? 0 : 12,
                  ),
                  child: _scheduledRideCard(rides[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _scheduledRideCard(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.amber.withAlpha((0.38 * 255).round())),
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
                      ? 'Scheduled ride ${ride.id}'
                      : ride.dropoffLocation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(ride.status),
            ],
          ),
          const SizedBox(height: 10),
          _detail('Ride ID', ride.id),
          _detail('Rider ID', ride.riderId ?? 'Not assigned'),
          _detail('Driver ID', ride.assignedDriver ?? 'Not assigned'),
          _detail('Pickup', ride.pickupLocation),
          _detail('Dropoff', ride.dropoffLocation),
          _detail('Fare', ride.priceLabel),
          _detail('Scheduled time', _scheduledDateLabel(ride)),
          _detail('Status', ride.status.label),
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
        ],
      ),
    );
  }

  Widget _driversSection(List<AppUser> drivers, List<Ride> rides) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'All Drivers',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${drivers.length} total',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (drivers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No driver profiles found',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              itemCount: drivers.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final driver = drivers[index];
                final driverRides = rides
                    .where((ride) => ride.assignedDriver == driver.uid)
                    .toList();
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == drivers.length - 1 ? 0 : 12,
                  ),
                  child: _driverCard(driver, driverRides),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _rideCard(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.amber.withAlpha((0.38 * 255).round())),
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
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(ride.status),
            ],
          ),
          const SizedBox(height: 10),
          _detail('Pickup', ride.pickupLocation),
          _detail('Dropoff', ride.dropoffLocation),
          _detail('Zone', ride.zone),
          _detail('Vehicle', ride.vehicleType.label),
          _detail('Ride type', ride.rideTypeLabel),
          if (ride.isScheduled)
            _detail('Scheduled time', _scheduledDateLabel(ride)),
          _detail('Fare', ride.priceLabel),
          _detail('Created', _formatDateTime(ride.createdAt)),
          _detail('Rider ID', ride.riderId ?? 'Not assigned'),
          _detail('Driver ID', ride.assignedDriver ?? 'Not assigned'),
          _detail(
            'Rider rating',
            ride.riderRating == null ? 'Not rated' : '${ride.riderRating}/5',
          ),
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
        ],
      ),
    );
  }

  Widget _driverCard(AppUser driver, List<Ride> rides) {
    final completed = rides
        .where((ride) => ride.status == RideStatus.completed)
        .toList();
    final driverEarnings = _sumFares(completed);
    final active = rides
        .where(
          (ride) =>
              ride.status == RideStatus.accepted ||
              ride.status == RideStatus.arriving ||
              ride.status == RideStatus.inProgress,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            driver.displayName.isEmpty
                ? 'SpeedyTrips Driver'
                : driver.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _detail('Email', driver.email),
          _detail('Role', driver.role.label),
          _detail('UID', driver.uid),
          _detail('Status', _driverStatusLabel(rides)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _driverPill('Trips', completed.length.toString(), Icons.route),
              _driverPill(
                'Earnings',
                _currency(driverEarnings),
                Icons.account_balance_wallet,
              ),
              _driverPill('Active', active.toString(), Icons.play_circle),
              _driverPill('Rating', _ratingLabel(completed), Icons.star),
            ],
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

  Widget _statusChip(RideStatus? status) {
    final isSelected = selectedStatus == status;
    final label = status?.label ?? 'All statuses';

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: Colors.amber,
      backgroundColor: Colors.black,
      side: BorderSide(color: isSelected ? Colors.amber : Colors.white24),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) {
        setState(() {
          selectedStatus = status;
        });
      },
    );
  }

  Widget _rideTypeChip(String? rideType, String label) {
    final isSelected = selectedRideType == rideType;

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: Colors.amber,
      backgroundColor: Colors.black,
      side: BorderSide(color: isSelected ? Colors.amber : Colors.white24),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) {
        setState(() {
          selectedRideType = rideType;
        });
      },
    );
  }

  Widget _scheduledStatusChip(RideStatus? status) {
    final isSelected = selectedScheduledStatus == status;
    final label = status?.label ?? 'All scheduled statuses';

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: Colors.amber,
      backgroundColor: Colors.black,
      side: BorderSide(color: isSelected ? Colors.amber : Colors.white24),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) {
        setState(() {
          selectedScheduledStatus = status;
        });
      },
    );
  }

  Widget _statusCountPill(RideStatus status, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: _statusColor(status).withAlpha((0.65 * 255).round()),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: _statusColor(status), size: 12),
          const SizedBox(width: 8),
          Text(
            '${status.label}: $count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(RideStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status).withAlpha((0.14 * 255).round()),
        border: Border.all(
          color: _statusColor(status).withAlpha((0.55 * 255).round()),
        ),
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

  Widget _driverPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12100B),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 17),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70, fontSize: 15),
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

  List<Ride> _filteredRides(List<Ride> rides) {
    final query = searchText.toLowerCase();

    return rides.where((ride) {
      if (selectedStatus != null && ride.status != selectedStatus) {
        return false;
      }

      if (selectedRideType == 'scheduled' && !ride.isScheduled) {
        return false;
      }

      if (selectedRideType == 'now' && ride.isScheduled) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchable = [
        ride.id,
        ride.pickupLocation,
        ride.dropoffLocation,
        ride.zone,
        ride.vehicleType.label,
        ride.rideTypeLabel,
        ride.status.label,
        ride.riderId ?? '',
        ride.assignedDriver ?? '',
        ride.priceLabel,
        if (ride.isScheduled) _scheduledDateLabel(ride),
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  List<Ride> _filteredScheduledRides(List<Ride> rides) {
    final filtered = rides.where((ride) {
      if (!ride.isScheduled) {
        return false;
      }

      if (selectedScheduledStatus != null &&
          ride.status != selectedScheduledStatus) {
        return false;
      }

      final selectedDate = selectedScheduledDate;
      final scheduledDate = ride.effectiveScheduledDateTime;
      if (selectedDate != null &&
          (scheduledDate == null || !_isSameDay(scheduledDate, selectedDate))) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final first = a.effectiveScheduledDateTime ?? a.createdAt;
      final second = b.effectiveScheduledDateTime ?? b.createdAt;
      return first.compareTo(second);
    });

    return filtered;
  }

  Future<void> _pickScheduledDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedScheduledDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedScheduledDate = picked;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  String _scheduledDateLabel(Ride ride) {
    final scheduledDateTime = ride.effectiveScheduledDateTime;
    if (scheduledDateTime == null) {
      return 'Not scheduled';
    }

    return _formatDateTime(scheduledDateTime);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _ratingLabel(List<Ride> completedRides) {
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

  String _driverStatusLabel(List<Ride> rides) {
    final hasActiveRide = rides.any(
      (ride) =>
          ride.status == RideStatus.accepted ||
          ride.status == RideStatus.arriving ||
          ride.status == RideStatus.inProgress,
    );

    if (hasActiveRide) {
      return 'Busy';
    }

    return 'Available / offline';
  }

  Widget _adminHeader() {
    final user = AuthService.instance.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'SpeedyTrips Admin';
    final email = user?.email?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Profile',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _detail('Name', name),
          _detail('Email', email),
          _detail('Role', 'Admin'),
        ],
      ),
    );
  }

  void _openRideDetails(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RideDetailScreen(ride: ride, title: 'Admin Ride Details'),
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

  int _sumFares(List<Ride> rides) {
    return rides.fold(0, (total, ride) => total + ride.fare);
  }

  String _currency(int amount) {
    return '\$$amount';
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

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF12100B),
      border: Border.all(color: Colors.amber.withAlpha((0.42 * 255).round())),
      borderRadius: BorderRadius.circular(12),
    );
  }
}
