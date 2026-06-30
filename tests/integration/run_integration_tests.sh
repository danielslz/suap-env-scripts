#!/usr/bin/env bash
# tests/integration/run_integration_tests.sh
# Script para construir imagens Docker e executar testes de integração
#
# Uso:
#   ./tests/integration/run_integration_tests.sh          # Executa todos os testes
#   ./tests/integration/run_integration_tests.sh debian   # Apenas testes Debian
#   ./tests/integration/run_integration_tests.sh fedora   # Apenas testes Fedora
#   ./tests/integration/run_integration_tests.sh debian dev   # Apenas dev Debian
#   ./tests/integration/run_integration_tests.sh fedora prod  # Apenas prod Fedora

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Cores para output
GREEN=$(tput setaf 2 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
NO_COLOR=$(tput sgr0 2>/dev/null || echo "")

# Nomes das imagens Docker de teste
IMAGE_DEBIAN="suap-test-deb"
IMAGE_FEDORA="suap-test-rpm"

# Caminho do bats dentro do container
BATS_CMD="tests/test_helper/bats-core/bin/bats"

msg_info() { echo "${GREEN}==> $1${NO_COLOR}"; }
msg_warn() { echo "${YELLOW}==> $1${NO_COLOR}"; }
msg_fail() { echo "${RED}==> FALHA: $1${NO_COLOR}"; }

# Verificar se Docker está disponível
check_docker() {
    if ! command -v docker &>/dev/null; then
        msg_fail "Docker não está instalado. Instale o Docker para executar testes de integração."
        exit 1
    fi

    if ! docker info &>/dev/null; then
        msg_fail "Docker daemon não está rodando ou sem permissão. Verifique com 'docker info'."
        exit 1
    fi
}

# Construir imagem Docker
build_image() {
    local distro="$1"
    local dockerfile="tests/integration/Dockerfile.${distro}"
    local image_name

    if [ "${distro}" = "debian" ]; then
        image_name="${IMAGE_DEBIAN}"
    else
        image_name="${IMAGE_FEDORA}"
    fi

    msg_info "Construindo imagem ${image_name} a partir de ${dockerfile}..."
    if ! docker build -f "${dockerfile}" -t "${image_name}" "${PROJECT_ROOT}"; then
        msg_fail "Falha ao construir imagem ${image_name}"
        return 1
    fi
    msg_info "Imagem ${image_name} construída com sucesso."
}

# Executar testes em um container
run_tests() {
    local distro="$1"
    local test_type="$2"
    local image_name
    local test_file

    if [ "${distro}" = "debian" ]; then
        image_name="${IMAGE_DEBIAN}"
        test_file="tests/integration/test_${test_type}_debian.bats"
    else
        image_name="${IMAGE_FEDORA}"
        test_file="tests/integration/test_${test_type}_rpm.bats"
    fi

    msg_info "Executando ${test_file} em container ${image_name}..."
    if docker run --rm "${image_name}" "${BATS_CMD}" "${test_file}"; then
        msg_info "PASSOU: ${test_file}"
        return 0
    else
        msg_fail "FALHOU: ${test_file}"
        return 1
    fi
}

# Executar todos os testes para uma distro
run_all_for_distro() {
    local distro="$1"
    local failures=0

    build_image "${distro}" || return 1

    run_tests "${distro}" "dev" || ((failures++))
    run_tests "${distro}" "prod" || ((failures++))

    return "${failures}"
}

# --- Main ---

check_docker

DISTRO="${1:-all}"
TEST_TYPE="${2:-all}"
TOTAL_FAILURES=0

case "${DISTRO}" in
    debian)
        if [ "${TEST_TYPE}" = "all" ]; then
            run_all_for_distro "debian" || ((TOTAL_FAILURES++))
        else
            build_image "debian" || exit 1
            run_tests "debian" "${TEST_TYPE}" || ((TOTAL_FAILURES++))
        fi
        ;;
    fedora)
        if [ "${TEST_TYPE}" = "all" ]; then
            run_all_for_distro "fedora" || ((TOTAL_FAILURES++))
        else
            build_image "fedora" || exit 1
            run_tests "fedora" "${TEST_TYPE}" || ((TOTAL_FAILURES++))
        fi
        ;;
    all)
        msg_info "Executando todos os testes de integração (Debian + Fedora)..."
        echo ""
        run_all_for_distro "debian" || ((TOTAL_FAILURES++))
        echo ""
        run_all_for_distro "fedora" || ((TOTAL_FAILURES++))
        ;;
    *)
        echo "Uso: $0 [debian|fedora|all] [dev|prod|all]"
        exit 1
        ;;
esac

echo ""
if [ "${TOTAL_FAILURES}" -eq 0 ]; then
    msg_info "Todos os testes de integração passaram!"
    exit 0
else
    msg_fail "Alguns testes de integração falharam."
    exit 1
fi
