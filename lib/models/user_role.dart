enum UserRole {
  rider,
  driver,
  admin,
}

extension UserRoleLabel on UserRole {
  String get id {
    switch (this) {
      case UserRole.rider:
        return 'rider';
      case UserRole.driver:
        return 'driver';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get label {
    switch (this) {
      case UserRole.rider:
        return 'Rider';
      case UserRole.driver:
        return 'Driver';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

UserRole userRoleFromId(String id) {
  switch (id) {
    case 'rider':
      return UserRole.rider;
    case 'driver':
      return UserRole.driver;
    case 'admin':
      return UserRole.admin;
    default:
      throw ArgumentError.value(id, 'id', 'Unknown user role id');
  }
}
