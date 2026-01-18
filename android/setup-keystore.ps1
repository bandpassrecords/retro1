# Script para configurar keystore local para builds de release
# Execute: .\android\setup-keystore.ps1

Write-Host "=== Configuração de Keystore para Retro1 ===" -ForegroundColor Cyan
Write-Host ""

# Verificar se o keystore já existe
$keystorePath = "android\app\release.keystore"
if (Test-Path $keystorePath) {
    Write-Host "AVISO: O keystore já existe em $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "Deseja sobrescrever? (s/N)"
    if ($overwrite -ne "s" -and $overwrite -ne "S") {
        Write-Host "Operação cancelada." -ForegroundColor Yellow
        exit 0
    }
}

# Solicitar informações do keystore
Write-Host "Por favor, forneça as seguintes informações:" -ForegroundColor Green
Write-Host ""

$storePassword = Read-Host "Senha do keystore" -AsSecureString
$storePasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword)
)

$keyPasswordConfirm = Read-Host "Senha da chave (pode ser a mesma do keystore)" -AsSecureString
$keyPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPasswordConfirm)
)

$keyAlias = Read-Host "Alias da chave (padrão: retro1)"
if ([string]::IsNullOrWhiteSpace($keyAlias)) {
    $keyAlias = "retro1"
}

$validity = Read-Host "Validade em dias (padrão: 10000)"
if ([string]::IsNullOrWhiteSpace($validity)) {
    $validity = "10000"
}

Write-Host ""
Write-Host "Criando keystore..." -ForegroundColor Green

# Criar o keystore
$keytoolCommand = "keytool -genkey -v -keystore `"$keystorePath`" -alias $keyAlias -keyalg RSA -keysize 2048 -validity $validity -storepass `"$storePasswordPlain`" -keypass `"$keyPasswordPlain`" -dname `"CN=Retro1, OU=Development, O=Bandpass Records, L=City, ST=State, C=BR`""

try {
    Invoke-Expression $keytoolCommand
    Write-Host "✓ Keystore criado com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "✗ Erro ao criar keystore: $_" -ForegroundColor Red
    exit 1
}

# Criar o arquivo key.properties
Write-Host ""
Write-Host "Criando arquivo key.properties..." -ForegroundColor Green

$keyPropertiesContent = @"
storeFile=app/release.keystore
storePassword=$storePasswordPlain
keyAlias=$keyAlias
keyPassword=$keyPasswordPlain
"@

$keyPropertiesPath = "android\key.properties"
$keyPropertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8 -NoNewline

Write-Host "✓ Arquivo key.properties criado em $keyPropertiesPath" -ForegroundColor Green

# Limpar senhas da memória
$storePasswordPlain = $null
$keyPasswordPlain = $null

Write-Host ""
Write-Host "=== Configuração concluída! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Agora você pode fazer builds de release localmente:" -ForegroundColor Green
Write-Host "  flutter build appbundle --release" -ForegroundColor Yellow
Write-Host "  flutter build apk --release" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  IMPORTANTE: NUNCA faça commit do keystore ou key.properties!" -ForegroundColor Red
