enum RideStatus {
  pending,
  accepted,
  arriving,
  inProgress,
  completed,
  cancelled,
}

typedef RidesStatus = RideStatus;

extension RideStatusLabel on RideStatus {
  String get id {
    switch (this) {
      case RideStatus.pending:
        return 'pending';
      case RideStatus.accepted:
        return 'accepted';
      case RideStatus.arriving:
        return 'arriving';
      case RideStatus.inProgress:
        return 'in_progress';
      case RideStatus.completed:
        return 'completed';
      case RideStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case RideStatus.pending:
        return 'Pending';
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.arriving:
        return 'Arriving';
      case RideStatus.inProgress:
        return 'In progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }
}

RideStatus rideStatusFromId(String id) {
  switch (id) {
    case 'pending':
    case 'requested':
      return RideStatus.pending;
    case 'accepted':
      return RideStatus.accepted;
    case 'arriving':
      return RideStatus.arriving;
    case 'in_progress':
      return RideStatus.inProgress;
    case 'completed':
      return RideStatus.completed;
    case 'cancelled':
    case 'canceled':
    case 'declined':
      return RideStatus.cancelled;
    default:
      throw ArgumentError.value(id, 'id', 'Unknown ride status id');
  }
}
