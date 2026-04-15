import 'package:flutter/material.dart';

import 'screens/rider/rider_home.dart';

import 'screens/rider/my_rides.dart';

void main() {
  runApp(const SpeedyTripsApp());
}

class SpeedyTripsApp extends StatelessWidget {
  const SpeedyTripsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SpeedyTrips"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RiderHome()),
                        );
              },
              child: const Text("I'm a Rider"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DriverHome(
        pickup: "BHM Airport",
        zone: "Zone 1",
        rideType: "Ride Now",
        price: "\$25",
        selectedDate: null,
        selectedTime: null,
      ),
    ),
  );
},
              child: const Text("I'm a Driver"),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverHome extends StatefulWidget {
  final String pickup;
  final String zone;
  final String rideType;
  final String price;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  const DriverHome({
    super.key,
    required this.pickup,
    required this.zone,
    required this.rideType,
    required this.price,
    this.selectedDate,
    this.selectedTime,
  });

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool isOnline = false;
  bool rideAccepted = false;

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(
              isOnline ? "Status: Online" : "Status: Offline",
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.red,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  isOnline = !isOnline;
                });
              },
              child: Text(isOnline ? "Go Offline" : "Go Online"),
            ),

            const SizedBox(height: 30),

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
                  const Text(
                    "Incoming Ride Request",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Pickup: ${widget.pickup}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "Zone: ${widget.zone}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "Type: ${widget.rideType}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "Price: ${widget.price}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (!rideAccepted) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isOnline
                          ? () {
                              setState(() {
                                rideAccepted = true;
                              });
                            }
                          : null,
                      child: const Text(
                        "Accept Ride",
                        style: TextStyle(fontSize: 16),
                        ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isOnline
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Ride Declined"),
                                ),
                              );
                            }
                          : null,
                      child: const Text(
                        "Decline Ride",
                        style: TextStyle(fontSize: 16),
                        ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                "Ride Accepted ✅",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Driver is heading to pickup"),
                    ),
                  );
                },
                child: const Text("Start Trip"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RideSuccessScreen extends StatelessWidget {
  final String zone;
  final String price;
  final String rideType;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  const RideSuccessScreen({
    super.key,
    required this.zone,
    required this.price,
    required this.rideType,
    this.selectedDate,
    this.selectedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SpeedyTrips"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),

              const Text(
                "Ride Confirmed 🚗",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Pickup: BHM Airport\n"
                "Zone: $zone\n"
                "Type: $rideType\n"
                "${selectedDate != null ? "Date: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}\n" : ""}"
                "${selectedTime != null ? "Time: ${selectedTime!.format(context)}\n" : ""}"
                "Price: $price",
                style: const TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Done"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  final Map<String, Map<String, int>> zonePricing = {
    "Zone 1": {
      "black_ride": 25,
      "black_suv": 35,
    },
    "Zone 2": {
      "black_ride": 35,
      "black_suv": 45,
    },
    "Zone 3": {
      "black_ride": 45,
      "black_suv": 55,
    },
    "Zone 4": {
      "black_ride": 60,
      "black_suv": 75,
    },
    "Zone 5 - Tuscaloosa": {
      "black_ride": 100,
      "black_suv": 120,
    },
  };

  final List<String> savedLocations = [
    "Downtown Birmingham",
    "Homewood",
    "Hoover",
    "Tuscaloosa",
  ];

  String? selectedZone;
  String vehicleType = "black_suv";
  String scheduleType = "now";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? customDropoff;

  bool get isScheduled => scheduleType == "scheduled";

  int get currentFare {
    if (selectedZone == null) return 0;
    return zonePricing[selectedZone]?[vehicleType] ?? 0;
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
      customDropoff = location;

      final matchedZone = zonePricing.keys.firstWhere(
        (zone) => location.toLowerCase().contains(zone.toLowerCase().split(" - ").first),
        orElse: () => "",
      );

      if (matchedZone.isNotEmpty) {
        selectedZone = matchedZone;
      }
    });
  }

  void handleConfirmRide() {
    if (selectedZone == null) return;

    if (isScheduled && selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date")),
      );
      return;
    }

    if (isScheduled && selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a time")),
      );
      return;
    }

    final rideType = isScheduled ? "Scheduled Ride" : "Ride Now";
    final price = "\$$currentFare";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Your Ride"),
        content: Text(
          isScheduled
              ? "Pickup: Birmingham Airport (BHM)\n"
                "Dropoff: ${customDropoff ?? selectedZone}\n"
                "Zone: $selectedZone\n"
                "Vehicle: ${vehicleType == "black_ride" ? "Black Ride" : "Black SUV"}\n"
                "Type: $rideType\n"
                "Date: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}\n"
                "Time: ${selectedTime!.format(context)}\n"
                "Price: $price"
              : "Pickup: Birmingham Airport (BHM)\n"
                "Dropoff: ${customDropoff ?? selectedZone}\n"
                "Zone: $selectedZone\n"
                "Vehicle: ${vehicleType == "black_ride" ? "Black Ride" : "Black SUV"}\n"
                "Type: $rideType\n"
                "Price: $price",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RideSuccessScreen(
                    zone: selectedZone!,
                    price: price,
                    rideType: rideType,
                    selectedDate: selectedDate,
                    selectedTime: selectedTime,
                  ),
                ),
              );

              setState(() {
                selectedZone = null;
                customDropoff = null;
                vehicleType = "black_suv";
                scheduleType = "now";
                selectedDate = null;
                selectedTime = null;
              });
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dropoffText = customDropoff ?? selectedZone ?? "";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SpeedyTrips"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Saved Places",
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

            const Text(
              "Pickup location",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Birmingham Airport (BHM)",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              "Where to?",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedZone,
              dropdownColor: Colors.black,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              items: zonePricing.keys.map((zone) {
                return DropdownMenuItem(
                  value: zone,
                  child: Text(zone),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedZone = value;
                  customDropoff = null;

                  if (selectedZone == "Zone 5 - Tuscaloosa") {
                    scheduleType = "scheduled";
                  }
                });
              },
            ),
            if (dropoffText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Dropoff: $dropoffText",
                style: const TextStyle(color: Colors.white70),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                ChoiceChip(
                  label: const Text("Now"),
                  selected: scheduleType == "now",
                  onSelected: (_) {
                    if (selectedZone == "Zone 5 - Tuscaloosa") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Tuscaloosa rides must be scheduled"),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      scheduleType = "now";
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Schedule"),
                  selected: scheduleType == "scheduled",
                  onSelected: (_) {
                    setState(() {
                      scheduleType = "scheduled";
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
                      ? "Select Date"
                      : "Date: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}",
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickTime,
                child: Text(
                  selectedTime == null
                      ? "Select Time"
                      : "Time: ${selectedTime!.format(context)}",
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
                  "Map Preview Placeholder\nBirmingham",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),

            if (selectedZone != null) ...[
              const SizedBox(height: 20),
              const Text(
                "Choose Your Ride",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _vehicleCard(
                label: "Black Ride",
                type: "black_ride",
                price: zonePricing[selectedZone]!["black_ride"]!,
              ),
              const SizedBox(height: 12),
              _vehicleCard(
                label: "Black SUV",
                type: "black_suv",
                price: zonePricing[selectedZone]!["black_suv"]!,
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
                      "$selectedZone · Flat Rate",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "\$$currentFare",
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
                        ? "Scheduled Trip: $selectedZone - ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year} at ${selectedTime!.format(context)} - \$$currentFare"
                        : "Scheduled Trip: $selectedZone - Select date and time - \$$currentFare"
                    : "Ride Now Trip: $selectedZone - \$$currentFare",
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
                    isScheduled ? "Schedule Ride" : "Confirm Ride",
                  ),
                ),
              ),
            ],
          ],
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
              "\$$price",
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