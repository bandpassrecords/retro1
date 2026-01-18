# Configuração de Keystore para Builds Locais

## Para Builds de Debug

**Não é necessário configurar nada!** O Android usa automaticamente um keystore de debug que é gerado automaticamente na primeira vez que você faz um build de debug.

## Para Builds de Release Locais

Se você quiser fazer builds de release localmente, siga estes passos:

### 1. Criar o Keystore

Execute o seguinte comando no terminal (na raiz do projeto):

```bash
keytool -genkey -v -keystore android/app/release.keystore -alias retro1 -keyalg RSA -keysize 2048 -validity 10000
```

**Informações solicitadas:**
- **Senha do keystore**: Escolha uma senha forte
- **Senha da chave**: Pode ser a mesma do keystore
- **Nome completo**: Seu nome ou nome da organização
- **Organização**: Nome da organização
- **Cidade**: Sua cidade
- **Estado**: Seu estado
- **Código do país**: Ex: BR, US, etc.

### 2. Criar o arquivo key.properties

Copie o arquivo de exemplo:

```bash
# Windows (PowerShell)
Copy-Item android/key.properties.example android/key.properties

# Linux/Mac
cp android/key.properties.example android/key.properties
```

Edite o arquivo `android/key.properties` e preencha com suas informações:

```properties
storeFile=app/release.keystore
storePassword=sua_senha_do_keystore
keyAlias=retro1
keyPassword=sua_senha_da_chave
```

### 3. Verificar que está funcionando

Faça um build de release:

```bash
flutter build appbundle --release
```

## ⚠️ IMPORTANTE

- **NUNCA** faça commit do arquivo `android/key.properties` ou `android/app/release.keystore`
- Esses arquivos já estão no `.gitignore`
- Guarde o keystore em um local seguro (backup)
- Use o mesmo keystore para todas as atualizações do app no Play Store

## Para CI/CD

O keystore é configurado automaticamente pelo GitHub Actions usando secrets. Não é necessário fazer nada manualmente.
