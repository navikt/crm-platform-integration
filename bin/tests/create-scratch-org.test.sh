#!/usr/bin/env bash
# Offline tests for bin/create-scratch-org.sh. A fake `sf` on PATH records calls; no Salesforce org is contacted.

set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/create-scratch-org.sh"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/scratch-org-tests.XXXXXX")"
WORK_DIR="$(cd "$WORK_DIR" && pwd)"
trap 'rm -rf "$WORK_DIR"' EXIT

FAKE_BIN="$WORK_DIR/fake-bin"
SF_LOG="$WORK_DIR/sf.log"
SF_ARG_LOG="$WORK_DIR/sf-arguments.jsonl"
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/sf" <<'EOF_SF'
#!/usr/bin/env bash
echo "$*" >> "$SF_LOG"
jq -cn --args '$ARGS.positional' -- sf "$@" >> "$SF_ARG_LOG"
if [[ -n "${SF_FAIL_COMMAND:-}" && "$*" == "$SF_FAIL_COMMAND"* ]]; then
    echo "offline sf failure: $SF_FAIL_COMMAND" >&2
    exit 23
fi
if [[ -n "${USER_IMPORT_CAPTURE:-}" ]]; then
    import_arguments=("$@")
    for ((argument_index = 0; argument_index < ${#import_arguments[@]}; argument_index += 1)); do
        if [[ "${import_arguments[$argument_index]}" == "--files" ]]; then
            cp "${import_arguments[$((argument_index + 1))]}" "$USER_IMPORT_CAPTURE"
            break
        fi
    done
fi
case "$*" in
    "config get target-dev-hub --json")
        jq -cn --arg value "${DEFAULT_DEVHUB:-offline-devhub}" '{status:0,result:[{name:"target-dev-hub",value:$value}]}'
        ;;
    "config get target-org --json")
        echo '{"status":0,"result":[{"name":"target-org","value":"fake-default-org"}]}'
        ;;
    *"SELECT Id FROM Profile WHERE Name = 'Case Handler'"*)
        echo '{"status":0,"result":{"records":[{"Id":"00e000000000001"}]}}'
        ;;
    *"SELECT Id FROM Profile WHERE Name = 'Support User'"*)
        echo '{"status":0,"result":{"records":[{"Id":"00e000000000002"}]}}'
        ;;
    *"SELECT Id FROM Profile"*)
        echo '{"status":0,"result":{"records":[{"Id":"00e000000000003"}]}}'
        ;;
    *"SELECT Username FROM User"*)
        echo '{"status":0,"result":{"records":[]}}'
        ;;
    *"SELECT SUM(NumLinesCovered)"*)
        echo "{\"status\":0,\"result\":{\"records\":[{\"covered\":${COVERAGE_RESULT:-80},\"uncovered\":${COVERAGE_UNCOVERED:-20}}]}}"
        ;;
    "package version list"*)
        echo "{\"status\":0,\"result\":[{\"SubscriberPackageVersionId\":\"offline-$5\",\"MajorVersion\":1,\"MinorVersion\":0,\"PatchVersion\":0,\"BuildNumber\":1}]}"
        ;;
    "package version report"*)
        dependency_json=null
        if [[ "${MISSING_DEPENDENCY:-false}" == "true" && "$5" == "offline-parent" ]]; then
            dependency_json='{"ids":[{"subscriberPackageVersionId":"offline-child"}]}'
        fi
        echo "{\"status\":0,\"result\":{\"SubscriberPackageVersionId\":\"$5\",\"Package2Id\":\"$5-package\",\"MajorVersion\":1,\"MinorVersion\":0,\"PatchVersion\":0,\"BuildNumber\":1,\"SubscriberPackageVersion\":{\"Dependencies\":$dependency_json}}}"
        ;;
    "package installed list"*)
        if [[ -n "${INSTALLED_PACKAGES:-}" ]]; then
            echo "$INSTALLED_PACKAGES"
        else
            echo '{"status":0,"result":[]}'
        fi
        ;;
    "package install -r"*)
        if [[ -n "${INSTALL_FAIL_COUNTER:-}" ]]; then
            failures="$(cat "$INSTALL_FAIL_COUNTER" 2>/dev/null || echo 0)"
            if (( failures < ${INSTALL_FAIL_TIMES:-0} )); then
                echo $((failures + 1)) > "$INSTALL_FAIL_COUNTER"
                echo "${INSTALL_FAIL_MESSAGE:-Error: read ECONNRESET}" >&2
                exit 1
            fi
        fi
        echo "Successfully installed package from fake sf"
        ;;
    *)
        echo '{"status":0,"result":{}}'
        ;;
esac
EOF_SF
chmod +x "$FAKE_BIN/sf"

cat > "$FAKE_BIN/sfp" <<'EOF_SFP'
#!/usr/bin/env bash
echo "sfp $*" >> "$SF_LOG"
jq -cn --args '$ARGS.positional' -- sfp "$@" >> "$SF_ARG_LOG"
case "$1 $2" in
    "pool list")
        if [[ "${POOL_LIST_EXIT:-0}" != 0 ]]; then
            echo "offline pool list failure" >&2
            exit "$POOL_LIST_EXIT"
        fi
        printf '%s\n' "${POOL_LIST_OUTPUT-Unused Scratch Orgs in the Pool: 2}"
        ;;
    "pool fetch")
        if [[ "${POOL_FETCH_EXIT:-0}" != 0 ]]; then
            echo "offline pool fetch failure" >&2
            exit "$POOL_FETCH_EXIT"
        fi
        ;;
    *) echo "Unexpected offline sfp command: $*" >&2; exit 99 ;;
esac
EOF_SFP
chmod +x "$FAKE_BIN/sfp"

PASSED=0
FAILED=0
OUTPUT=""
EXIT_CODE=0
PROJECT=""

new_project() {
    PROJECT="$WORK_DIR/$1"
    mkdir -p "$PROJECT/config"
    echo '{"edition":"Developer"}' > "$PROJECT/config/project-scratch-def.json"
    echo '{"packageDirectories":[{"path":"force-app","default":true}]}' > "$PROJECT/sfdx-project.json"
    : > "$SF_LOG"
    : > "$SF_ARG_LOG"
}

write_config() {
    printf '%s\n' "$1" > "$PROJECT/sf-project.config.json"
}

run_script() {
    OUTPUT="$(cd "$PROJECT" && env PATH="$FAKE_BIN:$PATH" TMPDIR="$WORK_DIR" SF_LOG="$SF_LOG" SF_ARG_LOG="$SF_ARG_LOG" "$@" 2>&1)"
    EXIT_CODE=$?
}

script() {
    run_script bash "$SCRIPT" "$@"
}

pass() { PASSED=$((PASSED + 1)); }

fail() {
    FAILED=$((FAILED + 1))
    echo "FAIL [$CURRENT_TEST]: $1"
}

assert_exit() {
    [[ "$EXIT_CODE" -eq "$1" ]] && pass || fail "expected exit $1, got $EXIT_CODE. Output:\n$OUTPUT"
}

assert_exit_nonzero() {
    [[ "$EXIT_CODE" -ne 0 ]] && pass || fail "expected non-zero exit. Output:\n$OUTPUT"
}

assert_contains() {
    [[ "$OUTPUT" == *"$1"* ]] && pass || fail "expected output to contain: $1"
}

assert_not_contains() {
    [[ "$OUTPUT" != *"$1"* ]] && pass || fail "expected output not to contain: $1"
}

assert_json() {
    local file="$1" filter="$2" expected="$3" actual
    actual="$(jq -c "$filter" "$file" 2>&1)"
    [[ "$actual" == "$expected" ]] && pass || fail "$filter in $file: expected $expected, got $actual"
}

test_reads_config_values() {
    new_project reads-config
    write_config '{
        "schemaVersion": 1,
        "defaultOrgAlias": "cfg-org",
        "permissionSets": ["PermA", "PermB"],
        "communityName": "Config Community",
        "postSteps": ["permsets", "community"]
    }'
    script --post-steps-only --dry-run
    assert_exit 0
    assert_contains "sf org assign permset --target-org cfg-org --name PermA --name PermB"
    assert_contains "sf community publish --target-org cfg-org --name Config\\ Community"
    assert_not_contains "project deploy start"
}

test_missing_dependency_blocks_setup_and_apply_is_explicit() {
    new_project missing-transitive
    echo '{"packageDirectories":[{"path":"force-app","dependencies":[{"package":"parent","versionNumber":"1.0.0.LATEST"}]}],"packageAliases":{"child":"offline-child-package"},"packageKeyConfig":{"parent":false}}' > "$PROJECT/sfdx-project.json"
    script --alias offline-org --post-steps none
    assert_exit 0
    : > "$SF_LOG"
    run_script env MISSING_DEPENDENCY=true bash "$SCRIPT" --alias offline-org --post-steps none
    assert_exit_nonzero
    assert_contains "Package: child"
    assert_contains "Required: 1.0.0.1"
    ! grep -Eq '^(org delete|org create|package install|project deploy|pool fetch)' "$SF_LOG" && pass || fail "preflight allowed a mutation"
    [[ ! -f "$PROJECT/sfdx-project.json.dependencies.backup" ]] && pass || fail "read-only check created backup"
    run_script env MISSING_DEPENDENCY=true NO_COLOR=1 bash "$SCRIPT" --check-dependencies --color
    assert_exit_nonzero
    assert_contains $'\033[31mMissing packages: 1'
    assert_contains $'\033[1;36mDependency graph'
    assert_contains '+-- child 1.0.0.1 [MISSING]'
    run_script env MISSING_DEPENDENCY=true FORCE_COLOR=1 bash "$SCRIPT" --check-dependencies --no-color
    assert_exit_nonzero
    assert_not_contains $'\033['
    run_script env MISSING_DEPENDENCY=true bash "$SCRIPT" --check-dependencies --dependency-report "$PROJECT/custom report.md"
    assert_exit_nonzero
    grep -q '```mermaid' "$PROJECT/custom report.md" && pass || fail "missing custom Mermaid report"
    grep -q 'Missing packages: 1' "$PROJECT/custom report.md" && pass || fail "missing dependency absent from report"
    grep -q 'Dependency graph explorer' "$PROJECT/custom report.html" && pass || fail "missing HTML companion for custom report"
    : > "$SF_LOG"
    script --dependency-report "$PROJECT/absent/report.md" --alias offline-org --post-steps none
    assert_exit_nonzero
    ! grep -Eq '^(org delete|org create|package install|project deploy|pool fetch)' "$SF_LOG" && pass || fail "report failure allowed mutations"
    run_script env MISSING_DEPENDENCY=true bash "$SCRIPT" --apply-dependencies
    assert_exit 0
    assert_json "$PROJECT/sfdx-project.json" '.packageDirectories[0].dependencies[0].package' '"child"'
    assert_json "$PROJECT/sfdx-project.json" '.packageDirectories[0].dependencies[0].versionNumber' '"1.0.0.1"'
    run_script env MISSING_DEPENDENCY=true bash "$SCRIPT" --check-dependencies
    assert_exit 0
    assert_contains "Dependency preflight PASSED"
}

test_cli_overrides_config() {
    new_project cli-overrides
    write_config '{"defaultOrgAlias":"cfg-org","communityName":"Config Community","postSteps":["community"]}'
    script --post-steps-only --dry-run --alias cli-org --community-name Other
    assert_exit 0
    assert_contains "sf community publish --target-org cli-org --name Other"
    assert_not_contains "cfg-org"
}

test_environment_overrides_config() {
    new_project env-overrides
    write_config '{"defaultOrgAlias":"cfg-org","permissionSets":["PermA"],"postSteps":["permsets"]}'
    run_script env ORG_ALIAS=env-org PERMISSION_SETS="EnvA,EnvB" bash "$SCRIPT" --post-steps-only --dry-run
    assert_exit 0
    assert_contains "--target-org env-org --name EnvA --name EnvB"
}

test_relative_paths_resolve_from_config_directory() {
    new_project relative-paths
    mkdir -p "$PROJECT/nested"
    echo '{"packageDirectories":[{"path":"force-app"}]}' > "$PROJECT/nested/sfdx-project.json"
    printf '%s\n' '{"defaultOrgAlias":"cfg-org","dummyDataPlan":"data/Plan.json","postSteps":["data"]}' > "$PROJECT/nested/sf-project.config.json"
    script --project-file nested/sfdx-project.json --post-steps-only --dry-run
    assert_exit 0
    assert_contains "--plan nested/data/Plan.json"
}

test_no_config_falls_back_to_sf_target_org() {
    new_project no-config
    write_config '{"defaultOrgAlias":"cfg-org","permissionSets":["PermA"],"postSteps":["permsets"]}'
    script --no-config --post-steps-only --post-steps permsets --dry-run
    assert_exit 0
    assert_contains "fake-default-org"
    assert_contains "No permission sets configured"
    assert_not_contains "org assign permset"
}

test_invalid_config_fails_before_org_commands() {
    new_project invalid-json
    write_config '{ not json'
    script --dry-run
    assert_exit_nonzero
    assert_contains "sf-project.config.json"
    [[ ! -s "$SF_LOG" ]] && pass || fail "sf was called: $(cat "$SF_LOG")"
}

test_unsupported_schema_version_fails() {
    new_project schema-version
    write_config '{"schemaVersion":2}'
    script --dry-run
    assert_exit_nonzero
    assert_contains "schemaVersion"
}

test_wrong_field_type_fails() {
    new_project wrong-type
    write_config '{"permissionSets":"PermA"}'
    script --dry-run
    assert_exit_nonzero
    assert_contains "permissionSets"
}

test_explicit_missing_config_fails() {
    new_project missing-config
    script --config does-not-exist.json --dry-run
    assert_exit_nonzero
    assert_contains "does-not-exist.json"
}

test_default_alias_is_project_directory_name() {
    new_project my-generic-project
    script --dry-run --skip-packages --post-steps none
    assert_exit 0
    assert_contains "Creating scratch org: my-generic-project"
    assert_not_contains "crm-arbeidsforhold"
}

test_unconfigured_post_steps_are_skipped_with_warning() {
    new_project unconfigured-steps
    write_config '{"defaultOrgAlias":"cfg-org"}'
    script --post-steps-only --post-steps permsets,data,community --dry-run
    assert_exit 0
    assert_contains "No permission sets configured"
    assert_contains "No dummy data plan configured"
    assert_contains "No community name configured"
    assert_not_contains "community publish"
    assert_not_contains "data import tree"
}

test_custom_post_step_runs_from_config() {
    new_project custom-step
    write_config '{
        "defaultOrgAlias": "cfg-org",
        "postSteps": ["seed"],
        "customPostSteps": [{"name": "seed", "executable": "echo", "arguments": ["hello world", "--flag"]}]
    }'
    script --post-steps-only --dry-run
    assert_exit 0
    assert_contains "echo hello\\ world --flag"
}

test_unknown_post_step_fails() {
    new_project unknown-step
    write_config '{"defaultOrgAlias":"cfg-org"}'
    script --post-steps-only --post-steps seed --dry-run
    assert_exit_nonzero
    assert_contains "Invalid post step: seed"
}

test_install_key_requirement_comes_from_package_key_config() {
    new_project key-config
    cat > "$PROJECT/sfdx-project.json" <<'EOF_PROJECT'
{
    "packageDirectories": [
        {"path": "force-app", "package": "main", "dependencies": [{"package": "open-pkg", "versionNumber": "1.0.0.LATEST"}, {"package": "locked-pkg", "versionNumber": "1.0.0.LATEST"}]},
        {"path": "open-pkg"},
        {"path": "locked-pkg"}
    ],
    "packageKeyConfig": {"open-pkg": false}
}
EOF_PROJECT
    script --dry-run --post-steps none --skip-version-check
    assert_exit 0
    local open_line locked_line
    open_line="$(grep -F 'Would run:' <<< "$OUTPUT" | grep -F 'package install' | sed -n 1p)"
    locked_line="$(grep -F 'Would run:' <<< "$OUTPUT" | grep -F 'package install' | sed -n 2p)"
    [[ "$open_line" != *" -k "* ]] && pass || fail "open-pkg should not use an install key: $open_line"
    [[ "$locked_line" == *" -k "* ]] && pass || fail "locked-pkg should use an install key: $locked_line"
}

test_no_dependencies_is_not_an_error() {
    new_project no-dependencies
    script --dry-run --post-steps none
    assert_exit 0
    assert_contains "No package dependencies declared"
}

test_dependency_cleanup_uses_package_directories_and_preserve_policy() {
    new_project dependency-cleanup
    cat > "$PROJECT/sfdx-project.json" <<'EOF_PROJECT'
{
    "packageDirectories": [
        {"path": "force-app", "dependencies": [{"package": "dep-pkg", "versionNumber": "1.0.0.LATEST"}]},
        {"path": "vendor/dep-source", "package": "dep-pkg"}
    ]
}
EOF_PROJECT
    write_config '{"dependencySourcePolicy":{"preserveRootFiles":["README.md","KEEP.md"]}}'
    mkdir -p "$PROJECT/vendor/dep-source/main"
    touch "$PROJECT/vendor/dep-source/README.md" "$PROJECT/vendor/dep-source/KEEP.md" "$PROJECT/vendor/dep-source/main/file.xml"
    script --clear-dependency-sources-only
    assert_exit 0
    [[ -f "$PROJECT/vendor/dep-source/README.md" && -f "$PROJECT/vendor/dep-source/KEEP.md" ]] && pass || fail "preserved files were removed"
    [[ ! -e "$PROJECT/vendor/dep-source/main" ]] && pass || fail "dependency content was not cleared"
}

test_dependency_cleanup_refuses_project_root() {
    new_project dependency-root-guard
    cat > "$PROJECT/sfdx-project.json" <<'EOF_PROJECT'
{
    "packageDirectories": [
        {"path": "force-app", "dependencies": [{"package": "root-pkg", "versionNumber": "1.0.0.LATEST"}]},
        {"path": ".", "package": "root-pkg"}
    ]
}
EOF_PROJECT
    touch "$PROJECT/important.txt"
    script --clear-dependency-sources-only
    assert_exit_nonzero
    [[ -f "$PROJECT/important.txt" ]] && pass || fail "project root content was deleted"
}

test_dummy_users_come_from_config() {
    new_project dummy-users
    mkdir -p "$PROJECT/data"
    echo '{"records":[{"Username":"u1@example.test"}]}' > "$PROJECT/data/User.json"
    echo '[]' > "$PROJECT/data/Plan.json"
    write_config '{
        "defaultOrgAlias": "cfg-org",
        "dummyDataPlan": "data/Plan.json",
        "postSteps": ["data"],
        "dummyUsers": {
            "file": "data/User.json",
            "profileName": "Custom Profile",
            "permissionSetAssignments": [
                {"permissionSets": ["P1", "P2"], "usernames": ["u1@example.test", "u2@example.test"]}
            ]
        }
    }'
    script --post-steps-only --dry-run
    assert_exit 0
    assert_contains "Would resolve profile(s) Custom Profile"
    assert_contains "--name P1 --name P2 --on-behalf-of u1@example.test --on-behalf-of u2@example.test"
}

test_dummy_users_can_use_multiple_profiles() {
    new_project dummy-users-multiple-profiles
    mkdir -p "$PROJECT/data"
    cat > "$PROJECT/data/User.json" <<'EOF_USERS'
{"records":[
    {"attributes":{"type":"User","referenceId":"Handler"},"Username":"handler@example.test","ProfileId":"org-specific"},
    {"attributes":{"type":"User","referenceId":"Support"},"Username":"support@example.test","ProfileId":"org-specific"},
    {"attributes":{"type":"User","referenceId":"Default"},"Username":"default@example.test","ProfileId":"org-specific"}
]}
EOF_USERS
    echo '[]' > "$PROJECT/data/Plan.json"
    write_config '{
        "dummyDataPlan":"data/Plan.json",
        "postSteps":["data"],
        "dummyUsers":{
            "file":"data/User.json",
            "profileName":"Default Profile",
            "profileAssignments":[
                {"profileName":"Case Handler","usernames":["handler@example.test"]},
                {"profileName":"Support User","usernames":["support@example.test"]}
            ]
        }
    }'
    local capture="$WORK_DIR/imported-multiple-profiles.json"
    run_script env USER_IMPORT_CAPTURE="$capture" bash "$SCRIPT" --post-steps-only --post-steps data
    assert_exit 0
    assert_json "$capture" '[.records[].ProfileId]' '["00e000000000001","00e000000000002","00e000000000003"]'
    grep -Fq "SELECT Id FROM Profile WHERE Name = 'Case Handler'" "$SF_LOG" && pass || fail "Case Handler profile was not queried"
    grep -Fq "SELECT Id FROM Profile WHERE Name = 'Support User'" "$SF_LOG" && pass || fail "Support User profile was not queried"
    grep -Fq "SELECT Id FROM Profile WHERE Name = 'Default Profile'" "$SF_LOG" && pass || fail "Default Profile was not queried"
}

test_dummy_user_assignments_environment_override() {
    new_project dummy-users-env
    mkdir -p "$PROJECT/data"
    echo '{"records":[]}' > "$PROJECT/data/User.json"
    echo '[]' > "$PROJECT/data/Plan.json"
    write_config '{"defaultOrgAlias":"cfg-org","dummyDataPlan":"data/Plan.json","postSteps":["data"],"dummyUsers":{"file":"data/User.json","permissionSetAssignments":[{"permissionSets":["P1"],"usernames":["u1"]}]}}'
    run_script env DUMMY_USER_PERMSET_ASSIGNMENTS="E1,E2:x1,x2;E3:x3" bash "$SCRIPT" --post-steps-only --dry-run
    assert_exit 0
    assert_contains "--name E1 --name E2 --on-behalf-of x1 --on-behalf-of x2"
    assert_contains "--name E3 --on-behalf-of x3"
    assert_not_contains "--on-behalf-of u1"
}

test_init_config_writes_effective_settings() {
    new_project init-config
    run_script env PACKAGE_INSTALL_KEY=top-secret-value bash "$SCRIPT" --init-config --alias new-org --permission-sets A,B --community-name Portal
    assert_exit 0
    local file="$PROJECT/sf-project.config.json"
    [[ -f "$file" ]] && pass || fail "config file was not written"
    assert_json "$file" '.schemaVersion' '1'
    assert_json "$file" '.defaultOrgAlias' '"new-org"'
    assert_json "$file" '.permissionSets' '["A","B"]'
    assert_json "$file" '.communityName' '"Portal"'
    assert_json "$file" '.coverage' '{"minimumPercent":75,"testClass":null,"classNamePattern":"%"}'
    assert_json "$file" '.dummyDataPlan' 'null'
    assert_json "$file" '.scratchDefinition' '"config/project-scratch-def.json"'
    assert_json "$file" '.postSteps' '["deploy"]'
    ! grep -q "top-secret-value" "$file" && pass || fail "install key was written to config"
    [[ ! -s "$SF_LOG" ]] && pass || fail "sf was called during --init-config"
}

test_init_config_refuses_to_overwrite() {
    new_project init-config-refuse
    write_config '{"defaultOrgAlias":"keep-me"}'
    script --init-config --alias other
    assert_exit_nonzero
    assert_contains "--force"
    assert_json "$PROJECT/sf-project.config.json" '.defaultOrgAlias' '"keep-me"'
}

test_init_config_force_preserves_unmanaged_keys() {
    new_project init-config-force
    write_config '{"defaultOrgAlias":"old","commandTimeouts":{"readMs":1000},"customPostSteps":[{"name":"seed","executable":"echo"}],"postSteps":["deploy","seed"]}'
    script --init-config --force --alias new
    assert_exit 0
    assert_json "$PROJECT/sf-project.config.json" '.defaultOrgAlias' '"new"'
    assert_json "$PROJECT/sf-project.config.json" '.commandTimeouts.readMs' '1000'
    assert_json "$PROJECT/sf-project.config.json" '.customPostSteps[0].name' '"seed"'
    assert_json "$PROJECT/sf-project.config.json" '.postSteps' '["deploy","seed"]'
}

test_init_config_dry_run_prints_without_writing() {
    new_project init-config-dry-run
    script --init-config --dry-run --alias preview-org
    assert_exit 0
    assert_contains '"defaultOrgAlias": "preview-org"'
    [[ ! -e "$PROJECT/sf-project.config.json" ]] && pass || fail "dry-run wrote the config file"
}

test_default_post_steps_match_sf_project() {
    new_project default-post-steps
    write_config '{"defaultOrgAlias":"cfg-org","communityName":"Portal"}'
    script --post-steps-only --dry-run
    assert_exit 0
    assert_contains "sf project deploy start --target-org cfg-org"
    assert_contains "--source-dir force-app"
    assert_not_contains "community publish"
}

test_empty_post_steps_array_means_none() {
    new_project empty-post-steps
    write_config '{"defaultOrgAlias":"cfg-org","postSteps":[]}'
    script --post-steps-only --dry-run
    assert_exit 0
    assert_not_contains "project deploy start"
}

test_duration_outside_salesforce_limits_fails() {
    new_project duration-limit
    script --init-config --dry-run --duration-days 31
    assert_exit_nonzero
    assert_contains "from 1 to 30"
}

test_paths_resolve_from_project_root_with_explicit_config() {
    new_project explicit-config-paths
    mkdir -p "$PROJECT/settings"
    printf '%s\n' '{"defaultOrgAlias":"cfg-org","dummyDataPlan":"data/Plan.json","postSteps":["data"]}' > "$PROJECT/settings/custom.json"
    script --config settings/custom.json --post-steps-only --dry-run
    assert_exit 0
    assert_contains "--plan data/Plan.json"
}

test_custom_post_step_runs_in_project_root() {
    new_project custom-step-cwd
    write_config '{"defaultOrgAlias":"cfg-org","postSteps":["marker"],"customPostSteps":[{"name":"marker","executable":"sh","arguments":["-c","pwd > cwd-marker.txt"]}]}'
    OUTPUT="$(cd "$WORK_DIR" && env PATH="$FAKE_BIN:$PATH" SF_LOG="$SF_LOG" bash "$SCRIPT" --project-file custom-step-cwd/sfdx-project.json --post-steps-only 2>&1)"
    EXIT_CODE=$?
    assert_exit 0
    [[ -f "$PROJECT/cwd-marker.txt" ]] && pass || fail "custom step did not run in the project root"
}

test_empty_preserve_list_keeps_nothing() {
    new_project preserve-nothing
    cat > "$PROJECT/sfdx-project.json" <<'EOF_PROJECT'
{"packageDirectories":[{"path":"force-app","dependencies":[{"package":"dep","versionNumber":"1.0.0.LATEST"}]},{"path":"dep"}]}
EOF_PROJECT
    write_config '{"dependencySourcePolicy":{"preserveRootFiles":[]}}'
    mkdir -p "$PROJECT/dep"
    touch "$PROJECT/dep/README.md"
    script --clear-dependency-sources-only
    assert_exit 0
    [[ ! -e "$PROJECT/dep/README.md" ]] && pass || fail "README.md was kept although preserveRootFiles is empty"
}

test_undeclared_dependency_directory_follows_require_local_directories() {
    new_project require-local-directories
    echo '{"packageDirectories":[{"path":"force-app","dependencies":[{"package":"missing-dep","versionNumber":"1.0.0.LATEST"}]}]}' > "$PROJECT/sfdx-project.json"
    script --clear-dependency-sources-only
    assert_exit_nonzero
    assert_contains "Dependency package directory is not declared: missing-dep"

    write_config '{"dependencySourcePolicy":{"requireLocalDirectories":false}}'
    script --clear-dependency-sources-only
    assert_exit 0
    assert_contains "No package directory is declared for dependency missing-dep"
}

test_install_key_variable_name_from_config() {
    new_project key-variable
    write_config '{"packageInstallKeyEnvironmentVariable":"TEAM-KEY"}'
    script --init-config --dry-run
    assert_exit 0
    assert_contains '"packageInstallKeyEnvironmentVariable": "TEAM-KEY"'
}

# Every fixture must be accepted or rejected identically by this script and the sf-project loader.
test_config_acceptance_matches_sf_project_loader() {
    local cli_dir
    cli_dir="$(dirname "$SCRIPT")/../tools/salesforce-project-cli"
    if [[ ! -d "$cli_dir" ]]; then
        echo "SKIP [$CURRENT_TEST]: optional sf-project CLI is not included in this standalone project"
        return 0
    fi
    if [[ ! -x "$cli_dir/node_modules/.bin/tsx" ]]; then
        echo "SKIP [$CURRENT_TEST]: run npm install in tools/salesforce-project-cli to enable the cross-tool check"
        return 0
    fi

    local -a fixtures=(
        'valid|{}'
        'valid|{"postSteps":[]}'
        'valid|{"communityName":null,"dummyDataPlan":null}'
        'valid|{"customPostSteps":[{"name":"seed","executable":"echo","arguments":["a"],"label":"Seed"}],"postSteps":["deploy","seed"]}'
        'valid|{"dummyUsers":{"file":"u.json","permissionSetAssignments":[{"permissionSets":["P"],"usernames":["u"]}]}}'
        'valid|{"dummyUsers":{"file":"u.json","profileAssignments":[{"profileName":"Case Handler","usernames":["h"]},{"profileName":"Support User","usernames":["s"]}]}}'
        'valid|{"coverage":{"minimumPercent":78.5,"testClass":"ProjectCoverageTest","classNamePattern":"Project_%"}}'
        'valid|{"coverage":{"minimumPercent":78.5,"testClass":"ProjectCoverageTest","classNamePattern":"Project_%"}}'
        'valid|{"packageInstallKeyEnvironmentVariable":"TEAM-KEY","commandTimeouts":{"readMs":1000}}'
        'invalid|{"schemaVersion":2}'
        'invalid|{"defaultOrgAlias":null}'
        'invalid|{"scratchDurationDays":31}'
        'invalid|{"postSteps":["all"]}'
        'invalid|{"postSteps":["seed"]}'
        'invalid|{"customPostSteps":[{"name":"deploy","executable":"x"}]}'
        'invalid|{"customPostSteps":[{"name":"a","executable":"x"},{"name":"a","executable":"y"}]}'
        'invalid|{"customPostSteps":[{"name":"a","executable":"x","label":""}]}'
        'invalid|{"pool":{"use":"yes"}}'
        'invalid|{"commandTimeouts":{"readMs":0}}'
        'invalid|{"dependencySourcePolicy":{"requireLocalDirectories":"no"}}'
        'invalid|{"dummyUsers":{"profileName":"x"}}'
        'invalid|{"dummyUsers":{"file":"u.json","profileAssignments":[{"profileName":"Case Handler","usernames":["same"]},{"profileName":"Support User","usernames":["same"]}]}}'
        'invalid|{"dummyUsers":{"file":"u.json","permissionSetAssignments":[{"permissionSets":["P"],"usernames":[]}]}}'
        'invalid|{"coverage":{"minimumPercent":101}}'
        'invalid|{"coverage":{"testClass":12}}'
        'invalid|{"coverage":{"classNamePattern":""}}'
        'invalid|{"coverage":{"minimumPercent":101}}'
        'invalid|{"coverage":{"testClass":12}}'
        'invalid|{"coverage":{"classNamePattern":""}}'
    )
    local fixture expected json ts_line bash_result ts_result index=0
    local -a fixture_dirs=()

    for fixture in "${fixtures[@]}"; do
        new_project "parity-$index"
        write_config "${fixture#*|}"
        fixture_dirs+=("$PROJECT")
        index=$((index + 1))
    done

    ts_result="$(cd "$cli_dir" && ./node_modules/.bin/tsx -e "
        (async () => {
            const { loadProjectConfiguration } = await import('./src/domain/config.ts');
            for (const directory of process.argv.slice(1)) {
                console.log(await loadProjectConfiguration(directory).then(() => 'valid', () => 'invalid'));
            }
        })();
    " "${fixture_dirs[@]}" 2>&1)"

    index=0
    for fixture in "${fixtures[@]}"; do
        expected="${fixture%%|*}"
        json="${fixture#*|}"
        PROJECT="${fixture_dirs[$index]}"
        script --init-config --dry-run
        bash_result="valid"
        [[ "$EXIT_CODE" -ne 0 ]] && bash_result="invalid"
        ts_line="$(sed -n "$((index + 1))p" <<< "$ts_result")"
        [[ "$bash_result" == "$expected" ]] && pass || fail "bash says $bash_result for $json (expected $expected)"
        [[ "$ts_line" == "$expected" ]] && pass || fail "sf-project says ${ts_line:-nothing} for $json (expected $expected)"
        index=$((index + 1))
    done
}

test_package_version_update_previews_and_applies_with_backup() {
    new_project package-version-update
    cat > "$PROJECT/sfdx-project.json" <<'EOF_PROJECT'
{
    "packageDirectories": [
        {"path":"force-app","dependencies":[{"package":"pkg-one","versionNumber":"0.9.0.LATEST"}]},
        {"path":"another-package-dir","dependencies":[{"package":"pkg-one","versionNumber":"0.9.0.NEXT"}]}
    ],
    "packageAliases": {"pkg-one":"0Ho000000000001"}
}
EOF_PROJECT
    cp "$PROJECT/sfdx-project.json" "$WORK_DIR/package-version-original.json"

    script --check-versions
    assert_exit 0
    assert_contains "pkg-one: 0.9.0.LATEST -> 1.0.0.LATEST"
    assert_json "$PROJECT/sfdx-project.json" '.packageDirectories[0].dependencies[0].versionNumber' '"0.9.0.LATEST"'
    [[ ! -e "$PROJECT/sfdx-project.json.backup" ]] && pass || fail "preview created a backup"

    script --apply-project-versions
    assert_exit 0
    assert_json "$PROJECT/sfdx-project.json.backup" '.packageDirectories[0].dependencies[0].versionNumber' '"0.9.0.LATEST"'
    assert_json "$PROJECT/sfdx-project.json" '.packageDirectories[0].dependencies[0].versionNumber' '"1.0.0.LATEST"'
    assert_json "$PROJECT/sfdx-project.json" '.packageDirectories[1].dependencies[0].versionNumber' '"1.0.0.LATEST"'
}

test_coverage_check_runs_and_enforces_threshold() {
    new_project coverage-check
    script --coverage-check --alias coverage-org --coverage-package-id 04t-test --coverage-minimum 75 --coverage-test-class CoverageTest
    assert_exit 0
    assert_contains "Apex coverage: 80.00% (80 covered, 20 uncovered)"
    grep -Fq 'package install --target-org coverage-org --package 04t-test' "$SF_LOG" && pass || fail "coverage package install did not run"
    grep -Fq 'project deploy start --target-org coverage-org --source-dir force-app' "$SF_LOG" && pass || fail "coverage deploy did not run"
    grep -Fq 'apex run test --target-org coverage-org --tests CoverageTest' "$SF_LOG" && pass || fail "selected Apex test did not run"

    run_script env COVERAGE_RESULT=60 bash "$SCRIPT" --coverage-check --alias coverage-org --coverage-skip-install --coverage-skip-deploy --coverage-minimum 75
    run_script env COVERAGE_RESULT=60 COVERAGE_UNCOVERED=40 bash "$SCRIPT" --coverage-check --alias coverage-org --coverage-skip-install --coverage-skip-deploy --coverage-minimum 75
    assert_exit_nonzero
    assert_contains "below the required 75%"
}

test_coverage_check_dry_run_does_not_call_sf() {
    new_project coverage-dry-run
    script --coverage-check --alias coverage-org --coverage-package-id 04t-test --dry-run
    assert_exit 0
    assert_contains "apex run test"
    assert_contains "coverage"
    [[ ! -s "$SF_LOG" ]] && pass || fail "dry-run called sf"
}

ESC=$'\033['

assert_has_colour() {
    [[ "$OUTPUT" == *"$ESC"* ]] && pass || fail "expected ANSI colour codes in output"
}

assert_no_colour() {
    [[ "$OUTPUT" != *"$ESC"* ]] && pass || fail "expected no ANSI colour codes in output"
}

install_call_count() {
    grep -c '^package install -r' "$SF_LOG" || true
}

write_dependency_project() {
    local dependencies="" key_config="" package_name
    for package_name in "$@"; do
        dependencies+="${dependencies:+,}{\"package\":\"$package_name\",\"versionNumber\":\"1.0.0.LATEST\"}"
        key_config+="${key_config:+,}\"$package_name\":false"
    done
    printf '{"packageDirectories":[{"path":"force-app","dependencies":[%s]}],"packageKeyConfig":{%s}}\n' "$dependencies" "$key_config" > "$PROJECT/sfdx-project.json"
}

INSTALLED_FIXTURE='{"status":0,"result":[
    {"SubscriberPackageName":"lower-pkg","SubscriberPackageVersionNumber":"0.9.0.1","SubscriberPackageVersionId":"04tlower"},
    {"SubscriberPackageName":"equal-pkg","SubscriberPackageVersionNumber":"1.0.0.1","SubscriberPackageVersionId":"04t000000000001"},
    {"SubscriberPackageName":"higher-pkg","SubscriberPackageVersionNumber":"2.0.0.1","SubscriberPackageVersionId":"04thigher"}
]}'

test_non_terminal_output_has_no_colour() {
    new_project no-colour
    script --dry-run --post-steps deploy
    assert_exit 0
    assert_no_colour
}

test_force_color_and_color_flag_enable_colour() {
    new_project force-colour
    run_script env FORCE_COLOR=1 bash "$SCRIPT" --dry-run --post-steps none
    assert_exit 0
    assert_has_colour
    script --color --dry-run --post-steps none
    assert_has_colour
}

test_no_color_disables_colour_and_cli_flag_wins() {
    new_project no-color-env
    run_script env FORCE_COLOR=1 NO_COLOR=1 bash "$SCRIPT" --dry-run --post-steps none
    assert_no_colour
    run_script env FORCE_COLOR=1 bash "$SCRIPT" --no-color --dry-run --post-steps none
    assert_no_colour
    run_script env NO_COLOR=1 bash "$SCRIPT" --color --dry-run --post-steps none
    assert_has_colour
}

test_icons_follow_locale() {
    new_project icons
    run_script env LC_ALL=en_US.UTF-8 bash "$SCRIPT" --dry-run --post-steps none
    assert_contains "✔ Scratch org setup completed successfully."
    run_script env LC_ALL=C LC_CTYPE=C LANG=C bash "$SCRIPT" --dry-run --post-steps none
    assert_contains "+ Scratch org setup completed successfully."
    assert_not_contains "✔"
    assert_not_contains "▸"
}

test_phases_are_numbered_for_phases_that_run() {
    new_project phases
    script --dry-run --post-steps deploy
    assert_exit 0
    assert_contains "[1/3] Scratch org"
    assert_contains "[2/3] Packages"
    assert_contains "[3/3] Post-steps"

    script --post-steps-only --dry-run --alias cfg-org
    assert_exit 0
    assert_contains "[1/1] Post-steps"
    assert_not_contains "[1/3]"
}

test_package_loop_shows_progress_counter() {
    new_project package-progress
    write_dependency_project pkg-a pkg-b
    script --dry-run --post-steps none --skip-version-check
    assert_exit 0
    assert_contains "[1/2] pkg-a"
    assert_contains "[2/2] pkg-b"
}

test_post_steps_show_progress_and_list_unselected_once() {
    new_project post-step-progress
    write_config '{"defaultOrgAlias":"cfg-org","permissionSets":["P"],"communityName":"Portal","postSteps":["permsets","community"]}'
    script --post-steps-only --dry-run
    assert_exit 0
    assert_contains "[1/2] permsets"
    assert_contains "[2/2] community"
    assert_contains "Not selected: deploy, data"
    assert_not_contains "Skipping post step:"
}

test_package_install_retries_transient_errors() {
    new_project install-retry
    write_dependency_project pkg-a
    run_script env INSTALL_FAIL_TIMES=1 INSTALL_FAIL_COUNTER="$WORK_DIR/retry-counter" PACKAGE_INSTALL_RETRY_DELAY_SECONDS=0 \
        bash "$SCRIPT" --skip-org --alias cfg-org --post-steps none --skip-version-check
    assert_exit 0
    assert_contains "attempt 1/3"
    assert_contains "Installed pkg-a"
    [[ "$(install_call_count)" -eq 2 ]] && pass || fail "expected 2 install calls, got $(install_call_count)"
}

test_package_install_does_not_retry_other_errors_and_shows_cli_output() {
    new_project install-no-retry
    write_dependency_project pkg-a
    run_script env INSTALL_FAIL_TIMES=5 INSTALL_FAIL_COUNTER="$WORK_DIR/no-retry-counter" INSTALL_FAIL_MESSAGE="Error: INVALID_INSTALLATION_KEY" \
        PACKAGE_INSTALL_RETRY_DELAY_SECONDS=0 bash "$SCRIPT" --skip-org --alias cfg-org --post-steps none --skip-version-check
    assert_exit_nonzero
    assert_contains "INVALID_INSTALLATION_KEY"
    assert_contains "Failed to install package pkg-a"
    [[ "$(install_call_count)" -eq 1 ]] && pass || fail "expected 1 install call, got $(install_call_count)"
}

test_package_install_gives_up_after_max_attempts() {
    new_project install-max-attempts
    write_dependency_project pkg-a
    run_script env INSTALL_FAIL_TIMES=5 INSTALL_FAIL_COUNTER="$WORK_DIR/max-counter" PACKAGE_INSTALL_MAX_ATTEMPTS=2 \
        PACKAGE_INSTALL_RETRY_DELAY_SECONDS=0 bash "$SCRIPT" --skip-org --alias cfg-org --post-steps none --skip-version-check
    assert_exit_nonzero
    [[ "$(install_call_count)" -eq 2 ]] && pass || fail "expected 2 install calls, got $(install_call_count)"
}

test_successful_install_output_is_hidden_unless_verbose() {
    new_project install-verbose
    write_dependency_project pkg-a
    script --skip-org --alias cfg-org --post-steps none --skip-version-check
    assert_exit 0
    assert_not_contains "Successfully installed package from fake sf"
    script --skip-org --alias cfg-org --post-steps none --skip-version-check --verbose
    assert_exit 0
    assert_contains "Successfully installed package from fake sf"
}

test_update_packages_installs_updates_skips_and_never_downgrades() {
    new_project update-packages
    write_dependency_project missing-pkg lower-pkg equal-pkg higher-pkg
    run_script env INSTALLED_PACKAGES="$INSTALLED_FIXTURE" bash "$SCRIPT" --update-packages --alias cfg-org --skip-version-check
    assert_exit 0
    [[ "$(install_call_count)" -eq 2 ]] && pass || fail "expected 2 install calls, got $(install_call_count)"
    assert_contains "missing-pkg target=1.0.0.1"
    assert_contains "lower-pkg 0.9.0.1 -> 1.0.0.1"
    assert_contains "equal-pkg 1.0.0.1"
    assert_contains "higher-pkg installed=2.0.0.1 target=1.0.0.1"
    assert_contains "[4/4] higher-pkg"
}

test_package_plan_reports_without_installing() {
    new_project package-plan
    write_dependency_project missing-pkg lower-pkg equal-pkg higher-pkg
    run_script env INSTALLED_PACKAGES="$INSTALLED_FIXTURE" bash "$SCRIPT" --package-plan --alias cfg-org --skip-version-check
    assert_exit 0
    [[ "$(install_call_count)" -eq 0 ]] && pass || fail "package plan installed packages"
    assert_contains "would be installed"
    assert_contains "would be updated"
    assert_contains "would be skipped"
    assert_contains "lower-pkg would update 0.9.0.1 -> 1.0.0.1"
}

test_self_check_passes_without_mutating_orgs() {
    new_project self-check
    write_config '{"defaultOrgAlias":"cfg-org"}'
    script --self-check
    assert_exit 0
    assert_contains "Self-check completed successfully."
    assert_contains "Required commands"
    ! grep -Eq 'org create|org delete|deploy start|package install -r' "$SF_LOG" && pass || fail "self-check mutated an org: $(cat "$SF_LOG")"
}

test_self_check_fails_without_scratch_definition() {
    new_project self-check-missing-definition
    rm "$PROJECT/config/project-scratch-def.json"
    script --self-check
    assert_exit_nonzero
    assert_contains "project-scratch-def.json"
}

test_delete_org_only_dry_run_does_not_call_sf() {
    new_project delete-only
    script --delete-org-only --alias old-org --dry-run
    assert_exit 0
    assert_contains "Would run: sf org delete scratch --no-prompt --target-org old-org"
    [[ ! -s "$SF_LOG" ]] && pass || fail "dry-run called sf: $(cat "$SF_LOG")"
}

test_help_prints_usage_without_summary() {
    new_project help
    script --help
    assert_exit 0
    assert_contains "Usage:"
    assert_contains "--no-color"
    assert_contains "--verbose"
    assert_not_contains "Run summary"
}

test_settings_list_active_modes_on_one_line() {
    new_project active-modes
    script --post-steps-only --dry-run --alias cfg-org
    assert_exit 0
    assert_contains "Active modes"
    assert_contains "dry-run, post-steps-only"
}

test_run_summary_reports_success() {
    new_project summary-success
    script --dry-run --post-steps none
    assert_exit 0
    assert_contains "Run summary"
    assert_contains "SUCCESS"
    assert_contains "Duration"
}

test_run_summary_reports_failure_without_generic_installation_message() {
    new_project summary-failure
    script --post-steps-only --post-steps nope --dry-run --alias cfg-org
    assert_exit_nonzero
    assert_contains "FAILED (exit code 1)"
    assert_contains "Invalid post step: nope"
    assert_not_contains "Installation failed."
}

test_deploy_runs_before_source_tracking_reset() {
    new_project deploy-before-reset
    script --post-steps-only --post-steps deploy --alias cfg-org
    assert_exit 0
    local first_command
    first_command="$(grep -E '^project (deploy start|reset tracking)' "$SF_LOG" | head -1)"
    [[ "$first_command" == "project deploy start"* ]] && pass || fail "source tracking was reset before deploy: $(cat "$SF_LOG")"
    grep -q '^project reset tracking' "$SF_LOG" && pass || fail "source tracking was not reset after deploy"
}

sf_command_order() {
    grep -nE "^project ($1)" "$SF_LOG" | head -1 | cut -d: -f1
}

test_full_deploy_deletes_local_tracking_before_deploy() {
    new_project full-deploy
    script --post-steps-only --post-steps deploy --full-deploy --alias cfg-org
    assert_exit 0
    local delete_line deploy_line reset_line
    delete_line="$(sf_command_order 'delete tracking')"
    deploy_line="$(sf_command_order 'deploy start')"
    reset_line="$(sf_command_order 'reset tracking')"
    [[ -n "$delete_line" && -n "$deploy_line" && -n "$reset_line" ]] && pass || fail "missing tracking/deploy commands: $(cat "$SF_LOG")"
    (( delete_line < deploy_line && deploy_line < reset_line )) && pass || fail "expected delete tracking < deploy < reset: $(cat "$SF_LOG")"
    grep -Fq 'project delete tracking --target-org cfg-org --no-prompt' "$SF_LOG" && pass || fail "delete tracking did not target cfg-org"
}

test_full_deploy_dry_run_only_prints_commands() {
    new_project full-deploy-dry-run
    script --post-steps-only --post-steps deploy --full-deploy --alias cfg-org --dry-run
    assert_exit 0
    assert_contains "Would run: sf project delete tracking --target-org cfg-org --no-prompt"
    [[ ! -s "$SF_LOG" ]] && pass || fail "dry-run called sf: $(cat "$SF_LOG")"
}

test_redeploy_runs_only_a_full_deploy() {
    new_project redeploy
    write_config '{"defaultOrgAlias":"cfg-org","permissionSets":["P"],"postSteps":["deploy","permsets"]}'
    script --redeploy
    assert_exit 0
    grep -q '^project delete tracking --target-org cfg-org' "$SF_LOG" && pass || fail "redeploy did not delete tracking"
    grep -q '^project deploy start --target-org cfg-org' "$SF_LOG" && pass || fail "redeploy did not deploy"
    ! grep -Eq '^(org create|org delete|package install|org assign permset)' "$SF_LOG" && pass || fail "redeploy ran more than a deploy: $(cat "$SF_LOG")"
    assert_contains "full-deploy"
}

test_tracked_deploy_prints_full_deploy_hint() {
    new_project deploy-hint
    script --post-steps-only --post-steps deploy --alias cfg-org
    assert_exit 0
    assert_contains "--redeploy"
}

test_help_is_grouped_by_task() {
    new_project help-groups
    script --help
    assert_exit 0
    assert_contains "Common tasks"
    assert_contains "--redeploy"
    assert_contains "--full-deploy"
    assert_contains "What to run"
    assert_contains "Environment variables"
}

assert_no_org_mutations() {
    ! grep -Eq '^(sfp pool fetch|org delete|org create|project deploy|org assign|data import|community publish)' "$SF_LOG" && pass || fail "unexpected mutation: $(cat "$SF_LOG")"
}

assert_logged_arguments() {
    local expected
    expected="$(jq -cn --args '$ARGS.positional' -- "$@")"
    grep -Fxq "$expected" "$SF_ARG_LOG" && pass || fail "expected argument vector $expected; got: $(cat "$SF_ARG_LOG")"
}

test_pool_fetch_uses_config_and_preserves_argument_boundaries() {
    new_project pool-config
    write_config '{"defaultOrgAlias":"pool ø org","pool":{"use":true,"tag":"team ø pool","devHub":"NAV DevHub","fallbackToCreate":false}}'
    script --skip-packages --post-steps none
    assert_exit 0
    assert_logged_arguments sfp pool list --tag "team ø pool" -a --targetdevhubusername "NAV DevHub"
    assert_logged_arguments sfp pool fetch --tag "team ø pool" --targetdevhubusername "NAV DevHub" --alias "pool ø org" --setdefaultusername
    ! grep -Eq '^(org create|org delete|config get target-dev-hub)' "$SF_LOG" && pass || fail "fetch should not create/delete or resolve an explicit hub"
}

test_pool_resolves_default_devhub() {
    new_project pool-default-devhub
    run_script env DEFAULT_DEVHUB="NAV DevHub" bash "$SCRIPT" --use-pool --pool-tag dev --alias offline-org --skip-packages --post-steps none
    assert_exit 0
    assert_logged_arguments sf config get target-dev-hub --json
    assert_logged_arguments sfp pool list --tag dev -a --targetdevhubusername "NAV DevHub"
    assert_logged_arguments sfp pool fetch --tag dev --targetdevhubusername "NAV DevHub" --alias offline-org --setdefaultusername
}

test_pool_empty_and_unparseable_output_obey_fallback() {
    local pool_output fallback index=0
    for pool_output in 'Unused Scratch Orgs in the Pool: 0' 'Unrecognised pool output'; do
        for fallback in true false; do
            new_project "pool-fallback-$index-$fallback"
            write_config "{\"pool\":{\"use\":true,\"devHub\":\"offline-devhub\",\"fallbackToCreate\":$fallback}}"
            run_script env POOL_LIST_OUTPUT="$pool_output" bash "$SCRIPT" --skip-packages --post-steps none
            if [[ "$fallback" == true ]]; then
                assert_exit 0
                assert_contains "Falling back to normal scratch org creation."
                grep -q '^org create scratch ' "$SF_LOG" && pass || fail "fallback did not create an org"
            else
                assert_exit_nonzero
                assert_no_org_mutations
                if [[ "$index" == 0 ]]; then
                    assert_contains "No unused scratch orgs available in pool."
                else
                    assert_contains "Could not determine whether the scratch org pool has available orgs."
                fi
            fi
            ! grep -q '^sfp pool fetch ' "$SF_LOG" && pass || fail "unavailable pool was fetched"
        done
        index=$((index + 1))
    done
}

test_pool_command_failures_do_not_fall_back_to_create() {
    local command
    for command in list fetch; do
        new_project "pool-failed-$command"
        write_config '{"pool":{"use":true,"devHub":"offline-devhub","fallbackToCreate":true}}'
        if [[ "$command" == list ]]; then
            run_script env POOL_LIST_EXIT=17 bash "$SCRIPT" --skip-packages --post-steps none
        else
            run_script env POOL_FETCH_EXIT=19 bash "$SCRIPT" --skip-packages --post-steps none
        fi
        if [[ "$command" == list ]]; then assert_exit 17; else assert_exit 19; fi
        assert_contains "offline pool $command failure"
        assert_contains "Failed to $command"
        ! grep -Eq '^(org create|org delete)' "$SF_LOG" && pass || fail "pool failure fell back to create/delete"
    done
}

test_pool_dry_run_never_fetches_deletes_or_creates() {
    local pool_output index=0
    for pool_output in 'Unused Scratch Orgs in the Pool: 2' 'Unused Scratch Orgs in the Pool: 0' 'Unrecognised output'; do
        new_project "pool-dry-run-$index"
        write_config '{"pool":{"use":true,"devHub":"offline-devhub","fallbackToCreate":true}}'
        run_script env POOL_LIST_OUTPUT="$pool_output" bash "$SCRIPT" --dry-run --skip-packages --post-steps none
        assert_exit 0
        assert_no_org_mutations
        if [[ "$index" == 0 ]]; then
            assert_contains "Would run: sfp pool fetch"
        else
            assert_contains "Would run: sf org create scratch"
        fi
        index=$((index + 1))
    done
}

test_pool_environment_overrides_config_including_false() {
    new_project pool-env
    write_config '{"pool":{"use":false,"tag":"config-tag","devHub":"config-hub","fallbackToCreate":true}}'
    run_script env USE_POOL=true POOL_TAG="env ø tag" POOL_DEVHUB_USERNAME="env hub" FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY=false POOL_LIST_OUTPUT='Unused Scratch Orgs in the Pool: 0' bash "$SCRIPT" --skip-packages --post-steps none
    assert_exit_nonzero
    assert_logged_arguments sfp pool list --tag "env ø tag" -a --targetdevhubusername "env hub"
    assert_no_org_mutations

    new_project pool-env-false
    write_config '{"pool":{"use":true,"tag":"config-tag","devHub":"config-hub","fallbackToCreate":false}}'
    run_script env USE_POOL=false bash "$SCRIPT" --skip-packages --post-steps none
    assert_exit 0
    grep -q '^org create scratch ' "$SF_LOG" && pass || fail "explicit env false did not disable pool"
    ! grep -q '^sfp ' "$SF_LOG" && pass || fail "explicit env false still called sfp"

    new_project pool-env-fallback-true
    write_config '{"pool":{"use":true,"devHub":"config-hub","fallbackToCreate":false}}'
    run_script env FALLBACK_TO_SCRATCH_CREATE_IF_POOL_EMPTY=true POOL_LIST_OUTPUT='Unused Scratch Orgs in the Pool: 0' bash "$SCRIPT" --skip-packages --post-steps none
    assert_exit 0
    grep -q '^org create scratch ' "$SF_LOG" && pass || fail "env true did not override config fallback false"
}

test_pool_flags_override_environment_and_config() {
    new_project pool-flags
    write_config '{"pool":{"use":false,"tag":"config-tag","devHub":"config-hub","fallbackToCreate":false}}'
    run_script env USE_POOL=false POOL_TAG=env-tag POOL_DEVHUB_USERNAME=env-hub bash "$SCRIPT" --use-pool --pool-tag "flag ø tag" --pool-devhub "flag hub" --alias flag-org --skip-packages --post-steps none
    assert_exit 0
    assert_logged_arguments sfp pool list --tag "flag ø tag" -a --targetdevhubusername "flag hub"
    assert_logged_arguments sfp pool fetch --tag "flag ø tag" --targetdevhubusername "flag hub" --alias flag-org --setdefaultusername
}

test_custom_post_step_failure_preserves_error_and_exit_code() {
    new_project custom-failure
    write_config '{"postSteps":["fail"],"customPostSteps":[{"name":"fail","executable":"bash","arguments":["-c","echo custom-offline-error >&2; exit 29"]}]}'
    script --post-steps-only --alias offline-org
    assert_exit 29
    assert_contains "custom-offline-error"
    assert_contains 'Custom post step "fail" failed.'
}

test_custom_post_step_without_arguments() {
    new_project custom-empty-arguments
    write_config '{"postSteps":["seed"],"customPostSteps":[{"name":"seed","executable":"true"}]}'
    script --post-steps-only --alias offline-org
    assert_exit 0
}

test_spaces_and_non_ascii_are_preserved_in_paths_and_arguments() {
    new_project 'project ø with spaces'
    mkdir -p "$PROJECT/config ø" "$PROJECT/data ø" "$PROJECT/bin ø"
    cp "$PROJECT/config/project-scratch-def.json" "$PROJECT/config ø/scratch ø.json"
    echo '[]' > "$PROJECT/data ø/plan ø.json"
    cat > "$PROJECT/bin ø/capture ø" <<'EOF_CAPTURE'
#!/usr/bin/env bash
jq -cn --arg cwd "$PWD" --args '{cwd:$cwd,arguments:$ARGS.positional}' -- "$@" > 'custom-arguments.json'
EOF_CAPTURE
    chmod +x "$PROJECT/bin ø/capture ø"
    write_config '{"postSteps":["data","community","capture"],"dummyDataPlan":"data ø/plan ø.json","communityName":"Portal ø name","customPostSteps":[{"name":"capture","executable":"./bin ø/capture ø","arguments":["hello ø world","","--flag","two words"]}]}'
    cp "$PROJECT/sf-project.config.json" "$PROJECT/config ø/settings ø.json"
    script --config "$PROJECT/config ø/settings ø.json" --definition-file "$PROJECT/config ø/scratch ø.json" --project-file "$PROJECT/sfdx-project.json" --alias 'alias ø with spaces' --skip-packages
    assert_exit 0
    assert_logged_arguments sf org create scratch --set-default --definition-file "$PROJECT/config ø/scratch ø.json" --duration-days 14 --alias 'alias ø with spaces'
    assert_logged_arguments sf data import tree --target-org 'alias ø with spaces' --plan "$PROJECT/data ø/plan ø.json"
    assert_logged_arguments sf community publish --target-org 'alias ø with spaces' --name 'Portal ø name'
    assert_json "$PROJECT/custom-arguments.json" '.arguments' '["hello ø world","","--flag","two words"]'
    assert_json "$PROJECT/custom-arguments.json" '.cwd' "\"$PROJECT\""
}

test_builtin_post_step_failures_propagate() {
    local step command
    for step in deploy permsets data community; do
        new_project "post-failure-$step"
        mkdir -p "$PROJECT/data"
        echo '[]' > "$PROJECT/data/plan.json"
        write_config '{"permissionSets":["P"],"dummyDataPlan":"data/plan.json","communityName":"Offline Portal"}'
        case "$step" in
            deploy) command='project deploy start' ;;
            permsets) command='org assign permset' ;;
            data) command='data import tree' ;;
            community) command='community publish' ;;
        esac
        run_script env SF_FAIL_COMMAND="$command" bash "$SCRIPT" --post-steps-only --post-steps "$step" --alias offline-org
        assert_exit 23
        assert_contains "offline sf failure: $command"
        assert_contains "command failed"
        assert_not_contains "Scratch org setup completed successfully."
        ! grep -q '^project reset tracking' "$SF_LOG" && pass || fail "failed post-step still reset tracking"
    done
}

test_unknown_and_missing_options_are_rejected_before_cli_calls() {
    new_project invalid-options
    script --not-a-real-option
    assert_exit_nonzero
    assert_contains "Unknown argument: --not-a-real-option"
    local option
    for option in --alias --duration-days --definition-file --project-file --dependency-report --community-name --dummy-data-plan --permission-sets --config --post-steps --pool-tag --pool-devhub --keychain-service --keychain-account --coverage-package-id --coverage-minimum --coverage-test-class --coverage-class-pattern; do
        script "$option"
        assert_exit_nonzero
        assert_contains "Missing value for option: $option"
    done
    script --alias --dry-run
    assert_exit_nonzero
    assert_contains "Missing value for option: --alias"
    [[ ! -s "$SF_LOG" ]] && pass || fail "invalid options called a CLI"
}

test_invalid_duration_is_rejected() {
    new_project invalid-duration
    local duration
    for duration in 0 31 abc; do
        script --duration-days "$duration" --dry-run
        assert_exit_nonzero
        if [[ "$duration" == abc ]]; then
            assert_contains "Duration days must be a number"
        else
            assert_contains "Duration days must be an integer from 1 to 30"
        fi
    done
    [[ ! -s "$SF_LOG" ]] && pass || fail "invalid duration called a CLI"
}

test_invalid_config_booleans_and_empty_alias_or_tag_are_rejected() {
    new_project invalid-config-values
    local fixture key
    for fixture in 'pool.use|{"pool":{"use":"true"}}' 'pool.fallbackToCreate|{"pool":{"fallbackToCreate":"false"}}' 'dependencySourcePolicy.requireLocalDirectories|{"dependencySourcePolicy":{"requireLocalDirectories":"false"}}' 'defaultOrgAlias|{"defaultOrgAlias":""}' 'pool.tag|{"pool":{"tag":""}}'; do
        key="${fixture%%|*}"
        write_config "${fixture#*|}"
        script --dry-run
        assert_exit_nonzero
        assert_contains "$key must be"
    done
    write_config '{}'
    for key in --alias --pool-tag; do
        script "$key" ''
        assert_exit_nonzero
        assert_contains "Missing value for option: $key"
    done
    [[ ! -s "$SF_LOG" ]] && pass || fail "invalid values called a CLI"
}

test_rejected_exclusive_mode_combinations() {
    new_project exclusive-modes
    local first second
    for first in --init-config --delete-org-only --clear-dependency-sources-only --post-steps-only --check-versions --coverage-check; do
        case "$first" in
            --init-config) set -- --delete-org-only --update-packages --package-plan --clear-dependency-sources-only --self-check --post-steps-only ;;
            --delete-org-only) set -- --update-packages --package-plan ;;
            --clear-dependency-sources-only) set -- --refresh-dependency-sources --delete-org-only --update-packages --package-plan --self-check ;;
            --post-steps-only) set -- --delete-org-only --update-packages --package-plan --clear-dependency-sources-only ;;
            --check-versions) set -- --delete-org-only --update-packages --package-plan --clear-dependency-sources-only --self-check --post-steps-only ;;
            --coverage-check) set -- --check-versions --delete-org-only --update-packages --package-plan --clear-dependency-sources-only --self-check --post-steps-only ;;
        esac
        for second in "$@"; do
            script "$first" "$second" --dry-run
            assert_exit_nonzero
            assert_contains "cannot combine"
        done
    done
    script --force
    assert_exit_nonzero
    assert_contains "--force can only be used with --init-config."
    [[ ! -s "$SF_LOG" ]] && pass || fail "exclusive mode validation called a CLI"
}

test_script_has_no_repository_specific_values() {
    local pattern='crm-arbeidsforhold|Aa-registret|AAREG_|saksbehandler|brukerstotte|@nav\.no|NAV DevHub|platform-data-model'
    if grep -nEi "$pattern" "$SCRIPT"; then
        CURRENT_TEST="${FUNCNAME[0]}" fail "repository-specific values remain in the script"
    else
        pass
    fi
}

for test_name in $(declare -F | awk '{print $3}' | grep '^test_'); do
    CURRENT_TEST="$test_name"
    "$test_name"
done

echo ""
echo "Passed assertions: $PASSED"
echo "Failed assertions: $FAILED"
[[ "$FAILED" -eq 0 ]]
