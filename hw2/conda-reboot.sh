#!/bin/bash -i

# --- Константы ---
ENV_NAME="cuda_venv"
PYTHON_VERSION="3.9"
CONDA_CMD="conda"
LOG_FILE="../../../conda_reboot.log"

# --- Функции для логирования ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

fail() {
    log "❌ Ошибка: $1"
    exit "${2:-1}"
}

# --- Проверка conda ---
if ! command -v "$CONDA_CMD" &> /dev/null; then
    fail "Conda не установлена или не добавлена в PATH!"
fi

# --- Подтверждение ---
read -p "⚠️ ВНИМАНИЕ: Скрипт переустановит окружение '$ENV_NAME'. Продолжить? [y/n] " answer
if [[ ! "$answer" =~ ^[Yy] ]]; then
    log "❌ Отменено пользователем."
    exit 1
fi

log "✅ Подтверждено. Начинаем..."

# --- Очистка модулей и деактивация ---
log "🔄 Очистка модулей и деактивация текущего окружения..."
module purge || fail "Не удалось очистить модули."
module load Python || fail "Не удалось загрузить Python."

if conda deactivate; then
    log "✅ Текущее окружение деактивировано."
else
    log "⚠️ Не удалось деактивировать окружение (возможно, его нет). Продолжаем..."
fi

# --- Удаление старого окружения ---
log "🔄 Проверка и удаление старого окружения '$ENV_NAME'..."
if conda env list | grep -q "$ENV_NAME"; then
    if conda remove --name "$ENV_NAME" --all -y; then
        log "✅ Окружение '$ENV_NAME' удалено."
    else
        fail "Не удалось удалить окружение '$ENV_NAME'."
    fi
else
    log "ℹ️ Окружение '$ENV_NAME' не найдено. Пропускаем удаление."
fi

# --- Создание нового окружения ---
log "🔄 Создание нового окружения '$ENV_NAME' (Python $PYTHON_VERSION)..."
if conda create --name "$ENV_NAME" python="$PYTHON_VERSION" -y; then
    log "✅ Окружение '$ENV_NAME' создано."
else
    fail "Не удалось создать окружение '$ENV_NAME'."
fi

# --- Установка зависимостей ---
log "🔄 Установка зависимостей через conda-libs-install.sh..."
if bash conda-libs-install.sh; then
    log "✅ Все зависимости установлены!"
else
    fail "Ошибка при установке зависимостей. Проверьте скрипт conda-libs-install.sh."
fi

log "🎉 Готово! Окружение '$ENV_NAME' успешно переустановлено."