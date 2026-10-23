#!/usr/bin/env bash

set -euo pipefail

# -----------------------------
# Settings
# -----------------------------
# Precedence: CLI option > environment variable > sf-project.config.json > generic default.
# Project-specific values belong in sf-project.config.json, never in this file.

DEFAULT_DURATION_DAYS=14
DEFAULT_SCRATCH_DEF_FILE="config/project-scratch-def.json"
DEFAULT_POST_STEPS="deploy"
DEFAULT_POOL_TAG="dev"
DEFAULT_DUMMY_USER_PROFILE_NAME="Standard User"
DEFAULT_PACKAGE_INSTALL_KEY_ENV_VAR="PACKAGE_INSTALL_KEY"
DEFAULT_PRESERVE_ROOT_FILES="README.md"
BUILTIN_POST_STEPS="deploy permsets data community"
CONFIG_FILE_NAME="sf-project.config.json"
# jq helper that quotes a value as a SOQL string literal, escaping backslashes and single quotes.
SOQL_STRING_JQ='def soql_string: "\u0027" + (gsub("\\\\"; "\\\\") | gsub("\u0027"; "\\\u0027")) + "\u0027";'

ORG_ALIAS="${ORG_ALIAS:-}"
ORG_ALIAS_SOURCE=""
if [[ -n "$ORG_ALIAS" ]]; then
    ORG_ALIAS_SOURCE="environment ORG_ALIAS"
fi
DURATION_DAYS="${DURATION_DAYS:-}"
SCRATCH_DEF_FILE="${SCRATCH_DEF_FILE:-}"
PROJECT_FILE="${PROJECT_FILE:-sfdx-project.json}"
COMMUNITY_NAME="${COMMUNITY_NAME:-}"
DUMMY_DATA_PLAN="${DUMMY_DATA_PLAN:-}"
PERMISSION_SETS="${PERMISSION_SETS:-}"
DUMMY_USER_FILE="${DUMMY_USER_FILE:-}"
DUMMY_USER_PROFILE_NAME="${DUMMY_USER_PROFILE_NAME:-}"
DUMMY_USER_PERMSET_ASSIGNMENTS="${DUMMY_USER_PERMSET_ASSIGNMENTS:-}"
# Newline-separated "<permission sets>|<usernames>" entries, each list space-separated.
DUMMY_USER_ASSIGNMENTS=""
DUMMY_PROFILE_ASSIGNMENTS_JSON='[]'
PACKAGE_INSTALL_KEY_ENV_VAR="${PACKAGE_INSTALL_KEY_ENV_VAR:-}"
PRESERVE_ROOT_FILES="${PRESERVE_ROOT_FILES:-}"
PRESERVE_NOTHING=false
REQUIRE_LOCAL_DIRECTORIES=true
CUSTOM_POST_STEP_NAMES=""

SF_PROJECT_CONFIG="${SF_PROJECT_CONFIG:-}"
USE_CONFIG=true
CONFIG_FILE=""
CONFIG_LOADED=false
INIT_CONFIG_ONLY=false
FORCE_INIT_CONFIG=false
PACKAGE_WAIT_MINUTES="${PACKAGE_WAIT_MINUTES:-10}"
PACKAGE_INSTALL_MAX_ATTEMPTS="${PACKAGE_INSTALL_MAX_ATTEMPTS:-3}"
PACKAGE_INSTALL_RETRY_DELAY_SECONDS="${PACKAGE_INSTALL_RETRY_DELAY_SECONDS:-5}"
PACKAGE_INSTALL_KEY="${PACKAGE_INSTALL_KEY:-}"
PACKAGE_INSTALL_KEYCHAIN_SERVICE="${PACKAGE_INSTALL_KEYCHAIN_SERVICE:-}"
PACKAGE_INSTALL_KEYCHAIN_ACCOUNT="${PACKAGE_INSTALL_KEYCHAIN_ACCOUNT:-}"

RUN_ORG_CREATE="${RUN_ORG_CREATE:-true}"
RUN_PACKAGES="${RUN_PACKAGES:-true}"
POST_STEPS="${POST_STEPS:-}"
VERIFY_PACKAGE_VERSIONS="${VERIFY_PACKAGE_VERSIONS:-true}"
INSTALL_LATEST_PACKAGES="${INSTALL_LATEST_PACKAGES:-false}"
DELETE_ORG_ONLY="${DELETE_ORG_ONLY:-false}"
UPDATE_PACKAGES_ONLY="${UPDATE_PACKAGES_ONLY:-false}"
POST_STEPS_ONLY_MODE="${POST_STEPS_ONLY_MODE:-false}"
FULL_DEPLOY="${FULL_DEPLOY:-false}"
REDEPLOY=false

USE_POOL="${USE_POOL:-}"
POOL_TAG="${POOL_TAG:-}"
POOL_DEVHUB_USERNAME="${POOL_DEVHUB_USERNAME:-}"
FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY="${FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY:-}"
ORG_AVAILABLE_FOR_READ="${ORG_AVAILABLE_FOR_READ:-true}"

SELF_CHECK_ONLY="${SELF_CHECK_ONLY:-false}"
DRY_RUN="${DRY_RUN:-false}"
PACKAGE_PLAN_ONLY="${PACKAGE_PLAN_ONLY:-false}"
CHECK_PROJECT_VERSIONS_ONLY="${CHECK_PROJECT_VERSIONS_ONLY:-false}"
APPLY_PROJECT_VERSIONS="${APPLY_PROJECT_VERSIONS:-false}"
COVERAGE_CHECK_ONLY="${COVERAGE_CHECK_ONLY:-false}"
COVERAGE_PACKAGE_ID="${COVERAGE_PACKAGE_ID:-}"
COVERAGE_MINIMUM="${COVERAGE_MINIMUM:-}"
COVERAGE_TEST_CLASS="${COVERAGE_TEST_CLASS:-}"
COVERAGE_CLASS_PATTERN="${COVERAGE_CLASS_PATTERN:-}"
COVERAGE_RUN_ALL="${COVERAGE_RUN_ALL:-false}"
COVERAGE_SKIP_INSTALL="${COVERAGE_SKIP_INSTALL:-false}"
COVERAGE_SKIP_DEPLOY="${COVERAGE_SKIP_DEPLOY:-false}"
REFRESH_DEPENDENCY_SOURCES="${REFRESH_DEPENDENCY_SOURCES:-false}"
CLEAR_DEPENDENCY_SOURCES_ONLY="${CLEAR_DEPENDENCY_SOURCES_ONLY:-false}"

REQUESTED_RUN_ORG_CREATE=""
REQUESTED_RUN_PACKAGES=""
REQUESTED_POST_STEPS=""
REQUESTED_USE_POOL=""
REQUESTED_UPDATE_PACKAGES_ONLY=""
REQUESTED_PACKAGE_PLAN_ONLY=""
REQUESTED_INSTALL_LATEST_PACKAGES=""
REQUESTED_POST_STEPS_ONLY_MODE=""
TARGET_ORG=""
TARGET_ORG_SOURCE=""

# Optional override of packageKeyConfig in the project file: packages listed here do NOT use an install key.
PACKAGES_NOT_REQUIRING_INSTALL_KEY="${PACKAGES_NOT_REQUIRING_INSTALL_KEY:-}"

PACKAGE_UPDATE_SUGGESTIONS=""
INSTALLED_PACKAGES_JSON=""

RUN_STARTED_AT="$(date '+%Y-%m-%d %H:%M:%S %Z')"
RUN_STARTED_SECONDS="$SECONDS"
SUMMARY_PRINTED=false
SUMMARY_ENABLED=true

RUN_ACTIONS=()
PACKAGES_INSTALLED=()
PACKAGES_UPDATED=()
PACKAGES_SKIPPED=()
PACKAGES_MISSING=()
PACKAGES_HIGHER_THAN_TARGET=()
POST_STEPS_RUN=()
POST_STEPS_SKIPPED=()
ORG_ACTION="No org action recorded."

# -----------------------------
# Output
# -----------------------------

# auto, always or never; set by --color / --no-color.
COLOR_MODE="auto"
VERBOSE="${VERBOSE:-false}"
INTERACTIVE=false
PHASE_INDEX=0
PHASE_TOTAL=0
PROGRESS_OUTPUT=""
PROGRESS_DURATION=""

BOLD="" DIM="" RED="" GREEN="" YELLOW="" BLUE="" CYAN="" RESET=""
ICON_OK="+" ICON_FAIL="x" ICON_WARN="!" ICON_STEP=">" ICON_INFO="-" ICON_SKIP="o" ICON_UPDATE="^" ICON_RULE="-"
SPINNER_FRAMES=("-" "\\" "|" "/")

is_utf8_locale() {
    local locale="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
    [[ "$locale" =~ [Uu][Tt][Ff]-?8 ]]
}

colour_enabled() {
    case "$COLOR_MODE" in
        always) return 0 ;;
        never) return 1 ;;
    esac
    [[ -n "${NO_COLOR:-}" ]] && return 1
    [[ -n "${FORCE_COLOR:-}" && "${FORCE_COLOR}" != "0" ]] && return 0
    [[ -t 1 && "${TERM:-}" != "dumb" ]]
}

init_output() {
    if colour_enabled; then
        BOLD=$'\033[1m'
        DIM=$'\033[2m'
        RED=$'\033[31m'
        GREEN=$'\033[32m'
        YELLOW=$'\033[33m'
        BLUE=$'\033[34m'
        CYAN=$'\033[36m'
        RESET=$'\033[0m'
    fi

    if is_utf8_locale; then
        ICON_OK="✔" ICON_FAIL="✖" ICON_WARN="⚠" ICON_STEP="▸" ICON_INFO="•" ICON_SKIP="○" ICON_UPDATE="↑" ICON_RULE="─"
        SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    fi

    if [[ -t 1 && -z "${CI:-}" && "${TERM:-}" != "dumb" ]]; then
        INTERACTIVE=true
    fi
}

rule() {
    local width="${1:-60}"
    local line=""
    printf -v line '%*s' "$width" ''
    printf '%s' "${line// /$ICON_RULE}"
}

banner() {
    echo ""
    echo "${BOLD}${BLUE}$(rule 60)${RESET}"
    echo "${BOLD}${BLUE}  $1${RESET}"
    echo "${BOLD}${BLUE}$(rule 60)${RESET}"
}

section() {
    local title="$1"
    local padding=$((56 - ${#title}))
    (( padding < 3 )) && padding=3
    echo ""
    echo "${BOLD}${CYAN}${ICON_RULE}${ICON_RULE} ${title} ${RESET}${DIM}$(rule "$padding")${RESET}"
}

phase() {
    PHASE_INDEX=$((PHASE_INDEX + 1))
    section "[$PHASE_INDEX/$PHASE_TOTAL] $1"
}

counter() {
    printf '%s[%d/%d]%s' "$DIM" "$1" "$2" "$RESET"
}

step() { echo "${CYAN}${ICON_STEP}${RESET} $*"; }
item() { echo ""; echo "${BOLD}$*${RESET}"; }
info() { echo "  ${DIM}$*${RESET}"; }
success() { echo "${GREEN}${ICON_OK}${RESET} $*"; }
skipped() { echo "${DIM}${ICON_SKIP} $*${RESET}"; }
failure() { echo "${RED}${ICON_FAIL}${RESET} $*"; }

kv() {
    local value="${2:-}"
    if [[ -z "$value" || "$value" == "none" ]]; then
        value="${DIM}${value:-none}${RESET}"
    fi
    printf '  %s%-*s%s %s\n' "$DIM" "${3:-28}" "$1" "$RESET" "$value"
}

indent_output() {
    sed 's/^/    /' <<< "$1"
}

format_short_duration() {
    local total_seconds="$1"
    if (( total_seconds >= 60 )); then
        printf '%dm %02ds' $((total_seconds / 60)) $((total_seconds % 60))
    else
        printf '%ds' "$total_seconds"
    fi
}

# Runs a command with captured output: a spinner on interactive terminals, start line otherwise.
run_with_progress() {
    local label="$1"
    shift
    local log_file=""
    local started="$SECONDS"
    local status=0
    local pid=""
    local frame=0

    log_file="$(mktemp)"

    if [[ "$INTERACTIVE" == "true" ]]; then
        "$@" < /dev/null > "$log_file" 2>&1 &
        pid=$!
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r  %s%s%s %s %s%s%s' "$CYAN" "${SPINNER_FRAMES[frame % ${#SPINNER_FRAMES[@]}]}" "$RESET" \
                "$label" "$DIM" "$(format_short_duration $((SECONDS - started)))" "$RESET"
            frame=$((frame + 1))
            sleep 0.1
        done
        wait "$pid" || status=$?
        printf '\r\033[K'
    else
        info "$label ..."
        "$@" < /dev/null > "$log_file" 2>&1 || status=$?
    fi

    PROGRESS_OUTPUT="$(cat "$log_file")"
    PROGRESS_DURATION="$(format_short_duration $((SECONDS - started)))"
    rm -f "$log_file"
    return "$status"
}

# -----------------------------
# Common helpers
# -----------------------------

error() {
    local exit_code="${1:-1}"
    local message="${2:-Installation failed.}"
    local first_line="${message%%$'\n'*}"

    echo ""
    echo "${RED}${BOLD}${ICON_FAIL} ${first_line}${RESET}"
    if [[ "$message" == *$'\n'* ]]; then
        echo "${RED}${message#*$'\n'}${RESET}"
    fi

    exit "$exit_code"
}

warning() {
    echo "${YELLOW}${ICON_WARN} Warning:${RESET} $1"
}

add_action() { RUN_ACTIONS+=("$1"); }
add_package_installed() { PACKAGES_INSTALLED+=("$1"); }
add_package_updated() { PACKAGES_UPDATED+=("$1"); }
add_package_skipped() { PACKAGES_SKIPPED+=("$1"); }
add_package_missing() { PACKAGES_MISSING+=("$1"); }
add_package_higher_than_target() { PACKAGES_HIGHER_THAN_TARGET+=("$1"); }
add_post_step_run() { POST_STEPS_RUN+=("$1"); }
add_post_step_skipped() { POST_STEPS_SKIPPED+=("$1"); }

format_duration() {
    local total_seconds="$1"
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))
    local seconds=$((total_seconds % 60))

    printf "%02dh %02dm %02ds" "$hours" "$minutes" "$seconds"
}

print_array_items() {
    local title="$1"
    local icon="$2"
    shift 2

    if [[ "$#" -eq 0 ]]; then
        return 0
    fi

    if [[ "$#" -eq 1 && -z "${1:-}" ]]; then
        return 0
    fi

    echo ""
    echo "  ${BOLD}$title${RESET}"
    local entry=""
    for entry in "$@"; do
        echo "    $icon $entry"
    done
}

array_length() {
    local array_name="$1"
    local length=0

    eval "length=\${#${array_name}[@]}" 2>/dev/null || length=0
    echo "$length"
}

active_modes() {
    local modes=()

    [[ "$DRY_RUN" == "true" ]] && modes+=("dry-run")
    [[ "$SELF_CHECK_ONLY" == "true" ]] && modes+=("self-check")
    [[ "$PACKAGE_PLAN_ONLY" == "true" ]] && modes+=("package-plan")
    [[ "$UPDATE_PACKAGES_ONLY" == "true" ]] && modes+=("update-packages")
    [[ "$DELETE_ORG_ONLY" == "true" ]] && modes+=("delete-org-only")
    [[ "$POST_STEPS_ONLY_MODE" == "true" ]] && modes+=("post-steps-only")
    [[ "$FULL_DEPLOY" == "true" ]] && modes+=("full-deploy")
    [[ "$CHECK_PROJECT_VERSIONS_ONLY" == "true" ]] && modes+=("check-versions")
    [[ "$COVERAGE_CHECK_ONLY" == "true" ]] && modes+=("coverage-check")
    [[ "$INSTALL_LATEST_PACKAGES" == "true" ]] && modes+=("install-latest")
    [[ "$USE_POOL" == "true" ]] && modes+=("use-pool")
    [[ "$REFRESH_DEPENDENCY_SOURCES" == "true" ]] && modes+=("refresh-dependency-sources")
    [[ "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" ]] && modes+=("clear-dependency-sources-only")
    [[ "$VERBOSE" == "true" ]] && modes+=("verbose")

    if [[ "${#modes[@]}" -eq 0 ]]; then
        echo "standard"
        return 0
    fi

    local joined=""
    joined="$(printf '%s, ' "${modes[@]}")"
    echo "${joined%, }"
}

print_run_summary() {
    local exit_code="${1:-0}"

    if [[ "$SUMMARY_ENABLED" != "true" ]]; then
        return 0
    fi

    if [[ "$SUMMARY_PRINTED" == "true" ]]; then
        return 0
    fi

    SUMMARY_PRINTED=true

    local ended_at=""
    local elapsed_seconds=""
    local status=""
    local installed_label="Installed"
    local updated_label="Updated"

    ended_at="$(date '+%Y-%m-%d %H:%M:%S %Z')"
    elapsed_seconds=$((SECONDS - RUN_STARTED_SECONDS))

    if [[ "$exit_code" -eq 0 ]]; then
        status="${GREEN}${BOLD}${ICON_OK} SUCCESS${RESET}"
    else
        status="${RED}${BOLD}${ICON_FAIL} FAILED (exit code $exit_code)${RESET}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        installed_label="Would install"
        updated_label="Would update"
    fi

    banner "Run summary"
    kv "Status" "$status" 14
    kv "Duration" "$(format_duration "$elapsed_seconds")" 14
    kv "Started" "$RUN_STARTED_AT" 14
    kv "Ended" "$ended_at" 14
    kv "Org alias" "$ORG_ALIAS" 14
    kv "Active modes" "$(active_modes)" 14
    kv "Org" "$ORG_ACTION" 14
    kv "Post steps" "$POST_STEPS" 14

    echo ""
    echo "  ${BOLD}Packages${RESET}"
    printf '    %s %-19s %s\n' "${GREEN}${ICON_OK}${RESET}" "$installed_label" "$(array_length PACKAGES_INSTALLED)"
    printf '    %s %-19s %s\n' "${BLUE}${ICON_UPDATE}${RESET}" "$updated_label" "$(array_length PACKAGES_UPDATED)"
    printf '    %s %-19s %s\n' "${DIM}${ICON_SKIP}${RESET}" "Already correct" "$(array_length PACKAGES_SKIPPED)"
    printf '    %s %-19s %s\n' "${YELLOW}${ICON_WARN}${RESET}" "Higher than target" "$(array_length PACKAGES_HIGHER_THAN_TARGET)"
    printf '    %s %-19s %s\n' "${YELLOW}${ICON_INFO}${RESET}" "Missing before" "$(array_length PACKAGES_MISSING)"

    print_array_items "Packages missing before install" "${YELLOW}${ICON_INFO}${RESET}" "${PACKAGES_MISSING[@]-}"
    print_array_items "Packages installed" "${GREEN}${ICON_OK}${RESET}" "${PACKAGES_INSTALLED[@]-}"
    print_array_items "Packages updated" "${BLUE}${ICON_UPDATE}${RESET}" "${PACKAGES_UPDATED[@]-}"
    print_array_items "Packages skipped" "${DIM}${ICON_SKIP}${RESET}" "${PACKAGES_SKIPPED[@]-}"
    print_array_items "Packages higher than target" "${YELLOW}${ICON_WARN}${RESET}" "${PACKAGES_HIGHER_THAN_TARGET[@]-}"

    echo ""
    echo "  ${BOLD}Post steps${RESET}"
    if [[ "$(array_length POST_STEPS_RUN)" -eq 0 ]]; then
        echo "    ${DIM}${ICON_SKIP} Ran:     none${RESET}"
    else
        echo "    ${GREEN}${ICON_OK}${RESET} Ran:     ${POST_STEPS_RUN[*]-}"
    fi

    if [[ "$(array_length POST_STEPS_SKIPPED)" -eq 0 ]]; then
        echo "    ${DIM}${ICON_SKIP} Skipped: none${RESET}"
    else
        echo "    ${DIM}${ICON_SKIP}${RESET} Skipped: ${POST_STEPS_SKIPPED[*]-}"
    fi

    print_array_items "Actions" "${CYAN}${ICON_INFO}${RESET}" "${RUN_ACTIONS[@]-}"

    echo "${BOLD}${BLUE}$(rule 60)${RESET}"
    echo ""
}

on_exit() {
    local exit_code=$?
    set +e
    print_run_summary "$exit_code"
}

trap on_exit EXIT

format_command() {
    printf '%q ' "$@"
    echo ""
}

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  ${YELLOW}[dry-run] Would run:${RESET} ${DIM}$(format_command "$@")${RESET}"
        return 0
    fi

    "$@"
}

# Runs an `sf ... --json` command and strips any non-JSON banner text
# (e.g. the CLI telemetry consent notice) that some sf versions print to stdout
# before the JSON payload, so the result can be piped straight into jq.
sf_json() {
    "$@" --json 2>&1 | sed -n '/^{/,$p'
}

is_retryable_package_install_failure() {
    local output="$1"

    case "$output" in
        *"TypeError: terminated"*|*"ECONNRESET"*|*"read ECONNRESET"*|*"socket hang up"*|*"ETIMEDOUT"*|*"ENOTFOUND"*|*"UND_ERR_"*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

usage() {
    cat <<'EOF_USAGE'
create-scratch-org.sh - create and configure a Salesforce scratch org for this project.

A full run: delete the old org with the same alias, create a new one, install the
package dependencies from sfdx-project.json, then run the post-steps
(deploy, permsets, data, community, custom steps).

Usage:
  ./bin/create-scratch-org.sh [options]

Common tasks:
  New scratch org (full setup)          ./bin/create-scratch-org.sh
  Preview without changing anything     ./bin/create-scratch-org.sh --dry-run
  Check tools, login and config         ./bin/create-scratch-org.sh --self-check
  Re-run the post-steps on existing org ./bin/create-scratch-org.sh --post-steps-only
  Re-run selected post-steps            ./bin/create-scratch-org.sh --post-steps-only --post-steps data,permsets
  Force a full redeploy of all source   ./bin/create-scratch-org.sh --redeploy
  Install missing/outdated packages     ./bin/create-scratch-org.sh --update-packages
  See what packages would change        ./bin/create-scratch-org.sh --package-plan
  Delete the scratch org                ./bin/create-scratch-org.sh --delete-org-only
  Create sf-project.config.json         ./bin/create-scratch-org.sh --init-config

Target and scratch org:
  -a, --alias <alias>             Org alias. Config: defaultOrgAlias. Default: project directory name.
  -d, --duration-days <1-30>      Scratch org lifetime. Config: scratchDurationDays. Default: 14
  -f, --definition-file <file>    Scratch org definition. Config: scratchDefinition.
                                  Default: config/project-scratch-def.json
  --use-pool                      Fetch an org from the sfp pool first. Config: pool.use
  --pool-tag <tag>                sfp pool tag. Config: pool.tag. Default: dev
  --pool-devhub <alias>           Dev Hub for sfp. Config: pool.devHub. Default: sf target-dev-hub.

What to run:
  --post-steps-only               Use an existing org: skip org create and package install.
  -s, --post-steps <steps>        Comma-separated post-steps. Config: postSteps. Default: deploy
                                  Values: deploy, permsets, data, community, custom step names, all, none.
  --redeploy                      Shortcut for --post-steps-only --post-steps deploy --full-deploy.
  --full-deploy                   The deploy step deletes local source tracking first, so all local
                                  source is deployed, not only tracked changes. Org data is untouched.
  --skip-org                      Do not delete/create/fetch the scratch org.
  --skip-packages                 Do not install packages.
  --delete-org-only               Only delete the org with the given alias.

Post-step settings:
  --permission-sets <names>       Permission sets for the permsets step. Config: permissionSets.
  --dummy-data-plan <file>        Data plan for the data step. Config: dummyDataPlan.
  -c, --community-name <name>     Community for the community step. Config: communityName.

Packages:
  --update-packages               Only install dependencies that are missing or behind (no org create).
  --install-latest                Use the latest released versions instead of sfdx-project.json versions.
  --package-plan                  Show what would be installed or updated, without changes.
  --skip-version-check            Do not warn when dependencies are not on the latest release.
  --keychain-service <service>    macOS Keychain service holding the install key.
  --keychain-account <account>    macOS Keychain account for the install key.

Preview and checks:
  --dry-run                       Print every changing command instead of running it.
  --self-check                    Check commands, CLI login, files and package resolution. No changes.

Maintenance:
  --check-versions                Preview newer package versions for sfdx-project.json.
  --apply-project-versions        Write them (creates sfdx-project.json.backup).
  --coverage-check                Run Apex tests on an existing org and check aggregate coverage.
    --coverage-package-id <04t>   Package version to install first.
    --coverage-minimum <percent>  Required coverage. Default: 75
    --coverage-test-class <name>  Test class to run (otherwise all tests).
    --coverage-class-pattern <p>  Apex class LIKE filter.
    --coverage-run-all            Run all tests even if a test class is configured.
    --coverage-skip-install       Skip the package install.
    --coverage-skip-deploy        Skip the force-app deploy.
  --refresh-dependency-sources    Clear dependency source folders before setup, retrieve them after.
  --clear-dependency-sources-only Clear dependency source folders and exit.

Configuration:
  -p, --project-file <file>       Salesforce DX project file. Default: sfdx-project.json
  --config <file>                 Config file. Default: sf-project.config.json next to the project file.
  --no-config                     Ignore the config file.
  --init-config                   Write sf-project.config.json from the effective settings and exit.
                                  Add --dry-run to print it, --force to update an existing file.
  Precedence: command-line option > environment variable > sf-project.config.json > default.

Output:
  --verbose                       Show Salesforce CLI output for successful package installs.
  --color / --no-color            Force colours on or off. Default: on in a terminal only.
  -h, --help                      Show this help.

Source tracking:
  The deploy step only sends changes that source tracking has recorded since the last
  reset. If the org is missing metadata, run --redeploy (or add --full-deploy).

Environment variables:
  ORG_ALIAS, DURATION_DAYS, SCRATCH_DEF_FILE, PROJECT_FILE, COMMUNITY_NAME, DUMMY_DATA_PLAN,
  POST_STEPS, PERMISSION_SETS, USE_POOL, POOL_TAG, POOL_DEVHUB_USERNAME,
  FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY, SF_PROJECT_CONFIG, FULL_DEPLOY, VERBOSE
                                      Same as the matching option or config value.
  PACKAGE_INSTALL_KEY                 Install key for packages that need one.
  PACKAGE_INSTALL_KEY_ENV_VAR         Name of the variable holding the key.
                                      Config: packageInstallKeyEnvironmentVariable.
  PACKAGE_INSTALL_KEYCHAIN_SERVICE    macOS Keychain service for the key.
  PACKAGE_INSTALL_KEYCHAIN_ACCOUNT    macOS Keychain account for the key.
  PACKAGES_NOT_REQUIRING_INSTALL_KEY  Comma-separated override of packageKeyConfig.
  PACKAGE_INSTALL_MAX_ATTEMPTS        Install attempts for transient CLI/network errors. Default: 3
  PACKAGE_INSTALL_RETRY_DELAY_SECONDS Delay between attempts. Default: 5
  PRESERVE_ROOT_FILES                 Root files kept during dependency cleanup. Default: README.md
  DUMMY_USER_FILE                     Dummy user file for the data step. Config: dummyUsers.file
  DUMMY_USER_PROFILE_NAME             Default dummy user profile. Config: dummyUsers.profileName
  DUMMY_USER_PERMSET_ASSIGNMENTS      "PermA,PermB:user1,user2;PermC:user3".
                                      Config: dummyUsers.permissionSetAssignments
  NO_COLOR / FORCE_COLOR              Disable colours / enable them outside a terminal.
EOF_USAGE
}

require_option_value() {
    local option_name="$1"
    local option_value="${2:-}"

    if [[ -z "$option_value" || "$option_value" == -* ]]; then
        error 1 "Missing value for option: $option_name"
    fi
}

validate_number() {
    local value="$1"
    local name="$2"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        error 1 "$name must be a number. Got: $value"
    fi
}

validate_boolean() {
    local value="$1"
    local name="$2"

    case "$value" in
        true|false) ;;
        *) error 1 "$name must be either true or false. Got: $value" ;;
    esac
}

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        error 1 "Required command not found: $command_name"
    fi
}

validate_file_exists() {
    local file_path="$1"
    local name="$2"

    if [[ ! -f "$file_path" ]]; then
        error 1 "$name not found: $file_path"
    fi
}

validate_json_file() {
    local file_path="$1"

    if ! jq empty "$file_path" >/dev/null 2>&1; then
        error 1 "Invalid JSON file: $file_path"
    fi
}

# -----------------------------
# sf-project.config.json
# -----------------------------

resolve_config_file() {
    if [[ -n "$SF_PROJECT_CONFIG" ]]; then
        CONFIG_FILE="$SF_PROJECT_CONFIG"
    elif [[ "$(dirname "$PROJECT_FILE")" == "." ]]; then
        CONFIG_FILE="$CONFIG_FILE_NAME"
    else
        CONFIG_FILE="$(dirname "$PROJECT_FILE")/$CONFIG_FILE_NAME"
    fi
}

run_in_project_root() {
    (cd "$(project_root_dir)" && "$@")
}

validate_duration_days() {
    validate_number "$DURATION_DAYS" "Duration days"

    if (( 10#$DURATION_DAYS < 1 || 10#$DURATION_DAYS > 30 )); then
        error 2 "Duration days must be an integer from 1 to 30. Got: $DURATION_DAYS"
    fi
}

config_validation_errors() {
    # Mirrors the sf-project Zod schema so both tools accept and reject the same files.
    jq -r --arg builtins "$BUILTIN_POST_STEPS" '
        def string_list: type == "array" and all(.[]; type == "string" and length > 0);
        def nonempty_string: type == "string" and length > 0;
        def positive_int: type == "number" and . == floor and . > 0;
        def field(key; check; message): if has(key) and ((.[key] | check) | not) then message else empty end;
        if type != "object" then
            "the root value must be a JSON object"
        else
            [$builtins | splits(" ")] as $builtin_steps
            | [.customPostSteps? | arrays | .[] | objects | .name | strings] as $custom_names
            | field("schemaVersion"; . == 1; "unsupported schemaVersion: \(.schemaVersion). Supported: 1"),
            field("defaultOrgAlias"; nonempty_string; "defaultOrgAlias must be a non-empty string"),
            field("scratchDefinition"; nonempty_string; "scratchDefinition must be a non-empty string"),
            field("scratchDurationDays"; type == "number" and . == floor and . >= 1 and . <= 30; "scratchDurationDays must be an integer between 1 and 30"),
            field("permissionSets"; string_list; "permissionSets must be an array of non-empty strings"),
            field("dummyDataPlan"; . == null or nonempty_string; "dummyDataPlan must be a non-empty string or null"),
            field("communityName"; . == null or nonempty_string; "communityName must be a non-empty string or null"),
            field("postSteps"; string_list; "postSteps must be an array of non-empty strings"),
            field("customPostSteps"; type == "array" and all(.[]; type == "object"
                and (.name | nonempty_string)
                and (.executable | nonempty_string)
                and ((.arguments // []) | type == "array" and all(.[]; type == "string"))
                and ((has("label") | not) or (.label | nonempty_string)));
                "customPostSteps entries need a non-empty name and executable, an optional string arguments array and an optional non-empty label"),
            ($custom_names[] | select(IN($builtin_steps[])) | "customPostSteps name collides with a built-in post-step: \(.)"),
            ($custom_names | group_by(.) | map(select(length > 1) | .[0]) | .[] | "customPostSteps declares the same name more than once: \(.)"),
            (.postSteps? | arrays | .[] | strings | select(IN(($builtin_steps + $custom_names)[]) | not) | "postSteps references an unknown step: \(.)"),
            field("pool"; type == "object"; "pool must be an object"),
            (.pool | objects
                | field("use"; type == "boolean"; "pool.use must be a boolean"),
                field("tag"; nonempty_string; "pool.tag must be a non-empty string"),
                field("devHub"; nonempty_string; "pool.devHub must be a non-empty string"),
                field("fallbackToCreate"; type == "boolean"; "pool.fallbackToCreate must be a boolean")),
            field("packageInstallKeyEnvironmentVariable"; nonempty_string; "packageInstallKeyEnvironmentVariable must be a non-empty string"),
            field("commandTimeouts"; type == "object"; "commandTimeouts must be an object"),
            (.commandTimeouts | objects
                | field("readMs"; positive_int; "commandTimeouts.readMs must be a positive integer"),
                field("mutationMs"; positive_int; "commandTimeouts.mutationMs must be a positive integer")),
            field("dependencySourcePolicy"; type == "object"; "dependencySourcePolicy must be an object"),
            (.dependencySourcePolicy | objects
                | field("preserveRootFiles"; string_list; "dependencySourcePolicy.preserveRootFiles must be an array of non-empty strings"),
                field("requireLocalDirectories"; type == "boolean"; "dependencySourcePolicy.requireLocalDirectories must be a boolean")),
                field("coverage"; type == "object"; "coverage must be an object"),
                (.coverage | objects
                    | field("minimumPercent"; type == "number" and . >= 0 and . <= 100; "coverage.minimumPercent must be between 0 and 100"),
                    field("testClass"; . == null or nonempty_string; "coverage.testClass must be a non-empty string or null"),
                    field("classNamePattern"; nonempty_string; "coverage.classNamePattern must be a non-empty string")),
            field("dummyUsers"; type == "object"; "dummyUsers must be an object"),
            (.dummyUsers | objects
                | (if has("file") then empty else "dummyUsers.file is required" end),
                field("file"; nonempty_string; "dummyUsers.file must be a non-empty string"),
                field("profileName"; nonempty_string; "dummyUsers.profileName must be a non-empty string"),
                field("profileAssignments"; type == "array" and all(.[]; type == "object"
                    and (.profileName | nonempty_string)
                    and (.usernames | string_list and length > 0))
                    and ([.[].usernames[]] | length == (unique | length));
                    "dummyUsers.profileAssignments entries need a profileName and non-empty usernames, with each username assigned only once"),
                field("permissionSetAssignments"; type == "array" and all(.[]; type == "object"
                    and (.permissionSets | string_list and length > 0)
                    and (.usernames | string_list and length > 0));
                    "dummyUsers.permissionSetAssignments entries need non-empty permissionSets and usernames arrays"))
        end
    ' "$CONFIG_FILE"
}

config_get() {
    jq -r "($1) | if . == null then empty elif type == \"array\" then join(\",\") else tostring end" "$CONFIG_FILE"
}

config_is_empty_array() {
    jq -e "($1) == []" "$CONFIG_FILE" >/dev/null
}

# Relative paths resolve from the project root, as in sf-project.
config_path() {
    local value="$1"

    if [[ "$value" == /* || "$(project_root_dir)" == "." ]]; then
        echo "$value"
    else
        echo "$(project_root_dir)/$value"
    fi
}

apply_config_value() {
    local variable_name="$1"
    local jq_path="$2"
    local kind="${3:-value}"
    local value=""

    [[ -n "${!variable_name}" ]] && return 0

    value="$(config_get "$jq_path")"
    [[ -z "$value" ]] && return 0

    if [[ "$kind" == "path" ]]; then
        value="$(config_path "$value")"
    fi

    printf -v "$variable_name" '%s' "$value"
}

load_config() {
    local validation_errors=""

    if [[ "$USE_CONFIG" != "true" ]]; then
        return 0
    fi

    if [[ ! -f "$CONFIG_FILE" ]]; then
        if [[ -n "$SF_PROJECT_CONFIG" ]]; then
            error 2 "Configuration file not found: $CONFIG_FILE"
        fi
        return 0
    fi

    require_command "jq"

    if ! jq empty "$CONFIG_FILE" >/dev/null 2>&1; then
        error 2 "Invalid JSON in configuration file: $CONFIG_FILE"
    fi

    validation_errors="$(config_validation_errors)"
    if [[ -n "$validation_errors" ]]; then
        error 2 "Invalid configuration file $CONFIG_FILE:"$'\n'"$(sed 's/^/- /' <<< "$validation_errors")"
    fi

    if [[ -z "$ORG_ALIAS" ]]; then
        apply_config_value ORG_ALIAS '.defaultOrgAlias'
        [[ -n "$ORG_ALIAS" ]] && ORG_ALIAS_SOURCE="$CONFIG_FILE defaultOrgAlias"
    fi

    apply_config_value SCRATCH_DEF_FILE '.scratchDefinition' path
    apply_config_value DURATION_DAYS '.scratchDurationDays'
    apply_config_value PERMISSION_SETS '.permissionSets'
    apply_config_value DUMMY_DATA_PLAN '.dummyDataPlan' path
    apply_config_value COMMUNITY_NAME '.communityName'
    apply_config_value POST_STEPS '.postSteps'
    apply_config_value USE_POOL '.pool.use'
    apply_config_value POOL_TAG '.pool.tag'
    apply_config_value POOL_DEVHUB_USERNAME '.pool.devHub'
    apply_config_value FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY '.pool.fallbackToCreate'
    apply_config_value PACKAGE_INSTALL_KEY_ENV_VAR '.packageInstallKeyEnvironmentVariable'
    apply_config_value PRESERVE_ROOT_FILES '.dependencySourcePolicy.preserveRootFiles'
    apply_config_value DUMMY_USER_FILE '.dummyUsers.file' path
    apply_config_value DUMMY_USER_PROFILE_NAME '.dummyUsers.profileName'
    DUMMY_PROFILE_ASSIGNMENTS_JSON="$(jq -c '.dummyUsers.profileAssignments // []' "$CONFIG_FILE")"
    apply_config_value COVERAGE_MINIMUM '.coverage.minimumPercent'
    apply_config_value COVERAGE_TEST_CLASS '.coverage.testClass'
    apply_config_value COVERAGE_CLASS_PATTERN '.coverage.classNamePattern'

    # An empty array means "nothing" in sf-project, not "use the default".
    if [[ -z "$POST_STEPS" ]] && config_is_empty_array '.postSteps'; then
        POST_STEPS="none"
    fi
    if [[ -z "$PRESERVE_ROOT_FILES" ]] && config_is_empty_array '.dependencySourcePolicy.preserveRootFiles'; then
        PRESERVE_NOTHING=true
    fi
    if [[ "$(config_get '.dependencySourcePolicy.requireLocalDirectories')" == "false" ]]; then
        REQUIRE_LOCAL_DIRECTORIES=false
    fi

    if [[ -z "$DUMMY_USER_PERMSET_ASSIGNMENTS" ]]; then
        DUMMY_USER_ASSIGNMENTS="$(jq -r '.dummyUsers.permissionSetAssignments[]? | "\((.permissionSets // []) | join(" "))|\((.usernames // []) | join(" "))"' "$CONFIG_FILE")"
    fi

    CUSTOM_POST_STEP_NAMES="$(jq -r '[.customPostSteps[]?.name] | join(" ")' "$CONFIG_FILE")"
    CONFIG_LOADED=true
}

parse_dummy_user_assignments_from_environment() {
    local group=""
    local permission_sets=""
    local usernames=""

    [[ -z "$DUMMY_USER_PERMSET_ASSIGNMENTS" ]] && return 0

    DUMMY_USER_ASSIGNMENTS=""
    IFS=';' read -ra assignment_groups <<< "$DUMMY_USER_PERMSET_ASSIGNMENTS"
    for group in "${assignment_groups[@]}"; do
        [[ -z "${group// /}" ]] && continue
        if [[ "$group" != *:* ]]; then
            error 1 "Invalid DUMMY_USER_PERMSET_ASSIGNMENTS entry: $group. Expected <permission sets>:<usernames>."
        fi
        permission_sets="${group%%:*}"
        usernames="${group#*:}"
        DUMMY_USER_ASSIGNMENTS+="${permission_sets//,/ }|${usernames//,/ }"$'\n'
    done
}

apply_generic_defaults() {
    if [[ -z "$ORG_ALIAS" ]]; then
        ORG_ALIAS="$(basename "$(cd "$(dirname "$PROJECT_FILE")" && pwd)")"
        ORG_ALIAS_SOURCE="default"
    fi

    DURATION_DAYS="${DURATION_DAYS:-$DEFAULT_DURATION_DAYS}"
    SCRATCH_DEF_FILE="${SCRATCH_DEF_FILE:-$(config_path "$DEFAULT_SCRATCH_DEF_FILE")}"
    POST_STEPS="${POST_STEPS:-$DEFAULT_POST_STEPS}"
    USE_POOL="${USE_POOL:-false}"
    POOL_TAG="${POOL_TAG:-$DEFAULT_POOL_TAG}"
    FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY="${FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY:-true}"
    DUMMY_USER_PROFILE_NAME="${DUMMY_USER_PROFILE_NAME:-$DEFAULT_DUMMY_USER_PROFILE_NAME}"
    COVERAGE_MINIMUM="${COVERAGE_MINIMUM:-75}"
    COVERAGE_CLASS_PATTERN="${COVERAGE_CLASS_PATTERN:-%}"
    PACKAGE_INSTALL_KEY_ENV_VAR="${PACKAGE_INSTALL_KEY_ENV_VAR:-$DEFAULT_PACKAGE_INSTALL_KEY_ENV_VAR}"
    PRESERVE_ROOT_FILES="${PRESERVE_ROOT_FILES:-$DEFAULT_PRESERVE_ROOT_FILES}"
    if [[ "$PRESERVE_NOTHING" == "true" ]]; then
        PRESERVE_ROOT_FILES=""
    fi
    PERMISSION_SETS="$(tr -s ' ,' ',' <<< "$PERMISSION_SETS" | sed 's/^,//; s/,$//')"

    if [[ -z "$PACKAGE_INSTALL_KEY" ]]; then
        PACKAGE_INSTALL_KEY="$(printenv -- "$PACKAGE_INSTALL_KEY_ENV_VAR" || true)"
    fi

    if ! [[ "$COVERAGE_MINIMUM" =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk -v value="$COVERAGE_MINIMUM" 'BEGIN { exit !(value >= 0 && value <= 100) }'; then
        error 2 "coverage.minimumPercent must be a number from 0 to 100. Got: $COVERAGE_MINIMUM"
    fi
}

config_relative_path() {
    local value="$1"
    local root=""

    root="$(project_root_dir)"
    if [[ -n "$value" && "$root" != "." && "$value" == "$root/"* ]]; then
        echo "${value#"$root/"}"
    else
        echo "$value"
    fi
}

generate_config_json() {
    local expanded_post_steps="$POST_STEPS"

    if [[ "$POST_STEPS" == "all" ]]; then
        expanded_post_steps="$(all_post_step_names | tr ' ' ',')"
    elif [[ "$POST_STEPS" == "none" ]]; then
        expanded_post_steps=""
    fi

    # Install keys are deliberately not passed to jq: only the variable name is written.
    jq -n \
        --arg alias "$ORG_ALIAS" \
        --arg scratchDefinition "$(config_relative_path "$SCRATCH_DEF_FILE")" \
        --argjson durationDays "$DURATION_DAYS" \
        --arg permissionSets "$PERMISSION_SETS" \
        --arg dataPlan "$(config_relative_path "$DUMMY_DATA_PLAN")" \
        --arg community "$COMMUNITY_NAME" \
        --arg postSteps "$expanded_post_steps" \
        --argjson usePool "$USE_POOL" \
        --arg poolTag "$POOL_TAG" \
        --arg poolDevHub "$POOL_DEVHUB_USERNAME" \
        --argjson fallbackToCreate "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" \
        --arg keyVariable "$PACKAGE_INSTALL_KEY_ENV_VAR" \
        --arg preserveRootFiles "$PRESERVE_ROOT_FILES" \
        --arg userFile "$(config_relative_path "$DUMMY_USER_FILE")" \
        --arg userProfile "$DUMMY_USER_PROFILE_NAME" \
        --arg userAssignments "$DUMMY_USER_ASSIGNMENTS" \
        --argjson coverageMinimum "$COVERAGE_MINIMUM" \
        --arg coverageTestClass "$COVERAGE_TEST_CLASS" \
        --arg coverageClassPattern "$COVERAGE_CLASS_PATTERN" '
        def list: [splits("[,[:space:]]+")] | map(select(length > 0));
        def nullable: if . == "" then null else . end;
        {
            schemaVersion: 1,
            defaultOrgAlias: $alias,
            scratchDefinition: $scratchDefinition,
            scratchDurationDays: $durationDays,
            permissionSets: ($permissionSets | list),
            dummyDataPlan: ($dataPlan | nullable),
            communityName: ($community | nullable),
            postSteps: ($postSteps | list),
            pool: ({ use: $usePool, tag: $poolTag, fallbackToCreate: $fallbackToCreate }
                + (if $poolDevHub == "" then {} else { devHub: $poolDevHub } end)),
            packageInstallKeyEnvironmentVariable: $keyVariable,
            coverage: {
                minimumPercent: $coverageMinimum,
                testClass: ($coverageTestClass | nullable),
                classNamePattern: $coverageClassPattern
            },
            dependencySourcePolicy: { preserveRootFiles: ($preserveRootFiles | list) }
        }
        + (if $userFile == "" then {} else {
            dummyUsers: {
                file: $userFile,
                profileName: $userProfile,
                permissionSetAssignments: [
                    $userAssignments | split("\n")[] | select(length > 0) | split("|")
                    | { permissionSets: (.[0] | list), usernames: ((.[1] // "") | list) }
                ]
            }
        } end)
    '
}

init_config() {
    local generated_json=""
    local output_json=""
    local temporary_file=""

    require_command "jq"

    if [[ "$USE_CONFIG" != "true" ]]; then
        error 1 "--init-config cannot be combined with --no-config."
    fi

    if [[ -f "$CONFIG_FILE" && "$FORCE_INIT_CONFIG" != "true" && "$DRY_RUN" != "true" ]]; then
        error 1 "$CONFIG_FILE already exists. Use --init-config --force to update it; keys this script does not manage are kept."
    fi

    generated_json="$(generate_config_json)"

    if [[ -f "$CONFIG_FILE" ]]; then
        output_json="$(jq -s '.[0] * .[1]' "$CONFIG_FILE" - <<< "$generated_json")"
    else
        output_json="$(jq '.' <<< "$generated_json")"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        echo "Dry-run: would write $CONFIG_FILE:"
        jq --indent 4 '.' <<< "$output_json"
        ORG_ACTION="No org action. Dry-run configuration preview."
        return 0
    fi

    temporary_file="$(mktemp "$CONFIG_FILE.XXXXXX")"
    jq --indent 4 '.' <<< "$output_json" > "$temporary_file"
    mv "$temporary_file" "$CONFIG_FILE"

    echo ""
    echo "${GREEN}${ICON_OK}${RESET} Wrote $CONFIG_FILE."
    info "Keep installation keys in \$$PACKAGE_INSTALL_KEY_ENV_VAR or an approved secret store, never in this file."
    ORG_ACTION="No org action. Configuration file written."
    add_action "Wrote $CONFIG_FILE"
}

validate_post_steps() {
    POST_STEPS="${POST_STEPS// /}"

    if [[ "$POST_STEPS" == "all" || "$POST_STEPS" == "none" ]]; then
        return 0
    fi

    IFS=',' read -ra selected_steps <<< "$POST_STEPS"

    for step in "${selected_steps[@]}"; do
        if ! is_known_post_step "$step"; then
            error 1 "Invalid post step: $step. Valid values are: all, none, $(all_post_step_names | tr ' ' ',' | sed 's/,/, /g')"
        fi
    done
}

all_post_step_names() {
    echo "$BUILTIN_POST_STEPS${CUSTOM_POST_STEP_NAMES:+ $CUSTOM_POST_STEP_NAMES}"
}

is_known_post_step() {
    [[ " $(all_post_step_names) " == *" $1 "* ]]
}

should_run_post_step() {
    local step="$1"

    if [[ "$POST_STEPS" == "all" ]]; then
        return 0
    fi

    if [[ "$POST_STEPS" == "none" ]]; then
        return 1
    fi

    if [[ ",$POST_STEPS," == *",$step,"* ]]; then
        return 0
    fi

    return 1
}

needs_project_file() {
    if [[ "$RUN_PACKAGES" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" || "$CHECK_PROJECT_VERSIONS_ONLY" == "true" || "$COVERAGE_CHECK_ONLY" == "true" || "$SELF_CHECK_ONLY" == "true" || "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" ]]; then
        return 0
    fi

    return 1
}

read_dependencies() {
    jq -r '
        .packageDirectories[]?
        | select(.dependencies != null)
        | .dependencies[]?
        | [.package, .versionNumber]
        | @tsv
    ' "$PROJECT_FILE"
}

dependency_count() {
    jq -r '
        [
            .packageDirectories[]?
            | select(.dependencies != null)
            | .dependencies[]?
        ]
        | length
    ' "$PROJECT_FILE"
}

package_requires_key() {
    local package_name="$1"

    if [[ -n "$PACKAGES_NOT_REQUIRING_INSTALL_KEY" ]]; then
        local normalized_no_key_packages=",${PACKAGES_NOT_REQUIRING_INSTALL_KEY// /},"
        [[ "$normalized_no_key_packages" != *",$package_name,"* ]]
        return
    fi

    # Same rule as sf-project: a package missing from packageKeyConfig requires a key.
    [[ "$(jq -r --arg package_name "$package_name" '.packageKeyConfig[$package_name] | if . == false then "false" else "true" end' "$PROJECT_FILE")" == "true" ]]
}

resolve_package_install_key_from_keychain() {
    if [[ -n "$PACKAGE_INSTALL_KEY" ]]; then
        return 0
    fi

    if [[ "$(uname -s)" != "Darwin" ]]; then
        return 0
    fi

    if ! command -v security >/dev/null 2>&1; then
        return 0
    fi

    local services=()
    local service=""
    local key_value=""

    if [[ -n "$PACKAGE_INSTALL_KEYCHAIN_SERVICE" ]]; then
        services+=("$PACKAGE_INSTALL_KEYCHAIN_SERVICE")
    fi

    services+=(
        "$ORG_ALIAS-package-install-key"
        "$ORG_ALIAS/package-install-key"
    )

    local project_package_name=""
    project_package_name="$(jq -r '.name // first(.packageDirectories[]? | .package // empty) // empty' "$PROJECT_FILE" 2>/dev/null || true)"
    if [[ -n "$project_package_name" && "$project_package_name" != "$ORG_ALIAS" ]]; then
        services+=("$project_package_name-package-install-key")
    fi

    services+=(
        "$PACKAGE_INSTALL_KEY_ENV_VAR"
        "salesforce-package-install-key"
    )

    for service in "${services[@]}"; do
        if [[ -n "$PACKAGE_INSTALL_KEYCHAIN_ACCOUNT" ]]; then
            key_value="$(security find-generic-password -s "$service" -a "$PACKAGE_INSTALL_KEYCHAIN_ACCOUNT" -w 2>/dev/null || true)"
        else
            key_value="$(security find-generic-password -s "$service" -w 2>/dev/null || true)"
        fi

        if [[ -n "$key_value" ]]; then
            PACKAGE_INSTALL_KEY="$key_value"
            echo ""
            echo "Found package install key in macOS Keychain (service: $service)."
            return 0
        fi
    done
}

check_if_package_install_key_is_required() {
    local install_key_required=false

    if [[ "$DRY_RUN" == "true" || "$SELF_CHECK_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" ]]; then
        return 0
    fi

    if [[ "$RUN_PACKAGES" != "true" && "$UPDATE_PACKAGES_ONLY" != "true" ]]; then
        return 0
    fi

    while IFS=$'\t' read -r package_name requested_version; do
        [[ -z "$package_name" ]] && continue

        if package_requires_key "$package_name"; then
            install_key_required=true
            break
        fi
    done < <(read_dependencies)

    if [[ "$install_key_required" == "true" && -z "$PACKAGE_INSTALL_KEY" ]]; then
        resolve_package_install_key_from_keychain
    fi

    if [[ "$install_key_required" == "true" && -z "$PACKAGE_INSTALL_KEY" ]]; then
        echo ""
        read -rsp "Package install key: " PACKAGE_INSTALL_KEY
        echo ""

        if [[ -z "$PACKAGE_INSTALL_KEY" ]]; then
            error 1 "Package install key is required because one or more packages require it."
        fi
    fi
}

resolve_pool_devhub_username_for_check() {
    if [[ -n "$POOL_DEVHUB_USERNAME" ]]; then
        echo "$POOL_DEVHUB_USERNAME"
        return 0
    fi

    local resolved_devhub=""

    resolved_devhub="$(
        sf config get target-dev-hub --json 2>/dev/null \
            | jq -r '.result[]? | select(.name == "target-dev-hub") | .value // empty' \
            | head -n 1
    )"

    if [[ -z "$resolved_devhub" || "$resolved_devhub" == "null" ]]; then
        return 1
    fi

    echo "$resolved_devhub"
}

resolve_default_target_org_for_runtime() {
    local resolved_target_org=""

    resolved_target_org="$(
        sf config get target-org --json 2>/dev/null \
            | jq -r '.result[]? | select(.name == "target-org") | .value // empty' \
            | head -n 1
    )"

    if [[ -z "$resolved_target_org" || "$resolved_target_org" == "null" ]]; then
        return 1
    fi

    echo "$resolved_target_org"
}

resolve_runtime_target_org() {
    local resolved_target_org=""

    if [[ "$ORG_ALIAS_SOURCE" != "default" ]]; then
        TARGET_ORG="$ORG_ALIAS"
        TARGET_ORG_SOURCE="$ORG_ALIAS_SOURCE"
        return 0
    fi

    if [[ "$RUN_ORG_CREATE" == "true" ]]; then
        TARGET_ORG="$ORG_ALIAS"
        TARGET_ORG_SOURCE="org alias for create/fetch"
        return 0
    fi

    if resolved_target_org="$(resolve_default_target_org_for_runtime)"; then
        TARGET_ORG="$resolved_target_org"
        TARGET_ORG_SOURCE="sf config target-org"
        return 0
    fi

    error 1 "No org alias or Salesforce default target org is configured for partial run mode. Pass --alias <alias>, set defaultOrgAlias in $CONFIG_FILE_NAME, or run: sf config set target-org \"<alias-or-username>\"."
}

resolve_pool_devhub_username() {
    if [[ -n "$POOL_DEVHUB_USERNAME" ]]; then
        echo "$POOL_DEVHUB_USERNAME"
        return 0
    fi

    local resolved_devhub=""

    resolved_devhub="$(
        sf config get target-dev-hub --json 2>/dev/null \
            | jq -r '.result[]? | select(.name == "target-dev-hub") | .value // empty' \
            | head -n 1
    )"

    if [[ -z "$resolved_devhub" || "$resolved_devhub" == "null" ]]; then
        error 1 "sfp requires --targetdevhubusername, but no --pool-devhub was provided and no sf target-dev-hub config was found. Run either: sf config set target-dev-hub \"<devhub-alias>\", set pool.devHub in $CONFIG_FILE_NAME, or use: --pool-devhub \"<devhub-alias>\""
    fi

    echo "$resolved_devhub"
}

get_pool_list_output() {
    local resolved_devhub=""
    resolved_devhub="$(resolve_pool_devhub_username)"

    sfp pool list \
        --tag "$POOL_TAG" \
        -a \
        --targetdevhubusername "$resolved_devhub"
}

unused_pool_org_count() {
    local pool_output="$1"

    echo "$pool_output" \
        | sed -nE 's/.*Unused Scratch Orgs in the Pool[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' \
        | tail -n 1
}

fetch_scratch_org_from_pool() {
    local resolved_devhub=""
    resolved_devhub="$(resolve_pool_devhub_username)"

    echo ""
    step "Fetching scratch org from sfp pool..."
    kv "Pool tag" "$POOL_TAG" 10
    kv "DevHub" "$resolved_devhub" 10
    kv "Alias" "$ORG_ALIAS" 10

    run_cmd sfp pool fetch \
        --tag "$POOL_TAG" \
        --targetdevhubusername "$resolved_devhub" \
        --alias "$ORG_ALIAS" \
        --setdefaultusername \
        || error $? "Failed to fetch scratch org from sfp pool."

    if [[ "$DRY_RUN" == "true" ]]; then
        ORG_AVAILABLE_FOR_READ=false
        ORG_ACTION="Dry-run: would fetch scratch org from pool: tag=$POOL_TAG alias=$ORG_ALIAS"
        add_action "Dry-run: would fetch scratch org from pool with tag $POOL_TAG as alias $ORG_ALIAS"
    else
        ORG_AVAILABLE_FOR_READ=true
        ORG_ACTION="Fetched scratch org from pool: tag=$POOL_TAG alias=$ORG_ALIAS"
        add_action "Fetched scratch org from pool with tag $POOL_TAG as alias $ORG_ALIAS"
    fi
}

try_fetch_scratch_org_from_pool() {
    local pool_output=""
    local unused_count=""

    echo ""
    step "Checking sfp scratch org pool..."
    kv "Pool tag" "$POOL_TAG" 10

    pool_output="$(get_pool_list_output)" || error $? "Failed to list sfp scratch org pool."
    echo "$pool_output"

    unused_count="$(unused_pool_org_count "$pool_output")"

    if [[ -z "$unused_count" ]]; then
        warning "Could not parse unused scratch org count from sfp pool list output."

        if [[ "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" == "true" ]]; then
            info "Falling back to normal scratch org creation."
            return 1
        fi

        error 1 "Could not determine whether the scratch org pool has available orgs."
    fi

    if [[ "$unused_count" -gt 0 ]]; then
        echo ""
        success "Unused scratch orgs available in pool: $unused_count"
        fetch_scratch_org_from_pool
        return 0
    fi

    warning "No unused scratch orgs available in pool."

    if [[ "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" == "true" ]]; then
        info "Falling back to normal scratch org creation."
        return 1
    fi

    error 1 "No unused scratch orgs available in pool."
}

get_package_versions_json() {
    local package_name="$1"

    sf package version list \
        --released \
        --order-by CreatedDate \
        --json \
        --packages "$package_name"
}

latest_version_json() {
    local versions_json="$1"

    echo "$versions_json" | jq -c '
        .result
        | map(select(.SubscriberPackageVersionId != null))
        | sort_by(
            (.MajorVersion // 0),
            (.MinorVersion // 0),
            (.PatchVersion // 0),
            (.BuildNumber // 0),
            (.CreatedDate // "")
        )
        | last // empty
    '
}

requested_version_json() {
    local versions_json="$1"
    local requested_version="$2"

    echo "$versions_json" | jq -c --arg requested "$requested_version" '
        def released_versions:
            .result
            | map(select(.SubscriberPackageVersionId != null));

        def sort_versions:
            sort_by(
                (.MajorVersion // 0),
                (.MinorVersion // 0),
                (.PatchVersion // 0),
                (.BuildNumber // 0),
                (.CreatedDate // "")
            );

        ($requested | split(".")) as $parts
        | if ($requested == "" or $requested == "LATEST") then
            released_versions
            | sort_versions
            | last // empty
          elif (($parts | length) >= 3) then
            ($parts[0] | tonumber?) as $major
            | ($parts[1] | tonumber?) as $minor
            | ($parts[2] | tonumber?) as $patch
            | (
                released_versions
                | map(
                    select(
                        ((.MajorVersion // -1) == $major)
                        and ((.MinorVersion // -1) == $minor)
                        and ((.PatchVersion // -1) == $patch)
                        and (
                            (($parts | length) < 4)
                            or ($parts[3] == "LATEST")
                            or (($parts[3] | tonumber?) == null)
                            or ((.BuildNumber // -1) == ($parts[3] | tonumber?))
                        )
                    )
                )
                | sort_versions
                | last // empty
              )
          else
            released_versions
            | sort_versions
            | last // empty
          end
    '
}

version_label_from_json() {
    local version_json="$1"

    echo "$version_json" | jq -r '
        if . == null or . == "" then
            "unknown"
        elif .MajorVersion != null then
            "\(.MajorVersion).\(.MinorVersion).\(.PatchVersion).\(.BuildNumber // "unknown")"
        else
            .Version // .VersionNumber // .Name // "unknown"
        end
    '
}

base_version_from_json() {
    local version_json="$1"

    echo "$version_json" | jq -r '
        if . == null or . == "" then
            "unknown"
        elif .MajorVersion != null then
            "\(.MajorVersion).\(.MinorVersion).\(.PatchVersion)"
        else
            (.Version // .VersionNumber // .Name // "unknown")
            | split(".")
            | .[0:3]
            | join(".")
        end
    '
}

base_version_from_requested() {
    local requested_version="$1"

    requested_version="${requested_version%.LATEST}"
    requested_version="${requested_version%.NEXT}"

    IFS='.' read -r major minor patch rest <<< "$requested_version"

    if [[ -z "${major:-}" || -z "${minor:-}" || -z "${patch:-}" ]]; then
        echo "unknown"
        return 0
    fi

    echo "$major.$minor.$patch"
}

subscriber_package_version_id_from_json() {
    local version_json="$1"

    echo "$version_json" | jq -r '.SubscriberPackageVersionId // empty'
}

suggested_version_number_from_latest() {
    echo "$RESOLVED_LATEST_BASE_VERSION.LATEST"
}

RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID=""
RESOLVED_SELECTED_VERSION=""
RESOLVED_SELECTED_BASE_VERSION=""
RESOLVED_LATEST_VERSION=""
RESOLVED_LATEST_BASE_VERSION=""
RESOLVED_LATEST_SUBSCRIBER_PACKAGE_VERSION_ID=""

resolve_package_version() {
    local package_name="$1"
    local requested_version="$2"

    local versions_json=""
    local selected_json=""
    local latest_json=""

    versions_json="$(get_package_versions_json "$package_name")" \
        || error $? "Failed to list package versions for $package_name"

    latest_json="$(latest_version_json "$versions_json")"

    if [[ -z "$latest_json" || "$latest_json" == "null" ]]; then
        error 1 "Could not resolve latest released version for package $package_name"
    fi

    if [[ "$INSTALL_LATEST_PACKAGES" == "true" ]]; then
        selected_json="$latest_json"
    else
        selected_json="$(requested_version_json "$versions_json" "$requested_version")"
    fi

    if [[ -z "$selected_json" || "$selected_json" == "null" ]]; then
        error 1 "Could not resolve requested version $requested_version for package $package_name"
    fi

    RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID="$(subscriber_package_version_id_from_json "$selected_json")"
    RESOLVED_SELECTED_VERSION="$(version_label_from_json "$selected_json")"
    RESOLVED_SELECTED_BASE_VERSION="$(base_version_from_json "$selected_json")"

    RESOLVED_LATEST_VERSION="$(version_label_from_json "$latest_json")"
    RESOLVED_LATEST_BASE_VERSION="$(base_version_from_json "$latest_json")"
    RESOLVED_LATEST_SUBSCRIBER_PACKAGE_VERSION_ID="$(subscriber_package_version_id_from_json "$latest_json")"

    if [[ -z "$RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID" ]]; then
        error 1 "Could not find SubscriberPackageVersionId for $package_name $requested_version"
    fi
}

warn_if_dependency_is_not_latest() {
    local package_name="$1"
    local requested_version="$2"

    if [[ "$VERIFY_PACKAGE_VERSIONS" != "true" ]]; then
        return 0
    fi

    local requested_base_version=""
    local suggested_version_number=""

    requested_base_version="$(base_version_from_requested "$requested_version")"
    suggested_version_number="$(suggested_version_number_from_latest)"

    if [[ "$requested_base_version" != "$RESOLVED_LATEST_BASE_VERSION" ]]; then
        warning "$package_name is not on the latest released version. Defined: $requested_version. Latest: $RESOLVED_LATEST_VERSION ($RESOLVED_LATEST_SUBSCRIBER_PACKAGE_VERSION_ID). Suggested versionNumber: $suggested_version_number"

        PACKAGE_UPDATE_SUGGESTIONS+="$package_name|$requested_version|$suggested_version_number|$RESOLVED_LATEST_VERSION|$RESOLVED_LATEST_SUBSCRIBER_PACKAGE_VERSION_ID"$'\n'
    fi
}

print_package_update_suggestions() {
    if [[ "$VERIFY_PACKAGE_VERSIONS" != "true" ]]; then
        return 0
    fi

    if [[ -z "$PACKAGE_UPDATE_SUGGESTIONS" ]]; then
        echo ""
        success "All dependency versions in $PROJECT_FILE look up to date."
        return 0
    fi

    section "Suggested dependency updates for $PROJECT_FILE"

    while IFS='|' read -r package_name current_version suggested_version latest_version latest_04t; do
        [[ -z "$package_name" ]] && continue

        item "${YELLOW}${ICON_UPDATE}${RESET} ${BOLD}$package_name${RESET}"
        kv "Current versionNumber" "$current_version" 24
        kv "Suggested versionNumber" "${GREEN}$suggested_version${RESET}" 24
        kv "Latest resolved version" "$latest_version" 24
        kv "Latest 04t" "$latest_04t" 24
    done <<< "$PACKAGE_UPDATE_SUGGESTIONS"

    echo ""
    echo "${BOLD}Dependency entries you can copy into $PROJECT_FILE:${RESET}"
    echo ""

    while IFS='|' read -r package_name current_version suggested_version latest_version latest_04t; do
        [[ -z "$package_name" ]] && continue

        cat <<EOF_JSON
{
    "package": "$package_name",
    "versionNumber": "$suggested_version"
},
EOF_JSON
    done <<< "$PACKAGE_UPDATE_SUGGESTIONS"

    echo ""
    info "Copy the suggested versionNumber values into the matching dependency entries in $PROJECT_FILE."
}

check_project_package_versions() {
    local package_name=""
    local current_version=""
    local comparable_version=""
    local latest_json=""
    local latest_base=""
    local latest_version=""
    local versions_json=""
    local updates_json='{}'
    local update_count=0
    local temp_file=""

    section "Latest released package versions from $PROJECT_FILE"

    while IFS=$'\t' read -r package_name current_version; do
        [[ -z "$package_name" ]] && continue
        versions_json="$(get_package_versions_json "$package_name")" \
            || error 1 "Failed to list package versions for $package_name"
        latest_json="$(latest_version_json "$versions_json")"
        if [[ -z "$latest_json" || "$latest_json" == "null" ]]; then
            error 1 "No released package version found for $package_name"
        fi

        latest_base="$(base_version_from_json "$latest_json")"
        latest_version="$latest_base.LATEST"
        comparable_version="${current_version%.LATEST}"
        comparable_version="${comparable_version%.NEXT}"
        if [[ "$comparable_version" == "$latest_base" ]]; then
            success "$package_name: ${current_version:-not configured} is current ($latest_version)"
            continue
        fi

        echo "${YELLOW}${ICON_UPDATE}${RESET} $package_name: ${current_version:-not configured} -> ${GREEN}$latest_version${RESET}"
        updates_json="$(jq -n -c --argjson updates "$updates_json" --arg package "$package_name" --arg version "$latest_version" '$updates + {($package): $version}')"
        update_count=$((update_count + 1))
    done < <(read_dependencies)

    if [[ "$update_count" -eq 0 ]]; then
        echo ""
        success "All configured package versions are current."
        return 0
    fi

    if [[ "$APPLY_PROJECT_VERSIONS" != "true" || "$DRY_RUN" == "true" ]]; then
        echo ""
        info "Preview only: $update_count package constraint(s) can be updated. Use --apply-project-versions to write them."
        return 0
    fi

    temp_file="$(mktemp "${PROJECT_FILE}.XXXXXX")"
    if ! jq --argjson updates "$updates_json" '
        .packageDirectories |= map(
            if .dependencies then
                .dependencies |= map(
                    if ($updates[.package] // null) != null then .versionNumber = $updates[.package] else . end
                )
            else . end
        )
    ' "$PROJECT_FILE" > "$temp_file"; then
        rm -f "$temp_file"
        error 1 "Could not update dependency versions in $PROJECT_FILE"
    fi

    cp -p "$PROJECT_FILE" "${PROJECT_FILE}.backup" \
        || { rm -f "$temp_file"; error 1 "Could not create backup ${PROJECT_FILE}.backup"; }
    mv -f "$temp_file" "$PROJECT_FILE" \
        || { rm -f "$temp_file"; error 1 "Could not replace $PROJECT_FILE"; }

    echo ""
    success "Updated $update_count package constraint(s). Backup: ${PROJECT_FILE}.backup"
}

run_coverage_check() {
    local -a install_arguments=(package install --target-org "$TARGET_ORG" --package "$COVERAGE_PACKAGE_ID" -r --json)
    local test_run_json=""
    local test_run_id=""
    local test_status=0
    local coverage_json=""
    local covered=""
    local uncovered=""
    local percentage=""
    local escaped_pattern="$(printf '%s' "$COVERAGE_CLASS_PATTERN" | sed -e 's/\\/\\\\/g' -e "s/'/\\\\&/g")"
    local query="SELECT SUM(NumLinesCovered) covered, SUM(NumLinesUncovered) uncovered FROM ApexCodeCoverageAggregate WHERE ApexClassOrTrigger.Name LIKE '$escaped_pattern'"

    section "Post-package coverage check for $TARGET_ORG"
    kv "Required coverage" "$COVERAGE_MINIMUM%" 18

    if [[ -n "$COVERAGE_PACKAGE_ID" && "$COVERAGE_SKIP_INSTALL" != "true" ]]; then
        if [[ -n "$PACKAGE_INSTALL_KEY" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                install_arguments+=(--installation-key "***")
            else
                install_arguments+=(--installation-key "$PACKAGE_INSTALL_KEY")
            fi
        fi
        run_cmd sf "${install_arguments[@]}" || error $? "Package installation failed before coverage check."
    elif [[ -z "$COVERAGE_PACKAGE_ID" && "$COVERAGE_SKIP_INSTALL" != "true" ]]; then
        skipped "Skipping package install: no coverage package ID was provided."
    fi

    if [[ "$COVERAGE_SKIP_DEPLOY" != "true" ]]; then
        run_cmd sf project deploy start \
            --target-org "$TARGET_ORG" \
            --source-dir force-app \
            --ignore-conflicts \
            --json \
            || error $? "Metadata deployment failed before coverage check."
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ "$COVERAGE_RUN_ALL" == "true" || -z "$COVERAGE_TEST_CLASS" ]]; then
            run_cmd sf apex run test --target-org "$TARGET_ORG" --code-coverage --wait 120 --json
        else
            run_cmd sf apex run test --target-org "$TARGET_ORG" --tests "$COVERAGE_TEST_CLASS" --code-coverage --synchronous --result-format human
        fi
        run_cmd sf data query --target-org "$TARGET_ORG" --use-tooling-api --query "$query" --result-format json
        ORG_ACTION="No org action. Coverage check dry-run."
        return 0
    fi

    if [[ "$COVERAGE_RUN_ALL" == "true" || -z "$COVERAGE_TEST_CLASS" ]]; then
        set +e
        sf apex run test --target-org "$TARGET_ORG" --code-coverage --wait 120 --json
        test_status=$?
        set -e
        if [[ "$test_status" -ne 0 ]]; then
            test_run_json="$(sf_json sf apex run test --target-org "$TARGET_ORG" --code-coverage)" \
                || error $? "Could not start asynchronous Apex tests."
            test_run_id="$(jq -r '.result.testRunId // empty' <<< "$test_run_json")"
            if [[ -z "$test_run_id" ]]; then
                error 1 "Could not parse testRunId from the asynchronous Apex test run."
            fi
            sf apex get test --target-org "$TARGET_ORG" --test-run-id "$test_run_id" --code-coverage --result-format human \
                || error $? "Could not retrieve asynchronous Apex test results."
        fi
    else
        sf apex run test \
            --target-org "$TARGET_ORG" \
            --tests "$COVERAGE_TEST_CLASS" \
            --code-coverage \
            --synchronous \
            --result-format human \
            || error $? "Apex test class $COVERAGE_TEST_CLASS failed."
    fi

    coverage_json="$(sf_json sf data query \
        --target-org "$TARGET_ORG" \
        --use-tooling-api \
        --query "$query" \
        --result-format json)" || error $? "Could not query aggregate Apex coverage."
    covered="$(jq -r '.result.records[0].covered // 0' <<< "$coverage_json")"
    uncovered="$(jq -r '.result.records[0].uncovered // 0' <<< "$coverage_json")"
    percentage="$(awk -v covered="$covered" -v uncovered="$uncovered" 'BEGIN { total = covered + uncovered; if (total > 0) printf "%.2f", covered / total * 100; else printf "0.00" }')"

    echo ""
    step "Apex coverage: $percentage% ($covered covered, $uncovered uncovered)"
    ORG_ACTION="Completed coverage check for $TARGET_ORG: $percentage%"
    if ! awk -v percentage="$percentage" -v minimum="$COVERAGE_MINIMUM" 'BEGIN { exit !(percentage >= minimum) }'; then
        error 1 "Coverage $percentage% is below the required $COVERAGE_MINIMUM%."
    fi
    success "Coverage is at or above $COVERAGE_MINIMUM%."
}

get_installed_packages_json() {
    sf package installed list \
    --target-org "$TARGET_ORG" \
        --json
}

load_installed_packages() {
    step "Reading installed packages from org: $TARGET_ORG"

    if [[ "$ORG_AVAILABLE_FOR_READ" != "true" ]]; then
        warning "Org was not actually created or fetched in this run. Assuming no installed packages for planning."
        INSTALLED_PACKAGES_JSON='{"result":[]}'
        return 0
    fi

    INSTALLED_PACKAGES_JSON="$(get_installed_packages_json)" \
        || error $? "Failed to read installed packages from org: $TARGET_ORG"
}

installed_package_json() {
    local package_name="$1"

    echo "$INSTALLED_PACKAGES_JSON" | jq -c --arg package_name "$package_name" '
        (.result // [])
        | map(
            select(
                (
                    .SubscriberPackageName
                    // .PackageName
                    // .Name
                    // .Package
                    // ""
                ) == $package_name
            )
        )
        | first // empty
    '
}

installed_package_version() {
    local installed_json="$1"

    echo "$installed_json" | jq -r '
        .SubscriberPackageVersionNumber
        // .VersionNumber
        // .Version
        // "unknown"
    '
}

installed_package_04t() {
    local installed_json="$1"

    echo "$installed_json" | jq -r '
        .SubscriberPackageVersionId
        // .SubscriberPackageVersionID
        // empty
    '
}

normalize_version() {
    local version="$1"

    version="${version%.LATEST}"
    version="${version%.NEXT}"
    version="$(echo "$version" | sed -E 's/[^0-9.].*$//')"

    IFS='.' read -r major minor patch build rest <<< "$version"

    major="${major:-0}"
    minor="${minor:-0}"
    patch="${patch:-0}"
    build="${build:-0}"

    echo "$major.$minor.$patch.$build"
}

compare_versions() {
    local left=""
    local right=""

    left="$(normalize_version "$1")"
    right="$(normalize_version "$2")"

    IFS='.' read -r left_major left_minor left_patch left_build <<< "$left"
    IFS='.' read -r right_major right_minor right_patch right_build <<< "$right"

    local left_parts=("$left_major" "$left_minor" "$left_patch" "$left_build")
    local right_parts=("$right_major" "$right_minor" "$right_patch" "$right_build")

    for i in 0 1 2 3; do
        if (( 10#${left_parts[$i]} < 10#${right_parts[$i]} )); then
            echo "-1"
            return 0
        fi

        if (( 10#${left_parts[$i]} > 10#${right_parts[$i]} )); then
            echo "1"
            return 0
        fi
    done

    echo "0"
}

install_resolved_package() {
    local package_name="$1"
    local max_attempts="$PACKAGE_INSTALL_MAX_ATTEMPTS"
    local retry_delay_seconds="$PACKAGE_INSTALL_RETRY_DELAY_SECONDS"
    local attempt=""
    local output=""
    local status=0
    local label=""

    local install_args=(
        package install
        -r
        -w "$PACKAGE_WAIT_MINUTES"
        -p "$RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID"
        --target-org "$TARGET_ORG"
    )

    if package_requires_key "$package_name"; then
        if [[ "$DRY_RUN" == "true" ]]; then
            install_args+=(-k "***")
        else
            install_args+=(-k "$PACKAGE_INSTALL_KEY")
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        run_cmd sf "${install_args[@]}" \
            || error $? "Failed to install package $package_name with ID $RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID"
        return 0
    fi

    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        status=0
        label="Installing $package_name $RESOLVED_SELECTED_VERSION"
        if (( attempt > 1 )); then
            label+=" (attempt $attempt/$max_attempts)"
        fi

        run_with_progress "$label" sf "${install_args[@]}" || status=$?
        output="$PROGRESS_OUTPUT"

        if [[ "$status" -eq 0 ]]; then
            if [[ "$VERBOSE" == "true" && -n "$output" ]]; then
                indent_output "$output"
            fi
            success "Installed $package_name $RESOLVED_SELECTED_VERSION ${DIM}in $PROGRESS_DURATION${RESET}"
            return 0
        fi

        failure "Install of $package_name failed after $PROGRESS_DURATION (attempt $attempt/$max_attempts). Salesforce CLI output:"
        if [[ -n "$output" ]]; then
            indent_output "$output"
        fi

        if (( attempt < max_attempts )) && is_retryable_package_install_failure "$output"; then
            warning "Transient Salesforce CLI/network error while installing $package_name (attempt $attempt/$max_attempts). Retrying in ${retry_delay_seconds}s..."
            sleep "$retry_delay_seconds"
            continue
        fi

        error "$status" "Failed to install package $package_name with ID $RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID"
    done
}

delete_existing_scratch_org() {
    echo ""
    step "Deleting existing scratch org, if it exists: $ORG_ALIAS"

    if [[ "$DRY_RUN" == "true" ]]; then
        run_cmd sf org delete scratch \
            --no-prompt \
            --target-org "$ORG_ALIAS"

        ORG_ACTION="Dry-run: would delete scratch org if it existed: $ORG_ALIAS"
        add_action "Dry-run: would delete scratch org if it existed: $ORG_ALIAS"
    else
        sf org delete scratch \
            --no-prompt \
            --target-org "$ORG_ALIAS" \
            > /dev/null 2>&1 || true

        ORG_ACTION="Attempted to delete scratch org: $ORG_ALIAS"
        add_action "Deleted scratch org if it existed: $ORG_ALIAS"
        success "Old scratch org removed (if it existed)."
    fi
}

read_dependency_package_names() {
    jq -r '[.packageDirectories[]? | .dependencies // [] | .[] | .package // empty | select(length > 0)] | unique[]' "$PROJECT_FILE" 2>/dev/null || true
}

project_root_dir() {
    dirname "$PROJECT_FILE"
}

dependency_package_directory() {
    local package_name="$1"
    local package_path=""

    package_path="$(jq -r --arg package_name "$package_name" '
        first(
            .packageDirectories[]?
            | select(.package == $package_name or ((.path // "") | split("/") | map(select(. != "" and . != ".")) | last) == $package_name)
            | .path
        ) // empty
    ' "$PROJECT_FILE")"

    [[ -z "$package_path" ]] && return 0

    if [[ "$package_path" == /* ]]; then
        echo "$package_path"
    elif [[ "$(project_root_dir)" == "." ]]; then
        echo "$package_path"
    else
        echo "$(project_root_dir)/$package_path"
    fi
}

is_preserved_root_file() {
    local entry_name="$1"
    local preserved=""

    IFS=',' read -ra preserved_entries <<< "$PRESERVE_ROOT_FILES"
    for preserved in "${preserved_entries[@]}"; do
        preserved="${preserved// /}"
        [[ -n "$preserved" && "$entry_name" == "$preserved" ]] && return 0
    done

    return 1
}

clear_dependency_package_directories() {
    local package_names=()
    local package_name=""
    local package_dir=""
    local project_root=""
    local resolved_dir=""
    local child=""

    while IFS= read -r package_name; do
        [[ -z "$package_name" ]] && continue
        package_names+=("$package_name")
    done < <(read_dependency_package_names)

    if [[ ${#package_names[@]} -eq 0 ]]; then
        echo ""
        skipped "No dependency package directories to clear."
        return 0
    fi

    project_root="$(cd "$(project_root_dir)" && pwd -P)"

    section "Clearing dependency package directories"
    info "Keeping: ${PRESERVE_ROOT_FILES:-nothing}"

    for package_name in "${package_names[@]}"; do
        package_dir="$(dependency_package_directory "$package_name")"

        if [[ -z "$package_dir" ]]; then
            if [[ "$REQUIRE_LOCAL_DIRECTORIES" == "true" ]]; then
                error 2 "Dependency package directory is not declared: $package_name. Declare it in $PROJECT_FILE or set dependencySourcePolicy.requireLocalDirectories to false."
            fi
            warning "No package directory is declared for dependency $package_name in $PROJECT_FILE. Skipping."
            continue
        fi

        if [[ ! -d "$package_dir" ]]; then
            skipped "Skipping missing directory: $package_dir"
            continue
        fi

        resolved_dir="$(cd "$package_dir" && pwd -P)"
        if [[ "$resolved_dir" == "$project_root" || "$resolved_dir" != "$project_root/"* ]]; then
            error 1 "Refusing to clear $package_dir for $package_name: it must be a subdirectory of the project root $project_root."
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            info "Dry-run: would clear contents of $package_dir except ${PRESERVE_ROOT_FILES:-nothing}"
            continue
        fi

        while IFS= read -r -d '' child; do
            is_preserved_root_file "$(basename "$child")" && continue
            rm -rf -- "$child"
        done < <(find "$resolved_dir" -mindepth 1 -maxdepth 1 -print0)

        success "Cleared contents of $package_dir except ${PRESERVE_ROOT_FILES:-nothing}"
    done

    add_action "Cleared dependency package directories"
}

temporarily_disable_forceignore() {
    local forceignore_path=".forceignore"
    local backup_path=".forceignore.disabled"

    if [[ ! -f "$forceignore_path" ]]; then
        info "No .forceignore file present; nothing to disable."
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        info "Dry-run: would temporarily disable $forceignore_path"
        return 0
    fi

    if [[ -f "$backup_path" ]]; then
        rm -f "$backup_path"
    fi

    mv "$forceignore_path" "$backup_path"
    info "Temporarily disabled $forceignore_path"
}

restore_forceignore() {
    local forceignore_path=".forceignore"
    local backup_path=".forceignore.disabled"

    if [[ ! -f "$backup_path" ]]; then
        if [[ -f "$forceignore_path" ]]; then
            info ".forceignore already active; nothing to restore."
        fi
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        info "Dry-run: would restore $backup_path to $forceignore_path"
        return 0
    fi

    mv "$backup_path" "$forceignore_path"
    info "Restored $forceignore_path"
}

retrieve_dependency_packages() {
    local package_names=()
    local package_name=""

    while IFS= read -r package_name; do
        [[ -z "$package_name" ]] && continue
        package_names+=("$package_name")
    done < <(read_dependency_package_names)

    if [[ ${#package_names[@]} -eq 0 ]]; then
        echo ""
        skipped "No dependency packages available for retrieve."
        return 0
    fi

    step "Retrieving dependency package metadata after setup..."

    temporarily_disable_forceignore

    local index=0
    for package_name in "${package_names[@]}"; do
        index=$((index + 1))
        item "$(counter "$index" "${#package_names[@]}") $package_name"

        if [[ "$DRY_RUN" == "true" ]]; then
            info "Dry-run: would run sf project retrieve start --target-org $TARGET_ORG -n $package_name"
            continue
        fi

        if ! sf project retrieve start \
            --target-org "$TARGET_ORG" \
            -n "$package_name"; then
            restore_forceignore
            error 1 "Failed to retrieve package $package_name from org: $TARGET_ORG"
        fi

        success "Retrieved package: $package_name"
    done

    restore_forceignore
    add_action "Retrieved dependency packages into source with temporary .forceignore disable"
}

create_scratch_org() {
    echo ""
    step "Creating scratch org: $ORG_ALIAS"

    run_cmd sf org create scratch \
        --set-default \
        --definition-file "$SCRATCH_DEF_FILE" \
        --duration-days "$DURATION_DAYS" \
        --alias "$ORG_ALIAS" \
        || error $? '"sf org create scratch" command failed.'

    if [[ "$DRY_RUN" == "true" ]]; then
        ORG_AVAILABLE_FOR_READ=false
        ORG_ACTION="Dry-run: would create scratch org: $ORG_ALIAS"
        add_action "Dry-run: would create scratch org $ORG_ALIAS with duration $DURATION_DAYS days"
    else
        ORG_AVAILABLE_FOR_READ=true
        ORG_ACTION="Created scratch org: $ORG_ALIAS"
        add_action "Created scratch org $ORG_ALIAS with duration $DURATION_DAYS days"
    fi
}

setup_org() {
    if [[ "$RUN_ORG_CREATE" != "true" ]]; then
        return 0
    fi

    phase "Scratch org"

    if [[ "$REFRESH_DEPENDENCY_SOURCES" == "true" ]]; then
        clear_dependency_package_directories
    fi

    if [[ "$USE_POOL" == "true" ]]; then
        if try_fetch_scratch_org_from_pool; then
            echo ""
            success "Using scratch org fetched from pool."
            return 0
        fi
    fi

    delete_existing_scratch_org
    create_scratch_org
}

print_package_header() {
    local index="$1"
    local total="$2"
    local package_name="$3"
    local requested_version="$4"

    item "$(counter "$index" "$total") ${BOLD}$package_name${RESET}"
    kv "Defined version" "$requested_version" 18
    kv "Target version" "$RESOLVED_SELECTED_VERSION" 18
    kv "Target 04t" "$RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID" 18
}

print_package_mode() {
    local verb="$1"
    if [[ "$INSTALL_LATEST_PACKAGES" == "true" ]]; then
        info "$verb mode: latest released package versions"
    else
        info "$verb mode: versions defined in $PROJECT_FILE"
    fi
}

install_packages() {
    local count=""
    local index=0
    count="$(dependency_count)"

    if [[ "$count" -eq 0 ]]; then
        skipped "No package dependencies declared in $PROJECT_FILE. Nothing to install."
        return 0
    fi

    step "Installing $count package dependencies from $PROJECT_FILE"
    print_package_mode "Install"

    load_installed_packages

    while IFS=$'\t' read -r package_name requested_version; do
        [[ -z "$package_name" ]] && continue
        index=$((index + 1))

        resolve_package_version "$package_name" "$requested_version"

        local installed_json=""
        local installed_04t=""

        installed_json="$(installed_package_json "$package_name")"

        print_package_header "$index" "$count" "$package_name" "$requested_version"
        warn_if_dependency_is_not_latest "$package_name" "$requested_version"

        if [[ -n "$installed_json" && "$installed_json" != "null" ]]; then
            installed_04t="$(installed_package_04t "$installed_json")"
            kv "Installed 04t" "${installed_04t:-unknown}" 18

            if [[ "$installed_04t" == "$RESOLVED_SUBSCRIBER_PACKAGE_VERSION_ID" ]]; then
                skipped "Package is already on target 04t. Skipping."
                add_package_skipped "$package_name $RESOLVED_SELECTED_VERSION"
                continue
            fi
        else
            kv "Installed 04t" "not installed" 18
        fi

        install_resolved_package "$package_name"
        add_package_installed "$package_name $RESOLVED_SELECTED_VERSION"

    done < <(read_dependencies)
}

update_packages() {
    local count=""
    local index=0
    count="$(dependency_count)"

    if [[ "$count" -eq 0 ]]; then
        skipped "No package dependencies declared in $PROJECT_FILE. Nothing to update."
        return 0
    fi

    step "Checking and updating $count package dependencies from $PROJECT_FILE"
    print_package_mode "Update"

    load_installed_packages

    while IFS=$'\t' read -r package_name requested_version; do
        [[ -z "$package_name" ]] && continue
        index=$((index + 1))

        resolve_package_version "$package_name" "$requested_version"

        local installed_json=""
        local installed_version=""
        local installed_04t=""
        local comparison=""

        installed_json="$(installed_package_json "$package_name")"

        print_package_header "$index" "$count" "$package_name" "$requested_version"
        warn_if_dependency_is_not_latest "$package_name" "$requested_version"

        if [[ -z "$installed_json" || "$installed_json" == "null" ]]; then
            kv "Installed version" "not installed" 18
            add_package_missing "$package_name target=$RESOLVED_SELECTED_VERSION"
            install_resolved_package "$package_name"
            add_package_installed "$package_name $RESOLVED_SELECTED_VERSION"
            continue
        fi

        installed_version="$(installed_package_version "$installed_json")"
        installed_04t="$(installed_package_04t "$installed_json")"

        kv "Installed version" "$installed_version" 18
        kv "Installed 04t" "${installed_04t:-unknown}" 18

        comparison="$(compare_versions "$installed_version" "$RESOLVED_SELECTED_VERSION")"

        if [[ "$comparison" == "-1" ]]; then
            echo "${BLUE}${ICON_UPDATE}${RESET} Installed version is lower than target version. Installing update."
            install_resolved_package "$package_name"
            add_package_updated "$package_name $installed_version -> $RESOLVED_SELECTED_VERSION"
        elif [[ "$comparison" == "0" ]]; then
            skipped "Package is already on target version. Skipping."
            add_package_skipped "$package_name $installed_version"
        else
            warning "$package_name has a higher version installed than the target version. Installed: $installed_version. Target: $RESOLVED_SELECTED_VERSION. Skipping downgrade."
            add_package_higher_than_target "$package_name installed=$installed_version target=$RESOLVED_SELECTED_VERSION"
        fi

    done < <(read_dependencies)
}

deploy_metadata() {
    if [[ "$FULL_DEPLOY" == "true" ]]; then
        step "Deleting local source tracking so all local source is deployed..."
        run_cmd sf project delete tracking \
            --target-org "$TARGET_ORG" \
            --no-prompt \
            || error $? '"sf project delete tracking" command failed.'
        add_action "Deleted local source tracking for $TARGET_ORG (full deploy)"
    fi

    step "Deploying metadata..."

    run_cmd sf project deploy start \
        --target-org "$TARGET_ORG" \
        --source-dir force-app \
        --ignore-conflicts \
        || error $? '"sf project deploy start" command failed.'

    add_action "Deployed metadata to $TARGET_ORG"

    if [[ "$FULL_DEPLOY" != "true" ]]; then
        info "Only changes tracked since the last reset are deployed. If metadata is missing in the org, run: $(basename "$0") --redeploy"
    fi
}

reset_source_tracking() {
    step "Resetting source tracking..."

    run_cmd sf project reset tracking \
        --target-org "$TARGET_ORG" \
        --no-prompt \
        --json \
        || error $? '"sf project reset tracking" command failed.'

    add_action "Reset source tracking baseline for $TARGET_ORG"
}

assign_permission_sets() {
    local permission_set=""
    local -a name_flags=()

    step "Assigning permission sets..."

    for permission_set in ${PERMISSION_SETS//,/ }; do
        name_flags+=(--name "$permission_set")
    done

    run_cmd sf org assign permset \
        --target-org "$TARGET_ORG" \
        "${name_flags[@]}" \
        || error $? '"sf org assign permset" command failed.'

    add_action "Assigned permission sets in $TARGET_ORG"
}

import_dummy_data() {
    step "Importing dummy data..."

    run_cmd sf data import tree \
        --target-org "$TARGET_ORG" \
        --plan "$DUMMY_DATA_PLAN" \
        || error $? '"sf data import tree" command failed.'

    add_action "Imported dummy data using $DUMMY_DATA_PLAN"

    import_dummy_users
    assign_dummy_user_permission_sets
}

import_dummy_users() {
    step "Importing dummy users..."

    if [[ -z "$DUMMY_USER_FILE" ]]; then
        skipped "No dummy user file configured (dummyUsers.file / DUMMY_USER_FILE). Skipping dummy user import."
        return 0
    fi

    if [[ ! -f "$DUMMY_USER_FILE" ]]; then
        skipped "No dummy user file found at $DUMMY_USER_FILE. Skipping dummy user import."
        return 0
    fi

    require_command jq

    if [[ "$DRY_RUN" == "true" ]]; then
        local profile_names
        profile_names="$(jq -r --arg default "$DUMMY_USER_PROFILE_NAME" --argjson assignments "$DUMMY_PROFILE_ASSIGNMENTS_JSON" '[ $default, $assignments[]?.profileName ] | unique | join(", ")' "$DUMMY_USER_FILE")"
        echo "  ${YELLOW}[dry-run] Would resolve profile(s) ${profile_names} and import missing users from $DUMMY_USER_FILE${RESET}"
        return 0
    fi

    local profile_names_json
    local profile_ids_json='{}'
    local profile_name_literal
    local profile_id
    local profile_name
    profile_names_json="$(jq -c --arg default "$DUMMY_USER_PROFILE_NAME" --argjson assignments "$DUMMY_PROFILE_ASSIGNMENTS_JSON" '
        [
            .records[]?
            | (if (.Username | type) == "string" then .Username else "" end) as $username
            | ([$assignments[]? | select(.usernames | index($username)) | .profileName][0] // $default)
        ]
        | unique
    ' "$DUMMY_USER_FILE")"

    while IFS= read -r profile_name; do
        [[ -z "$profile_name" ]] && continue
        profile_name_literal="$(jq -rn --arg value "$profile_name" "$SOQL_STRING_JQ"' $value | soql_string')"
        profile_id="$(sf_json sf data query \
            --target-org "$TARGET_ORG" \
            --query "SELECT Id FROM Profile WHERE Name = ${profile_name_literal} LIMIT 1" \
            | jq -r '.result.records[0].Id // empty')"

        if [[ -z "$profile_id" ]]; then
            warning "Could not resolve profile '${profile_name}' in $TARGET_ORG. Users assigned to it will be skipped."
            continue
        fi

        profile_ids_json="$(jq -c --arg name "$profile_name" --arg id "$profile_id" '. + {($name): $id}' <<< "$profile_ids_json")"
    done < <(jq -r '.[]' <<< "$profile_names_json")

    local username_in_clause
    username_in_clause="$(jq -r "$SOQL_STRING_JQ"' [.records[].Username | strings] | map(soql_string) | join(",")' "$DUMMY_USER_FILE")"

    if [[ -z "$username_in_clause" ]]; then
        skipped "No usernames found in $DUMMY_USER_FILE. Skipping dummy user import."
        return 0
    fi

    local existing_usernames_json
    existing_usernames_json="$(sf_json sf data query \
        --target-org "$TARGET_ORG" \
        --query "SELECT Username FROM User WHERE Username IN (${username_in_clause})" \
        | jq -c '[.result.records[].Username]')"

    local tmp_user_file
    tmp_user_file="$(mktemp)"

    jq --arg default_profile "$DUMMY_USER_PROFILE_NAME" \
        --argjson profile_assignments "$DUMMY_PROFILE_ASSIGNMENTS_JSON" \
        --argjson profile_ids "$profile_ids_json" \
        --argjson existing "$existing_usernames_json" '
        def profile_name_for($username):
            [$profile_assignments[]? | select(.usernames | index($username)) | .profileName][0]
            // $default_profile;

        .records |= map(
            select((.Username as $u | $existing | index($u)) | not)
            | (profile_name_for(.Username // "")) as $profile_name
            | select($profile_ids[$profile_name] != null)
            | .ProfileId = $profile_ids[$profile_name]
        )
    ' "$DUMMY_USER_FILE" > "$tmp_user_file"

    local remaining
    remaining="$(jq '.records | length' "$tmp_user_file")"

    if [[ "$remaining" -eq 0 ]]; then
        skipped "All dummy users already exist in $TARGET_ORG. Skipping creation."
        rm -f "$tmp_user_file"
        return 0
    fi

    info "Creating $remaining dummy user(s) with configured profile(s)."

    if ! sf data import tree --target-org "$TARGET_ORG" --files "$tmp_user_file"; then
        rm -f "$tmp_user_file"
        error $? '"sf data import tree" command failed for dummy users.'
    fi

    rm -f "$tmp_user_file"
    success "Imported $remaining dummy user(s)."
    add_action "Imported $remaining dummy user(s) into $TARGET_ORG"
}

assign_permset_to_users() {
    local permset_list="$1"
    local username_list="$2"
    local name
    local username
    local -a name_flags=()
    local -a behalf_flags=()

    for name in $permset_list; do
        name_flags+=(--name "$name")
    done
    for username in $username_list; do
        behalf_flags+=(--on-behalf-of "$username")
    done

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  ${YELLOW}[dry-run] Would run:${RESET} ${DIM}$(format_command sf org assign permset --target-org "$TARGET_ORG" "${name_flags[@]}" "${behalf_flags[@]}")${RESET}"
        return 0
    fi

    local output
    local exit_code=0
    output="$(sf org assign permset --target-org "$TARGET_ORG" "${name_flags[@]}" "${behalf_flags[@]}" --json 2>&1 | sed -n '/^{/,$p')" || exit_code=$?

    if [[ "$exit_code" -eq 0 ]]; then
        success "Assigned [$permset_list] to: $username_list"
        add_action "Assigned permission set(s) [$permset_list] to: $username_list"
        return 0
    fi

    local non_duplicate_failures
    non_duplicate_failures="$(echo "$output" | jq -r '[.result.failures[]?.message // empty] | map(select(contains("Duplicate PermissionSetAssignment") | not)) | length' 2>/dev/null || echo "1")"

    if [[ "$non_duplicate_failures" == "0" ]]; then
        skipped "Permission set(s) [$permset_list] already assigned to some/all of: $username_list. Skipping."
        return 0
    fi

    indent_output "$output"
    error "$exit_code" '"sf org assign permset" command failed for dummy users.'
}

assign_dummy_user_permission_sets() {
    local permission_sets=""
    local usernames=""

    step "Assigning permission sets to dummy users..."

    if [[ -z "$DUMMY_USER_FILE" || ! -f "$DUMMY_USER_FILE" ]]; then
        skipped "No dummy user file found. Skipping dummy user permission set assignment."
        return 0
    fi

    if [[ -z "$DUMMY_USER_ASSIGNMENTS" ]]; then
        skipped "No dummy user permission set assignments configured (dummyUsers.permissionSetAssignments). Skipping."
        return 0
    fi

    require_command jq

    while IFS='|' read -r permission_sets usernames; do
        [[ -z "$permission_sets" || -z "$usernames" ]] && continue
        assign_permset_to_users "$permission_sets" "$usernames"
    done <<< "$DUMMY_USER_ASSIGNMENTS"
}

publish_community() {
    step "Publishing community: $COMMUNITY_NAME"

    run_cmd sf community publish \
        --target-org "$TARGET_ORG" \
        --name "$COMMUNITY_NAME" \
        || error $? "\"sf community publish\" command failed for community: \"$COMMUNITY_NAME\"."

    add_action "Published community $COMMUNITY_NAME"
}

run_custom_post_step() {
    local step_name="$1"
    local executable=""
    local argument=""
    local -a step_arguments=()

    executable="$(jq -r --arg name "$step_name" 'first(.customPostSteps[]? | select(.name == $name) | .executable) // empty' "$CONFIG_FILE")"
    while IFS= read -r -d '' argument; do
        step_arguments+=("$argument")
    done < <(jq -j --arg name "$step_name" 'first(.customPostSteps[]? | select(.name == $name)) | (.arguments // [])[] | . + "\u0000"' "$CONFIG_FILE")

    step "Running custom post step: $step_name"

    run_cmd run_in_project_root "$executable" "${step_arguments[@]}" \
        || error $? "Custom post step \"$step_name\" failed."

    add_action "Ran custom post step $step_name"
}

run_post_step() {
    local step="$1"
    local missing_setting=""

    case "$step" in
        permsets) [[ -z "$PERMISSION_SETS" ]] && missing_setting="No permission sets configured (permissionSets / PERMISSION_SETS / --permission-sets)." ;;
        data) [[ -z "$DUMMY_DATA_PLAN" ]] && missing_setting="No dummy data plan configured (dummyDataPlan / DUMMY_DATA_PLAN / --dummy-data-plan)." ;;
        community) [[ -z "$COMMUNITY_NAME" ]] && missing_setting="No community name configured (communityName / COMMUNITY_NAME / --community-name)." ;;
    esac

    if [[ -n "$missing_setting" ]]; then
        warning "$missing_setting Skipping post step: $step"
        add_post_step_skipped "$step"
        return 0
    fi

    case "$step" in
        deploy) deploy_metadata ;;
        permsets) assign_permission_sets ;;
        data) import_dummy_data ;;
        community) publish_community ;;
        *) run_custom_post_step "$step" ;;
    esac

    add_post_step_run "$step"
}

run_self_check() {
    local failures=0
    local requested_needs_project_file=false
    local requested_requires_org_access=false
    local requested_data_step=false
    local install_key_required=false
    local package_count=0
    local summary_rows=""
    local checks_total=0
    local checks_passed=0
    local checks_failed=0
    local checks_skipped=0
    local command_failures=0
    local file_failures=0
    local package_resolution_failed=0
    local package_resolution_passed=0
    local key_check_status="SKIP"
    local key_check_detail="No package in dependency set requires install key."

    local requested_run_org_create="$REQUESTED_RUN_ORG_CREATE"
    local requested_run_packages="$REQUESTED_RUN_PACKAGES"
    local requested_post_steps="$REQUESTED_POST_STEPS"
    local requested_use_pool="$REQUESTED_USE_POOL"
    local requested_update_packages_only="$REQUESTED_UPDATE_PACKAGES_ONLY"
    local requested_package_plan_only="$REQUESTED_PACKAGE_PLAN_ONLY"
    local requested_install_latest_packages="$REQUESTED_INSTALL_LATEST_PACKAGES"

    add_summary_row() {
        local status="$1"
        local name="$2"
        local detail="$3"

        checks_total=$((checks_total + 1))

        case "$status" in
            PASS) checks_passed=$((checks_passed + 1)) ;;
            FAIL) checks_failed=$((checks_failed + 1)) ;;
            SKIP) checks_skipped=$((checks_skipped + 1)) ;;
        esac

        summary_rows+="$status|$name|$detail"$'\n'
    }

    print_self_check_summary() {
        local status_colour=""
        local status_icon=""

        section "Self-check summary"
        printf '  %s%s %-8s%s %s%s %-8s%s %s%s %-8s%s %s\n' \
            "$GREEN" "$ICON_OK" "$checks_passed passed" "$RESET" \
            "$RED" "$ICON_FAIL" "$checks_failed failed" "$RESET" \
            "$DIM" "$ICON_SKIP" "$checks_skipped skipped" "$RESET" \
            "${DIM}($checks_total total)${RESET}"
        echo ""
        printf "  %-8s | %-30s | %s\n" "Status" "Check" "Details"
        printf "  %-8s-+-%-30s-+-%s\n" "--------" "------------------------------" "------------------------------"

        while IFS='|' read -r status name detail; do
            [[ -z "$status" ]] && continue
            case "$status" in
                PASS) status_colour="$GREEN" status_icon="$ICON_OK" ;;
                FAIL) status_colour="$RED" status_icon="$ICON_FAIL" ;;
                *) status_colour="$DIM" status_icon="$ICON_SKIP" ;;
            esac
            printf "  %s%s %-6s%s | %-30s | %s\n" "$status_colour" "$status_icon" "$status" "$RESET" "$name" "$detail"
        done <<< "$summary_rows"
    }

    banner "Self-check"
    kv "Bash version" "${BASH_VERSION:-unknown}"
    kv "Script file" "$0"
    kv "Working directory" "$(pwd)"
    kv "Org alias" "$ORG_ALIAS"
    kv "Project file" "$PROJECT_FILE"
    kv "Scratch definition file" "$SCRATCH_DEF_FILE"
    kv "Post steps" "$POST_STEPS"
    kv "Post steps only mode" "$POST_STEPS_ONLY_MODE"
    kv "Use pool" "$USE_POOL"
    kv "Install latest packages" "$INSTALL_LATEST_PACKAGES"

    section "Requested mode (before self-check safety overrides)"
    kv "Run org create/fetch" "$requested_run_org_create"
    kv "Run packages" "$requested_run_packages"
    kv "Update packages only" "$requested_update_packages_only"
    kv "Package plan only" "$requested_package_plan_only"
    kv "Use pool" "$requested_use_pool"
    kv "Post steps" "$requested_post_steps"
    kv "Install latest packages" "$requested_install_latest_packages"

    section "Required commands"
    if command -v sf >/dev/null 2>&1; then
        echo "${GREEN}OK:${RESET} sf"
    else
        echo "${RED}FAIL:${RESET} sf command not found"
        failures=$((failures + 1))
        command_failures=$((command_failures + 1))
    fi

    if command -v jq >/dev/null 2>&1; then
        echo "${GREEN}OK:${RESET} jq"
    else
        echo "${RED}FAIL:${RESET} jq command not found"
        failures=$((failures + 1))
        command_failures=$((command_failures + 1))
    fi

    if command -v sed >/dev/null 2>&1; then
        echo "${GREEN}OK:${RESET} sed"
    else
        echo "${RED}FAIL:${RESET} sed command not found"
        failures=$((failures + 1))
        command_failures=$((command_failures + 1))
    fi

    if [[ "$requested_use_pool" == "true" && "$requested_run_org_create" == "true" ]]; then
        if command -v sfp >/dev/null 2>&1; then
            echo "${GREEN}OK:${RESET} sfp"
        else
            echo "${RED}FAIL:${RESET} sfp command not found (required for pool mode)"
            failures=$((failures + 1))
            command_failures=$((command_failures + 1))
        fi
    fi

    if [[ "$command_failures" -eq 0 ]]; then
        add_summary_row "PASS" "Required commands" "All required commands are available."
    else
        add_summary_row "FAIL" "Required commands" "$command_failures required command check(s) failed."
    fi

    section "Salesforce CLI access"
    if sf org list --json >/dev/null 2>&1; then
        echo "${GREEN}OK:${RESET} sf org list --json"
        add_summary_row "PASS" "Salesforce CLI session" "sf org list --json succeeded."
    else
        echo "${RED}FAIL:${RESET} Could not run sf org list --json. Ensure CLI auth/session is valid."
        failures=$((failures + 1))
        add_summary_row "FAIL" "Salesforce CLI session" "sf org list --json failed."
    fi

    if [[ "$requested_use_pool" == "true" && "$requested_run_org_create" == "true" ]]; then
        section "Pool access (read-only)"

        local resolved_devhub_for_check=""
        if resolved_devhub_for_check="$(resolve_pool_devhub_username_for_check)"; then
            echo "${GREEN}OK:${RESET} resolved DevHub for pool: $resolved_devhub_for_check"
            if sfp pool list --tag "$POOL_TAG" -a --targetdevhubusername "$resolved_devhub_for_check" >/dev/null 2>&1; then
                echo "${GREEN}OK:${RESET} sfp pool list --tag $POOL_TAG"
                add_summary_row "PASS" "Pool access" "sfp pool list worked for tag $POOL_TAG."
            else
                echo "${RED}FAIL:${RESET} Could not list sfp pool for tag $POOL_TAG"
                failures=$((failures + 1))
                add_summary_row "FAIL" "Pool access" "sfp pool list failed for tag $POOL_TAG."
            fi
        else
            echo "${RED}FAIL:${RESET} Could not resolve DevHub for pool mode. Set --pool-devhub or sf target-dev-hub config."
            failures=$((failures + 1))
            add_summary_row "FAIL" "Pool access" "Could not resolve pool DevHub."
        fi
    else
        add_summary_row "SKIP" "Pool access" "Pool mode not requested."
    fi

    if [[ "$requested_run_packages" == "true" || "$requested_update_packages_only" == "true" || "$requested_package_plan_only" == "true" ]]; then
        requested_needs_project_file=true
    fi

    section "Files"
    if [[ "$requested_needs_project_file" == "true" ]]; then
        if [[ -f "$PROJECT_FILE" ]]; then
            echo "${GREEN}OK:${RESET} $PROJECT_FILE exists"
            if jq empty "$PROJECT_FILE" >/dev/null 2>&1; then
                echo "${GREEN}OK:${RESET} $PROJECT_FILE is valid JSON"
            else
                echo "${RED}FAIL:${RESET} $PROJECT_FILE is not valid JSON"
                failures=$((failures + 1))
                file_failures=$((file_failures + 1))
            fi
        else
            echo "${RED}FAIL:${RESET} Project file not found: $PROJECT_FILE"
            failures=$((failures + 1))
            file_failures=$((file_failures + 1))
        fi
    else
        skipped "Project file check skipped (no package operations requested)."
    fi

    if [[ "$requested_run_org_create" == "true" && ( "$requested_use_pool" != "true" || "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" == "true" ) ]]; then
        if [[ -f "$SCRATCH_DEF_FILE" ]]; then
            echo "${GREEN}OK:${RESET} $SCRATCH_DEF_FILE exists"
            if jq empty "$SCRATCH_DEF_FILE" >/dev/null 2>&1; then
                echo "${GREEN}OK:${RESET} $SCRATCH_DEF_FILE is valid JSON"
            else
                echo "${RED}FAIL:${RESET} $SCRATCH_DEF_FILE is not valid JSON"
                failures=$((failures + 1))
                file_failures=$((file_failures + 1))
            fi
        else
            echo "${RED}FAIL:${RESET} Scratch definition file not found: $SCRATCH_DEF_FILE"
            failures=$((failures + 1))
            file_failures=$((file_failures + 1))
        fi
    fi

    if [[ "$requested_post_steps" == "all" || ",$requested_post_steps," == *,data,* ]]; then
        requested_data_step=true
    fi

    if [[ "$requested_data_step" == "true" && -z "$DUMMY_DATA_PLAN" ]]; then
        skipped "Dummy data plan check skipped (no dummy data plan configured)."
    elif [[ "$requested_data_step" == "true" ]]; then
        if [[ -f "$DUMMY_DATA_PLAN" ]]; then
            echo "${GREEN}OK:${RESET} $DUMMY_DATA_PLAN exists"
            if jq empty "$DUMMY_DATA_PLAN" >/dev/null 2>&1; then
                echo "${GREEN}OK:${RESET} $DUMMY_DATA_PLAN is valid JSON"
            else
                echo "${RED}FAIL:${RESET} $DUMMY_DATA_PLAN is not valid JSON"
                failures=$((failures + 1))
                file_failures=$((file_failures + 1))
            fi
        else
            echo "${RED}FAIL:${RESET} Dummy data plan not found: $DUMMY_DATA_PLAN"
            failures=$((failures + 1))
            file_failures=$((file_failures + 1))
        fi
    fi

    if [[ "$file_failures" -eq 0 ]]; then
        add_summary_row "PASS" "Files and JSON" "All required files exist and parse as JSON."
    else
        add_summary_row "FAIL" "Files and JSON" "$file_failures file/JSON check(s) failed."
    fi

    if [[ "$requested_update_packages_only" == "true" || "$requested_package_plan_only" == "true" ]]; then
        requested_requires_org_access=true
    fi

    if [[ "$requested_run_org_create" != "true" && ( "$requested_run_packages" == "true" || "$requested_post_steps" != "none" ) ]]; then
        requested_requires_org_access=true
    fi

    if [[ "$requested_requires_org_access" == "true" ]]; then
        section "Target org access (read-only)"
        if sf org display --target-org "$TARGET_ORG" --json >/dev/null 2>&1; then
            echo "${GREEN}OK:${RESET} sf org display --target-org $TARGET_ORG"
            add_summary_row "PASS" "Target org access" "Target org $TARGET_ORG is readable."
        else
            echo "${RED}FAIL:${RESET} Could not read target org: $TARGET_ORG"
            failures=$((failures + 1))
            add_summary_row "FAIL" "Target org access" "Could not read target org $TARGET_ORG."
        fi
    else
        add_summary_row "SKIP" "Target org access" "No read-only org access required for requested mode."
    fi

    if [[ "$requested_needs_project_file" == "true" && -f "$PROJECT_FILE" ]]; then
        section "Package dependencies and version resolution"
        package_count="$(dependency_count 2>/dev/null || echo 0)"
        kv "Dependencies found" "$package_count"

        if [[ "$package_count" -eq 0 ]]; then
            skipped "No package dependencies declared in $PROJECT_FILE."
            add_summary_row "SKIP" "Package resolution" "No package dependencies declared."
        else
            while IFS=$'\t' read -r package_name requested_version; do
                [[ -z "$package_name" ]] && continue

                if package_requires_key "$package_name"; then
                    install_key_required=true
                fi

                local versions_json=""
                local selected_json=""
                local latest_json=""

                if ! versions_json="$(get_package_versions_json "$package_name" 2>/dev/null)"; then
                    echo "${RED}FAIL:${RESET} Could not list released versions for package: $package_name"
                    failures=$((failures + 1))
                    package_resolution_failed=$((package_resolution_failed + 1))
                    continue
                fi

                latest_json="$(latest_version_json "$versions_json" 2>/dev/null || true)"
                if [[ -z "$latest_json" || "$latest_json" == "null" ]]; then
                    echo "${RED}FAIL:${RESET} Could not resolve latest released version for package: $package_name"
                    failures=$((failures + 1))
                    package_resolution_failed=$((package_resolution_failed + 1))
                    continue
                fi

                if [[ "$requested_install_latest_packages" == "true" ]]; then
                    selected_json="$latest_json"
                else
                    selected_json="$(requested_version_json "$versions_json" "$requested_version" 2>/dev/null || true)"
                fi

                if [[ -z "$selected_json" || "$selected_json" == "null" ]]; then
                    echo "${RED}FAIL:${RESET} Could not resolve requested version $requested_version for package: $package_name"
                    failures=$((failures + 1))
                    package_resolution_failed=$((package_resolution_failed + 1))
                    continue
                fi

                echo "${GREEN}OK:${RESET} $package_name -> $requested_version"
                package_resolution_passed=$((package_resolution_passed + 1))
            done < <(read_dependencies)

            if [[ "$package_resolution_failed" -eq 0 ]]; then
                add_summary_row "PASS" "Package resolution" "Resolved $package_resolution_passed/$package_count dependencies."
            else
                add_summary_row "FAIL" "Package resolution" "Resolved $package_resolution_passed/$package_count; failed $package_resolution_failed."
            fi

            if [[ "$install_key_required" == "true" ]]; then
                if [[ -n "$PACKAGE_INSTALL_KEY" ]]; then
                    echo "${GREEN}OK:${RESET} Package install key provided via environment"
                    key_check_status="PASS"
                    key_check_detail="Install key is available via environment variable."
                else
                    resolve_package_install_key_from_keychain
                    if [[ -n "$PACKAGE_INSTALL_KEY" ]]; then
                        echo "${GREEN}OK:${RESET} Package install key available from macOS Keychain"
                        key_check_status="PASS"
                        key_check_detail="Install key was resolved from macOS Keychain."
                    else
                        echo "${RED}FAIL:${RESET} Package install key is required for at least one package, but was not found in env or Keychain."
                        failures=$((failures + 1))
                        key_check_status="FAIL"
                        key_check_detail="Install key required but not found in env or Keychain."
                    fi
                fi
            fi
        fi
    else
        add_summary_row "SKIP" "Package resolution" "No package operation requested."
    fi

    add_summary_row "$key_check_status" "Install key readiness" "$key_check_detail"

    print_self_check_summary

    if [[ "$failures" -gt 0 ]]; then
        ORG_ACTION="No org action. Self-check failed."
        error 1 "Self-check found $failures issue(s)."
    fi

    ORG_ACTION="No org action. Self-check only."
    add_action "Self-check completed"

    echo ""
    success "${GREEN}${BOLD}Self-check completed successfully.${RESET}"
    info "No orgs were created, deleted, fetched, deployed to, or modified."
}

package_plan() {
    local count=""
    local index=0
    count="$(dependency_count)"

    if [[ "$count" -eq 0 ]]; then
        echo ""
        skipped "No package dependencies declared in $PROJECT_FILE. Nothing to plan."
        return 0
    fi

    section "Package plan for org: $TARGET_ORG"
    print_package_mode "Plan"

    load_installed_packages

    while IFS=$'\t' read -r package_name requested_version; do
        [[ -z "$package_name" ]] && continue
        index=$((index + 1))

        resolve_package_version "$package_name" "$requested_version"

        local installed_json=""
        local installed_version=""
        local installed_04t=""
        local comparison=""

        installed_json="$(installed_package_json "$package_name")"

        print_package_header "$index" "$count" "$package_name" "$requested_version"
        warn_if_dependency_is_not_latest "$package_name" "$requested_version"

        if package_requires_key "$package_name"; then
            kv "Install key" "required" 18
        else
            kv "Install key" "not required" 18
        fi

        if [[ -z "$installed_json" || "$installed_json" == "null" ]]; then
            echo "${YELLOW}${ICON_INFO} Plan:${RESET} package is missing and would be installed."
            add_package_missing "$package_name target=$RESOLVED_SELECTED_VERSION"
            continue
        fi

        installed_version="$(installed_package_version "$installed_json")"
        installed_04t="$(installed_package_04t "$installed_json")"

        kv "Installed version" "$installed_version" 18
        kv "Installed 04t" "${installed_04t:-unknown}" 18

        comparison="$(compare_versions "$installed_version" "$RESOLVED_SELECTED_VERSION")"

        if [[ "$comparison" == "-1" ]]; then
            echo "${BLUE}${ICON_UPDATE} Plan:${RESET} installed version is lower than target and would be updated."
            add_package_updated "$package_name would update $installed_version -> $RESOLVED_SELECTED_VERSION"
        elif [[ "$comparison" == "0" ]]; then
            echo "${GREEN}${ICON_OK} Plan:${RESET} package is already on target version and would be skipped."
            add_package_skipped "$package_name $installed_version"
        else
            warning "$package_name has a higher version installed than the target version. Installed: $installed_version. Target: $RESOLVED_SELECTED_VERSION. Would skip downgrade."
            add_package_higher_than_target "$package_name installed=$installed_version target=$RESOLVED_SELECTED_VERSION"
        fi

    done < <(read_dependencies)
}

print_settings() {
    local pool_devhub_display="${POOL_DEVHUB_USERNAME:-resolve from sf config target-dev-hub}"
    local keychain_service_display="${PACKAGE_INSTALL_KEYCHAIN_SERVICE:-auto}"
    local keychain_account_display="${PACKAGE_INSTALL_KEYCHAIN_ACCOUNT:-auto}"
    local config_display="not used"

    if [[ "$CONFIG_LOADED" == "true" ]]; then
        config_display="$CONFIG_FILE"
    elif [[ "$USE_CONFIG" == "true" ]]; then
        config_display="$CONFIG_FILE (not found, using defaults)"
    fi

    banner "Scratch org setup"
    kv "Active modes" "${BOLD}$(active_modes)${RESET}"
    kv "Configuration file" "$config_display"

    section "Target"
    kv "Creation alias" "$ORG_ALIAS ${DIM}($ORG_ALIAS_SOURCE)${RESET}"
    kv "Effective target org" "${BOLD}$TARGET_ORG${RESET}"
    kv "Target org source" "$TARGET_ORG_SOURCE"

    section "Scratch org"
    kv "Create/fetch org" "$RUN_ORG_CREATE"
    kv "Definition file" "$SCRATCH_DEF_FILE"
    kv "Duration days" "$DURATION_DAYS"
    kv "Use pool" "$USE_POOL"
    if [[ "$USE_POOL" == "true" ]]; then
        kv "Pool tag" "$POOL_TAG"
        kv "Pool DevHub" "$pool_devhub_display"
    fi

    section "Project and packages"
    kv "Project file" "$PROJECT_FILE"
    kv "Install packages" "$RUN_PACKAGES"
    kv "Verify package versions" "$VERIFY_PACKAGE_VERSIONS"
    kv "Package wait minutes" "$PACKAGE_WAIT_MINUTES"
    kv "Install attempts / delay" "$PACKAGE_INSTALL_MAX_ATTEMPTS / ${PACKAGE_INSTALL_RETRY_DELAY_SECONDS}s"
    kv "Packages not requiring key" "${PACKAGES_NOT_REQUIRING_INSTALL_KEY:-from packageKeyConfig in $PROJECT_FILE}"
    kv "Install key variable" "$PACKAGE_INSTALL_KEY_ENV_VAR"
    kv "Keychain service/account" "$keychain_service_display / $keychain_account_display"
    kv "Preserved dependency files" "$PRESERVE_ROOT_FILES"

    section "Post-steps"
    kv "Selected" "${BOLD}$POST_STEPS${RESET}"
    kv "Permission sets" "${PERMISSION_SETS:-none}"
    kv "Community name" "${COMMUNITY_NAME:-none}"
    kv "Dummy data plan" "${DUMMY_DATA_PLAN:-none}"
    kv "Dummy user file" "${DUMMY_USER_FILE:-none}"
    kv "Custom post steps" "${CUSTOM_POST_STEP_NAMES:-none}"
}

# -----------------------------
# Arguments
# -----------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--alias)
            require_option_value "$1" "${2:-}"
            ORG_ALIAS="$2"
            ORG_ALIAS_SOURCE="--alias"
            shift 2
            ;;
        -d|--duration-days)
            require_option_value "$1" "${2:-}"
            DURATION_DAYS="$2"
            shift 2
            ;;
        -f|--definition-file)
            require_option_value "$1" "${2:-}"
            SCRATCH_DEF_FILE="$2"
            shift 2
            ;;
        -p|--project-file)
            require_option_value "$1" "${2:-}"
            PROJECT_FILE="$2"
            shift 2
            ;;
        -c|--community-name)
            require_option_value "$1" "${2:-}"
            COMMUNITY_NAME="$2"
            shift 2
            ;;
        --dummy-data-plan)
            require_option_value "$1" "${2:-}"
            DUMMY_DATA_PLAN="$2"
            shift 2
            ;;
        --permission-sets)
            require_option_value "$1" "${2:-}"
            PERMISSION_SETS="$2"
            shift 2
            ;;
        --config)
            require_option_value "$1" "${2:-}"
            SF_PROJECT_CONFIG="$2"
            shift 2
            ;;
        --no-config)
            USE_CONFIG=false
            shift
            ;;
        --init-config)
            INIT_CONFIG_ONLY=true
            shift
            ;;
        --force)
            FORCE_INIT_CONFIG=true
            shift
            ;;
        -s|--post-steps)
            require_option_value "$1" "${2:-}"
            POST_STEPS="$2"
            shift 2
            ;;
        --install-latest)
            INSTALL_LATEST_PACKAGES=true
            shift
            ;;
        --update-packages)
            UPDATE_PACKAGES_ONLY=true
            shift
            ;;
        --use-pool)
            USE_POOL=true
            shift
            ;;
        --pool-tag)
            require_option_value "$1" "${2:-}"
            POOL_TAG="$2"
            shift 2
            ;;
        --pool-devhub)
            require_option_value "$1" "${2:-}"
            POOL_DEVHUB_USERNAME="$2"
            shift 2
            ;;
        --keychain-service)
            require_option_value "$1" "${2:-}"
            PACKAGE_INSTALL_KEYCHAIN_SERVICE="$2"
            shift 2
            ;;
        --keychain-account)
            require_option_value "$1" "${2:-}"
            PACKAGE_INSTALL_KEYCHAIN_ACCOUNT="$2"
            shift 2
            ;;
        --delete-org-only)
            DELETE_ORG_ONLY=true
            shift
            ;;
        --self-check)
            SELF_CHECK_ONLY=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --package-plan)
            PACKAGE_PLAN_ONLY=true
            shift
            ;;
        --check-versions)
            CHECK_PROJECT_VERSIONS_ONLY=true
            shift
            ;;
        --apply-project-versions)
            CHECK_PROJECT_VERSIONS_ONLY=true
            APPLY_PROJECT_VERSIONS=true
            shift
            ;;
        --coverage-check)
            COVERAGE_CHECK_ONLY=true
            shift
            ;;
        --coverage-package-id)
            require_option_value "$1" "${2:-}"
            COVERAGE_PACKAGE_ID="$2"
            shift 2
            ;;
        --coverage-minimum)
            require_option_value "$1" "${2:-}"
            COVERAGE_MINIMUM="$2"
            shift 2
            ;;
        --coverage-test-class)
            require_option_value "$1" "${2:-}"
            COVERAGE_TEST_CLASS="$2"
            shift 2
            ;;
        --coverage-class-pattern)
            require_option_value "$1" "${2:-}"
            COVERAGE_CLASS_PATTERN="$2"
            shift 2
            ;;
        --coverage-run-all)
            COVERAGE_RUN_ALL=true
            shift
            ;;
        --coverage-skip-install)
            COVERAGE_SKIP_INSTALL=true
            shift
            ;;
        --coverage-skip-deploy)
            COVERAGE_SKIP_DEPLOY=true
            shift
            ;;
        --refresh-dependency-sources)
            REFRESH_DEPENDENCY_SOURCES=true
            shift
            ;;
        --clear-dependency-sources-only)
            CLEAR_DEPENDENCY_SOURCES_ONLY=true
            shift
            ;;
        --post-steps-only)
            POST_STEPS_ONLY_MODE=true
            shift
            ;;
        --full-deploy)
            FULL_DEPLOY=true
            shift
            ;;
        --redeploy)
            REDEPLOY=true
            shift
            ;;
        --skip-org)
            RUN_ORG_CREATE=false
            shift
            ;;
        --skip-packages)
            RUN_PACKAGES=false
            shift
            ;;
        --skip-version-check)
            VERIFY_PACKAGE_VERSIONS=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --color)
            COLOR_MODE=always
            shift
            ;;
        --no-color)
            COLOR_MODE=never
            shift
            ;;
        -h|--help)
            SUMMARY_ENABLED=false
            usage
            exit 0
            ;;
        *)
            error 1 "Unknown argument: $1"
            ;;
    esac
done

# -----------------------------
# Configuration
# -----------------------------

init_output
resolve_config_file
load_config
parse_dummy_user_assignments_from_environment
apply_generic_defaults

if [[ "$FORCE_INIT_CONFIG" == "true" && "$INIT_CONFIG_ONLY" != "true" ]]; then
    error 1 "--force can only be used with --init-config."
fi

if [[ "$INIT_CONFIG_ONLY" == "true" ]]; then
    if [[ "$DELETE_ORG_ONLY" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" || "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" || "$SELF_CHECK_ONLY" == "true" || "$POST_STEPS_ONLY_MODE" == "true" ]]; then
        error 1 "You cannot combine --init-config with another exclusive mode."
    fi

    validate_duration_days
    validate_boolean "$USE_POOL" "USE_POOL"
    validate_boolean "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" "FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY"
    validate_post_steps
    init_config
    exit 0
fi

# -----------------------------
# Normalize mode shortcuts
# -----------------------------

if [[ "$REDEPLOY" == "true" ]]; then
    POST_STEPS_ONLY_MODE=true
    POST_STEPS=deploy
    FULL_DEPLOY=true
fi

if [[ "$DELETE_ORG_ONLY" == "true" && "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    error 1 "You cannot combine --delete-org-only and --update-packages."
fi

if [[ "$DELETE_ORG_ONLY" == "true" && "$PACKAGE_PLAN_ONLY" == "true" ]]; then
    error 1 "You cannot combine --delete-org-only and --package-plan."
fi

if [[ "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" && "$REFRESH_DEPENDENCY_SOURCES" == "true" ]]; then
    error 1 "You cannot combine --clear-dependency-sources-only and --refresh-dependency-sources."
fi

if [[ "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" && ( "$DELETE_ORG_ONLY" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" || "$SELF_CHECK_ONLY" == "true" ) ]]; then
    error 1 "You cannot combine --clear-dependency-sources-only with another exclusive mode."
fi

if [[ "$POST_STEPS_ONLY_MODE" == "true" && ( "$DELETE_ORG_ONLY" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" || "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" ) ]]; then
    error 1 "You cannot combine --post-steps-only with another exclusive mode."
fi

if [[ "$CHECK_PROJECT_VERSIONS_ONLY" == "true" && ( "$DELETE_ORG_ONLY" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" || "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" || "$SELF_CHECK_ONLY" == "true" || "$POST_STEPS_ONLY_MODE" == "true" ) ]]; then
    error 1 "You cannot combine --check-versions with another exclusive mode."
fi

if [[ "$CHECK_PROJECT_VERSIONS_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    POST_STEPS=none
    USE_POOL=false
fi

if [[ "$COVERAGE_CHECK_ONLY" == "true" && ( "$CHECK_PROJECT_VERSIONS_ONLY" == "true" || "$DELETE_ORG_ONLY" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" || "$PACKAGE_PLAN_ONLY" == "true" || "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" || "$SELF_CHECK_ONLY" == "true" || "$POST_STEPS_ONLY_MODE" == "true" ) ]]; then
    error 1 "You cannot combine --coverage-check with another exclusive mode."
fi

if [[ "$COVERAGE_CHECK_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    POST_STEPS=none
    USE_POOL=false
fi

if [[ "$DELETE_ORG_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    POST_STEPS=none
    USE_POOL=false
fi

if [[ "$PACKAGE_PLAN_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    POST_STEPS=none
    USE_POOL=false
fi

if [[ "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=true
    POST_STEPS=none
    USE_POOL=false
fi

if [[ "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    POST_STEPS=none
    USE_POOL=false
fi

if [[ "$POST_STEPS_ONLY_MODE" == "true" ]]; then
    RUN_ORG_CREATE=false
    RUN_PACKAGES=false
    USE_POOL=false
fi

REQUESTED_RUN_ORG_CREATE="$RUN_ORG_CREATE"
REQUESTED_RUN_PACKAGES="$RUN_PACKAGES"
REQUESTED_POST_STEPS="$POST_STEPS"
REQUESTED_USE_POOL="$USE_POOL"
REQUESTED_UPDATE_PACKAGES_ONLY="$UPDATE_PACKAGES_ONLY"
REQUESTED_PACKAGE_PLAN_ONLY="$PACKAGE_PLAN_ONLY"
REQUESTED_INSTALL_LATEST_PACKAGES="$INSTALL_LATEST_PACKAGES"
REQUESTED_POST_STEPS_ONLY_MODE="$POST_STEPS_ONLY_MODE"

# -----------------------------
# Validation
# -----------------------------

validate_duration_days
validate_number "$PACKAGE_WAIT_MINUTES" "Package wait minutes"
validate_number "$PACKAGE_INSTALL_MAX_ATTEMPTS" "Package install max attempts"
validate_number "$PACKAGE_INSTALL_RETRY_DELAY_SECONDS" "Package install retry delay seconds"

if [[ "$PACKAGE_INSTALL_MAX_ATTEMPTS" -lt 1 ]]; then
    error 1 "Package install max attempts must be at least 1. Got: $PACKAGE_INSTALL_MAX_ATTEMPTS"
fi

validate_boolean "$RUN_ORG_CREATE" "RUN_ORG_CREATE"
validate_boolean "$RUN_PACKAGES" "RUN_PACKAGES"
validate_boolean "$VERIFY_PACKAGE_VERSIONS" "VERIFY_PACKAGE_VERSIONS"
validate_boolean "$INSTALL_LATEST_PACKAGES" "INSTALL_LATEST_PACKAGES"
validate_boolean "$DELETE_ORG_ONLY" "DELETE_ORG_ONLY"
validate_boolean "$UPDATE_PACKAGES_ONLY" "UPDATE_PACKAGES_ONLY"
validate_boolean "$USE_POOL" "USE_POOL"
validate_boolean "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" "FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY"
validate_boolean "$SELF_CHECK_ONLY" "SELF_CHECK_ONLY"
validate_boolean "$DRY_RUN" "DRY_RUN"
validate_boolean "$PACKAGE_PLAN_ONLY" "PACKAGE_PLAN_ONLY"
validate_boolean "$CHECK_PROJECT_VERSIONS_ONLY" "CHECK_PROJECT_VERSIONS_ONLY"
validate_boolean "$APPLY_PROJECT_VERSIONS" "APPLY_PROJECT_VERSIONS"
validate_boolean "$COVERAGE_CHECK_ONLY" "COVERAGE_CHECK_ONLY"
validate_boolean "$COVERAGE_RUN_ALL" "COVERAGE_RUN_ALL"
validate_boolean "$COVERAGE_SKIP_INSTALL" "COVERAGE_SKIP_INSTALL"
validate_boolean "$COVERAGE_SKIP_DEPLOY" "COVERAGE_SKIP_DEPLOY"
validate_boolean "$FULL_DEPLOY" "FULL_DEPLOY"
validate_boolean "$REFRESH_DEPENDENCY_SOURCES" "REFRESH_DEPENDENCY_SOURCES"
validate_boolean "$CLEAR_DEPENDENCY_SOURCES_ONLY" "CLEAR_DEPENDENCY_SOURCES_ONLY"

validate_post_steps

if [[ "$COVERAGE_CHECK_ONLY" == "true" ]]; then
    if ! [[ "$COVERAGE_MINIMUM" =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk -v value="$COVERAGE_MINIMUM" 'BEGIN { exit !(value >= 0 && value <= 100) }'; then
        error 2 "Coverage minimum must be a number from 0 to 100. Got: $COVERAGE_MINIMUM"
    fi
fi

if [[ "$CLEAR_DEPENDENCY_SOURCES_ONLY" == "true" ]]; then
    require_command "jq"
    validate_file_exists "$PROJECT_FILE" "Project file"
    validate_json_file "$PROJECT_FILE"

    ORG_ACTION="No org action. Dependency source cleanup only."
    print_settings
    clear_dependency_package_directories

    echo ""
    success "${GREEN}${BOLD}Dependency source cleanup completed successfully.${RESET}"
    exit 0
fi

require_command "sf"

if [[ "$USE_POOL" == "true" ]]; then
    require_command "sfp"
    require_command "jq"
fi

if needs_project_file; then
    require_command "jq"
    require_command "sed"

    validate_file_exists "$PROJECT_FILE" "Project file"
    validate_json_file "$PROJECT_FILE"
fi

if [[ "$RUN_ORG_CREATE" == "true" && ( "$USE_POOL" != "true" || "$FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY" == "true" ) ]]; then
    validate_file_exists "$SCRATCH_DEF_FILE" "Scratch org definition file"
fi

if [[ "$CHECK_PROJECT_VERSIONS_ONLY" == "true" ]]; then
    print_settings
    check_project_package_versions
    exit 0
fi

resolve_runtime_target_org

if [[ "$COVERAGE_CHECK_ONLY" == "true" ]]; then
    print_settings
    run_coverage_check
    exit 0
fi

# -----------------------------
# Main
# -----------------------------

print_settings

if [[ "$SELF_CHECK_ONLY" == "true" ]]; then
    run_self_check
    exit 0
fi

if [[ "$DELETE_ORG_ONLY" == "true" ]]; then
    delete_existing_scratch_org

    echo ""
    success "${GREEN}${BOLD}Scratch org delete completed successfully.${RESET}"
    exit 0
fi

if [[ "$PACKAGE_PLAN_ONLY" == "true" ]]; then
    ORG_ACTION="No org action. Package plan only."
    package_plan
    print_package_update_suggestions

    echo ""
    success "${GREEN}${BOLD}Package plan completed successfully.${RESET}"
    exit 0
fi

RUN_PACKAGE_PHASE=false
if [[ "$RUN_PACKAGES" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    RUN_PACKAGE_PHASE=true
fi

SELECTED_POST_STEPS=()
UNSELECTED_POST_STEPS=()
for post_step in $(all_post_step_names); do
    if should_run_post_step "$post_step"; then
        SELECTED_POST_STEPS+=("$post_step")
    else
        UNSELECTED_POST_STEPS+=("$post_step")
    fi
done

[[ "$RUN_ORG_CREATE" == "true" ]] && PHASE_TOTAL=$((PHASE_TOTAL + 1))
[[ "$RUN_PACKAGE_PHASE" == "true" ]] && PHASE_TOTAL=$((PHASE_TOTAL + 1))
[[ "${#SELECTED_POST_STEPS[@]}" -gt 0 ]] && PHASE_TOTAL=$((PHASE_TOTAL + 1))
[[ "$REFRESH_DEPENDENCY_SOURCES" == "true" ]] && PHASE_TOTAL=$((PHASE_TOTAL + 1))

check_if_package_install_key_is_required
setup_org

if [[ "$RUN_PACKAGE_PHASE" == "true" ]]; then
    phase "Packages"
fi

if [[ "$USE_POOL" == "true" && "$RUN_PACKAGES" == "true" ]]; then
    update_packages
elif [[ "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    update_packages
elif [[ "$RUN_PACKAGES" == "true" ]]; then
    install_packages
fi

for post_step in "${UNSELECTED_POST_STEPS[@]-}"; do
    [[ -n "$post_step" ]] && add_post_step_skipped "$post_step"
done

if [[ "${#SELECTED_POST_STEPS[@]}" -gt 0 ]]; then
    phase "Post-steps"
    if [[ "${#UNSELECTED_POST_STEPS[@]}" -gt 0 ]]; then
        info "Not selected: $(printf '%s, ' "${UNSELECTED_POST_STEPS[@]}" | sed 's/, $//')"
    fi

    post_step_index=0
    for post_step in "${SELECTED_POST_STEPS[@]}"; do
        post_step_index=$((post_step_index + 1))
        item "$(counter "$post_step_index" "${#SELECTED_POST_STEPS[@]}") ${BOLD}$post_step${RESET}"
        run_post_step "$post_step"
    done
fi

if should_run_post_step "deploy"; then
    echo ""
    reset_source_tracking
fi

if [[ "$REFRESH_DEPENDENCY_SOURCES" == "true" ]]; then
    phase "Dependency sources"
    retrieve_dependency_packages
fi

if [[ "$RUN_PACKAGES" == "true" || "$UPDATE_PACKAGES_ONLY" == "true" ]]; then
    print_package_update_suggestions
fi

echo ""
success "${GREEN}${BOLD}Scratch org setup completed successfully.${RESET}"