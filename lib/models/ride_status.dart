enum RideStatus {
  requested,
  accepted,
  inProgress,
  completed,
  declined,
}

typedef RidesStatus = RideStatus;

extension RideStatusLabel on RideStatus {
  String get id {
    switch (this) {
      case RideStatus.requested:
        return 'requested';
      case RideStatus.accepted:
        return 'accepted';
      case RideStatus.inProgress:
        return 'in_progress';
      case RideStatus.completed:
        return 'completed';
      case RideStatus.declined:
        return 'declined';
    }
  }

  String get label {
    switch (this) {
      case RideStatus.requested:
        return 'Requested';
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.inProgress:
        return 'In progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.declined:
        return 'Declined';
    }
  }
}

RideStatus rideStatusFromId(String id) {
  switch (id) {
    case 'requested':
      return RideStatus.requested;
    case 'accepted':
      return RideStatus.accepted;
    case 'in_progress':
      return RideStatus.inProgress;
    case 'completed':
      return RideStatus.completed;
    case 'declined':
      return RideStatus.declined;
    default:
      throw ArgumentError.value(id, 'id', 'Unknown ride status id');
  }
}
