import 'package:flutter/material.dart';

import '../../repositories/ride_repository.dart';

class TripComplete extends StatefulWidget {
  final String rideId;
  final String zone;
  final String vehicleType;
  final String price;
  final int? riderRating;

  const TripComplete({
    super.key,
    required this.rideId,
    required this.zone,
    required this.vehicleType,
    required this.price,
    this.riderRating,
  });

  @override
  State<TripComplete> createState() => _TripCompleteState();
}

class _TripCompleteState extends State<TripComplete> {
  int? selectedRating;
  bool ratingSaved = false;
  bool ratingSaving = false;

  @override
  void initState() {
    super.initState();
    selectedRating = widget.riderRating;
    ratingSaved = widget.riderRating != null;
  }

  void handleDone() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> saveRating(int rating) async {
    setState(() {
      ratingSaving = true;
    });

    try {
      await RideRepository.instance.rateRide(
        rideId: widget.rideId,
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

      setState(() {
        selectedRating = rating;
        ratingSaved = true;
      });
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
          ratingSaving = false;
        });
      }
    }
  }

  void selectRating(int rating) {
    setState(() {
      selectedRating = rating;
    });

    saveRating(rating);
  }

  Widget buildStar(int index) {
    final isSelected = index <= (selectedRating ?? 0);

    return IconButton(
      tooltip: '$index star rating',
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 44,
      ),
      padding: EdgeInsets.zero,
      onPressed: ratingSaving ? null : () => selectRating(index),
      icon: Icon(
        isSelected ? Icons.star : Icons.star_border,
        color: isSelected ? Colors.amber : Colors.white54,
        size: 36,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleLabel =
        widget.vehicleType == "black_suv" ? "Black SUV" : "Black Ride";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Trip Complete"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Thanks for riding with",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const Text(
                "SpeedyTrips",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Zone: ${widget.zone}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Vehicle: $vehicleLabel",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Price: ${widget.price}",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withOpacity(.45)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Rate Your Trip",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      children: List.generate(5, (index) {
                        return buildStar(index + 1);
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (ratingSaved)
                      const Text(
                        "Thanks for rating your trip",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      const Text(
                        "Tap a star to save your rating",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: handleDone,
                  child: const Text(
                    "Done",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
