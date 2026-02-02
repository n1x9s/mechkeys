# MechKeys — Текущий этап

## Статус: Фаза 3 / MVP v0.1 ЗАВЕРШЁН
## Последнее обновление: 2026-02-02 14:10

### Завершено:
- [x] Создание структуры проекта
- [x] MVP v0.1
  - [x] Info.plist (LSUIElement)
  - [x] MenuBarExtra с иконкой и toggle
  - [x] PermissionManager — Accessibility onboarding
  - [x] KeyListener — CGEvent Tap
  - [x] SoundEngine — AVAudioEngine + пул 16 нод
  - [x] SoundPackManager — загрузка наборов
  - [x] 6 звуковых наборов (placeholder sounds)
  - [x] Окно настроек (Sound, General, About)
- [ ] Настройки v0.2
- [ ] Продвинутые функции v0.3
- [ ] Релиз v1.0

### Решения:
- Звуки: сгенерированы placeholder с помощью ffmpeg
- Иконка: SF Symbol keyboard.fill
- Дистрибуция: сначала .app
- Обновления: GitHub API
- Sandbox: отключён (требуется для CGEvent Tap)
- macOS: 13.0+ (Ventura)

### Следующие шаги:
1. Тестирование приложения
2. Заменить placeholder звуки на реальные сэмплы
3. Улучшить UI
4. Добавить DMG инсталлятор

### Файлы проекта:
- mechkeys/mechkeysApp.swift — главный файл, MenuBarExtra
- mechkeys/Core/ — KeyListener, SoundEngine, SoundPackManager, PermissionManager
- mechkeys/Models/ — KeyCategory, SoundPack, SettingsStore
- mechkeys/Views/ — SettingsView, OnboardingView, и другие
- SoundPacks/ — 6 наборов звуков

### Проблемы:
- Нет (сборка успешна)
