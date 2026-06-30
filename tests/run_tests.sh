#!/usr/bin/env bash
# tests/run_tests.sh - Script auxiliar para execução de testes
# Uso:
#   ./tests/run_tests.sh          # Executa todos os testes (exceto integração)
#   ./tests/run_tests.sh unit     # Apenas testes unitários
#   ./tests/run_tests.sh property # Apenas testes de propriedade
#   ./tests/run_tests.sh smoke    # Apenas testes de fumaça
#   ./tests/run_tests.sh all      # Todos incluindo integração

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BATS="${SCRIPT_DIR}/test_helper/bats-core/bin/bats"

if [[ ! -x "$BATS" ]]; then
    echo "Erro: bats-core não encontrado. Execute:"
    echo "  git submodule update --init --recursive"
    exit 1
fi

case "${1:-default}" in
    unit)
        echo "==> Executando testes unitários..."
        "$BATS" "${SCRIPT_DIR}/unit/"
        ;;
    property)
        echo "==> Executando testes de propriedade..."
        "$BATS" "${SCRIPT_DIR}/property/"
        ;;
    smoke)
        echo "==> Executando testes de fumaça..."
        "$BATS" "${SCRIPT_DIR}/smoke/"
        ;;
    integration)
        echo "==> Executando testes de integração..."
        "$BATS" "${SCRIPT_DIR}/integration/"
        ;;
    all)
        echo "==> Executando todos os testes..."
        "$BATS" "${SCRIPT_DIR}/unit/" "${SCRIPT_DIR}/property/" "${SCRIPT_DIR}/smoke/" "${SCRIPT_DIR}/integration/"
        ;;
    default)
        echo "==> Executando testes unitários, de propriedade e de fumaça..."
        "$BATS" "${SCRIPT_DIR}/unit/" "${SCRIPT_DIR}/property/" "${SCRIPT_DIR}/smoke/"
        ;;
    *)
        echo "Uso: $0 [unit|property|smoke|integration|all]"
        exit 1
        ;;
esac
