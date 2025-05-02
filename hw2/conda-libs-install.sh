#!/bin/bash

# --- Константы ---
ENV_NAME="cuda_venv"
LOG_FILE="../../../conda_libs_install.log"

# --- Функции ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

fail() {
    log "❌ Ошибка: $1"
    exit "${2:-1}"
}

# --- Активация окружения ---
log "🔄 Активация окружения '$ENV_NAME'..."
module purge || fail "Не удалось очистить модули."
module load Python || fail "Не удалось загрузить Python."

if conda activate "$ENV_NAME"; then
    log "✅ Окружение '$ENV_NAME' активировано."
else
    fail "Не удалось активировать окружение '$ENV_NAME'."
fi

# --- Установка пакетов ---
log "🔄 Установка CUDA и зависимостей..."
packages=(
    "conda-forge::cudatoolkit=11.7"
    "conda-forge::pycuda"
    "numba"
    "numpy"
)

for pkg in "${packages[@]}"; do
    log "Установка: $pkg..."
    if conda install -c conda-forge "$pkg" -y; then
        log "✅ Успешно: $pkg"
    else
        fail "Не удалось установить $pkg."
    fi
done

log "✅ Все пакеты установлены!"