#!/bin/bash
# Script para configurar keystore local para builds de release
# Execute: chmod +x android/setup-keystore.sh && ./android/setup-keystore.sh

echo "=== Configuração de Keystore para Retro1 ==="
echo ""

# Verificar se o keystore já existe
KEYSTORE_PATH="android/app/release.keystore"
if [ -f "$KEYSTORE_PATH" ]; then
    echo "AVISO: O keystore já existe em $KEYSTORE_PATH"
    read -p "Deseja sobrescrever? (s/N): " overwrite
    if [ "$overwrite" != "s" ] && [ "$overwrite" != "S" ]; then
        echo "Operação cancelada."
        exit 0
    fi
fi

# Solicitar informações do keystore
echo "Por favor, forneça as seguintes informações:"
echo ""

read -sp "Senha do keystore: " STORE_PASSWORD
echo ""
read -sp "Senha da chave (pode ser a mesma do keystore): " KEY_PASSWORD
echo ""

read -p "Alias da chave (padrão: retro1): " KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-retro1}

read -p "Validade em dias (padrão: 10000): " VALIDITY
VALIDITY=${VALIDITY:-10000}

echo ""
echo "Criando keystore..."

# Criar o keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Retro1, OU=Development, O=Bandpass Records, L=City, ST=State, C=BR"

if [ $? -eq 0 ]; then
    echo "✓ Keystore criado com sucesso!"
else
    echo "✗ Erro ao criar keystore"
    exit 1
fi

# Criar o arquivo key.properties
echo ""
echo "Criando arquivo key.properties..."

KEY_PROPERTIES_PATH="android/key.properties"
cat > "$KEY_PROPERTIES_PATH" << EOF
storeFile=app/release.keystore
storePassword=$STORE_PASSWORD
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASSWORD
EOF

echo "✓ Arquivo key.properties criado em $KEY_PROPERTIES_PATH"

echo ""
echo "=== Configuração concluída! ==="
echo ""
echo "Agora você pode fazer builds de release localmente:"
echo "  flutter build appbundle --release"
echo "  flutter build apk --release"
echo ""
echo "⚠️  IMPORTANTE: NUNCA faça commit do keystore ou key.properties!"
