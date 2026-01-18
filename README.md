# One Second Per Day

Um aplicativo Flutter inspirado no One Second Everyday, onde você registra 1 segundo por dia e cria timelines visuais incríveis.

## Funcionalidades

- 📷 Captura de vídeo/foto diária
- ✂️ Editor de 1 segundo preciso
- 📅 Calendário e timeline visual
- 🎞️ Geração de vídeos compilados (mês/ano)
- 🔔 Notificações inteligentes
- ☁️ Backup local (Hive)

## Como executar

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Estrutura do Projeto

- `lib/models/` - Modelos de dados (Hive)
- `lib/services/` - Serviços (mídia, vídeo, notificações)
- `lib/screens/` - Telas do app
- `lib/widgets/` - Widgets reutilizáveis
- `lib/utils/` - Utilitários e helpers
