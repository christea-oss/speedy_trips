enum VehicleType { blackRide, blackSuv }

extension VehicleTypeLabel on VehicleType {
  String get id {
    switch (this) {
      case VehicleType.blackRide:
        return 'black_ride';
      case VehicleType.blackSuv:
        return 'black_suv';
    }
  }

  String get label {
    switch (this) {
      case VehicleType.blackRide:
        return 'Black Ride';
      case VehicleType.blackSuv:
        return 'Black SUV';
    }
  }
}

VehicleType vehicleTypeFromId(String id) {
  switch (id) {
    case 'black_ride':
      return VehicleType.blackRide;
    case 'black_suv':
      return VehicleType.blackSuv;
    default:
      throw ArgumentError.value(id, 'id', 'Unknown vehicle type id');
  }
}
