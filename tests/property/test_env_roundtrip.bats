#!/usr/bin/env bats
# Feature: suap-setup, Property 1: Round-trip do arquivo .env
#
# Para qualquer conjunto de pares chave=valor válidos (sem caracteres especiais
# de shell não-escapados), escrever esses pares no arquivo .env e depois
# carregá-los com load_env_file() deve resultar em variáveis de shell com
# exatamente os mesmos valores originais.
#
# **Validates: Requirements 1.2, 1.3, 1.4, 1.5, 4.1, 4.3, 4.5**

setup() {
    load '../test_helper/common-setup'
    TEST_TEMP_DIR="$(mktemp -d)"

    # Source common.sh with TERM set to support tput
    export TERM=xterm
    source "$COMMON_SH"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

# --- Helper Functions ---

# Generate a random alphanumeric string of given length
random_string() {
    local length="${1:-8}"
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

# Generate a random key name (starts with letter, alphanumeric + underscore)
random_key() {
    local prefix
    prefix="$(cat /dev/urandom | tr -dc 'A-Z' | head -c 1)"
    local suffix
    suffix="$(cat /dev/urandom | tr -dc 'A-Z0-9_' | head -c 7)"
    echo "${prefix}${suffix}"
}

# Generate a random simple value (alphanumeric, dots, slashes, hyphens - no shell special chars)
random_value() {
    local length="${1:-12}"
    cat /dev/urandom | tr -dc 'a-zA-Z0-9/._-' | head -c "$length"
}

# --- Property Tests ---

@test "Property 1.1: Round-trip of random key=value pairs via load_env_file (100 iterations)" {
    local iterations=100
    local i

    for ((i = 1; i <= iterations; i++)); do
        # Generate a random number of key=value pairs (1 to 5)
        local num_pairs=$(( (RANDOM % 5) + 1 ))
        local env_file="${TEST_TEMP_DIR}/env_${i}"
        local -a keys=()
        local -a values=()

        # Generate random pairs and write to .env file
        > "$env_file"
        local j
        for ((j = 0; j < num_pairs; j++)); do
            local gen_key
            gen_key="TEST_$(random_key)_${i}_${j}"
            local gen_val
            gen_val="$(random_value)"
            keys+=("$gen_key")
            values+=("$gen_val")
            echo "${gen_key}=${gen_val}" >> "$env_file"
        done

        # Load the env file using load_env_file
        load_env_file "$env_file"

        # Verify each variable matches the original value
        for ((j = 0; j < num_pairs; j++)); do
            local actual_value
            actual_value="${!keys[$j]}"
            if [ "$actual_value" != "${values[$j]}" ]; then
                fail "Iteration $i, pair $j: Expected '${keys[$j]}=${values[$j]}' but got '${keys[$j]}=${actual_value}'"
            fi
        done

        # Unset variables to avoid pollution between iterations
        for ((j = 0; j < num_pairs; j++)); do
            unset "${keys[$j]}"
        done
    done
}

@test "Property 1.2: Round-trip preserves values with dots, slashes and hyphens (100 iterations)" {
    local iterations=100
    local i

    for ((i = 1; i <= iterations; i++)); do
        local env_file="${TEST_TEMP_DIR}/env_paths_${i}"
        local var_name="PATH_VAR_${i}"
        # Generate path-like values with slashes, dots, and hyphens
        local segment1 segment2 segment3
        segment1="$(random_string 5)"
        segment2="$(random_string 4)"
        segment3="$(random_string 6)"
        local expected_val="/opt/${segment1}/${segment2}-${segment3}.d"

        echo "${var_name}=${expected_val}" > "$env_file"

        load_env_file "$env_file"

        local actual_value="${!var_name}"
        if [ "$actual_value" != "$expected_val" ]; then
            fail "Iteration $i: Expected '${var_name}=${expected_val}' but got '${var_name}=${actual_value}'"
        fi

        unset "$var_name"
    done
}

@test "Property 1.3: Round-trip ignores comments and empty lines (100 iterations)" {
    local iterations=100
    local i

    for ((i = 1; i <= iterations; i++)); do
        local env_file="${TEST_TEMP_DIR}/env_comments_${i}"
        local var_name="COMMENT_TEST_${i}"
        local expected_val
        expected_val="$(random_value 10)"

        # Write env file with random comments and blank lines interspersed
        {
            echo "# This is a comment $(random_string 10)"
            echo ""
            echo "  # Indented comment"
            echo "${var_name}=${expected_val}"
            echo ""
            echo "# Another trailing comment"
        } > "$env_file"

        load_env_file "$env_file"

        local actual_value="${!var_name}"
        if [ "$actual_value" != "$expected_val" ]; then
            fail "Iteration $i: Expected '${var_name}=${expected_val}' but got '${var_name}=${actual_value}'"
        fi

        unset "$var_name"
    done
}

@test "Property 1.4: Round-trip with variable expansion in values (100 iterations)" {
    local iterations=100
    local i

    for ((i = 1; i <= iterations; i++)); do
        local env_file="${TEST_TEMP_DIR}/env_expand_${i}"
        local base_key="BASE_${i}"
        local derived_key="DERIVED_${i}"
        local base_value
        base_value="/opt/$(random_string 6)"

        # Write env with a base variable and a derived one using ${VAR} expansion
        {
            echo "${base_key}=${base_value}"
            echo "${derived_key}=\${${base_key}}/subdir"
        } > "$env_file"

        load_env_file "$env_file"

        local actual_base="${!base_key}"
        local actual_derived="${!derived_key}"
        local expected_derived="${base_value}/subdir"

        if [ "$actual_base" != "$base_value" ]; then
            fail "Iteration $i: Base - Expected '${base_value}' but got '${actual_base}'"
        fi

        if [ "$actual_derived" != "$expected_derived" ]; then
            fail "Iteration $i: Derived - Expected '${expected_derived}' but got '${actual_derived}'"
        fi

        unset "$base_key" "$derived_key"
    done
}
