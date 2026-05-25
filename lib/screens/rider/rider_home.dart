import 'package:flutter/material.dart';

import '../../models/vehicle_type.dart';
import '../../repositories/ride_repository.dart';
import '../../services/auth_service.dart';
import '../auth/role_selection_screen.dart';
import '../shared/ride_success_screen.dart';
import 'my_rides.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  static const String defaultPickupLocation =
      'BHM Airport - Door 4L or DL-Door 4L';
  static const String statewideZone = 'Zone 8 - Alabama Statewide';

  final TextEditingController pickupController = TextEditingController(
    text: defaultPickupLocation,
  );
  final TextEditingController dropoffController = TextEditingController();

  final Map<String, Map<String, int>> zonePricing = {
    'Zone 1 - Central Birmingham': {
      'black_ride': 25,
      'black_suv': 35,
    },
    'Zone 2 - South Metro': {
      'black_ride': 35,
      'black_suv': 45,
    },
    'Zone 3 - Hoover Corridor': {
      'black_ride': 45,
      'black_suv': 55,
    },
    'Zone 4 - North Corridor': {
      'black_ride': 55,
      'black_suv': 70,
    },
    'Zone 5 - East Corridor': {
      'black_ride': 55,
      'black_suv': 70,
    },
    'Zone 6 - West Corridor': {
      'black_ride': 55,
      'black_suv': 70,
    },
    'Zone 7 - Tuscaloosa Route': {
      'black_ride': 100,
      'black_suv': 120,
    },
    'Zone 8 - Alabama Statewide': {
      'black_ride': 150,
      'black_suv': 190,
    },
  };

  final Map<String, String> zoneCoverage = {
    'Zone 1 - Central Birmingham': 'Downtown, UAB, Southside, Five Points, BJCC',
    'Zone 2 - South Metro': 'Homewood, Vestavia, Mountain Brook, Brookwood',
    'Zone 3 - Hoover Corridor': 'Hoover, Riverchase, Pelham, Alabaster',
    'Zone 4 - North Corridor': 'Gardendale, Fultondale, Warrior, Morris',
    'Zone 5 - East Corridor': 'Trussville, Irondale, Leeds, Moody',
    'Zone 6 - West Corridor': 'Bessemer, Fairfield, Hueytown, McCalla',
    'Zone 7 - Tuscaloosa Route':
        'Tuscaloosa, Northport, University of Alabama area',
    'Zone 8 - Alabama Statewide':
        'Montgomery, Huntsville, Auburn, Mobile, Dothan, Anniston, Gadsden, Decatur, Florence, Gulf Shores, Orange Beach, and other Alabama cities',
  };

  final Map<String, String> savedLocationZones = {
    'Downtown': 'Zone 1 - Central Birmingham',
    'UAB': 'Zone 1 - Central Birmingham',
    'Southside': 'Zone 1 - Central Birmingham',
    'Five Points': 'Zone 1 - Central Birmingham',
    'BJCC': 'Zone 1 - Central Birmingham',
    'Homewood': 'Zone 2 - South Metro',
    'Vestavia': 'Zone 2 - South Metro',
    'Mountain Brook': 'Zone 2 - South Metro',
    'Brookwood': 'Zone 2 - South Metro',
    'Hoover': 'Zone 3 - Hoover Corridor',
    'Riverchase': 'Zone 3 - Hoover Corridor',
    'Pelham': 'Zone 3 - Hoover Corridor',
    'Alabaster': 'Zone 3 - Hoover Corridor',
    'Gardendale': 'Zone 4 - North Corridor',
    'Fultondale': 'Zone 4 - North Corridor',
    'Warrior': 'Zone 4 - North Corridor',
    'Morris': 'Zone 4 - North Corridor',
    'Trussville': 'Zone 5 - East Corridor',
    'Irondale': 'Zone 5 - East Corridor',
    'Leeds': 'Zone 5 - East Corridor',
    'Moody': 'Zone 5 - East Corridor',
    'Bessemer': 'Zone 6 - West Corridor',
    'Fairfield': 'Zone 6 - West Corridor',
    'Hueytown': 'Zone 6 - West Corridor',
    'McCalla': 'Zone 6 - West Corridor',
    'Tuscaloosa': 'Zone 7 - Tuscaloosa Route',
    'Northport': 'Zone 7 - Tuscaloosa Route',
    'University of Alabama area': 'Zone 7 - Tuscaloosa Route',
    'Montgomery': 'Zone 8 - Alabama Statewide',
    'Huntsville': 'Zone 8 - Alabama Statewide',
    'Auburn': 'Zone 8 - Alabama Statewide',
    'Mobile': 'Zone 8 - Alabama Statewide',
    'Dothan': 'Zone 8 - Alabama Statewide',
    'Anniston': 'Zone 8 - Alabama Statewide',
    'Gadsden': 'Zone 8 - Alabama Statewide',
    'Decatur': 'Zone 8 - Alabama Statewide',
    'Florence': 'Zone 8 - Alabama Statewide',
    'Gulf Shores': 'Zone 8 - Alabama Statewide',
    'Orange Beach': 'Zone 8 - Alabama Statewide',
  };

  final List<String> savedLocations = [
    'Downtown',
    'Homewood',
    'Hoover',
    'Tuscaloosa',
    'Montgomery',
    'Huntsville',
    'Auburn',
    'Mobile',
    'Gulf Shores',
  ];

  String? selectedZone;
  String vehicleType = 'black_suv';
  String scheduleType = 'now';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? customPickup;
  String? customDropoff;

  bool get isScheduled => scheduleType == 'scheduled';

  int get currentFare {
    if (selectedZone == null) return 0;
    return zonePricing[selectedZone]?[vehicleType] ?? 0;
  }

  String get selectedServiceAreaName {
    if (selectedZone == null) return '';
    return serviceAreaName(selectedZone!);
  }

  Map<String, String> get addressZoneKeywords {
    return {
      ...savedLocationZones,
      'Birmingham': 'Zone 1 - Central Birmingham',
      'Birmingham Airport': 'Zone 1 - Central Birmingham',
      'BHM': 'Zone 1 - Central Birmingham',
      'Avondale': 'Zone 1 - Central Birmingham',
      'Lakeview': 'Zone 1 - Central Birmingham',
      'Highland Park': 'Zone 1 - Central Birmingham',
      'Vestavia Hills': 'Zone 2 - South Metro',
      'Cahaba Heights': 'Zone 2 - South Metro',
      'Mountain Brk': 'Zone 2 - South Metro',
      'Riverchase Galleria': 'Zone 3 - Hoover Corridor',
      'Helena': 'Zone 3 - Hoover Corridor',
      'Chelsea': 'Zone 3 - Hoover Corridor',
      'Center Point': 'Zone 4 - North Corridor',
      'Pinson': 'Zone 4 - North Corridor',
      'Clay': 'Zone 4 - North Corridor',
      'Roebuck': 'Zone 5 - East Corridor',
      'Pell City': 'Zone 5 - East Corridor',
      'Pleasant Grove': 'Zone 6 - West Corridor',
      'Midfield': 'Zone 6 - West Corridor',
      'University of Alabama': 'Zone 7 - Tuscaloosa Route',
      'Bryant Denny': 'Zone 7 - Tuscaloosa Route',
    };
  }

  @override
  void dispose() {
    pickupController.dispose();
    dropoffController.dispose();
    super.dispose();
  }

  String get currentPickupLocation {
    final pickup = customPickup ?? pickupController.text.trim();
    return pickup.isEmpty ? defaultPickupLocation : pickup;
  }

  String serviceAreaName(String zone) {
    final parts = zone.split(' - ');
    return parts.length > 1 ? parts.last : zone;
  }

  String normalizeLocation(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  bool isAirportLocation(String value) {
    final normalizedValue = normalizeLocation(value);
    return normalizedValue.contains('bhm') ||
        normalizedValue.contains('birmingham airport') ||
        normalizedValue.contains('airport') ||
        normalizedValue.contains('door 4l') ||
        normalizedValue.contains('dl door 4l');
  }

  String zoneForAddress(String value) {
    final normalizedValue = normalizeLocation(value);
    if (normalizedValue.isEmpty) return statewideZone;

    for (final entry in addressZoneKeywords.entries) {
      final normalizedKeyword = normalizeLocation(entry.key);
      if (normalizedKeyword.isNotEmpty &&
          normalizedValue.contains(normalizedKeyword)) {
        return entry.value;
      }
    }

    return statewideZone;
  }

  String? zoneForTrip({
    required String pickup,
    required String dropoff,
  }) {
    final cleanPickup = pickup.trim();
    final cleanDropoff = dropoff.trim();

    if (cleanPickup.isEmpty && cleanDropoff.isEmpty) {
      return null;
    }

    final pickupIsAirport = isAirportLocation(cleanPickup);
    final dropoffIsAirport = isAirportLocation(cleanDropoff);

    if ((cleanDropoff.isEmpty && pickupIsAirport) ||
        (cleanPickup.isEmpty && dropoffIsAirport) ||
        (pickupIsAirport && dropoffIsAirport)) {
      return null;
    }

    if (pickupIsAirport && cleanDropoff.isNotEmpty) {
      return zoneForAddress(cleanDropoff);
    }

    if (dropoffIsAirport && cleanPickup.isNotEmpty) {
      return zoneForAddress(cleanPickup);
    }

    if (cleanDropoff.isNotEmpty) {
      return zoneForAddress(cleanDropoff);
    }

    if (cleanPickup.isNotEmpty) {
      return zoneForAddress(cleanPickup);
    }

    return null;
  }

  void updateTripZone() {
    final matchedZone = zoneForTrip(
      pickup: currentPickupLocation,
      dropoff: dropoffController.text,
    );

    selectedZone = matchedZone;
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void handleSavedSelect(String location) {
    setState(() {
      dropoffController.text = location;
      customDropoff = location;
      updateTripZone();
    });
  }

  void handleZoneSelect(String? value) {
    setState(() {
      selectedZone = value;
      customPickup = pickupController.text.trim().isEmpty
          ? null
          : pickupController.text.trim();
      customDropoff = dropoffController.text.trim().isEmpty
          ? null
          : dropoffController.text.trim();
    });
  }

  void handlePickupChanged(String value) {
    final pickup = value.trim();

    setState(() {
      customPickup = pickup.isEmpty ? null : pickup;
      updateTripZone();
    });
  }

  void handleDropoffChanged(String value) {
    final dropoff = value.trim();

    setState(() {
      customDropoff = dropoff.isEmpty ? null : dropoff;
      updateTripZone();
    });
  }

  Future<void> handleConfirmRide() async {
    if (selectedZone == null) return;

    if (isScheduled && selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    if (isScheduled && selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    final rideType = isScheduled ? 'Scheduled Ride' : 'Ride Now';
    final price = '\$$currentFare';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Ride'),
        content: Text(
          isScheduled
              ? 'Pickup: $currentPickupLocation\n'
                  'Dropoff: ${customDropoff ?? selectedServiceAreaName}\n'
                  'Service Area: $selectedServiceAreaName\n'
                  'Vehicle: ${vehicleType == "black_ride" ? "Black Ride" : "Black SUV"}\n'
                  'Type: $rideType\n'
                  'Date: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}\n'
                  'Time: ${selectedTime!.format(context)}\n'
                  'Price: $price'
              : 'Pickup: $currentPickupLocation\n'
                  'Dropoff: ${customDropoff ?? selectedServiceAreaName}\n'
                  'Service Area: $selectedServiceAreaName\n'
                  'Vehicle: ${vehicleType == "black_ride" ? "Black Ride" : "Black SUV"}\n'
                  'Type: $rideType\n'
                  'Price: $price',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ride = await RideRepository.instance.createRide(
                pickupLocation: currentPickupLocation,
                dropoffLocation: customDropoff ?? selectedServiceAreaName,
                zone: selectedZone!,
                vehicleType: vehicleType == 'black_ride'
                    ? VehicleType.blackRide
                    : VehicleType.blackSuv,
                rideType: rideType,
                fare: currentFare,
                scheduledDate: selectedDate,
                scheduledTime: selectedTime,
              );

              if (!context.mounted) return;

              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RideSuccessScreen(ride: ride),
                ),
              );

              if (!mounted) return;

              setState(() {
                selectedZone = null;
                customPickup = null;
                customDropoff = null;
                pickupController.text = defaultPickupLocation;
                dropoffController.clear();
                vehicleType = 'black_suv';
                scheduleType = 'now';
                selectedDate = null;
                selectedTime = null;
              });
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
    final serviceAreaText = selectedZone == null
        ? ''
        : '$selectedServiceAreaName Service Area';
    final dropoffText = customDropoff ?? serviceAreaText;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SpeedyTrips'),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'Saved Places',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: savedLocations.map((location) {
                return ActionChip(
                  label: Text(location),
                  onPressed: () => handleSavedSelect(location),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyRides(),
                    ),
                  );
                },
                child: const Text(
                  'View Ride History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pickup location',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: pickupController,
              onChanged: handlePickupChanged,
              decoration: InputDecoration(
                hintText: defaultPickupLocation,
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Pickup: $currentPickupLocation',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Where to?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: dropoffController,
              onChanged: handleDropoffChanged,
              decoration: InputDecoration(
                hintText: 'Enter address or city',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedZone ?? 'service-area-empty'),
              value: selectedZone,
              isExpanded: true,
              dropdownColor: Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text(
                'Select service area',
                style: TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
              items: zonePricing.keys.map((zone) {
                return DropdownMenuItem(
                  value: zone,
                  child: Text(
                    serviceAreaName(zone),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              selectedItemBuilder: (context) {
                return zonePricing.keys.map((zone) {
                  return Text(
                    serviceAreaName(zone),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              onChanged: handleZoneSelect,
            ),
            if (dropoffText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Dropoff: $dropoffText',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (selectedZone != null) ...[
              const SizedBox(height: 8),
              Text(
                serviceAreaText,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Coverage: ${zoneCoverage[selectedZone]}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Now'),
                  selected: scheduleType == 'now',
                  onSelected: (_) {
                    setState(() {
                      scheduleType = 'now';
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Schedule'),
                  selected: scheduleType == 'scheduled',
                  onSelected: (_) {
                    setState(() {
                      scheduleType = 'scheduled';
                    });
                  },
                ),
              ],
            ),
            if (isScheduled) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: pickDate,
                child: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickTime,
                child: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : 'Time: ${selectedTime!.format(context)}',
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Center(
                child: Text(
                  'Map Preview Placeholder\nBirmingham',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            if (selectedZone != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Choose Your Ride',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _vehicleCard(
                label: 'Black Ride',
                type: 'black_ride',
                price: zonePricing[selectedZone]!['black_ride']!,
              ),
              const SizedBox(height: 12),
              _vehicleCard(
                label: 'Black SUV',
                type: 'black_suv',
                price: zonePricing[selectedZone]!['black_suv']!,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$serviceAreaText - Flat Rate',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '\$$currentFare',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isScheduled
                    ? selectedDate != null && selectedTime != null
                        ? 'Scheduled Trip: $serviceAreaText - ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year} at ${selectedTime!.format(context)} - \$$currentFare'
                        : 'Scheduled Trip: $serviceAreaText - Select date and time - \$$currentFare'
                    : 'Ride Now Trip: $serviceAreaText - \$$currentFare',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleConfirmRide,
                  child: Text(
                    isScheduled ? 'Schedule Ride' : 'Confirm Ride',
                  ),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleCard({
    required String label,
    required String type,
    required int price,
  }) {
    final selected = vehicleType == type;

    return InkWell(
      onTap: () {
        setState(() {
          vehicleType = type;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withOpacity(.15) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.amber : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '\$$price',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
