import 'package:flutter/material.dart';
import 'package:speedy_trips/screens/rider/my_rides.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  String? selectedZone;
  String vehicleType = "black_suv";
  String scheduleType = "now";

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String? customDropoff;

  List<String> savedLocations = [
    "Downtown Birmingham",
    "Homewood",
    "Hoover",
    "Tuscaloosa",
  ];

  final Map<String, Map<String, int>> zones = {
    "Zone 1": {"black_ride": 25, "black_suv": 35},
    "Zone 2": {"black_ride": 35, "black_suv": 45},
    "Zone 3": {"black_ride": 45, "black_suv": 55},
    "Zone 4": {"black_ride": 60, "black_suv": 75},
    "Zone 5 - Tuscaloosa": {"black_ride": 100, "black_suv": 120},
  };

  int get currentFare {
    if (selectedZone == null) return 0;
    return zones[selectedZone]![vehicleType]!;
  }

  bool get isScheduled => scheduleType == "scheduled";

  void handleSavedSelect(String location) {
    setState(() {
      customDropoff = location;
      selectedZone = null;
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
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

  void handleConfirmRide() {
    if (selectedZone == null) return;

    if (isScheduled && selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select date")),
      );
      return;
    }

    if (isScheduled && selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select time")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Ride"),
        content: Text(
          "Pickup: BHM Airport\n"
          "Dropoff: ${customDropoff ?? selectedZone}\n"
          "Zone: $selectedZone\n"
          "Vehicle: $vehicleType\n"
          "Fare: \$$currentFare",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ride Confirmed")),
              );
            },
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SpeedyTrips"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: savedLocations.map((loc) {
                return ActionChip(
                  label: Text(loc),
                  onPressed: () => handleSavedSelect(loc),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            Container(
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
      "View Ride History",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
),

const SizedBox(height: 20),

            DropdownButtonFormField(
              dropdownColor: Colors.black,
              value: selectedZone,
              items: zones.keys.map((zone) {
                return DropdownMenuItem(
                  value: zone,
                  child: Text(zone),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedZone = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                ChoiceChip(
                  label: const Text("Now"),
                  selected: scheduleType == "now",
                  onSelected: (_) {
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
              ElevatedButton(onPressed: pickDate, child: const Text("Pick Date")),
              ElevatedButton(onPressed: pickTime, child: const Text("Pick Time")),
            ],

            const SizedBox(height: 20),

            if (selectedZone != null)
              Column(
                children: [
                  Text(
                    "\$$currentFare",
                    style: const TextStyle(color: Colors.amber, fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: handleConfirmRide,
                    child: Text(isScheduled ? "Schedule Ride" : "Confirm Ride"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}