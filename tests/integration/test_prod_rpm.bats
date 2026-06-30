#!/usr/bin/env bats
# tests/integration/test_prod_rpm.bats
# Testes de integração: fluxo de produção completo em RPM (Fedora)
# Executado dentro de container Docker (Dockerfile.fedora)

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

# --- Testes do ambiente para produção RPM ---

@test "[rpm-prod] rpm/suap-prod.sh existe e é executável" {
    [ -f "${PROJECT_ROOT}/rpm/suap-prod.sh" ]
    [ -x "${PROJECT_ROOT}/rpm/suap-prod.sh" ]
}

@test "[rpm-prod] script de produção exige root" {
    # Executar como não-root deve falhar
    if [ "$(id -u)" -eq 0 ]; then
        skip "Teste executando como root - não é possível testar rejeição"
    fi

    run bash -c "source '${PROJECT_ROOT}/lib/common.sh' && load_env_file '${TEST_ENV_FILE}' && bash '${PROJECT_ROOT}/rpm/suap-prod.sh'"
    assert_failure
}

@test "[rpm-prod] detect_distro() funciona em ambiente RPM de produção" {
    run bash -c "source '${PROJECT_ROOT}/lib/common.sh' && detect_distro && echo \${DISTRO_TYPE}"
    assert_success
    assert_output "rpm"
}

@test "[rpm-prod] get_supervisor_conf_dir() retorna caminho RPM" {
    run bash -c "source '${PROJECT_ROOT}/lib/common.sh' && DISTRO_TYPE=rpm && get_supervisor_conf_dir"
    assert_success
    assert_output "/etc/supervisord.d"
}

@test "[rpm-prod] get_nginx_conf_path() retorna caminho RPM" {
    run bash -c "source '${PROJECT_ROOT}/lib/common.sh' && DISTRO_TYPE=rpm && get_nginx_conf_path"
    assert_success
    assert_output "/etc/nginx/conf.d/suap.conf"
}

# --- Testes de configurações de produção ---

@test "[rpm-prod] arquivos de configuração do Supervisor existem" {
    [ -f "${PROJECT_ROOT}/supervisor/suap.conf" ]
    [ -f "${PROJECT_ROOT}/supervisor/run_suap.sh" ]
    [ -f "${PROJECT_ROOT}/supervisor/celery_worker.conf" ]
    [ -f "${PROJECT_ROOT}/supervisor/run_celery_worker.sh" ]
    [ -f "${PROJECT_ROOT}/supervisor/celery_beat.conf" ]
    [ -f "${PROJECT_ROOT}/supervisor/run_celery_beat.sh" ]
    [ -f "${PROJECT_ROOT}/supervisor/celery_flower.conf" ]
    [ -f "${PROJECT_ROOT}/supervisor/run_celery_flower.sh" ]
}

@test "[rpm-prod] configuração Nginx existe" {
    [ -f "${PROJECT_ROOT}/nginx/suap" ]
}

@test "[rpm-prod] configuração Nginx contém upstream com least_conn" {
    run grep "least_conn" "${PROJECT_ROOT}/nginx/suap"
    assert_success
}

@test "[rpm-prod] configuração Nginx contém client_max_body_size" {
    run grep "client_max_body_size" "${PROJECT_ROOT}/nginx/suap"
    assert_success
}
