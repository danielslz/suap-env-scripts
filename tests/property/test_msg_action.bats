#!/usr/bin/env bats
# Feature: suap-setup, Property 8: Mensagens de progresso em verde para todos os scripts
#
# Para cada script do projeto, deve existir ao menos uma chamada a msg_action(),
# garantindo que o usuário recebe feedback visual em verde durante a execução.
# Esta propriedade verifica estaticamente (via grep) a presença de msg_action em
# cada script listado.
#
# **Validates: Requirements 25.5, 25.6, 25.7, 25.8, 25.9**

setup() {
    load '../test_helper/common-setup'
}

# --- Helper ---

# Array de scripts que DEVEM conter msg_action
declare -a SCRIPTS_WITH_MSG_ACTION=(
    "deb/install-redis.sh"
    "rpm/install-redis.sh"
    "deb/install-nginx.sh"
    "rpm/install-nginx.sh"
    "docker/dev/docker-setup.sh"
    "docker/prod/docker-setup.sh"
    "setup.sh"
    "deb/suap-dev.sh"
    "rpm/suap-dev.sh"
    "deb/suap-prod.sh"
    "rpm/suap-prod.sh"
)

# --- Property Tests ---

@test "Property 8: Todos os scripts contêm ao menos uma chamada a msg_action" {
    local failures=()
    local script

    for script in "${SCRIPTS_WITH_MSG_ACTION[@]}"; do
        local full_path="${PROJECT_ROOT}/${script}"

        # Verificar que o arquivo existe
        if [ ! -f "$full_path" ]; then
            failures+=("${script}: arquivo não encontrado")
            continue
        fi

        # Verificar presença de msg_action (chamada de função)
        if ! grep -q 'msg_action' "$full_path"; then
            failures+=("${script}: não contém chamada a msg_action")
        fi
    done

    if [ ${#failures[@]} -gt 0 ]; then
        local msg="Scripts sem msg_action:\n"
        for f in "${failures[@]}"; do
            msg+="  - ${f}\n"
        done
        fail "$(echo -e "$msg")"
    fi
}

@test "Property 8.1: Cada script de instalação Redis usa msg_action para progresso" {
    local -a redis_scripts=("deb/install-redis.sh" "rpm/install-redis.sh")
    local script

    for script in "${redis_scripts[@]}"; do
        local full_path="${PROJECT_ROOT}/${script}"
        [ -f "$full_path" ] || fail "${script}: arquivo não encontrado"

        local count
        count=$(grep -c 'msg_action' "$full_path")
        [ "$count" -ge 1 ] || fail "${script}: esperado >= 1 chamada(s) a msg_action, encontrado ${count}"
    done
}

@test "Property 8.2: Cada script de instalação Nginx usa msg_action para progresso" {
    local -a nginx_scripts=("deb/install-nginx.sh" "rpm/install-nginx.sh")
    local script

    for script in "${nginx_scripts[@]}"; do
        local full_path="${PROJECT_ROOT}/${script}"
        [ -f "$full_path" ] || fail "${script}: arquivo não encontrado"

        local count
        count=$(grep -c 'msg_action' "$full_path")
        [ "$count" -ge 1 ] || fail "${script}: esperado >= 1 chamada(s) a msg_action, encontrado ${count}"
    done
}

@test "Property 8.3: Cada script Docker usa msg_action para progresso" {
    local -a docker_scripts=("docker/dev/docker-setup.sh" "docker/prod/docker-setup.sh")
    local script

    for script in "${docker_scripts[@]}"; do
        local full_path="${PROJECT_ROOT}/${script}"
        [ -f "$full_path" ] || fail "${script}: arquivo não encontrado"

        local count
        count=$(grep -c 'msg_action' "$full_path")
        [ "$count" -ge 1 ] || fail "${script}: esperado >= 1 chamada(s) a msg_action, encontrado ${count}"
    done
}

@test "Property 8.4: O wrapper setup.sh usa msg_action para progresso" {
    local full_path="${PROJECT_ROOT}/setup.sh"
    [ -f "$full_path" ] || fail "setup.sh: arquivo não encontrado"

    local count
    count=$(grep -c 'msg_action' "$full_path")
    [ "$count" -ge 1 ] || fail "setup.sh: esperado >= 1 chamada(s) a msg_action, encontrado ${count}"
}

@test "Property 8.5: Cada script de desenvolvimento usa msg_action para progresso" {
    local -a dev_scripts=("deb/suap-dev.sh" "rpm/suap-dev.sh")
    local script

    for script in "${dev_scripts[@]}"; do
        local full_path="${PROJECT_ROOT}/${script}"
        [ -f "$full_path" ] || fail "${script}: arquivo não encontrado"

        local count
        count=$(grep -c 'msg_action' "$full_path")
        [ "$count" -ge 1 ] || fail "${script}: esperado >= 1 chamada(s) a msg_action, encontrado ${count}"
    done
}

@test "Property 8.6: Cada script de produção usa msg_action para progresso" {
    local -a prod_scripts=("deb/suap-prod.sh" "rpm/suap-prod.sh")
    local script

    for script in "${prod_scripts[@]}"; do
        local full_path="${PROJECT_ROOT}/${script}"
        [ -f "$full_path" ] || fail "${script}: arquivo não encontrado"

        local count
        count=$(grep -c 'msg_action' "$full_path")
        [ "$count" -ge 1 ] || fail "${script}: esperado >= 1 chamada(s) a msg_action, encontrado ${count}"
    done
}
