# Configuração do Git

## Arquivos Criados/Atualizados

### `.gitignore`
Arquivo completo de ignore para Flutter/Android, incluindo:
- Build artifacts (`/build/`, `/android/app/build/`)
- Arquivos gerados (`*.g.dart`, `.dart_tool/`)
- Configurações locais (`android/local.properties`, `android/key.properties`)
- Keystores (`*.keystore`, `*.jks`)
- Arquivos de IDE (`.idea/`, `.vscode/`)
- Cache do Gradle (`android/.gradle/`)

### `.gitattributes`
Configuração de normalização de line endings:
- Arquivos de texto: LF (Linux/Mac)
- Scripts Windows: CRLF
- Arquivos binários: sem conversão

## Arquivos Versionados

### Código Fonte
- ✅ `lib/` - Todo o código Dart
- ✅ `assets/` - Assets do aplicativo
- ✅ `pubspec.yaml` e `pubspec.lock` - Dependências
- ✅ `l10n.yaml` - Configuração de localização
- ✅ `analysis_options.yaml` - Configuração do linter

### Android
- ✅ `android/app/build.gradle.kts` - Build do app
- ✅ `android/build.gradle.kts` - Build raiz
- ✅ `android/settings.gradle.kts` - Configurações do Gradle
- ✅ `android/gradle.properties` - Propriedades do Gradle
- ✅ `android/gradle/wrapper/` - Gradle Wrapper
- ✅ `android/gradlew` e `android/gradlew.bat` - Scripts do Gradle
- ✅ `android/app/src/` - Código fonte Android (Kotlin, recursos)

### CI/CD
- ✅ `.github/workflows/android-release.yml` - Workflow de release

## Arquivos NÃO Versionados (ignorados)

### Configurações Locais
- ❌ `android/local.properties` - Contém paths locais do SDK
- ❌ `android/key.properties` - Contém senhas do keystore
- ❌ `android/app/release.keystore` - Keystore de assinatura

### Build Artifacts
- ❌ `/build/` - Outputs de build
- ❌ `android/app/build/` - Builds do Android
- ❌ `android/.gradle/` - Cache do Gradle

### Arquivos Gerados
- ❌ `*.g.dart` - Arquivos gerados pelo build_runner
- ❌ `.dart_tool/` - Cache do Dart
- ❌ `.flutter-plugins` - Cache de plugins

## Próximos Passos

1. **Configurar Secrets no GitHub** (para CI/CD):
   - `ANDROID_KEYSTORE_BASE64`
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`

2. **Criar Keystore Local** (para builds locais):
   ```bash
   keytool -genkey -v -keystore android/app/release.keystore -alias retro1 -keyalg RSA -keysize 2048 -validity 10000
   ```

3. **Criar `android/key.properties`** (não versionado):
   ```properties
   storeFile=release.keystore
   storePassword=sua_senha
   keyAlias=retro1
   keyPassword=sua_senha
   ```

## Comandos Úteis

### Verificar status
```bash
git status
```

### Adicionar todos os arquivos necessários
```bash
git add .
```

### Verificar o que será commitado
```bash
git status --short
```

### Commit inicial
```bash
git commit -m "Initial commit: Retro1 Android app"
```

## Notas

- O arquivo `android/local.properties` é gerado automaticamente pelo Flutter e não deve ser versionado
- Os arquivos `*.g.dart` são gerados pelo `build_runner` e não devem ser versionados
- O keystore de release deve ser mantido em segredo e nunca versionado
