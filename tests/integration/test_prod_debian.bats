#!/usr/bin/env bats
# tests/integration/test_prod_debian.bats
# Testes de integração: fluxo de produção completo em Debian
# Executado dentro de container Docker (Dockerfile.debian)

setup() {
    load '../test_helper/common-setup'

    # Diretório temporário para simulação do ambiente
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR

    # Configurar variáveis de ambiente para o teste
    export HOME="${TEST_TEMP_DIR}/home"
    mkdir -p "${HOME}"

    # Simular .env para os testes
    export TEST_ENV_FILE="${TEST_TEMP_DIR}/.env"
}

teardown() {
    rm -rf "${TEST_TEMP_DIR}"
}

# --- Testes do ambiente para produção Debian ---

@test "[debian-prod] deb/suap-prod.sh existe e é executável" {
    [ -f "${PROJECT_ROOT}/deb/suap-prod.sh" ]
    [ -x "${PROJECT_ROOT}/deb/suap-prod.sh" ]
}

@test "[debian-prod] script de produção exige root" {
    # Executar como não-root deve falhar
    if [ "$(id -u)" -eq 0 ]; then
        skip "Teste executando como root - não é possível testar rejeição"
    fi

    run bash -c "source '${PROJECT_ROOT}/lib/common.sh' && load_env_file '${TEST_ENV_FILE}' && bash '${PROJECT_ROOT}/deb/suap-prod.sh'"
    assert_failure
}

@test "[debian-prod] detect_distro() funciona em ambiente Debian de produção" {
    run bash -c "source '${PROJECT_ROOT}/lib/common.sh' && detect_distro && echo \${DISTRO_TYPE}"
    assert_success
    assert_output "deb"
}

@test "[debian-prod] get_supervisor_conf_dir() retorna caminho Debian" {
    run bash -c "source '${PROJECT_ROOT}/lib/common.sh' && DISTRO_TYPE=deb && get_supervisor_conf_dir"
    assert_success
    assert_output "/etc/supervisor/conf.d"
}

@test "[debian-prod] get_nginx_conf_path() retorna caminho Debian" {
    run bash -c "source '${PROJECT_ROOT}/lib/common.sh' && DISTRO_TYPE=deb && get_nginx_conf_path"
    assert_success
    assert_output "/etc/nginx/sites-available/suap"
}

# --- Testes de configurações de produção ---

@test "[debian-prod] arquivos de configuração do Supervisor existem" {
    [ -f "${PROJECT_ROOT}/supervisor/suap.conf" ]
    [ -f "${PROJECT_ROOT}/supervisor/run_suap.sh" ]
    [ -f "${PROJECT_ROOT}/supervisor/celery_worker.conf" ]
    [ -f "${PROJECT_ROOT}/supervisor/run_celery_worker.sh" ]
    [ -f "${PROJECT_ROOT}/supervisor/celery_beat.conf" ]
    [ -f "${PROJECT_ROOT}/supervisor/run_celery_beat.sh" ]
    [ -f "${PROJECT_ROOT}/supervisor/celery_flower.conf" ]
    [ -f "${PROJECT_ROOT}/supervisor/run_celery_flower.sh" ]
}

@test "[debian-prod] configuração Nginx existe" {
    [ -f "${PROJECT_ROOT}/nginx/suap" ]
}

@test "[debian-prod] configuração Nginx contém upstream com least_conn" {
    run grep "least_conn" "${PROJECT_ROOT}/nginx/suap"
    assert_success
}

@test "[debian-prod] configuração Nginx contém client_max_body_size" {
    run grep "client_max_body_size" "${PROJECT_ROOT}/nginx/suap"
    assert_success
}
