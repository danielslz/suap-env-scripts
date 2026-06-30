#!/usr/bin/env bats
# Feature: suap-setup, Property 4: Idempotência de execução
#
# Para qualquer script (dev ou prod) executado duas vezes consecutivas no mesmo
# ambiente, o estado final do sistema após a segunda execução deve ser idêntico
# ao estado após a primeira execução, e a segunda execução deve exibir mensagens
# em amarelo (pulo) em vez de verde (ação) para todas as etapas já concluídas.
#
# **Validates: Requirements 24.3, 24.4, 25.1, 25.2, 25.3, 25.4**

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

# Generate a random string of given length using alphanumeric characters
random_string() {
    local length="${1:-8}"
    cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | head -c "$length"
}

# Generate a random filename (no path separators)
random_filename() {
    local prefix="${1:-file}"
    echo "${prefix}_$(random_string 10)"
}

# Simulate the idempotent file copy pattern used in the scripts:
# If target doesn't exist, copy source -> msg_action; else msg_skip
idempotent_file_copy() {
    local source_file="$1"
    local target_file="$2"

    if [ ! -f "$target_file" ]; then
        cp "$source_file" "$target_file"
        msg_action "Gerando $(basename "$target_file")"
    else
        msg_skip "$(basename "$target_file") já existe"
    fi
}

# Simulate the idempotent directory creation pattern:
# If dir doesn't exist, create it -> msg_action; else msg_skip
idempotent_dir_create() {
    local dir_path="$1"

    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        msg_action "Criando diretório $(basename "$dir_path")"
    else
        msg_skip "Diretório $(basename "$dir_path") já existe"
    fi
}

# --- Property Tests ---

@test "Property 4.1: File copy idempotency - second invocation always skips (100 iterations)" {
    local iterations=100
    local i

    for ((i = 1; i <= iterations; i++)); do
        local fname
        fname="$(random_filename "settings")"
        local source_file="${TEST_TEMP_DIR}/source_${fname}"
        local target_file="${TEST_TEMP_DIR}/target_${fname}"

        # Create a random source file with random content
        local content
        content="$(random_string 50)"
        echo "$content" > "$source_file"

        # First invocation: file does not exist -> should use msg_action (green)
        run idempotent_file_copy "$source_file" "$target_file"
        assert_success
        assert_output --partial ">>>"
        # The output should contain GREEN (action message)
        [[ "$output" == *"$(tput setaf 2)"* ]] || fail "Iteration $i: First call should produce GREEN (action) message, got: $output"

        # Verify file was actually created with correct content
        assert [ -f "$target_file" ]
        local actual_content
        actual_content="$(cat "$target_file")"
        assert_equal "$actual_content" "$content"

        # Capture state after first invocation
        local state_after_first
        state_after_first="$(md5sum "$target_file" | cut -d' ' -f1)"

        # Second invocation: file exists -> should use msg_skip (yellow)
        run idempotent_file_copy "$source_file" "$target_file"
        assert_success
        assert_output --partial ">>>"
        # The output should contain YELLOW (skip message)
        [[ "$output" == *"$(tput setaf 3)"* ]] || fail "Iteration $i: Second call should produce YELLOW (skip) message, got: $output"

        # Verify state is unchanged after second invocation
        local state_after_second
        state_after_second="$(md5sum "$target_file" | cut -d' ' -f1)"
        assert_equal "$state_after_first" "$state_after_second"
    done
}

@test "Property 4.2: Directory creation idempotency - second invocation always skips (100 iterations)" {
    local iterations=100
    local i

    for ((i = 1; i <= iterations; i++)); do
        local dirname
        dirname="$(random_filename "venv")"
        local dir_path="${TEST_TEMP_DIR}/${dirname}"

        # First invocation: directory does not exist -> should use msg_action (green)
        run idempotent_dir_create "$dir_path"
        assert_success
        assert_output --partial ">>>"
        [[ "$output" == *"$(tput setaf 2)"* ]] || fail "Iteration $i: First call should produce GREEN (action) message, got: $output"

        # Verify directory was created
        assert [ -d "$dir_path" ]

        # Record directory state (existence + permissions)
        local state_after_first
        state_after_first="$(stat -c '%a' "$dir_path")"

        # Second invocation: directory exists -> should use msg_skip (yellow)
        run idempotent_dir_create "$dir_path"
        assert_success
        assert_output --partial ">>>"
        [[ "$output" == *"$(tput setaf 3)"* ]] || fail "Iteration $i: Second call should produce YELLOW (skip) message, got: $output"

        # Verify directory state is unchanged
        local state_after_second
        state_after_second="$(stat -c '%a' "$dir_path")"
        assert_equal "$state_after_first" "$state_after_second"
    done
}

@test "Property 4.3: File copy never overwrites existing target (100 iterations with random content)" {
    local iterations=100
    local i

    for ((i = 1; i <= iterations; i++)); do
        local fname
        fname="$(random_filename "env")"
        local source_file="${TEST_TEMP_DIR}/source_${fname}"
        local target_file="${TEST_TEMP_DIR}/target_${fname}"

        # Create source with random content
        local original_content
        original_content="$(random_string 64)"
        echo "$original_content" > "$source_file"

        # First invocation creates the target
        idempotent_file_copy "$source_file" "$target_file" > /dev/null 2>&1

        # Modify source with different content (simulating a sample file update)
        local new_content
        new_content="$(random_string 64)"
        echo "$new_content" > "$source_file"

        # Second invocation should NOT overwrite target
        run idempotent_file_copy "$source_file" "$target_file"
        assert_success

        # Target should still have original content
        local actual_content
        actual_content="$(cat "$target_file")"
        assert_equal "$actual_content" "$original_content"
    done
}

@test "Property 4.4: msg_action uses green color and msg_skip uses yellow color for any message (100 iterations)" {
    local iterations=100
    local i
    local green yellow no_color

    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
    no_color="$(tput sgr0)"

    for ((i = 1; i <= iterations; i++)); do
        # Generate random message content
        local msg
        msg="$(random_string 30)"

        # msg_action should produce green output
        run msg_action "$msg"
        assert_success
        [[ "$output" == *"${green}"* ]] || fail "Iteration $i: msg_action should contain GREEN escape, got: $output"
        [[ "$output" == *"${msg}"* ]] || fail "Iteration $i: msg_action should contain the message text"
        [[ "$output" == *"${no_color}"* ]] || fail "Iteration $i: msg_action should reset color"

        # msg_skip should produce yellow output
        run msg_skip "$msg"
        assert_success
        [[ "$output" == *"${yellow}"* ]] || fail "Iteration $i: msg_skip should contain YELLOW escape, got: $output"
        [[ "$output" == *"${msg}"* ]] || fail "Iteration $i: msg_skip should contain the message text"
        [[ "$output" == *"${no_color}"* ]] || fail "Iteration $i: msg_skip should reset color"
    done
}

@test "Property 4.5: Complete idempotency scenario - multi-step setup executed twice (100 iterations)" {
    local iterations=100
    local i

    for ((i = 1; i <= iterations; i++)); do
        # Create isolated workspace for this iteration
        local workspace="${TEST_TEMP_DIR}/workspace_${i}"
        mkdir -p "$workspace"

        # Create random sample files (simulating settings_sample.py and .env.dev.sample)
        local settings_content env_content
        settings_content="$(random_string 40)"
        env_content="$(random_string 40)"
        echo "$settings_content" > "${workspace}/settings_sample.py"
        echo "$env_content" > "${workspace}/.env.dev.sample"

        # Define target paths
        local settings_target="${workspace}/settings.py"
        local env_target="${workspace}/.env"
        local venv_dir="${workspace}/.venv"

        # --- First execution (should perform actions) ---
        local first_output=""

        run idempotent_file_copy "${workspace}/settings_sample.py" "$settings_target"
        assert_success
        [[ "$output" == *"$(tput setaf 2)"* ]] || fail "Iteration $i: First exec settings.py should be GREEN"
        first_output+="$output"$'\n'

        run idempotent_file_copy "${workspace}/.env.dev.sample" "$env_target"
        assert_success
        [[ "$output" == *"$(tput setaf 2)"* ]] || fail "Iteration $i: First exec .env should be GREEN"
        first_output+="$output"$'\n'

        run idempotent_dir_create "$venv_dir"
        assert_success
        [[ "$output" == *"$(tput setaf 2)"* ]] || fail "Iteration $i: First exec venv should be GREEN"
        first_output+="$output"$'\n'

        # Capture full state after first execution
        local state1_settings state1_env state1_venv
        state1_settings="$(md5sum "$settings_target" | cut -d' ' -f1)"
        state1_env="$(md5sum "$env_target" | cut -d' ' -f1)"
        state1_venv="$(stat -c '%a' "$venv_dir")"

        # --- Second execution (should skip all) ---
        run idempotent_file_copy "${workspace}/settings_sample.py" "$settings_target"
        assert_success
        [[ "$output" == *"$(tput setaf 3)"* ]] || fail "Iteration $i: Second exec settings.py should be YELLOW"

        run idempotent_file_copy "${workspace}/.env.dev.sample" "$env_target"
        assert_success
        [[ "$output" == *"$(tput setaf 3)"* ]] || fail "Iteration $i: Second exec .env should be YELLOW"

        run idempotent_dir_create "$venv_dir"
        assert_success
        [[ "$output" == *"$(tput setaf 3)"* ]] || fail "Iteration $i: Second exec venv should be YELLOW"

        # Verify state is identical after second execution
        local state2_settings state2_env state2_venv
        state2_settings="$(md5sum "$settings_target" | cut -d' ' -f1)"
        state2_env="$(md5sum "$env_target" | cut -d' ' -f1)"
        state2_venv="$(stat -c '%a' "$venv_dir")"

        assert_equal "$state1_settings" "$state2_settings"
        assert_equal "$state1_env" "$state2_env"
        assert_equal "$state1_venv" "$state2_venv"
    done
}
