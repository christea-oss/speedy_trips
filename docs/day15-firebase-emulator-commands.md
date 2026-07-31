# Day 15 Firebase Emulator Commands

Run these commands individually on Windows.

## Auth emulator suite
```bash
export JAVA_HOME='/c/Program Files/Android/openjdk/jdk-21.0.8' && export PATH="$JAVA_HOME/bin:$PATH" && firebase emulators:exec --project speedytrips-5b584 --only auth,firestore "flutter test -d windows --dart-define=RUN_EMULATOR_TESTS=true integration_test/firebase_emulator_auth_test.dart"
```

## Firestore rules suite
```bash
export JAVA_HOME='/c/Program Files/Android/openjdk/jdk-21.0.8' && export PATH="$JAVA_HOME/bin:$PATH" && firebase emulators:exec --project speedytrips-5b584 --only auth,firestore "flutter test -d windows --dart-define=RUN_EMULATOR_TESTS=true integration_test/firebase_emulator_rules_test.dart"
```

## Ride emulator suite
```bash
export JAVA_HOME='/c/Program Files/Android/openjdk/jdk-21.0.8' && export PATH="$JAVA_HOME/bin:$PATH" && firebase emulators:exec --project speedytrips-5b584 --only auth,firestore "flutter test -d windows --dart-define=RUN_EMULATOR_TESTS=true integration_test/firebase_emulator_ride_test.dart"
```
