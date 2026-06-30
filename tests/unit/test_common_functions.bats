#!/usr/bin/env bats
# tests/unit/test_common_functions.bats
# Testes unitários para funções de output e utilitários de lib/common.sh
# Validates: Requirements 25.1, 25.2, 25.3, 25.4

setup() {
    load '../test_helper/common-setup'

    # Necessário para tput funcionar em ambiente de teste
    export TERM=xterm

    # Source da biblioteca sob teste
    source "$COMMON_SH"

    # Diretório temporário para mocks
    TEST_TEMP_DIR="$(mktemp -d)"
    export PATH="${TEST_TEMP_DIR}:${PATH}"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

# ============================================================
# Testes de msg_action()
# ============================================================

@test "msg_action() exibe mensagem com prefixo '>>> '" {
    run msg_action "Instalando pacotes"
    assert_success
    assert_output --partial ">>> Instalando pacotes"
}

@test "msg_action() contém código de cor verde (tput setaf 2)" {
    local green
    green=$(tput setaf 2)
    run msg_action "Ação teste"
    assert_success
    assert_output --partial "${green}"
}

@test "msg_action() contém reset de cor (tput sgr0)" {
    local no_color
    no_color=$(tput sgr0)
    run msg_action "Ação teste"
    assert_success
    assert_output --partial "${no_color}"
}

# ============================================================
# Testes de msg_skip()
# ============================================================

@test "msg_skip() exibe mensagem com prefixo '>>> '" {
    run msg_skip "Etapa já concluída"
    assert_success
    assert_output --partial ">>> Etapa já concluída"
}

@test "msg_skip() contém código de cor amarela (tput setaf 3)" {
    local yellow
    yellow=$(tput setaf 3)
    run msg_skip "Pulo teste"
    assert_success
    assert_output --partial "${yellow}"
}

@test "msg_skip() contém reset de cor (tput sgr0)" {
    local no_color
    no_color=$(tput sgr0)
    run msg_skip "Pulo teste"
    assert_success
    assert_output --partial "${no_color}"
}

# ============================================================
# Testes de msg_error()
# ============================================================

@test "msg_error() exibe mensagem com prefixo 'ERRO: '" {
    run msg_error "Falha na operação"
    assert_success
    assert_output --partial "ERRO: Falha na operação"
}

@test "msg_error() contém código de cor vermelha (tput setaf 1)" {
    local red
    red=$(tput setaf 1)
    run msg_error "Erro teste"
    assert_success
    assert_output --partial "${red}"
}

@test "msg_error() contém reset de cor (tput sgr0)" {
    local no_color
    no_color=$(tput sgr0)
    run msg_error "Erro teste"
    assert_success
    assert_output --partial "${no_color}"
}

# ============================================================
# Testes de is_pkg_installed() - Debian (dpkg)
# ============================================================

@test "is_pkg_installed() retorna 0 para pacote instalado (deb)" {
    export DISTRO_TYPE="deb"

    # Mock dpkg -l retornando pacote instalado
    cat > "${TEST_TEMP_DIR}/dpkg" << 'MOCK'
#!/bin/bash
echo "ii  curl 7.88.1-10+deb12u5 amd64 command line tool"
MOCK
    chmod +x "${TEST_TEMP_DIR}/dpkg"

    run is_pkg_installed "curl"
    assert_success
}

@test "is_pkg_installed() retorna 1 para pacote não instalado (deb)" {
    export DISTRO_TYPE="deb"

    # Mock dpkg -l retornando lista sem o pacote
    cat > "${TEST_TEMP_DIR}/dpkg" << 'MOCK'
#!/bin/bash
echo "ii  vim 9.0.1378 amd64 Vi IMproved"
MOCK
    chmod +x "${TEST_TEMP_DIR}/dpkg"

    run is_pkg_installed "curl"
    assert_failure
}

@test "is_pkg_installed() retorna 1 quando dpkg não lista nada (deb)" {
    export DISTRO_TYPE="deb"

    # Mock dpkg -l retornando saída vazia
    cat > "${TEST_TEMP_DIR}/dpkg" << 'MOCK'
#!/bin/bash
echo ""
MOCK
    chmod +x "${TEST_TEMP_DIR}/dpkg"

    run is_pkg_installed "pacote-inexistente"
    assert_failure
}

# ============================================================
# Testes de is_pkg_installed() - RPM
# ============================================================

@test "is_pkg_installed() retorna 0 para pacote instalado (rpm)" {
    export DISTRO_TYPE="rpm"

    # Mock rpm -q retornando sucesso
    cat > "${TEST_TEMP_DIR}/rpm" << 'MOCK'
#!/bin/bash
if [ "$1" = "-q" ] && [ "$2" = "curl" ]; then
    echo "curl-7.76.1-26.el9.x86_64"
    exit 0
fi
exit 1
MOCK
    chmod +x "${TEST_TEMP_DIR}/rpm"

    run is_pkg_installed "curl"
    assert_success
}

@test "is_pkg_installed() retorna 1 para pacote não instalado (rpm)" {
    export DISTRO_TYPE="rpm"

    # Mock rpm -q retornando falha
    cat > "${TEST_TEMP_DIR}/rpm" << 'MOCK'
#!/bin/bash
echo "package pacote-inexistente is not installed"
exit 1
MOCK
    chmod +x "${TEST_TEMP_DIR}/rpm"

    run is_pkg_installed "pacote-inexistente"
    assert_failure
}

# ============================================================
# Testes de check_docker_available() - Sucesso
# ============================================================

@test "check_docker_available() retorna sucesso quando docker e compose estão disponíveis" {
    # Mock docker
    cat > "${TEST_TEMP_DIR}/docker" << 'MOCK'
#!/bin/bash
if [ "$1" = "compose" ] && [ "$2" = "version" ]; then
    echo "Docker Compose version v2.24.5"
    exit 0
fi
exit 0
MOCK
    chmod +x "${TEST_TEMP_DIR}/docker"

    run check_docker_available
    assert_success
}

# ============================================================
# Testes de check_docker_available() - Falha
# ============================================================

@test "check_docker_available() falha quando docker não está instalado" {
    # Criar um PATH restrito que contém tput mas não docker
    local restricted_bin="${TEST_TEMP_DIR}/restricted_bin"
    mkdir -p "$restricted_bin"

    # Copiar apenas tput (necessário para cores)
    local tput_path
    tput_path="$(command -v tput)"
    cp "$tput_path" "$restricted_bin/"

    # Executar check_docker_available em subshell com PATH restrito (sem docker)
    run bash -c "
        export TERM=xterm
        export PATH='${restricted_bin}'
        source '${COMMON_SH}'
        check_docker_available
    "
    assert_failure
    assert_output --partial "ERRO:"
}

@test "check_docker_available() falha quando docker compose não está disponível" {
    # Mock docker que falha em 'compose version'
    cat > "${TEST_TEMP_DIR}/docker" << 'MOCK'
#!/bin/bash
if [ "$1" = "compose" ] && [ "$2" = "version" ]; then
    exit 1
fi
exit 0
MOCK
    chmod +x "${TEST_TEMP_DIR}/docker"

    run check_docker_available
    assert_failure
    assert_output --partial "ERRO:"
}
