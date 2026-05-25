enum UserRole {
  rider,
  driver,
}

extension UserRoleLabel on UserRole {
  String get id {
    switch (this) {
      case UserRole.rider:
        return 'rider';
      case UserRole.driver:
        return 'driver';
    }
  }

  String get label {
    switch (this) {
      case UserRole.rider:
        return 'Rider';
      case UserRole.driver:
        return 'Driver';
    }
  }
}

UserRole userRoleFromId(String id) {
  switch (id) {
    case 'rider':
      return UserRole.rider;
    case 'driver':
      return UserRole.driver;
    default:
      throw ArgumentError.value(id, 'id', 'Unknown user role id');
  }
}
