#!/usr/bin/env bats

setup() {
  set -eu -o pipefail
  export GITHUB_REPO=takielias/ddev-oci8

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-oci8-$(date +%s)"
  mkdir -p ~/tmp
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true

  # Cleanup existing project
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true

  # Init new test project
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --php-version=8.2
  assert_success
  run ddev start -y
  assert_success
}

oci8_health_checks() {
  # Oracle libraries check
  run ddev exec ldconfig -p
  assert_success
  assert_output --partial "libclntsh"

  # PHP extension check
  run ddev exec php -m
  assert_success
  assert_output --partial "oci8"

  # Check PHP info for oci8 enabled
  run ddev exec php -i
  assert_success
  assert_output --regexp "OCI8.*Support.*enabled"

  # Check Oracle Instant Client version
  run ddev exec php -i
  assert_success
  assert_output --regexp "Oracle.*Instant Client.*23"

  # Create test script
  cat <<'EOF' > "${TESTDIR}/oci-test.php"
<?php
if (!extension_loaded('oci8')) {
    exit("OCI8 extension NOT loaded");
}
$conn = @oci_connect('test', 'test', 'localhost/XE');
if (!$conn) {
    $e = oci_error();
    echo "OCI8 Test: Extension loaded but connection failed (expected) - " . $e['message'];
} else {
    echo "OCI8 Test: Successfully connected (unexpected)";
    oci_close($conn);
}
EOF

  # Copy test file into container and run
  ddev exec mkdir -p /var/www/html
  docker cp "${TESTDIR}/oci-test.php" ddev-${PROJNAME}-web:/var/www/html/oci-test.php

  run ddev exec php /var/www/html/oci-test.php
  assert_success
  assert_output --partial "OCI8 Test: Extension loaded but connection failed (expected)"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ -n "${TESTDIR:-}" ] && rm -rf "${TESTDIR}"
}

@test "install from directory and verify oci8" {
  set -eu -o pipefail
  echo "# Installing OCI8 add-on from ${DIR}" >&3
  run ddev add-on get "${DIR}"
  assert_success

  run ddev restart -y
  assert_success

  oci8_health_checks
}

@test "install from release and verify oci8" {
  set -eu -o pipefail
  echo "# Installing OCI8 add-on from GitHub release" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success

  run ddev restart -y
  assert_success

  oci8_health_checks
}
