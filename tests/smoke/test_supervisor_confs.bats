#!/usr/bin/env bats
# tests/smoke/test_supervisor_confs.bats - Testes de fumaça para configurações Supervisor
# Valida: Requisitos 21.1, 21.2, 21.3, 21.4, 21.5, 21.6, 21.7, 21.8

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    SUAP_CONF="$PROJECT_ROOT/supervisor/suap.conf"
    CELERY_WORKER_CONF="$PROJECT_ROOT/supervisor/celery_worker.conf"
    CELERY_BEAT_CONF="$PROJECT_ROOT/supervisor/celery_beat.conf"
    CELERY_FLOWER_CONF="$PROJECT_ROOT/supervisor/celery_flower.conf"
}

# ============================================================
# supervisor/suap.conf
# ============================================================

@test "suap.conf existe" {
    [ -f "$SUAP_CONF" ]
}

@test "suap.conf contém seção [program:suap]" {
    run grep -q "\[program:suap\]" "$SUAP_CONF"
    [ "$status" -eq 0 ]
}

@test "suap.conf define directory" {
    run grep -q "directory" "$SUAP_CONF"
    [ "$status" -eq 0 ]
}

@test "suap.conf define user" {
    run grep -q "user" "$SUAP_CONF"
    [ "$status" -eq 0 ]
}

@test "suap.conf define command" {
    run grep -q "command" "$SUAP_CONF"
    [ "$status" -eq 0 ]
}

@test "suap.conf define stdout_logfile" {
    run grep -q "stdout_logfile" "$SUAP_CONF"
    [ "$status" -eq 0 ]
}

@test "suap.conf define stderr_logfile" {
    run grep -q "stderr_logfile" "$SUAP_CONF"
    [ "$status" -eq 0 ]
}

# ============================================================
# supervisor/celery_worker.conf
# ============================================================

@test "celery_worker.conf existe" {
    [ -f "$CELERY_WORKER_CONF" ]
}

@test "celery_worker.conf contém seção [program:celery_worker]" {
    run grep -q "\[program:celery_worker\]" "$CELERY_WORKER_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_worker.conf define directory" {
    run grep -q "directory" "$CELERY_WORKER_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_worker.conf define user" {
    run grep -q "user" "$CELERY_WORKER_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_worker.conf define command" {
    run grep -q "command" "$CELERY_WORKER_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_worker.conf define stdout_logfile" {
    run grep -q "stdout_logfile" "$CELERY_WORKER_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_worker.conf define stderr_logfile" {
    run grep -q "stderr_logfile" "$CELERY_WORKER_CONF"
    [ "$status" -eq 0 ]
}

# ============================================================
# supervisor/celery_beat.conf
# ============================================================

@test "celery_beat.conf existe" {
    [ -f "$CELERY_BEAT_CONF" ]
}

@test "celery_beat.conf contém seção [program:celery_beat]" {
    run grep -q "\[program:celery_beat\]" "$CELERY_BEAT_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_beat.conf define directory" {
    run grep -q "directory" "$CELERY_BEAT_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_beat.conf define user" {
    run grep -q "user" "$CELERY_BEAT_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_beat.conf define command" {
    run grep -q "command" "$CELERY_BEAT_CONF"
    [ "$status" -eq 0 ]
}

# ============================================================
# supervisor/celery_flower.conf
# ============================================================

@test "celery_flower.conf existe" {
    [ -f "$CELERY_FLOWER_CONF" ]
}

@test "celery_flower.conf contém seção [program:celery_flower]" {
    run grep -q "\[program:celery_flower\]" "$CELERY_FLOWER_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_flower.conf define directory" {
    run grep -q "directory" "$CELERY_FLOWER_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_flower.conf define user" {
    run grep -q "user" "$CELERY_FLOWER_CONF"
    [ "$status" -eq 0 ]
}

@test "celery_flower.conf define command" {
    run grep -q "command" "$CELERY_FLOWER_CONF"
    [ "$status" -eq 0 ]
}
