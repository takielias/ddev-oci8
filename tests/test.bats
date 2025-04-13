#!/usr/bin/env bats

# Test file for DDEV OCI8 add-on
# Verifies Oracle Instant Client and PHP OCI8 extension installation

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
  
  # Create test project
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --php-version=8.1
  assert_success
  run ddev start -y
  assert_success
}

oci8_health_checks() {
  # Verify Oracle Instant Client installation
  run ddev exec ldconfig -p | grep -i oci
  assert_success
  assert_output --partial "liboci"
  
  # Verify PHP OCI8 extension
  run ddev exec php -m
  assert_success
  assert_output --partial "oci8"
  
  # Verify library paths
  run ddev exec php -i | grep -i "oci8.*version"
  assert_success
  assert_output --regexp "OCI8.*enabled"
  
  # Verify Instant Client version
  run ddev exec php -i | grep -i "oracle.*version"
  assert_success
  assert_output --regexp "Oracle.*Instant Client"
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
  
  # Restart to apply changes
  run ddev restart -y
  assert_success
  
  # Verify installation
  oci8_health_checks
  
  # Additional test: Create a simple PHP connection test
  cat <<'EOF' > ${TESTDIR}/oci-test.php
<?php
$conn = oci_connect('test', 'test', 'localhost/XE');
if (!$conn) {
    $e = oci_error();
    echo "OCI8 Test: Connection failed - " . $e['message'];
} else {
    echo "OCI8 Test: Extension loaded successfully";
    oci_close($conn);
}
EOF
  
  # Test the PHP file (will show connection failed but verify extension works)
  run ddev exec php oci-test.php
  assert_success
  assert_output --partial "Extension loaded successfully"
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