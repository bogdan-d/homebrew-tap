#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_log() {
  grep -Eq "$1" "${FAKE_BREW_LOG}" || fail "missing log entry: $1"
}

assert_no_log() {
  if grep -Eq "$1" "${FAKE_BREW_LOG}"
  then
    fail "unexpected log entry: $1"
  fi
}

setup_case() {
  local name="$1"
  CASE_ROOT="${TEST_ROOT}/${name}"
  FAKE_BREW_ROOT="${CASE_ROOT}/brew"
  FAKE_BREW_LOG="${CASE_ROOT}/brew.log"
  WORK_ROOT="${CASE_ROOT}/work"
  mkdir -p "${FAKE_BREW_ROOT}/taps" "${FAKE_BREW_ROOT}/installed" "${FAKE_BREW_ROOT}/caskroom" "${WORK_ROOT}/Casks"
  : >"${FAKE_BREW_LOG}"
  printf 'cask "example" do\nend\n' >"${WORK_ROOT}/Casks/example.rb"
  export FAKE_BREW_ROOT FAKE_BREW_LOG
}

run_helper() {
  (
    cd "${WORK_ROOT}"
    PATH="${TEST_ROOT}/bin:${PATH}" "${REPO_ROOT}/dev-cask.sh" "$@"
  )
}

mkdir -p "${TEST_ROOT}/bin"
cat >"${TEST_ROOT}/bin/brew" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

printf '%s' "$1" >>"$FAKE_BREW_LOG"
printf '\t%s' "${@:2}" >>"$FAKE_BREW_LOG"
printf '\n' >>"$FAKE_BREW_LOG"

tap_path() {
  local tap="$1"
  printf '%s/taps/%s/homebrew-%s\n' "$FAKE_BREW_ROOT" "${tap%%/*}" "${tap#*/}"
}

case "$1" in
  tap-new)
    tap="${@: -1}"
    mkdir -p "$(tap_path "$tap")/Casks"
    ;;
  --repo)
    path="$(tap_path "$2")"
    [[ -d "$path" ]] || exit 1
    printf '%s\n' "$path"
    ;;
  --caskroom)
    printf '%s/caskroom/%s\n' "$FAKE_BREW_ROOT" "$2"
    ;;
  list)
    [[ "$2" == "--cask" ]]
    [[ -f "$FAKE_BREW_ROOT/installed/$3" ]]
    ;;
  style|livecheck|bump)
    ;;
  audit)
    token="${@: -1}"
    tap="${token%/*}"
    count="$(find "$(tap_path "$tap")/Casks" -maxdepth 1 -name '*.rb' -print | wc -l)"
    [[ "$count" -eq 1 ]] || exit 97
    [[ "${FAKE_AUDIT_FAIL:-false}" == "false" ]] || exit 42
    ;;
  install)
    token="${@: -1}"
    cask="${token##*/}"
    touch "$FAKE_BREW_ROOT/installed/$cask"
    mkdir -p "$FAKE_BREW_ROOT/caskroom/$cask/.metadata"
    printf '{}\n' >"$FAKE_BREW_ROOT/caskroom/$cask/.metadata/INSTALL_RECEIPT.json"
    ;;
  uninstall)
    token="${@: -1}"
    cask="${token##*/}"
    rm -f "$FAKE_BREW_ROOT/installed/$cask"
    rm -rf "$FAKE_BREW_ROOT/caskroom/$cask"
    ;;
  untap)
    [[ "$*" != *"--force"* ]] || exit 99
    tap="${@: -1}"
    rm -rf "$(tap_path "$tap")"
    ;;
  *)
    echo "Unexpected fake brew command: $*" >&2
    exit 98
    ;;
esac
EOF
chmod +x "${TEST_ROOT}/bin/brew"

setup_case style
run_helper style example --fix
assert_log '^style[[:space:]]+Casks/example\.rb[[:space:]]+--fix$'
assert_no_log '^tap-new'

setup_case audit
touch "${FAKE_BREW_ROOT}/installed/unrelated"
run_helper audit example
assert_log '^tap-new[[:space:]]+--no-git[[:space:]]+bogdan-d/local-test-'
assert_log '^audit[[:space:]]+--cask[[:space:]]+bogdan-d/local-test-.*/example$'
assert_log '^untap[[:space:]]+bogdan-d/local-test-'
assert_no_log '^uninstall'
assert_no_log '(^|[[:space:]])--force([[:space:]]|$)'
[[ -f "${FAKE_BREW_ROOT}/installed/unrelated" ]] || fail "audit cleanup removed an unrelated cask"

setup_case installed
touch "${FAKE_BREW_ROOT}/installed/example"
set +e
run_helper install example
status=$?
set -e
[[ ${status} -ne 0 ]] || fail "install accepted a pre-existing cask"
assert_no_log '^install'
assert_no_log '^uninstall'
assert_log '^untap[[:space:]]+bogdan-d/local-test-'

setup_case failed-audit
export FAKE_AUDIT_FAIL=true
set +e
run_helper audit example
status=$?
set -e
unset FAKE_AUDIT_FAIL
[[ ${status} -eq 42 ]] || fail "failed audit returned ${status} instead of 42"
assert_log '^untap[[:space:]]+bogdan-d/local-test-'
assert_no_log '^uninstall'

setup_case install
run_helper install example
assert_log '^install[[:space:]]+--cask[[:space:]]+bogdan-d/local-test-.*/example$'
assert_log '^uninstall[[:space:]]+--cask[[:space:]]+bogdan-d/local-test-.*/example$'
assert_log '^untap[[:space:]]+bogdan-d/local-test-'
[[ ! -f "${FAKE_BREW_ROOT}/installed/example" ]] || fail "test cask remained installed"

setup_case kept
output="$(run_helper audit example --keep)"
tap="$(sed -n 's/^Kept scratch tap \(.*\)\.$/\1/p' <<<"${output}")"
[[ -n "${tap}" ]] || fail "kept tap name was not reported"
run_helper cleanup example --tap "${tap}"
assert_log "^untap[[:space:]]+${tap}$"
assert_no_log '^uninstall'

setup_case replaced-install
output="$(run_helper install example --keep)"
tap="$(sed -n 's/^Kept scratch tap \(.*\)\.$/\1/p' <<<"${output}")"
rm -rf "${FAKE_BREW_ROOT}/caskroom/example"
mkdir -p "${FAKE_BREW_ROOT}/caskroom/example/.metadata"
printf '{"replacement":true}\n' >"${FAKE_BREW_ROOT}/caskroom/example/.metadata/INSTALL_RECEIPT.json"
: >"${FAKE_BREW_LOG}"
set +e
run_helper cleanup example --tap "${tap}"
status=$?
set -e
[[ ${status} -ne 0 ]] || fail "cleanup removed a replacement installation"
assert_no_log '^uninstall'
assert_no_log '^untap'
[[ -f "${FAKE_BREW_ROOT}/installed/example" ]] || fail "replacement installation was removed"

echo "dev-cask tests passed"
