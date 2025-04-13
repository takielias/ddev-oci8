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
  
  # Cleanup any existing project
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  
  # Create test project with PHP 8.2
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --php-version=8.2
  assert_success
  run ddev start -y
  assert_success
}

oci8_health_checks() {
  # Verify Oracle libraries are found
  run ddev exec ldconfig -p | grep -i liboci || true
  assert_success
  assert_output --partial "liboci"

  # Verify PHP OCI8 extension is loaded
  run ddev exec php -m
  assert_success
  assert_output --partial "oci8"

  # Verify OCI8 extension details
  run ddev exec php -i | grep -i "oci8.*version" || true
  assert_success
  assert_output --regexp "OCI8.*enabled"

  # Verify Instant Client version
  run ddev exec php -i | grep -i "oracle.*version" || true
  assert_success
  assert_output --regexp "Oracle.*Instant Client.*23"

  # Basic connection test (should fail but verify extension works)
  cat <<'EOF' > ${TESTDIR}/oci-test.php
<?php
if (!extension_loaded('oci8')) {
    die("OCI8 extension NOT loaded");
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

  run ddev exec php oci-test.php
  assert_success
  assert_output --partial "OCI8 Test: Extension loaded but connection failed (expected)"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
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