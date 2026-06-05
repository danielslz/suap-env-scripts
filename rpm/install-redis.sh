#!/usr/bin/env bash
set -u

echo "Instalando Redis..."

# Instalar Redis
sudo dnf install -y redis

# Iniciar o serviço Redis
sudo systemctl start redis

# Habilitar Redis para iniciar automaticamente
sudo systemctl enable redis

# Verificar status
echo "Verificando status do Redis..."
sudo systemctl status redis

echo "Redis instalado com sucesso!"
