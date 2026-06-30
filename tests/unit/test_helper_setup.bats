#!/usr/bin/env bats
# tests/unit/test_helper_setup.bats - Valida que o helper compartilhado funciona

setup() {
    load '../test_helper/common-setup'
}

@test "PROJECT_ROOT aponta para a raiz do projeto" {
    assert [ -f "$PROJECT_ROOT/setup.sh" ]
}

@test "LIB_DIR aponta para o diretório lib/" {
    assert [ -d "$LIB_DIR" ]
}

@test "COMMON_SH aponta para lib/common.sh" {
    assert [ -f "$COMMON_SH" ]
}

@test "bats-assert está disponível (assert_success)" {
    run true
    assert_success
}

@test "bats-assert está disponível (assert_output)" {
    run echo "hello"
    assert_output "hello"
}

@test "bats-assert está disponível (assert_line)" {
    run printf "line1\nline2\n"
    assert_line --index 0 "line1"
    assert_line --index 1 "line2"
}
