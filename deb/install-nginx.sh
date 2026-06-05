#!/usr/bin/env bash
set -u

echo "Instalando Nginx"

# Atualizar repositórios
sudo apt-get update

# Instalar Nginx
sudo apt-get install -y nginx

# Iniciar o serviço Nginx
sudo systemctl start nginx

# Habilitar Nginx para iniciar automaticamente
sudo systemctl enable nginx

# Copiar arquivo de configuração do SUAP
echo "Copiando configuração do SUAP..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sudo cp "$SCRIPT_DIR/nginx/suap" /etc/nginx/sites-available/suap

# Criar link simbólico em sites-enabled
sudo ln -sf /etc/nginx/sites-available/suap /etc/nginx/sites-enabled/suap

# Desabilitar configuração padrão se existir
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
echo "Testando configuração do Nginx..."
sudo nginx -t

# Recarregar Nginx para aplicar a nova configuração
echo "Recarregando Nginx..."
sudo systemctl reload nginx

# Verificar status
echo "Verificando status do Nginx..."
sudo systemctl status nginx

echo "Nginx instalado com sucesso!"
echo ""
echo "⚠️  IMPORTANTE: Não esqueça de configurar os endereços IPs no arquivo de configuração do SUAP"
echo "Arquivo: /etc/nginx/sites-available/suap"
echo "Certifique-se de informar corretamente os IPs dos servidores backend (upstream)."
