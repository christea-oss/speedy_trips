#!/usr/bin/env bash
set -euo pipefail

export JAVA_HOME='/c/Program Files/Android/openjdk/jdk-21.0.8'
export PATH="$JAVA_HOME/bin:$PATH"

firebase emulators:exec \
  --project speedytrips-5b584 \
  --only auth,firestore \
  "flutter test -d windows test/firebase_emulator_auth_test.dart test/firebase_emulator_ride_test.dart test/firebase_emulator_rules_test.dart"
