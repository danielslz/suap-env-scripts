#!/usr/bin/env bash
# tests/test_helper/common-setup.bash
# Helper compartilhado para todos os testes bats do projeto suap-setup.
# Carrega bats-support e bats-assert, e define variáveis comuns.

_COMMON_SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega bibliotecas auxiliares do bats
load "${_COMMON_SETUP_DIR}/bats-support/load.bash"
load "${_COMMON_SETUP_DIR}/bats-assert/load.bash"

# Raiz do projeto (dois níveis acima de tests/test_helper/)
export PROJECT_ROOT
PROJECT_ROOT="$(cd "${_COMMON_SETUP_DIR}/../.." && pwd)"

# Caminho para a biblioteca compartilhada do projeto
export LIB_DIR="${PROJECT_ROOT}/lib"
export COMMON_SH="${LIB_DIR}/common.sh"

# Diretório temporário para artefatos de teste (criado sob demanda)
# Uso: TEST_TEMP_DIR="$(temp_make)" dentro de setup()
#       temp_del "$TEST_TEMP_DIR" dentro de teardown()
