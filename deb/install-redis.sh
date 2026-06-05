#!/usr/bin/env bash
set -u

echo "Instalando Redis..."

# Atualizar repositórios
sudo apt-get update

# Instalar Redis
sudo apt-get install -y redis-server

# Iniciar o serviço Redis
sudo systemctl start redis-server

# Habilitar Redis para iniciar automaticamente
sudo systemctl enable redis-server

# Verificar status
echo "Verificando status do Redis..."
sudo systemctl status redis-server

echo "Redis instalado com sucesso!"
